-- Lehtede loetavad näited väljamõeldud kontoga; lõpus eemaldatakse kõik katseandmed.
\set ON_ERROR_STOP on
START TRANSACTION;
INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
    SELECT 'U11NAIDE','u11-naide@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,
        DATE '2000-01-01','Näidis' FROM public.riik AS r
    CROSS JOIN public.isiku_seisundi_liik AS s WHERE r.kood='EST' AND s.kood='EL';
INSERT INTO public.kasutajakonto (isik_id,parool)
    SELECT isik_id,laiendused.crypt('naidis-u11-parool',laiendused.gen_salt('bf',12))
    FROM public.isik WHERE isikukood='U11NAIDE';
INSERT INTO public.tootaja (isik_id,tootaja_seisundi_liik_id)
    SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM public.isik AS i
    CROSS JOIN public.tootaja_seisundi_liik AS s WHERE i.isikukood='U11NAIDE' AND s.kood='TO';
INSERT INTO public.tootaja_rolli_omamine (tootaja_id,tootaja_roll_id,alguse_aeg)
    SELECT t.tootaja_id,r.tootaja_roll_id,date_trunc('second',CURRENT_TIMESTAMP)
    FROM public.tootaja AS t JOIN public.isik AS i USING (isik_id)
    CROSS JOIN public.tootaja_roll AS r WHERE i.isikukood='U11NAIDE' AND r.kood='KAUBAHALDUR';
SET LOCAL ROLE epood_rakendus;

-- Sisselogimine: TRUE ning FALSE.
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='U11-NAIDE@EXAMPLE.INVALID',p_parool:='naidis-u11-parool') AS oige_parool;
SELECT public.f_on_kaubahaldur(p_kasutajanimi:='u11-naide@example.invalid',p_parool:='vale-naidis') AS vale_parool;

