# /Taxonomy

One USD stage, ten tracks, five self-hosted runtimes.

## Tracks

| Track | Source | Prims |
|---|---|---|
| Languages | languages/languages.tsv | 89 |
| PianoRecord | piano-record/mapping.tsv | 91 |
| FHSS | fhss/bands.tsv | 33 |
| Constants | constants/si.tsv | 26 |
| Licenses | licenses/licenses.tsv | 83 |
| Sovereign | sovereign/*.tsv | 100 |
| Host | host/host.tsv | 19 |
| ModelTree | model-tree/tree.tsv | varies |
| Docs | (generated) | 9 |

## Reproduce

    bash ~/tmig-full/bootstrap.sh
    bash ~/tmig-full/selftest.sh

## Runtime

    8080  LLM        llama.cpp
    8081  embeddings sentence-transformers / TEI
    8082  image      diffusers
    8083  ASR        faster-whisper
    8084  vision     transformers
    8090  HTTP API   fastapi
