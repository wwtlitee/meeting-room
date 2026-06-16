param(
  [Parameter(Mandatory = $true)]
  [string]$RoleSlug,
  [Parameter(Mandatory = $true)]
  [string]$Topic,
  [string]$SkillRoot = '',
  [string]$Vote = '',
  [string]$StanceSummary = '',
  [string]$CandidateTurn = '',
  [string]$KeyRisk = '',
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$MemoryStart = '<!-- memory_entries:start -->'
$MemoryEnd = '<!-- memory_entries:end -->'

function U {
  param([string]$Value)
  return [System.Text.RegularExpressions.Regex]::Unescape($Value)
}

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$personasRoot = Join-Path $SkillRoot 'references\personas'

function Read-TextFile {
  param([string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-TextFile {
  param(
    [string]$Path,
    [string]$Content
  )
  [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Get-PersonaDirBySlug {
  param(
    [string]$Root,
    [string]$Slug
  )

  foreach ($division in Get-ChildItem -Path $Root -Directory) {
    $candidate = Join-Path $division.FullName $Slug
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw "RoleSlug not found under personas: $Slug"
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
    throw 'Required marker block not found.'
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
    throw 'memory.md marker block not found.'
  }

  $entryStart = $startIndex + $MemoryStart.Length
  $entryBlock = $MemoryText.Substring($entryStart, $endIndex - $entryStart).Trim()
  if ([string]::IsNullOrWhiteSpace($entryBlock)) {
    return @()
  }

  $matches = [regex]::Matches($entryBlock, '(?ms)^## .+?(?=^## |\z)')
  $entries = @()
  foreach ($match in $matches) {
    $entries += $match.Value.Trim()
  }
  return $entries
}

function New-MemoryEntry {
  param(
    [string]$EntryTopic,
    [string]$VoteValue,
    [string]$Summary,
    [string]$Turn,
    [string]$Risk
  )

  $voteText = if ($VoteValue) { $VoteValue.ToUpperInvariant() } else { (U '\u672a\u8bb0\u5f55') }
  $summaryText = if ($Summary) { $Summary } else { (U '\u672a\u8bb0\u5f55') }
  $turnText = if ($Turn) { $Turn } else { (U '\u672a\u8bb0\u5f55') }
  $riskText = if ($Risk) { $Risk } else { (U '\u672a\u8bb0\u5f55') }

  $lines = @(
    ('## {0} | {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $EntryTopic),
    ('- {0}{1}' -f (U '\u4f1a\u8bae\u6295\u7968\uff1a'), $voteText),
    ('- {0}{1}' -f (U '\u672c\u8f6e\u89c2\u70b9\uff1a'), $summaryText),
    ('- {0}{1}' -f (U '\u53d1\u8a00\u4f9d\u636e\uff1a'), $turnText),
    ('- {0}{1}' -f (U '\u98ce\u9669\u63d0\u9192\uff1a'), $riskText),
    ('- {0}' -f (U '\u4e0b\u6b21\u590d\u7528\u4ef7\u503c\uff1a\u540e\u7eed\u82e5\u4e3b\u8fdb\u7a0b\u8ffd\u95ee\u8be5\u4eba\u683c\u521a\u624d\u7684\u5224\u65ad\u4f9d\u636e\uff0c\u53ef\u76f4\u63a5\u4ece\u672c\u6761\u4f1a\u8bae\u8bb0\u5fc6\u56de\u635e\u3002'))
  )

  return ($lines -join "`r`n")
}

$personaDir = Get-PersonaDirBySlug -Root $personasRoot -Slug $RoleSlug
$memoryPath = Join-Path $personaDir 'memory.md'
if (-not (Test-Path -LiteralPath $memoryPath)) {
  throw "memory.md not found: $memoryPath"
}

$memoryText = Read-TextFile $memoryPath
$entries = @(Get-MemoryEntries $memoryText)
$newEntry = New-MemoryEntry -EntryTopic $Topic -VoteValue $Vote -Summary $StanceSummary -Turn $CandidateTurn -Risk $KeyRisk
$updatedEntries = @($newEntry) + $entries
$updatedBlock = ($updatedEntries -join "`r`n`r`n")
$newMemoryText = Replace-MarkedBlock -Text $memoryText -StartMarker $MemoryStart -EndMarker $MemoryEnd -Block $updatedBlock

if ($Apply) {
  Write-TextFile -Path $memoryPath -Content $newMemoryText
}

[pscustomobject]@{
  ok = $true
  roleSlug = $RoleSlug
  memoryPath = $memoryPath
  apply = [bool]$Apply
} | ConvertTo-Json -Depth 6
