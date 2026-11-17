-- Enne käivitamist tee andmebaasist pg_dump-varukoopia ja jäta meelde kasutajanime ja parooli paarid.
-- Asendab ainult bcrypt-kujuta paroolid; korduv käivitamine ei muuda juba räsitud ridu.
\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS laiendused;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA laiendused;

UPDATE public.kasutajakonto
SET parool = laiendused.crypt(parool,laiendused.gen_salt('bf',12))
WHERE parool !~ '^\$2[abxy]\$(0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}$';
