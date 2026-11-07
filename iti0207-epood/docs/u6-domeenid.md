# Ü6: klassifikaatori nimetuse domeen

07.11.2026. Tehniline lisa; Wordi lõppdokumenti veel üle kandmata.

Ü6 juhendi §2–3 järgi peab vähemalt üks domeen olema järjekindlalt kasutusel vähemalt
kahel mitte-välisvõtme veerul. Domeen koondab ühised omadused; need eemaldatakse
veeru küljest. Refaktoreerimine peab säilitama Ü5 andmed ja sellele peab eelnema varundus.

## Valik ja kasutuskohad

Senine `klassifikaatori_nimetus` on sisuliselt sobiv: `varchar(100)`, kohustuslik ja
vähemalt ühe mittetühimärgiga. Selle 15 kasutuskohta on auditeeritud; korduvaid
veeru NOT NULL-, CHECK- ega DEFAULT-määranguid ei olnud. Muutub ainult domeeni
nimi: `d_klassifikaatori_nimetus`. Olemasoleva CHECK-kitsenduse nimi säilib.
Ka automaatselt antud NOT NULL-kitsenduse vana nimi võib migreeritud skeemis säilida;
uues skeemis tuletatakse see uuest domeeninimest. See on kosmeetiline kataloogierinevus.

Domeen määrab järgmiste tabelite `nimetus` veeru:

| Rühm | Tabelid |
|---|---|
| Riik ja seisundid | `riik`, `isiku_seisundi_liik`, `tootaja_seisundi_liik`, `kliendi_seisundi_liik`, `kauba_seisundi_liik` |
| Roll ja kategooriad | `tootaja_roll`, `kauba_kategooria_tyyp`, `kauba_kategooria` |
| Telefoni klassifikaatorid | `brand`, `diagonaal`, `ekraani_resolutsioon`, `kaamera`, `protsessor`, `sisemalu`, `varv` |

Kõik 15 on mitte-välisvõtme veerud. Unikaalsus jääb tabeli omaduseks (kategoorial
unikaalne koos tüübiga). Ühist sisulist vaikeväärtust ei ole; DEFAULT-i ei lisata.
`kaup.nimetus` jääb eraldi `varchar(255)` veeruks koos miinimumpikkuse reegliga.
Kauba koodid, isikunimed, viiteveerud ja tõeväärtused ei kuulu sellesse domeeni.
Tõeväärtustel kasutatakse endiselt PostgreSQLi `boolean` tüüpi.

## Loomine ja olemasoleva skeemi muutmine

Uue skeemi täielik deklaratsioon: [00_domains.sql](../sql/00_domains.sql).

```sql
CREATE DOMAIN d_klassifikaatori_nimetus AS varchar(100)
    NOT NULL
    CONSTRAINT ck_klassifikaatori_nimetus_sisu CHECK (VALUE ~ '[^[:space:]]');
COMMENT ON DOMAIN d_klassifikaatori_nimetus IS
    'Klassifikaatori kohustuslik nimetus pikkusega kuni 100 märki; peab sisaldama vähemalt ühte mittetühimärki.';
```

[01_tables_draft.sql](../sql/01_tables_draft.sql) sisaldab kõigi 15 tabeli ajakohastatud
CREATE TABLE-lauseid, näiteks veerud on kujul `nimetus d_klassifikaatori_nimetus`.
Sama veeru juures NOT NULL-i, sisukontrolli ega vaikeväärtust ei korrata.

Täidetud senise projektiskeemi jaoks kasutatakse
[migrations/06_domeeni_nimi.sql](../sql/migrations/06_domeeni_nimi.sql):

```sql
ALTER DOMAIN public.klassifikaatori_nimetus RENAME TO d_klassifikaatori_nimetus;
```

Skript kontrollib enne kinnitamist eeldatud domeeni omadusi ja kõiki kasutuskohti.
Vea korral katkeb tehing. Kui domeen on juba õigesti ümber nimetatud, ei tee korduv
käivitamine muudatusi. Mõlema nime koosesinemisel või ootamatu skeemi korral skript
peatub. See ei ole suvalise või domeenita skeemi migreerimise skript.

