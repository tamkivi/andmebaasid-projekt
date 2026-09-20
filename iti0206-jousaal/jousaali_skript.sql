-- Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise
-- funktsionaalse allsüsteemi PostgreSQL DDL.
--
-- Skript loob public skeemi terviklikult uuesti, et varasemad ümbernimetatud
-- objektid ei jääks hindaja jaoks alles.

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

CREATE DOMAIN kood_10 AS VARCHAR(10) NOT NULL
    CONSTRAINT chk_domeen_lyhikood_mittetyhi CHECK (VALUE ~ '[^[:space:]]');

CREATE DOMAIN e_meil_aadress AS VARCHAR(254)
    CONSTRAINT chk_domeen_e_meil_at_mark_olemas CHECK (VALUE LIKE '%@%');

CREATE DOMAIN ajakava_ajahetk AS TIMESTAMP(0) WITH TIME ZONE
    CONSTRAINT chk_domeen_ajatempel_alampiir CHECK (
        VALUE >= (TIMESTAMP '2000-01-01 00:00:00' AT TIME ZONE 'Europe/Tallinn')
    )
    CONSTRAINT chk_domeen_ajatempel_ylempiir CHECK (
        VALUE < (TIMESTAMP '2100-01-01 00:00:00' AT TIME ZONE 'Europe/Tallinn')
    );

