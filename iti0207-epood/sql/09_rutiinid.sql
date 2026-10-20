-- Kaupade andmemuudatuste lepingulised funktsioonid.
START TRANSACTION;

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

COMMIT;
