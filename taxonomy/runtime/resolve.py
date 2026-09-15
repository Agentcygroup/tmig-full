#!/usr/bin/env python3
import sys, re, pathlib, json
from pxr import Usd
TAX = pathlib.Path.home() / "tmig-full" / "taxonomy"
RULES = [
    (r"\b(translate|translation)\b", "translation"),
    (r"\b(summarize|summary)\b", "summarization"),
    (r"\b(classify|classification)\b", "text-classification"),
    (r"\b(question|qa)\b", "question-answering"),
    (r"\b(generate|write)\b", "text-generation"),
    (r"\b(embed|similar)\b", "sentence-similarity"),
    (r"\b(image|photo)\b", "image-classification"),
    (r"\b(detect)\b", "object-detection"),
    (r"\b(segment)\b", "image-segmentation"),
    (r"\b(caption|describe image)\b", "image-to-text"),
    (r"\b(draw|paint|imagine)\b", "text-to-image"),
    (r"\b(speech|transcribe|asr)\b", "automatic-speech-recognition"),
    (r"\b(speak|tts|voice)\b", "text-to-speech"),
    (r"\b(forecast|series)\b", "time-series-forecasting"),
    (r"\b(robot)\b", "robotics"),
    (r"\b(rl|reinforce)\b", "reinforcement-learning"),
    (r"\b(graph|node)\b", "graph-ml"),
]
RUNTIME_MAP = {
    "text-generation": "llama.cpp", "translation": "llama.cpp",
    "summarization": "llama.cpp", "text-classification": "vLLM",
    "question-answering": "vLLM", "sentence-similarity": "vLLM",
    "image-classification": "vLLM", "object-detection": "vLLM",
    "image-segmentation": "vLLM", "image-to-text": "vLLM",
    "text-to-image": "diffusers",
    "automatic-speech-recognition": "faster-whisper",
    "text-to-speech": "transformers",
    "time-series-forecasting": "transformers",
    "robotics": "transformers", "reinforcement-learning": "transformers",
    "graph-ml": "transformers",
}
def resolve(text):
    hits = [t for pat, t in RULES if re.search(pat, text, re.I)] or ["text-generation"]
    catalog = TAX / "unified.usda"
    prims = []
    if catalog.exists():
        s = Usd.Stage.Open(str(catalog))
        if s:
            for prim in s.Traverse():
                t = prim.GetAttribute("task")
                if t and t.Get() in hits:
                    m = prim.GetAttribute("model")
                    prims.append({"task": t.Get(), "path": str(prim.GetPath()),
                                  "model": m.Get() if m else None})
    return {"intent": text, "tasks": hits,
            "runtime": RUNTIME_MAP.get(hits[0], "vLLM"),
            "prims": prims[:10]}
if __name__ == "__main__":
    print(json.dumps(resolve(" ".join(sys.argv[1:]) or "generate text"), indent=2))
