@id("kernel.entity.create")
permit (principal == Principal::"kernel", action == Action::"create", resource)
when { resource.kind != "" && resource.id != "" };

@id("kernel.entity.no-empty")
forbid (principal == Principal::"kernel", action == Action::"create", resource)
when { resource.kind == "" || resource.id == "" };

@id("kernel.op.authorize")
permit (principal == Principal::"kernel", action == Action::"invoke", resource)
when { context.decision == "allow" };

@id("kernel.op.no-policy-no-op")
forbid (principal == Principal::"kernel", action == Action::"invoke", resource)
when { context.decision != "allow" };
