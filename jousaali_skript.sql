-- Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise
-- funktsionaalse allsüsteemi PostgreSQL DDL.
--
-- Skript hoiab alles isiku, kasutajakonto ja töötaja vundamendi, kuid
-- asendab vana treeningukaardi keskse mudeli konkreetsete treeningukordade,
-- registreeringute, ootejärjekorra ja osalemise protsessiga.

CREATE SCHEMA IF NOT EXISTS public;

CREATE DOMAIN kood_10 AS VARCHAR(10)
    CHECK (btrim(VALUE) <> '');

CREATE DOMAIN e_meil_aadress AS VARCHAR(254)
    CHECK (btrim(VALUE) <> '' AND position('@' in VALUE) > 1 AND position(' ' in VALUE) = 0);

CREATE SEQUENCE seq_treeninguliigi_kood
    START WITH 1000
    INCREMENT BY 1;

CREATE SEQUENCE seq_treeningukorra_kood
    START WITH 2000
    INCREMENT BY 1;

CREATE SEQUENCE seq_registreeringu_kood
    START WITH 3000
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

CREATE TABLE treeninguliigi_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeninguliigi_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_treeninguliigi_seisundi_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeninguliigi_seisundi_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE treeningukorra_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_treeningukorra_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_treeningukorra_seisundi_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningukorra_seisundi_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE registreeringu_seisundi_liik (
    kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_registreeringu_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_registreeringu_seisundi_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_registreeringu_seisundi_nimetus_not_empty CHECK (btrim(nimetus) <> '')
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
    CONSTRAINT fk_isik_riik FOREIGN KEY (riigi_kood) REFERENCES riik (riigi_kood),
    CONSTRAINT fk_isik_seisund FOREIGN KEY (isiku_seisundi_liik_kood) REFERENCES isiku_seisundi_liik (kood),
    CONSTRAINT chk_isik_isikukood_not_empty CHECK (btrim(isikukood) <> ''),
    CONSTRAINT chk_isik_name_present CHECK (
        (eesnimi IS NOT NULL AND btrim(eesnimi) <> '')
        OR (perenimi IS NOT NULL AND btrim(perenimi) <> '')
    ),
    CONSTRAINT chk_isik_elukoht_not_empty CHECK (elukoht IS NULL OR btrim(elukoht) <> ''),
    CONSTRAINT chk_isik_synni_kp_range CHECK (synni_kp BETWEEN DATE '1900-01-01' AND DATE '2100-12-31'),
    CONSTRAINT chk_isik_muutm_aeg CHECK (viimase_muutm_aeg >= reg_aeg)
);

CREATE TABLE kasutajakonto (
    e_meil e_meil_aadress NOT NULL,
    parool VARCHAR(255) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_kasutajakonto PRIMARY KEY (e_meil),
    CONSTRAINT fk_kasutajakonto_isik FOREIGN KEY (e_meil) REFERENCES isik (e_meil),
    CONSTRAINT chk_kasutajakonto_parool_not_empty CHECK (btrim(parool) <> '')
);

CREATE TABLE klient (
    e_meil e_meil_aadress NOT NULL,
    registreerimise_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_klient PRIMARY KEY (e_meil),
    CONSTRAINT fk_klient_kasutajakonto FOREIGN KEY (e_meil) REFERENCES kasutajakonto (e_meil)
);

CREATE TABLE tootaja (
    e_meil e_meil_aadress NOT NULL,
    tootaja_seisundi_liik_kood kood_10 NOT NULL,
    CONSTRAINT pk_tootaja PRIMARY KEY (e_meil),
    CONSTRAINT fk_tootaja_konto FOREIGN KEY (e_meil) REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_tootaja_seisund FOREIGN KEY (tootaja_seisundi_liik_kood) REFERENCES tootaja_seisundi_liik (kood)
);

CREATE TABLE tootaja_rolli_omamine (
    tootaja_e_meil e_meil_aadress NOT NULL,
    tootaja_roll_kood kood_10 NOT NULL,
    alguse_aeg TIMESTAMP WITH TIME ZONE NOT NULL,
    lopu_aeg TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_tootaja_rolli_omamine PRIMARY KEY (tootaja_e_meil, tootaja_roll_kood, alguse_aeg),
    CONSTRAINT fk_rolli_omamine_tootaja FOREIGN KEY (tootaja_e_meil) REFERENCES tootaja (e_meil),
    CONSTRAINT fk_rolli_omamine_roll FOREIGN KEY (tootaja_roll_kood) REFERENCES tootaja_roll (kood),
    CONSTRAINT chk_rolli_omamine_aeg CHECK (lopu_aeg IS NULL OR lopu_aeg > alguse_aeg)
);

CREATE TABLE treeninguliik (
    treeninguliigi_kood INTEGER NOT NULL DEFAULT nextval('seq_treeninguliigi_kood'),
    nimetus VARCHAR(200) NOT NULL,
    kirjeldus TEXT,
    kestus_minutites INTEGER NOT NULL,
    vajalik_varustus TEXT,
    seisundi_kood kood_10 NOT NULL DEFAULT 'KOOST',
    registreerija_e_meil e_meil_aadress REFERENCES tootaja (e_meil),
    viimase_muutja_e_meil e_meil_aadress REFERENCES tootaja (e_meil),
    registreerimise_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutmise_aeg TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_treeninguliik PRIMARY KEY (treeninguliigi_kood),
    CONSTRAINT uq_treeninguliik_nimetus UNIQUE (nimetus),
    CONSTRAINT fk_treeninguliik_seisund FOREIGN KEY (seisundi_kood) REFERENCES treeninguliigi_seisundi_liik (kood),
    CONSTRAINT chk_treeninguliik_kood_positive CHECK (treeninguliigi_kood > 0),
    CONSTRAINT chk_treeninguliik_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_treeninguliik_kestus CHECK (kestus_minutites BETWEEN 15 AND 240),
    CONSTRAINT chk_treeninguliik_kirjeldus_not_empty CHECK (kirjeldus IS NULL OR btrim(kirjeldus) <> ''),
    CONSTRAINT chk_treeninguliik_varustus_not_empty CHECK (vajalik_varustus IS NULL OR btrim(vajalik_varustus) <> ''),
    CONSTRAINT chk_treeninguliik_muutmise_aeg CHECK (
        viimase_muutmise_aeg IS NULL OR viimase_muutmise_aeg >= registreerimise_aeg
    )
);

ALTER SEQUENCE seq_treeninguliigi_kood OWNED BY treeninguliik.treeninguliigi_kood;

CREATE TABLE treeninguliigi_kategooria_omamine (
    treeninguliigi_kood INTEGER NOT NULL,
    treeningu_kategooria_kood kood_10 NOT NULL,
    CONSTRAINT pk_treeninguliigi_kategooria_omamine PRIMARY KEY (treeninguliigi_kood, treeningu_kategooria_kood),
    CONSTRAINT fk_treeninguliigi_kategooria_liik FOREIGN KEY (treeninguliigi_kood)
        REFERENCES treeninguliik (treeninguliigi_kood),
    CONSTRAINT fk_treeninguliigi_kategooria_kategooria FOREIGN KEY (treeningu_kategooria_kood)
        REFERENCES treeningu_kategooria (kood)
);

CREATE TABLE varustus (
    varustuse_kood kood_10 NOT NULL,
    nimetus VARCHAR(100) NOT NULL,
    kirjeldus TEXT,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_varustus PRIMARY KEY (varustuse_kood),
    CONSTRAINT uq_varustus_nimetus UNIQUE (nimetus),
    CONSTRAINT chk_varustus_kood_not_empty CHECK (btrim(varustuse_kood) <> ''),
    CONSTRAINT chk_varustus_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_varustus_kirjeldus_not_empty CHECK (kirjeldus IS NULL OR btrim(kirjeldus) <> '')
);

CREATE TABLE treeninguliigi_varustuse_noue (
    treeninguliigi_kood INTEGER NOT NULL,
    varustuse_kood kood_10 NOT NULL,
    minimaalne_kogus INTEGER NOT NULL,
    on_kohustuslik BOOLEAN NOT NULL DEFAULT TRUE,
    markus TEXT,
    CONSTRAINT pk_treeninguliigi_varustuse_noue PRIMARY KEY (treeninguliigi_kood, varustuse_kood),
    CONSTRAINT fk_treeninguliigi_varustuse_noue_liik FOREIGN KEY (treeninguliigi_kood)
        REFERENCES treeninguliik (treeninguliigi_kood),
    CONSTRAINT fk_treeninguliigi_varustuse_noue_varustus FOREIGN KEY (varustuse_kood)
        REFERENCES varustus (varustuse_kood),
    CONSTRAINT chk_treeninguliigi_varustuse_noue_kogus CHECK (minimaalne_kogus > 0),
    CONSTRAINT chk_treeninguliigi_varustuse_noue_markus CHECK (markus IS NULL OR btrim(markus) <> '')
);

CREATE TABLE ruum (
    ruumi_kood kood_10 NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    asukoht VARCHAR(300),
    mahutavus INTEGER NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_ruum PRIMARY KEY (ruumi_kood),
    CONSTRAINT uq_ruum_nimetus UNIQUE (nimetus),
    CONSTRAINT chk_ruum_kood_not_empty CHECK (btrim(ruumi_kood) <> ''),
    CONSTRAINT chk_ruum_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_ruum_asukoht_not_empty CHECK (asukoht IS NULL OR btrim(asukoht) <> ''),
    CONSTRAINT chk_ruum_mahutavus_positive CHECK (mahutavus > 0)
);

