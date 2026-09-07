# Shiren 6 terminology retranslation audit

Audit date: 2026-09-07. Source baseline: `7813974` (`fixed typos and missing colons`).

This folder documents proposed work. No game text, mechanics, save format, or ROM patch was changed by this audit.

- [Step one: item terminology](step-one-item-terminology.md): scope, affected files, source policy, and acceptance criteria.
- [Item inventory](item-terminology.csv): all 232 item-ID slots, existing names, candidate replacements, and unresolved exceptions.
- [Unidentified-name inventory](unidentified-item-names.csv): all 152 randomized appearance names, which also need terminology review.
- [Blank Scroll changes](blank-scrolls.md): current implementation, eight-character constraint, special cases, proposed changes, and tests.
- [Risk register](retranslation-risks.md): severity, evidence, mitigations, and release gates.

The two-project approach is workable:

1. **Item names and their functional dependencies:** names, category labels, Blank Scroll input/matching, `Scribe:` hints, and literal item-name references. Keep existing item behavior.
2. **Prose:** item descriptions first, then messages, tutorials, dialogue, and signs. Use Shiren 6 terminology and style, but describe SFC behavior accurately.

The missing pieces are a shared glossary, unidentified names, item-linked monster/status terminology, UI/ROM space checks, and save compatibility. They are part of these two projects rather than a mandatory third project.

Inventory results: 105 candidate mappings, 29 entries requiring a naming decision, and 98 protected slots (95 marked unused/dummy plus the target placeholder, money, and null entries). All 152 unidentified appearance names are listed separately for review.

“Every name and description from Shiren 6” needs exceptions: some SFC objects lack a direct counterpart, and similarly named items can behave differently. Candidate mappings are research leads, not a claim that the complete official English localization has been verified. Preserve SFC-specific items with a documented naming decision instead of substituting a different item.

Validation performed: source inspection, complete item/name-table inventory checks, and successful standalone assembly of the current `text.asm` with `wla-65816`. A full ROM link and emulator tests were not performed; remaining runtime questions are recorded in the linked documents.
