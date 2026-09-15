// hybrids domain

@id("hybrids.op.compose")
permit (principal, action == Action::"compose", resource)
when { context.domain == "hybrids" };

@id("hybrids.op.evaluate")
permit (principal, action == Action::"evaluate", resource)
when { context.domain == "hybrids" };
