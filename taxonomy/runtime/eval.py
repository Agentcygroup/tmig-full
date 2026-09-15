#!/usr/bin/env python3
import sys, json, time, pathlib, subprocess
RUNT = pathlib.Path.home() / "tmig-full" / "taxonomy" / "runtime"
PY = pathlib.Path.home() / "tmig-full" / "venvs" / "hf" / "bin" / "python"
def bench(task):
    t0 = time.time()
    script = f'''
import sys, time
task = {task!r}
try:
    from transformers import pipeline
    m = {{"text-generation":"gpt2","text-classification":"distilbert-base-uncased-finetuned-sst-2-english","question-answering":"deepset/roberta-base-squad2","summarization":"facebook/bart-large-cnn","translation":"Helsinki-NLP/opus-mt-en-de","fill-mask":"bert-base-uncased"}}.get(task,"gpt2")
    p = pipeline(task, model=m); t = time.time()
    if task == "question-answering": print(p(question="What is 2+2?", context="2+2 equals 4."))
    elif task == "fill-mask": print(p("Paris is the capital of [MASK]."))
    else: print(str(p("Hello world"))[:100])
    print("latency_ms", int((time.time()-t)*1000))
except Exception as e: print("err", type(e).__name__, e)
'''
    r = subprocess.run([str(PY),"-c",script], capture_output=True, text=True, timeout=300)
    return {"task": task, "wall_ms": int((time.time()-t0)*1000), "out": (r.stdout or r.stderr)[:300]}
if __name__ == "__main__":
    tasks = sys.argv[1:] or ["text-generation","text-classification","question-answering"]
    results = [bench(t) for t in tasks]
    (RUNT/"eval-results.json").write_text(json.dumps(results, indent=2))
    print(f"wrote {RUNT}/eval-results.json")
    for r in results: print(f"  {r['task']:<24} {r['wall_ms']:>6} ms")
