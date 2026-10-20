-- Kaupade andmemuudatuste lepingulised funktsioonid.
START TRANSACTION;

CREATE FUNCTION f_registreeri_nutitelefon(
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
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
WITH sisend AS MATERIALIZED (
    SELECT tegija.tootaja_id,b.brand_id,e.kaamera_id AS eesmine_id,
           t.kaamera_id AS tagumine_id,m.sisemalu_id,d.diagonaal_id,
           p.protsessor_id,r.ekraani_resolutsioon_id
    FROM (SELECT t.tootaja_id
      FROM public.tootaja AS t
      INNER JOIN public.isik AS i USING (isik_id)
      WHERE lower(i.e_meil)=lower(p_e_meil)
      FOR SHARE OF t,i) AS tegija
    CROSS JOIN (SELECT brand_id FROM public.brand
        WHERE (kood=p_brandi_kood) AND on_aktiivne FOR SHARE) AS b
    CROSS JOIN (SELECT kaamera_id FROM public.kaamera
        WHERE (kood=p_kaamera_kood_eesmine) AND on_aktiivne FOR SHARE) AS e
    CROSS JOIN (SELECT kaamera_id FROM public.kaamera
        WHERE (kood=p_kaamera_kood_tagumine) AND on_aktiivne FOR SHARE) AS t
    CROSS JOIN (SELECT sisemalu_id FROM public.sisemalu
        WHERE (kood=p_sisemalu_kood) AND on_aktiivne FOR SHARE) AS m
    CROSS JOIN (SELECT diagonaal_id FROM public.diagonaal
        WHERE (kood=p_diagonaali_kood) AND on_aktiivne FOR SHARE) AS d
    CROSS JOIN (SELECT protsessor_id FROM public.protsessor
        WHERE (kood=p_protsessori_kood) AND on_aktiivne FOR SHARE) AS p
    CROSS JOIN (SELECT ekraani_resolutsioon_id FROM public.ekraani_resolutsioon
        WHERE (kood=p_ekraani_resolutsiooni_kood) AND on_aktiivne FOR SHARE) AS r
), ootel AS MATERIALIZED (
    SELECT kauba_seisundi_liik_id FROM public.kauba_seisundi_liik
    WHERE (kood=1) AND on_aktiivne FOR SHARE
), lisatud AS (
    INSERT INTO public.kaup (kauba_kood,nimetus,hind,kirjeldus,pildi_aadress,
        kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id)
    SELECT p_kauba_kood,p_nimetus,p_hind,p_kirjeldus,p_pildi_aadress,
           o.kauba_seisundi_liik_id,a.brand_id,a.tootaja_id,a.tootaja_id
    FROM sisend AS a CROSS JOIN ootel AS o
    ON CONFLICT (kauba_kood) DO NOTHING
    RETURNING kaup_id,kauba_kood
), telefon AS (
    INSERT INTO public.nutitelefon (kaup_id,eesmine_kaamera_id,tagumine_kaamera_id,
        sisemalu_id,diagonaal_id,protsessor_id,ekraani_resolutsioon_id,
        on_veekindel,on_sormejalelugeja)
    SELECT k.kaup_id,a.eesmine_id,a.tagumine_id,a.sisemalu_id,a.diagonaal_id,
           a.protsessor_id,a.ekraani_resolutsioon_id,p_on_veekindel,p_on_sormejalelugeja
    FROM lisatud AS k CROSS JOIN sisend AS a
    RETURNING kaup_id
)
SELECT k.kauba_kood FROM lisatud AS k INNER JOIN telefon AS t USING (kaup_id);
END;
COMMENT ON FUNCTION f_registreeri_nutitelefon(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying) IS
    'OP1: registreerib ühe lausega ootel kauba ja selle nutitelefoni. Töötaja ning aktiivne algseisund, bränd ja telefoni klassifikaatorid leitakse koodide järgi FOR SHARE kaitsega. Kaamerad seotakse vastavalt eesmiseks ja tagumiseks. Mõlemad muutja viited saavad töötaja ID; korduva kaubakoodi korral ei lisata kumbagi rida ja tulemus on NULL.';

CREATE FUNCTION f_unusta_kaup(p_kauba_kood kaup.kauba_kood%TYPE)
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
DELETE FROM public.kaup AS k
WHERE (k.kauba_kood=p_kauba_kood)
    AND k.kauba_seisundi_liik_id IN (
        SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
        WHERE s.kood=1 FOR SHARE)
RETURNING k.kauba_kood;
END;
COMMENT ON FUNCTION f_unusta_kaup(character varying) IS
    'OP2: kustutab ainult ootel kauba. Seisundit kontrollib sama DELETE-lause koodi 1 järgi ja FOR SHARE kaitseb klassifikaatorit. Telefon, kategooriaseosed ja variandid kustuvad välisvõtmete ON DELETE CASCADE abil; muutuseta tulemus on NULL.';

CREATE FUNCTION f_aktiveeri_kaup(
    p_kauba_kood kaup.kauba_kood%TYPE,p_e_meil isik.e_meil%TYPE)
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
UPDATE public.kaup AS k
SET kauba_seisundi_liik_id=uus.kauba_seisundi_liik_id,
    viimase_muutja_id=tegija.tootaja_id,viimase_muutm_aeg=CURRENT_TIMESTAMP
FROM (SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
      WHERE (s.kood=2) AND s.on_aktiivne FOR SHARE) AS uus
CROSS JOIN (SELECT t.tootaja_id
      FROM public.tootaja AS t
      INNER JOIN public.isik AS i USING (isik_id)
      WHERE lower(i.e_meil)=lower(p_e_meil)
      FOR SHARE OF t,i) AS tegija
WHERE (k.kauba_kood=p_kauba_kood)
    AND k.kauba_seisundi_liik_id IN (
        SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
        WHERE s.kood IN (1,3) FOR SHARE)
    AND EXISTS (SELECT 1 FROM public.kauba_kategooria_omamine AS o
                WHERE o.kaup_id=k.kaup_id FOR SHARE)
RETURNING k.kauba_kood;
END;
COMMENT ON FUNCTION f_aktiveeri_kaup(character varying,character varying) IS
    'OP3: aktiveerib ootel või mitteaktiivse kauba, millel on vähemalt üks kategooria. Sama UPDATE kontrollib lähte- ja sihtseisundit ning töötaja olemasolu tõstutundetu e-posti järgi. Teiste tabelite eeltingimused on kaitstud FOR SHARE lukuga. Salvestab viimase muutja ja aja ning tagastab koodi ainult õnnestumisel.';

CREATE FUNCTION f_muuda_kaup_mitteaktiivseks(
    p_kauba_kood kaup.kauba_kood%TYPE,p_e_meil isik.e_meil%TYPE)
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
UPDATE public.kaup AS k
SET kauba_seisundi_liik_id=uus.kauba_seisundi_liik_id,
    viimase_muutja_id=tegija.tootaja_id,viimase_muutm_aeg=CURRENT_TIMESTAMP
FROM (SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
      WHERE (s.kood=3) AND s.on_aktiivne FOR SHARE) AS uus
CROSS JOIN (SELECT t.tootaja_id
      FROM public.tootaja AS t
      INNER JOIN public.isik AS i USING (isik_id)
      WHERE lower(i.e_meil)=lower(p_e_meil)
      FOR SHARE OF t,i) AS tegija
WHERE (k.kauba_kood=p_kauba_kood)
    AND k.kauba_seisundi_liik_id IN (
        SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
        WHERE s.kood IN (2) FOR SHARE)
RETURNING k.kauba_kood;
END;
COMMENT ON FUNCTION f_muuda_kaup_mitteaktiivseks(character varying,character varying) IS
    'OP4: muudab aktiivse kauba mitteaktiivseks. Sama UPDATE kontrollib lähte- ja sihtseisundit ning töötaja olemasolu tõstutundetu e-posti järgi. Teiste tabelite eeltingimused on kaitstud FOR SHARE lukuga. Salvestab viimase muutja ja aja ning tagastab koodi ainult õnnestumisel.';

CREATE FUNCTION f_lopeta_kaup(
    p_kauba_kood kaup.kauba_kood%TYPE,p_e_meil isik.e_meil%TYPE)
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
UPDATE public.kaup AS k
SET kauba_seisundi_liik_id=uus.kauba_seisundi_liik_id,
    viimase_muutja_id=tegija.tootaja_id,viimase_muutm_aeg=CURRENT_TIMESTAMP
FROM (SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
      WHERE (s.kood=4) AND s.on_aktiivne FOR SHARE) AS uus
CROSS JOIN (SELECT t.tootaja_id
      FROM public.tootaja AS t
      INNER JOIN public.isik AS i USING (isik_id)
      WHERE lower(i.e_meil)=lower(p_e_meil)
      FOR SHARE OF t,i) AS tegija
WHERE (k.kauba_kood=p_kauba_kood)
    AND k.kauba_seisundi_liik_id IN (
        SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
        WHERE s.kood IN (2,3) FOR SHARE)
RETURNING k.kauba_kood;
END;
COMMENT ON FUNCTION f_lopeta_kaup(character varying,character varying) IS
    'OP5: lõpetab aktiivse või mitteaktiivse kauba. Sama UPDATE kontrollib lähte- ja sihtseisundit ning töötaja olemasolu tõstutundetu e-posti järgi. Teiste tabelite eeltingimused on kaitstud FOR SHARE lukuga. Salvestab viimase muutja ja aja ning tagastab koodi ainult õnnestumisel.';

CREATE FUNCTION f_muuda_kaup(
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
RETURNS kaup.kauba_kood%TYPE
LANGUAGE SQL VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
BEGIN ATOMIC
WITH sisend AS MATERIALIZED (
    SELECT tegija.tootaja_id,b.brand_id,e.kaamera_id AS eesmine_id,
           t.kaamera_id AS tagumine_id,m.sisemalu_id,d.diagonaal_id,
           p.protsessor_id,r.ekraani_resolutsioon_id
    FROM (SELECT t.tootaja_id
      FROM public.tootaja AS t
      INNER JOIN public.isik AS i USING (isik_id)
      WHERE lower(i.e_meil)=lower(p_e_meil)
      FOR SHARE OF t,i) AS tegija
    CROSS JOIN (SELECT brand_id FROM public.brand
        WHERE (kood=p_brandi_kood) AND on_aktiivne FOR SHARE) AS b
    CROSS JOIN (SELECT kaamera_id FROM public.kaamera
        WHERE (kood=p_kaamera_kood_eesmine) AND on_aktiivne FOR SHARE) AS e
    CROSS JOIN (SELECT kaamera_id FROM public.kaamera
        WHERE (kood=p_kaamera_kood_tagumine) AND on_aktiivne FOR SHARE) AS t
    CROSS JOIN (SELECT sisemalu_id FROM public.sisemalu
        WHERE (kood=p_sisemalu_kood) AND on_aktiivne FOR SHARE) AS m
    CROSS JOIN (SELECT diagonaal_id FROM public.diagonaal
        WHERE (kood=p_diagonaali_kood) AND on_aktiivne FOR SHARE) AS d
    CROSS JOIN (SELECT protsessor_id FROM public.protsessor
        WHERE (kood=p_protsessori_kood) AND on_aktiivne FOR SHARE) AS p
    CROSS JOIN (SELECT ekraani_resolutsioon_id FROM public.ekraani_resolutsioon
        WHERE (kood=p_ekraani_resolutsiooni_kood) AND on_aktiivne FOR SHARE) AS r
), muudetud AS (
    UPDATE public.kaup AS k
    SET kauba_kood=p_kauba_kood_uus,nimetus=p_nimetus,hind=p_hind,
        kirjeldus=p_kirjeldus,pildi_aadress=p_pildi_aadress,brand_id=a.brand_id,
        viimase_muutja_id=a.tootaja_id,viimase_muutm_aeg=CURRENT_TIMESTAMP
    FROM sisend AS a
    WHERE (k.kauba_kood=p_kauba_kood_vana) AND (k.xmin=p_ver::xid)
        AND k.kauba_seisundi_liik_id IN (
            SELECT s.kauba_seisundi_liik_id FROM public.kauba_seisundi_liik AS s
            WHERE s.kood IN (1,3) FOR SHARE)
        AND EXISTS (SELECT 1 FROM public.nutitelefon AS n
                    WHERE n.kaup_id=k.kaup_id FOR SHARE)
    RETURNING k.kaup_id,k.kauba_kood
), telefon AS (
    UPDATE public.nutitelefon AS n
    SET eesmine_kaamera_id=a.eesmine_id,tagumine_kaamera_id=a.tagumine_id,
        sisemalu_id=a.sisemalu_id,diagonaal_id=a.diagonaal_id,
        protsessor_id=a.protsessor_id,ekraani_resolutsioon_id=a.ekraani_resolutsioon_id,
        on_veekindel=p_on_veekindel,on_sormejalelugeja=p_on_sormejalelugeja
    FROM muudetud AS k CROSS JOIN sisend AS a
    WHERE n.kaup_id=k.kaup_id
    RETURNING n.kaup_id
)
SELECT k.kauba_kood FROM muudetud AS k INNER JOIN telefon AS t USING (kaup_id);
END;
COMMENT ON FUNCTION f_muuda_kaup(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying) IS
    'OP6: muudab ootel või mitteaktiivse kauba ja telefoni ühe lausega. xmin võrdlus välistab vananenud versiooni ülekirjutamise. Töötaja ja aktiivsed uued klassifikaatorid ning olemasolev telefon kontrollitakse FOR SHARE kaitsega. Muudab viimase muutja ja aja, säilitab registreerija, registreerimisaja ja seisundi; õnnestumisel tagastab uue kaubakoodi, muidu NULL.';

COMMIT;
