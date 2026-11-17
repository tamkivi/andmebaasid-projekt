-- Rakenduse vaadete sisu ja vormide sisendite kontroll eraldi testandmebaasis.
START TRANSACTION;
-- Otsesed muudatused valmistavad ette piirjuhud ja võetakse lõpus tagasi.
ALTER TABLE public.kaup DISABLE TRIGGER USER;
ALTER TABLE public.nutitelefon DISABLE TRIGGER USER;
ALTER TABLE public.kauba_variant DISABLE TRIGGER USER;
ALTER TABLE public.kauba_kategooria_omamine DISABLE TRIGGER USER;
UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2026-01-15 10:20:30+00',
    viimase_muutm_aeg=TIMESTAMPTZ '2026-01-15 10:20:30+00' WHERE kauba_kood='APL001';
UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2026-07-15 10:20:30+00',
    viimase_muutm_aeg=TIMESTAMPTZ '2026-07-15 10:20:30+00' WHERE kauba_kood='APL002';
UPDATE public.kauba_seisundi_liik SET nimetus='Kontrollseisund '||kood;
INSERT INTO public.kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
    SELECT k.kaup_id,c.kauba_kategooria_id FROM public.kaup AS k
    CROSS JOIN public.kauba_kategooria AS c
    WHERE k.kauba_kood='APL001' AND c.kood IN ('MEESTELEFONID','KLASSIKALINE')
    ON CONFLICT (kaup_id,kauba_kategooria_id) DO NOTHING;
INSERT INTO public.kauba_variant (kaup_id,varv_id)
    SELECT k.kaup_id,v.varv_id FROM public.kaup AS k CROSS JOIN public.varv AS v
    WHERE k.kauba_kood='APL001' AND v.kood IN ('BLACK','WHITE')
    ON CONFLICT (kaup_id,varv_id) DO NOTHING;
DELETE FROM public.kauba_kategooria_omamine WHERE kaup_id=(
    SELECT kaup_id FROM public.kaup WHERE kauba_kood='APL003');
DELETE FROM public.kauba_variant WHERE kaup_id=(
    SELECT kaup_id FROM public.kaup WHERE kauba_kood='APL003');
INSERT INTO public.kaup (kauba_kood,nimetus,hind,kirjeldus,brand_id,
    kauba_seisundi_liik_id,registreerija_id,viimase_muutja_id)
    SELECT 'UAP004','Telefonikirjeta kontrollkaup',1,'Ainult vaadete piirjuhu kontroll.',
        k.brand_id,k.kauba_seisundi_liik_id,k.registreerija_id,k.viimase_muutja_id
    FROM public.kaup AS k WHERE k.kauba_kood='APL004';