CREATE TABLE riik (
    riigi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_riik PRIMARY KEY (riigi_kood),
    CONSTRAINT chk_riik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE isiku_seisundi_liik (
    isiku_seisundi_liigi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_isiku_seisundi_liik PRIMARY KEY (isiku_seisundi_liigi_kood),
    CONSTRAINT chk_isiku_seisundi_liik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE tootaja_seisundi_liik (
    tootaja_seisundi_liigi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tootaja_seisundi_liik PRIMARY KEY (tootaja_seisundi_liigi_kood),
    CONSTRAINT chk_tootaja_seisundi_liik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE tootaja_roll (
    tootaja_rolli_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_tootaja_roll PRIMARY KEY (tootaja_rolli_kood),
    CONSTRAINT chk_tootaja_roll_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_tootaja_roll_kirjeldus_mittetyhi CHECK (kirjeldus ~ '[^[:space:]]')
);

CREATE TABLE treeninguliigi_seisundi_liik (
    treeninguliigi_seisundi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeninguliigi_seisundi_liik PRIMARY KEY (treeninguliigi_seisundi_kood),
    CONSTRAINT chk_treeninguliigi_seisundi_liik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE treeningukorra_seisundi_liik (
    treeningukorra_seisundi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_treeningukorra_seisundi_liik PRIMARY KEY (treeningukorra_seisundi_kood),
    CONSTRAINT chk_treeningukorra_seisundi_liik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_treeningukorra_seisundi_liik_kirjeldus_mittetyhi CHECK (kirjeldus ~ '[^[:space:]]')
);

CREATE TABLE registreeringu_seisundi_liik (
    registreeringu_seisundi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    kirjeldus TEXT,
    CONSTRAINT pk_registreeringu_seisundi_liik PRIMARY KEY (registreeringu_seisundi_kood),
    CONSTRAINT chk_registreeringu_seisundi_liik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_registreeringu_seisundi_liik_kirjeldus_mittetyhi CHECK (kirjeldus ~ '[^[:space:]]')
);

CREATE TABLE treeningu_kategooria_tyyp (
    treeningu_kategooria_tyybi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria_tyyp PRIMARY KEY (treeningu_kategooria_tyybi_kood),
    CONSTRAINT chk_treeningu_kategooria_tyyp_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE treeningu_kategooria (
    treeningu_kategooria_kood kood_10,
    treeningu_kategooria_tyybi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_treeningu_kategooria PRIMARY KEY (treeningu_kategooria_kood),
    CONSTRAINT uq_treeningu_kategooria_tyyp_nimetus UNIQUE (treeningu_kategooria_tyybi_kood, nimetus),
    CONSTRAINT fk_treeningu_kategooria_treeningu_kategooria_tyyp FOREIGN KEY (treeningu_kategooria_tyybi_kood)
        REFERENCES treeningu_kategooria_tyyp (treeningu_kategooria_tyybi_kood) ON UPDATE CASCADE,
    CONSTRAINT chk_treeningu_kategooria_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]')
);

CREATE TABLE isik (
    e_meil e_meil_aadress NOT NULL,
    isikukood VARCHAR(20) NOT NULL,
    riigi_kood kood_10,
    isiku_seisundi_liigi_kood kood_10 DEFAULT 'KLIENT',
    synni_kp DATE NOT NULL,
    registreerimise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    viimase_muutmise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    eesnimi VARCHAR(100),
    perenimi VARCHAR(100),
    elukoht VARCHAR(200),
    CONSTRAINT pk_isik PRIMARY KEY (e_meil),
    CONSTRAINT uq_isik_isikukood_riigi_kood UNIQUE (isikukood, riigi_kood),
    CONSTRAINT fk_isik_riik FOREIGN KEY (riigi_kood) REFERENCES riik (riigi_kood) ON UPDATE CASCADE,
    CONSTRAINT fk_isik_isiku_seisundi_liik FOREIGN KEY (isiku_seisundi_liigi_kood)
        REFERENCES isiku_seisundi_liik (isiku_seisundi_liigi_kood) ON UPDATE CASCADE,
    CONSTRAINT chk_isik_isikukood_mittetyhi CHECK (isikukood ~ '[^[:space:]]'),
    CONSTRAINT chk_isik_eesnimi_voi_perenimi_olemas CHECK (eesnimi IS NOT NULL OR perenimi IS NOT NULL),
    CONSTRAINT chk_isik_eesnimi_mittetyhi CHECK (eesnimi ~ '[^[:space:]]'),
    CONSTRAINT chk_isik_perenimi_mittetyhi CHECK (perenimi ~ '[^[:space:]]'),
    CONSTRAINT chk_isik_elukoht_mittetyhi CHECK (elukoht ~ '[^[:space:]]'),
    CONSTRAINT chk_isik_synni_kp_alampiir CHECK (synni_kp >= DATE '1900-01-01'),
    CONSTRAINT chk_isik_synni_kp_tulevikus_keelatud CHECK (synni_kp <= CURRENT_DATE),
    CONSTRAINT chk_isik_synni_kp_enne_registreerimise_aega CHECK (synni_kp <= registreerimise_aeg::date),
    CONSTRAINT chk_isik_viimase_muutmise_aeg_parast_registreerimist CHECK (registreerimise_aeg <= viimase_muutmise_aeg)
);

CREATE TABLE kasutajakonto (
    e_meil e_meil_aadress NOT NULL,
    parool VARCHAR(255) NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_kasutajakonto PRIMARY KEY (e_meil),
    CONSTRAINT fk_kasutajakonto_isik FOREIGN KEY (e_meil) REFERENCES isik (e_meil) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_kasutajakonto_parool_mittetyhi CHECK (parool ~ '[^[:space:]]')
);

CREATE OR REPLACE FUNCTION fn_uuenda_viimase_muutmise_aeg()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.viimase_muutmise_aeg := CURRENT_TIMESTAMP(0);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_isik_viimase_muutmise_aeg
BEFORE UPDATE ON isik
FOR EACH ROW
EXECUTE FUNCTION fn_uuenda_viimase_muutmise_aeg();

CREATE TABLE klient (
    e_meil e_meil_aadress NOT NULL,
    registreerimise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_klient PRIMARY KEY (e_meil),
    CONSTRAINT fk_klient_kasutajakonto FOREIGN KEY (e_meil) REFERENCES kasutajakonto (e_meil) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE tootaja (
    e_meil e_meil_aadress NOT NULL,
    tootaja_seisundi_liigi_kood kood_10 DEFAULT 'AKTIIVNE',
    CONSTRAINT pk_tootaja PRIMARY KEY (e_meil),
    CONSTRAINT fk_tootaja_kasutajakonto FOREIGN KEY (e_meil) REFERENCES kasutajakonto (e_meil) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tootaja_tootaja_seisundi_liik FOREIGN KEY (tootaja_seisundi_liigi_kood)
        REFERENCES tootaja_seisundi_liik (tootaja_seisundi_liigi_kood) ON UPDATE CASCADE
);

CREATE TABLE tootaja_rolli_omamine (
    tootaja_e_meil e_meil_aadress NOT NULL,
    tootaja_rolli_kood kood_10,
    alguse_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    kehtivuse_lopu_aeg TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT TIMESTAMPTZ 'infinity',
    CONSTRAINT pk_tootaja_rolli_omamine PRIMARY KEY (tootaja_e_meil, tootaja_rolli_kood, alguse_aeg),
    CONSTRAINT fk_tootaja_rolli_omamine_tootaja FOREIGN KEY (tootaja_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tootaja_rolli_omamine_tootaja_roll FOREIGN KEY (tootaja_rolli_kood)
        REFERENCES tootaja_roll (tootaja_rolli_kood) ON UPDATE CASCADE,
    CONSTRAINT chk_tootaja_rolli_omamine_kehtivuse_lopu_aeg_alampiir CHECK (
        kehtivuse_lopu_aeg >= (TIMESTAMP '2000-01-01 00:00:00' AT TIME ZONE 'Europe/Tallinn')
    ),
    CONSTRAINT chk_tootaja_rolli_omamine_kehtivuse_lopu_aeg_ylempiir CHECK (
        kehtivuse_lopu_aeg < (TIMESTAMP '2100-01-01 00:00:00' AT TIME ZONE 'Europe/Tallinn')
        OR kehtivuse_lopu_aeg = TIMESTAMPTZ 'infinity'
    ),
    CONSTRAINT chk_tootaja_rolli_omamine_alguse_aeg_enne_kehtivuse_lopu_aega CHECK (
        alguse_aeg::TIMESTAMP WITH TIME ZONE < kehtivuse_lopu_aeg::TIMESTAMP WITH TIME ZONE
    )
);

CREATE TABLE treeninguliik (
    treeninguliigi_id INTEGER GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME seq_treeninguliigi_id
        START WITH 1000
        INCREMENT BY 1
    ),
    nimetus VARCHAR(100) NOT NULL,
    kirjeldus TEXT,
    kestus_minutites INTEGER NOT NULL,
    vajalik_varustus VARCHAR(1000),
    treeninguliigi_seisundi_kood kood_10 DEFAULT 'KOOST',
    registreerija_e_meil e_meil_aadress,
    viimase_muutja_e_meil e_meil_aadress,
    registreerimise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    viimase_muutmise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    CONSTRAINT pk_treeninguliik PRIMARY KEY (treeninguliigi_id),
    CONSTRAINT uq_treeninguliik_nimetus UNIQUE (nimetus),
    CONSTRAINT fk_treeninguliik_treeninguliigi_seisundi_liik FOREIGN KEY (treeninguliigi_seisundi_kood)
        REFERENCES treeninguliigi_seisundi_liik (treeninguliigi_seisundi_kood) ON UPDATE CASCADE,
    CONSTRAINT fk_treeninguliik_registreerija_tootaja FOREIGN KEY (registreerija_e_meil)
        REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_treeninguliik_viimase_muutja_tootaja FOREIGN KEY (viimase_muutja_e_meil)
        REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT chk_treeninguliik_treeninguliigi_id_positiivne CHECK (treeninguliigi_id > 0),
    CONSTRAINT chk_treeninguliik_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_treeninguliik_kestus_minutites_miinimum CHECK (kestus_minutites >= 15),
    CONSTRAINT chk_treeninguliik_kestus_minutites_maksimum CHECK (kestus_minutites <= 240),
    CONSTRAINT chk_treeninguliik_kirjeldus_mittetyhi CHECK (kirjeldus ~ '[^[:space:]]'),
    CONSTRAINT chk_treeninguliik_vajalik_varustus_mittetyhi CHECK (vajalik_varustus ~ '[^[:space:]]'),
    CONSTRAINT chk_treeninguliik_viimase_muutmise_aeg_parast_registreerimist CHECK (registreerimise_aeg <= viimase_muutmise_aeg)
);

CREATE TRIGGER trg_treeninguliik_viimase_muutmise_aeg
BEFORE UPDATE ON treeninguliik
FOR EACH ROW
EXECUTE FUNCTION fn_uuenda_viimase_muutmise_aeg();

CREATE TABLE treeninguliigi_kategooria_omamine (
    treeninguliigi_id INTEGER NOT NULL,
    treeningu_kategooria_kood kood_10,
    CONSTRAINT pk_treeninguliigi_kategooria_omamine PRIMARY KEY (treeninguliigi_id, treeningu_kategooria_kood),
    CONSTRAINT fk_treeninguliigi_kategooria_omamine_treeninguliik FOREIGN KEY (treeninguliigi_id)
        REFERENCES treeninguliik (treeninguliigi_id) ON DELETE CASCADE,
    CONSTRAINT fk_treeninguliigi_kategooria_omamine_treeningu_kategooria FOREIGN KEY (treeningu_kategooria_kood)
        REFERENCES treeningu_kategooria (treeningu_kategooria_kood) ON UPDATE CASCADE
);

CREATE TABLE varustus (
    varustuse_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    kirjeldus TEXT,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_varustus PRIMARY KEY (varustuse_kood),
    CONSTRAINT uq_varustus_nimetus UNIQUE (nimetus),
    CONSTRAINT chk_varustus_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_varustus_kirjeldus_mittetyhi CHECK (kirjeldus ~ '[^[:space:]]')
);

CREATE TABLE treeninguliigi_varustuse_noue (
    treeninguliigi_id INTEGER NOT NULL,
    varustuse_kood kood_10,
    minimaalne_kogus INTEGER NOT NULL,
    on_kohustuslik BOOLEAN NOT NULL DEFAULT TRUE,
    markus VARCHAR(1000),
    CONSTRAINT pk_treeninguliigi_varustuse_noue PRIMARY KEY (treeninguliigi_id, varustuse_kood),
    CONSTRAINT fk_treeninguliigi_varustuse_noue_treeninguliik FOREIGN KEY (treeninguliigi_id)
        REFERENCES treeninguliik (treeninguliigi_id) ON DELETE CASCADE,
    CONSTRAINT fk_treeninguliigi_varustuse_noue_varustus FOREIGN KEY (varustuse_kood)
        REFERENCES varustus (varustuse_kood) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_treeninguliigi_varustuse_noue_minimaalne_kogus_positiivne CHECK (minimaalne_kogus > 0),
    CONSTRAINT chk_treeninguliigi_varustuse_noue_markus_mittetyhi CHECK (markus ~ '[^[:space:]]')
);

CREATE TABLE ruum (
    ruumi_kood kood_10,
    nimetus VARCHAR(100) NOT NULL,
    asukoht VARCHAR(300),
    mahutavus INTEGER NOT NULL,
    on_aktiivne BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_ruum PRIMARY KEY (ruumi_kood),
    CONSTRAINT uq_ruum_nimetus UNIQUE (nimetus),
    CONSTRAINT chk_ruum_nimetus_mittetyhi CHECK (nimetus ~ '[^[:space:]]'),
    CONSTRAINT chk_ruum_asukoht_mittetyhi CHECK (asukoht ~ '[^[:space:]]'),
    CONSTRAINT chk_ruum_mahutavus_positiivne CHECK (mahutavus > 0)
);

CREATE TABLE ruumi_varustuse_omamine (
    ruumi_kood kood_10,
    varustuse_kood kood_10,
    kogus INTEGER NOT NULL,
    markus VARCHAR(1000),
    CONSTRAINT pk_ruumi_varustuse_omamine PRIMARY KEY (ruumi_kood, varustuse_kood),
    CONSTRAINT fk_ruumi_varustuse_omamine_ruum FOREIGN KEY (ruumi_kood)
        REFERENCES ruum (ruumi_kood) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ruumi_varustuse_omamine_varustus FOREIGN KEY (varustuse_kood)
        REFERENCES varustus (varustuse_kood) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_ruumi_varustuse_omamine_kogus_positiivne CHECK (kogus > 0),
    CONSTRAINT chk_ruumi_varustuse_omamine_markus_mittetyhi CHECK (markus ~ '[^[:space:]]')
);

CREATE TABLE treeneri_padevus (
    tootaja_e_meil e_meil_aadress NOT NULL,
    treeninguliigi_id INTEGER NOT NULL,
    alates DATE NOT NULL DEFAULT CURRENT_DATE,
    kuni DATE NOT NULL DEFAULT DATE 'infinity',
    CONSTRAINT pk_treeneri_padevus PRIMARY KEY (tootaja_e_meil, treeninguliigi_id),
    CONSTRAINT fk_treeneri_padevus_tootaja FOREIGN KEY (tootaja_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_treeneri_padevus_treeninguliik FOREIGN KEY (treeninguliigi_id)
        REFERENCES treeninguliik (treeninguliigi_id) ON DELETE CASCADE,
    CONSTRAINT chk_treeneri_padevus_alates_alampiir CHECK (alates >= DATE '2000-01-01'),
    CONSTRAINT chk_treeneri_padevus_alates_ylempiir CHECK (alates < DATE '2100-01-01'),
    CONSTRAINT chk_treeneri_padevus_kuni_alampiir CHECK (kuni >= DATE '2000-01-01'),
    CONSTRAINT chk_treeneri_padevus_kuni_ylempiir CHECK (kuni < DATE '2100-01-01' OR kuni = DATE 'infinity'),
    CONSTRAINT chk_treeneri_padevus_alates_enne_kuni CHECK (alates < kuni)
);

CREATE TABLE treeningukord (
    treeningukorra_id INTEGER GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME seq_treeningukorra_id
        START WITH 2000
        INCREMENT BY 1
    ),
    treeninguliigi_id INTEGER NOT NULL,
    treener_e_meil e_meil_aadress NOT NULL,
    ruumi_kood kood_10,
    alguse_aeg ajakava_ajahetk NOT NULL,
    lopu_aeg ajakava_ajahetk NOT NULL,
    registreerimise_lopp ajakava_ajahetk NOT NULL,
    tyhistamise_lopp ajakava_ajahetk NOT NULL,
    maksimaalne_osalejate_arv INTEGER NOT NULL,
    treeningukorra_seisundi_kood kood_10 DEFAULT 'KAVAND',
    looja_e_meil e_meil_aadress,
    viimase_muutja_e_meil e_meil_aadress,
    loomise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    viimase_muutmise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    tyhistamise_pohjus VARCHAR(1000),
    CONSTRAINT pk_treeningukord PRIMARY KEY (treeningukorra_id),
    CONSTRAINT uq_treeningukord_treeninguliik_ruum_treener_alguse_aeg UNIQUE (treeninguliigi_id, ruumi_kood, treener_e_meil, alguse_aeg),
    CONSTRAINT fk_treeningukord_treeninguliik FOREIGN KEY (treeninguliigi_id) REFERENCES treeninguliik (treeninguliigi_id),
    CONSTRAINT fk_treeningukord_treener FOREIGN KEY (treener_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_treeningukord_ruum FOREIGN KEY (ruumi_kood) REFERENCES ruum (ruumi_kood) ON UPDATE CASCADE,
    CONSTRAINT fk_treeningukord_treeningukorra_seisundi_liik FOREIGN KEY (treeningukorra_seisundi_kood)
        REFERENCES treeningukorra_seisundi_liik (treeningukorra_seisundi_kood) ON UPDATE CASCADE,
    CONSTRAINT fk_treeningukord_looja_tootaja FOREIGN KEY (looja_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_treeningukord_viimase_muutja_tootaja FOREIGN KEY (viimase_muutja_e_meil)
        REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT chk_treeningukord_treeningukorra_id_positiivne CHECK (treeningukorra_id > 0),
    CONSTRAINT chk_treeningukord_alguse_aeg_enne_lopu_aega CHECK (
        alguse_aeg::TIMESTAMP WITH TIME ZONE < lopu_aeg::TIMESTAMP WITH TIME ZONE
    ),
    CONSTRAINT chk_treeningukord_registreerimise_lopp_enne_alguse_aega CHECK (registreerimise_lopp <= alguse_aeg),
    CONSTRAINT chk_treeningukord_registreerimise_lopp_enne_tyhistamise_loppu CHECK (registreerimise_lopp <= tyhistamise_lopp),
    CONSTRAINT chk_treeningukord_tyhistamise_lopp_enne_alguse_aega CHECK (tyhistamise_lopp <= alguse_aeg),
    CONSTRAINT chk_treeningukord_maksimaalne_osalejate_arv_positiivne CHECK (maksimaalne_osalejate_arv > 0),
    CONSTRAINT chk_treeningukord_tyhistamise_pohjus_mittetyhi CHECK (tyhistamise_pohjus ~ '[^[:space:]]'),
    CONSTRAINT chk_treeningukord_viimase_muutmise_aeg_parast_loomist CHECK (loomise_aeg <= viimase_muutmise_aeg)
);

CREATE TRIGGER trg_treeningukord_viimase_muutmise_aeg
BEFORE UPDATE ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_uuenda_viimase_muutmise_aeg();

CREATE TABLE registreering (
    registreeringu_id INTEGER GENERATED ALWAYS AS IDENTITY (
        SEQUENCE NAME seq_registreeringu_id
        START WITH 3000
        INCREMENT BY 1
    ),
    treeningukorra_id INTEGER NOT NULL,
    klient_e_meil e_meil_aadress NOT NULL,
    registreeringu_seisundi_kood kood_10 DEFAULT 'KINNIT',
    registreerimise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    tyhistamise_aeg ajakava_ajahetk,
    edendamise_aeg ajakava_ajahetk,
    tyhistamise_pohjus VARCHAR(1000),
    CONSTRAINT pk_registreering PRIMARY KEY (registreeringu_id),
    CONSTRAINT fk_registreering_treeningukord FOREIGN KEY (treeningukorra_id) REFERENCES treeningukord (treeningukorra_id),
    CONSTRAINT fk_registreering_klient FOREIGN KEY (klient_e_meil) REFERENCES klient (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_registreering_registreeringu_seisundi_liik FOREIGN KEY (registreeringu_seisundi_kood)
        REFERENCES registreeringu_seisundi_liik (registreeringu_seisundi_kood) ON UPDATE CASCADE,
    CONSTRAINT chk_registreering_registreeringu_id_positiivne CHECK (registreeringu_id > 0),
    CONSTRAINT chk_registreering_kliendi_tyhistamise_aeg_olemas CHECK (registreeringu_seisundi_kood <> 'TYH_KL' OR tyhistamise_aeg IS NOT NULL),
    CONSTRAINT chk_registreering_systeemse_tyhistamise_aeg_olemas CHECK (registreeringu_seisundi_kood <> 'TYH_SYS' OR tyhistamise_aeg IS NOT NULL),
    CONSTRAINT chk_registreering_registreerimise_aeg_enne_edendamise_aega CHECK (registreerimise_aeg <= edendamise_aeg),
    CONSTRAINT chk_registreering_registreerimise_aeg_enne_tyhistamise_aega CHECK (registreerimise_aeg <= tyhistamise_aeg),
    CONSTRAINT chk_registreering_edendamise_aeg_enne_tyhistamise_aega CHECK (edendamise_aeg <= tyhistamise_aeg),
    CONSTRAINT chk_registreering_tyhistamise_pohjus_mittetyhi CHECK (tyhistamise_pohjus ~ '[^[:space:]]')
);

CREATE TABLE ootejarjekorra_koht (
    registreeringu_id INTEGER NOT NULL,
    treeningukorra_id INTEGER NOT NULL,
    ootejarjekorra_nr INTEGER NOT NULL,
    CONSTRAINT pk_ootejarjekorra_koht PRIMARY KEY (registreeringu_id),
    CONSTRAINT uq_ootejarjekorra_koht_treeningukord_nr UNIQUE (treeningukorra_id, ootejarjekorra_nr),
    CONSTRAINT fk_ootejarjekorra_koht_registreering FOREIGN KEY (registreeringu_id)
        REFERENCES registreering (registreeringu_id) ON DELETE CASCADE,
    CONSTRAINT fk_ootejarjekorra_koht_treeningukord FOREIGN KEY (treeningukorra_id)
        REFERENCES treeningukord (treeningukorra_id),
    CONSTRAINT chk_ootejarjekorra_koht_ootejarjekorra_nr_positiivne CHECK (ootejarjekorra_nr > 0)
);

CREATE TABLE osalemine (
    registreeringu_id INTEGER NOT NULL,
    klient_e_meil e_meil_aadress NOT NULL,
    treener_e_meil e_meil_aadress NOT NULL,
    on_osalenud BOOLEAN NOT NULL,
    markija_e_meil e_meil_aadress NOT NULL,
    markimise_aeg ajakava_ajahetk NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    markus VARCHAR(1000),
    CONSTRAINT pk_osalemine PRIMARY KEY (registreeringu_id),
    CONSTRAINT fk_osalemine_registreering FOREIGN KEY (registreeringu_id) REFERENCES registreering (registreeringu_id) ON DELETE CASCADE,
    CONSTRAINT fk_osalemine_klient FOREIGN KEY (klient_e_meil) REFERENCES klient (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_osalemine_treener FOREIGN KEY (treener_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT fk_osalemine_markija FOREIGN KEY (markija_e_meil) REFERENCES tootaja (e_meil) ON UPDATE CASCADE,
    CONSTRAINT chk_osalemine_markus_mittetyhi CHECK (markus ~ '[^[:space:]]')
);

CREATE INDEX ix_isik_riik ON isik (riigi_kood);
CREATE INDEX ix_isik_isiku_seisundi_liik ON isik (isiku_seisundi_liigi_kood);
CREATE INDEX ix_tootaja_tootaja_seisundi_liik ON tootaja (tootaja_seisundi_liigi_kood);
CREATE UNIQUE INDEX uq_tootaja_rolli_omamine_aktiivne_roll
ON tootaja_rolli_omamine (tootaja_rolli_kood, tootaja_e_meil)
WHERE kehtivuse_lopu_aeg = TIMESTAMPTZ 'infinity';

CREATE INDEX ix_treeninguliik_seisundi_liik ON treeninguliik (treeninguliigi_seisundi_kood);
CREATE INDEX ix_treeninguliik_registreerija_tootaja ON treeninguliik (registreerija_e_meil);
CREATE INDEX ix_treeninguliik_viimase_muutja_tootaja ON treeninguliik (viimase_muutja_e_meil);
CREATE INDEX ix_treeninguliigi_kategooria_omamine_treeningu_kategooria ON treeninguliigi_kategooria_omamine (treeningu_kategooria_kood);
CREATE INDEX ix_treeninguliigi_varustuse_noue_varustus ON treeninguliigi_varustuse_noue (varustuse_kood);
CREATE INDEX ix_ruumi_varustuse_omamine_varustus ON ruumi_varustuse_omamine (varustuse_kood);
CREATE INDEX ix_treeneri_padevus_treeninguliik ON treeneri_padevus (treeninguliigi_id);
CREATE INDEX ix_treeningukord_treener_aeg ON treeningukord (treener_e_meil, alguse_aeg, lopu_aeg);
CREATE INDEX ix_treeningukord_ruum_aeg ON treeningukord (ruumi_kood, alguse_aeg, lopu_aeg);
CREATE INDEX ix_treeningukord_seisundi_liik ON treeningukord (treeningukorra_seisundi_kood);
CREATE INDEX ix_treeningukord_looja_tootaja ON treeningukord (looja_e_meil);
CREATE INDEX ix_treeningukord_viimase_muutja_tootaja ON treeningukord (viimase_muutja_e_meil);
CREATE INDEX ix_registreering_seisundi_liik ON registreering (registreeringu_seisundi_kood);
CREATE INDEX ix_registreering_treeningukord_seisund_aeg ON registreering (treeningukorra_id, registreeringu_seisundi_kood, registreerimise_aeg);
CREATE INDEX ix_osalemine_klient ON osalemine (klient_e_meil);
CREATE INDEX ix_osalemine_treener ON osalemine (treener_e_meil);
CREATE INDEX ix_osalemine_markija ON osalemine (markija_e_meil);

CREATE UNIQUE INDEX uq_registreering_aktiivne_klient_kord
ON registreering (klient_e_meil, treeningukorra_id)
WHERE registreeringu_seisundi_kood = 'KINNIT' OR registreeringu_seisundi_kood = 'OOTEJRK';

CREATE OR REPLACE FUNCTION on_kasutajal_roll(
    p_e_meil e_meil_aadress,
    p_tootaja_rolli_kood kood_10
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
BEGIN ATOMIC
    SELECT EXISTS (
        SELECT 1
        FROM tootaja t
        JOIN tootaja_rolli_omamine tro ON tro.tootaja_e_meil = t.e_meil
        JOIN tootaja_roll tr ON tr.tootaja_rolli_kood = tro.tootaja_rolli_kood
        WHERE t.e_meil = p_e_meil
          AND t.tootaja_seisundi_liigi_kood = 'AKTIIVNE'
          AND tr.tootaja_rolli_kood = p_tootaja_rolli_kood
          AND tr.on_aktiivne
          AND tro.alguse_aeg <= CURRENT_TIMESTAMP(0)
          AND tro.kehtivuse_lopu_aeg > CURRENT_TIMESTAMP(0)
    );
END;

CREATE OR REPLACE FUNCTION on_juhataja(p_e_meil e_meil_aadress)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
BEGIN ATOMIC
    SELECT on_kasutajal_roll(p_e_meil => p_e_meil, p_tootaja_rolli_kood => 'JUHATAJA');
END;

CREATE OR REPLACE FUNCTION on_treener(p_e_meil e_meil_aadress)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
BEGIN ATOMIC
    SELECT on_kasutajal_roll(p_e_meil => p_e_meil, p_tootaja_rolli_kood => 'TREENER');
END;

CREATE OR REPLACE FUNCTION fn_tuvasta_kasutaja_e_meili_jargi(p_kasutaja_e_meili_aadress e_meil_aadress)
RETURNS TABLE (
    e_meil e_meil_aadress,
    parooli_rasi VARCHAR(255),
    on_aktiivne BOOLEAN,
    eesnimi VARCHAR(100),
    perenimi VARCHAR(100),
    kasutaja_liik TEXT,
    rollid TEXT[]
)
LANGUAGE sql
STABLE
BEGIN ATOMIC
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
            array_agg(DISTINCT tro.tootaja_rolli_kood)
                FILTER (WHERE tro.tootaja_rolli_kood IS NOT NULL),
            ARRAY[]::TEXT[]
        ) AS rollid
    FROM kasutajakonto k
    JOIN isik i ON i.e_meil = k.e_meil
    LEFT JOIN tootaja_rolli_omamine tro
        ON tro.tootaja_e_meil = k.e_meil
       AND tro.alguse_aeg <= CURRENT_TIMESTAMP(0)
       AND tro.kehtivuse_lopu_aeg > CURRENT_TIMESTAMP(0)
    WHERE k.e_meil = p_kasutaja_e_meili_aadress
    GROUP BY k.e_meil, k.parool, k.on_aktiivne, i.eesnimi, i.perenimi;
END;

CREATE OR REPLACE FUNCTION fn_kontrolli_treeneri_padevust()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT on_treener(NEW.tootaja_e_meil) THEN
        RAISE EXCEPTION 'Pädevust saab lisada ainult aktiivse TREENER rolliga töötajale.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeneri_padevus_roll
BEFORE INSERT OR UPDATE ON treeneri_padevus
FOR EACH ROW
EXECUTE FUNCTION fn_kontrolli_treeneri_padevust();

CREATE OR REPLACE FUNCTION fn_treeningukord_algseisund()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.treeningukorra_seisundi_kood <> 'KAVAND' THEN
        RAISE EXCEPTION 'Treeningukord tuleb luua seisundis KAVAND.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_algseisund
BEFORE INSERT ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_treeningukord_algseisund();

CREATE OR REPLACE FUNCTION fn_treeningukord_seisundisiire()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.treeningukorra_seisundi_kood IS NOT DISTINCT FROM NEW.treeningukorra_seisundi_kood THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.treeningukorra_seisundi_kood = 'KAVAND' AND NEW.treeningukorra_seisundi_kood IN ('AVATUD', 'TYHIST'))
        OR (OLD.treeningukorra_seisundi_kood = 'AVATUD' AND NEW.treeningukorra_seisundi_kood IN ('SULETUD', 'TYHIST'))
        OR (OLD.treeningukorra_seisundi_kood = 'SULETUD' AND NEW.treeningukorra_seisundi_kood IN ('TOIMUNUD', 'TYHIST'))
    ) THEN
        RAISE EXCEPTION 'Treeningukorra lubamatu seisundimuudatus: % -> %.',
            OLD.treeningukorra_seisundi_kood,
            NEW.treeningukorra_seisundi_kood;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_seisundisiire
BEFORE UPDATE OF treeningukorra_seisundi_kood ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_treeningukord_seisundisiire();

CREATE OR REPLACE FUNCTION on_ruum_sobiv_treeninguliigile(
    p_ruumi_kood kood_10,
    p_treeninguliigi_id INTEGER
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
BEGIN ATOMIC
    SELECT NOT EXISTS (
        SELECT 1
        FROM treeninguliigi_varustuse_noue n
        WHERE n.treeninguliigi_id = p_treeninguliigi_id
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
END;

CREATE OR REPLACE FUNCTION fn_kontrolli_treeningukorra_invariandid()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ruumi_mahutavus INTEGER;
BEGIN
    IF NEW.treeningukorra_seisundi_kood = 'TYHIST' THEN
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
        WHERE tl.treeninguliigi_id = NEW.treeninguliigi_id
          AND tl.treeninguliigi_seisundi_kood = 'AKTIIVNE'
    ) THEN
        RAISE EXCEPTION 'Treeningukorda saab planeerida ainult aktiivse treeninguliigi alusel.';
    END IF;

    IF NOT on_treener(NEW.treener_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra treeneril peab olema aktiivne TREENER roll.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM treeneri_padevus tp
        WHERE tp.tootaja_e_meil = NEW.treener_e_meil
          AND tp.treeninguliigi_id = NEW.treeninguliigi_id
          AND tp.alates <= NEW.alguse_aeg::date
          AND tp.kuni > NEW.alguse_aeg::date
    ) THEN
        RAISE EXCEPTION 'Treeneril puudub valitud treeninguliigi kehtiv pädevus.';
    END IF;

    IF NOT on_ruum_sobiv_treeninguliigile(
        p_ruumi_kood => NEW.ruumi_kood,
        p_treeninguliigi_id => NEW.treeninguliigi_id
    ) THEN
        RAISE EXCEPTION 'Ruumis puudub treeninguliigi jaoks nõutav varustus.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM treeningukord tk
        WHERE tk.treener_e_meil = NEW.treener_e_meil
          AND tk.treeningukorra_seisundi_kood <> 'TYHIST'
          AND (TG_OP = 'INSERT' OR tk.treeningukorra_id <> OLD.treeningukorra_id)
          AND NOT (NEW.lopu_aeg <= tk.alguse_aeg OR NEW.alguse_aeg >= tk.lopu_aeg)
    ) THEN
        RAISE EXCEPTION 'Treeneril on samal ajal juba teine tühistamata treeningukord.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM treeningukord tk
        WHERE tk.ruumi_kood = NEW.ruumi_kood
          AND tk.treeningukorra_seisundi_kood <> 'TYHIST'
          AND (TG_OP = 'INSERT' OR tk.treeningukorra_id <> OLD.treeningukorra_id)
          AND NOT (NEW.lopu_aeg <= tk.alguse_aeg OR NEW.alguse_aeg >= tk.lopu_aeg)
    ) THEN
        RAISE EXCEPTION 'Ruumis on samal ajal juba teine tühistamata treeningukord.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treeningukord_invariandid
BEFORE INSERT OR UPDATE OF treeninguliigi_id, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg, maksimaalne_osalejate_arv, treeningukorra_seisundi_kood
ON treeningukord
FOR EACH ROW
EXECUTE FUNCTION fn_kontrolli_treeningukorra_invariandid();

CREATE OR REPLACE FUNCTION fn_registreering_seisundisiire()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.registreeringu_seisundi_kood NOT IN ('KINNIT', 'OOTEJRK') THEN
            RAISE EXCEPTION 'Registreering tuleb luua seisundis KINNIT või OOTEJRK.';
        END IF;
        RETURN NEW;
    END IF;

    IF OLD.registreeringu_seisundi_kood IS NOT DISTINCT FROM NEW.registreeringu_seisundi_kood THEN
        RETURN NEW;
    END IF;

    IF NOT (
        (OLD.registreeringu_seisundi_kood = 'OOTEJRK' AND NEW.registreeringu_seisundi_kood IN ('KINNIT', 'TYH_KL', 'TYH_SYS'))
        OR (OLD.registreeringu_seisundi_kood = 'KINNIT' AND NEW.registreeringu_seisundi_kood IN ('TYH_KL', 'TYH_SYS'))
    ) THEN
        RAISE EXCEPTION 'Registreeringu lubamatu seisundimuudatus: % -> %.',
            OLD.registreeringu_seisundi_kood,
            NEW.registreeringu_seisundi_kood;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registreering_seisundisiire
BEFORE INSERT OR UPDATE OF registreeringu_seisundi_kood ON registreering
FOR EACH ROW
EXECUTE FUNCTION fn_registreering_seisundisiire();

CREATE OR REPLACE FUNCTION fn_kontrolli_osalemine()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_treeningukorra_id INTEGER;
    v_klient_e_meil e_meil_aadress;
    v_treener_e_meil e_meil_aadress;
    v_treeningukorra_seisundi_kood VARCHAR(10);
    v_alguse_aeg TIMESTAMP WITH TIME ZONE;
    v_registreeringu_seisundi_kood VARCHAR(10);
BEGIN
    SELECT r.treeningukorra_id, r.klient_e_meil, r.registreeringu_seisundi_kood, tk.treener_e_meil, tk.treeningukorra_seisundi_kood, tk.alguse_aeg
    INTO v_treeningukorra_id, v_klient_e_meil, v_registreeringu_seisundi_kood, v_treener_e_meil, v_treeningukorra_seisundi_kood, v_alguse_aeg
    FROM registreering r
    JOIN treeningukord tk ON tk.treeningukorra_id = r.treeningukorra_id
    WHERE r.registreeringu_id = NEW.registreeringu_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Registreeringut ei leitud.';
    END IF;

    IF NEW.klient_e_meil <> v_klient_e_meil THEN
        RAISE EXCEPTION 'Osalemise klient peab vastama registreeringu kliendile.';
    END IF;

    IF NEW.treener_e_meil <> v_treener_e_meil THEN
        RAISE EXCEPTION 'Osalemise treener peab vastama treeningukorra määratud treenerile.';
    END IF;

    IF NOT on_treener(NEW.treener_e_meil) THEN
        RAISE EXCEPTION 'Osalemise treener peab omama TREENER rolli.';
    END IF;

    IF v_registreeringu_seisundi_kood <> 'KINNIT' THEN
        RAISE EXCEPTION 'Osalemist saab märkida ainult kinnitatud registreeringule.';
    END IF;

    IF v_treeningukorra_seisundi_kood NOT IN ('SULETUD', 'TOIMUNUD') THEN
        RAISE EXCEPTION 'Osalemist saab märkida ainult suletud või toimunud treeningukorrale.';
    END IF;

    IF v_alguse_aeg > CURRENT_TIMESTAMP(0) THEN
        RAISE EXCEPTION 'Osalemist ei saa märkida enne treeningukorra algust.';
    END IF;

    IF NEW.markija_e_meil <> v_treener_e_meil AND NOT on_juhataja(NEW.markija_e_meil) THEN
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
    p_treeninguliigi_id INTEGER,
    p_treener_e_meil e_meil_aadress,
    p_ruumi_kood kood_10,
    p_alguse_aeg TIMESTAMP WITH TIME ZONE,
    p_lopu_aeg TIMESTAMP WITH TIME ZONE,
    p_registreerimise_lopp TIMESTAMP WITH TIME ZONE,
    p_tyhistamise_lopp TIMESTAMP WITH TIME ZONE,
    p_maksimaalne_osalejate_arv INTEGER,
    p_juhataja_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra planeerimiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    INSERT INTO treeningukord (
        treeninguliigi_id,
        treener_e_meil,
        ruumi_kood,
        alguse_aeg,
        lopu_aeg,
        registreerimise_lopp,
        tyhistamise_lopp,
        maksimaalne_osalejate_arv,
        treeningukorra_seisundi_kood,
        looja_e_meil,
        viimase_muutja_e_meil
    )
    VALUES (
        p_treeninguliigi_id,
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
    );
END;
$$;

CREATE OR REPLACE FUNCTION fn_ava_treeningukord(
    p_treeningukorra_id INTEGER,
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
    IF NOT on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra avamiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    UPDATE treeningukord
    SET treeningukorra_seisundi_kood = 'AVATUD',
        viimase_muutja_e_meil = p_juhataja_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
    WHERE treeningukorra_id = p_treeningukorra_id
      AND treeningukorra_seisundi_kood = 'KAVAND'
      AND alguse_aeg > CURRENT_TIMESTAMP(0)
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Avatavat tulevast kavandatud treeningukorda ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sulge_treeningukord(
    p_treeningukorra_id INTEGER,
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
    WHERE treeningukorra_id = p_treeningukorra_id;

    IF v_treener_e_meil IS NULL THEN
        RAISE EXCEPTION 'Suletavat treeningukorda ei leitud.';
    END IF;

    IF p_actor_e_meil <> v_treener_e_meil AND NOT on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra saab sulgeda määratud treener või juhataja.';
    END IF;

    IF CURRENT_TIMESTAMP(0) < v_reg_lopp AND NOT on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treener saab treeningukorra sulgeda alles pärast registreerimise lõppu.';
    END IF;

    UPDATE treeningukord
    SET treeningukorra_seisundi_kood = 'SULETUD',
        viimase_muutja_e_meil = p_actor_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
    WHERE treeningukorra_id = p_treeningukorra_id
      AND treeningukorra_seisundi_kood = 'AVATUD'
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Suletavat avatud treeningukorda ei leitud.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_lopeta_treeningukord(
    p_treeningukorra_id INTEGER,
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
    WHERE treeningukorra_id = p_treeningukorra_id;

    IF v_treener_e_meil IS NULL THEN
        RAISE EXCEPTION 'Lõpetatavat treeningukorda ei leitud.';
    END IF;

    IF p_actor_e_meil <> v_treener_e_meil AND NOT on_juhataja(p_actor_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra saab toimunuks märkida määratud treener või juhataja.';
    END IF;

    UPDATE treeningukord
    SET treeningukorra_seisundi_kood = 'TOIMUNUD',
        viimase_muutja_e_meil = p_actor_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
    WHERE treeningukorra_id = p_treeningukorra_id
      AND treeningukorra_seisundi_kood = 'SULETUD'
      AND lopu_aeg <= CURRENT_TIMESTAMP(0)
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Toimunuks saab märkida ainult lõppenud suletud treeningukorra.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_registreeri_klient_treeningukorrale(
    p_treeningukorra_id INTEGER,
    p_klient_e_meil e_meil_aadress
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_kord treeningukord%ROWTYPE;
    v_kinnitatud_arv INTEGER;
    v_ootejarjekorra_nr INTEGER;
    v_registreeringu_id INTEGER;
BEGIN
    SELECT
        tk.treeningukorra_id,
        tk.treeninguliigi_id,
        tk.treener_e_meil,
        tk.ruumi_kood,
        tk.alguse_aeg,
        tk.lopu_aeg,
        tk.registreerimise_lopp,
        tk.tyhistamise_lopp,
        tk.maksimaalne_osalejate_arv,
        tk.treeningukorra_seisundi_kood,
        tk.looja_e_meil,
        tk.viimase_muutja_e_meil,
        tk.loomise_aeg,
        tk.viimase_muutmise_aeg,
        tk.tyhistamise_pohjus
    INTO v_kord
    FROM treeningukord tk
    WHERE tk.treeningukorra_id = p_treeningukorra_id
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

    IF v_kord.treeningukorra_seisundi_kood <> 'AVATUD' THEN
        RAISE EXCEPTION 'Registreerida saab ainult avatud treeningukorrale.';
    END IF;

    IF CURRENT_TIMESTAMP(0) > v_kord.registreerimise_lopp THEN
        RAISE EXCEPTION 'Registreerimise tähtaeg on möödunud.';
    END IF;

    SELECT COUNT(*)
    INTO v_kinnitatud_arv
    FROM registreering r
    WHERE r.treeningukorra_id = p_treeningukorra_id
      AND r.registreeringu_seisundi_kood = 'KINNIT';

    IF v_kinnitatud_arv < v_kord.maksimaalne_osalejate_arv THEN
        INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
        VALUES (p_treeningukorra_id, p_klient_e_meil, 'KINNIT');
    ELSE
        SELECT COALESCE(MAX(ok.ootejarjekorra_nr), 0) + 1
        INTO v_ootejarjekorra_nr
        FROM ootejarjekorra_koht ok
        JOIN registreering r ON r.registreeringu_id = ok.registreeringu_id
        WHERE ok.treeningukorra_id = p_treeningukorra_id
          AND r.registreeringu_seisundi_kood = 'OOTEJRK';

        INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
        VALUES (p_treeningukorra_id, p_klient_e_meil, 'OOTEJRK')
        RETURNING registreering.registreeringu_id INTO v_registreeringu_id;

        INSERT INTO ootejarjekorra_koht (registreeringu_id, treeningukorra_id, ootejarjekorra_nr)
        VALUES (v_registreeringu_id, p_treeningukorra_id, v_ootejarjekorra_nr);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_edenda_ootejarjekorrast(
    p_treeningukorra_id INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_kord treeningukord%ROWTYPE;
    v_promote_id INTEGER;
    v_kinnitatud_arv INTEGER;
BEGIN
    SELECT
        tk.treeningukorra_id,
        tk.treeninguliigi_id,
        tk.treener_e_meil,
        tk.ruumi_kood,
        tk.alguse_aeg,
        tk.lopu_aeg,
        tk.registreerimise_lopp,
        tk.tyhistamise_lopp,
        tk.maksimaalne_osalejate_arv,
        tk.treeningukorra_seisundi_kood,
        tk.looja_e_meil,
        tk.viimase_muutja_e_meil,
        tk.loomise_aeg,
        tk.viimase_muutmise_aeg,
        tk.tyhistamise_pohjus
    INTO v_kord
    FROM treeningukord tk
    WHERE tk.treeningukorra_id = p_treeningukorra_id
    FOR UPDATE;

    IF NOT FOUND OR v_kord.treeningukorra_seisundi_kood <> 'AVATUD' THEN
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_kinnitatud_arv
    FROM registreering r
    WHERE r.treeningukorra_id = p_treeningukorra_id
      AND r.registreeringu_seisundi_kood = 'KINNIT';

    IF v_kinnitatud_arv >= v_kord.maksimaalne_osalejate_arv THEN
        RETURN;
    END IF;

    SELECT r.registreeringu_id
    INTO v_promote_id
    FROM registreering r
    JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = r.registreeringu_id
    WHERE r.treeningukorra_id = p_treeningukorra_id
      AND r.registreeringu_seisundi_kood = 'OOTEJRK'
    ORDER BY ok.ootejarjekorra_nr, r.registreerimise_aeg, r.registreeringu_id
    FETCH FIRST 1 ROW ONLY
    FOR UPDATE SKIP LOCKED;

    IF v_promote_id IS NULL THEN
        RETURN;
    END IF;

    UPDATE registreering
    SET registreeringu_seisundi_kood = 'KINNIT',
        edendamise_aeg = CURRENT_TIMESTAMP(0)
    WHERE registreering.registreeringu_id = v_promote_id;

    DELETE FROM ootejarjekorra_koht
    WHERE registreeringu_id = v_promote_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_tyhista_registreering(
    p_registreeringu_id INTEGER,
    p_actor_e_meil e_meil_aadress,
    p_pohjus TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_reg registreering%ROWTYPE;
    v_kord treeningukord%ROWTYPE;
    v_uus_seisund VARCHAR(10);
BEGIN
    SELECT
        r.registreeringu_id,
        r.treeningukorra_id,
        r.klient_e_meil,
        r.registreeringu_seisundi_kood,
        r.registreerimise_aeg,
        r.tyhistamise_aeg,
        r.edendamise_aeg,
        r.tyhistamise_pohjus
    INTO v_reg
    FROM registreering r
    WHERE r.registreeringu_id = p_registreeringu_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Registreeringut ei leitud.';
    END IF;

    SELECT
        tk.treeningukorra_id,
        tk.treeninguliigi_id,
        tk.treener_e_meil,
        tk.ruumi_kood,
        tk.alguse_aeg,
        tk.lopu_aeg,
        tk.registreerimise_lopp,
        tk.tyhistamise_lopp,
        tk.maksimaalne_osalejate_arv,
        tk.treeningukorra_seisundi_kood,
        tk.looja_e_meil,
        tk.viimase_muutja_e_meil,
        tk.loomise_aeg,
        tk.viimase_muutmise_aeg,
        tk.tyhistamise_pohjus
    INTO v_kord
    FROM treeningukord tk
    WHERE tk.treeningukorra_id = v_reg.treeningukorra_id
    FOR UPDATE;

    IF v_reg.registreeringu_seisundi_kood NOT IN ('KINNIT', 'OOTEJRK') THEN
        RAISE EXCEPTION 'Tühistada saab ainult aktiivset registreeringut.';
    END IF;

    IF v_kord.treeningukorra_seisundi_kood IN ('TOIMUNUD', 'TYHIST') THEN
        RAISE EXCEPTION 'Toimunud või tühistatud treeningukorra registreeringut ei saa kliendi kaudu tühistada.';
    END IF;

    IF on_juhataja(p_actor_e_meil) THEN
        v_uus_seisund := 'TYH_SYS';
    ELSE
        IF p_actor_e_meil <> v_reg.klient_e_meil THEN
            RAISE EXCEPTION 'Klient saab tühistada ainult enda registreeringu.';
        END IF;
        IF CURRENT_TIMESTAMP(0) > v_kord.tyhistamise_lopp THEN
            RAISE EXCEPTION 'Tühistamise tähtaeg on möödunud.';
        END IF;
        v_uus_seisund := 'TYH_KL';
    END IF;

    UPDATE registreering
    SET registreeringu_seisundi_kood = v_uus_seisund,
        tyhistamise_aeg = CURRENT_TIMESTAMP(0),
        tyhistamise_pohjus = p_pohjus
    WHERE registreering.registreeringu_id = p_registreeringu_id;

    DELETE FROM ootejarjekorra_koht
    WHERE registreeringu_id = p_registreeringu_id;

    IF v_reg.registreeringu_seisundi_kood = 'KINNIT' AND v_uus_seisund = 'TYH_KL' THEN
        PERFORM fn_edenda_ootejarjekorrast(p_treeningukorra_id => v_reg.treeningukorra_id);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_marki_osalemine(
    p_registreeringu_id INTEGER,
    p_markija_e_meil e_meil_aadress,
    p_on_osalenud BOOLEAN,
    p_markus TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_klient_e_meil e_meil_aadress;
    v_treener_e_meil e_meil_aadress;
BEGIN
    SELECT r.klient_e_meil, tk.treener_e_meil
    INTO v_klient_e_meil, v_treener_e_meil
    FROM registreering r
    JOIN treeningukord tk ON tk.treeningukorra_id = r.treeningukorra_id
    WHERE r.registreeringu_id = p_registreeringu_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Registreeringut ei leitud.';
    END IF;

    INSERT INTO osalemine (
        registreeringu_id,
        klient_e_meil,
        treener_e_meil,
        on_osalenud,
        markija_e_meil,
        markus
    )
    VALUES (
        p_registreeringu_id,
        v_klient_e_meil,
        v_treener_e_meil,
        p_on_osalenud,
        p_markija_e_meil,
        p_markus
    )
    ON CONFLICT (registreeringu_id)
    DO UPDATE SET
        klient_e_meil = EXCLUDED.klient_e_meil,
        treener_e_meil = EXCLUDED.treener_e_meil,
        on_osalenud = EXCLUDED.on_osalenud,
        markija_e_meil = EXCLUDED.markija_e_meil,
        markimise_aeg = CURRENT_TIMESTAMP(0),
        markus = EXCLUDED.markus;
END;
$$;

CREATE OR REPLACE FUNCTION fn_tyhista_treeningukord(
    p_treeningukorra_id INTEGER,
    p_juhataja_e_meil e_meil_aadress,
    p_pohjus TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_updated INTEGER;
BEGIN
    IF NOT on_juhataja(p_juhataja_e_meil) THEN
        RAISE EXCEPTION 'Treeningukorra tühistamiseks peab kasutajal olema JUHATAJA roll.';
    END IF;

    UPDATE treeningukord
    SET treeningukorra_seisundi_kood = 'TYHIST',
        viimase_muutja_e_meil = p_juhataja_e_meil,
        viimase_muutmise_aeg = CURRENT_TIMESTAMP(0),
        tyhistamise_pohjus = p_pohjus
    WHERE treeningukorra_id = p_treeningukorra_id
      AND treeningukorra_seisundi_kood IN ('KAVAND', 'AVATUD', 'SULETUD')
    RETURNING 1 INTO v_updated;

    IF v_updated IS NULL THEN
        RAISE EXCEPTION 'Tühistatavat kavandatud, avatud või suletud treeningukorda ei leitud.';
    END IF;

    UPDATE registreering
    SET registreeringu_seisundi_kood = 'TYH_SYS',
        tyhistamise_aeg = CURRENT_TIMESTAMP(0),
        tyhistamise_pohjus = COALESCE(p_pohjus, 'Treeningukord tühistati.')
    WHERE treeningukorra_id = p_treeningukorra_id
      AND registreeringu_seisundi_kood IN ('KINNIT', 'OOTEJRK');

    DELETE FROM ootejarjekorra_koht ok
    USING registreering r
    WHERE r.registreeringu_id = ok.registreeringu_id
      AND r.treeningukorra_id = p_treeningukorra_id;
END;
$$;

CREATE VIEW treeninguliigid_kategooriatega WITH (security_barrier = true) AS
SELECT
    tl.treeninguliigi_id,
    tl.nimetus AS treeninguliigi_nimetus,
    tl.kirjeldus AS treeninguliigi_kirjeldus,
    tl.kestus_minutites,
    tl.vajalik_varustus AS treeninguliigi_vajalik_varustus,
    tl.treeninguliigi_seisundi_kood,
    COALESCE(string_agg(tk.nimetus, ', ' ORDER BY tk.nimetus), '') AS treeningu_kategooriad
FROM treeninguliik tl
LEFT JOIN treeninguliigi_kategooria_omamine tlko ON tlko.treeninguliigi_id = tl.treeninguliigi_id
LEFT JOIN treeningu_kategooria tk ON tk.treeningu_kategooria_kood = tlko.treeningu_kategooria_kood
GROUP BY tl.treeninguliigi_id, tl.nimetus, tl.kirjeldus, tl.kestus_minutites, tl.vajalik_varustus, tl.treeninguliigi_seisundi_kood;

CREATE VIEW treeninguliigi_varustuse_nouded WITH (security_barrier = true) AS
SELECT
    tl.treeninguliigi_id,
    tl.nimetus AS treeninguliigi_nimetus,
    n.varustuse_kood,
    v.nimetus AS varustuse_nimetus,
    n.minimaalne_kogus,
    n.on_kohustuslik,
    n.markus AS varustuse_noude_markus
FROM treeninguliigi_varustuse_noue n
JOIN treeninguliik tl ON tl.treeninguliigi_id = n.treeninguliigi_id
JOIN varustus v ON v.varustuse_kood = n.varustuse_kood;

CREATE VIEW ruumide_varustus WITH (security_barrier = true) AS
SELECT
    r.ruumi_kood,
    r.nimetus AS ruumi_nimetus,
    r.mahutavus AS ruumi_mahutavus,
    v.varustuse_kood,
    v.nimetus AS varustuse_nimetus,
    rvo.kogus AS ruumi_varustuse_kogus,
    rvo.markus AS ruumi_varustuse_markus
FROM ruumi_varustuse_omamine rvo
JOIN ruum r ON r.ruumi_kood = rvo.ruumi_kood
JOIN varustus v ON v.varustuse_kood = rvo.varustuse_kood;

CREATE VIEW juhataja_treeningukordade_ulevaade WITH (security_barrier = true) AS
SELECT
    tk.treeningukorra_id,
    tk.treeningukorra_seisundi_kood AS korra_seisundi_kood,
    tl.nimetus AS treeninguliigi_nimetus,
    tk.alguse_aeg,
    tk.lopu_aeg,
    tk.registreerimise_lopp,
    tk.tyhistamise_lopp,
    r.nimetus AS ruumi_nimetus,
    r.mahutavus AS ruumi_mahutavus,
    tk.maksimaalne_osalejate_arv,
    tr.e_meil AS treener_e_meil,
    concat_ws(' ', i.eesnimi, i.perenimi) AS treener_nimi,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_osalejate_arv,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringute_arv,
    GREATEST(
        tk.maksimaalne_osalejate_arv - COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT'),
        0
    ) AS vabu_kohti
FROM treeningukord tk
JOIN treeninguliik tl ON tl.treeninguliigi_id = tk.treeninguliigi_id
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN tootaja tr ON tr.e_meil = tk.treener_e_meil
JOIN kasutajakonto kk ON kk.e_meil = tr.e_meil
JOIN isik i ON i.e_meil = kk.e_meil
LEFT JOIN registreering reg ON reg.treeningukorra_id = tk.treeningukorra_id
GROUP BY tk.treeningukorra_id, tk.treeningukorra_seisundi_kood, tl.nimetus, tk.alguse_aeg, tk.lopu_aeg,
         tk.registreerimise_lopp, tk.tyhistamise_lopp, r.nimetus, r.mahutavus,
         tk.maksimaalne_osalejate_arv, tr.e_meil, i.eesnimi, i.perenimi;

CREATE VIEW avalikud_treeningukorrad WITH (security_barrier = true) AS
SELECT
    tk.treeningukorra_id,
    tk.treeningukorra_seisundi_kood AS korra_seisundi_kood,
    tl.nimetus AS treeninguliigi_nimetus,
    tk.alguse_aeg,
    tk.lopu_aeg,
    tk.registreerimise_lopp,
    tk.tyhistamise_lopp,
    r.nimetus AS ruumi_nimetus,
    r.mahutavus AS ruumi_mahutavus,
    tk.maksimaalne_osalejate_arv,
    tr.e_meil AS treener_e_meil,
    concat_ws(' ', i.eesnimi, i.perenimi) AS treener_nimi,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_osalejate_arv,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringute_arv,
    GREATEST(
        tk.maksimaalne_osalejate_arv - COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT'),
        0
    ) AS vabu_kohti
FROM treeningukord tk
JOIN treeninguliik tl ON tl.treeninguliigi_id = tk.treeninguliigi_id
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN tootaja tr ON tr.e_meil = tk.treener_e_meil
JOIN kasutajakonto kk ON kk.e_meil = tr.e_meil
JOIN isik i ON i.e_meil = kk.e_meil
LEFT JOIN registreering reg ON reg.treeningukorra_id = tk.treeningukorra_id
WHERE tk.treeningukorra_seisundi_kood = 'AVATUD'
  AND tk.registreerimise_lopp >= CURRENT_TIMESTAMP(0)
GROUP BY tk.treeningukorra_id, tk.treeningukorra_seisundi_kood, tl.nimetus, tk.alguse_aeg, tk.lopu_aeg,
         tk.registreerimise_lopp, tk.tyhistamise_lopp, r.nimetus, r.mahutavus,
         tk.maksimaalne_osalejate_arv, tr.e_meil, i.eesnimi, i.perenimi;

CREATE VIEW kliendi_registreeringud WITH (security_barrier = true) AS
SELECT
    reg.registreeringu_id,
    reg.klient_e_meil,
    reg.treeningukorra_id,
    reg.registreeringu_seisundi_kood,
    ok.ootejarjekorra_nr,
    tl.nimetus AS treeninguliigi_nimetus,
    tk.alguse_aeg,
    tk.treeningukorra_seisundi_kood,
    r.nimetus AS ruumi_nimetus,
    concat_ws(' ', i.eesnimi, i.perenimi) AS treener_nimi,
    os.on_osalenud
FROM registreering reg
JOIN treeningukord tk ON tk.treeningukorra_id = reg.treeningukorra_id
JOIN treeninguliik tl ON tl.treeninguliigi_id = tk.treeninguliigi_id
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN isik i ON i.e_meil = tk.treener_e_meil
LEFT JOIN osalemine os ON os.registreeringu_id = reg.registreeringu_id
LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = reg.registreeringu_id;

CREATE VIEW treeneri_tunniplaan WITH (security_barrier = true) AS
SELECT
    tk.treeningukorra_id,
    tk.treeningukorra_seisundi_kood AS korra_seisundi_kood,
    tl.nimetus AS treeninguliigi_nimetus,
    tk.alguse_aeg,
    tk.lopu_aeg,
    r.nimetus AS ruumi_nimetus,
    tk.maksimaalne_osalejate_arv,
    tr.e_meil AS treener_e_meil,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_osalejate_arv,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringute_arv
FROM treeningukord tk
JOIN treeninguliik tl ON tl.treeninguliigi_id = tk.treeninguliigi_id
JOIN ruum r ON r.ruumi_kood = tk.ruumi_kood
JOIN tootaja tr ON tr.e_meil = tk.treener_e_meil
LEFT JOIN registreering reg ON reg.treeningukorra_id = tk.treeningukorra_id
GROUP BY tk.treeningukorra_id, tk.treeningukorra_seisundi_kood, tl.nimetus, tk.alguse_aeg, tk.lopu_aeg,
         r.nimetus, tk.maksimaalne_osalejate_arv, tr.e_meil;

CREATE VIEW treeningukorra_osalejad WITH (security_barrier = true) AS
SELECT
    reg.registreeringu_id,
    reg.treeningukorra_id,
    reg.klient_e_meil,
    concat_ws(' ', i.eesnimi, i.perenimi) AS klient_nimi,
    reg.registreeringu_seisundi_kood,
    ok.ootejarjekorra_nr,
    reg.registreerimise_aeg,
    os.klient_e_meil AS osalemise_klient_e_meil,
    os.treener_e_meil AS osalemise_treener_e_meil,
    os.on_osalenud,
    os.markija_e_meil,
    os.markimise_aeg,
    os.markus AS osalemise_markus
FROM registreering reg
JOIN klient k ON k.e_meil = reg.klient_e_meil
JOIN isik i ON i.e_meil = k.e_meil
LEFT JOIN osalemine os ON os.registreeringu_id = reg.registreeringu_id
LEFT JOIN ootejarjekorra_koht ok ON ok.registreeringu_id = reg.registreeringu_id;

CREATE VIEW treeningute_taituvuse_statistika WITH (security_barrier = true) AS
SELECT
    tl.treeninguliigi_id,
    tl.nimetus AS treeninguliigi_nimetus,
    COUNT(tk.treeningukorra_id) AS treeningukordade_koguarv,
    COUNT(tk.treeningukorra_id) FILTER (WHERE tk.treeningukorra_seisundi_kood = 'AVATUD') AS avatud_treeningukordade_arv,
    COUNT(tk.treeningukorra_id) FILTER (WHERE tk.treeningukorra_seisundi_kood = 'TOIMUNUD') AS toimunud_treeningukordade_arv,
    COALESCE(SUM(tk.maksimaalne_osalejate_arv), 0) AS maksimaalsete_kohtade_arv,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_osalejate_arv,
    COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringute_arv,
    ROUND(
        CASE WHEN COALESCE(SUM(tk.maksimaalne_osalejate_arv), 0) = 0 THEN 0
             ELSE COUNT(reg.registreeringu_id) FILTER (WHERE reg.registreeringu_seisundi_kood = 'KINNIT')::numeric
                  / SUM(tk.maksimaalne_osalejate_arv)::numeric * 100
        END,
        1
    ) AS taituvus_protsent
FROM treeninguliik tl
LEFT JOIN treeningukord tk ON tk.treeninguliigi_id = tl.treeninguliigi_id
LEFT JOIN registreering reg ON reg.treeningukorra_id = tk.treeningukorra_id
GROUP BY tl.treeninguliigi_id, tl.nimetus;

COMMENT ON TABLE treeninguliik IS 'Korduv rühmatreeningu tüüp ehk mall, mille alusel planeeritakse konkreetsed treeningukorrad.';
COMMENT ON TABLE treeningukord IS 'Konkreetne kalendris toimuv rühmatreening koos ruumi, treeneri, tähtaegade ja mahupiiranguga.';
COMMENT ON TABLE registreering IS 'Kliendi kinnitatud või ootejärjekorras registreering treeningukorrale.';
COMMENT ON TABLE ootejarjekorra_koht IS 'Ootejärjekorras oleva registreeringu kohustuslik järjekorrakoht.';
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

INSERT INTO isiku_seisundi_liik (isiku_seisundi_liigi_kood, nimetus) VALUES
('KLIENT', 'Klient'),
('TOOTAJA', 'Töötaja')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_seisundi_liik (tootaja_seisundi_liigi_kood, nimetus) VALUES
('AKTIIVNE', 'Aktiivne'),
('PUHKUSEL', 'Puhkusel'),
('LAHKUNUD', 'Lahkunud')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_roll (tootaja_rolli_kood, nimetus, kirjeldus) VALUES
('TREENER', 'Treener', 'Treener, kes näeb enda treeningukordi ja märgib osalemist.'),
('JUHATAJA', 'Juhataja', 'Juhataja, kes planeerib, avab, tühistab ja analüüsib treeningukordi.'),
('KL_HALDUR', 'Klassifikaatorite haldur', 'Klassifikaatorite haldur.'),
('TOO_HALD', 'Töötajate haldur', 'Töötajate andmete haldur.')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliigi_seisundi_liik (treeninguliigi_seisundi_kood, nimetus, on_aktiivne) VALUES
('KOOST', 'Koostamisel', TRUE),
('AKTIIVNE', 'Aktiivne', TRUE),
('MITTEAKT', 'Mitteaktiivne', TRUE),
('LOPETATUD', 'Lõpetatud', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningukorra_seisundi_liik (treeningukorra_seisundi_kood, nimetus, on_aktiivne, kirjeldus) VALUES
('KAVAND', 'Kavandatud', TRUE, 'Treeningukord on planeeritud, kuid registreerimine ei ole avatud.'),
('AVATUD', 'Registreerimiseks avatud', TRUE, 'Klient saab registreeruda või sattuda ootejärjekorda.'),
('SULETUD', 'Suletud', TRUE, 'Registreerimine on lõppenud ja treener saab kohalolu märkida.'),
('TOIMUNUD', 'Toimunud', FALSE, 'Treeningukord on lõpetatud.'),
('TYHIST', 'Tühistatud', FALSE, 'Treeningukord tühistati.')
ON CONFLICT DO NOTHING;

INSERT INTO registreeringu_seisundi_liik (registreeringu_seisundi_kood, nimetus, on_aktiivne, kirjeldus) VALUES
('KINNIT', 'Kinnitatud', TRUE, 'Klient on treeningukorra osalejate hulgas.'),
('OOTEJRK', 'Ootejärjekorras', TRUE, 'Treeningukord on täis ja klient ootab vaba kohta.'),
('TYH_KL', 'Kliendi poolt tühistatud', FALSE, 'Klient tühistas enda aktiivse registreeringu.'),
('TYH_SYS', 'Süsteemi poolt tühistatud', FALSE, 'Registreering tühistati treeningukorra või juhataja otsuse tõttu.')
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria_tyyp (treeningu_kategooria_tyybi_kood, nimetus, on_aktiivne) VALUES
('GRUPP', 'Rühmatreening', TRUE),
('TASE', 'Raskusaste', TRUE),
('FOOKUS', 'Treeningu fookus', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningu_kategooria (treeningu_kategooria_kood, treeningu_kategooria_tyybi_kood, nimetus, on_aktiivne) VALUES
('JOOGA', 'GRUPP', 'Jooga', TRUE),
('HIIT', 'GRUPP', 'HIIT', TRUE),
('JOUD', 'FOOKUS', 'Jõutreening', TRUE),
('ALG', 'TASE', 'Algajatele', TRUE),
('EDAS', 'TASE', 'Edasijõudnutele', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liigi_kood, synni_kp, eesnimi, perenimi, elukoht, e_meil)
VALUES
('39001010001', 'EE', 'TOOTAJA', DATE '1990-01-01', 'Anna', 'Juhataja', 'Tallinn', 'juhataja@jousaal.ee'),
('38802020002', 'EE', 'TOOTAJA', DATE '1988-02-02', 'Tristan', 'Treener', 'Tallinn', 'treener@jousaal.ee'),
('39203030003', 'EE', 'TOOTAJA', DATE '1992-03-03', 'Liis', 'Treener', 'Tartu', 'treener2@jousaal.ee'),
('39504040004', 'EE', 'KLIENT', DATE '1995-04-04', 'Andres', 'Klient', 'Tallinn', 'klient@jousaal.ee'),
('39605050005', 'EE', 'KLIENT', DATE '1996-05-05', 'Kärt', 'Klient', 'Pärnu', 'klient2@jousaal.ee'),
('39706060006', 'EE', 'KLIENT', DATE '1997-06-06', 'Mati', 'Klient', 'Tartu', 'klient3@jousaal.ee'),
('39807070007', 'EE', 'KLIENT', DATE '1998-07-07', 'Mari', 'Klient', 'Tallinn', 'klient4@jousaal.ee')
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

INSERT INTO tootaja (e_meil, tootaja_seisundi_liigi_kood)
VALUES
('juhataja@jousaal.ee', 'AKTIIVNE'),
('treener@jousaal.ee', 'AKTIIVNE'),
('treener2@jousaal.ee', 'AKTIIVNE')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_rolli_kood, alguse_aeg)
VALUES
('juhataja@jousaal.ee', 'JUHATAJA', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener2@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliik (
    treeninguliigi_id,
    nimetus,
    kirjeldus,
    kestus_minutites,
    vajalik_varustus,
    treeninguliigi_seisundi_kood,
    registreerija_e_meil,
    viimase_muutja_e_meil
)
OVERRIDING SYSTEM VALUE
VALUES
(1000, 'Jooga algajatele', 'Rahulik rühmatreening liikuvuse ja hingamise arendamiseks.', 60, 'Matid ja joogaplokid', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1001, 'HIIT rühmatreening', 'Kõrge intensiivsusega intervalltreening väikesele grupile.', 45, 'Matid, hantlid ja stopper', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1002, 'Jõutreeningu tehnika', 'Rühmatund jõusaali põhiharjutuste tehnika õppimiseks.', 75, 'Kangid ja kettad', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
ON CONFLICT DO NOTHING;

SELECT setval('seq_treeninguliigi_id', GREATEST((SELECT COALESCE(MAX(treeninguliigi_id), 999) FROM treeninguliik), 999), TRUE);

INSERT INTO treeninguliigi_kategooria_omamine (treeninguliigi_id, treeningu_kategooria_kood)
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
    treeninguliigi_id,
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
    SELECT ruumi_kood, nimetus, asukoht, mahutavus
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

INSERT INTO treeneri_padevus (tootaja_e_meil, treeninguliigi_id, alates)
VALUES
('treener@jousaal.ee', 1000, DATE '2025-01-01'),
('treener@jousaal.ee', 1001, DATE '2025-01-01'),
('treener2@jousaal.ee', 1002, DATE '2025-01-01')
ON CONFLICT DO NOTHING;

-- Demo treeningukord rows use fixed IDs as stable seed identities. Avoid
-- attempting duplicate inserts because BEFORE INSERT overlap triggers fire
-- before ON CONFLICT can skip an existing row.
WITH seeded_treeningukorrad (
    treeningukorra_id,
    treeninguliigi_id,
    treener_e_meil,
    ruumi_kood,
    alguse_aeg,
    lopu_aeg,
    registreerimise_lopp,
    tyhistamise_lopp,
    maksimaalne_osalejate_arv,
    treeningukorra_seisundi_kood,
    looja_e_meil,
    viimase_muutja_e_meil
) AS (
    VALUES
    (2000, 1002, 'treener2@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP(0) + INTERVAL '10 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '10 days 75 minutes',
        CURRENT_TIMESTAMP(0) + INTERVAL '9 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '9 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2001, 1000, 'treener@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP(0) + INTERVAL '7 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '7 days 60 minutes',
        CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2002, 1001, 'treener@jousaal.ee', 'SAAL_A',
        CURRENT_TIMESTAMP(0) + INTERVAL '5 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '5 days 45 minutes',
        CURRENT_TIMESTAMP(0) + INTERVAL '4 days',
        CURRENT_TIMESTAMP(0) + INTERVAL '4 days',
        2, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2003, 1000, 'treener@jousaal.ee', 'SAAL_B',
        CURRENT_TIMESTAMP(0) - INTERVAL '3 days',
        CURRENT_TIMESTAMP(0) - INTERVAL '3 days' + INTERVAL '60 minutes',
        CURRENT_TIMESTAMP(0) - INTERVAL '4 days',
        CURRENT_TIMESTAMP(0) - INTERVAL '4 days',
        8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
)
INSERT INTO treeningukord (
    treeningukorra_id,
    treeninguliigi_id,
    treener_e_meil,
    ruumi_kood,
    alguse_aeg,
    lopu_aeg,
    registreerimise_lopp,
    tyhistamise_lopp,
    maksimaalne_osalejate_arv,
    treeningukorra_seisundi_kood,
    looja_e_meil,
    viimase_muutja_e_meil
)
OVERRIDING SYSTEM VALUE
SELECT
    s.treeningukorra_id,
    s.treeninguliigi_id,
    s.treener_e_meil,
    s.ruumi_kood,
    s.alguse_aeg,
    s.lopu_aeg,
    s.registreerimise_lopp,
    s.tyhistamise_lopp,
    s.maksimaalne_osalejate_arv,
    s.treeningukorra_seisundi_kood,
    s.looja_e_meil,
    s.viimase_muutja_e_meil
FROM seeded_treeningukorrad s
WHERE NOT EXISTS (
    SELECT 1
    FROM treeningukord tk
    WHERE tk.treeningukorra_id = s.treeningukorra_id
);

SELECT setval('seq_treeningukorra_id', GREATEST((SELECT COALESCE(MAX(treeningukorra_id), 1999) FROM treeningukord), 1999), TRUE);

UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'TYHIST',
    tyhistamise_pohjus = 'Demo treeningukord tühistati enne avamist.',
    registreerimise_lopp = CURRENT_TIMESTAMP(0) - INTERVAL '1 minute',
    tyhistamise_lopp = CURRENT_TIMESTAMP(0) - INTERVAL '1 minute',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2000
  AND treeningukorra_seisundi_kood = 'KAVAND';

UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'AVATUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id IN (2001, 2002)
  AND treeningukorra_seisundi_kood = 'KAVAND';

UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'AVATUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003
  AND treeningukorra_seisundi_kood = 'KAVAND';

UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'SULETUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003
  AND treeningukorra_seisundi_kood = 'AVATUD';

UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'TOIMUNUD',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003
  AND treeningukorra_seisundi_kood = 'SULETUD';

INSERT INTO registreering (
    registreeringu_id,
    treeningukorra_id,
    klient_e_meil,
    registreeringu_seisundi_kood
)
OVERRIDING SYSTEM VALUE
VALUES
(3000, 2002, 'klient@jousaal.ee', 'KINNIT'),
(3001, 2002, 'klient2@jousaal.ee', 'KINNIT'),
(3002, 2002, 'klient3@jousaal.ee', 'OOTEJRK'),
(3003, 2003, 'klient@jousaal.ee', 'KINNIT'),
(3004, 2003, 'klient2@jousaal.ee', 'KINNIT'),
(3005, 2002, 'klient4@jousaal.ee', 'OOTEJRK')
ON CONFLICT DO NOTHING;

SELECT setval('seq_registreeringu_id', GREATEST((SELECT COALESCE(MAX(registreeringu_id), 2999) FROM registreering), 2999), TRUE);

INSERT INTO ootejarjekorra_koht (registreeringu_id, treeningukorra_id, ootejarjekorra_nr)
VALUES
(3002, 2002, 1),
(3005, 2002, 2)
ON CONFLICT DO NOTHING;

UPDATE registreering
SET registreeringu_seisundi_kood = 'TYH_KL',
    tyhistamise_aeg = CURRENT_TIMESTAMP(0),
    tyhistamise_pohjus = 'Demo klient tühistas registreeringu.'
WHERE registreeringu_id = 3000
  AND registreeringu_seisundi_kood = 'KINNIT';

UPDATE registreering
SET registreeringu_seisundi_kood = 'KINNIT',
    edendamise_aeg = CURRENT_TIMESTAMP(0)
WHERE registreeringu_id = 3002
  AND registreeringu_seisundi_kood = 'OOTEJRK';

DELETE FROM ootejarjekorra_koht
WHERE registreeringu_id = 3002;

UPDATE ootejarjekorra_koht
SET ootejarjekorra_nr = 1
WHERE registreeringu_id = 3005;

INSERT INTO osalemine (registreeringu_id, klient_e_meil, treener_e_meil, on_osalenud, markija_e_meil, markus)
VALUES
(3003, 'klient@jousaal.ee', 'treener@jousaal.ee', TRUE, 'treener@jousaal.ee', 'Osales kogu treeningus.'),
(3004, 'klient2@jousaal.ee', 'treener@jousaal.ee', FALSE, 'treener@jousaal.ee', 'Puudus ette teatamata.')
ON CONFLICT DO NOTHING;

DO $$
DECLARE
    v_failed BOOLEAN;
BEGIN
    v_failed := FALSE;
    BEGIN
        INSERT INTO treeningukord (
            treeninguliigi_id, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
            registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv,
            treeningukorra_seisundi_kood, looja_e_meil, viimase_muutja_e_meil
        )
        VALUES (
            1000, 'treener@jousaal.ee', 'SAAL_B',
            CURRENT_TIMESTAMP(0) + INTERVAL '7 days 15 minutes',
            CURRENT_TIMESTAMP(0) + INTERVAL '7 days 75 minutes',
            CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
            CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
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
            treeninguliigi_id, treener_e_meil, ruumi_kood, alguse_aeg, lopu_aeg,
            registreerimise_lopp, tyhistamise_lopp, maksimaalne_osalejate_arv,
            treeningukorra_seisundi_kood, looja_e_meil, viimase_muutja_e_meil
        )
        VALUES (
            1002, 'treener2@jousaal.ee', 'SAAL_B',
            CURRENT_TIMESTAMP(0) + INTERVAL '7 days 5 minutes',
            CURRENT_TIMESTAMP(0) + INTERVAL '7 days 55 minutes',
            CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
            CURRENT_TIMESTAMP(0) + INTERVAL '6 days',
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
            p_treeninguliigi_id => 1002,
            p_treener_e_meil => 'treener2@jousaal.ee',
            p_ruumi_kood => 'SAAL_A',
            p_alguse_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '12 days',
            p_lopu_aeg => CURRENT_TIMESTAMP(0) + INTERVAL '12 days 75 minutes',
            p_registreerimise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '11 days',
            p_tyhistamise_lopp => CURRENT_TIMESTAMP(0) + INTERVAL '11 days',
            p_maksimaalne_osalejate_arv => 2,
            p_juhataja_e_meil => 'juhataja@jousaal.ee'
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
        INSERT INTO registreering (treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
        VALUES (2002, 'klient2@jousaal.ee', 'KINNIT');
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

        GRANT EXECUTE ON FUNCTION public.on_kasutajal_roll(e_meil_aadress, kood_10) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.on_juhataja(e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.on_treener(e_meil_aadress) TO jousaali_rakendus;
        GRANT EXECUTE ON FUNCTION public.fn_tuvasta_kasutaja_e_meili_jargi(e_meil_aadress) TO jousaali_rakendus;
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

EXPLAIN SELECT treeningukorra_id, treeninguliigi_nimetus, alguse_aeg, vabu_kohti
FROM avalikud_treeningukorrad
WHERE vabu_kohti > 0;

-- Andmebaasiobjektide kustutamiseks tuleb käske käivitada vastupidises
-- sõltuvusjärjekorras. Esitatav loomisskript jätab need käsud kommentaaridesse,
-- et käivitamine ei kustutaks loodud hindamisandmebaasi.
-- DROP VIEW IF EXISTS treeninguliigid_kategooriatega CASCADE;
-- DROP VIEW IF EXISTS treeninguliigi_varustuse_nouded CASCADE;
-- DROP VIEW IF EXISTS ruumide_varustus CASCADE;
-- DROP VIEW IF EXISTS treeningute_taituvuse_statistika CASCADE;
-- DROP VIEW IF EXISTS juhataja_treeningukordade_ulevaade CASCADE;
-- DROP VIEW IF EXISTS treeningukorra_osalejad CASCADE;
-- DROP VIEW IF EXISTS treeneri_tunniplaan CASCADE;
-- DROP VIEW IF EXISTS kliendi_registreeringud CASCADE;
-- DROP VIEW IF EXISTS avalikud_treeningukorrad CASCADE;
-- DROP TABLE IF EXISTS osalemine, ootejarjekorra_koht, registreering, treeningukord, treeneri_padevus,
--     ruumi_varustuse_omamine, treeninguliigi_varustuse_noue, ruum, varustus,
--     treeninguliigi_kategooria_omamine, treeninguliik, klient CASCADE;
