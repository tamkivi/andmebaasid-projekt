-- Tehingu kinnitab kontrolli käivitaja.
START TRANSACTION;
UPDATE kaup SET kauba_seisundi_liik_id=(SELECT kauba_seisundi_liik_id FROM kauba_seisundi_liik WHERE kood=2)
WHERE kauba_kood='CON008' RETURNING kauba_kood;
