-- Jõusaali rühmatreeningute prototüübi demoandmed.
-- Käivita pärast submission_files/skript.sql importimist, kui soovid demoandmed uuesti tagada.

INSERT INTO riik (riigi_kood, nimetus) VALUES
('EE', 'Eesti'), ('LV', 'Läti'), ('LT', 'Leedu')
ON CONFLICT DO NOTHING;

INSERT INTO isiku_seisundi_liik (isiku_seisundi_liigi_kood, nimetus) VALUES
('KLIENT', 'Klient'), ('TOOTAJA', 'Töötaja')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_seisundi_liik (tootaja_seisundi_liigi_kood, nimetus) VALUES
('AKTIIVNE', 'Aktiivne'), ('PUHKUSEL', 'Puhkusel'), ('LAHKUNUD', 'Lahkunud')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_roll (tootaja_rolli_kood, nimetus, kirjeldus) VALUES
('TREENER', 'Treener', 'Treener märgib osalemist ja näeb enda tunniplaani.'),
('JUHATAJA', 'Juhataja', 'Juhataja planeerib ja juhib treeningukordi.')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliigi_seisundi_liik (treeninguliigi_seisundi_kood, nimetus, on_aktiivne) VALUES
('KOOST', 'Koostamisel', TRUE), ('AKTIIVNE', 'Aktiivne', TRUE),
('MITTEAKT', 'Mitteaktiivne', TRUE), ('LOPETATUD', 'Lõpetatud', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO treeningukorra_seisundi_liik (treeningukorra_seisundi_kood, nimetus, on_aktiivne) VALUES
('KAVAND', 'Kavandatud', TRUE), ('AVATUD', 'Avatud', TRUE),
('SULETUD', 'Suletud', TRUE), ('TOIMUNUD', 'Toimunud', FALSE), ('TYHIST', 'Tühistatud', FALSE)
ON CONFLICT DO NOTHING;

INSERT INTO registreeringu_seisundi_liik (registreeringu_seisundi_kood, nimetus, on_aktiivne) VALUES
('KINNIT', 'Kinnitatud', TRUE), ('OOTEJRK', 'Ootejärjekorras', TRUE),
('TYH_KL', 'Kliendi poolt tühistatud', FALSE), ('TYH_SYS', 'Süsteemi poolt tühistatud', FALSE)
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
VALUES ('klient@jousaal.ee'), ('klient2@jousaal.ee'), ('klient3@jousaal.ee'), ('klient4@jousaal.ee')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja (e_meil, tootaja_seisundi_liigi_kood)
VALUES ('juhataja@jousaal.ee', 'AKTIIVNE'), ('treener@jousaal.ee', 'AKTIIVNE'), ('treener2@jousaal.ee', 'AKTIIVNE')
ON CONFLICT DO NOTHING;

INSERT INTO tootaja_rolli_omamine (tootaja_e_meil, tootaja_rolli_kood, alguse_aeg)
VALUES
('juhataja@jousaal.ee', 'JUHATAJA', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02'),
('treener2@jousaal.ee', 'TREENER', TIMESTAMPTZ '2025-01-01 00:00:00+02')
ON CONFLICT DO NOTHING;

INSERT INTO treeninguliik (treeninguliigi_id, nimetus, kirjeldus, kestus_minutites, vajalik_varustus, treeninguliigi_seisundi_kood, registreerija_e_meil, viimase_muutja_e_meil)
OVERRIDING SYSTEM VALUE
VALUES
(1000, 'Jooga algajatele', 'Rahulik rühmatreening liikuvuse ja hingamise arendamiseks.', 60, 'Matid ja joogaplokid', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1001, 'HIIT rühmatreening', 'Kõrge intensiivsusega intervalltreening väikesele grupile.', 45, 'Matid, hantlid ja stopper', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
(1002, 'Jõutreeningu tehnika', 'Rühmatund jõusaali põhiharjutuste tehnika õppimiseks.', 75, 'Kangid ja kettad', 'AKTIIVNE', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
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

INSERT INTO treeninguliigi_varustuse_noue (treeninguliigi_id, varustuse_kood, minimaalne_kogus, on_kohustuslik, markus)
VALUES
(1000, 'MATID', 6, TRUE, 'Joogatund vajab igale osalejale matti.'),
(1000, 'EKRAAN', 1, FALSE, 'Soovituslik juhendmaterjali kuvamiseks.'),
(1001, 'MATID', 2, TRUE, 'HIIT kasutab põrandaharjutusi.'),
(1001, 'HANTLID', 2, TRUE, 'HIIT tunnis kasutatakse hantleid.'),
(1002, 'KANGID', 4, TRUE, 'Jõutreeningu tehnika tunnis kasutatakse kange.')
ON CONFLICT DO NOTHING;

INSERT INTO ruum (ruumi_kood, nimetus, asukoht, mahutavus)
VALUES ('SAAL_A', 'Väike stuudio', '1. korrus', 2), ('SAAL_B', 'Suur rühmatreeningute saal', '2. korrus', 12)
ON CONFLICT DO NOTHING;

INSERT INTO ruumi_varustuse_omamine (ruumi_kood, varustuse_kood, kogus, markus)
VALUES
('SAAL_A', 'MATID', 4, 'Väikese stuudio matid.'),
('SAAL_A', 'HANTLID', 4, 'HIIT tunniks piisav hulk hantleid.'),
('SAAL_A', 'PALLID', 2, 'Lisavarustus väikese grupi harjutusteks.'),
('SAAL_B', 'MATID', 12, 'Suure saali matid.'),
('SAAL_B', 'HANTLID', 10, 'Suure saali hantlid.'),
('SAAL_B', 'KANGID', 6, 'Jõutreeningu tehnika varustus.'),
('SAAL_B', 'EKRAAN', 1, 'Ekraan või projektor juhendmaterjaliks.')
ON CONFLICT DO NOTHING;

INSERT INTO treeneri_padevus (tootaja_e_meil, treeninguliigi_id, alates)
VALUES ('treener@jousaal.ee', 1000, DATE '2025-01-01'), ('treener@jousaal.ee', 1001, DATE '2025-01-01'), ('treener2@jousaal.ee', 1002, DATE '2025-01-01')
ON CONFLICT DO NOTHING;

-- Demo treeningukord rows use fixed IDs as stable seed identities. Avoid
-- attempting duplicate inserts because BEFORE INSERT overlap triggers fire
-- before ON CONFLICT can skip an existing row.
WITH seeded_treeningukorrad (
    treeningukorra_id, treeninguliigi_id, treener_e_meil, ruumi_kood,
    alguse_aeg, lopu_aeg, registreerimise_lopp, tyhistamise_lopp,
    maksimaalne_osalejate_arv, treeningukorra_seisundi_kood, looja_e_meil, viimase_muutja_e_meil
) AS (
    VALUES
    (2000, 1002, 'treener2@jousaal.ee', 'SAAL_B', CURRENT_TIMESTAMP(0) + INTERVAL '10 days', CURRENT_TIMESTAMP(0) + INTERVAL '10 days 75 minutes', CURRENT_TIMESTAMP(0) + INTERVAL '9 days', CURRENT_TIMESTAMP(0) + INTERVAL '9 days', 8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2001, 1000, 'treener@jousaal.ee', 'SAAL_B', CURRENT_TIMESTAMP(0) + INTERVAL '7 days', CURRENT_TIMESTAMP(0) + INTERVAL '7 days 60 minutes', CURRENT_TIMESTAMP(0) + INTERVAL '6 days', CURRENT_TIMESTAMP(0) + INTERVAL '6 days', 8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2002, 1001, 'treener@jousaal.ee', 'SAAL_A', CURRENT_TIMESTAMP(0) + INTERVAL '5 days', CURRENT_TIMESTAMP(0) + INTERVAL '5 days 45 minutes', CURRENT_TIMESTAMP(0) + INTERVAL '4 days', CURRENT_TIMESTAMP(0) + INTERVAL '4 days', 2, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee'),
    (2003, 1000, 'treener@jousaal.ee', 'SAAL_B', CURRENT_TIMESTAMP(0) - INTERVAL '3 days', CURRENT_TIMESTAMP(0) - INTERVAL '3 days' + INTERVAL '60 minutes', CURRENT_TIMESTAMP(0) - INTERVAL '4 days', CURRENT_TIMESTAMP(0) - INTERVAL '4 days', 8, 'KAVAND', 'juhataja@jousaal.ee', 'juhataja@jousaal.ee')
)
INSERT INTO treeningukord (
    treeningukorra_id, treeninguliigi_id, treener_e_meil, ruumi_kood,
    alguse_aeg, lopu_aeg, registreerimise_lopp, tyhistamise_lopp,
    maksimaalne_osalejate_arv, treeningukorra_seisundi_kood, looja_e_meil, viimase_muutja_e_meil
)
OVERRIDING SYSTEM VALUE
SELECT
    s.treeningukorra_id, s.treeninguliigi_id, s.treener_e_meil, s.ruumi_kood,
    s.alguse_aeg, s.lopu_aeg, s.registreerimise_lopp, s.tyhistamise_lopp,
    s.maksimaalne_osalejate_arv, s.treeningukorra_seisundi_kood, s.looja_e_meil, s.viimase_muutja_e_meil
FROM seeded_treeningukorrad s
WHERE NOT EXISTS (
    SELECT 1
    FROM treeningukord tk
    WHERE tk.treeningukorra_id = s.treeningukorra_id
);

UPDATE treeningukord SET treeningukorra_seisundi_kood = 'AVATUD', viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id IN (2001, 2002) AND treeningukorra_seisundi_kood = 'KAVAND';
UPDATE treeningukord
SET treeningukorra_seisundi_kood = 'TYHIST',
    tyhistamise_pohjus = 'Demo treeningukord tühistati enne avamist.',
    registreerimise_lopp = CURRENT_TIMESTAMP(0) - INTERVAL '1 minute',
    tyhistamise_lopp = CURRENT_TIMESTAMP(0) - INTERVAL '1 minute',
    viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2000 AND treeningukorra_seisundi_kood = 'KAVAND';
UPDATE treeningukord SET treeningukorra_seisundi_kood = 'AVATUD', viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003 AND treeningukorra_seisundi_kood = 'KAVAND';
UPDATE treeningukord SET treeningukorra_seisundi_kood = 'SULETUD', viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003 AND treeningukorra_seisundi_kood = 'AVATUD';
UPDATE treeningukord SET treeningukorra_seisundi_kood = 'TOIMUNUD', viimase_muutmise_aeg = CURRENT_TIMESTAMP(0)
WHERE treeningukorra_id = 2003 AND treeningukorra_seisundi_kood = 'SULETUD';

INSERT INTO registreering (registreeringu_id, treeningukorra_id, klient_e_meil, registreeringu_seisundi_kood)
OVERRIDING SYSTEM VALUE
VALUES
(3000, 2002, 'klient@jousaal.ee', 'KINNIT'),
(3001, 2002, 'klient2@jousaal.ee', 'KINNIT'),
(3002, 2002, 'klient3@jousaal.ee', 'OOTEJRK'),
(3003, 2003, 'klient@jousaal.ee', 'KINNIT'),
(3004, 2003, 'klient2@jousaal.ee', 'KINNIT'),
(3005, 2002, 'klient4@jousaal.ee', 'OOTEJRK')
ON CONFLICT DO NOTHING;

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

SELECT 'Demoandmed on olemas: üks tühistatud treeningukord, üks avatud vabade kohtadega treeningukord, üks täis avatud treeningukord ootejärjekorraga ja üks toimunud treeningukord osalemistega.';
