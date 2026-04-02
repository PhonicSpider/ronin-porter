# =========================================
# Author: PhonicSpider
# Created: 2024-06-01
# Description:
# An easy port opener/closer for admins of game servers or any application that requires specific ports to be open.
# =========================================

<#
    Copyright (C) 2026 PhonicSpider

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU Affero General Public License for more details.
#>

# PortOpener.ps1 - A simple PowerShell script to manage Windows Firewall rules for specific ports.
# This script can be used to open or close ports for applications like game servers, remote desktop, etc.
# Usage:
#   1. To update (refresh) rules: .\PortOpener.ps1
#   2. To remove rules only: .\PortOpener.ps1 -Mode RemoveOnly
# Note: Run this script with administrative privileges to modify firewall rules.





# ==========================================
# CONFIGURATION SECTION
# ==========================================
$Mode           = "Update"               # Options: "Update" or "RemoveOnly"
$DebugMode      = $true                  # Set to $true for detailed error logs
$RuleName       = "Space Engineers Test" 
$Ports          = "27016, 29016"         # Can be "80", "80, 443", or "27000-27050"
$Protocols      = @("TCP", "UDP")        
$Action         = "Allow"                
$Profile        = "Any"                  
# ==========================================

# --- Logging & UI Helper ---
function Write-Log {
    param ([string]$Message, [ValidateSet("Info", "Warning", "Error", "Debug")]$Level = "Info")
    $Color = switch ($Level) { "Info" {"Cyan"}; "Warning" {"Yellow"}; "Error" {"Red"}; "Debug" {"Gray"}; Default {"White"} }
    if ($Level -eq "Debug" -and -not $DebugMode) { return }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$($Level.ToUpper())] $Message" -ForegroundColor $Color
}

# --- 1. Admin Elevation ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Elevating to Administrator..." -Level "Warning"
    try { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop; exit } 
    catch { Write-Log "Elevation failed. Right-click and 'Run as Administrator'." -Level "Error"; pause; exit }
}

# --- 2. Input Validation (Pre-Flight) ---
Write-Log "Validating configuration..." -Level "Debug"
$CleanPorts = $Ports -replace '\s+', '' # Remove all whitespace for the API
if ($CleanPorts -match '[^0-9,-]') {
    Write-Log "Invalid characters found in Ports: '$Ports'. Only numbers, commas, and hyphens allowed." -Level "Error"
    pause; exit
}

# --- 3. Cleanup ---
Write-Log "Starting cleanup for '$RuleName'..."
try {
    $Existing = Get-NetFirewallRule -DisplayName "$RuleName*" -ErrorAction SilentlyContinue
    if ($Existing) {
        $Existing | Remove-NetFirewallRule -ErrorAction Stop
        Write-Log "Cleaned $(@($Existing).Count) existing rules." -Level "Warning"
    }
} catch {
    Write-Log "Cleanup failed: $($_.Exception.Message)" -Level "Error"
}

if ($Mode -eq "RemoveOnly") { 
    Write-Log "Mode set to RemoveOnly. Ports are now closed." -Level "Info"
    pause; return 
}

# --- 4. Rule Creation ---
$SuccessCount = 0
foreach ($Proto in $Protocols) {
    try {
        $Name = "$RuleName ($Proto)"
        New-NetFirewallRule -DisplayName $Name -Direction Inbound -Action $Action -Protocol $Proto -LocalPort $CleanPorts -Profile $Profile -Enabled True -ErrorAction Stop | Out-Null
        Write-Log "Created: $Name" -Level "Info"
        $SuccessCount++
    } catch {
        Write-Log "Failed to create $Proto rule: $($_.Exception.Message)" -Level "Error"
    }
}

# --- 5. Final Summary ---
Write-Host "`n-------------------------------------------" -ForegroundColor Gray
if ($SuccessCount -eq $Protocols.Count) {
    Write-Host " STATUS: SUCCESS" -ForegroundColor Green
    Write-Host " All ports ($Ports) are now OPEN." -ForegroundColor White
} else {
    Write-Host " STATUS: COMPLETED WITH ERRORS" -ForegroundColor Yellow
    Write-Host " Check debug logs above for details." -ForegroundColor White
}
Write-Host "-------------------------------------------`n" -ForegroundColor Gray

# Only pause if we are in DebugMode or if there's a potential we were run by double-clicking
if ($DebugMode) { Write-Log "Press any key to close this window..." -Level "Debug"; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
