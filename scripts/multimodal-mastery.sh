#!/usr/bin/env bash
# Task mastery across the full HF taxonomy.
set -uo pipefail
VENV="${TMIG_VENV:-$HOME/.pi-venv}"
[ -x "$VENV/bin/python" ] || VENV="$HOME/tmig-full/venvs/hf"
PY="$VENV/bin/python"
LOG="$HOME/tmig-full/receipts/taxonomy.log"
mkdir -p "$(dirname "$LOG")"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }

TAXONOMY=$(cat <<'EOF'
audio-text-to-text|Multimodal|Qwen/Qwen2-Audio-7B-Instruct|transformers
image-text-to-text|Multimodal|llava-hf/llava-1.5-7b-hf|transformers
image-text-to-image|Multimodal|timbrooks/instruct-pix2pix|diffusers
image-text-to-video|Multimodal|ali-vilab/i2vgen-xl|diffusers
visual-question-answering|Multimodal|Salesforce/blip-vqa-base|transformers
document-question-answering|Multimodal|naver-clova-ix/donut-base-finetuned-docvqa|transformers
video-text-to-text|Multimodal|microsoft/Florence-2-large|transformers
visual-document-retrieval|Multimodal|vidore/colpali|transformers
any-to-any|Multimodal|HuggingFaceM4/idefics2-8b|transformers
depth-estimation|Computer Vision|depth-anything/Depth-Anything-V2-Small-hf|transformers
image-classification|Computer Vision|google/vit-base-patch16-224|transformers
object-detection|Computer Vision|hustvl/yolos-tiny|transformers
image-segmentation|Computer Vision|facebook/mask2former-swin-small-coco-instance|transformers
text-to-image|Computer Vision|runwayml/stable-diffusion-v1-5|diffusers
image-to-text|Computer Vision|Salesforce/blip-image-captioning-base|transformers
image-to-image|Computer Vision|timbrooks/instruct-pix2pix|diffusers
image-to-video|Computer Vision|stabilityai/stable-video-diffusion-img2vid-xt|diffusers
unconditional-image-generation|Computer Vision|google/ddpm-cifar10-32|diffusers
video-classification|Computer Vision|MCG-NJU/videomae-base-finetuned-kinetics|transformers
text-to-video|Computer Vision|damo-vilab/text-to-video-ms-1.7b|diffusers
zero-shot-image-classification|Computer Vision|openai/clip-vit-base-patch32|transformers
mask-generation|Computer Vision|facebook/sam-vit-base|transformers
zero-shot-object-detection|Computer Vision|google/owlvit-base-patch32|transformers
text-to-3d|Computer Vision|openai/shap-e|diffusers
image-to-3d|Computer Vision|ashawkey/zero123-xl-diffusers|diffusers
image-feature-extraction|Computer Vision|google/vit-base-patch16-224|transformers
keypoint-detection|Computer Vision|facebook/detr-resnet-50|transformers
video-to-video|Computer Vision|stabilityai/stable-video-diffusion-img2vid-xt|diffusers
text-classification|NLP|distilbert-base-uncased-finetuned-sst-2-english|transformers
token-classification|NLP|dslim/bert-base-NER|transformers
table-question-answering|NLP|google/tapas-base-finetuned-wtq|transformers
question-answering|NLP|deepset/roberta-base-squad2|transformers
zero-shot-classification|NLP|facebook/bart-large-mnli|transformers
translation|NLP|Helsinki-NLP/opus-mt-en-de|transformers
summarization|NLP|facebook/bart-large-cnn|transformers
feature-extraction|NLP|sentence-transformers/all-MiniLM-L6-v2|transformers
text-generation|NLP|gpt2|transformers
fill-mask|NLP|bert-base-uncased|transformers
sentence-similarity|NLP|sentence-transformers/all-MiniLM-L6-v2|sentence-transformers
text-ranking|NLP|cross-encoder/ms-marco-MiniLM-L-6-v2|sentence-transformers
text-to-speech|Audio|facebook/mms-tts-eng|transformers
text-to-audio|Audio|facebook/musicgen-small|transformers
automatic-speech-recognition|Audio|openai/whisper-large-v3|transformers
audio-to-audio|Audio|facebook/encodec_24khz|transformers
audio-classification|Audio|MIT/ast-finetuned-audioset-10-10-0.4593|transformers
voice-activity-detection|Audio|pyannote/segmentation-3.0|gated:hf_token_required
tabular-classification|Tabular|scikit-learn/random-forest|sklearn
tabular-regression|Tabular|scikit-learn/gradient-boosting|sklearn
time-series-forecasting|Tabular|amazon/chronos-t5-small|transformers
reinforcement-learning|RL|stable-baselines3/PPO|stable-baselines3
robotics|RL|lerobot/act|unsupported:not_hf_task_schema
graph-ml|Other|deepmind/graphcast|unsupported:not_hf_task_schema
EOF
)

cmd="${1:-coverage}"; shift || true

