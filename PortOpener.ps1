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
# Options: "Update" (Refresh rules) or "RemoveOnly" (Delete and stop)
$Mode           = "Update"               

$RuleName       = "Valheim Server"       # The base name for the rules
$Ports          = "2456, 2457, 2458"     # Single, list, or range
$Protocols      = @("TCP", "UDP")        # Protocols to apply
$Action         = "Allow"                # "Allow" or "Block"
$Profile        = "Any"                  # "Any", "Domain", "Private", or "Public"
# ==========================================

# --- Early Check: Removal Logic ---
Write-Host "Checking for existing rules for '$RuleName'..." -ForegroundColor Cyan

$ExistingRules = Get-NetFirewallRule -DisplayName "$RuleName*" -ErrorAction SilentlyContinue

if ($ExistingRules) {
    $ExistingRules | Remove-NetFirewallRule
    Write-Host "Old rules removed successfully." -ForegroundColor Yellow
} else {
    Write-Host "No existing rules found to remove." -ForegroundColor Gray
}

# --- The "Return" Logic ---
if ($Mode -eq "RemoveOnly") {
    Write-Host "Mode set to RemoveOnly. Script exiting now." -ForegroundColor White -BackgroundColor DarkBlue
    return # This stops the script here
}

# --- Rule Creation Logic ---
foreach ($Proto in $Protocols) {
    $FullDisplayName = "$RuleName ($Proto)"
    
    New-NetFirewallRule -DisplayName $FullDisplayName `
                        -Direction Inbound `
                        -Action $Action `
                        -Protocol $Proto `
                        -LocalPort $Ports `
                        -Profile $Profile `
                        -Enabled True
    Write-Host "Created: $FullDisplayName" -ForegroundColor Green
}