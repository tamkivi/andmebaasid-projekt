# Ü7: kaupade lugemisvaated

10.11.2026. Tehniline lisa. Kohalik PostgreSQLi kontroll on tehtud; Wordi lõppdokumenti
ülekandmine on veel tegemata.

Ülesanne 7 nõuab vähemalt nelja sisukat, kommenteeritud ja testandmetel ridu tagastavat
vaadet ning nende loomise, lugemise ja kustutamise lauseid. Siin on 12 lugemisvaadet.
Kõik kasutavad turvabarjääri, nimetatud veerge ja pgApexi jaoks ORDER BY klauslit.
Igal vaatel on INSERT-, UPDATE- ja DELETE-toimingud asendatud toimeta reegliga.
Neid reegleid ei arvestata kauba seisundimuudatusi jõustavate reeglitena.

## Kasutusjuhud ja rea tähendus

| Vaade | Kasutusjuht või eesmärk | Ühe rea tähendus |
|---|---|---|
| `v_kaubad_muutmiseks` | 5 ja 7, OP7.1; OP6 versioonikontroll | Ootel või mitteaktiivne kaup; sisaldab tegelikku `xmin` väärtust |
| `v_kaubad` | 8, OP8.1 | Iga kaup, ka lõpetatud; kategooriad ja variandid ei paljunda ridu |
| `v_kauba_kategooriad` | 2, 4 ja 8, OP2.2 | Kauba ja kategooria seos koos kategooria tüübi nimetusega |
| `v_kauba_variandid` | 2, 4 ja 8, OP2.4 | Kauba ja värvi seos |
| `v_kaupade_detailid` | 4 ja 8, OP4.1 ja OP8.2; OP3.1, OP6.1 ja OP9.1 nimekirjad | Iga kaup koos telefoni omaduste, seisundi, brändi ja registreerimisandmetega |
| `v_kaupade_koondaruanne` | 10, OP10.1 | Iga seisund, ka siis, kui selles pole kaupu |
| `v_aktiivsed_kaubad` | 11, OP11.2 | Aktiivse kauba ja kategooria paar; kategooriata kaubal üks tühja kategooriaga rida |
| `v_kategooriate_valikud` | 2, 4 ja 11, OP2.1 | Aktiivne kategooria koos aktiivse tüübi nimetusega |
| `v_varvide_valikud` | 2 ja 4, OP2.3 | Uuele variandile valitav aktiivne värv |
| `v_kaupade_kategooriate_loendid` | Kategooriate koondnimekiri | Iga kaup ja üks kategooriate ning tüüpide nimetusi sisaldav string |
| `v_kaupade_kategooriate_pingeread` | Kategooriate arvu võrdlus | Iga kauba kategooriate arv ning koht hõredas ja tihedas pingereas |
| `v_kaupade_json` | Hierarhiline andmevahetus | Iga kauba JSONB-objekt koos kategooriate objektide massiiviga |

Kasutusjuhu 1 kasutajatuvastamine kuulub eraldi töösse; selleks ei avaldata kontode
andmeid lugemisvaadetes. OP2.1 ja OP2.3 valikuvaated tulenevad lähteprojekti vormide
kirjeldusest. Muudest klassifikaatoritest üks-ühele koopiavaateid ei looda.

## Ühendamised ja pgApexi kasutus

Detailvaates on kauba kohustuslikud brändi-, seisundi- ja töötajaseosed INNER JOIN-id.
Töötajaviited osutavad töötaja, mitte otse isiku võtmele; seetõttu on mõlema töötajasildi
jaoks vaja töötaja ja isiku ühendamist. Nime puuduvat osa käsitleb `concat_ws`.
Telefonikirje ja selle klassifikaatorite LEFT JOIN-id säilitavad kauba ka siis, kui sellel
puudub nutitelefoni kirje. Kategooriad ja värvivariandid loetakse eraldi alamaruannetest.

Koondaruande aluseks on seisundite tabel ning kaupade arv leitakse `count(k.kaup_id)`
abil. Seetõttu ei muutu kaubata seisundi arv üheks. Aruanne järjestatakse arvu järgi
kahanevalt ja võrdse arvu korral suurtähtedega seisundinimetuse järgi kasvavalt.
Kataloogi seisund valitakse sisulise koodiga 2, mitte tehnilise identifikaatoriga.
Kategooriafiltriga leitakse soovitud seosed; ilma filtrita säilib ka kategooriata aktiivne kaup.
Suletud klassifikaatorite nimetused säilivad olemasolevate kaupade ja seoste juures,
kuigi neid ei pakuta uue seose valikus. Samanimeliste ühendamisveergude korral on
kasutatud USING-ut; eri rollides viiteveergude korral ON-i.

