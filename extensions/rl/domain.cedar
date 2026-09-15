// rl domain

@id("rl.op.step")
permit (principal, action == Action::"step", resource)
when { context.domain == "rl" };

@id("rl.op.rollout")
permit (principal, action == Action::"rollout", resource)
when { context.domain == "rl" };