CREATE TABLE ruumi_varustuse_omamine (
    ruumi_kood kood_10 NOT NULL,
    varustuse_kood kood_10 NOT NULL,
    kogus INTEGER NOT NULL,
    markus TEXT,
    CONSTRAINT pk_ruumi_varustuse_omamine PRIMARY KEY (ruumi_kood, varustuse_kood),
    CONSTRAINT fk_ruumi_varustuse_omamine_ruum FOREIGN KEY (ruumi_kood)
        REFERENCES ruum (ruumi_kood),
    CONSTRAINT fk_ruumi_varustuse_omamine_varustus FOREIGN KEY (varustuse_kood)
        REFERENCES varustus (varustuse_kood),
    CONSTRAINT chk_ruumi_varustuse_omamine_kogus CHECK (kogus > 0),
    CONSTRAINT chk_ruumi_varustuse_omamine_markus CHECK (markus IS NULL OR btrim(markus) <> '')
);

CREATE TABLE treeneri_padevus (
    tootaja_e_meil e_meil_aadress NOT NULL,
    treeninguliigi_kood INTEGER NOT NULL,
    alates DATE NOT NULL DEFAULT CURRENT_DATE,
    kuni DATE,
    CONSTRAINT pk_treeneri_padevus PRIMARY KEY (tootaja_e_meil, treeninguliigi_kood),
    CONSTRAINT fk_treeneri_padevus_tootaja FOREIGN KEY (tootaja_e_meil) REFERENCES tootaja (e_meil),
    CONSTRAINT fk_treeneri_padevus_liik FOREIGN KEY (treeninguliigi_kood) REFERENCES treeninguliik (treeninguliigi_kood),
    CONSTRAINT chk_treeneri_padevus_aeg CHECK (kuni IS NULL OR kuni >= alates)
);

CREATE TABLE treeningukord (
    treeningukorra_kood INTEGER NOT NULL DEFAULT nextval('seq_treeningukorra_kood'),
    treeninguliigi_kood INTEGER NOT NULL,
    treener_e_meil e_meil_aadress NOT NULL,
    ruumi_kood kood_10 NOT NULL,
    alguse_aeg TIMESTAMP WITH TIME ZONE NOT NULL,
    lopu_aeg TIMESTAMP WITH TIME ZONE NOT NULL,
    registreerimise_lopp TIMESTAMP WITH TIME ZONE NOT NULL,
    tyhistamise_lopp TIMESTAMP WITH TIME ZONE NOT NULL,
    maksimaalne_osalejate_arv INTEGER NOT NULL,
    seisundi_kood kood_10 NOT NULL DEFAULT 'KAVAND',
    looja_e_meil e_meil_aadress REFERENCES tootaja (e_meil),
    viimase_muutja_e_meil e_meil_aadress REFERENCES tootaja (e_meil),
    loomise_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutmise_aeg TIMESTAMP WITH TIME ZONE,
    tyhistamise_pohjus TEXT,
    CONSTRAINT pk_treeningukord PRIMARY KEY (treeningukorra_kood),
    CONSTRAINT fk_treeningukord_liik FOREIGN KEY (treeninguliigi_kood) REFERENCES treeninguliik (treeninguliigi_kood),
    CONSTRAINT fk_treeningukord_treener FOREIGN KEY (treener_e_meil) REFERENCES tootaja (e_meil),
    CONSTRAINT fk_treeningukord_ruum FOREIGN KEY (ruumi_kood) REFERENCES ruum (ruumi_kood),
    CONSTRAINT fk_treeningukord_seisund FOREIGN KEY (seisundi_kood) REFERENCES treeningukorra_seisundi_liik (kood),
    CONSTRAINT chk_treeningukord_kood_positive CHECK (treeningukorra_kood > 0),
    CONSTRAINT chk_treeningukord_aeg CHECK (alguse_aeg < lopu_aeg),
    CONSTRAINT chk_treeningukord_reg_lopp CHECK (registreerimise_lopp <= alguse_aeg),
    CONSTRAINT chk_treeningukord_tyh_lopp CHECK (tyhistamise_lopp <= alguse_aeg),
    CONSTRAINT chk_treeningukord_maht_positive CHECK (maksimaalne_osalejate_arv > 0),
    CONSTRAINT chk_treeningukord_pohjus_not_empty CHECK (tyhistamise_pohjus IS NULL OR btrim(tyhistamise_pohjus) <> ''),
    CONSTRAINT chk_treeningukord_muutmise_aeg CHECK (
        viimase_muutmise_aeg IS NULL OR viimase_muutmise_aeg >= loomise_aeg
    )
);

ALTER SEQUENCE seq_treeningukorra_kood OWNED BY treeningukord.treeningukorra_kood;

CREATE TABLE registreering (
    registreeringu_kood INTEGER NOT NULL DEFAULT nextval('seq_registreeringu_kood'),
    treeningukorra_kood INTEGER NOT NULL,
    klient_e_meil e_meil_aadress NOT NULL,
    seisundi_kood kood_10 NOT NULL,
    registreerimise_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tyhistamise_aeg TIMESTAMP WITH TIME ZONE,
    edendamise_aeg TIMESTAMP WITH TIME ZONE,
    ootejarjekorra_nr INTEGER,
    tyhistamise_pohjus TEXT,
    CONSTRAINT pk_registreering PRIMARY KEY (registreeringu_kood),
    CONSTRAINT fk_registreering_treeningukord FOREIGN KEY (treeningukorra_kood) REFERENCES treeningukord (treeningukorra_kood),
    CONSTRAINT fk_registreering_klient FOREIGN KEY (klient_e_meil) REFERENCES klient (e_meil),
    CONSTRAINT fk_registreering_seisund FOREIGN KEY (seisundi_kood) REFERENCES registreeringu_seisundi_liik (kood),
    CONSTRAINT chk_registreering_kood_positive CHECK (registreeringu_kood > 0),
    CONSTRAINT chk_registreering_ootejarjekord CHECK (
        (seisundi_kood = 'OOTEJRK' AND ootejarjekorra_nr IS NOT NULL AND ootejarjekorra_nr > 0)
        OR (seisundi_kood <> 'OOTEJRK')
    ),
    CONSTRAINT chk_registreering_tyhistamine CHECK (
        (seisundi_kood IN ('TYH_KL', 'TYH_SYS') AND tyhistamise_aeg IS NOT NULL)
        OR (seisundi_kood NOT IN ('TYH_KL', 'TYH_SYS'))
    ),
    CONSTRAINT chk_registreering_pohjus_not_empty CHECK (tyhistamise_pohjus IS NULL OR btrim(tyhistamise_pohjus) <> '')
);

ALTER SEQUENCE seq_registreeringu_kood OWNED BY registreering.registreeringu_kood;

CREATE TABLE osalemine (
    registreeringu_kood INTEGER NOT NULL,
    osales BOOLEAN NOT NULL,
    markija_e_meil e_meil_aadress NOT NULL,
    markimise_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    markus TEXT,
    CONSTRAINT pk_osalemine PRIMARY KEY (registreeringu_kood),
    CONSTRAINT fk_osalemine_registreering FOREIGN KEY (registreeringu_kood) REFERENCES registreering (registreeringu_kood),
    CONSTRAINT fk_osalemine_markija FOREIGN KEY (markija_e_meil) REFERENCES tootaja (e_meil),
    CONSTRAINT chk_osalemine_markus_not_empty CHECK (markus IS NULL OR btrim(markus) <> '')
);

CREATE INDEX ix_isik_riik ON isik (riigi_kood);
CREATE INDEX ix_isik_seisund ON isik (isiku_seisundi_liik_kood);
CREATE INDEX ix_tootaja_seisund ON tootaja (tootaja_seisundi_liik_kood);
CREATE INDEX ix_rolli_omamine_roll ON tootaja_rolli_omamine (tootaja_roll_kood);
CREATE INDEX ix_treeninguliik_seisund ON treeninguliik (seisundi_kood);
CREATE INDEX ix_treeninguliik_registreerija ON treeninguliik (registreerija_e_meil);
CREATE INDEX ix_treeninguliik_viimase_muutja ON treeninguliik (viimase_muutja_e_meil);
CREATE INDEX ix_treeninguliigi_kategooria_kategooria ON treeninguliigi_kategooria_omamine (treeningu_kategooria_kood);
CREATE INDEX ix_treeninguliigi_varustuse_noue_varustus ON treeninguliigi_varustuse_noue (varustuse_kood);
CREATE INDEX ix_ruumi_varustuse_omamine_varustus ON ruumi_varustuse_omamine (varustuse_kood);
CREATE INDEX ix_treeneri_padevus_liik ON treeneri_padevus (treeninguliigi_kood);
CREATE INDEX ix_treeningukord_liik ON treeningukord (treeninguliigi_kood);
CREATE INDEX ix_treeningukord_treener_aeg ON treeningukord (treener_e_meil, alguse_aeg, lopu_aeg);
CREATE INDEX ix_treeningukord_ruum_aeg ON treeningukord (ruumi_kood, alguse_aeg, lopu_aeg);
CREATE INDEX ix_treeningukord_seisund ON treeningukord (seisundi_kood);
CREATE INDEX ix_treeningukord_looja ON treeningukord (looja_e_meil);
CREATE INDEX ix_treeningukord_viimase_muutja ON treeningukord (viimase_muutja_e_meil);
CREATE INDEX ix_registreering_treeningukord ON registreering (treeningukorra_kood);
CREATE INDEX ix_registreering_klient ON registreering (klient_e_meil);
CREATE INDEX ix_registreering_seisund ON registreering (seisundi_kood);
CREATE INDEX ix_osalemine_markija ON osalemine (markija_e_meil);

