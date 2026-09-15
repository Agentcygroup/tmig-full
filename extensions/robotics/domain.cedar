// robotics domain

@id("robotics.op.plan")
permit (principal, action == Action::"plan", resource)
when { context.domain == "robotics" };

@id("robotics.op.act")
permit (principal, action == Action::"act", resource)
when { context.domain == "robotics" };
