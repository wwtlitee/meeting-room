param(
  [string]$Topic = '',
[ValidateSet('discussion','jury_deliberation')]
[string]$Mode = 'discussion',
  [int]$ParticipantCount = 8,
  [int]$Port = 5175,
  [string]$SkillRoot = '',
  [string]$SessionFile = '',
  [switch]$UseCurrentSession,
  [int]$LiveTurnDelayMs = 1200,
  [switch]$DisableLiveRuntime
)

$ErrorActionPreference = 'Stop'

function T {
  param([string]$Value)
  return [System.Text.RegularExpressions.Regex]::Unescape($Value)
}

$Text = [pscustomobject]@{
  HostRole = (T '\u4e3b\u6301\u4eba\uff08\u4f1a\u8bae\u4e3b\u6301\uff09')
  LeftParen = (T '\uff08')
  RightParen = (T '\uff09')
  ListSep = (T '\u3001')
  MeetingTopic = (T '\u4f1a\u8bae\u4e3b\u9898\uff1a')
  Participants = (T '\u53c2\u4f1a\u4eba\u5458\uff1a')
  VisualOptional = (T '\u53ef\u89c6\u5316\u4f1a\u8bae\uff08\u53ef\u9009\u65c1\u89c2\uff09\uff1a')
  VisualUnavailable = (T '\u53ef\u89c6\u5316\u4f1a\u8bae\uff08\u53ef\u9009\u65c1\u89c2\uff09\uff1a\u5f53\u524d\u4e0d\u53ef\u7528\uff0c\u7ee7\u7eed\u6587\u5b57\u4f1a\u8bae\u3002')
  TextTranscript = (T '\u4ee5\u4e0b\u4e3a\u6587\u5b57\u4f1a\u8bae\u5b9e\u5f55\uff1a')
  Conclusion = (T '\u4f1a\u8bae\u7ed3\u8bba\uff1a')
  Plan = (T '\u5b9e\u65bd\u65b9\u6848\uff1a')
  Workers = (T '\u63a8\u8350\u5458\u5de5\uff1a')
  ExecutionChoice = (T '\u8bf7\u9009\u62e9\u6267\u884c\u65b9\u5f0f\uff1a')
  DirectExecution = (T '\u0031\uff0c\u76f4\u63a5\u4e3b\u4efb\u52a1\u6267\u884c')
  SubAgentExecution = (T '\u0032\uff0c\u62c9\u8d77\u5b50 agent \u5206\u5de5\u6267\u884c')
  Deliverable = (T '\uff1a')
  Owner = (T '\uff1b\u8d1f\u8d23\u4eba\uff1a')
  Acceptance = (T '\uff1b\u9a8c\u6536\uff1a')
  Slash = ' / '
  WorkerTaskSep = (T '\uff1a')
  WorkerDeliverable = (T '\uff1b\u4ea4\u4ed8\uff1a')
  LaunchBlocked = (T '\u53ef\u89c6\u5316\u4f1a\u8bae\u6682\u4e0d\u53ef\u7528')
  BrowserWarning = (T '\u6ce8\u610f\uff1a\u672a\u80fd\u786e\u8ba4\u5f53\u524d\u7aef\u53e3\u6b63\u5728\u670d\u52a1\u672c\u6b21\u4f1a\u8bae session\u3002')
  NoTextFallback = (T '\u6587\u5b57\u4f1a\u8bae\u53ef\u4ee5\u7ee7\u7eed\uff1b\u8bf7\u5148\u4fee\u590d viewer/server/session \u8eab\u4efd\u6821\u9a8c\u95ee\u9898\u540e\u518d\u4f7f\u7528\u53ef\u89c6\u5316\u65c1\u89c2\u3002')
}

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$startViewerScript = Join-Path $SkillRoot 'scripts\start_visual_meeting.ps1'
$clickMeetingLinkScript = Join-Path $SkillRoot 'scripts\click_latest_meeting_link.ps1'
$initializeLiveScript = Join-Path $SkillRoot 'runtime\initialize_live_meeting.ps1'
$defaultSessionFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\current-session.json'
$defaultRuntimeFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json'
$LiveTurnDelayMs = [Math]::Max(0, $LiveTurnDelayMs)

