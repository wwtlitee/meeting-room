param(
  [string]$Topic = '',
  [ValidateSet('jury_deliberation')]
  [string]$Mode = 'jury_deliberation',
  [int]$ParticipantCount = 7,
  [string]$SkillRoot = '',
  [string]$SourceSessionFile = '',
  [string]$OutFile = '',
  [int]$TurnDelayMs = 1200,
  [switch]$UseCurrentSession,
  [switch]$SkipContextBuild
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
$buildContextScript = Join-Path $SkillRoot 'scripts\build_meeting_authoring_context.ps1'
$fallbackSessionScript = Join-Path $SkillRoot 'scripts\new_visual_meeting_session.ps1'
$defaultSessionFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\current-session.json'
$defaultRuntimeFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json'

if (-not $OutFile) {
  $OutFile = $defaultRuntimeFile
}

$ParticipantCount = [Math]::Max(5, [Math]::Min(10, $ParticipantCount))
$TurnDelayMs = [Math]::Max(0, $TurnDelayMs)

function Read-Utf8JsonFile {
  param([string]$Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $text = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
  return ($text | ConvertFrom-Json)
}

function Write-Utf8JsonFile {
  param(
    [string]$Path,
    [object]$Value
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $dir = Split-Path -Parent $fullPath
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  $json = $Value | ConvertTo-Json -Depth 24
  $tempPath = '{0}.{1}.tmp' -f $fullPath, ([guid]::NewGuid().ToString('N'))
  [System.IO.File]::WriteAllText($tempPath, $json, $Utf8Json)

  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      Move-Item -LiteralPath $tempPath -Destination $fullPath -Force
      return
    }
    catch {
      if ($attempt -eq 3) {
        throw
      }
      Start-Sleep -Milliseconds (50 * $attempt)
    }
  }
}

function New-HostRoleMeta {
  return [ordered]@{
    name = (U '\u4e3b\u6301\u4eba')
    title = (U '\u4f1a\u8bae\u4e3b\u6301')
    lane = 'center'
    department = (U '\u4f1a\u8bae\u4e3b\u6301')
  }
}

function Get-ContextBySlugMap {
  param([object]$Context)

  $map = @{}
  foreach ($item in @($Context.roleContexts)) {
    $map[[string]$item.slug] = $item
  }

  return $map
}

function New-ContextFromSourceSession {
  param([object]$SourceSession)

  $participants = @($SourceSession.participants | Where-Object { $_ -and $_ -ne 'host' })
  $roleContexts = @()
  foreach ($speakerId in $participants) {
    $sourceMeta = $SourceSession.roleMeta.PSObject.Properties[[string]$speakerId]
    $meta = if ($sourceMeta) { $sourceMeta.Value } else { $null }
    $roleContexts += [ordered]@{
      slug = [string]$speakerId
      displayName = if ($meta -and $meta.name) { [string]$meta.name } else { [string]$speakerId }
      roleName = if ($meta -and $meta.title) { [string]$meta.title } else { (U '\u4e13\u5bb6\u6210\u5458') }
      division = if ($meta -and $meta.department) { [string]$meta.department } else { '' }
    }
  }

  return [pscustomobject]@{
    ok = $true
    topic = [string]$SourceSession.topic
    participantCount = $participants.Count
    participants = $participants
    roleContexts = $roleContexts
    source = 'source-session'
  }
}

function Get-LiveRoleMeta {
  param(
    [object]$SourceSession,
    [object]$Context
  )

  $contextBySlug = Get-ContextBySlugMap $Context
  $roleMeta = [ordered]@{
    host = New-HostRoleMeta
  }

  $expertIndex = 0
  foreach ($speakerId in @($SourceSession.participants | Where-Object { $_ -ne 'host' })) {
    $sourceMeta = $SourceSession.roleMeta.PSObject.Properties[[string]$speakerId]
    $contextRole = $contextBySlug[[string]$speakerId]
    $lane = if ($sourceMeta) { [string]$sourceMeta.Value.lane } else { '' }
    if ([string]::IsNullOrWhiteSpace($lane)) {
      $lane = if (($expertIndex % 2) -eq 0) { 'left' } else { 'right' }
    }
    $expertIndex += 1

    $name = if ($sourceMeta) { [string]$sourceMeta.Value.name } else { '' }
    if ([string]::IsNullOrWhiteSpace($name) -and $contextRole) {
      $name = [string]$contextRole.displayName
    }
    if ([string]::IsNullOrWhiteSpace($name)) {
      $name = [string]$speakerId
    }

    $title = if ($sourceMeta) { [string]$sourceMeta.Value.title } else { '' }
    if ([string]::IsNullOrWhiteSpace($title) -and $contextRole) {
      $title = [string]$contextRole.roleName
    }
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = (U '\u4e13\u5bb6\u6210\u5458')
    }

    $department = if ($sourceMeta) { [string]$sourceMeta.Value.department } else { '' }
    if ([string]::IsNullOrWhiteSpace($department) -and $contextRole) {
      $department = [string]$contextRole.division
    }

    $roleMeta[[string]$speakerId] = [ordered]@{
      name = $name
      title = $title
      lane = $lane
      department = $department
    }
  }

  return $roleMeta
}

