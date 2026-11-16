#!/bin/sh
# Ühendus määratakse libpq keskkonnamuutujate ja paroolifailiga.
set -eu
umask 077
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
repo=$(CDPATH='' cd -- "$root/.." && pwd -P)
usage() {
    echo "Kasutus: $0 [uuri|kontrolli|testi] [LOGIKATALOOG]" >&2
    echo "        $0 paigalda KINNITAN [LOGIKATALOOG]" >&2
    echo 'Määra PGHOST, PGPORT, PGDATABASE ja PGUSER. Parool sobib faili ~/.pgpass.' >&2
}
mode=${1:-uuri}
if [ "$#" -gt 0 ]; then shift; fi
case "$mode" in
    uuri|kontrolli|testi) [ "$#" -le 1 ] || { usage; exit 2; } ;;
    paigalda)
        [ "${1:-}" = KINNITAN ] && [ "$#" -le 2 ] || { usage; exit 2; }
        shift ;;
    *) usage; exit 2 ;;
esac
: "${PGHOST:?Määra PGHOST}" "${PGDATABASE:?Määra PGDATABASE}" "${PGUSER:?Määra PGUSER}"
export PGPORT="${PGPORT:-5432}" PGCONNECT_TIMEOUT=5
command -v psql >/dev/null || { echo 'psql puudub käsuteelt.' >&2; exit 1; }
logs=${1:-$(mktemp -d /tmp/iti0207-koolikontroll.XXXXXX)}
mkdir -p -- "$logs"
logs=$(CDPATH='' cd -- "$logs" && pwd -P)
case "$logs/" in "$repo/"*) echo 'Logikataloog peab asuma väljaspool repositooriumi.' >&2; exit 2 ;; esac
psql_run() { psql -X -v ON_ERROR_STOP=1 "$@"; }
probe() {
    PGOPTIONS="${PGOPTIONS:-} -c default_transaction_read_only=on -c statement_timeout=10000" \
        psql_run -qAt >"$logs/uuri.log" <<'SQL'
SELECT 'Versioon: ' || version();
SELECT 'Ühendus: ' || current_user || ' / ' || current_database();
SELECT 'Kodeering: ' || current_setting('server_encoding') || '; järjestus: ' || datcollate FROM pg_database WHERE datname=current_database();
SELECT 'Oma roll: super=' || rolsuper || ', rollide loomine=' || rolcreaterole || ', andmebaaside loomine=' || rolcreatedb FROM pg_roles WHERE rolname=current_user;
SELECT 'Loomisõigus: andmebaas=' || has_database_privilege(current_database(),'CREATE') || ', public=' || has_schema_privilege('public','CREATE');
SELECT 'postgres_fdw: saadaval=' || EXISTS(SELECT FROM pg_available_extensions WHERE name='postgres_fdw') || ', paigaldatud=' || EXISTS(SELECT FROM pg_extension WHERE extname='postgres_fdw');
SELECT 'Skeemid: laiendused=' || EXISTS(SELECT FROM pg_namespace WHERE nspname='laiendused') || ', valine=' || EXISTS(SELECT FROM pg_namespace WHERE nspname='valine');
SELECT 'public: tabeleid=' || count(*) FILTER (WHERE relkind IN ('r','p')) || ', vaateid=' || count(*) FILTER (WHERE relkind='v') FROM pg_class WHERE relnamespace='public'::regnamespace;
SELECT 'public: f_ funktsioone=' || count(*) FROM pg_proc WHERE pronamespace='public'::regnamespace AND left(proname,2)='f_';
SELECT 'Domeenid: uus=' || (to_regtype('public.d_klassifikaatori_nimetus') IS NOT NULL) || ', vana=' || (to_regtype('public.klassifikaatori_nimetus') IS NOT NULL);
SELECT 'Rakenduseroll: ' || EXISTS(SELECT FROM pg_roles WHERE rolname='epood_rakendus');
SQL
    cat "$logs/uuri.log"
}
fresh() {
    PGOPTIONS="${PGOPTIONS:-} -c default_transaction_read_only=on -c statement_timeout=10000" \
        psql_run -qAt <<'SQL'
SELECT NOT (EXISTS(SELECT FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind IN ('r','p','v','m','S','f'))
 OR EXISTS(SELECT FROM pg_proc WHERE pronamespace='public'::regnamespace)
 OR EXISTS(SELECT FROM pg_type WHERE typnamespace='public'::regnamespace AND typtype='d')
 OR EXISTS(SELECT FROM pg_namespace WHERE nspname IN ('valine','laiendused'))
 OR EXISTS(SELECT FROM pg_roles WHERE rolname='epood_rakendus')
 OR EXISTS(SELECT FROM pg_foreign_server));
SQL
}
catalogue() {
    PGOPTIONS="${PGOPTIONS:-} -c default_transaction_read_only=on -c statement_timeout=10000" \
        psql_run -q >"$logs/kontrolli.log" <<'SQL'
DO $kontroll$
DECLARE
    v_nimed text[] := ARRAY['f_leia_tootaja','f_registreeri_nutitelefon','f_unusta_kaup',
        'f_aktiveeri_kaup','f_muuda_kaup_mitteaktiivseks','f_lopeta_kaup','f_muuda_kaup',
        'f_lisa_kaup_kategooriasse','f_eemalda_kaup_kategooriast','f_lisa_kauba_variant','f_eemalda_kauba_variant'];
    v_op text[] := ARRAY['OP1-OP10','OP1','OP2','OP3','OP4','OP5','OP6','OP7','OP8','OP9','OP10'];
    v_vaated text[] := ARRAY['v_kaubad_muutmiseks','v_kaubad','v_kauba_kategooriad','v_kauba_variandid',
        'v_kaupade_detailid','v_kaupade_koondaruanne','v_aktiivsed_kaubad','v_kategooriate_valikud',
        'v_varvide_valikud','v_kaupade_kategooriate_loendid','v_kaupade_kategooriate_pingeread','v_kaupade_json'];
    v_r record;
BEGIN
    IF NOT EXISTS(SELECT FROM pg_roles WHERE rolname='epood_rakendus') THEN
        RAISE EXCEPTION 'Rakenduseroll puudub';
    END IF;
    IF (SELECT count(*) FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname=ANY(v_nimed))<>11
        OR (SELECT count(DISTINCT proname) FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname=ANY(v_nimed))<>11 THEN
        RAISE EXCEPTION 'Oodatud on 11 üheselt määratud funktsiooni';
    END IF;
    FOR v_r IN SELECT p.*,l.lanname,array_position(v_nimed,p.proname::text) AS jrk
        FROM pg_proc p JOIN pg_language l ON l.oid=p.prolang
        WHERE p.pronamespace='public'::regnamespace AND p.proname=ANY(v_nimed)
    LOOP
        IF v_r.lanname<>'sql' OR NOT v_r.prosecdef OR v_r.prosqlbody IS NULL
            OR NOT coalesce(v_r.proconfig @> ARRAY['search_path=public, pg_temp'],false)
            OR coalesce(obj_description(v_r.oid,'pg_proc'),'') !~ ('\m'||v_op[v_r.jrk]||'\M') THEN
            RAISE EXCEPTION 'Funktsiooni % keel, turvaomadused või kommentaar ei vasta nõuetele',v_r.proname;
        END IF;
        IF has_function_privilege('epood_rakendus',v_r.oid,'EXECUTE')<>(v_r.proname<>'f_leia_tootaja') THEN
            RAISE EXCEPTION 'Funktsiooni % käivitusõigus ei vasta liidesele',v_r.proname;
        END IF;
    END LOOP;
    IF EXISTS(SELECT FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind IN ('r','p')
        AND has_table_privilege('epood_rakendus',oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')) THEN
        RAISE EXCEPTION 'Rakenduserollil on baastabeli otseõigus';
    END IF;
    IF (SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='v' AND relname=ANY(v_vaated))<>12 THEN
        RAISE EXCEPTION 'Kõik 12 lugemisvaadet peavad olema olemas';
    END IF;
    IF EXISTS(SELECT FROM pg_class WHERE relnamespace='public'::regnamespace AND relname=ANY(v_vaated)
        AND NOT has_table_privilege('epood_rakendus',oid,'SELECT')) THEN
        RAISE EXCEPTION 'Rakenduserollil puudub vaate lugemisõigus';
    END IF;
END;
$kontroll$;
SQL
    echo 'Kataloogikontroll läbitud: 11 funktsiooni, 10 avalikku käivitusõigust, 12 vaadet.'
}
case "$mode" in
    uuri)
        probe
        if [ "$(fresh)" != t ]; then
            echo 'Olemasolevaid objekte või rakenduserolli leiti. Värske paigalduse tee ei sobi; automaatset uuendamist ei tehta.'
        fi ;;
    kontrolli) catalogue ;;
    paigalda)
        probe
        [ "$(fresh)" = t ] || { echo 'Paigaldusest keelduti: olemasolevad objektid või rakenduseroll.' >&2; exit 1; }
        version=$(psql --version | sed -n 's/.* \([0-9][0-9]*\)\.[0-9].*/\1/p')
        [ -n "$version" ] && [ "$version" -ge 15 ] || { echo 'Paigaldamiseks on vaja psql versiooni 15 või uuemat.' >&2; exit 1; }
        export U8_ALLIKA_KASUTAJA="${TESTANDMETE_KASUTAJA:-$PGUSER}"
        export U8_ALLIKA_HOST="${TESTANDMETE_HOST:-$PGHOST}"
        export U8_ALLIKA_PORT="${TESTANDMETE_PORT:-$PGPORT}"
        export U8_ALLIKA_BAAS="${TESTANDMETE_ANDMEBAAS:-testandmed}"
        if [ "${U8_ALLIKA_PAROOL+x}" != x ]; then
            terminal=$(stty -g </dev/tty)
            trap 'stty "$terminal" </dev/tty; unset U8_ALLIKA_PAROOL' 0
            trap 'exit 1' 1 2 15
            stty -echo </dev/tty
            printf 'JSON-allika parool: ' >/dev/tty
            IFS= read -r U8_ALLIKA_PAROOL </dev/tty
            stty "$terminal" </dev/tty
            printf '\n' >/dev/tty
        fi
        export U8_ALLIKA_PAROOL
        # SQL-lausete väljatrükki ei lubata, sest kasutajaseos sisaldab parooli.
        {
            printf '%s\n' '\set ECHO none' '\set VERBOSITY terse' \
                '\getenv apex_kasutaja U8_ALLIKA_KASUTAJA' '\getenv apex_parool U8_ALLIKA_PAROOL' \
                '\getenv testandmete_host U8_ALLIKA_HOST' '\getenv testandmete_port U8_ALLIKA_PORT' \
                '\getenv testandmete_dbname U8_ALLIKA_BAAS'
            printf '\\i %s/sql/run_u5.sql\n' "'$root'"
        } | psql_run >/dev/null 2>&1 || {
            unset U8_ALLIKA_PAROOL
            echo 'Andmete laadimine katkes. Osaline paigaldus tuleb käsitsi üle vaadata. Parooli sisaldada võivat veaväljundit ei salvestatud.' >&2
            exit 1
        }
        unset U8_ALLIKA_PAROOL
        : >"$logs/paigalda.log"
        for f in 05_views.sql 09_rutiinid.sql 14_statistics.sql 16_rights.sql; do
            printf 'Fail: %s\n' "$f" >>"$logs/paigalda.log"
            psql_run -q -f "$root/sql/$f" >>"$logs/paigalda.log" 2>&1 || {
                echo "Paigaldus katkes. Veateade on failis $logs/paigalda.log. Osaline paigaldus tuleb käsitsi üle vaadata." >&2
                exit 1
            }
        done
        echo 'Paigaldusfailid täideti ettenähtud järjekorras.' >>"$logs/paigalda.log"
        catalogue
        echo 'Värske paigaldus lõpetatud.' ;;
    testi)
        catalogue
        # Näidete ja domeeni testil on oma väline ROLLBACK; teised saavad ümbrise.
        # run_all.sql ja korduvlaadimise test on mõeldud ainult eraldi testandmebaasi.
        sqlfile=$(mktemp /tmp/iti0207-testid.XXXXXX)
        trap 'rm -f -- "$sqlfile"' 0
        trap 'exit 1' 1 2 15
        cat >"$sqlfile" <<'SQL'
