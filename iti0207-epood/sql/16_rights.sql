-- Rakenduse lugemisõiguste roll; sisselogimist see roll ei võimalda.
CREATE ROLE epood_rakendus NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
    NOINHERIT NOREPLICATION NOBYPASSRLS;
COMMENT ON ROLE epood_rakendus IS 'Kaupade halduri rakenduse nelja lugemisvaate minimaalsed õigused.';

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

GRANT USAGE ON SCHEMA public TO epood_rakendus;
GRANT SELECT ON v_kaup_muutmiseks,v_kaubad,v_kauba_kategooriad,v_kauba_variandid
    TO epood_rakendus;

DO $yhendus$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO epood_rakendus',current_database());
END;
$yhendus$;