Ü7 juhendi järgi peab pgApexi aruanne koos detailivaatega kasutama sama andmebaasivaadet.
Kõigi kaupade lehe jaoks on selleks `v_kaupade_detailid`; aruanne kuvab selle veergudest
OP8.1 nimekirja alamhulga ja detailivorm OP8.2 väljad. Senine `v_kaubad` jääb alles
olemasoleva nimekirjaliidesena. `v_kauba_kategooriad` ja `v_kauba_variandid` on
kauba koodiga filtreeritavate alamaruannete allikad. Rakendust ennast ei ole veel loodud.

OP3.1 ootel kaupade nimekiri, OP6.1 aktiivsete kaupade nimekiri ja OP9.1 lõpetatavate
kaupade nimekiri kasutavad detailvaate `seisundi_kood` veergu vastavalt tingimustega
`= 1`, `= 2` ja `IN (2,3)`. Muutmisvorm loeb versioonitunnuse sama kauba kohta
vaatest `v_kaubad_muutmiseks`; `xmin` on endiselt tüüpi `xid`. Selle olemasolu ei
muuda lugemisvaadet kirjutusliideseks: muudatused tehakse lepinguliste rutiinidega.

Lähteprojekti §1.2.4 järgi esitatakse ajatemplid kujul `DD.MM.YYYY HH24:MI:SS`.
Vaated vormindavad need sõnaselgelt Eesti ajas, arvestades suve- ja talveaega.
Seetõttu on `v_kaubad_muutmiseks.reg_aeg` nüüd `text`, mitte `timestamptz`.
Olemasolevas paigalduses ei saa seda tüüpi vahetada CREATE OR REPLACE VIEW abil;
vajalik oleks eraldi sõltuvusi ja õigusi arvestav uuendus. Siinne skript on uue
paigalduse jaoks ega ole andmeid säilitav uuendusskript.

Kategoorialoend kasutab järjestatud `string_agg`-i ja tagastab kategooriata kaubal
tühja stringi. Pingereas on täpselt neli veergu; `rank()` ja `dense_rank()` arvestavad
ainult kategooriate arvu, et võrdsed arvud jääksid samale kohale. Kauba kood määrab
üksnes võrdsete ridade kuvamisjärjekorra. JSON-vaates on täpselt üks JSONB-veerg;
kategooriata kauba massiiv on `[]`. Hinnad on eurodes ja sisaldavad makse; rakenduse
väljasildid peavad näitama ühikuid ning eristama loetavaid ja muudetavaid välju.

## Loomine ja kommentaarid

Järgnev on [05_views.sql](../sql/05_views.sql) täielik sisu koos lugemisreeglitega.

