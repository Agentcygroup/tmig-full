#!/usr/bin/env python3
import sys, json, subprocess, pathlib
ROOT = pathlib.Path.home() / "tmig-full"
PY = ROOT / "venvs" / "hf" / "bin" / "python"
def status():
    out = {}
    for name, cmd in [
        ("llama.cpp", ["which","llama-server"]), ("ollama", ["which","ollama"]),
        ("vLLM", [str(PY),"-c","import vllm"]), ("MLX", [str(PY),"-c","import mlx_lm"]),
        ("faster-whisper", [str(PY),"-c","import faster_whisper"]),
        ("diffusers", [str(PY),"-c","import diffusers"]),
        ("transformers", [str(PY),"-c","import transformers"]),
    ]:
        try: out[name] = subprocess.run(cmd, capture_output=True, timeout=10).returncode == 0
        except Exception: out[name] = False
    return out
def pick(task):
    order = {
        "text-generation": ["llama.cpp","MLX","vLLM","transformers"],
        "translation": ["llama.cpp","MLX","vLLM","transformers"],
        "summarization": ["llama.cpp","vLLM","transformers"],
        "text-classification": ["vLLM","transformers"],
        "question-answering": ["vLLM","transformers"],
        "sentence-similarity": ["vLLM","transformers"],
        "image-classification": ["vLLM","transformers"],
        "object-detection": ["vLLM","transformers"],
        "image-segmentation": ["vLLM","transformers"],
        "image-to-text": ["vLLM","transformers"],
        "text-to-image": ["diffusers"],
        "automatic-speech-recognition": ["faster-whisper","transformers"],
        "text-to-speech": ["transformers"],
        "time-series-forecasting": ["transformers"],
        "robotics": ["transformers"], "reinforcement-learning": ["transformers"],
        "graph-ml": ["transformers"],
    }
    a = status()
    for r in order.get(task, ["transformers"]):
        if a.get(r): return r
    return None
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "status": print(json.dumps(status(), indent=2))
    elif len(sys.argv) > 1: print(pick(sys.argv[1]))
    else: print(json.dumps({"available": status()}, indent=2))
