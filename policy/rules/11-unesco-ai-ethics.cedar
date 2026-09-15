// @source: unesco-ai-ethics-2021
// @instrument: UNESCO SHS/BIO/PI/2021/1
// @clause: Policy Action Area 5 - Gender
// @nonclaim: Interpretation only; not reviewed by UNESCO.
//
// Derived: deny ops that carry a gender-stereotype context marker.

forbid (
    principal,
    action,
    resource
)
when {
    context has demographic &&
    context.demographic has gender &&
    (context.demographic.gender == "stereotype_inference" ||
     context.demographic.gender == "gender_classification")
};