function Get-SessionRoleLine {
  param(
    [object]$FullSession,
    [string]$RoleId
  )

  if ($RoleId -eq 'host') {
    return $Text.HostRole
  }

  $roleMetaProperty = $FullSession.roleMeta.PSObject.Properties[$RoleId]
  if (-not $roleMetaProperty) {
    return $RoleId
  }

  $roleMeta = $roleMetaProperty.Value
  $name = [string]$roleMeta.name
  $title = [string]$roleMeta.title

  if ($name -and $title) {
    return ('{0}{1}{2}{3}' -f $name, $Text.LeftParen, $title, $Text.RightParen)
  }
  if ($name) {
    return $name
  }
  if ($title) {
    return $title
  }

  return $RoleId
}

function Get-VisibleMeetingParticipantIds {
  param([object]$FullSession)

  $ids = New-Object System.Collections.Generic.List[string]
  $ids.Add('host')

  if ($FullSession.runtime -and $FullSession.runtime.formalParticipants) {
    foreach ($item in @($FullSession.runtime.formalParticipants)) {
      $roleId = [string]$item.roleId
      if (-not [string]::IsNullOrWhiteSpace($roleId)) {
        $ids.Add($roleId)
      }
    }
    foreach ($item in @($FullSession.runtime.ambientParticipants)) {
      $roleId = [string]$item.roleId
      if (-not [string]::IsNullOrWhiteSpace($roleId)) {
        $ids.Add($roleId)
      }
    }
    return @($ids.ToArray() | Select-Object -Unique)
  }

  foreach ($roleId in @($FullSession.participants | Where-Object { $_ -and $_ -ne 'host' })) {
    $metaProp = $FullSession.roleMeta.PSObject.Properties[[string]$roleId]
    if ($metaProp -and $metaProp.Value.ambientState) {
      continue
    }
    $ids.Add([string]$roleId)
  }

  return @($ids.ToArray() | Select-Object -Unique)
}

function ConvertTo-LimitedLines {
  param(
    [object[]]$Items,
    [scriptblock]$Formatter,
    [int]$Limit = 6
  )

  $lines = New-Object System.Collections.Generic.List[string]
  foreach ($item in @($Items | Select-Object -First $Limit)) {
    $line = & $Formatter $item
    if (-not [string]::IsNullOrWhiteSpace($line)) {
      $lines.Add($line)
    }
  }

  return @($lines)
}

function ConvertTo-UserSafeText {
  param([object]$Value)

  $text = [string]$Value
  if ([string]::IsNullOrWhiteSpace($text)) {
    return ''
  }

  $text = $text -replace '<SCRIPT_[^>]+>', '内部步骤'
  $text = $text -replace '\bSCRIPT_[A-Za-z0-9_.-]+\b', '内部步骤'
  $text = $text -replace '\bcurrent-session\.json\b', '会议内容'
  $text = $text -replace '\bvisualTranscript\b', '会议记录'
  $text = $text -replace '\bsession\s+JSON\b', '会议内容'
  $text = $text -replace '\bsession\b', '会议内容'
  $text = $text -replace '\bviewer\b', '会议页'
  $text = $text -replace '会议数据', '会议内容'
  $text = $text -replace '剧本', '会议过程'
  $text = $text -replace 'A/B\s*方案', '两种备选路线'

  return $text
}

function Test-JuryVoteUnanimous {
  param([object]$Round)

  if (-not $Round.votes -or -not $Round.votes.PSObject.Properties) {
    return $false
  }

  $votes = @(
    $Round.votes.PSObject.Properties |
      Where-Object { $_.Name -ne 'host' -and -not [string]::IsNullOrWhiteSpace([string]$_.Value) } |
      ForEach-Object { ([string]$_.Value).ToLowerInvariant() }
  )
  $formalVotes = @($votes | Where-Object { $_ -in @('a', 'b') })
  if ($formalVotes.Count -eq 0) {
    return $false
  }

  return @($formalVotes | Sort-Object -Unique).Count -eq 1
}

