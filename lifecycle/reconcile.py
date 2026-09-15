#!/usr/bin/env python3
import os, pathlib, signal, subprocess, sys, time, urllib.request
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

ROOT = pathlib.Path.home() / "tmig-full"
SPEC = ROOT / "lifecycle" / "services.toml"
VENV = os.environ.get("TMIG_VENV") or str(pathlib.Path.home() / ".pi-venv")

def expand(s):
    return os.path.expanduser(s.replace("$VENV", VENV))

def healthy(url, timeout=3):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            return 200 <= r.status < 400
    except Exception:
        return False

def pid_on(port):
    try:
        out = subprocess.check_output(["lsof", "-ti", f":{port}"],
                                      stderr=subprocess.DEVNULL).decode().split()
        return [int(x) for x in out if x.strip().isdigit()]
    except subprocess.CalledProcessError:
        return []

def wait_port_free(port, deadline=5.0):
    end = time.time() + deadline
    while time.time() < end:
        if not pid_on(port):
            return True
        time.sleep(0.2)
    return not pid_on(port)

def wait_ready(svc, timeout=45.0):
    end = time.time() + timeout
    url = svc['health']
    while time.time() < end:
        if healthy(url):
            return True
        time.sleep(0.25)
    return False

def kill_pids(pids):
    for pid in pids:
        try: os.kill(pid, signal.SIGTERM)
        except ProcessLookupError: pass
    time.sleep(0.5)
    for pid in pids:
        try: os.kill(pid, signal.SIGKILL)
        except ProcessLookupError: pass

def start(svc):
    log = open(expand(svc["log"]), "ab")
    env = os.environ.copy()
    env["PATH"] = "/opt/homebrew/bin:" + env.get("PATH", "")
    p = subprocess.Popen(
        [expand(x) for x in svc["cmd"]],
        cwd=expand(svc.get("cwd", "~")),
        env=env, stdin=subprocess.DEVNULL, stdout=log, stderr=log,
        start_new_session=True,
    )
    wait_ready(svc, timeout=45.0)
    return p.pid

def reconcile(dry=False):
    specs = tomllib.loads(SPEC.read_text())["service"]
    out = []
    for svc in specs:
        name, port, url = svc["name"], int(svc["port"]), svc["health"]
        if healthy(url):
            out.append((name, port, "up", "skip"))
            continue
        pids = pid_on(port)
        if dry:
            out.append((name, port, "down", f"would restart pids={pids}"))
            continue
        if pids:
            kill_pids(pids); wait_port_free(port)
        out.append((name, port, "down", f"started pid={start(svc)}"))
    return out

def main():
    dry = "--dry" in sys.argv
    rows = reconcile(dry=dry)
    for n, p, s, a in rows:
        print(f"  {n:<12} :{p}  {s:<5}  {a}")
    ok = all(healthy(f"http://127.0.0.1:{p}/health") or
             healthy(f"http://127.0.0.1:{p}/v1/models") for _, p, _, _ in rows)
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
