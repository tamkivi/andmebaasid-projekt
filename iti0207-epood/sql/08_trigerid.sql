-- Kaupade elutsükli, muudetavuse ja registreerimisandmete reeglid.
START TRANSACTION;

CREATE OR REPLACE FUNCTION public.f_trig_kaup_algseisund()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_kood smallint;
BEGIN
    SELECT kood INTO v_kood FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=NEW.kauba_seisundi_liik_id FOR SHARE;
    IF v_kood<>1 THEN
        RAISE EXCEPTION 'Uue kauba seisund peab olema ootel.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, seisundi kood %s.',NEW.kauba_kood,v_kood),
            HINT='Lisa kaup ootel seisundis.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_algseisund', COLUMN='kauba_seisundi_liik_id';
    END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_algseisund() IS 'Uue kauba saab lisada ainult ootel seisundis, koodiga 1. Tundmatut seisundiviidet kontrollib välisvõti.';

CREATE OR REPLACE TRIGGER trig_kaup_algseisund
BEFORE INSERT ON public.kaup
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kaup_algseisund();
COMMENT ON TRIGGER trig_kaup_algseisund ON public.kaup IS 'Uus kaup peab olema ootel.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_seisundimuudatus()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_vana smallint;
    v_uus smallint;
BEGIN
    SELECT kood INTO v_vana FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=OLD.kauba_seisundi_liik_id FOR SHARE;
    SELECT kood INTO v_uus FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=NEW.kauba_seisundi_liik_id FOR SHARE;
    IF v_vana IS NOT NULL AND v_uus IS NOT NULL AND (v_vana,v_uus) NOT IN ((1,2),(3,2),(2,3),(2,4),(3,4)) THEN
        RAISE EXCEPTION 'Kauba seisundimuudatus ei ole lubatud.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, seisundi kood %s -> %s.',OLD.kauba_kood,v_vana,v_uus),
            HINT='Järgi kauba seisundidiagrammi.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_seisundimuudatus', COLUMN='kauba_seisundi_liik_id';
    END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_seisundimuudatus() IS 'Lubab seisundikoodide üleminekuid 1->2, 3->2, 2->3, 2->4 ja 3->4. Sama seisundi tagasikirjutamine funktsiooni ei käivita.';

CREATE OR REPLACE TRIGGER trig_kaup_seisundimuudatus
BEFORE UPDATE OF kauba_seisundi_liik_id ON public.kaup
FOR EACH ROW WHEN (OLD.kauba_seisundi_liik_id IS DISTINCT FROM NEW.kauba_seisundi_liik_id)
EXECUTE FUNCTION public.f_trig_kaup_seisundimuudatus();
COMMENT ON TRIGGER trig_kaup_seisundimuudatus ON public.kaup IS 'Kontrollib ainult tegelikku seisundimuudatust.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_aktiveerimine()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_kood smallint;
BEGIN
    SELECT kood INTO v_kood FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=NEW.kauba_seisundi_liik_id FOR SHARE;
    -- FOR SHARE ei lase teisel tehingul leitud kategooriaseost samal ajal kustutada.
    IF v_kood=2 AND NOT EXISTS (SELECT 1 FROM public.kauba_kategooria_omamine
        WHERE kaup_id=NEW.kaup_id FOR SHARE) THEN
        RAISE EXCEPTION 'Kauba aktiveerimiseks peab sellel olema vähemalt üks kategooria.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, kauba tunnus %s.',NEW.kauba_kood,NEW.kaup_id),
            HINT='Lisa ootel või mitteaktiivsele kaubale kategooria.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_aktiveerimine', COLUMN='kauba_seisundi_liik_id';
    END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_aktiveerimine() IS 'Aktiivsesse seisundisse viidaval kaubal peab olema vähemalt üks kategooria. Leitud kategooriaseos lukustatakse FOR SHARE abil, et teine tehing ei saaks seda aktiveerimise ajal kustutada.';

