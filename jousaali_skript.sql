-- Jõusaali treeningute infosüsteemi PostgreSQL DDL.
-- Objektide loomise järjekord arvestab välisvõtmete sõltuvusi.
-- Andmebaasi loomise näide:
-- CREATE DATABASE jousaali;
-- Seejärel käivitage käesolev skript loodud andmebaasis.

CREATE SCHEMA IF NOT EXISTS public;

CREATE DOMAIN kood_10 AS VARCHAR(10)
    CHECK (btrim(VALUE) <> '');

CREATE DOMAIN e_meil_aadress AS VARCHAR(254)
    CHECK (btrim(VALUE) <> '' AND position('@' in VALUE) > 1 AND position(' ' in VALUE) = 0);

CREATE DOMAIN raha_mitte_negatiivne AS NUMERIC(8,2)
    CHECK (VALUE >= 0);

CREATE SEQUENCE seq_treeningu_kood
    START WITH 1000
    INCREMENT BY 1;

CREATE TABLE riik (
    riigi_kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_riik PRIMARY KEY (riigi_kood),
    CONSTRAINT chk_riik_kood_not_empty CHECK (btrim(riigi_kood) <> ''),
    CONSTRAINT chk_riik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE isiku_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_isiku_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_isiku_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_isiku_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE tootaja_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tootaja_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_tootaja_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_tootaja_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE tootaja_roll (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_tootaja_roll PRIMARY KEY (kood),
    CONSTRAINT chk_tootaja_roll_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_tootaja_roll_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_tootaja_roll_kirjeldus_not_empty CHECK (kirjeldus IS NULL OR btrim(kirjeldus) <> '')
);

CREATE TABLE treeningu_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_treeningu_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningu_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE treeningu_kategooria_tyyp (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria_tyyp PRIMARY KEY (kood),
    CONSTRAINT chk_treeningu_kategooria_tyyp_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningu_kategooria_tyyp_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE treeningu_kategooria (
    kood kood_10 NOT NULL,
    treeningu_kategooria_tyyp_kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria PRIMARY KEY (kood),
    CONSTRAINT uq_treeningu_kategooria_tyyp_nimetus UNIQUE (treeningu_kategooria_tyyp_kood, nimetus),
    CONSTRAINT fk_treeningu_kategooria_tyyp FOREIGN KEY (treeningu_kategooria_tyyp_kood)
        REFERENCES treeningu_kategooria_tyyp (kood),
    CONSTRAINT chk_treeningu_kategooria_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningu_kategooria_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE isik (
    isikukood VARCHAR(20) NOT NULL,
    riigi_kood kood_10 NOT NULL,
    isiku_seisundi_liik_kood kood_10 NOT NULL,
    synni_kp DATE NOT NULL,
    reg_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutm_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    eesnimi VARCHAR(200),
    perenimi VARCHAR(200),
    elukoht VARCHAR(500),
    e_meil e_meil_aadress NOT NULL,
    CONSTRAINT pk_isik PRIMARY KEY (isikukood, riigi_kood),
    CONSTRAINT uq_isik_e_meil UNIQUE (e_meil),
    CONSTRAINT fk_isik_riik FOREIGN KEY (riigi_kood)
        REFERENCES riik (riigi_kood),
    CONSTRAINT fk_isik_seisund FOREIGN KEY (isiku_seisundi_liik_kood)
        REFERENCES isiku_seisundi_liik (kood),
    CONSTRAINT chk_isik_isikukood_not_empty CHECK (btrim(isikukood) <> ''),
    CONSTRAINT chk_isik_name_present CHECK (
        (eesnimi IS NOT NULL AND btrim(eesnimi) <> '')
        OR (perenimi IS NOT NULL AND btrim(perenimi) <> '')
    ),
    CONSTRAINT chk_isik_elukoht_not_empty CHECK (elukoht IS NULL OR btrim(elukoht) <> ''),
    CONSTRAINT chk_isik_e_meil_format CHECK (btrim(e_meil) <> '' AND position('@' in e_meil) > 1),
    CONSTRAINT chk_isik_synni_kp_range CHECK (synni_kp BETWEEN DATE '1900-01-01' AND DATE '2100-12-31'),
    CONSTRAINT chk_isik_muutm_aeg CHECK (viimase_muutm_aeg >= reg_aeg)
);

CREATE TABLE kasutajakonto (
    e_meil e_meil_aadress NOT NULL,
    parool VARCHAR(255) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_kasutajakonto PRIMARY KEY (e_meil),
    CONSTRAINT fk_kasutajakonto_isik FOREIGN KEY (e_meil)
        REFERENCES isik (e_meil),
    CONSTRAINT chk_kasutajakonto_e_meil_format CHECK (btrim(e_meil) <> '' AND position('@' in e_meil) > 1),
    CONSTRAINT chk_kasutajakonto_parool_not_empty CHECK (btrim(parool) <> '')
);

CREATE TABLE tootaja (
    e_meil e_meil_aadress NOT NULL,
    tootaja_seisundi_liik_kood kood_10 NOT NULL,
    CONSTRAINT pk_tootaja PRIMARY KEY (e_meil),
    CONSTRAINT fk_tootaja_konto FOREIGN KEY (e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_tootaja_seisund FOREIGN KEY (tootaja_seisundi_liik_kood)
        REFERENCES tootaja_seisundi_liik (kood)
);

CREATE TABLE tootaja_rolli_omamine (
    tootaja_e_meil e_meil_aadress NOT NULL,
    tootaja_roll_kood kood_10 NOT NULL,
    alguse_aeg TIMESTAMP WITH TIME ZONE NOT NULL,
    lopu_aeg TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_tootaja_rolli_omamine PRIMARY KEY (tootaja_e_meil, tootaja_roll_kood, alguse_aeg),
    CONSTRAINT fk_rolli_omamine_tootaja FOREIGN KEY (tootaja_e_meil)
        REFERENCES tootaja (e_meil),
    CONSTRAINT fk_rolli_omamine_roll FOREIGN KEY (tootaja_roll_kood)
        REFERENCES tootaja_roll (kood),
    CONSTRAINT chk_rolli_omamine_aeg CHECK (lopu_aeg IS NULL OR lopu_aeg > alguse_aeg)
);

CREATE TABLE treening (
    treeningu_kood INTEGER NOT NULL DEFAULT nextval('seq_treeningu_kood'),
    treeningu_seisundi_liik_kood kood_10 NOT NULL DEFAULT 'OOTEL',
    registreerija_e_meil e_meil_aadress NOT NULL,
    viimase_muutja_e_meil e_meil_aadress NOT NULL,
    reg_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutm_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nimetus VARCHAR(200) NOT NULL,
    kirjeldus TEXT NOT NULL,
    kestus_minutites INTEGER NOT NULL,
    maksimaalne_osalejate_arv INTEGER NOT NULL,
    vajalik_varustus TEXT NOT NULL,
    hind raha_mitte_negatiivne NOT NULL,
    CONSTRAINT pk_treening PRIMARY KEY (treeningu_kood),
    CONSTRAINT uq_treening_nimetus UNIQUE (nimetus),
    CONSTRAINT fk_treeningu_seisund FOREIGN KEY (treeningu_seisundi_liik_kood)
        REFERENCES treeningu_seisundi_liik (kood),
    CONSTRAINT fk_treeningu_registreerija FOREIGN KEY (registreerija_e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_treeningu_muutja FOREIGN KEY (viimase_muutja_e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT chk_treeningu_kood_positive CHECK (treeningu_kood > 0),
    CONSTRAINT chk_treening_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_treening_kirjeldus_not_empty CHECK (btrim(kirjeldus) <> ''),
    CONSTRAINT chk_treening_kestus_range CHECK (kestus_minutites BETWEEN 15 AND 240),
    CONSTRAINT chk_treening_osalejate_arv_positive CHECK (maksimaalne_osalejate_arv > 0),
    CONSTRAINT chk_treening_varustus_not_empty CHECK (btrim(vajalik_varustus) <> ''),
    CONSTRAINT chk_treening_hind_non_negative CHECK (hind >= 0),
    CONSTRAINT chk_treening_muutm_aeg CHECK (viimase_muutm_aeg >= reg_aeg)
);

ALTER SEQUENCE seq_treeningu_kood OWNED BY treening.treeningu_kood;

CREATE TABLE treeningu_kategooria_omamine (
    treeningu_kood INTEGER NOT NULL,
    treeningu_kategooria_kood kood_10 NOT NULL,
    CONSTRAINT pk_treeningu_kategooria_omamine PRIMARY KEY (treeningu_kood, treeningu_kategooria_kood),
    CONSTRAINT fk_kategooria_omamine_treening FOREIGN KEY (treeningu_kood)
        REFERENCES treening (treeningu_kood),
    CONSTRAINT fk_kategooria_omamine_kategooria FOREIGN KEY (treeningu_kategooria_kood)
        REFERENCES treeningu_kategooria (kood)
);

CREATE INDEX ix_isik_riik ON isik (riigi_kood);
CREATE INDEX ix_isik_seisund ON isik (isiku_seisundi_liik_kood);
CREATE INDEX ix_tootaja_seisund ON tootaja (tootaja_seisundi_liik_kood);
CREATE INDEX ix_rolli_omamine_roll ON tootaja_rolli_omamine (tootaja_roll_kood);
CREATE INDEX ix_treening_seisund ON treening (treeningu_seisundi_liik_kood);
CREATE INDEX ix_treening_registreerija ON treening (registreerija_e_meil);
CREATE INDEX ix_treening_muutja ON treening (viimase_muutja_e_meil);
CREATE INDEX ix_treeningu_kategooria_tyyp ON treeningu_kategooria (treeningu_kategooria_tyyp_kood);
CREATE INDEX ix_kategooria_omamine_kategooria ON treeningu_kategooria_omamine (treeningu_kategooria_kood);

INSERT INTO riik (riigi_kood, nimetus) VALUES
('EE', 'Eesti'),
('LV', 'Läti'),
('LT', 'Leedu')
ON CONFLICT DO NOTHING;

INSERT INTO isiku_seisundi_liik (kood, nimetus) VALUES
('KLIENT', 'Klient'),
('TOOTAJA', 'Töötaja')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_seisundi_liik (kood, nimetus) VALUES
('AKTIIVNE', 'Aktiivne'),
('PUHKUSEL', 'Puhkusel'),
('LAHKUNUD', 'Lahkunud')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_roll (kood, nimetus, kirjeldus) VALUES
('TREENER', 'Treener', 'Treener, kes registreerib ja juhib treeningute töövoogu'),
('JUHATAJA', 'Juhataja', 'Juhataja, kes vaatab aruandeid ja lõpetab treeninguid'),
('KL_HALDUR', 'Klassifikaatorite haldur', 'Klassifikaatorite haldur'),
('TOO_HALD', 'Töötajate haldur', 'Töötajate andmete haldur')
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_seisundi_liik (kood, nimetus, on_aktiivne) VALUES
('OOTEL', 'Ootel', TRUE),
('AKTIIVNE', 'Aktiivne', TRUE),
('MITTEAKT', 'Mitteaktiivne', TRUE),
('LOPPENUD', 'Lõppenud', FALSE),
('UNUSTATUD', 'Unustatud', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria_tyyp (kood, nimetus, on_aktiivne) VALUES
('GRUPP', 'Grupitreening', TRUE),
('PERS', 'Personaaltreening', TRUE),
('KARDIO', 'Kardiotreening', TRUE),
('JÕUD', 'Jõutreening', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria (kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne) VALUES
('GRUPP', 'GRUPP', 'Grupitreening', TRUE),
('PERS', 'PERS', 'Personaaltreening', TRUE),
('KARDIO', 'KARDIO', 'Kardiotreening', TRUE),
('JÕUD', 'JÕUD', 'Jõutreening', TRUE)
ON CONFLICT DO NOTHING;

WITH json_lahteandmed AS (
    SELECT '[
        {"kood": "VENITUS", "treeningu_kategooria_tyyp_kood": "GRUPP", "nimetus": "Venitustreening", "on_aktiivne": true},
        {"kood": "RING", "treeningu_kategooria_tyyp_kood": "JÕUD", "nimetus": "Ringtreening", "on_aktiivne": true}
    ]'::jsonb AS andmed
)
INSERT INTO treeningu_kategooria (kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne)
SELECT kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne
FROM json_lahteandmed,
     jsonb_to_recordset(andmed) AS r(
         kood VARCHAR(10),
         treeningu_kategooria_tyyp_kood VARCHAR(10),
         nimetus VARCHAR(200),
         on_aktiivne BOOLEAN
     )
ON CONFLICT DO NOTHING;

CREATE VIEW v_treeningud_kategooriatega AS
SELECT
    t.treeningu_kood,
    t.nimetus,
    t.kirjeldus,
    t.kestus_minutites,
    t.maksimaalne_osalejate_arv,
    t.vajalik_varustus,
    t.hind,
    t.reg_aeg,
    t.viimase_muutm_aeg,
    s.kood AS seisundi_kood,
    s.nimetus AS seisund,
    COALESCE(string_agg(tk.nimetus, ', ' ORDER BY tk.nimetus), '') AS kategooriad
FROM treening t
JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
LEFT JOIN treeningu_kategooria_omamine tko ON tko.treeningu_kood = t.treeningu_kood
LEFT JOIN treeningu_kategooria tk ON tk.kood = tko.treeningu_kategooria_kood
GROUP BY
    t.treeningu_kood, t.nimetus, t.kirjeldus, t.kestus_minutites,
    t.maksimaalne_osalejate_arv, t.vajalik_varustus, t.hind,
    t.reg_aeg, t.viimase_muutm_aeg, s.kood, s.nimetus;

CREATE VIEW v_aktiivsed_treeningud AS
SELECT *
FROM v_treeningud_kategooriatega
WHERE seisundi_kood = 'AKTIIVNE';

CREATE VIEW v_treeningute_arv_seisundi_kaupa AS
SELECT s.kood, s.nimetus, COUNT(t.treeningu_kood) AS arv
FROM treeningu_seisundi_liik s
LEFT JOIN treening t ON t.treeningu_seisundi_liik_kood = s.kood
GROUP BY s.kood, s.nimetus;

CREATE VIEW v_treeningute_arv_kategooria_kaupa AS
SELECT tk.nimetus AS kategooria, ktt.nimetus AS tyyp, COUNT(tko.treeningu_kood) AS arv
FROM treeningu_kategooria tk
JOIN treeningu_kategooria_tyyp ktt ON tk.treeningu_kategooria_tyyp_kood = ktt.kood
LEFT JOIN treeningu_kategooria_omamine tko ON tko.treeningu_kategooria_kood = tk.kood
GROUP BY tk.nimetus, ktt.nimetus;

CREATE OR REPLACE FUNCTION fn_kasutaja_tuvastamise_andmed(p_e_meil e_meil_aadress)
RETURNS TABLE (
    e_meil e_meil_aadress,
    parooli_rasi VARCHAR(255),
    on_aktiivne BOOLEAN,
    eesnimi VARCHAR(200),
    perenimi VARCHAR(200),
    rollid TEXT[]
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        k.e_meil,
        k.parool AS parooli_rasi,
        k.on_aktiivne,
        i.eesnimi,
        i.perenimi,
        COALESCE(
            array_agg(DISTINCT tro.tootaja_roll_kood)
                FILTER (WHERE tro.tootaja_roll_kood IS NOT NULL),
            ARRAY[]::TEXT[]
        ) AS rollid
    FROM kasutajakonto k
    JOIN isik i ON i.e_meil = k.e_meil
    LEFT JOIN tootaja_rolli_omamine tro
        ON tro.tootaja_e_meil = k.e_meil
       AND tro.lopu_aeg IS NULL
    WHERE k.e_meil = p_e_meil
    GROUP BY k.e_meil, k.parool, k.on_aktiivne, i.eesnimi, i.perenimi;
$$;

CREATE OR REPLACE FUNCTION fn_registreeri_treening(
    p_nimetus VARCHAR(200),
    p_kirjeldus TEXT,
    p_kestus_minutites INTEGER,
    p_maksimaalne_osalejate_arv INTEGER,
    p_vajalik_varustus TEXT,
    p_hind raha_mitte_negatiivne,
    p_treeningu_kategooria_koodid VARCHAR(10)[],
    p_registreerija_e_meil e_meil_aadress
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_treeningu_kood INTEGER;
BEGIN
    IF p_treeningu_kategooria_koodid IS NULL
       OR cardinality(p_treeningu_kategooria_koodid) = 0 THEN
        RAISE EXCEPTION 'Treeningul peab olema vähemalt üks kategooria.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM kasutajakonto k
        WHERE k.e_meil = p_registreerija_e_meil
          AND k.on_aktiivne
    ) THEN
        RAISE EXCEPTION 'Registreerija kasutajakonto puudub või ei ole aktiivne.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_treeningu_kategooria_koodid) AS valitud(kood)
        LEFT JOIN treeningu_kategooria tk ON tk.kood = valitud.kood
        WHERE tk.kood IS NULL OR NOT tk.on_aktiivne
    ) THEN
        RAISE EXCEPTION 'Treeningu kategooria puudub või ei ole aktiivne.';
    END IF;

    INSERT INTO treening (
        treeningu_seisundi_liik_kood,
        registreerija_e_meil,
        viimase_muutja_e_meil,
        nimetus,
        kirjeldus,
        kestus_minutites,
        maksimaalne_osalejate_arv,
        vajalik_varustus,
        hind
    )
    VALUES (
        'OOTEL',
        p_registreerija_e_meil,
        p_registreerija_e_meil,
        p_nimetus,
        p_kirjeldus,
        p_kestus_minutites,
        p_maksimaalne_osalejate_arv,
        p_vajalik_varustus,
        p_hind
    )
    RETURNING treeningu_kood INTO v_treeningu_kood;

    INSERT INTO treeningu_kategooria_omamine (treeningu_kood, treeningu_kategooria_kood)
    SELECT v_treeningu_kood, valitud.kood
    FROM unnest(p_treeningu_kategooria_koodid) AS valitud(kood)
    ON CONFLICT DO NOTHING;

    RETURN v_treeningu_kood;
END;
$$;

CREATE OR REPLACE FUNCTION fn_aktiveeri_treening(
    p_treeningu_kood INTEGER,
    p_muutja_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated INTEGER;
BEGIN
    UPDATE treening
    SET treeningu_seisundi_liik_kood = 'AKTIIVNE',
        viimase_muutja_e_meil = p_muutja_e_meil,
        viimase_muutm_aeg = CURRENT_TIMESTAMP
    WHERE treeningu_kood = p_treeningu_kood
      AND treeningu_seisundi_liik_kood IN ('OOTEL', 'MITTEAKT')
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Aktiveeritavat ootel või mitteaktiivset treeningut ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_lopeta_treening(
    p_treeningu_kood INTEGER,
    p_muutja_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated INTEGER;
BEGIN
    UPDATE treening
    SET treeningu_seisundi_liik_kood = 'LOPPENUD',
        viimase_muutja_e_meil = p_muutja_e_meil,
        viimase_muutm_aeg = CURRENT_TIMESTAMP
    WHERE treeningu_kood = p_treeningu_kood
      AND treeningu_seisundi_liik_kood IN ('AKTIIVNE', 'MITTEAKT')
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Lõpetatavat aktiivset või mitteaktiivset treeningut ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_treening_initial_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.treeningu_seisundi_liik_kood <> 'OOTEL' THEN
        RAISE EXCEPTION 'Treening tuleb registreerida seisundis OOTEL.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treening_initial_status
BEFORE INSERT ON treening
FOR EACH ROW
EXECUTE FUNCTION fn_treening_initial_status();

CREATE OR REPLACE FUNCTION fn_treening_status_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.treeningu_seisundi_liik_kood IS NOT DISTINCT FROM NEW.treeningu_seisundi_liik_kood THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.treeningu_seisundi_liik_kood = 'OOTEL' AND NEW.treeningu_seisundi_liik_kood IN ('AKTIIVNE', 'UNUSTATUD'))
        OR (OLD.treeningu_seisundi_liik_kood = 'AKTIIVNE' AND NEW.treeningu_seisundi_liik_kood IN ('MITTEAKT', 'LOPPENUD'))
        OR (OLD.treeningu_seisundi_liik_kood = 'MITTEAKT' AND NEW.treeningu_seisundi_liik_kood IN ('AKTIIVNE', 'LOPPENUD'))
    ) THEN
        RAISE EXCEPTION 'Treeningu lubamatu seisundimuudatus: % -> %.',
            OLD.treeningu_seisundi_liik_kood,
            NEW.treeningu_seisundi_liik_kood;
    END IF;

    IF NEW.treeningu_seisundi_liik_kood = 'AKTIIVNE'
       AND NOT EXISTS (
            SELECT 1
            FROM treeningu_kategooria_omamine tko
            WHERE tko.treeningu_kood = NEW.treeningu_kood
       ) THEN
        RAISE EXCEPTION 'Treeningut ei saa aktiveerida ilma kategooriata.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treening_status_transition
BEFORE UPDATE OF treeningu_seisundi_liik_kood ON treening
FOR EACH ROW
EXECUTE FUNCTION fn_treening_status_transition();

CREATE OR REPLACE FUNCTION fn_treening_prevent_active_categoryless()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM treening t
        WHERE t.treeningu_kood = OLD.treeningu_kood
          AND t.treeningu_seisundi_liik_kood = 'AKTIIVNE'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM treeningu_kategooria_omamine tko
        WHERE tko.treeningu_kood = OLD.treeningu_kood
    ) THEN
        RAISE EXCEPTION 'Aktiivsel treeningul peab olema vähemalt üks kategooria.';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_treening_no_active_without_category
AFTER DELETE ON treeningu_kategooria_omamine
DEFERRABLE INITIALLY IMMEDIATE
FOR EACH ROW
EXECUTE FUNCTION fn_treening_prevent_active_categoryless();

BEGIN;
INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, eesnimi, perenimi, e_meil)
VALUES ('39901010000', 'EE', 'TOOTAJA', DATE '1990-01-01', 'Test', 'Treener', 'ddl.test.treener@example.com');
INSERT INTO kasutajakonto (e_meil, parool)
VALUES ('ddl.test.treener@example.com', 'pbkdf2:sha256:test');

INSERT INTO tootaja (e_meil, tootaja_seisundi_liik_kood)
VALUES ('ddl.test.treener@example.com', 'AKTIIVNE');

INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_roll_kood, alguse_aeg)
VALUES ('ddl.test.treener@example.com', 'TREENER', CURRENT_TIMESTAMP);

SELECT *
FROM fn_kasutaja_tuvastamise_andmed('ddl.test.treener@example.com');

DO $$
DECLARE
    v_failed BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO treening (
            treeningu_seisundi_liik_kood, registreerija_e_meil, viimase_muutja_e_meil,
            nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, vajalik_varustus, hind
        )
        VALUES (
            'AKTIIVNE', 'ddl.test.treener@example.com', 'ddl.test.treener@example.com',
            'DDL vigane algseisund', 'Kontroll', 45, 10, 'Matt', 0
        );
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud algseisundi kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Algseisundi triger ei rakendunud.';
    END IF;
END $$;

INSERT INTO treening (
    registreerija_e_meil, viimase_muutja_e_meil,
    nimetus, kirjeldus, kestus_minutites, maksimaalne_osalejate_arv, vajalik_varustus, hind
)
VALUES (
    'ddl.test.treener@example.com', 'ddl.test.treener@example.com',
    'DDL trigeri kontrolltreening', 'Kontroll', 45, 10, 'Matt', 0
)
RETURNING treeningu_kood;

INSERT INTO treeningu_kategooria_omamine (treeningu_kood, treeningu_kategooria_kood)
SELECT treeningu_kood, 'GRUPP'
FROM treening
WHERE nimetus = 'DDL trigeri kontrolltreening';

UPDATE treening
SET treeningu_seisundi_liik_kood = 'AKTIIVNE',
    viimase_muutm_aeg = CURRENT_TIMESTAMP
WHERE nimetus = 'DDL trigeri kontrolltreening';

DO $$
DECLARE
    v_failed BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE treening
        SET treeningu_seisundi_liik_kood = 'UNUSTATUD'
        WHERE nimetus = 'DDL trigeri kontrolltreening';
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud seisundimuudatuse kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Seisundimuudatuse triger ei rakendunud.';
    END IF;
END $$;

DO $$
DECLARE
    v_failed BOOLEAN := FALSE;
BEGIN
    BEGIN
        DELETE FROM treeningu_kategooria_omamine
        WHERE treeningu_kood = (
            SELECT treeningu_kood
            FROM treening
            WHERE nimetus = 'DDL trigeri kontrolltreening'
        );
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud kategooria kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Aktiivse treeningu kategooria triger ei rakendunud.';
    END IF;
END $$;

DO $$
DECLARE
    v_treeningu_kood INTEGER;
    v_loppseisund VARCHAR(10);
BEGIN
    v_treeningu_kood := fn_registreeri_treening(
        'DDL rutiini kontrolltreening',
        'Kontroll',
        45,
        10,
        'Matt',
        0,
        ARRAY['GRUPP'],
        'ddl.test.treener@example.com'
    );

    PERFORM fn_aktiveeri_treening(v_treeningu_kood, 'ddl.test.treener@example.com');
    PERFORM fn_lopeta_treening(v_treeningu_kood, 'ddl.test.treener@example.com');

    SELECT treeningu_seisundi_liik_kood
    INTO v_loppseisund
    FROM treening
    WHERE treeningu_kood = v_treeningu_kood;

    IF v_loppseisund <> 'LOPPENUD' THEN
        RAISE EXCEPTION 'Rutiinide test ei jõudnud lõppseisundisse.';
    END IF;
END $$;
ROLLBACK;

ANALYZE;

EXPLAIN
SELECT *
FROM v_aktiivsed_treeningud
WHERE hind <= 20;

-- Rollid ja kasutajad.
-- Rollide loomine võib jagatud õppekeskkonnas vajada kõrgemaid õiguseid.
-- Kui rollide loomise õigus puudub, jääb andmemudel ja testandmed siiski kontrollitavaks.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jousaali_rakendus') THEN
        CREATE ROLE jousaali_rakendus NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jousaali_vaatleja') THEN
        CREATE ROLE jousaali_vaatleja NOLOGIN;
    END IF;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Rollide loomine jäeti vahele, sest käivitajal puudub CREATE ROLE õigus.';
END $$;

-- Üleliigsete õiguste äravõtmine.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- Õiguste jagamine.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jousaali_rakendus') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA public TO jousaali_rakendus';
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO jousaali_rakendus';
        EXECUTE 'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO jousaali_rakendus';
        EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO jousaali_rakendus';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jousaali_vaatleja') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA public TO jousaali_vaatleja';
        EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO jousaali_vaatleja';
        EXECUTE 'GRANT EXECUTE ON FUNCTION fn_kasutaja_tuvastamise_andmed(e_meil_aadress) TO jousaali_vaatleja';
    END IF;
END $$;

-- Andmebaasiobjektide kustutamise järjekord, kasutada ainult eraldi puhastusskriptis:
-- REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM jousaali_rakendus, jousaali_vaatleja;
-- REVOKE ALL ON ALL TABLES IN SCHEMA public FROM jousaali_rakendus, jousaali_vaatleja;
-- DROP TRIGGER trg_treening_no_active_without_category ON treening;
-- DROP TRIGGER trg_treening_status_transition ON treening;
-- DROP TRIGGER trg_treening_initial_status ON treening;
-- DROP FUNCTION fn_treening_prevent_active_categoryless();
-- DROP FUNCTION fn_treening_status_transition();
-- DROP FUNCTION fn_treening_initial_status();
-- DROP FUNCTION fn_lopeta_treening(INTEGER, e_meil_aadress);
-- DROP FUNCTION fn_aktiveeri_treening(INTEGER, e_meil_aadress);
-- DROP FUNCTION fn_registreeri_treening(VARCHAR, TEXT, INTEGER, INTEGER, TEXT, NUMERIC, kood_10[], e_meil_aadress);
-- DROP FUNCTION fn_kasutaja_tuvastamise_andmed(e_meil_aadress);
-- DROP VIEW v_treeningute_arv_kategooria_kaupa;
-- DROP VIEW v_treeningute_arv_seisundi_kaupa;
-- DROP VIEW v_aktiivsed_treeningud;
-- DROP VIEW v_treeningud_kategooriatega;
-- DROP TABLE treeningu_kategooria_omamine;
-- DROP TABLE treening;
-- DROP TABLE tootaja_rolli_omamine;
-- DROP TABLE treeningu_kategooria;
-- DROP TABLE kasutajakonto;
-- DROP TABLE tootaja;
-- DROP TABLE isik;
-- DROP TABLE treeningu_kategooria_tyyp;
-- DROP TABLE treeningu_seisundi_liik;
-- DROP TABLE tootaja_roll;
-- DROP TABLE tootaja_seisundi_liik;
-- DROP TABLE isiku_seisundi_liik;
-- DROP TABLE riik;
-- DROP SEQUENCE seq_treeningu_kood;
-- DROP DOMAIN raha_mitte_negatiivne;
-- DROP DOMAIN e_meil_aadress;
-- DROP DOMAIN kood_10;
-- DROP ROLE jousaali_rakendus;
-- DROP ROLE jousaali_vaatleja;
