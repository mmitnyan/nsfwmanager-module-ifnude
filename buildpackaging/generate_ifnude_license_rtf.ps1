param(
    [Parameter(Mandatory = $true)]
    [string]$ReadmePath,
    [Parameter(Mandatory = $true)]
    [string]$LicensePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputRtfPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ReadmePath)) {
    throw "README not found: $ReadmePath"
}
if (-not (Test-Path -LiteralPath $LicensePath)) {
    throw "LICENSE not found: $LicensePath"
}

$readme = Get-Content -Raw -LiteralPath $ReadmePath
$license = Get-Content -Raw -LiteralPath $LicensePath

$content = "NSFW Manager - ifnude Engine`r`n`r`nREADME`r`n$readme`r`n`r`nLICENSE`r`n$license"
$content = $content -replace "`r`n|`r|`n", "`n"

# Escape RTF special chars.
$escaped = $content -replace '\\', '\\\\' -replace '\{', '\\{' -replace '\}', '\\}'
$lines = $escaped -split "`n"
$body = ($lines | Where-Object { $_ -ne '' }) -join '\par '

$rtf = "{\rtf1\ansi\deff0{\fonttbl{\f0 Arial;}}\fs20 $body }"
Set-Content -LiteralPath $OutputRtfPath -Value $rtf -Encoding ASCII
Write-Host "[ifnude-license-rtf] OK: $OutputRtfPath"
