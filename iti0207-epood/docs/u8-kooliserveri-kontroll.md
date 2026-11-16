# Ü8 kontroll kooliserveris

Käivita käsud projekti `iti0207-epood` kataloogis. Kontroll on mõeldud eraldi
projektiandmebaasile. Varasema paigalduse uuendamist ei ole katsetatud.

1. Lülita FortiClient VPN sisse ja määra ühendus. Kasuta olemasolevat
   `~/.pgpass` faili või sisesta parool `psql` küsimise peale. Ilma `~/.pgpass`
   failita küsib skript parooli iga ühenduse jaoks eraldi ehk ühe käsu jooksul
   mitu korda. Ära kirjuta parooli käsureale ega logisse. Vali igaks kontrolliks
   uus logikataloog väljaspool repositooriumi.

   ```sh
   export PGHOST='<HOST>' PGPORT=5432 PGDATABASE='<ANDMEBAAS>' PGUSER='<KASUTAJA>'
   export U8_LOGID="$(mktemp -d /tmp/iti0207-kooliserver.XXXXXX)"
   pg_isready -h "$PGHOST" -p "$PGPORT" -t 5
   scripts/kontrolli_kooliserverit.sh uuri "$U8_LOGID/uuri"
   ```

   `uuri` ainult loeb versiooni, ühendust, oma õigusi ja olemasolevaid objekte.
   Kui server ei vasta, kontrolli VPN-i. Kui leidub varasemaid objekte või roll
   `epood_rakendus`, peatu: otsusta, kas need tuleb säilitada või pärast
   varundamist sobiva eemaldamisskriptiga kustutada. Ära käivita uut paigaldust
   vana peale. Roll on serveriülene ja võib kuuluda teisele andmebaasile.
   Kui vajalikud loomise õigused puuduvad, ära jätka paigaldusega.

2. Tühjas projektiandmebaasis kasuta `psql` versiooni 15 või uuemat.
   Järgmine käsk küsib JSON-allika parooli ilma seda ekraanile näitamata.
   Vaikimisi on allikas samas serveris ja pordis, andmebaas `testandmed`,
   kasutaja sama mis `PGUSER`. Vajadusel määra enne käivitamist
   `TESTANDMETE_HOST`, `TESTANDMETE_PORT`, `TESTANDMETE_ANDMEBAAS` ja
   `TESTANDMETE_KASUTAJA`. Need muutujad ei sisalda parooli.

   ```sh
   scripts/kontrolli_kooliserverit.sh paigalda KINNITAN "$U8_LOGID/paigalda"
   ```

   Järjekord on `sql/run_u5.sql`, `sql/05_views.sql`, `sql/09_rutiinid.sql`,
   `sql/14_statistics.sql`, `sql/16_rights.sql`. Laadimise muutujad on
   `apex_kasutaja` ja `apex_parool`; skript annab need `psql` keskkonna kaudu
   `\getenv` abil. Faili `run_u5.sql` veaväljundit ei salvestata, sest see võib
   sisaldada JSON-allika parooli. Ülejäänud nelja faili väljund salvestatakse
   faili `$U8_LOGID/paigalda/paigalda.log`. Katkemisel peatu ja vaata osaline
   paigaldus üle; automaatset eemaldamist pole.

3. Kontrolli kataloogi ja käivita andmesisu säilitavad testid.

   ```sh
   scripts/kontrolli_kooliserverit.sh kontrolli "$U8_LOGID/kontrolli"
   scripts/kontrolli_kooliserverit.sh testi "$U8_LOGID/testi"
   ```

   Oodatav kokkuvõte: `Kataloogikontroll läbitud: 11 funktsiooni, 10 avalikku
   käivitusõigust, 12 vaadet.` ning `Testid läbitud: kõigi 24 tabeli reaarv ja
   sisu säilisid.` Kui testid katkevad, on veateade failis
   `$U8_LOGID/testi/testi.log`. Ühine abifunktsioon `f_leia_tootaja` jääb
   rakenduserollile suletuks. Testid kasutavad tagasipööramist või alamtehinguid; enne ja pärast
   võrreldakse iga tabeli reaarvu ning sisu räsi. Identiteedijadade väärtused võivad
   katsete käigus edasi liikuda. `sql/tests/run_all.sql` laadib andmeid uuesti
   ning sobib ainult eraldi testandmebaasi.

