#!/usr/bin/env python3
import sys
TEXT = "INVOICE  Total  42.00"
BOXES = [[0,0,60,12],[0,0,0,0],[200,0,240,12]]
def main():
    try:
        from transformers import AutoTokenizer
    except Exception as e:
        print(f"  note  transformers unavailable: {e}"); return 0
    try:
        tok = AutoTokenizer.from_pretrained("microsoft/layoutlm-base-uncased")
    except Exception as e:
        print(f"  note  model not cached: {e}"); return 0
    enc = tok(TEXT, boxes=BOXES, return_tensors="pt", truncation=True)
    print(f"  ok    LayoutLM tokenized: input_ids={enc['input_ids'].shape}")
    return 0
if __name__ == "__main__": sys.exit(main())
