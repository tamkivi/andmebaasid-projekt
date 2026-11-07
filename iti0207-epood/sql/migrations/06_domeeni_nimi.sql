-- Enne käivitamist tee olemasolevast andmebaasist pg_dump varukoopia.
-- Eeldus: projekti vana klassifikaatori_nimetus on juba kõigil 15 nimetuse veerul.
-- Nime muutmine säilitab domeeni OID, andmed, õigused ja sõltuvused (ka vaated).
\set ON_ERROR_STOP on
START TRANSACTION;
SET LOCAL search_path TO public, pg_temp;

DO $migratsioon$
DECLARE
    v_domeen oid;
BEGIN
    IF to_regtype('public.klassifikaatori_nimetus') IS NOT NULL THEN
        IF to_regtype('public.d_klassifikaatori_nimetus') IS NOT NULL THEN
            RAISE EXCEPTION 'Mõlemad domeeninimed on olemas; kontrolli skeemi käsitsi';
        END IF;
        ALTER DOMAIN public.klassifikaatori_nimetus RENAME TO d_klassifikaatori_nimetus;
    END IF;
    SELECT oid INTO v_domeen FROM pg_catalog.pg_type
    WHERE oid=to_regtype('public.d_klassifikaatori_nimetus') AND typtype='d'
        AND typnotnull AND typbasetype='varchar'::regtype AND typtypmod=104
        AND typdefault IS NULL;
    IF v_domeen IS NULL OR (
        SELECT count(*) FROM pg_catalog.pg_attribute AS a
        JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
        WHERE t.relnamespace='public'::regnamespace AND t.relkind='r'
            AND a.atttypid=v_domeen AND a.attnum>0 AND NOT a.attisdropped
    )<>15 THEN
        RAISE EXCEPTION 'Migratsioon eeldab olemasolevat varchar(100) kohustuslikku domeeni ja 15 kasutuskohta';
    END IF;
    IF (SELECT count(*) FROM pg_catalog.pg_constraint WHERE contypid=v_domeen AND contype='c')<>1
        OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
            WHERE contypid=v_domeen AND conname='ck_klassifikaatori_nimetus_sisu'
                AND convalidated AND pg_get_expr(conbin,0)='((VALUE)::text ~ ''[^[:space:]]''::text)')
        OR EXISTS (SELECT 1 FROM pg_catalog.pg_attribute AS a
            JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
            LEFT JOIN pg_catalog.pg_attrdef AS d ON d.adrelid=t.oid AND d.adnum=a.attnum
            WHERE t.relnamespace='public'::regnamespace AND t.relkind='r'
                AND a.atttypid=v_domeen AND a.attnum>0 AND NOT a.attisdropped
                AND (a.attnotnull OR d.oid IS NOT NULL OR a.attname<>'nimetus'
                    OR t.relname NOT IN ('brand','diagonaal','ekraani_resolutsioon',
                        'isiku_seisundi_liik','kaamera','kauba_kategooria','kauba_kategooria_tyyp',
                        'kauba_seisundi_liik','kliendi_seisundi_liik','protsessor','riik','sisemalu',
                        'tootaja_roll','tootaja_seisundi_liik','varv')
                    OR EXISTS (SELECT 1 FROM pg_catalog.pg_constraint AS c
                        WHERE c.conrelid=t.oid AND a.attnum=ANY(c.conkey) AND c.contype IN ('f','c')))) THEN
        RAISE EXCEPTION 'Domeeni väärtusreegel või kasutuskohad erinevad eeldatud skeemist';
    END IF;
END;
$migratsioon$;

COMMIT;
