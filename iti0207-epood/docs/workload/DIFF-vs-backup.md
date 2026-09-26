# Võrdlus 21.09 täitmise varukoopiaga

Varukoopia: `Tamkivi_ITI0207_toomaht_2026_ver1_backup_2026-09-21-fill.xlsx`.

**Ainus sisendi või valemiteksti erinevus: `ITI0207!E14`, 210 → 450 min (+240).** Ülejäänud sisendid ja kõik 115 valemit on samad. `E7=10` oli juba varukoopias.

| Tuletatud tulemus | Enne | Nüüd |
|---|---:|---:|
| E16, 4. nädala minutid | 380 | 620 |
| E17, 4. nädala tunnid | 6,3 | 10,3 |
| S14, projekti minutid | 430 | 670 |
| T14, projekti tunnid | 7,2 | 11,2 |
| E18:R18 ja S16, kumulatiivsed/kokku minutid | 1495 | 1735 |
| E19:Q19, kumulatiivsed nädalatunnid | 24,9 | 28,9 |
| T16, ümardatud tegevustunnid kokku | 25,1 | 29,1 |
| R19, täistundideks ümardatud kokkuvõte | 25 | 29 |
| B27, erinevus 156 tunnist | −130,9 | −126,9 |
| B28, tegelik töömaht EAP-des | 1,0 | 1,1 |

Abirea `N33=T14` ja `P33=T16` väärtused muutuvad vastavalt. Muud abirea tulemused ei muutu.

Lisaks on lõppfailis nüüd **115 arvutatud valemitulemust vahemälus**, mida varukoopias polnud. Seetõttu pole failid bait-baidilt samad ka valemitulemuste osas. See pole sisendite ega valemite muudatus.

- Varukoopia SHA-256: `8b06cf872d981cb223cf7af3e98f6610fabd3a8ecfd2b7b64d2b958dcd8632fe`.
- Lõppfaili SHA-256: `95c687f5e623633b89c70902969931e0cb1f5db8115c09d0c548dae6925703fe`.

Varasemad tulemused arvutati varukoopia sisenditest samade mallivalemitega; need ei pärine varukoopia puuduvast vahemälust.
