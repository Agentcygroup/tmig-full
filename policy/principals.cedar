// The three principals that act in this system.
// Nothing else may hold a Principal:: entity.
@id("policy.principal.kernel")
permit (
    principal == Principal::"kernel",
    action,
    resource
)
when { context.principal == "kernel" };

@id("policy.principal.reconcile")
permit (
    principal == Principal::"reconcile",
    action,
    resource
)
when { context.principal == "reconcile" };

@id("policy.principal.xt")
permit (
    principal == Principal::"xt",
    action,
    resource
)
when { context.principal == "xt" };

// Any other principal is denied outright.
@id("policy.principal.unknown")
forbid (
    principal,
    action,
    resource
)
when {
    principal != Principal::"kernel" &&
    principal != Principal::"reconcile" &&
    principal != Principal::"xt"
};
