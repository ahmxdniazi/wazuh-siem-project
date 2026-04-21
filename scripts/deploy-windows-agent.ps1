# ================================================================
#  Wazuh Windows Agent Deployment Script
#  Project: SIEM Deployment & Analysis
#  Author:  Muhammad Ahmad | 25I-7705
#
#  Usage (Run as Administrator):
#    .\deploy-windows-agent.ps1 -ManagerIP "192.168.134.129" -AgentName "windows-endpoint"
# ================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ManagerIP = "192.168.134.129",

    [Parameter(Mandatory=$false)]
    [string]$AgentName = "windows-endpoint",

    [Parameter(Mandatory=$false)]
    [string]$WazuhVersion = "4.14.4-1"
)

# ────────────────────────────────────────────────────────────────
# COLORS & HELPERS
# ────────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ██╗    ██╗ █████╗ ███████╗██╗   ██╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ██║    ██║██╔══██╗╚══███╔╝██║   ██║██║  ██║" -ForegroundColor Cyan
    Write-Host "  ██║ █╗ ██║███████║  ███╔╝ ██║   ██║███████║" -ForegroundColor Cyan
    Write-Host "  ██║███╗██║██╔══██║ ███╔╝  ██║   ██║██╔══██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔███╔╝██║  ██║███████╗╚██████╔╝██║  ██║" -ForegroundColor Cyan
    Write-Host "   ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Windows Agent Deployment Script" -ForegroundColor White
    Write-Host "  Manager: $ManagerIP  |  Agent: $AgentName" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Section($msg) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host " $msg" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info($msg)  { Write-Host "[+] $msg" -ForegroundColor Green  }
function Write-Warn($msg)  { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[-] $msg" -ForegroundColor Red    }

# ────────────────────────────────────────────────────────────────
# CHECK ADMIN PRIVILEGES
# ────────────────────────────────────────────────────────────────
function Check-Admin {
    Write-Section "Checking Administrator Privileges"
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Err "This script must be run as Administrator!"
        Write-Err "Right-click PowerShell -> 'Run as Administrator'"
        exit 1
    }
    Write-Info "Running with Administrator privileges"
}

# ────────────────────────────────────────────────────────────────
# STOP EXISTING AGENT
# ────────────────────────────────────────────────────────────────
function Stop-ExistingAgent {
    Write-Section "Stopping Existing Wazuh Agent (if running)"
    $svc = Get-Service -Name "Wazuh" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        Write-Warn "Stopping existing Wazuh service..."
        NET STOP Wazuh 2>$null
        Write-Info "Wazuh service stopped"
    } else {
        Write-Info "No running Wazuh service found"
    }
}

# ────────────────────────────────────────────────────────────────
# DOWNLOAD & INSTALL AGENT
# ────────────────────────────────────────────────────────────────
function Install-WazuhAgent {
    Write-Section "Downloading & Installing Wazuh Agent v$WazuhVersion"

    $msiUrl  = "https://packages.wazuh.com/4.x/windows/wazuh-agent-$WazuhVersion.msi"
    $msiPath = "$env:TEMP\wazuh-agent.msi"

    Write-Info "Downloading from: $msiUrl"
    try {
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
        Write-Info "Download complete: $msiPath"
    } catch {
        Write-Err "Download failed: $_"
        exit 1
    }

    Write-Info "Installing MSI (silent mode)..."
    $installArgs = @(
        "/i", $msiPath,
        "/q",
        "WAZUH_MANAGER=$ManagerIP",
        "WAZUH_AGENT_NAME=$AgentName",
        "WAZUH_PROTOCOL=tcp"
    )

    $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Info "Agent installed successfully (Exit code: 0)"
    } else {
        Write-Err "Installation failed with exit code: $($proc.ExitCode)"
        exit 1
    }
}

# ────────────────────────────────────────────────────────────────
# START AGENT SERVICE
# ────────────────────────────────────────────────────────────────
function Start-WazuhAgent {
    Write-Section "Starting Wazuh Agent Service"

    Write-Info "Waiting for service registration..."
    Start-Sleep -Seconds 5

    NET START Wazuh
    Start-Sleep -Seconds 3

    $svc = Get-Service -Name "Wazuh" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        Write-Info "Wazuh Agent is RUNNING"
    } else {
        Write-Err "Wazuh Agent failed to start!"
        Write-Err "Check Event Viewer > Windows Logs > Application for errors"
        exit 1
    }
}

# ────────────────────────────────────────────────────────────────
# VERIFY & CLEANUP
# ────────────────────────────────────────────────────────────────
function Verify-Installation {
    Write-Section "Verification"

    $svc = Get-Service -Name "Wazuh"
    Write-Info "Service Status: $($svc.Status)"
    Write-Info "Agent Name: $AgentName"
    Write-Info "Manager IP: $ManagerIP"

    $ossecLog = "C:\Program Files (x86)\ossec-agent\ossec.log"
    if (Test-Path $ossecLog) {
        Write-Info "Agent log: $ossecLog"
        Write-Info "Last 5 log entries:"
        Get-Content $ossecLog -Tail 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
}

function Cleanup {
    Write-Info "Cleaning up installer..."
    Remove-Item -Path "$env:TEMP\wazuh-agent.msi" -Force -ErrorAction SilentlyContinue
}

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────
Write-Banner
Check-Admin
Stop-ExistingAgent
Install-WazuhAgent
Start-WazuhAgent
Verify-Installation
Cleanup

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " ✅ Wazuh Windows Agent Deployment Complete!" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  Manager:    https://$ManagerIP" -ForegroundColor Cyan
Write-Host "  Agent Name: $AgentName" -ForegroundColor Yellow
Write-Host "  Verify:     Wazuh Dashboard → Endpoints section" -ForegroundColor Yellow
Write-Host ""