DO $vaated$
DECLARE
    v_loend text;
    v_tabel text;
    v_vaade text;
    v_veerg text;
    v_kood text;
    v_ridu bigint;
    v_sort text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.kauba_seisundi_liik WHERE kood<>kauba_seisundi_liik_id) THEN
        RAISE EXCEPTION 'Katse vajab seisundikoodist erinevaid tehnilisi tunnuseid';
    END IF;
    IF EXISTS (SELECT 1 FROM public.v_ootel_kaubad AS v JOIN public.kaup AS k USING (kauba_kood)
        JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood<>1)
        OR (SELECT count(*) FROM public.v_ootel_kaubad)<>(SELECT count(*) FROM public.kaup AS k
            JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood=1)
        OR EXISTS (SELECT 1 FROM public.v_aktiivsed_kaubad_haldurile AS v
            JOIN public.kaup AS k USING (kauba_kood)
            JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood<>2)
        OR (SELECT count(*) FROM public.v_aktiivsed_kaubad_haldurile)<>(SELECT count(*) FROM public.kaup AS k
            JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood=2) THEN
        RAISE EXCEPTION 'Seisundivaated ei järgi koodi või kaotavad ridu';
    END IF;
    FOREACH v_vaade IN ARRAY ARRAY['v_ootel_kaubad','v_aktiivsed_kaubad_haldurile',
        'v_kauba_muutmise_vorm','v_kaupade_detailid_seostega'] LOOP
        EXECUTE format('SELECT (array_agg(kauba_kood))::text FROM public.%I',v_vaade) INTO v_loend;
        EXECUTE format('SELECT (array_agg(kauba_kood ORDER BY nimetus,kauba_kood))::text FROM public.%I',v_vaade) INTO v_sort;
        IF v_loend IS DISTINCT FROM v_sort THEN RAISE EXCEPTION 'Vaate % järjestus on vale',v_vaade; END IF;
    END LOOP;
    IF (SELECT reg_aeg FROM public.v_ootel_kaubad WHERE kauba_kood='APL001') IS DISTINCT FROM '15.01.2026 12:20:30'
        OR (SELECT reg_aeg FROM public.v_aktiivsed_kaubad_haldurile WHERE kauba_kood='APL002') IS DISTINCT FROM '15.07.2026 13:20:30' THEN
        RAISE EXCEPTION 'Talve- või suveaja esitus on vale';
    END IF;
    IF (SELECT count(*) FROM public.v_kauba_muutmise_vorm)<>(SELECT count(*) FROM public.kaup AS k
        JOIN public.nutitelefon AS n USING (kaup_id)
        JOIN public.kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id) WHERE s.kood IN (1,3))
        OR EXISTS (SELECT 1 FROM public.v_kauba_muutmise_vorm AS v
            JOIN public.kaup AS k USING (kauba_kood) WHERE v.ver<>k.xmin::text)
        OR EXISTS (SELECT kauba_kood FROM public.v_kauba_muutmise_vorm GROUP BY kauba_kood HAVING count(*)<>1)
        OR NOT EXISTS (SELECT 1 FROM public.v_kauba_muutmise_vorm
            WHERE kauba_kood='APL001' AND on_veekindel IS TRUE AND on_sormejalelugeja IS NULL) THEN
        RAISE EXCEPTION 'Muutmisvormi read, versioon või märkeruudu eeltäide on vale';
    END IF;
    IF (SELECT count(*) FROM public.v_kaupade_detailid_seostega)<>(SELECT count(*) FROM public.kaup)
        OR EXISTS (SELECT kauba_kood FROM public.v_kaupade_detailid_seostega GROUP BY kauba_kood HAVING count(*)<>1)
        OR NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='UAP004'
            AND on_veekindel='' AND on_sormejalelugeja='' AND kategooriad='' AND variandid='')
        OR NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='APL003'
            AND kategooriad='' AND variandid='')
        OR NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='APL004') THEN
        RAISE EXCEPTION 'Detailvaade kaotas seosteta, telefonita või lõpetatud kauba või paljundas ridu';
    END IF;
    SELECT string_agg(c.kategooria_nimetus||' ('||c.kategooria_tyyp_nimetus||')',', '
        ORDER BY c.kategooria_tyyp_nimetus,c.kategooria_nimetus,c.kategooria_kood)
        INTO v_loend FROM public.v_kauba_kategooriad AS c WHERE kauba_kood='APL001';
    IF NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='APL001'
        AND kategooriad=v_loend AND variandid='Must, Valge' AND on_veekindel='Jah' AND on_sormejalelugeja='Ei') THEN
        RAISE EXCEPTION 'Kahe kategooria ja kahe värvi koondloend või Jah/Ei esitus on vale';
    END IF;
    FOR v_tabel,v_vaade,v_veerg IN SELECT * FROM (VALUES
        ('brand','v_brandide_valikud','brandi_kood'),
        ('kaamera','v_kaamerate_valikud','kaamera_kood'),
        ('sisemalu','v_sisemalude_valikud','sisemalu_kood'),
        ('diagonaal','v_diagonaalide_valikud','diagonaali_kood'),
        ('protsessor','v_protsessorite_valikud','protsessori_kood'),
        ('ekraani_resolutsioon','v_ekraani_resolutsioonide_valikud','ekraani_resolutsiooni_kood')
    ) AS x(tabel,vaade,veerg) LOOP
        EXECUTE format('SELECT kood::text FROM public.%I WHERE on_aktiivne ORDER BY kood LIMIT 1',v_tabel) INTO STRICT v_kood;
        EXECUTE format('UPDATE public.%I SET on_aktiivne=FALSE WHERE kood::text=$1',v_tabel) USING v_kood;
        EXECUTE format('SELECT %I::text FROM public.%I WHERE %I::text=$1',v_veerg,v_vaade,v_veerg) INTO v_loend USING v_kood;
        IF v_loend IS NOT NULL THEN RAISE EXCEPTION 'Suletud klassifikaator jäi vaatesse %',v_vaade; END IF;
        EXECUTE format('SELECT count(*) FROM public.%I',v_vaade) INTO v_ridu;
        EXECUTE format('SELECT count(*)::text FROM public.%I WHERE on_aktiivne',v_tabel) INTO v_loend;
        IF v_ridu<>v_loend::bigint THEN RAISE EXCEPTION 'Valikute hulk on vale vaates %',v_vaade; END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.v_kategooriate_valikud_tyybiga AS v
        JOIN public.kauba_kategooria AS c ON c.kood=v.kategooria_kood
        JOIN public.kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
        WHERE v.valiku_nimetus<>c.nimetus||' ('||t.nimetus||')') THEN
        RAISE EXCEPTION 'Kategooria valikust puudub tüübi nimetus';
    END IF;
    INSERT INTO public.kauba_kategooria_tyyp (kood,nimetus)
        VALUES ('U11TY1','Kontrolltüüp üks'),('U11TY2','Kontrolltüüp kaks');
    INSERT INTO public.kauba_kategooria (kood,nimetus,kauba_kategooria_tyyp_id)
        SELECT 'U11KAT'||right(t.kood,1),'Samanimeline kategooria',t.kauba_kategooria_tyyp_id
        FROM public.kauba_kategooria_tyyp AS t WHERE t.kood IN ('U11TY1','U11TY2');
    IF (SELECT count(DISTINCT valiku_nimetus) FROM public.v_kategooriate_valikud_tyybiga
        WHERE kategooria_kood IN ('U11KAT1','U11KAT2'))<>2 THEN
        RAISE EXCEPTION 'Tüüp ei erista samanimelisi kategooriaid';
    END IF;
    UPDATE public.kauba_kategooria SET on_aktiivne=FALSE WHERE kood='MEESTELEFONID';
    UPDATE public.kauba_kategooria_tyyp SET on_aktiivne=FALSE WHERE kood='VALIMUS';
    IF EXISTS (SELECT 1 FROM public.v_kategooriate_valikud_tyybiga
        WHERE kategooria_kood IN ('MEESTELEFONID','KLASSIKALINE')) THEN
        RAISE EXCEPTION 'Suletud kategooria või tüübi valik jäi nähtavaks';
    END IF;
    IF (SELECT count(*) FROM public.v_seotud_kategooriate_valikud
        WHERE kategooria_kood IN ('MEESTELEFONID','KLASSIKALINE'))<>2
        OR EXISTS (SELECT kategooria_kood FROM public.v_seotud_kategooriate_valikud
            GROUP BY kategooria_kood HAVING count(*)<>1) THEN
        RAISE EXCEPTION 'Eemaldamise valik kaotas suletud seose või kordab kategooriat';
    END IF;
