// segmentation domain

@id("segmentation.op.segment")
permit (principal, action == Action::"segment", resource)
when { context.domain == "segmentation" };

@id("segmentation.op.refine")
permit (principal, action == Action::"refine", resource)
when { context.domain == "segmentation" };
