// Egress is denied. Reads and writes are covered by the sandbox rule.
@id("policy.resource.no-egress")
forbid (
    principal,
    action,
    resource
)
when {
    context.resource_path like "http://*"  ||
    context.resource_path like "https://*" ||
    context.resource_path like "git@*"
};
