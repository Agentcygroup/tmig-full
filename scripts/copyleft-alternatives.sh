#!/usr/bin/env bash
# Copyleft / permissive-OSS alternatives for every HF-listed library.
# Focus: GPL/LGPL/AGPL/MPL or fully-permissive projects that avoid proprietary lock-in.
set -uo pipefail

ROOT="$HOME/tmig-full"
VENV="$ROOT/venvs/hf"
PY="$VENV/bin/python"
LOG="$ROOT/receipts/copyleft.log"
OUT="$ROOT/copyleft"
mkdir -p "$OUT" "$(dirname "$LOG")"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }

# original | license | copyleft alternative | license | category | kind
TABLE=$(cat <<'EOF'
PyTorch|BSD-3|JAX|Apache-2|tensor|pip
PyTorch|BSD-3|PaddlePaddle|Apache-2|tensor|pip
PyTorch|BSD-3|tinygrad|MIT|tensor|pip
TensorFlow|Apache-2|PaddlePaddle|Apache-2|tensor|pip
TensorFlow|Apache-2|JAX|Apache-2|tensor|pip
JAX|Apache-2|PyTorch|BSD-3|tensor|pip
JAX|Apache-2|PaddlePaddle|Apache-2|tensor|pip
Safetensors|Apache-2|NumPy .npz|BSD-3|serialization|pip
Safetensors|Apache-2|msgpack|Apache-2|serialization|pip
Transformers|Apache-2|llama.cpp|MIT|inference|brew
Transformers|Apache-2|ONNX Runtime|MIT|inference|pip
PEFT|Apache-2|LoRA (microsoft)|MIT|finetuning|pip
GGUF|MIT|safetensors|Apache-2|format|pip
GGUF|MIT|ONNX|Apache-2|format|pip
TensorBoard|Apache-2|Visdom|Apache-2|viz|pip
TensorBoard|Apache-2|Weights & Biases|MIT|viz|pip
TensorBoard|Apache-2|Aim|Apache-2|viz|pip
Diffusers|Apache-2|ComfyUI|GPL-3|generation|git
Diffusers|Apache-2|InvokeAI|Apache-2|generation|pip
ONNX|Apache-2|OpenVINO|Apache-2|runtime|pip
ONNX|Apache-2|Apache TVM|Apache-2|runtime|pip
stable-baselines3|MIT|RLlib|Apache-2|rl|pip
stable-baselines3|MIT|CleanRL|MIT|rl|pip
sentence-transformers|Apache-2|fastText|MIT|embedding|pip
sentence-transformers|Apache-2|Gensim|LGPL-2.1|embedding|pip
MLX|MIT|llama.cpp|MIT|inference|brew
MLX|MIT|OpenVINO|Apache-2|runtime|pip
ml-agents|Apache-2|PettingZoo|MIT|rl|pip
ml-agents|Apache-2|Gymnasium|MIT|rl|pip
Keras|Apache-2|scikit-learn|BSD-3|ml|pip
Keras|Apache-2|PaddlePaddle|Apache-2|ml|pip
TF-Keras|Apache-2|PaddlePaddle|Apache-2|ml|pip
Joblib|BSD-3|dask|BSD-3|parallel|pip
Joblib|BSD-3|ray|Apache-2|parallel|pip
Transformers.js|Apache-2|ONNX Runtime Web|MIT|inference|npm
Transformers.js|Apache-2|WebLLM|Apache-2|inference|npm
Adapters|Apache-2|LoRA (microsoft)|MIT|finetuning|pip
timm|Apache-2|torchvision|BSD-3|vision|pip
timm|Apache-2|Kornia|Apache-2|vision|pip
setfit|Apache-2|scikit-learn|BSD-3|fewshot|pip
OpenVINO|Apache-2|ONNX Runtime|MIT|runtime|pip
OpenVINO|Apache-2|Apache TVM|Apache-2|runtime|pip
sample-factory|MIT|RLlib|Apache-2|rl|pip
sample-factory|MIT|CleanRL|MIT|rl|pip
Core ML|BSD-3|ONNX Runtime|MIT|runtime|pip
Core ML|BSD-3|llama.cpp|MIT|inference|brew
LiteRT|Apache-2|ONNX Runtime|MIT|runtime|pip
LiteRT|Apache-2|NCNN|BSD-3|runtime|pip
NeMo|Apache-2|SpeechBrain|Apache-2|audio|pip
NeMo|Apache-2|ESPnet|Apache-2|audio|pip
Flair|MIT|spaCy|MIT|nlp|pip
Flair|MIT|Stanza|Apache-2|nlp|pip
fastai|Apache-2|scikit-learn|BSD-3|ml|pip
ESPnet|Apache-2|SpeechBrain|Apache-2|audio|pip
Rust|Apache-2/MIT|candle|Apache-2|tensor|git
Rust|Apache-2/MIT|burn|MIT|tensor|git
Scikit-learn|BSD-3|mlpack|BSD-3|ml|brew
Scikit-learn|BSD-3|Shogun|GPL-3|ml|brew
BERTopic|MIT|Gensim|LGPL-2.1|topic|pip
BERTopic|MIT|scikit-learn LDA|BSD-3|topic|pip
spaCy|MIT|Stanza|Apache-2|nlp|pip
spaCy|MIT|NLTK|Apache-2|nlp|pip
fastText|MIT|Gensim|LGPL-2.1|embedding|pip
OpenCLIP|MIT|CLIP (openai)|MIT|clip|pip
ExecuTorch|BSD-3|ONNX Runtime Mobile|MIT|runtime|pip
KerasHub|Apache-2|HuggingFace Transformers|Apache-2|hub|pip
Asteroid|MIT|SpeechBrain|Apache-2|audio|pip
speechbrain|Apache-2|ESPnet|Apache-2|audio|pip
AllenNLP|Apache-2|Stanza|Apache-2|nlp|pip
AllenNLP|Apache-2|spaCy|MIT|nlp|pip
llamafile|Apache-2|llama.cpp|MIT|inference|brew
PaddlePaddle|Apache-2|PyTorch|BSD-3|tensor|pip
PaddleOCR|Apache-2|Tesseract|Apache-2|ocr|brew
PaddleOCR|Apache-2|EasyOCR|Apache-2|ocr|pip
Fairseq|MIT|ESPnet|Apache-2|audio|pip
Fairseq|MIT|SpeechBrain|Apache-2|audio|pip
Stanza|Apache-2|spaCy|MIT|nlp|pip
pyannote.audio|MIT|SpeechBrain|Apache-2|audio|pip
Habana|Apache-2|ONNX Runtime|MIT|runtime|pip
Habana|Apache-2|OpenVINO|Apache-2|runtime|pip
SpanMarker|MIT|spaCy|MIT|nlp|pip
Graphcore|Apache-2|ONNX Runtime|MIT|runtime|pip
Graphcore|Apache-2|OpenVINO|Apache-2|runtime|pip
paddlenlp|Apache-2|spaCy|MIT|nlp|pip
paddlenlp|Apache-2|Stanza|Apache-2|nlp|pip
unity-sentis|Apache-2|ONNX Runtime|MIT|runtime|pip
unity-sentis|Apache-2|NCNN|BSD-3|runtime|pip
DDUF|Apache-2|safetensors|Apache-2|format|pip
DDUF|Apache-2|zip + numpy|BSD-3|format|pip
univa|Apache-2|Ray|Apache-2|distributed|pip
univa|Apache-2|dask|BSD-3|distributed|pip
EOF
)

