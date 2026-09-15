// embeddings domain

@id("embeddings.op.encode")
permit (principal, action == Action::"encode", resource)
when { context.domain == "embeddings" };

@id("embeddings.op.search")
permit (principal, action == Action::"search", resource)
when { context.domain == "embeddings" };
