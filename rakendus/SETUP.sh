#!/bin/bash
# Jõusaali Infosüsteemi - Rakenduse seadistamise skript

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Jõusaali Infosüsteemi - Rakenduse Seadistamine               ║"
echo "║  ITI0206 - Andmebaaside projektid                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 1. Virtuaalse keskkonna loomine
echo "[1/5] Virtuaalse keskkonna loomine..."
python3 -m venv venv
source venv/bin/activate

# 2. Paketite paigaldamine
echo "[2/5] Vajalike paketite paigaldamine..."
pip install -r requirements.txt

# 3. Keskkonna muutujate seadistamine
echo "[3/5] Keskkonna muutujate seadistamine..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "   ⚠️  .env fail loodud. Palun redigeerige andmebaasi üksikasju!"
else
    echo "   ℹ️  .env fail juba olemas."
fi

# 4. Andmebaasi kontroll
echo "[4/5] Andmebaasi kontroll..."
python3 << 'EOF'
import sys
try:
    import psycopg2
    print("   ✅ PostgreSQL draiver on paigaldatud")
except ImportError:
    print("   ❌ PostgreSQL draivert pole paigaldatud")
    sys.exit(1)
EOF

# 5. Rakenduse käivitus
echo "[5/5] Rakendus on valmis käivitamiseks!"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Järgmised sammud:                                             ║"
echo "║  1. Redigeerige .env faili PostgreSQL andmetega                ║"
echo "║  2. Looge andmebaas PostgreSQL-is                             ║"
echo "║  3. Käivitage: python app.py                                  ║"
echo "║  4. Minge: http://localhost:5000                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