cmd="${1:-map}"; shift || true

case "$cmd" in
  map)
    printf '%-22s | %-10s | %-22s | %-10s | %s\n' "ORIGINAL" "LIC" "ALTERNATIVE" "LIC" "CATEGORY"
    printf -- '-%.0s' {1..100}; echo
    echo "$TABLE" | awk -F'|' '!seen[$1"|"$3]++{printf "%-22s | %-10s | %-22s | %-10s | %s\n",$1,$2,$3,$4,$5}'
    ;;

  install)
    log "== install copyleft alternatives =="
    [ -x "$PY" ] || { log "no venv"; exit 1; }

    # pip
    for p in \
      jax jaxlib \
      tinygrad \
      onnx onnxruntime \
      openvino \
      tvm \
      transformers \
      sentence-transformers \
      gensim \
      spacy \
      stanza \
      nltk \
      flair \
      scikit-learn \
      mlpack \
      dask ray \
      gymnasium pettingzoo \
      stable-baselines3 \
      torch torchvision \
      kornia \
      easyocr \
      speechbrain espnet \
      asteroid \
      fairseq \
      hypernetx \
      umap-learn hdbscan \
      clip-anytorch \
      cleanrl \
      invokee \
      ; do
      log "  pip: $p"
      "$PY" -m pip install -q "$p" >>"$LOG" 2>&1 && log "    ok" || log "    skip"
    done

    # brew
    if command -v brew >/dev/null 2>&1; then
      for t in tesseract shogun; do
        brew list --formula "$t" >/dev/null 2>&1 && log "  ok   brew $t" || {
          log "  add  brew $t"
          brew install "$t" >>"$LOG" 2>&1 || log "    skip $t"
        }
      done
    fi

    # git-cloned
    clone() {
      local n="$1" u="$2"
      [ -d "$ROOT/copyleft/$n" ] && { log "  ok   git $n"; return; }
      log "  clone $n"
      git clone --depth 1 "$u" "$ROOT/copyleft/$n" >>"$LOG" 2>&1 || log "    skip"
    }
    clone candle      https://github.com/huggingface/candle.git
    clone burn        https://github.com/tracel-ai/burn.git
    clone CleanRL     https://github.com/vwxyzjn/cleanrl.git
    clone ComfyUI     https://github.com/comfyanonymous/ComfyUI.git
    clone InvokeAI    https://github.com/invoke-ai/InvokeAI.git

    log "== done — see $LOG =="
    ;;

  coverage)
    log "== coverage =="
    [ -x "$PY" ] || exit 1
    for mod in \
      jax torch paddle onnx onnxruntime openvino tvm \
      transformers sentence_transformers gensim spacy stanza nltk flair \
      sklearn dask ray gymnasium stable_baselines3 kornia easyocr \
      speechbrain asteroid fairseq hypernetx clip; do
      "$PY" -c "import $mod" 2>/dev/null && log "  ok   $mod" || log "  --   $mod"
    done
    ;;

  copyleft-only)
    log "== copyleft-licensed alternatives only (GPL/LGPL/AGPL/MPL) =="
    echo "$TABLE" | awk -F'|' '!seen[$3]++ && ($4 ~ /GPL|MPL|EUPL|AGPL|LGPL/){printf "%-22s | %-22s | %s\n",$1,$3,$4}'
    ;;

  permissive-only)
    log "== permissive alternatives only (MIT/Apache/BSD) =="
    echo "$TABLE" | awk -F'|' '!seen[$3]++ && ($4 ~ /MIT|Apache|BSD/){printf "%-22s | %-22s | %s\n",$1,$3,$4}'
    ;;

  "")
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  *)
    echo "unknown: $cmd" >&2; exit 1 ;;
esac
