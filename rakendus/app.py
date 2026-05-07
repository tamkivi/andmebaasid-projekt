"""
Jõusaali Infosüsteemi - Treeningu Funktsionaalne Allsüsteem
Flask rakendus

Author: Tristan Aik Sild, Gustav Tamkivi
Course: ITI0206 - Andmebaaside projektid
"""

from decimal import Decimal, InvalidOperation
from functools import wraps
import logging
import os

from dotenv import load_dotenv
from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from flask_session import Session
import psycopg2
from psycopg2.extras import RealDictCursor
from werkzeug.security import check_password_hash

load_dotenv()

# Konfigureerimine
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'iti0206-local-prototype-secret')
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

TRAINING_EDITABLE_STATUSES = ('OOTEL', 'MITTEAKT')
TRAINING_FINISHABLE_STATUSES = ('AKTIIVNE', 'MITTEAKT')
ROLE_LABELS = {
    'TREENER': 'Treener',
    'JUHATAJA': 'Juhataja',
    'KL_HALDUR': 'Klassifikaatorite haldur',
    'TOO_HALD': 'Töötajate haldur',
}

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

        cur.execute("""
            INSERT INTO treeningu_seisundi_liik (kood, nimetus, on_aktiivne) VALUES
            ('OOTEL', 'Ootel', TRUE),
            ('AKTIIVNE', 'Aktiivne', TRUE),
            ('MITTEAKT', 'Mitteaktiivne', TRUE),
            ('LOPPENUD', 'Lõppenud', FALSE),
            ('UNUSTATUD', 'Unustatud', FALSE)
            ON CONFLICT (kood) DO NOTHING
        """)

        cur.execute("""
            INSERT INTO treeningu_kategooria_tyyp (kood, nimetus, on_aktiivne) VALUES
            ('GRUPP', 'Grupitreening', TRUE),
            ('PERS', 'Personaaltreening', TRUE),
            ('KARDIO', 'Kardiotreening', TRUE),
            ('JÕUD', 'Jõutreening', TRUE)
            ON CONFLICT (kood) DO NOTHING
        """)

        cur.execute("""
            INSERT INTO treeningu_kategooria
            (kood, treeningu_kategooria_tyyp_kood, nimetus, on_aktiivne) VALUES
            ('GRUPP', 'GRUPP', 'Grupitreening', TRUE),
            ('PERS', 'PERS', 'Personaaltreening', TRUE),
            ('KARDIO', 'KARDIO', 'Kardiotreening', TRUE),
            ('JÕUD', 'JÕUD', 'Jõutreening', TRUE)
            ON CONFLICT (kood) DO NOTHING
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
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def has_role(role_code):
    """Kontrolli, kas sisselogitud kasutajal on konkreetne tööalane roll."""
    return role_code in session.get('roles', [])

def display_role(user_session):
    """Tagasta kasutajale kuvatav rollinimetus."""
    roles = user_session.get('roles', [])
    for role in ('TREENER', 'JUHATAJA', 'KL_HALDUR', 'TOO_HALD'):
        if role in roles:
            return ROLE_LABELS[role]
    if user_session.get('role') == 'tootaja':
        return 'Töötaja'
    if user_session.get('role') == 'uudistaja':
        return 'Uudistaja'
    return 'Klient'

def template_user():
    if 'user_id' not in session:
        return {'role': 'uudistaja', 'roles': [], 'name': 'Uudistaja', 'display_role': 'Uudistaja'}
    user = dict(session)
    user['display_role'] = display_role(user)
    return user

def load_training_categories(cur):
    cur.execute("""
        SELECT kood, nimetus
        FROM treeningu_kategooria
        WHERE on_aktiivne = TRUE
        ORDER BY nimetus
    """)
    return cur.fetchall()

def validate_training_form(form):
    errors = []

    name = (form.get('name') or '').strip()
    description = (form.get('description') or '').strip()
    equipment = (form.get('equipment') or '').strip()
    categories = list(dict.fromkeys(form.getlist('categories')))

    if not name:
        errors.append('Treeningu nimetus on nõutud.')
    if not description:
        errors.append('Kirjeldus on nõutud.')
    if not equipment:
        errors.append('Vajalik varustus on nõutud.')
    if not categories:
        errors.append('Valige vähemalt üks kategooria.')

    try:
        duration = int(form.get('duration', ''))
        if duration < 15 or duration > 240:
            errors.append('Kestus peab olema vahemikus 15 kuni 240 minutit.')
    except (TypeError, ValueError):
        duration = None
        errors.append('Kestus peab olema täisarv.')

    try:
        max_participants = int(form.get('max_participants', ''))
        if max_participants <= 0:
            errors.append('Maksimaalne osalejate arv peab olema positiivne täisarv.')
    except (TypeError, ValueError):
        max_participants = None
        errors.append('Maksimaalne osalejate arv peab olema täisarv.')

    try:
        price = Decimal(form.get('price', '')).quantize(Decimal('0.01'))
        if price < 0:
            errors.append('Hind ei tohi olla negatiivne.')
        if price > Decimal('999999.99'):
            errors.append('Hind on andmebaasi välja jaoks liiga suur.')
    except (InvalidOperation, TypeError, ValueError):
        price = None
        errors.append('Hind peab olema korrektne arv.')

    return {
        'name': name,
        'description': description,
        'duration': duration,
        'max_participants': max_participants,
        'equipment': equipment,
        'price': price,
        'categories': categories,
    }, errors

def update_training_status(cur, training_id, next_status, allowed_statuses, changed_by):
    cur.execute("""
        UPDATE treening
        SET treeningu_seisundi_liik_kood = %s,
            viimase_muutja_e_meil = %s,
            viimase_muutm_aeg = NOW()
        WHERE treeningu_kood = %s
          AND treeningu_seisundi_liik_kood = ANY(%s)
    """, (next_status, changed_by, training_id, list(allowed_statuses)))
    return cur.rowcount

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

        return render_template('dashboard.html', stats=stats, user=template_user())

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
def trainings():
    """Näita treeninguid"""
    conn = get_db_connection()
    if not conn:
        return render_template('trainings.html', error='Andmebaasi viga'), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Töötajad näevad tööalast terviknimekirja; kliendid ja uudistajad ainult aktiivseid.
        if session.get('role') == 'tootaja':
            cur.execute("""
                SELECT t.treeningu_kood, t.nimetus, t.kirjeldus, t.kestus_minutites,
                       t.maksimaalne_osalejate_arv, t.hind,
                       s.kood as seisundi_kood, s.nimetus as seisund
                FROM treening t
                JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
                ORDER BY t.nimetus
            """)
        else:
            cur.execute("""
                SELECT t.treeningu_kood, t.nimetus, t.kirjeldus, t.kestus_minutites,
                       t.maksimaalne_osalejate_arv, t.hind,
                       s.kood as seisundi_kood, s.nimetus as seisund
                FROM treening t
                JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
                WHERE s.kood = 'AKTIIVNE'
                ORDER BY t.nimetus
            """)

        trainings = cur.fetchall()
        return render_template('trainings.html', trainings=trainings, user=template_user())

    except psycopg2.Error as e:
        logger.error(f"Trainings viga: {e}")
        return render_template('trainings.html', error='Andmebaasi viga'), 500
    finally:
        cur.close()
        conn.close()

@app.route('/training/<int:training_id>')
def training_detail(training_id):
    """Treeningu detailid"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Treeningu info
        visibility_condition = "" if session.get('role') == 'tootaja' else "AND t.treeningu_seisundi_liik_kood = 'AKTIIVNE'"
        cur.execute(f"""
            SELECT t.*, s.nimetus as seisund
            FROM treening t
            JOIN treeningu_seisundi_liik s ON t.treeningu_seisundi_liik_kood = s.kood
            WHERE t.treeningu_kood = %s
              {visibility_condition}
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
    if not has_role('TREENER'):
        return render_template('error.html', error='Ligipääs keelatud'), 403

    if request.method == 'GET':
        conn = get_db_connection()
        if not conn:
            return render_template('register_training.html', error='Andmebaasi viga'), 500

        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            categories = load_training_categories(cur)
            return render_template(
                'register_training.html',
                categories=categories,
                selected_categories=[],
                training=None,
                mode='create',
                user=template_user(),
            )
        finally:
            cur.close()
            conn.close()

    # POST
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        data, errors = validate_training_form(request.form)
        if errors:
            return jsonify({'error': ' '.join(errors)}), 400

        # Väldi prototüübis samaaegse lisamise korral MAX+1 konflikti.
        cur.execute("LOCK TABLE treening IN EXCLUSIVE MODE")
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
            data['name'],
            data['description'],
            data['duration'],
            data['max_participants'],
            data['equipment'],
            data['price']
        ))

        for cat in data['categories']:
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

@app.route('/trainer/edit-training/<int:training_id>', methods=['GET', 'POST'])
@login_required
def edit_training(training_id):
    """Muuda ootel või mitteaktiivset treeningut"""
    if not has_role('TREENER'):
        return render_template('error.html', error='Ligipääs keelatud'), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)

        if request.method == 'GET':
            cur.execute("""
                SELECT *
                FROM treening
                WHERE treeningu_kood = %s
                  AND treeningu_seisundi_liik_kood = ANY(%s)
            """, (training_id, list(TRAINING_EDITABLE_STATUSES)))
            training = cur.fetchone()
            if not training:
                return render_template('error.html', error='Muuta saab ainult ootel või mitteaktiivset treeningut.'), 404
            categories = load_training_categories(cur)
            cur.execute("""
                SELECT treeningu_kategooria_kood
                FROM treeningu_kategooria_omamine
                WHERE treeningu_kood = %s
            """, (training_id,))
            selected_categories = [row['treeningu_kategooria_kood'] for row in cur.fetchall()]
            return render_template(
                'register_training.html',
                categories=categories,
                selected_categories=selected_categories,
                training=training,
                mode='edit',
                user=template_user(),
            )

        data, errors = validate_training_form(request.form)
        if errors:
            return jsonify({'error': ' '.join(errors)}), 400

        cur.execute("""
            UPDATE treening
            SET nimetus = %s,
                kirjeldus = %s,
                kestus_minutites = %s,
                maksimaalne_osalejate_arv = %s,
                vajalik_varustus = %s,
                hind = %s,
                viimase_muutja_e_meil = %s,
                viimase_muutm_aeg = NOW()
            WHERE treeningu_kood = %s
              AND treeningu_seisundi_liik_kood = ANY(%s)
        """, (
            data['name'],
            data['description'],
            data['duration'],
            data['max_participants'],
            data['equipment'],
            data['price'],
            session['user_id'],
            training_id,
            list(TRAINING_EDITABLE_STATUSES),
        ))
        if cur.rowcount == 0:
            conn.rollback()
            return jsonify({'error': 'Muuta saab ainult ootel või mitteaktiivset treeningut.'}), 400

        cur.execute("""
            DELETE FROM treeningu_kategooria_omamine
            WHERE treeningu_kood = %s
        """, (training_id,))
        for cat in data['categories']:
            cur.execute("""
                INSERT INTO treeningu_kategooria_omamine
                (treeningu_kood, treeningu_kategooria_kood)
                VALUES (%s, %s)
            """, (training_id, cat))

        conn.commit()
        return jsonify({'success': True, 'id': training_id})

    except psycopg2.Error as e:
        logger.error(f"Edit training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Muutmise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/trainer/activate-training/<int:training_id>', methods=['POST'])
@login_required
def activate_training(training_id):
    """Aktiveeri treening"""
    if not has_role('TREENER'):
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

        updated = update_training_status(cur, training_id, 'AKTIIVNE', TRAINING_EDITABLE_STATUSES, session['user_id'])
        if updated == 0:
            conn.rollback()
            return jsonify({'error': 'Aktiveerida saab ainult ootel või mitteaktiivset treeningut'}), 400

        conn.commit()
        return jsonify({'success': True})

    except psycopg2.Error as e:
        logger.error(f"Activate training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Aktiveerimise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/trainer/deactivate-training/<int:training_id>', methods=['POST'])
@login_required
def deactivate_training(training_id):
    """Muuda aktiivne treening mitteaktiivseks"""
    if not has_role('TREENER'):
        return jsonify({'error': 'Ligipääs keelatud'}), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor()
        updated = update_training_status(cur, training_id, 'MITTEAKT', ('AKTIIVNE',), session['user_id'])
        if updated == 0:
            conn.rollback()
            return jsonify({'error': 'Mitteaktiivseks saab muuta ainult aktiivset treeningut'}), 400
        conn.commit()
        return jsonify({'success': True})
    except psycopg2.Error as e:
        logger.error(f"Deactivate training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Seisundi muutmise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/trainer/forget-training/<int:training_id>', methods=['POST'])
@login_required
def forget_training(training_id):
    """Unusta ootel treening"""
    if not has_role('TREENER'):
        return jsonify({'error': 'Ligipääs keelatud'}), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor()
        updated = update_training_status(cur, training_id, 'UNUSTATUD', ('OOTEL',), session['user_id'])
        if updated == 0:
            conn.rollback()
            return jsonify({'error': 'Unustada saab ainult ootel treeningut'}), 400
        conn.commit()
        return jsonify({'success': True})
    except psycopg2.Error as e:
        logger.error(f"Forget training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Unustamise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/manager/finish-training/<int:training_id>', methods=['POST'])
@login_required
def finish_training(training_id):
    """Lõpeta aktiivne või mitteaktiivne treening"""
    if not has_role('JUHATAJA'):
        return jsonify({'error': 'Ligipääs keelatud'}), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Andmebaasi viga'}), 500

    try:
        cur = conn.cursor()
        updated = update_training_status(cur, training_id, 'LOPPENUD', TRAINING_FINISHABLE_STATUSES, session['user_id'])
        if updated == 0:
            conn.rollback()
            return jsonify({'error': 'Lõpetada saab ainult aktiivset või mitteaktiivset treeningut'}), 400
        conn.commit()
        return jsonify({'success': True})
    except psycopg2.Error as e:
        logger.error(f"Finish training viga: {e}")
        conn.rollback()
        return jsonify({'error': 'Lõpetamise viga'}), 500
    finally:
        cur.close()
        conn.close()

@app.route('/manager/report')
@login_required
def manager_report():
    """Treeningute koondaruanne juhatajale"""
    if not has_role('JUHATAJA'):
        return render_template('error.html', error='Ligipääs keelatud'), 403

    conn = get_db_connection()
    if not conn:
        return render_template('report.html', error='Andmebaasi viga', user=template_user()), 500

    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""
            SELECT s.kood, s.nimetus, COUNT(t.treeningu_kood) AS arv
            FROM treeningu_seisundi_liik s
            LEFT JOIN treening t ON t.treeningu_seisundi_liik_kood = s.kood
            GROUP BY s.kood, s.nimetus
            ORDER BY s.nimetus
        """)
        by_status = cur.fetchall()

        cur.execute("""
            SELECT tk.nimetus AS kategooria, ktt.nimetus AS tyyp, COUNT(tko.treeningu_kood) AS arv
            FROM treeningu_kategooria tk
            JOIN treeningu_kategooria_tyyp ktt ON tk.treeningu_kategooria_tyyp_kood = ktt.kood
            LEFT JOIN treeningu_kategooria_omamine tko ON tko.treeningu_kategooria_kood = tk.kood
            GROUP BY tk.nimetus, ktt.nimetus
            ORDER BY ktt.nimetus, tk.nimetus
        """)
        by_category = cur.fetchall()
        return render_template('report.html', by_status=by_status, by_category=by_category, user=template_user())
    except psycopg2.Error as e:
        logger.error(f"Report viga: {e}")
        return render_template('report.html', error='Andmebaasi viga', user=template_user()), 500
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
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'MITTEAKT') as inactive,
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'LOPPENUD') as finished,
                (SELECT COUNT(*) FROM treening WHERE treeningu_seisundi_liik_kood = 'UNUSTATUD') as forgotten
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