```sql
-- Kaupade halduri lugemisliides.
CREATE VIEW v_kaubad_muutmiseks
    (kauba_kood,nimetus,seisundi_nimetus,hind,kirjeldus,pildi_aadress,reg_aeg,xmin)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,s.nimetus,k.hind,k.kirjeldus,k.pildi_aadress,
    to_char(k.reg_aeg AT TIME ZONE 'Europe/Tallinn','DD.MM.YYYY HH24:MI:SS'),k.xmin
FROM kaup AS k
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
WHERE s.kood IN (1,3)
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW v_kaubad_muutmiseks IS
    'Kasutusjuht Vaata kõiki ootel või mitteaktiivseid kaupu, OP7.1: halduri muudetavate kaupade nimekiri koos OP6 muutmise versioonitunnusega xmin. Seisund leitakse koodi, mitte surrogaat-ID järgi; registreerimise aeg on Eesti ajas kujul DD.MM.YYYY HH24:MI:SS. Ainult lugemiseks.';

CREATE VIEW v_kaubad
    (kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,b.nimetus,s.nimetus,k.hind,k.kirjeldus
FROM kaup AS k
INNER JOIN brand AS b USING (brand_id)
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW v_kaubad IS
    'Kasutusjuht Vaata kõiki kaupu, OP8.1: kõigi kaupade nimekiri, kaasa arvatud lõpetatud kaup. Iga kaup esineb korra; variante ja kategooriaid siia ei ühendata. Ainult lugemiseks.';

CREATE VIEW v_kauba_kategooriad
    (kauba_kood,kategooria_kood,kategooria_nimetus,kategooria_tyyp_kood,kategooria_tyyp_nimetus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,c.kood,c.nimetus,t.kood,t.nimetus
FROM kaup AS k
INNER JOIN kauba_kategooria_omamine AS o USING (kaup_id)
INNER JOIN kauba_kategooria AS c USING (kauba_kategooria_id)
INNER JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
ORDER BY k.kauba_kood,t.nimetus,c.nimetus,c.kood;
COMMENT ON VIEW v_kauba_kategooriad IS
    'Kauba halduri kauba vaatamise ja muutmise vormi kategooriaseosed, OP2.2. Iga kauba ja kategooria paar esineb korra; kategooriata kaubal seoseridu ei ole. Ainult lugemiseks.';

CREATE VIEW v_kauba_variandid
    (kauba_kood,varvi_kood,varvi_nimetus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,v.kood,v.nimetus
FROM kaup AS k
INNER JOIN kauba_variant AS kv USING (kaup_id)
INNER JOIN varv AS v USING (varv_id)
ORDER BY k.kauba_kood,v.nimetus,v.kood;
COMMENT ON VIEW v_kauba_variandid IS
    'Kauba halduri kauba vaatamise ja muutmise vormi värvivariandid, OP2.4. Sama kauba ja värvi paar esineb korra. Ainult lugemiseks.';

-- Detailvorm ei ühenda mitmeväärtuselisi kategooriaid ega värvivariante.
CREATE VIEW v_kaupade_detailid
    (kauba_kood,nimetus,brand_nimetus,seisundi_kood,seisundi_nimetus,hind,
     eesmine_kaamera,tagumine_kaamera,sisemalu,ekraani_diagonaal,protsessor,
     ekraani_resolutsioon,ekraani_laius_pikslites,ekraani_korgus_pikslites,
     on_sormejalelugeja,on_veekindel,kirjeldus,pildi_aadress,
     registreerimise_aeg,viimase_muutmise_aeg,registreerija,viimane_muutja)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,b.nimetus,s.kood,s.nimetus,k.hind,
    e.nimetus,t.nimetus,m.nimetus,d.nimetus,p.nimetus,r.nimetus,
    r.horisontaalne,r.vertikaalne,n.on_sormejalelugeja,n.on_veekindel,
    k.kirjeldus,k.pildi_aadress,
    to_char(k.reg_aeg AT TIME ZONE 'Europe/Tallinn','DD.MM.YYYY HH24:MI:SS'),
    to_char(k.viimase_muutm_aeg AT TIME ZONE 'Europe/Tallinn','DD.MM.YYYY HH24:MI:SS'),
    concat_ws(' ',ri.eesnimi,ri.perenimi) || ' (' || ri.e_meil || ')',
    concat_ws(' ',mi.eesnimi,mi.perenimi) || ' (' || mi.e_meil || ')'
FROM kaup AS k
INNER JOIN brand AS b USING (brand_id)
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
INNER JOIN (tootaja AS rt INNER JOIN isik AS ri USING (isik_id))
    ON rt.tootaja_id=k.registreerija_id
INNER JOIN (tootaja AS mt INNER JOIN isik AS mi USING (isik_id))
    ON mt.tootaja_id=k.viimase_muutja_id
LEFT JOIN nutitelefon AS n USING (kaup_id)
LEFT JOIN kaamera AS e ON e.kaamera_id=n.eesmine_kaamera_id
LEFT JOIN kaamera AS t ON t.kaamera_id=n.tagumine_kaamera_id
LEFT JOIN sisemalu AS m USING (sisemalu_id)
LEFT JOIN diagonaal AS d USING (diagonaal_id)
LEFT JOIN protsessor AS p USING (protsessor_id)
LEFT JOIN ekraani_resolutsioon AS r USING (ekraani_resolutsioon_id)
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW v_kaupade_detailid IS
    'Kasutusjuhud Muuda kaupa (OP4.1) ja Vaata kõiki kaupu (OP8.2): üks rida iga kauba kohta koos brändi, seisundi ja telefoni tehniliste näitajate nimetustega. Kaup, millel puudub nutitelefoni kirje, säilib tühjade tehniliste väljadega. Registreerija ja viimase muutja nimi koos meiliaadressiga eristab samanimelisi töötajaid; ajad on Eesti ajas kujul DD.MM.YYYY HH24:MI:SS. Seisundikoodiga filtreeritakse OP3.1 (1), OP6.1 (2) ja OP9.1 (2,3) nimekirju. Ainult lugemiseks.';

CREATE VIEW v_kaupade_koondaruanne
    (seisundi_kood,seisundi_nimetus,kaupade_arv)
    WITH (security_barrier=true) AS
SELECT s.kood,upper(s.nimetus),count(k.kaup_id) AS kaupade_arv
FROM kauba_seisundi_liik AS s
LEFT JOIN kaup AS k USING (kauba_seisundi_liik_id)
GROUP BY s.kauba_seisundi_liik_id,s.kood,s.nimetus
ORDER BY kaupade_arv DESC,upper(s.nimetus),s.kood;
COMMENT ON VIEW v_kaupade_koondaruanne IS
    'Kasutusjuht Vaata kaupade koondaruannet, OP10.1: juhataja näeb iga registreeritud seisundi koodi, suurtähtedega nimetust ja kaupade arvu; kaubata seisundi korral on arv 0. Esmalt kuvatakse suurima kaupade arvuga seisundid; viigid lahendatakse nimetuse järgi tähestiku järjekorras. Ainult lugemiseks.';

CREATE VIEW v_aktiivsed_kaubad
    (kauba_kood,nimetus,kategooria_kood,kategooria_nimetus,
     kategooria_tyyp_nimetus,hind,kirjeldus,pildi_aadress)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,c.kood,c.nimetus,t.nimetus,
    k.hind,k.kirjeldus,k.pildi_aadress
FROM kaup AS k
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
LEFT JOIN kauba_kategooria_omamine AS o USING (kaup_id)
LEFT JOIN kauba_kategooria AS c USING (kauba_kategooria_id)
LEFT JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
WHERE s.kood=2
ORDER BY k.nimetus,k.kauba_kood,t.nimetus,c.nimetus,c.kood;
COMMENT ON VIEW v_aktiivsed_kaubad IS
    'Kasutusjuht Vaata aktiivseid kaupu, OP11.2: kliendi ja uudistaja kataloog, mida filtreeritakse valitud kategooria koodi järgi. Üks rida iga aktiivse kauba ja kategooria paari kohta; kategooriata aktiivne kaup esineb ühe tühja kategooriaga reana. Registreerimisandmeid ega töötajate andmeid ei avaldata. Ainult lugemiseks.';

CREATE VIEW v_kategooriate_valikud
    (kategooria_kood,kategooria_nimetus,kategooria_tyyp_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus,t.nimetus
FROM kauba_kategooria AS c
INNER JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
WHERE c.on_aktiivne AND t.on_aktiivne
ORDER BY t.nimetus,c.nimetus,c.kood;
COMMENT ON VIEW v_kategooriate_valikud IS
    'Kasutusjuhud Registreeri nutitelefon, Muuda kaupa ja Vaata aktiivseid kaupu, OP2.1: valikusse sobivad aktiivsed kategooriad koos aktiivse kategooriatüübi nimetusega. Tüübi nimetus eristab samanimelisi kategooriaid; kood on seose salvestamise ja kataloogi filtreerimise võti. Ainult lugemiseks.';

CREATE VIEW v_varvide_valikud
    (varvi_kood,varvi_nimetus)
    WITH (security_barrier=true) AS
SELECT v.kood,v.nimetus
FROM varv AS v
WHERE v.on_aktiivne
ORDER BY v.nimetus,v.kood;
COMMENT ON VIEW v_varvide_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP2.3: uue kaubavariandi värvi valimiseks näidatakse ainult aktiivseid värvinimetusi koos seose salvestamiseks vajaliku sisulise koodiga. Olemasolevad variandid jäävad nähtavaks eraldi variandivaates ka värvi sulgemisel. Ainult lugemiseks.';

-- Kategooriate koondkujud säilitavad ka ühegi kategooriata kaubad.
CREATE VIEW v_kaupade_kategooriate_loendid
    (kauba_kood,nimetus,kategooriad)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,
    coalesce(string_agg(c.nimetus || ' (' || t.nimetus || ')',', '
        ORDER BY t.nimetus,c.nimetus,c.kood)
        FILTER (WHERE c.kauba_kategooria_id IS NOT NULL),'')
FROM kaup AS k
LEFT JOIN kauba_kategooria_omamine AS o USING (kaup_id)
LEFT JOIN kauba_kategooria AS c USING (kauba_kategooria_id)
LEFT JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
GROUP BY k.kaup_id,k.kauba_kood,k.nimetus
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW v_kaupade_kategooriate_loendid IS
    'Halduri ülevaade: üks rida iga kauba kohta, mille kategooriate ja nende tüüpide nimetused on koondatud ühte järjestatud stringi kujul kategooria (tüüp). Kategooriata kauba loend on tühi string. Koondkuju võimaldab näidata kategooriaid kaupade ridu paljundamata. Ainult lugemiseks.';

CREATE VIEW v_kaupade_kategooriate_pingeread
    (kauba_kood,kategooriate_arv,hore_koht,tihe_koht)
    WITH (security_barrier=true) AS
WITH kategooriate_arvud AS (
    SELECT k.kauba_kood,count(o.kauba_kategooria_id) AS kategooriate_arv
    FROM kaup AS k
    LEFT JOIN kauba_kategooria_omamine AS o USING (kaup_id)
    GROUP BY k.kaup_id,k.kauba_kood
)
SELECT kauba_kood,kategooriate_arv,
    rank() OVER (ORDER BY kategooriate_arv DESC),
    dense_rank() OVER (ORDER BY kategooriate_arv DESC)
FROM kategooriate_arvud
ORDER BY kategooriate_arv DESC,kauba_kood;
COMMENT ON VIEW v_kaupade_kategooriate_pingeread IS
    'Halduri kategooriaseoste võrdlus: iga kauba kood, kategooriate arv ning koht hõredas ja tihedas pingereas. Suurima kategooriate arvuga kaup on esimene; võrdse arvuga kaubad jagavad kohta. Kategooriata kaup osaleb arvuga null. Kauba koodi järgi järjestamine ei muuda jagatud kohti. Ainult lugemiseks.';

CREATE VIEW v_kaupade_json
    (kauba_json)
    WITH (security_barrier=true) AS
SELECT jsonb_build_object(
    'kauba_kood',k.kauba_kood,'nimetus',k.nimetus,
    'brand',b.nimetus,'seisund',s.nimetus,
    'hind',k.hind,'kirjeldus',k.kirjeldus,
    'kategooriad',coalesce(
        jsonb_agg(jsonb_build_object('kategooria',c.nimetus,'tyyp',t.nimetus)
            ORDER BY t.nimetus,c.nimetus,c.kood)
            FILTER (WHERE c.kauba_kategooria_id IS NOT NULL),'[]'::jsonb))
FROM kaup AS k
INNER JOIN brand AS b USING (brand_id)
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
LEFT JOIN kauba_kategooria_omamine AS o USING (kaup_id)
LEFT JOIN kauba_kategooria AS c USING (kauba_kategooria_id)
LEFT JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
GROUP BY k.kaup_id,k.kauba_kood,k.nimetus,b.nimetus,s.nimetus,k.hind,k.kirjeldus
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW v_kaupade_json IS
    'Kaupade hierarhiline lugemismudel: täpselt üks JSONB-veerg ja üks rida iga kauba kohta. Kauba objekti sees on kategooriate objektide massiiv, mille liikmed esitavad kategooria ja tüübi nimetuse. Kategooriata kaubal on tühi massiiv, mitte üks nullväärtustega objekt. Sobib struktuurseks andmevahetuseks. Ainult lugemiseks.';

-- Lugemisvaadete kaudu tehtavad muutmiskatsed ei muuda baastabeleid.
CREATE RULE r_v_kaubad_muutmiseks_insert AS
    ON INSERT TO v_kaubad_muutmiseks DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_muutmiseks_update AS
    ON UPDATE TO v_kaubad_muutmiseks DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_muutmiseks_delete AS
    ON DELETE TO v_kaubad_muutmiseks DO INSTEAD NOTHING;

CREATE RULE r_v_kaubad_insert AS
    ON INSERT TO v_kaubad DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_update AS
    ON UPDATE TO v_kaubad DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_delete AS
    ON DELETE TO v_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_kategooriad_insert AS
    ON INSERT TO v_kauba_kategooriad DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_kategooriad_update AS
    ON UPDATE TO v_kauba_kategooriad DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_kategooriad_delete AS
    ON DELETE TO v_kauba_kategooriad DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_variandid_insert AS
    ON INSERT TO v_kauba_variandid DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_variandid_update AS
    ON UPDATE TO v_kauba_variandid DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_variandid_delete AS
    ON DELETE TO v_kauba_variandid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_insert AS
    ON INSERT TO v_kaupade_detailid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_update AS
    ON UPDATE TO v_kaupade_detailid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_delete AS
    ON DELETE TO v_kaupade_detailid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_koondaruanne_insert AS
    ON INSERT TO v_kaupade_koondaruanne DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_koondaruanne_update AS
    ON UPDATE TO v_kaupade_koondaruanne DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_koondaruanne_delete AS
    ON DELETE TO v_kaupade_koondaruanne DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_insert AS
    ON INSERT TO v_aktiivsed_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_update AS
    ON UPDATE TO v_aktiivsed_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_delete AS
    ON DELETE TO v_aktiivsed_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_insert AS
    ON INSERT TO v_kategooriate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_update AS
    ON UPDATE TO v_kategooriate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_delete AS
    ON DELETE TO v_kategooriate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_varvide_valikud_insert AS
    ON INSERT TO v_varvide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_varvide_valikud_update AS
    ON UPDATE TO v_varvide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_varvide_valikud_delete AS
    ON DELETE TO v_varvide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_loendid_insert AS
    ON INSERT TO v_kaupade_kategooriate_loendid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_loendid_update AS
    ON UPDATE TO v_kaupade_kategooriate_loendid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_loendid_delete AS
    ON DELETE TO v_kaupade_kategooriate_loendid DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_pingeread_insert AS
    ON INSERT TO v_kaupade_kategooriate_pingeread DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_pingeread_update AS
    ON UPDATE TO v_kaupade_kategooriate_pingeread DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_kategooriate_pingeread_delete AS
    ON DELETE TO v_kaupade_kategooriate_pingeread DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_json_insert AS
    ON INSERT TO v_kaupade_json DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_json_update AS
    ON UPDATE TO v_kaupade_json DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_json_delete AS
    ON DELETE TO v_kaupade_json DO INSTEAD NOTHING;
```