function Test-JurySessionContract {
  param([object]$FullSession)

  $failures = New-Object System.Collections.Generic.List[string]
  $mode = [string]$FullSession.mode
  $isJury = $mode -eq 'jury_deliberation' -or [bool]$FullSession.deliberation.enabled
  if (-not $isJury) {
    return [pscustomobject]@{
      ok = $true
      failures = @()
    }
  }

  $turns = @($FullSession.turns)
  $voteRounds = @($FullSession.deliberation.voteRounds)
  if ($turns.Count -eq 0) {
    $failures.Add('Jury session must contain turns.')
  }
  if ($voteRounds.Count -eq 0) {
    $failures.Add('Jury session must contain deliberation.voteRounds.')
  }
  if ($turns.Count -gt 0 -and [string]$turns[0].speakerId -ne 'host') {
    $failures.Add('First jury turn must be a host topic-reading turn.')
  }

  $turnIdMap = @{}
  $turnIndexById = @{}
  for ($i = 0; $i -lt $turns.Count; $i++) {
    $turn = $turns[$i]
    $id = [string]$turn.id
    $speakerId = [string]$turn.speakerId
    $phase = [string]$turn.phase
    $type = [string]$turn.type

    if ([string]::IsNullOrWhiteSpace($id)) {
      $failures.Add(("Jury turn at index {0} is missing id." -f $i))
    }
    elseif ($turnIdMap.ContainsKey($id)) {
      $failures.Add(("Jury turn id is duplicated: {0}" -f $id))
    }
    else {
      $turnIdMap[$id] = $turn
      $turnIndexById[$id] = $i
    }

    if ($speakerId -ne 'host' -and ($phase -match '裁决|投票|控场|总结|结论|收束' -or $type -in @('vote', 'control', 'conclusion'))) {
      $failures.Add(("Non-host turn must not control jury flow: index {0}, speaker {1}, phase {2}." -f $i, $speakerId, $phase))
    }
  }

  if ($voteRounds.Count -gt 0) {
    $firstAfterTurnId = [string]$voteRounds[0].afterTurnId
    if ($firstAfterTurnId -ne 'host-vote-1') {
      $failures.Add('First vote round must attach to host-vote-1.')
    }

    $firstVoteIndex = -1
    for ($i = 0; $i -lt $turns.Count; $i++) {
      if ([string]$turns[$i].id -eq 'host-vote-1') {
        $firstVoteIndex = $i
        break
      }
    }
    if ($firstVoteIndex -ne 1) {
      $failures.Add('First host vote-control turn must immediately follow the opening host turn.')
    }
    elseif ($turns.Count -le 2 -or [string]$turns[2].speakerId -ne 'host') {
      $failures.Add('A host round-start control turn must immediately follow the first vote-control turn.')
    }

    if (-not (Test-JuryVoteUnanimous -Round $voteRounds[$voteRounds.Count - 1])) {
      $failures.Add('Final jury vote must be unanimous before the host summary turn.')
    }
  }

  $legacyVoteFields = @('activationIndex', 'afterTurnIndex', 'beforeTurnIndex', 'beforeTurnId', 'turnIndex')
  for ($i = 0; $i -lt $voteRounds.Count; $i++) {
    $round = $voteRounds[$i]
    $afterTurnId = [string]$round.afterTurnId

    foreach ($field in $legacyVoteFields) {
      if ($round.PSObject.Properties.Name -contains $field) {
        $failures.Add(("Vote round {0} must use afterTurnId only; remove legacy field {1}." -f $i, $field))
      }
    }

    if ([string]::IsNullOrWhiteSpace($afterTurnId)) {
      $failures.Add(("Vote round {0} is missing afterTurnId." -f $i))
      continue
    }
    if (-not $turnIdMap.ContainsKey($afterTurnId)) {
      $failures.Add(("Vote round {0} points to missing turn id {1}." -f $i, $afterTurnId))
      continue
    }

    $hostTurn = $turnIdMap[$afterTurnId]
    if ([string]$hostTurn.speakerId -ne 'host') {
      $failures.Add(("Vote round {0} must point to a host turn, got {1}." -f $i, [string]$hostTurn.speakerId))
    }
    if ([string]$hostTurn.type -ne 'vote' -and [string]$hostTurn.phase -notmatch '投票') {
      $failures.Add(("Vote round {0} must point to a host vote-control turn." -f $i))
    }

    $roundNumber = $i + 1
    $expectedVoteTurnId = ('host-vote-{0}' -f $roundNumber)
    if ($afterTurnId -ne $expectedVoteTurnId) {
      $failures.Add(("Vote round {0} must target {1}, got {2}." -f $i, $expectedVoteTurnId, $afterTurnId))
    }

    if (-not $turnIndexById.ContainsKey($afterTurnId)) {
      continue
    }

    $voteTurnIndex = [int]$turnIndexById[$afterTurnId]
    $isUnanimous = Test-JuryVoteUnanimous -Round $round
    if ($isUnanimous) {
      if ($i -ne $voteRounds.Count - 1) {
        $failures.Add(("Only the final jury vote may be unanimous; vote round {0} still has following rounds." -f $i))
      }
      $expectedResultId = ('host-r{0}-result' -f $roundNumber)
      if ($voteTurnIndex + 1 -ge $turns.Count) {
        $failures.Add(("Unanimous vote round {0} must be followed by a host result turn." -f $i))
      }
      else {
        $resultTurn = $turns[$voteTurnIndex + 1]
        if ([string]$resultTurn.speakerId -ne 'host' -or [string]$resultTurn.type -ne 'control' -or [string]$resultTurn.id -ne $expectedResultId -or [string]$resultTurn.phase -notmatch '结果|裁决|一致') {
          $failures.Add(("Unanimous vote round {0} must be followed by {1}, a host result turn." -f $i, $expectedResultId))
        }
        elseif ($voteTurnIndex + 2 -ge $turns.Count) {
          $failures.Add(("Unanimous vote round {0} must be followed by host-final after {1}." -f $i, $expectedResultId))
        }
        else {
          $nextTurn = $turns[$voteTurnIndex + 2]
          if ([string]$nextTurn.speakerId -ne 'host' -or [string]$nextTurn.type -ne 'conclusion' -or [string]$nextTurn.id -ne 'host-final') {
            $failures.Add(("Unanimous vote round {0} must continue from {1} to host-final." -f $i, $expectedResultId))
          }
        }
      }
      continue
    }

    $expectedRoundStartId = ('host-r{0}-start' -f $roundNumber)
    if ($voteTurnIndex + 1 -ge $turns.Count) {
      $failures.Add(("Non-unanimous vote round {0} must be followed by a host round-start turn." -f $i))
      continue
    }

    $roundStartTurn = $turns[$voteTurnIndex + 1]
    if ([string]$roundStartTurn.id -ne $expectedRoundStartId -or [string]$roundStartTurn.speakerId -ne 'host' -or [string]$roundStartTurn.type -ne 'control' -or [string]$roundStartTurn.phase -notmatch '发言') {
      $failures.Add(("Non-unanimous vote round {0} must be followed by {1}, a host round-start control turn." -f $i, $expectedRoundStartId))
      continue
    }

    $nextVoteTurnId = ('host-vote-{0}' -f ($roundNumber + 1))
    if (-not $turnIndexById.ContainsKey($nextVoteTurnId)) {
      $failures.Add(("Non-unanimous vote round {0} must eventually continue to {1}." -f $i, $nextVoteTurnId))
      continue
    }

    $nextVoteIndex = [int]$turnIndexById[$nextVoteTurnId]
    if ($nextVoteIndex -le $voteTurnIndex + 2) {
      $failures.Add(("Round {0} must contain at least one juror speech before {1}." -f $roundNumber, $nextVoteTurnId))
      continue
    }

    for ($turnIndex = $voteTurnIndex + 2; $turnIndex -lt $nextVoteIndex; $turnIndex++) {
      $speechTurn = $turns[$turnIndex]
      if ([string]$speechTurn.speakerId -eq 'host' -or [string]$speechTurn.type -ne 'speak') {
        $failures.Add(("Only juror speech turns may appear between {0} and {1}; bad turn index {2}." -f $expectedRoundStartId, $nextVoteTurnId, $turnIndex))
      }
    }
  }

  return [pscustomobject]@{
    ok = ($failures.Count -eq 0)
    failures = @($failures.ToArray())
  }
}

