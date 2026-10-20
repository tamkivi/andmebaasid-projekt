-- Projekti realiseeritud objektide kustutamine eraldi projektiandmebaasis.
START TRANSACTION;

-- Õigused.
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

-- Domeenist sõltuvad vaated ja nende reeglid on juba eemaldatud.
DROP VIEW IF EXISTS v_kaup_muutmiseks;
DROP VIEW IF EXISTS v_kaubad;
DROP VIEW IF EXISTS v_kauba_kategooriad;
DROP VIEW IF EXISTS v_kauba_variandid;

-- Projekt ei loo väliseid tabeleid, rutiine, trigereid ega laiendusi.
DROP ROLE epood_rakendus;

COMMIT;
