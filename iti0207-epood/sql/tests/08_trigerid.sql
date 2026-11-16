-- Lubatud ja keelatud muudatused; kõik andme- ja seadistusmuudatused võetakse tagasi.
START TRANSACTION;
\ir 08_testiabi.sql

DO $kataloog$
DECLARE v record;
BEGIN
    IF (SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal
        AND tgrelid IN ('kaup'::regclass,'isik'::regclass,'nutitelefon'::regclass,
            'kauba_variant'::regclass,'kauba_kategooria_omamine'::regclass))<>20 THEN
        RAISE EXCEPTION 'Oodati 20 trigerit';
    END IF;
    IF EXISTS(SELECT 1 FROM (VALUES
            ('trig_kaup_algseisund','kaup',7),
            ('trig_kaup_seisundimuudatus','kaup',19),
            ('trig_kaup_seisundimuudatus_kategooria','kaup',19),
            ('trig_kaup_kustutamine','kaup',11),
            ('trig_kaup_andmete_muutmine','kaup',19),
            ('trig_nutitelefon_kauba_muudetavus','nutitelefon',15),
            ('trig_nutitelefon_muutmine','nutitelefon',19),
            ('trig_kauba_kategooria_omamine_kauba_muudetavus','kauba_kategooria_omamine',15),
            ('trig_kauba_kategooria_omamine_muutmine','kauba_kategooria_omamine',19),
            ('trig_kauba_variant_kauba_muudetavus','kauba_variant',15),
            ('trig_kauba_variant_muutmine','kauba_variant',19),
            ('trig_kaup_reg_andmed','kaup',19),
            ('trig_kaup_viimase_muutm_aeg','kaup',19),
            ('trig_isik_viimase_muutm_aeg','isik',19),
            ('trig_kaup_aktiivne_algseisund','kaup',7),
            ('trig_kaup_aktiivne_uus_seisund','kaup',19),
            ('trig_kaup_truncate','kaup',34),
            ('trig_nutitelefon_truncate','nutitelefon',34),
            ('trig_kauba_kategooria_omamine_truncate','kauba_kategooria_omamine',34),
            ('trig_kauba_variant_truncate','kauba_variant',34)
        ) AS e(nimi,tabel,tyyp)
        LEFT JOIN pg_trigger t ON t.tgname=e.nimi AND t.tgrelid=to_regclass('public.'||e.tabel)
        WHERE t.oid IS NULL OR t.tgtype<>e.tyyp) THEN
        RAISE EXCEPTION 'Triger on seotud vale tabeli või sündmusega';
    END IF;
    FOR v IN SELECT t.*,obj_description(t.oid,'pg_trigger') AS selgitus
        FROM pg_trigger AS t WHERE NOT t.tgisinternal
    LOOP
        IF v.tgenabled<>'O' OR (v.tgtype & 2)=0 OR v.selgitus IS NULL
            OR ((v.tgtype & 32)=0 AND (v.tgtype & 1)=0)
            OR ((v.tgtype & 32)<>0 AND (v.tgtype & 1)<>0) THEN
            RAISE EXCEPTION 'Vale trigeri määratlus: %',v.tgname;
        END IF;
    END LOOP;
    IF (SELECT count(*) FROM pg_proc AS p INNER JOIN pg_language AS l ON l.oid=p.prolang
        WHERE p.pronamespace='public'::regnamespace AND p.prorettype='trigger'::regtype
            AND l.lanname='plpgsql' AND p.prosecdef AND p.provolatile='v'
            AND p.proconfig @> ARRAY['search_path=public, pg_temp']
            AND obj_description(p.oid,'pg_proc') IS NOT NULL)<>10 THEN
        RAISE EXCEPTION 'Trigerifunktsioonide keel, õigused, otsingutee või kommentaar puudub';
    END IF;
END;
$kataloog$;

DO $elutsykkel$
DECLARE
    v_id integer; v_vana integer; v_uus integer; v_lause text;
    v_enne jsonb; v_lubatud integer:=0; v_keelatud integer:=0;
