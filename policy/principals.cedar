// Each principal carries a nonclaim; see policy/rules/04-nonclaims.cedar.
// Exactly three principals are permitted. Any other is denied.
@id("policy.principal.allow")
permit (
    principal,
    action,
    resource
)
when {
    context.principal == "kernel"    ||
    context.principal == "reconcile" ||
    context.principal == "xt"
};

@id("policy.principal.deny")
forbid (
    principal,
    action,
    resource
)
when {
    context.principal != "kernel"    &&
    context.principal != "reconcile" &&
    context.principal != "xt"
};
