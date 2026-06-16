param(
  [string]$RuntimeFile = '',
  [Parameter(Mandatory = $true)]
  [string]$SpeakerId,
  [string]$TurnId = '',
  [string]$Phase = '',
  [ValidateSet('speak', 'challenge', 'vote', 'control', 'consensus', 'decision', 'conclusion')]
  [string]$Type = 'speak',
  [Parameter(Mandatory = $true)]
  [string]$Text,
  [string]$ScreenTitle = '',
  [string]$ScreenStatus = '',
  [int]$RoundNumber = 0,
  [string]$VotesJson = '',
  [string]$SummaryJson = '',
  [switch]$SkipPersonaMemory,
  [switch]$Finish,
  [string]$SkillRoot = ''
)

# append_live_meeting_turn
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
$appendPersonaMemoryScript = Join-Path $SkillRoot 'runtime\append_meeting_persona_memory.ps1'

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

function Get-RoleMetaValue {
  param(
    [object]$RoleMeta,
    [string]$RoleId
  )

  $prop = $RoleMeta.PSObject.Properties[$RoleId]
  if ($prop) { return $prop.Value }
  return $null
}

function Get-FormalRoleIds {
  param([object]$Session)

  if ($Session.runtime -and $Session.runtime.formalParticipants) {
    return @($Session.runtime.formalParticipants | ForEach-Object { [string]$_.roleId })
  }

  return @($Session.participants | Where-Object {
    $_ -and $_ -ne 'host' -and -not (Get-RoleMetaValue -RoleMeta $Session.roleMeta -RoleId ([string]$_)).ambientState
  })
}

function Get-SpeakingAmbientRoleIds {
  param([object]$Session)

  if ($Session.runtime -and $Session.runtime.ambientParticipants) {
    return @($Session.runtime.ambientParticipants | Where-Object { $_.canSpeak } | ForEach-Object { [string]$_.roleId })
  }

  return @($Session.participants | Where-Object {
    $meta = Get-RoleMetaValue -RoleMeta $Session.roleMeta -RoleId ([string]$_)
    $_ -and $_ -ne 'host' -and $meta -and $meta.ambientState -and $meta.canSpeak
  })
}

function Get-VoteVoterRoleIds {
  param([object]$Session)

  $ids = New-Object System.Collections.Generic.List[string]
  $seen = New-Object 'System.Collections.Generic.HashSet[string]'

  $addId = {
    param([string]$RoleId)

    if ([string]::IsNullOrWhiteSpace($RoleId) -or $RoleId -eq 'host') {
      return
    }
    if ($seen.Add($RoleId)) {
      $ids.Add($RoleId)
    }
  }

  if ($Session.runtime -and $Session.runtime.formalParticipants) {
    foreach ($participant in @($Session.runtime.formalParticipants)) {
      & $addId ([string]$participant.roleId)
    }
  }

  if ($Session.runtime -and $Session.runtime.ambientParticipants) {
    foreach ($participant in @($Session.runtime.ambientParticipants)) {
      & $addId ([string]$participant.roleId)
    }
  }

  if ($ids.Count -eq 0) {
    foreach ($participant in @($Session.participants)) {
      & $addId ([string]$participant)
    }
  }

  return @($ids.ToArray())
}

function Normalize-VoteValue {
  param([string]$Value)

  $vote = ([string]$Value).Trim().ToLowerInvariant()
  $sideAValues = @('a', 'side_a', (U '\u65b9\u6848a'), (U '\u652f\u6301a'), 'green')
  $sideBValues = @('b', 'side_b', (U '\u65b9\u6848b'), (U '\u652f\u6301b'), 'red')
  $agreeValues = @('agree', 'follow', 'nod', 'yes', 'same', (U '\u5bf9\u5bf9\u5bf9'), (U '\u540c\u610f'), (U '\u8d5e\u540c'), (U '\u8ddf\u968f'))
  $abstainValues = @('z', 'abstain', 'reserve', 'reserved', (U '\u5f03\u6743'), (U '\u4fdd\u7559'))

  if ($vote -in $sideAValues) {
    return 'a'
  }
  if ($vote -in $sideBValues) {
    return 'b'
  }
  if ($vote -in $agreeValues) {
    return 'agree'
  }
  if ($vote -in $abstainValues) {
    return 'z'
  }

  return 'z'
}