4. Ava sama ühendusega kaks `psql` akent. Aknas A käivita
   `psql -X -v ON_ERROR_STOP=1`, aknas B
   `PGAPPNAME=u8_b psql -X -v ON_ERROR_STOP=1`. Kõik järgnevad `\i` käsud
   käivitatakse neis akendes. Kontrolli enne esimest seadistamist, et näidiskauba
   kood on vaba; kui tulemus pole null, vali katsetamiseks eraldi andmebaas.

   ```sql
   SELECT count(*) FROM public.kaup WHERE kauba_kood='CON008';
   ```

   Enne **iga** tabelis toodud katset käivita aknas A:

   ```sql
   \i sql/tests/samaaegsus/seadista.sql
   ```

   S1 ja S2 puhul loe pärast seadistamist ja enne A muudatust **mõlemas** aknas
   sama versioon. Säilita see muutuja B aknas ka A tehingu kinnitamise järel.

   ```sql
   SELECT xmin::text AS ver FROM public.v_kaubad_muutmiseks WHERE kauba_kood='CON008' \gset
   ```

   | Katse | A aken | B aken | Oodatav B tulemus |
   |---|---|---|---|
   | S1 | `\i sql/tests/samaaegsus/s1_a.sql` | `\i sql/tests/samaaegsus/s1_b.sql` | Ootab A kinnitamist, seejärel `NULL` |
   | S2 | `\i sql/tests/samaaegsus/s2_a.sql`, siis kohe `COMMIT;` | `\i sql/tests/samaaegsus/s2_b.sql` | Vana versioon lükatakse tagasi: `NULL` |
   | S3, aktiveerimine enne | `\i sql/tests/samaaegsus/s3_aktiveeri_a.sql` | `\i sql/tests/samaaegsus/s3_aktiveeri_b.sql` | Ootab, seejärel `NULL` |
   | S3, eemaldamine enne | `\i sql/tests/samaaegsus/s3_eemalda_a.sql` | `\i sql/tests/samaaegsus/s3_eemalda_b.sql` | Ootab, seejärel `NULL` |
   | S4 | `\i sql/tests/samaaegsus/s4_a.sql` | `\i sql/tests/samaaegsus/s4_b.sql` | Teine aktiveerimine ootab, seejärel `NULL` |
   | S5, kustutamine enne | `\i sql/tests/samaaegsus/s5_kustuta_a.sql` | `\i sql/tests/samaaegsus/s5_kustuta_b.sql` | Ootab, seejärel `NULL` |
   | S5, variandi lisamine enne | `\i sql/tests/samaaegsus/s5_variant_a.sql` | `\i sql/tests/samaaegsus/s5_variant_b.sql` | Ootab, seejärel `CON008`; kaup kustutatakse |

   A tulemus on igas katses `CON008`. Välja arvatud S2, jäta A tehing lahti ja
   käivita B fail. B oote ajal kontrolli aknas A lukuootust:

   ```sql
   SELECT application_name,wait_event_type,wait_event FROM pg_stat_activity WHERE application_name='u8_b';
   ```

   `wait_event_type` peab olema `Lock`. Seejärel käivita A aknas `COMMIT;`,
   oota B tulemus ära ja käivita B aknas `COMMIT;`. S2 puhul on A juba kinnitatud.
   Pärast iga katset käivita A aknas:

   ```sql
   \i sql/tests/samaaegsus/kontrolli.sql
   ```

   Täpsem selgitus on [samaaegsuse juhendis](../sql/tests/samaaegsus/README.md).
   Automaatne `scripts/kontrolli_samaaegsust.sh` on teadlikult ainult kohalikuks
   testimiseks. Ummikseisu korral tuleb korrata kogu tehingut.

