-- PostgreSQL DDL for the gym training information system.
-- The order below respects all foreign-key dependencies.

CREATE TABLE riik (
    riigi_kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_riik PRIMARY KEY (riigi_kood),
    CONSTRAINT chk_riik_kood_not_empty CHECK (btrim(riigi_kood) <> ''),
    CONSTRAINT chk_riik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE isiku_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_isiku_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_isiku_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_isiku_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE tootaja_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tootaja_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_tootaja_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_tootaja_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE tootaja_roll (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_tootaja_roll PRIMARY KEY (kood),
    CONSTRAINT chk_tootaja_roll_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_tootaja_roll_nimetus_not_empty CHECK (btrim(nimetus) <> ''),
    CONSTRAINT chk_tootaja_roll_kirjeldus_not_empty CHECK (kirjeldus IS NULL OR btrim(kirjeldus) <> '')
);

CREATE TABLE treeningu_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_seisundi_liik PRIMARY KEY (kood),
    CONSTRAINT chk_treeningu_seisundi_liik_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningu_seisundi_liik_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE treeningu_kategooria_tyyp (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria_tyyp PRIMARY KEY (kood),
    CONSTRAINT chk_treeningu_kategooria_tyyp_kood_not_empty CHECK (btrim(kood) <> ''),
    CONSTRAINT chk_treeningu_kategooria_tyyp_nimetus_not_empty CHECK (btrim(nimetus) <> '')
);

CREATE TABLE treeningu_kategooria (
    kood VARCHAR(10) NOT NULL,
    treeningu_kategooria_tyyp_kood VARCHAR(10) NOT NULL,
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
    riigi_kood VARCHAR(10) NOT NULL,
    isiku_seisundi_liik_kood VARCHAR(10) NOT NULL,
    synni_kp DATE NOT NULL,
    reg_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutm_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    eesnimi VARCHAR(200),
    perenimi VARCHAR(200),
    elukoht VARCHAR(500),
    e_meil VARCHAR(254) NOT NULL,
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
    e_meil VARCHAR(254) NOT NULL,
    parool VARCHAR(255) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_kasutajakonto PRIMARY KEY (e_meil),
    CONSTRAINT fk_kasutajakonto_isik FOREIGN KEY (e_meil)
        REFERENCES isik (e_meil),
    CONSTRAINT chk_kasutajakonto_e_meil_format CHECK (btrim(e_meil) <> '' AND position('@' in e_meil) > 1),
    CONSTRAINT chk_kasutajakonto_parool_not_empty CHECK (btrim(parool) <> '')
);

CREATE TABLE tootaja (
    e_meil VARCHAR(254) NOT NULL,
    tootaja_seisundi_liik_kood VARCHAR(10) NOT NULL,
    CONSTRAINT pk_tootaja PRIMARY KEY (e_meil),
    CONSTRAINT fk_tootaja_konto FOREIGN KEY (e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_tootaja_seisund FOREIGN KEY (tootaja_seisundi_liik_kood)
        REFERENCES tootaja_seisundi_liik (kood)
);

CREATE TABLE tootaja_rolli_omamine (
    tootaja_e_meil VARCHAR(254) NOT NULL,
    tootaja_roll_kood VARCHAR(10) NOT NULL,
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
    treeningu_kood INTEGER NOT NULL,
    treeningu_seisundi_liik_kood VARCHAR(10) NOT NULL,
    registreerija_e_meil VARCHAR(254) NOT NULL,
    viimase_muutja_e_meil VARCHAR(254) NOT NULL,
    reg_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viimase_muutm_aeg TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nimetus VARCHAR(200) NOT NULL,
    kirjeldus TEXT NOT NULL,
    kestus_minutites INTEGER NOT NULL,
    maksimaalne_osalejate_arv INTEGER NOT NULL,
    vajalik_varustus TEXT NOT NULL,
    hind NUMERIC(8,2) NOT NULL,
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

CREATE TABLE treeningu_kategooria_omamine (
    treeningu_kood INTEGER NOT NULL,
    treeningu_kategooria_kood VARCHAR(10) NOT NULL,
    CONSTRAINT pk_treeningu_kategooria_omamine PRIMARY KEY (treeningu_kood, treeningu_kategooria_kood),
    CONSTRAINT fk_kategooria_omamine_treening FOREIGN KEY (treeningu_kood)
        REFERENCES treening (treeningu_kood),
    CONSTRAINT fk_kategooria_omamine_kategooria FOREIGN KEY (treeningu_kategooria_kood)
        REFERENCES treeningu_kategooria (kood)
);

CREATE INDEX ix_isik_seisund ON isik (isiku_seisundi_liik_kood);
CREATE INDEX ix_tootaja_seisund ON tootaja (tootaja_seisundi_liik_kood);
CREATE INDEX ix_treening_seisund ON treening (treeningu_seisundi_liik_kood);
CREATE INDEX ix_treening_registreerija ON treening (registreerija_e_meil);
CREATE INDEX ix_treening_muutja ON treening (viimase_muutja_e_meil);
CREATE INDEX ix_treeningu_kategooria_tyyp ON treeningu_kategooria (treeningu_kategooria_tyyp_kood);
