#!/usr/bin/env python3
"""monte25k — nested Monte Carlo over the reconciler's invariants.

For each trial:
  1. pick a random subset of services to kill
  2. run reconcile() once
  3. assert every service is healthy afterwards
  4. run reconcile() again
  5. assert the second run reports every service as `up skip`

Outer trials:  25_000
Inner trials:  random subset size, 0..N
Deterministic seed so runs are reproducible.
"""
import os, pathlib, random, signal, subprocess, sys, time, urllib.request

ROOT = pathlib.Path.home() / "tmig-full"
sys.path.insert(0, str(ROOT / "lifecycle"))
import reconcile as R   # noqa: E402

TRIALS = int(os.environ.get("MONTE_TRIALS", "25000"))
SEED   = int(os.environ.get("MONTE_SEED", "20260915"))
SLEEP  = float(os.environ.get("MONTE_SLEEP", "0.35"))

def services():
    return R.tomllib.loads(R.SPEC.read_text())["service"]

def healthy(url):
    return R.healthy(url)

def kill_svc(svc):
    for pid in R.pid_on(int(svc["port"])):
        try: os.kill(pid, signal.SIGKILL)
        except ProcessLookupError: pass

def all_up(svcs):
    return all(healthy(s["health"]) for s in svcs)

def main():
    random.seed(SEED)
    svcs = services()
    n = len(svcs)
    fails = []
    t0 = time.time()

    # warm-up: ensure all up
    R.reconcile()
    time.sleep(SLEEP)
    if not all_up(svcs):
        print("warm-up failed: not all services healthy")
        return 2

    for i in range(1, TRIALS + 1):
        k = random.randint(0, n)
        victims = random.sample(svcs, k)
        for s in victims:
            kill_svc(s)
        R.reconcile()

        if not all_up(svcs):
            fails.append((i, "after first reconcile, some down",
                          [s["name"] for s in svcs if not healthy(s["health"])]))

        # second reconcile must be a pure no-op
        second = R.reconcile()
        acted = [r for r in second if r[3] != "skip"]
        if acted:
            fails.append((i, "second reconcile acted",
                          [(r[0], r[2], r[3]) for r in acted]))

        if i % 500 == 0:
            rate = i / max(time.time() - t0, 1e-6)
            eta  = (TRIALS - i) / max(rate, 1e-6)
            print(f"  trial {i:>6} / {TRIALS}   rate {rate:6.1f}/s   eta {eta:6.0f}s   fails {len(fails)}")

        if fails and len(fails) >= 5:
            print("stopping: 5 failures reached")
            break

    print()
    print(f"trials run: {TRIALS}")
    print(f"failures:   {len(fails)}")
    for i, why, detail in fails[:10]:
        print(f"  trial {i}: {why}: {detail}")
    print(f"elapsed:    {time.time() - t0:.1f}s")
    return 0 if not fails else 1

if __name__ == "__main__":
    sys.exit(main())