function Get-DominantExplicitFormalVoteSide {
  param(
    [object]$Session,
    [hashtable]$RawVoteMap
  )

  $counts = @{ a = 0; b = 0 }
  foreach ($roleId in @(Get-FormalRoleIds -Session $Session)) {
    if (-not $RawVoteMap.ContainsKey($roleId)) {
      continue
    }

    $vote = [string]$RawVoteMap[$roleId]
    if ($vote -eq 'a' -or $vote -eq 'b') {
      $counts[$vote] = [int]$counts[$vote] + 1
    }
  }

  if ($counts.a -gt $counts.b) { return 'a' }
  if ($counts.b -gt $counts.a) { return 'b' }
  return 'z'
}

function Resolve-VoteForRole {
  param(
    [object]$Session,
    [string]$RoleId,
    [hashtable]$RawVoteMap,
    [string]$DominantFormalVoteSide
  )

  if ($RawVoteMap.ContainsKey($RoleId)) {
    $explicitVote = [string]$RawVoteMap[$RoleId]
    if ($explicitVote -eq 'agree') {
      return $DominantFormalVoteSide
    }
    return $explicitVote
  }

  $meta = Get-RoleMetaValue -RoleMeta $Session.roleMeta -RoleId $RoleId
  if ($meta -and $meta.ambientState) {
    $state = ([string]$meta.ambientState).ToLowerInvariant()
    if ($state -eq 'nod') {
      return $DominantFormalVoteSide
    }

    $ambientVote = Normalize-VoteValue ([string]$meta.ambientVote)
    if ($ambientVote -eq 'agree') {
      return $DominantFormalVoteSide
    }
    return $ambientVote
  }

  return 'z'
}

function Get-RecentKeyTurns {
  param(
    [object[]]$Turns,
    [int]$Limit = 5
  )

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($turn in @($Turns | Select-Object -Last $Limit)) {
    $textValue = [string]$turn.text
    if ($textValue.Length -gt 180) {
      $textValue = $textValue.Substring(0, 180)
    }
    $items.Add([ordered]@{
      id = [string]$turn.id
      speakerId = [string]$turn.speakerId
      phase = [string]$turn.phase
      type = [string]$turn.type
      text = $textValue
    })
  }

  return @($items.ToArray())
}

function Test-PersonaStoreForRole {
  param(
    [string]$Root,
    [string]$RoleId
  )

  if ([string]::IsNullOrWhiteSpace($RoleId) -or $RoleId -eq 'host') {
    return $false
  }

  $personasRoot = Join-Path $Root 'references\personas'
  if (-not (Test-Path -LiteralPath $personasRoot)) {
    return $false
  }

  foreach ($division in Get-ChildItem -Path $personasRoot -Directory) {
    $candidate = Join-Path $division.FullName $RoleId
    if (Test-Path -LiteralPath (Join-Path $candidate 'memory.md')) {
      return $true
    }
  }

  return $false
}

function Get-PlainTextSnippet {
  param(
    [string]$Value,
    [int]$MaxLength = 220
  )

  $snippet = ([string]$Value).Replace("`r", ' ').Replace("`n", ' ').Trim()
  if ($snippet.Length -gt $MaxLength) {
    return $snippet.Substring(0, $MaxLength) + '...'
  }
  return $snippet
}