CREATE UNIQUE INDEX uq_registreering_aktiivne_klient_kord
ON registreering (treeningukorra_kood, klient_e_meil)
WHERE seisundi_kood IN ('KINNIT', 'OOTEJRK');

CREATE UNIQUE INDEX uq_registreering_ootejarjekord
ON registreering (treeningukorra_kood, ootejarjekorra_nr)
WHERE seisundi_kood = 'OOTEJRK';

CREATE OR REPLACE FUNCTION fn_kasutajal_on_roll(
    p_e_meil e_meil_aadress,
    p_roll_kood kood_10
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM tootaja t
        JOIN tootaja_rolli_omamine tro ON tro.tootaja_e_meil = t.e_meil
        JOIN tootaja_roll tr ON tr.kood = tro.tootaja_roll_kood
        WHERE t.e_meil = p_e_meil
          AND t.tootaja_seisundi_liik_kood = 'AKTIIVNE'
          AND tr.kood = p_roll_kood
          AND tr.on_aktiivne
          AND tro.alguse_aeg <= CURRENT_TIMESTAMP
          AND (tro.lopu_aeg IS NULL OR tro.lopu_aeg > CURRENT_TIMESTAMP)
    );
$$;

CREATE OR REPLACE FUNCTION fn_on_juhataja(p_e_meil e_meil_aadress)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT fn_kasutajal_on_roll(p_e_meil, 'JUHATAJA');
$$;

CREATE OR REPLACE FUNCTION fn_on_treener(p_e_meil e_meil_aadress)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT fn_kasutajal_on_roll(p_e_meil, 'TREENER');
$$;

CREATE OR REPLACE FUNCTION fn_kasutaja_tuvastamise_andmed(p_e_meil e_meil_aadress)
RETURNS TABLE (
    e_meil e_meil_aadress,
    parooli_rasi VARCHAR(255),
    on_aktiivne BOOLEAN,
    eesnimi VARCHAR(200),
    perenimi VARCHAR(200),
    kasutaja_liik TEXT,
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
        CASE
            WHEN EXISTS (SELECT 1 FROM tootaja t WHERE t.e_meil = k.e_meil) THEN 'tootaja'
            WHEN EXISTS (SELECT 1 FROM klient kl WHERE kl.e_meil = k.e_meil) THEN 'klient'
            ELSE 'uudistaja'
        END AS kasutaja_liik,
        COALESCE(
            array_agg(DISTINCT tro.tootaja_roll_kood)
                FILTER (WHERE tro.tootaja_roll_kood IS NOT NULL),
            ARRAY[]::TEXT[]
        ) AS rollid
    FROM kasutajakonto k
    JOIN isik i ON i.e_meil = k.e_meil
    LEFT JOIN tootaja_rolli_omamine tro
        ON tro.tootaja_e_meil = k.e_meil
       AND tro.alguse_aeg <= CURRENT_TIMESTAMP
       AND (tro.lopu_aeg IS NULL OR tro.lopu_aeg > CURRENT_TIMESTAMP)
    WHERE k.e_meil = p_e_meil
    GROUP BY k.e_meil, k.parool, k.on_aktiivne, i.eesnimi, i.perenimi;
$$;

CREATE OR REPLACE FUNCTION fn_kontrolli_treeneri_padevust()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT fn_on_treener(NEW.tootaja_e_meil) THEN
        RAISE EXCEPTION 'Pädevust saab lisada ainult aktiivse TREENER rolliga töötajale.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeneri_padevus_roll
BEFORE INSERT OR UPDATE ON treeneri_padevus
FOR EACH ROW
EXECUTE FUNCTION fn_kontrolli_treeneri_padevust();

CREATE OR REPLACE FUNCTION fn_treeningukord_initial_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.seisundi_kood <> 'KAVAND' THEN
        RAISE EXCEPTION 'Treeningukord tuleb luua seisundis KAVAND.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_initial_status
BEFORE INSERT ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_treeningukord_initial_status();

CREATE OR REPLACE FUNCTION fn_treeningukord_status_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.seisundi_kood IS NOT DISTINCT FROM NEW.seisundi_kood THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.seisundi_kood = 'KAVAND' AND NEW.seisundi_kood IN ('AVATUD', 'TYHIST'))
        OR (OLD.seisundi_kood = 'AVATUD' AND NEW.seisundi_kood IN ('SULETUD', 'TYHIST'))
        OR (OLD.seisundi_kood = 'SULETUD' AND NEW.seisundi_kood IN ('TOIMUNUD', 'TYHIST'))
    ) THEN
        RAISE EXCEPTION 'Treeningukorra lubamatu seisundimuudatus: % -> %.',
            OLD.seisundi_kood,
            NEW.seisundi_kood;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_status_transition
BEFORE UPDATE OF seisundi_kood ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_treeningukord_status_transition();

CREATE OR REPLACE FUNCTION fn_ruum_sobib_treeninguliigile(
    p_ruumi_kood kood_10,
    p_treeninguliigi_kood INTEGER
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT NOT EXISTS (
        SELECT 1
        FROM treeninguliigi_varustuse_noue n
        WHERE n.treeninguliigi_kood = p_treeninguliigi_kood
          AND n.on_kohustuslik
          AND NOT EXISTS (
              SELECT 1
              FROM ruumi_varustuse_omamine rvo
              JOIN varustus v ON v.varustuse_kood = rvo.varustuse_kood
              WHERE rvo.ruumi_kood = p_ruumi_kood
                AND rvo.varustuse_kood = n.varustuse_kood
                AND rvo.kogus >= n.minimaalne_kogus
                AND v.on_aktiivne
          )
    );
$$;

CREATE OR REPLACE FUNCTION fn_kontrolli_treeningukorra_invariandid()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ruumi_mahutavus INTEGER;
BEGIN
    IF NEW.seisundi_kood = 'TYHIST' THEN
        RETURN NEW;
    END IF;

    SELECT mahutavus INTO v_ruumi_mahutavus
    FROM ruum
    WHERE ruumi_kood = NEW.ruumi_kood
      AND on_aktiivne;

    IF v_ruumi_mahutavus IS NULL THEN
        RAISE EXCEPTION 'Treeningukorra ruum puudub või ei ole aktiivne.';
    END IF;

    IF NEW.maksimaalne_osalejate_arv > v_ruumi_mahutavus THEN
        RAISE EXCEPTION 'Treeningukorra osalejate arv (%) ületab ruumi mahutavuse (%).',
            NEW.maksimaalne_osalejate_arv,
            v_ruumi_mahutavus;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM treeninguliik tl
        WHERE tl.treeninguliigi_kood = NEW.treeninguliigi_kood
          AND tl.seisundi_kood = 'AKTIIVNE'
    ) THEN
        RAISE EXCEPTION 'Treeningukorda saab planeerida ainult aktiivse treeninguliigi alusel.';
    END IF;

    IF NOT fn_on_treener(NEW.treener_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra treeneril peab olema aktiivne TREENER roll.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM treeneri_padevus tp
        WHERE tp.tootaja_e_meil = NEW.treener_e_meil
          AND tp.treeninguliigi_kood = NEW.treeninguliigi_kood
          AND tp.alates <= NEW.alguse_aeg::date
          AND (tp.kuni IS NULL OR tp.kuni >= NEW.alguse_aeg::date)
    ) THEN
        RAISE EXCEPTION 'Treeneril puudub valitud treeninguliigi kehtiv pädevus.';
    END IF;

    IF NOT fn_ruum_sobib_treeninguliigile(NEW.ruumi_kood, NEW.treeninguliigi_kood) THEN
        RAISE EXCEPTION 'Ruumis puudub treeninguliigi jaoks nõutav varustus.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM treeningukord tk
        WHERE tk.treener_e_meil = NEW.treener_e_meil
          AND tk.seisundi_kood <> 'TYHIST'
          AND (TG_OP = 'INSERT' OR tk.treeningukorra_kood <> OLD.treeningukorra_kood)
          AND NOT (NEW.lopu_aeg <= tk.alguse_aeg OR NEW.alguse_aeg >= tk.lopu_aeg)
    ) THEN
        RAISE EXCEPTION 'Treeneril on samal ajal juba teine tühistamata treeningukord.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM treeningukord tk
        WHERE tk.ruumi_kood = NEW.ruumi_kood
          AND tk.seisundi_kood <> 'TYHIST'
          AND (TG_OP = 'INSERT' OR tk.treeningukorra_kood <> OLD.treeningukorra_kood)
          AND NOT (NEW.lopu_aeg <= tk.alguse_aeg OR NEW.alguse_aeg >= tk.lopu_aeg)
    ) THEN
        RAISE EXCEPTION 'Ruumis on samal ajal juba teine tühistamata treeningukord.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_invariandid
BEFORE INSERT OR UPDATE OF treeninguliigi_kood, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg, maksimaalne_osalejate_arv, seisundi_kood
ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_kontrolli_treeningukorra_invariandid();

