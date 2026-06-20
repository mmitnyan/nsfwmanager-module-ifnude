@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PAYLOAD_ROOT=%SCRIPT_DIR%ifnude_payload"
set "ASSETS_SOURCE_ROOT=%SCRIPT_DIR%..\assets"
set "README_SOURCE=%SCRIPT_DIR%..\README.md"
set "LICENSE_SOURCE=%SCRIPT_DIR%..\LICENSE"
set "LICENSE_RTF=%SCRIPT_DIR%ifnude_license.generated.rtf"
set "IFNUDE_SOURCE_ROOT=%PAYLOAD_ROOT%\ifnude-main"
set "WXS_MAIN=%SCRIPT_DIR%ifnude_engine.wxs"
set "WXS_HARVEST=%SCRIPT_DIR%ifnude_engine.harvest.wxs"
set "WXS_HARVEST_ASSETS=%SCRIPT_DIR%ifnude_assets.harvest.wxs"
set "OBJ_MAIN=%SCRIPT_DIR%ifnude_engine.wixobj"
set "OBJ_HARVEST=%SCRIPT_DIR%ifnude_engine.harvest.wixobj"
set "OBJ_HARVEST_ASSETS=%SCRIPT_DIR%ifnude_assets.harvest.wixobj"
set "NSFWMANAGER_MAJOR=2"
set "NSFWMANAGER_VERSION=%NSFWMANAGER_MAJOR%.0.0"
set "IFNUDE_SETUP_PY=%SCRIPT_DIR%..\engines\ifnude-main\setup.py"
set "IFNUDE_VERSION="
if exist "%IFNUDE_SETUP_PY%" (
    for /f "tokens=2 delims==" %%V in ('findstr /R /C:"^VERSION *= *[\"\047].*[\"\047]" "%IFNUDE_SETUP_PY%"') do set "IFNUDE_VERSION=%%~V"
)
if defined IFNUDE_VERSION (
    set "IFNUDE_VERSION=!IFNUDE_VERSION: =!"
    set "IFNUDE_VERSION=!IFNUDE_VERSION:'=!"
    set "IFNUDE_VERSION=!IFNUDE_VERSION:\"=!"
)
if not defined IFNUDE_VERSION set "IFNUDE_VERSION=0.0.3"
set "MSI_OUT=%SCRIPT_DIR%nsfwmanager-module-ifnude-%NSFWMANAGER_MAJOR%-%IFNUDE_VERSION%.msi"
set "WIX_BANNER_BMP=%ASSETS_SOURCE_ROOT%\WixUIBannerBmp.bmp"
set "WIX_DIALOG_BMP=%ASSETS_SOURCE_ROOT%\WixUIDialogBmp.bmp"

echo.
echo ============================================================================
echo   IFNUDE ENGINE - MSI BUILDER
echo   Source: https://github.com/s0md3v/ifnude/archive/refs/heads/main.zip
echo ============================================================================
echo.

REM --- [1/6] Localiser WiX (candle/light/heat) ---
echo [1/6] Localisation de WiX Toolset...
set "WIX_BIN="
if exist "%ProgramFiles(x86)%\WiX Toolset v3.14\bin\candle.exe" set "WIX_BIN=%ProgramFiles(x86)%\WiX Toolset v3.14\bin"
if exist "%ProgramFiles%\WiX Toolset v3.14\bin\candle.exe"       set "WIX_BIN=%ProgramFiles%\WiX Toolset v3.14\bin"
if exist "%ProgramFiles(x86)%\WiX Toolset v3.11\bin\candle.exe" set "WIX_BIN=%ProgramFiles(x86)%\WiX Toolset v3.11\bin"
if exist "%ProgramFiles%\WiX Toolset v3.11\bin\candle.exe"       set "WIX_BIN=%ProgramFiles%\WiX Toolset v3.11\bin"

if not defined WIX_BIN (
    echo [ERREUR] WiX Toolset introuvable.
    echo         Installez avec: winget install WiXToolset.WiXToolset
    exit /b 1
)