function Test-LiveRuntimeShellContract {
  param([object]$FullSession)

  $failures = New-Object System.Collections.Generic.List[string]
  $mode = [string]$FullSession.mode
  if ($mode -notin @('discussion', 'jury_deliberation')) {
    $failures.Add('Live meeting mode must be discussion or jury_deliberation.')
  }
  if ($mode -eq 'jury_deliberation') {
    if (-not [bool]$FullSession.deliberation.enabled) {
      $failures.Add('Jury live meeting deliberation must be enabled.')
    }
    if ([string]::IsNullOrWhiteSpace([string]$FullSession.deliberation.labelA) -or [string]::IsNullOrWhiteSpace([string]$FullSession.deliberation.labelB)) {
      $failures.Add('Jury live meeting must expose A/B labels before launch.')
    }
  }
  if ([string]$FullSession.generator -match 'new_visual_meeting_session') {
    $failures.Add('Live meeting must not be generated by the deterministic visual session template.')
  }
  if ([string]$FullSession.runtime.kind -ne 'main-process-live-meeting-runtime') {
    $failures.Add('Live meeting runtime kind must be main-process-live-meeting-runtime.')
  }

  $formalCount = @($FullSession.runtime.formalParticipants).Count
  $ambientCount = @($FullSession.runtime.ambientParticipants).Count
  if ($formalCount -lt 3) {
    $failures.Add('Live meeting must invite real formal participants.')
  }
  if (($formalCount + $ambientCount) -ne 10) {
    $failures.Add('Live meeting must fill exactly 10 visible seats with formal participants plus ambient states.')
  }

  return [pscustomobject]@{
    ok = $failures.Count -eq 0
    failures = @($failures.ToArray())
  }
}

