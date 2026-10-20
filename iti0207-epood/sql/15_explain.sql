-- Kolme baastabelit ühendava kaupade nimekirja päringu täitmisplaan.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT kauba_kood,nimetus,brand_nimetus,seisundi_nimetus,hind,kirjeldus
FROM public.v_kaubad
WHERE hind BETWEEN 100 AND 1000
ORDER BY nimetus,kauba_kood;
