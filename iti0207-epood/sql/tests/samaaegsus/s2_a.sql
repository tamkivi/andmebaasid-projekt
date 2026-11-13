-- Tehingu kinnitab kontrolli käivitaja.
START TRANSACTION;
SELECT coalesce(f_lisa_kaup_kategooriasse(p_kauba_kood:='CON008',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY),p_kauba_kategooria_kood:='NAISTELEFONID'),'NULL');