function Append-PersonaMemoryForTurn {
  param(
    [string]$Root,
    [string]$RoleId,
    [string]$MeetingTopic,
    [string]$TurnText,
    [string]$TurnType,
    [object]$VoteSnapshot
  )

  if ($SkipPersonaMemory -or $RoleId -eq 'host') {
    return $false
  }
  if (-not (Test-Path -LiteralPath $appendPersonaMemoryScript)) {
    return $false
  }
  if (-not (Test-PersonaStoreForRole -Root $Root -RoleId $RoleId)) {
    return $false
  }

  $vote = ''
  if ($VoteSnapshot -and $VoteSnapshot.votes) {
    $prop = $VoteSnapshot.votes.PSObject.Properties[$RoleId]
    if ($prop) {
      $vote = [string]$prop.Value
    }
  }

  $summary = Get-PlainTextSnippet -Value $TurnText -MaxLength 180
  $basis = ('{0}: {1}' -f $TurnType, (Get-PlainTextSnippet -Value $TurnText -MaxLength 260))

  try {
    & $appendPersonaMemoryScript -RoleSlug $RoleId -Topic $MeetingTopic -SkillRoot $Root -Vote $vote -StanceSummary $summary -CandidateTurn $basis -KeyRisk (U '\u672c\u8f6e\u4f1a\u8bae\u53d1\u8a00\u5df2\u81ea\u52a8\u8bb0\u5165\u4eba\u683c\u8bb0\u5fc6\uff0c\u4f9b\u540e\u7eed\u540c\u89d2\u8272\u7ee7\u7eed\u5224\u65ad\u65f6\u590d\u7528\u3002') -Apply | Out-Null
    return $true
  }
  catch {
    Write-Warning ("Persona memory append skipped for {0}: {1}" -f $RoleId, $_.Exception.Message)
    return $false
  }
}

function Convert-VotesToRound {
  param(
    [object]$Votes,
    [object]$Session,
    [int]$Number,
    [string]$AfterTurnId
  )

  $counts = [ordered]@{ a = 0; b = 0; z = 0 }
  $voteMap = [ordered]@{}
  $rawVoteMap = @{}
  $voterIds = @(Get-VoteVoterRoleIds -Session $Session)
  $voterIdSet = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($roleId in $voterIds) {
    [void]$voterIdSet.Add([string]$roleId)
  }

  foreach ($prop in @($Votes.PSObject.Properties)) {
    $roleId = [string]$prop.Name
    if (-not $voterIdSet.Contains($roleId)) {
      continue
    }

    $rawVoteMap[$roleId] = Normalize-VoteValue ([string]$prop.Value)
  }

  $dominantFormalVoteSide = Get-DominantExplicitFormalVoteSide -Session $Session -RawVoteMap $rawVoteMap
  foreach ($roleId in $voterIds) {
    $vote = Resolve-VoteForRole -Session $Session -RoleId ([string]$roleId) -RawVoteMap $rawVoteMap -DominantFormalVoteSide $dominantFormalVoteSide
    if ($vote -notin @('a', 'b', 'z')) {
      $vote = 'z'
    }
    $voteMap[[string]$roleId] = $vote
    $counts[$vote] = [int]$counts[$vote] + 1
  }

  return [ordered]@{
    id = ('vote-{0}' -f $Number)
    label = ('{0}{1}{2}' -f (U '\u7b2c'), $Number, (U '\u8f6e\u6295\u7968'))
    afterTurnId = $AfterTurnId
    counts = $counts
    votes = $voteMap
    voterCount = $voterIds.Count
  }
}

if (-not (Test-Path -LiteralPath $RuntimeFile)) {
  throw "Runtime file does not exist: $RuntimeFile"
}

$session = Read-Utf8JsonFile $RuntimeFile
$turns = New-Object System.Collections.Generic.List[object]
foreach ($turn in @($session.turns)) {
  $turns.Add($turn)
}

$visibleVotes = New-Object System.Collections.Generic.List[object]
foreach ($round in @($session.deliberation.voteRounds)) {
  $visibleVotes.Add($round)
}

