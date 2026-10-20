-- Tühjade baastabelite statistika kogumise kontroll.
DO $kontroll$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class AS t
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind='r' AND t.reltuples<0
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Kõigi baastabelite kohta peab olema kogutud planeerija statistika.',
            HINT='Käivita ANALYZE pärast andmete laadimist.';
    END IF;
END;
$kontroll$;
