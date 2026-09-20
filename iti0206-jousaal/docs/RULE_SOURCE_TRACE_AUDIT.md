# Rule Source Trace Audit

## 1. Executive summary

This audit traces the reported validation rules against the files under `instruction_guides/`, including the standalone checklist files, `Koond.txt`, the project template, the sample project PDF text, the assignment PDF text, and the pattern guide PDF text.

Scope note: the earlier audit response itself is not stored as a repository file, so this report traces the rule families that were used in the current audit discussion and the disputed/high-impact rules called out by the user. When a rule is verbatim in a checklist `.txt` file, it is classified as explicit even if the broader course PDFs only imply it.

Traced rule groups: 32.

Classification counts:

- Explicit: 24
- Strongly implied: 3
- Weakly implied / heuristic: 3
- Not found: 0
- Contradicted / questionable: 2

Highest-risk rules to trust without professor/TA confirmation:

- Extended report-use-case scenario step count: `Koond.txt` contains an older "exactly 2" formulation, while `Laiendatud_kasutusjuhud.txt` allows 2 or more steps for report-display use cases.
- Read-only OP handling: extended use-case rules require OP references for data reads, while the template requires written contracts only for add/update/delete operations and the pattern guide says read contracts may be omitted.
- Exact 1:1 matching between high-level and extended use cases: explicit in `Koond.txt`, but not clearly stated in the template or PDFs.
- General heading-content and title-page email checks: explicit in `Koond.txt`, but weakly supported outside that checklist.
- Several exact diagram-to-text matching rules: explicit in `Koond.txt`, but only partly supported by template/example material.

## 2. Evidence classification legend

- Explicit - the guide directly states the rule or requirement.
- Strongly implied - the guide does not state it as a rule, but examples/templates/checklists clearly require it.
- Weakly implied / heuristic - the rule may be a reasonable modeling convention, but the guide does not clearly require it.
- Not found - no supporting evidence was found in the provided instruction guides.
- Contradicted / questionable - the instruction guides seem to allow or suggest something different.

## 3. Rule-by-rule source trace

### Reegel: Kohahoidja tekst / kohahoidja tähed

Current audit claim: The audit used placeholder-text and placeholder-letter rules to flag leftover template markers such as `<täienda...>`, `X`, or `Y`.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 137-141: "Kohahoidja tähed sisukorras" and "Kohahoidja tähed tekstis".
- `instruction_guides/Yldvaade.txt`, lines 142-146: exact rule for `<täienda...>` and X/Y placeholder letters in text.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc` extracted text, lines 268 and 325: the template itself contains headings such as `X funktsionaalse allsüsteemi...` and `X registri...`, showing the placeholders are meant to be replaced.

Reasoning: The checklist explicitly says these exact placeholders are reportable if left in the submitted document. The template confirms X is a placeholder convention.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Tiitelleht - nimi / email

Current audit claim: The audit used title-page rules to flag missing author identity information.

Source classification: Explicit for the rule text, weakly implied outside `Koond.txt`.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 156-160: title page must include at least one author's name and email.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc` extracted text, lines 165-170: author declaration contains `[Autorite nimed]`.

Reasoning: The exact name/email rule is in `Koond.txt`. The template clearly expects author names, but the extracted template text did not show an email placeholder.

Confidence: Medium.

Action recommendation: Keep rule as mandatory if `Koond.txt` is authoritative; otherwise confirm the email requirement with professor/TA.

### Reegel: Pealkirjade vaheline sisu

Current audit claim: The audit flagged adjacent headings with no intervening ordinary content.

Source classification: Explicit in `Koond.txt`; weakly implied elsewhere.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 162-169: the rule says a heading followed by another heading at same/lower level must have text, figure, table, or list between them.

Reasoning: This is directly stated in the consolidated checklist. I did not find an equivalent requirement in the project template or PDFs.

Confidence: Medium.

Action recommendation: Keep rule but mark as implied if using only course template/PDFs; keep mandatory if `Koond.txt` is authoritative.

### Reegel: Allsüsteemide/registrite nimede konsistentsus - vorm ja olemasolu

Current audit claim: The audit flagged subsystem/register names used in headings, captions, or text with forms not matching the master lists, or names not present in those lists.

