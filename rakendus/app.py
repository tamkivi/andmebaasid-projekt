"""
Jõusaali Infosüsteemi - Treeningu Funktsionaalne Allsüsteem
Flask rakendus

Author: Tristan Aik Sild, Gustav Tamkivi
Course: ITI0206 - Andmebaaside projektid
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from flask_session import Session
from werkzeug.security import check_password_hash, generate_password_hash
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime, timedelta
import logging

# Konfigureerimine
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'iti0206-local-demo-secret')
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)

# Andmebaasi ühendus
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'port': os.environ.get('DB_PORT', '5432'),
    'database': os.environ.get('DB_NAME', 'jousaali'),
    'user': os.environ.get('DB_USER', 'postgres'),
    'password': os.environ.get('DB_PASSWORD', 'postgres')
}

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# ANDMEBAASI FUNKTSIOONID
# ============================================================================

def get_db_connection():
    """Loo andmebaasi ühendus"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        logger.error(f"Andmebaasi ühenduse viga: {e}")
        return None

def init_db():
    """Initsialiseerige andmebaas (loo klassifikaatorid kui tühjad)"""
    conn = get_db_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()

        # Kontrollige kas klassifikaatorid on olemas
        cur.execute("SELECT COUNT(*) FROM treeningu_seisundi_liik")
        if cur.fetchone()[0] == 0:
            # Lisa seisundid
            cur.execute("""
                INSERT INTO treeningu_seisundi_liik (kood, nimetus, on_aktiivne) VALUES
                ('OOTEL', 'Ootel', TRUE),
                ('AKTIIVNE', 'Aktiivne', TRUE),
                    ('MITTEAKT', 'Mitteaktiivne', TRUE),
                ('LOPPENUD', 'Lõppenud', FALSE)
            """)

        # Lisage kategooria tüübid
        cur.execute("SELECT COUNT(*) FROM treeningu_kategooria_tyyp")
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO treeningu_kategooria_tyyp (kood, nimetus, on_aktiivne) VALUES
                ('GRUPP', 'Grupitreening', TRUE),
                ('PERS', 'Personaaltreening', TRUE),
                ('KARDIO', 'Kardiotreening', TRUE),
                ('JÕUD', 'Jõutreening', TRUE)
            """)

        cur.execute("SELECT COUNT(*) FROM treeningu_kategooria")
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO treeningu_kategooria
                (kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne) VALUES
                ('GRUPP', 'GRUPP', 'Grupitreening', TRUE),
                ('PERS', 'PERS', 'Personaaltreening', TRUE),
                ('KARDIO', 'KARDIO', 'Kardiotreening', TRUE),
                ('JÕUD', 'JÕUD', 'Jõutreening', TRUE)
            """)

        conn.commit()
        return True
    except psycopg2.Error as e:
        logger.error(f"DB init viga: {e}")
        conn.rollback()
        return False
    finally:
        cur.close()
        conn.close()

# ============================================================================
# AUTENTIMINE JA SESSIOON
# ============================================================================

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Kasutaja sisselogimine"""
    if request.method == 'GET':
        return render_template('login.html')

    email = request.form.get('email')
    password = request.form.get('password')

    if not email or not password:
        return render_template('login.html', error='E-mail ja parool nõutud'), 400

    conn = get_db_connection()
    if not conn:
        return render_template('login.html', error='Andmebaasi viga'), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Kontrollige kasutajakontot
        cur.execute("""
            SELECT k.e_meil, k.parool, k.on_aktiivne,
                   i.eesnimi, i.perenimi,
                   CASE WHEN t.e_meil IS NOT NULL THEN 'tootaja' ELSE 'klient' END as roll
            FROM kasutajakonto k
            JOIN isik i ON k.e_meil = i.e_meil
            LEFT JOIN tootaja t ON k.e_meil = t.e_meil
            WHERE k.e_meil = %s
        """, (email,))

        user = cur.fetchone()

        if not user:
            return render_template('login.html', error='Kasutajat ei leitud'), 401

        if not user['on_aktiivne']:
            return render_template('login.html', error='Konto ei ole aktiivne'), 401

        if not check_password_hash(user['parool'], password):
            return render_template('login.html', error='Vale parool'), 401

        # Kontrollige töötaja rolle
        roles = []
        if user['roll'] == 'tootaja':
            cur.execute("""
                SELECT DISTINCT tr.kood
                FROM tootaja_rolli_omamine tro
                JOIN tootaja_roll tr ON tro.tootaja_roll_kood = tr.kood
                WHERE tro.tootaja_e_meil = %s
                AND tro.lopu_aeg IS NULL
            """, (email,))
            roles = [r['kood'] for r in cur.fetchall()]

        # Seadista sessioon
        session['user_id'] = email
        session['name'] = f"{user['eesnimi']} {user['perenimi']}"
        session['role'] = user['roll']
        session['roles'] = roles

        return redirect(url_for('dashboard'))

    except psycopg2.Error as e:
        logger.error(f"Login viga: {e}")
        return render_template('login.html', error='Andmebaasi viga'), 500
    finally:
        cur.close()
        conn.close()

@app.route('/logout')
def logout():
    """Kasutaja väljalogimine"""
    session.clear()
    return redirect(url_for('login'))

def login_required(f):
    """Nõutakse sisselogimist"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# ============================================================================
