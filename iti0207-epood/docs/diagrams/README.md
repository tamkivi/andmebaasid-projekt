# Ü2 registridiagrammid

Genereeritud 23.09.2026 puhtast kohalikust PostgreSQL 17 baasist iti0207_epood_u2_audit_20260923 pärast sql/01_tables_draft.sql laadimist. Viis registrit on jagatud 11 püstisesse A4 dokumenti sobivasse joonisesse.

| Tüvi | Register | Detailsed tabelid |
| --- | --- | --- |
| u2-01a-klassifikaatorid-isikuseisundid | Klassifikaatorid | isiku_seisundi_liik, tootaja_seisundi_liik, kliendi_seisundi_liik |
| u2-01b-klassifikaatorid-yldised | Klassifikaatorid | kauba_seisundi_liik, tootaja_roll, riik |
| u2-01c-klassifikaatorid-ekraan | Klassifikaatorid | diagonaal, ekraani_resolutsioon, kaamera |
| u2-01d-klassifikaatorid-tehnika | Klassifikaatorid | protsessor, sisemalu, brand |
| u2-01e-klassifikaatorid-kategooriad | Klassifikaatorid | varv, kauba_kategooria_tyyp, kauba_kategooria |
| u2-02-isikud | Isikud | isik, kasutajakonto |
| u2-03-tootajad | Töötajad | tootaja, tootaja_rolli_omamine |
| u2-04-kliendid | Kliendid | klient |
| u2-05a-kaubad | Kaubad | kaup |
| u2-05b-nutitelefon | Kaubad | nutitelefon |
| u2-05c-kauba-seosed | Kaubad | kauba_variant, kauba_kategooria_omamine |

Igal tüvel on PNG (DOCX-i paigutamiseks), PDF (vektor- ja printkontroll) ning DOT (taastatav paigutus). Omanditabeli sinine päis näitab veerge, täpseid tüüpe/pikkusi, NULL/NOT NULL-i, vaikeväärtusi ja nimelisi PK/UK/FK piiranguid. Hall nimekast on ainult otsene FK sihttabel. Iga tabeli detailid esinevad täpselt ühel joonisel. FK ridade D = ON DELETE, U = ON UPDATE.

Suurim lõplik PDF on 474×673 pt; see mahub püstisele A4 lehele (595×842 pt) tavapäraste veeristega ilma vähendamata. Iga lõplik PDF renderdati ja vaadati üle. Joonised on sisuümbrise suurusega PDF-id, mitte juba A4 mõõtu lehed.

Taastamiseks laadi SQL tühja kohalikku baasi ja käivita skript ITI0207_U2_DB keskkonnamuutujaga. Näiteks selles auditis kasutatud baasil:

    ITI0207_U2_DB=iti0207_epood_u2_audit_20260923 python3 iti0207-epood/scripts/render_u2_er_diagrams.py

Skript nõuab andmebaasi nime teadlikku valimist. Varasema iti0207_epood_u2 baasi FK tegevused ei vasta 23.09 SQL-ile; kasuta ülaltoodud auditibaasi kuni vana baasi uuesti laadimiseni. Kooli apex2 baasi jaoks see Ü2 ekspordikäsk ei ole.