function Get-ThinkingRoster {
  param(
    [object[]]$Participants,
    [string]$CurrentSpeakerId = ''
  )

  $thinking = New-Object System.Collections.Generic.List[object]
  foreach ($speakerId in @($Participants | Where-Object { $_ -and $_ -ne 'host' })) {
    if ([string]$speakerId -eq $CurrentSpeakerId) {
      continue
    }

    $thinking.Add([ordered]@{
      roleId = [string]$speakerId
      status = 'thinking'
    })
  }

  return @($thinking.ToArray())
}

function Get-RoleMetaValue {
  param(
    [object]$RoleMeta,
    [string]$RoleId
  )

  if (-not $RoleMeta -or [string]::IsNullOrWhiteSpace($RoleId)) {
    return $null
  }
  if ($RoleMeta -is [System.Collections.IDictionary] -and $RoleMeta.Contains($RoleId)) {
    return $RoleMeta[$RoleId]
  }

  $metaProp = $RoleMeta.PSObject.Properties[$RoleId]
  if ($metaProp) {
    return $metaProp.Value
  }

  return $null
}

function Get-FormalParticipants {
  param(
    [object[]]$Participants,
    [object]$RoleMeta
  )

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($speakerId in @($Participants | Where-Object { $_ -and $_ -ne 'host' })) {
    $meta = Get-RoleMetaValue -RoleMeta $RoleMeta -RoleId ([string]$speakerId)
    if ($meta -and $meta.ambientState) {
      continue
    }

    $items.Add([ordered]@{
      roleId = [string]$speakerId
      name = if ($meta -and $meta.name) { [string]$meta.name } else { [string]$speakerId }
      title = if ($meta -and $meta.title) { [string]$meta.title } else { '' }
      lane = if ($meta -and $meta.lane) { [string]$meta.lane } else { '' }
      status = 'ready'
    })
  }

  return @($items.ToArray())
}

function Get-AmbientParticipants {
  param(
    [object[]]$Participants,
    [object]$RoleMeta
  )

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($speakerId in @($Participants | Where-Object { $_ -and $_ -ne 'host' })) {
    $meta = Get-RoleMetaValue -RoleMeta $RoleMeta -RoleId ([string]$speakerId)
    if (-not ($meta -and $meta.ambientState)) {
      continue
    }

    $items.Add([ordered]@{
      roleId = [string]$speakerId
      name = if ($meta.name) { [string]$meta.name } else { [string]$speakerId }
      title = if ($meta.title) { [string]$meta.title } else { '' }
      lane = if ($meta.lane) { [string]$meta.lane } else { '' }
      state = [string]$meta.ambientState
      vote = if ($meta.ambientVote) { [string]$meta.ambientVote } else { '' }
    })
  }

  return @($items.ToArray())
}