Source classification: Explicit in `Koond.txt`; weakly implied outside it.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 143-154: exact rules for subsystem/register name form consistency and existence.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc` extracted text, lines 254-264: template has paired lists of "Funktsionaalne allsüsteem" and "Register, mida see funktsionaalne allsüsteem teenindab".

Reasoning: The exact checking rule is in `Koond.txt`. The template implies there should be controlled subsystem/register lists, but not the full text/caption consistency rule.

Confidence: Medium.

Action recommendation: Keep rule but mark as checklist-derived.

### Reegel: Organisatsiooni eesmärgid

Current audit claim: The audit flagged organization goals that described the information system instead of the organization's business/strategic goals.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 12-13: organization goals must not describe the created information system's functionality or goals.
- `instruction_guides/Koond.txt`, line 190: same rule in the consolidated checklist.

Reasoning: The rule is direct and unambiguous.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Lausendi struktuur / lausendi kordused

Current audit claim: The audit flagged non-simple sentences and repeated identical sentences in the "Lausendid" section.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 15-19: sentences in "Lausendid" must be simple sentences and duplicate sentences are reportable.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 70-73: describes CRUD-style activities around core data, supporting the idea that statements are used to connect data and processes, but not the simple-sentence rule itself.

Reasoning: The detailed syntax rule is checklist-specific but explicit.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Põhiobjekt "Klassifikaator"

Current audit claim: The audit treated missing `Klassifikaator` in the põhiobjektide list as a violation and treated related Klassifikaator-dependent rules conditionally.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 47-48: "Põhiobjekt Klassifikaator" is violated if the põhiobjektide list does not contain `Klassifikaator`.
- `instruction_guides/Koond.txt`, lines 202-203: same rule in the consolidated checklist.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 177-183: "Klassifikaator on üks põhiolemitüüp".
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 291, 425, 516, 1553, and 1726: the sample project includes `Klassifikaator`, `Klassifikaatorite haldur`, `Klassifikaatorite funktsionaalne allsüsteem`, `Klassifikaatorite register`, and a `Klassifikaator` entity.

Reasoning: This is not merely an example. The standalone general-view checklist directly requires it, and the pattern guide says Klassifikaator is a main entity type.

Confidence: High.

Action recommendation: Keep rule as mandatory. Related rules whose precondition is "Klassifikaator is in põhiobjektide list" should only be reported when that precondition is actually satisfied.

### Reegel: Põhiobjektide vorm, detailitase, kordused, andmed/data, and domain dependency rules

Current audit claim: The audit flagged plural põhiobjekt names, too-specific roles/classifiers, duplicate objects, names containing "andmed", and missing related concepts such as `Tellimus`, `Pilet`, or `Broneering`.

Source classification: Explicit in the checklist; some dependency rules are heuristic outside the checklist.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 44-69: rules for singular põhiobjekt names, `Klassifikaator`, "andmed/data", domain dependency rules, detail level, and duplicates.
- `instruction_guides/Koond.txt`, lines 199-223: same expanded rules.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 75-91: defines what a põhiolemitüüp is and why it must be tied to domain data and lifecycle.

Reasoning: Basic form/detail rules are explicit. Domain-specific dependency rules are also explicit in the checklist, but look heuristic if the checklist is not considered authoritative.

Confidence: Medium-high.

Action recommendation: Keep form/detail rules as mandatory. Treat domain dependency rules as mandatory only if the checklist is accepted as grading policy.

### Reegel: Halduri nime vorming / mitmesõnalise põhiobjekti halduri vorming

Current audit claim: The audit flagged actor names like `<singular object> haldur` where plural genitive object naming is expected.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 73-80: actor names that manage põhiobjektid must be in "[põhiobjekti mitmuse omastav] haldur" form, with a special rule for adjective+noun objects.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 425 and 989: sample uses `Klassifikaatorite haldur`.

Reasoning: The naming rule is direct, and the sample follows it.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Töötaja/Klassifikaator põhiobjekt => corresponding haldur actor

Current audit claim: The audit flagged missing `Töötajate haldur` or `Klassifikaatorite haldur` when the corresponding põhiobjekt exists.

Source classification: Explicit for the conditional rule; strongly implied by sample.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 88-92: `Töötaja` requires `Töötajate haldur`/`Personalihaldur`/`Personalitöötaja`; `Klassifikaator` requires `Klassifikaatorite haldur`.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 425 and 463: sample includes `Klassifikaatorite haldur` and its pädevusala.

Reasoning: The rule is conditional. It must not be reported if the precondition is not met, except the separate mandatory `Klassifikaator` missing rule.

Confidence: High.

Action recommendation: Keep rule as mandatory, but enforce preconditions strictly.

### Reegel: Müük/Teenus => Pank/Maksekeskus

Current audit claim: The audit flagged missing `Pank` or `Maksekeskus` actor when the organization sells goods or provides paid services.

Source classification: Explicit in checklist; weakly implied / heuristic outside it.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 85-86: explicit conditional rule for sales/services requiring `Pank` or `Maksekeskus`.

Reasoning: The exact rule is in the checklist. I did not find corresponding support in template, sample project, assignment PDF, or pattern guide.

Confidence: Medium.

Action recommendation: Keep rule but mark as checklist-derived; needs professor/TA clarification if it would cause major model changes.

### Reegel: Nimetuste kontseptsioonid

Current audit claim: The audit flagged names that combine multiple concepts using "ja" or similar conjunctions.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 21-22: names of põhiobjektid, tegutsejad, functional subsystems, or registers must not combine multiple concepts using `ja`.
- `instruction_guides/Koond.txt`, lines 250-251: same consolidated rule.

Reasoning: Directly stated.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Põhiobjekt <=> allsüsteem/register 1:1, naming form, and name-stem match

Current audit claim: The audit flagged missing/mismatched functional subsystems and registers for põhiobjektid and mismatched name stems between subsystem and register names.

Source classification: Explicit, with strong PDF/template support.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 99-117: subsystem/register name formats, stem match, and 1:1 subsystem-register relation.
- `instruction_guides/Yldvaade.txt`, lines 134-135: each põhiobjekt must map exactly to one subsystem and one register; every subsystem/register must map to one põhiobjekt.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 177-181: each põhiolemitüüp has a separate register in the information-system business architecture; classifiers belong in a classifier register.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 254-264: template pairs each functional subsystem with the register it services.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 480-520: sample lists matching pairs such as `Töötajate funktsionaalne allsüsteem` / `Töötajate register`.

Reasoning: The exact 1:1 and naming rules are explicit in `Yldvaade.txt`; course materials reinforce the pattern.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Põhiobjekt/tegutseja links to goals, lausendid, and põhiprotsessid

Current audit claim: The audit flagged põhiobjektid or tegutsejad not mentioned in goals, statements, or process descriptions.

Source classification: Explicit in checklist; weakly implied by pattern material.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 119-138: links organization goals, information-system goals, lausendid, põhiprotsessid, and tegutseja/pädevusala correspondence.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 70-73 and 75-91: core entity types support system activities and subsystem decomposition.

Reasoning: The exact cross-reference checks are checklist rules. The pattern guide supports the general modeling idea but not every exact mention requirement.

Confidence: Medium-high.

Action recommendation: Keep rule but mark cross-mention checks as checklist-derived.

### Reegel: Tegutseja <=> pädevusala seos

Current audit claim: The audit flagged actors without exactly one matching pädevusala and pädevusalad without exactly one matching actor.

Source classification: Explicit in checklist; strongly implied by template.

Supporting source(s):

- `instruction_guides/Yldvaade.txt`, lines 137-138: exact 1:1 actor/pädevusala rule.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 241 and 248-251: template separately asks for actors and internal/external pädevusalad.

Reasoning: The exact 1:1 wording is in the checklist. The template expects both lists but does not state exact 1:1 matching.

Confidence: Medium-high.

Action recommendation: Keep rule but mark as checklist-derived.

### Reegel: Kõrgtaseme kasutusjuhtude structure, active naming, specificity, grammar, and description length

Current audit claim: The audit flagged high-level use cases missing labels, using noun/passive names, overly generic names, grammar errors, or descriptions outside 1-6 sentences.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Lyhidad_kasutusjuhud.txt`, lines 31-38: examples demonstrate `Kasutusjuht:`, `Tegutsejad:`, `Kirjeldus:` and the structure rule requires those labels.
- `instruction_guides/Lyhidad_kasutusjuhud.txt`, lines 41-54: specificity, active voice, grammar, and description length rules.

