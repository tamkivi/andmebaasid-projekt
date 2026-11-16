-- Näited täidetakse eraldi testandmebaasis pärast 13_testandmed.sql laadimist.
-- Puuduvate andmete või volituse korral on tulemus NULL; trigeri keeld annab vea.
START TRANSACTION;
CREATE TEMP TABLE u8_osalised ON COMMIT DROP AS
SELECT DISTINCT ON (r.kood) r.kood AS roll,i.e_meil
FROM isik i JOIN tootaja t USING(isik_id)
JOIN tootaja_rolli_omamine o USING(tootaja_id)
JOIN tootaja_roll r USING(tootaja_roll_id)
WHERE r.kood IN ('KAUBAHALDUR','JUHATAJA')
  AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP
ORDER BY r.kood,t.tootaja_id;

-- Ühine abifunktsioon: sobiv töötaja ja olematu töötaja.
SELECT f_leia_tootaja(p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_rolli_kood:='KAUBAHALDUR') AS tootaja_id;
SELECT t.tootaja_id,i.e_meil FROM tootaja t JOIN isik i USING(isik_id)
WHERE i.e_meil=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR');
SELECT (SELECT f_leia_tootaja(p_e_meil:='puuduv@example.invalid',
    p_rolli_kood:='KAUBAHALDUR')) AS tagasilukatud;

-- OP1: registreerimine ja korduva koodi tõttu tagasilükatud lisamine.