function Get-QueueSnapshot {
  param(
    [object[]]$Turns,
    [int]$CurrentIndex
  )

  $queue = New-Object System.Collections.Generic.List[object]
  $phase = if ($CurrentIndex -ge 0 -and $CurrentIndex -lt $Turns.Count) { [string]$Turns[$CurrentIndex].phase } else { '' }
  for ($i = $CurrentIndex + 1; $i -lt $Turns.Count; $i++) {
    $turn = $Turns[$i]
    if ([string]$turn.speakerId -eq 'host') {
      continue
    }
    if ($phase -and [string]$turn.phase -ne $phase) {
      break
    }

    $queue.Add([ordered]@{
      roleId = [string]$turn.speakerId
      pendingTurnId = [string]$turn.id
    })
  }

  return @($queue.ToArray())
}

function Get-RuntimeStatus {
  param(
    [string]$MeetingMode,
    [object]$Turn,
    [bool]$Finished = $false
  )

  if ($Finished) {
    return 'done'
  }

  if (-not $Turn) {
    return 'prepare'
  }

  if ($MeetingMode -eq 'jury_deliberation') {
    if ([string]$Turn.id -eq 'opening') { return 'opening' }
    if ([string]$Turn.type -eq 'vote') { return ('vote_round_' + ([string]$Turn.phase -replace '\D', '')) }
    if ([string]$Turn.id -match '^host-r\d+-start$') { return ('discussion_round_' + ([string]$Turn.id -replace '\D', '')) }
    if ([string]$Turn.id -match '^host-r\d+-result$') { return ('vote_result_' + ([string]$Turn.id -replace '\D', '')) }
    if ([string]$Turn.id -eq 'host-final') { return 'final_summary' }
  }

  if ([string]$Turn.speakerId -eq 'host') {
    return 'host_control'
  }

  return 'discussion'
}

function Get-HostStage {
  param(
    [string]$MeetingMode,
    [object]$Turn,
    [bool]$Finished = $false
  )

  if ($Finished) {
    return 'done'
  }
  if (-not $Turn) {
    return 'prepare'
  }
  if ([string]$Turn.speakerId -ne 'host') {
    return 'listen'
  }
  if ([string]$Turn.type -eq 'vote') {
    return 'vote'
  }
  if ([string]$Turn.type -eq 'conclusion') {
    return 'conclusion'
  }
  if ($MeetingMode -eq 'jury_deliberation' -and [string]$Turn.id -match '^host-r\d+-') {
    return 'round-control'
  }

  return 'moderate'
}

function Get-RoundNumber {
  param(
    [object]$Turn,
    [object[]]$VisibleVoteRounds
  )

  if (-not $Turn) {
    return 0
  }
  if ([string]$Turn.id -match 'host-vote-(\d+)') {
    return [int]$matches[1]
  }
  if ([string]$Turn.id -match 'host-r(\d+)-start') {
    return [int]$matches[1]
  }
  if ([string]$Turn.id -eq 'host-final') {
    return @($VisibleVoteRounds).Count
  }
  if ([string]$Turn.phase -match '(\d+)') {
    return [int]$matches[1]
  }

  return 0
}

function Get-CurrentOptions {
  param([object]$SourceSession)

  if (-not $SourceSession.deliberation) {
    return [ordered]@{}
  }

  return [ordered]@{
    a = [ordered]@{
      label = [string]$SourceSession.deliberation.labelA
      detail = [string]$SourceSession.deliberation.detailA
    }
    b = [ordered]@{
      label = [string]$SourceSession.deliberation.labelB
      detail = [string]$SourceSession.deliberation.detailB
    }
    z = [ordered]@{
      label = if ($SourceSession.deliberation.labelZ) { [string]$SourceSession.deliberation.labelZ } else { (U '\u5f03\u6743') }
      detail = if ($SourceSession.deliberation.detailZ) { [string]$SourceSession.deliberation.detailZ } else { (U '\u6682\u4e0d\u8868\u6001') }
    }
  }
}

