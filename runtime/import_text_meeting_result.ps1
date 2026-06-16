param(
  [string]$RuntimeFile = '',
  [string]$SkillRoot = '',
  [string]$TurnsJson = '',
  [string]$TurnsJsonFile = '',
  [string]$SummaryJson = '',
  [string]$SummaryJsonFile = '',
  [string]$VoteRoundsJson = '',
  [string]$VoteRoundsJsonFile = '',
  [string]$DeliberationJson = '',
  [string]$DeliberationJsonFile = '',
  [string]$ViewerUrl = 'http://127.0.0.1:5175/'
)

$ErrorActionPreference = 'Stop'
$Utf8Json = [System.Text.UTF8Encoding]::new($false)

function U {
  param([string]$Value)
  return [System.Text.RegularExpressions.Regex]::Unescape($Value)
}

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
if (-not $RuntimeFile) {
  $RuntimeFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json'
}

function Read-Utf8JsonFile {
  param([string]$Path)
  return (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path | ConvertFrom-Json)
}

function Write-Utf8JsonFile {
  param(
    [string]$Path,
    [object]$Value
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $json = $Value | ConvertTo-Json -Depth 24
  $tempPath = '{0}.{1}.tmp' -f $fullPath, ([guid]::NewGuid().ToString('N'))
  [System.IO.File]::WriteAllText($tempPath, $json, $Utf8Json)
  Move-Item -LiteralPath $tempPath -Destination $fullPath -Force
}

function Read-JsonInput {
  param(
    [string]$InlineJson,
    [string]$JsonFile,
    [string]$Label
  )

  if (-not [string]::IsNullOrWhiteSpace($JsonFile)) {
    if (-not (Test-Path -LiteralPath $JsonFile)) {
      throw "$Label file does not exist: $JsonFile"
    }
    return (Get-Content -Raw -Encoding UTF8 -LiteralPath $JsonFile | ConvertFrom-Json)
  }

  if (-not [string]::IsNullOrWhiteSpace($InlineJson)) {
    return ($InlineJson | ConvertFrom-Json)
  }

  throw "$Label is required."
}

function Read-OptionalJsonInput {
  param(
    [string]$InlineJson,
    [string]$JsonFile,
    [string]$Label
  )

  if (-not [string]::IsNullOrWhiteSpace($JsonFile)) {
    if (-not (Test-Path -LiteralPath $JsonFile)) {
      throw "$Label file does not exist: $JsonFile"
    }
    return (Get-Content -Raw -Encoding UTF8 -LiteralPath $JsonFile | ConvertFrom-Json)
  }

  if (-not [string]::IsNullOrWhiteSpace($InlineJson)) {
    return ($InlineJson | ConvertFrom-Json)
  }

  return $null
}

function Set-ObjectProperty {
  param(
    [object]$Target,
    [string]$Name,
    [object]$Value
  )

  if ($Target.PSObject.Properties[$Name]) {
    $Target.$Name = $Value
  }
  else {
    $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
}

function Get-RoleMetaValue {
  param(
    [object]$RoleMeta,
    [string]$RoleId
  )

  if (-not $RoleMeta -or [string]::IsNullOrWhiteSpace($RoleId)) {
    return $null
  }

  $prop = $RoleMeta.PSObject.Properties[$RoleId]
  if ($prop) {
    return $prop.Value
  }

  return $null
}

function New-FallbackRoleMeta {
  param([string]$RoleId)

  return [ordered]@{
    name = (U '\u4e34\u65f6\u4e13\u5bb6')
    title = (U '\u4e34\u65f6\u53c2\u4f1a\u89d2\u8272')
    lane = 'left'
    department = (U '\u672a\u5206\u7ec4')
  }
}

function Normalize-ImportedTurn {
  param(
    [object]$Turn,
    [int]$Index
  )

  $speakerId = [string]$Turn.speakerId
  if ([string]::IsNullOrWhiteSpace($speakerId)) {
    throw "Imported turn at index $Index is missing speakerId."
  }

  $text = [string]$Turn.text
  if ([string]::IsNullOrWhiteSpace($text)) {
    throw "Imported turn at index $Index is missing text."
  }

  $type = [string]$Turn.type
  if ([string]::IsNullOrWhiteSpace($type)) {
    $type = if ($speakerId -eq 'host' -and $Index -eq 0) { 'control' } else { 'speak' }
  }

  $phase = [string]$Turn.phase
  if ([string]::IsNullOrWhiteSpace($phase)) {
    $phase = if ($speakerId -eq 'host' -and $type -eq 'conclusion') { (U '\u603b\u7ed3') } else { (U '\u8ba8\u8bba') }
  }

  [ordered]@{
    id = if ($Turn.id) { [string]$Turn.id } else { ('import-turn-{0:000}' -f ($Index + 1)) }
    speakerId = $speakerId
    phase = $phase
    type = $type
    screenTitle = if ($Turn.screenTitle) { [string]$Turn.screenTitle } else { $phase }
    screenStatus = if ($Turn.screenStatus) { [string]$Turn.screenStatus } else { if ($type -eq 'conclusion') { 'DONE' } else { 'TEXT' } }
    text = $text
  }
}

function Test-ImportedVoteRounds {
  param(
    [object[]]$VoteRounds,
    [object[]]$Turns
  )

  $turnIds = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($turn in @($Turns)) {
    $id = [string]$turn.id
    if (-not [string]::IsNullOrWhiteSpace($id)) {
      [void]$turnIds.Add($id)
    }
  }

  $legacyFields = @('activationIndex', 'afterTurnIndex', 'beforeTurnIndex', 'beforeTurnId', 'turnIndex')
  for ($i = 0; $i -lt @($VoteRounds).Count; $i++) {
    $round = $VoteRounds[$i]
    $afterTurnId = [string]$round.afterTurnId
    if ([string]::IsNullOrWhiteSpace($afterTurnId)) {
      throw "Vote round $i is missing afterTurnId."
    }
    if (-not $turnIds.Contains($afterTurnId)) {
      throw "Vote round $i points to missing turn id: $afterTurnId."
    }
    foreach ($field in $legacyFields) {
      if ($round.PSObject.Properties[$field]) {
        throw "Vote round $i uses legacy field $field; use afterTurnId only."
      }
    }
    if (-not $round.PSObject.Properties['votes'] -or -not $round.votes) {
      throw "Vote round $i is missing votes."
    }
  }
}

if (-not (Test-Path -LiteralPath $RuntimeFile)) {
  throw "Runtime file does not exist: $RuntimeFile"
}

$session = Read-Utf8JsonFile $RuntimeFile
$importedTurns = @(Read-JsonInput -InlineJson $TurnsJson -JsonFile $TurnsJsonFile -Label 'Turns')
$importedSummary = Read-JsonInput -InlineJson $SummaryJson -JsonFile $SummaryJsonFile -Label 'Summary'
$importedVoteRounds = Read-OptionalJsonInput -InlineJson $VoteRoundsJson -JsonFile $VoteRoundsJsonFile -Label 'VoteRounds'
$importedDeliberation = Read-OptionalJsonInput -InlineJson $DeliberationJson -JsonFile $DeliberationJsonFile -Label 'Deliberation'

$normalizedTurns = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $importedTurns.Count; $i++) {
  $normalizedTurns.Add((Normalize-ImportedTurn -Turn $importedTurns[$i] -Index $i))
}

foreach ($turn in @($normalizedTurns.ToArray())) {
  $meta = Get-RoleMetaValue -RoleMeta $session.roleMeta -RoleId ([string]$turn.speakerId)
  $needsFallback = (-not $meta) -or ([string]$meta.name -eq [string]$turn.speakerId)
  if ($needsFallback) {
    $fallbackMeta = New-FallbackRoleMeta -RoleId ([string]$turn.speakerId)
    if ($meta) {
      $session.roleMeta.PSObject.Properties.Remove([string]$turn.speakerId)
    }
    $session.roleMeta | Add-Member -NotePropertyName ([string]$turn.speakerId) -NotePropertyValue $fallbackMeta
  }
}

$session.turns = @($normalizedTurns.ToArray())
$session.summary = $importedSummary

if ($importedDeliberation) {
  foreach ($prop in $importedDeliberation.PSObject.Properties) {
    Set-ObjectProperty -Target $session.deliberation -Name $prop.Name -Value $prop.Value
  }
  if ($importedDeliberation.PSObject.Properties['voteRounds']) {
    $importedVoteRounds = @($importedDeliberation.voteRounds)
  }
}

if ($importedVoteRounds) {
  $voteRounds = @($importedVoteRounds)
  Test-ImportedVoteRounds -VoteRounds $voteRounds -Turns @($normalizedTurns.ToArray())
  $session.mode = 'jury_deliberation'
  Set-ObjectProperty -Target $session.deliberation -Name 'enabled' -Value $true
  Set-ObjectProperty -Target $session.deliberation -Name 'voteRounds' -Value $voteRounds
  $latestRound = $voteRounds | Select-Object -Last 1
  $session.runtime.mode = 'jury_deliberation'
  $session.runtime.voteSnapshot = [ordered]@{
    roundId = [string]$latestRound.id
    counts = [ordered]@{}
    votes = $latestRound.votes
  }
}
elseif ([string]$session.mode -eq 'jury_deliberation' -and [bool]$session.deliberation.enabled -and @($session.deliberation.voteRounds).Count -gt 0) {
  Test-ImportedVoteRounds -VoteRounds @($session.deliberation.voteRounds) -Turns @($normalizedTurns.ToArray())
}
else {
  $session.mode = 'discussion'
  Set-ObjectProperty -Target $session.deliberation -Name 'enabled' -Value $false
  Set-ObjectProperty -Target $session.deliberation -Name 'voteRounds' -Value @()
}

$session.runtime.status = 'done'
$session.runtime.hostStage = 'done'
$session.runtime.round = 0
$session.runtime.lastSpeakerId = if ($normalizedTurns.Count -gt 0) { [string]$normalizedTurns[$normalizedTurns.Count - 1].speakerId } else { 'host' }
$session.runtime.turnCount = $normalizedTurns.Count
$session.runtime.thinking = @()
$session.runtime.queue = @()
$session.runtime.pendingSpeaker = $null
if (-not ($importedVoteRounds -or ([string]$session.mode -eq 'jury_deliberation' -and @($session.deliberation.voteRounds).Count -gt 0))) {
  $session.runtime.voteSnapshot = [ordered]@{
    roundId = ''
    counts = [ordered]@{}
    votes = [ordered]@{}
  }
}
$session.runtime.unresolvedDisagreements = @()
$session.runtime.nextQuestions = @()
$session.runtime.consensusDraft = if ($importedSummary.PSObject.Properties['consensus']) { @($importedSummary.consensus) } else { @() }
$session.runtime.recentKeyTurns = @($normalizedTurns.ToArray() | Select-Object -Last 5)
$session.runtime.updatedAt = (Get-Date).ToUniversalTime().ToString('o')
$endedAt = (Get-Date).ToUniversalTime().ToString('o')
if ($session.PSObject.Properties['endedAt']) {
  $session.endedAt = $endedAt
}
else {
  $session | Add-Member -NotePropertyName 'endedAt' -NotePropertyValue $endedAt
}

Write-Utf8JsonFile -Path $RuntimeFile -Value $session

$viewerSessionUrl = ('{0}/?session=meeting-runtime.json&reload={1}' -f $ViewerUrl.TrimEnd('/'), [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())

[pscustomobject]@{
  ok = $true
  runtimeFile = [System.IO.Path]::GetFullPath($RuntimeFile)
  turnCount = $normalizedTurns.Count
  consensusCount = @($session.summary.consensus).Count
  implementationCount = @($session.summary.implementationPlan).Count
  workerCount = @($session.summary.recommendedWorkers).Count
  mode = [string]$session.mode
  voteRoundCount = @($session.deliberation.voteRounds).Count
  viewerUrl = $viewerSessionUrl
  codexViewerMessage = ('[{0}]({1}){2}' -f (U '\u6253\u5f00\u53ef\u89c6\u5316\u4f1a\u8bae'), $viewerSessionUrl, (U '\uff08\u5df2\u5bfc\u5165\u672c\u8f6e\u6587\u5b57\u4f1a\u8bae\uff09'))
} | ConvertTo-Json -Depth 8
