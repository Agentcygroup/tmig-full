// @source: iso-iec-42001-2023
// @instrument: ISO/IEC 42001:2023
// @clause: Clause 9.1 - Monitoring, measurement, analysis
// @nonclaim: Paraphrased; not reviewed by ISO. No ISO certification implied.
//
// Derived: any op tagged ongoing must carry a monitoring record.

forbid (
    principal,
    action,
    resource
)
when {
    context has resource_tag &&
    context.resource_tag == "ongoing" &&
    (!(context has monitoring_record) || context.monitoring_record == "")
};
