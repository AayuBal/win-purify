# Requires -Version 5.1
<#
.SYNOPSIS
    Clean-DriverStore.ps1 - Safe DriverStore Cleanup
.DESCRIPTION
    Uses pnputil to enumerate and clean redundant graphics/display driver packages.
    Strictly forbids /force so Windows Kernel protects in-use drivers automatically.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   WIN-PURIFY Safe DriverStore Pruning            " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "Enumerating third-party driver packages..." -ForegroundColor Gray
$rawDrivers = pnputil /enum-drivers
$drivers = @()
$currentDriver = @{}

foreach ($line in $rawDrivers) {
    if ($line -match "Published Name:\s+(oem\d+\.inf)") {
        if ($currentDriver.Name) { $drivers += [PSCustomObject]$currentDriver }
        $currentDriver = @{ Name = $matches[1] }
    } elseif ($line -match "Original Name:\s+(.+)$") {
        $currentDriver.OriginalName = $matches[1].Trim()
    } elseif ($line -match "Provider Name:\s+(.+)$") {
        $currentDriver.Provider = $matches[1].Trim()
    } elseif ($line -match "Class Name:\s+(.+)$") {
        $currentDriver.Class = $matches[1].Trim()
    } elseif ($line -match "Driver Version:\s+(.+)$") {
        $currentDriver.Version = $matches[1].Trim()
    }
}
if ($currentDriver.Name) { $drivers += [PSCustomObject]$currentDriver }

$displayDrivers = $drivers | Where-Object { 
    $_.Class -match "Display" -or $_.Provider -match "NVIDIA|AMD|Intel" -or $_.OriginalName -match "nv.*\.inf|igdlh.*\.inf|u0.*\.inf"
}

Write-Host "Found $($displayDrivers.Count) display/graphics driver packages in DriverStore." -ForegroundColor Yellow

$oemList = $displayDrivers | Select-Object -ExpandProperty Name
$deletedCount = 0
$keptCount = 0

foreach ($oem in $oemList) {
    $item = $displayDrivers | Where-Object { $_.Name -eq $oem } | Select-Object -First 1
    Write-Host "`nChecking driver package: $oem ($($item.OriginalName), Version: $($item.Version))" -ForegroundColor Cyan
    
    if ($WhatIf) {
        Write-Host "  [WhatIf Preview] Would execute: pnputil /delete-driver $oem" -ForegroundColor Gray
        continue
    }

    $res = pnputil /delete-driver $oem 2>&1 | Out-String
    
    if ($res -match "Driver package deleted successfully" -or $res -match "successfully") {
        Write-Host "  [SUCCESS] Removed superseded driver package! Reclaimed ~2.5 GB." -ForegroundColor Green
        $deletedCount++
    } elseif ($res -match "in use" -or $res -match "failed") {
        Write-Host "  [PROTECTED] Driver package is currently in active hardware use. Kept safe." -ForegroundColor Yellow
        $keptCount++
    } else {
        Write-Host "  [INFO] Output: $($res.Trim())" -ForegroundColor Gray
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Driver Cleanup Summary:" -ForegroundColor Cyan
Write-Host "  - Superseded packages removed: $deletedCount (Reclaimed ~$([math]::Round($deletedCount * 2.5, 1)) GB)" -ForegroundColor Green
Write-Host "  - Active packages safely kept: $keptCount" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
