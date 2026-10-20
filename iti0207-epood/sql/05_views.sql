-- Kaupade halduri lugemisliides.
CREATE VIEW v_kaubad_muutmiseks
    (kauba_kood,nimetus,seisundi_nimetus,hind,kirjeldus,pildi_aadress,reg_aeg,xmin)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,s.nimetus,k.hind,k.kirjeldus,k.pildi_aadress,k.reg_aeg,k.xmin
FROM kaup AS k
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
WHERE s.kood IN (1,3);
COMMENT ON VIEW v_kaubad_muutmiseks IS
    'Kasutusjuht Vaata kõiki ootel või mitteaktiivseid kaupu, OP7.1: halduri muudetavate kaupade nimekiri koos OP6 muutmise versioonitunnusega xmin. Seisund leitakse koodi, mitte surrogaat-ID järgi. Ainult lugemiseks.';

CREATE VIEW v_kaubad
    (kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,k.nimetus,b.nimetus,s.nimetus,k.hind,k.kirjeldus
FROM kaup AS k
INNER JOIN brand AS b USING (brand_id)
INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id);
COMMENT ON VIEW v_kaubad IS
    'Kasutusjuht Vaata kõiki kaupu, OP8.1: kõigi kaupade nimekiri, kaasa arvatud lõpetatud kaup. Iga kaup esineb korra; variante ja kategooriaid siia ei ühendata. Ainult lugemiseks.';

CREATE VIEW v_kauba_kategooriad
    (kauba_kood,kategooria_kood,kategooria_nimetus,kategooria_tyyp_kood,kategooria_tyyp_nimetus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,c.kood,c.nimetus,t.kood,t.nimetus
FROM kaup AS k
INNER JOIN kauba_kategooria_omamine AS o USING (kaup_id)
INNER JOIN kauba_kategooria AS c USING (kauba_kategooria_id)
INNER JOIN kauba_kategooria_tyyp AS t USING (kauba_kategooria_tyyp_id);
COMMENT ON VIEW v_kauba_kategooriad IS
    'Kauba halduri kauba vaatamise ja muutmise vormi kategooriaseosed, OP2.2. Iga kauba ja kategooria paar esineb korra; kategooriata kaubal seoseridu ei ole. Ainult lugemiseks.';

CREATE VIEW v_kauba_variandid
    (kauba_kood,varvi_kood,varvi_nimetus)
    WITH (security_barrier=true) AS
SELECT k.kauba_kood,v.kood,v.nimetus
FROM kaup AS k
INNER JOIN kauba_variant AS kv USING (kaup_id)
INNER JOIN varv AS v USING (varv_id);
COMMENT ON VIEW v_kauba_variandid IS
    'Kauba halduri kauba vaatamise ja muutmise vormi värvivariandid, OP2.4. Sama kauba ja värvi paar esineb korra. Ainult lugemiseks.';

-- Lugemisvaadete kaudu tehtavad muutmiskatsed ei muuda baastabeleid.
CREATE RULE r_v_kaubad_muutmiseks_insert AS
    ON INSERT TO v_kaubad_muutmiseks DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_muutmiseks_update AS
    ON UPDATE TO v_kaubad_muutmiseks DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_muutmiseks_delete AS
    ON DELETE TO v_kaubad_muutmiseks DO INSTEAD NOTHING;

CREATE RULE r_v_kaubad_insert AS
    ON INSERT TO v_kaubad DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_update AS
    ON UPDATE TO v_kaubad DO INSTEAD NOTHING;
CREATE RULE r_v_kaubad_delete AS
    ON DELETE TO v_kaubad DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_kategooriad_insert AS
    ON INSERT TO v_kauba_kategooriad DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_kategooriad_update AS
    ON UPDATE TO v_kauba_kategooriad DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_kategooriad_delete AS
    ON DELETE TO v_kauba_kategooriad DO INSTEAD NOTHING;

CREATE RULE r_v_kauba_variandid_insert AS
    ON INSERT TO v_kauba_variandid DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_variandid_update AS
    ON UPDATE TO v_kauba_variandid DO INSTEAD NOTHING;
CREATE RULE r_v_kauba_variandid_delete AS
    ON DELETE TO v_kauba_variandid DO INSTEAD NOTHING;