Domeeni OID ei muutu. Ümbernimetamine ei loo sõltuvaid objekte uuesti. Kohalik
säilivuskontroll võrdleb tabeliandmeid, arvujadade seisusid ning allpool nimetatud
kataloogivälju; domeeni õigusi, kitsenduste kirjeid, vaatereegleid ja kommentaare
eraldi ei võrrelda. Test ei tõenda kogu kataloogi täpset säilimist.
ALTER TABLE TYPE pole sellel olemasoleval skeemil vajalik, sest veerud kasutavad juba
õiget domeeni. Uue skeemi CREATE TABLE-laused sisaldavad uut nime.

Enne migratsiooni tee `pg_dump -Fc` abil varukoopia väljapoole repositooriumi ja
kontrolli selle taastamist uude tühja testandmebaasi `pg_restore --exit-on-error` abil.
Ühenduse argumendid tuleb määrata selgesõnaliselt. Varukoopia võib sisaldada
välisühenduse kasutajavastenduse valikuid, sealhulgas parooli. Käsitle seda salajasena,
piira faili ligipääs ainult omanikule ning ära lisa seda versioonihaldusse ega avalda logis.
Varukoopia ei sisalda väliste tabelite lähteandmeid ega serveriüleseid rolle; need tuleb taastamiseks eraldi tagada.

See on **ainult domeeni migratsioon**, mitte varasemate rutiinide ja õiguste uuendus.
Kohalik täidetud lähtebaas oli hübriid: vana domeeninimi ja Ü5 andmed, kuid juba
ühendatud uute allkirjadega rutiinid ning õigused. See ei olnud muutmata `4d0fc09`
ega `96f0c86` põhjal ehitatud andmebaas. Varem kinnitatud rutiinidega täidetud baasis
jäävad pärast domeeni migratsiooni alles näiteks `f_leia_tootaja(varchar)` ja
`f_unusta_kaup(varchar)`; uued kahe argumendiga kutsed ei ole sellega kaetud.
`09_rutiinid.sql` uuesti käivitamine ei asenda olemasolevaid rutiine terviklikult.

Sellise baasi rutiinide uuendamine on eraldi Ü8 töö: eemaldada kõik 11 vana allkirjaga
funktsiooni ühe sõltuvusi arvestava DROP FUNCTION-lausega samas tehingus, käivitada
`09_rutiinid.sql` ning rakendada `16_rights.sql` REVOKE/GRANT-osa uuesti ilma
CREATE ROLE-lauseta. Teiste sõltuvuste olemasolu tuleb enne kontrollida; CASCADE-i ei
kasutata. Eraldi uuendusskripti ega selle tee katset selles töös ei lisatud.

## Paigalduse ja testide järjekord

Uues eraldatud projektikeskkonnas, kus `epood_rakendus` rolli veel ei ole:

1. `run_u5.sql` loob domeeni, tabelid ja indeksid ning laadib Ü5 andmed. Anna välise
   allika ühendusmuutujad käivitamisel. Vana domeeninime leidmisel nõuab laadija
   esmalt migratsiooni. Ü5 laadija ei paigalda rutiine, vaateid ega õigusi.
2. Käivita `05_views.sql`, `09_rutiinid.sql`, `14_statistics.sql` ja `16_rights.sql`
   selles järjekorras ning `ON_ERROR_STOP=1` valikuga. Roll on serveriülene;
   olemasolevat samanimelist rolli ei muudeta ega taaskasutata pimesi.
3. Käivita `psql -X -v ON_ERROR_STOP=1 … -f tests/run_all.sql` samade allikamuutujatega.
   See käivitab kõik 11 olemasolevat testikomplekti ja Ü5 korduvlaadimise kontrolli.
   Õiguste test vajab välist tehingut; laadijate oma tehinguid sellesse ei pakita.

Täidetud vanal **testskeemil** käivitatakse pärast varundamist eraldi
`tests/06_migration.sql`. See võrdleb kõigi 24 tabeli kogu sisu, arvujadade seisusid,
domeeni OID-d, veergude ja funktsioonide kataloogikirjeid ning pg_classi stabiilseid
välju (oid, relname, reltype, relkind, relacl, relnatts) enne ja pärast kaht migratsiooni
käivitust. VACUUMi ja ANALYZE statistikat ei võrrelda. Seejärel kontrollib domeeni väärtusi.

