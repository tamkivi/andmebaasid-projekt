-- Iga näide lõpeb tagasipööramisega. Oodatud vea järel ei tehta muid päringuid.
\set ON_ERROR_STOP on

\echo trig_kaup_algseisund
START TRANSACTION;
-- Tulemus: ootel kauba lisamine õnnestub.
INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,kauba_seisundi_liik_id,
    brand_id,registreerija_id,viimase_muutja_id)
SELECT 'NAT009','Trigeri näidiskaup',100,'Trigeri näite kontrollkirjeldus',s.kauba_seisundi_liik_id,
    k.brand_id,k.registreerija_id,k.viimase_muutja_id
FROM kaup k CROSS JOIN kauba_seisundi_liik s WHERE k.kauba_kood='APL001' AND s.kood=1;
SELECT kauba_kood FROM kaup WHERE kauba_kood='NAT009';
-- Tulemus: ebaõnnestub veateatega "Uue kauba seisund peab olema ootel.".
\set ON_ERROR_STOP off
INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,kauba_seisundi_liik_id,
    brand_id,registreerija_id,viimase_muutja_id)
SELECT 'NAT009','Trigeri näidiskaup',100,'Trigeri näite kontrollkirjeldus',s.kauba_seisundi_liik_id,
    k.brand_id,k.registreerija_id,k.viimase_muutja_id
FROM kaup k CROSS JOIN kauba_seisundi_liik s WHERE k.kauba_kood='APL001' AND s.kood=2;
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_seisundimuudatus
START TRANSACTION;
-- Tulemus: 1 -> 2 ja sama seisundi tagasikirjutamine õnnestuvad.
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kauba_kood='APL001';
UPDATE kaup SET kauba_seisundi_liik_id=kauba_seisundi_liik_id;
-- Tulemus: ebaõnnestub veateatega "Kauba seisundimuudatus ei ole lubatud.".
\set ON_ERROR_STOP off
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=1) WHERE kauba_kood='APL002';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_seisundimuudatus_kategooria
START TRANSACTION;
-- Tulemus: kategooriaga kauba aktiveerimine õnnestub.
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kauba_kood='APL003';
DELETE FROM kauba_kategooria_omamine WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001');
-- Tulemus: ebaõnnestub veateatega "Kauba aktiveerimiseks peab sellel olema vähemalt üks kategooria.".
\set ON_ERROR_STOP off
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kauba_kood='APL001';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_kustutamine
START TRANSACTION;
-- Tulemus: ootel kaup ja selle sõltuvad read kustuvad.
DELETE FROM kaup WHERE kauba_kood='APL001';
SELECT kauba_kood FROM kaup WHERE kauba_kood='APL001';
-- Tulemus: ebaõnnestub veateatega "Kustutada saab ainult ootel kaupa.".
\set ON_ERROR_STOP off
DELETE FROM kaup WHERE kauba_kood='APL002';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_andmete_muutmine
START TRANSACTION;
-- Tulemus: ootel kauba hinna muutmine ning endiste väärtuste tagasikirjutamine õnnestuvad.
UPDATE kaup SET hind=hind+1 WHERE kauba_kood='APL001';
UPDATE kaup SET hind=hind;
-- Tulemus: ebaõnnestub veateatega "Kauba andmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
UPDATE kaup SET hind=hind+1 WHERE kauba_kood='APL002';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_nutitelefon_kauba_muudetavus
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete toiming õnnestub.
DELETE FROM nutitelefon WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001');
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
DELETE FROM nutitelefon WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL002');
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_nutitelefon_muutmine
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete muutmine õnnestub.
UPDATE nutitelefon SET on_veekindel=NOT on_veekindel WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001');
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
UPDATE nutitelefon SET on_veekindel=NOT on_veekindel WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL002');
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_variant_kauba_muudetavus
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete toiming õnnestub.
INSERT INTO kauba_variant (kaup_id,varv_id) SELECT (SELECT kaup_id FROM kaup WHERE kauba_kood='APL001'),varv_id FROM varv WHERE kood='WHITE';
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
INSERT INTO kauba_variant (kaup_id,varv_id) SELECT (SELECT kaup_id FROM kaup WHERE kauba_kood='APL002'),varv_id FROM varv WHERE kood='WHITE';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_variant_muutmine
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete muutmine õnnestub.
UPDATE kauba_variant SET varv_id=(SELECT varv_id FROM varv WHERE kood='WHITE') WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001');
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
UPDATE kauba_variant SET varv_id=(SELECT varv_id FROM varv WHERE kood='WHITE') WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL002');
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_kategooria_omamine_kauba_muudetavus
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete toiming õnnestub.
INSERT INTO kauba_kategooria_omamine SELECT (SELECT kaup_id FROM kaup WHERE kauba_kood='APL001'),kauba_kategooria_id FROM kauba_kategooria WHERE kood='MEESTELEFONID';
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
INSERT INTO kauba_kategooria_omamine SELECT (SELECT kaup_id FROM kaup WHERE kauba_kood='APL002'),kauba_kategooria_id FROM kauba_kategooria WHERE kood='MEESTELEFONID';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_kategooria_omamine_muutmine
START TRANSACTION;
-- Tulemus: ootel kauba lisaandmete muutmine õnnestub.
UPDATE kauba_kategooria_omamine SET kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood='MEESTELEFONID') WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL001') AND kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood='KLASSIKALINE');
-- Tulemus: ebaõnnestub veateatega "Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.".
\set ON_ERROR_STOP off
UPDATE kauba_kategooria_omamine SET kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood='MEESTELEFONID') WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='APL002') AND kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood='KLASSIKALINE');
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_reg_andmed
START TRANSACTION;
-- Tulemus: algsete registreerimisandmete tagasikirjutamine õnnestub.
UPDATE kaup SET reg_aeg=reg_aeg,registreerija_id=registreerija_id;
-- Tulemus: ebaõnnestub veateatega "Kauba registreerijat ja registreerimise aega ei saa muuta.".
\set ON_ERROR_STOP off
UPDATE kaup SET reg_aeg=reg_aeg-interval '1 day' WHERE kauba_kood='APL001';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_viimase_muutm_aeg
START TRANSACTION;
-- Tulemus: etteantud vana aeg asendatakse tehingu algusajaga; kontroll annab true.
UPDATE kaup SET viimase_muutm_aeg=TIMESTAMPTZ '2020-01-01';
SELECT bool_and(viimase_muutm_aeg=CURRENT_TIMESTAMP::timestamptz(0)) AS aeg_oige FROM kaup;
ROLLBACK;

