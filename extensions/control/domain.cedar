// control domain

@id("control.op.observe")
permit (principal, action == Action::"observe", resource)
when { context.domain == "control" };

@id("control.op.command")
permit (principal, action == Action::"command", resource)
when { context.domain == "control" };
