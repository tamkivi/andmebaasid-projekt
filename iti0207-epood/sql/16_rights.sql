-- Rakenduse lugemisõiguste roll; sisselogimist see roll ei võimalda.
CREATE ROLE epood_rakendus NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
    NOINHERIT NOREPLICATION NOBYPASSRLS;
COMMENT ON ROLE epood_rakendus IS 'Kaupade halduri rakenduse lugemisvaadete ja lepinguliste funktsioonide minimaalsed õigused.';

REVOKE ALL ON SCHEMA valine,laiendused FROM PUBLIC,epood_rakendus;
REVOKE ALL ON ALL TABLES IN SCHEMA valine FROM PUBLIC,epood_rakendus;
REVOKE ALL ON FOREIGN SERVER minu_testandmete_server_apex FROM PUBLIC,epood_rakendus;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON DOMAIN klassifikaatori_nimetus FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE USAGE ON TYPES FROM PUBLIC;
DO $oigused$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC',current_database());
END;
$oigused$;

-- Lepinguliste funktsioonide käivitamine ei kuulu PUBLIC-i õigustesse.
REVOKE ALL ON FUNCTION f_aktiveeri_kaup(character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_eemalda_kauba_variant(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_eemalda_kaup_kategooriast(character varying, character varying, character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION f_leia_tootaja(character varying) FROM PUBLIC;
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
REVOKE ALL ON FUNCTION f_unusta_kaup(character varying) FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO epood_rakendus;
GRANT SELECT ON v_kaubad_muutmiseks,v_kaubad,v_kauba_kategooriad,v_kauba_variandid
    TO epood_rakendus;

DO $yhendus$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO epood_rakendus',current_database());
END;
$yhendus$;

-- Rakendus saab käivitada kümmet andmemuudatuse funktsiooni.
GRANT EXECUTE ON FUNCTION f_aktiveeri_kaup(character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_eemalda_kauba_variant(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_eemalda_kaup_kategooriast(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_lisa_kauba_variant(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_lisa_kaup_kategooriasse(character varying, character varying, character varying) TO epood_rakendus;
GRANT EXECUTE ON FUNCTION f_lopeta_kaup(character varying, character varying) TO epood_rakendus;
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
GRANT EXECUTE ON FUNCTION f_unusta_kaup(character varying) TO epood_rakendus;
