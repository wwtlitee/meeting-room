param(
  [Parameter(Mandatory = $true)]
  [string]$Topic,
  [int]$ParticipantCount = 8,
  [string]$SkillRoot = "",
  [string]$OutFile = ""
)

$ErrorActionPreference = 'Stop'
$Utf8Bom = [System.Text.UTF8Encoding]::new($true)

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$RoleManifestPath = Join-Path $SkillRoot 'references\roles_manifest.json'
$RoleRoot = Join-Path $SkillRoot 'references\roles'
$PersonaRoot = Join-Path $SkillRoot 'references\personas'
$RoleNameZhPath = Join-Path $SkillRoot 'references\ROLE_NAME_ZH.md'

function Read-TextFile {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return ''
  }

  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-TextFile {
  param(
    [string]$Path,
    [string]$Content
  )

  $dir = Split-Path -Parent $Path
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  [System.IO.File]::WriteAllText($Path, $Content, $Utf8Bom)
}

function Get-RoleChineseNameMap {
  param([string]$Path)

  $map = @{}
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    if ($line -notmatch '^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|$') {
      continue
    }

    $division = $matches[1].Trim()
    $name = $matches[2].Trim()
    $zh = $matches[3].Trim()

    if ($division -in @(':---', '分组') -or $name -in @(':---', '原名')) {
      continue
    }

    $map["$division|$name"] = $zh
  }

  return $map
}

function Resolve-RolePath {
  param(
    [string]$Root,
    [object]$Role
  )

  $candidates = New-Object System.Collections.Generic.List[string]
  $candidates.Add((Join-Path $Root ('{0}\{1}.md' -f $Role.division, $Role.slug)))

  if ($Role.source_path) {
    $candidates.Add((Join-Path $Root ([string]$Role.source_path)))
  }

  if ($Role.reference_path) {
    $relative = ([string]$Role.reference_path) -replace '^references[\\/]+roles[\\/]+', ''
    $candidates.Add((Join-Path $Root $relative))
  }

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  return $candidates[0]
}

function Get-TopicTerms {
  param([string]$Text)

  $terms = New-Object System.Collections.Generic.List[string]
  $stop = @('我们', '这个', '那个', '现在', '然后', '就是', '需要', '可以', '不是', '什么', '问题', '一下', '专家', '专家团', '会议室')

  foreach ($match in [regex]::Matches($Text.ToLowerInvariant(), '[a-z0-9][a-z0-9_-]{2,}')) {
    $terms.Add($match.Value)
  }

  foreach ($match in [regex]::Matches($Text, '[\u4e00-\u9fff]{2,}')) {
    $segment = $match.Value
    for ($size = 2; $size -le 4; $size++) {
      if ($segment.Length -lt $size) {
        continue
      }

      for ($i = 0; $i -le $segment.Length - $size; $i++) {
        $term = $segment.Substring($i, $size)
        if ($stop -notcontains $term) {
          $terms.Add($term)
        }
      }
    }
  }

  return @($terms | Sort-Object -Unique)
}

function Get-BoostScore {
  param(
    [object]$Role,
    [string]$TopicText
  )

  $score = 0
  $slug = [string]$Role.slug
  $division = [string]$Role.division

  if ($TopicText -match '会议|会议室|讨论|发言|对话|拟人|主持|流程|专家团|轮流|读稿|反驳|补充|陪审|投票|12怒汉') {
    if ($slug -in @('specialized-workflow-architect', 'agents-orchestrator')) { $score += 20 }
    if ($slug -in @('product-manager', 'product-behavioral-nudge-engine')) { $score += 12 }
    if ($slug -in @('academic-psychologist', 'academic-narratologist')) { $score += 12 }
    if ($slug -in @('design-ux-researcher', 'prompt-pack-designer', 'demo-script-producer')) { $score += 10 }
    if ($slug -in @('testing-reality-checker', 'testing-evidence-collector', 'testing-workflow-optimizer', 'specialized-model-qa')) { $score += 9 }
    if ($slug -eq 'engineering-ai-engineer') { $score += 8 }
  }

  if ($TopicText -match '深度|轻度|模式|live|runtime|主进程|实时|会议记录|人格|子\s*agent|agent') {
    if ($slug -in @('agents-orchestrator', 'specialized-workflow-architect')) { $score += 32 }
    if ($slug -in @('product-manager', 'product-sprint-prioritizer')) { $score += 26 }
    if ($slug -in @('engineering-ai-engineer', 'engineering-backend-architect', 'engineering-senior-developer')) { $score += 24 }
    if ($slug -in @('testing-reality-checker', 'testing-workflow-optimizer', 'specialized-model-qa')) { $score += 22 }
    if ($slug -in @('design-ux-architect', 'design-ux-researcher', 'project-management-project-shepherd')) { $score += 16 }
  }

  if ($TopicText -match '网页|动画|viewer|react|前端|界面|ui|视觉|播放|铭牌|屏幕') {
    if ($division -eq 'design') { $score += 5 }
    if ($slug -in @('engineering-frontend-developer', 'design-ux-architect', 'motion-graphics-director', 'visual-qa-inspector')) { $score += 14 }
  }

  if ($TopicText -match '记忆|知识|人格|资料|检索|筛选|路由|角色|prompt|提示词') {
    if ($slug -in @('agents-orchestrator', 'specialized-workflow-architect', 'engineering-ai-engineer', 'prompt-pack-designer')) { $score += 14 }
    if ($slug -in @('product-manager', 'engineering-technical-writer', 'testing-evidence-collector')) { $score += 8 }
  }

  if ($TopicText -match 'mimo|code|免费|额度|无限|模型|成本|值不值|怎么用') {
    if ($slug -in @('product-manager', 'utility-product-designer')) { $score += 28 }
    if ($slug -in @('specialized-workflow-architect', 'agents-orchestrator')) { $score += 24 }
    if ($slug -in @('engineering-ai-engineer', 'engineering-backend-architect')) { $score += 22 }
    if ($slug -in @('testing-reality-checker', 'testing-workflow-optimizer')) { $score += 20 }
    if ($slug -in @('finance-financial-analyst', 'business-insight-analyst', 'finance-fpa-analyst')) { $score += 18 }
  }

  return $score
}

