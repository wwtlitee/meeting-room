param(
  [string]$SkillRoot = '',
  [string]$WorkspaceRoot = '',
  [string]$GlobalSkillsRoot = '',
  [string]$ActivationNotice = '会议室 skill已触发～喵'
)

$ErrorActionPreference = 'Stop'

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
if (-not $WorkspaceRoot) {
  $WorkspaceRoot = Split-Path -Parent $SkillRoot
}
$WorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot)

if (-not $GlobalSkillsRoot) {
  $GlobalSkillsRoot = Join-Path $env:USERPROFILE '.codex\skills'
}
$GlobalSkillsRoot = [System.IO.Path]::GetFullPath($GlobalSkillsRoot)

$skillFile = Join-Path $SkillRoot 'SKILL.md'
$startScript = Join-Path $SkillRoot 'scripts\start_expert_panel_meeting.ps1'
$newSessionScript = Join-Path $SkillRoot 'scripts\new_visual_meeting_session.ps1'
$liveRuntimeScript = Join-Path $SkillRoot 'runtime\run_live_meeting.ps1'
$initializeLiveScript = Join-Path $SkillRoot 'runtime\initialize_live_meeting.ps1'
$setThinkingScript = Join-Path $SkillRoot 'runtime\set_live_meeting_thinking.ps1'
$appendLiveTurnScript = Join-Path $SkillRoot 'runtime\append_live_meeting_turn.ps1'
$appendPersonaMemoryScript = Join-Path $SkillRoot 'runtime\append_meeting_persona_memory.ps1'
$importTextMeetingScript = Join-Path $SkillRoot 'runtime\import_text_meeting_result.ps1'
$clickLinkScript = Join-Path $SkillRoot 'scripts\click_latest_meeting_link.ps1'
$viewerAppFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\react-viewer\src\App.jsx'
$viewerStyleFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\react-viewer\src\styles.css'
$currentSessionFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\current-session.json'
$runtimeSessionFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json'
$roleNameZhFile = Join-Path $SkillRoot 'references\ROLE_NAME_ZH.md'
$removedInAppScript = Join-Path $SkillRoot 'scripts\open_inapp_browser_url.ps1'
$workspaceAgents = Join-Path $WorkspaceRoot 'AGENTS.md'
$deepseekSkill = Join-Path $GlobalSkillsRoot 'deepseek-plan-debate'
$oldAgencyAgentsSkill = Join-Path $GlobalSkillsRoot 'agency-agents'

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
  param(
    [string]$Id,
    [bool]$Ok,
    [string]$Message
  )

  $script:checks.Add([pscustomobject]@{
    id = $Id
    ok = $Ok
    message = $Message
  })
}

function Get-DisplayWidthUnits {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return 0.0
  }

  $units = 0.0
  $indexes = [System.Globalization.StringInfo]::ParseCombiningCharacters($Text)
  for ($i = 0; $i -lt $indexes.Length; $i++) {
    $start = $indexes[$i]
    $length = if ($i -lt $indexes.Length - 1) { $indexes[$i + 1] - $start } else { $Text.Length - $start }
    $glyph = $Text.Substring($start, $length)

    if ($glyph -match '^[\u0000-\u007F]$' -or $glyph -match '^[\uFF61-\uFFDC\uFFE8-\uFFEE]$') {
      $units += 0.5
    }
    else {
      $units += 1.0
    }
  }

  return [Math]::Round($units, 2)
}

if (-not (Test-Path -LiteralPath $skillFile)) {
  throw "Missing SKILL.md: $skillFile"
}
if (-not (Test-Path -LiteralPath $startScript)) {
  throw "Missing start script: $startScript"
}
if (-not (Test-Path -LiteralPath $clickLinkScript)) {
  throw "Missing click link script: $clickLinkScript"
}
if (-not (Test-Path -LiteralPath $roleNameZhFile)) {
  throw "Missing role Chinese name map: $roleNameZhFile"
}