Reasoning: These are direct checklist rules and also supported by the examples at the top of the file.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Kõrgtaseme OP/UI/physical-action bans and actor consistency/existence

Current audit claim: The audit flagged OP references in high-level descriptions, UI details, physical-world actions, inconsistent actor names, and actors not in the general actor/pädevusala lists.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Lyhidad_kasutusjuhud.txt`, lines 56-70: OP reference ban, UI detail ban, physical-world action ban, actor consistency, and actor existence in pädevusalad/general actor list.
- `instruction_guides/Lyhidad_kasutusjuhud.txt`, lines 72-78: specific state-changing use cases, `halda`/`manage` ban, and one-põhiobjekt focus.

Reasoning: Direct checklist support.

Confidence: High.

Action recommendation: Keep rule as mandatory, except the one-põhiobjekt focus is partly judgment-based and should be applied conservatively.

### Reegel: Laiendatud kasutusjuhtude structure and actor/stakeholder rules

Current audit claim: The audit flagged extended use cases missing required sections, missing primary actors among stakeholders, or missing additional stakeholders.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 41-57: required extended-use-case sections and primary/additional stakeholder rules.
- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 11-29: example shows the full expected structure.

Reasoning: Direct checklist and example support.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Laiendatud stsenaariumi sammude arv

Current audit claim: The audit flagged extended scenarios with too few/many steps and, for report-display use cases, may have used a strict "exactly 2" expectation.

Source classification: Contradicted / questionable.

Supporting source(s):

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 59-63: ordinary interactive use cases must have 4-10 steps; report-display use cases violate the rule only if they have fewer than 2 steps; automatic use cases violate only if fewer than 1 step.
- `instruction_guides/Koond.txt`, lines 499-506: contains both an older stricter statement ("aruande" case violates if steps are not 2) and the newer 3-case formulation that only requires at least 2 for report-display use cases.

Reasoning: There is an internal conflict in `Koond.txt`, and the standalone extended-use-case checklist is more precise and less strict. A finding based only on "report use case is not exactly 2 steps" is unsafe.

Confidence: High for the conflict; medium for enforcement.

Action recommendation: Needs manual professor/TA clarification. Until clarified, use the standalone `Laiendatud_kasutusjuhud.txt` version.

### Reegel: Laiendatud system/subjekt steps and OP references

Current audit claim: The audit flagged missing system actions, actor-only/system-only scenarios, system data-read/write steps without OP references, and OP references placed on actor or use-case-call steps.

Source classification: Explicit, with nuanced external support.

Supporting source(s):

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 68-81: system-action and subject-action presence rules; data read/save system steps need `OPx.y`; actor steps and use-case calls must not contain OP references.
- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 21-25: example uses OP references for both display/read steps and save steps.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 350-352: extended descriptions use color to distinguish read-only and data-changing DB operations.

Reasoning: Missing OP references in read/list/display system steps are supported by the extended-use-case checklist and example. This does not automatically mean read-only operation contracts must be written.

Confidence: High for OP references in scenarios; medium for downstream contract enforcement.

Action recommendation: Keep scenario OP-reference rule as mandatory.

### Reegel: Read-only vs data-changing operation contracts

Current audit claim: The audit used rules that data-changing OP references must be written as contracts, while read-only OPs should not be written as contracts or should be treated differently.

Source classification: Contradicted / questionable.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 773-777: data-changing referenced OPs must be written; read operation is a violation if it is written as a contract.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 415-418: DB operation contracts describe preconditions/postconditions and "Tuleb kirja panna andmete lisamise/muutmise/kustutamise operatsioonid".
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 970-975: every C/R/U/D letter corresponds to an OP, but read-operation contracts may be omitted; they can also be described in contract format.

Reasoning: The project template supports writing contracts for add/update/delete operations. The pattern guide explicitly allows but does not require read-operation contracts. Therefore a hard "read contracts are forbidden" rule is not fully aligned with the PDF pattern guide.

Confidence: High.

Action recommendation: Keep data-changing OP contract requirement as mandatory. Treat read-contract prohibition as professor/TA clarification needed.

### Reegel: Laiendatud nimekirja/aruande andmete spetsifikatsioon

Current audit claim: The audit flagged list/report display steps that did not specify displayed data, showed only codes, or omitted user-understandable unique identifiers.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 83-96: list data, list data amount, unique identifier, person identifier, and report data specificity rules.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 1165-1168 and 1201-1204: sample display steps specify concrete displayed data such as names, matriculation numbers, email addresses, and comments.

Reasoning: Direct rule support and sample behavior.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Laiendatud UI details, physical actions, actor consistency, primary actor matching

Current audit claim: The audit flagged extended use cases containing specific UI elements, physical-world actions, inconsistent actor names, actors not in pädevusalad, or scenario actions that do not match the primary actor.

Source classification: Explicit, with one heuristic component.

Supporting source(s):

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 101-118: UI detail ban, physical action ban, actor consistency, primary actor in pädevusalad, and primary actor/scenario matching.

Reasoning: The rules are explicit. The "primary actor matches scenario" rule is partly judgment-based but directly stated.

Confidence: High.

Action recommendation: Keep rule as mandatory; apply scenario/actor mismatch conservatively.

### Reegel: Laiendatud ja kõrgtaseme vastavus - 1:1 and actors

Current audit claim: The audit flagged high-level use cases without same-named extended use cases, extended use cases without same-named high-level entries, and actor mismatches between corresponding use cases.

Source classification: Explicit in `Koond.txt`; weakly implied in template.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 560-564: exact 1:1 and actor correspondence rules.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 286 and 350: high-level descriptions are presented first, then extended descriptions in detailed analysis.

Reasoning: The exact same-name 1:1 requirement is only found in `Koond.txt`. The template requires both levels, but does not explicitly state exact same-name 1:1 coverage.

Confidence: Medium.

Action recommendation: Keep rule but mark as checklist-derived; needs professor/TA clarification if used as a blocker.

### Reegel: Registri eskiismudel rules

Current audit claim: The audit flagged repeated/unknown pädevusalad, subsystems, registers, duplicate or unenforceable business rules, and illogical related registries in registry sketches.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Registri_eskiismudel.txt`, lines 12-19: duplicate pädevusalad/subsystems/related registers.
- `instruction_guides/Registri_eskiismudel.txt`, lines 21-34: business-rule enforceability, duplicate business rules, and related-register logic.
- `instruction_guides/Registri_eskiismudel.txt`, lines 36-43: existence of pädevusalad, subsystems, and related registers in general lists.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 325-337: template sections for registry sketches.

