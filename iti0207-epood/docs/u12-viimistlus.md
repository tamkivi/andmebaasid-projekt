# Ü12: andmebaasi ja rakenduse lõppkontroll

17.11.2026. See lisa jätkab [Ü11 lehtede juhendit](u11-rakendus.md).
Täpsustasin kaupade halduri õigusi, lisasin eraldi ühenduskasutaja ning kontrollisin
SQL-lauseid kohalikes PostgreSQL 17 ja 18 katseandmebaasides. Ü7 vaadete,
Ü8 rutiinide, Ü9 trigerite, Ü10 tuvastamise ja Ü11 vormifunktsioonide käitumist
ma ei muutnud. Kooliserveris ja pgApexis on allpool loetletud sammud veel tegemata.

## Õiguste ülevaatus

Rakendus loeb vaateid ja muudab andmeid funktsioonidega. Baastabelite ega
IDENTITY-generaatorite õigusi ühenduskasutajal pole. Vaated kasutavad omaniku
õigusi ning andmemuudatuse funktsioonid on SECURITY DEFINER kindla otsinguteega
`public, pg_temp`. Kaks vormifunktsiooni on SECURITY INVOKER, mistõttu säilitasin
ka nende kutsutavate registreerimis- ja muutmisfunktsioonide käivitusõiguse.

| Objektid | Otsus | Põhjus |
|---|---|---|
| `v_kaubad_muutmiseks`, `v_kauba_muutmise_vorm`, `v_ootel_kaubad`, `v_aktiivsed_kaubad_haldurile` | SELECT säilib | Lehtede 4 ja 6–9 allikad ning kaubavalik. |
| `v_kaupade_detailid_seostega` | SELECT säilib | Kõigi kaupade nimekiri ja detail lehtedel 2–3. |
| `v_kauba_kategooriad`, `v_kauba_variandid`, `v_varvide_valikud`, `v_kategooriate_valikud_tyybiga`, `v_seotud_kategooriate_valikud` | SELECT säilib | Lehtede 10–11 seosed ja valikud. |
| `v_brandide_valikud`, `v_kaamerate_valikud`, `v_sisemalude_valikud`, `v_diagonaalide_valikud`, `v_protsessorite_valikud`, `v_ekraani_resolutsioonide_valikud` | SELECT säilib | Lehtede 5–6 aktiivsed tehnilised valikud. |
| `v_kaupade_koondaruanne`, `v_aktiivsed_kaubad` | SELECT eemaldatud | Teiste töökohtade tegevused. |
| `v_kaubad`, `v_kaupade_detailid`, `v_kaupade_kategooriate_loendid`, `v_kategooriate_valikud`, `v_kaupade_kategooriate_pingeread`, `v_kaupade_json` | SELECT eemaldatud | Ükski Ü11 leht neid otse ei kasuta. |
| `f_on_kaubahaldur`, kaks `_vormist` funktsiooni, `f_registreeri_nutitelefon`, `f_muuda_kaup`, `f_aktiveeri_kaup`, `f_muuda_kaup_mitteaktiivseks`, `f_unusta_kaup` ning neli kategooria- ja variandifunktsiooni | EXECUTE säilib | Tuvastamine ja halduri üheksa andmemuudatust. |
| `f_lopeta_kaup` | EXECUTE eemaldatud | Kauba lõpetab juhataja. |
| `f_leia_tootaja`, kümme trigerifunktsiooni | Otsekutse keelatud | Sisemised abifunktsioonid ja automaatsed trigerid. |
| `valine`, `laiendused`, välised tabelid ja välisserver | Juurdepääs keelatud | Laadimine ja laienduste otsekutsed pole rakenduse tegevused. |
| Keel `plpgsql` ja laienduste funktsioonid | PUBLIC-i vaikeõigused eemaldatud | Rakendus ei loo plokke ega kutsu laiendusi otse. |

Kokku jääb rollile 16 vaate lugemisõigus ja 12 funktsiooni käivitusõigus.
Detailvaade töötab ka pärast selle alusvaadete otseõiguste eemaldamist;
kontrollisin seda ühenduskasutajana.
Testide DO-plokkidele antakse keeleõigus ainult tagasivõetava tehingu sees.
See õigus ei jää rakendusele alles.

