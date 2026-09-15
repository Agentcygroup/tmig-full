# Invariants derived from standards bodies

Each check in `scripts/tests/standards/` cites its source. The check is a
*derivation*, not a claim of conformance. A derivation says: this standard
requires X; here is a command that fails if X is absent.

| Standard | Derived invariant | Check |
|---|---|---|
| OECD AI Principles 1.5 | Traceability of decisions | `oecd-accountability.sh` |
| OECD AI Principles 1.5 | Systematic risk management | `oecd-risk.sh` |
| UNESCO AI Ethics | Ethical impact assessment present | `unesco-eia.sh` |
| CoE Framework Convention Art. 8 | Transparency and oversight record | `coe-transparency.sh` |
| NIST AI RMF GOVERN 1.1 | Legal/regulatory requirements documented | `nist-govern.sh` |
| NIST AI RMF MEASURE 2.5 | Performance criteria documented | `nist-measure.sh` |
| ISO/IEC 42001 9.1 | Monitoring, measurement, evaluation | `iso-42001-monitor.sh` |
| ISO/IEC 42001 A.7 | Transparency to users | `iso-42001-transparency.sh` |
| ISO/IEC 25010 | Product quality characteristics | `iso-25010-quality.sh` |
| IEEE 7000 | Ethical values traceable in design | `ieee-7000-values.sh` |
| IEEE 7001 | Transparency of autonomous decisions | `ieee-7001-transparency.sh` |
| IEEE 7002 | Data privacy process | `ieee-7002-privacy.sh` |
| EU AI Act Art. 5 | Prohibited practices not present | `eu-ai-act-prohibited.sh` |
| NIST SSDF PW.4 | Secure software development practices | `nist-ssdf.sh` |
| UK AI principles | Five cross-cutting principles | `uk-ai-principles.sh` |
| GDPR Art. 5 | Data protection principles | `gdpr-principles.sh` |
| WCAG 2.2 | Accessibility (POUR) | `wcag-accessibility.sh` |
| ISO 9001 | Quality management principles | `iso-9001-quality.sh` |
| ISO/IEC 29119 | Software testing standard | `iso-29119-testing.sh` |
| ISO/IEC 27001 | Information security controls | `iso-27001-security.sh` |
| ACM Code of Ethics 1.2 | Avoid harm | `acm-avoid-harm.sh` |
| ACM Code of Ethics 1.3 | Be honest and trustworthy | `acm-honesty.sh` |
| BCS Code of Conduct | Professional competence, no false claims | `bcs-competence.sh` |
| SE Code of Ethics 3 (PRODUCT) | Highest professional standards | `se-code-product.sh` |
| SE Code of Ethics 6 (PROFESSION) | Advance integrity and reputation | `se-code-profession.sh` |

## UK AI Regulation White Paper (2023) — five principles
safety, transparency, fairness, accountability, contestability.

## GDPR Art. 5 — data protection principles
lawfulness, fairness, transparency, purpose limitation, minimisation,
accuracy, storage limitation, integrity, accountability.
