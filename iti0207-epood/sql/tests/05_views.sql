-- Kaupade halduri lugemisvaadete sisu ja muutmiskeelu kontroll.
DO $kontroll$
DECLARE
    v_vaade text;
    v_lause text;
    v_ridu bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='v_kaubad_muutmiseks'
          AND column_name='xmin' AND udt_name='xid') OR EXISTS (
        SELECT 1 FROM v_kaubad_muutmiseks AS v
        INNER JOIN kaup AS k USING (kauba_kood) WHERE v.xmin<>k.xmin) THEN
        RAISE EXCEPTION 'Muutmise vaade peab esitama kauba tegeliku xmin väärtuse';
    END IF;
    IF (SELECT count(*) FROM pg_catalog.pg_class AS c
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind='v'
          AND c.relname IN ('v_kaubad_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid')
          AND c.reloptions @> ARRAY['security_barrier=true']
          AND pg_catalog.obj_description(c.oid,'pg_class') IS NOT NULL) <> 4 THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Neli kommenteeritud lugemisvaadet peavad kasutama security_barrier kaitset.',
            HINT='Kontrolli vaadete deklaratsioone.';
    END IF;
    BEGIN
        INSERT INTO public.riik (kood,nimetus) VALUES ('QZZ','Kontrollriik');
        INSERT INTO public.isiku_seisundi_liik (kood,nimetus) VALUES ('TEST','Kontrollväärtus');
        INSERT INTO public.tootaja_seisundi_liik (kood,nimetus) VALUES ('TEST','Kontrollväärtus');
        INSERT INTO public.brand (kood,nimetus) VALUES ('TEST','Kontrollbränd');
        INSERT INTO public.varv (kood,nimetus) VALUES ('MUST','Katsemust'),('VALGE','Katsevalge');
        INSERT INTO public.kauba_kategooria_tyyp (kood,nimetus) VALUES ('OTSTARVE','Otstarve');
        INSERT INTO public.kauba_kategooria (kood,nimetus,kauba_kategooria_tyyp_id)
            SELECT v.kood,v.nimetus,t.kauba_kategooria_tyyp_id
            FROM (VALUES ('KODU','Kodus'),('TOO','Tööl')) AS v(kood,nimetus)
            CROSS JOIN public.kauba_kategooria_tyyp AS t WHERE t.kood='OTSTARVE';
        -- Tehnilised ID-d erinevad sisulistest seisundikoodidest.
        IF NOT EXISTS (SELECT 1 FROM public.kauba_seisundi_liik WHERE kauba_seisundi_liik_id<>kood) THEN
            RAISE EXCEPTION 'Kontroll vajab koodidest erinevaid seisundi identifikaatoreid';
        END IF;
        INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
            SELECT 'kontroll-isik','views@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,DATE '2000-01-01','Mari'
            FROM public.riik AS r CROSS JOIN public.isiku_seisundi_liik AS s WHERE r.kood='QZZ' AND s.kood='TEST';
        INSERT INTO public.tootaja (isik_id,tootaja_seisundi_liik_id)
            SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM public.isik AS i CROSS JOIN public.tootaja_seisundi_liik AS s WHERE i.e_meil='views@example.invalid' AND s.kood='TEST';
        INSERT INTO public.kaup (kauba_kood,nimetus,kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id,hind,kirjeldus)
            SELECT 'ABC00'||s.kood,'Kontrolltelefon '||s.kood,s.kauba_seisundi_liik_id,b.brand_id,t.tootaja_id,t.tootaja_id,100,'Kontrollkirjeldus'
            FROM public.kauba_seisundi_liik AS s CROSS JOIN public.brand AS b CROSS JOIN public.tootaja AS t INNER JOIN public.isik AS i USING (isik_id) WHERE s.kood IN (1,2,3,4) AND b.kood='TEST' AND i.e_meil='views@example.invalid';
        INSERT INTO public.kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
            SELECT k.kaup_id,c.kauba_kategooria_id FROM public.kaup AS k CROSS JOIN public.kauba_kategooria AS c WHERE k.kauba_kood='ABC001' AND c.kood IN ('KODU','TOO');
        INSERT INTO public.kauba_variant (kaup_id,varv_id)
            SELECT k.kaup_id,v.varv_id FROM public.kaup AS k CROSS JOIN public.varv AS v WHERE k.kauba_kood='ABC001' AND v.kood IN ('MUST','VALGE');
        IF (SELECT count(*) FROM public.v_kaubad WHERE kauba_kood LIKE 'ABC00%')<>4
            OR (SELECT count(DISTINCT kauba_kood) FROM public.v_kaubad WHERE kauba_kood LIKE 'ABC00%')<>4
            OR (SELECT count(*) FROM public.v_kaubad_muutmiseks WHERE kauba_kood LIKE 'ABC00%')<>2
            OR EXISTS (SELECT 1 FROM public.v_kaubad_muutmiseks WHERE kauba_kood LIKE 'ABC00%' AND kauba_kood NOT IN ('ABC001','ABC003'))
            OR (SELECT count(*) FROM public.v_kauba_kategooriad WHERE kauba_kood LIKE 'ABC00%')<>2
            OR (SELECT count(*) FROM public.v_kauba_variandid WHERE kauba_kood LIKE 'ABC00%')<>2
            OR NOT EXISTS (SELECT 1 FROM public.v_kaubad WHERE kauba_kood='ABC004' AND brand_nimetus='Kontrollbränd' AND seisundi_nimetus='Lõpetatud') THEN
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Vale vaate sisu',
                DETAIL='Seisundite, seoste või korduste käsitlus ei vasta lähteandmetele.',
                HINT='Kontrolli ühendamisi ja seisundikoodide kasutust.';
        END IF;
        FOR v_vaade IN SELECT unnest(ARRAY['v_kaubad_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid'])
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
        IF (SELECT count(*) FROM public.kaup WHERE kauba_kood LIKE 'ABC00%')<>4 OR EXISTS (SELECT 1 FROM public.kaup WHERE kauba_kood='XYZ001')
            OR (SELECT count(*) FROM public.kauba_kategooria_omamine WHERE kaup_id IN (SELECT kaup_id FROM public.kaup WHERE kauba_kood LIKE 'ABC00%'))<>2
            OR (SELECT count(*) FROM public.kauba_variant WHERE kaup_id IN (SELECT kaup_id FROM public.kaup WHERE kauba_kood LIKE 'ABC00%'))<>2 THEN
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Lugemisvaate kõrvalmõju',
                DETAIL='Baastabelite read peavad jääma samaks.', HINT='Kontrolli muutmisreeglite sisu.';
        END IF;
        RAISE EXCEPTION USING ERRCODE='ZT001', MESSAGE='Kontrollandmete eemaldamine',
            DETAIL='Kontrollandmed eemaldatakse sama ploki alatehinguga.', HINT='See erand püütakse samas plokis.';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$kontroll$;

