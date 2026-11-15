# Ü8: kaupade andmemuudatuste rutiinid

14.11.2026. Tehniline lisa. Kümme lepingulist funktsiooni ja ühine abifunktsioon
on eraldatud kohalikus PostgreSQL 17.10 klastris kontrollitud. Kooliserveri paigaldus
ja pgApexi rakendus on veel kontrollimata.

## Operatsioonid ja õigused

| Leping | Funktsioon | Vajalik kehtiv roll |
|---|---|---|
| OP1 | `f_registreeri_nutitelefon` | `KAUBAHALDUR` |
| OP2 | `f_unusta_kaup` | `KAUBAHALDUR` |
| OP3 | `f_aktiveeri_kaup` | `KAUBAHALDUR` |
| OP4 | `f_muuda_kaup_mitteaktiivseks` | `KAUBAHALDUR` |
| OP5 | `f_lopeta_kaup` | `JUHATAJA` |
| OP6 | `f_muuda_kaup` | `KAUBAHALDUR` |
| OP7 | `f_lisa_kaup_kategooriasse` | `KAUBAHALDUR` |
| OP8 | `f_eemalda_kaup_kategooriast` | `KAUBAHALDUR` |
| OP9 | `f_lisa_kauba_variant` | `KAUBAHALDUR` |
| OP10 | `f_eemalda_kauba_variant` | `KAUBAHALDUR` |
| OP1–OP10 ühine kontroll | `f_leia_tootaja` | Kutsuv funktsioon annab rolli koodi |

Loomise laused ja iga funktsiooni eesmärki selgitav `COMMENT ON FUNCTION` on
failis [09_rutiinid.sql](../sql/09_rutiinid.sql). Kõik funktsioonid on SQL-keelsed,
SQL-standardi kehandiga `BEGIN ATOMIC … END`, muutlikud (`VOLATILE`) ja täidetavad
looja õigustes (`SECURITY DEFINER`). Otsingutee on `public, pg_temp` ning kehandis
kasutatavad püsiobjektid on skeemiga määratud. Parameetrite nimed väldivad täpitähti,
näiteks `p_brandi_kood` ja `p_varv_kood`.

Kümme muutmisfunktsiooni tagastavad õnnestumisel kaubakoodi, muutuseta tulemus
on NULL. Deklaratiivse kitsenduse rikkumine võib siiski anda vea. Abifunktsioon
annab sobiva töötaja ID üheelemendilise hulgana; sobiva töötaja puudumisel on hulk
tühi. Funktsiooni skalaarne alampäring annab sel juhul NULL-i.

[16_rights.sql](../sql/16_rights.sql) eemaldab PUBLIC-i käivitusõigused ja annab
kümne lepingulise funktsiooni käivitamise rollile `epood_rakendus`. Abifunktsiooni
otseõigust rakenduserollile ei anta. Rakenduseroll saab lugeda vaateid, kuid tal
pole baastabelite otseõigusi. E-posti parameeter ei asenda rakenduse kasutajatuvastust;
see tuleb siduda sisseloginud kasutajaga rakenduse juures.

## Eeltingimused ja üks andmemuudatuslause

Ühine töötajakontroll otsib e-posti tõstutundetult. Isik peab olema elus (`EL`),
töösuhe katseajal (`KA`), tööl (`TO`) või puhkusel (`PU`) ning nõutud roll peab
kehtima: `alguse_aeg <= CURRENT_TIMESTAMP < lopu_aeg`. Töötaja, isiku, rolli
omamise ning kontrollitavate klassifikaatorite read lukustatakse `FOR SHARE` abil.
Seega ei saa teine tehing kontrolli järel rolli omamist lõpetada ega kontrollitud
seisundi või rolli koodi muuta enne esimese tehingu lõppu.
Iga lepinguline funktsioon kasutab seda kontrolli. Kahe seansi katses ootas rolli
omamise lõpetamine kontrolli teinud tehingu lõppu. Kui rolli lõpetamine kinnitati
esimesena, ootas abifunktsioon seda muudatust ja tagastas seejärel tühja hulga.

