// @source: nist-ai-rmf-2023
// @instrument: NIST AI 100-1
// @clause: Measure 2.5 - Performance criteria documented
// @nonclaim: Interpretation only; not reviewed by NIST.
//
// Derived: any op tagged evaluated must carry documented criteria.

forbid (
    principal,
    action,
    resource
)
when {
    context has resource_tag &&
    context.resource_tag == "evaluated" &&
    (!(context has criteria) || context.criteria == "")
};
