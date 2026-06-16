[CmdletBinding()]
param(
    [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RoleSlug,
    [int]$KeepEntries = 12,
    [int]$MaxSummaryBullets = 24,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$Utf8Bom = [System.Text.UTF8Encoding]::new($true)
$MemoryStart = "<!-- memory_entries:start -->"
$MemoryEnd = "<!-- memory_entries:end -->"
$SummaryStart = "<!-- compacted_memory:start -->"
$SummaryEnd = "<!-- compacted_memory:end -->"

function Read-TextFile {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8Bom)
}

function Get-PersonaDirs {
    param(
        [string]$Root,
        [string]$Slug
    )

    if (-not (Test-Path -Path $Root)) {
        throw "Persona root not found: $Root"
    }

    if ($Slug) {
        $found = @()
        foreach ($division in Get-ChildItem -Path $Root -Directory) {
            $candidate = Join-Path $division.FullName $Slug
            if (Test-Path -Path $candidate) {
                $found += Get-Item -Path $candidate
            }
        }
        if ($found.Count -eq 0) {
            throw "RoleSlug not found under personas: $Slug"
        }
        return $found
    }

    $dirs = @()
    foreach ($division in Get-ChildItem -Path $Root -Directory) {
        $dirs += Get-ChildItem -Path $division.FullName -Directory
    }
    return $dirs
}

function Replace-MarkedBlock {
    param(
        [string]$Text,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Block
    )

    $startIndex = $Text.IndexOf($StartMarker)
    $endIndex = $Text.IndexOf($EndMarker)
    if (($startIndex -lt 0) -or ($endIndex -le $startIndex)) {
        throw "Required marker block not found."
    }

    $before = $Text.Substring(0, $startIndex + $StartMarker.Length)
    $after = $Text.Substring($endIndex)
    return $before + "`r`n" + $Block.Trim() + "`r`n" + $after
}

function Get-MemoryEntries {
    param([string]$MemoryText)

    $startIndex = $MemoryText.IndexOf($MemoryStart)
    $endIndex = $MemoryText.IndexOf($MemoryEnd)
    if (($startIndex -lt 0) -or ($endIndex -le $startIndex)) {
        throw "memory.md marker block not found."
    }

    $entryStart = $startIndex + $MemoryStart.Length
    $entryBlock = $MemoryText.Substring($entryStart, $endIndex - $entryStart).Trim()
    if ([string]::IsNullOrWhiteSpace($entryBlock)) {
        return @()
    }

    $matches = [regex]::Matches($entryBlock, "(?ms)^## .+?(?=^## |\z)")
    $entries = @()
    foreach ($match in $matches) {
        $entries += $match.Value.Trim()
    }
    return $entries
}

function New-SummaryBullets {
    param(
        [string[]]$OldEntries,
        [int]$Limit
    )

    $joined = $OldEntries -join "`n"
    $matches = [regex]::Matches($joined, "(?m)^\s*-\s+(.+)$")
    $seen = @{}
    $bullets = New-Object System.Collections.ArrayList

    foreach ($match in $matches) {
        $clean = $match.Groups[1].Value.Trim()
        if ($clean.Length -gt 180) {
            $clean = $clean.Substring(0, 180) + "..."
        }
        if (($clean.Length -gt 0) -and (-not $seen.ContainsKey($clean))) {
            [void]$bullets.Add("- $clean")
            $seen[$clean] = $true
        }
        if ($bullets.Count -ge $Limit) {
            break
        }
    }

    if ($bullets.Count -eq 0) {
        foreach ($entry in $OldEntries) {
            $firstLine = ($entry -split "`r?`n")[0].Trim()
            if ($firstLine.Length -gt 0) {
                [void]$bullets.Add("- " + $firstLine.TrimStart("#").Trim())
            }
            if ($bullets.Count -ge $Limit) {
                break
            }
        }
    }

    return @($bullets)
}

$personasRoot = Join-Path $SkillRoot "references\personas"
$personaDirs = Get-PersonaDirs $personasRoot $RoleSlug
$changed = 0
$checked = 0

foreach ($dir in $personaDirs) {
    $checked++
    $memoryPath = Join-Path $dir.FullName "memory.md"
    $summaryPath = Join-Path $dir.FullName "memory_summary.md"

    if ((-not (Test-Path -Path $memoryPath)) -or (-not (Test-Path -Path $summaryPath))) {
        Write-Warning "Missing memory files under $($dir.FullName)"
        continue
    }

    $memoryText = Read-TextFile $memoryPath
    $summaryText = Read-TextFile $summaryPath
    $entries = @(Get-MemoryEntries $memoryText)

    if ($entries.Count -le $KeepEntries) {
        continue
    }

    $oldCount = $entries.Count - $KeepEntries
    $oldEntries = @($entries[0..($oldCount - 1)])
    $recentEntries = @($entries[$oldCount..($entries.Count - 1)])
    $bullets = @(New-SummaryBullets $oldEntries $MaxSummaryBullets)
    $nowText = Get-Date -Format "yyyy-MM-dd HH:mm"

    $summaryBlock = @(
        "## 当前压缩摘要",
        "",
        "- 更新时间：$nowText - v1.0.0",
        "- 压缩来源：$oldCount 条旧 memory 原始记录；memory.md 保留最近 $KeepEntries 条 - v1.0.0",
        "",
        "### 可复用记忆",
        ($bullets -join "`r`n")
    ) -join "`r`n"

    $newSummaryText = Replace-MarkedBlock $summaryText $SummaryStart $SummaryEnd $summaryBlock
    $recentBlock = ($recentEntries -join "`r`n`r`n")
    $newMemoryText = Replace-MarkedBlock $memoryText $MemoryStart $MemoryEnd $recentBlock

    if ($Apply) {
        Write-TextFile $summaryPath $newSummaryText
        Write-TextFile $memoryPath $newMemoryText
    }

    $changed++
    Write-Host "Compaction ready: $($dir.Name) old=$oldCount keep=$KeepEntries apply=$Apply"
}

Write-Host "Persona memory compaction check complete."
Write-Host "Persona dirs checked: $checked"
Write-Host "Persona dirs changed: $changed"
if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply to write changes."
}
