// File writes must stay inside the sandbox.
@id("policy.rule.sandbox.write")
forbid (
    principal,
    action == Action::"write",
    resource
)
when {
    !(resource.path like "/Users/metadusa/*" ||
      resource.path like "/opt/tmig/*"     ||
      resource.path like "/tmp/tmig-*")
};
