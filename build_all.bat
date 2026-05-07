@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set CP=tools\jackcess-4.0.5.jar;tools\commons-logging-1.3.4.jar;tools\commons-lang3-3.17.0.jar
set EAP_BASE=work\eap_edit\EA_converted.eap
set EAP_CLEAN=work\eap_edit\EA_cleaned.eap
set EAP_OUTPUT=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap
set EAP_SOURCE=preset_files\EA_converted_source.eap

echo === ITI0206 Build Pipeline ===

if not exist .venv\Scripts\python.exe (
    echo Creating Python virtual environment...
    python -m venv .venv
    if errorlevel 1 goto :error
)
set PYTHON=.venv\Scripts\python.exe
%PYTHON% -c "import docx; from PIL import Image" >nul 2>nul
if errorlevel 1 (
    echo Installing Python dependencies...
    %PYTHON% -m pip install -r requirements.txt
    if errorlevel 1 goto :error
)
if not exist work\eap_edit mkdir work\eap_edit

echo [1/5] Compiling Java tools...
javac -cp "%CP%" tools\EapConvert.java tools\EapRename.java tools\EapFixes.java tools\EapDedupe.java
if errorlevel 1 goto :error

echo [2/5] Copying tracked EAP source...
if not exist "%EAP_SOURCE%" (
    echo Missing %EAP_SOURCE%. The original EA template is kept for reference, but the build requires the tracked Jackcess-compatible EAP source.
    goto :error
)
copy /Y "%EAP_SOURCE%" "%EAP_BASE%" >nul

echo [3/5] Preparing EAP from converted base...
copy /Y "%EAP_BASE%" "%EAP_OUTPUT%" >nul

echo [4/5] Running EAP rename + fixes...
java -cp "tools;%CP%" EapRename "%EAP_OUTPUT%"
if errorlevel 1 goto :error
java -cp "tools;%CP%" EapFixes "%EAP_OUTPUT%"
if errorlevel 1 goto :error
java -cp "tools;%CP%" EapDedupe "%EAP_OUTPUT%" "%EAP_CLEAN%"
if errorlevel 1 goto :error
copy /Y "%EAP_CLEAN%" "%EAP_OUTPUT%" >nul

echo [5/5] Generating structured DOCX...
%PYTHON% tools\fill_report_docx.py
if errorlevel 1 goto :error

echo.
echo === Build complete ===
echo Output files:
echo   - Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx
echo   - Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap
goto :eof

:error
echo.
echo === Build FAILED ===
exit /b 1