-- Täidetud andmebaasis peavad kõik avaliku liidese vaated olema kasutatavad.
DO $liides$
DECLARE
    v_vaade text;
    v_ridu bigint;
    v_veerud integer;
    v_oid oid;
    v_nimed text[]:=ARRAY[
        'v_kaubad_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid',
        'v_kaupade_detailid','v_kaupade_koondaruanne','v_aktiivsed_kaubad',
        'v_kategooriate_valikud','v_varvide_valikud','v_kaupade_kategooriate_loendid',
        'v_kaupade_kategooriate_pingeread','v_kaupade_json'];
    v_tabel record;
    v_sisu jsonb;
    v_enne jsonb:='{}'::jsonb;
    v_veerg text;
    v_lause text;
BEGIN
    IF (SELECT count(*) FROM pg_class AS c INNER JOIN pg_namespace AS n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind='v')<>cardinality(v_nimed) THEN
        RAISE EXCEPTION 'Avalikus liideses peab olema täpselt kaksteist kavandatud vaadet';
    END IF;
    FOREACH v_vaade IN ARRAY v_nimed LOOP
        v_oid:=to_regclass('public.'||v_vaade);
        IF v_oid IS NULL OR NOT EXISTS (SELECT 1 FROM pg_class
            WHERE oid=v_oid AND relkind='v'
              AND reloptions @> ARRAY['security_barrier=true']
              AND NOT coalesce(reloptions @> ARRAY['security_invoker=true'],false)
              AND char_length(obj_description(oid,'pg_class'))>80) THEN
            RAISE EXCEPTION 'Vaate % kommentaar või turvabarjäär puudub',v_vaade;
        END IF;
        IF pg_get_viewdef(v_oid,true) !~ 'ORDER BY' THEN
            RAISE EXCEPTION 'Vaates % puudub järjestus',v_vaade;
        END IF;
        IF (SELECT count(DISTINCT r.ev_type) FROM pg_rewrite AS r
            WHERE r.ev_class=v_oid AND r.ev_type IN ('2','3','4')
              AND r.is_instead AND r.ev_enabled='O'
              AND pg_get_ruledef(r.oid) ~ 'DO INSTEAD NOTHING')<>3 THEN
            RAISE EXCEPTION 'Vaade % vajab kolme toimeta muutmisreeglit',v_vaade;
        END IF;
        EXECUTE format('SELECT count(*) FROM public.%I',v_vaade) INTO v_ridu;
        IF v_ridu<1 THEN RAISE EXCEPTION 'Vaade % ei tagasta testandmetel ridu',v_vaade; END IF;
        RAISE NOTICE '%: % rida',v_vaade,v_ridu;
    END LOOP;
    IF EXISTS (SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name=ANY(v_nimed)
          AND (column_name IN ('id','kood') OR column_name ~ '_id$')) THEN
        RAISE EXCEPTION 'Lugemisliides ei tohi näidata üldist ega tehnilist identifikaatorit';
    END IF;
    SELECT count(*) INTO v_veerud FROM information_schema.columns
        WHERE table_schema='public' AND table_name='v_kaupade_kategooriate_pingeread';
    IF v_veerud<>4 THEN RAISE EXCEPTION 'Pingereavaates peab olema täpselt neli veergu'; END IF;
    IF (SELECT count(*) FROM information_schema.columns
        WHERE table_schema='public' AND table_name='v_kaupade_json')<>1
        OR NOT EXISTS (SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='v_kaupade_json'
              AND column_name='kauba_json' AND udt_name='jsonb') THEN
        RAISE EXCEPTION 'Hierarhiavaates peab olema üks JSONB-veerg';
    END IF;
    IF (SELECT array_agg(column_name::text ORDER BY ordinal_position) FROM information_schema.columns
        WHERE table_schema='public' AND table_name='v_aktiivsed_kaubad') IS DISTINCT FROM
        ARRAY['kauba_kood','nimetus','kategooria_kood','kategooria_nimetus',
            'kategooria_tyyp_nimetus','hind','kirjeldus','pildi_aadress'] THEN
        RAISE EXCEPTION 'Avaliku kataloogi veerud ei vasta lepingule või avaldavad siseandmeid';
    END IF;
    -- Võrdlus hõlmab kõigi baastabelite kogu sisu, mitte ainult kaubaridade arvu.
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
        EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),''[]''::jsonb) '
            'FROM public.%I AS t',v_tabel.tablename) INTO v_sisu;
        v_enne:=v_enne||jsonb_build_object(v_tabel.tablename,v_sisu);
    END LOOP;
    FOREACH v_vaade IN ARRAY v_nimed LOOP
        SELECT attname INTO STRICT v_veerg FROM pg_attribute
            WHERE attrelid=to_regclass('public.'||v_vaade) AND attnum=1 AND NOT attisdropped;
        FOREACH v_lause IN ARRAY ARRAY[
            format('INSERT INTO public.%I DEFAULT VALUES',v_vaade),
            format('UPDATE public.%I SET %I=%I',v_vaade,v_veerg,v_veerg),
            format('DELETE FROM public.%I',v_vaade)] LOOP
            EXECUTE v_lause;
            GET DIAGNOSTICS v_ridu=ROW_COUNT;
            IF v_ridu<>0 THEN RAISE EXCEPTION 'Vaate % muutmiskatse mõjus',v_vaade; END IF;
        END LOOP;
    END LOOP;
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
        EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),''[]''::jsonb) '
            'FROM public.%I AS t',v_tabel.tablename) INTO v_sisu;
        IF v_sisu IS DISTINCT FROM v_enne->v_tabel.tablename THEN
            RAISE EXCEPTION 'Vaadete muutmiskatsed muutsid tabelit %',v_tabel.tablename;
        END IF;
    END LOOP;
