// 3d domain

@id("3d.op.reconstruct")
permit (principal, action == Action::"reconstruct", resource)
when { context.domain == "3d" };

@id("3d.op.render")
permit (principal, action == Action::"render", resource)
when { context.domain == "3d" };
