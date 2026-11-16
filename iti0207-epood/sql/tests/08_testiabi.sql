-- Ainult tagasipööratavate katsete andmete ettevalmistamiseks.
CREATE FUNCTION pg_temp.u9_seisund(p_id integer,p_kood integer) RETURNS void
LANGUAGE plpgsql AS $abi$
BEGIN
    ALTER TABLE public.kaup DISABLE TRIGGER USER;
    UPDATE public.kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id
        FROM public.kauba_seisundi_liik WHERE kood=p_kood) WHERE kaup_id=p_id;
    ALTER TABLE public.kaup ENABLE TRIGGER USER;
END;
$abi$;
CREATE FUNCTION pg_temp.u9_aeg(p_id integer) RETURNS void
LANGUAGE plpgsql AS $abi$
BEGIN
    ALTER TABLE public.kaup DISABLE TRIGGER USER;
    UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2026-01-01 00:00:00+02',
        viimase_muutm_aeg=TIMESTAMPTZ '2026-01-01 00:00:00+02' WHERE kaup_id=p_id;
    ALTER TABLE public.kaup ENABLE TRIGGER USER;
END;
$abi$;
CREATE FUNCTION pg_temp.u9_viga(p_lause text,p_reegel text,p_teade text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $abi$
DECLARE
    v_reegel text; v_teade text; v_skeem text; v_tabel text;
    v_detail text; v_vihje text; v_veerg text;
BEGIN
    BEGIN
        EXECUTE p_lause;
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME,v_teade=MESSAGE_TEXT,
            v_skeem=SCHEMA_NAME,v_tabel=TABLE_NAME,v_detail=PG_EXCEPTION_DETAIL,
            v_vihje=PG_EXCEPTION_HINT,v_veerg=COLUMN_NAME;
        IF v_reegel IS DISTINCT FROM p_reegel OR v_skeem<>'public'
            OR v_tabel='' OR v_detail='' OR v_vihje=''
            OR (p_teade IS NOT NULL AND v_teade IS DISTINCT FROM p_teade)
            OR (p_reegel NOT LIKE '%_kustutamine' AND p_reegel NOT LIKE '%_truncate' AND v_veerg='') THEN
            RAISE EXCEPTION 'Vale veateade: %, %, %, %, %, %, %',
                v_reegel,v_teade,v_skeem,v_tabel,v_detail,v_vihje,v_veerg;
        END IF;
        RETURN;
    END;
    RAISE EXCEPTION 'Keelatud lause õnnestus: %',p_lause;
END;
$abi$;
