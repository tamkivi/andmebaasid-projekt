@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set CP=tools\jackcess-4.0.5.jar;tools\commons-logging-1.3.4.jar;tools\commons-lang3-3.17.0.jar
set EAP_BASE=work\eap_edit\EA_converted.eap
set EAP_CLEAN=work\eap_edit\EA_cleaned.eap
set EAP_OUTPUT=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap
set EAP_SOURCE=preset_files\EA_converted_source.eap
set SQL_OUTPUT=jousaali_skript.sql
set DOCX_OUTPUT=Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx

echo === ITI0206 Build Pipeline ===

call :download_jar jackcess-4.0.5.jar "https://repo1.maven.org/maven2/com/healthmarketscience/jackcess/jackcess/4.0.5/jackcess-4.0.5.jar"
if errorlevel 1 goto :error
call :download_jar commons-logging-1.3.4.jar "https://repo1.maven.org/maven2/commons-logging/commons-logging/1.3.4/commons-logging-1.3.4.jar"
if errorlevel 1 goto :error
call :download_jar commons-lang3-3.17.0.jar "https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.17.0/commons-lang3-3.17.0.jar"
if errorlevel 1 goto :error

if not exist .venv\Scripts\python.exe (
    echo Creating Python virtual environment...
    python -m venv .venv
    if errorlevel 1 goto :error
)
set "PYTHON=.venv\Scripts\python.exe"
"%PYTHON%" -c "import docx; from PIL import Image" >nul 2>nul
if errorlevel 1 (
    echo Installing Python dependencies...
    "%PYTHON%" -m pip install -r requirements.txt
    if errorlevel 1 goto :error
)
if not exist "work\eap_edit" mkdir "work\eap_edit"

echo [1/8] Rendering Mermaid diagrams...
"%PYTHON%" tools\render_diagrams.py
if errorlevel 1 goto :error

echo [2/8] Compiling Java tools...
javac -cp "%CP%" tools\EapConvert.java tools\EapRename.java tools\EapFixes.java tools\EapDedupe.java
if errorlevel 1 goto :error

echo [3/8] Copying tracked EAP source...
if not exist "%EAP_SOURCE%" (
    echo Missing %EAP_SOURCE%. The original EA template is kept for reference, but the build requires the tracked Jackcess-compatible EAP source.
    goto :error
)
copy /Y "%EAP_SOURCE%" "%EAP_BASE%" >nul

echo [4/8] Preparing EAP from converted base...
copy /Y "%EAP_BASE%" "%EAP_OUTPUT%" >nul

echo [5/8] Running EAP rename + fixes...
java -cp "tools;%CP%" EapRename "%EAP_OUTPUT%"
if errorlevel 1 goto :error
java -cp "tools;%CP%" EapFixes "%EAP_OUTPUT%"
if errorlevel 1 goto :error
java -cp "tools;%CP%" EapDedupe "%EAP_OUTPUT%" "%EAP_CLEAN%"
if errorlevel 1 goto :error
copy /Y "%EAP_CLEAN%" "%EAP_OUTPUT%" >nul

echo [6/8] Generating structured DOCX...
"%PYTHON%" tools\fill_report_docx.py
if errorlevel 1 goto :error

echo [7/8] Generating SQL script...
"%PYTHON%" -c "from tools.sql_ddl import SQL_DDL; print(SQL_DDL.strip())" > "%SQL_OUTPUT%"
if errorlevel 1 goto :error

echo [8/8] Refreshing submission_files artifacts...
if not exist "submission_files" mkdir "submission_files"
if exist submission_files\rakendus rmdir /S /Q submission_files\rakendus
copy /Y "%DOCX_OUTPUT%" submission_files\dokument.docx >nul
copy /Y "%SQL_OUTPUT%" submission_files\skript.sql >nul
copy /Y "%EAP_OUTPUT%" submission_files\mudelid.eap >nul
if exist submission_files\dokument.zip del /Q submission_files\dokument.zip
if exist submission_files\mudelid.zip del /Q submission_files\mudelid.zip
if exist submission_files\rakendus.zip del /Q submission_files\rakendus.zip
pushd rakendus
powershell -NoProfile -Command "Compress-Archive -Path '.env.example','README.md','SETUP.sh','app.py','requirements.txt','test_data.sql','templates' -DestinationPath '..\submission_files\rakendus.zip' -Force"
if errorlevel 1 goto :error
popd

echo.
echo === Build complete ===
echo Output files:
echo   - Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.docx
echo   - Jousaali_infosusteemi_treeningute_funktsionaalne_allsusteem.eap
echo   - %SQL_OUTPUT%
echo   - submission_files\dokument.docx
echo   - submission_files\mudelid.eap
echo   - submission_files\skript.sql
echo   - submission_files\rakendus.zip
goto :eof

:download_jar
set "JAR_NAME=%~1"
set "JAR_URL=%~2"
if not exist "tools\%JAR_NAME%" (
    echo Downloading %JAR_NAME%...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '%JAR_URL%' -OutFile 'tools\%JAR_NAME%'"
    if errorlevel 1 exit /b 1
)
exit /b 0

:error
echo.
echo === Build FAILED ===
exit /b 1