Reasoning: The exact checks are directly stated and align with the template structure.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Olemitüübi definitsiooni pikkus, tautology, and classifier examples

Current audit claim: The audit flagged too-short/tautological entity definitions and classifier-like entity definitions without examples.

Source classification: Explicit in `Koond.txt`; strongly implied by sample for examples.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 588-595: entity definition length, tautology, and classifier-example rules.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 1535-1553: sample table presents entity definitions, including `Klassifikaator`.

Reasoning: Exact rule support is in `Koond.txt`; sample supports descriptive definitions but not every exact audit condition.

Confidence: Medium-high.

Action recommendation: Keep rule as mandatory if `Koond.txt` is authoritative; otherwise treat classifier examples as implied.

### Reegel: Atribuudi definitsiooni format, annotations, and examples

Current audit claim: The audit flagged attribute definitions without human-readable explanation before `{}`, without constraints inside `{}`, with undefined/unused annotations, or missing `Näiteväärtus`.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 6-9: defines `@Kohustuslik` and `@Pole_tühi`.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 15-29: examples show explanation, `{constraints}`, and `Näiteväärtus`.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 41-57: structure, separation, explanation, constraints, and annotation rules.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 80-81: `Näiteväärtus` rule.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 392-398: template's attribute table includes `Atribuudi definitsioon` and `Näiteväärtus`.

Reasoning: Direct checklist, examples, and template support.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Atribuudi implementation terms and conceptual FK-like names

Current audit claim: The audit flagged attribute definitions/names that use table/column terminology, `_id`, generated sequential IDs, primary keys, foreign keys, or another entity type's name as a FK-like attribute.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 59-78: forbidden terms `tabel`/`veerg`, `_id`, generated ID, primary key, foreign key.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 65-69: conceptual-model rule against attribute names containing another entity type's name, with exceptions.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 365-367: ERD should show exactly the entity types, attributes, and relationships whose data must be stored.

Reasoning: Direct checklist support. The template supports conceptual-vs-physical separation.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: Atribuudi semantic constraints for money, quantity, text, date/time, email, phone, personal code

Current audit claim: The audit flagged missing currency/VAT/decimal/null constraints for money, missing units/zero/negative constraints for quantities, missing target audience for comments, missing `@Pole_tühi` for text, missing date ranges, missing `@` in email constraints, missing phone allowed characters, and missing personal-code format.

Source classification: Explicit in attribute checklist; examples support email/text.

Supporting source(s):

- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 83-93: money currency, VAT, decimal places, and zero/null constraints.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 95-101: quantity unit and zero/negative constraints; comment/description audience.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 104-120: text emptiness, date/time range, email `@`, phone allowed characters, and personal-code format.
- `instruction_guides/Atribuutide_definitsioonid.txt`, lines 25-29: email example requires at least one `@` and gives example value.

