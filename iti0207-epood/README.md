# Nutitelefonide e-poe infosüsteemi kaupade funktsionaalne allsüsteem

**Kursus:** ITI0207 Andmebaasid II  
**Õppeaasta:** 2026/2027  
**Töötuba:** Kaupade haldur  
**DBMS:** PostgreSQL  
**Rakendustööriist:** pgApex (vajadusel muudetav)

## Projekti kirjeldus

See on ITI0207 andmebaaside kursuse töö, mis käsitleb nutitelefonide e-poe infosüsteemi kaupade funktsionaalset allsüsteemi. Projekt põhineb Erki kataloogi näidisel.

**Oluline:** See projekt EI OLE jõusaali projekti jätk ega täiendus. See on täiesti uus domeen ja uus töö ITI0207 kursuse raames.

## Viide varasemale tööle

Selles repositooriumis on ka eelmise aasta ITI0206 jõusaali projekt kaustas `../iti0206-jousaal/`. See on seal ainult viitena varasema andmebaasiprojekti protsessi ja mallide kohta, kuid see ei ole selle aasta tööga sisuliselt seotud.

## Struktuur

Projekti kataloogid:

- `docs/` - Dokumentatsioon ja aruanded
- `models/` - Enterprise Architect mudelid (`.eap`)
- `sql/` - SQL skriptid ja DDL
- `app/` - Rakenduse lähtefailid (pgApex või muu)

## Arendus

Värske andmebaasi paigaldusjärjekord on `sql/run_u5.sql`, `sql/05_views.sql`,
`sql/07_tuvastamine.sql`, `sql/08_trigerid.sql`, `sql/09_rutiinid.sql`,
`sql/09_1_rakenduse_liides.sql`, `sql/14_statistics.sql`, `sql/16_rights.sql`.
Olemasoleva Ü10 paigalduse uuendus kasutab ainult uut liideseskripti ja Ü11
õiguste plokki; kogu õiguste faili uuesti ei käivitata, sest see loob rolli.

[Ü11 lisa](docs/u11-rakendus.md) kirjeldab kaupade halduri lehti, vormivälju,
valikuallikaid, autentimist ja veel kontrollimata pgApexi piiranguid.
Andmebaasi liidest on kontrollitud kohalikult; lehed tuleb koolis ise ehitada.
Täielik SQL-kontroll käivitatakse eraldi testandmebaasis failiga
`sql/tests/run_all.sql`.

## Esitamine

_(Esitatavad artefaktid ja juhised lisatakse hiljem)_