set "CANDLE=%WIX_BIN%\candle.exe"
set "LIGHT=%WIX_BIN%\light.exe"
set "HEAT=%WIX_BIN%\heat.exe"

echo [OK] WiX: !WIX_BIN!
if not exist "!HEAT!" (
    echo [ERREUR] heat.exe introuvable dans !WIX_BIN!
    exit /b 1
)
echo.

REM --- [2/6] Telecharger et preparer le payload ifnude-main ---
echo [2/6] Preparation du payload ifnude-main...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%prepare_ifnude_payload.ps1" -OutputRoot "%PAYLOAD_ROOT%"
if errorlevel 1 (
    echo [ERREUR] Echec preparation payload ifnude.
    exit /b 1
)

if not exist "%IFNUDE_SOURCE_ROOT%\ifnude\__init__.py" (
    echo [ERREUR] Payload invalide. Fichier manquant:
    echo         %IFNUDE_SOURCE_ROOT%\ifnude\__init__.py
    exit /b 1
)
if not exist "%ASSETS_SOURCE_ROOT%" (
    echo [ERREUR] Dossier assets introuvable: %ASSETS_SOURCE_ROOT%
    exit /b 1
)
if not exist "%WIX_BANNER_BMP%" (
    echo [ERREUR] WixUIBannerBmp.bmp introuvable: %WIX_BANNER_BMP%
    exit /b 1
)
if not exist "%WIX_DIALOG_BMP%" (
    echo [ERREUR] WixUIDialogBmp.bmp introuvable: %WIX_DIALOG_BMP%
    exit /b 1
)
if not exist "%README_SOURCE%" (
    echo [ERREUR] README.md introuvable: %README_SOURCE%
    exit /b 1
)
if not exist "%LICENSE_SOURCE%" (
    echo [ERREUR] LICENSE introuvable: %LICENSE_SOURCE%
    exit /b 1
)
echo [OK] Payload pret: %IFNUDE_SOURCE_ROOT%
echo [OK] Assets prets: %ASSETS_SOURCE_ROOT%
echo.

REM --- [2.5/6] Generer le texte de licence RTF (README + LICENSE) ---
echo [2.5/6] Generation de la licence RTF concatenee...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%generate_ifnude_license_rtf.ps1" -ReadmePath "%README_SOURCE%" -LicensePath "%LICENSE_SOURCE%" -OutputRtfPath "%LICENSE_RTF%"
if errorlevel 1 (
    echo [ERREUR] Echec generation du fichier RTF de licence.
    exit /b 1
)
if not exist "%LICENSE_RTF%" (
    echo [ERREUR] Fichier RTF de licence non genere: %LICENSE_RTF%
    exit /b 1
)
echo [OK] Licence RTF: %LICENSE_RTF%
echo.

REM --- [3/6] Generer les fragments WiX depuis les fichiers ifnude et assets ---
echo [3/6] Harvest des fichiers ifnude et assets (heat)...
if exist "%WXS_HARVEST%" del /q "%WXS_HARVEST%"
if exist "%WXS_HARVEST_ASSETS%" del /q "%WXS_HARVEST_ASSETS%"
"%HEAT%" dir "%IFNUDE_SOURCE_ROOT%" -nologo -gg -srd -sreg -dr IFNUDE_MAIN_DIR -cg IfnudeMainComponents -var var.IfnudeSourceRoot -out "%WXS_HARVEST%"
if errorlevel 1 (
    echo [ERREUR] heat a echoue.
    exit /b 1
)
"%HEAT%" dir "%ASSETS_SOURCE_ROOT%" -nologo -gg -srd -sreg -dr ASSETSDIR -cg AssetsComponents -var var.AssetsSourceRoot -out "%WXS_HARVEST_ASSETS%"
if errorlevel 1 (
    echo [ERREUR] heat a echoue sur les assets.
    exit /b 1
)
echo [OK] Fragment genere: %WXS_HARVEST%
echo [OK] Fragment genere: %WXS_HARVEST_ASSETS%
echo.