$skillText = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
$startText = Get-Content -LiteralPath $startScript -Raw -Encoding UTF8
$newSessionText = Get-Content -LiteralPath $newSessionScript -Raw -Encoding UTF8
$liveRuntimeText = Get-Content -LiteralPath $liveRuntimeScript -Raw -Encoding UTF8
$initializeLiveText = if (Test-Path -LiteralPath $initializeLiveScript) { Get-Content -LiteralPath $initializeLiveScript -Raw -Encoding UTF8 } else { '' }
$setThinkingText = if (Test-Path -LiteralPath $setThinkingScript) { Get-Content -LiteralPath $setThinkingScript -Raw -Encoding UTF8 } else { '' }
$appendLiveTurnText = if (Test-Path -LiteralPath $appendLiveTurnScript) { Get-Content -LiteralPath $appendLiveTurnScript -Raw -Encoding UTF8 } else { '' }
$appendPersonaMemoryText = if (Test-Path -LiteralPath $appendPersonaMemoryScript) { Get-Content -LiteralPath $appendPersonaMemoryScript -Raw -Encoding UTF8 } else { '' }
$importTextMeetingText = if (Test-Path -LiteralPath $importTextMeetingScript) { Get-Content -LiteralPath $importTextMeetingScript -Raw -Encoding UTF8 } else { '' }
$clickText = Get-Content -LiteralPath $clickLinkScript -Raw -Encoding UTF8
$viewerAppText = Get-Content -LiteralPath $viewerAppFile -Raw -Encoding UTF8
$viewerStyleText = Get-Content -LiteralPath $viewerStyleFile -Raw -Encoding UTF8
$roleNameZhText = Get-Content -LiteralPath $roleNameZhFile -Raw -Encoding UTF8
$agentsText = if (Test-Path -LiteralPath $workspaceAgents) {
  Get-Content -LiteralPath $workspaceAgents -Raw -Encoding UTF8
}
else {
  ''
}

$requiredTerms = @(
  '会议室',
  'meeting room',
  '专家团',
  '会议skill',
  '会议 skill',
  '专家团开会',
  '开会',
  '开个会',
  '专家团会议',
  '陪审团',
  '陪审团会议',
  '陪审模式',
  '12怒汉',
  '十二怒汉',
  '多角色讨论',
  '多智能体讨论',
  'expert panel',
  'jury deliberation'
)

Add-Check 'skill-frontmatter-name' ($skillText -match '(?m)^name:\s*meeting-room\s*$') 'SKILL.md frontmatter name must be meeting-room.'
Add-Check 'skill-highest-priority-description' ($skillText -match 'Highest-priority meeting-room trigger' -and $skillText -match 'MUST use this skill') 'Description must advertise highest-priority meeting-room routing.'
Add-Check 'activation-notice-present' ($skillText.Contains($ActivationNotice)) 'SKILL.md must contain the exact activation notice.'
$activationFirstStep = '1. Output the activation notice first: `' + $ActivationNotice + '`.'
Add-Check 'activation-notice-first-step' ($skillText.Contains($activationFirstStep)) 'Function 1 first step must output the activation notice.'
Add-Check 'no-deepseek-routing' ($skillText -match 'Do not route to `deepseek-plan-debate`') 'Meeting requests must not route to deepseek-plan-debate.'
Add-Check 'single-meeting-entrance-rule' ($skillText.Contains('there is only one meeting entrance') -and $skillText.Contains('Do not ask the user to choose `普通会议` or `陪审团会议`')) 'SKILL.md must define a single user-facing meeting entrance.'
Add-Check 'no-mode-select-state' ($skillText -notmatch '`mode_select`' -and $skillText -notmatch 'Ask meeting mode') 'SKILL.md must not keep the old user-facing meeting-mode selection state.'
Add-Check 'old-mode-prompt-forbidden' ($skillText.Contains('The old prompt is forbidden')) 'SKILL.md must explicitly forbid the old 普通会议/陪审团会议 prompt.'
Add-Check 'roundtable-chain-removed' ($skillText -notmatch 'roundtable|圆桌会议' -and $startText -notmatch 'roundtable' -and $newSessionText -notmatch 'roundtable|host-roundtable' -and $liveRuntimeText -notmatch 'roundtable' -and $viewerAppText -notmatch "mode:\s*.*roundtable|mode\s*:\s*session\.mode\s*\|\|\s*'roundtable'") 'Roundtable user-facing and script chains must be removed.'

