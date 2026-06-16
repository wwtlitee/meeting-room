param(
  [Parameter(Mandatory = $true)]
  [string]$Topic,
  [ValidateSet('discussion','jury_deliberation')]
  [string]$Mode = 'discussion',
  [int]$ParticipantCount = 8,
  [string]$SkillRoot = '',
  [string]$OutFile = '',
  [string]$LabelA = '',
  [string]$LabelB = '',
  [string]$DetailA = '',
  [string]$DetailB = ''
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
$defaultRuntimeFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json'

if (-not $OutFile) {
  $OutFile = $defaultRuntimeFile
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
  Move-Item -LiteralPath $tempPath -Destination $fullPath -Force
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

function Get-DefaultOptionSet {
  param([string]$MeetingTopic)

  if ([regex]::IsMatch($MeetingTopic, (U '\u6df1\u5ea6.*\u6a21\u5f0f|\u6a21\u5f0f.*\u6df1\u5ea6'))) {
    return [ordered]@{
      labelA = (U '\u4fdd\u7559\u6df1\u5ea6')
      labelB = (U '\u4ec5\u4fdd\u7559\u8f7b\u5ea6')
      detailA = (U '\u6df1\u5ea6\u6a21\u5f0f\u4f5c\u4e3a\u9ad8\u98ce\u9669\u3001\u9ad8\u4e0d\u786e\u5b9a\u6216\u9700\u591a\u8f6e\u9a8c\u8bc1\u4efb\u52a1\u7684\u6309\u9700\u8def\u5f84')
      detailB = (U '\u5220\u9664\u6df1\u5ea6\u6a21\u5f0f\uff0c\u4f1a\u8bae\u53ea\u4fdd\u7559\u4e3b\u8fdb\u7a0b\u8f7b\u5ea6 live')
    }
  }

  return [ordered]@{
    labelA = (U '\u8def\u7ebf A')
    labelB = (U '\u8def\u7ebf B')
    detailA = (U '\u4fdd\u7559\u6216\u63a8\u8fdb\u7b2c\u4e00\u5019\u9009\u8def\u5f84')
    detailB = (U '\u6536\u7f29\u6216\u63a8\u8fdb\u7b2c\u4e8c\u5019\u9009\u8def\u5f84')
  }
}

function Get-AmbientStateProfile {
  param([string]$State)

  switch ([string]$State) {
    'nod' {
      return [ordered]@{
        label = (U '\u5bf9\u5bf9\u5bf9')
        canSpeak = $true
        speechStyle = 'agree'
        defaultUtterance = (U '\u5bf9\u5bf9\u5bf9\uff0c\u8fd9\u53e5\u6709\u9053\u7406\u3002')
        vote = 'agree'
      }
    }
    'reserve' {
      return [ordered]@{
        label = (U '\u4fdd\u7559\u610f\u89c1')
        canSpeak = $true
        speechStyle = 'reserve'
        defaultUtterance = (U '\u6211\u4fdd\u7559\u610f\u89c1\uff0c\u9a8c\u6536\u53e3\u5f84\u518d\u6e05\u695a\u4e00\u70b9\u6211\u518d\u843d\u8fb9\u3002')
        vote = 'z'
      }
    }
    'thinking' {
      return [ordered]@{
        label = (U '\u518d\u60f3\u60f3')
        canSpeak = $true
        speechStyle = 'thinking'
        defaultUtterance = (U '\u6211\u518d\u60f3\u60f3\uff0c\u8fd9\u91cc\u8fd8\u5dee\u4e00\u4e2a\u66f4\u5177\u4f53\u7684\u843d\u5730\u53e3\u5f84\u3002')
        vote = 'z'
      }
    }
    'phone' {
      return [ordered]@{
        label = (U '\u770b\u624b\u673a')
        canSpeak = $false
        speechStyle = 'visual'
        defaultUtterance = ''
        vote = 'z'
      }
    }
    default {
      return [ordered]@{
        label = (U '\u7761\u89c9\u4e2d')
        canSpeak = $false
        speechStyle = 'visual'
        defaultUtterance = ''
        vote = 'z'
      }
    }
  }
}

if (-not (Test-Path -LiteralPath $buildContextScript)) {
  throw "Build context script does not exist: $buildContextScript"
}

$formalCount = [Math]::Max(3, [Math]::Min(10, $ParticipantCount))
$contextParticipantCount = [Math]::Max(10, $formalCount)
$context = (& $buildContextScript -Topic $Topic -ParticipantCount $contextParticipantCount -SkillRoot $SkillRoot) | ConvertFrom-Json
if (-not $context.ok) {
  throw 'Failed to build meeting authoring context.'
}

$formalRoles = @($context.roleContexts | Select-Object -First $formalCount)
$formalIds = @($formalRoles | ForEach-Object { [string]$_.slug })
$ambientNeeded = [Math]::Max(0, 10 - $formalIds.Count)
$ambientStates = @('zzz', 'nod', 'thinking', 'reserve', 'phone', 'zzz', 'nod', 'thinking', 'reserve', 'phone')
$ambientRoles = @($context.roleContexts | Select-Object -Skip $formalCount -First $ambientNeeded)
$ambientIds = @($ambientRoles | ForEach-Object { [string]$_.slug })

$roleMeta = [ordered]@{
  host = [ordered]@{
    name = (U '\u4e3b\u6301\u4eba')
    title = (U '\u4f1a\u8bae\u4e3b\u6301')
    lane = 'center'
    department = (U '\u4f1a\u8bae\u4e3b\u6301')
  }
}

$formalParticipants = New-Object System.Collections.Generic.List[object]
$seatIndex = 0
foreach ($role in $formalRoles) {
  $roleId = [string]$role.slug
  $lane = if (($seatIndex % 2) -eq 0) { 'left' } else { 'right' }
  $roleMeta[$roleId] = [ordered]@{
    name = [string]$role.displayName
    title = [string]$role.roleName
    lane = $lane
    department = [string]$role.division
  }
  $formalParticipants.Add([ordered]@{
    roleId = $roleId
    name = [string]$role.displayName
    title = [string]$role.roleName
    lane = $lane
    status = 'ready'
  })
  $seatIndex += 1
}

$ambientParticipants = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $ambientIds.Count; $i++) {
  $roleId = $ambientIds[$i]
  $role = $ambientRoles[$i]
  $state = $ambientStates[$i % $ambientStates.Count]
  $profile = Get-AmbientStateProfile -State $state
  $lane = if (($seatIndex % 2) -eq 0) { 'left' } else { 'right' }
  $roleMeta[$roleId] = [ordered]@{
    name = [string]$role.displayName
    title = [string]$role.roleName
    lane = $lane
    department = [string]$role.division
    ambientState = $state
    ambientLabel = [string]$profile.label
    ambientVote = [string]$profile.vote
    canSpeak = [bool]$profile.canSpeak
    speechStyle = [string]$profile.speechStyle
    defaultUtterance = [string]$profile.defaultUtterance
  }
  $ambientParticipants.Add([ordered]@{
    roleId = $roleId
    name = [string]$role.displayName
    title = [string]$role.roleName
    lane = $lane
    state = $state
    stateLabel = [string]$profile.label
    vote = [string]$profile.vote
    canSpeak = [bool]$profile.canSpeak
    speechStyle = [string]$profile.speechStyle
    defaultUtterance = [string]$profile.defaultUtterance
  })
  $seatIndex += 1
}

$optionSet = Get-DefaultOptionSet -MeetingTopic $Topic
if (-not [string]::IsNullOrWhiteSpace($LabelA)) { $optionSet.labelA = $LabelA }
if (-not [string]::IsNullOrWhiteSpace($LabelB)) { $optionSet.labelB = $LabelB }
if (-not [string]::IsNullOrWhiteSpace($DetailA)) { $optionSet.detailA = $DetailA }
if (-not [string]::IsNullOrWhiteSpace($DetailB)) { $optionSet.detailB = $DetailB }

$outFullPath = [System.IO.Path]::GetFullPath($OutFile)
$contextFile = Join-Path (Split-Path -Parent $outFullPath) 'meeting-runtime.context.json'
Write-Utf8JsonFile -Path $contextFile -Value $context

$now = (Get-Date).ToUniversalTime().ToString('o')
$participants = @('host') + $formalIds + $ambientIds
$session = [ordered]@{
  version = '1.4.0'
  id = 'meeting-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-live'
  startedAt = $now
  layout = 'vertical-long-table'
  title = $Topic
  topic = $Topic
  generator = 'meeting-room/runtime/initialize_live_meeting.ps1'
  mode = $Mode
  participants = $participants
  roleMeta = $roleMeta
  deliberation = [ordered]@{
    enabled = ($Mode -eq 'jury_deliberation')
    labelA = [string]$optionSet.labelA
    labelB = [string]$optionSet.labelB
    labelZ = (U '\u5f03\u6743')
    detailA = [string]$optionSet.detailA
    detailB = [string]$optionSet.detailB
    detailZ = (U '\u6682\u4e0d\u8868\u6001')
    voteRounds = @()
  }
  runtime = [ordered]@{
    version = '1.2.0'
    kind = 'main-process-live-meeting-runtime'
    status = 'live_waiting'
    topic = $Topic
    currentOptions = [ordered]@{
      a = [ordered]@{ label = [string]$optionSet.labelA; detail = [string]$optionSet.detailA }
      b = [ordered]@{ label = [string]$optionSet.labelB; detail = [string]$optionSet.detailB }
      z = [ordered]@{ label = (U '\u5f03\u6743'); detail = (U '\u6682\u4e0d\u8868\u6001') }
    }
    hostStage = 'prepare'
    round = 0
    host = 'main-process'
    mode = $Mode
    participantTarget = 10
    formalTarget = $formalIds.Count
    ambientTarget = $ambientIds.Count
    participantMin = 5
    participantDefault = 10
    participantMax = 10
    formalParticipants = @($formalParticipants.ToArray())
    ambientParticipants = @($ambientParticipants.ToArray())
    thinking = @($formalParticipants.ToArray() | ForEach-Object { [ordered]@{ roleId = [string]$_.roleId; status = 'thinking' } })
    queue = @()
    recentKeyTurns = @()
    unresolvedDisagreements = @()
    voteSnapshot = [ordered]@{
      roundId = ''
      counts = [ordered]@{}
      votes = [ordered]@{}
    }
    consensusDraft = @()
    nextQuestions = @((U '\u4e3b\u8fdb\u7a0b\u8bfb\u53d6\u4eba\u683c\u4e0e\u4f1a\u8bae\u8bb0\u5f55\u540e\u8ffd\u52a0\u4e0b\u4e00\u6761\u53d1\u8a00'))
    lastSpeakerId = ''
    pendingSpeaker = $null
    turnCount = 0
    note = 'main-process-live-runtime'
    contextFile = $contextFile
    updatedAt = $now
  }
  turns = @()
  summary = [ordered]@{}
}

Write-Utf8JsonFile -Path $outFullPath -Value $session

[pscustomobject]@{
  ok = $true
  topic = $Topic
  participant_count = $formalIds.Count
  participants = $formalIds
  ambient_count = $ambientIds.Count
  ambient_participants = $ambientIds
  out_file = $outFullPath
  context_file = $contextFile
  session_url = 'meeting-runtime.json'
  source = 'main_process_live'
  liveContract = 'main-process-append-only'
} | ConvertTo-Json -Depth 8