function Get-VoteSnapshot {
  param([object[]]$VisibleVoteRounds)

  $rounds = @($VisibleVoteRounds)
  if ($rounds.Count -eq 0) {
    return [ordered]@{
      roundId = ''
      counts = [ordered]@{}
      votes = [ordered]@{}
    }
  }

  $round = $rounds[$rounds.Count - 1]
  return [ordered]@{
    roundId = [string]$round.id
    label = [string]$round.label
    afterTurnId = [string]$round.afterTurnId
    counts = if ($round.counts) { $round.counts } else { [ordered]@{} }
    votes = if ($round.votes) { $round.votes } else { [ordered]@{} }
  }
}

function Get-RecentKeyTurns {
  param(
    [object[]]$Turns,
    [int]$Limit = 5
  )

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($turn in @($Turns | Select-Object -Last $Limit)) {
    $text = [string]$turn.text
    if ($text.Length -gt 180) {
      $text = $text.Substring(0, 180)
    }
    $items.Add([ordered]@{
      id = [string]$turn.id
      speakerId = [string]$turn.speakerId
      phase = [string]$turn.phase
      type = [string]$turn.type
      text = $text
    })
  }

  return @($items.ToArray())
}

function Get-NextQuestions {
  param(
    [object]$Turn,
    [object[]]$Queue,
    [bool]$Finished = $false
  )

  if ($Finished) {
    return @()
  }
  if (-not $Turn) {
    return @('Which participant should speak first?')
  }
  if (@($Queue).Count -gt 0) {
    return @('What should the next queued participant respond to from the latest turn?')
  }

  return @('Has the meeting reached an actionable consensus, or is another round needed?')
}

function Get-UnresolvedDisagreements {
  param(
    [object]$SourceSession,
    [object[]]$VisibleVoteRounds
  )

  $snapshot = Get-VoteSnapshot -VisibleVoteRounds $VisibleVoteRounds
  $votes = @($snapshot.votes.PSObject.Properties | ForEach-Object { [string]$_.Value } | Where-Object { $_ })
  $uniqueVotes = @($votes | Select-Object -Unique)
  if ($uniqueVotes.Count -gt 1) {
    return @('Visible votes are not unified yet.')
  }

  return @()
}

function Update-LiveRuntimeState {
  param(
    [object]$LiveSession,
    [object]$SourceSession,
    [object]$Turn,
    [object[]]$AllTurns,
    [int]$CurrentIndex,
    [object[]]$AppendedTurns,
    [object[]]$VisibleVoteRounds,
    [bool]$Finished = $false
  )

  $queue = @(Get-QueueSnapshot -Turns $AllTurns -CurrentIndex $CurrentIndex)
  $roundNumber = Get-RoundNumber -Turn $Turn -VisibleVoteRounds $VisibleVoteRounds
  $currentSpeakerId = if ($Turn) { [string]$Turn.speakerId } else { '' }

  $LiveSession.turns = @($AppendedTurns)
  $LiveSession.deliberation.voteRounds = @($VisibleVoteRounds)
  $LiveSession.runtime.status = Get-RuntimeStatus -MeetingMode ([string]$LiveSession.mode) -Turn $Turn -Finished:$Finished
  $LiveSession.runtime.hostStage = Get-HostStage -MeetingMode ([string]$LiveSession.mode) -Turn $Turn -Finished:$Finished
  $LiveSession.runtime.round = $roundNumber
  $LiveSession.runtime.lastSpeakerId = $currentSpeakerId
  $LiveSession.runtime.turnCount = @($AppendedTurns).Count
  $LiveSession.runtime.thinking = if ($Finished) { @() } else { @(Get-ThinkingRoster -Participants $LiveSession.participants -CurrentSpeakerId $currentSpeakerId) }
  $LiveSession.runtime.queue = if ($Finished) { @() } else { $queue }
  $LiveSession.runtime.recentKeyTurns = @(Get-RecentKeyTurns -Turns $AppendedTurns)
  $LiveSession.runtime.voteSnapshot = Get-VoteSnapshot -VisibleVoteRounds $VisibleVoteRounds
  $LiveSession.runtime.unresolvedDisagreements = @(Get-UnresolvedDisagreements -SourceSession $SourceSession -VisibleVoteRounds $VisibleVoteRounds)
  $LiveSession.runtime.nextQuestions = @(Get-NextQuestions -Turn $Turn -Queue $queue -Finished:$Finished)
  $LiveSession.runtime.consensusDraft = if ($Finished -and $SourceSession.summary) { @($SourceSession.summary.consensus) } else { @() }
  $LiveSession.runtime.updatedAt = (Get-Date).ToUniversalTime().ToString('o')
}

