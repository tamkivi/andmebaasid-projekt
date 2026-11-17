-- Kasutaja tuvastamine kaupade halduri rakenduses.
START TRANSACTION;

CREATE OR REPLACE FUNCTION public.f_on_kaubahaldur(p_kasutajanimi text, p_parool text)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $keha$
DECLARE
    v_salvestatud_rasi public.kasutajakonto.parool%TYPE;
    v_naidisrasi CONSTANT text := '$2a$12$Hrp3v6fT8gpM9VOjszMM8.C7W1EoJzFgknYmfy0jxM9BxkgZ.Va6y';
    v_arvutatud_rasi text;
BEGIN
    SELECT k.parool INTO v_salvestatud_rasi
    FROM public.isik AS i
    INNER JOIN public.kasutajakonto AS k USING (isik_id)
    INNER JOIN public.isiku_seisundi_liik AS si USING (isiku_seisundi_liik_id)
    INNER JOIN public.tootaja AS t USING (isik_id)
    INNER JOIN public.tootaja_seisundi_liik AS st USING (tootaja_seisundi_liik_id)
    WHERE lower(i.e_meil)=lower(p_kasutajanimi)
        AND k.on_aktiivne
        AND si.kood='EL'
        AND st.kood IN ('KA','TO','PU')
        AND EXISTS (
            SELECT 1 FROM public.tootaja_rolli_omamine AS o
            INNER JOIN public.tootaja_roll AS r USING (tootaja_roll_id)
            WHERE o.tootaja_id=t.tootaja_id AND r.kood='KAUBAHALDUR' AND r.on_aktiivne
                AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP);

    -- Räsi arvutatakse ka siis, kui sobivat kontot ei leitud.
    v_arvutatud_rasi := laiendused.crypt(p_parool,COALESCE(v_salvestatud_rasi,v_naidisrasi));

    RETURN COALESCE(v_salvestatud_rasi IS NOT NULL AND v_salvestatud_rasi=v_arvutatud_rasi,FALSE);
END;
$keha$;

COMMENT ON FUNCTION public.f_on_kaubahaldur(text, text) IS
'Autendib ja autoriseerib kaupade halduri. p_kasutajanimi on tõstutundetu meiliaadress,
p_parool on avatekstiline tõstutundlik parool. TRUE tähendab, et parool on õige,
konto on aktiivne, isik on elus (EL), töötaja seisund on KA, TO või PU ning tal on
praegu aktiivne roll KAUBAHALDUR (alguse_aeg <= praegune aeg < lopu_aeg).
Muudel juhtudel, ka NULL-sisendi korral, on tulemus FALSE. Puuduva sobiva konto
korral kasutatakse sama algoritmi ja kuluteguriga näidisräsi (bcrypt, 12), et
vähendada kontode eristamist vastamisaja põhjal; täiesti võrdset aega see ei taga.';

REVOKE ALL ON FUNCTION public.f_on_kaubahaldur(text, text) FROM PUBLIC;

COMMIT;
