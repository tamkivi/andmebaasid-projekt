# Ü9: kaupade trigerid

16.11.2026. Tehniline lisa. Lähtusin Ü9 juhendi versioonist 3 ja kauba
seisundidiagrammist. Trigerid ja rutiinid on kontrollitud eraldi kohalikes
PostgreSQL 17.12 ja 18.6 andmebaasides. Kooliserver ja pgApexi rakendus on
veel kontrollimata.

## Trigerid ja nende ülesanded

Loomise laused ning funktsioonide ja trigerite kommentaarid on failis
[08_trigerid.sql](../sql/08_trigerid.sql). Kokku on 20 trigerit ja 10
PL/pgSQL-keelset trigerifunktsiooni. Samaväärsed trigerid eri tabelites kasutavad
ühist funktsiooni; hindamisel ei käsitle ma neid eri ärireeglitena.

Kõik kontrollid toimuvad enne andmemuudatust. Reataseme triger tagastab lubatud
lisamisel või muutmisel `NEW` ja kustutamisel `OLD`. TRUNCATE-i keelavad trigerid
on lausetaseme trigerid. Funktsioonid täidetakse looja õigustes, otsinguteega
`public, pg_temp`, ning püsitabelid on skeemiga määratud.

| Triger | Tabel ja sündmus | Kontroll või toiming |
|---|---|---|
| `trig_kaup_algseisund` | `kaup`, INSERT | Uus kaup peab olema ootel, kood 1 |
| `trig_kaup_seisundimuudatus` | `kaup`, seisundiveeru UPDATE | Lubatud on 1→2, 3→2, 2→3, 2→4 ja 3→4 |
| `trig_kaup_seisundimuudatus_kategooria` | `kaup`, seisundiveeru UPDATE | Aktiveeritaval kaubal peab olema kategooria |
| `trig_kaup_kustutamine` | `kaup`, DELETE | Kustutada saab ainult ootel kaupa |
| `trig_kaup_andmete_muutmine` | `kaup`, põhiandmete UPDATE | Tegeliku muutuse eel peab kaup olema ootel või mitteaktiivne |
| `trig_nutitelefon_kauba_muudetavus` | `nutitelefon`, INSERT või DELETE | Seotud kaup peab olema muudetav |
| `trig_nutitelefon_muutmine` | `nutitelefon`, UPDATE | Tegelikul muutusel kontrollitakse vana ja uut seotud kaupa |
| `trig_kauba_kategooria_omamine_kauba_muudetavus` | `kauba_kategooria_omamine`, INSERT või DELETE | Seotud kaup peab olema muudetav |
| `trig_kauba_kategooria_omamine_muutmine` | `kauba_kategooria_omamine`, UPDATE | Tegelikul muutusel kontrollitakse vana ja uut seotud kaupa |
| `trig_kauba_variant_kauba_muudetavus` | `kauba_variant`, INSERT või DELETE | Seotud kaup peab olema muudetav |
| `trig_kauba_variant_muutmine` | `kauba_variant`, UPDATE | Tegelikul muutusel kontrollitakse vana ja uut seotud kaupa |
| `trig_kaup_reg_andmed` | `kaup`, registreerimisandmete UPDATE | Registreerija ja registreerimisaeg ei tohi muutuda |
| `trig_kaup_viimase_muutm_aeg` | `kaup`, UPDATE | Määrab viimase muutmise aja |
| `trig_isik_viimase_muutm_aeg` | `isik`, UPDATE | Määrab viimase muutmise aja |
| `trig_kaup_aktiivne_algseisund` | `kaup`, INSERT | Algseisundiliik peab olema aktiivne |
| `trig_kaup_aktiivne_uus_seisund` | `kaup`, seisundiveeru UPDATE | Tegelikult valitav uus seisundiliik peab olema aktiivne |
| `trig_kaup_truncate` | `kaup`, TRUNCATE | Keelab tabeli tühjendamise |
| `trig_nutitelefon_truncate` | `nutitelefon`, TRUNCATE | Keelab tabeli tühjendamise |
| `trig_kauba_kategooria_omamine_truncate` | `kauba_kategooria_omamine`, TRUNCATE | Keelab tabeli tühjendamise |
| `trig_kauba_variant_truncate` | `kauba_variant`, TRUNCATE | Keelab tabeli tühjendamise |

Seisundit võrreldakse klassifikaatori koodi järgi. Surrogaatvõtme väärtust ega
seisundi nimetust koodiks ei peeta. Uue seisundiliigi aktiivsus on eraldi reegel.
Sama seisundi tagasikirjutamine ei ole seisundiüleminek ja on kõigis neljas
seisundis lubatud. Ka põhi- ja lisaandmete UPDATE-trigerite `WHEN` võrdleb
tegelikke väärtusi, arvestades NULL-i. Seetõttu ei takista triger muutmata
andmete tagasikirjutamist.