function Get-ExpectedPagePattern {
  param([string]$Topic)

  $candidate = ($Topic -replace '\s+', ' ').Trim()
  if ($candidate.Contains(':')) {
    $candidate = $candidate.Split(':')[0].Trim()
  }
  if ($candidate.Contains([string](T '\uff1a'))) {
    $candidate = $candidate.Split([string](T '\uff1a'))[0].Trim()
  }

  $candidate = $candidate `
    -replace '项目优化讨论会', '优化会' `
    -replace '优化讨论会', '优化会' `
    -replace '讨论会', '会'

  if ($candidate.Length -gt 18) {
    $candidate = $candidate.Substring(0, 18)
  }

  if ([string]::IsNullOrWhiteSpace($candidate)) {
    $candidate = $Topic
    if ($candidate.Length -gt 18) {
      $candidate = $candidate.Substring(0, 18)
    }
  }

  return [regex]::Escape($candidate)
}

function Get-ViewerSessionFetchUrl {
  param(
    [string]$ViewerUrl,
    [string]$SessionUrl
  )

  if ($SessionUrl -match '^https?://') {
    return $SessionUrl
  }

  $baseUri = [System.Uri]::new(($ViewerUrl.TrimEnd('/') + '/'))
  return ([System.Uri]::new($baseUri, $SessionUrl)).AbsoluteUri
}

function Test-ViewerServesSession {
  param(
    [string]$ViewerUrl,
    [string]$SessionUrl,
    [object]$FullSession
  )

  $fetchUrl = Get-ViewerSessionFetchUrl -ViewerUrl $ViewerUrl -SessionUrl $SessionUrl
  $expectedId = [string]$FullSession.id
  $expectedTopic = [string]$FullSession.topic

  try {
    $response = Invoke-WebRequest -Uri $fetchUrl -UseBasicParsing -TimeoutSec 3
    $content = $response.Content
    if ($response.RawContentStream) {
      $response.RawContentStream.Position = 0
      $reader = [System.IO.StreamReader]::new($response.RawContentStream, [System.Text.Encoding]::UTF8, $true)
      $content = $reader.ReadToEnd()
      $reader.Dispose()
    }
    $content = $content.TrimStart([char]0xFEFF)
    $servedSession = $content | ConvertFrom-Json
    $servedId = [string]$servedSession.id
    $servedTopic = [string]$servedSession.topic
    $matches = if (-not [string]::IsNullOrWhiteSpace($expectedId)) {
      $servedId -eq $expectedId
    }
    else {
      $servedTopic -eq $expectedTopic
    }

    return [pscustomobject]@{
      ok = $true
      matches = [bool]$matches
      url = $fetchUrl
      expectedId = $expectedId
      servedId = $servedId
      expectedTopic = $expectedTopic
      servedTopic = $servedTopic
      message = if ($matches) { 'Prepared meeting session is being served.' } else { 'Viewer is serving a different meeting session.' }
    }
  }
  catch {
    return [pscustomobject]@{
      ok = $false
      matches = $false
      url = $fetchUrl
      expectedId = $expectedId
      servedId = ''
      expectedTopic = $expectedTopic
      servedTopic = ''
      message = $_.Exception.Message
    }
  }
}

function New-CodexStartMessage {
  param(
    [object]$FullSession,
    [string]$Url,
    [bool]$ViewerReady = $false
  )

  $participantLines = New-Object System.Collections.Generic.List[string]
  foreach ($roleId in @(Get-VisibleMeetingParticipantIds -FullSession $FullSession)) {
    $participantLines.Add((Get-SessionRoleLine -FullSession $FullSession -RoleId ([string]$roleId)))
  }

  return @(
    ('{0}{1}' -f $Text.MeetingTopic, (ConvertTo-UserSafeText $FullSession.topic)),
    ('{0}{1}' -f $Text.Participants, ($participantLines -join $Text.ListSep)),
    '',
    $(if ($ViewerReady) { $Text.VisualOptional } else { $Text.VisualUnavailable }),
    $(if ($ViewerReady) { ('[打开可视化会议]({0})（手动点击打开）' -f $Url) } else { '' }),
    '',
    $Text.TextTranscript
  ) -join "`n"
}