CREATE OR REPLACE TRIGGER trig_kaup_seisundimuudatus_kategooria
BEFORE UPDATE OF kauba_seisundi_liik_id ON public.kaup
FOR EACH ROW WHEN (OLD.kauba_seisundi_liik_id IS DISTINCT FROM NEW.kauba_seisundi_liik_id)
EXECUTE FUNCTION public.f_trig_kaup_aktiveerimine();
COMMENT ON TRIGGER trig_kaup_seisundimuudatus_kategooria ON public.kaup IS 'Aktiveerimine eeldab kategooriat.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_kustutamine()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_kood smallint;
BEGIN
    SELECT kood INTO v_kood FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=OLD.kauba_seisundi_liik_id FOR SHARE;
    IF v_kood<>1 THEN
        RAISE EXCEPTION 'Kustutada saab ainult ootel kaupa.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, seisundi kood %s.',OLD.kauba_kood,v_kood),
            HINT='Säilita müügis olnud kauba ajalugu; vajadusel lõpeta kaup.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_kustutamine';
    END IF;
    RETURN OLD;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_kustutamine() IS 'Kustutada saab ainult ootel kauba, seisundikoodiga 1. Sõltuvad read kustutab välisvõtme ON DELETE CASCADE.';

CREATE OR REPLACE TRIGGER trig_kaup_kustutamine
BEFORE DELETE ON public.kaup
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kaup_kustutamine();
COMMENT ON TRIGGER trig_kaup_kustutamine ON public.kaup IS 'Kustutamine on lubatud ainult ootel seisundis.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_muudetavus()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_kood smallint;
BEGIN
    SELECT kood INTO v_kood FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=OLD.kauba_seisundi_liik_id FOR SHARE;
    IF v_kood NOT IN (1,3) THEN
        RAISE EXCEPTION 'Kauba andmeid saab muuta ainult ootel või mitteaktiivses seisundis.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, muudatuseelne seisundi kood %s.',OLD.kauba_kood,v_kood),
            HINT='Muuda aktiivne kaup enne andmete muutmist mitteaktiivseks.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_muudetavus',
            COLUMN=CASE
                WHEN OLD.kauba_kood IS DISTINCT FROM NEW.kauba_kood THEN 'kauba_kood'
                WHEN OLD.nimetus IS DISTINCT FROM NEW.nimetus THEN 'nimetus'
                WHEN OLD.hind IS DISTINCT FROM NEW.hind THEN 'hind'
                WHEN OLD.kirjeldus IS DISTINCT FROM NEW.kirjeldus THEN 'kirjeldus'
                WHEN OLD.pildi_aadress IS DISTINCT FROM NEW.pildi_aadress THEN 'pildi_aadress'
                WHEN OLD.brand_id IS DISTINCT FROM NEW.brand_id THEN 'brand_id'
                ELSE 'kaup_id' END;
    END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_muudetavus() IS 'Kauba põhiandmete tegelikul muutmisel peab vana seisundi kood olema 1 või 3, ka seisundi samaaegsel muutmisel. Auditväljad ja seisund ei kuulu põhiandmete võrdlusse.';

CREATE OR REPLACE TRIGGER trig_kaup_andmete_muutmine
BEFORE UPDATE OF kaup_id,kauba_kood,nimetus,hind,kirjeldus,pildi_aadress,brand_id ON public.kaup
FOR EACH ROW WHEN (ROW(OLD.kaup_id,OLD.kauba_kood,OLD.nimetus,OLD.hind,OLD.kirjeldus,OLD.pildi_aadress,OLD.brand_id) IS DISTINCT FROM ROW(NEW.kaup_id,NEW.kauba_kood,NEW.nimetus,NEW.hind,NEW.kirjeldus,NEW.pildi_aadress,NEW.brand_id))
EXECUTE FUNCTION public.f_trig_kaup_muudetavus();
COMMENT ON TRIGGER trig_kaup_andmete_muutmine ON public.kaup IS 'Kontrollib muutuvaid põhiandmeid vana seisundi järgi.';

CREATE OR REPLACE FUNCTION public.f_trig_kauba_osa_muudetavus()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_ids integer[];
    v_id integer;
    v_kood smallint;
    v_kauba_kood varchar;
    v_seisundi_id smallint;
