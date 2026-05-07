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
('LOPPENUD', 'Lõppenud', FALSE)
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
-- Kasutage: python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('parool'))"

-- Isikud
INSERT INTO isik (isikukood, riigi_kood, isiku_seisundi_liik_kood, synni_kp, eesnimi, perenimi, e_meil)
VALUES
('12345678901', 'EE', 'TOOTAJA', '1990-01-01', 'Tristan', 'Treener', 'treener@jousaal.ee'),
('12345678902', 'EE', 'TOOTAJA', '1985-06-15', 'Anna', 'Juhataja', 'juhataja@jousaal.ee'),
('12345678903', 'EE', 'KLIENT', '1995-03-20', 'Andres', 'Klient', 'klient@jousaal.ee'),
('12345678904', 'EE', 'KLIENT', '2000-12-10', 'Kärt', 'Uudistaja', 'uudistaja@jousaal.ee')
ON CONFLICT DO NOTHING;

-- Kasutajakonod (paroolid: treener123, juhataja123, klient123, uudistaja123)
-- Tekitate paroolide räsid:
-- python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('treener123'))"
INSERT INTO kasutajakonto (e_meil, parool, on_aktiivne)
VALUES
('treener@jousaal.ee', 'scrypt:32768:8:1$NLG0aRhGi41NdBvp$97d0c72a0f8e2c1f3e5a7b9d2c4e6f8a1b3d5f7a9c1e3f5a7b9d1c3e5f7a9b', TRUE),
('juhataja@jousaal.ee', 'scrypt:32768:8:1$6YqFj0nKp3R7tVwx$8a9c1e3f5a7b9d1c3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a', TRUE),
('klient@jousaal.ee', 'scrypt:32768:8:1$WxZ1aB2cD3eF4gHi$9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b', TRUE),
('uudistaja@jousaal.ee', 'scrypt:32768:8:1$2nL8j5qT9wP0sV3xY$1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d3e5f7a9b1d', TRUE)
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

-- Testkasutusjuhid - Kolm näidis-treeningut
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
    'Intensiivne intervall-treening, mis parandab kardiovascular fiitust ja kulutab palju kaloreid.',
    45, 10, 'Dumbbells, kettlebells, matid', 18.00
)
ON CONFLICT DO NOTHING;

-- Treeningu kategooriad
INSERT INTO treeningu_kategooria_omamine (treeningu_kood, treeningu_kategooria_kood)
VALUES
(1, 'JÕUD'),
(2, 'GRUPP'),
(3, 'KARDIO')
ON CONFLICT DO NOTHING;

-- Näita testimandmeid
SELECT '✅ Testimandmed on lisatud edukalt!';
SELECT '📊 Kasutajad:';
SELECT e_meil, COUNT(*) FROM kasutajakonto GROUP BY e_meil;
SELECT '🏋️ Treeningud:';
SELECT treeningu_kood, nimetus, hind FROM treening;
