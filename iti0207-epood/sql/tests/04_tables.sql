-- Kontseptuaalse andmemudeli väärtusreeglite piirjuhtude kontroll.
-- Kontrollread eemaldatakse sama anonüümse ploki alatehinguga.
DO $kontroll$
DECLARE
    juht jsonb;
    tegelik_olek text;
    tegelik_kitsendus text;
BEGIN
    BEGIN
        INSERT INTO public.riik (kood,nimetus) VALUES ('EST', 'Eesti');
        INSERT INTO public.isiku_seisundi_liik (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.tootaja_seisundi_liik (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.kliendi_seisundi_liik (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.tootaja_roll (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.kauba_seisundi_liik (kood,nimetus) VALUES (1, 'Ootel');
        INSERT INTO public.brand (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.diagonaal (kood,nimetus) VALUES (6.1, 'Kuus koma üks');
        INSERT INTO public.ekraani_resolutsioon (kood,nimetus,horisontaalne,vertikaalne) VALUES ('FHD','Täis-HD',1080,1920);
        INSERT INTO public.kaamera (kood,nimetus) VALUES (12.0, 'Kaksteist megapikslit');
        INSERT INTO public.protsessor (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.sisemalu (kood,nimetus) VALUES (128, 'Sada kakskümmend kaheksa');
        INSERT INTO public.varv (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.kauba_kategooria_tyyp (kood,nimetus) VALUES ('TEST', 'Kontrollväärtus');
        INSERT INTO public.kauba_kategooria (kood,nimetus,kauba_kategooria_tyyp_id) SELECT 'TEST','Kontrollkategooria',kauba_kategooria_tyyp_id FROM public.kauba_kategooria_tyyp WHERE kood='TEST';
        INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,reg_aeg,viimase_muutm_aeg,eesnimi) SELECT '12345678901','fixture@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,DATE '2000-01-01',TIMESTAMPTZ '2026-10-01 12:00:00+03',TIMESTAMPTZ '2026-10-01 12:00:00+03','Mari' FROM public.riik r CROSS JOIN public.isiku_seisundi_liik s;
        INSERT INTO public.kasutajakonto (isik_id,parool) SELECT isik_id,repeat('x',60) FROM public.isik WHERE e_meil='fixture@example.invalid';
        INSERT INTO public.tootaja (isik_id,tootaja_seisundi_liik_id) SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM public.isik i CROSS JOIN public.tootaja_seisundi_liik s;
        INSERT INTO public.tootaja_rolli_omamine (tootaja_id,tootaja_roll_id,alguse_aeg) SELECT t.tootaja_id,r.tootaja_roll_id,TIMESTAMPTZ '2026-10-01 12:00:00+03' FROM public.tootaja t CROSS JOIN public.tootaja_roll r;
        INSERT INTO public.kaup (kauba_kood,nimetus,kauba_seisundi_liik_id,brand_id,registreerija_id,viimase_muutja_id,hind,kirjeldus,reg_aeg,viimase_muutm_aeg) SELECT 'ABC123','Kontrolltelefon',s.kauba_seisundi_liik_id,b.brand_id,t.tootaja_id,t.tootaja_id,1000,'Telefoni kirjeldus',TIMESTAMPTZ '2026-10-01 12:00:00+03',TIMESTAMPTZ '2026-10-01 12:00:00+03' FROM public.kauba_seisundi_liik s CROSS JOIN public.brand b CROSS JOIN public.tootaja t;
        FOR juht IN SELECT value FROM jsonb_array_elements($sobivad$[
  "UPDATE public.riik SET nimetus='Õige nimetus'",
  "UPDATE public.isiku_seisundi_liik SET nimetus='Õige nimetus'",
  "UPDATE public.isiku_seisundi_liik SET kood='A'",
  "UPDATE public.tootaja_seisundi_liik SET nimetus='Õige nimetus'",
  "UPDATE public.tootaja_seisundi_liik SET kood='A'",
  "UPDATE public.kliendi_seisundi_liik SET nimetus='Õige nimetus'",
  "UPDATE public.kliendi_seisundi_liik SET kood='A'",
  "UPDATE public.tootaja_roll SET nimetus='Õige nimetus'",
  "UPDATE public.tootaja_roll SET kood='A'",
  "UPDATE public.kauba_seisundi_liik SET nimetus='Õige nimetus'",
  "UPDATE public.brand SET nimetus='Õige nimetus'",
  "UPDATE public.brand SET kood='A'",
  "UPDATE public.diagonaal SET nimetus='Õige nimetus'",
  "UPDATE public.ekraani_resolutsioon SET nimetus='Õige nimetus'",
  "UPDATE public.ekraani_resolutsioon SET kood='A'",
  "UPDATE public.kaamera SET nimetus='Õige nimetus'",
  "UPDATE public.protsessor SET nimetus='Õige nimetus'",
  "UPDATE public.protsessor SET kood='A'",
  "UPDATE public.sisemalu SET nimetus='Õige nimetus'",
  "UPDATE public.varv SET nimetus='Õige nimetus'",
  "UPDATE public.varv SET kood='A'",
  "UPDATE public.kauba_kategooria_tyyp SET nimetus='Õige nimetus'",
  "UPDATE public.kauba_kategooria_tyyp SET kood='A'",
  "UPDATE public.kauba_kategooria SET nimetus='Õige nimetus'",
  "UPDATE public.kauba_kategooria SET kood='A'",
  "UPDATE public.riik SET kood='USA'",
  "UPDATE public.diagonaal SET kood=1",
  "UPDATE public.kaamera SET kood=1",
  "UPDATE public.sisemalu SET kood=1",
  "UPDATE public.ekraani_resolutsioon SET horisontaalne=1",
  "UPDATE public.ekraani_resolutsioon SET vertikaalne=1",
  "UPDATE public.isik SET isikukood=E'Õun +/\\\\=-123'",
  "UPDATE public.isik SET eesnimi=NULL,perenimi='李'",
  "UPDATE public.isik SET synni_kp=DATE '1900-01-01'",
  "UPDATE public.isik SET synni_kp=DATE '2100-12-31',reg_aeg=TIMESTAMPTZ '2100-12-31 23:59:59+02',viimase_muutm_aeg=TIMESTAMPTZ '2100-12-31 23:59:59+02'",
  "UPDATE public.isik SET elukoht=NULL,perenimi=NULL,eesnimi='Mari'",
  "UPDATE public.isik SET reg_aeg=TIMESTAMPTZ '2010-01-01 00:00:00+02',viimase_muutm_aeg=TIMESTAMPTZ '2010-01-01 00:00:00+02',synni_kp=DATE '2010-01-01'",
  "UPDATE public.tootaja_roll SET kirjeldus=NULL",
  "UPDATE public.tootaja_rolli_omamine SET lopu_aeg='infinity'::timestamptz",
  "UPDATE public.tootaja_rolli_omamine SET alguse_aeg=TIMESTAMPTZ '2010-01-01 00:00:00+02',lopu_aeg=TIMESTAMPTZ '2100-12-31 23:59:59+02'",
  "UPDATE public.kaup SET kauba_kood='ABC123'",
  "UPDATE public.kaup SET kauba_kood='ABC'||repeat('1',47)",
  "UPDATE public.kaup SET nimetus='Õige'",
  "UPDATE public.kaup SET hind=0.01",
  "UPDATE public.kaup SET hind=1000,pildi_aadress=NULL",
  "UPDATE public.kaup SET hind=1000.01,pildi_aadress='foto.png'",
  "UPDATE public.kaup SET hind=9999999999.99,pildi_aadress='foto.jpg'",
  "UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2010-01-01 00:00:00+02',viimase_muutm_aeg=TIMESTAMPTZ '2010-01-01 00:00:00+02'",
  "UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2100-12-31 23:59:59+02',viimase_muutm_aeg=TIMESTAMPTZ '2100-12-31 23:59:59+02'"
]$sobivad$::jsonb)
        LOOP
            BEGIN
                EXECUTE juht #>> '{}';
                RAISE EXCEPTION USING ERRCODE = 'ZP001', MESSAGE = 'Sobiva piirjuhu tagasipööramine', DETAIL = 'Kontrollrida ei jää andmebaasi.', HINT = 'See erand püütakse samas plokis.';
            EXCEPTION WHEN SQLSTATE 'ZP001' THEN NULL;
            END;
        END LOOP;
        FOR juht IN SELECT value FROM jsonb_array_elements($vigased$[
  {
    "sql": "UPDATE public.riik SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.isiku_seisundi_liik SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.isiku_seisundi_liik SET kood='   '",
    "state": "23514",
    "constraint": "ck_isiku_seisundi_liik_kood_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_seisundi_liik SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_seisundi_liik SET kood='   '",
    "state": "23514",
    "constraint": "ck_tootaja_seisundi_liik_kood_sisu"
  },
  {
    "sql": "UPDATE public.kliendi_seisundi_liik SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.kliendi_seisundi_liik SET kood='   '",
    "state": "23514",
    "constraint": "ck_kliendi_seisundi_liik_kood_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_roll SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_roll SET kood='   '",
    "state": "23514",
    "constraint": "ck_tootaja_roll_kood_sisu"
  },
  {
    "sql": "UPDATE public.kauba_seisundi_liik SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.brand SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.brand SET kood='   '",
    "state": "23514",
    "constraint": "ck_brand_kood_sisu"
  },
  {
    "sql": "UPDATE public.diagonaal SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.ekraani_resolutsioon SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.ekraani_resolutsioon SET kood='   '",
    "state": "23514",
    "constraint": "ck_ekraani_resolutsioon_kood_sisu"
  },
  {
    "sql": "UPDATE public.kaamera SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.protsessor SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.protsessor SET kood='   '",
    "state": "23514",
    "constraint": "ck_protsessor_kood_sisu"
  },
  {
    "sql": "UPDATE public.sisemalu SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.varv SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.varv SET kood='   '",
    "state": "23514",
    "constraint": "ck_varv_kood_sisu"
  },
  {
    "sql": "UPDATE public.kauba_kategooria_tyyp SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.kauba_kategooria_tyyp SET kood='   '",
    "state": "23514",
    "constraint": "ck_kauba_kategooria_tyyp_kood_sisu"
  },
  {
    "sql": "UPDATE public.kauba_kategooria SET nimetus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_klassifikaatori_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.kauba_kategooria SET kood='   '",
    "state": "23514",
    "constraint": "ck_kauba_kategooria_kood_sisu"
  },
  {
    "sql": "UPDATE public.riik SET kood='est'",
    "state": "23514",
    "constraint": "ck_riik_kood_kuju"
  },
  {
    "sql": "UPDATE public.diagonaal SET kood=0",
    "state": "23514",
    "constraint": "ck_diagonaal_kood_positiivne"
  },
  {
    "sql": "UPDATE public.diagonaal SET kood='NaN'::numeric",
    "state": "23514",
    "constraint": "ck_diagonaal_kood_positiivne"
  },
  {
    "sql": "UPDATE public.kaamera SET kood=0",
    "state": "23514",
    "constraint": "ck_kaamera_kood_positiivne"
  },
  {
    "sql": "UPDATE public.kaamera SET kood='NaN'::numeric",
    "state": "23514",
    "constraint": "ck_kaamera_kood_positiivne"
  },
  {
    "sql": "UPDATE public.sisemalu SET kood=0",
    "state": "23514",
    "constraint": "ck_sisemalu_kood_positiivne"
  },
  {
    "sql": "UPDATE public.ekraani_resolutsioon SET horisontaalne=0",
    "state": "23514",
    "constraint": "ck_ekraani_resolutsioon_horisontaalne_positiivne"
  },
  {
    "sql": "UPDATE public.ekraani_resolutsioon SET vertikaalne=0",
    "state": "23514",
    "constraint": "ck_ekraani_resolutsioon_vertikaalne_positiivne"
  },
  {
    "sql": "UPDATE public.isik SET isikukood='   '",
    "state": "23514",
    "constraint": "ck_isik_isikukood_sisu"
  },
  {
    "sql": "UPDATE public.isik SET isikukood='ABC!'",
    "state": "23514",
    "constraint": "ck_isik_isikukood_margid"
  },
  {
    "sql": "UPDATE public.isik SET eesnimi=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_isik_eesnimi_sisu"
  },
  {
    "sql": "UPDATE public.isik SET perenimi=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_isik_perenimi_sisu"
  },
  {
    "sql": "UPDATE public.isik SET elukoht=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_isik_elukoht_sisu"
  },
  {
    "sql": "UPDATE public.isik SET eesnimi=NULL,perenimi=NULL",
    "state": "23514",
    "constraint": "ck_isik_nimi_olemas"
  },
  {
    "sql": "UPDATE public.isik SET elukoht='123456'",
    "state": "23514",
    "constraint": "ck_isik_elukoht_margid"
  },
  {
    "sql": "UPDATE public.isik SET e_meil='puudub-at'",
    "state": "23514",
    "constraint": "ck_isik_e_meil_kuju"
  },
  {
    "sql": "UPDATE public.isik SET synni_kp=DATE '1899-12-31'",
    "state": "23514",
    "constraint": "ck_isik_synni_kp_vahemik"
  },
  {
    "sql": "UPDATE public.isik SET synni_kp=DATE '2026-10-02'",
    "state": "23514",
    "constraint": "ck_isik_synni_kp_registreerimine"
  },
  {
    "sql": "UPDATE public.isik SET reg_aeg=TIMESTAMPTZ '2009-12-31 23:59:59+02'",
    "state": "23514",
    "constraint": "ck_isik_reg_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.isik SET viimase_muutm_aeg=TIMESTAMPTZ '2101-01-01 00:00:00+02'",
    "state": "23514",
    "constraint": "ck_isik_viimase_muutm_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.isik SET viimase_muutm_aeg=TIMESTAMPTZ '2026-09-30 12:00:00+03'",
    "state": "23514",
    "constraint": "ck_isik_ajaline_jarjestus"
  },
  {
    "sql": "UPDATE public.kasutajakonto SET parool='   '",
    "state": "23514",
    "constraint": "ck_kasutajakonto_parool_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_roll SET kirjeldus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_tootaja_roll_kirjeldus_sisu"
  },
  {
    "sql": "UPDATE public.tootaja_rolli_omamine SET alguse_aeg=TIMESTAMPTZ '2009-12-31 23:59:59+02'",
    "state": "23514",
    "constraint": "ck_tootaja_rolli_omamine_alguse_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.tootaja_rolli_omamine SET lopu_aeg=TIMESTAMPTZ '2101-01-01 00:00:00+02'",
    "state": "23514",
    "constraint": "ck_tootaja_rolli_omamine_lopu_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.tootaja_rolli_omamine SET lopu_aeg=alguse_aeg",
    "state": "23514",
    "constraint": "ck_tootaja_rolli_omamine_ajaline_jarjestus"
  },
  {
    "sql": "UPDATE public.kaup SET kauba_kood='ABC12'",
    "state": "23514",
    "constraint": "ck_kaup_kauba_kood_min_pikkus"
  },
  {
    "sql": "UPDATE public.kaup SET kauba_kood='ABc123'",
    "state": "23514",
    "constraint": "ck_kaup_kauba_kood_kuju"
  },
  {
    "sql": "UPDATE public.kaup SET nimetus='    '",
    "state": "23514",
    "constraint": "ck_kaup_nimetus_sisu"
  },
  {
    "sql": "UPDATE public.kaup SET nimetus='abc'",
    "state": "23514",
    "constraint": "ck_kaup_nimetus_min_pikkus"
  },
  {
    "sql": "UPDATE public.kaup SET hind=0",
    "state": "23514",
    "constraint": "ck_kaup_hind_positiivne"
  },
  {
    "sql": "UPDATE public.kaup SET hind='NaN'::numeric",
    "state": "23514",
    "constraint": "ck_kaup_hind_positiivne"
  },
  {
    "sql": "UPDATE public.kaup SET kirjeldus=E' \\t\\n'",
    "state": "23514",
    "constraint": "ck_kaup_kirjeldus_sisu"
  },
  {
    "sql": "UPDATE public.kaup SET reg_aeg=TIMESTAMPTZ '2009-12-31 23:59:59+02'",
    "state": "23514",
    "constraint": "ck_kaup_reg_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.kaup SET viimase_muutm_aeg=TIMESTAMPTZ '2101-01-01 00:00:00+02'",
    "state": "23514",
    "constraint": "ck_kaup_viimase_muutm_aeg_vahemik"
  },
  {
    "sql": "UPDATE public.kaup SET viimase_muutm_aeg=TIMESTAMPTZ '2026-09-30 12:00:00+03'",
    "state": "23514",
    "constraint": "ck_kaup_ajaline_jarjestus"
  },
  {
    "sql": "UPDATE public.kaup SET pildi_aadress='foto.jpeg'",
    "state": "23514",
    "constraint": "ck_kaup_pildi_aadress_kuju"
  },
  {
    "sql": "UPDATE public.kaup SET hind=1000.01,pildi_aadress=NULL",
    "state": "23514",
    "constraint": "ck_kaup_kalli_kauba_pilt"
  },
  {
    "sql": "UPDATE public.kaup SET kauba_kood='ABC'||repeat('1',48)",
    "state": "22001",
    "constraint": ""
  }
]$vigased$::jsonb)
        LOOP
            BEGIN
                EXECUTE juht->>'sql';
                RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Vigane väärtus võeti vastu', DETAIL = juht->>'constraint', HINT = 'Kontrolli vastava väärtusreegli jõustamist.';
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS tegelik_olek = RETURNED_SQLSTATE, tegelik_kitsendus = CONSTRAINT_NAME;
                IF tegelik_olek <> juht->>'state' OR (juht->>'constraint' <> '' AND tegelik_kitsendus IS DISTINCT FROM juht->>'constraint') THEN
                    RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Ootamatu kontrolltulemus', DETAIL = format('Oodatud %s / %s, saadud %s / %s', juht->>'state', juht->>'constraint', tegelik_olek, tegelik_kitsendus), HINT = 'Kontrolli piirjuhu andmeid ja nimetatud kitsendust.';
                END IF;
            END;
        END LOOP;
        RAISE EXCEPTION USING ERRCODE = 'ZT001', MESSAGE = 'Kontrollandmete tagasipööramine', DETAIL = 'Kõik sobivad ja vigased piirjuhud kontrolliti.', HINT = 'See erand püütakse samas plokis.';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$kontroll$;
