-- Rakenduse lugemisõiguste roll; sisselogimist see roll ei võimalda.
CREATE ROLE epood_rakendus NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
    NOINHERIT NOREPLICATION NOBYPASSRLS;
COMMENT ON ROLE epood_rakendus IS 'Kaupade halduri rakenduse lugemisvaadete, lepinguliste funktsioonide ja tuvastamisfunktsiooni minimaalsed õigused.';

REVOKE ALL ON SCHEMA valine,laiendused FROM PUBLIC,epood_rakendus;
REVOKE ALL ON ALL TABLES IN SCHEMA valine FROM PUBLIC,epood_rakendus;
REVOKE ALL ON FOREIGN SERVER minu_testandmete_server_apex FROM PUBLIC,epood_rakendus;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON DOMAIN d_klassifikaatori_nimetus FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE USAGE ON TYPES FROM PUBLIC;
DO $oigused$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC',current_database());
END;
$oigused$;

-- Trigerifunktsioone ei anta rakendusele; lepingulised funktsioonid ei kuulu PUBLIC-ile.
REVOKE ALL ON FUNCTION public.f_trig_kaup_algseisund() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_seisundimuudatus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_aktiveerimine() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_kustutamine() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_muudetavus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kauba_osa_muudetavus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_reg_andmed() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_viimase_muutm_aeg() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_aktiivne_seisund() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_keela_truncate() FROM PUBLIC;
REVOKE ALL ON FUNCTION f_aktiveeri_kaup(character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_eemalda_kauba_variant(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_eemalda_kaup_kategooriast(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_leia_tootaja(character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_lisa_kauba_variant(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_lisa_kaup_kategooriasse(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_lopeta_kaup(character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_muuda_kaup(text,
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
    character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_muuda_kaup_mitteaktiivseks(character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_registreeri_nutitelefon(character varying,
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
    character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_unusta_kaup(character varying, character varying) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.f_on_kaubahaldur(text, text) FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO epood_rakendus;
GRANT SELECT ON v_kaubad_muutmiseks,v_kauba_kategooriad,v_kauba_variandid,
    v_varvide_valikud TO epood_rakendus;

DO $yhendus$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO epood_rakendus',current_database());
END;
$yhendus$;

-- Rakendus saab käivitada üheksat andmemuudatuse funktsiooni, kaht vormifunktsiooni ja tuvastamisfunktsiooni.
GRANT EXECUTE ON FUNCTION f_aktiveeri_kaup(character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_eemalda_kauba_variant(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_eemalda_kaup_kategooriast(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_lisa_kauba_variant(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_lisa_kaup_kategooriasse(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_muuda_kaup(text,
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
    character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_muuda_kaup_mitteaktiivseks(character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_registreeri_nutitelefon(character varying,
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
    character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_unusta_kaup(character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION public.f_on_kaubahaldur(text, text) TO epood_rakendus;

-- Rakenduse liides (Ü11).
GRANT SELECT ON public.v_ootel_kaubad,
    public.v_aktiivsed_kaubad_haldurile,
    public.v_kauba_muutmise_vorm,
    public.v_brandide_valikud,
    public.v_kaamerate_valikud,
    public.v_sisemalude_valikud,
    public.v_diagonaalide_valikud,
    public.v_protsessorite_valikud,
    public.v_ekraani_resolutsioonide_valikud,
    public.v_kategooriate_valikud_tyybiga,
    public.v_kaupade_detailid_seostega,
    public.v_seotud_kategooriate_valikud
    TO epood_rakendus;
GRANT EXECUTE ON FUNCTION public.f_registreeri_nutitelefon_vormist(character varying,character varying,numeric,text,
    character varying,character varying,character varying,boolean,boolean,numeric,numeric,
    integer,numeric,character varying,character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION public.f_muuda_kaup_vormist(text,character varying,character varying,character varying,
    numeric,text,character varying,character varying,character varying,boolean,boolean,
    numeric,numeric,integer,numeric,character varying,character varying) TO epood_rakendus;

-- Rakendusele vastav kasutaja ja liigsete õiguste äravõtmine (Ü12).
REVOKE EXECUTE ON FUNCTION f_lopeta_kaup(character varying, character varying) FROM epood_rakendus;
REVOKE SELECT ON v_kaubad,v_kaupade_detailid,v_kaupade_koondaruanne,
    v_aktiivsed_kaubad,v_kategooriate_valikud,v_kaupade_kategooriate_loendid,
    v_kaupade_kategooriate_pingeread,v_kaupade_json FROM epood_rakendus;
REVOKE USAGE ON LANGUAGE plpgsql FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA laiendused FROM PUBLIC;
CREATE USER t253787_epood_kaubahaldur NOSUPERUSER NOCREATEDB NOCREATEROLE
    INHERIT NOREPLICATION NOBYPASSRLS;
COMMENT ON ROLE t253787_epood_kaubahaldur IS
    'Kaupade halduri rakenduse piiratud ühenduskasutaja; õigused rolli epood_rakendus kaudu.';
GRANT epood_rakendus TO t253787_epood_kaubahaldur;
