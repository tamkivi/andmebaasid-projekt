-- Tehingu kinnitab kontrolli käivitaja.
START TRANSACTION;
DELETE FROM kauba_kategooria_omamine
WHERE kaup_id=(SELECT kaup_id FROM kaup WHERE kauba_kood='CON008')
RETURNING (SELECT kauba_kood FROM kaup WHERE kaup_id=kauba_kategooria_omamine.kaup_id);