$pendingSpeaker = if ($session.runtime -and $session.runtime.PSObject.Properties['pendingSpeaker']) { $session.runtime.pendingSpeaker } else { $null }
if ($pendingSpeaker) {
  $pendingRoleId = [string]$pendingSpeaker.roleId
  $pendingTurnId = [string]$pendingSpeaker.turnId
  if ($pendingRoleId -ne $SpeakerId) {
    throw "Cannot append speaker '$SpeakerId' while pending speaker '$pendingRoleId' is waiting to commit."
  }
  if ($TurnId -and $pendingTurnId -and $TurnId -ne $pendingTurnId) {
    throw "Cannot append turn '$TurnId' while pending turn '$pendingTurnId' is waiting to commit."
  }
  if (-not $TurnId -and -not [string]::IsNullOrWhiteSpace($pendingTurnId)) {
    $TurnId = $pendingTurnId
  }
}

if (-not $TurnId) {
  if ($SpeakerId -eq 'host' -and $Type -eq 'vote') {
    $nextVoteNumber = if ($RoundNumber -gt 0) { $RoundNumber } else { @($session.deliberation.voteRounds).Count + 1 }
    $TurnId = 'host-vote-{0}' -f $nextVoteNumber
  }
  elseif ($SpeakerId -eq 'host' -and $Type -eq 'conclusion') {
    $TurnId = 'host-final'
  }
  else {
    $TurnId = 'turn-{0:000}' -f ($turns.Count + 1)
  }
}

if (-not $Phase) {
  $Phase = if ($Type -eq 'vote') { (U '\u6295\u7968') } elseif ($Type -eq 'control') { (U '\u63a7\u573a') } elseif ($Type -eq 'conclusion') { (U '\u603b\u7ed3') } else { (U '\u5b9e\u65f6\u53d1\u8a00') }
}
if (-not $ScreenTitle) {
  $ScreenTitle = if ($Type -eq 'vote') { (U '\u6295\u7968') } elseif ($Type -eq 'control') { (U '\u8f6e\u6b21\u5f15\u5bfc') } elseif ($Type -eq 'conclusion') { (U '\u4f1a\u8bae\u7ed3\u8bba') } else { (U '\u5b9e\u65f6\u8ba8\u8bba') }
}
if (-not $ScreenStatus) {
  $ScreenStatus = if ($Type -eq 'vote') { 'VOTE' } elseif ($Type -eq 'control') { 'ROUND' } elseif ($Type -eq 'conclusion') { 'DONE' } else { 'LIVE' }
}

$turnObject = [ordered]@{
  id = $TurnId
  speakerId = $SpeakerId
  phase = $Phase
  type = $Type
  screenTitle = $ScreenTitle
  screenStatus = $ScreenStatus
  text = $Text
}
$turns.Add($turnObject)

if ($Type -eq 'vote' -and -not [string]::IsNullOrWhiteSpace($VotesJson)) {
  $votes = $VotesJson | ConvertFrom-Json
  $roundNo = if ($RoundNumber -gt 0) { $RoundNumber } else { $visibleVotes.Count + 1 }
  $visibleVotes.Add((Convert-VotesToRound -Votes $votes -Session $session -Number $roundNo -AfterTurnId $TurnId))
}

if (-not [string]::IsNullOrWhiteSpace($SummaryJson)) {
  $session.summary = $SummaryJson | ConvertFrom-Json
}

$formalRoleIds = @(Get-FormalRoleIds -Session $session)
$currentSpeakerId = $SpeakerId
$thinking = New-Object System.Collections.Generic.List[object]
foreach ($roleId in $formalRoleIds) {
  if ($roleId -eq $currentSpeakerId -or $Finish) {
    continue
  }
  $thinking.Add([ordered]@{
    roleId = $roleId
    status = 'thinking'
  })
}

$latestVote = if ($visibleVotes.Count -gt 0) { $visibleVotes[$visibleVotes.Count - 1] } else { $null }
$voteSnapshot = if ($latestVote) {
  [ordered]@{
    roundId = [string]$latestVote.id
    label = [string]$latestVote.label
    afterTurnId = [string]$latestVote.afterTurnId
    counts = $latestVote.counts
    votes = $latestVote.votes
  }
}
else {
  [ordered]@{ roundId = ''; counts = [ordered]@{}; votes = [ordered]@{} }
}