BEGIN
    SELECT kaup_id INTO STRICT v_id FROM kaup WHERE kauba_kood='APL001';
    -- Uus kaup: ainult kood 1. Surrogaatvõtmeid ei eeldata.
    FOR v_uus IN 1..4 LOOP
        v_lause:=format($l$INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,
            kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id)
            SELECT 'TRG001','Uue kauba kontroll',100,'Uue kauba sisuline kontrollkirjeldus',
                s.kauba_seisundi_liik_id,k.brand_id,k.registreerija_id,k.viimase_muutja_id
            FROM kaup AS k CROSS JOIN kauba_seisundi_liik AS s
            WHERE k.kaup_id=%s AND s.kood=%s$l$,v_id,v_uus);
        IF v_uus=1 THEN
            BEGIN
                EXECUTE v_lause;
                IF NOT EXISTS(SELECT 1 FROM kaup WHERE kauba_kood='TRG001'
                    AND reg_aeg=CURRENT_TIMESTAMP::timestamptz(0)
                    AND viimase_muutm_aeg=reg_aeg) THEN
                    RAISE EXCEPTION 'Lisamise vaikeväärtused ei säilinud';
                END IF;
                RAISE SQLSTATE 'ZT001';
            EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL; END;
        ELSE
            PERFORM pg_temp.u9_viga(v_lause,'kaup_algseisund','Uue kauba seisund peab olema ootel.');
        END IF;
    END LOOP;
    -- 4 x 4: viis üleminekut ja neli sama seisundi tagasikirjutamist on lubatud.
    FOR v_vana IN 1..4 LOOP
        FOR v_uus IN 1..4 LOOP
            PERFORM pg_temp.u9_seisund(v_id,v_vana);
            SELECT to_jsonb(k) INTO v_enne FROM kaup k WHERE kaup_id=v_id;
            v_lause:=format('UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=%s) WHERE kaup_id=%s',v_uus,v_id);
            IF v_vana=v_uus OR (v_vana,v_uus) IN ((1,2),(3,2),(2,3),(2,4),(3,4)) THEN
                EXECUTE v_lause; v_lubatud:=v_lubatud+1;
                IF NOT EXISTS(SELECT 1 FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id)
                    WHERE k.kaup_id=v_id AND s.kood=v_uus) THEN RAISE EXCEPTION 'Vale sihtseisund'; END IF;
            ELSE
                PERFORM pg_temp.u9_viga(v_lause,'kaup_seisundimuudatus','Kauba seisundimuudatus ei ole lubatud.');
                v_keelatud:=v_keelatud+1;
                IF v_enne IS DISTINCT FROM (SELECT to_jsonb(k) FROM kaup k WHERE kaup_id=v_id) THEN
                    RAISE EXCEPTION 'Keelatud üleminek muutis andmeid';
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    IF v_lubatud<>9 OR v_keelatud<>7 THEN RAISE EXCEPTION 'Seisundimaatriks jäi puudulikuks'; END IF;
    RAISE NOTICE 'Seisundimaatriks: 9 lubatud, 7 keelatud';
    -- Juhendi kohustuslik katse, olemas on kaup igas neljas seisundis.
    PERFORM pg_temp.u9_seisund(v_id,1);
    IF (SELECT count(DISTINCT s.kood) FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id))<>4 THEN
        RAISE EXCEPTION 'Sama seisundi katse vajab kõiki nelja seisundit';
    END IF;
    UPDATE kaup SET kauba_seisundi_liik_id=kauba_seisundi_liik_id;
    PERFORM pg_temp.u9_seisund(v_id,1);
    DELETE FROM kauba_kategooria_omamine WHERE kaup_id=v_id;
    FOREACH v_vana IN ARRAY ARRAY[1,3] LOOP
        PERFORM pg_temp.u9_seisund(v_id,v_vana);
        PERFORM pg_temp.u9_viga(format('UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kaup_id=%s',v_id),
            'kaup_aktiveerimine','Kauba aktiveerimiseks peab sellel olema vähemalt üks kategooria.');
    END LOOP;
    PERFORM pg_temp.u9_seisund(v_id,1);
    INSERT INTO kauba_kategooria_omamine SELECT v_id,kauba_kategooria_id FROM kauba_kategooria WHERE kood='KLASSIKALINE';
    UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=2;
    PERFORM pg_temp.u9_viga(format('UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kaup_id=%s',v_id),
        'kaup_aktiivne_seisund','Kauba uus seisund peab olema aktiivne klassifikaatoriväärtus.');
    UPDATE kauba_seisundi_liik SET on_aktiivne=TRUE WHERE kood=2;
    FOR v_vana IN 2..4 LOOP
        PERFORM pg_temp.u9_seisund(v_id,v_vana);
        PERFORM pg_temp.u9_viga(format('DELETE FROM kaup WHERE kaup_id=%s',v_id),'kaup_kustutamine','Kustutada saab ainult ootel kaupa.');
        IF NOT EXISTS(SELECT 1 FROM nutitelefon WHERE kaup_id=v_id)
            OR NOT EXISTS(SELECT 1 FROM kauba_variant WHERE kaup_id=v_id)
            OR NOT EXISTS(SELECT 1 FROM kauba_kategooria_omamine WHERE kaup_id=v_id) THEN
            RAISE EXCEPTION 'Keelatud kustutamine eemaldas sõltuva rea';
        END IF;
    END LOOP;
    PERFORM pg_temp.u9_seisund(v_id,1);
    DELETE FROM kaup WHERE kaup_id=v_id;
    IF EXISTS(SELECT 1 FROM kaup WHERE kaup_id=v_id)
        OR EXISTS(SELECT 1 FROM nutitelefon WHERE kaup_id=v_id)
        OR EXISTS(SELECT 1 FROM kauba_variant WHERE kaup_id=v_id)
        OR EXISTS(SELECT 1 FROM kauba_kategooria_omamine WHERE kaup_id=v_id) THEN
        RAISE EXCEPTION 'Lubatud kustutamine ei eemaldanud kõiki ridu';
    END IF;
