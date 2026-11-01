-- Käivita psql-is: psql -v apex_kasutaja=... -v apex_parool=... -f 12_1_valised_tabelid.sql
-- Kasutajanimi ja parool antakse käivitamisel muutujatena; siia neid ei salvestata.
-- Ühenduse muutujad kehtivad serveri esimesel loomisel; olemasolevat ühendust ei muudeta.
\if :{?testandmete_host}
\else
\set testandmete_host apex2.taltech.ee
\endif
\if :{?testandmete_dbname}
\else
\set testandmete_dbname testandmed
\endif
\if :{?testandmete_port}
\else
\set testandmete_port 5432
\endif

START TRANSACTION;

CREATE SCHEMA IF NOT EXISTS laiendused;
CREATE EXTENSION IF NOT EXISTS postgres_fdw SCHEMA laiendused;

CREATE SERVER IF NOT EXISTS minu_testandmete_server_apex FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host :'testandmete_host', dbname :'testandmete_dbname', port :'testandmete_port');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER minu_testandmete_server_apex
    OPTIONS (user :'apex_kasutaja', password :'apex_parool');

CREATE SCHEMA IF NOT EXISTS valine;

CREATE FOREIGN TABLE IF NOT EXISTS valine.Riik_sisend (riik JSONB)
    SERVER minu_testandmete_server_apex
    OPTIONS (schema_name 'public', table_name 'riik_jsonb', updatable 'false');

CREATE FOREIGN TABLE IF NOT EXISTS valine.Isik_sisend (isik JSONB)
    SERVER minu_testandmete_server_apex
    OPTIONS (schema_name 'public', table_name 'isik_jsonb', updatable 'false');

COMMIT;