`tests/03_domains.sql` kontrollib 15 konkreetset mitte-FK kasutuskohta, domeeni omadusi
ja dubleerimise puudumist. Lubatud on sisukas tekst ja 100 märki; keelatud on otsene
NULL, tühi tekst, ainult tühimärgid ja 101 märgi sisestamine. Kontrollitakse ka kahe
eraldi tabeliveeru kaudu lisamist/muutmist ja kasutuses domeeni RESTRICT-kustutamise
keelamist. Test lõpeb ROLLBACK-iga; uued domeenitestid ei tarbi identiteedi väärtusi.

## PostgreSQLi NOT NULL erijuht

Ü6 §4.1 kirjeldab, et domeenitüübilise tühja alampäringu NULL võib domeeni NOT NULL
kontrollist mööduda. Seda käitumist demonstreerib test ajutises tabelis ja pöörab tagasi.
Siin järgitakse juhendi teadlikku valikut hoida ühine NOT NULL domeenis ning vältida
selle dubleerimist veergudel. See ei ole absoluutne NULL-i puudumise garantii kõigi
võimalike SQL-lausete korral; tavaline otsene NULL-i sisestamine lükatakse tagasi.

## Kustutamine

[19_drop_objects.sql](../sql/19_drop_objects.sql) eemaldab kõigepealt rutiinid ja
vaated koos reeglitega, seejärel tabelid viitavatest viidatud tabelite poole ja alles siis:

```sql
DROP DOMAIN d_klassifikaatori_nimetus RESTRICT;
```

Kasutuses domeenile ei rakendata `DROP DOMAIN … CASCADE`, sest PostgreSQLis
kustutaks see domeeni kasutavad veerud. Kustutamisskript on kogu eraldi projektiskeemi
eemaldamiseks, mitte andmeid säilitavaks migratsiooniks. Seda katsetatakse ainult
selleks loodud testkeskkonnas.

## Kontrolli piir ja allikad

Kohalik kontroll: PostgreSQL 17.10, eraldi ajutine privaatne klaster, kohalik
superkasutaja, kaks Mauruse §6.1 kujuga JSONB-näidistabelit ja sünteetilised andmed.
Välisühenduse näidis kasutas privaatset kohalikku soklit ja tühja parooli; see ei
tõenda postgres_fdw paroolinõuete täitmist tavakasutajana. SET LOCAL ROLE kontrollid
katavad rakendusrolli õigusi selles keskkonnas. Koolis on kontrollimata üliõpilase
CREATE ROLE ja REVOKE ON DATABASE võimalused, omanikuõiguste käitumine ning
mitte-superkasutaja välisühenduse piirangud. Varundus/taastamine, migratsioon,
integreeritud testid, korduvlaadimine, tühjalt ehitus ja eemaldamine kontrolliti kohalikult.
See ei kinnita kooliserveri PostgreSQL 18, tegeliku allika ega kooliõiguste toimimist.
Wordi jaotised 4.3 ja 5 vajavad hiljem selle lisa ning nõutud kasutusinfo lisamist.

Aluseks on 07.11.2026 salvestatud kehtivad Mauruse väljavõtted:

- Ülesanne 6, terviktekst, eriti §2–4.1, §4.3–4.4 ja §4.8.
- Ülesanne 5 ver2, §2, §4.4 ja §6.1 (laadimine ning loogiline varukoopia).
- Ülesanne 8, §3–4 ja §7.3–7.6 (ühendatavate rutiinide lepingud, allkirjad ja turvalisus).
- Sissejuhatus ver5, lk 39; hindamismudeli CSV on ainult esimese töölehe väljavõte.

Päritolu: [aine 391](https://maurus.ttu.ee/aine_index.php?aine=391) ja
[dokumendikataloog 4942](https://maurus.ttu.ee/vaata_doc_voog.php?m_doc_catalog=4942&aine=391).
