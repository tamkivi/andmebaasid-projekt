-- Kaupade halduri lehtede lugemisliides ja vormide sisendite kohandus.
START TRANSACTION;

CREATE VIEW public.v_ootel_kaubad
    (kauba_kood,nimetus,hind,kirjeldus,pildi_aadress,reg_aeg)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,k.hind,k.kirjeldus,k.pildi_aadress,
    to_char(k.reg_aeg AT TIME ZONE 'Europe/Tallinn','DD.MM.YYYY HH24:MI:SS')
FROM public.kaup AS k
INNER JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
WHERE s.kood=1
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW public.v_ootel_kaubad IS
    'Kasutusjuht Unusta kaup, OP3.1: üks rida iga sobivas seisundis kauba kohta. Seisund leitakse koodi järgi; registreerimise aeg on Eesti ajas kujul DD.MM.YYYY HH24:MI:SS. Ainult lugemiseks.';

CREATE VIEW public.v_aktiivsed_kaubad_haldurile
    (kauba_kood,nimetus,hind,kirjeldus,pildi_aadress,reg_aeg)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,k.hind,k.kirjeldus,k.pildi_aadress,
    to_char(k.reg_aeg AT TIME ZONE 'Europe/Tallinn','DD.MM.YYYY HH24:MI:SS')
FROM public.kaup AS k
INNER JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
WHERE s.kood=2
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW public.v_aktiivsed_kaubad_haldurile IS
    'Kasutusjuht Muuda kaup mitteaktiivseks, OP6.1: üks rida iga sobivas seisundis kauba kohta. Seisund leitakse koodi järgi; registreerimise aeg on Eesti ajas kujul DD.MM.YYYY HH24:MI:SS. Ainult lugemiseks.';

CREATE VIEW public.v_kauba_muutmise_vorm
    (kauba_kood,ver,nimetus,hind,kirjeldus,pildi_aadress,brandi_kood,
     on_veekindel,on_sormejalelugeja,eesmise_kaamera_kood,tagumise_kaamera_kood,
     sisemalu_kood,diagonaali_kood,protsessori_kood,ekraani_resolutsiooni_kood)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.xmin::text,k.nimetus,k.hind,k.kirjeldus,k.pildi_aadress,b.kood,
    nullif(n.on_veekindel,FALSE),nullif(n.on_sormejalelugeja,FALSE),e.kood,t.kood,
    m.kood,d.kood,p.kood,r.kood
FROM public.kaup AS k
INNER JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
INNER JOIN public.brand AS b USING (brand_id)
INNER JOIN public.nutitelefon AS n USING (kaup_id)
INNER JOIN public.kaamera AS e ON e.kaamera_id=n.eesmine_kaamera_id
INNER JOIN public.kaamera AS t ON t.kaamera_id=n.tagumine_kaamera_id
INNER JOIN public.sisemalu AS m USING (sisemalu_id)
INNER JOIN public.diagonaal AS d USING (diagonaal_id)
INNER JOIN public.protsessor AS p USING (protsessor_id)
INNER JOIN public.ekraani_resolutsioon AS r USING (ekraani_resolutsioon_id)
WHERE s.kood IN (1,3)
ORDER BY k.nimetus,k.kauba_kood;
COMMENT ON VIEW public.v_kauba_muutmise_vorm IS
    'Kasutusjuht Muuda kaupa, OP4.1: ootel ja mitteaktiivse nutitelefoni vormi eeltäitmine sisuliste koodide ja tegeliku xmin-versiooniga. FALSE esitatakse NULL-ina, sest pgApex märgib iga mittetühja eeltäitega märkeruudu valituks; vormifunktsioon taastab FALSE-i. Ainult lugemiseks.';

