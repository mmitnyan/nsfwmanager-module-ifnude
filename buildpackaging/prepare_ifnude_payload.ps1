param(
    [string]$Url = "https://github.com/s0md3v/ifnude/archive/refs/heads/main.zip",
    [string]$OutputRoot = "$PSScriptRoot\ifnude_payload"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[ifnude-payload] $Message"
}

$zipPath = Join-Path $OutputRoot "ifnude-main.zip"
$tempExtract = Join-Path $OutputRoot "_extract_tmp"
$targetFolder = Join-Path $OutputRoot "ifnude-main"

Write-Step "OutputRoot: $OutputRoot"
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

if (Test-Path $tempExtract) {
    Remove-Item -Recurse -Force $tempExtract
}
if (Test-Path $targetFolder) {
    Remove-Item -Recurse -Force $targetFolder
}

Write-Step "Downloading: $Url"
Invoke-WebRequest -Uri $Url -OutFile $zipPath

Write-Step "Extracting archive"
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force

function Resolve-IfnudeRoot {
    param([string]$BasePath)

    $exact = Join-Path $BasePath "ifnude-main"
    if (Test-Path (Join-Path $exact "ifnude\__init__.py")) {
        return $exact
    }

    $nested = Get-ChildItem -Path $BasePath -Directory -Recurse |
    Where-Object { Test-Path (Join-Path $_.FullName "ifnude\__init__.py") } |
    Select-Object -First 1
    if ($null -ne $nested) {
        return $nested.FullName
    }

    $flat = Get-ChildItem -Path $BasePath -Directory -Recurse |
    Where-Object {
        (Test-Path (Join-Path $_.FullName "__init__.py")) -and
        (Test-Path (Join-Path $_.FullName "detector.py"))
    } |
    Select-Object -First 1
    if ($null -ne $flat) {
        return $flat.FullName
    }

    return $null
}

$sourceRoot = Resolve-IfnudeRoot -BasePath $tempExtract
if ($null -eq $sourceRoot) {
    throw "Unable to locate extracted ifnude sources in $tempExtract"
}

Write-Step "Normalizing payload to: $targetFolder"
New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null

# Always build the expected tree:
# ifnude-main/
#   ifnude/__init__.py
$targetPackageDir = Join-Path $targetFolder "ifnude"
New-Item -ItemType Directory -Force -Path $targetPackageDir | Out-Null

$sourcePackageDir = Join-Path $sourceRoot "ifnude"
if (Test-Path (Join-Path $sourcePackageDir "__init__.py")) {
    Copy-Item -Path (Join-Path $sourcePackageDir "*") -Destination $targetPackageDir -Recurse -Force
}
elseif ((Test-Path (Join-Path $sourceRoot "__init__.py")) -and (Test-Path (Join-Path $sourceRoot "detector.py"))) {
    Copy-Item -Path (Join-Path $sourceRoot "*.py") -Destination $targetPackageDir -Force
}
else {
    throw "Invalid source layout. Missing ifnude package files in $sourceRoot"
}

foreach ($meta in @(".gitignore", "LICENSE.md", "README.md", "setup.py")) {
    $srcMeta = Join-Path $sourceRoot $meta
    if (Test-Path $srcMeta) {
        Copy-Item -Path $srcMeta -Destination (Join-Path $targetFolder $meta) -Force
    }
}

$probeFile = Join-Path $targetPackageDir "__init__.py"
if (-not (Test-Path $probeFile)) {
    throw "Invalid payload. Missing: $probeFile"
}

if (Test-Path $tempExtract) {
    Remove-Item -Recurse -Force $tempExtract
}

Write-Step "Payload is ready"
Write-Host "[ifnude-payload] OK: $targetFolder"
