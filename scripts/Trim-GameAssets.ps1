# Requires -Version 5.1
<#
.SYNOPSIS
    Trim-GameAssets.ps1 - Game Assets & Shader Cache Optimization
.DESCRIPTION
    Scans and purges redundant Unreal Engine 4K optional paks (*optional*.pak),
    outdated DirectX shader caches, and local game PSOCache.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GameRootPath,

    [Parameter(Mandatory = $false)]
    [switch]$Execute
)

$ErrorActionPreference = "SilentlyContinue"
$isScanOnly = -not $Execute.IsPresent

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   WIN-PURIFY Game Asset & Shader Optimization    " -ForegroundColor Cyan
Write-Host "   Mode: $(if ($isScanOnly) { '[SCAN ONLY]' } else { '[PHYSICAL PURGE]' })" -ForegroundColor $(if ($isScanOnly) { 'Yellow' } else { 'Red' })
Write-Host "==================================================" -ForegroundColor Cyan

# 1. DirectX & GPU Shader Cache
Write-Host "`n[1] Scanning DirectX & GPU Shader Caches..." -ForegroundColor Yellow
$d3dCachePath = "$env:LOCALAPPDATA\D3DSCache"
$nvCachePath = "$env:LOCALAPPDATA\NVIDIA\DXCache"

$cachePaths = @($d3dCachePath, $nvCachePath)
foreach ($cp in $cachePaths) {
    if (Test-Path $cp) {
        $files = Get-ChildItem -Path $cp -File -Recurse -ErrorAction SilentlyContinue
        $measure = $files | Measure-Object -Property Length -Sum
        $sizeMB = [math]::Round($measure.Sum / 1MB, 2)
        Write-Host "  Found Shader Cache: $cp ($($files.Count) files, $sizeMB MB)"
        
        if (-not $isScanOnly -and $files.Count -gt 0) {
            Write-Host "    Clearing stale shader cache files..." -ForegroundColor Gray
            Remove-Item -Path "$cp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [DONE] Cache flushed. Games will rebuild fresh shaders on next run." -ForegroundColor Green
        }
    }
}

# 2. Unreal Engine Optional 4K Paks
Write-Host "`n[2] Scanning for Unreal Engine Optional 4K Texture Paks (*optional*.pak)..." -ForegroundColor Yellow

$pakDirs = @()
if ($GameRootPath -and (Test-Path $GameRootPath)) {
    $pakDirs += (Get-ChildItem -Path $GameRootPath -Directory -Recurse -Filter "Paks" -ErrorAction SilentlyContinue).FullName
} else {
    $commonDrives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
    foreach ($d in $commonDrives) {
        $candidate = "$d\Program Files\Delta Force\DeltaForce\Content\Paks"
        if (Test-Path $candidate) { $pakDirs += $candidate }
        $candidate2 = "$d\Delta Force\DeltaForce\Content\Paks"
        if (Test-Path $candidate2) { $pakDirs += $candidate2 }
    }
}

$foundPaks = @()
foreach ($pDir in $pakDirs) {
    $paks = Get-ChildItem -Path $pDir -File -Filter "*optional*" -ErrorAction SilentlyContinue
    $foundPaks += $paks
}

if ($foundPaks.Count -gt 0) {
    Write-Host "  Found $($foundPaks.Count) optional 4K texture packages:" -ForegroundColor Magenta
    $pakTotalBytes = 0
    foreach ($p in $foundPaks) {
        $sizeGB = [math]::Round($p.Length / 1GB, 2)
        $pakTotalBytes += $p.Length
        Write-Host ("    [{0,6} GB] {1}" -f $sizeGB, $p.FullName)
    }
    $totalGB = [math]::Round($pakTotalBytes / 1GB, 2)
    Write-Host "  Potential space reclaim: $totalGB GB!" -ForegroundColor Magenta
    
    if (-not $isScanOnly) {
        Write-Host "  Stripping optional texture packages..." -ForegroundColor Red
        foreach ($p in $foundPaks) {
            Remove-Item -Path $p.FullName -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  [DONE] Optional texture paks stripped! Does not affect gameplay, FPS, or matchmaking." -ForegroundColor Green
    } else {
        Write-Host "  [SCAN ONLY] Pass -Execute switch to remove these packages." -ForegroundColor Cyan
    }
} else {
    Write-Host "  Clean. No optional 4K paks detected." -ForegroundColor Green
}

# 3. Local Game PSOCache
if ($pakDirs.Count -gt 0) {
    Write-Host "`n[3] Checking local game PSOCache..." -ForegroundColor Yellow
    foreach ($pDir in $pakDirs) {
        $savedDir = Join-Path (Split-Path $pDir -Parent) "Saved"
        $psoDir = Join-Path $savedDir "PSOCache"
        if (Test-Path $psoDir) {
            $psoFiles = Get-ChildItem -Path $psoDir -File -Recurse -ErrorAction SilentlyContinue
            $psoSizeMB = [math]::Round(($psoFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
            Write-Host "  Found local PSOCache: $psoDir ($psoSizeMB MB)"
            if (-not $isScanOnly) {
                Remove-Item -Path "$psoDir\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  [DONE] PSOCache cleared." -ForegroundColor Green
            }
        }
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Game asset scan complete." -ForegroundColor Cyan
