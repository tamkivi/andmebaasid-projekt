-- Töötajateks valin isik_id järgi esimesed kaks laaditud isikut, klientideks kuni kolm järgmist.
-- Valik ei sõltu lähteandmete nimedest, e-posti aadressidest ega genereeritud ID väärtustest.
START TRANSACTION;

DO $allikas$
BEGIN
    IF (SELECT count(*) FROM isik)<4 THEN
        RAISE EXCEPTION 'Testandmed vajavad vähemalt nelja välisest allikast laaditud elus isikut';
    END IF;
END;
$allikas$;

INSERT INTO tootaja (isik_id,tootaja_seisundi_liik_id)
SELECT i.isik_id,s.tootaja_seisundi_liik_id
FROM (SELECT isik_id FROM isik ORDER BY isik_id FETCH FIRST 2 ROWS ONLY) AS i
CROSS JOIN tootaja_seisundi_liik AS s
WHERE s.kood='TO'
ON CONFLICT (isik_id) DO NOTHING;

-- Teine töötaja (juhataja) on esimese töötaja mentor.
UPDATE tootaja SET mentor_id=(SELECT tootaja_id FROM tootaja ORDER BY isik_id DESC FETCH FIRST 1 ROW ONLY)
WHERE tootaja_id=(SELECT tootaja_id FROM tootaja ORDER BY isik_id FETCH FIRST 1 ROW ONLY)
    AND mentor_id IS NULL
    AND (SELECT count(*) FROM tootaja)>1;

INSERT INTO tootaja_rolli_omamine (tootaja_id,tootaja_roll_id,alguse_aeg)
SELECT t.tootaja_id,r.tootaja_roll_id,TIMESTAMPTZ '2025-01-01 00:00:00+02'
FROM (SELECT tootaja_id,row_number() OVER (ORDER BY isik_id) AS jrk FROM tootaja) AS t
INNER JOIN tootaja_roll AS r
    ON r.kood=CASE t.jrk WHEN 1 THEN 'KAUBAHALDUR' WHEN 2 THEN 'JUHATAJA' END
ON CONFLICT (tootaja_id,tootaja_roll_id,alguse_aeg) DO NOTHING;

INSERT INTO tootaja_rolli_omamine (tootaja_id,tootaja_roll_id,alguse_aeg,lopu_aeg)
SELECT t.tootaja_id,r.tootaja_roll_id,
       TIMESTAMPTZ '2024-01-01 00:00:00+02',TIMESTAMPTZ '2025-01-01 00:00:00+02'
FROM (SELECT tootaja_id FROM tootaja ORDER BY isik_id FETCH FIRST 1 ROW ONLY) AS t
CROSS JOIN tootaja_roll AS r
WHERE r.kood='KAUBAHALDUR'
ON CONFLICT (tootaja_id,tootaja_roll_id,alguse_aeg) DO NOTHING;

-- Olemasoleva kliendi seisund ja suhtlusnõusolek säilivad.
INSERT INTO klient (isik_id,kliendi_seisundi_liik_id,on_nous_tylitamisega)
SELECT i.isik_id,s.kliendi_seisundi_liik_id,TRUE
FROM (SELECT isik_id FROM isik ORDER BY isik_id OFFSET 2 ROWS FETCH FIRST 3 ROWS ONLY) AS i
CROSS JOIN kliendi_seisundi_liik AS s
WHERE s.kood='AK'
ON CONFLICT (isik_id) DO NOTHING;

INSERT INTO kaup (kauba_kood,nimetus,kauba_seisundi_liik_id,brand_id,
                  registreerija_id,viimase_muutja_id,hind,kirjeldus,pildi_aadress)
SELECT a.kood,a.nimetus,s.kauba_seisundi_liik_id,b.brand_id,
       t.tootaja_id,t.tootaja_id,a.hind,a.kirjeldus,a.pilt
FROM (VALUES
    ('APL001','iPhone 15 näidiseksemplar',1,899.00,
     'Avaldamiseks ettevalmistatav 128 GB nutitelefon igapäevaseks suhtluseks ja pildistamiseks.',NULL),
    ('APL002','iPhone 15 suure mäluga näidis',2,1199.00,
     'Avaldatud 256 GB telefon mahuka foto- ja videokogu hoidmiseks.',
     'https://example.invalid/epood/apl002.jpg'),
    ('APL003','iPhone 15 peatatud pakkumine',3,749.00,
     'Ajutiselt müügilt eemaldatud 128 GB pakkumine; kirjeldus on hinnakontrolliks muudetav.',
     'https://example.invalid/epood/apl003.png'),
    ('APL004','iPhone 15 lõpetatud pakkumine',4,499.00,
     'Lõpetatud 128 GB näidispakkumine, mis säilib kaupade ajaloolises nimekirjas.',NULL)
) AS a(kood,nimetus,seisund,hind,kirjeldus,pilt)
INNER JOIN kauba_seisundi_liik AS s ON s.kood=a.seisund
CROSS JOIN brand AS b
CROSS JOIN (SELECT tootaja_id FROM tootaja ORDER BY isik_id FETCH FIRST 1 ROW ONLY) AS t
WHERE b.kood='APPLE'
ON CONFLICT (kauba_kood) DO NOTHING;

INSERT INTO nutitelefon (kaup_id,eesmine_kaamera_id,tagumine_kaamera_id,
                        sisemalu_id,diagonaal_id,protsessor_id,
                        ekraani_resolutsioon_id,on_sormejalelugeja,on_veekindel)
SELECT k.kaup_id,e.kaamera_id,t.kaamera_id,m.sisemalu_id,d.diagonaal_id,
       p.protsessor_id,r.ekraani_resolutsioon_id,FALSE,TRUE
FROM kaup AS k
CROSS JOIN kaamera AS e CROSS JOIN kaamera AS t
INNER JOIN sisemalu AS m ON m.kood=CASE k.kauba_kood WHEN 'APL002' THEN 256 ELSE 128 END
CROSS JOIN diagonaal AS d CROSS JOIN protsessor AS p CROSS JOIN ekraani_resolutsioon AS r
WHERE k.kauba_kood IN ('APL001','APL002','APL003','APL004')
    AND e.kood=12.0 AND t.kood=48.0 AND d.kood=6.1
    AND p.kood='A16' AND r.kood='2556x1179'
ON CONFLICT (kaup_id) DO NOTHING;

INSERT INTO kauba_variant (kaup_id,varv_id)
SELECT k.kaup_id,v.varv_id
FROM kaup AS k CROSS JOIN varv AS v
WHERE k.kauba_kood IN ('APL001','APL002','APL003','APL004') AND v.kood='BLACK'
ON CONFLICT (kaup_id,varv_id) DO NOTHING;

INSERT INTO kauba_kategooria_omamine (kaup_id,kauba_kategooria_id)
SELECT k.kaup_id,c.kauba_kategooria_id
FROM kaup AS k CROSS JOIN kauba_kategooria AS c
WHERE k.kauba_kood IN ('APL001','APL002','APL003','APL004')
    AND c.kood IN ('NAISTELEFONID','KLASSIKALINE')
ON CONFLICT (kaup_id,kauba_kategooria_id) DO NOTHING;

COMMIT;
