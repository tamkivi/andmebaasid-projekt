# Final Submission Verification Audit

Audit date: 2026-06-03.

## 1. Executive verdict

**Ready to submit after manual EAP openability check and final DOCX visual inspection.**

The build produces the required four submission files, automated validation passes, and the DBeaver physical diagram blocker is resolved by six real PNG exports in `manual_exports/dbeaver_physical/`. The remaining checks are manual because Enterprise Architect openability and final DOCX page-break/layout review cannot be fully proven by the repository scripts.

## 2. Current blocker status

| Area | Status | Result |
|---|---:|---|
| Version conflict / wrong artifact suspicion | Fixed | Root DOCX/EAP/SQL and `submission_files/` copies hash-match after build. |
| Use-case diagram notation | Fixed | Actors are outside the system boundary, use cases are inside, unsupported include/extend labels are removed, and time is not modeled as actor `Aeg`. |
| State diagram final states | Fixed | Treeningukord and registreering diagrams use named separate terminal outcome states. |
| EAP stale statechart content | Fixed in generator | The EAP post-processor replaces the old `Alg -> Ootel -> Aktiivne/Mitteaktiivne/Lõpetatud/Unustatud` statechart with current treeningukord and registreering lifecycles, and the validator now fails if stale state objects or StateFlow patterns return. |
| UML generalization misuse | Fixed | EAP validation fails classifier-related `Generalization` misuse. |
| Figure 7 conceptual/register diagram | Fixed | Conceptual diagrams avoid SQL foreign-key detail. |
| Figure 10 / Osalemine references | Fixed | The model and SQL include participant/client and trainer/employee references. |
| DBeaver PostgreSQL physical diagrams | Fixed | Six PNG exports exist in `manual_exports/dbeaver_physical/` and are embedded into the DOCX during build. |
| Prototype SQL function parity | Fixed | The Flask prototype calls current SQL function signatures. |

## 3. DBeaver export status

The following files are present and are the physical diagram source images used by the DOCX generator:

- `manual_exports/dbeaver_physical/registreeringute_register.png`
- `manual_exports/dbeaver_physical/treeningukordade_register.png`
- `manual_exports/dbeaver_physical/osalemiste_register.png`
- `manual_exports/dbeaver_physical/isikute_rollide_register.png`
- `manual_exports/dbeaver_physical/treenerite_padevuste_register.png`
- `manual_exports/dbeaver_physical/klassifikaatorite_register.png`

`docs/DBEAVER_PHYSICAL_DIAGRAM_EXPORT_CHECKLIST.md` remains useful as the re-export checklist. It is no longer evidence that the current submission is missing DBeaver diagrams.

## 4. Required validation commands

Run these before submission and keep all results passing:

```bash
bash ./build_all.sh
find . -name ".DS_Store" -print -delete
.venv/bin/python tools/validate_project.py
.venv/bin/python tests/database/run_database_validation.py
.venv/bin/python -m compileall -q tools tests rakendus
git diff --check
unzip -t submission_files/rakendus.zip
```

The validator checks the four-file submission set, root/submission artifact parity, DOCX image embedding, DBeaver image presence, EAP packages/actors/use cases/classes/connectors, and stale EAP statechart regression guards.

## 5. Remaining manual checks before submission

- Open `submission_files/mudelid.eap` in Enterprise Architect or the required viewer and confirm it is openable.
- Visually inspect `submission_files/dokument.docx`, especially page breaks, table readability, Figure 2, state diagrams, and embedded DBeaver physical diagrams.
- Confirm `submission_files/` contains exactly `dokument.docx`, `mudelid.eap`, `skript.sql`, and `rakendus.zip`.
