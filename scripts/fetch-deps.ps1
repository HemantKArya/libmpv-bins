<#
.SYNOPSIS
    Download prebuilt libmpv binaries for Windows
.EXAMPLE
    .\fetch-deps.ps1
    .\fetch-deps.ps1 -Platform android
    .\fetch-deps.ps1 -Platform all
#>
param(
    [ValidateSet("auto", "windows", "android", "all")]
    [string]$Platform = "auto",
    [string]$Version = "2026.04.26"
)

$ErrorActionPreference = "Stop"

$Repo = "YOUR_USERNAME/libmpv-prebuilt"
$BaseUrl = "https://github.com/$Repo/releases/download/v$Version"
$OutDir = Join-Path $PSScriptRoot "..\third_party\mpv"

function Fetch-Archive {
    param([string]$Name, [string]$DestDir)

    $Archive = "$Name.tar.gz"
    $Url = "$BaseUrl/$Archive"
    $VersionFile = Join-Path $DestDir ".version"

    if (Test-Path $VersionFile) {
        $Current = Get-Content $VersionFile -Raw
        if ($Current.Trim() -eq $Version) {
            Write-Host "  [OK] $Name already at v$Version" -ForegroundColor Green
            return
        }
    }

    Write-Host "  [->] Downloading $Archive..." -ForegroundColor Cyan
    $TmpFile = Join-Path $env:TEMP $Archive

    Invoke-WebRequest -Uri $Url -OutFile $TmpFile -UseBasicParsing

    if (Test-Path $DestDir) { Remove-Item $DestDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

    tar -xzf $TmpFile -C $DestDir
    Remove-Item $TmpFile -Force

    Set-Content -Path $VersionFile -Value $Version
    Write-Host "  [OK] $Name -> $DestDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "  libmpv-prebuilt v$Version"
Write-Host "  -------------------------"
Write-Host ""

if ($Platform -eq "auto") { $Platform = "windows" }

switch ($Platform) {
    "windows" {
        Fetch-Archive "libmpv-windows-x86_64"  "$OutDir\windows\x86_64"
        Fetch-Archive "libmpv-windows-aarch64" "$OutDir\windows\aarch64"
    }
    "android" {
        Fetch-Archive "libmpv-android-arm64-v8a"   "$OutDir\android\arm64-v8a"
        Fetch-Archive "libmpv-android-armeabi-v7a" "$OutDir\android\armeabi-v7a"
        Fetch-Archive "libmpv-android-x86_64"      "$OutDir\android\x86_64"
        Fetch-Archive "libmpv-android-x86"         "$OutDir\android\x86"
    }
    "all" {
        & $MyInvocation.MyCommand.Path -Platform "windows" -Version $Version
        & $MyInvocation.MyCommand.Path -Platform "android" -Version $Version
    }
}

Write-Host ""
Write-Host "  Done! Dependencies in: $OutDir" -ForegroundColor Green
Write-Host ""