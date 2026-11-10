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
    'Kasutusjuhud Muuda kaupa (OP4.1) ja Vaata kõiki kaupu (OP8.2): üks rida iga kauba kohta koos brändi, seisundi ja telefoni tehniliste näitajate nimetustega. Telefonialaliigita kaup säilib tühjade tehniliste väljadega. Registreerija ja viimase muutja nimi koos meiliaadressiga eristab samanimelisi töötajaid; ajad on Eesti ajas kujul DD.MM.YYYY HH24:MI:SS. Seisundikoodiga filtreeritakse OP3.1 (1), OP6.1 (2) ja OP9.1 (2,3) nimekirju. Ainult lugemiseks.';

CREATE VIEW v_kaupade_koondaruanne
    (seisundi_kood,seisundi_nimetus,kaupade_arv)
    WITH (security_barrier=true) AS
SELECT s.kood,upper(s.nimetus),count(k.kaup_id) AS kaupade_arv
FROM kauba_seisundi_liik AS s
LEFT JOIN kaup AS k USING (kauba_seisundi_liik_id)
GROUP BY s.kauba_seisundi_liik_id,s.kood,s.nimetus
ORDER BY kaupade_arv DESC,upper(s.nimetus),s.kood;
COMMENT ON VIEW v_kaupade_koondaruanne IS
    'Kasutusjuht Vaata kaupade koondaruannet, OP10.1: juhataja näeb iga registreeritud seisundi koodi, suurtähtedega nimetust ja kaupade arvu, ka tühja seisundi korral nulli. Esmalt kuvatakse suurima kaupade arvuga seisundid; viigid lahendatakse nimetuse järgi tähestiku järjekorras. Ainult lugemiseks.';

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
    'Halduri kategooriaseoste võrdlus: iga kauba kood, kategooriate arv ning koht hõredas ja tihedas pingereas. Suurima kategooriate arvuga kaup on esimene; võrdse arvuga kaubad jagavad kohta. Kategooriata kaup osaleb arvuga null. Lõplik koodijärjestus ei lõhu viike. Ainult lugemiseks.';

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
