param(
  [string]$RuntimeFile = '',
  [Parameter(Mandatory = $true)]
  [string]$SpeakerId,
  [string]$TurnId = '',
  [string]$Phase = '',
  [ValidateSet('speak', 'challenge')]
  [string]$Type = 'speak',
  [string]$ScreenTitle = '',
  [string]$ScreenStatus = '',
  [string]$SkillRoot = ''
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

function Get-FormalRoleIds {
  param([object]$Session)

  if ($Session.runtime -and $Session.runtime.formalParticipants) {
    return @($Session.runtime.formalParticipants | ForEach-Object { [string]$_.roleId } | Where-Object { $_ })
  }

  return @($Session.participants | Where-Object { $_ -and $_ -ne 'host' })
}

if (-not (Test-Path -LiteralPath $RuntimeFile)) {
  throw "Runtime file does not exist: $RuntimeFile"
}

$session = Read-Utf8JsonFile $RuntimeFile
if ($SpeakerId -eq 'host') {
  throw 'Host control turns are fixed-flow turns and must be appended directly, not routed through pending speaker thinking.'
}

$roleMetaProp = $session.roleMeta.PSObject.Properties[$SpeakerId]
if (-not $roleMetaProp) {
  throw "SpeakerId is not in current meeting roleMeta: $SpeakerId"
}

$turns = @($session.turns)
if (-not $TurnId) {
  if ($SpeakerId -eq 'host' -and $Type -eq 'vote') {
    $nextVoteNumber = @($session.deliberation.voteRounds).Count + 1
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
  $Phase = (U '\u6b63\u5728\u601d\u8003')
}
if (-not $ScreenTitle) {
  $ScreenTitle = (U '\u5b9e\u65f6\u8ba8\u8bba')
}
if (-not $ScreenStatus) {
  $ScreenStatus = 'THINK'
}

$pending = [ordered]@{
  roleId = $SpeakerId
  turnId = $TurnId
  phase = $Phase
  type = $Type
  screenTitle = $ScreenTitle
  screenStatus = $ScreenStatus
  status = 'thinking'
  requiresPersonaRead = $true
  requiresRuntimeRead = $true
  startedAt = (Get-Date).ToUniversalTime().ToString('o')
}

if ($session.runtime.PSObject.Properties['pendingSpeaker']) {
  $session.runtime.pendingSpeaker = $pending
}
else {
  $session.runtime | Add-Member -NotePropertyName 'pendingSpeaker' -NotePropertyValue $pending
}

$formalRoleIds = @(Get-FormalRoleIds -Session $session)
$thinking = New-Object System.Collections.Generic.List[object]
foreach ($roleId in $formalRoleIds) {
  if ($roleId -eq $SpeakerId) {
    continue
  }
  $thinking.Add([ordered]@{
    roleId = $roleId
    status = 'thinking'
  })
}

$session.runtime.status = 'speaker_thinking'
$session.runtime.hostStage = 'listen'
$session.runtime.turnCount = @($session.turns).Count
$session.runtime.thinking = @($thinking.ToArray())
$session.runtime.nextQuestions = @((U '\u5f53\u524d\u53d1\u8a00\u4eba\u6b63\u5728\u8bfb\u53d6\u4eba\u683c\u4fe1\u606f\u548c\u4f1a\u8bae\u5b9e\u65f6\u5185\u5bb9\uff0c\u751f\u6210\u5b8c\u6210\u540e\u518d\u63d0\u4ea4\u53d1\u8a00'))
$session.runtime.updatedAt = (Get-Date).ToUniversalTime().ToString('o')

Write-Utf8JsonFile -Path $RuntimeFile -Value $session

[pscustomobject]@{
  ok = $true
  runtimeFile = [System.IO.Path]::GetFullPath($RuntimeFile)
  speakerId = $SpeakerId
  turnId = $TurnId
  status = $session.runtime.status
  pendingSpeaker = $pending
} | ConvertTo-Json -Depth 8
