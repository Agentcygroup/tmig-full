// Writes must stay inside the sandbox.
@id("policy.rule.sandbox.write")
forbid (
    principal,
    action == Action::"write",
    resource
)
when {
    context.resource_path != "" &&
    !(context.resource_path like "/Users/metadusa/*" ||
      context.resource_path like "/opt/tmig/*"     ||
      context.resource_path like "/tmp/tmig-*")
};