function New-CodexLaunchBlockedMessage {
  param(
    [object]$FullSession,
    [string]$Url
  )

  $participantLines = New-Object System.Collections.Generic.List[string]
  foreach ($roleId in @(Get-VisibleMeetingParticipantIds -FullSession $FullSession)) {
    $participantLines.Add((Get-SessionRoleLine -FullSession $FullSession -RoleId ([string]$roleId)))
  }

  return @(
    ('{0}{1}' -f $Text.MeetingTopic, (ConvertTo-UserSafeText $FullSession.topic)),
    ('{0}{1}' -f $Text.Participants, ($participantLines -join $Text.ListSep)),
    '',
    $Text.LaunchBlocked,
    '',
    $Text.BrowserWarning,
    $Text.NoTextFallback
  ) -join "`n"
}

function New-CodexFinalMessage {
  param(
    [object]$FullSession
  )

  $summary = $FullSession.summary
  $consensusLines = ConvertTo-LimitedLines -Items @($summary.consensus) -Formatter { param($item) ('- {0}' -f (ConvertTo-UserSafeText $item)) } -Limit 2
  $planLines = ConvertTo-LimitedLines -Items @($summary.implementationPlan) -Formatter {
    param($item)
    $owner = Get-SessionRoleLine -FullSession $FullSession -RoleId ([string]$item.owner)
    $itemId = ConvertTo-UserSafeText $item.id
    if ([string]::IsNullOrWhiteSpace($itemId)) {
      $itemId = '步骤'
    }
    '- [{0}] {1}{2}{3}{4}{5}{6}' -f $itemId, (ConvertTo-UserSafeText $item.title), $Text.Deliverable, (ConvertTo-UserSafeText $item.deliverable), $Text.Owner, $owner, ($Text.Acceptance + (ConvertTo-UserSafeText $item.acceptance))
  } -Limit 3
  $workerLines = ConvertTo-LimitedLines -Items @($summary.recommendedWorkers) -Formatter {
    param($worker)
    '- {0}{1}{2}{3}{4}{5}{6}{7}' -f (ConvertTo-UserSafeText $worker.name), $Text.LeftParen, (ConvertTo-UserSafeText $worker.title), $Text.Slash, (ConvertTo-UserSafeText $worker.priority), $Text.RightParen, $Text.WorkerTaskSep, ((ConvertTo-UserSafeText $worker.task) + $Text.WorkerDeliverable + (ConvertTo-UserSafeText $worker.deliverable))
  } -Limit 3

  return @(
    $Text.Conclusion,
    ($consensusLines -join "`n"),
    '',
    $Text.Plan,
    ($planLines -join "`n"),
    '',
    $Text.Workers,
    ($workerLines -join "`n"),
    '',
    $Text.ExecutionChoice,
    $Text.DirectExecution,
    $Text.SubAgentExecution
  ) -join "`n"
}