BEGIN
    IF TG_OP='INSERT' THEN v_ids:=ARRAY[NEW.kaup_id];
    ELSIF TG_OP='DELETE' THEN v_ids:=ARRAY[OLD.kaup_id];
    ELSE v_ids:=ARRAY[OLD.kaup_id,NEW.kaup_id];
    END IF;
    -- Kahe kauba vahel tõstmisel kontrollitakse mõlemat kasvava tunnuse järjekorras.
    FOR v_id IN SELECT DISTINCT a.id FROM unnest(v_ids) AS a(id) ORDER BY a.id
    LOOP
        -- Kõigepealt lukustatakse kaubarida ja loetakse selle värske seisundiviide.
        -- Üks liitpäring võib lukuootuse järel anda klassifikaatori vana liidetud rea.
        SELECT k.kauba_seisundi_liik_id,k.kauba_kood INTO v_seisundi_id,v_kauba_kood
        FROM public.kaup AS k WHERE k.kaup_id=v_id FOR SHARE;
        SELECT s.kood INTO v_kood FROM public.kauba_seisundi_liik AS s
        WHERE s.kauba_seisundi_liik_id=v_seisundi_id FOR SHARE;
        -- Puuduv vanem võib olla sama lause lisandus või kaskaadkustutus; viidet kontrollib FK.
        IF v_kood NOT IN (1,3) THEN
            RAISE EXCEPTION 'Kauba lisaandmeid saab muuta ainult ootel või mitteaktiivses seisundis.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, kauba tunnus %s, seisundi kood %s, toiming %s.',v_kauba_kood,v_id,v_kood,TG_OP),
            HINT='Muuda aktiivne kaup enne lisaandmete muutmist mitteaktiivseks.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_kauba_muudetavus', COLUMN='kaup_id';
        END IF;
    END LOOP;
    IF TG_OP='DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kauba_osa_muudetavus() IS 'Telefoni, kategooriaseose ja variandi lisamine, tegelik muutmine või kustutamine nõuab kauba seisundikoodi 1 või 3. FOR SHARE kaitseb seotud kaubaridu; funktsioon kaubarida ise ei uuenda.';

CREATE OR REPLACE TRIGGER trig_nutitelefon_kauba_muudetavus
BEFORE INSERT OR DELETE ON public.nutitelefon
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_nutitelefon_kauba_muudetavus ON public.nutitelefon IS 'Lisaandmete lisamine ja kustutamine eeldab muudetavat kaupa.';

CREATE OR REPLACE TRIGGER trig_nutitelefon_muutmine
BEFORE UPDATE ON public.nutitelefon
FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_nutitelefon_muutmine ON public.nutitelefon IS 'Lisaandmete tegelik muutmine kontrollib nii vana kui uut kaupa.';

CREATE OR REPLACE TRIGGER trig_kauba_kategooria_omamine_kauba_muudetavus
BEFORE INSERT OR DELETE ON public.kauba_kategooria_omamine
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_kauba_kategooria_omamine_kauba_muudetavus ON public.kauba_kategooria_omamine IS 'Lisaandmete lisamine ja kustutamine eeldab muudetavat kaupa.';

CREATE OR REPLACE TRIGGER trig_kauba_kategooria_omamine_muutmine
BEFORE UPDATE ON public.kauba_kategooria_omamine
FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_kauba_kategooria_omamine_muutmine ON public.kauba_kategooria_omamine IS 'Lisaandmete tegelik muutmine kontrollib nii vana kui uut kaupa.';

CREATE OR REPLACE TRIGGER trig_kauba_variant_kauba_muudetavus
BEFORE INSERT OR DELETE ON public.kauba_variant
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_kauba_variant_kauba_muudetavus ON public.kauba_variant IS 'Lisaandmete lisamine ja kustutamine eeldab muudetavat kaupa.';

