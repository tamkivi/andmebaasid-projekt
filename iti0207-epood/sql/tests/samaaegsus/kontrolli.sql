-- Terviklus pärast iga katset.
DO $c$ BEGIN
IF EXISTS(SELECT 1 FROM kaup k JOIN kauba_seisundi_liik s USING(kauba_seisundi_liik_id) WHERE s.kood=2 AND NOT EXISTS(SELECT 1 FROM kauba_kategooria_omamine o WHERE o.kaup_id=k.kaup_id)) THEN RAISE EXCEPTION 'Aktiivne kaup on kategooriata'; END IF;
IF EXISTS(SELECT 1 FROM kaup k LEFT JOIN nutitelefon n USING(kaup_id) GROUP BY k.kaup_id HAVING count(n.kaup_id)<>1) THEN RAISE EXCEPTION 'Kaubal peab olema täpselt üks nutitelefon'; END IF;
IF EXISTS(SELECT 1 FROM kaup WHERE viimase_muutm_aeg<reg_aeg) THEN RAISE EXCEPTION 'Viimase muutmise aeg eelneb registreerimisajale'; END IF;
IF EXISTS(SELECT 1 FROM kauba_variant v LEFT JOIN kaup k USING(kaup_id) WHERE k.kaup_id IS NULL) THEN RAISE EXCEPTION 'Variandil puudub seotud kaup'; END IF;
END $c$;