CREATE OR REPLACE FUNCTION fn_registreering_status_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.seisundi_kood NOT IN ('KINNIT', 'OOTEJRK') THEN
            RAISE EXCEPTION 'Registreering tuleb luua seisundis KINNIT või OOTEJRK.';
        END IF;
        RETURN NEW;
    END IF;

    IF OLD.seisundi_kood IS NOT DISTINCT FROM NEW.seisundi_kood THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.seisundi_kood = 'OOTEJRK' AND NEW.seisundi_kood IN ('KINNIT', 'TYH_KL', 'TYH_SYS'))
        OR (OLD.seisundi_kood = 'KINNIT' AND NEW.seisundi_kood IN ('TYH_KL', 'TYH_SYS'))
    ) THEN
        RAISE EXCEPTION 'Registreeringu lubamatu seisundimuudatus: % -> %.',
            OLD.seisundi_kood,
            NEW.seisundi_kood;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registreering_status_transition
BEFORE INSERT OR UPDATE OF seisundi_kood ON registreering
FOR EACH ROW
EXECUTE FUNCTION fn_registreering_status_transition();

CREATE OR REPLACE FUNCTION fn_kontrolli_osalemine()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_treeningukorra_kood INTEGER;
    v_treener_e_meil e_meil_aadress;
    v_seisundi_kood kood_10;
    v_alguse_aeg TIMESTAMP WITH TIME ZONE;
    v_reg_seisund kood_10;
BEGIN
    SELECT r.treeningukorra_kood, r.seisundi_kood, tk.treener_e_meil, tk.seisundi_kood, tk.alguse_aeg
    INTO v_treeningukorra_kood, v_reg_seisund, v_treener_e_meil, v_seisundi_kood, v_alguse_aeg
    FROM registreering r
    JOIN treeningukord tk ON tk.treeningukorra_kood = r.treeningukorra_kood
    WHERE r.registreeringu_kood = NEW.registreeringu_kood;

    IF v_reg_seisund <> 'KINNIT' THEN
        RAISE EXCEPTION 'Osalemist saab märkida ainult kinnitatud registreeringule.';
    END IF;

    IF v_seisundi_kood NOT IN ('SULETUD', 'TOIMUNUD') THEN
        RAISE EXCEPTION 'Osalemist saab märkida ainult suletud või toimunud treeningukorrale.';
    END IF;

    IF v_alguse_aeg > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Osalemist ei saa märkida enne treeningukorra algust.';
    END IF;

    IF NEW.markija_e_meil <> v_treener_e_meil AND NOT fn_on_juhataja(NEW.markija_e_meil) THEN
        RAISE EXCEPTION 'Osalemist saab märkida ainult määratud treener või juhataja.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_osalemine_kontroll
BEFORE INSERT OR UPDATE ON osalemine
FOR EACH ROW
EXECUTE FUNCTION fn_kontrolli_osalemine();

