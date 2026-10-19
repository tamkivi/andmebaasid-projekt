-- Kaupade halduri lugemisvaadete sisu ja muutmiskeelu kontroll.
DO $kontroll$
DECLARE
    v_vaade text;
    v_lause text;
    v_ridu bigint;
BEGIN
    IF (SELECT count(*) FROM pg_catalog.pg_class AS c
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind='v'
          AND c.relname IN ('v_kaup_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid')
          AND c.reloptions @> ARRAY['security_barrier=true']
          AND pg_catalog.obj_description(c.oid,'pg_class') IS NOT NULL) <> 4 THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Neli kommenteeritud lugemisvaadet peavad kasutama security_barrier kaitset.',
            HINT='Kontrolli vaadete deklaratsioone.';
    END IF;
    BEGIN
        INSERT INTO public.riik (kood,nimetus) VALUES ('EST','Eesti');
        INSERT INTO public.isiku_seisundi_liik (kood,nimetus) VALUES ('TEST','Kontrollväärtus');
        INSERT INTO public.tootaja_seisundi_liik (kood,nimetus) VALUES ('TEST','Kontrollväärtus');
        INSERT INTO public.brand (kood,nimetus) VALUES ('TEST','Kontrollbränd');
        INSERT INTO public.varv (kood,nimetus) VALUES ('MUST','Must'),('VALGE','Valge');
        INSERT INTO public.kauba_kategooria_tyyp (kood,nimetus) VALUES ('OTSTARVE','Otstarve');
        INSERT INTO public.kauba_kategooria (kood,nimetus,kauba_kategooria_tyyp_id)
            SELECT v.kood,v.nimetus,t.kauba_kategooria_tyyp_id
            FROM (VALUES ('KODU','Kodus'),('TOO','Tööl')) AS v(kood,nimetus)
            CROSS JOIN public.kauba_kategooria_tyyp AS t;
        -- Tehnilised ID-d erinevad sisulistest seisundikoodidest.
        INSERT INTO public.kauba_seisundi_liik (kauba_seisundi_liik_id,kood,nimetus)
            VALUES (101,1,'Ootel'),(103,2,'Aktiivne'),(107,3,'Mitteaktiivne'),(109,4,'Lõpetatud');
        INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
            SELECT 'kontroll-isik','views@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,DATE '2000-01-01','Mari'
            FROM public.riik AS r CROSS JOIN public.isiku_seisundi_liik AS s;
        INSERT INTO public.tootaja (isik_id,tootaja_seisundi_liik_id)
            SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM public.isik AS i CROSS JOIN public.tootaja_seisundi_liik AS s;
        INSERT INTO public.kaup (kauba_kood,nimetus,kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id,hind,kirjeldus)
            SELECT 'ABC00'||s.kood,'Kontrolltelefon '||s.kood,s.kauba_seisundi_liik_id,b.brand_id,t.tootaja_id,t.tootaja_id,100,'Kontrollkirjeldus'
            FROM public.kauba_seisundi_liik AS s CROSS JOIN public.brand AS b CROSS JOIN public.tootaja AS t;
        INSERT INTO public.kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
            SELECT k.kaup_id,c.kauba_kategooria_id FROM public.kaup AS k CROSS JOIN public.kauba_kategooria AS c WHERE k.kauba_kood='ABC001';
        INSERT INTO public.kauba_variant (kaup_id,varv_id)
            SELECT k.kaup_id,v.varv_id FROM public.kaup AS k CROSS JOIN public.varv AS v WHERE k.kauba_kood='ABC001';
        IF (SELECT count(*) FROM public.v_kaubad)<>4
            OR (SELECT count(DISTINCT kauba_kood) FROM public.v_kaubad)<>4
            OR (SELECT count(*) FROM public.v_kaup_muutmiseks)<>2
            OR EXISTS (SELECT 1 FROM public.v_kaup_muutmiseks WHERE kauba_kood NOT IN ('ABC001','ABC003'))
            OR (SELECT count(*) FROM public.v_kauba_kategooriad)<>2
            OR (SELECT count(*) FROM public.v_kauba_variandid)<>2
            OR NOT EXISTS (SELECT 1 FROM public.v_kaubad WHERE kauba_kood='ABC004' AND brand_nimetus='Kontrollbränd' AND seisundi_nimetus='Lõpetatud') THEN
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Vale vaate sisu',
                DETAIL='Seisundite, seoste või korduste käsitlus ei vasta lähteandmetele.',
                HINT='Kontrolli ühendamisi ja seisundikoodide kasutust.';
        END IF;
        FOR v_vaade IN SELECT unnest(ARRAY['v_kaup_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid'])
        LOOP
            FOR v_lause IN SELECT unnest(ARRAY[
                format('UPDATE public.%I SET kauba_kood=%L',v_vaade,'XYZ001'),
                format('DELETE FROM public.%I',v_vaade),
                format('INSERT INTO public.%I (kauba_kood) VALUES (%L)',v_vaade,'XYZ001')])
            LOOP
                EXECUTE v_lause;
                GET DIAGNOSTICS v_ridu=ROW_COUNT;
                IF v_ridu<>0 THEN
                    RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Lugemisvaade muutis andmeid',
                        DETAIL='INSERT, UPDATE ja DELETE reeglid peavad jätma andmed puutumata.',
                        HINT='Kontrolli DO INSTEAD NOTHING reegleid.';
                END IF;
            END LOOP;
        END LOOP;
        IF (SELECT count(*) FROM public.kaup)<>4 OR EXISTS (SELECT 1 FROM public.kaup WHERE kauba_kood='XYZ001')
            OR (SELECT count(*) FROM public.kauba_kategooria_omamine)<>2
            OR (SELECT count(*) FROM public.kauba_variant)<>2 THEN
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Lugemisvaate kõrvalmõju',
                DETAIL='Baastabelite read peavad jääma samaks.', HINT='Kontrolli muutmisreeglite sisu.';
        END IF;
        RAISE EXCEPTION USING ERRCODE='ZT001', MESSAGE='Kontrollandmete eemaldamine',
            DETAIL='Kontrollandmed eemaldatakse sama ploki alatehinguga.', HINT='See erand püütakse samas plokis.';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$kontroll$;
