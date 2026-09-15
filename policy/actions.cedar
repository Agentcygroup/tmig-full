// Six actions. Nothing else is part of the system.
@id("policy.action.read")
permit (principal, action == Action::"read",    resource);
@id("policy.action.write")
permit (principal, action == Action::"write",   resource);
@id("policy.action.exec")
permit (principal, action == Action::"exec",    resource);
@id("policy.action.release")
permit (principal, action == Action::"release", resource);
@id("policy.action.sign")
permit (principal, action == Action::"sign",    resource);
@id("policy.action.push")
permit (principal, action == Action::"push",    resource);
