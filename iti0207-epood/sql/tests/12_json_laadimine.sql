-- Kohaliku JSON-allika kuju, laadimise ja väliste tabelite kirjutamiskeelu kontroll.
DO $kontroll$
DECLARE
    v_allikas bigint;
BEGIN
    IF (SELECT count(*) FROM riik)<>246
        OR EXISTS (SELECT 1 FROM riik WHERE kood !~ '^[A-Z]{3}$')
        OR (SELECT count(*) FROM valine.Riik_sisend)<>246 THEN
        RAISE EXCEPTION 'Riikide laadimine ei vasta kohalikule lähteandmestikule';
    END IF;
    SELECT count(*) INTO v_allikas
    FROM valine.Isik_sisend AS a
    CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
        isikukood text PATH '$.isikukood',seisund smallint PATH '$.seisund'
    )) AS jt WHERE jt.seisund=1;
    IF v_allikas<>3 OR (SELECT count(*) FROM isik)<>v_allikas
        OR (SELECT count(*) FROM kasutajakonto)<>v_allikas THEN
        RAISE EXCEPTION 'Isikute või kontode arv ei vasta elus isikute arvule';
    END IF;
    IF EXISTS (
        SELECT 1 FROM valine.Isik_sisend AS a
        CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
            isikukood text PATH '$.isikukood',eesnimi text PATH '$.eesnimi',
            perenimi text PATH '$.perekonnanimi',email text PATH '$.email',
            synni_aeg date PATH '$.synni_aeg',seisund smallint PATH '$.seisund',
            aadress text PATH '$.aadress',parool text PATH '$.parool'
        )) AS jt
        INNER JOIN riik AS r ON r.kood=JSON_VALUE(a.isik,'$.riik')
        LEFT OUTER JOIN isik AS i ON (i.riik_id=r.riik_id AND i.isikukood=jt.isikukood)
        LEFT OUTER JOIN isiku_seisundi_liik AS s USING (isiku_seisundi_liik_id)
        LEFT OUTER JOIN kasutajakonto AS k USING (isik_id)
        WHERE (jt.seisund=1 AND (i.isik_id IS NULL OR s.kood<>'EL'
            OR i.eesnimi IS DISTINCT FROM jt.eesnimi OR i.perenimi IS DISTINCT FROM jt.perenimi
            OR i.e_meil IS DISTINCT FROM jt.email OR i.synni_kp IS DISTINCT FROM jt.synni_aeg
            OR i.elukoht IS DISTINCT FROM jt.aadress OR k.parool !~ '^\$2a\$12\$.{53}$'
            OR k.parool IS DISTINCT FROM laiendused.crypt(jt.parool,k.parool)
            OR k.on_aktiivne IS DISTINCT FROM TRUE))
           OR (jt.seisund<>1 AND i.isik_id IS NOT NULL)
    ) OR NOT EXISTS (SELECT 1 FROM isik WHERE eesnimi IS NULL AND perenimi IS NOT NULL)
      OR NOT EXISTS (SELECT 1 FROM isik WHERE e_meil<>lower(e_meil))
      OR (SELECT count(DISTINCT riik_id) FROM isik)<2 THEN
        RAISE EXCEPTION 'Riigi, seisundi, nime või konto seos ei vasta lähteandmetele';
    END IF;
    BEGIN
        INSERT INTO valine.Riik_sisend (riik) VALUES ('{}'::jsonb);
        RAISE EXCEPTION 'Välisesse tabelisse kirjutamine õnnestus';
    EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
    END;
    BEGIN
        INSERT INTO valine.Isik_sisend (isik) VALUES ('{}'::jsonb);
        RAISE EXCEPTION 'Välisesse tabelisse kirjutamine õnnestus';
    EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
    END;
    IF (SELECT count(*) FROM pg_extension AS e
        INNER JOIN pg_namespace AS n ON n.oid=e.extnamespace
        WHERE e.extname IN ('postgres_fdw','pgcrypto') AND n.nspname='laiendused')<>2 THEN
        RAISE EXCEPTION 'Laiendused peavad kuuluma eraldi skeemi';
    END IF;
    IF EXISTS (SELECT 1 FROM kasutajakonto AS k
        WHERE k.parool IN (SELECT jt.parool FROM valine.Isik_sisend AS a
            CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
                parool text PATH '$.parool')) AS jt))
        OR (SELECT count(DISTINCT parool) FROM kasutajakonto)<>(SELECT count(*) FROM kasutajakonto) THEN
        RAISE EXCEPTION 'Parool on salvestatud avatekstina või ilma juhusliku soolata';
    END IF;
END;
$kontroll$;
