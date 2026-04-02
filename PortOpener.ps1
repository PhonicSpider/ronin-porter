# =========================================
# Author: PhonicSpider
# Created: 2024-06-01
# Description:
# An easy port opener/closer for admins of game servers or any application that requires specific ports to be open.
# =========================================


# PortOpener.ps1 - A simple PowerShell script to manage Windows Firewall rules for specific ports.
# This script can be used to open or close ports for applications like game servers, remote desktop, etc.
# Usage:
#   1. To update (refresh) rules: .\PortOpener.ps1
#   2. To remove rules only: .\PortOpener.ps1 -Mode RemoveOnly
# Note: Run this script with administrative privileges to modify firewall rules.





# ==========================================
# CONFIGURATION SECTION
# ==========================================
$Mode           = "Update"               # "Update" or "RemoveOnly"
$DebugMode      = $true                  # Set to $true to see detailed errors/verbose logs
$RuleName       = "Space Engineers Test" # Base name for firewall rules, will be suffixed with protocol (TCP/UDP)
$Ports          = "27016, 29016"         # Comma-separated list of ports to open/close, will be done on both TCP and UDP
$Protocols      = @("TCP", "UDP")        # Protocols to apply rules to, can be "TCP", "UDP", or both
$Action         = "Allow"                # "Allow" to open ports, "Block" to close ports if not using the "Mode" parameter"
$Profile        = "Any"                  # "Domain", "Private", "Public", or "Any" - which network profiles the rule applies to
# ==========================================

# --- Logging Helper Function ---

# A helper function to write colored log messages with timestamps and levels (Info, Warning, Error, Debug).
function Write-Log {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Debug")][string]$Level = "Info"
    )

    $Color = switch ($Level) {
        "Info"    { "Cyan" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "Gray" }
        Default   { "White" }
    }

    if ($Level -eq "Debug" -and -not $DebugMode) { return }

    $Timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Timestamp] [$($Level.ToUpper())] $Message" -ForegroundColor $Color
}

# --- 1. Admin Elevation Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Requesting Administrative privileges..." -Level "Warning"
    try {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        exit
    } catch {
        Write-Log "Failed to elevate to Admin. Firewall rules cannot be modified." -Level "Error"
        if ($DebugMode) { Write-Log $_.Exception.Message -Level "Debug" }
        pause; exit
    }
}

# --- 2. Cleanup Logic ---
Write-Log "Starting cleanup for '$RuleName'..."
try {
    $ExistingRules = Get-NetFirewallRule -DisplayName "$RuleName*" -ErrorAction Stop
    if ($ExistingRules) {
        $ExistingRules | Remove-NetFirewallRule -ErrorAction Stop
        Write-Log "Successfully removed existing rules." -Level "Warning"
    } else {
        Write-Log "No matching rules found to remove." -Level "Debug"
    }
} catch {
    Write-Log "An error occurred during cleanup check." -Level "Debug"
    Write-Log $_.Exception.Message -Level "Debug"
}

if ($Mode -eq "RemoveOnly") {
    Write-Log "Operation 'RemoveOnly' complete. Exiting." -Level "Info"
    return
}

# --- 3. Rule Creation ---
foreach ($Proto in $Protocols) {
    $FullDisplayName = "$RuleName ($Proto)"
    Write-Log "Attempting to create: $FullDisplayName..." -Level "Debug"
    
    try {
        $Params = @{
            DisplayName  = $FullDisplayName
            Direction    = "Inbound"
            Action       = $Action
            Protocol     = $Proto
            LocalPort    = $Ports
            Profile      = $Profile
            Enabled      = "True"
            ErrorAction  = "Stop" # Forces the 'try/catch' to trigger on failure
        }

        New-NetFirewallRule @Params | Out-Null
        Write-Log "Created: $FullDisplayName" -Level "Info"
    } catch {
        Write-Log "Failed to create rule: $FullDisplayName" -Level "Error"
        Write-Log "Technical Details: $($_.Exception.Message)" -Level "Debug"
    }
}

Write-Log "Firewall update complete." -Level "Info"