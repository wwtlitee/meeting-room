param(
  [Parameter(Mandatory = $true)]
  [string]$Topic,
  [string]$SkillRoot = '',
  [int]$ParticipantCount = 6,
  [string]$OutFile = '',
  [string]$LabelA = 'Authored',
  [string]$LabelB = 'Live',
  [string]$DetailA = 'Single scripted session',
  [string]$DetailB = 'Runtime incremental session'
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
$ParticipantCount = [Math]::Max(5, [Math]::Min(10, $ParticipantCount))
$buildContextScript = Join-Path $SkillRoot 'scripts\build_meeting_authoring_context.ps1'

if (-not $OutFile) {
  $OutFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\live-jury-demo-session.json'
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

  $json = $Value | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($fullPath, $json, $Utf8Json)
}

function New-Turn {
  param(
    [string]$Id,
    [string]$SpeakerId,
    [string]$Phase,
    [string]$Type,
    [string]$Text
  )

  return [ordered]@{
    id = $Id
    speakerId = $SpeakerId
    phase = $Phase
    type = $Type
    text = $Text
  }
}

$context = (& $buildContextScript -Topic $Topic -ParticipantCount $ParticipantCount -SkillRoot $SkillRoot) | ConvertFrom-Json
if (-not $context.ok) {
  throw 'Failed to build meeting authoring context.'
}

$roles = @($context.roleContexts)
if ($roles.Count -lt 5) {
  throw 'Live jury demo session requires at least 5 selected roles.'
}

$participants = @('host')
$participants += @($roles | ForEach-Object { [string]$_.slug })

$roleMeta = [ordered]@{
  host = [ordered]@{
    name = (U '\u4e3b\u6301\u4eba')
    title = (U '\u4f1a\u8bae\u4e3b\u6301')
    lane = 'center'
  }
}

for ($i = 0; $i -lt $roles.Count; $i++) {
  $role = $roles[$i]
  $lane = if (($i % 2) -eq 0) { 'left' } else { 'right' }
  $roleMeta[[string]$role.slug] = [ordered]@{
    name = [string]$role.displayName
    title = [string]$role.roleName
    lane = $lane
  }
}

$r1 = $roles[0]
$r2 = $roles[1]
$r3 = $roles[2]
$r4 = $roles[3]
$r5 = $roles[4]
$r6 = if ($roles.Count -ge 6) { $roles[5] } else { $roles[4] }

$turns = @(
  (New-Turn 'opening' 'host' (U '\u5f00\u9898') 'speak' ("{0}{1}{2}{3}{4}{5}{6}{7}" -f
      (U '\u5927\u5bb6\u597d\uff0c\u672c\u6b21\u4f1a\u8bae\u7684\u4e3b\u9898\u662f\uff1a'),
      $Topic,
      (U '\u3002A \u8def\u7ebf\u662f'),
      $LabelA,
      (U '\uff0cB \u8def\u7ebf\u662f'),
      $LabelB,
      (U '\u3002\u4eca\u5929\u6211\u4eec\u53ea\u5224\u65ad\u4e00\u4ef6\u4e8b\uff1a\u54ea\u6761\u8def\u7ebf\u66f4\u9002\u5408\u6210\u4e3a\u4e13\u5bb6\u56e2\u4f1a\u8bae\u7684\u4e3b\u8def\u7ebf'),
      (U '\u3002')))
  (New-Turn 'host-vote-1' 'host' (U '\u7b2c\u4e00\u8f6e\u6295\u7968') 'vote' ("{0}{1}{2}{3}{4}" -f
      (U '\u5148\u505a\u7b2c\u4e00\u8f6e\u5224\u65ad\uff1aA \u662f'),
      $LabelA,
      (U '\uff0cB \u662f'),
      $LabelB,
      (U '\u3002')))
  (New-Turn 'host-r1-start' 'host' (U '\u7b2c\u4e00\u8f6e\u53d1\u8a00') 'control' (U '\u7b2c\u4e00\u8f6e\u5148\u56f4\u7ed5\u4e09\u4ef6\u4e8b\u804a\uff1a\u771f\u5b9e\u4eba\u683c\u611f\uff0c\u5f00\u4f1a\u6210\u672c\uff0c\u4ee5\u53ca viewer \u9700\u4e0d\u9700\u8981\u63a8\u7ffb\u91cd\u6765\u3002'))
  (New-Turn 'r1-1' ([string]$r1.slug) (U '\u7b2c\u4e00\u8f6e\u53d1\u8a00') 'speak' ((U '\u6211\u5148\u66ff A \u4fdd\u7559\u4e00\u4e2a\u4ef7\u503c\uff1a') + $LabelA + (U '\u80dc\u5728\u7a33\uff0c\u4eca\u5929\u5c31\u80fd\u64ad\uff0c\u4f46\u5b83\u7684\u4eba\u683c\u8fd8\u662f\u4e00\u4e2a\u4e2d\u5fc3\u8111\u5199\u51fa\u6765\u7684\u3002')))
  (New-Turn 'r1-2' ([string]$r2.slug) (U '\u7b2c\u4e00\u8f6e\u53d1\u8a00') 'speak' ((U '\u6211\u503e\u5411 B\uff0c\u56e0\u4e3a ') + $LabelB + (U '\u81f3\u5c11\u80fd\u628a\u4f1a\u8bae\u6539\u6210\u8fd0\u884c\u4e2d\u72b6\u6001\uff0c\u540e\u9762\u518d\u628a\u771f\u5b50 agent \u63a5\u8fdb\u53bb\u5c31\u662f\u5408\u7406\u8def\u5f84\u3002')))
  (New-Turn 'r1-3' ([string]$r3.slug) (U '\u7b2c\u4e00\u8f6e\u53d1\u8a00') 'speak' (U '\u6211\u66f4\u5173\u5fc3 viewer \u6539\u9020\u91cf\u3002\u53ea\u8981 session \u7ed3\u6784\u4ece\u6574\u7bc7 turns \u53d8\u6210\u589e\u91cf turns \u548c runtime \u72b6\u6001\uff0c\u524d\u7aef\u662f\u80fd\u7ee7\u7eed\u590d\u7528\u7684\u3002'))
  (New-Turn 'host-vote-2' 'host' (U '\u7b2c\u4e8c\u8f6e\u6295\u7968') 'vote' (U '\u518d\u6295\u4e00\u6b21\uff1a\u5982\u679c\u7b2c\u4e00\u7248\u5148\u505a 5-6 \u4eba MVP\uff0c\u662f\u5426\u5e94\u8be5\u4f18\u5148\u9009 live session \u8def\u7ebf\uff1f'))
  (New-Turn 'host-r2-start' 'host' (U '\u7b2c\u4e8c\u8f6e\u53d1\u8a00') 'control' (U '\u7b2c\u4e8c\u8f6e\u53ea\u56de\u7b54\u4e00\u4e2a\u95ee\u9898\uff1a\u54ea\u6761\u8def\u7ebf\u5bf9\u73b0\u6709\u8d44\u4ea7\u590d\u7528\u6700\u591a\uff0c\u540c\u65f6\u53c8\u80fd\u771f\u6b63\u8d70\u5411\u591a\u4eba\u683c\u8fd0\u884c\u65f6\u3002'))
  (New-Turn 'r2-1' ([string]$r4.slug) (U '\u7b2c\u4e8c\u8f6e\u53d1\u8a00') 'speak' (U '\u6211\u503e\u5411\u5148\u505a live replay MVP\uff0c\u56e0\u4e3a\u5b83\u80fd\u5148\u628a viewer \u548c runtime \u4e4b\u95f4\u7684\u6570\u636e\u5951\u7ea6\u7acb\u4f4f\uff0c\u7136\u540e\u518d\u6362\u6210\u771f\u5b50 agent \u5e76\u53d1\u601d\u8003\u3002'))
  (New-Turn 'r2-2' ([string]$r5.slug) (U '\u7b2c\u4e8c\u8f6e\u53d1\u8a00') 'speak' (U '\u6211\u770b\u91cd\u7684\u662f\u8fd0\u8425\u6210\u672c\u300210 \u4eba\u4e0a\u9650\u4fdd\u7559\u6ca1\u95ee\u9898\uff0c\u4f46\u9ed8\u8ba4 6 \u4eba\u5de6\u53f3\u6700\u7a33\uff0c\u8fd9\u6837\u7b49 runtime \u6539\u6210\u771f\u601d\u8003\u65f6\u624d\u4e0d\u4f1a\u4e00\u4e0b\u5b50\u70b8\u6210\u672c\u3002'))
  (New-Turn 'r2-3' ([string]$r6.slug) (U '\u7b2c\u4e8c\u8f6e\u53d1\u8a00') 'speak' (U '\u6211\u7684\u7ed3\u8bba\u662f\uff0cAuthored \u53ef\u4ee5\u4f5c\u4e3a fallback\uff0c\u4f46\u5982\u679c\u76ee\u6807\u662f\u771f\u6b63\u4eba\u683c\u4e92\u76f8\u8bf4\u670d\uff0c\u4e3b\u8def\u7ebf\u4e00\u5b9a\u5f97\u662f live session\u3002'))
  (New-Turn 'host-vote-3' 'host' (U '\u6700\u7ec8\u4e00\u8f6e\u6295\u7968') 'vote' (U '\u6700\u540e\u786e\u8ba4\uff1a\u662f\u5426\u91c7\u7528 live session \u4f5c\u4e3a\u4e13\u5bb6\u56e2\u4e3b\u8def\u7ebf\uff0cAuthored \u964d\u7ea7\u4e3a fallback \u548c smoke test\uff1f'))
  (New-Turn 'host-r3-result' 'host' (U '\u6700\u7ec8\u7ed3\u679c') 'control' (U '\u6700\u7ec8\u4e00\u8f6e\u7968\u6570\u5df2\u7ecf\u4e00\u81f4\uff0c\u5bf9\u4e3b\u8def\u7ebf\u7684\u9009\u62e9\u73b0\u5728\u53ef\u4ee5\u6536\u675f\u3002'))
  (New-Turn 'host-final' 'host' (U '\u4e3b\u6301\u4eba\u603b\u7ed3') 'conclusion' (U '\u672c\u573a\u7ed3\u8bba\u662f\uff1alive session \u5e94\u8be5\u6210\u4e3a\u4e13\u5bb6\u56e2\u4f1a\u8bae\u7684\u4e3b\u8def\u7ebf\uff0cAuthored \u4fdd\u7559\u4e3a fallback \u548c smoke test\u3002\u7b2c\u4e00\u6b65\u5148\u628a 5-6 \u4eba MVP \u8dd1\u7a33\uff0c\u7136\u540e\u518d\u628a\u771f\u5b50 agent \u5e76\u53d1\u601d\u8003\u63a5\u8fdb\u6765\u3002'))
)

$voteRounds = @(
  [ordered]@{
    id = 'vote-1'
    label = (U '\u7b2c\u4e00\u8f6e\u6295\u7968')
    afterTurnId = 'host-vote-1'
    prompt = (U '\u7b2c\u4e00\u8f6e\uff1a\u73b0\u5728\u5e94\u7ee7\u7eed Authored\uff0c\u8fd8\u662f\u5e94\u8be5\u8f6c\u5411 Live\uff1f')
    votes = [ordered]@{
      ([string]$r1.slug) = 'a'
      ([string]$r2.slug) = 'b'
      ([string]$r3.slug) = 'b'
      ([string]$r4.slug) = 'b'
      ([string]$r5.slug) = 'a'
      ([string]$r6.slug) = 'b'
    }
    counts = [ordered]@{ a = 2; b = 4 }
  },
  [ordered]@{
    id = 'vote-2'
    label = (U '\u7b2c\u4e8c\u8f6e\u6295\u7968')
    afterTurnId = 'host-vote-2'
    prompt = (U '\u7b2c\u4e8c\u8f6e\uff1a\u5982\u679c\u5148\u505a MVP\uff0c\u662f\u5426\u5e94\u8be5\u4f18\u5148 Live \u8def\u7ebf\uff1f')
    votes = [ordered]@{
      ([string]$r1.slug) = 'b'
      ([string]$r2.slug) = 'b'
      ([string]$r3.slug) = 'b'
      ([string]$r4.slug) = 'b'
      ([string]$r5.slug) = 'a'
      ([string]$r6.slug) = 'b'
    }
    counts = [ordered]@{ a = 1; b = 5 }
  },
  [ordered]@{
    id = 'vote-3'
    label = (U '\u6700\u7ec8\u4e00\u8f6e\u6295\u7968')
    afterTurnId = 'host-vote-3'
    prompt = (U '\u6700\u7ec8\u4e00\u8f6e\uff1a\u662f\u5426\u786e\u8ba4 Live \u4e3a\u4e3b\u8def\u7ebf\uff0cAuthored \u4e3a fallback\uff1f')
    votes = [ordered]@{
      ([string]$r1.slug) = 'b'
      ([string]$r2.slug) = 'b'
      ([string]$r3.slug) = 'b'
      ([string]$r4.slug) = 'b'
      ([string]$r5.slug) = 'b'
      ([string]$r6.slug) = 'b'
    }
    counts = [ordered]@{ a = 0; b = 6 }
  }
)

$session = [ordered]@{
  version = '1.2.0'
  id = 'meeting-' + (Get-Date).ToString('yyyyMMdd-HHmmss') + '-authored-vs-live'
  startedAt = (Get-Date).ToUniversalTime().ToString('o')
  title = $Topic
  topic = $Topic
  mode = 'jury_deliberation'
  participants = $participants
  roleMeta = $roleMeta
  deliberation = [ordered]@{
    enabled = $true
    labelA = $LabelA
    labelB = $LabelB
    detailA = $DetailA
    detailB = $DetailB
    voteRounds = $voteRounds
  }
  turns = $turns
  summary = [ordered]@{
    consensus = @(
      (U '\u4e13\u5bb6\u56e2\u4f1a\u8bae\u7684\u4e3b\u8def\u7ebf\u5e94\u8be5\u662f live session\uff0cAuthored \u964d\u7ea7\u4e3a fallback \u548c smoke test\u3002'),
      (U '\u4e3b\u8fdb\u7a0b\u7ee7\u7eed\u62c5\u4efb\u4e3b\u6301\u4eba\uff0c\u53c2\u4f1a\u4eba\u683c\u5b9e\u65f6\u601d\u8003\u5e76\u6392\u961f\u53d1\u8a00\u3002'),
      (U '\u7b2c\u4e00\u7248\u5148\u7a33\u5b9a 5-6 \u4eba\uff0c\u7136\u540e\u518d\u5411\u66f4\u591a\u5e2d\u4f4d\u6269\u5c55\u3002')
    )
    nextActions = @(
      (U '\u628a live replay MVP \u5347\u7ea7\u6210\u771f\u5b50 agent \u5019\u9009\u53d1\u8a00\u8f93\u51fa\u3002'),
      (U '\u7ed9 viewer \u63a5\u5165 runtime.thinking \u548c runtime.queue \u7684\u53ef\u89c6\u5316\u3002'),
      (U '\u628a Authored \u8def\u5f84\u9650\u5236\u5728 fallback \u548c\u8c03\u8bd5\u7528\u9014\u3002')
    )
    implementationPlan = @(
      [ordered]@{ id = 'LIVE-1'; title = (U '\u771f\u5b9e\u5e76\u53d1\u601d\u8003'); owner = [string]$r2.slug; deliverable = (U '\u5b50 agent \u5019\u9009\u53d1\u8a00\u8f93\u51fa'); acceptance = (U '\u6240\u6709\u53c2\u4f1a\u4eba\u683c\u90fd\u80fd\u63d0\u4ea4\u672c\u8f6e\u5019\u9009\u53d1\u8a00\u548c\u7acb\u573a') },
      [ordered]@{ id = 'LIVE-2'; title = (U '\u4f1a\u8bae\u9875\u8fd0\u884c\u4e2d\u72b6\u6001'); owner = [string]$r3.slug; deliverable = 'thinking queue UI'; acceptance = (U '\u4f1a\u8bae\u9875\u53ef\u663e\u793a\u6b63\u5728\u601d\u8003\u548c\u5019\u53d1\u8a00\u961f\u5217') },
      [ordered]@{ id = 'LIVE-3'; title = (U '\u8fd0\u884c\u65f6\u8c03\u5ea6'); owner = [string]$r4.slug; deliverable = (U '\u53d1\u8a00\u961f\u5217\u4e0e\u589e\u91cf\u518d\u601d\u8003'); acceptance = (U '\u7968\u6570\u53d8\u5316\u80fd\u5bf9\u5e94\u4e0a\u4e00\u8f6e\u771f\u5b9e\u53d1\u8a00') }
    )
    recommendedWorkers = @(
      [ordered]@{ roleId = [string]$r2.slug; name = [string]$r2.displayName; title = [string]$r2.roleName; priority = 'P0'; task = (U '\u843d\u5730 Live \u4e3b\u8def\u7ebf'); scope = (U '\u8fd0\u884c\u65f6\u548c agent \u8f93\u51fa'); deliverable = (U '\u771f\u5b9e\u601d\u8003\u8f93\u51fa\u534f\u8bae') },
      [ordered]@{ roleId = [string]$r3.slug; name = [string]$r3.displayName; title = [string]$r3.roleName; priority = 'P0'; task = (U '\u628a viewer \u63a5\u6210\u8fd0\u884c\u4e2d\u72b6\u6001\u6d88\u8d39\u8005'); scope = (U '\u4f1a\u8bae\u9875'); deliverable = (U 'runtime \u53ef\u89c6\u5316 UI') },
      [ordered]@{ roleId = [string]$r4.slug; name = [string]$r4.displayName; title = [string]$r4.roleName; priority = 'P1'; task = (U '\u8865\u8fd0\u884c\u65f6\u8c03\u5ea6'); scope = (U '\u8f6e\u6b21\u548c\u961f\u5217'); deliverable = (U '\u53d1\u8a00\u961f\u5217\u4e0e\u589e\u91cf\u518d\u601d\u8003') }
    )
    futureAnimationIdea = (U '\u540e\u7eed\u53ef\u628a thinking \u72b6\u6001\u6620\u5c04\u5230\u5e2d\u4f4d\u5f85\u547d\u52a8\u753b\uff0c\u628a queue \u72b6\u6001\u6620\u5c04\u5230\u5019\u573a\u63d0\u793a\u3002')
  }
  generator = 'meeting-room/runtime/new_live_jury_demo_session.ps1'
}

Write-Utf8JsonFile -Path $OutFile -Value $session

[pscustomobject]@{
  ok = $true
  topic = $Topic
  participantCount = $roles.Count
  participants = @($roles | ForEach-Object { $_.slug })
  outFile = [System.IO.Path]::GetFullPath($OutFile)
} | ConvertTo-Json -Depth 8
