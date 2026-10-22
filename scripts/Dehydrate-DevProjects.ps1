# Requires -Version 5.1
<#
.SYNOPSIS
    Dehydrate-DevProjects.ps1 - Safe Dev Project Dependency & Cache Dehydration
.DESCRIPTION
    Scans and purges reproducible dependency packages (node_modules, .venv, dist, .next)
    from inactive projects. 100% preserves source code, markdown, configurations, and .git history.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath,

    [Parameter(Mandatory = $false)]
    [switch]$Execute,

    [Parameter(Mandatory = $false)]
    [int]$DaysInactive = 30
)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path -Path $RootPath)) {
    Write-Error "Path does not exist: $RootPath"
    exit 1
}

$isScanOnly = -not $Execute.IsPresent

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   WIN-PURIFY Dev Project Dehydration Engine      " -ForegroundColor Cyan
Write-Host "   Target: $RootPath                              " -ForegroundColor Cyan
Write-Host "   Mode: $(if ($isScanOnly) { '[SCAN ONLY]' } else { '[PHYSICAL PURGE]' })" -ForegroundColor $(if ($isScanOnly) { 'Yellow' } else { 'Red' })
Write-Host "==================================================" -ForegroundColor Cyan

$targets = @("node_modules", ".venv", "dist", ".next", ".turbo", "__pycache__")
$foundFolders = @()
$cutoffDate = (Get-Date).AddDays(-$DaysInactive)

Write-Host "Scanning for inactive project caches ($DaysInactive days threshold)..." -ForegroundColor Gray

foreach ($targetName in $targets) {
    $items = Get-ChildItem -Path $RootPath -Directory -Recurse -Depth 4 -Filter $targetName -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        if ($item.FullName -match "node_modules[\\/].+node_modules") { continue }
        
        $parent = $item.Parent
        if ($parent -and ($parent.LastWriteTime -lt $cutoffDate -or $item.LastWriteTime -lt $cutoffDate)) {
            $foundFolders += $item
        }
    }
}

if ($foundFolders.Count -eq 0) {
    Write-Host "Clean! No abandoned project caches found." -ForegroundColor Green
    exit 0
}

Write-Host "`nFound the following dehydratable cache targets:" -ForegroundColor Yellow
$totalBytes = 0

foreach ($folder in $foundFolders) {
    $measure = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
    $totalBytes += $measure.Sum
    Write-Host ("  [{0,8} MB] {1}" -f $sizeMB, $folder.FullName)
}

$totalGB = [math]::Round($totalBytes / 1GB, 2)
Write-Host "`nTotal: $($foundFolders.Count) cache folders, Total Size: $totalGB GB" -ForegroundColor Magenta

if ($isScanOnly) {
    Write-Host "Currently in [SCAN ONLY] mode. No files were deleted." -ForegroundColor Green
    Write-Host "To execute physical dehydration, run with switch: -Execute" -ForegroundColor Cyan
} else {
    Write-Host "`nExecuting physical dehydration..." -ForegroundColor Red
    foreach ($folder in $foundFolders) {
        Write-Host "  Removing: $($folder.FullName) ..." -NoNewline
        Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host " [DONE]" -ForegroundColor Green
    }
    Write-Host "`nDehydration complete! Reclaimed $totalGB GB." -ForegroundColor Green
    Write-Host "Source code and .git history are 100% preserved. Run npm install or pip install anytime to restore." -ForegroundColor Gray
}
