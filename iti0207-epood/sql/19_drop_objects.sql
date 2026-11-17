-- Projekti realiseeritud objektide kustutamine eraldi projektiandmebaasis.
START TRANSACTION;

-- Õigused.
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM epood_rakendus;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM epood_rakendus;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM epood_rakendus;
REVOKE ALL ON SCHEMA public FROM epood_rakendus;
DO $oigused$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM epood_rakendus',current_database());
END;
$oigused$;
GRANT USAGE ON LANGUAGE plpgsql TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT EXECUTE ON FUNCTIONS TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT USAGE ON TYPES TO PUBLIC;

-- Trigerid eemaldatakse enne trigerifunktsioone.
DROP TRIGGER trig_kaup_algseisund ON public.kaup;
DROP TRIGGER trig_kaup_seisundimuudatus ON public.kaup;
DROP TRIGGER trig_kaup_seisundimuudatus_kategooria ON public.kaup;
DROP TRIGGER trig_kaup_kustutamine ON public.kaup;
DROP TRIGGER trig_kaup_andmete_muutmine ON public.kaup;
DROP TRIGGER trig_nutitelefon_kauba_muudetavus ON public.nutitelefon;
DROP TRIGGER trig_nutitelefon_muutmine ON public.nutitelefon;
DROP TRIGGER trig_kauba_kategooria_omamine_kauba_muudetavus ON public.kauba_kategooria_omamine;
DROP TRIGGER trig_kauba_kategooria_omamine_muutmine ON public.kauba_kategooria_omamine;
DROP TRIGGER trig_kauba_variant_kauba_muudetavus ON public.kauba_variant;
DROP TRIGGER trig_kauba_variant_muutmine ON public.kauba_variant;
DROP TRIGGER trig_kaup_reg_andmed ON public.kaup;
DROP TRIGGER trig_kaup_viimase_muutm_aeg ON public.kaup;
DROP TRIGGER trig_isik_viimase_muutm_aeg ON public.isik;
DROP TRIGGER trig_kaup_aktiivne_algseisund ON public.kaup;
DROP TRIGGER trig_kaup_aktiivne_uus_seisund ON public.kaup;
DROP TRIGGER trig_kaup_truncate ON public.kaup;
DROP TRIGGER trig_nutitelefon_truncate ON public.nutitelefon;
DROP TRIGGER trig_kauba_kategooria_omamine_truncate ON public.kauba_kategooria_omamine;
DROP TRIGGER trig_kauba_variant_truncate ON public.kauba_variant;

DROP FUNCTION public.f_trig_kaup_algseisund();
DROP FUNCTION public.f_trig_kaup_seisundimuudatus();
DROP FUNCTION public.f_trig_kaup_aktiveerimine();
DROP FUNCTION public.f_trig_kaup_kustutamine();
DROP FUNCTION public.f_trig_kaup_muudetavus();
DROP FUNCTION public.f_trig_kauba_osa_muudetavus();
DROP FUNCTION public.f_trig_kaup_reg_andmed();
DROP FUNCTION public.f_trig_viimase_muutm_aeg();
DROP FUNCTION public.f_trig_kaup_aktiivne_seisund();
DROP FUNCTION public.f_trig_keela_truncate();

-- Vormifunktsioonid eemaldatakse enne nende kutsutavaid rutiine.
DROP FUNCTION public.f_registreeri_nutitelefon_vormist(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying);
DROP FUNCTION public.f_muuda_kaup_vormist(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying);

-- Rutiinid eemaldatakse enne nende kasutatavaid tabeleid ja domeeni.
DROP FUNCTION public.f_on_kaubahaldur(text, text);
DROP FUNCTION f_aktiveeri_kaup(character varying, character varying);
DROP FUNCTION f_eemalda_kauba_variant(character varying, character varying, character varying);
DROP FUNCTION f_eemalda_kaup_kategooriast(character varying, character varying, character varying);
DROP FUNCTION f_lisa_kauba_variant(character varying, character varying, character varying);
DROP FUNCTION f_lisa_kaup_kategooriasse(character varying, character varying, character varying);
DROP FUNCTION f_lopeta_kaup(character varying, character varying);
DROP FUNCTION f_muuda_kaup(text,
    character varying,
    character varying,
    character varying,
    numeric,
    text,
    character varying,
    character varying,
    character varying,
    boolean,
    boolean,
    numeric,
    numeric,
    integer,
    numeric,
    character varying,
    character varying);
