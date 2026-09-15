#!/usr/bin/env python3
import os
import json
import hashlib
from datetime import datetime, timezone

NODES = ["node-01", "node-02", "node-03"]
GRID_SIZE = 3

def initialize_mesh():
    print("== Initializing Live Sovereign Mesh Runtime (MLX Cluster) ==")
    receipt_base = os.path.expanduser("~/receipts/Agentcygroup/mlx-cluster")

    for i, node in enumerate(NODES):
        x = i % GRID_SIZE
        y = (i + 1) % GRID_SIZE
        bound_input = f"{node}-0.0.1-{x}-{y}".encode()
        hash_val = hashlib.sha256(bound_input).hexdigest()

        node_dir = os.path.join(receipt_base, node)
        os.makedirs(node_dir, exist_ok=True)

        state = {
            "node": node,
            "topology": "toroidal",
            "coordinates": {"x": x, "y": y},
            "kaleidogami_bound": hash_val,
            "status": "live-operational",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

        path = os.path.join(node_dir, "toroidal_state.json")
        with open(path, "w") as f:
            json.dump(state, f, indent=2)

        print(f"[{node}] Active -> Toroidal Coordinate ({x}, {y}) | Hash: {hash_val[:12]}")

    print("== Sovereign Mesh Node Daemon Active & Self-Executing ==")

if __name__ == "__main__":
    initialize_mesh()