# DASHBOARD JA PEALEHT
# ============================================================================

@app.route('/')
def index():
    """Pealeht"""
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    """Kasutaja dashboard"""
    conn = get_db_connection()
    if not conn:
        return render_template('dashboard.html', error='Andmebaasi viga'), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Aktiivsete treeningu arv
        cur.execute("""
            SELECT COUNT(*) as arv FROM treening
            WHERE treeningu_seisundi_liik_kood = 'AKTIIVNE'
        """)
        active_count = cur.fetchone()['arv']

        # Kasutajate arv
        cur.execute("SELECT COUNT(*) as arv FROM isik")
        users_count = cur.fetchone()['arv']

        # Treeningute arv
        cur.execute("SELECT COUNT(*) as arv FROM treening")
        trainings_count = cur.fetchone()['arv']

        stats = {
            'active_trainings': active_count,
            'total_users': users_count,
            'total_trainings': trainings_count
        }

        return render_template('dashboard.html', stats=stats, user=session)

    except psycopg2.Error as e:
        logger.error(f"Dashboard viga: {e}")
        return render_template('dashboard.html', error='Andmebaasi viga'), 500
    finally:
        cur.close()
        conn.close()

# ============================================================================
# TREENINGU HALDUS
# ============================================================================

@app.route('/trainings')
@login_required
def trainings():
    """Näita treeninguid"""
    conn = get_db_connection()
    if not conn:
        return render_template('trainings.html', error='Andmebaasi viga'), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Klient ja uudistaja näevad ainult aktiivseid
        if session.get('role') == 'tootaja':
            cur.execute("""
                SELECT t.treeningu_kood, t.nimetus, t.kirjeldus, t.kestus_minutites,
                       t.maksimaalne_osalejate_arv, t.hind, s.nimetus as seisund
                FROM treening t
                JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
                ORDER BY t.nimetus
            """)
        else:
            cur.execute("""
                SELECT t.treeningu_kood, t.nimetus, t.kirjeldus, t.kestus_minutites,
                       t.maksimaalne_osalejate_arv, t.hind, s.nimetus as seisund
                FROM treening t
                JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
                WHERE s.kood = 'AKTIIVNE'
                ORDER BY t.nimetus
            """)

        trainings = cur.fetchall()
        return render_template('trainings.html', trainings=trainings, user=session)

    except psycopg2.Error as e:
        logger.error(f"Trainings viga: {e}")
        return render_template('trainings.html', error='Andmebaasi viga'), 500
    finally:
        cur.close()
        conn.close()