CREATE OR REPLACE FUNCTION fn_planeeri_treeningukord(
    p_treeninguliigi_kood INTEGER,
    p_treener_e_meil e_meil_aadress,
    p_ruumi_kood kood_10,
    p_alguse_aeg TIMESTAMP WITH TIME ZONE,
    p_lopu_aeg TIMESTAMP WITH TIME ZONE,
    p_registreerimise_lopp TIMESTAMP WITH TIME ZONE,
    p_tyhistamise_lopp TIMESTAMP WITH TIME ZONE,
    p_maksimaalne_osalejate_arv INTEGER,
    p_juhataja_e_meil e_meil_aadress
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_treeningukorra_kood INTEGER;
BEGIN
    IF NOT fn_on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra planeerimiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    INSERT INTO treeningukord (
        treeninguliigi_kood,
        treener_e_meil,
        ruumi_kood,
        alguse_aeg,
        lopu_aeg,
        registreerimise_lopp,
        tyhistamise_lopp,
        maksimaalne_osalejate_arv,
        seisundi_kood,
        looja_e_meil,
        viimase_muutja_e_meil
    )
    VALUES (
        p_treeninguliigi_kood,
        p_treener_e_meil,
        p_ruumi_kood,
        p_alguse_aeg,
        p_lopu_aeg,
        p_registreerimise_lopp,
        p_tyhistamise_lopp,
        p_maksimaalne_osalejate_arv,
        'KAVAND',
        p_juhataja_e_meil,
        p_juhataja_e_meil
    )
    RETURNING treeningukorra_kood INTO v_treeningukorra_kood;

    RETURN v_treeningukorra_kood;
END;
$$;

CREATE OR REPLACE FUNCTION fn_ava_treeningukord(
    p_treeningukorra_kood INTEGER,
    p_juhataja_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_updated INTEGER;
BEGIN
    IF NOT fn_on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra avamiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    UPDATE treeningukord
    SET seisundi_kood = 'AVATUD',
        viimase_muutja_e_meil = p_juhataja_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP
    WHERE treeningukorra_kood = p_treeningukorra_kood
      AND seisundi_kood = 'KAVAND'
      AND alguse_aeg > CURRENT_TIMESTAMP
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Avatavat tulevast kavandatud treeningukorda ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sulge_treeningukord(
    p_treeningukorra_kood INTEGER,
    p_actor_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_treener_e_meil e_meil_aadress;
    v_reg_lopp TIMESTAMP WITH TIME ZONE;
    v_updated INTEGER;
BEGIN
    SELECT treener_e_meil, registreerimise_lopp
    INTO v_treener_e_meil, v_reg_lopp
    FROM treeningukord
    WHERE treeningukorra_kood = p_treeningukorra_kood;

    IF v_treener_e_meil IS NULL THEN
        RAISE EXCEPTION 'Suletavat treeningukorda ei leitud.';
    END IF;

    IF p_actor_e_meil <> v_treener_e_meil AND NOT fn_on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra saab sulgeda määratud treener või juhataja.';
    END IF;

    IF CURRENT_TIMESTAMP < v_reg_lopp AND NOT fn_on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treener saab treeningukorra sulgeda alles pärast registreerimise lõppu.';
    END IF;

    UPDATE treeningukord
    SET seisundi_kood = 'SULETUD',
        viimase_muutja_e_meil = p_actor_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP
    WHERE treeningukorra_kood = p_treeningukorra_kood
      AND seisundi_kood = 'AVATUD'
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Suletavat avatud treeningukorda ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_lopeta_treeningukord(
    p_treeningukorra_kood INTEGER,
    p_actor_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_treener_e_meil e_meil_aadress;
    v_updated INTEGER;
BEGIN
    SELECT treener_e_meil
    INTO v_treener_e_meil
    FROM treeningukord
    WHERE treeningukorra_kood = p_treeningukorra_kood;

    IF v_treener_e_meil IS NULL THEN
        RAISE EXCEPTION 'Lõpetatavat treeningukorda ei leitud.';
    END IF;

    IF p_actor_e_meil <> v_treener_e_meil AND NOT fn_on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra saab toimunuks märkida määratud treener või juhataja.';
    END IF;

    UPDATE treeningukord
    SET seisundi_kood = 'TOIMUNUD',
        viimase_muutja_e_meil = p_actor_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP
    WHERE treeningukorra_kood = p_treeningukorra_kood
      AND seisundi_kood = 'SULETUD'
      AND lopu_aeg <= CURRENT_TIMESTAMP
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Toimunuks saab märkida ainult lõppenud suletud treeningukorra.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_registreeri_klient_treeningukorrale(
    p_treeningukorra_kood INTEGER,
    p_klient_e_meil e_meil_aadress
)
RETURNS TABLE (
    registreeringu_kood INTEGER,
    seisundi_kood kood_10,
    ootejarjekorra_nr INTEGER,
    teade TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_kord treeningukord%ROWTYPE;
    v_kinnitatud_arv INTEGER;
    v_ootejarjekorra_nr INTEGER;
BEGIN
    SELECT *
    INTO v_kord
    FROM treeningukord
    WHERE treeningukord.treeningukorra_kood = p_treeningukorra_kood
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Treeningukorda ei leitud.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM klient k
        JOIN kasutajakonto kk ON kk.e_meil = k.e_meil
        WHERE k.e_meil = p_klient_e_meil
          AND k.on_aktiivne
          AND kk.on_aktiivne
    ) THEN
        RAISE EXCEPTION 'Klient puudub või ei ole aktiivne.';
    END IF;

    IF v_kord.seisundi_kood <> 'AVATUD' THEN
        RAISE EXCEPTION 'Registreerida saab ainult avatud treeningukorrale.';
    END IF;

    IF CURRENT_TIMESTAMP > v_kord.registreerimise_lopp THEN
        RAISE EXCEPTION 'Registreerimise tähtaeg on möödunud.';
    END IF;

    SELECT COUNT(*)
    INTO v_kinnitatud_arv
    FROM registreering r
    WHERE r.treeningukorra_kood = p_treeningukorra_kood
      AND r.seisundi_kood = 'KINNIT';

    IF v_kinnitatud_arv < v_kord.maksimaalne_osalejate_arv THEN
        INSERT INTO registreering (treeningukorra_kood, klient_e_meil, seisundi_kood)
        VALUES (p_treeningukorra_kood, p_klient_e_meil, 'KINNIT')
        RETURNING registreering.registreeringu_kood INTO registreeringu_kood;

        seisundi_kood := 'KINNIT';
        ootejarjekorra_nr := NULL;
        teade := 'Registreering kinnitati.';
        RETURN NEXT;
    ELSE
        SELECT COALESCE(MAX(r.ootejarjekorra_nr), 0) + 1
        INTO v_ootejarjekorra_nr
        FROM registreering r
        WHERE r.treeningukorra_kood = p_treeningukorra_kood
          AND r.seisundi_kood = 'OOTEJRK';

        INSERT INTO registreering (
            treeningukorra_kood,
            klient_e_meil,
            seisundi_kood,
            ootejarjekorra_nr
        )
        VALUES (p_treeningukorra_kood, p_klient_e_meil, 'OOTEJRK', v_ootejarjekorra_nr)
        RETURNING registreering.registreeringu_kood INTO registreeringu_kood;

        seisundi_kood := 'OOTEJRK';
        ootejarjekorra_nr := v_ootejarjekorra_nr;
        teade := 'Treeningukord on täis. Klient lisati ootejärjekorda.';
        RETURN NEXT;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_edenda_ootejarjekorrast(
    p_treeningukorra_kood INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_kord treeningukord%ROWTYPE;
    v_promote_id INTEGER;
    v_kinnitatud_arv INTEGER;
BEGIN
    SELECT *
    INTO v_kord
    FROM treeningukord tk
    WHERE tk.treeningukorra_kood = p_treeningukorra_kood
    FOR UPDATE;

    IF NOT FOUND OR v_kord.seisundi_kood <> 'AVATUD' THEN
        RETURN NULL;
    END IF;

    SELECT COUNT(*)
    INTO v_kinnitatud_arv
    FROM registreering r
    WHERE r.treeningukorra_kood = p_treeningukorra_kood
      AND r.seisundi_kood = 'KINNIT';

    IF v_kinnitatud_arv >= v_kord.maksimaalne_osalejate_arv THEN
        RETURN NULL;
    END IF;

    SELECT r.registreeringu_kood
    INTO v_promote_id
    FROM registreering r
    WHERE r.treeningukorra_kood = p_treeningukorra_kood
      AND r.seisundi_kood = 'OOTEJRK'
    ORDER BY r.ootejarjekorra_nr NULLS LAST, r.registreerimise_aeg, r.registreeringu_kood
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_promote_id IS NULL THEN
        RETURN NULL;
    END IF;

    UPDATE registreering
    SET seisundi_kood = 'KINNIT',
        edendamise_aeg = CURRENT_TIMESTAMP,
        ootejarjekorra_nr = NULL
    WHERE registreering.registreeringu_kood = v_promote_id;

    RETURN v_promote_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_tyhista_registreering(
    p_registreeringu_kood INTEGER,
    p_actor_e_meil e_meil_aadress,
    p_pohjus TEXT DEFAULT NULL
)
RETURNS TABLE (
    tyhistatud_registreeringu_kood INTEGER,
    edendatud_registreeringu_kood INTEGER,
    teade TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_reg registreering%ROWTYPE;
    v_kord treeningukord%ROWTYPE;
    v_uus_seisund kood_10;
    v_edendatud INTEGER;
BEGIN
    SELECT *
    INTO v_reg
    FROM registreering r
    WHERE r.registreeringu_kood = p_registreeringu_kood
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Registreeringut ei leitud.';
    END IF;

    SELECT *
    INTO v_kord
    FROM treeningukord tk
    WHERE tk.treeningukorra_kood = v_reg.treeningukorra_kood
    FOR UPDATE;

    IF v_reg.seisundi_kood NOT IN ('KINNIT', 'OOTEJRK') THEN
        RAISE EXCEPTION 'Tühistada saab ainult aktiivset registreeringut.';
    END IF;

    IF v_kord.seisundi_kood IN ('TOIMUNUD', 'TYHIST') THEN
        RAISE EXCEPTION 'Toimunud või tühistatud treeningukorra registreeringut ei saa kliendi kaudu tühistada.';
    END IF;

    IF fn_on_juhataja(p_actor_e_meil) THEN
        v_uus_seisund := 'TYH_SYS';
    ELSE
        IF p_actor_e_meil <> v_reg.klient_e_meil THEN
            RAISE EXCEPTION 'Klient saab tühistada ainult enda registreeringu.';
        END IF;
        IF CURRENT_TIMESTAMP > v_kord.tyhistamise_lopp THEN
            RAISE EXCEPTION 'Tühistamise tähtaeg on möödunud.';
        END IF;
        v_uus_seisund := 'TYH_KL';
    END IF;

    UPDATE registreering
    SET seisundi_kood = v_uus_seisund,
        tyhistamise_aeg = CURRENT_TIMESTAMP,
        tyhistamise_pohjus = p_pohjus
    WHERE registreering.registreeringu_kood = p_registreeringu_kood;

    IF v_reg.seisundi_kood = 'KINNIT' AND v_uus_seisund = 'TYH_KL' THEN
        v_edendatud := fn_edenda_ootejarjekorrast(v_reg.treeningukorra_kood);
    ELSE
        v_edendatud := NULL;
    END IF;

    tyhistatud_registreeringu_kood := p_registreeringu_kood;
    edendatud_registreeringu_kood := v_edendatud;
    teade := CASE
        WHEN v_edendatud IS NULL THEN 'Registreering tühistati.'
        ELSE 'Registreering tühistati ja esimene ootel klient edendati kinnitatuks.'
    END;
    RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION fn_marki_osalemine(
    p_registreeringu_kood INTEGER,
    p_markija_e_meil e_meil_aadress,
    p_osales BOOLEAN,
    p_markus TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO osalemine (
        registreeringu_kood,
        osales,
        markija_e_meil,
        markus
    )
    VALUES (
        p_registreeringu_kood,
        p_osales,
        p_markija_e_meil,
        p_markus
    )
    ON CONFLICT (registreeringu_kood)
    DO UPDATE SET
        osales = EXCLUDED.osales,
        markija_e_meil = EXCLUDED.markija_e_meil,
        markimise_aeg = CURRENT_TIMESTAMP,
        markus = EXCLUDED.markus;
END;
$$;

CREATE OR REPLACE FUNCTION fn_tyhista_treeningukord(
    p_treeningukorra_kood INTEGER,
    p_juhataja_e_meil e_meil_aadress,
    p_pohjus TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_affected INTEGER;
    v_updated INTEGER;
BEGIN
    IF NOT fn_on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra tühistamiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    UPDATE treeningukord
    SET seisundi_kood = 'TYHIST',
        viimase_muutja_e_meil = p_juhataja_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP,
        tyhistamise_pohjus = p_pohjus
    WHERE treeningukorra_kood = p_treeningukorra_kood
      AND seisundi_kood IN ('KAVAND', 'AVATUD', 'SULETUD')
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Tühistatavat kavandatud, avatud või suletud treeningukorda ei leitud.';
    END IF;

    UPDATE registreering
    SET seisundi_kood = 'TYH_SYS',
        tyhistamise_aeg = CURRENT_TIMESTAMP,
        tyhistamise_pohjus = COALESCE(p_pohjus, 'Treeningukord tühistati.')
    WHERE treeningukorra_kood = p_treeningukorra_kood
      AND seisundi_kood IN ('KINNIT', 'OOTEJRK');

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN v_affected;
END;
$$;

CREATE VIEW v_treeninguliigid_kategooriatega AS
SELECT
    tl.treeninguliigi_kood,
    tl.nimetus,
    tl.kirjeldus,
    tl.kestus_minutites,
    tl.vajalik_varustus,
    tl.seisundi_kood,
    COALESCE(string_agg(tk.nimetus, ', ' ORDER BY tk.nimetus), '') AS kategooriad
FROM treeninguliik tl
LEFT JOIN treeninguliigi_kategooria_omamine tlko ON tlko.treeninguliigi_kood = tl.treeninguliigi_kood
LEFT JOIN treeningu_kategooria tk ON tk.kood = tlko.treeningu_kategooria_kood
GROUP BY tl.treeninguliigi_kood, tl.nimetus, tl.kirjeldus, tl.kestus_minutites, tl.vajalik_varustus, tl.seisundi_kood;

CREATE VIEW v_treeninguliigi_varustuse_nouded AS
SELECT
    tl.treeninguliigi_kood,
    tl.nimetus AS treeninguliik,
    n.varustuse_kood,
    v.nimetus AS varustus,
    n.minimaalne_kogus,
    n.on_kohustuslik,
    n.markus
FROM treeninguliigi_varustuse_noue n
JOIN treeninguliik tl ON tl.treeninguliigi_kood = n.treeninguliigi_kood
JOIN varustus v ON v.varustuse_kood = n.varustuse_kood;

CREATE VIEW v_ruumide_varustus AS
SELECT
    r.ruumi_kood,
    r.nimetus AS ruum,
    r.mahutavus,
    v.varustuse_kood,
    v.nimetus AS varustus,
    rvo.kogus,
    rvo.markus
FROM ruumi_varustuse_omamine rvo
JOIN ruum r ON r.ruumi_kood = rvo.ruumi_kood
JOIN varustus v ON v.varustuse_kood = rvo.varustuse_kood;

CREATE VIEW v_juhataja_treeningukordade_ulevaade AS
SELECT
    tk.treeningukorra_kood,
    tk.seisundi_kood,
    tl.nimetus AS treeninguliik,
    tk.alguse_aeg,
    tk.lopu_aeg,
    tk.registreerimise_lopp,
    tk.tyhistamise_lopp,
    r.nimetus AS ruum,
    r.mahutavus AS ruumi_mahutavus,
    tk.maksimaalne_osalejate_arv,
    tr.e_meil AS treener_e_meil,
    concat_ws(' ', i.eesnimi, i.perenimi) AS treener_nimi,
    COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'KINNIT') AS kinnitatud_arv,
    COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'OOTEJRK') AS ootejarjekorra_arv,
    GREATEST(
        tk.maksimaalne_osalejate_arv - COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'KINNIT'),
        0
    ) AS vabu_kohti
FROM treeningukord tk
JOIN treeninguliik tl ON tl.treeninguliigi_kood = tk.treeninguliigi_kood
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN tootaja tr ON tr.e_meil = tk.treener_e_meil
JOIN kasutajakonto kk ON kk.e_meil = tr.e_meil
JOIN isik i ON i.e_meil = kk.e_meil
LEFT JOIN registreering reg ON reg.treeningukorra_kood = tk.treeningukorra_kood
GROUP BY tk.treeningukorra_kood, tk.seisundi_kood, tl.nimetus, tk.alguse_aeg, tk.lopu_aeg,
         tk.registreerimise_lopp, tk.tyhistamise_lopp, r.nimetus, r.mahutavus,
         tk.maksimaalne_osalejate_arv, tr.e_meil, i.eesnimi, i.perenimi;

CREATE VIEW v_avalikud_treeningukorrad AS
SELECT *
FROM v_juhataja_treeningukordade_ulevaade
WHERE seisundi_kood = 'AVATUD'
  AND registreerimise_lopp >= CURRENT_TIMESTAMP;

CREATE VIEW v_kliendi_registreeringud AS
SELECT
    reg.registreeringu_kood,
    reg.klient_e_meil,
    reg.treeningukorra_kood,
    reg.seisundi_kood AS registreeringu_seisundi_kood,
    reg.ootejarjekorra_nr,
    reg.registreerimise_aeg,
    reg.tyhistamise_aeg,
    reg.edendamise_aeg,
    tl.nimetus AS treeninguliik,
    tk.alguse_aeg,
    tk.lopu_aeg,
    tk.seisundi_kood AS treeningukorra_seisundi_kood,
    r.nimetus AS ruum,
    concat_ws(' ', i.eesnimi, i.perenimi) AS treener_nimi,
    tk.treener_e_meil,
    os.osales,
    os.markimise_aeg
FROM registreering reg
JOIN treeningukord tk ON tk.treeningukorra_kood = reg.treeningukorra_kood
JOIN treeninguliik tl ON tl.treeninguliigi_kood = tk.treeninguliigi_kood
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN isik i ON i.e_meil = tk.treener_e_meil
LEFT JOIN osalemine os ON os.registreeringu_kood = reg.registreeringu_kood;

CREATE VIEW v_treeneri_tunniplaan AS
SELECT
    u.*
FROM v_juhataja_treeningukordade_ulevaade u
JOIN treeningukord tk ON tk.treeningukorra_kood = u.treeningukorra_kood;

CREATE VIEW v_treeningukorra_osalejad AS
SELECT
    reg.registreeringu_kood,
    reg.treeningukorra_kood,
    reg.klient_e_meil,
    concat_ws(' ', i.eesnimi, i.perenimi) AS klient_nimi,
    reg.seisundi_kood AS registreeringu_seisundi_kood,
    reg.ootejarjekorra_nr,
    reg.registreerimise_aeg,
    os.osales,
    os.markija_e_meil,
    os.markimise_aeg,
    os.markus
FROM registreering reg
JOIN klient k ON k.e_meil = reg.klient_e_meil
JOIN isik i ON i.e_meil = k.e_meil
LEFT JOIN osalemine os ON os.registreeringu_kood = reg.registreeringu_kood;

CREATE VIEW v_treeningute_taituvuse_statistika AS
SELECT
    tl.treeninguliigi_kood,
    tl.nimetus AS treeninguliik,
    COUNT(tk.treeningukorra_kood) AS treeningukordade_arv,
    COUNT(tk.treeningukorra_kood) FILTER (WHERE tk.seisundi_kood = 'AVATUD') AS avatud_arv,
    COUNT(tk.treeningukorra_kood) FILTER (WHERE tk.seisundi_kood = 'TOIMUNUD') AS toimunud_arv,
    COALESCE(SUM(tk.maksimaalne_osalejate_arv), 0) AS kohti_kokku,
    COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'KINNIT') AS kinnitatud_arv,
    COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'OOTEJRK') AS ootejarjekorra_arv,
    ROUND(
        CASE WHEN COALESCE(SUM(tk.maksimaalne_osalejate_arv), 0) = 0 THEN 0
             ELSE COUNT(reg.registreeringu_kood) FILTER (WHERE reg.seisundi_kood = 'KINNIT')::numeric
                  / SUM(tk.maksimaalne_osalejate_arv)::numeric * 100
        END,
        1
    ) AS taituvus_protsent
FROM treeninguliik tl
LEFT JOIN treeningukord tk ON tk.treeninguliigi_kood = tl.treeninguliigi_kood
LEFT JOIN registreering reg ON reg.treeningukorra_kood = tk.treeningukorra_kood
GROUP BY tl.treeninguliigi_kood, tl.nimetus;

COMMENT ON TABLE treeninguliik IS 'Korduv rühmatreeningu tüüp ehk mall, mille alusel planeeritakse konkreetsed treeningukorrad.';
COMMENT ON TABLE treeningukord IS 'Konkreetne kalendris toimuv rühmatreening koos ruumi, treeneri, tähtaegade ja mahupiiranguga.';
COMMENT ON TABLE registreering IS 'Kliendi kinnitatud või ootejärjekorras registreering treeningukorrale.';
COMMENT ON TABLE osalemine IS 'Treeningukorra kohalolu tulemus kinnitatud registreeringu kohta.';
COMMENT ON TABLE treeneri_padevus IS 'Seos, mis määrab, milliseid treeninguliike treener võib juhendada.';
COMMENT ON TABLE varustus IS 'Rühmatreeningu läbiviimiseks vajalik toetav põhiandmete tabel.';
COMMENT ON TABLE ruumi_varustuse_omamine IS 'Seos, mis näitab, milline varustus ja millises koguses on ruumis olemas.';
COMMENT ON TABLE treeninguliigi_varustuse_noue IS 'Treeninguliigi kohustuslikud ja soovituslikud varustuse nõuded.';

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
('TREENER', 'Treener', 'Treener, kes näeb enda treeningukordi ja märgib osalemist.'),
('JUHATAJA', 'Juhataja', 'Juhataja, kes planeerib, avab, tühistab ja analüüsib treeningukordi.'),
('KL_HALDUR', 'Klassifikaatorite haldur', 'Klassifikaatorite haldur.'),
('TOO_HALD', 'Töötajate haldur', 'Töötajate andmete haldur.')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliigi_seisundi_liik (kood, nimetus, on_aktiivne) VALUES
('KOOST', 'Koostamisel', TRUE),
('AKTIIVNE', 'Aktiivne', TRUE),
('MITTEAKT', 'Mitteaktiivne', TRUE),
('LOPETATUD', 'Lõpetatud', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningukorra_seisundi_liik (kood, nimetus, on_aktiivne, kirjeldus) VALUES
('KAVAND', 'Kavandatud', TRUE, 'Treeningukord on planeeritud, kuid registreerimine ei ole avatud.'),
('AVATUD', 'Registreerimiseks avatud', TRUE, 'Klient saab registreeruda või sattuda ootejärjekorda.'),
('SULETUD', 'Suletud', TRUE, 'Registreerimine on lõppenud ja treener saab kohalolu märkida.'),
('TOIMUNUD', 'Toimunud', FALSE, 'Treeningukord on lõpetatud.'),
('TYHIST', 'Tühistatud', FALSE, 'Treeningukord tühistati.')
ON CONFLICT DO NOTHING;

INSERT INTO registreeringu_seisundi_liik (kood, nimetus, on_aktiivne, kirjeldus) VALUES
('KINNIT', 'Kinnitatud', TRUE, 'Klient on treeningukorra osalejate hulgas.'),
('OOTEJRK', 'Ootejärjekorras', TRUE, 'Treeningukord on täis ja klient ootab vaba kohta.'),
('TYH_KL', 'Kliendi poolt tühistatud', FALSE, 'Klient tühistas enda aktiivse registreeringu.'),
('TYH_SYS', 'Süsteemi poolt tühistatud', FALSE, 'Registreering tühistati treeningukorra või juhataja otsuse tõttu.')
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria_tyyp (kood, nimetus, on_aktiivne) VALUES
('GRUPP', 'Rühmatreening', TRUE),
('TASE', 'Raskusaste', TRUE),
('FOOKUS', 'Treeningu fookus', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria (kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne) VALUES
('JOOGA', 'GRUPP', 'Jooga', TRUE),
('HIIT', 'GRUPP', 'HIIT', TRUE),
('JOUD', 'FOOKUS', 'Jõutreening', TRUE),
('ALG', 'TASE', 'Algajatele', TRUE),
('EDAS', 'TASE', 'Edasijõudnutele', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, eesnimi, perenimi, e_meil)
VALUES
('39001010001', 'EE', 'TOOTAJA', DATE '1990-01-01', 'Anna', 'Juhataja', 'juhataja@jousaal.ee'),
('38802020002', 'EE', 'TOOTAJA', DATE '1988-02-02', 'Tristan', 'Treener', 'treener@jousaal.ee'),
('39203030003', 'EE', 'TOOTAJA', DATE '1992-03-03', 'Liis', 'Treener', 'treener2@jousaal.ee'),
('39504040004', 'EE', 'KLIENT', DATE '1995-04-04', 'Andres', 'Klient', 'klient@jousaal.ee'),
('39605050005', 'EE', 'KLIENT', DATE '1996-05-05', 'Kärt', 'Klient', 'klient2@jousaal.ee'),
('39706060006', 'EE', 'KLIENT', DATE '1997-06-06', 'Mati', 'Klient', 'klient3@jousaal.ee'),
('39807070007', 'EE', 'KLIENT', DATE '1998-07-07', 'Mari', 'Klient', 'klient4@jousaal.ee')
ON CONFLICT DO NOTHING;

INSERT INTO kasutajakonto (e_meil, parool, on_aktiivne)
VALUES
('juhataja@jousaal.ee', 'pbkdf2:sha256:600000$NGnXTK9mS91J7f0j$584635e60de4cf6f7c5118e432d070a6c8637293d1d0e883f09804c42f947391', TRUE),
('treener@jousaal.ee', 'pbkdf2:sha256:600000$qGrjekABIBB0g8pG$4272ce1a72ccbac241b1495117c3d283d55c610f1bc07b94ac360f92fd46a5f8', TRUE),
('treener2@jousaal.ee', 'pbkdf2:sha256:600000$qGrjekABIBB0g8pG$4272ce1a72ccbac241b1495117c3d283d55c610f1bc07b94ac360f92fd46a5f8', TRUE),
('klient@jousaal.ee', 'pbkdf2:sha256:600000$B5iUw7q4jcv37X7p$4ed6374c3e1c0ef86063fa0a1033a4fcf780b5476a769a2b8bb19f89fbfbc1b2', TRUE),
('klient2@jousaal.ee', 'pbkdf2:sha256:600000$B5iUw7q4jcv37X7p$4ed6374c3e1c0ef86063fa0a1033a4fcf780b5476a769a2b8bb19f89fbfbc1b2', TRUE),
('klient3@jousaal.ee', 'pbkdf2:sha256:600000$B5iUw7q4jcv37X7p$4ed6374c3e1c0ef86063fa0a1033a4fcf780b5476a769a2b8bb19f89fbfbc1b2', TRUE),
('klient4@jousaal.ee', 'pbkdf2:sha256:600000$B5iUw7q4jcv37X7p$4ed6374c3e1c0ef86063fa0a1033a4fcf780b5476a769a2b8bb19f89fbfbc1b2', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO klient (e_meil)
VALUES
('klient@jousaal.ee'),
('klient2@jousaal.ee'),
('klient3@jousaal.ee'),
('klient4@jousaal.ee')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja (e_meil, tootaja_seisundi_liik_kood)
VALUES
('juhataja@jousaal.ee', 'AKTIIVNE'),
('treener@jousaal.ee', 'AKTIIVNE'),
('treener2@jousaal.ee', 'AKTIIVNE')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_roll_kood, alguse_aeg)
VALUES
('juhataja@jousaal.ee', 'JUHATAJA', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener2@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliik (
    treeninguliigi_kood,
    nimetus,
    kirjeldus,
    kestus_minutites,
    vajalik_varustus,
    seisundi_kood,
    registreerija_e_meil,
    viimase_muutja_e_meil
)
VALUES
(1000, 'Jooga algajatele', 'Rahulik rühmatreening liikuvuse ja hingamise arendamiseks.', 60, 'Matid ja joogaplokid', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1001, 'HIIT rühmatreening', 'Kõrge intensiivsusega intervalltreening väikesele grupile.', 45, 'Matid, hantlid ja stopper', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1002, 'Jõutreeningu tehnika', 'Rühmatund jõusaali põhiharjutuste tehnika õppimiseks.', 75, 'Kangid ja kettad', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
ON CONFLICT DO NOTHING;

SELECT setval('seq_treeninguliigi_kood', GREATEST((SELECT COALESCE(MAX(treeninguliigi_kood), 999) FROM treeninguliik), 999), TRUE);

INSERT INTO treeninguliigi_kategooria_omamine (treeninguliigi_kood, treeningu_kategooria_kood)
VALUES
(1000, 'JOOGA'),
(1000, 'ALG'),
(1001, 'HIIT'),
(1001, 'EDAS'),
(1002, 'JOUD'),
(1002, 'ALG')
ON CONFLICT DO NOTHING;

INSERT INTO varustus (varustuse_kood, nimetus, kirjeldus, on_aktiivne)
VALUES
('MATID', 'Treeningmatid', 'Rühmatreeningu matid põrandaharjutusteks.', TRUE),
('HANTLID', 'Hantlid', 'Väikese grupi jõuharjutuste hantlid.', TRUE),
('KANGID', 'Kangid', 'Jõutreeningu tehnika harjutuste kangid.', TRUE),
('EKRAAN', 'Ekraan või projektor', 'Juhendvideo või ajakava kuvamiseks kasutatav ekraan.', TRUE),
('RATTAD', 'Spinningurattad', 'Statsionaarsed rattad rattatreeninguks.', TRUE),
('PALLID', 'Võimlemispallid', 'Tasakaalu- ja kereharjutuste pallid.', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliigi_varustuse_noue (
    treeninguliigi_kood,
    varustuse_kood,
    minimaalne_kogus,
    on_kohustuslik,
    markus
)
VALUES
(1000, 'MATID', 6, TRUE, 'Joogatund vajab igale osalejale matti.'),
(1000, 'EKRAAN', 1, FALSE, 'Soovituslik juhendmaterjali kuvamiseks.'),
(1001, 'MATID', 2, TRUE, 'HIIT kasutab põrandaharjutusi.'),
(1001, 'HANTLID', 2, TRUE, 'HIIT tunnis kasutatakse hantleid.'),
(1002, 'KANGID', 4, TRUE, 'Jõutreeningu tehnika tunnis kasutatakse kange.')
ON CONFLICT DO NOTHING;

INSERT INTO ruum (ruumi_kood, nimetus, asukoht, mahutavus)
VALUES
('SAAL_A', 'Väike stuudio', '1. korrus', 2),
('SAAL_B', 'Suur rühmatreeningute saal', '2. korrus', 12)
ON CONFLICT DO NOTHING;

WITH json_ruumid AS (
    SELECT *
    FROM jsonb_to_recordset(
        '[
            {"ruumi_kood":"SAAL_C","nimetus":"Rahulik venitusstuudio","asukoht":"1. korrus","mahutavus":6}
        ]'::jsonb
    ) AS x(ruumi_kood kood_10, nimetus VARCHAR(100), asukoht VARCHAR(200), mahutavus INTEGER)
)
INSERT INTO ruum (ruumi_kood, nimetus, asukoht, mahutavus)
SELECT jr.ruumi_kood, jr.nimetus, jr.asukoht, jr.mahutavus
FROM json_ruumid jr
ON CONFLICT DO NOTHING;

INSERT INTO ruumi_varustuse_omamine (ruumi_kood, varustuse_kood, kogus, markus)
VALUES
('SAAL_A', 'MATID', 4, 'Väikese stuudio matid.'),
('SAAL_A', 'HANTLID', 4, 'HIIT tunniks piisav hulk hantleid.'),
('SAAL_A', 'PALLID', 2, 'Lisavarustus väikese grupi harjutusteks.'),
('SAAL_B', 'MATID', 12, 'Suure saali matid.'),
('SAAL_B', 'HANTLID', 10, 'Suure saali hantlid.'),
('SAAL_B', 'KANGID', 6, 'Jõutreeningu tehnika varustus.'),
('SAAL_B', 'EKRAAN', 1, 'Ekraan või projektor juhendmaterjaliks.'),
('SAAL_C', 'MATID', 6, 'Venitusstuudio matid.'),
('SAAL_C', 'PALLID', 6, 'Venitusstuudio võimlemispallid.')
ON CONFLICT DO NOTHING;

INSERT INTO treeneri_padevus (tootaja_e_meil, treeninguliigi_kood, alates)
VALUES
('treener@jousaal.ee', 1000, DATE '2025-01-01'),
('treener@jousaal.ee', 1001, DATE '2025-01-01'),
('treener2@jousaal.ee', 1002, DATE '2025-01-01')
ON CONFLICT DO NOTHING;

-- Demo treeningukord rows use fixed IDs as stable seed identities. Avoid
-- attempting duplicate inserts because BEFORE INSERT overlap triggers fire
-- before ON CONFLICT can skip an existing row.
WITH seeded_treeningukorrad (
    treeningukorra_kood,
    treeninguliigi_kood,
    treener_e_meil,
    ruumi_kood,
    alguse_aeg,
    lopu_aeg,
    registreerimise_lopp,
    tyhistamise_lopp,
    maksimaalne_osalejate_arv,
    seisundi_kood,
    looja_e_meil,
    viimase_muutja_e_meil
) AS (
    VALUES
    (2000, 1002, 'treener2@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP + INTERVAL '10 days',
        CURRENT_TIMESTAMP + INTERVAL '10 days 75 minutes',
        CURRENT_TIMESTAMP + INTERVAL '9 days',
        CURRENT_TIMESTAMP + INTERVAL '9 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2001, 1000, 'treener@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP + INTERVAL '7 days',
        CURRENT_TIMESTAMP + INTERVAL '7 days 60 minutes',
        CURRENT_TIMESTAMP + INTERVAL '6 days',
        CURRENT_TIMESTAMP + INTERVAL '6 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2002, 1001, 'treener@jousaal.ee', 'SAAL_A',
        CURRENT_TIMESTAMP + INTERVAL '5 days',
        CURRENT_TIMESTAMP + INTERVAL '5 days 45 minutes',
        CURRENT_TIMESTAMP + INTERVAL '4 days',
        CURRENT_TIMESTAMP + INTERVAL '4 days',
        2, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2003, 1000, 'treener@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP - INTERVAL '3 days',
        CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '60 minutes',
        CURRENT_TIMESTAMP - INTERVAL '4 days',
        CURRENT_TIMESTAMP - INTERVAL '4 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
)
INSERT INTO treeningukord (
    treeningukorra_kood,
    treeninguliigi_kood,
    treener_e_meil,
    ruumi_kood,
    alguse_aeg,
    lopu_aeg,
    registreerimise_lopp,
    tyhistamise_lopp,
    maksimaalne_osalejate_arv,
    seisundi_kood,
    looja_e_meil,
    viimase_muutja_e_meil
)
SELECT
    s.treeningukorra_kood,
    s.treeninguliigi_kood,
    s.treener_e_meil,
    s.ruumi_kood,
    s.alguse_aeg,
    s.lopu_aeg,
    s.registreerimise_lopp,
    s.tyhistamise_lopp,
    s.maksimaalne_osalejate_arv,
    s.seisundi_kood,
    s.looja_e_meil,
    s.viimase_muutja_e_meil
FROM seeded_treeningukorrad s
WHERE NOT EXISTS (
    SELECT 1
    FROM treeningukord tk
    WHERE tk.treeningukorra_kood = s.treeningukorra_kood
);

SELECT setval('seq_treeningukorra_kood', GREATEST((SELECT COALESCE(MAX(treeningukorra_kood), 1999) FROM treeningukord), 1999), TRUE);

UPDATE treeningukord
SET seisundi_kood = 'AVATUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP
WHERE treeningukorra_kood IN (2001, 2002)
  AND seisundi_kood = 'KAVAND';

UPDATE treeningukord
SET seisundi_kood = 'AVATUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP
WHERE treeningukorra_kood = 2003
  AND seisundi_kood = 'KAVAND';

UPDATE treeningukord
SET seisundi_kood = 'SULETUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP
WHERE treeningukorra_kood = 2003
  AND seisundi_kood = 'AVATUD';

UPDATE treeningukord
SET seisundi_kood = 'TOIMUNUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP
WHERE treeningukorra_kood = 2003
  AND seisundi_kood = 'SULETUD';

INSERT INTO registreering (
    registreeringu_kood,
    treeningukorra_kood,
    klient_e_meil,
    seisundi_kood,
    ootejarjekorra_nr
)
VALUES
(3000, 2002, 'klient@jousaal.ee', 'KINNIT', NULL),
(3001, 2002, 'klient2@jousaal.ee', 'KINNIT', NULL),
(3002, 2002, 'klient3@jousaal.ee', 'OOTEJRK', 1),
(3003, 2003, 'klient@jousaal.ee', 'KINNIT', NULL),
(3004, 2003, 'klient2@jousaal.ee', 'KINNIT', NULL)
ON CONFLICT DO NOTHING;

SELECT setval('seq_registreeringu_kood', GREATEST((SELECT COALESCE(MAX(registreeringu_kood), 2999) FROM registreering), 2999), TRUE);

INSERT INTO osalemine (registreeringu_kood, osales, markija_e_meil, markus)
VALUES
(3003, TRUE, 'treener@jousaal.ee', 'Osales kogu treeningus.'),
(3004, FALSE, 'treener@jousaal.ee', 'Puudus ette teatamata.')
ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_failed BOOLEAN;
BEGIN
    v_failed := FALSE;
    BEGIN
        INSERT INTO treeningukord (
            treeninguliigi_kood, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
            registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv,
            seisundi_kood, looja_e_meil, viimase_muutja_e_meil
        )
        VALUES (
            1000, 'treener@jousaal.ee', 'SAAL_B',
            CURRENT_TIMESTAMP + INTERVAL '7 days 15 minutes',
            CURRENT_TIMESTAMP + INTERVAL '7 days 75 minutes',
            CURRENT_TIMESTAMP + INTERVAL '6 days',
            CURRENT_TIMESTAMP + INTERVAL '6 days',
            8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'
        );
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud treeneri kattuvuse kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Treeneri kattuvuse kontroll ei rakendunud.';
    END IF;

    v_failed := FALSE;
    BEGIN
        INSERT INTO treeningukord (
            treeninguliigi_kood, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
            registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv,
            seisundi_kood, looja_e_meil, viimase_muutja_e_meil
        )
        VALUES (
            1000, 'treener@jousaal.ee', 'SAAL_B',
            CURRENT_TIMESTAMP + INTERVAL '10 days 5 minutes',
            CURRENT_TIMESTAMP + INTERVAL '10 days 55 minutes',
            CURRENT_TIMESTAMP + INTERVAL '9 days',
            CURRENT_TIMESTAMP + INTERVAL '9 days',
            8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'
        );
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud ruumi kattuvuse kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Ruumi kattuvuse kontroll ei rakendunud.';
    END IF;

    v_failed := FALSE;
    BEGIN
        PERFORM fn_planeeri_treeningukord(
            1002,
            'treener2@jousaal.ee',
            'SAAL_A',
            CURRENT_TIMESTAMP + INTERVAL '12 days',
            CURRENT_TIMESTAMP + INTERVAL '12 days 75 minutes',
            CURRENT_TIMESTAMP + INTERVAL '11 days',
            CURRENT_TIMESTAMP + INTERVAL '11 days',
            2,
            'juhataja@jousaal.ee'
        );
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud varustuse kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Varustuse kontroll ei rakendunud.';
    END IF;

    v_failed := FALSE;
    BEGIN
        INSERT INTO registreering (treeningukorra_kood, klient_e_meil, seisundi_kood)
        VALUES (2002, 'klient@jousaal.ee', 'KINNIT');
    EXCEPTION WHEN others THEN
        v_failed := TRUE;
        RAISE NOTICE 'Oodatud topeltregistreeringu kontroll: %', SQLERRM;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Topeltregistreeringu kontroll ei rakendunud.';
    END IF;
END $$;

DO $$
BEGIN
    BEGIN
        CREATE ROLE jousaali_rakendus LOGIN;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Rolli jousaali_rakendus loomiseks puudub õigus.';
    END;

    BEGIN
        CREATE ROLE jousaali_vaatleja LOGIN;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Rolli jousaali_vaatleja loomiseks puudub õigus.';
    END;
END $$;

DO $$
BEGIN
    BEGIN
        REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'Public skeemi CREATE õiguse eemaldamiseks puudub õigus.';
    END;

    BEGIN
        ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'Funktsioonide vaikimisi PUBLIC EXECUTE õiguse eemaldamiseks puudub õigus.';
    END;

    BEGIN
        REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'Funktsioonide PUBLIC EXECUTE õiguse eemaldamiseks puudub õigus.';
    END;

    IF to_regrole('jousaali_rakendus') IS NOT NULL THEN
        GRANT USAGE ON SCHEMA public TO jousaali_rakendus;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO jousaali_rakendus;
        REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM jousaali_rakendus;

        GRANT EXECUTE ON FUNCTION public.fn_kasutajal_on_roll(e_meil_aadress, kood_10) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_on_juhataja(e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_on_treener(e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_kasutaja_tuvastamise_andmed(e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_planeeri_treeningukord(
            INTEGER,
            e_meil_aadress,
            kood_10,
            TIMESTAMP WITH TIME ZONE,
            TIMESTAMP WITH TIME ZONE,
            TIMESTAMP WITH TIME ZONE,
            TIMESTAMP WITH TIME ZONE,
            INTEGER,
            e_meil_aadress
        ) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_ava_treeningukord(INTEGER, e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_sulge_treeningukord(INTEGER, e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_lopeta_treeningukord(INTEGER, e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_registreeri_klient_treeningukorrale(INTEGER, e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_tyhista_registreering(INTEGER, e_meil_aadress, TEXT) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_marki_osalemine(INTEGER, e_meil_aadress, BOOLEAN, TEXT) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_tyhista_treeningukord(INTEGER, e_meil_aadress, TEXT) TO jousaali_rakendus;
    END IF;

    IF to_regrole('jousaali_vaatleja') IS NOT NULL THEN
        GRANT USAGE ON SCHEMA public TO jousaali_vaatleja;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO jousaali_vaatleja;
    END IF;
END $$;

ANALYZE;

EXPLAIN SELECT *
FROM v_avalikud_treeningukorrad
WHERE vabu_kohti > 0;

-- Andmebaasiobjektide kustutamiseks tuleb käske käivitada vastupidises
-- sõltuvusjärjekorras. Esitatav loomisskript jätab need käsud kommentaaridesse,
-- et käivitamine ei kustutaks loodud hindamisandmebaasi.
-- DROP VIEW IF EXISTS v_treeninguliigid_kategooriatega CASCADE;
-- DROP VIEW IF EXISTS v_treeninguliigi_varustuse_nouded CASCADE;
-- DROP VIEW IF EXISTS v_ruumide_varustus CASCADE;
-- DROP VIEW IF EXISTS v_treeningute_taituvuse_statistika CASCADE;
-- DROP VIEW IF EXISTS v_juhataja_treeningukordade_ulevaade CASCADE;
-- DROP VIEW IF EXISTS v_treeningukorra_osalejad CASCADE;
-- DROP VIEW IF EXISTS v_treeneri_tunniplaan CASCADE;
-- DROP VIEW IF EXISTS v_kliendi_registreeringud CASCADE;
-- DROP VIEW IF EXISTS v_avalikud_treeningukorrad CASCADE;
-- DROP TABLE IF EXISTS osalemine, registreering, treeningukord, treeneri_padevus,
--     ruumi_varustuse_omamine, treeninguliigi_varustuse_noue, ruum, varustus,
--     treeninguliigi_kategooria_omamine, treeninguliik, klient CASCADE;