| Funktsioonid | Samas lauses kontrollitavad täiendavad eeltingimused |
|---|---|
| OP1 | Aktiivne algseisund koodiga 1, bränd ja kõik telefoni klassifikaatorid; korduvat kaubakoodi ei lisata |
| OP2 | Kaup on ootel, seisundi kood 1 |
| OP3 | Lähteseisund 1 või 3, aktiivne sihtseisund 2 ja vähemalt üks kategooriaseos |
| OP4 | Lähteseisund 2 ja aktiivne sihtseisund 3 |
| OP5 | Lähteseisund 2 või 3 ja aktiivne sihtseisund 4 |
| OP6 | Seisund 1 või 3, sama `xmin`, olemasolev telefon ja aktiivsed uued klassifikaatorid |
| OP7, OP9 | Seisund 1 või 3 ning aktiivne lisatav kategooria või värv; korduvat seost ei lisata |
| OP8, OP10 | Seisund 1 või 3 ning eemaldatava klassifikaatori olemasolu; suletud klassifikaatori seost võib eemaldada |

Klassifikaatoreid otsitakse sisuliste koodide, mitte nimetuste või eeldatavate
surrogaatvõtmete järgi. Teiste tabelite kontrollitavaid klassifikaatoriridu ja OP3
kategooriaseost kaitseb `FOR SHARE`. OP1 lisab kauba ja telefoni sama lause sees
andmemuudatusega CTE-de abil. OP2 sõltuvad read kustuvad välisvõtmete
`ON DELETE CASCADE` tõttu. OP6 muudab kauba ja telefoni ühe SQL-lausega.

OP3–OP10 muudavad viimase muutja viidet ning viimase muutmise aega. OP7–OP10
teevad seda ainult siis, kui kategooriaseos või variant tegelikult lisati või eemaldati.
Registreerija ja registreerimisaeg säilivad. Kitsendustega jõustatud reegleid rutiinis
ei korrata. Seisundimuudatuste kontroll on praegu rutiinides; seisundimuudatuste
trigerite lisamisel tuleb vastavad kontrollid viia trigeritesse, et vältida kordamist.

## Optimistlik lähenemine ja lukud

Valisin optimistliku lähenemise, sest veebivorm ei hoia andmebaasiühendust kogu
muutmise aja avatuna ning pgApex 3 toetab `xmin`-argumendi sidumist. Lisaveergu
`rea_versioon` pole vaja: [v_kaubad_muutmiseks](../sql/05_views.sql) annab tegeliku
`xmin`-i ning OP6 saab selle tekstina parameetriga `p_ver`. Tingimus
`k.xmin=p_ver::xid` jätab vananenud vormi muudatuse tegemata ja funktsioon annab
NULL-i. Rakendus peab seejärel kuvama värske rea ning laskma kasutajal otsustada,
kas ta soovib muudatust uuesti teha.

OP2–OP5 lähteseisundi tingimus samas DELETE- või UPDATE-lauses on optimistliku
lähenemise erijuhus. OP7–OP10 lukustavad kauba rea `FOR UPDATE` abil enne seose
muutmist ja muudavad ka kauba rida. Seega aegub enne seose muudatust avatud OP6
vorm. Veebivormi täitmise ajal andmebaasirida lukus ei hoita.
Iga rakenduskutse peab olema omaette lühike tehing: ühe tehingu sees tehtud
muudatused võivad jagada sama `xmin`-i.

OP6 telefoni olemasolu kontroll kasutab `FOR NO KEY UPDATE` lukku, sest sama
lause muudab seda telefonirida hiljem. Senise `FOR SHARE` luku korral võtsid kaks
muutjat jagatud lukud ning püüdsid neid hiljem tugevdada. Kaheksal samaaegsel
ühendusel tekkis 30-sekundilises katses 291 ummikseisu 292 katsest. Tugevama luku
võtmine enne kauba muutmist kõrvaldas selle katses: mõlemas eraldi korduskatses
oli OP6 ummikseise ja muid tõrkeid null. Teine sama versiooni kasutav seanss ootas
lukku ning sai seejärel NULL-i.