Põhiandmete muutmisel lähtutakse vanast seisundist. Mitteaktiivse kauba hinna
muutmine koos aktiveerimisega on lubatud. Aktiivse kauba hinna muutmine koos
mitteaktiivseks muutmisega on keelatud: kõigepealt tuleb muuta seisundit ja
seejärel andmeid. Auditväljad ei kuulu põhiandmete võrdlusse, sest ka lubatud
seisundimuudatusel tuleb salvestada muutja ja aeg.

## Miks kasutasin trigereid

CHECK-kitsendus ei saa võrrelda rea vana ja uut versiooni ega kontrollida teise
tabeli kategooriaseost. Samuti ei saa CHECK takistada ootel olekust väljunud
kauba kustutamist. Need reeglid vajavad trigereid. Olemasolevad NOT NULL-,
CHECK-, UNIQUE- ja välisvõtmekitsendused jäävad alles ning nende kontrolle
trigerites ei korrata. Tundmatu või puuduva viite lükkab tagasi vastav kitsendus.

Registreerimisaeg ja esimene muutmisaeg saavad lisamisel endiselt tabeli
vaikeväärtuse. Ajatriger töötab ainult UPDATE korral ja määrab
`CURRENT_TIMESTAMP`-i ehk tehingu algusaja. Veerg on sekunditäpsusega, seega ei
pea järjestikuste muudatuste ajatemplid erinema. Triger käivitub ka siis, kui
sama töötaja lisab seose ja kaubareal muutja tunnus ei muutu.

TRUNCATE ei käivita DELETE-reatrigereid. Valisin selle keelamise kaupade ja
lisaandmete tabelites. Lubatud kaupade kustutamiseks saab kasutada DELETE-lauset.

## Veateated ja rutiinide muudatused

Trigeri keeld annab SQLSTATE-i `23514` (`check_violation`). Põhisõnum on püsiv
ja eestikeelne, näiteks „Kauba seisundimuudatus ei ole lubatud.” Muutuvad koodid,
tunnused ja seisundid on `DETAIL`-väljal. `HINT` annab soovituse ning `SCHEMA`,
`TABLE`, `CONSTRAINT` ja asjakohane `COLUMN` võimaldavad vea täpsemalt siduda.
Skeemi ja tabeli nimed tulevad `TG_TABLE_SCHEMA` ja `TG_TABLE_NAME` kaudu.

[09_rutiinid.sql](../sql/09_rutiinid.sql) ei korda enam trigerite kontrolle.

| Rutiinid | Trigerisse viidud kontroll või toiming |
|---|---|
| OP1 | Algseisundiliigi aktiivsus; koodi 1 valimine jääb registreerimise osaks |
| OP2 | Kustutatava kauba ootel seisund |
| OP3–OP5 | Lubatud üleminek ja uue seisundiliigi aktiivsus |
| OP3 | Kategooria olemasolu aktiveerimisel |
| OP6–OP10 | Kauba muudetavus |
| OP3–OP10 | Viimase muutmise aja määramine |

Töötaja volitus, uue brändi ja telefoni klassifikaatorite aktiivsus, lisatava
kategooria või värvi aktiivsus ning OP6 `xmin`-kontroll jäävad rutiinidesse.
Rutiin määrab viimase muutja, sest triger ei tea rakenduses sisse loginud töötajat.

Puuduva kauba, volituse või vananenud versiooni korral on tulemus endiselt NULL.
Muudetaval kaubal annab korduv seose lisamine või puuduva seose eemaldamine samuti
NULL-i. Kui triger keelab tegeliku muudatuse, annab kutse nüüd vea, mitte NULL-i.
OP3–OP5 korduskutse samasse seisundisse võib õnnestuda ja uuendab auditandmeid.
Aktiivsele kaubale seose lisamise katse võib anda vea ka `ON CONFLICT DO NOTHING`
korral, sest BEFORE INSERT-triger käivitub enne konflikti lahendamist.

## Samaaegsed muudatused

Lisaandmete triger lukustab esmalt kaubarea `FOR SHARE` abil ja loeb selle
seisundiviite. Alles seejärel loeb ta klassifikaatorist seisundikoodi, samuti
`FOR SHARE` lukuga. Ühest liitpäringust ei piisanud: otsese SQL-i kahe seansi
katses jäi lukuootuse järel liidetud klassifikaatori väärtus vanaks. Kahe eraldi
lugemisega sai teine seanss värske seisundi ja keelatud kustutamine katkes.
Kahe kauba vahel teisaldamisel kontrollitakse mõlemat kasvava tunnuse järjekorras.

Aktiveeriv UPDATE hoiab kaubarea muutmislukku. Seose lisamine, muutmine või
kustutamine peab saama samale reale jagatud luku. Seetõttu ei saa aktiveerimine
ja ainsa kategooria eemaldamine korraga läbi minna. Aktiveerimise triger loeb
kategooriaseost eraldi seoserida lukustamata; see väldib vastupidist lukustusjärjekorda.
Kontrollisin mõlemat järjekorda nii rutiinide kui ka otseste SQL-lausetega.