CREATE VIEW public.v_brandide_valikud
    (brandi_kood,brandi_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.brand AS c
WHERE c.on_aktiivne
ORDER BY c.nimetus,c.kood;
COMMENT ON VIEW public.v_brandide_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori brand aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_kaamerate_valikud
    (kaamera_kood,kaamera_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.kaamera AS c
WHERE c.on_aktiivne
ORDER BY c.kood;
COMMENT ON VIEW public.v_kaamerate_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori kaamera aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_sisemalude_valikud
    (sisemalu_kood,sisemalu_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.sisemalu AS c
WHERE c.on_aktiivne
ORDER BY c.kood;
COMMENT ON VIEW public.v_sisemalude_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori sisemalu aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_diagonaalide_valikud
    (diagonaali_kood,diagonaali_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.diagonaal AS c
WHERE c.on_aktiivne
ORDER BY c.kood;
COMMENT ON VIEW public.v_diagonaalide_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori diagonaal aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_protsessorite_valikud
    (protsessori_kood,protsessori_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.protsessor AS c
WHERE c.on_aktiivne
ORDER BY c.nimetus,c.kood;
COMMENT ON VIEW public.v_protsessorite_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori protsessor aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_ekraani_resolutsioonide_valikud
    (ekraani_resolutsiooni_kood,ekraani_resolutsiooni_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus
FROM public.ekraani_resolutsioon AS c
WHERE c.on_aktiivne
ORDER BY c.nimetus,c.kood;
COMMENT ON VIEW public.v_ekraani_resolutsioonide_valikud IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP1 ja OP6: klassifikaatori ekraani_resolutsioon aktiivsete väärtuste valik. Vorm näitab nimetust ja edastab sisulise koodi; tehnilist identifikaatorit ei avaldata. Ainult lugemiseks.';

CREATE VIEW public.v_kategooriate_valikud_tyybiga
    (kategooria_kood,valiku_nimetus)
    WITH (security_barrier=true) AS
SELECT c.kood,c.nimetus || ' (' || t.nimetus || ')'
FROM public.kauba_kategooria AS c
INNER JOIN public.kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
WHERE c.on_aktiivne AND t.on_aktiivne
ORDER BY t.nimetus,c.nimetus,c.kood;
COMMENT ON VIEW public.v_kategooriate_valikud_tyybiga IS
    'Kasutusjuhud Registreeri nutitelefon ja Muuda kaupa, OP2.1: aktiivse tüübi aktiivsed kategooriad. Kategooria ja tüübi ühine silt eristab eri tüüpide samanimelisi kategooriaid ühe valikuvälja sees. Ainult lugemiseks.';

CREATE VIEW public.v_kaupade_detailid_seostega
    (kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus,pildi_aadress,
     eesmine_kaamera,tagumine_kaamera,sisemalu,ekraani_diagonaal,protsessor,
     ekraani_resolutsioon,on_sormejalelugeja,on_veekindel,kategooriad,variandid,
     registreerimise_aeg,viimase_muutmise_aeg,registreerija,viimane_muutja)
    WITH (security_barrier=true) AS
SELECT d.kauba_kood,d.nimetus,d.brand_nimetus,d.seisundi_nimetus,d.hind,
    d.kirjeldus,d.pildi_aadress,d.eesmine_kaamera,d.tagumine_kaamera,d.sisemalu,
    d.ekraani_diagonaal,d.protsessor,d.ekraani_resolutsioon,
    CASE d.on_sormejalelugeja WHEN TRUE THEN 'Jah' WHEN FALSE THEN 'Ei' ELSE '' END,
    CASE d.on_veekindel WHEN TRUE THEN 'Jah' WHEN FALSE THEN 'Ei' ELSE '' END,
    c.kategooriad,coalesce(v.variandid,''),d.registreerimise_aeg,
    d.viimase_muutmise_aeg,d.registreerija,d.viimane_muutja
FROM public.v_kaupade_detailid AS d
INNER JOIN public.v_kaupade_kategooriate_loendid AS c USING (kauba_kood)
LEFT JOIN (
    SELECT kv.kauba_kood,string_agg(kv.varvi_nimetus,', '
        ORDER BY kv.varvi_nimetus,kv.varvi_kood) AS variandid
    FROM public.v_kauba_variandid AS kv
    GROUP BY kv.kauba_kood
) AS v USING (kauba_kood)
ORDER BY d.nimetus,d.kauba_kood;
COMMENT ON VIEW public.v_kaupade_detailid_seostega IS
    'Kasutusjuht Vaata kõiki kaupu, OP8.1 ja OP8.2: nimekiri ja detailvaade kasutavad sama allikat. Ü7 detailid ning kategoorialoend on taaskasutatud; värvid koondatakse enne ühendamist, et seosed ei paljundaks kaubaridu. Ka seosteta ja lõpetatud kaup säilib; tõeväärtused on Jah või Ei. Ainult lugemiseks.';

CREATE RULE r_v_ootel_kaubad_insert AS
    ON INSERT TO public.v_ootel_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_ootel_kaubad_update AS
    ON UPDATE TO public.v_ootel_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_ootel_kaubad_delete AS
    ON DELETE TO public.v_ootel_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_haldurile_insert AS
    ON INSERT TO public.v_aktiivsed_kaubad_haldurile DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_haldurile_update AS
    ON UPDATE TO public.v_aktiivsed_kaubad_haldurile DO INSTEAD NOTHING;

CREATE RULE r_v_aktiivsed_kaubad_haldurile_delete AS
    ON DELETE TO public.v_aktiivsed_kaubad_haldurile DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_muutmise_vorm_insert AS
    ON INSERT TO public.v_kauba_muutmise_vorm DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_muutmise_vorm_update AS
    ON UPDATE TO public.v_kauba_muutmise_vorm DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_muutmise_vorm_delete AS
    ON DELETE TO public.v_kauba_muutmise_vorm DO INSTEAD NOTHING;

CREATE RULE r_v_brandide_valikud_insert AS
    ON INSERT TO public.v_brandide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_brandide_valikud_update AS
    ON UPDATE TO public.v_brandide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_brandide_valikud_delete AS
    ON DELETE TO public.v_brandide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kaamerate_valikud_insert AS
    ON INSERT TO public.v_kaamerate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kaamerate_valikud_update AS
    ON UPDATE TO public.v_kaamerate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kaamerate_valikud_delete AS
    ON DELETE TO public.v_kaamerate_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_sisemalude_valikud_insert AS
    ON INSERT TO public.v_sisemalude_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_sisemalude_valikud_update AS
    ON UPDATE TO public.v_sisemalude_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_sisemalude_valikud_delete AS
    ON DELETE TO public.v_sisemalude_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_diagonaalide_valikud_insert AS
    ON INSERT TO public.v_diagonaalide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_diagonaalide_valikud_update AS
    ON UPDATE TO public.v_diagonaalide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_diagonaalide_valikud_delete AS
    ON DELETE TO public.v_diagonaalide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_protsessorite_valikud_insert AS
    ON INSERT TO public.v_protsessorite_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_protsessorite_valikud_update AS
    ON UPDATE TO public.v_protsessorite_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_protsessorite_valikud_delete AS
    ON DELETE TO public.v_protsessorite_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_ekraani_resolutsioonide_valikud_insert AS
    ON INSERT TO public.v_ekraani_resolutsioonide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_ekraani_resolutsioonide_valikud_update AS
    ON UPDATE TO public.v_ekraani_resolutsioonide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_ekraani_resolutsioonide_valikud_delete AS
    ON DELETE TO public.v_ekraani_resolutsioonide_valikud DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_tyybiga_insert AS
    ON INSERT TO public.v_kategooriate_valikud_tyybiga DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_tyybiga_update AS
    ON UPDATE TO public.v_kategooriate_valikud_tyybiga DO INSTEAD NOTHING;

CREATE RULE r_v_kategooriate_valikud_tyybiga_delete AS
    ON DELETE TO public.v_kategooriate_valikud_tyybiga DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_seostega_insert AS
    ON INSERT TO public.v_kaupade_detailid_seostega DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_seostega_update AS
    ON UPDATE TO public.v_kaupade_detailid_seostega DO INSTEAD NOTHING;

CREATE RULE r_v_kaupade_detailid_seostega_delete AS
    ON DELETE TO public.v_kaupade_detailid_seostega DO INSTEAD NOTHING;

CREATE OR REPLACE FUNCTION public.f_registreeri_nutitelefon_vormist(
    p_kauba_kood kaup.kauba_kood%TYPE,
    p_nimetus kaup.nimetus%TYPE,
    p_hind kaup.hind%TYPE,
    p_kirjeldus kaup.kirjeldus%TYPE,
    p_pildi_aadress kaup.pildi_aadress%TYPE,
    p_e_meil isik.e_meil%TYPE,
    p_brandi_kood brand.kood%TYPE,
    p_on_veekindel nutitelefon.on_veekindel%TYPE,
    p_on_sormejalelugeja nutitelefon.on_sormejalelugeja%TYPE,
    p_kaamera_kood_eesmine kaamera.kood%TYPE,
    p_kaamera_kood_tagumine kaamera.kood%TYPE,
    p_sisemalu_kood sisemalu.kood%TYPE,
    p_diagonaali_kood diagonaal.kood%TYPE,
    p_protsessori_kood protsessor.kood%TYPE,
    p_ekraani_resolutsiooni_kood ekraani_resolutsioon.kood%TYPE)
RETURNS public.kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY INVOKER
SET search_path = public, pg_temp
BEGIN ATOMIC
SELECT public.f_registreeri_nutitelefon(
    p_kauba_kood:=p_kauba_kood,
    p_nimetus:=p_nimetus,
    p_hind:=p_hind,
    p_kirjeldus:=p_kirjeldus,
    p_pildi_aadress:=p_pildi_aadress,
    p_e_meil:=p_e_meil,
    p_brandi_kood:=p_brandi_kood,
    p_on_veekindel:=coalesce(p_on_veekindel,FALSE),
    p_on_sormejalelugeja:=coalesce(p_on_sormejalelugeja,FALSE),
    p_kaamera_kood_eesmine:=p_kaamera_kood_eesmine,
    p_kaamera_kood_tagumine:=p_kaamera_kood_tagumine,
    p_sisemalu_kood:=p_sisemalu_kood,
    p_diagonaali_kood:=p_diagonaali_kood,
    p_protsessori_kood:=p_protsessori_kood,
    p_ekraani_resolutsiooni_kood:=p_ekraani_resolutsiooni_kood);
END;
COMMENT ON FUNCTION public.f_registreeri_nutitelefon_vormist(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying) IS
    'Edastab vormi kutse funktsioonile f_registreeri_nutitelefon. Valimata märkeruudu NULL asendatakse FALSE-iga; ülejäänud sisendid ja tulemus säilivad. Äritingimusi kontrollivad ainult senine rutiin ja trigerid.';
REVOKE ALL ON FUNCTION public.f_registreeri_nutitelefon_vormist(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.f_muuda_kaup_vormist(
    p_ver text,
    p_kauba_kood_vana kaup.kauba_kood%TYPE,
    p_kauba_kood_uus kaup.kauba_kood%TYPE,
    p_nimetus kaup.nimetus%TYPE,
    p_hind kaup.hind%TYPE,
    p_kirjeldus kaup.kirjeldus%TYPE,
    p_pildi_aadress kaup.pildi_aadress%TYPE,
    p_e_meil isik.e_meil%TYPE,
    p_brandi_kood brand.kood%TYPE,
    p_on_veekindel nutitelefon.on_veekindel%TYPE,
    p_on_sormejalelugeja nutitelefon.on_sormejalelugeja%TYPE,
    p_kaamera_kood_eesmine kaamera.kood%TYPE,
    p_kaamera_kood_tagumine kaamera.kood%TYPE,
    p_sisemalu_kood sisemalu.kood%TYPE,
    p_diagonaali_kood diagonaal.kood%TYPE,
    p_protsessori_kood protsessor.kood%TYPE,
    p_ekraani_resolutsiooni_kood ekraani_resolutsioon.kood%TYPE)
RETURNS public.kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY INVOKER
SET search_path = public, pg_temp
BEGIN ATOMIC
SELECT public.f_muuda_kaup(
    p_ver:=p_ver,
    p_kauba_kood_vana:=p_kauba_kood_vana,
    p_kauba_kood_uus:=p_kauba_kood_uus,
    p_nimetus:=p_nimetus,
    p_hind:=p_hind,
    p_kirjeldus:=p_kirjeldus,
    p_pildi_aadress:=p_pildi_aadress,
    p_e_meil:=p_e_meil,
    p_brandi_kood:=p_brandi_kood,
    p_on_veekindel:=coalesce(p_on_veekindel,FALSE),
    p_on_sormejalelugeja:=coalesce(p_on_sormejalelugeja,FALSE),
    p_kaamera_kood_eesmine:=p_kaamera_kood_eesmine,
    p_kaamera_kood_tagumine:=p_kaamera_kood_tagumine,
    p_sisemalu_kood:=p_sisemalu_kood,
    p_diagonaali_kood:=p_diagonaali_kood,
    p_protsessori_kood:=p_protsessori_kood,
    p_ekraani_resolutsiooni_kood:=p_ekraani_resolutsiooni_kood);
END;
COMMENT ON FUNCTION public.f_muuda_kaup_vormist(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying) IS
    'Edastab vormi kutse funktsioonile f_muuda_kaup. Valimata märkeruudu NULL asendatakse FALSE-iga; ülejäänud sisendid ja tulemus säilivad. Äritingimusi kontrollivad ainult senine rutiin ja trigerid.';
REVOKE ALL ON FUNCTION public.f_muuda_kaup_vormist(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying) FROM PUBLIC;

COMMIT;