function Get-CompactEvidence {
  param(
    [string]$Text,
    [int]$MaxChars = 2200
  )

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ''
  }

  $lines = New-Object System.Collections.Generic.List[string]
  $skip = $false

  foreach ($line in ($Text -split "`r?`n")) {
    $trimmed = $line.TrimEnd()

    if ($trimmed -match '^## Change Logs') {
      break
    }

    if ($trimmed -match '^## 收录规则|^## 使用边界|^## Change Logs') {
      $skip = $true
      continue
    }

    if ($skip -and $trimmed -match '^##\s+') {
      $skip = $false
    }

    if ($skip) {
      continue
    }

    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }

    if ($trimmed -match '^\|') {
      continue
    }

    $lines.Add($trimmed)
  }

  $joined = ($lines -join "`n").Trim()
  if ($joined.Length -gt $MaxChars) {
    $joined = $joined.Substring(0, $MaxChars).TrimEnd() + "`n..."
  }

  return $joined
}

function Get-DisplayName {
  param(
    [object]$Role,
    [hashtable]$ChineseNames
  )

  $key = "{0}|{1}" -f $Role.division, $Role.name
  if ($ChineseNames.ContainsKey($key)) {
    return [string]$ChineseNames[$key]
  }

  return [string]$Role.name
}

function New-MeetingRuntimeContext {
  param(
    [object]$Role,
    [string]$DisplayName
  )

  return @"
你以稳定角色 prompt 中定义的【$DisplayName / $($Role.name)】身份参加会议室会议。

会议主题：
$Topic

发言规则：
1. 先遵守 baseRolePrompt，也就是该人格的原始角色 prompt；不要临时改写人格。
2. 再参考 personaStoreContext 中的 profile、knowledge、memory_summary，作为长期经验和专业资料。
3. 每次发言都要根据已发生的会议内容、当前议题、以及自己的人格 prompt 自由判断。
4. 发言要像这个岗位的人在现场判断：讲清专业上的担心、取舍、验收、失败路径或可执行建议。
5. 可以同意、反驳、追问、修正自己，也可以点名回应某个人；这些动作必须由上下文自然触发。
6. 禁止用固定模板，禁止“观点一/观点二/我赞同/我反对”排队式发言。
7. 禁止把资料里的句子直接搬进台词。资料只能改变你的判断方式。
8. 如果把你的铭牌换成别的角色，这句话仍然成立，就说明你发言失败，必须重写。
9. 除非用户明确要求简版，否则正式参会角色单次发言默认要有充分展开，通常至少 2 句，不要只给一句短判断。
10. 要压短的是会议最后的统一摘要，不是中间专家发言；中间发言应保留推理细节，结尾只做短收束。
"@
}

$roles = @((Get-Content -Raw -LiteralPath $RoleManifestPath -Encoding UTF8 | ConvertFrom-Json).roles)
$ChineseNames = Get-RoleChineseNameMap $RoleNameZhPath
$terms = Get-TopicTerms $Topic
$ParticipantCount = [Math]::Max(3, [Math]::Min(12, $ParticipantCount))

