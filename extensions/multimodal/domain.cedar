// multimodal domain

@id("multimodal.op.fuse")
permit (principal, action == Action::"fuse", resource)
when { context.domain == "multimodal" };

@id("multimodal.op.align")
permit (principal, action == Action::"align", resource)
when { context.domain == "multimodal" };
