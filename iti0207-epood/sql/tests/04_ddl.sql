-- Füüsilise skeemi tervikluse kontroll süsteemikataloogist.
DO $kontroll$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class AS t
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind='r'
          AND t.relname NOT IN ('kauba_variant','kauba_kategooria_omamine')
          AND NOT COALESCE(t.reloptions @> ARRAY['fillfactor=90'],false)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Muudetava tabeli FILLFACTOR peab jätma uuendustele vaba ruumi.',
            HINT='Kontrolli tabeli salvestusparameetrit.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class AS t
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind='r'
          AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint AS c WHERE c.conrelid=t.oid AND c.contype='p')
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Primaarvõti puudub',
            DETAIL='Igal baastabelil peab olema primaarvõti.', HINT='Kontrolli tabelite deklaratsioone.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute AS a
        INNER JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        INNER JOIN pg_catalog.pg_type AS ty ON ty.oid=a.atttypid
        LEFT OUTER JOIN pg_catalog.pg_attrdef AS d ON d.adrelid=t.oid AND d.adnum=a.attnum
        WHERE n.nspname='public' AND t.relkind='r' AND a.attnum>0 AND NOT a.attisdropped
          AND ((d.oid IS NOT NULL AND NOT a.attnotnull AND NOT ty.typnotnull)
               OR (ty.typname IN ('timestamp','timestamptz') AND NOT a.attnotnull)
               OR (a.attidentity='' AND pg_catalog.pg_get_expr(d.adbin,d.adrelid) LIKE 'nextval(%')
               OR (a.attname IN ('registreerija_id','viimase_muutja_id') AND d.oid IS NOT NULL))
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ebasobiv veeru deklaratsioon',
            DETAIL='Vaikeväärtuse, kohustuslikkuse või võtmegeneraatori reegel ei ole täidetud.',
            HINT='Kontrolli ajatemplite, vaikeväärtuste ja identiteediveergude deklaratsioone.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint AS c
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=c.connamespace
        WHERE n.nspname='public' AND c.contype='f'
          AND EXISTS (SELECT 1 FROM pg_catalog.pg_attribute AS a
                      WHERE a.attrelid=c.conrelid AND a.attnum=ANY(c.conkey) AND a.attidentity<>'')
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Välisvõtmel on generaator',
            DETAIL='Viide peab pärinema viidatud reast.', HINT='Eemalda välisvõtme identiteedimäärang.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint AS c
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=c.connamespace
        WHERE n.nspname='public' AND c.contype IN ('p','u','f','c')
          AND (c.conname !~ '^(pk|uk|fk|ck)_[a-z0-9_]+$' OR octet_length(c.conname)>=63)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ebasobiv kitsenduse nimi',
            DETAIL='Kitsenduse nimi peab olema selge ja PostgreSQLi piirist lühem.',
            HINT='Kasuta ühtlast nimetamist ning väldi nime kärpimist.';
    END IF;
END;
$kontroll$;
