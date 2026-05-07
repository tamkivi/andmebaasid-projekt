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
EAP_OUTPUT="Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap"
DOCX_OUTPUT="Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx"

echo "=== ITI0206 Build Pipeline ==="

# Step 1: Compile Java tools
echo "[1/4] Compiling Java tools..."
javac -cp "$CP" tools/EapConvert.java tools/EapRename.java tools/EapFixes.java

# Step 2: Generate filled .docx
echo "[2/4] Generating filled .docx..."
python3 tools/fill_report_docx.py

# Step 3: Copy base EAP and run rename + fixes
echo "[3/4] Preparing EAP from converted base..."
cp "$EAP_BASE" "$EAP_OUTPUT"

echo "[4/4] Running EAP rename + fixes..."
java -cp "tools:$CP" EapRename "$EAP_OUTPUT"
java -cp "tools:$CP" EapFixes "$EAP_OUTPUT"

echo ""
echo "=== Build complete ==="
echo "Output files:"
echo "  - $DOCX_OUTPUT"
echo "  - $EAP_OUTPUT"