SELECT f_registreeri_nutitelefon(p_kauba_kood:='DEM008',
    p_nimetus:='Rutiinide näidiskaup',
    p_hind:=899.00::numeric,
    p_kirjeldus:='Samaaegsuse kontroll',
    p_pildi_aadress:=NULL::varchar,
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_brandi_kood:='APPLE',
    p_on_veekindel:=TRUE,
    p_on_sormejalelugeja:=FALSE,
    p_kaamera_kood_eesmine:=12.0::numeric,
    p_kaamera_kood_tagumine:=48.0::numeric,
    p_sisemalu_kood:=128::integer,
    p_diagonaali_kood:=6.1::numeric,
    p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179');

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT k.kauba_kood,n.on_veekindel,n.on_sormejalelugeja FROM kaup k JOIN nutitelefon n USING(kaup_id) WHERE k.kauba_kood='DEM008';

SELECT f_registreeri_nutitelefon(p_kauba_kood:='DEM008',
    p_nimetus:='Rutiinide näidiskaup',
    p_hind:=899.00::numeric,
    p_kirjeldus:='Samaaegsuse kontroll',
    p_pildi_aadress:=NULL::varchar,
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_brandi_kood:='APPLE',
    p_on_veekindel:=TRUE,
    p_on_sormejalelugeja:=FALSE,
    p_kaamera_kood_eesmine:=12.0::numeric,
    p_kaamera_kood_tagumine:=48.0::numeric,
    p_sisemalu_kood:=128::integer,
    p_diagonaali_kood:=6.1::numeric,
    p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179');

-- OP6, a1–a4: mõlemad vormid loevad sama varem kinnitatud versiooni.
CREATE TEMP TABLE u8_vorm ON COMMIT DROP AS
SELECT xmin::text AS ver FROM v_kaubad_muutmiseks WHERE kauba_kood='APL001';
SELECT xmin,kauba_kood,nimetus,hind FROM v_kaubad_muutmiseks WHERE kauba_kood='APL001';
-- a3: esimene kasutaja salvestab hinna 901,00.

SELECT f_muuda_kaup(p_ver:=(SELECT ver FROM u8_vorm),
    p_kauba_kood_vana:='APL001',
    p_kauba_kood_uus:='APL001',
    p_nimetus:='iPhone 15 näidiseksemplar',
    p_hind:=901.00::numeric,
    p_kirjeldus:='Samaaegsuse kontroll',
    p_pildi_aadress:=NULL::varchar,
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_brandi_kood:='APPLE',
    p_on_veekindel:=TRUE,
    p_on_sormejalelugeja:=FALSE,
    p_kaamera_kood_eesmine:=12.0::numeric,
    p_kaamera_kood_tagumine:=48.0::numeric,
    p_sisemalu_kood:=128::integer,
    p_diagonaali_kood:=6.1::numeric,
    p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179') AS tulemus;

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='APL001';

-- a4: teine kasutaja saadab vana versiooni koos uue nimetuse ja vana hinnaga.

SELECT f_muuda_kaup(p_ver:=(SELECT ver FROM u8_vorm),
    p_kauba_kood_vana:='APL001',
    p_kauba_kood_uus:='APL001',
    p_nimetus:='Teise kasutaja nimetus',
    p_hind:=899.00::numeric,
    p_kirjeldus:='Samaaegsuse kontroll',
    p_pildi_aadress:=NULL::varchar,
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_brandi_kood:='APPLE',
    p_on_veekindel:=TRUE,
    p_on_sormejalelugeja:=FALSE,
    p_kaamera_kood_eesmine:=12.0::numeric,
    p_kaamera_kood_tagumine:=48.0::numeric,
    p_sisemalu_kood:=128::integer,
    p_diagonaali_kood:=6.1::numeric,
    p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179') AS tulemus;

SELECT kauba_kood,nimetus,hind,hind=901.00 AND nimetus='iPhone 15 näidiseksemplar' AS esimene_muudatus_sailis FROM kaup WHERE kauba_kood='APL001';

-- OP7: muudatus õnnestub; sama kutse kordamine annab NULL-i.

SELECT f_lisa_kaup_kategooriasse(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_kauba_kategooria_kood:='NAISTELEFONID') AS tulemus;

SELECT * FROM v_kauba_kategooriad WHERE kauba_kood='DEM008';

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_lisa_kaup_kategooriasse(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_kauba_kategooria_kood:='NAISTELEFONID') AS tulemus;

-- OP8: muudatus õnnestub; sama kutse kordamine annab NULL-i.

SELECT f_eemalda_kaup_kategooriast(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_kauba_kategooria_kood:='NAISTELEFONID') AS tulemus;

SELECT * FROM v_kauba_kategooriad WHERE kauba_kood='DEM008';

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_eemalda_kaup_kategooriast(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_kauba_kategooria_kood:='NAISTELEFONID') AS tulemus;

-- OP9: muudatus õnnestub; sama kutse kordamine annab NULL-i.

SELECT f_lisa_kauba_variant(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_varv_kood:='WHITE') AS tulemus;

SELECT * FROM v_kauba_variandid WHERE kauba_kood='DEM008';

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_lisa_kauba_variant(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_varv_kood:='WHITE') AS tulemus;

-- OP10: muudatus õnnestub; sama kutse kordamine annab NULL-i.

SELECT f_eemalda_kauba_variant(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_varv_kood:='WHITE') AS tulemus;

SELECT * FROM v_kauba_variandid WHERE kauba_kood='DEM008';

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_eemalda_kauba_variant(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_varv_kood:='WHITE') AS tulemus;

-- Aktiveerimise eeltingimus: kaubal on vähemalt üks kategooria.

SELECT f_lisa_kaup_kategooriasse(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR'),
    p_kauba_kategooria_kood:='KLASSIKALINE') AS tulemus;

-- OP3: lubatud seisundimuudatus; korduskutse annab NULL-i.

SELECT f_aktiveeri_kaup(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_aktiveeri_kaup(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

-- OP4: lubatud seisundimuudatus; korduskutse annab NULL-i.

SELECT f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

-- OP5: lubatud seisundimuudatus; korduskutse annab NULL-i.

SELECT f_lopeta_kaup(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='JUHATAJA')) AS tulemus;

SELECT k.kauba_kood,k.nimetus,k.hind,s.kood AS seisund,k.viimase_muutja_id FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE k.kauba_kood='DEM008';

SELECT f_lopeta_kaup(p_kauba_kood:='DEM008',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='JUHATAJA')) AS tulemus;

-- OP2: ootel kauba kustutamine ja sama kutse kordamine.

SELECT f_unusta_kaup(p_kauba_kood:='APL001',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

SELECT kauba_kood FROM kaup WHERE kauba_kood='APL001';

SELECT f_unusta_kaup(p_kauba_kood:='APL001',
    p_e_meil:=(SELECT e_meil FROM u8_osalised WHERE roll='KAUBAHALDUR')) AS tulemus;

ROLLBACK;

-- OP2: aktiivset kaupa ei kustutata.
START TRANSACTION;
-- Tulemus: ebaõnnestub veateatega "Kustutada saab ainult ootel kaupa.".
\set ON_ERROR_STOP off
SELECT f_unusta_kaup(p_kauba_kood:='APL002',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY));
\set ON_ERROR_STOP on
ROLLBACK;

-- OP3: lõpetatud kaupa ei aktiveerita.
START TRANSACTION;
-- Tulemus: ebaõnnestub veateatega "Kauba seisundimuudatus ei ole lubatud.".
\set ON_ERROR_STOP off
SELECT f_aktiveeri_kaup(p_kauba_kood:='APL004',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY));
\set ON_ERROR_STOP on
ROLLBACK;

-- OP4: ootel kaupa ei muudeta otse mitteaktiivseks.
START TRANSACTION;
-- Tulemus: ebaõnnestub veateatega "Kauba seisundimuudatus ei ole lubatud.".
\set ON_ERROR_STOP off
SELECT f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='APL001',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY));
\set ON_ERROR_STOP on
ROLLBACK;

-- OP5: ootel kaupa ei lõpetata.
START TRANSACTION;
-- Tulemus: ebaõnnestub veateatega "Kauba seisundimuudatus ei ole lubatud.".
\set ON_ERROR_STOP off
SELECT f_lopeta_kaup(p_kauba_kood:='APL001',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='JUHATAJA' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY));
\set ON_ERROR_STOP on
ROLLBACK;

-- OP3: kategooriata kaupa ei aktiveerita.
START TRANSACTION;
DELETE FROM kauba_kategooria_omamine WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001');
-- Tulemus: ebaõnnestub veateatega "Kauba aktiveerimiseks peab sellel olema vähemalt üks kategooria.".
\set ON_ERROR_STOP off
SELECT f_aktiveeri_kaup(p_kauba_kood:='APL001',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY));
\set ON_ERROR_STOP on
ROLLBACK;