END;
$elutsykkel$;
-- Eelmine plokk kustutas ühe näidiskauba; taastame algseisu järgmise katse jaoks.
ROLLBACK;
START TRANSACTION;
\ir 08_testiabi.sql

DO $muutmine$
DECLARE
    v_id integer; v_seisund integer; v_osa text; v_lause text; v_tabel text;
    v_telefon jsonb; v_enne jsonb; v_reg timestamptz; v_isik integer; v_teine integer;
BEGIN
    SELECT kaup_id INTO STRICT v_id FROM kaup WHERE kauba_kood='APL001';
    SELECT to_jsonb(n) INTO v_telefon FROM nutitelefon n WHERE kaup_id=v_id;
    FOREACH v_seisund IN ARRAY ARRAY[1,2,3,4] LOOP
        PERFORM pg_temp.u9_seisund(v_id,v_seisund);
        -- Muutmata põhiandmed ja muutmata lisaandmed on kõigis seisundites lubatud.
        UPDATE kaup SET kauba_kood=kauba_kood,nimetus=nimetus,hind=hind,
            kirjeldus=kirjeldus,pildi_aadress=pildi_aadress,brand_id=brand_id WHERE kaup_id=v_id;
        UPDATE nutitelefon SET on_veekindel=on_veekindel WHERE kaup_id=v_id;
        UPDATE kauba_variant SET varv_id=varv_id WHERE kaup_id=v_id;
        UPDATE kauba_kategooria_omamine SET kauba_kategooria_id=kauba_kategooria_id WHERE kaup_id=v_id;
        FOREACH v_osa IN ARRAY ARRAY['kauba_kood=''TRG002''','nimetus=''Muudetud trigeri kontrollkaup''',
            'hind=hind+1','kirjeldus=kirjeldus || '' Muutus.''',
            'pildi_aadress=''https://example.invalid/muutus.jpg''',
            'brand_id=(SELECT brand_id FROM brand WHERE kood=''SAMSUNG'')'] LOOP
            v_lause:=format('UPDATE kaup SET %s WHERE kaup_id=%s',v_osa,v_id);
            IF v_seisund IN (1,3) THEN
                BEGIN EXECUTE v_lause; RAISE SQLSTATE 'ZT001';
                EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL; END;
            ELSE
                PERFORM pg_temp.u9_viga(v_lause,'kaup_muudetavus',NULL,split_part(v_osa,'=',1));
            END IF;
        END LOOP;
        -- Igas lisatabelis: INSERT, tegelik UPDATE ja DELETE.
        FOR v_tabel,v_lause IN SELECT * FROM (VALUES
            ('nutitelefon',format('INSERT INTO nutitelefon SELECT * FROM jsonb_populate_record(NULL::nutitelefon,%L::jsonb) ON CONFLICT DO NOTHING',v_telefon)),
            ('nutitelefon',format('UPDATE nutitelefon SET on_veekindel=NOT on_veekindel WHERE kaup_id=%s',v_id)),
            ('nutitelefon',format('DELETE FROM nutitelefon WHERE kaup_id=%s',v_id)),
            ('kauba_variant',format('INSERT INTO kauba_variant(kaup_id,varv_id) SELECT %s,varv_id FROM varv WHERE kood=''WHITE''',v_id)),
            ('kauba_variant',format('UPDATE kauba_variant SET varv_id=(SELECT varv_id FROM varv WHERE kood=''WHITE'') WHERE kaup_id=%s',v_id)),
            ('kauba_variant',format('DELETE FROM kauba_variant WHERE kaup_id=%s',v_id)),
            ('kauba_kategooria_omamine',format('INSERT INTO kauba_kategooria_omamine SELECT %s,kauba_kategooria_id FROM kauba_kategooria WHERE kood=''MEESTELEFONID''',v_id)),
            ('kauba_kategooria_omamine',format('UPDATE kauba_kategooria_omamine SET kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood=''MEESTELEFONID'') WHERE kaup_id=%s AND kauba_kategooria_id=(SELECT kauba_kategooria_id FROM kauba_kategooria WHERE kood=''KLASSIKALINE'')',v_id)),
            ('kauba_kategooria_omamine',format('DELETE FROM kauba_kategooria_omamine WHERE kaup_id=%s',v_id))
        ) AS a(tabel,lause) LOOP
            IF v_seisund IN (1,3) THEN
                BEGIN
                    IF v_tabel='nutitelefon' AND v_lause LIKE 'INSERT%' THEN
                        DELETE FROM nutitelefon WHERE kaup_id=v_id;
                    END IF;
                    EXECUTE v_lause;
                    RAISE SQLSTATE 'ZT001';
                EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL; END;
            ELSE
                PERFORM pg_temp.u9_viga(v_lause,v_tabel || '_kauba_muudetavus');
            END IF;
        END LOOP;
    END LOOP;
    PERFORM pg_temp.u9_seisund(v_id,1);
    INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,kauba_seisundi_liik_id,
        brand_id,registreerija_id,viimase_muutja_id)
    SELECT 'TRG005','Lisaandmete liigutamise kontroll',100,'Teise muudetava kauba kontrollkirjeldus',
        kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id FROM kaup WHERE kaup_id=v_id;
    SELECT kaup_id INTO v_teine FROM kaup WHERE kauba_kood='TRG005';
    PERFORM pg_temp.u9_seisund(v_teine,3);
    FOREACH v_tabel IN ARRAY ARRAY['nutitelefon','kauba_variant','kauba_kategooria_omamine'] LOOP
        BEGIN
            EXECUTE format('UPDATE %I SET kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood=''TRG005'') WHERE kaup_id=%s',v_tabel,v_id);
            RAISE SQLSTATE 'ZT001';
        EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL; END;
    END LOOP;
    -- Lisaandmete teisaldamisel kontrollitakse nii vana kui uut kaupa.
    PERFORM pg_temp.u9_seisund(v_id,1);
    FOREACH v_tabel IN ARRAY ARRAY['nutitelefon','kauba_variant','kauba_kategooria_omamine'] LOOP
        PERFORM pg_temp.u9_viga(format('UPDATE %I SET kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood=''APL002'') WHERE kaup_id=%s',v_tabel,v_id),v_tabel || '_kauba_muudetavus');
    END LOOP;
    PERFORM pg_temp.u9_seisund(v_id,2);
    FOREACH v_tabel IN ARRAY ARRAY['nutitelefon','kauba_variant','kauba_kategooria_omamine'] LOOP
        PERFORM pg_temp.u9_viga(format('UPDATE %I SET kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood=''APL003'') WHERE kaup_id=%s',v_tabel,v_id),v_tabel || '_kauba_muudetavus');
    END LOOP;
    -- Tegelik muutus puudub, kui suletud klassifikaator kirjutatakse samana tagasi.
    UPDATE kauba_seisundi_liik SET on_aktiivne=FALSE WHERE kood=2;
    UPDATE kaup SET kauba_seisundi_liik_id=kauba_seisundi_liik_id WHERE kaup_id=v_id;
    UPDATE kauba_seisundi_liik SET on_aktiivne=TRUE WHERE kood=2;
    PERFORM pg_temp.u9_seisund(v_id,3);
    UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2),hind=hind+1 WHERE kaup_id=v_id;
    PERFORM pg_temp.u9_viga(format('UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=3),hind=hind+1 WHERE kaup_id=%s',v_id),'kaup_muudetavus');
    SELECT to_jsonb(k),reg_aeg INTO v_enne,v_reg FROM kaup k WHERE kaup_id=v_id;
    PERFORM pg_temp.u9_viga(format('UPDATE kaup SET reg_aeg=reg_aeg-interval ''1 day'' WHERE kaup_id=%s',v_id),'kaup_reg_andmed','Kauba registreerijat ja registreerimise aega ei saa muuta.');
    PERFORM pg_temp.u9_viga(format('UPDATE kaup SET registreerija_id=(SELECT max(tootaja_id) FROM tootaja) WHERE kaup_id=%s',v_id),'kaup_reg_andmed');
    UPDATE kaup SET reg_aeg=reg_aeg,registreerija_id=registreerija_id,
        viimase_muutm_aeg=TIMESTAMPTZ '2020-01-01' WHERE kaup_id=v_id;
    IF NOT EXISTS(SELECT 1 FROM kaup WHERE kaup_id=v_id AND reg_aeg=v_reg
        AND viimase_muutm_aeg=CURRENT_TIMESTAMP::timestamptz(0)) THEN RAISE EXCEPTION 'Kauba aja triger ei toimi'; END IF;
    SELECT min(isik_id) INTO v_isik FROM isik;
    -- Muutmata isikurida säilitab varasema aja; tegelik muudatus saab tehingu aja.
    ALTER TABLE isik DISABLE TRIGGER trig_isik_viimase_muutm_aeg;
    UPDATE isik SET reg_aeg=TIMESTAMPTZ '2019-01-01',
        viimase_muutm_aeg=TIMESTAMPTZ '2020-01-01' WHERE isik_id=v_isik;
    ALTER TABLE isik ENABLE TRIGGER trig_isik_viimase_muutm_aeg;
    UPDATE isik SET eesnimi=eesnimi WHERE isik_id=v_isik;
    IF NOT EXISTS(SELECT 1 FROM isik WHERE isik_id=v_isik
        AND viimase_muutm_aeg=TIMESTAMPTZ '2020-01-01') THEN
        RAISE EXCEPTION 'Muutmata isiku ajatempel muutus';
    END IF;
    UPDATE isik SET eesnimi=eesnimi || 'x' WHERE isik_id=v_isik;
    IF NOT EXISTS(SELECT 1 FROM isik WHERE isik_id=v_isik
        AND viimase_muutm_aeg=CURRENT_TIMESTAMP::timestamptz(0)) THEN RAISE EXCEPTION 'Isiku aja triger ei toimi'; END IF;
    FOREACH v_tabel IN ARRAY ARRAY['kaup','nutitelefon','kauba_variant','kauba_kategooria_omamine'] LOOP
        PERFORM pg_temp.u9_viga(format('TRUNCATE %I CASCADE',v_tabel),v_tabel || '_truncate',
            'Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.');
    END LOOP;
    RAISE NOTICE 'Muudetavuse, registreerimisandmete, aja ja TRUNCATE katsed läbitud';
