// detection domain

@id("detection.op.detect")
permit (principal, action == Action::"detect", resource)
when { context.domain == "detection" };

@id("detection.op.nms")
permit (principal, action == Action::"nms", resource)
when { context.domain == "detection" };