CREATE TEMP TABLE u8_sisu_enne (tabel text PRIMARY KEY,ridu bigint,rasi text);
SQL
        # Sisu asemel säilitatakse ainult reaarv ja räsi, neid ei prindita logisse.
        cat >>"$sqlfile" <<'SQL'
DO $enne$
DECLARE v_tabel text;
BEGIN
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename LOOP
        EXECUTE format('INSERT INTO u8_sisu_enne SELECT %L,count(*),md5(coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text)::text,''null'')) FROM public.%I t',v_tabel,v_tabel);
    END LOOP;
END;
$enne$;
SQL
        for f in 03_domains.sql 04_ddl.sql 04_tables.sql 05_views.sql 09_rutiinid.sql 09_rutiinid_naited.sql 10_indexes.sql 11_klassifikaatorid.sql 12_json_laadimine.sql 13_testandmed.sql 14_statistics.sql; do
            case "$f" in 03_domains.sql|09_rutiinid_naited.sql) ;; *) printf '%s\n' 'BEGIN;' >>"$sqlfile" ;; esac
            printf '\\i %s/sql/tests/%s\n' "'$root'" "$f" >>"$sqlfile"
            case "$f" in 03_domains.sql|09_rutiinid_naited.sql) ;; *) printf '%s\n' 'ROLLBACK;' >>"$sqlfile" ;; esac
        done
        printf '%s\n' 'BEGIN;' >>"$sqlfile"
        printf '\\i %s/sql/tests/16_rights.sql\n' "'$root'" >>"$sqlfile"
        printf '%s\n' 'ROLLBACK;' >>"$sqlfile"
        cat >>"$sqlfile" <<'SQL'
DO $parast$
DECLARE v_enne record; v_ridu bigint; v_rasi text;
BEGIN
    IF (SELECT count(*) FROM u8_sisu_enne)<>24 OR (SELECT count(*) FROM pg_tables WHERE schemaname='public')<>24 THEN
        RAISE EXCEPTION 'Tabelite hulk on puudulik või muutus';
    END IF;
    FOR v_enne IN SELECT * FROM u8_sisu_enne LOOP
        EXECUTE format('SELECT count(*),md5(coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text)::text,''null'')) FROM public.%I t',v_enne.tabel) INTO v_ridu,v_rasi;
        IF v_ridu<>v_enne.ridu OR v_rasi IS DISTINCT FROM v_enne.rasi THEN
            RAISE EXCEPTION 'Tabeli % sisu muutus',v_enne.tabel;
        END IF;
    END LOOP;
END;
$parast$;
SQL
        psql_run -q -f "$sqlfile" >"$logs/testi.log" 2>&1 || {
            echo "Testid katkesid. Veateade on failis $logs/testi.log" >&2
            exit 1
        }
        echo 'Testid läbitud: kõigi 24 tabeli reaarv ja sisu säilisid.' ;;
esac
echo "Logid: $logs"
