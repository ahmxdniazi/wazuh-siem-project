#!/usr/bin/env pwsh
# ================================================================
#  Atomic Red Team — MITRE ATT&CK Threat Simulation Script
#  Project: SIEM Deployment & Analysis
#  Author:  Muhammad Ahmad | 25I-7705
#
#  Run inside PowerShell (pwsh) on the monitored Linux endpoint
#  Prerequisites: Invoke-AtomicRedTeam installed
# ================================================================

# ────────────────────────────────────────────────────────────────
# COLORS
# ────────────────────────────────────────────────────────────────
function Write-Section($msg) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $msg" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}
function Write-Info($msg)    { Write-Host "  [✓] $msg" -ForegroundColor Green }
function Write-Running($msg) { Write-Host "  [►] $msg" -ForegroundColor Yellow }
function Write-Alert($msg)   { Write-Host "  [⚠] $msg" -ForegroundColor Red }

# ────────────────────────────────────────────────────────────────
# BANNER
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   ATOMIC RED TEAM — WAZUH SIEM VALIDATION   ║" -ForegroundColor Cyan
Write-Host "  ║   MITRE ATT&CK Technique Simulation Suite   ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Author : Muhammad Ahmad | 25I-7705" -ForegroundColor Gray
Write-Host "  Purpose: Validate Wazuh SIEM detection capabilities" -ForegroundColor Gray
Write-Host "  WARNING: Run ONLY in isolated lab environment" -ForegroundColor Red
Write-Host ""

# ────────────────────────────────────────────────────────────────
# CHECK PREREQUISITES
# ────────────────────────────────────────────────────────────────
Write-Section "Step 1 — Checking Prerequisites"

# Check if Invoke-AtomicRedTeam is available
if (-not (Get-Module -ListAvailable -Name Invoke-AtomicRedTeam)) {
    Write-Alert "Invoke-AtomicRedTeam not installed. Installing now..."

    Write-Running "Installing Invoke-AtomicRedTeam framework..."
    IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)

    Write-Running "Downloading Atomics folder..."
    Install-AtomicRedTeam -getAtomics -Force

    Write-Info "Invoke-AtomicRedTeam installed successfully"
} else {
    Write-Info "Invoke-AtomicRedTeam is already installed"
}

# Import the module
Import-Module Invoke-AtomicRedTeam -ErrorAction SilentlyContinue
Write-Info "Module imported"

$AtomicsPath = "$HOME/AtomicRedTeam/atomics"
Write-Info "Atomics folder: $AtomicsPath"
Write-Info "Prerequisites OK"

# ────────────────────────────────────────────────────────────────
# TECHNIQUE LIST TO TEST
# ────────────────────────────────────────────────────────────────
$techniques = @(
    @{
        ID          = "T1003.008"
        Name        = "OS Credential Dumping: /etc/passwd and /etc/shadow"
        Tactic      = "Credential Access"
        Platform    = "Linux"
        Description = "Simulates reading /etc/shadow to dump password hashes"
        Severity    = "CRITICAL"
    },
    @{
        ID          = "T1003.007"
        Name        = "OS Credential Dumping: Proc Filesystem"
        Tactic      = "Credential Access"
        Platform    = "Linux"
        Description = "Attempts to dump process memory via /proc filesystem"
        Severity    = "HIGH"
    },
    @{
        ID          = "T1003.006"
        Name        = "OS Credential Dumping: DCSync"
        Tactic      = "Credential Access"
        Platform    = "Linux"
        Description = "DCSync technique simulation (Linux compatible tests)"
        Severity    = "HIGH"
    }
)

# ────────────────────────────────────────────────────────────────
# RUN SIMULATIONS
# ────────────────────────────────────────────────────────────────
Write-Section "Step 2 — Running MITRE ATT&CK Simulations"

$results = @()

foreach ($technique in $techniques) {
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │ Technique : $($technique.ID)" -ForegroundColor White
    Write-Host "  │ Name      : $($technique.Name)" -ForegroundColor White
    Write-Host "  │ Tactic    : $($technique.Tactic)" -ForegroundColor Yellow
    Write-Host "  │ Severity  : $($technique.Severity)" -ForegroundColor Red
    Write-Host "  └─────────────────────────────────────────────┘" -ForegroundColor DarkCyan

    Write-Running "Executing: Invoke-AtomicTest $($technique.ID)"

    try {
        $output = Invoke-AtomicTest $technique.ID -PathToAtomicsFolder $AtomicsPath 2>&1
        Write-Info "Execution complete — Check Wazuh Dashboard for alerts"
        $results += [PSCustomObject]@{
            Technique  = $technique.ID
            Name       = $technique.Name
            Status     = "Executed"
            WazuhAlert = "Check Dashboard"
        }
    } catch {
        Write-Alert "Test failed or not applicable on this platform: $_"
        $results += [PSCustomObject]@{
            Technique  = $technique.ID
            Name       = $technique.Name
            Status     = "Not Applicable"
            WazuhAlert = "N/A"
        }
    }

    Write-Running "Waiting 5 seconds for Wazuh to process events..."
    Start-Sleep -Seconds 5
}

# ────────────────────────────────────────────────────────────────
# SUMMARY
# ────────────────────────────────────────────────────────────────
Write-Section "Step 3 — Simulation Summary"

Write-Host "  Technique Results:" -ForegroundColor White
Write-Host ""

foreach ($r in $results) {
    $color = if ($r.Status -eq "Executed") { "Green" } else { "Yellow" }
    Write-Host "  [$($r.Status.ToUpper())] $($r.Technique) — $($r.Name)" -ForegroundColor $color
}

Write-Host ""
Write-Host "  ═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Next Steps:" -ForegroundColor White
Write-Host "  1. Open Wazuh Dashboard: https://<MANAGER_IP>" -ForegroundColor Gray
Write-Host "  2. Navigate to: Security Events" -ForegroundColor Gray
Write-Host "  3. Navigate to: MITRE ATT&CK section" -ForegroundColor Gray
Write-Host "  4. Filter by agent name and last 24 hours" -ForegroundColor Gray
Write-Host "  5. Verify alert counts have increased" -ForegroundColor Gray
Write-Host "  ═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