Reasoning: Direct checklist support. Some constraints may be best-practice-like but are explicitly stated in the course checklist file.

Confidence: High.

Action recommendation: Keep rule as mandatory if the attribute checklist is authoritative.

### Reegel: Operatsiooni lepingu structure, parameters, postconditions, and DB-only effects

Current audit claim: The audit flagged operation contracts missing sections, missing postconditions, read-only postconditions, bad parameter names, unused parameters, unknown postcondition sources, unused precondition variables, ID value assignment, external effects, duplicate conditions, wrong assignment operators, FK/relationship duplication, and SQL time functions.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/AB_op_lepingud.txt`, lines 54-64: required contract structure, postconditions, and data-changing postconditions.
- `instruction_guides/AB_op_lepingud.txt`, lines 67-88: time/status parameter, `p_` prefix, parameter use, postcondition source, and precondition variable use.
- `instruction_guides/AB_op_lepingud.txt`, lines 90-112: ID assignment, external effects, duplicates, assignment operator, FK/relationship duplication, and SQL time function rules.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 415-418: operation contracts use pre/postconditions and should cover add/update/delete operations referenced in extended use cases.

Reasoning: Direct rule support and template support.

Confidence: High.

Action recommendation: Keep rule as mandatory, with read-only contract nuance handled separately.

### Reegel: Operation references to use cases, entity types, and attributes

Current audit claim: The audit flagged operation contracts that reference undefined use cases, whose "Kasutus kasutusjuhtude poolt" does not match actual scenario references, or that mention undefined entity types/attributes.

Source classification: Explicit.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 779-789: exact rules for use-case reference correctness, use-case correspondence, entity type existence, and attribute existence.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 415-418: operation contracts refer to conceptual data model elements and data-changing operations referenced in extended use cases.

Reasoning: Direct checklist support; template supports consistency with conceptual data model and use cases.

Confidence: High.

Action recommendation: Keep rule as mandatory.

### Reegel: CRUD matrix orientation, symbols, summary, and completeness

Current audit claim: The audit flagged CRUD matrix columns/rows not matching use cases/entity types, invalid symbols such as `-` or `/`, missing summary column, empty rows/columns, wrong row summary, rows with only C/U/D, or actor/pädevusala dimensions.

Source classification: Explicit in `Koond.txt`; strongly implied by examples/pattern guide.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 810-848: exact CRUD rules for use-case columns, entity rows, allowed symbols, summary column, empty rows/columns, only-C/U/D rows, and actor/pädevusala dimensions.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 935-970: pattern guide shows use cases as columns, entity types as rows, C/R/U/D letters, and says each C/R/U/D corresponds to a DB operation.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 2024-2045: sample says the CRUD matrix is at entity/use-case precision and includes a row summary like `CRUD`.

Reasoning: The exact invalid-symbol and summary rules are checklist-explicit. The course examples strongly support row/column orientation and C/R/U/D notation.

Confidence: High for orientation and symbols if `Koond.txt` is authoritative; medium for summary column if relying only on PDFs/examples.

Action recommendation: Keep rule as mandatory, but note that summary-column strictness is checklist/example-derived.

### Reegel: Package/UC diagram content, actors, include, and extends

Current audit claim: The audit flagged package diagrams lacking expected elements/links, actor mismatches, UC names/actors not matching text, include links absent from scenario text, or extends links without extension points.

Source classification: Explicit in `Koond.txt`; weakly implied by template/PDFs.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 871-887: package diagram content and existence rules for actors, registries, and subsystems.
- `instruction_guides/Koond.txt`, lines 889-901: UC diagram exact name/actor matching, include correspondence, and extends extension-point rule.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 276-286: package diagram and use-case model requirements.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 840-842: use-case text descriptions are the main content and the diagram is like a table of contents.

Reasoning: Exact matching and include/extends checks are checklist rules. The template/PDFs support consistency but do not explicitly state every exact-match rule.

Confidence: Medium.

Action recommendation: Keep as checklist-derived; use as warning if not confirmed by professor/TA.

### Reegel: ERD existence, PK/FK bans, entity/attribute matching, and cardinality vs `@Kohustuslik`

Current audit claim: The audit flagged missing ERDs per register, PK/FK notation in conceptual ERDs, entity definitions not matching ERD entities, attribute definitions not matching ERD attributes, and cardinality/mandatory mismatches.

Source classification: Explicit in `Koond.txt`; strongly implied by template/sample for core ERD requirements.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 903-934: ERD per register, PK/FK bans, ERD entity-definition matching, ERD attribute-definition matching, and cardinality vs `@Kohustuslik`.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 365-370 and 375-398: ERDs must include all stored entity types/attributes/relationships; template has entity and attribute definition tables.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 1473-1535: sample presents multiple registry ERDs and says the entity-definition table describes ERD entity types.

Reasoning: Exact cross-checks and PK/FK bans are checklist-explicit. Template/sample strongly support ERD-definition consistency.

Confidence: High if `Koond.txt` is authoritative; medium-high from template/sample alone.

Action recommendation: Keep rule as mandatory; exact cardinality checks are checklist-derived.

### Reegel: State diagrams and OP references

Current audit claim: The audit flagged missing OP references on state transitions or inappropriate state-diagram constructs.

Source classification: Explicit, with strong pattern-guide support for OP references.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 939-945: placeholder-event, decision-point, and OP-reference rules for state diagrams.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 213-217: every state transition corresponds to a database operation described in contract format.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 505-510: sample explanation says OP1-OP5 are short identifiers of DB operation contracts shown on the state diagram.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 426-429: template requires a registry primary object's UML state diagram.

Reasoning: OP references on transitions have both checklist and pattern-guide support. The decision-point ban is checklist-explicit but not separately found in PDFs.

Confidence: High for OP references; medium for decision-point ban outside checklist.

Action recommendation: Keep OP-reference rule as mandatory; keep decision-point ban as checklist-derived.

### Reegel: DB design diagram existence

Current audit claim: The audit flagged missing physical database design diagrams for registers/subsystems.

Source classification: Explicit in `Koond.txt`; strongly implied by template/sample.

Supporting source(s):

- `instruction_guides/Koond.txt`, lines 948-949: DB design diagram existence rule.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 431-435: template has physical design section for registers needed by a functional subsystem.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, line 2142: sample has "Klassifikaatorite registri füüsilise disaini andmebaasi diagramm".

Reasoning: Direct checklist rule plus template/sample support.

Confidence: High.

Action recommendation: Keep rule as mandatory if physical design is in scope.

## 4. Special checks required

### 4.1 Klassifikaator as required põhiobjekt

Is `Klassifikaator` explicitly required in the põhiobjektide list?

Yes. `instruction_guides/Yldvaade.txt`, lines 47-48 directly states that the rule is violated if the põhiobjektide list does not contain `Klassifikaator`.

Is it required only in the conceptual model?

No. The checklist specifically requires it in the põhiobjektide list. Separately, the pattern guide also states that `Klassifikaator` is a põhiolemitüüp: `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 177-183.