## Lugemine ja kontroll

Iga vaate täieliku tulemuse kontrollpäring:

```sql
SELECT * FROM public.v_kaubad_muutmiseks;
SELECT * FROM public.v_kaubad;
SELECT * FROM public.v_kauba_kategooriad;
SELECT * FROM public.v_kauba_variandid;
SELECT * FROM public.v_kaupade_detailid;
SELECT * FROM public.v_kaupade_koondaruanne;
SELECT * FROM public.v_aktiivsed_kaubad;
SELECT * FROM public.v_kategooriate_valikud;
SELECT * FROM public.v_varvide_valikud;
SELECT * FROM public.v_kaupade_kategooriate_loendid;
SELECT * FROM public.v_kaupade_kategooriate_pingeread;
SELECT * FROM public.v_kaupade_json;
```

Üheveeruline kaubakoodide päring hierarhilise esituse põhjal:

```sql
SELECT kauba_json->>'kauba_kood' AS kauba_kood
FROM public.v_kaupade_json
ORDER BY kauba_kood;
```

Rakenduse päringutes kirjutatakse vajalikud veerud nimeliselt välja; eelnev `SELECT *`
on juhendis nõutud kontrollpäring. Kategooriafiltri parameeter antakse rakenduses seotud
parameetrina, mitte päringuteksti sisse liidetud kasutajasisendina.

