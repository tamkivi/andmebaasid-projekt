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

-- Telefoni registreerimise, kahe tabeli muutmise ja versioonikontrolli katsetamine.
DO $telefon$
DECLARE
    v_e_meil varchar;
    v_oige_e_meil varchar;
    v_muutja integer;
    v_id integer;
    v_ver text;
    v_vana_ver text;
    v_tulemus varchar;
    v_kood varchar:='REG001';
    v_nimetus varchar:='Muudetud kontrolltelefon';
    v_hind numeric:=999;
    v_brand varchar:='APPLE';
    v_enne jsonb;
    v_telefon jsonb;
    v_algne jsonb;
    v_tabel text;
    v_kood_tekst text;
    v_seisund smallint;
    v_kitsendus text;
BEGIN
    IF (SELECT count(*) FROM pg_proc AS p INNER JOIN pg_namespace AS n ON n.oid=p.pronamespace
        INNER JOIN pg_language AS l ON l.oid=p.prolang
        WHERE n.nspname='public' AND p.proname IN ('f_registreeri_nutitelefon','f_muuda_kaup')
          AND p.prosqlbody IS NOT NULL AND l.lanname='sql' AND p.provolatile='v'
          AND p.prosecdef AND NOT p.proisstrict
          AND p.proconfig @> ARRAY['search_path=public, pg_temp']
          AND obj_description(p.oid,'pg_proc') IS NOT NULL)<>2 THEN
        RAISE EXCEPTION 'Telefoni funktsioonide omadused ei vasta nõuetele';
    END IF;
    BEGIN
        SELECT i.e_meil,t.tootaja_id INTO v_e_meil,v_muutja
        FROM tootaja AS t INNER JOIN isik AS i USING (isik_id)
        ORDER BY t.tootaja_id DESC FETCH FIRST 1 ROW ONLY;
        v_oige_e_meil:=v_e_meil;
        SELECT k.kaup_id,to_jsonb(k) INTO v_id,v_algne FROM kaup AS k WHERE kauba_kood='APL001';
        SELECT xmin::text INTO v_ver FROM v_kaubad_muutmiseks WHERE kauba_kood='APL001';
        v_vana_ver:=v_ver;
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='APL001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'UPD001' OR NOT EXISTS (
            SELECT 1 FROM kaup AS k INNER JOIN nutitelefon AS n USING (kaup_id)
            INNER JOIN kaamera AS e ON e.kaamera_id=n.eesmine_kaamera_id
            INNER JOIN kaamera AS t ON t.kaamera_id=n.tagumine_kaamera_id
            INNER JOIN sisemalu AS m USING (sisemalu_id)
            WHERE k.kaup_id=v_id AND k.kauba_kood='UPD001' AND k.nimetus=v_nimetus
                AND k.hind=v_hind AND k.pildi_aadress IS NULL AND k.viimase_muutja_id=v_muutja
                AND e.kood=12.0 AND t.kood=48.0 AND m.kood=256
                AND to_jsonb(k)->'reg_aeg'=v_algne->'reg_aeg'
                AND to_jsonb(k)->'registreerija_id'=v_algne->'registreerija_id'
                AND to_jsonb(k)->'kauba_seisundi_liik_id'=v_algne->'kauba_seisundi_liik_id'
                AND k.viimase_muutm_aeg=CURRENT_TIMESTAMP::timestamptz(0)) THEN
            RAISE EXCEPTION 'OP6 ei muutnud mõlemat rida või muutis säilitatavaid välju';
        END IF;
        SELECT to_jsonb(k) INTO v_enne FROM kaup AS k WHERE kaup_id=v_id;
        SELECT to_jsonb(n) INTO v_telefon FROM nutitelefon AS n WHERE kaup_id=v_id;
        v_nimetus:='Vananenud muudatus';
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id)
            OR v_telefon IS DISTINCT FROM (SELECT to_jsonb(n) FROM nutitelefon AS n WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'OP6 kirjutas vananenud xmin versiooni üle';
        END IF;
        SELECT xmin::text INTO v_ver FROM v_kaubad_muutmiseks WHERE kauba_kood='UPD001';
        IF v_ver=v_vana_ver THEN RAISE EXCEPTION 'Versioonikatse ei tekitanud uut tehinguversiooni'; END IF;
        v_nimetus:='Registreeritud kontrolltelefon';
        SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'REG001' OR NOT EXISTS (
            SELECT 1 FROM kaup AS k INNER JOIN nutitelefon AS n USING (kaup_id)
            INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
            INNER JOIN kaamera AS e ON e.kaamera_id=n.eesmine_kaamera_id
            INNER JOIN kaamera AS t ON t.kaamera_id=n.tagumine_kaamera_id
            WHERE k.kauba_kood='REG001' AND s.kood=1 AND k.registreerija_id=v_muutja
                AND k.viimase_muutja_id=v_muutja AND k.pildi_aadress IS NULL
                AND e.kood=12.0 AND t.kood=48.0) THEN
            RAISE EXCEPTION 'OP1 ei loonud õiget kauba ja telefoni paari';
        END IF;
        SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR (SELECT count(*) FROM kaup WHERE kauba_kood='REG001')<>1 THEN
            RAISE EXCEPTION 'OP1 ei lükanud korduvat koodi muutuseta tagasi';
        END IF;
        v_kood:='REG002';
        v_e_meil:='puuduv@example.invalid';
        SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR EXISTS (SELECT 1 FROM kaup WHERE kauba_kood=v_kood) THEN
            RAISE EXCEPTION 'OP1 registreeris kauba puuduva töötajaga';
        END IF;
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'OP6 muutis kauba puuduva töötajaga';
        END IF;
        v_e_meil:=v_oige_e_meil;
        FOR v_tabel,v_kood_tekst IN SELECT a.tabel,a.kood FROM (VALUES
            ('brand','APPLE'),('kaamera','12.0'),('kaamera','48.0'),
            ('sisemalu','256'),('diagonaal','6.1'),('protsessor','A16'),
            ('ekraani_resolutsioon','2556x1179')
        ) AS a(tabel,kood)
        LOOP
            EXECUTE format('UPDATE public.%I SET on_aktiivne=FALSE WHERE kood::text=$1',v_tabel) USING v_kood_tekst;
            SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
            IF v_tulemus IS NOT NULL OR EXISTS (SELECT 1 FROM kaup WHERE kauba_kood=v_kood) THEN
                RAISE EXCEPTION 'OP1 kasutas mitteaktiivset klassifikaatorit %',v_tabel;
            END IF;
            SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
            IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id)
                OR v_telefon IS DISTINCT FROM (SELECT to_jsonb(n) FROM nutitelefon AS n WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION 'OP6 kasutas mitteaktiivset klassifikaatorit %',v_tabel;
            END IF;
            EXECUTE format('UPDATE public.%I SET on_aktiivne=TRUE WHERE kood::text=$1',v_tabel) USING v_kood_tekst;
        END LOOP;
        UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=1;
        SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL THEN RAISE EXCEPTION 'OP1 kasutas mitteaktiivset algseisundit'; END IF;
        UPDATE kauba_seisundi_liik SET on_aktiivne=TRUE WHERE kood=1;
        v_brand:='PUUDUV';
        SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL THEN RAISE EXCEPTION 'OP1 kasutas olematut brändi'; END IF;
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL THEN RAISE EXCEPTION 'OP6 kasutas olematut brändi'; END IF;
        v_brand:='APPLE';
        FOR v_seisund IN SELECT unnest(ARRAY[2,4]::smallint[])
        LOOP
            UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id
                FROM kauba_seisundi_liik WHERE kood=v_seisund) WHERE kaup_id=v_id;
            SELECT xmin::text,to_jsonb(k) INTO v_ver,v_enne FROM kaup AS k WHERE kaup_id=v_id;
            SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
            IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
                RAISE EXCEPTION 'OP6 lubas keelatud seisundi %',v_seisund;
            END IF;
        END LOOP;
        UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id
            FROM kauba_seisundi_liik WHERE kood=3) WHERE kaup_id=v_id;
        SELECT xmin::text INTO v_ver FROM kaup WHERE kaup_id=v_id;
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS DISTINCT FROM 'UPD001' THEN RAISE EXCEPTION 'OP6 peab lubama seisundit 3'; END IF;
        SELECT xmin::text,to_jsonb(k) INTO v_ver,v_enne FROM kaup AS k WHERE kaup_id=v_id;
        SELECT to_jsonb(n) INTO v_telefon FROM nutitelefon AS n WHERE kaup_id=v_id;
        v_hind:=0;
        BEGIN
            SELECT f_registreeri_nutitelefon(
            p_kauba_kood:=v_kood,
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
            RAISE EXCEPTION 'OP1 võttis vastu keelatud hinna';
        EXCEPTION WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_kitsendus=CONSTRAINT_NAME;
            IF v_kitsendus<>'ck_kaup_hind_positiivne' THEN RAISE; END IF;
        END;
        BEGIN
            SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
            RAISE EXCEPTION 'OP6 võttis vastu keelatud hinna';
        EXCEPTION WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_kitsendus=CONSTRAINT_NAME;
            IF v_kitsendus<>'ck_kaup_hind_positiivne' THEN RAISE; END IF;
        END;
        IF EXISTS (SELECT 1 FROM kaup WHERE kauba_kood='REG002')
            OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id)
            OR v_telefon IS DISTINCT FROM (SELECT to_jsonb(n) FROM nutitelefon AS n WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'Kitsenduse viga jättis osalise muudatuse';
        END IF;
        v_hind:=999;
        DELETE FROM nutitelefon WHERE kaup_id=v_id;
        SELECT f_muuda_kaup(
            p_ver:=v_ver,
            p_kauba_kood_vana:='UPD001',
            p_kauba_kood_uus:='UPD001',
            p_nimetus:=v_nimetus,
            p_hind:=v_hind::numeric,
            p_kirjeldus:='Funktsiooniga hallatava telefoni sisuline kontrollkirjeldus.',
            p_pildi_aadress:=NULL::varchar,
            p_e_meil:=v_e_meil,
            p_brandi_kood:=v_brand,
            p_on_veekindel:=TRUE,
            p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,
            p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,
            p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',
            p_ekraani_resolutsiooni_kood:='2556x1179') INTO v_tulemus;
        IF v_tulemus IS NOT NULL OR v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup AS k WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'OP6 muutis telefoni kirjeta kaupa';
        END IF;
        RAISE EXCEPTION USING ERRCODE='ZT001',MESSAGE='Kontrollmuudatuste eemaldamine';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$telefon$;