$unresolved = @()
if ($latestVote) {
  $voteValues = @($latestVote.votes.PSObject.Properties | ForEach-Object { [string]$_.Value } | Where-Object { $_ -in @('a', 'b') } | Sort-Object -Unique)
  if ($voteValues.Count -gt 1) {
    $unresolved = @((U '\u53ef\u89c1\u6295\u7968\u5c1a\u672a\u7edf\u4e00'))
  }
}

$status = if ($Finish) {
  'done'
}
elseif ($Type -eq 'vote') {
  'vote_round_' + ($(if ($RoundNumber -gt 0) { $RoundNumber } else { $visibleVotes.Count }))
}
elseif ($Type -eq 'control') {
  'host_control'
}
elseif ($SpeakerId -eq 'host') {
  'host_control'
}
else {
  'discussion'
}

$hostStage = if ($Finish) {
  'done'
}
elseif ($Type -eq 'vote') {
  'vote'
}
elseif ($Type -eq 'control') {
  'moderate'
}
elseif ($Type -eq 'conclusion') {
  'conclusion'
}
elseif ($SpeakerId -eq 'host') {
  'moderate'
}
else {
  'listen'
}

$session.turns = @($turns.ToArray())
$session.deliberation.voteRounds = @($visibleVotes.ToArray())
$session.runtime.status = $status
$session.runtime.hostStage = $hostStage
$session.runtime.round = if ($RoundNumber -gt 0) { $RoundNumber } else { $visibleVotes.Count }
$session.runtime.lastSpeakerId = $currentSpeakerId
$session.runtime.turnCount = $turns.Count
$session.runtime.thinking = @($thinking.ToArray())
$speakingAmbientRoleIds = @(Get-SpeakingAmbientRoleIds -Session $session | Where-Object { $_ -and $_ -ne $currentSpeakerId })
$session.runtime.queue = @($speakingAmbientRoleIds | ForEach-Object { [ordered]@{ roleId = [string]$_; status = 'ambient_ready' } })
$session.runtime.recentKeyTurns = @(Get-RecentKeyTurns -Turns @($turns.ToArray()))
$session.runtime.voteSnapshot = $voteSnapshot
$session.runtime.unresolvedDisagreements = $unresolved
$session.runtime.nextQuestions = if ($Finish) { @() } else { @((U '\u4e3b\u8fdb\u7a0b\u8bfb\u53d6\u4eba\u683c\u3001\u53ef\u53d1\u8a00\u6c1b\u56f4\u72b6\u6001\u4e0e\u6700\u65b0\u4f1a\u8bae\u8bb0\u5f55\u540e\u8ffd\u52a0\u4e0b\u4e00\u6761')) }
$session.runtime.consensusDraft = if ($session.summary -and $session.summary.consensus) { @($session.summary.consensus) } else { @() }
$session.runtime.pendingSpeaker = $null
$session.runtime.updatedAt = (Get-Date).ToUniversalTime().ToString('o')
if ($Finish) {
  $endedAt = (Get-Date).ToUniversalTime().ToString('o')
  if ($session.PSObject.Properties['endedAt']) {
    $session.endedAt = $endedAt
  }
  else {
    $session | Add-Member -NotePropertyName 'endedAt' -NotePropertyValue $endedAt
  }
}

$personaMemoryAppended = Append-PersonaMemoryForTurn -Root $SkillRoot -RoleId $SpeakerId -MeetingTopic ([string]$session.topic) -TurnText $Text -TurnType $Type -VoteSnapshot $voteSnapshot

Write-Utf8JsonFile -Path $RuntimeFile -Value $session

[pscustomobject]@{
  ok = $true
  runtimeFile = [System.IO.Path]::GetFullPath($RuntimeFile)
  turnId = $TurnId
  speakerId = $SpeakerId
  type = $Type
  turnCount = $turns.Count
  voteRounds = $visibleVotes.Count
  status = $session.runtime.status
  personaMemoryAppended = $personaMemoryAppended
} | ConvertTo-Json -Depth 8