@app.route('/training/<int:training_id>')
@login_required
def training_detail(training_id):
    """Treeningu detailid"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Treeningu info
        cur.execute("""
            SELECT t.*, s.nimetus as seisund
            FROM treening t
            JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
            WHERE t.treeningu_kood = %s
        """, (training_id,))

        training = cur.fetchone()
        if not training:
            return jsonify({'error': 'Treening ei leitud'}), 404

        # Kategooriad
        cur.execute("""
            SELECT tk.kood, tk.nimetus
            FROM treeningu_kategooria_omamine tko
            JOIN treeningu_kategooria tk ON tko.treeningu_kategooria_kood = tk.kood
            WHERE tko.treeningu_kood = %s
        """, (training_id,))

        categories = cur.fetchall()
        training['categories'] = categories

        return jsonify(training)

    except psycopg2.Error as e:
        logger.error(f"Training detail viga: {e}")
        return jsonify({'error': 'Andmebaasi viga'}), 500
    finally:
        cur.close()
        conn.close()

# ============================================================================
# TREENER FUNKTSIOONID
# ============================================================================

@app.route('/trainer/register-training', methods=['GET', 'POST'])
@login_required
def register_training():
    """Registreeri uus treening"""
    if session.get('role') != 'tootaja':
        return redirect(url_for('dashboard'))

    if request.method == 'GET':
        conn = get_db_connection()
        if not conn:
            return render_template('register_training.html', error='Andmebaasi viga'), 500

        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SELECT kood, nimetus FROM treeningu_kategooria WHERE on_aktiivne = TRUE")
            categories = cur.fetchall()
            return render_template('register_training.html', categories=categories, user=session)
        finally:
            cur.close()
            conn.close()

    # POST
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Leidke järgmine treening ID
        cur.execute("SELECT COALESCE(MAX(treeningu_kood), 0) + 1 as next_id FROM treening")
        next_id = cur.fetchone()['next_id']

        # Sisestage treening
        cur.execute("""
            INSERT INTO treening
            (treeningu_kood, treeningu_seisundi_liik_kood, registreerija_e_meil,
             viimase_muutja_e_meil, nimetus, kirjeldus, kestus_minutites,
             maksimaalne_osalejate_arv, vajalik_varustus, hind)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            next_id, 'OOTEL', session['user_id'], session['user_id'],
            request.form.get('name'),
            request.form.get('description'),
            int(request.form.get('duration')),
            int(request.form.get('max_participants')),
            request.form.get('equipment'),
            float(request.form.get('price'))
        ))

        # Lisa kategooriad
        categories = request.form.getlist('categories')
        for cat in categories:
            cur.execute("""
                INSERT INTO treeningu_kategooria_omamine
                (treeningu_kood, treeningu_kategooria_kood)
                VALUES (%s, %s)
            """, (next_id, cat))

        conn.commit()
        return jsonify({'success': True, 'id': next_id})

    except psycopg2.Error as e:
        logger.error(f"Register training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Registreerimise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/trainer/activate-training/<int:training_id>', methods=['POST'])
@login_required
def activate_training(training_id):
    """Aktiveeri treening"""
    if session.get('role') != 'tootaja':
        return jsonify({'error': 'Ligipääs keelatud'}), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor()

        # Kontrollige kategooriaid
        cur.execute("""
            SELECT COUNT(*) FROM treeningu_kategooria_omamine
            WHERE treeningu_kood = %s
        """, (training_id,))

        if cur.fetchone()[0] == 0:
            return jsonify({'error': 'Treening peab kuuluma vähemalt ühte kategooriasse'}), 400

        # Muutke seisundit
        cur.execute("""
            UPDATE treening
            SET treeningu_seisundi_liik_kood = %s,
                viimase_muutja_e_meil = %s,
                viimase_muutm_aeg = NOW()
            WHERE treeningu_kood = %s
        """, ('AKTIIVNE', session['user_id'], training_id))

        conn.commit()
        return jsonify({'success': True})

    except psycopg2.Error as e:
        logger.error(f"Activate training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Aktiveerimise viga'}), 500
    finally:
        cur.close()
        conn.close()

# ============================================================================
# API LÕPP-PUNKTID
# ============================================================================

@app.route('/api/stats')
@login_required
def api_stats():
    """Statistika API"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute("""
            SELECT
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'AKTIIVNE') as active,
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'OOTEL') as pending,
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'MITTEAKT') as inactive
        """)

        stats = cur.fetchone()
        return jsonify(stats)

    except psycopg2.Error as e:
        logger.error(f"Stats API viga: {e}")
        return jsonify({'error': 'Andmebaasi viga'}), 500
    finally:
        cur.close()
        conn.close()

# ============================================================================
# VEAPARANDUS
# ============================================================================

@app.errorhandler(404)
def not_found(e):
    """404 viga"""
    return render_template('error.html', error='Lehekülge ei leitud'), 404

@app.errorhandler(500)
def server_error(e):
    """500 viga"""
    logger.error(f"Server error: {e}")
    return render_template('error.html', error='Serveri viga'), 500

# ============================================================================
# RAKENDUSE KÄIVITAMINE
# ============================================================================

if __name__ == '__main__':
    # Initsialiseerige andmebaas
    init_db()

    # Käivitage rakendus
    app.run(
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 5000)),
        debug=os.environ.get('FLASK_ENV') == 'development'
    )
