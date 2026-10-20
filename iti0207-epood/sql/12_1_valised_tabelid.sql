-- Käivita psql-is: psql -v apex_kasutaja=... -v apex_parool=... -f 12_1_valised_tabelid.sql
-- Kasutajanimi ja parool antakse käivitamisel muutujatena; siia neid ei salvestata.
START TRANSACTION;

CREATE SCHEMA IF NOT EXISTS laiendused;
CREATE EXTENSION IF NOT EXISTS postgres_fdw SCHEMA laiendused;

CREATE SERVER minu_testandmete_server_apex FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'apex2.taltech.ee', dbname 'testandmed', port '5432');

CREATE USER MAPPING FOR CURRENT_USER SERVER minu_testandmete_server_apex
    OPTIONS (user :'apex_kasutaja', password :'apex_parool');

CREATE SCHEMA IF NOT EXISTS valine;

CREATE FOREIGN TABLE valine.Riik_sisend (riik JSONB)
    SERVER minu_testandmete_server_apex
    OPTIONS (schema_name 'public', table_name 'riik_jsonb', updatable 'false');

CREATE FOREIGN TABLE valine.Isik_sisend (isik JSONB)
    SERVER minu_testandmete_server_apex
    OPTIONS (schema_name 'public', table_name 'isik_jsonb', updatable 'false');

COMMIT;
