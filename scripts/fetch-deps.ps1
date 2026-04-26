<#
.SYNOPSIS
    Download prebuilt libmpv binaries
.DESCRIPTION
    Downloads prebuilt libmpv libraries from GitHub Releases
    for use in cross-platform projects.
.EXAMPLE
    .\fetch-deps.ps1
    .\fetch-deps.ps1 -Platform android
    .\fetch-deps.ps1 -Platform all
    .\fetch-deps.ps1 -Platform windows -Version 2026.04.26
#>
param(
    [ValidateSet("auto", "windows", "android", "linux", "macos", "ios", "all")]
    [string]$Platform = "auto",

    [string]$Version = "2026.04.26",

    [string]$Repo = "YOUR_USERNAME/libmpv-prebuilt"
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://github.com/$Repo/releases/download/v$Version"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir = Join-Path $ScriptDir "..\third_party\mpv"

function Write-Step  { param([string]$Msg) Write-Host "  [->] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "  [!!] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "  [XX] $Msg" -ForegroundColor Red; exit 1 }

function Fetch-Archive {
    param(
        [string]$Name,
        [string]$DestDir
    )

    $Archive = "$Name.tar.gz"
    $Url = "$BaseUrl/$Archive"
    $VersionFile = Join-Path $DestDir ".version"

    # Skip if already downloaded
    if (Test-Path $VersionFile) {
        $Current = (Get-Content $VersionFile -Raw).Trim()
        if ($Current -eq $Version) {
            Write-Ok "$Name already at v$Version, skipping"
            return
        }
    }

    Write-Step "Downloading $Archive..."
    $TmpFile = Join-Path $env:TEMP $Archive

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $TmpFile -UseBasicParsing
    }
    catch {
        Write-Err "Failed to download $Url`n$($_.Exception.Message)"
    }

    Write-Step "Extracting to $DestDir..."
    if (Test-Path $DestDir) {
        Remove-Item $DestDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

    # tar is available on Windows 10+ natively
    tar -xzf $TmpFile -C $DestDir
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to extract $TmpFile"
    }

    Remove-Item $TmpFile -Force -ErrorAction SilentlyContinue
    Set-Content -Path $VersionFile -Value $Version -NoNewline

    Write-Ok "$Name -> $DestDir"
}

# ── Main ──
Write-Host ""
Write-Host "  libmpv-prebuilt v$Version" -ForegroundColor White
Write-Host "  -----------------------------"
Write-Host "  Repo:   $Repo"
Write-Host "  Output: $OutDir"
Write-Host ""

if ($Platform -eq "auto") {
    $Platform = "windows"
    Write-Ok "Auto-detected platform: windows"
    Write-Host ""
}

switch ($Platform) {
    "windows" {
        Fetch-Archive "libmpv-windows-x86_64"  (Join-Path $OutDir "windows\x86_64")
        Fetch-Archive "libmpv-windows-aarch64" (Join-Path $OutDir "windows\aarch64")
    }
    "android" {
        Fetch-Archive "libmpv-android-arm64-v8a"   (Join-Path $OutDir "android\arm64-v8a")
        Fetch-Archive "libmpv-android-armeabi-v7a" (Join-Path $OutDir "android\armeabi-v7a")
        Fetch-Archive "libmpv-android-x86_64"      (Join-Path $OutDir "android\x86_64")
        Fetch-Archive "libmpv-android-x86"         (Join-Path $OutDir "android\x86")
    }
    "linux" {
        Fetch-Archive "libmpv-linux-x86_64" (Join-Path $OutDir "linux\x86_64")
    }
    "macos" {
        Fetch-Archive "libmpv-macos-arm64"  (Join-Path $OutDir "macos\arm64")
        Fetch-Archive "libmpv-macos-x86_64" (Join-Path $OutDir "macos\x86_64")
    }
    "ios" {
        Fetch-Archive "libmpv-ios-arm64"           (Join-Path $OutDir "ios\arm64")
        Fetch-Archive "libmpv-iossimulator-arm64"  (Join-Path $OutDir "iossimulator\arm64")
        Fetch-Archive "libmpv-iossimulator-x86_64" (Join-Path $OutDir "iossimulator\x86_64")
    }
    "all" {
        & $MyInvocation.MyCommand.Path -Platform "windows" -Version $Version -Repo $Repo
        & $MyInvocation.MyCommand.Path -Platform "android" -Version $Version -Repo $Repo
        & $MyInvocation.MyCommand.Path -Platform "linux"   -Version $Version -Repo $Repo
        & $MyInvocation.MyCommand.Path -Platform "macos"   -Version $Version -Repo $Repo
        & $MyInvocation.MyCommand.Path -Platform "ios"     -Version $Version -Repo $Repo
        return
    }
}

Write-Host ""
Write-Ok "Done! Dependencies in: $OutDir"

# Print summary
Write-Host ""
Write-Host "  Installed:"
Get-ChildItem -Path $OutDir -Recurse -Filter ".version" -ErrorAction SilentlyContinue | ForEach-Object {
    $RelDir = $_.DirectoryName.Replace($OutDir, "").TrimStart("\", "/")
    $Ver = (Get-Content $_.FullName -Raw).Trim()
    Write-Host "    $RelDir -> v$Ver"
}
Write-Host ""