-- =====================================================================
-- Jõusaali infosüsteemi treeningute funktsionaalse allsüsteemi
-- vajatavate registrite füüsilise disaini SQL DDL
-- Andmebaasisüsteem: PostgreSQL
-- Autorid: Tristan Aik Sild, Gustav Tamkivi (IAIB23)
-- =====================================================================
-- 1. riik
CREATE TABLE riik (
    riigi_kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_riik PRIMARY KEY (riigi_kood)
);

-- 2. isiku_seisundi_liik
CREATE TABLE isiku_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_isiku_seisundi_liik PRIMARY KEY (kood)
);

-- 3. tootaja_seisundi_liik
CREATE TABLE tootaja_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tootaja_seisundi_liik PRIMARY KEY (kood)
);

-- 4. tootaja_roll
CREATE TABLE tootaja_roll (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_tootaja_roll PRIMARY KEY (kood)
);

-- 5. treeningu_seisundi_liik
CREATE TABLE treeningu_seisundi_liik (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_seisundi_liik PRIMARY KEY (kood)
);

-- 6. treeningu_kategooria_tyyp
CREATE TABLE treeningu_kategooria_tyyp (
    kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria_tyyp PRIMARY KEY (kood)
);

-- 7. treeningu_kategooria
CREATE TABLE treeningu_kategooria (
    kood VARCHAR(10) NOT NULL,
    treeningu_kategooria_tyyp_kood VARCHAR(10) NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria PRIMARY KEY (kood),
    CONSTRAINT fk_treeningu_kategooria_tyyp FOREIGN KEY (treeningu_kategooria_tyyp_kood)
        REFERENCES treeningu_kategooria_tyyp (kood)
);

-- 8. isik
CREATE TABLE isik (
    isikukood VARCHAR(20) NOT NULL,
    riigi_kood VARCHAR(10) NOT NULL,
    isiku_seisundi_liik_kood VARCHAR(10) NOT NULL,
    synni_kp DATE,
    reg_aeg TIMESTAMP NOT NULL,
    viimase_muutm_aeg TIMESTAMP NOT NULL,
    eesnimi VARCHAR(200),
    perenimi VARCHAR(200),
    elukoht VARCHAR(500),
    e_meil VARCHAR(254),
    CONSTRAINT pk_isik PRIMARY KEY (isikukood, riigi_kood),
    CONSTRAINT fk_isik_riik FOREIGN KEY (riigi_kood)
        REFERENCES riik (riigi_kood),
    CONSTRAINT fk_isik_seisund FOREIGN KEY (isiku_seisundi_liik_kood)
        REFERENCES isiku_seisundi_liik (kood)
);

-- 9. kasutajakonto
CREATE TABLE kasutajakonto (
    e_meil VARCHAR(254) NOT NULL,
    parool VARCHAR(255) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_kasutajakonto PRIMARY KEY (e_meil),
    CONSTRAINT fk_kasutajakonto_isik FOREIGN KEY (e_meil)
        REFERENCES isik (e_meil)
);

-- 10. tootaja
CREATE TABLE tootaja (
    e_meil VARCHAR(254) NOT NULL,
    tootaja_seisundi_liik_kood VARCHAR(10) NOT NULL,
    CONSTRAINT pk_tootaja PRIMARY KEY (e_meil),
    CONSTRAINT fk_tootaja_konto FOREIGN KEY (e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_tootaja_seisund FOREIGN KEY (tootaja_seisundi_liik_kood)
        REFERENCES tootaja_seisundi_liik (kood)
);

-- 11. tootaja_rolli_omamine
CREATE TABLE tootaja_rolli_omamine (
    tootaja_e_meil VARCHAR(254) NOT NULL,
    tootaja_roll_kood VARCHAR(10) NOT NULL,
    alguse_aeg TIMESTAMP NOT NULL,
    lopu_aeg TIMESTAMP NOT NULL,
    CONSTRAINT pk_tootaja_rolli_omamine PRIMARY KEY (tootaja_e_meil, tootaja_roll_kood, alguse_aeg),
    CONSTRAINT fk_rolli_omamine_tootaja FOREIGN KEY (tootaja_e_meil)
        REFERENCES tootaja (e_meil),
    CONSTRAINT fk_rolli_omamine_roll FOREIGN KEY (tootaja_roll_kood)
        REFERENCES tootaja_roll (kood)
);

-- 12. treening
CREATE TABLE treening (
    treeningu_kood INTEGER NOT NULL CHECK (treeningu_kood > 0),
    treeningu_seisundi_liik_kood VARCHAR(10) NOT NULL,
    registreerija_e_meil VARCHAR(254) NOT NULL,
    viimase_muutja_e_meil VARCHAR(254) NOT NULL,
    reg_aeg TIMESTAMP NOT NULL,
    viimase_muutm_aeg TIMESTAMP NOT NULL,
    nimetus VARCHAR(200) NOT NULL CHECK (nimetus <> ''),
    kirjeldus TEXT,
    kestus_minutites INTEGER CHECK (kestus_minutites > 0),
    maksimaalne_osalejate_arv INTEGER,
    vajalik_varustus TEXT,
    hind NUMERIC(8,2) CHECK (hind >= 0),
    CONSTRAINT pk_treening PRIMARY KEY (treeningu_kood),
    CONSTRAINT fk_treeningu_seisund FOREIGN KEY (treeningu_seisundi_liik_kood)
        REFERENCES treeningu_seisundi_liik (kood),
    CONSTRAINT fk_treeningu_registreerija FOREIGN KEY (registreerija_e_meil)
        REFERENCES kasutajakonto (e_meil),
    CONSTRAINT fk_treeningu_muutja FOREIGN KEY (viimase_muutja_e_meil)
        REFERENCES kasutajakonto (e_meil)
);

-- 13. treeningu_kategooria_omamine
CREATE TABLE treeningu_kategooria_omamine (
    treeningu_kood INTEGER NOT NULL CHECK (treeningu_kood > 0),
    treeningu_kategooria_kood VARCHAR(10) NOT NULL,
    CONSTRAINT pk_treeningu_kategooria_omamine PRIMARY KEY (treeningu_kood, treeningu_kategooria_kood),
    CONSTRAINT fk_kategooria_omamine_treening FOREIGN KEY (treeningu_kood)
        REFERENCES treening (treeningu_kood),
    CONSTRAINT fk_kategooria_omamine_kategooria FOREIGN KEY (treeningu_kategooria_kood)
        REFERENCES treeningu_kategooria (kood)
);