$missingTerms = @($requiredTerms | Where-Object { -not $skillText.Contains($_) })
Add-Check 'trigger-term-coverage' ($missingTerms.Count -eq 0) ('Missing trigger terms: {0}' -f (($missingTerms -join ', ') -replace '^$', 'none'))

Add-Check 'viewer-optional-field' ($startText -match 'hardStartRequired\s*=\s*\$false') 'Start script must expose hardStartRequired=false for the default path.'
Add-Check 'text-meeting-primary-field' ($startText -match 'textFallbackAllowed\s*=\s*\$true') 'Start script must expose textFallbackAllowed=true for the default path.'
Add-Check 'start-default-discussion' ($startText -match '\[string\]\$Mode\s*=\s*''discussion''' -and $startText -match 'main-process live') 'Start script must default to the single-entry discussion live path.'
Add-Check 'main-process-live-initializer-present' ((Test-Path -LiteralPath $initializeLiveScript) -and $initializeLiveText -match 'main-process-live-meeting-runtime' -and $initializeLiveText -match 'formalParticipants' -and $initializeLiveText -match 'ambientParticipants' -and $initializeLiveText -match 'turns = @\(\)') 'Live initializer must create an empty main-process runtime shell with formal plus ambient seats.'
Add-Check 'main-process-live-thinking-sync-present' ((Test-Path -LiteralPath $setThinkingScript) -and $setThinkingText -match 'pendingSpeaker' -and $setThinkingText -match 'requiresPersonaRead' -and $setThinkingText -match 'requiresRuntimeRead' -and $setThinkingText -match 'Host control turns are fixed-flow turns' -and $viewerAppText -match 'getMeetingPendingTurn' -and $viewerAppText -match 'pendingSpeaker') 'Live runtime must sync only non-host pre-speech generation windows to the viewer before appending a turn.'
Add-Check 'main-process-live-append-present' ((Test-Path -LiteralPath $appendLiveTurnScript) -and $appendLiveTurnText -match 'append_live_meeting_turn' -and $appendLiveTurnText -match 'VotesJson' -and $appendLiveTurnText -match 'SummaryJson' -and $appendLiveTurnText -match "'control'") 'Live append script must support main-process turn, vote, host control, and summary writes.'
Add-Check 'persona-memory-auto-append' ((Test-Path -LiteralPath $appendPersonaMemoryScript) -and $appendLiveTurnText -match 'Append-PersonaMemoryForTurn' -and $appendLiveTurnText -match 'append_meeting_persona_memory\.ps1' -and $appendPersonaMemoryText -match 'memory_entries:start') 'Every non-host live meeting turn with a persona store must be appended to that persona memory.md by default.'
Add-Check 'text-import-preserves-jury-votes' ((Test-Path -LiteralPath $importTextMeetingScript) -and $importTextMeetingText -match 'VoteRoundsJson' -and $importTextMeetingText -match 'DeliberationJson' -and $importTextMeetingText -match 'Test-ImportedVoteRounds' -and $importTextMeetingText -notmatch '\$session\.deliberation\.voteRounds\s*=\s*@\(\)') 'Text meeting import must support jury voteRounds/deliberation payloads instead of always erasing A/B vote state.'
Add-Check 'live-vote-normalization-contract' ($appendLiveTurnText -match 'Get-VoteVoterRoleIds' -and $appendLiveTurnText -match 'Resolve-VoteForRole' -and $appendLiveTurnText -match 'Get-DominantExplicitFormalVoteSide' -and $initializeLiveText -match "vote = 'agree'") 'Live vote rounds must normalize all visible non-host voters and make nod/对对对 follow the current formal majority instead of hardcoding A or B.'
Add-Check 'viewer-vote-normalization-contract' ($viewerAppText -match 'getMeetingVoterIds' -and $viewerAppText -match 'getAmbientDefaultVoteSide' -and $viewerAppText -match 'getDominantExplicitFormalVoteSide' -and $viewerAppText -match 'getJuryVotesForRound\(activeMeeting') 'Viewer vote counts must use the same all-visible-voter normalization as runtime vote rounds.'
Add-Check 'ambient-speaking-state-contract' ($skillText -match 'not mute placeholders' -and $skillText -match '对对对' -and $skillText -match '`nod`' -and $skillText -match '`reserve`' -and $skillText -match '`thinking`' -and $initializeLiveText -match 'Get-AmbientStateProfile' -and $initializeLiveText -match 'canSpeak = \$true' -and $initializeLiveText -match '\\u5bf9\\u5bf9\\u5bf9' -and $appendLiveTurnText -match 'Get-SpeakingAmbientRoleIds' -and $appendLiveTurnText -match 'ambient_ready') 'Ambient states nod/reserve/thinking must be first-class speaking ambient personas, not silent filler.'
Add-Check 'viewer-no-outcome-panel' ($viewerAppText -notmatch 'MeetingOutcomePanel|meeting-outcome|会议产物' -and $viewerStyleText -notmatch 'meeting-outcome|outcome-heading|plan-grid|worker-grid|future-animation-note') 'Viewer must not render a meeting-products panel; post-meeting outcomes belong in Codex chat.'
Add-Check 'viewer-transcript-progressive-reveal' ($viewerAppText -match 'visibleTurns\s*=\s*useMemo' -and $viewerAppText -match 'meetingTurns\.slice\(0' -and $viewerAppText -match 'visibleTurns\.map') 'Viewer transcript must reveal only current and past turns, never future conclusions during playback.'
Add-Check 'default-path-no-template-generator' ($startText -notmatch 'newSessionScript|&\s*\$newSessionScript|scripts\\new_visual_meeting_session\.ps1' -and $startText -match 'initialize_live_meeting\.ps1' -and $startText -match 'Test-LiveRuntimeShellContract') 'Default meeting launch path must initialize live state, not generate a full scripted session.'
Add-Check 'launch-blocked-message' ($startText -match 'codexLaunchBlockedMessage') 'Start script must return codexLaunchBlockedMessage.'
Add-Check 'served-session-identity-guard' ($startText -match 'Test-ViewerServesSession' -and $startText -match 'servedSession' -and $startText -match 'sessionIsServed') 'Start script must verify served session identity before reporting success.'
Add-Check 'jury-session-contract-guard' ($startText -match 'Test-JurySessionContract' -and $startText -match 'First host vote-control turn must immediately follow the opening host turn' -and $startText -match 'Final jury vote must be unanimous before the host summary turn') 'Start script must block malformed jury sessions before opening the viewer.'
Add-Check 'click-link-script-present' (Test-Path -LiteralPath $clickLinkScript) 'Legacy/manual click_latest_meeting_link.ps1 helper may remain in the skill package.'
Add-Check 'old-inapp-script-removed' (-not (Test-Path -LiteralPath $removedInAppScript)) 'Old open_inapp_browser_url.ps1 side-panel/URL-entry script must be removed.'
Add-Check 'manual-viewer-link-default' ($startText -match 'manual_link_only' -and $startText -match 'viewerLinkText' -and $startText -match 'viewerLinkOptional') 'Start script must expose a manual optional viewer link instead of auto-clicking it.'
Add-Check 'no-auto-click-after-message' ($skillText -notmatch 'must run `scripts/click_latest_meeting_link\.ps1`' -and $skillText -notmatch 'call `autoClickScript`') 'SKILL.md must not require auto-clicking the rendered meeting link.'
Add-Check 'no-url-entry-automation' ($startText -notmatch 'UseInAppAutomation|openInApp|OpenDefaultBrowserAfterInAppFailure|UrlEdit|SetValue') 'Start script must not contain URL-entry or side-panel automation.'
Add-Check 'blocked-message-no-sidebar-assumption' ($startText -notmatch '\\u53f3\\u4fa7\\u6d4f\\u89c8\\u5668') 'Visual-unavailable message must not blame right-sidebar browser state.'
Add-Check 'click-script-minimal-target' ($clickText -match 'Find-LatestMeetingLink') 'If kept, the click helper must stay a minimal latest-link invoker.'
$clickScriptForbiddenTerms = @('UrlEdit', 'SetValue', 'Ctrl+Alt+B', '^%b')
$clickScriptForbiddenHits = @($clickScriptForbiddenTerms | Where-Object { $clickText.Contains($_) })
Add-Check 'click-script-no-url-entry' ($clickScriptForbiddenHits.Count -eq 0) ('Click script must not type URLs or toggle browser side panels. Forbidden hits: {0}' -f (($clickScriptForbiddenHits -join ', ') -replace '^$', 'none'))