CREATE OR REPLACE TRIGGER trig_kauba_variant_muutmine
BEFORE UPDATE ON public.kauba_variant
FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION public.f_trig_kauba_osa_muudetavus();
COMMENT ON TRIGGER trig_kauba_variant_muutmine ON public.kauba_variant IS 'Lisaandmete tegelik muutmine kontrollib nii vana kui uut kaupa.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_reg_andmed()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
BEGIN
    RAISE EXCEPTION 'Kauba registreerijat ja registreerimise aega ei saa muuta.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, registreerija %s -> %s, aeg %s -> %s.',OLD.kauba_kood,OLD.registreerija_id,NEW.registreerija_id,OLD.reg_aeg,NEW.reg_aeg),
            HINT='Säilita kauba algsed registreerimisandmed.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_reg_andmed',
            COLUMN=CASE WHEN OLD.registreerija_id IS DISTINCT FROM NEW.registreerija_id
                THEN 'registreerija_id' ELSE 'reg_aeg' END;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_reg_andmed() IS 'Keelab kauba registreerija või registreerimisaja tegeliku muutmise. Endise väärtuse tagasikirjutamine on lubatud.';

CREATE OR REPLACE TRIGGER trig_kaup_reg_andmed
BEFORE UPDATE OF reg_aeg,registreerija_id ON public.kaup
FOR EACH ROW WHEN (ROW(OLD.reg_aeg,OLD.registreerija_id) IS DISTINCT FROM ROW(NEW.reg_aeg,NEW.registreerija_id))
EXECUTE FUNCTION public.f_trig_kaup_reg_andmed();
COMMENT ON TRIGGER trig_kaup_reg_andmed ON public.kaup IS 'Algne registreerija ja registreerimisaeg säilivad.';

CREATE OR REPLACE FUNCTION public.f_trig_viimase_muutm_aeg()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
BEGIN
    NEW.viimase_muutm_aeg:=CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_viimase_muutm_aeg() IS 'Määrab kauba või isiku rea muutmisel viimase muutmise ajaks tehingu algusaja. INSERT vaikeväärtused jäävad tabeli määrata.';

CREATE OR REPLACE TRIGGER trig_kaup_viimase_muutm_aeg
BEFORE UPDATE ON public.kaup
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_viimase_muutm_aeg();
COMMENT ON TRIGGER trig_kaup_viimase_muutm_aeg ON public.kaup IS 'Määrab viimase muutmise aja iga kaubarea UPDATE korral, ka siis, kui sama töötaja muudab kauba seoseid ja kaubarea väärtused ei muutu.';

CREATE OR REPLACE TRIGGER trig_isik_viimase_muutm_aeg
BEFORE UPDATE ON public.isik
FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION public.f_trig_viimase_muutm_aeg();
COMMENT ON TRIGGER trig_isik_viimase_muutm_aeg ON public.isik IS 'Määrab viimase muutmise aja ainult siis, kui isiku andmed tegelikult muutuvad.';

CREATE OR REPLACE FUNCTION public.f_trig_kaup_aktiivne_seisund()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_aktiivne boolean;
BEGIN
    SELECT on_aktiivne INTO v_aktiivne FROM public.kauba_seisundi_liik
    WHERE kauba_seisundi_liik_id=NEW.kauba_seisundi_liik_id FOR SHARE;
    IF NOT v_aktiivne THEN
        RAISE EXCEPTION 'Kauba uus seisund peab olema aktiivne klassifikaatoriväärtus.' USING
            ERRCODE='check_violation',
            DETAIL=format('Kauba kood %s, seisundi tunnus %s.',NEW.kauba_kood,NEW.kauba_seisundi_liik_id),
            HINT='Vali aktiivne seisundiliik.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_aktiivne_seisund', COLUMN='kauba_seisundi_liik_id';
    END IF;
    RETURN NEW;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_kaup_aktiivne_seisund() IS 'Kauba lisamisel ja tegelikul seisundimuudatusel peab uus seisundiliik olema aktiivne. FOR SHARE välistab selle samaaegse sulgemise.';