## Rakenduse ühenduskasutaja

[16_rights.sql](../sql/16_rights.sql) loob NOLOGIN-rolli `epood_rakendus`
ja LOGIN-kasutaja `t253787_epood_kaubahaldur`. Kasutaja pärib rolli õigused,
kuid ei oma objekte ega muid liikmesusi ning tal pole haldusõigusi.
Loomislauses pole parooli. Parooliga ühendus hakkab tööle pärast seda, kui olen
parooli interaktiivselt määranud. Rakenduse andmebaasikasutajaks tuleb valida
see piiratud kasutaja; enda koolikontot sinna ei sisestata.

Nimed on serveriülesed. Enne paigaldamist vaatan psql-is `\du epood_rakendus`
ja `\du t253787_epood_kaubahaldur` abil olemasolevad rollid üle ning kinnitan
matriklinumbri eesliite. Kui olemasolev roll pole minu projekti oma, peatun ja
selgitan nimekokkupõrke enne SQL-i rakendamist.

## Paroolide laadimine

Ü12 juhendi §7 järgi lisab INSERT JSON-andmete laadimisel kontole allika testparooli
ning vahetult järgnev UPDATE asendab selle bcrypt-räsiga. Mõlemad laused kuuluvad
samasse tehingusse; kinnitamisel on tabelis ainult räsid. Olemasolevaid räsisid
ei muudeta. Vanema paigalduse jaoks säilib eraldi paroolimigratsioon.

## Statistika ja täitmisplaan

[14_statistics.sql](../sql/14_statistics.sql) käivitab kogu andmebaasis `ANALYZE;`.
Väliseid tabeleid see ilma eraldi nimetamiseta ei analüüsi. Valisin Ü7 vaate
`v_kaubad`, mis ühendab tabelid `kaup`, `brand` ja `kauba_seisundi_liik`.
[15_explain.sql](../sql/15_explain.sql) näitab vaate enda päringu tekstilist
plaani koos tegeliku täitmise ja puhvrite kasutusega. Vaate järjestus säilib.
JSON-kuju saab vajaduse korral küsida EXPLAIN-i valikuga `FORMAT JSON`.

Kohalikus andmestikus tagastas vaade neli rida. Plaanis loeti väikesed tabelid
järjestikku, ühendati read räsitabelite abil ning sorteeriti tulemus nimetuse ja
kaubakoodi järgi. Kooliserveri plaan ja ajad tuleb enne dokumenti lisamist uuesti
mõõta. Kohalik plaan ei tõenda kooliserveri jõudlust.

## SQL-lausete ja turvalisuse kontroll

Täielik komplekt [tests/run_all.sql](../sql/tests/run_all.sql) kontrollib ka
varasemaid lepinguid. [Testandmete kontroll](../sql/tests/13_testandmed.sql)
nõuab igas 24 baastabelis vähemalt kaht rida, seega on Ü12 vähemalt ühe rea nõue
kaetud. Statistika ja plaani kontrollid nõuavad kõigi kolme tabeli lugemist,
puhvrinäitajaid ning vähemalt üht tegelikku tulemusrida.

Õiguste katsed kontrollivad lubatud tegevusi ja keelatud otsepöördumisi.
[Päris ühenduse kontroll](../scripts/kontrolli_rakenduse_kasutajat.sh) on ainult
kohaliku katseandmebaasi jaoks: see kontrollib õiget ühendust ja vale parooli
keeldu ning eemaldab lõpus ajutise testparooli. Kooliserveris seda skripti ei käivitata.

[Turvakontroll](../sql/tests/17_turvalisus.sql) annab tuvastamisele ja
registreerimisvormile süstimise kujuga teksti. Vale sisend ei anna sissepääsu,
nimetus ja kirjeldus säilivad muutmata tekstina ning kõik baastabelid jäävad alles.
Rutiinid ei koosta kasutaja sisendist dünaamilist SQL-i. Paigalduse dünaamilistes
lausetes kasutatakse andmebaasinime jaoks `format`-i `%I` vormingut; klassifikaatorite
laadimisel pannakse indeksi tingimusse kataloogist loetud täisarvuline seisundi ID.
Brauseri HTML-i varjestamist kohalik SQL-test ei kontrolli. Ü11 peidetud tegijavälja
ja vabalt valitava sortimise piirangud jäävad samuti kehtima.