$roleNameRows = New-Object System.Collections.Generic.List[object]
foreach ($line in ($roleNameZhText -split "`r?`n")) {
  if ($line -notmatch '^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$') {
    continue
  }

  $division = $matches[1].Trim()
  $name = $matches[2].Trim()
  $zh = $matches[3].Trim()
  if ($division -in @(':---', '分组') -or $name -in @(':---', '原名')) {
    continue
  }

  $roleNameRows.Add([pscustomobject]@{
    division = $division
    name = $name
    zh = $zh
    widthUnits = Get-DisplayWidthUnits $zh
  })
}
$roleNameOverLimit = @($roleNameRows | Where-Object { $_.widthUnits -gt 6.0 })
$roleNameEmpty = @($roleNameRows | Where-Object { [string]::IsNullOrWhiteSpace($_.zh) })
Add-Check 'role-name-map-count' ($roleNameRows.Count -eq 260) ('ROLE_NAME_ZH.md must keep 260 role rows. Current rows: {0}' -f $roleNameRows.Count)
Add-Check 'role-name-map-nonempty' ($roleNameEmpty.Count -eq 0) ('ROLE_NAME_ZH.md display aliases must not be empty. Empty rows: {0}' -f $roleNameEmpty.Count)
Add-Check 'role-name-map-six-char-limit' ($roleNameOverLimit.Count -eq 0) ('ROLE_NAME_ZH.md display aliases must be <= 6 width units. Over-limit rows: {0}' -f (($roleNameOverLimit | ForEach-Object { '{0}/{1}:{2}({3})' -f $_.division, $_.name, $_.zh, $_.widthUnits }) -join ', '))

