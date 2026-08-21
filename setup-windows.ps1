#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up Love2D and LuaRocks for game development on Windows

.DESCRIPTION
    This script checks for and installs Love2D and LuaRocks,
    then prints version information and run instructions.

.NOTES
    Requires Administrator privileges for Chocolatey/Scoop installations.
    Run with: pwsh -ExecutionPolicy Bypass -File setup-windows.ps1
#>

# Strict mode equivalent to 'set -euo pipefail'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Color output helpers
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERR]  $Message" -ForegroundColor Red }

# Check if running as Administrator
function Test-IsAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if a command exists in PATH
function Test-Command {
    param([string]$Name)
    return (Get-Command $Name -ErrorAction SilentlyContinue) -ne $null
}

# Get version of a command
function Get-CommandVersion {
    param([string]$Command, [string]$VersionArg = '--version')
    try {
        & $Command $VersionArg 2>&1 | Select-Object -First 1
    } catch {
        return "unknown"
    }
}

# Install Love2D
function Install-Love2D {
    Write-Info "Checking for Love2D..."

    if (Test-Command 'love') {
        $version = Get-CommandVersion 'love'
        Write-Success "Love2D already installed: $version"
        return
    }

    Write-Warning "Love2D not found. Attempting installation..."

    # Try Chocolatey first
    if (Test-Command 'choco') {
        Write-Info "Installing Love2D via Chocolatey..."
        try {
            choco install love -y --no-progress
            Write-Success "Love2D installed via Chocolatey"
            return
        } catch {
            Write-Warning "Chocolatey install failed: $_"
        }
    }

    # Try Scoop
    if (Test-Command 'scoop') {
        Write-Info "Installing Love2D via Scoop..."
        try {
            scoop install love
            Write-Success "Love2D installed via Scoop"
            return
        } catch {
            Write-Warning "Scoop install failed: $_"
        }
    }

    # Fallback: Download installer
    Write-Info "Downloading Love2D installer..."
    $url = 'https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.exe'
    $installer = "$env:TEMP\love-installer.exe"

    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Write-Info "Running Love2D installer (requires admin)..."
        Start-Process -FilePath $installer -ArgumentList '/S' -Wait -Verb RunAs
        Write-Success "Love2D installed via direct download"
    } catch {
        Write-ErrorMsg "Failed to install Love2D: $_"
        throw "Love2D installation failed"
    } finally {
        if (Test-Path $installer) { Remove-Item $installer -Force -ErrorAction SilentlyContinue }
    }
}

# Install LuaRocks
function Install-LuaRocks {
    Write-Info "Checking for LuaRocks..."

    if (Test-Command 'luarocks') {
        $version = Get-CommandVersion 'luarocks'
        Write-Success "LuaRocks already installed: $version"
        return
    }

    Write-Warning "LuaRocks not found. Attempting installation..."

    # Try Chocolatey
    if (Test-Command 'choco') {
        Write-Info "Installing LuaRocks via Chocolatey..."
        try {
            choco install luarocks -y --no-progress
            Write-Success "LuaRocks installed via Chocolatey"
            return
        } catch {
            Write-Warning "Chocolatey install failed: $_"
        }
    }

    # Try Scoop
    if (Test-Command 'scoop') {
        Write-Info "Installing LuaRocks via Scoop..."
        try {
            scoop install luarocks
            Write-Success "LuaRocks installed via Scoop"
            return
        } catch {
            Write-Warning "Scoop install failed: $_"
        }
    }

    # Fallback: Manual install (requires Lua first)
    Write-ErrorMsg "Automatic LuaRocks install requires Chocolatey or Scoop."
    Write-Info "Please install LuaRocks manually:"
    Write-Info "  1. Install Lua from https://www.lua.org/download.html"
    Write-Info "  2. Download LuaRocks from https://luarocks.org/releases"
    Write-Info "  3. Follow Windows build instructions"
    throw "LuaRocks installation failed - manual intervention required"
}

# Main execution
try {
    Write-Host "`n=== Game Development Setup for Windows ===`n" -ForegroundColor Magenta

    # Check admin for package managers
    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Write-Warning "Not running as Administrator. Chocolatey/Scoop installs may fail."
        Write-Info "Re-run as Administrator for best results.`n"
    }

    # Install dependencies
    Install-Love2D
    Install-LuaRocks

    # Verify installations
    Write-Host "`n=== Verification ===`n" -ForegroundColor Magenta

    $loveVersion = Get-CommandVersion 'love'
    $luarocksVersion = Get-CommandVersion 'luarocks'

    Write-Success "Love2D:  $loveVersion"
    Write-Success "LuaRocks: $luarocksVersion"

    # Print run instructions
    Write-Host "`n=== How to Run the Game ===`n" -ForegroundColor Magenta
    Write-Host "From the project root directory:" -ForegroundColor White
    Write-Host "  love ." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or with a specific main file:" -ForegroundColor White
    Write-Host "  love src/main.lua" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "For development with live reload:" -ForegroundColor White
    Write-Host "  luarocks install lovers" -ForegroundColor Yellow
    Write-Host "  lovers ." -ForegroundColor Yellow

    Write-Host "`n=== Setup Complete ===`n" -ForegroundColor Green

} catch {
    Write-ErrorMsg "`nSetup failed: $_"
    exit 1
}