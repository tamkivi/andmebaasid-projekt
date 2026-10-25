-- Klassifikaatorite väärtused ja töötajate pädevusalad.
START TRANSACTION;

INSERT INTO isiku_seisundi_liik (kood,nimetus) VALUES
    ('EL','Elus'),('SU','Surnud');

INSERT INTO tootaja_seisundi_liik (kood,nimetus) VALUES
    ('KA','Katseajal'),('TO','Tööl'),('PU','Puhkusel'),
    ('PE','Peatatud'),('LO','Lõpetatud');

INSERT INTO kliendi_seisundi_liik (kood,nimetus) VALUES
    ('AK','Aktiivne'),('PE','Peatatud'),('LO','Lõpetatud');

INSERT INTO tootaja_roll (kood,nimetus,kirjeldus) VALUES
    ('JUHATAJA','Juhataja','Juhib ettevõtte tegevust, lõpetab kaupade pakkumise ja vaatab koondaruandeid.'),
    ('KAUBAHALDUR','Kauba haldur','Registreerib nutitelefone ning haldab kaupade kirjeldusi, hindu, kategooriaid ja värvivariante.'),
    ('KLASSIFIKAATORIHALDUR','Klassifikaatorite haldur','Registreerib klassifikaatorite väärtusi ning korrastab nende nimetusi ja kasutatavust.'),
    ('KLIENDIHALDUR','Kliendihaldur','Haldab kliendisuhteid, kliendi seisundit ja kliendi antud suhtlusnõusolekuid.'),
    ('RAAMATUPIDAJA','Raamatupidaja','Peab arvestust majandustehingute üle ning kontrollib finantsaruannete lähteandmeid.'),
    ('PERSONALIHALDUR','Personalihaldur','Registreerib töötajaid ning haldab nende seisundeid ja rollide kehtivusperioode.');

-- Lisamisjärjekord eristab seisundikoode tehnilistest identifikaatoritest.
INSERT INTO kauba_seisundi_liik (kood,nimetus) VALUES
    (3,'Mitteaktiivne'),(4,'Lõpetatud'),(1,'Ootel'),(2,'Aktiivne');

-- Lõpetamata (ootel, aktiivsete ja mitteaktiivsete) kaupade nimetused on unikaalsed.
-- Osalise indeksi tingimus vajab Lõpetatud seisundi tehnilist ID-d, mis on teada alles pärast lisamist.
DO $indeks$
BEGIN
    EXECUTE format('CREATE UNIQUE INDEX ux_kaup_nimetus_lopetamata ON kaup (nimetus) '
        'WHERE kauba_seisundi_liik_id<>%s',
        (SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=4));
END;
$indeks$;

INSERT INTO brand (kood,nimetus) VALUES
    ('APPLE','Apple'),('SAMSUNG','Samsung'),('GOOGLE','Google');

INSERT INTO diagonaal (kood,nimetus) VALUES
    (6.1,'6,1 tolli'),(6.7,'6,7 tolli');

INSERT INTO ekraani_resolutsioon (kood,nimetus,horisontaalne,vertikaalne) VALUES
    ('2556x1179','2556 × 1179 pikslit',2556,1179),
    ('2340x1080','2340 × 1080 pikslit',2340,1080);

INSERT INTO kaamera (kood,nimetus) VALUES
    (12.0,'12 MP'),(48.0,'48 MP'),(50.0,'50 MP');

INSERT INTO protsessor (kood,nimetus) VALUES
    ('A16','Apple A16 Bionic'),('EXYNOS2400','Samsung Exynos 2400'),
    ('TENSORG3','Google Tensor G3');

INSERT INTO sisemalu (kood,nimetus) VALUES
    (128,'128 GB'),(256,'256 GB');

INSERT INTO varv (kood,nimetus) VALUES
    ('BLACK','Must'),('WHITE','Valge');
-- Varem kasutatud sinist värvi uutele kaupadele enam ei määrata.
INSERT INTO varv (kood,nimetus,on_aktiivne) VALUES ('BLUE','Sinine',FALSE);

INSERT INTO kauba_kategooria_tyyp (kood,nimetus) VALUES
    ('VALIMUS','Välimus'),('SIHTGRUPP','Sihtgrupp');

INSERT INTO kauba_kategooria (kood,nimetus,kauba_kategooria_tyyp_id)
SELECT a.kood,a.nimetus,t.kauba_kategooria_tyyp_id
FROM (VALUES
    ('NAISTELEFONID','Naistetelefonid','SIHTGRUPP'),
    ('MEESTELEFONID','Meestetelefonid','SIHTGRUPP'),
    ('KLASSIKALINE','Klassikalise välimusega telefonid','VALIMUS')
) AS a(kood,nimetus,tyybi_kood)
INNER JOIN kauba_kategooria_tyyp AS t ON t.kood=a.tyybi_kood;

COMMIT;
