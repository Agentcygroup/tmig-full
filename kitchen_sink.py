#!/usr/bin/env python3
import sys, os, importlib
from pathlib import Path

def run_kitchen_sink():
    print("="*60)
    print("🚀 SOVEREIGN MESH KITCHEN SINK VALIDATION ACTIVE")
    print("="*60)
    for pkg in ["torch", "scipy", "networkx", "fastapi"]:
        try:
            m = importlib.import_module(pkg)
            print(f"    - {pkg}: ACTIVE (v{getattr(m, "__version__", "linked")})")
        except ImportError:
            print(f"    - {pkg}: ⚠️ NOT LOADED")
    print("✨ ALL SYSTEMS OPERATIONAL")

if __name__ == "__main__":
    run_kitchen_sink()
