// Every layer must declare strength >= 1.
@id("policy.rule.strength.floor")
forbid (principal, action, resource)
when { context.strength < 1 };

// ci and all must dominate the code they gate.
@id("policy.rule.strength.ci-all")
forbid (principal, action, resource)
when {
    (context.layer == "ci" || context.layer == "all") &&
    context.strength < 40
};

// The policy layer itself must dominate everything it inspects.
@id("policy.rule.strength.policy")
forbid (principal, action, resource)
when {
    context.layer == "policy" &&
    context.strength < 90
};
