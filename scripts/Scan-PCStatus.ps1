# Requires -Version 5.1
<#
.SYNOPSIS
    Scan-PCStatus.ps1 - Windows System Health & Resource Diagnostics
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       WIN-PURIFY System Health Diagnostic        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Drive C
$cDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$cTotal = [math]::Round($cDrive.Size / 1GB, 2)
$cFree = [math]::Round($cDrive.FreeSpace / 1GB, 2)
$cUsed = [math]::Round(($cDrive.Size - $cDrive.FreeSpace) / 1GB, 2)
$cFreePercent = [math]::Round(($cFree / $cTotal) * 100, 1)

Write-Host "[1] Drive C: Status" -ForegroundColor Yellow
Write-Host "    Total: $cTotal GB | Used: $cUsed GB | Free: $cFree GB ($($cFreePercent)% free)"

# 2. RAM & Pagefile
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRam = [math]::Round($totalRam - $freeRam, 2)
$ramPercent = [math]::Round(($usedRam / $totalRam) * 100, 1)

$pagefiles = Get-CimInstance -ClassName Win32_PageFileUsage
$totalPagefileMB = 0
foreach ($pf in $pagefiles) {
    $totalPagefileMB += $pf.AllocatedBaseSize
}
$pagefileGB = [math]::Round($totalPagefileMB / 1024, 2)

Write-Host "`n[2] Memory & Pagefile Status" -ForegroundColor Yellow
Write-Host "    RAM Total: $totalRam GB | Used: $usedRam GB ($($ramPercent)%) | Free: $freeRam GB"
Write-Host "    Pagefile (Virtual Memory): $pagefileGB GB"

# 3. DriverStore Redundancy
Write-Host "`n[3] DriverStore Graphic Drivers Check" -ForegroundColor Yellow
$nvDrivers = pnputil /enum-drivers | Select-String -Pattern "nv_dispi.inf|nvaci.inf|nvhda.inf" -Context 2, 2
$driverCount = ($nvDrivers | Select-String -Pattern "Published Name:").Count
if ($driverCount -gt 1) {
    Write-Host "    Detected $driverCount display driver packages in DriverStore. Run Clean-DriverStore to prune." -ForegroundColor Magenta
} else {
    Write-Host "    DriverStore graphics repository is clean." -ForegroundColor Green
}

# 4. Startup apps
Write-Host "`n[4] Startup Apps Check" -ForegroundColor Yellow
$runEntries = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
$startCount = 0
foreach ($prop in $runEntries.PSObject.Properties) {
    if ($prop.Name -notmatch "^PS|^_") {
        $startCount++
    }
}
Write-Host "    Registry Startup Entries: $startCount items"

# 5. Crash dump strategy
$dumpKey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -ErrorAction SilentlyContinue
$dumpMode = $dumpKey.CrashDumpEnabled
$dumpText = switch ($dumpMode) {
    0 { "Disabled" }
    1 { "Complete memory dump (Large GBs)" }
    2 { "Kernel memory dump" }
    3 { "Minidump 256KB (Optimized)" }
    7 { "Automatic memory dump" }
    default { "Mode: $dumpMode" }
}
Write-Host "`n[5] Crash Dump Strategy: $dumpText" -ForegroundColor Yellow

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Diagnostics complete." -ForegroundColor Cyan
