-- Ohtliku kujuga sisend jääb tekstiks; veebis varjestamist kontrollitakse eraldi.
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('epood.turva_e_meil',(
    SELECT i.e_meil FROM isik AS i JOIN tootaja AS t USING(isik_id)
    JOIN tootaja_rolli_omamine AS o USING(tootaja_id)
    JOIN tootaja_roll AS r USING(tootaja_roll_id)
    WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP
        AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id LIMIT 1),true);
-- Ainult selle tagasivõetava kontrolli DO-ploki jaoks.
GRANT USAGE ON LANGUAGE plpgsql TO epood_rakendus;
SET LOCAL ROLE epood_rakendus;
DO $kontroll$
DECLARE
    v_sisend text;
    v_nr integer:=0;
    v_kood varchar;
BEGIN
    FOREACH v_sisend IN ARRAY ARRAY[$s$' OR '1'='1$s$,
        $s$'; DROP TABLE kaup; --$s$,$s$<script>alert(1)</script>$s$]
    LOOP
        IF public.f_on_kaubahaldur(v_sisend,v_sisend) IS DISTINCT FROM FALSE
            OR public.f_on_kaubahaldur(current_setting('epood.turva_e_meil'),v_sisend) IS DISTINCT FROM FALSE THEN
            RAISE EXCEPTION 'Sisend ei tohi anda sisselogimisõigust';
        END IF;
        v_nr:=v_nr+1; v_kood:='SEC00'||v_nr;
        IF public.f_registreeri_nutitelefon_vormist(v_kood,v_sisend,899,v_sisend,
            NULL,current_setting('epood.turva_e_meil')::varchar,'APPLE',NULL,NULL,
            12,48,256,6.1,'A16','2556x1179') IS DISTINCT FROM v_kood THEN
            RAISE EXCEPTION 'Teksti registreerimise kontroll ebaõnnestus';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega
            WHERE kauba_kood=v_kood AND nimetus=v_sisend AND kirjeldus=v_sisend) THEN
            RAISE EXCEPTION 'Sisend peab säilima täpselt tekstina';
        END IF;
    END LOOP;
END;
$kontroll$;
RESET ROLE;
DO $tabelid$
BEGIN
    IF (SELECT count(*) FROM pg_tables WHERE schemaname='public')<>24 THEN
        RAISE EXCEPTION 'Kõik 24 baastabelit peavad säilima';
    END IF;
END;
$tabelid$;
ROLLBACK;