$scored = foreach ($role in $roles) {
  $division = [string]$role.division
  $slug = [string]$role.slug
  $personaDir = Join-Path (Join-Path $PersonaRoot $division) $slug
  $roleCardPath = Resolve-RolePath $RoleRoot $role
  $profilePath = Join-Path $personaDir 'profile.md'
  $knowledgePath = Join-Path $personaDir 'knowledge.md'
  $memorySummaryPath = Join-Path $personaDir 'memory_summary.md'

  $roleCard = Read-TextFile $roleCardPath
  $profile = Read-TextFile $profilePath
  $knowledge = Read-TextFile $knowledgePath
  $memorySummary = Read-TextFile $memorySummaryPath
  $displayName = Get-DisplayName $role $ChineseNames
  $corpus = ("$displayName $($role.name) $slug $division $($role.description) $roleCard $profile $knowledge $memorySummary").ToLowerInvariant()
  $score = Get-BoostScore $role $Topic

  foreach ($term in $terms) {
    if ($corpus.Contains($term.ToLowerInvariant())) {
      $score += [Math]::Min(8, [Math]::Max(2, $term.Length))
    }
  }

  [pscustomobject]@{
    score = $score
    slug = $slug
    role = $role
    displayName = $displayName
    roleCard = $roleCard
    profile = $profile
    knowledge = $knowledge
    memorySummary = $memorySummary
    roleCardPath = $roleCardPath
    profilePath = $profilePath
    knowledgePath = $knowledgePath
    memorySummaryPath = $memorySummaryPath
  }
}

$fallbackSlugs = @(
  'product-manager',
  'specialized-workflow-architect',
  'agents-orchestrator',
  'engineering-ai-engineer',
  'academic-psychologist',
  'academic-narratologist',
  'design-ux-researcher',
  'specialized-model-qa',
  'prompt-pack-designer',
  'testing-workflow-optimizer'
)

$selected = New-Object System.Collections.Generic.List[object]
foreach ($item in ($scored | Sort-Object -Property @{ Expression = 'score'; Descending = $true }, slug)) {
  if ($selected.Count -ge $ParticipantCount) {
    break
  }

  if ($item.score -gt 0) {
    $selected.Add($item)
  }
}

foreach ($slug in $fallbackSlugs) {
  if ($selected.Count -ge $ParticipantCount) {
    break
  }

  if (@($selected | Where-Object { $_.slug -eq $slug }).Count -gt 0) {
    continue
  }

  $item = $scored | Where-Object { $_.slug -eq $slug } | Select-Object -First 1
  if ($item) {
    $selected.Add($item)
  }
}

$selected = @($selected | Select-Object -First $ParticipantCount)
$roleContexts = @()
foreach ($item in $selected) {
  $roleContexts += [ordered]@{
    slug = [string]$item.slug
    displayName = [string]$item.displayName
    roleName = [string]$item.role.name
    division = [string]$item.role.division
    description = [string]$item.role.description
    sourceFiles = [ordered]@{
      roleCard = [string]$item.roleCardPath
      profile = [string]$item.profilePath
      knowledge = [string]$item.knowledgePath
      memorySummary = [string]$item.memorySummaryPath
    }
    baseRolePrompt = [string]$item.roleCard
    personaStoreContext = [ordered]@{
      profile = Get-CompactEvidence $item.profile 1400
      knowledge = Get-CompactEvidence $item.knowledge 2600
      memorySummary = Get-CompactEvidence $item.memorySummary 900
    }
    meetingRuntimeContext = New-MeetingRuntimeContext $item.role $item.displayName
  }
}

$context = [ordered]@{
  ok = $true
  version = '1.0.0'
  kind = 'meeting-room-authoring-context'
  topic = $Topic
  participantCount = $selected.Count
  participants = @($roleContexts | ForEach-Object { $_.slug })
  authoringInstructions = @(
    'Use baseRolePrompt as the stable identity prompt for each employee.',
    'Use personaStoreContext as long-term professional memory and knowledge, not as a phrase bank.',
    'Use meetingRuntimeContext only as this meeting''s temporary wrapper: topic, turn rules, and nameplate-swap test.',
    'Do not generate or rewrite a persona prompt per meeting.',
    'Do not generate dialogue by extracting keywords from persona files.',
    'At each turn, choose the next speaker from conversation need and persona expertise, not from a fixed rhetorical slot.',
    'Write or import the final meeting-runtime.json only after the transcript passes the nameplate-swap test for every non-host line.'
  )
  outputSessionPath = (Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\meeting-runtime.json')
  roleContexts = $roleContexts
}

$json = $context | ConvertTo-Json -Depth 12

if ($OutFile) {
  Write-TextFile $OutFile $json
}

$json