Uues eraldatud projektikeskkonnas laaditakse kõigepealt Ü5 andmed `run_u5.sql` abil,
seejärel käivitatakse `05_views.sql`, `09_rutiinid.sql`, `14_statistics.sql` ja
`16_rights.sql`. Viimane loob serveriülese rolli; olemasolevat samanimelist rolli ei
muudeta pimesi. Rakenduserolli vaadete lugemisõigused on:

```sql
GRANT SELECT ON v_kaubad_muutmiseks,v_kaubad,v_kauba_kategooriad,v_kauba_variandid,
    v_kaupade_detailid,v_kaupade_koondaruanne,v_aktiivsed_kaubad,
    v_kategooriate_valikud,v_varvide_valikud,v_kaupade_kategooriate_loendid,
    v_kaupade_kategooriate_pingeread,v_kaupade_json
    TO epood_rakendus;
```

[tests/05_views.sql](../sql/tests/05_views.sql) säilitab senised kontrollid ning lisab
kõigi 12 vaate olemasolu, kommentaaride, turvabarjääri, järjestuse, õigete veergude,
vähemalt ühe tulemuse rea ning kolme toimeta muutmisreegli kontrollid. Võrreldakse
kõigi 24 baastabeli sisu enne ja pärast vaadete kaudu tehtud muutmiskatseid.
Piirjuhtude andmed pööratakse tagasi: kaubata seisund, telefonikirjeta ja kategooriata
kaup, eri seisundid, pingerea viigid, nimede puuduvad osad ning suve- ja talveaeg.
Kontrollitakse nii suletud kategooriat kui ka suletud tüüpi ja värvi.