END;
$vaated$;
ROLLBACK;

START TRANSACTION;
SELECT set_config('epood.vormi_e_meil',(
    SELECT i.e_meil FROM public.isik AS i JOIN public.tootaja AS t USING (isik_id)
    JOIN public.tootaja_rolli_omamine AS o USING (tootaja_id)
    JOIN public.tootaja_roll AS r USING (tootaja_roll_id)
    WHERE r.kood='KAUBAHALDUR' AND o.lopu_aeg='infinity' ORDER BY t.tootaja_id LIMIT 1),true);
SELECT set_config('epood.vormi_juhataja',(
    SELECT i.e_meil FROM public.isik AS i JOIN public.tootaja AS t USING (isik_id)
    JOIN public.tootaja_rolli_omamine AS o USING (tootaja_id)
    JOIN public.tootaja_roll AS r USING (tootaja_roll_id)
    WHERE r.kood='JUHATAJA' AND o.lopu_aeg='infinity' ORDER BY t.tootaja_id LIMIT 1),true);
UPDATE public.brand SET on_aktiivne=FALSE WHERE kood='GOOGLE';
DO $omadused$
BEGIN
    IF (SELECT count(*) FROM pg_proc AS p JOIN pg_language AS l ON l.oid=p.prolang
        WHERE p.pronamespace='public'::regnamespace AND p.proname IN (
            'f_registreeri_nutitelefon_vormist','f_muuda_kaup_vormist')
        AND l.lanname='sql' AND p.prosqlbody IS NOT NULL AND NOT p.prosecdef
        AND p.proconfig @> ARRAY['search_path=public, pg_temp']
        AND obj_description(p.oid,'pg_proc') IS NOT NULL)<>2 THEN
        RAISE EXCEPTION 'Vormifunktsioonide omadused on puudulikud';
    END IF;
