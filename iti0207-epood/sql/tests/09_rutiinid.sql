-- Andmemuudatuste funktsioonide lepingute ja kõrvalmõjude kontroll.
DO $kontroll$
DECLARE
    v_e_meil varchar;
    v_muutja integer;
    v_id integer;
    v_tulemus varchar;
    v_nimi text;
    v_vana smallint;
    v_uus smallint;
    v_enne jsonb;
    v_kategooriad smallint[];
BEGIN
    IF (SELECT count(*) FROM pg_proc AS p
        INNER JOIN pg_namespace AS n ON n.oid=p.pronamespace
        INNER JOIN pg_language AS l ON l.oid=p.prolang
        WHERE n.nspname='public'
          AND p.proname IN ('f_unusta_kaup','f_aktiveeri_kaup',
              'f_muuda_kaup_mitteaktiivseks','f_lopeta_kaup')
          AND l.lanname='sql' AND p.prosqlbody IS NOT NULL
          AND p.provolatile='v' AND p.prosecdef AND NOT p.proisstrict
          AND p.proconfig @> ARRAY['search_path=public, pg_temp']
          AND obj_description(p.oid,'pg_proc') IS NOT NULL)<>4 THEN
        RAISE EXCEPTION 'Funktsioonide keel, turvaomadused või kommentaarid on puudulikud';
    END IF;
    BEGIN
        SELECT i.e_meil,t.tootaja_id INTO v_e_meil,v_muutja
        FROM tootaja AS t INNER JOIN isik AS i USING (isik_id)
        ORDER BY t.tootaja_id DESC FETCH FIRST 1 ROW ONLY;
        SELECT kaup_id INTO v_id FROM kaup WHERE kauba_kood='APL001';
        UPDATE kaup SET reg_aeg=TIMESTAMPTZ '2026-01-01 00:00:00+02',
            viimase_muutm_aeg=TIMESTAMPTZ '2026-01-01 00:00:00+02' WHERE kaup_id=v_id;

        SELECT f_aktiveeri_kaup(p_kauba_kood:='APL001',p_e_meil:=upper(v_e_meil)) INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'APL001' OR NOT EXISTS (
            SELECT 1 FROM kaup AS k INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
            WHERE k.kaup_id=v_id AND s.kood=2 AND k.viimase_muutja_id=v_muutja
                AND k.viimase_muutm_aeg>k.reg_aeg) THEN
            RAISE EXCEPTION 'OP3 ei aktiveerinud kaupa ega registreerinud muutjat ja aega';
        END IF;
        SELECT f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='APL001',p_e_meil:=v_e_meil) INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'APL001' OR NOT EXISTS (
            SELECT 1 FROM kaup AS k INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
            WHERE k.kaup_id=v_id AND s.kood=3 AND k.viimase_muutja_id=v_muutja) THEN
            RAISE EXCEPTION 'OP4 ei muutnud kauba seisundit';
        END IF;
        SELECT f_aktiveeri_kaup(p_kauba_kood:='APL001',p_e_meil:=v_e_meil) INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'APL001' THEN RAISE EXCEPTION 'OP3 peab lubama ka seisundit 3'; END IF;
        SELECT f_lopeta_kaup(p_kauba_kood:='APL001',p_e_meil:=v_e_meil) INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'APL001' OR NOT EXISTS (
            SELECT 1 FROM kaup AS k INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
            WHERE k.kaup_id=v_id AND s.kood=4 AND k.viimase_muutja_id=v_muutja) THEN
            RAISE EXCEPTION 'OP5 ei lõpetanud kaupa';
        END IF;

        FOR v_nimi,v_vana,v_uus IN SELECT a.nimi,a.vana,a.uus FROM (VALUES
            ('f_aktiveeri_kaup',1::smallint,2::smallint),
            ('f_muuda_kaup_mitteaktiivseks',2::smallint,3::smallint),
            ('f_lopeta_kaup',3::smallint,4::smallint)
        ) AS a(nimi,vana,uus)
        LOOP
            UPDATE kaup SET kauba_seisundi_liik_id=(
                SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=v_vana)
            WHERE kaup_id=v_id;
            SELECT to_jsonb(k) INTO v_enne FROM kaup AS k WHERE kaup_id=v_id;
            EXECUTE format('SELECT public.%I(p_kauba_kood:=$1,p_e_meil:=$2)',v_nimi)
                INTO v_tulemus USING 'APL001','puuduv@example.invalid';
            IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (
                SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION '% muutis kaupa puuduva töötajaga',v_nimi;
            END IF;
            UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=v_uus;
            EXECUTE format('SELECT public.%I(p_kauba_kood:=$1,p_e_meil:=$2)',v_nimi)
                INTO v_tulemus USING 'APL001',v_e_meil;
            IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (
                SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION '% kasutas mitteaktiivset sihtseisundit',v_nimi;
            END IF;
            UPDATE kauba_seisundi_liik SET on_aktiivne=TRUE WHERE kood=v_uus;
            EXECUTE format('SELECT public.%I(p_kauba_kood:=$1,p_e_meil:=$2)',v_nimi)
                INTO v_tulemus USING 'PUUDUV',v_e_meil;
            IF v_tulemus IS NOT NULL THEN RAISE EXCEPTION '% leidis olematu kauba',v_nimi; END IF;
            EXECUTE format('SELECT public.%I(p_kauba_kood:=$1,p_e_meil:=$2)',v_nimi)
                INTO v_tulemus USING 'APL001',v_e_meil;
            IF v_tulemus IS DISTINCT FROM 'APL001' THEN RAISE EXCEPTION '% keeldus lubatud muutusest',v_nimi; END IF;
        END LOOP;

        FOR v_nimi,v_vana IN SELECT a.nimi,a.vana FROM (VALUES
            ('f_aktiveeri_kaup',2::smallint),('f_aktiveeri_kaup',4::smallint),
            ('f_muuda_kaup_mitteaktiivseks',1::smallint),
            ('f_muuda_kaup_mitteaktiivseks',3::smallint),
            ('f_muuda_kaup_mitteaktiivseks',4::smallint),
            ('f_lopeta_kaup',1::smallint),('f_lopeta_kaup',4::smallint)
        ) AS a(nimi,vana)
        LOOP
            UPDATE kaup SET kauba_seisundi_liik_id=(
                SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=v_vana)
            WHERE kaup_id=v_id;
            SELECT to_jsonb(k) INTO v_enne FROM kaup AS k WHERE kaup_id=v_id;
            EXECUTE format('SELECT public.%I(p_kauba_kood:=$1,p_e_meil:=$2)',v_nimi)
                INTO v_tulemus USING 'APL001',v_e_meil;
            IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (
                SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION '% lubas keelatud lähteoleku %',v_nimi,v_vana;
            END IF;
        END LOOP;
        UPDATE kaup SET kauba_seisundi_liik_id=(
            SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=1)
        WHERE kaup_id=v_id;
        SELECT array_agg(kauba_kategooria_id) INTO v_kategooriad
        FROM kauba_kategooria_omamine WHERE kaup_id=v_id;
        DELETE FROM kauba_kategooria_omamine WHERE kaup_id=v_id;
        SELECT to_jsonb(k) INTO v_enne FROM kaup AS k WHERE kaup_id=v_id;
        SELECT f_aktiveeri_kaup(p_kauba_kood:='APL001',p_e_meil:=v_e_meil) INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (
            SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'OP3 aktiveeris kategooriata kauba';
        END IF;
        INSERT INTO kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
        SELECT v_id,a.kood FROM unnest(v_kategooriad) AS a(kood);
        FOR v_vana IN SELECT unnest(ARRAY[2,3,4]::smallint[])
        LOOP
            UPDATE kaup SET kauba_seisundi_liik_id=(
                SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=v_vana)
            WHERE kaup_id=v_id;
            SELECT f_unusta_kaup(p_kauba_kood:='APL001') INTO v_tulemus;
            IF v_tulemus IS NOT NULL OR NOT EXISTS (SELECT 1 FROM kaup WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION 'OP2 kustutas mitteootel kauba';
            END IF;
        END LOOP;
        SELECT f_unusta_kaup(p_kauba_kood:='PUUDUV') INTO v_tulemus;
        IF v_tulemus IS NOT NULL THEN RAISE EXCEPTION 'OP2 tagastas olematu kauba'; END IF;
        UPDATE kaup SET kauba_seisundi_liik_id=(
            SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=1)
        WHERE kaup_id=v_id;
        IF NOT EXISTS (SELECT 1 FROM nutitelefon WHERE kaup_id=v_id)
            OR NOT EXISTS (SELECT 1 FROM kauba_variant WHERE kaup_id=v_id)
            OR NOT EXISTS (SELECT 1 FROM kauba_kategooria_omamine WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'Kustutamise kontroll vajab kõiki sõltuvaid ridu';
        END IF;
        SELECT f_unusta_kaup(p_kauba_kood:='APL001') INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'APL001' OR EXISTS (SELECT 1 FROM kaup WHERE kaup_id=v_id)
            OR EXISTS (SELECT 1 FROM nutitelefon WHERE kaup_id=v_id)
            OR EXISTS (SELECT 1 FROM kauba_variant WHERE kaup_id=v_id)
            OR EXISTS (SELECT 1 FROM kauba_kategooria_omamine WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'OP2 ei eemaldanud kaupa koos sõltuvate ridadega';
        END IF;
        RAISE EXCEPTION USING ERRCODE='ZT001',MESSAGE='Kontrollmuudatuste eemaldamine';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$kontroll$;
