-- Ü7 kolme baastabelit ühendava vaate päringu tekstiline täitmisplaan.
EXPLAIN (ANALYZE, BUFFERS)
SELECT kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus
FROM public.v_kaubad;
