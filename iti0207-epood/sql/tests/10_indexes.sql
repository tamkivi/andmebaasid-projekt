-- Välisvõtmete indeksite ja e-posti unikaalsuse kontroll.
DO $kontroll$
DECLARE
    v_riik smallint;
    v_seisund smallint;
    v_kitsendus text;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint AS c
        INNER JOIN pg_catalog.pg_class AS t ON t.oid = c.conrelid
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
        CROSS JOIN LATERAL unnest(c.conkey) AS k(veerg)
        WHERE n.nspname = 'public' AND c.contype = 'f'
          AND NOT EXISTS (
              SELECT 1 FROM pg_catalog.pg_index AS ix
              INNER JOIN pg_catalog.pg_class AS it ON it.oid = ix.indexrelid
              INNER JOIN pg_catalog.pg_am AS am ON am.oid = it.relam
              WHERE ix.indrelid = c.conrelid AND ix.indkey[0] = k.veerg
                AND ix.indisvalid AND ix.indisready AND ix.indpred IS NULL
                AND am.amname = 'btree'
          )
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Ootamatu kontrolltulemus',
            DETAIL = 'Vähemalt ühe välisvõtme veerul puudub sobiva algusveeruga indeks.',
            HINT = 'Kontrolli välisvõtmete ja indeksite vastavust.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_index AS ix
        INNER JOIN pg_catalog.pg_class AS t ON t.oid = ix.indrelid
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid = t.relnamespace
        WHERE n.nspname = 'public'
        GROUP BY ix.indrelid,ix.indkey,ix.indclass,ix.indcollation,ix.indoption,
                 ix.indisunique,ix.indexprs::text,ix.indpred::text
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Dubleeritud indeks',
            DETAIL = 'Samad võtmed ja avaldised on indekseeritud korduvalt.',
            HINT = 'Arvesta primaar- ja alternatiivvõtmete automaatsete indeksitega.';
    END IF;
    BEGIN
        INSERT INTO public.riik (kood,nimetus) VALUES ('QZZ','Kontrollriik') RETURNING riik_id INTO v_riik;
        INSERT INTO public.isiku_seisundi_liik (kood,nimetus) VALUES ('TEST','Kontrollväärtus')
            RETURNING isiku_seisundi_liik_id INTO v_seisund;
        INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
            VALUES ('kontroll-a','Index-Mari@Example.invalid',v_riik,v_seisund,DATE '2000-01-01','Mari');
        BEGIN
            INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
                VALUES ('kontroll-b','index-mari@example.INVALID',v_riik,v_seisund,DATE '2000-01-01','Mart');
            RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Tõstuvariant võeti vastu',
                DETAIL = 'Sama e-posti aadressi teine tõstuvariant peab olema keelatud.',
                HINT = 'Kontrolli lower(e_meil) unikaalset indeksit.';
        EXCEPTION WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS v_kitsendus = CONSTRAINT_NAME;
            IF v_kitsendus <> 'ux_isik_e_meil' THEN
                RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Vale unikaalsuse kontroll',
                    DETAIL = 'Erandi peab põhjustama ux_isik_e_meil.',
                    HINT = 'Kontrolli SQLSTATE-i 23505 ja indeksi nime.';
            END IF;
        END;
        INSERT INTO public.isik (isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
            VALUES ('kontroll-c','index-mart@example.invalid',v_riik,v_seisund,DATE '2000-01-01','Mart');
        RAISE EXCEPTION USING ERRCODE = 'ZT001', MESSAGE = 'Kontrollandmete eemaldamine',
            DETAIL = 'Kõik kontrollread eemaldatakse.', HINT = 'See erand püütakse samas plokis.';
    EXCEPTION WHEN SQLSTATE 'ZT001' THEN NULL;
    END;
END;
$kontroll$;
