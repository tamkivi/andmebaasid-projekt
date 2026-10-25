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
ALTER DEFAULT PRIVILEGES GRANT EXECUTE ON FUNCTIONS TO PUBLIC;
ALTER DEFAULT PRIVILEGES GRANT USAGE ON TYPES TO PUBLIC;

-- Rutiinid eemaldatakse enne nende kasutatavaid tabeleid ja domeeni.
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
DROP FUNCTION f_unusta_kaup(character varying);
DROP FUNCTION f_leia_tootaja(character varying);

-- Domeen ja sellest sõltuvad veerud ning vaated eemaldatakse koos.
DROP DOMAIN klassifikaatori_nimetus CASCADE;

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

-- Domeenist sõltuvad vaated ja nende reeglid on juba eemaldatud.
DROP VIEW IF EXISTS v_kaubad_muutmiseks;
DROP VIEW IF EXISTS v_kaubad;
DROP VIEW IF EXISTS v_kauba_kategooriad;
DROP VIEW IF EXISTS v_kauba_variandid;

-- Projekt ei loo trigereid ega trigerifunktsioone.
DROP ROLE epood_rakendus;

DROP EXTENSION postgres_fdw;
DROP EXTENSION pgcrypto;
DROP SCHEMA valine;
DROP SCHEMA laiendused;

COMMIT;
