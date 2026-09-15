// @source: coe-framework-2024
// @instrument: CETS No. 225
// @clause: Article 8 - Transparency and oversight
// @nonclaim: Interpretation only; not reviewed by the Council of Europe.
//
// Derived: any op tagged high_risk must carry a transparency_record.

forbid (
    principal,
    action,
    resource
)
when {
    context has resource_tag &&
    context.resource_tag == "high_risk" &&
    (!(context has transparency_record) || context.transparency_record == "")
};