[tests/16_rights.sql](../sql/tests/16_rights.sql) loeb kõiki vaateid rakenduserollina ning
proovib nende kaudu lisamist, muutmist ja kustutamist. Baastabelite otseõigusi ega
õiguste edasijagamist ei anta. [tests/run_all.sql](../sql/tests/run_all.sql) käivitab
vaadete kontrolli ka pärast Ü5 korduvlaadimist. Õiguste test saab vajaliku välise
tehingu; oma tehingutega laadijaid ei pakita sellesse tehingusse.

10.11.2026 läbisid eraldatud PostgreSQL 17.10 klastris kõik 11 integreeritud komplekti,
Ü5 korduvlaadimine ja eraldi olemasolev Ü6 migratsioonikomplekt. Eemaldamine andis
null projektiobjekti; seejärel ehitati sama eraldatud baas uuesti ja kontrolliti uuesti.
Kõik vaated tagastasid projekti testandmetel vähemalt ühe rea. Uusi püsivaid testandmeid
ei olnud vaja lisada. Hilisemad kommentaaride sõnastusparandused ei muutnud vaadete
alampäringuid ega reegleid.

## Kustutamine

Vaadete kustutamise laused on [19_drop_objects.sql](../sql/19_drop_objects.sql) osa.
Vaate kustutamisel eemaldatakse ka selle reeglid. Kõik vaated põhinevad baastabelitel,
mitte teistel vaadetel. Need eemaldatakse enne baastabeleid; domeen eemaldatakse
alles pärast sõltuvaid tabeleid ja muid objekte RESTRICT-valikuga.

