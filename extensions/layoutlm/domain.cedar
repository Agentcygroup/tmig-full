@id("layoutlm.op.tokenize")
permit (principal, action == Action::"tokenize", resource)
when { context.domain == "layoutlm" };

@id("layoutlm.op.encode_box")
permit (principal, action == Action::"encode_box", resource)
when { context.domain == "layoutlm" };

@id("layoutlm.op.classify")
permit (principal, action == Action::"classify", resource)
when { context.domain == "layoutlm" };

@id("layoutlm.op.extract_kv")
permit (principal, action == Action::"extract_kv", resource)
when { context.domain == "layoutlm" };