5. Kontrolli samas näidiskatses õigusi. Seadista näidiskaup uuesti ja leia
   omanikuühenduses kaubahalduri aadress. See ei ole konto parool.

   ```sql
   \i sql/tests/samaaegsus/seadista.sql
   SELECT i.e_meil FROM public.isik i JOIN public.tootaja t USING(isik_id) JOIN public.tootaja_rolli_omamine o USING(tootaja_id) JOIN public.tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY \gset
   BEGIN;
   SET LOCAL ROLE epood_rakendus;
   SELECT public.f_aktiveeri_kaup(p_kauba_kood:='CON008',p_e_meil:=:'e_meil');
   ROLLBACK;
   ```

   Funktsiooni tulemus peab olema `CON008`. `SET ROLE` vajab vastavat õigust;
   kui see puudub, jääb rollivahetuse katse tegemata, kuni õigus on eraldi
   lahendatud. Sama õigus on vajalik režiimis `testi` käivitatavale failile
   `sql/tests/16_rights.sql`; selle puudumisel katkeb testimine rollivahetuse
   veaga. Ära lisa selleks õigusi kontrollimatult. Kaks järgnevat käsku
   käivita käsureal eraldi: mõlemad peavad lõppema baastabeli juurdepääsuveaga.

   ```sh
   psql -X -v ON_ERROR_STOP=1 -c 'SET ROLE epood_rakendus; SELECT * FROM public.kaup;'
   psql -X -v ON_ERROR_STOP=1 -c "SET ROLE epood_rakendus; UPDATE public.kaup SET hind=hind WHERE kauba_kood='CON008';"
   ```

   Eemalda näidiskaup omanikuühenduses pärast kõiki katseid. Teised näidisandmed
   jäävad alles.

   ```sql
   DELETE FROM public.kaup WHERE kauba_kood='CON008';
   ```

6. Kontrolli pgApexis funktsiooni väljakutset rakenduse lehelt. Õnnestumisel
   tagastatakse kaubakood, keeldumisel pole tagastatavat väärtust (`NULL`).
   OP6 vorm loeb vaate `v_kaubad_muutmiseks` veeru `xmin` ja saadab selle tekstina
   argumendile `p_ver`. Kaks sama versiooni lugenud vormi ei tohi teineteise
   muudatusi üle kirjutada. Rakenduse päringud kasutavad seotud parameetreid.

7. Salvesta tegelik serveriversioon, server, andmebaasi nimi, arenduskeskkond,
   pgApexi aadress, rakenduse nimi ja kontrolliks mõeldud sisselogimisandmed
   dokumendi sissejuhatuse tabeli 1 vastavatesse lahtritesse. Konto peab olema
   selleks mõeldud piiratud testkonto; ära kasuta isiklikku parooli. Märgi üles
   testide kuupäev, tulemused ja tegemata katsed. Muuda dokumendi ning lisade
   kooliserveri ja pgApexi kohta käivaid „kontrollimata” väiteid alles siis, kui
   vastav kontroll on päriselt läbitud.

8. Eemaldamine on eraldi käsitsi tehtav otsus pärast andmebaasi nime ja
   varukoopia kontrollimist. Ära eemalda töötavat paigaldust, mida on veel vaja
   esitlemiseks. Skript `kontrolli_kooliserverit.sh` ise objekte ei kustuta.

   ```sh
   psql -X -v ON_ERROR_STOP=1 -f sql/19_drop_objects.sql
   psql -X -v ON_ERROR_STOP=1 -qAt -c "SELECT (SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind IN ('r','p','v','m','S','f')) AS seoseid, (SELECT count(*) FROM pg_proc WHERE pronamespace='public'::regnamespace) AS funktsioone, (SELECT count(*) FROM pg_type WHERE typnamespace='public'::regnamespace AND typtype='d') AS domeene, (SELECT count(*) FROM pg_namespace WHERE nspname IN ('valine','laiendused')) AS skeeme, (SELECT count(*) FROM pg_roles WHERE rolname='epood_rakendus') AS rolle, (SELECT count(*) FROM pg_foreign_server) AS valisservereid, (SELECT count(*) FROM pg_extension WHERE extname IN ('pgcrypto','postgres_fdw')) AS laiendusi, (SELECT count(*) FROM pg_default_acl) AS vaikimisi_oigusi;"
   ```

   Oodatav tulemus on `0|0|0|0|0|0|0|0` eraldi projektiandmebaasis.