```sql
DROP VIEW v_kaupade_json;
DROP VIEW v_kaupade_kategooriate_pingeread;
DROP VIEW v_kaupade_kategooriate_loendid;
DROP VIEW v_kaupade_detailid;
DROP VIEW v_kaupade_koondaruanne;
DROP VIEW v_aktiivsed_kaubad;
DROP VIEW v_kategooriate_valikud;
DROP VIEW v_varvide_valikud;
DROP VIEW v_kaubad_muutmiseks;
DROP VIEW v_kaubad;
DROP VIEW v_kauba_kategooriad;
DROP VIEW v_kauba_variandid;
```

Kustutamist kontrolliti ainult eraldatud kohalikus testkeskkonnas. Kooliserveri
PostgreSQL 18, tegelik välisallikas, üliõpilase õigused, mitte-superkasutaja välisühendus,
rakenduse kasutajatuvastamine ja pgApexi lehed on endiselt kontrollimata.

## Allikad ja dokumendi seis

Aluseks on Ülesande 7 täistekst (§3–4 ja §7), hindamismudeli v1.2 kõigi töölehtede
väljavõte (eriti andmebaasi kriteeriumid 5, 59–63 ning lisapunktid 1–4 ja 11),
lähteprojekti kasutusjuhud 1–11 ja §1.2.4 ning [töökoha juhend](ulesanded/epood-ab2-guide-2026-09-20.md).
Hindamismudeli eraldi CSV on ainult esimese töölehe väljavõte, mitte kogu mudel.
Päritolu: [Maurus, aine 391](https://maurus.ttu.ee/aine_index.php?aine=391).

Wordi lõppdokumenti tuleb veel kanda nii [Ü6 domeenilisa](u6-domeenid.md) kui ka
siinsed vaated, kommentaarid ja kontroll- ning kustutamislaused. Peatüki 5 nõutud
ajakohastamine jääb eraldi tööks. Tehniline lisa ei kinnita kooliserveri paigaldust,
rakenduse valmimist ega projekti esitamist.
