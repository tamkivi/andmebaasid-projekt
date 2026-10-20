-- Klassifikaatorite koodide, kirjelduste ja kasutatavuse kontroll.
DO $kontroll$
DECLARE
    v_tabel text;
    v_koodid text[];
    v_leitud text[];
BEGIN
    FOR v_tabel,v_koodid IN SELECT a.tabel,a.koodid FROM (VALUES
        ('isiku_seisundi_liik',ARRAY['EL','SU']),
        ('tootaja_seisundi_liik',ARRAY['KA','TO','PU','PE','LO']),
        ('kliendi_seisundi_liik',ARRAY['AK','PE','LO']),
        ('tootaja_roll',ARRAY['JUHATAJA','KAUBAHALDUR','KLASSIFIKAATORIHALDUR','KLIENDIHALDUR','RAAMATUPIDAJA','PERSONALIHALDUR']),
        ('kauba_seisundi_liik',ARRAY['1','2','3','4']),
        ('brand',ARRAY['APPLE','SAMSUNG','GOOGLE']),
        ('diagonaal',ARRAY['6.1','6.7']),
        ('ekraani_resolutsioon',ARRAY['2556x1179','2340x1080']),
        ('kaamera',ARRAY['12.0','48.0','50.0']),
        ('protsessor',ARRAY['A16','EXYNOS2400','TENSORG3']),
        ('sisemalu',ARRAY['128','256']),
        ('varv',ARRAY['BLACK','WHITE','BLUE']),
        ('kauba_kategooria_tyyp',ARRAY['VALIMUS','SIHTGRUPP']),
        ('kauba_kategooria',ARRAY['NAISTELEFONID','MEESTELEFONID','KLASSIKALINE'])
    ) AS a(tabel,koodid)
    LOOP
        EXECUTE format('SELECT array_agg(kood::text) FROM public.%I',v_tabel) INTO v_leitud;
        IF v_leitud IS NULL OR NOT v_leitud @> v_koodid THEN
            RAISE EXCEPTION 'Klassifikaatori % kohustuslikud koodid puuduvad',v_tabel;
        END IF;
        IF v_tabel='kauba_seisundi_liik' AND cardinality(v_leitud)<>4 THEN
            RAISE EXCEPTION 'Kauba seisundeid peab olema täpselt neli';
        END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM tootaja_roll WHERE kirjeldus IS NULL OR kirjeldus=nimetus::text)
        OR NOT EXISTS (SELECT 1 FROM varv WHERE kood='BLUE' AND NOT on_aktiivne)
        OR EXISTS (SELECT 1 FROM kauba_kategooria AS k
                   INNER JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id)
                   WHERE (k.kood IN ('NAISTELEFONID','MEESTELEFONID') AND t.kood<>'SIHTGRUPP')
                      OR (k.kood='KLASSIKALINE' AND t.kood<>'VALIMUS')) THEN
        RAISE EXCEPTION 'Kirjeldus, kasutatavus või kategooria tüüp ei vasta määratlusele';
    END IF;
END;
$kontroll$;