case "$cmd" in
  list)
    printf '%-38s | %-16s | %s\n' "TASK" "FAMILY" "MODEL"
    printf -- '-%.0s' {1..120}; echo
    echo "$TAXONOMY" | while IFS='|' read -r t f m p; do
      printf '%-38s | %-16s | %s\n' "$t" "$f" "$m"
    done
    ;;
  summary)
    echo "$TAXONOMY" | awk -F'|' '{c[$2]++} END {for (f in c) print c[f], f}' | sort -rn
    ;;
  install)
    log "== install deps =="
    [ -x "$PY" ] || { log "no venv at $VENV"; exit 1; }
    "$PY" -m pip install -q \
      transformers diffusers accelerate datasets \
      sentencepiece protobuf safetensors \
      torch torchvision torchaudio \
      sentence-transformers pyannote.audio \
      stable-baselines3 gymnasium torch-geometric \
      scikit-learn pandas librosa soundfile \
      timm einops ftfy imageio imageio-ffmpeg \
      2>&1 | tail -3 | tee -a "$LOG"
    log "== done =="
    ;;
  coverage)
    log "== taxonomy coverage =="
    printf '%-38s | %-16s | %-8s | %-40s | %s\n' TASK FAMILY INSTALL MODEL STATUS
    printf '%.0s-' {1..130}; echo
    echo "$TAXONOMY" | while IFS='|' read -r task family model status; do
      [ -z "$model" ] && continue
      inst="--"
      case "$family" in
        Audio|"Computer Vision"|Multimodal|NLP) mod="transformers" ;;
        Tabular) mod="sklearn" ;;
        RL)      mod="stable_baselines3" ;;
        Other)   mod="torch_geometric" ;;
        *)       mod="transformers" ;;
      esac
      "$PY" -c "import $mod" 2>/dev/null && inst="ok"
      printf '%-38s | %-16s | %-8s | %-40s | %s\n' \
        "$task" "$family" "$inst" "$model" "${status:-ok}"
    done
    ;;
  run)
    task="${1:?usage: run <task>}"
    row=$(echo "$TAXONOMY" | awk -F'|' -v t="$task" '$1==t')
    [ -n "$row" ] || { echo "unknown task: $task" >&2; exit 1; }
    IFS='|' read -r t f m p <<< "$row"
    log "== $t ($f) → $m =="
    "$PY" - "$t" "$m" <<'PY'
import sys, numpy as np
task, model = sys.argv[1], sys.argv[2]
try:
    if task in ("text-classification","token-classification","zero-shot-classification",
                "question-answering","summarization","translation","fill-mask",
                "feature-extraction","text-generation"):
        from transformers import pipeline
        p = pipeline(task, model=model)
        if task == "question-answering":
            print(p(question="What is 2+2?", context="2+2 equals 4."))
        elif task == "zero-shot-classification":
            print(p("I love Rust", candidate_labels=["tech","food"]))
        elif task == "fill-mask":
            print(p("Paris is the capital of [MASK]."))
        else:
            print(str(p("Hello world"))[:200])
    elif task in ("image-classification","image-to-text","zero-shot-image-classification"):
        from PIL import Image
        from transformers import pipeline
        img = Image.new("RGB", (224, 224), (128, 128, 128))
        p = pipeline(task, model=model)
        print(p(img))
    elif task in ("object-detection","image-segmentation","depth-estimation",
                  "zero-shot-object-detection","mask-generation"):
        from PIL import Image
        from transformers import pipeline
        img = Image.new("RGB", (384, 384), (128, 128, 128))
        p = pipeline(task, model=model)
        print(p(img))
    elif task in ("automatic-speech-recognition","audio-classification"):
        from transformers import pipeline
        p = pipeline(task, model=model)
        print(p(np.zeros(16000, dtype=np.float32)))
    elif task == "sentence-similarity":
        from sentence_transformers import SentenceTransformer
        m2 = SentenceTransformer(model)
        v = m2.encode(["hello", "world"])
        print("shape:", v.shape)
    elif task in ("tabular-classification","tabular-regression"):
        from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
        m2 = RandomForestClassifier() if "class" in task else GradientBoostingRegressor()
        X = np.random.rand(20, 4)
        y = np.random.randint(0, 2, 20) if "class" in task else np.random.rand(20)
        m2.fit(X, y)
        print(f"trained: {m2.__class__.__name__}")
    elif task == "reinforcement-learning":
        import stable_baselines3
        print("sb3:", stable_baselines3.__version__)
    elif task == "graph-ml":
        import torch_geometric
        print("pyg:", torch_geometric.__version__)
    else:
        print(f"loaded model for {task}: {model}")
except Exception as e:
    print(f"err: {type(e).__name__}: {e}")
PY
    ;;
  pull)
    log "== pull every model =="
    HF="$VENV/bin/hf"
    [ -x "$HF" ] || { log "no hf binary"; exit 1; }
    unset HF_TOKEN HF_TOKEN_PATH 2>/dev/null || true
    echo "$TAXONOMY" | while IFS='|' read -r t f m p; do
      [ -z "$m" ] && continue
      log "  $t → $m"
      "$HF" download "$m" >>"$LOG" 2>&1 && log "    ok" || log "    skip (gated)"
    done
    ;;
  "")
    sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "usage: $0 list|summary|install|coverage|run <task>|pull" >&2
    exit 1
    ;;
esac
