#!/usr/bin/env python3
import os, pathlib, signal, socket, subprocess, sys, time, urllib.request

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
        out = subprocess.check_output(
            ["lsof", "-ti", f":{port}"], stderr=subprocess.DEVNULL
        ).decode().split()
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

def kill_pids(pids):
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    time.sleep(0.5)
    for pid in pids:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

def start(svc):
    cmd = [expand(x) for x in svc["cmd"]]
    log = open(expand(svc["log"]), "ab")
    cwd = expand(svc.get("cwd", "~"))
    env = os.environ.copy()
    env["PATH"] = "/opt/homebrew/bin:" + env.get("PATH", "")
    p = subprocess.Popen(
        cmd, cwd=cwd, env=env,
        stdin=subprocess.DEVNULL, stdout=log, stderr=log,
        start_new_session=True,
    )
    return p.pid

def reconcile(dry=False):
    specs = tomllib.loads(SPEC.read_text())["service"]
    results = []
    for svc in specs:
        name, port, url = svc["name"], int(svc["port"]), svc["health"]
        if healthy(url):
            results.append((name, port, "up", "skip"))
            continue
        pids = pid_on(port)
        if dry:
            results.append((name, port, "down", f"would restart (pids={pids})"))
            continue
        if pids:
            kill_pids(pids)
            wait_port_free(port)
        pid = start(svc)
        results.append((name, port, "down", f"started pid={pid}"))
    return results

def main():
    dry = "--dry" in sys.argv
    r = reconcile(dry=dry)
    for name, port, state, action in r:
        print(f"  {name:<12} :{port}  {state:<5}  {action}")
    time.sleep(2)
    all_up = all(healthy(f"http://127.0.0.1:{port}/health") or
                 healthy(f"http://127.0.0.1:{port}/v1/models")
                 for _, port, _, _ in r)
    return 0 if all_up else 1

if __name__ == "__main__":
    sys.exit(main())
