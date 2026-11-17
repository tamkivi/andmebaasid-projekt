-- Loetavad tuvastamise näited; kõik näidisandmed võetakse lõpus tagasi.
\set ON_ERROR_STOP on
START TRANSACTION;

INSERT INTO isik(isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
SELECT 'U10NAIDE','u10-naide@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,DATE '2000-01-01','Näidis'
FROM riik AS r CROSS JOIN isiku_seisundi_liik AS s WHERE r.kood='EST' AND s.kood='EL';
INSERT INTO kasutajakonto(isik_id,parool)
SELECT isik_id,laiendused.crypt('naidis-parool-1',laiendused.gen_salt('bf',12))
FROM isik WHERE isikukood='U10NAIDE';
INSERT INTO tootaja(isik_id,tootaja_seisundi_liik_id)
SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM isik AS i CROSS JOIN tootaja_seisundi_liik AS s
WHERE i.isikukood='U10NAIDE' AND s.kood='TO';
INSERT INTO tootaja_rolli_omamine(tootaja_id,tootaja_roll_id,alguse_aeg)
SELECT t.tootaja_id,r.tootaja_roll_id,date_trunc('second',CURRENT_TIMESTAMP)
FROM tootaja AS t JOIN isik USING (isik_id) CROSS JOIN tootaja_roll AS r
WHERE isikukood='U10NAIDE' AND r.kood='KAUBAHALDUR';

SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u10-naide@example.invalid',p_parool:='naidis-parool-1');
-- Tulemus: TRUE, õige parool ja kehtiv kaubahalduri roll.
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='U10-NAIDE@EXAMPLE.INVALID',p_parool:='naidis-parool-1');
-- Tulemus: TRUE, kasutajanimi on tõstutundetu.
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u10-naide@example.invalid',p_parool:='vale-naidis');
-- Tulemus: FALSE, parool on vale.
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u10-naide@example.invalid',p_parool:='NAIDIS-PAROOL-1');
-- Tulemus: FALSE, parool on tõstutundlik.
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='puuduv@example.invalid',p_parool:='naidis-parool-1');
-- Tulemus: FALSE, kasutaja puudub.

UPDATE kasutajakonto SET on_aktiivne=FALSE
WHERE isik_id=(SELECT isik_id FROM isik WHERE isikukood='U10NAIDE');
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u10-naide@example.invalid',p_parool:='naidis-parool-1');
-- Tulemus: FALSE, konto on mitteaktiivne.
UPDATE kasutajakonto SET on_aktiivne=TRUE
WHERE isik_id=(SELECT isik_id FROM isik WHERE isikukood='U10NAIDE');
UPDATE tootaja_rolli_omamine SET tootaja_roll_id=(SELECT tootaja_roll_id FROM tootaja_roll WHERE kood='JUHATAJA')
WHERE tootaja_id=(SELECT t.tootaja_id FROM tootaja AS t JOIN isik USING (isik_id) WHERE isikukood='U10NAIDE');
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u10-naide@example.invalid',p_parool:='naidis-parool-1');
-- Tulemus: FALSE, juhataja roll ei anna kaubahalduri töökohta sissepääsu.

ROLLBACK;
