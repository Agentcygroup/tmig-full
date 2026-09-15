// Every layer carries a non-claim. Emitted as a cmd on the layer.
@id("policy.rule.nonclaims.required")
forbid (principal, action, resource)
when {
    context.layer like "schema:*" &&
    context.cmd == ""
};

// The four non-claims the freeze always emits.
@id("policy.rule.nonclaims.mastery")
forbid (principal, action, resource)
when { context.claim == "mastery" };
@id("policy.rule.nonclaims.accreditation")
forbid (principal, action, resource)
when { context.claim == "accreditation" };
@id("policy.rule.nonclaims.coherence")
forbid (principal, action, resource)
when { context.claim == "coherence-proof" };
@id("policy.rule.nonclaims.completeness")
forbid (principal, action, resource)
when { context.claim == "completeness" };