function New-LiveSessionShell {
  param(
    [object]$SourceSession,
    [object]$Context,
    [string]$MeetingMode
  )

  $roleMeta = Get-LiveRoleMeta -SourceSession $SourceSession -Context $Context
  $participantIds = @($SourceSession.participants)
  $meetingMode = if ($SourceSession.mode) { [string]$SourceSession.mode } else { $MeetingMode }

  return [ordered]@{
    version = '1.3.0'
    id = if ($SourceSession.id) { [string]$SourceSession.id + '-live' } else { 'meeting-live-' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
    startedAt = (Get-Date).ToUniversalTime().ToString('o')
    layout = 'vertical-long-table'
    title = [string]$SourceSession.title
    topic = [string]$SourceSession.topic
    generator = 'meeting-room/runtime/run_live_meeting.ps1'
    mode = $meetingMode
    participants = $participantIds
    roleMeta = $roleMeta
    deliberation = [ordered]@{
      enabled = [bool]$SourceSession.deliberation.enabled
      labelA = [string]$SourceSession.deliberation.labelA
      labelB = [string]$SourceSession.deliberation.labelB
      labelZ = if ($SourceSession.deliberation.labelZ) { [string]$SourceSession.deliberation.labelZ } else { (U '\u5f03\u6743') }
      detailA = [string]$SourceSession.deliberation.detailA
      detailB = [string]$SourceSession.deliberation.detailB
      detailZ = if ($SourceSession.deliberation.detailZ) { [string]$SourceSession.deliberation.detailZ } else { (U '\u6682\u4e0d\u8868\u6001') }
      voteRounds = @()
    }
    runtime = [ordered]@{
      version = '1.1.0'
      kind = 'meeting-runtime'
      status = 'prepare'
      topic = [string]$SourceSession.topic
      currentOptions = Get-CurrentOptions -SourceSession $SourceSession
      hostStage = 'prepare'
      round = 0
      host = 'main-process'
      mode = $meetingMode
      participantTarget = [int]$Context.participantCount
      participantMin = 5
      participantDefault = 7
      participantMax = 10
      formalParticipants = @(Get-FormalParticipants -Participants $participantIds -RoleMeta $roleMeta)
      ambientParticipants = @(Get-AmbientParticipants -Participants $participantIds -RoleMeta $roleMeta)
      thinking = @()
      queue = @()
      recentKeyTurns = @()
      unresolvedDisagreements = @()
      voteSnapshot = [ordered]@{
        roundId = ''
        counts = [ordered]@{}
        votes = [ordered]@{}
      }
      consensusDraft = @()
      nextQuestions = @('Which participant should speak first?')
      lastSpeakerId = ''
      turnCount = 0
      note = 'single-process-live-runtime'
      updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    turns = @()
    summary = [ordered]@{}
  }
}

if (-not $Topic -and -not $UseCurrentSession -and -not $SourceSessionFile) {
  throw 'Topic is required unless -UseCurrentSession or -SourceSessionFile is provided.'
}

$sourceFile = ''
if ($SourceSessionFile) {
  $sourceFile = [System.IO.Path]::GetFullPath($SourceSessionFile)
}
elseif ($UseCurrentSession) {
  $sourceFile = $defaultSessionFile
}
else {
  $tempSourceFile = Join-Path $SkillRoot ('assets\expert-meeting-viewer\art\current-session.runtime-source-{0}.json' -f ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
  $null = & $fallbackSessionScript -Topic $Topic -Mode $Mode -ParticipantCount $ParticipantCount -SkillRoot $SkillRoot -OutFile $tempSourceFile -Apply
  $sourceFile = $tempSourceFile
}

if (-not (Test-Path -LiteralPath $sourceFile)) {
  throw "Source session file not found: $sourceFile"
}

$sourceSession = Read-Utf8JsonFile $sourceFile
if (-not $Topic) {
  $Topic = [string]$sourceSession.topic
}

$context = $null
if ($SkipContextBuild) {
  $context = New-ContextFromSourceSession -SourceSession $sourceSession
}
else {
  $context = (& $buildContextScript -Topic $Topic -ParticipantCount $ParticipantCount -SkillRoot $SkillRoot) | ConvertFrom-Json
  if (-not $context.ok) {
    throw 'Failed to build meeting authoring context.'
  }
}

$liveSession = New-LiveSessionShell -SourceSession $sourceSession -Context $context -MeetingMode $Mode
$allTurns = @($sourceSession.turns)
$appendedTurns = New-Object System.Collections.Generic.List[object]
$visibleVoteRounds = New-Object System.Collections.Generic.List[object]

Update-LiveRuntimeState -LiveSession $liveSession -SourceSession $sourceSession -Turn $null -AllTurns $allTurns -CurrentIndex -1 -AppendedTurns @() -VisibleVoteRounds @()
Write-Utf8JsonFile -Path $OutFile -Value $liveSession

for ($i = 0; $i -lt $allTurns.Count; $i++) {
  $turn = $allTurns[$i]
  $appendedTurns.Add($turn)

  if ([string]$turn.type -eq 'vote') {
    $round = @($sourceSession.deliberation.voteRounds | Where-Object { [string]$_.afterTurnId -eq [string]$turn.id }) | Select-Object -First 1
    if ($round) {
      $visibleVoteRounds.Add($round)
    }
  }

  Update-LiveRuntimeState -LiveSession $liveSession -SourceSession $sourceSession -Turn $turn -AllTurns $allTurns -CurrentIndex $i -AppendedTurns @($appendedTurns.ToArray()) -VisibleVoteRounds @($visibleVoteRounds.ToArray())

  Write-Utf8JsonFile -Path $OutFile -Value $liveSession

  if ($TurnDelayMs -gt 0 -and $i -lt $allTurns.Count - 1) {
    Start-Sleep -Milliseconds $TurnDelayMs
  }
}

$liveSession.summary = $sourceSession.summary
$lastTurn = if ($allTurns.Count -gt 0) { $allTurns[$allTurns.Count - 1] } else { $null }
Update-LiveRuntimeState -LiveSession $liveSession -SourceSession $sourceSession -Turn $lastTurn -AllTurns $allTurns -CurrentIndex ($allTurns.Count - 1) -AppendedTurns @($appendedTurns.ToArray()) -VisibleVoteRounds @($visibleVoteRounds.ToArray()) -Finished $true
$liveSession.endedAt = (Get-Date).ToUniversalTime().ToString('o')

Write-Utf8JsonFile -Path $OutFile -Value $liveSession

[pscustomobject]@{
  ok = $true
  version = '1.1.0'
  kind = 'single-process-live-meeting-runtime'
  mode = [string]$liveSession.mode
  topic = $Topic
  participantCount = [int]$context.participantCount
  participants = @($context.participants)
  sourceSessionFile = $sourceFile
  outFile = [System.IO.Path]::GetFullPath($OutFile)
  turns = @($allTurns).Count
  voteRounds = @($visibleVoteRounds.ToArray()).Count
} | ConvertTo-Json -Depth 10