function ConvertTo-ProcessArgumentString {
  param([string[]]$Arguments)

  return ($Arguments | ForEach-Object {
    $value = [string]$_
    if ($value -match '[\s"]') {
      '"' + ($value -replace '"', '\"') + '"'
    }
    else {
      $value
    }
  }) -join ' '
}

if ($SessionFile) {
  $sourceSessionFile = [System.IO.Path]::GetFullPath($SessionFile)
  if (-not (Test-Path -LiteralPath $sourceSessionFile)) {
    throw "SessionFile does not exist: $sourceSessionFile"
  }

  if ($sourceSessionFile -ne $defaultSessionFile) {
    Copy-Item -LiteralPath $sourceSessionFile -Destination $defaultSessionFile -Force
  }

  $session = [pscustomobject]@{
    ok = $true
    topic = ''
    participant_count = 0
    participants = @()
    out_file = $defaultSessionFile
    session_url = 'current-session.json'
    source = 'session_file'
  }
} elseif ($UseCurrentSession) {
  if (-not (Test-Path -LiteralPath $defaultSessionFile)) {
    throw "Current session does not exist: $defaultSessionFile"
  }

  $session = [pscustomobject]@{
    ok = $true
    topic = ''
    participant_count = 0
    participants = @()
    out_file = $defaultSessionFile
    session_url = 'current-session.json'
    source = 'current_session'
  }
} else {
  if (-not $Topic) {
    throw 'Topic is required unless -UseCurrentSession or -SessionFile is provided.'
  }

  if ($DisableLiveRuntime) {
    throw 'DisableLiveRuntime is no longer supported for the user-facing meeting entrance. The only supported entrance is main-process live.'
  }

  if (-not (Test-Path -LiteralPath $initializeLiveScript)) {
    throw "Live initializer does not exist: $initializeLiveScript"
  }

  $session = & $initializeLiveScript -Topic $Topic -Mode $Mode -ParticipantCount $ParticipantCount -SkillRoot $SkillRoot -OutFile $defaultRuntimeFile | ConvertFrom-Json
}

$fullSession = Get-Content -LiteralPath ([string]$session.out_file) -Raw -Encoding UTF8 | ConvertFrom-Json
$session.topic = [string]$fullSession.topic
$formalVisibleIds = @(Get-VisibleMeetingParticipantIds -FullSession $fullSession | Where-Object { $_ -ne 'host' })
$session.participant_count = $formalVisibleIds.Count
$session.participants = $formalVisibleIds
$messageSession = $fullSession
$juryContract = if ([string]$session.source -eq 'main_process_live') {
  Test-LiveRuntimeShellContract -FullSession $fullSession
}
else {
  Test-JurySessionContract -FullSession $fullSession
}

if (-not $juryContract.ok) {
  $failureLines = @($juryContract.failures | ForEach-Object { '- ' + $_ })
  $blockedMessage = @(
    'REPORT_CONFLICT：陪审团会议结构校验失败',
    '',
    '会议页未启动。已按“禁止兜底”规则中断：不输出文字模拟会议、不输出会议结论。',
    '',
    '失败项：',
    ($failureLines -join "`n")
  ) -join "`n"

  [pscustomobject]@{
    ok = $false
    session = $session
    juryContract = $juryContract
    hardStartRequired = $true
    textFallbackAllowed = $false
    codexStartMessage = ''
    codexLaunchBlockedMessage = $blockedMessage
    codexFinalMessage = ''
    codexMessage = $blockedMessage
  } | ConvertTo-Json -Depth 8
  return
}

$reloadStamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$sessionUrl = [string]$session.session_url
if ([string]::IsNullOrWhiteSpace($sessionUrl)) {
  $sessionUrl = 'current-session.json'
}
$viewer = $null
$servedSession = $null
$viewerAttempts = New-Object System.Collections.Generic.List[object]

