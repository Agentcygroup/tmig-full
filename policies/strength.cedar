// Every layer must declare strength >= 1.
@id("strength.forbid.00")
forbid (principal, action, resource)
when { context.strength < 1 };

// ci and all must dominate the code they gate.
@id("strength.forbid.01")
forbid (principal, action, resource)
when {
    (context.layer == "ci" || context.layer == "all") &&
    context.strength < 40
};

// The policy layer itself must dominate everything it inspects.
@id("strength.forbid.02")
forbid (principal, action, resource)
when {
    context.layer == "policy" &&
    context.strength < 90
};