Is it shown only as an example?

No. It appears in examples, but there is also direct rule text. The sample project includes `Klassifikaator` in the general-view object list and conceptual model (`instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 291, 1553, and 1726).

Does the guide require a `Klassifikaatorite haldur` actor?

Conditionally yes. `instruction_guides/Yldvaade.txt`, lines 91-92 says if the põhiobjektide list contains `Klassifikaator`, the actors must include `Klassifikaatorite haldur`. Since `Klassifikaator` is itself required by line 47, the actor is effectively required unless the professor treats the condition separately.

Recommendation: Keep `Põhiobjekt Klassifikaator` as mandatory. Do not report Klassifikaator-dependent rules under a contradictory premise; first resolve whether the submitted document's põhiobjekt list contains `Klassifikaator`.

### 4.2 1:1 mapping between põhiobjekt, functional subsystem, and register

Exact support:

- `instruction_guides/Yldvaade.txt`, lines 99-117: subsystem/register naming and 1:1 subsystem-register relationship.
- `instruction_guides/Yldvaade.txt`, lines 134-135: each põhiobjekt maps exactly to one subsystem and one register, and each subsystem/register maps to one põhiobjekt.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 177-181: each põhiolemitüüp corresponds to a separate register in the information-system business architecture.
- `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 480-520: sample shows parallel subsystem/register names.

Classification: Explicit for the checklist, strongly implied by template/sample.

Recommendation: Keep as mandatory.

### 4.3 Use case high-level vs extended 1:1 matching

Exact support:

- `instruction_guides/Koond.txt`, lines 560-564: exact same-name 1:1 matching and actor matching.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, lines 286 and 350: high-level descriptions are required in one section and extended descriptions in detailed analysis.

Classification: Explicit in `Koond.txt`, weakly implied by template.

Recommendation: Keep rule but mark as checklist-derived; use as a blocker only if `Koond.txt` is accepted as authoritative.

### 4.4 OP references in extended use cases

Exact support:

- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 74-75: system data read/save steps require OP references.
- `instruction_guides/Laiendatud_kasutusjuhud.txt`, lines 21-25: example uses OP references on read/display and save steps.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, line 352: distinguishes read-only and data-changing OP references in extended use cases.
- `instruction_guides/AB_projekt_Nullist_tegemiseks_2026.doc (textutil extract)`, line 418: written contracts are required for add/update/delete operations referenced in extended use cases.
- `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 970-975: read operations may be omitted from written contracts, but may also be described.

Classification: OP references in scenarios are explicit. Hard prohibition on written read contracts is contradicted/questionable.

Recommendation: Keep missing OP references in system read/write steps as mandatory. Treat read-contract prohibition as needing professor/TA clarification.

### 4.5 Attribute definition format

Exact support:

- Human-readable explanation before `{}`: `instruction_guides/Atribuutide_definitsioonid.txt`, lines 41-48.
- Constraints inside `{}`: lines 41-50.
- Required `Näiteväärtus`: lines 80-81 and template lines 392-398.
- `@Pole_tühi`: lines 8-9 and 104-105.
- Email requiring `@`: lines 25-29 and 113-114.
- Date/time range: lines 107-111.
- Quantity unit and zero/negative constraints: lines 95-99.
- Money currency/VAT/decimal/null constraints: lines 83-93.

Classification: Explicit.

Recommendation: Keep as mandatory.

### 4.6 CRUD matrix orientation and symbols

Exact support:

- Entity types as rows and use cases as columns: `instruction_guides/Koond.txt`, lines 810-814; examples in `instruction_guides/Projekti_mustripohine_juhend_1_52.pdf (extracted text)`, lines 935-960 and `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 2024-2045.
- Summary column: `instruction_guides/Koond.txt`, lines 822-829; sample `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, line 2045 shows row summary `CRUD`.
- Allowed values only C/R/U/D combinations: `instruction_guides/Koond.txt`, lines 816-817.
- `-` forbidden: implied by the allowed-values rule, because `-` is not C/R/U/D.
- `C/U` forbidden vs `CU` expected: implied by the allowed-values rule, because `/` is not an allowed symbol.

Classification: Explicit in `Koond.txt`; strongly implied by examples for orientation and summary.

Recommendation: Keep as mandatory if `Koond.txt` is authoritative.

### 4.7 Diagram-to-text exact matching

Exact support:

- UC diagram names and actors must match text: `instruction_guides/Koond.txt`, lines 889-893.
- Include/extends consistency: `instruction_guides/Koond.txt`, lines 895-901.
- ERD entity names and attributes must match definitions: `instruction_guides/Koond.txt`, lines 915-928.
- ERD cardinality and `@Kohustuslik`: `instruction_guides/Koond.txt`, lines 930-934.
- State transitions must include OP references: `instruction_guides/Koond.txt`, lines 945-946; strongly supported by pattern guide lines 213-217.
- Separate ERD per register: `instruction_guides/Koond.txt`, lines 903-904; sample has separate ERD figures per register at `instruction_guides/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf (extracted text)`, lines 1488-1531.
- Separate physical DB design diagram: `instruction_guides/Koond.txt`, lines 948-949; template lines 431-435 and sample line 2142 support physical design diagrams.

Classification: Explicit in `Koond.txt`; mixed strong/weak support outside it.

Recommendation: Keep as checklist-derived. Exact textual matching should be used carefully when diagram text extraction is poor.

## 5. Summary table

| Rule name | Classification | Best source | Confidence | Recommendation |
|---|---|---|---|---|
| Kohahoidja tekst/tähed | Explicit | `Koond.txt:137-141`, `Yldvaade.txt:142-146` | High | Keep rule as mandatory |
| Tiitelleht - nimi/email | Explicit / weak outside checklist | `Koond.txt:156-160` | Medium | Confirm email if not using `Koond.txt` |
| Pealkirjade vaheline sisu | Explicit in checklist | `Koond.txt:162-169` | Medium | Mark as checklist-derived |
| Allsüsteem/registri name consistency | Explicit in checklist | `Koond.txt:143-154` | Medium | Mark as checklist-derived |
| Organisatsiooni eesmärgid | Explicit | `Yldvaade.txt:12-13` | High | Keep mandatory |
| Lausendi struktuur/kordused | Explicit | `Yldvaade.txt:15-19` | High | Keep mandatory |
| Põhiobjekt Klassifikaator | Explicit | `Yldvaade.txt:47-48`, pattern guide lines 177-183 | High | Keep mandatory |
| Põhiobjekt form/detail/dependency | Explicit / heuristic outside checklist | `Yldvaade.txt:44-69` | Medium-high | Keep, with caution for domain dependencies |
| Halduri nime vorming | Explicit | `Yldvaade.txt:73-80` | High | Keep mandatory |
| Required Töötaja/Klassifikaator haldur | Explicit | `Yldvaade.txt:88-92` | High | Keep with strict preconditions |
| Müük/Teenus => Pank/Maksekeskus | Explicit in checklist only | `Yldvaade.txt:85-86` | Medium | Clarify if major rewrite needed |
| Nimetuste kontseptsioonid | Explicit | `Yldvaade.txt:21-22` | High | Keep mandatory |
| 1:1 põhiobjekt/allsüsteem/register | Explicit | `Yldvaade.txt:99-117`, `134-135` | High | Keep mandatory |
| Cross-links to goals/lausendid/processes | Explicit in checklist | `Yldvaade.txt:119-138` | Medium | Mark as checklist-derived |
| Tegutseja <=> pädevusala | Explicit in checklist | `Yldvaade.txt:137-138` | Medium-high | Mark as checklist-derived |
| High-level UC structure/naming/specificity | Explicit | `Lyhidad_kasutusjuhud.txt:38-54` | High | Keep mandatory |
| High-level UC bans/actor rules | Explicit | `Lyhidad_kasutusjuhud.txt:56-78` | High | Keep mandatory |
| Extended UC structure/stakeholders | Explicit | `Laiendatud_kasutusjuhud.txt:41-57` | High | Keep mandatory |
| Extended scenario step count | Contradicted/questionable | `Laiendatud_kasutusjuhud.txt:59-63`, `Koond.txt:499-506` | High | Clarify, use standalone file |
| Extended OP references | Explicit | `Laiendatud_kasutusjuhud.txt:74-81` | High | Keep mandatory |
| Read-operation contract prohibition | Contradicted/questionable | `Koond.txt:776-777`, pattern guide lines 970-975 | High | Needs clarification |
| List/report data specificity | Explicit | `Laiendatud_kasutusjuhud.txt:83-96` | High | Keep mandatory |
| Extended UI/physical/actor consistency | Explicit | `Laiendatud_kasutusjuhud.txt:101-118` | High | Keep mandatory |
| High-level vs extended 1:1 | Explicit in `Koond.txt` | `Koond.txt:560-564` | Medium | Mark as checklist-derived |
| Registry sketch rules | Explicit | `Registri_eskiismudel.txt:12-43` | High | Keep mandatory |
| Entity definition rules | Explicit in `Koond.txt` | `Koond.txt:588-595` | Medium-high | Keep if `Koond.txt` authoritative |
| Attribute format/annotations/examples | Explicit | `Atribuutide_definitsioonid.txt:41-57`, `80-81` | High | Keep mandatory |
| Attribute semantic constraints | Explicit | `Atribuutide_definitsioonid.txt:83-120` | High | Keep mandatory |
| Operation contract rules | Explicit | `AB_op_lepingud.txt:54-112` | High | Keep mandatory |
| Operation cross-reference rules | Explicit in `Koond.txt` | `Koond.txt:779-789` | High | Keep mandatory |
| CRUD matrix rules | Explicit in `Koond.txt` | `Koond.txt:810-848`, pattern guide lines 935-970 | High | Keep mandatory if `Koond.txt` authoritative |
| Diagram matching rules | Explicit in `Koond.txt` | `Koond.txt:871-949` | Medium | Mark as checklist-derived |

## 6. Rules not found or only weakly supported

No reported rule group was completely absent from the instruction corpus when the checklist files (`Koond.txt` and specialized `.txt` files) are treated as instruction guides.

Rules only weakly supported outside checklist files:

- `Pealkirjade vaheline sisu`: exact rule found only in `Koond.txt`; use as warning unless `Koond.txt` is authoritative.
- `Tiitelleht - email`: exact email requirement found only in `Koond.txt`; template shows author names but not extracted email placeholder.
- `Müük/Teenus => Pank/Maksekeskus`: exact rule found only in `Yldvaade.txt`; no supporting PDF/template hit found.
- `Laiendatud ja kõrgtaseme vastavus - 1:1`: exact same-name rule found only in `Koond.txt`; template only implies high-level and extended descriptions both exist.
- `Diagram-to-text exact matching`: exact matching rules are in `Koond.txt`; template/PDFs support consistency but not all exact checks.
- `CRUD summary column`: exact required summary column is in `Koond.txt`; examples show one, but pattern guide table did not clearly require a final summary column.

Contradicted/questionable rules:

- Extended report-use-case step count: `Koond.txt` has a stricter old rule and a newer more permissive rule; standalone `Laiendatud_kasutusjuhud.txt` supports the newer rule.
- Read-only operation contracts: `Koond.txt` says written read contracts are prohibited, but the pattern guide says they may be omitted and may also be described.

Suggested blocker/warning treatment:

- Blocker: rules explicitly stated in standalone checklists and reinforced by template/sample, such as `Klassifikaator`, subsystem/register naming, attribute format, operation contract structure, and extended OP references.
- Warning: checklist-only consistency rules where the template/PDF support is weak, such as heading content and exact high-level/extended 1:1 matching.
- Remove from blocker list unless professor confirms: strict "report use case must have exactly 2 steps" and hard prohibition on read-operation contracts.

## 7. Final recommendation

Safe to act on immediately:

- Add/repair `Klassifikaator` as a required põhiobjekt and ensure conditional `Klassifikaatorite haldur`, subsystem, register, and conceptual-model consequences are handled consistently.
- Fix subsystem/register naming and 1:1 mappings.
- Fix high-level and extended use-case structure, specificity, and OP reference omissions in system read/write steps.
- Fix attribute definition format, missing `Näiteväärtus`, missing constraints, and semantic constraints for text/date/email/phone/quantity/money/personal-code attributes.
- Fix operation contract structure and consistency with use-case references and entity/attribute definitions.
- Fix CRUD matrix orientation and invalid symbols.

Likely but not guaranteed:

- Exact diagram-to-text name matching, ERD attribute cross-checks, and cardinality vs `@Kohustuslik` checks.
- Heading-content checks.
- Actor/pädevusala exact 1:1 mapping when the project intentionally models an actor differently from a competence area.

Check with professor/TA before major rewrites:

- Whether read-only OP contracts are prohibited or merely optional.
- Whether report-display use cases must have exactly two steps or at least two steps.
- Whether `Pank`/`Maksekeskus` must be included for every paid-service project, even when payment processing is out of scope.
- Whether `Tiitelleht - email` is mandatory if the submitted template only contains author-name placeholders.

## Validation searches run

Representative searches executed against the repository and extracted PDF/template text:

- `rg -n "Klassifikaator|põhiobjekt|pohiobjekt|funktsionaalne allsüsteem|register|kasutusjuht|operatsioon|CRUD|Näiteväärtus|@Kohustuslik|@Pole_tühi|olemi-suhte|seisundidiagramm|\\bOP[0-9]" instruction_guides`
- `rg -n "Klassifikaator|põhiobjekt|funktsionaalne allsüsteem|register|CRUD maatriks|andmebaasioperatsioon|operatsioonileping|Näiteväärtus|olemi-suhte|seisundidiagramm|andmebaasi disaini" /tmp/instruction_corpus/AB_projekt_Nullist_tegemiseks_2026.doc.txt`
- `rg -n "Klassifikaator|põhiobjekt|funktsionaalne allsüsteem|CRUD|Näiteväärtus|@Kohustuslik|@Pole_tühi|olemi-suhte|seisundidiagramm|operatsioonileping|OP[0-9]" /tmp/instruction_corpus/Naidisprojekt_ITI0206_vastuvotuajad_ver6_44.pdf.txt`
- `rg -n "NB! Klassifikaator|Klassifikaator on üks|põhiolemitüüp|CRUD maatriks|Igale C, R|seisundi üleminekule" /tmp/instruction_corpus/Projekti_mustripohine_juhend_1_52.pdf.txt`
- `rg -n "põhiobjekt|põhiolemitüüp|funktsionaalne allsüsteem|register|kasutusjuht|CRUD|olemi-suhte|seisundidiagramm|andmebaasioperatsioon|operatsioonileping|Klassifikaator|Näiteväärtus" /tmp/instruction_corpus/Iseseisva_too_ylesande_pystitus_ITI0206_2026.pdf.txt`
