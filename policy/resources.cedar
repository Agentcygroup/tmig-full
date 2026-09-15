// The sandbox. Anything outside is denied.
@id("policy.resource.sandbox")
permit (
    principal,
    action,
    resource
)
when {
    resource.path like "/Users/metadusa/*" ||
    resource.path like "/opt/tmig/*"     ||
    resource.path like "/tmp/tmig-*"
};

@id("policy.resource.no-egress")
forbid (
    principal,
    action,
    resource
)
when {
    resource.path like "http://*"  ||
    resource.path like "https://*" ||
    resource.path like "git@*"
};