\echo trig_isik_viimase_muutm_aeg
START TRANSACTION;
-- Tulemus: etteantud vana aeg asendatakse tehingu algusajaga; kontroll annab true.
UPDATE isik SET viimase_muutm_aeg=TIMESTAMPTZ '2020-01-01';
SELECT bool_and(viimase_muutm_aeg=CURRENT_TIMESTAMP::timestamptz(0)) AS aeg_oige FROM isik;
ROLLBACK;

\echo trig_kaup_aktiivne_algseisund
START TRANSACTION;
UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=1;
-- Tulemus: ebaõnnestub veateatega "Kauba uus seisund peab olema aktiivne klassifikaatoriväärtus.".
\set ON_ERROR_STOP off
INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,kauba_seisundi_liik_id,
    brand_id,registreerija_id,viimase_muutja_id)
SELECT 'NAT009','Trigeri näidiskaup',100,'Trigeri näite kontrollkirjeldus',s.kauba_seisundi_liik_id,
    k.brand_id,k.registreerija_id,k.viimase_muutja_id
FROM kaup k CROSS JOIN kauba_seisundi_liik s WHERE k.kauba_kood='APL001' AND s.kood=1;
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_aktiivne_uus_seisund
START TRANSACTION;
UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=2;
-- Tulemus: ebaõnnestub veateatega "Kauba uus seisund peab olema aktiivne klassifikaatoriväärtus.".
\set ON_ERROR_STOP off
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kauba_kood='APL001';
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kaup_truncate
START TRANSACTION;
-- TRUNCATE on kõigis seisundites keelatud; DELETE kasutamist kontrollitakse eespool.
-- Tulemus: ebaõnnestub veateatega "Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.".
\set ON_ERROR_STOP off
TRUNCATE kaup CASCADE;
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_nutitelefon_truncate
START TRANSACTION;
-- TRUNCATE on kõigis seisundites keelatud; DELETE kasutamist kontrollitakse eespool.
-- Tulemus: ebaõnnestub veateatega "Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.".
\set ON_ERROR_STOP off
TRUNCATE nutitelefon CASCADE;
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_variant_truncate
START TRANSACTION;
-- TRUNCATE on kõigis seisundites keelatud; DELETE kasutamist kontrollitakse eespool.
-- Tulemus: ebaõnnestub veateatega "Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.".
\set ON_ERROR_STOP off
TRUNCATE kauba_variant CASCADE;
\set ON_ERROR_STOP on
ROLLBACK;

\echo trig_kauba_kategooria_omamine_truncate
START TRANSACTION;
-- TRUNCATE on kõigis seisundites keelatud; DELETE kasutamist kontrollitakse eespool.
-- Tulemus: ebaõnnestub veateatega "Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.".
\set ON_ERROR_STOP off
TRUNCATE kauba_kategooria_omamine CASCADE;
\set ON_ERROR_STOP on
ROLLBACK;
