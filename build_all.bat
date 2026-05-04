@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set CP=tools\jackcess-4.0.5.jar;tools\commons-logging-1.3.4.jar;tools\commons-lang3-3.17.0.jar
set EAP_BASE=work\eap_edit\EA_converted.eap
set EAP_OUTPUT=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap

echo === ITI0206 Build Pipeline ===

echo [1/4] Compiling Java tools...
javac -cp "%CP%" tools\EapConvert.java tools\EapRename.java tools\EapFixes.java
if errorlevel 1 goto :error

echo [2/4] Generating filled .docx...
python3 tools\fill_report_docx.py
if errorlevel 1 goto :error

echo [3/4] Preparing EAP from converted base...
copy /Y "%EAP_BASE%" "%EAP_OUTPUT%" >nul

echo [4/4] Running EAP rename + fixes...
java -cp "tools;%CP%" EapRename "%EAP_OUTPUT%"
if errorlevel 1 goto :error
java -cp "tools;%CP%" EapFixes "%EAP_OUTPUT%"
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
