// llms domain

@id("llms.op.generate")
permit (principal, action == Action::"generate", resource)
when { context.domain == "llms" };

@id("llms.op.embed")
permit (principal, action == Action::"embed", resource)
when { context.domain == "llms" };
