-- Jõusaali Infosüsteemi - Testimandmete skript
-- Kasutage seda skripti andmebaasi testimiseks

-- Klassifikaatorite lisamine (kui pole veel)
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
('TREENER', 'Treener', 'Treener, kes registreerib ja juhendab treeninguid'),
('JUHATAJA', 'Juhataja', 'Juhtkonna liige, kes jälgib treeningu portfelli'),
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

-- Testimiskasutajad - parooliräsid on näidisandmetes juba olemas.
-- Kasutage: python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('parool', method='pbkdf2:sha256'))"

-- Isikud
INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, eesnimi, perenimi, e_meil)
VALUES
('12345678901', 'EE', 'TOOTAJA', '1990-01-01', 'Tristan', 'Treener', 'treener@jousaal.ee'),
('12345678902', 'EE', 'TOOTAJA', '1985-06-15', 'Anna', 'Juhataja', 'juhataja@jousaal.ee'),
('12345678903', 'EE', 'KLIENT', '1995-03-20', 'Andres', 'Klient', 'klient@jousaal.ee'),
('12345678904', 'EE', 'KLIENT', '2000-12-10', 'Kärt', 'Uudistaja', 'uudistaja@jousaal.ee')
ON CONFLICT DO NOTHING;

-- Kasutajakonod (paroolid: treener123, juhataja123, klient123, uudistaja123)
-- Parooliräsid on loodud portatiivse pbkdf2:sha256 meetodiga.
INSERT INTO kasutajakonto (e_meil, parool, on_aktiivne)
VALUES
('treener@jousaal.ee', 'pbkdf2:sha256:600000$qGrjekABIBB0g8pG$4272ce1a72ccbac241b1495117c3d283d55c610f1bc07b94ac360f92fd46a5f8', TRUE),
('juhataja@jousaal.ee', 'pbkdf2:sha256:600000$NGnXTK9mS91J7f0j$584635e60de4cf6f7c5118e432d070a6c8637293d1d0e883f09804c42f947391', TRUE),
('klient@jousaal.ee', 'pbkdf2:sha256:600000$B5iUw7q4jcv37X7p$4ed6374c3e1c0ef86063fa0a1033a4fcf780b5476a769a2b8bb19f89fbfbc1b2', TRUE),
('uudistaja@jousaal.ee', 'pbkdf2:sha256:600000$LwatF4tC4eFejrx0$0ee7226e2c2a25ab2645c94db4f475e00e97cec4ac5aed69f270de751c5294b4', TRUE)
ON CONFLICT DO NOTHING;

-- Töötajad
INSERT INTO tootaja (e_meil, tootaja_seisundi_liik_kood)
VALUES
('treener@jousaal.ee', 'AKTIIVNE'),
('juhataja@jousaal.ee', 'AKTIIVNE')
ON CONFLICT DO NOTHING;

-- Töötaja rollide omamine
INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_roll_kood, alguse_aeg)
VALUES
('treener@jousaal.ee', 'TREENER', NOW()),
('juhataja@jousaal.ee', 'JUHATAJA', NOW()),
('juhataja@jousaal.ee', 'KL_HALDUR', NOW())
ON CONFLICT DO NOTHING;

-- Näidistreeningud
INSERT INTO treening (
    treeningu_kood, treeningu_seisundi_liik_kood, registreerija_e_meil,
    viimase_muutja_e_meil, nimetus, kirjeldus, kestus_minutites,
    maksimaalne_osalejate_arv, vajalik_varustus, hind
)
VALUES
(
    1, 'AKTIIVNE', 'treener@jousaal.ee', 'treener@jousaal.ee',
    'Jõutreening algajatele',
    'Põhiline jõutreening, mis keskendub tehnikale ja tugevuse arendamisele. Sobib algajatele ja kogenud treening harrastajatele.',
    60, 12, 'Hantlid, ribad, matid', 15.00
),
(
    2, 'AKTIIVNE', 'treener@jousaal.ee', 'treener@jousaal.ee',
    'Yoga ja painduvus',
    'Rahustav ja painduvust arendav treening, mis parandab keha valmisolekut ja vaimset heaolu.',
    75, 15, 'Matid, plokid, rihmad', 12.00
),
(
    3, 'OOTEL', 'treener@jousaal.ee', 'treener@jousaal.ee',
    'HIIT treening',
    'Intensiivne intervalltreening, mis parandab kardiovaskulaarset vormi ja kulutab palju kaloreid.',
    45, 10, 'Hantlid, sangpommid, matid', 18.00
)
ON CONFLICT DO NOTHING;

-- Treeningu kategooriad
INSERT INTO treeningu_kategooria_omamine (treeningu_kood, treeningu_kategooria_kood)
VALUES
(1, 'JÕUD'),
(2, 'GRUPP'),
(3, 'KARDIO')
ON CONFLICT DO NOTHING;

-- Näita testandmeid
SELECT 'Testandmed on lisatud edukalt.';
SELECT 'Kasutajad:';
SELECT e_meil, COUNT(*) FROM kasutajakonto GROUP BY e_meil;
SELECT 'Treeningud:';
SELECT treeningu_kood, nimetus, hind FROM treening;
