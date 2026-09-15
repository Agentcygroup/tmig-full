from fastapi import FastAPI, HTTPException
import ray
import os
import json

app = FastAPI(title="Sovereign Mesh Microservice Gateway", version="0.0.1")

if not ray.is_initialized():
    ray.init(ignore_reinit_error=True)

@ray.remote
def execute_node_task(node_id: str, payload: dict):
    return {"node": node_id, "status": "executed", "received_payload": payload}

@app.post("/mesh/dispatch")
async def dispatch_task(node_id: str, payload: dict):
    valid_nodes = ["node-01", "node-02", "node-03"]
    if node_id not in valid_nodes:
        raise HTTPException(status_code=400, detail="Invalid edge node identifier.")

    future = execute_node_task.remote(node_id, payload)
    result = ray.get(future)
    return {"gateway": "active", "dispatch_result": result}

@app.get("/mesh/status")
async def mesh_status():
    receipt_base = os.path.expanduser("~/receipts/Agentcygroup/mlx-cluster")
    nodes_status = {}
    for node in ["node-01", "node-02", "node-03"]:
        state_path = os.path.join(receipt_base, node, "toroidal_state.json")
        if os.path.exists(state_path):
            with open(state_path, "r") as f:
                nodes_status[node] = json.load(f)
        else:
            nodes_status[node] = {"status": "uninitialized"}
    return {"cluster_topology": "toroidal", "nodes": nodes_status}
