-- Iga baastabeli ja veeru andmekatte ning testandmete sisuliste seoste kontroll.
DO $kontroll$
DECLARE
    v_tabel text;
    v_veerg text;
    v_ridu bigint;
BEGIN
    IF (SELECT count(*) FROM pg_tables WHERE schemaname='public')<>24 THEN
        RAISE EXCEPTION 'Kontroll eeldab 24 projekti baastabelit';
    END IF;
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public'
    LOOP
        EXECUTE format('SELECT count(*) FROM public.%I',v_tabel) INTO v_ridu;
        IF v_ridu<2 THEN RAISE EXCEPTION 'Tabelis % peab olema vähemalt kaks rida',v_tabel; END IF;
        FOR v_veerg IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name=v_tabel
        LOOP
            EXECUTE format('SELECT count(%I) FROM public.%I',v_veerg,v_tabel) INTO v_ridu;
            IF v_ridu=0 THEN RAISE EXCEPTION 'Veerus %.% puuduvad väärtused',v_tabel,v_veerg; END IF;
        END LOOP;
    END LOOP;
    IF (SELECT count(DISTINCT s.kood) FROM kaup AS k
        INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id))<>4
        OR NOT EXISTS (SELECT 1 FROM kaup WHERE hind>1000 AND pildi_aadress IS NOT NULL)
        OR EXISTS (SELECT 1 FROM kaup WHERE kirjeldus=nimetus)
        OR EXISTS (SELECT 1 FROM kaup AS k WHERE NOT EXISTS (
            SELECT 1 FROM nutitelefon AS n WHERE n.kaup_id=k.kaup_id))
        OR NOT EXISTS (SELECT 1 FROM tootaja_rolli_omamine WHERE lopu_aeg='infinity'::timestamptz)
        OR NOT EXISTS (SELECT 1 FROM tootaja_rolli_omamine WHERE lopu_aeg<'infinity'::timestamptz)
        OR (SELECT count(DISTINCT r.kood) FROM tootaja_rolli_omamine AS o
            INNER JOIN tootaja_roll AS r USING (tootaja_roll_id)
            WHERE r.kood IN ('KAUBAHALDUR','JUHATAJA'))<>2 THEN
        RAISE EXCEPTION 'Kauba, telefoni või töötaja testandmed on puudulikud';
    END IF;
END;
$kontroll$;
