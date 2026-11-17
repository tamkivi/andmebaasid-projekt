-- Tegelik ridade arv, kolme tabeli lugemine ja puhvrite mõõtmine.
DO $kontroll$
DECLARE
    v_plaan jsonb;
    v_tabeleid integer;
BEGIN
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
        SELECT kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus
        FROM public.v_kaubad' INTO v_plaan;
    IF (v_plaan->0->'Plan'->>'Actual Rows')::numeric<1
        OR NOT (v_plaan->0->'Plan' ? 'Shared Hit Blocks') THEN
        RAISE EXCEPTION 'Plaan peab sisaldama tegelikke ridu ja puhvrite kasutust';
    END IF;
    WITH RECURSIVE solmed AS (
        SELECT v_plaan->0->'Plan' AS s
        UNION ALL
        SELECT laps FROM solmed CROSS JOIN LATERAL
            jsonb_array_elements(COALESCE(s->'Plans','[]'::jsonb)) AS laps
    )
    SELECT count(DISTINCT s->>'Relation Name') INTO v_tabeleid FROM solmed
        WHERE s->>'Relation Name' IN ('kaup','brand','kauba_seisundi_liik');
    IF v_tabeleid<>3 THEN RAISE EXCEPTION 'Plaan peab lugema kolme baastabelit'; END IF;
END;
$kontroll$;
