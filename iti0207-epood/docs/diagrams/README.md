# Ü2 registridiagrammid

Genereeritud kohalikust PostgreSQL 17 andmebaasist pärast projekti SQL-i laadimist. Viis registrit on jagatud 11 püstisesse A4 dokumenti sobivasse joonisesse.

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

Igal tüvel on PNG (DOCX-i paigutamiseks), PDF (vektor- ja printkontroll) ning DOT (taastatav paigutus). Omanditabeli sinine päis näitab veerge, täpseid tüüpe/pikkusi, NULL/NOT NULL-i, vaikeväärtusi ja nimelisi PK/UK/FK/CHECK piiranguid ning eraldi loodud indekseid ja määratud salvestusparameetreid. Hall nimekast on ainult otsene FK sihttabel. Iga tabeli detailid esinevad täpselt ühel joonisel. FK ridade D = ON DELETE, U = ON UPDATE.

PDF-id on sisuümbrise suurusega, mitte A4 lehed. Suurim laius on 499 pt ja suurim kõrgus 777 pt. DOCX-is sobitatakse joonised kuni 6,11 tolli laiusele ja 8,45 tolli kõrgusele alale, säilitades külgede suhte. CHECK-avaldised murtakse mitmele reale.

Taastamiseks laadi SQL tühja kohalikku baasi ja käivita skript teadlikult valitud andmebaasi nimega:

    ITI0207_U2_DB=tyhi_kohalik_baas python3 iti0207-epood/scripts/render_u2_er_diagrams.py

Skript loeb ainult valitud andmebaasi süsteemikataloogi. Kontrollimiseks kasuta eraldi loodud tühja kohalikku andmebaasi.