[19_drop_objects.sql](../sql/19_drop_objects.sql) eemaldab kõigepealt sõltuvad
objektid, siis tabelid ja rollid. IDENTITY-generaatorid kustuvad koos tabelitega.
Katsetasin skripti nii, et lõpu COMMIT asendati ainult testisisendis ROLLBACK-iga.
Objektid, rollid ja õigused taastusid. Seejärel kontrollisin, et päris eemaldamise
järel ei jäänud ühtegi projektiobjekti alles, ning ehitasin andmebaasi uuesti.
Mõlemas PostgreSQLi versioonis kontrollisin ka Ü11 seisust uuendamist, üheksat
kahe seansi katset ja kaht koormuskatset. Kohalikud konteinerid ning nende andmeköited eemaldati.

Kohalik kataloogikontroll ei asenda ametlikku Quick testi. Puuduvaid primaarvõtmeid,
indeksita välisvõtmeid, dubleerivaid indekseid ega fikseerimata otsinguteega
SECURITY DEFINER-funktsioone ei leitud. Olemasolevate baastabelite ja nende veergude
kommentaarid puuduvad; need tuleb ametliku kontrolli tulemustega koos üle vaadata.

## Veel tehtavad sammud koolis

1. Teen projekti andmebaasist varukoopia ja kontrollin taastatavust. Vaatan rollid
   ning oma varasema paigalduse seisu üle. Värske paigalduse järjekord on
   `run_u5.sql`, `05_views.sql`, `07_tuvastamine.sql`, `08_trigerid.sql`,
   `09_rutiinid.sql`, `09_1_rakenduse_liides.sql`, `14_statistics.sql`, `16_rights.sql`.
   Olemasolevale Ü11 paigaldusele käivitan ainult `16_rights.sql` lõpuosa alates
   kommentaarist „Rakendusele vastav kasutaja ja liigsete õiguste äravõtmine (Ü12).”.
   Kogu faili uuesti ei käivita, sest CREATE ROLE eeldab puuduvat rolli.
   Kui samanimeline LOGIN-kasutaja on juba olemas, selgitan selle päritolu enne jätkamist.
2. Määran psql-is parooli käsuga `\password t253787_epood_kaubahaldur`.
   Parooli ei kirjuta faili ega käsurea argumenti. Ühendun uue kasutajana ja
   käivitan `tests/16_1_rakenduse_kasutaja.sql`, andes psql-i muutujaga
   `test_e_meil` kehtiva kaubahalduri aadressi. Test võtab proovikirje tagasi;
   kood `USR012` peab enne olema vaba ja kõigis 16 loetavas vaates peab olema ridu.
3. Panen pgApexi rakenduse omadustesse Database username ja Database password
   uue ühenduskasutaja andmed. Käivitan „Refresh database objects” ja proovin
   kõiki Ü11 lehti. Avaliku lähtekoodi kataloogipäringud loevad skeeme, vaateid
   ja funktsioone ilma täiendavate baastabeliõigusteta; kooli versioon tuleb kinnitada.
   Tühi aruanne võib tähendada puuduvat SELECT- või USAGE-õigust. Kui leht kasutab
   eemaldatud vaadet, valin Ü11 tabeli järgi lubatud allika. Vajaduse korral
   põhjendan eraldi konkreetse vaate lisamist, mitte kõigi vanade õiguste taastamist.
   Kui lõin Ü11 ajal ühenduskasutaja `epood_u11_login`, siis pärast pgApexi
   ümberseadistamist eemaldan selle: `REVOKE epood_rakendus FROM epood_u11_login;`
   ja `DROP USER epood_u11_login;`. Enne seda kontrollin, et vana kasutaja kuulub
   minu projektile ja ükski teine rakendus seda ei kasuta.
   Kui leht annab veateate „permission denied for language plpgsql”, märgin üles,
   milline pgApexi tegevus seda vajab, ja annan keele USAGE-õiguse ainult rollile
   `epood_rakendus`, mitte PUBLIC-ile.
