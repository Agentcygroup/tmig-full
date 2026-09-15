// @source: eu-ai-act-2024
// @instrument: Regulation (EU) 2024/1689
// @clause: Article 5(1)(c) - Prohibited: social scoring
// @nonclaim: Not legal advice; not an EU conformity assessment.
//
// Derived: deny any op whose purpose or resource tag is social scoring.

forbid (
    principal,
    action,
    resource
)
when {
    context has purpose &&
    context.purpose == "social_scoring"
};

forbid (
    principal,
    action,
    resource
)
when {
    context has resource_tag &&
    context.resource_tag == "social_score"
};