if ($agentsText) {
  Add-Check 'workspace-agents-notice' ($agentsText.Contains($ActivationNotice)) 'Workspace AGENTS.md must contain the exact activation notice.'
  Add-Check 'workspace-agents-skill-rule' ($agentsText -match '必须使用全局 `meeting-room` skill') 'Workspace AGENTS.md must require meeting-room for meeting triggers.'
  Add-Check 'workspace-agents-single-entrance' ($agentsText -match '唯一会议入口' -and $agentsText -match '不得再询问') 'Workspace AGENTS.md must enforce the single meeting entrance.'
  Add-Check 'workspace-agents-text-primary' ($agentsText -match '文字版会议' -or $agentsText -match '继续文字会议') 'Workspace AGENTS.md must describe text meeting as the primary flow.'
}
else {
  Add-Check 'workspace-agents-present' $false "Workspace AGENTS.md not found: $workspaceAgents"
}

Add-Check 'deepseek-skill-removed' (-not (Test-Path -LiteralPath $deepseekSkill)) "deepseek-plan-debate skill must be absent at $deepseekSkill"
Add-Check 'old-agency-agents-skill-removed' (-not (Test-Path -LiteralPath $oldAgencyAgentsSkill)) "Old agency-agents skill must be absent after rename: $oldAgencyAgentsSkill"