END;
$omadused$;
SET LOCAL ROLE epood_rakendus;
DO $vormid$
DECLARE
    v_e_meil varchar:=current_setting('epood.vormi_e_meil');
    v_juhataja varchar:=current_setting('epood.vormi_juhataja');
    v_vaade text;
    v_arv bigint;
    v_r public.v_kauba_muutmise_vorm%ROWTYPE;
    v_reegel text;
BEGIN
    FOREACH v_vaade IN ARRAY ARRAY['v_ootel_kaubad','v_aktiivsed_kaubad_haldurile','v_kauba_muutmise_vorm','v_brandide_valikud','v_kaamerate_valikud','v_sisemalude_valikud','v_diagonaalide_valikud','v_protsessorite_valikud','v_ekraani_resolutsioonide_valikud','v_kategooriate_valikud_tyybiga','v_kaupade_detailid_seostega','v_seotud_kategooriate_valikud'] LOOP
        EXECUTE format('SELECT count(*) FROM public.%I',v_vaade) INTO v_arv;
        BEGIN
            EXECUTE format('DELETE FROM public.%I',v_vaade);
            GET DIAGNOSTICS v_arv=ROW_COUNT;
            IF v_arv<>0 THEN RAISE EXCEPTION 'Rakenduseroll muutis vaate % kaudu andmeid',v_vaade; END IF;
        EXCEPTION WHEN insufficient_privilege THEN NULL;
        END;
    END LOOP;
    BEGIN
        PERFORM kauba_kood FROM public.kaup;
        RAISE EXCEPTION 'Rakenduseroll sai baastabelit lugeda';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    IF public.f_registreeri_nutitelefon_vormist(
            p_kauba_kood:='UAP001',p_nimetus:='Vormi kontrolltelefon UAP001',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
            p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'UAP001' THEN
        RAISE EXCEPTION 'Registreerimise tulemus ei vasta sisendile: UAP001';
    END IF;
    IF public.f_registreeri_nutitelefon_vormist(
            p_kauba_kood:='UAP002',p_nimetus:='Vormi kontrolltelefon UAP002',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
            p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'UAP002' THEN
        RAISE EXCEPTION 'Registreerimise tulemus ei vasta sisendile: UAP002';
    END IF;
    IF public.f_registreeri_nutitelefon_vormist(
            p_kauba_kood:='UAP003',p_nimetus:='Vormi kontrolltelefon UAP003',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_juhataja,p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
            p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM NULL THEN
        RAISE EXCEPTION 'Registreerimise tulemus ei vasta sisendile: UAP003';
    END IF;
    IF public.f_registreeri_nutitelefon_vormist(
            p_kauba_kood:='UAP003',p_nimetus:='Vormi kontrolltelefon UAP003',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:='puuduv@example.invalid',p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
            p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM NULL THEN
        RAISE EXCEPTION 'Registreerimise tulemus ei vasta sisendile: UAP003';
    END IF;
    IF public.f_registreeri_nutitelefon_vormist(
            p_kauba_kood:='UAP003',p_nimetus:='Vormi kontrolltelefon UAP003',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_e_meil,p_brandi_kood:='GOOGLE',p_on_veekindel:=NULL,
            p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM NULL THEN
        RAISE EXCEPTION 'Registreerimise tulemus ei vasta sisendile: UAP003';
    END IF;
    IF public.f_registreeri_nutitelefon(
            p_kauba_kood:='UAP002',p_nimetus:='Vormi kontrolltelefon UAP002',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',p_on_veekindel:=FALSE,
            p_on_sormejalelugeja:=FALSE,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS NOT NULL THEN
        RAISE EXCEPTION 'Korduv registreerimine peab tagastama NULL-i';
    END IF;
    IF public.f_registreeri_nutitelefon(
            p_kauba_kood:='UAP005',p_nimetus:='Vormi kontrolltelefon UAP005',p_hind:='899',
            p_kirjeldus:='Vormi kaudu edastatud näidissisendid.',p_pildi_aadress:=NULL,
            p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',p_on_veekindel:=FALSE,
            p_on_sormejalelugeja:=FALSE,p_kaamera_kood_eesmine:='12',
            p_kaamera_kood_tagumine:='48',p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'UAP005' THEN
        RAISE EXCEPTION 'Alusfunktsiooni võrdluskutse ebaõnnestus';
    END IF;
    -- Andmebaasis varem kinnitatud rea xmin muutub esimesel vormikutsest salvestamisel.
    SELECT * INTO STRICT v_r FROM public.v_kauba_muutmise_vorm WHERE kauba_kood='APL001';
    IF public.f_muuda_kaup_vormist(
            p_ver:=v_r.ver,p_kauba_kood_vana:=v_r.kauba_kood,p_kauba_kood_uus:=v_r.kauba_kood,
            p_nimetus:=v_r.nimetus,p_hind:=v_r.hind,p_kirjeldus:=v_r.kirjeldus,
            p_pildi_aadress:=v_r.pildi_aadress,p_e_meil:=v_e_meil,p_brandi_kood:=v_r.brandi_kood,
            p_on_veekindel:=v_r.on_veekindel,
            p_on_sormejalelugeja:=v_r.on_sormejalelugeja,
            p_kaamera_kood_eesmine:=v_r.eesmise_kaamera_kood,p_kaamera_kood_tagumine:=v_r.tagumise_kaamera_kood,
            p_sisemalu_kood:=v_r.sisemalu_kood,p_diagonaali_kood:=v_r.diagonaali_kood,
            p_protsessori_kood:=v_r.protsessori_kood,p_ekraani_resolutsiooni_kood:=v_r.ekraani_resolutsiooni_kood) IS DISTINCT FROM 'APL001' THEN
        RAISE EXCEPTION 'Eeltäidetud rea muutmata salvestamine ebaõnnestus';
    END IF;
    IF public.f_muuda_kaup_vormist(
            p_ver:=v_r.ver,p_kauba_kood_vana:=v_r.kauba_kood,p_kauba_kood_uus:=v_r.kauba_kood,
            p_nimetus:=v_r.nimetus,p_hind:=v_r.hind,p_kirjeldus:=v_r.kirjeldus,
            p_pildi_aadress:=v_r.pildi_aadress,p_e_meil:=v_e_meil,p_brandi_kood:=v_r.brandi_kood,
            p_on_veekindel:=v_r.on_veekindel,
            p_on_sormejalelugeja:=v_r.on_sormejalelugeja,
            p_kaamera_kood_eesmine:=v_r.eesmise_kaamera_kood,p_kaamera_kood_tagumine:=v_r.tagumise_kaamera_kood,
            p_sisemalu_kood:=v_r.sisemalu_kood,p_diagonaali_kood:=v_r.diagonaali_kood,
            p_protsessori_kood:=v_r.protsessori_kood,p_ekraani_resolutsiooni_kood:=v_r.ekraani_resolutsiooni_kood) IS NOT NULL THEN
        RAISE EXCEPTION 'Aegunud vorm kirjutas uuema versiooni üle';
    END IF;
    SELECT * INTO STRICT v_r FROM public.v_kauba_muutmise_vorm WHERE kauba_kood='APL001';
    IF public.f_muuda_kaup(
            p_ver:=v_r.ver,p_kauba_kood_vana:=v_r.kauba_kood,p_kauba_kood_uus:=v_r.kauba_kood,
            p_nimetus:=v_r.nimetus,p_hind:=v_r.hind,p_kirjeldus:=v_r.kirjeldus,
            p_pildi_aadress:=v_r.pildi_aadress,p_e_meil:=v_e_meil,p_brandi_kood:=v_r.brandi_kood,
            p_on_veekindel:=coalesce(v_r.on_veekindel,FALSE),
            p_on_sormejalelugeja:=coalesce(v_r.on_sormejalelugeja,FALSE),
            p_kaamera_kood_eesmine:=v_r.eesmise_kaamera_kood,p_kaamera_kood_tagumine:=v_r.tagumise_kaamera_kood,
            p_sisemalu_kood:=v_r.sisemalu_kood,p_diagonaali_kood:=v_r.diagonaali_kood,
            p_protsessori_kood:=v_r.protsessori_kood,p_ekraani_resolutsiooni_kood:=v_r.ekraani_resolutsiooni_kood) IS DISTINCT FROM 'APL001' THEN
        RAISE EXCEPTION 'Vormirea edastamine alusfunktsioonile ebaõnnestus';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.v_kaupade_detailid_seostega
        WHERE kauba_kood='UAP001' AND on_veekindel='Ei' AND on_sormejalelugeja='Ei' AND pildi_aadress IS NULL) THEN
        RAISE EXCEPTION 'Valimata märkeruudud või tühi pildiaadress ei salvestunud õigesti';
    END IF;
    IF public.f_lisa_kaup_kategooriasse(p_kauba_kood:='UAP001',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_lisa_kaup_kategooriasse(p_kauba_kood:='UAP001',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_lisa_kauba_variant(p_kauba_kood:='UAP001',p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_lisa_kauba_variant(p_kauba_kood:='UAP001',p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_lisa_kauba_variant(p_kauba_kood:='UAP001',p_varv_kood:='BLUE',p_e_meil:=v_e_meil) IS NOT NULL THEN
        RAISE EXCEPTION 'Seose lisamine, kordus või suletud valiku kontroll ebaõnnestus';
    END IF;
    IF public.f_aktiveeri_kaup(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_aktiveeri_kaup(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_aktiveeri_kaup(p_kauba_kood:='PUUDUV',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='UAP001',p_e_meil:=v_juhataja) IS NOT NULL
        OR public.f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='UAP001',p_e_meil:='puuduv@example.invalid') IS NOT NULL THEN
        RAISE EXCEPTION 'Aktiveerimine, kordus, puuduv kaup või sobimatu tegija ei andnud õiget tulemust';
    END IF;
    BEGIN
        PERFORM public.f_unusta_kaup(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil);
        RAISE EXCEPTION 'Aktiivse kauba unustamine õnnestus';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
        IF v_reegel<>'kaup_kustutamine' THEN RAISE; END IF;
    END;
    IF public.f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_eemalda_kaup_kategooriast(p_kauba_kood:='UAP001',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_eemalda_kaup_kategooriast(p_kauba_kood:='UAP001',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_eemalda_kauba_variant(p_kauba_kood:='UAP001',p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP001'
        OR public.f_eemalda_kauba_variant(p_kauba_kood:='UAP001',p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS NOT NULL
        OR public.f_unusta_kaup(p_kauba_kood:='UAP002',p_e_meil:=v_e_meil) IS DISTINCT FROM 'UAP002'
        OR public.f_unusta_kaup(p_kauba_kood:='UAP002',p_e_meil:=v_e_meil) IS NOT NULL THEN
        RAISE EXCEPTION 'Mitteaktiivseks muutmine, seoste eemaldamine või ootel kauba unustamine ebaõnnestus';
    END IF;
    BEGIN
        PERFORM public.f_aktiveeri_kaup(p_kauba_kood:='UAP001',p_e_meil:=v_e_meil);
        RAISE EXCEPTION 'Kategooriata kauba aktiveerimine õnnestus';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
        IF v_reegel<>'kaup_aktiveerimine' THEN RAISE; END IF;
    END;
END;
$vormid$;
RESET ROLE;
DO $salvestatud$
BEGIN
    IF EXISTS (SELECT 1 FROM public.kaup WHERE kauba_kood='UAP002')
        OR NOT EXISTS (SELECT 1 FROM public.kaup AS k JOIN public.nutitelefon AS n USING (kaup_id)
            WHERE k.kauba_kood='UAP001' AND NOT n.on_veekindel AND NOT n.on_sormejalelugeja) THEN
        RAISE EXCEPTION 'Rakenduserolli kutsete tegelikud järeltingimused ei kehti';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.kaup AS k JOIN public.nutitelefon AS n USING (kaup_id)
        WHERE k.kauba_kood='APL001' AND n.on_veekindel AND NOT n.on_sormejalelugeja)
        OR NOT EXISTS (SELECT 1 FROM public.kaup AS k JOIN public.nutitelefon AS n USING (kaup_id)
            WHERE k.kauba_kood='UAP005' AND NOT n.on_veekindel AND NOT n.on_sormejalelugeja) THEN
        RAISE EXCEPTION 'Vormi- ja alusfunktsiooni märkeruutude sisulised tulemused erinevad';
    END IF;
END;
$salvestatud$;
ROLLBACK;
