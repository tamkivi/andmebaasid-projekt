"""
Jõusaali rühmatreeningute ajakava, registreerimise ja osalemise
funktsionaalne allsüsteem.

Flask prototüüp näitab kolme töövoogu:
- juhataja planeerib ja juhib treeningukordi;
- treener näeb enda tunniplaani ja märgib osalemist;
- klient registreerub, satub vajadusel ootejärjekorda ja tühistab registreeringu.
"""

from __future__ import annotations

from functools import wraps
import logging
import os

from dotenv import load_dotenv
from flask import Flask, flash, jsonify, redirect, render_template, request, session, url_for
from flask_session import Session
import psycopg2
from psycopg2.extras import RealDictCursor
from werkzeug.security import check_password_hash


load_dotenv()

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "iti0206-local-prototype-secret")
app.config["SESSION_TYPE"] = "filesystem"
Session(app)

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", "5432"),
    "database": os.environ.get("DB_NAME", "jousaali"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", "postgres"),
}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ROLE_LABELS = {
    "JUHATAJA": "Juhataja",
    "TREENER": "Treener",
    "KL_HALDUR": "Klassifikaatorite haldur",
    "TOO_HALD": "Töötajate haldur",
}

SESSION_STATUS_LABELS = {
    "KAVAND": "Kavandatud",
    "AVATUD": "Avatud",
    "SULETUD": "Suletud",
    "TOIMUNUD": "Toimunud",
    "TYHIST": "Tühistatud",
}

REGISTRATION_STATUS_LABELS = {
    "KINNIT": "Kinnitatud",
    "OOTEJRK": "Ootejärjekorras",
    "TYH_KL": "Kliendi poolt tühistatud",
    "TYH_SYS": "Süsteemi poolt tühistatud",
}


def get_db_connection():
    try:
        return psycopg2.connect(**DB_CONFIG)
    except psycopg2.Error as exc:
        logger.error("Andmebaasi ühenduse viga: %s", exc)
        return None


def init_db() -> bool:
    conn = get_db_connection()
    if not conn:
        return False
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        return True
    finally:
        conn.close()


def db_error_message(exc: psycopg2.Error) -> str:
    if getattr(exc, "diag", None) and exc.diag.message_primary:
        return exc.diag.message_primary
    return str(exc).strip() or "Andmebaasi toiming ebaõnnestus."


def login_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            return redirect(url_for("login"))
        return func(*args, **kwargs)

    return wrapper


def role_required(role_code: str):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if role_code not in session.get("roles", []):
                return render_template("error.html", error="Ligipääs keelatud"), 403
            return func(*args, **kwargs)

        return wrapper

    return decorator


def client_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if session.get("role") != "klient":
            return render_template("error.html", error="Ligipääs keelatud"), 403
        return func(*args, **kwargs)

    return wrapper


def display_role(user_session) -> str:
    for role in ("JUHATAJA", "TREENER", "KL_HALDUR", "TOO_HALD"):
        if role in user_session.get("roles", []):
            return ROLE_LABELS[role]
    if user_session.get("role") == "klient":
        return "Klient"
    if user_session.get("role") == "tootaja":
        return "Töötaja"
    return "Uudistaja"


def template_user():
    if "user_id" not in session:
        return {"role": "uudistaja", "roles": [], "name": "Uudistaja", "display_role": "Uudistaja"}
    user = dict(session)
    user["display_role"] = display_role(user)
    return user


def fetch_form_options(cur):
    cur.execute("""
        SELECT treeninguliigi_id, nimetus, kestus_minutites
        FROM treeninguliik
        WHERE treeninguliigi_seisundi_kood = 'AKTIIVNE'
        ORDER BY nimetus
    """)
    training_types = cur.fetchall()

    cur.execute("""
        SELECT
            r.ruumi_kood,
            r.nimetus,
            r.mahutavus,
            COALESCE(
                string_agg(rv.varustuse_nimetus || ' ' || rv.ruumi_varustuse_kogus::text || ' tk', ', ' ORDER BY rv.varustuse_nimetus),
                'varustus märkimata'
            ) AS varustuse_kokkuvote
        FROM ruum r
        LEFT JOIN ruumide_varustus rv ON rv.ruumi_kood = r.ruumi_kood
        WHERE r.on_aktiivne
        GROUP BY r.ruumi_kood, r.nimetus, r.mahutavus
        ORDER BY r.nimetus
    """)
    rooms = cur.fetchall()

    cur.execute("""
        SELECT
            treeninguliigi_id,
            treeninguliigi_nimetus,
            varustuse_nimetus,
            minimaalne_kogus,
            on_kohustuslik
        FROM treeninguliigi_varustuse_nouded
        ORDER BY treeninguliigi_nimetus, on_kohustuslik DESC, varustuse_nimetus
    """)
    equipment_requirements = cur.fetchall()

    cur.execute("""
        SELECT t.e_meil, concat_ws(' ', i.eesnimi, i.perenimi) AS nimi
        FROM tootaja t
        JOIN isik i ON i.e_meil = t.e_meil
        WHERE on_treener(t.e_meil)
        ORDER BY i.perenimi, i.eesnimi
    """)
    trainers = cur.fetchall()
    return training_types, rooms, trainers, equipment_requirements