Lisaandmete triger ei tee kaubareale UPDATE-lauset. OP7–OP10 muudavad kaubarea
sama SQL-lause CTE kaudu ja teine muutmine trigeris võiks tekitada vea, et sama
käsk on rida juba muutnud. Kaubarea UPDATE käivitab aja määramise trigeri.
Puuduv vanem ei takista sama lause lisandust ega lubatud kaskaadkustutamist;
viite terviklust kontrollib välisvõti.

## Kontrollimine

[08_trigerid.sql testid](../sql/tests/08_trigerid.sql) kontrollivad trigerite
kataloogi, kogu 4×4 seisundimaatriksit, aktiveerimist, kustutamise kaskaadi,
põhi- ja lisaandmete muudatusi, kauba vahetamist, registreerimisandmeid,
ajatempleid ja TRUNCATE-i keeldu. Lubatud on viis üleminekut ja neli sama
seisundi tagasikirjutamist; seitse üleminekut on keelatud. Klassifikaatorite
koodide vahetamine tunnuseid muutmata kontrollib, et loogika ei sõltu ID-dest.
Keelatud lausetel võrreldakse ka veakoodi, sõnumit ja struktureeritud lisainfot.

[08_trigerid_naited.sql](../sql/tests/08_trigerid_naited.sql) annab iga trigeri
kohta loetava tehinguploki ja „Tulemus:” selgituse. Seal on 18 oodatud viga;
väljundis kontrolliti kõigi sõnumite vastavust. Ajatrigeri puhul kontrollitakse
vale etteantud aja automaatset asendamist. Näidete ja kontrolltestide muudatused
võetakse ROLLBACK-iga tagasi.

[run_all.sql](../sql/tests/run_all.sql) sisaldab uusi ja olemasolevaid komplekte,
õiguste kontrolli ning Ü5 korduvlaadimist. Kitsenduste ja vaadete katsetes on
trigerid peatatud ainult tagasipööratava katse ajaks. Rutiinikutsed ja trigerite
kontrollid käivad sisselülitatud trigeritega.

Mõlemas PostgreSQL-i versioonis läbisid kontrolli värske paigaldus, Ü8 paigalduse
uuendus, täielik SQL-komplekt, eraldi domeenimigratsiooni katsed, eemaldamine,
null projektiobjekti kontroll ja uuesti ehitamine. Samaaegsuse kontrollis läbisid
mõlemad versioonid üheksa kahe seansi katset ning kaks 30-sekundilist koormustesti
kaheksa ühenduse ja nelja lõimega. Mõlemas koormustestis oli tõrkeid ja ummikseise
null. See tulemus ei tõenda, et ummikseis pole muude töökoormuste korral võimalik.

## Paigaldamine, eemaldamine ja piirid

Uue paigalduse järjekord on `run_u5.sql`, `05_views.sql`, `08_trigerid.sql`,
`09_rutiinid.sql`, `14_statistics.sql` ja `16_rights.sql`. Näidisandmete laadija
lisab kaubad ootel seisundis, lisab seosed ja viib kaubad seejärel vajalikku
seisundisse. Laadija töötab ka juba paigaldatud trigeritega ja ei muuda kordamisel
tabelite senist sisu.

Olemasolevale Ü8 paigaldusele tuleb lisada `08_trigerid.sql` ja seejärel asendada
rutiinid failist `09_rutiinid.sql`. Signatuurid säilivad ning CREATE OR REPLACE
jätab senised rutiinide käivitusõigused alles. Trigerifunktsioonide PUBLIC-õigused
eemaldatakse juba 08 skripti lõpus. 16 skripti tervikuna uuesti ei käivitata,
sest see loob rolli; sama faili õiguste loend sisaldab ka uusi funktsioone.
Rakenduseroll ei saa trigerifunktsioone otse käivitada.

[19_drop_objects.sql](../sql/19_drop_objects.sql) eemaldab kõigepealt trigerid,
siis trigerifunktsioonid ning seejärel ülejäänud rutiinid ja projektiga seotud
objektid. Eemaldamist kontrollisin ainult eraldi kohalikes testandmebaasides.
Testikonteinerid koos oma andmefailidega on pärast kontrolli eemaldatud.

Isiku, töötaja ja kliendi seisunditele ei lisatud üleminekureegleid, sest projekti
seisundidiagramm kirjeldab kaupa. Telefonitabeli primaarvõti tagab kuni ühe
telefoni kauba kohta; täpselt ühe telefoni lisamise tagab OP1, mitte need trigerid.
Omaniku otsene lisaandmete muudatus ei uuenda kauba ajatemplit. Rakenduse rutiinid
uuendavad seda ja rakenduserollil puuduvad tabelite otseõigused.

Kasutati kohalikku JSON-näidisallikat. Kooliserveri õigused, tegelik JSON-allikas,
pgApexi veateadete kuvamine ja sisseloginud kasutaja sidumine töötajaga on
kontrollimata. Wordi dokumenti tuleb lisada vastavad loendid ja uuendada sisukord.
Ü9 kohalik kontroll ei tähenda töö esitamist.