END;
$muutmine$;
ROLLBACK;

-- Koodid ja surrogaatvõtmed peavad jääma eri mõisteteks ka teise laadimisjärjekorra korral.
START TRANSACTION;
\ir 08_testiabi.sql
UPDATE kauba_seisundi_liik SET kood=kood+10 WHERE kood IN (1,2);
UPDATE kauba_seisundi_liik SET kood=CASE kood WHEN 11 THEN 2 WHEN 12 THEN 1 END WHERE kood IN (11,12);
DO $koodid$
DECLARE v_id integer;
BEGIN
    INSERT INTO kaup (kauba_kood,nimetus,hind,kirjeldus,kauba_seisundi_liik_id,
        brand_id,registreerija_id,viimase_muutja_id)
    SELECT 'TRG006','Klassifikaatori koodi kontroll',100,'Koodide ja tunnuste eristamise kontroll',
        s.kauba_seisundi_liik_id,k.brand_id,k.registreerija_id,k.viimase_muutja_id
    FROM kaup k CROSS JOIN kauba_seisundi_liik s WHERE k.kauba_kood='APL001' AND s.kood=1
    RETURNING kaup_id INTO v_id;
    INSERT INTO kauba_kategooria_omamine SELECT v_id,kauba_kategooria_id FROM kauba_kategooria WHERE kood='KLASSIKALINE';
    UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2) WHERE kaup_id=v_id;
    PERFORM pg_temp.u9_viga(format('DELETE FROM kaup WHERE kaup_id=%s',v_id),'kaup_kustutamine');
    RAISE NOTICE 'Seisundeid kontrolliti koodide, mitte surrogaatvõtmete järgi';
END;
$koodid$;
ROLLBACK;
