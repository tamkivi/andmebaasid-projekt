#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Download dependencies if missing
download_jar() {
    local name="$1" url="$2"
    if [ ! -f "tools/$name" ]; then
        echo "Downloading $name..."
        curl -sL -o "tools/$name" "$url"
    fi
}
download_jar jackcess-4.0.5.jar \
    "https://repo1.maven.org/maven2/com/healthmarketscience/jackcess/jackcess/4.0.5/jackcess-4.0.5.jar"
download_jar commons-logging-1.3.4.jar \
    "https://repo1.maven.org/maven2/commons-logging/commons-logging/1.3.4/commons-logging-1.3.4.jar"
download_jar commons-lang3-3.17.0.jar \
    "https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.17.0/commons-lang3-3.17.0.jar"

CP="tools/jackcess-4.0.5.jar:tools/commons-logging-1.3.4.jar:tools/commons-lang3-3.17.0.jar"
EAP_BASE="work/eap_edit/EA_converted.eap"
EAP_CLEAN="work/eap_edit/EA_cleaned.eap"
EAP_OUTPUT="Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap"
DOCX_OUTPUT="Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx"
EAP_SOURCE="preset_files/EA_converted_source.eap"

ensure_python() {
    if [ -n "${PYTHON:-}" ]; then
        "$PYTHON" - <<'PY'
import docx
from PIL import Image
PY
        return
    fi
    if [ ! -x ".venv/bin/python" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv .venv
    fi
    PYTHON=".venv/bin/python"
    if ! "$PYTHON" - <<'PY' >/dev/null 2>&1
import docx
from PIL import Image
PY
    then
        echo "Installing Python dependencies..."
        "$PYTHON" -m pip install -r requirements.txt
    fi
}

echo "=== ITI0206 Build Pipeline ==="

ensure_python
mkdir -p work/eap_edit

echo "[1/5] Compiling Java tools..."
javac -cp "$CP" tools/EapConvert.java tools/EapRename.java tools/EapFixes.java tools/EapDedupe.java

echo "[2/5] Copying tracked EAP source..."
if [ ! -f "$EAP_SOURCE" ]; then
    echo "Missing $EAP_SOURCE. The original EA template is kept for reference, but the build requires the tracked Jackcess-compatible EAP source."
    exit 1
fi
cp "$EAP_SOURCE" "$EAP_BASE"

echo "[3/5] Preparing EAP from converted base..."
cp "$EAP_BASE" "$EAP_OUTPUT"

echo "[4/5] Running EAP rename + fixes..."
java -cp "tools:$CP" EapRename "$EAP_OUTPUT"
java -cp "tools:$CP" EapFixes "$EAP_OUTPUT"
java -cp "tools:$CP" EapDedupe "$EAP_OUTPUT" "$EAP_CLEAN"
mv "$EAP_CLEAN" "$EAP_OUTPUT"

echo "[5/5] Generating structured DOCX..."
"$PYTHON" tools/fill_report_docx.py

echo ""
echo "=== Build complete ==="
echo "Output files:"
echo "  - $DOCX_OUTPUT"
echo "  - $EAP_OUTPUT"