END;
$liides$;

-- Piirjuhtude kontrollandmed eemaldatakse alatehinguga.
DO $sisu$
DECLARE
    v_arv bigint;
    v_hore bigint;
    v_tihe bigint;
    v_json jsonb;
    v_loend text;
    v_seisund smallint;
    v_tyyp smallint;
    v_varv smallint;
    v_jarjestus text[];
BEGIN
    BEGIN
        INSERT INTO kauba_seisundi_liik (kood,nimetus,on_aktiivne)
            VALUES (99,'Tühi kontrollseisund',false);
        IF NOT EXISTS (SELECT 1 FROM v_kaupade_koondaruanne
            WHERE seisundi_kood=99 AND seisundi_nimetus='TÜHI KONTROLLSEISUND' AND kaupade_arv=0) THEN
            RAISE EXCEPTION 'Ka tühja ja suletud seisundi kaupade arv peab olema null';
        END IF;
        IF (SELECT sum(kaupade_arv) FROM v_kaupade_koondaruanne)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(*) FROM v_kaupade_koondaruanne)<>(SELECT count(*) FROM kauba_seisundi_liik)
            OR EXISTS (SELECT 1 FROM v_kaupade_koondaruanne AS v
                INNER JOIN kauba_seisundi_liik AS s ON s.kood=v.seisundi_kood
                WHERE v.kaupade_arv<>(SELECT count(*) FROM kaup AS k
                    WHERE k.kauba_seisundi_liik_id=s.kauba_seisundi_liik_id)) THEN
            RAISE EXCEPTION 'Koondaruanne peab esitama iga seisundi tegeliku kaupade arvu';
        END IF;
        SELECT array_agg(seisundi_kood::text) INTO v_jarjestus FROM v_kaupade_koondaruanne;
        IF v_jarjestus IS DISTINCT FROM (SELECT array_agg(seisundi_kood::text
            ORDER BY kaupade_arv DESC,seisundi_nimetus,seisundi_kood) FROM v_kaupade_koondaruanne) THEN
            RAISE EXCEPTION 'Koondaruande järjestus ei vasta OP10.1 nõudele';
        END IF;
        INSERT INTO kaup (kauba_kood,nimetus,kauba_seisundi_liik_id,brand_id,
            registreerija_id,viimase_muutja_id,hind,kirjeldus,reg_aeg,viimase_muutm_aeg)
        SELECT 'UVC00'||s.kood,'Vaate kontrollkaup '||s.kood,s.kauba_seisundi_liik_id,
            k.brand_id,k.registreerija_id,k.viimase_muutja_id,100,'Vaadete piirjuhtude kontroll.',
            TIMESTAMPTZ '2026-01-15 10:34:56+00',TIMESTAMPTZ '2026-07-15 09:34:56+00'
        FROM (SELECT brand_id,registreerija_id,viimase_muutja_id FROM kaup
            ORDER BY kauba_kood FETCH FIRST 1 ROW ONLY) AS k
        CROSS JOIN kauba_seisundi_liik AS s WHERE s.kood IN (1,2,3,4);
        INSERT INTO kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
        SELECT k.kaup_id,c.kauba_kategooria_id FROM kaup AS k
        CROSS JOIN kauba_kategooria AS c
        WHERE (k.kauba_kood='UVC001' AND c.kood IN ('NAISTELEFONID','KLASSIKALINE'))
            OR (k.kauba_kood='UVC003' AND c.kood='NAISTELEFONID');
        IF (SELECT count(*) FROM v_kaupade_detailid)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(DISTINCT kauba_kood) FROM v_kaupade_detailid)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(*) FROM v_kaupade_detailid WHERE kauba_kood LIKE 'UVC00%'
                AND eesmine_kaamera IS NULL AND tagumine_kaamera IS NULL AND sisemalu IS NULL
                AND ekraani_diagonaal IS NULL AND protsessor IS NULL AND ekraani_resolutsioon IS NULL)<>4 THEN
            RAISE EXCEPTION 'Detailvaade peab säilitama ka telefonialaliigita kaubad ühe reana';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM v_kaupade_detailid WHERE kauba_kood='APL002'
            AND brand_nimetus='Apple' AND eesmine_kaamera='12 MP' AND tagumine_kaamera='48 MP'
            AND sisemalu='256 GB' AND ekraani_diagonaal='6,1 tolli'
            AND protsessor='Apple A16 Bionic' AND ekraani_resolutsioon='2556 × 1179 pikslit'
            AND ekraani_laius_pikslites=2556 AND ekraani_korgus_pikslites=1179
            AND on_veekindel AND NOT on_sormejalelugeja) THEN
            RAISE EXCEPTION 'Detailvaate tehnilised näitajad ei vasta telefoni klassifikaatoritele';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM v_kaupade_detailid WHERE kauba_kood='UVC001'
            AND registreerimise_aeg='15.01.2026 12:34:56'
            AND viimase_muutmise_aeg='15.07.2026 12:34:56')
            OR NOT EXISTS (SELECT 1 FROM v_kaubad_muutmiseks WHERE kauba_kood='UVC001'
                AND reg_aeg='15.01.2026 12:34:56') THEN
            RAISE EXCEPTION 'Ajad peavad olema Eesti talve- ja suveajas nõutud vormingus';
        END IF;
        -- Puuduv ees- või perenimi ei tohi muuta töötaja silti NULL-iks.
        UPDATE isik SET eesnimi=NULL,perenimi='Kontrollija'
            WHERE isik_id=(SELECT isik_id FROM tootaja
                WHERE tootaja_id=(SELECT registreerija_id FROM kaup WHERE kauba_kood='UVC001'));
        UPDATE kaup SET viimase_muutja_id=(SELECT tootaja_id FROM tootaja
            WHERE tootaja_id<>registreerija_id ORDER BY tootaja_id FETCH FIRST 1 ROW ONLY)
            WHERE kauba_kood='UVC001';
        UPDATE isik SET eesnimi='Muutja',perenimi=NULL
            WHERE isik_id=(SELECT isik_id FROM tootaja
                WHERE tootaja_id=(SELECT viimase_muutja_id FROM kaup WHERE kauba_kood='UVC001'));
        IF NOT EXISTS (SELECT 1 FROM v_kaupade_detailid AS v
            INNER JOIN kaup AS k USING (kauba_kood)
            INNER JOIN tootaja AS t ON t.tootaja_id=k.registreerija_id
            INNER JOIN isik AS i USING (isik_id)
            WHERE v.kauba_kood='UVC001' AND v.registreerija='Kontrollija ('||i.e_meil||')'
              AND v.viimane_muutja=(SELECT 'Muutja ('||mi.e_meil||')'
                  FROM tootaja AS mt INNER JOIN isik AS mi USING (isik_id)
                  WHERE mt.tootaja_id=k.viimase_muutja_id)) THEN
            RAISE EXCEPTION 'Töötaja silt peab sisaldama olemasolevat nime ja meiliaadressi';
        END IF;
        IF (SELECT count(*) FROM v_aktiivsed_kaubad WHERE kauba_kood='UVC002')<>1
            OR NOT EXISTS (SELECT 1 FROM v_aktiivsed_kaubad
                WHERE kauba_kood='UVC002' AND kategooria_kood IS NULL)
            OR EXISTS (SELECT 1 FROM v_aktiivsed_kaubad AS v INNER JOIN kaup AS k USING (kauba_kood)
                INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood<>2)
            OR (SELECT count(*) FROM v_aktiivsed_kaubad
                WHERE kauba_kood='APL002' AND kategooria_kood='NAISTELEFONID')<>1
            OR EXISTS (SELECT kauba_kood,kategooria_kood FROM v_aktiivsed_kaubad
                GROUP BY kauba_kood,kategooria_kood HAVING count(*)>1) THEN
            RAISE EXCEPTION 'Kataloog peab näitama ainult aktiivseid kaupu õige kategooriaseosega';
        END IF;
        IF (SELECT count(*) FROM v_kaupade_detailid WHERE kauba_kood LIKE 'UVC00%' AND seisundi_kood=1)<>1
            OR (SELECT count(*) FROM v_kaupade_detailid WHERE kauba_kood LIKE 'UVC00%' AND seisundi_kood=2)<>1
            OR (SELECT count(*) FROM v_kaupade_detailid WHERE kauba_kood LIKE 'UVC00%' AND seisundi_kood IN (2,3))<>2 THEN
            RAISE EXCEPTION 'OP3.1, OP6.1 ja OP9.1 filtrid peavad lähtuma sisulistest seisundikoodidest';
        END IF;
        SELECT kategooriad INTO STRICT v_loend FROM v_kaupade_kategooriate_loendid WHERE kauba_kood='UVC001';
        IF v_loend<>'Naistetelefonid (Sihtgrupp), Klassikalise välimusega telefonid (Välimus)'
            OR NOT EXISTS (SELECT 1 FROM v_kaupade_kategooriate_loendid WHERE kauba_kood='UVC002' AND kategooriad='')
            OR (SELECT count(*) FROM v_kaupade_kategooriate_loendid)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(DISTINCT kauba_kood) FROM v_kaupade_kategooriate_loendid)<>(SELECT count(*) FROM kaup) THEN
            RAISE EXCEPTION 'Kategoorialoend peab säilitama ka tühja loendiga kaubad ühe reana';
        END IF;
        IF (SELECT count(*) FROM v_kaupade_kategooriate_pingeread)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(DISTINCT kauba_kood) FROM v_kaupade_kategooriate_pingeread)<>(SELECT count(*) FROM kaup) THEN
            RAISE EXCEPTION 'Pingereas peab olema üks rida iga kauba kohta';
        END IF;
        SELECT kategooriate_arv,hore_koht,tihe_koht INTO STRICT v_arv,v_hore,v_tihe
            FROM v_kaupade_kategooriate_pingeread WHERE kauba_kood='UVC003';
        IF v_arv<>1 OR v_hore<>(SELECT 1+count(*) FROM v_kaupade_kategooriate_pingeread WHERE kategooriate_arv>1)
            OR v_tihe<>(SELECT 1+count(DISTINCT kategooriate_arv) FROM v_kaupade_kategooriate_pingeread WHERE kategooriate_arv>1)
            OR v_hore=v_tihe
            OR NOT EXISTS (SELECT 1 FROM v_kaupade_kategooriate_pingeread AS a
                INNER JOIN v_kaupade_kategooriate_pingeread AS b ON b.kauba_kood='UVC004'
                WHERE a.kauba_kood='UVC002' AND a.kategooriate_arv=0 AND b.kategooriate_arv=0
                  AND a.hore_koht=b.hore_koht AND a.tihe_koht=b.tihe_koht)
            OR EXISTS (SELECT 1 FROM v_kaupade_kategooriate_pingeread AS v
                INNER JOIN kaup AS k USING (kauba_kood)
                WHERE v.kategooriate_arv<>(SELECT count(*) FROM kauba_kategooria_omamine AS o WHERE o.kaup_id=k.kaup_id)) THEN
            RAISE EXCEPTION 'Pingeread peavad säilitama viigid, hõreda järgu vahed ja nullid';
        END IF;
        IF EXISTS (SELECT 1 FROM v_kaupade_kategooriate_pingeread AS v
            WHERE v.hore_koht<>(SELECT 1+count(*) FROM v_kaupade_kategooriate_pingeread AS p
                WHERE p.kategooriate_arv>v.kategooriate_arv)
               OR v.tihe_koht<>(SELECT 1+count(DISTINCT p.kategooriate_arv)
                   FROM v_kaupade_kategooriate_pingeread AS p
                   WHERE p.kategooriate_arv>v.kategooriate_arv)) THEN
            RAISE EXCEPTION 'Iga kauba koht peab vastama suurema kategooriate arvuga kaupadele';
        END IF;
        SELECT kauba_json INTO STRICT v_json FROM v_kaupade_json WHERE kauba_json->>'kauba_kood'='UVC001';
        IF jsonb_typeof(v_json)<>'object' OR jsonb_array_length(v_json->'kategooriad')<>2
            OR v_json->'kategooriad'->0 IS DISTINCT FROM jsonb_build_object('kategooria','Naistetelefonid','tyyp','Sihtgrupp')
            OR v_json->'kategooriad'->1 IS DISTINCT FROM jsonb_build_object(
                'kategooria','Klassikalise välimusega telefonid','tyyp','Välimus')
            OR NOT EXISTS (SELECT 1 FROM v_kaupade_json WHERE kauba_json->>'kauba_kood'='UVC002'
                AND kauba_json->'kategooriad'='[]'::jsonb)
            OR (SELECT count(*) FROM v_kaupade_json)<>(SELECT count(*) FROM kaup)
            OR (SELECT count(DISTINCT kauba_json->>'kauba_kood') FROM v_kaupade_json)<>(SELECT count(*) FROM kaup)
            OR EXISTS (SELECT kauba_kood FROM kaup EXCEPT SELECT kauba_json->>'kauba_kood' FROM v_kaupade_json)
            OR EXISTS (SELECT kauba_json->>'kauba_kood' FROM v_kaupade_json EXCEPT SELECT kauba_kood FROM kaup) THEN
            RAISE EXCEPTION 'JSON peab sisaldama iga kauba õigeid kategooriaid ja eristatavat koodi';
        END IF;
        SELECT kauba_kategooria_tyyp_id INTO STRICT v_tyyp FROM kauba_kategooria_tyyp WHERE kood='SIHTGRUPP';
        UPDATE kauba_kategooria_tyyp SET on_aktiivne=false WHERE kauba_kategooria_tyyp_id=v_tyyp;
        IF EXISTS (SELECT 1 FROM v_kategooriate_valikud WHERE kategooria_kood='NAISTELEFONID')
            OR NOT EXISTS (SELECT 1 FROM v_kauba_kategooriad WHERE kauba_kood='UVC001' AND kategooria_kood='NAISTELEFONID') THEN
            RAISE EXCEPTION 'Suletud tüüp peab kaduma valikust, kuid säilima olemasoleva kauba seostes';
        END IF;
        UPDATE kauba_kategooria_tyyp SET on_aktiivne=true WHERE kauba_kategooria_tyyp_id=v_tyyp;
        UPDATE kauba_kategooria SET on_aktiivne=false WHERE kood='NAISTELEFONID';
        IF EXISTS (SELECT 1 FROM v_kategooriate_valikud WHERE kategooria_kood='NAISTELEFONID') THEN
            RAISE EXCEPTION 'Suletud kategooria ei tohi olla uue seose valikus';
        END IF;
        SELECT varv_id INTO STRICT v_varv FROM varv WHERE kood='BLACK';
        UPDATE varv SET on_aktiivne=false WHERE varv_id=v_varv;
        IF EXISTS (SELECT 1 FROM v_varvide_valikud WHERE varvi_kood IN ('BLACK','BLUE'))
            OR NOT EXISTS (SELECT 1 FROM v_kauba_variandid WHERE kauba_kood='APL002' AND varvi_kood='BLACK') THEN
            RAISE EXCEPTION 'Suletud värv peab kaduma valikust, kuid säilima olemasolevates variantides';
        END IF;
        SELECT kauba_seisundi_liik_id INTO STRICT v_seisund FROM kauba_seisundi_liik WHERE kood=1;
        UPDATE kaup SET kauba_seisundi_liik_id=v_seisund;
        IF NOT EXISTS (SELECT 1 FROM v_kaupade_koondaruanne WHERE seisundi_kood=2 AND kaupade_arv=0)
            OR EXISTS (SELECT 1 FROM v_aktiivsed_kaubad) THEN
            RAISE EXCEPTION 'Aktiivsete kaupade puudumisel peab kataloog olema tühi ja seisundi arv null';
        END IF;
        RAISE EXCEPTION USING ERRCODE='ZT002',MESSAGE='Kontrollandmete eemaldamine';
    EXCEPTION WHEN SQLSTATE 'ZT002' THEN NULL;
    END;
END;
$sisu$;

-- Üheveeruline koodipäring hierarhilise esituse põhjal.
SELECT kauba_json->>'kauba_kood' AS kauba_kood FROM public.v_kaupade_json ORDER BY kauba_kood;