CREATE OR REPLACE TRIGGER trig_kaup_aktiivne_algseisund
BEFORE INSERT ON public.kaup
FOR EACH ROW
EXECUTE FUNCTION public.f_trig_kaup_aktiivne_seisund();
COMMENT ON TRIGGER trig_kaup_aktiivne_algseisund ON public.kaup IS 'Uus kaup vajab aktiivset seisundiliiki.';

CREATE OR REPLACE TRIGGER trig_kaup_aktiivne_uus_seisund
BEFORE UPDATE OF kauba_seisundi_liik_id ON public.kaup
FOR EACH ROW WHEN (OLD.kauba_seisundi_liik_id IS DISTINCT FROM NEW.kauba_seisundi_liik_id)
EXECUTE FUNCTION public.f_trig_kaup_aktiivne_seisund();
COMMENT ON TRIGGER trig_kaup_aktiivne_uus_seisund ON public.kaup IS 'Uus seisundiliik peab olema aktiivne.';

CREATE OR REPLACE FUNCTION public.f_trig_keela_truncate()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
BEGIN
    RAISE EXCEPTION 'Kaupade ja nende lisaandmete tühjendamine ei ole lubatud.' USING
            ERRCODE='check_violation',
            DETAIL=format('Tabel %I.%I, toiming %s.',TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP),
            HINT='Kasuta DELETE-lauset, mis kontrollib iga kauba seisundit.', SCHEMA=TG_TABLE_SCHEMA, TABLE=TG_TABLE_NAME,
            CONSTRAINT=TG_TABLE_NAME || '_truncate';
    RETURN NULL;
END;
$keha$;
COMMENT ON FUNCTION public.f_trig_keela_truncate() IS 'Keelab kaupade ja nende lisaandmete TRUNCATE-toimingu, mis jätaks reataseme kustutamiskontrollid vahele. Kustutamiseks tuleb kasutada DELETE-lauset.';

CREATE OR REPLACE TRIGGER trig_kaup_truncate
BEFORE TRUNCATE ON public.kaup
FOR EACH STATEMENT
EXECUTE FUNCTION public.f_trig_keela_truncate();
COMMENT ON TRIGGER trig_kaup_truncate ON public.kaup IS 'TRUNCATE on keelatud; kustutamisel tuleb läbida kauba seisundi kontroll.';

CREATE OR REPLACE TRIGGER trig_nutitelefon_truncate
BEFORE TRUNCATE ON public.nutitelefon
FOR EACH STATEMENT
EXECUTE FUNCTION public.f_trig_keela_truncate();
COMMENT ON TRIGGER trig_nutitelefon_truncate ON public.nutitelefon IS 'TRUNCATE on keelatud; kustutamisel tuleb läbida kauba seisundi kontroll.';

CREATE OR REPLACE TRIGGER trig_kauba_kategooria_omamine_truncate
BEFORE TRUNCATE ON public.kauba_kategooria_omamine
FOR EACH STATEMENT
EXECUTE FUNCTION public.f_trig_keela_truncate();
COMMENT ON TRIGGER trig_kauba_kategooria_omamine_truncate ON public.kauba_kategooria_omamine IS 'TRUNCATE on keelatud; kustutamisel tuleb läbida kauba seisundi kontroll.';

CREATE OR REPLACE TRIGGER trig_kauba_variant_truncate
BEFORE TRUNCATE ON public.kauba_variant
FOR EACH STATEMENT
EXECUTE FUNCTION public.f_trig_keela_truncate();
COMMENT ON TRIGGER trig_kauba_variant_truncate ON public.kauba_variant IS 'TRUNCATE on keelatud; kustutamisel tuleb läbida kauba seisundi kontroll.';

-- Trigerifunktsioone käivitavad trigerid, mitte rakendus otse.
REVOKE ALL ON FUNCTION public.f_trig_kaup_algseisund() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_seisundimuudatus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_aktiveerimine() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_kustutamine() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_muudetavus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kauba_osa_muudetavus() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_reg_andmed() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_viimase_muutm_aeg() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_kaup_aktiivne_seisund() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.f_trig_keela_truncate() FROM PUBLIC;

COMMIT;