DROP FUNCTION f_muuda_kaup_mitteaktiivseks(character varying, character varying);
DROP FUNCTION f_registreeri_nutitelefon(character varying,
    character varying,
    numeric,
    text,
    character varying,
    character varying,
    character varying,
    boolean,
    boolean,
    numeric,
    numeric,
    integer,
    numeric,
    character varying,
    character varying);
DROP FUNCTION f_unusta_kaup(character varying, character varying);
DROP FUNCTION f_leia_tootaja(character varying, character varying);

-- Vaated ja nende reeglid eemaldatakse enne baastabeleid.
DROP VIEW public.v_seotud_kategooriate_valikud;
DROP VIEW public.v_kaupade_detailid_seostega;
DROP VIEW public.v_kategooriate_valikud_tyybiga;
DROP VIEW public.v_ekraani_resolutsioonide_valikud;
DROP VIEW public.v_protsessorite_valikud;
DROP VIEW public.v_diagonaalide_valikud;
DROP VIEW public.v_sisemalude_valikud;
DROP VIEW public.v_kaamerate_valikud;
DROP VIEW public.v_brandide_valikud;
DROP VIEW public.v_kauba_muutmise_vorm;
DROP VIEW public.v_aktiivsed_kaubad_haldurile;
DROP VIEW public.v_ootel_kaubad;

DROP VIEW v_kaupade_json;
DROP VIEW v_kaupade_kategooriate_pingeread;
DROP VIEW v_kaupade_kategooriate_loendid;
DROP VIEW v_kaupade_detailid;
DROP VIEW v_kaupade_koondaruanne;
DROP VIEW v_aktiivsed_kaubad;
DROP VIEW v_kategooriate_valikud;
DROP VIEW v_varvide_valikud;
DROP VIEW v_kaubad_muutmiseks;
DROP VIEW v_kaubad;
DROP VIEW v_kauba_kategooriad;
DROP VIEW v_kauba_variandid;

-- Tabelid eemaldatakse viitavatest tabelitest viidatud tabelite suunas.
-- IDENTITY-generaatorid ja tabeliindeksid kustuvad koos tabeliga.
DROP TABLE kauba_kategooria_omamine;
DROP TABLE kauba_variant;
DROP TABLE nutitelefon;
DROP TABLE kaup;
DROP TABLE klient;
DROP TABLE tootaja_rolli_omamine;
DROP TABLE tootaja;
DROP TABLE kasutajakonto;
DROP TABLE isik;
DROP TABLE kauba_kategooria;
DROP TABLE kauba_kategooria_tyyp;
DROP TABLE varv;
DROP TABLE sisemalu;
DROP TABLE protsessor;
DROP TABLE kaamera;
DROP TABLE ekraani_resolutsioon;
DROP TABLE diagonaal;
DROP TABLE brand;
DROP TABLE kauba_seisundi_liik;
DROP TABLE tootaja_roll;
DROP TABLE kliendi_seisundi_liik;
DROP TABLE tootaja_seisundi_liik;
DROP TABLE isiku_seisundi_liik;
DROP TABLE riik;

-- Väliste andmete ühenduse eemaldamine ei muuda lähteandmebaasi.
DROP FOREIGN TABLE valine.Riik_sisend;
DROP FOREIGN TABLE valine.Isik_sisend;
DROP USER MAPPING FOR CURRENT_USER SERVER minu_testandmete_server_apex;
DROP SERVER minu_testandmete_server_apex;

-- Domeen eemaldatakse alles pärast kõiki sellest sõltuvaid objekte.
DROP DOMAIN d_klassifikaatori_nimetus RESTRICT;

DROP ROLE epood_rakendus;

DROP EXTENSION postgres_fdw;
DROP EXTENSION pgcrypto;
DROP SCHEMA valine;
DROP SCHEMA laiendused;

COMMIT;
