#!/bin/bash
set -euo pipefail

echo "Jõusaali rühmatreeningute prototüübi seadistamine"
echo "Andmebaasid I, ITI0206"
echo

echo "[1/4] Virtuaalse keskkonna loomine"
python3 -m venv venv
source venv/bin/activate

echo "[2/4] Pakettide paigaldamine"
pip install -r requirements.txt

echo "[3/4] .env faili ettevalmistamine"
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Loodi .env. Muuda selles PostgreSQL ühenduse väärtused."
else
    echo ".env on juba olemas."
fi

echo "[4/4] PostgreSQL draiveri kontroll"
python3 - <<'PY'
import psycopg2
print("psycopg2 on paigaldatud")
PY

echo
echo "Järgmised sammud:"
echo "1. Impordi juurkaustas: psql -v ON_ERROR_STOP=1 -d jousaali -f submission_files/skript.sql"
echo "2. Muuda rakendus/.env vastavalt enda andmebaasile."
echo "3. Käivita kataloogis rakendus/: python app.py"
echo "4. Ava http://127.0.0.1:5001"
