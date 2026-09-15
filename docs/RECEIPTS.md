# Receipts

Every Op that runs writes a `Receipt` — op name, input ids, output ids,
Cedar decision, timestamp, SHA-256 hash over the canonical JSON.

Receipts live in:

- `receipts/freeze/*.json` — from the freeze rewriter
- `infra/receipts/*.json` — from the reconciler
- `lifecycle/*.log` — from healthcheck and ongoing cycles

Verify: `Receipt::verify()` recomputes the hash and compares. Tampered
receipts fail verification.
