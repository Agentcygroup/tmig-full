// @source: oecd-ai-principles-2019
// @instrument: OECD/LEGAL/0449
// @clause: Principle 1.5 - Accountability
// @nonclaim: Interpretation only; not reviewed by the OECD.
//
// Derived: every op that produces a receipt must name an accountable
// principal. Traceability of decisions per Principle 1.5.

permit (
    principal,
    action == Action::"produce_receipt",
    resource
)
when {
    context has principal &&
    context.principal != "" &&
    context.accountable == true
};

forbid (
    principal,
    action == Action::"produce_receipt",
    resource
)
when {
    !(context has principal) ||
    context.principal == "" ||
    context.accountable != true
};
