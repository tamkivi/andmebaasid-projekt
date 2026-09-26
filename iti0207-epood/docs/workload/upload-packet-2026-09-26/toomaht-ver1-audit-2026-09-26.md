# ITI0207 töömahu audit — 26.09.2026

## Verdict
**Ready with nits** — faili sisus ega valemites blokeerivaid vigu ei leitud; salvestatud valemitulemused puuduvad.

## Identity & template structure
- Leht `ITI0207`; `X24=Gustav`, `X25=Tamkivi`, `X26=253787IAIB`.
- Failinimi `Tamkivi_ITI0207_toomaht_2026_ver1.xlsx` vastab nõutud mustrile; varukoopia on eraldi tähistatud.
- Developer-kaustas malli ei olnud. Võrdluseks kasutati handoff'i `E-ARTIFACTS/assignment/ITI0207_toomaht_2026.xlsx` faili.
- Malliga kattuvad tegevused `A2:A15`, nädalad `B1:Q1`, eksam `R1`, kokkuvõtteveerud `S:T`, identiteedisildid ja abirida `A33:P33`. Mõlemad lehed on 33 × 24, ühendatud lahtreid pole; lahtristiilid ning rea-/veerumõõdud kattuvad.
- Tulevaste nädalate ja eksami sisestusala `F2:R15` on tühi. Kokkuvõttevalemid on õigesti säilitatud. 2025 tekstijääke ei leitud.

## Week 1–4 totals vs expected
Tulemused arvutati sisenditest ja olemasolevatest valemitest sõltumatult; need pole Exceli vahemälust loetud väärtused.

| Nädal | Lahtrid | Oodatud min | Kontrollitud min | Tunnid | Erinevus min |
|---|---|---:|---:|---:|---:|
| 1 | B16:B17 | 240 | 240 | 4,0 | 0 |
| 2 | C16:C17 | 410 | 410 | 6,8 | 0 |
| 3 | D16:D17 | 465 | 465 | 7,8 | 0 |
| 4 | E16:E17 | 620 | 620 | 10,3 | 0 |

1. nädala tegevused vastavad ootusele. 2. nädala mitte-nullväärtused: `C2=90`, `C4=40`, `C6=75`, `C7=15`, `C12=90`, `C13=35`, `C14=60`, `C15=5`; 3. nädalal `D2=90`, `D6=90`, `D7=20`, `D12=100`, `D13=40`, `D14=120`, `D15=5`. Praktikumid `B3:E3=0`; 4. nädala loeng `E2=0`. 4. nädala sisendid vastavad ootusele, lisaks on `E7=10` min vahetestiks harjutamist.

## Formula integrity
Kõik 115 valemit kattuvad malliga, sealhulgas `B16:T16`, `B17:R19`, `S2:T15`, `B27:B28` ja `B33:P33`. Valemeid pole arvudega asendatud; vealahtrid ja `#REF!` puuduvad. Kõik valemid kontrolliti sõltumatu arvutusega.

`B18:E18` kumulatiivsed minutid: **240; 650; 1115; 1735**. `B19:E19` tunnid: **4,0; 10,8; 18,6; 28,9**. `S16=1735` min. Malli `T16=SUM(T2:T15)` annab **29,1 h**, sest liidab tegevuste kaupa ümardatud tunnid; `E19=28,9 h` liidab nädalate ümardatud tunnid. Erinevus tuleneb mallist. Ka `R19` täistundideks ümardamine vastab mallile.

## Diff vs pre-bump backup
Ainus lahtrisisu erinevus: **`E14: 210 → 450` min (+240)**. Valemid ja stiilid on samad. Sellest tulenevalt suureneb 4. nädala summa 380 → 620 min ning kogusumma 1495 → 1735 min. Tahtlik muudatus on korrektne.

## Issues
- **blocker:** puuduvad.
- **nit:** `data_only=True` lugemisel puuduvad kõigi 115 valemi salvestatud tulemused. `fullCalcOnLoad=True` on seatud; Excel peaks avamisel ümber arvutama. Exceli tegelikku ümberarvutust selles auditis ei kontrollitud.
- **info:** kontrollnimekirja 4. nädala tegevuste lühikirjeldusest puudub `E7=10`; olemasolev kirje selgitab 620 minuti kogusumma ja oli ka varukoopias.
- **info:** `T16` ja `E19` erinevus on malli ümardusloogika, mitte rikutud valem.

## Upload readiness
Fail on esimese vahearuande jaoks valmis ülaltoodud märkusega. Enne üleslaadimist tuleb kinnitada õige Mauruse **ver1** pesa avatus; selle praegust olekut ei kontrollitud.

Exceli faile ei muudetud (SHA-256 enne/pärast kattus). Loodi ainult see raport. Maurust, Moodle'it ega Discordi ei kasutatud; üleslaadimist, git commit'i ega push'i ei tehtud.
