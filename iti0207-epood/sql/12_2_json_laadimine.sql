START TRANSACTION;

-- Laadin riikide standardkoodid ja nimetused välise tabeli JSON-dokumentidest.
INSERT INTO riik (kood,nimetus)
SELECT JSON_VALUE(r.riik,'$."Alpha-3 code"'),
       JSON_VALUE(r.riik,'$."English short name lower case"')
FROM valine.Riik_sisend AS r;

-- Laadin ainult elus isikud ning leian riigi ja seisundi viited sisulise koodi järgi.
INSERT INTO isik (isikukood,eesnimi,perenimi,e_meil,synni_kp,elukoht,
                  riik_id,isiku_seisundi_liik_id)
SELECT jt.isikukood,jt.eesnimi,jt.perekonnanimi,jt.email,jt.synni_aeg,
       jt.aadress,r.riik_id,s.isiku_seisundi_liik_id
FROM valine.Isik_sisend AS a
CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
    isikukood varchar(50) PATH '$.isikukood',
    eesnimi varchar(50) PATH '$.eesnimi',
    perekonnanimi varchar(50) PATH '$.perekonnanimi',
    email varchar(254) PATH '$.email',
    synni_aeg date PATH '$.synni_aeg',
    seisund smallint PATH '$.seisund',
    aadress varchar(500) PATH '$.aadress'
)) AS jt
INNER JOIN riik AS r ON r.kood=JSON_VALUE(a.isik,'$.riik')
INNER JOIN isiku_seisundi_liik AS s ON s.kood='EL'
WHERE jt.seisund=1;

-- Seon lähteandmete avatekstilise testparooli õige isikuga riigi ja isikukoodi kaudu.
-- Konto aktiivsus saab vaikimisi väärtuse TRUE; räsimine lisandub eraldi.
INSERT INTO kasutajakonto (isik_id,parool)
SELECT i.isik_id,jt.parool
FROM valine.Isik_sisend AS a
CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
    isikukood varchar(50) PATH '$.isikukood',
    seisund smallint PATH '$.seisund',
    parool text PATH '$.parool'
)) AS jt
INNER JOIN riik AS r ON r.kood=JSON_VALUE(a.isik,'$.riik')
INNER JOIN isik AS i ON (i.riik_id=r.riik_id AND i.isikukood=jt.isikukood)
WHERE jt.seisund=1;

COMMIT;