OP3 ja OP8 lukustavad kauba ning kategooriaseose erinevas järjekorras. See võib
tekitada ummikseisu, mille korral PostgreSQL katkestab ühe tehingu. Eraldi käitatud
30-sekundilistes segakoormuse katsetes mõõdeti null ummikseisu; see ei tõenda,
et neid ei saa kunagi tekkida. Rakendus peab ummikseisu korral terve tehingu
uuesti proovima. Andmete terviklust kontrollitakse ka siis, kui koormustest raporteerib
ummikseisu.

## Kontrollimine

[09_rutiinid_naited.sql](../sql/tests/09_rutiinid_naited.sql) sisaldab iga funktsiooni
õnnestuvat ja tagasilükatud nimeliste argumentidega kutset ning tulemuse
kontrollpäringut. OP6 näide kordab juhendi a1–a4 olukorda: loetakse sama versioon,
salvestatakse uus hind ja proovitakse vana versiooniga teist nimetust. Teine kutse
annab NULL-i, esimese kasutaja hind ja nimetus säilivad. Näited lõpevad ROLLBACK-iga.

[09_rutiinid.sql testid](../sql/tests/09_rutiinid.sql) kontrollivad lisaks funktsioonide
omadusi, eeltingimusi, kõrvalmõjusid ja keeldumisel andmete säilimist.
[run_all.sql](../sql/tests/run_all.sql) käivitab mõlemad loendid ning ülejäänud
integreeritud komplektid. Nimelised argumendid ja vajalikud tüübiteisendused on
esitatud ka lühikestes näidetes.

[Samaaegsuse juhend](../sql/tests/samaaegsus/README.md) ja
[kontrolli_samaaegsust.sh](../scripts/kontrolli_samaaegsust.sh) teevad järgmised
kontrollid kahe eraldi seansi ning kolmanda vaatlusühenduse abil.

| Katse | Kohalik tulemus |
|---|---|
| S1: kaks OP6 kutset sama versiooniga | B lukuootus nähtav; pärast A kinnitamist B = NULL, A väärtused säilisid |
| S2: kategooria lisamine ja vana OP6 vorm | A kinnitas lisamise; B = NULL |
| S3: aktiveerimine ja ainsa kategooria eemaldamine, mõlemad järjekorrad | B lukuootus nähtav ja B = NULL; aktiivset kategooriata kaupa ei tekkinud |
| S4: kaks aktiveerimist | B lukuootus nähtav ja B = NULL |
| S5: kustutamine ja variandi lisamine, mõlemad järjekorrad | Pärast kustutamist lisamine = NULL; vastupidises järjekorras kustutamine õnnestus ning eemaldas ka variandi |

Koormustestid kasutavad `pgbench -n -c 8 -j 4 -T 30 --failures-detailed`.
Iga katse järel kontrolliti, et aktiivsel kaubal on kategooria, igal kaubal täpselt üks
telefon ning viimase muutmise aeg ei eelne registreerimisajale. Variantide hulgas
polnud orvuks jäänud ridu. Lukuootust kontrolliti `pg_stat_activity` kaudu.

## Eemaldamine ja piirid

[19_drop_objects.sql](../sql/19_drop_objects.sql) sisaldab kõigi üheteistkümne
funktsiooni kustutamist koos parameetrite tüüpidega. Lepingulised funktsioonid
kustutatakse enne ühist abifunktsiooni, vaateid, tabeleid ja domeeni. Olemasolev
kustutamisjärjekord ei vajanud muutmist. Täielik paigaldus, testid, eemaldamine,
null projektiobjekti kontroll ning uuesti ehitamine läbisid kohaliku kontrolli.

Kasutati eraldi ajutist PostgreSQL 17.10 klastrit ja kohalikku JSON-näidisallikat.
Kooliserveri PostgreSQL 18, tegelik JSON-allikas, üliõpilase õigused, olemasoleva
paigalduse vanade rutiiniallkirjade uuendamine, rakenduse kasutajatuvastus ja
pgApexi lehed on kontrollimata. Ü8 kohalik kontroll ei kinnita nende valmimist ega
projekti esitamist.