@app.context_processor
def inject_template_helpers():
    return {
        "session_status_label": lambda code: SESSION_STATUS_LABELS.get(code, code),
        "registration_status_label": lambda code: REGISTRATION_STATUS_LABELS.get(code, code),
    }


@app.route("/")
def index():
    if "user_id" in session:
        return redirect(url_for("dashboard"))
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return render_template("login.html")

    email = (request.form.get("email") or "").strip()
    password = request.form.get("password") or ""
    if not email or not password:
        return render_template("login.html", error="E-post ja parool on nõutud."), 400

    conn = get_db_connection()
    if not conn:
        return render_template("login.html", error="Andmebaasi ühendus ebaõnnestus."), 500

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM fn_tuvasta_kasutaja_e_meili_jargi(%s)", (email,))
            user = cur.fetchone()

        if not user:
            return render_template("login.html", error="Kasutajat ei leitud."), 401
        if not user["on_aktiivne"]:
            return render_template("login.html", error="Konto ei ole aktiivne."), 401
        if not check_password_hash(user["parooli_rasi"], password):
            return render_template("login.html", error="Vale parool."), 401

        roles = list(user["rollid"] or [])
        full_name = " ".join(part for part in [user["eesnimi"], user["perenimi"]] if part)
        session.clear()
        session["user_id"] = user["e_meil"]
        session["name"] = full_name or user["e_meil"]
        session["role"] = user["kasutaja_liik"]
        session["roles"] = roles
        return redirect(url_for("dashboard"))
    except psycopg2.Error as exc:
        logger.error("Login viga: %s", exc)
        return render_template("login.html", error=db_error_message(exc)), 500
    finally:
        conn.close()


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/dashboard")
@login_required
def dashboard():
    conn = get_db_connection()
    if not conn:
        return render_template("dashboard.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    (SELECT COUNT(*) FROM avalikud_treeningukorrad) AS avatud_kordi,
                    (SELECT COUNT(*) FROM treeningukord WHERE treeningukorra_seisundi_kood = 'KAVAND') AS kavandatud_kordi,
                    (SELECT COUNT(*) FROM registreering WHERE registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_registreeringuid,
                    (SELECT COUNT(*) FROM registreering WHERE registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringuid,
                    (SELECT COUNT(*) FROM klient WHERE on_aktiivne) AS aktiivseid_kliente
            """)
            stats = cur.fetchone()
        return render_template("dashboard.html", stats=stats, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Dashboard viga: %s", exc)
        return render_template("dashboard.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/schedule")
@login_required
def schedule():
    conn = get_db_connection()
    if not conn:
        return render_template("schedule.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT *
                FROM avalikud_treeningukorrad
                ORDER BY alguse_aeg, treeninguliigi_nimetus
            """)
            sessions = cur.fetchall()

            registrations = {}
            if session.get("role") == "klient":
                cur.execute("""
                    SELECT treeningukorra_id, registreeringu_id, registreeringu_seisundi_kood, ootejarjekorra_nr
                    FROM kliendi_registreeringud
                    WHERE klient_e_meil = %s
                      AND registreeringu_seisundi_kood IN ('KINNIT', 'OOTEJRK')
                """, (session["user_id"],))
                registrations = {row["treeningukorra_id"]: row for row in cur.fetchall()}

        return render_template("schedule.html", sessions=sessions, registrations=registrations, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Schedule viga: %s", exc)
        return render_template("schedule.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/client/sessions/<int:treeningukorra_id>/register", methods=["POST"])
@login_required
@client_required
def client_register_session(treeningukorra_id):
    conn = get_db_connection()
    if not conn:
        flash("Andmebaasi ühendus ebaõnnestus.", "danger")
        return redirect(url_for("schedule"))
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                SELECT fn_registreeri_klient_treeningukorrale(
                    p_treeningukorra_id => %s,
                    p_klient_e_meil => %s
                )
                """,
                (treeningukorra_id, session["user_id"]),
            )
        conn.commit()
        flash("Registreering salvestati.", "success")
    except psycopg2.Error as exc:
        conn.rollback()
        flash(db_error_message(exc), "danger")
    finally:
        conn.close()
    return redirect(url_for("schedule"))


@app.route("/client/registrations")
@login_required
@client_required
def client_registrations():
    conn = get_db_connection()
    if not conn:
        return render_template("client_registrations.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT *
                FROM kliendi_registreeringud
                WHERE klient_e_meil = %s
                ORDER BY alguse_aeg DESC, registreeringu_id DESC
            """, (session["user_id"],))
            registrations = cur.fetchall()
        return render_template("client_registrations.html", registrations=registrations, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Client registrations viga: %s", exc)
        return render_template("client_registrations.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/client/registrations/<int:registreeringu_id>/cancel", methods=["POST"])
@login_required
def cancel_registration(registreeringu_id):
    if session.get("role") != "klient" and "JUHATAJA" not in session.get("roles", []):
        return render_template("error.html", error="Ligipääs keelatud"), 403
    reason = (request.form.get("reason") or "Kasutaja tühistas registreeringu.").strip()
    conn = get_db_connection()
    if not conn:
        flash("Andmebaasi ühendus ebaõnnestus.", "danger")
        return redirect(request.referrer or url_for("dashboard"))
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                SELECT fn_tyhista_registreering(
                    p_registreeringu_id => %s,
                    p_actor_e_meil => %s,
                    p_pohjus => %s
                )
                """,
                (registreeringu_id, session["user_id"], reason),
            )
        conn.commit()
        flash("Registreering tühistati.", "success")
    except psycopg2.Error as exc:
        conn.rollback()
        flash(db_error_message(exc), "danger")
    finally:
        conn.close()
    return redirect(request.referrer or url_for("client_registrations"))


@app.route("/manager/sessions")
@login_required
@role_required("JUHATAJA")
def manager_sessions():
    conn = get_db_connection()
    if not conn:
        return render_template("manager_sessions.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT *
                FROM juhataja_treeningukordade_ulevaade
                ORDER BY alguse_aeg DESC, treeningukorra_id DESC
            """)
            sessions = cur.fetchall()
        return render_template("manager_sessions.html", sessions=sessions, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Manager sessions viga: %s", exc)
        return render_template("manager_sessions.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/manager/sessions/new", methods=["GET", "POST"])
@login_required
@role_required("JUHATAJA")
def manager_new_session():
    conn = get_db_connection()
    if not conn:
        return render_template("manager_session_form.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            if request.method == "GET":
                training_types, rooms, trainers, equipment_requirements = fetch_form_options(cur)
                return render_template(
                    "manager_session_form.html",
                    training_types=training_types,
                    rooms=rooms,
                    trainers=trainers,
                    equipment_requirements=equipment_requirements,
                    user=template_user(),
                )

            values = {
                "treeninguliigi_id": request.form.get("treeninguliigi_id"),
                "treener_e_meil": request.form.get("treener_e_meil"),
                "ruumi_kood": request.form.get("ruumi_kood"),
                "alguse_aeg": request.form.get("alguse_aeg"),
                "lopu_aeg": request.form.get("lopu_aeg"),
                "registreerimise_lopp": request.form.get("registreerimise_lopp"),
                "tyhistamise_lopp": request.form.get("tyhistamise_lopp"),
                "maksimaalne_osalejate_arv": request.form.get("maksimaalne_osalejate_arv"),
            }
            cur.execute(
                """
                SELECT fn_planeeri_treeningukord(
                    p_treeninguliigi_id => %s,
                    p_treener_e_meil => %s,
                    p_ruumi_kood => %s,
                    p_alguse_aeg => %s,
                    p_lopu_aeg => %s,
                    p_registreerimise_lopp => %s,
                    p_tyhistamise_lopp => %s,
                    p_maksimaalne_osalejate_arv => %s,
                    p_juhataja_e_meil => %s
                )
                """,
                (
                    values["treeninguliigi_id"],
                    values["treener_e_meil"],
                    values["ruumi_kood"],
                    values["alguse_aeg"],
                    values["lopu_aeg"],
                    values["registreerimise_lopp"],
                    values["tyhistamise_lopp"],
                    values["maksimaalne_osalejate_arv"],
                    session["user_id"],
                ),
            )
        conn.commit()
        flash("Treeningukord planeeriti.", "success")
        return redirect(url_for("manager_sessions"))
    except psycopg2.Error as exc:
        conn.rollback()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            training_types, rooms, trainers, equipment_requirements = fetch_form_options(cur)
        return render_template(
            "manager_session_form.html",
            error=db_error_message(exc),
            training_types=training_types,
            rooms=rooms,
            trainers=trainers,
            equipment_requirements=equipment_requirements,
            user=template_user(),
            form=request.form,
        ), 400
    finally:
        conn.close()


def call_session_function(function_name: str, treeningukorra_id: int, *extra_args):
    conn = get_db_connection()
    if not conn:
        flash("Andmebaasi ühendus ebaõnnestus.", "danger")
        return redirect(url_for("manager_sessions"))
    session_calls = {
        "fn_ava_treeningukord": (
            "SELECT fn_ava_treeningukord(p_treeningukorra_id => %s, p_juhataja_e_meil => %s)",
            (treeningukorra_id, session["user_id"]),
        ),
        "fn_sulge_treeningukord": (
            "SELECT fn_sulge_treeningukord(p_treeningukorra_id => %s, p_juhataja_e_meil => %s)",
            (treeningukorra_id, session["user_id"]),
        ),
        "fn_lopeta_treeningukord": (
            "SELECT fn_lopeta_treeningukord(p_treeningukorra_id => %s, p_juhataja_e_meil => %s)",
            (treeningukorra_id, session["user_id"]),
        ),
        "fn_tyhista_treeningukord": (
            """
            SELECT fn_tyhista_treeningukord(
                p_treeningukorra_id => %s,
                p_juhataja_e_meil => %s,
                p_pohjus => %s
            )
            """,
            (treeningukorra_id, session["user_id"], extra_args[0] if extra_args else None),
        ),
    }
    try:
        query, params = session_calls[function_name]
        with conn.cursor() as cur:
            cur.execute(query, params)
        conn.commit()
        flash("Toiming õnnestus.", "success")
    except psycopg2.Error as exc:
        conn.rollback()
        flash(db_error_message(exc), "danger")
    finally:
        conn.close()
    return redirect(request.referrer or url_for("manager_sessions"))


@app.route("/manager/sessions/<int:treeningukorra_id>/open", methods=["POST"])
@login_required
@role_required("JUHATAJA")
def manager_open_session(treeningukorra_id):
    return call_session_function("fn_ava_treeningukord", treeningukorra_id)


@app.route("/manager/sessions/<int:treeningukorra_id>/close", methods=["POST"])
@login_required
@role_required("JUHATAJA")
def manager_close_session(treeningukorra_id):
    return call_session_function("fn_sulge_treeningukord", treeningukorra_id)


@app.route("/manager/sessions/<int:treeningukorra_id>/complete", methods=["POST"])
@login_required
@role_required("JUHATAJA")
def manager_complete_session(treeningukorra_id):
    return call_session_function("fn_lopeta_treeningukord", treeningukorra_id)


@app.route("/manager/sessions/<int:treeningukorra_id>/cancel", methods=["POST"])
@login_required
@role_required("JUHATAJA")
def manager_cancel_session(treeningukorra_id):
    reason = (request.form.get("reason") or "Juhataja tühistas treeningukorra.").strip()
    return call_session_function("fn_tyhista_treeningukord", treeningukorra_id, reason)


@app.route("/manager/report")
@login_required
@role_required("JUHATAJA")
def manager_report():
    conn = get_db_connection()
    if not conn:
        return render_template("manager_report.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT * FROM treeningute_taituvuse_statistika ORDER BY treeninguliigi_nimetus")
            occupancy = cur.fetchall()
            cur.execute("""
                SELECT *
                FROM juhataja_treeningukordade_ulevaade
                ORDER BY alguse_aeg DESC
                LIMIT 20
            """)
            sessions = cur.fetchall()
        return render_template("manager_report.html", occupancy=occupancy, sessions=sessions, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Manager report viga: %s", exc)
        return render_template("manager_report.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/trainer/sessions")
@login_required
@role_required("TREENER")
def trainer_sessions():
    conn = get_db_connection()
    if not conn:
        return render_template("trainer_sessions.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT *
                FROM treeneri_tunniplaan
                WHERE treener_e_meil = %s
                ORDER BY alguse_aeg DESC, treeningukorra_id DESC
            """, (session["user_id"],))
            sessions = cur.fetchall()
        return render_template("trainer_sessions.html", sessions=sessions, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Trainer sessions viga: %s", exc)
        return render_template("trainer_sessions.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/trainer/sessions/<int:treeningukorra_id>/roster")
@login_required
@role_required("TREENER")
def trainer_roster(treeningukorra_id):
    conn = get_db_connection()
    if not conn:
        return render_template("trainer_roster.html", error="Andmebaasi ühendus ebaõnnestus.", user=template_user()), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT *
                FROM treeneri_tunniplaan
                WHERE treeningukorra_id = %s
                  AND treener_e_meil = %s
            """, (treeningukorra_id, session["user_id"]))
            session_row = cur.fetchone()
            if not session_row and "JUHATAJA" not in session.get("roles", []):
                return render_template("error.html", error="Seda treeningukorda ei leitud sinu tunniplaanist."), 404
            if not session_row:
                cur.execute("""
                    SELECT *
                    FROM juhataja_treeningukordade_ulevaade
                    WHERE treeningukorra_id = %s
                """, (treeningukorra_id,))
                session_row = cur.fetchone()

            cur.execute("""
                SELECT *
                FROM treeningukorra_osalejad
                WHERE treeningukorra_id = %s
                ORDER BY
                    CASE registreeringu_seisundi_kood WHEN 'KINNIT' THEN 1 WHEN 'OOTEJRK' THEN 2 ELSE 3 END,
                    ootejarjekorra_nr NULLS LAST,
                    registreerimise_aeg
            """, (treeningukorra_id,))
            roster = cur.fetchall()
        return render_template("trainer_roster.html", session_row=session_row, roster=roster, user=template_user())
    except psycopg2.Error as exc:
        logger.error("Trainer roster viga: %s", exc)
        return render_template("trainer_roster.html", error=db_error_message(exc), user=template_user()), 500
    finally:
        conn.close()


@app.route("/trainer/sessions/<int:treeningukorra_id>/attendance", methods=["POST"])
@login_required
@role_required("TREENER")
def trainer_mark_attendance(treeningukorra_id):
    conn = get_db_connection()
    if not conn:
        flash("Andmebaasi ühendus ebaõnnestus.", "danger")
        return redirect(url_for("trainer_roster", treeningukorra_id=treeningukorra_id))
    try:
        registration_ids = request.form.getlist("registreeringu_id")
        with conn.cursor() as cur:
            for raw_id in registration_ids:
                on_osalenud = request.form.get(f"osales_{raw_id}") == "on"
                markus = (request.form.get(f"markus_{raw_id}") or "").strip() or None
                cur.execute(
                    """
                    SELECT fn_marki_osalemine(
                        p_registreeringu_id => %s,
                        p_markija_e_meil => %s,
                        p_on_osalenud => %s,
                        p_markus => %s
                    )
                    """,
                    (raw_id, session["user_id"], on_osalenud, markus),
                )
        conn.commit()
        flash("Osalemised salvestati.", "success")
    except psycopg2.Error as exc:
        conn.rollback()
        flash(db_error_message(exc), "danger")
    finally:
        conn.close()
    return redirect(url_for("trainer_roster", treeningukorra_id=treeningukorra_id))


@app.route("/api/stats")
@login_required
def api_stats():
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Andmebaasi ühendus ebaõnnestus."}), 500
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    (SELECT COUNT(*) FROM avalikud_treeningukorrad) AS avatud_kordi,
                    (SELECT COUNT(*) FROM registreering WHERE registreeringu_seisundi_kood = 'KINNIT') AS kinnitatud_registreeringuid,
                    (SELECT COUNT(*) FROM registreering WHERE registreeringu_seisundi_kood = 'OOTEJRK') AS ootel_registreeringuid
            """)
            return jsonify(cur.fetchone())
    except psycopg2.Error as exc:
        return jsonify({"error": db_error_message(exc)}), 500
    finally:
        conn.close()


@app.errorhandler(404)
def not_found(_error):
    return render_template("error.html", error="Lehte ei leitud."), 404


@app.errorhandler(500)
def internal_error(_error):
    return render_template("error.html", error="Sisemine serveri viga."), 500


if __name__ == "__main__":
    init_db()
    port = int(os.getenv("PORT", "5001"))
    app.run(debug=True, host="0.0.0.0", port=port)