-- Leht 5: uus ootel telefon, tühi pildiaadress ja kaks valimata märkeruutu.
SELECT public.f_registreeri_nutitelefon_vormist(
    p_kauba_kood:='DEM011',p_nimetus:='Rakenduse näidistelefon',p_hind:='899',
    p_kirjeldus:='Lehtede ehitamise ja kontrollimise näidis.',p_pildi_aadress:=NULL,
    p_e_meil:='u11-naide@example.invalid',p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
    p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',p_kaamera_kood_tagumine:='48',
    p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179') AS registreerimine;
-- Tulemus: DEM011.
SELECT kauba_kood,nimetus,reg_aeg FROM public.v_ootel_kaubad WHERE kauba_kood='DEM011';
SELECT kauba_kood,on_veekindel,on_sormejalelugeja,kategooriad,variandid
    FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='DEM011';
-- Tulemus: Ei, Ei ja kaks tühja seoseloendit.

-- Lehed 10 ja 11: seoste lisamine; korduv lisamine annab NULL-i.
SELECT public.f_lisa_kaup_kategooriasse(p_kauba_kood:='DEM011',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:='u11-naide@example.invalid') AS kategooria_lisamine;
SELECT public.f_lisa_kauba_variant(p_kauba_kood:='DEM011',p_varv_kood:='WHITE',p_e_meil:='u11-naide@example.invalid') AS variandi_lisamine;
SELECT public.f_lisa_kauba_variant(p_kauba_kood:='DEM011',p_varv_kood:='WHITE',p_e_meil:='u11-naide@example.invalid') AS korduv_variant;
-- Tulemused: DEM011, DEM011, NULL.

-- Leht 6: muutmise vormi eeltäide ja hinna salvestamine.
SELECT kauba_kood,ver,brandi_kood,eesmise_kaamera_kood,tagumise_kaamera_kood
    FROM public.v_kauba_muutmise_vorm WHERE kauba_kood='DEM011';
SELECT public.f_muuda_kaup_vormist(
    p_ver:=(SELECT ver FROM public.v_kauba_muutmise_vorm WHERE kauba_kood='DEM011'),
    p_kauba_kood_vana:='DEM011',p_kauba_kood_uus:='DEM011',p_nimetus:='Rakenduse näidistelefon',
    p_hind:='901',p_kirjeldus:='Lehtede ehitamise ja kontrollimise näidis.',p_pildi_aadress:=NULL,
    p_e_meil:='u11-naide@example.invalid',p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
    p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',p_kaamera_kood_tagumine:='48',
    p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179') AS muutmine;
-- Tulemus: DEM011, hind 901.00.

-- Lehed 7 ja 8: aktiveerimine, kordus ning mitteaktiivseks muutmine.
SELECT public.f_aktiveeri_kaup(p_kauba_kood:='DEM011',p_e_meil:='u11-naide@example.invalid') AS aktiveerimine;
SELECT public.f_aktiveeri_kaup(p_kauba_kood:='DEM011',p_e_meil:='u11-naide@example.invalid') AS korduv_aktiveerimine;
SELECT kauba_kood,nimetus FROM public.v_aktiivsed_kaubad_haldurile WHERE kauba_kood='DEM011';
SELECT public.f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='DEM011',p_e_meil:='u11-naide@example.invalid') AS mitteaktiivseks_muutmine;
-- Tulemused: DEM011, NULL, üks nimekirjarida, DEM011.

-- Lehed 10 ja 11: seoste eemaldamine, mida mitteaktiivne seisund lubab.
SELECT public.f_eemalda_kaup_kategooriast(p_kauba_kood:='DEM011',p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:='u11-naide@example.invalid') AS kategooria_eemaldamine;
SELECT public.f_eemalda_kauba_variant(p_kauba_kood:='DEM011',p_varv_kood:='WHITE',p_e_meil:='u11-naide@example.invalid') AS variandi_eemaldamine;
-- Mõlemad tulemused: DEM011.

-- Lehed 2, 3 ja 4: sama detailallikas ning muudetavate kaupade nimekiri.
SELECT kauba_kood,nimetus,hind,seisundi_nimetus,kategooriad,variandid
    FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='DEM011';
SELECT kauba_kood,nimetus,seisundi_nimetus FROM public.v_kaubad_muutmiseks WHERE kauba_kood='DEM011';
-- Tulemus: hind 901.00, seisund Mitteaktiivne, tühjad seoseloendid; mõlemas üks rida.

-- Leht 9: puuduva kauba unustamine annab NULL-i.
SELECT public.f_unusta_kaup(p_kauba_kood:='PUUDUV',p_e_meil:='u11-naide@example.invalid') AS puuduv_kaup;
-- Mitteaktiivse kauba unustamise keelu kontroll püüab teadliku vea kinni.
DO $keeld$
BEGIN
    BEGIN
        PERFORM public.f_unusta_kaup(p_kauba_kood:='DEM011',p_e_meil:='u11-naide@example.invalid');
        RAISE EXCEPTION 'Oodati kustutamise keeldu';
    EXCEPTION WHEN check_violation THEN
        IF SQLERRM<>'Kustutada saab ainult ootel kaupa.' THEN RAISE; END IF;
        RAISE NOTICE 'Oodatud keeld: %',SQLERRM;
    END;
END;
$keeld$;
-- Tulemus: Oodatud keeld: Kustutada saab ainult ootel kaupa.

-- Ootel kauba eduka unustamise jaoks registreeritakse teine telefon.
SELECT public.f_registreeri_nutitelefon_vormist(
    p_kauba_kood:='DEM012',p_nimetus:='Unustamise näidistelefon',p_hind:='99',
    p_kirjeldus:='Ootel kauba kustutamise näidis.',p_pildi_aadress:=NULL,
    p_e_meil:='u11-naide@example.invalid',p_brandi_kood:='APPLE',p_on_veekindel:=NULL,
    p_on_sormejalelugeja:=NULL,p_kaamera_kood_eesmine:='12',p_kaamera_kood_tagumine:='48',
    p_sisemalu_kood:='128',p_diagonaali_kood:='6.1',p_protsessori_kood:='A16',
    p_ekraani_resolutsiooni_kood:='2556x1179') AS ootel_registreerimine;
SELECT public.f_unusta_kaup(p_kauba_kood:='DEM012',p_e_meil:='u11-naide@example.invalid') AS unustamine;
-- Mõlemad tulemused: DEM012. Kaupa ei ole enam üheski kaubavaates.
RESET ROLE;
ROLLBACK;