4. Kontrollin, et iga hinda näitava välja lipikul on valuuta (EUR). Lehtede 7–9
   tabelivormis peab olema märgitud „The final function parameter expects a value
   of APP_USER variable” ja xmin-i märkeruut peab jääma märkimata. Proovin kõik
   nupud ja veateated uuesti läbi.
5. Proovin sisselogimises, kõigis vormiväljades ja URL-i `kauba_kood` parameetris
   sisendeid `' OR '1'='1`, `'; DROP TABLE kaup; --` ja `<script>alert(1)</script>`.
   Kontrollin valikut „Is text escaped” ning vaatan tulemust aruandes, detailis,
   tabelivormis ja valikute siltidel. Skript ei tohi käivituda ega sissepääsu anda.
6. Käivitan omanikuna `tests/13_testandmed.sql`, seejärel `14_statistics.sql` ja
   `15_explain.sql`. Asendan dokumendis kohaliku plaani kooliserveri plaaniga ning
   kohandan selgituse tegelike operatsioonide, ridade, puhvrite ja aegade järgi.
   Ülikooli PostgreSQLi täpse versiooni kirjutan realisatsiooni algusesse.
7. Käivitan [ametliku disainikontrolli](https://apex2.taltech.ee/queries2/),
   alustades Quick testist. Iga leid ei pruugi olla viga: võrdlen seda mudeliga,
   parandan sisulised puudused ja käivitan kontrolli uuesti.
8. Ühendan Wordis varasemad parandused ja Ü12 teksti, uuendan tiitellehe ning
   peatüki 3 füüsilise disaini diagrammid, eemaldan teise andmebaasisüsteemi
   realisatsiooni pealkirjad, kontrollin viiteid ja lisan kasutatud materjalidesse
   „Andmebaasid II” õppematerjalid. Värskendan kogu sisukorra. See lisa ei muuda
   Ü11 lehtede kirjeldust ega lahenda varasemate Wordi paranduste ühendamist.
9. Teen projekti andmebaasist ning hiljem valmis rakenduse `pgapex3` andmebaasist
   eraldi plain-vormingus loogilised koopiad. Näiteks kasutan projekti koopia puhul
   käsku `pg_dump --format=plain --host=apex2.taltech.ee --username=<oma_kasutaja> --dbname=<projekti_andmebaas> --password --file=epood-loplik.sql`.
   Asendan kohatäitjad ning sisestan parooli interaktiivselt. Kui vajan andmetest
   INSERT-lauseid, lisan `--inserts`; kogu koopia jaoks sobib ka vaikimisi COPY.
   Kontrollin koopia taastatavust eraldi andmebaasis.

Ülikasutaja tehtud projekti dump võib sisaldada `CREATE USER MAPPING` lauses
välise andmeallika pärisparooli avatekstina. Enne jagamist otsin selle koha üles
ja asendan saladuse; jagatav fail vajab taastamisel ühenduse uuesti seadistamist.
`pgapex3` koopia sisaldab rakenduse ühenduskonto parooli. Kaitsen mõlemat faili,
ei lisa neid repositooriumisse ning lepin vajaduse korral kokku eraldi kontrollkonto.
Loogiline andmebaasikoopia ei loo serveriüleseid rolle. Enne taastamist käivitan
õiguste skriptist ainult rolli ja kasutaja loomise ning liikmesuse laused;
objektide GRANT-laused eeldavad taastatud objekte. Kohalikud testid, juhend ja haru avaldamine ei ole töö esitamine.

## Allikad

Lähtusin Ü12 ametliku juhendi punktidest 3–9 ja 11–14 ning „Andmebaasid II”
õppematerjalidest. Objektide värskendamist kontrollisin [pgapex3 avalikust
lähtekoodist](https://github.com/dmibiz/pgapex3/blob/master/pgapex/evolutions/3_create_materialized_view_functions.sql).
Avalik versioon ei kinnita koolis kasutatava versiooni käitumist.
