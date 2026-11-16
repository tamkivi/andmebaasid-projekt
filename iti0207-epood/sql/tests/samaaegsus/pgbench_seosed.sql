-- Oodatud ärireegli rikkumine lõpetab vaid vastava kutse, muud vead jäävad nähtavaks.
DO $katse$
DECLARE v_reegel text;
BEGIN
    PERFORM coalesce(f_aktiveeri_kaup(p_kauba_kood:='CON008',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY)),'NULL');
EXCEPTION WHEN check_violation THEN
    GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
    IF v_reegel NOT IN ('kaup_aktiveerimine','kaup_seisundimuudatus',
        'kauba_kategooria_omamine_kauba_muudetavus') THEN RAISE; END IF;
END;
$katse$;
DO $katse$
DECLARE v_reegel text;
BEGIN
    PERFORM coalesce(f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='CON008',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY)),'NULL');
EXCEPTION WHEN check_violation THEN
    GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
    IF v_reegel NOT IN ('kaup_aktiveerimine','kaup_seisundimuudatus',
        'kauba_kategooria_omamine_kauba_muudetavus') THEN RAISE; END IF;
END;
$katse$;
DO $katse$
DECLARE v_reegel text;
BEGIN
    PERFORM coalesce(f_lisa_kaup_kategooriasse(p_kauba_kood:='CON008',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY),p_kauba_kategooria_kood:='NAISTELEFONID'),'NULL');
EXCEPTION WHEN check_violation THEN
    GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
    IF v_reegel NOT IN ('kaup_aktiveerimine','kaup_seisundimuudatus',
        'kauba_kategooria_omamine_kauba_muudetavus') THEN RAISE; END IF;
END;
$katse$;
DO $katse$
DECLARE v_reegel text;
BEGIN
    PERFORM coalesce(f_eemalda_kaup_kategooriast(p_kauba_kood:='CON008',p_e_meil:=(SELECT i.e_meil FROM isik i JOIN tootaja t USING(isik_id) JOIN tootaja_rolli_omamine o USING(tootaja_id) JOIN tootaja_roll r USING(tootaja_roll_id) WHERE r.kood='KAUBAHALDUR' AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY),p_kauba_kategooria_kood:='NAISTELEFONID'),'NULL');
EXCEPTION WHEN check_violation THEN
    GET STACKED DIAGNOSTICS v_reegel=CONSTRAINT_NAME;
    IF v_reegel NOT IN ('kaup_aktiveerimine','kaup_seisundimuudatus',
        'kauba_kategooria_omamine_kauba_muudetavus') THEN RAISE; END IF;
END;
$katse$;
