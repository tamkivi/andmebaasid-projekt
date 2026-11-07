-- Täieliku paigalduse kontroll eraldi testandmebaasis, samade allikamuutujatega nagu run_u5.sql.
-- Migreerimise test 06_migration.sql käivitatakse eraldi täidetud vanal skeemil pärast varundamist.
\set ON_ERROR_STOP on
SET search_path TO public;
\ir 03_domains.sql
\ir 04_ddl.sql
\ir 04_tables.sql
\ir 05_views.sql
\ir 09_rutiinid.sql
\ir 10_indexes.sql
\ir 11_klassifikaatorid.sql
\ir 12_json_laadimine.sql
\ir 13_testandmed.sql
\ir 14_statistics.sql
-- Õiguste test vajab SAVEPOINTi ja SET LOCAL ROLE tõttu välist tehingut.
START TRANSACTION;
\ir 16_rights.sql
ROLLBACK;
-- Laadimisskriptid sisaldavad oma tehinguid; neid ei tohi pakkida välise tehingu sisse.
\ir run_u5.sql
