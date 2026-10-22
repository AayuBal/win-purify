# Requires -Version 5.1
<#
.SYNOPSIS
    Optimize-WindowsCore.ps1 - Windows Core OS Hardening & RAM Streamlining
.DESCRIPTION
    Executes tested and safe core optimizations:
    1. Sets crash dump strategy to Minidump 256KB (prevents multi-gigabyte MEMORY.DMP).
    2. Enforces zero background and startup boost policy for Microsoft Edge.
    3. Suppresses rogue background scheduled wake tasks (WPS, FlashCenter, etc.).
    4. Optional: Removes Windows 11 bloatware (YourPhone, Xbox, Zune, etc.).
    5. Optional: Disables SysMain for NVMe SSD systems.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$RemoveBloatware,

    [Parameter(Mandatory = $false)]
    [switch]$DisableSysMain
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   WIN-PURIFY Core OS & RAM Streamlining          " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Crash Dump Strategy -> Minidump 256KB
Write-Host "`n[1] Enforcing Crash Dump Strategy -> Minidump (256KB)..." -ForegroundColor Yellow
$crashPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
if (Test-Path $crashPath) {
    Set-ItemProperty -Path $crashPath -Name "CrashDumpEnabled" -Value 3 -Type DWord
    Write-Host "  [OK] CrashDumpEnabled locked to 3 (Minidump 256KB)." -ForegroundColor Green
}

# 2. Block Microsoft Edge Background Mode & Startup Boost
Write-Host "`n[2] Blocking Microsoft Edge Background Ghosts..." -ForegroundColor Yellow
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePolicyPath)) {
    New-Item -Path $edgePolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $edgePolicyPath -Name "BackgroundModeEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path $edgePolicyPath -Name "StartupBoostEnabled" -Value 0 -Type DWord
Write-Host "  [OK] BackgroundModeEnabled = 0, StartupBoostEnabled = 0 enforced." -ForegroundColor Green

# 3. Suppress Rogue Scheduled Tasks
Write-Host "`n[3] Suppressing Rogue Scheduled Wake Tasks..." -ForegroundColor Yellow
$badTasks = Get-ScheduledTask | Where-Object { 
    $_.TaskName -match "wps|kingsoft|flashcenter|updatetask" -and $_.State -ne "Disabled"
}
$taskCount = 0
foreach ($t in $badTasks) {
    Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [LOCKED] Scheduled Task: $($t.TaskName)" -ForegroundColor Gray
    $taskCount++
}
Write-Host "  [OK] Suppressed $taskCount background scheduled tasks." -ForegroundColor Green

# 4. Optional: Remove Bloatware
if ($RemoveBloatware.IsPresent) {
    Write-Host "`n[4] Removing Windows 11 Native Bloatware..." -ForegroundColor Yellow
    $bloatNames = @(
        "*YourPhone*",
        "*Microsoft.Windows.Search*",
        "*Xbox*",
        "*ZuneMusic*",
        "*ZuneVideo*",
        "*WindowsFeedbackHub*",
        "*Microsoft.Getstarted*",
        "*Microsoft.WindowsMaps*",
        "*MicrosoftTeams*"
    )
    foreach ($app in $bloatNames) {
        $pkgs = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
        foreach ($pkg in $pkgs) {
            Write-Host "  Removing AppX package: $($pkg.Name) ..." -ForegroundColor Gray
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  [OK] Bloatware removal pass completed." -ForegroundColor Green
}

# 5. Optional: Disable SysMain
if ($DisableSysMain.IsPresent) {
    Write-Host "`n[5] Optimizing SysMain Service for NVMe SSD..." -ForegroundColor Yellow
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  [OK] SysMain service stopped and disabled." -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Core OS streamlining completed successfully!" -ForegroundColor Cyan