if (Test-Path -LiteralPath $runtimeSessionFile) {
  $runtimeSession = [System.IO.File]::ReadAllText($runtimeSessionFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  $formalCount = @($runtimeSession.runtime.formalParticipants).Count
  $ambientCount = @($runtimeSession.runtime.ambientParticipants).Count
  Add-Check 'runtime-session-main-process-live' ([string]$runtimeSession.runtime.kind -eq 'main-process-live-meeting-runtime' -and [string]$runtimeSession.generator -notmatch 'new_visual_meeting_session') 'Current runtime session must be main-process live, not a scripted visual template.'
  Add-Check 'runtime-session-seat-fill' (($formalCount + $ambientCount) -eq 10 -and $formalCount -ge 3) ('Runtime session must fill 10 seats with formal plus ambient participants. formal={0}; ambient={1}' -f $formalCount, $ambientCount)
  $runtimeDiscussionOk = ([string]$runtimeSession.mode -eq 'discussion' -and -not [bool]$runtimeSession.deliberation.enabled)
  $runtimeJuryOk = ([string]$runtimeSession.mode -eq 'jury_deliberation' -and [bool]$runtimeSession.deliberation.enabled -and -not [string]::IsNullOrWhiteSpace([string]$runtimeSession.deliberation.labelA) -and -not [string]::IsNullOrWhiteSpace([string]$runtimeSession.deliberation.labelB))
  Add-Check 'runtime-session-mode-contract' ($runtimeDiscussionOk -or $runtimeJuryOk) 'Runtime session must be discussion without vote UI or jury_deliberation with visible A/B options.'

  $roleMetaRows = @()
  foreach ($property in $runtimeSession.roleMeta.PSObject.Properties) {
    $displayName = [string]$property.Value.name
    $roleMetaRows += [pscustomobject]@{
      roleId = [string]$property.Name
      name = $displayName
      widthUnits = Get-DisplayWidthUnits $displayName
    }
  }
  $roleMetaOverLimit = @($roleMetaRows | Where-Object { $_.roleId -ne 'host' -and $_.widthUnits -gt 6.0 })
  Add-Check 'runtime-session-rolemeta-short-names' ($roleMetaOverLimit.Count -eq 0) ('Runtime session roleMeta names must be <= 6 width units. Over-limit names: {0}' -f (($roleMetaOverLimit | ForEach-Object { '{0}:{1}({2})' -f $_.roleId, $_.name, $_.widthUnits }) -join ', '))

  $runtimeTurns = @($runtimeSession.turns)
  $runtimeVotes = @($runtimeSession.deliberation.voteRounds)
  if ($runtimeTurns.Count -gt 0 -and $runtimeVotes.Count -gt 0) {
    $runtimeFlowFailures = New-Object System.Collections.Generic.List[string]
    if ([string]$runtimeTurns[0].speakerId -ne 'host') {
      $runtimeFlowFailures.Add('first turn is not host')
    }

    $turnIndexById = @{}
    for ($i = 0; $i -lt $runtimeTurns.Count; $i++) {
      $id = [string]$runtimeTurns[$i].id
      if ($id) { $turnIndexById[$id] = $i }
    }

    if (-not $turnIndexById.ContainsKey('host-vote-1') -or [int]$turnIndexById['host-vote-1'] -ne 1) {
      $runtimeFlowFailures.Add('host-vote-1 is not immediately after opening')
    }

    for ($i = 0; $i -lt $runtimeVotes.Count; $i++) {
      $roundNo = $i + 1
      $expectedVoteId = 'host-vote-{0}' -f $roundNo
      $afterTurnId = [string]$runtimeVotes[$i].afterTurnId
      if ($afterTurnId -ne $expectedVoteId) {
        $runtimeFlowFailures.Add(("vote round {0} points to {1}, expected {2}" -f $roundNo, $afterTurnId, $expectedVoteId))
        continue
      }
      if (-not $turnIndexById.ContainsKey($expectedVoteId)) {
        $runtimeFlowFailures.Add(("missing {0}" -f $expectedVoteId))
        continue
      }

      $voteIndex = [int]$turnIndexById[$expectedVoteId]
      $voteValues = @($runtimeVotes[$i].votes.PSObject.Properties | ForEach-Object { [string]$_.Value } | Where-Object { $_ -in @('a', 'b') } | Sort-Object -Unique)
      $isUnanimous = $voteValues.Count -eq 1
      if ($isUnanimous) {
        $expectedResultId = 'host-r{0}-result' -f $roundNo
        if ($voteIndex + 1 -ge $runtimeTurns.Count -or [string]$runtimeTurns[$voteIndex + 1].id -ne $expectedResultId -or [string]$runtimeTurns[$voteIndex + 1].type -ne 'control') {
          $runtimeFlowFailures.Add(("unanimous {0} is not followed by {1} control" -f $expectedVoteId, $expectedResultId))
        }
        if ($voteIndex + 2 -ge $runtimeTurns.Count -or [string]$runtimeTurns[$voteIndex + 2].id -ne 'host-final' -or [string]$runtimeTurns[$voteIndex + 2].type -ne 'conclusion') {
          $runtimeFlowFailures.Add(("unanimous {0} is not followed by host-final conclusion" -f $expectedVoteId))
        }
      }
      else {
        $expectedStartId = 'host-r{0}-start' -f $roundNo
        $nextVoteId = 'host-vote-{0}' -f ($roundNo + 1)
        if ($voteIndex + 1 -ge $runtimeTurns.Count -or [string]$runtimeTurns[$voteIndex + 1].id -ne $expectedStartId -or [string]$runtimeTurns[$voteIndex + 1].type -ne 'control') {
          $runtimeFlowFailures.Add(("non-unanimous {0} is not followed by {1} control" -f $expectedVoteId, $expectedStartId))
        }
        if (-not $turnIndexById.ContainsKey($nextVoteId)) {
          $runtimeFlowFailures.Add(("non-unanimous {0} does not continue to {1}" -f $expectedVoteId, $nextVoteId))
        }
      }
    }

    Add-Check 'runtime-session-fixed-host-q-flow' ($runtimeFlowFailures.Count -eq 0) ('Current runtime with turns must preserve fixed host Q-flow. Failures: {0}' -f (($runtimeFlowFailures.ToArray() -join '; ') -replace '^$', 'none'))
  }
}
else {
  Add-Check 'runtime-session-present' $false "Runtime session file not found: $runtimeSessionFile"
}

Add-Check 'skill-text-meeting-primary' ($skillText -match 'text meeting as the primary delivery surface' -and $skillText -match 'do not auto-open it') 'SKILL.md must define the text meeting as primary and the viewer as optional.'
Add-Check 'skill-visual-link-copy' ($skillText -match '\[打开可视化会议\]' -and $skillText -match '手动点击打开') 'SKILL.md must expose the manual visual-meeting link copy.'

$failed = @($checks | Where-Object { -not $_.ok })

[pscustomobject]@{
  ok = ($failed.Count -eq 0)
  skillRoot = $SkillRoot
  workspaceRoot = $WorkspaceRoot
  globalSkillsRoot = $GlobalSkillsRoot
  checks = @($checks.ToArray())
  failures = @($failed)
} | ConvertTo-Json -Depth 6

if ($failed.Count -gt 0) {
  exit 1
}