for ($portOffset = 0; $portOffset -le 8; $portOffset++) {
  $candidatePort = $Port + $portOffset
  $candidateViewer = & $startViewerScript -Port $candidatePort | ConvertFrom-Json
  $candidateCheck = [pscustomobject]@{
    ok = $false
    matches = $false
    url = ''
    expectedId = [string]$fullSession.id
    servedId = ''
    expectedTopic = [string]$fullSession.topic
    servedTopic = ''
    message = 'Viewer did not start.'
  }

  if ($candidateViewer.ok) {
    $candidateCheck = Test-ViewerServesSession -ViewerUrl ([string]$candidateViewer.url) -SessionUrl $sessionUrl -FullSession $fullSession
  }

  $viewerAttempts.Add([pscustomobject]@{
    port = $candidatePort
    viewer = $candidateViewer
    sessionCheck = $candidateCheck
  })

  if ($candidateViewer.ok -and $candidateCheck.matches) {
    $viewer = $candidateViewer
    $servedSession = $candidateCheck
    break
  }
}

if (-not $viewer) {
  $lastAttempt = $viewerAttempts[$viewerAttempts.Count - 1]
  $viewer = $lastAttempt.viewer
  $servedSession = $lastAttempt.sessionCheck
}

$sessionIsServed = [bool]($servedSession -and $servedSession.matches)
$viewerUrl = [string]$viewer.url
$selectedViewerPort = $Port
try {
  $selectedViewerPort = ([System.Uri]$viewerUrl).Port
}
catch {
  $selectedViewerPort = $Port
}
$viewerSessionUrl = ('{0}/?session={1}&reload={2}' -f $viewerUrl.TrimEnd('/'), [uri]::EscapeDataString($sessionUrl), $reloadStamp)
$codexStartMessage = New-CodexStartMessage -FullSession $fullSession -Url $viewerSessionUrl -ViewerReady $sessionIsServed
$codexLaunchBlockedMessage = New-CodexLaunchBlockedMessage -FullSession $fullSession -Url $viewerSessionUrl
$summaryObject = $messageSession.summary
$consensusCount = if ($summaryObject -and $summaryObject.PSObject.Properties['consensus']) {
  @($summaryObject.consensus | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count
}
else { 0 }
$planCount = if ($summaryObject -and $summaryObject.PSObject.Properties['implementationPlan']) {
  @($summaryObject.implementationPlan | Where-Object { $_ }).Count
}
else { 0 }
$workerCount = if ($summaryObject -and $summaryObject.PSObject.Properties['recommendedWorkers']) {
  @($summaryObject.recommendedWorkers | Where-Object { $_ }).Count
}
else { 0 }
$hasFinalSummary = [bool]($consensusCount -gt 0 -or $planCount -gt 0 -or $workerCount -gt 0)
$codexFinalMessage = if ($hasFinalSummary) { New-CodexFinalMessage -FullSession $messageSession } else { '' }
$browserOpenStrategy = 'manual_link_only'
$linkClick = [pscustomobject]@{
  ok = $sessionIsServed
  mode = $browserOpenStrategy
  url = $viewerSessionUrl
  linkText = '打开可视化会议'
  script = ''
  message = if ($sessionIsServed) {
    'Meeting viewer is ready. Output codexStartMessage and let the user decide whether to click the visual-meeting link.'
  }
  else {
    'Prepared meeting session is not being served by the viewer. Continue with the text meeting without exposing a stale visual link.'
  }
}
$browserOpened = $false

[pscustomobject]@{
  ok = [bool]$session.ok
  session = $session
  viewer = $viewer
  servedSession = $servedSession
  viewerAttempts = @($viewerAttempts.ToArray())
  linkClick = $linkClick
  browserOpenStrategy = $browserOpenStrategy
  browserOpened = $browserOpened
  currentBrowserUrl = $viewerSessionUrl
  clickableLinkRequired = [bool]$sessionIsServed
  viewerLinkText = '打开可视化会议'
  viewerLinkOptional = $true
  url = $viewerUrl
  hardStartRequired = $false
  textFallbackAllowed = $true
  codexStartMessage = $codexStartMessage
  codexLaunchBlockedMessage = $codexLaunchBlockedMessage
  codexFinalMessage = $codexFinalMessage
  codexMessage = $codexStartMessage
} | ConvertTo-Json -Depth 8

