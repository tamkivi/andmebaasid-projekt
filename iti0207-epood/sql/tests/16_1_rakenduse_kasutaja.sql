-- Käivita päris ühenduskasutajana; test_e_meil on kehtiva kaubahalduri aadress.
\set ON_ERROR_STOP on
SELECT current_user='t253787_epood_kaubahaldur'
    AND session_user=current_user AS korras \gset
\if :korras
\else
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kaubad_muutmiseks \gset
\if :korras
\else
    \echo Vaade v_kaubad_muutmiseks ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kauba_kategooriad \gset
\if :korras
\else
    \echo Vaade v_kauba_kategooriad ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kauba_variandid \gset
\if :korras
\else
    \echo Vaade v_kauba_variandid ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_varvide_valikud \gset
\if :korras
\else
    \echo Vaade v_varvide_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_ootel_kaubad \gset
\if :korras
\else
    \echo Vaade v_ootel_kaubad ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_aktiivsed_kaubad_haldurile \gset
\if :korras
\else
    \echo Vaade v_aktiivsed_kaubad_haldurile ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kauba_muutmise_vorm \gset
\if :korras
\else
    \echo Vaade v_kauba_muutmise_vorm ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_brandide_valikud \gset
\if :korras
\else
    \echo Vaade v_brandide_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kaamerate_valikud \gset
\if :korras
\else
    \echo Vaade v_kaamerate_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_sisemalude_valikud \gset
\if :korras
\else
    \echo Vaade v_sisemalude_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_diagonaalide_valikud \gset
\if :korras
\else
    \echo Vaade v_diagonaalide_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_protsessorite_valikud \gset
\if :korras
\else
    \echo Vaade v_protsessorite_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_ekraani_resolutsioonide_valikud \gset
\if :korras
\else
    \echo Vaade v_ekraani_resolutsioonide_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kategooriate_valikud_tyybiga \gset
\if :korras
\else
    \echo Vaade v_kategooriate_valikud_tyybiga ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_kaupade_detailid_seostega \gset
\if :korras
\else
    \echo Vaade v_kaupade_detailid_seostega ei tagastanud ridu
    \quit 1
\endif
SELECT count(*)>=1 AS korras FROM public.v_seotud_kategooriate_valikud \gset
\if :korras
\else
    \echo Vaade v_seotud_kategooriate_valikud ei tagastanud ridu
    \quit 1
\endif
SELECT public.f_on_kaubahaldur('puuduv@example.invalid','vale-naidis') IS FALSE AS korras \gset
\if :korras
\else
    \quit 1
\endif
BEGIN;
SELECT public.f_registreeri_nutitelefon_vormist('USR012','Ühenduskasutaja kontrolltelefon',899,
    'Tagasivõetav ühenduse kontroll.',NULL,:'test_e_meil','APPLE',NULL,NULL,
    12,48,256,6.1,'A16','2556x1179')='USR012' AS korras \gset
\if :korras
\else
    \quit 1
\endif
SELECT count(*)=1 AS korras FROM public.v_kaupade_detailid_seostega WHERE kauba_kood='USR012' \gset
\if :korras
\else
    \quit 1
\endif
ROLLBACK;
\set ON_ERROR_STOP off
SELECT * FROM public.kaup;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
INSERT INTO public.kaup DEFAULT VALUES;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaubad;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaupade_detailid;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaupade_koondaruanne;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_aktiivsed_kaubad;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kategooriate_valikud;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaupade_kategooriate_loendid;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaupade_kategooriate_pingeread;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM public.v_kaupade_json;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT public.f_lopeta_kaup('USR012','puuduv@example.invalid');
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT public.f_leia_tootaja('puuduv@example.invalid','KAUBAHALDUR');
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT laiendused.crypt('x','y');
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM valine.riik_sisend;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
SELECT * FROM valine.isik_sisend;
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
CREATE TABLE public.keelatud (kood integer);
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
CREATE TEMP TABLE keelatud (kood integer);
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\set ON_ERROR_STOP off
DO 'BEGIN NULL; END';
\set keeld :SQLSTATE
\set ON_ERROR_STOP on
SELECT :'keeld'='42501' AS korras \gset
\if :korras
\else
    \echo Oodati keeldu 42501, saadi :keeld
    \quit 1
\endif
\echo Ühenduskasutaja kontroll läbitud.
