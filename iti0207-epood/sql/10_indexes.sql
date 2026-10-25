-- Välisvõtmete indeksid: PK või UNIQUE algusveeruga kaetud viiteid ei korrata.
CREATE INDEX ix_isik_isiku_seisundi_liik_id ON isik (isiku_seisundi_liik_id);
CREATE INDEX ix_kauba_kategooria_omamine_kauba_kategooria_id ON kauba_kategooria_omamine (kauba_kategooria_id);
CREATE INDEX ix_kauba_variant_varv_id ON kauba_variant (varv_id);
CREATE INDEX ix_kaup_brand_id ON kaup (brand_id);
CREATE INDEX ix_kaup_kauba_seisundi_liik_id ON kaup (kauba_seisundi_liik_id);
CREATE INDEX ix_kaup_registreerija_id ON kaup (registreerija_id);
CREATE INDEX ix_kaup_viimase_muutja_id ON kaup (viimase_muutja_id);
CREATE INDEX ix_klient_kliendi_seisundi_liik_id ON klient (kliendi_seisundi_liik_id);
CREATE INDEX ix_nutitelefon_diagonaal_id ON nutitelefon (diagonaal_id);
CREATE INDEX ix_nutitelefon_eesmine_kaamera_id ON nutitelefon (eesmine_kaamera_id);
CREATE INDEX ix_nutitelefon_ekraani_resolutsioon_id ON nutitelefon (ekraani_resolutsioon_id);
CREATE INDEX ix_nutitelefon_protsessor_id ON nutitelefon (protsessor_id);
CREATE INDEX ix_nutitelefon_sisemalu_id ON nutitelefon (sisemalu_id);
CREATE INDEX ix_nutitelefon_tagumine_kaamera_id ON nutitelefon (tagumine_kaamera_id);
CREATE INDEX ix_tootaja_tootaja_seisundi_liik_id ON tootaja (tootaja_seisundi_liik_id);
CREATE INDEX ix_tootaja_mentor_id ON tootaja (mentor_id);
CREATE INDEX ix_tootaja_rolli_omamine_tootaja_roll_id ON tootaja_rolli_omamine (tootaja_roll_id);

-- Funktsioonil põhinev indeks tagab e-posti tõstutundetu unikaalsuse.
CREATE UNIQUE INDEX ux_isik_e_meil ON isik (lower(e_meil));
