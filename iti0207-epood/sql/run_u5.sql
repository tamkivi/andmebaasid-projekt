-- Käivita projekti andmebaasis: psql -v apex_kasutaja=... -v apex_parool=... -f run_u5.sql
-- Ühenduse valikud: testandmete_host, testandmete_dbname ja testandmete_port.
-- Olemasolevas projekti skeemis laaditakse puuduvad andmed; skeemi struktuuri ei uuendata.
\set ON_ERROR_STOP on
SET search_path TO public;

-- Vana skeem tuleb enne laadimist eraldi migreerida; uut kasutamata domeeni ei looda.
DO $versioon$
BEGIN
    IF to_regtype('public.klassifikaatori_nimetus') IS NOT NULL THEN
        RAISE EXCEPTION 'Käivita enne laadimist migrations/06_domeeni_nimi.sql';
    END IF;
END;
$versioon$;

SELECT to_regtype('public.d_klassifikaatori_nimetus') IS NULL AS loo_domeen \gset
\if :loo_domeen
\ir 00_domains.sql
\endif

SELECT to_regclass('public.riik') IS NULL AS loo_tabelid \gset
\if :loo_tabelid
\ir 01_tables_draft.sql
\endif

\ir 10_indexes.sql
\ir 11_klassifikaatorid.sql
\ir 12_1_valised_tabelid.sql
\ir 12_2_json_laadimine.sql
\ir 13_testandmed.sql