REM --- [4/6] Compilation candle ---
echo [4/6] Compilation WiX (candle)...
if exist "%OBJ_MAIN%" del /q "%OBJ_MAIN%"
if exist "%OBJ_HARVEST%" del /q "%OBJ_HARVEST%"
if exist "%OBJ_HARVEST_ASSETS%" del /q "%OBJ_HARVEST_ASSETS%"

"%CANDLE%" -nologo -arch x64 -ext WixUIExtension -dNsfwManagerVersion="%NSFWMANAGER_VERSION%" -dIfnudeVersion="%IFNUDE_VERSION%" -dLicenseRtfPath="%LICENSE_RTF%" "%WXS_MAIN%" -out "%OBJ_MAIN%"
if errorlevel 1 (
    echo [ERREUR] candle a echoue sur le fichier principal.
    exit /b 1
)

"%CANDLE%" -nologo -arch x64 -dIfnudeSourceRoot="%IFNUDE_SOURCE_ROOT%" "%WXS_HARVEST%" -out "%OBJ_HARVEST%"
if errorlevel 1 (
    echo [ERREUR] candle a echoue sur le fragment harvest.
    exit /b 1
)

"%CANDLE%" -nologo -arch x64 -dAssetsSourceRoot="%ASSETS_SOURCE_ROOT%" "%WXS_HARVEST_ASSETS%" -out "%OBJ_HARVEST_ASSETS%"
if errorlevel 1 (
    echo [ERREUR] candle a echoue sur le fragment assets.
    exit /b 1
)
echo [OK] Compilation terminee.
echo.


REM ==========================================================
REM   MSI SIGNATURE 
REM ==========================================================
echo [4.1] MSI Signing...
echo ----------------------------------------------------------

signtool sign /v /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a /n "Manuel Mitnyan" "%MSI_OUT%"

if %ERRORLEVEL% neq 0 (
    echo [ERREUR] Echec de la signature MSI.
    pause & exit /b 1
)

echo Verification de la signature MSI...
signtool verify /pa "%MSI_OUT%"
set VERIFY_MSI_RC=%ERRORLEVEL%

if %VERIFY_MSI_RC% equ 0 (
    echo [OK] Verification MSI valide.
) else if %VERIFY_MSI_RC% equ 1 (
    echo [INFO] Signature MSI valide mais verification partielle ^(timestamp ou chaine non encore resolue^).
) else (
    echo [ERREUR] Verification MSI invalide.
    pause & exit /b 1
)

echo [OK] MSI signe et valide.
echo.


REM --- [5/6] Edition de liens MSI ---
echo [5/6] Edition de liens (light)...
if exist "%MSI_OUT%" del /q "%MSI_OUT%"
"%LIGHT%" -nologo -ext WixUIExtension -dWixUIBannerBmp="%WIX_BANNER_BMP%" -dWixUIDialogBmp="%WIX_DIALOG_BMP%" "%OBJ_MAIN%" "%OBJ_HARVEST%" "%OBJ_HARVEST_ASSETS%" -out "%MSI_OUT%" -sice:ICE38 -sice:ICE57 -sice:ICE64
if errorlevel 1 (
    echo [ERREUR] light a echoue.
    exit /b 1
)
if not exist "%MSI_OUT%" (
    echo [ERREUR] MSI non genere.
    exit /b 1
)
for %%I in ("%MSI_OUT%") do set MSI_SIZE=%%~zI
set /a MSI_MB=!MSI_SIZE! / 1024 / 1024
echo [OK] MSI cree: %MSI_OUT%
echo      Taille: !MSI_MB! Mo
echo.

REM --- [6/6] Resume ---
echo [6/6] Installation cible (MSI per-user):
echo      %%LOCALAPPDATA%%\NsfwManager\engines\ifnude-main
echo.
echo Exemple installation silencieuse:
echo      msiexec /i "%MSI_OUT%" /qn

echo.
echo Termine.
endlocal
exit /b 0
