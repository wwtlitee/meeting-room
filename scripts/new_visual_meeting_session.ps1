param(
  [Parameter(Mandatory = $true)]
  [string]$Topic,
  [ValidateSet('jury_deliberation')]
  [string]$Mode = 'jury_deliberation',
  [int]$ParticipantCount = 8,
  [string]$SkillRoot = "",
  [string]$OutFile = "",
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$Utf8Bom = [System.Text.UTF8Encoding]::new($true)
$Utf8Json = [System.Text.UTF8Encoding]::new($false)

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$buildContextScript = Join-Path $SkillRoot 'scripts\build_meeting_authoring_context.ps1'
$RoleManifestPath = Join-Path $SkillRoot 'references\roles_manifest.json'
$RoleRoot = Join-Path $SkillRoot 'references\roles'
$PersonaRoot = Join-Path $SkillRoot 'references\personas'
$RoleNameZhPath = Join-Path $SkillRoot 'references\ROLE_NAME_ZH.md'

if (-not $OutFile) {
  $OutFile = Join-Path $SkillRoot 'assets\expert-meeting-viewer\art\current-session.json'
}

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

  [System.IO.File]::WriteAllText($Path, $Content, $Utf8Json)
}

function ConvertTo-PlainLine {
  param([string]$Text)

  $line = ($Text -replace '^\s*[-*]\s*', '')
  $line = $line -replace '\*\*', ''
  $line = $line -replace '`', ''
  $line = $line -replace '\s*-\s*v\d+\.\d+\.\d+.*$', ''
  $line = $line -replace '\s+', ' '
  $line = $line.Trim()

  if ($line.Length -gt 92) {
    $line = $line.Substring(0, 92).TrimEnd('，', '。', '；', ';', ',') + '。'
  }

  return $line
}

function Test-ChineseFriendlyLine {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return $false
  }

  $chineseCount = [regex]::Matches($Text, '[\u4e00-\u9fff]').Count
  $latinCount = [regex]::Matches($Text, '[A-Za-z]').Count
  $koreanCount = [regex]::Matches($Text, '[\uac00-\ud7af]').Count

  if ($koreanCount -gt 0) {
    return $false
  }

  if ($chineseCount -lt 4) {
    return $false
  }

  return $latinCount -le [Math]::Max(10, [int]($chineseCount * 0.6))
}

function Get-ChineseDivisionTitle {
  param([string]$Division)

  switch ($Division) {
    'academic' { return '学术专家' }
    'agents' { return '智能体专家' }
    'design' { return '设计专家' }
    'engineering' { return '工程专家' }
    'finance' { return '财务专家' }
    'marketing' { return '内容与市场专家' }
    'product' { return '产品专家' }
    'sales' { return '销售专家' }
    'security' { return '安全专家' }
    'specialized' { return '专项专家' }
    'support' { return '支持专家' }
    'testing' { return '测试专家' }
    default { return '专家成员' }
  }
}

function Get-DisplayRoleTitle {
  param([object]$Role)

  if ($script:TopicIsChinese) {
    return Get-ChineseDivisionTitle ([string]$Role.division)
  }

  return [string]$Role.roleName
}

function Get-ChineseFallbackLine {
  param(
    [object]$Role,
    [string]$Kind,
    [string]$Fallback
  )

  $name = if ($Role.displayName) { [string]$Role.displayName } else { '这个角色' }

  switch ($Kind) {
    'ability' { return "$name 先把问题拆成输入、生成、展示和验收四层，避免把外文资料原句直接搬进发言。" }
    'criteria' { return "$name 的判断标准是：中文议题下，发言必须先中文化、再压缩成自然口语，英文术语只能作为必要名词保留。" }
    'deliverables' { return "$name 需要交付一套可复用的中文发言过滤规则、角色选择规则和回归检查清单。" }
    'risks' { return "$name 看到的主要风险是：角色资料本身多为英文，如果不做语言门禁，会议会继续像中英混杂的资料摘抄。" }
    default { return $Fallback }
  }
}

function ConvertTo-ChineseMeetingText {
  param([string]$Text)

  if (-not $script:TopicIsChinese -or [string]::IsNullOrWhiteSpace($Text)) {
    return $Text
  }

  $line = $Text
  $replacements = [ordered]@{
    'turns' = '发言列表'
    'roleMeta' = '角色信息'
    'participants' = '参会名单'
    'summary' = '会议总结'
    'viewer' = '会议网页'
    'session JSON' = '会议内容文件'
    'session' = '会议内容'
    'Codex/skill' = '技能侧'
    'Codex' = '聊天侧'
    'skill' = '能力'
    'QA' = '质检'
    'JSON' = '数据文件'
  }

  foreach ($key in $replacements.Keys) {
    $line = $line -replace [regex]::Escape($key), $replacements[$key]
  }

  $line = $line -replace '(?<![A-Za-z])UX(?![A-Za-z])', '用户体验'
  $line = $line -replace '(?<![A-Za-z])UI(?![A-Za-z])', '界面'
  $line = $line -replace '(?<![A-Za-z])AI(?![A-Za-z])', '人工智能'
  $line = $line -replace '(?<![A-Za-z])API(?![A-Za-z])', '接口'
  $line = $line -replace '(?<![A-Za-z])SEO(?![A-Za-z])', '搜索优化'

  $line = [regex]::Replace($line, '\s*[A-Za-z][A-Za-z0-9_-]{2,}\s*', '')
  $line = $line -replace '\s+', ' '
  $line = $line -replace '\s+([，。；：！？])', '$1'
  $line = $line -replace '([（【])\s+', '$1'
  $line = $line -replace '\s+([）】])', '$1'
  $line = $line -replace '。。+', '。'
  return $line.Trim()
}

function ConvertTo-ChineseLabel {
  param([string]$Text)

  if (-not $script:TopicIsChinese -or [string]::IsNullOrWhiteSpace($Text)) {
    return $Text
  }

  $line = $Text
  $line = $line -replace '(?<![A-Za-z])UX(?![A-Za-z])', '用户体验'
  $line = $line -replace '(?<![A-Za-z])UI(?![A-Za-z])', '界面'
  $line = $line -replace '(?<![A-Za-z])AI(?![A-Za-z])', '人工智能'
  $line = $line -replace '(?<![A-Za-z])API(?![A-Za-z])', '接口'
  $line = $line -replace '(?<![A-Za-z])SEO(?![A-Za-z])', '搜索优化'
  return $line.Trim()
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

  if ($TopicText -match '会议|会议室|讨论|发言|对话|拟人|主持|流程|专家团|轮流|读稿|反驳|补充') {
    if ($slug -in @('specialized-workflow-architect', 'agents-orchestrator')) { $score += 18 }
    if ($slug -in @('product-manager', 'product-behavioral-nudge-engine')) { $score += 12 }
    if ($slug -in @('academic-psychologist', 'academic-narratologist')) { $score += 12 }
    if ($slug -in @('design-ux-researcher', 'prompt-pack-designer', 'demo-script-producer')) { $score += 10 }
    if ($slug -in @('testing-reality-checker', 'testing-evidence-collector', 'testing-workflow-optimizer')) { $score += 9 }
    if ($slug -eq 'engineering-ai-engineer') { $score += 8 }
  }

  if ($TopicText -match '两个功能|功能一|功能二|员工执行|子任务|派工|确认执行|等待用户确认|单独唤起|开会出方案') {
    if ($slug -in @('agents-orchestrator', 'specialized-workflow-architect')) { $score += 24 }
    if ($slug -in @('product-manager', 'testing-workflow-optimizer')) { $score += 18 }
    if ($slug -in @('engineering-frontend-developer', 'engineering-ai-engineer')) { $score += 12 }
    if ($slug -in @('motion-graphics-director', 'design-ux-architect')) { $score += 8 }
  }

  if ($TopicText -match '网页|动画|viewer|react|前端|界面|ui|视觉|播放|铭牌|屏幕') {
    if ($division -eq 'design') { $score += 5 }
    if ($slug -in @('engineering-frontend-developer', 'design-ux-architect', 'motion-graphics-director', 'visual-qa-inspector')) { $score += 14 }
    if ($slug -in @('testing-accessibility-auditor', 'testing-reality-checker')) { $score += 8 }
  }

  if ($TopicText -match '记忆|知识|人格|资料|检索|筛选|路由|角色') {
    if ($slug -in @('agents-orchestrator', 'specialized-workflow-architect', 'engineering-ai-engineer', 'product-manager')) { $score += 10 }
    if ($slug -in @('engineering-data-engineer', 'testing-evidence-collector', 'engineering-technical-writer')) { $score += 8 }
  }

  if ($TopicText -match '中文|英文|外文|语言|句子|发言|台词|翻译|本地化|汉化|中英|韩文|日文') {
    if ($slug -in @('language-translator', 'marketing-china-market-localization-strategist')) { $score += 18 }
    if ($slug -in @('engineering-technical-writer', 'brand-copywriter', 'seo-content-editor', 'marketing-content-creator')) { $score += 12 }
    if ($slug -in @('specialized-workflow-architect', 'agents-orchestrator', 'product-manager')) { $score += 8 }
  }

  if ($TopicText -match '安全|隐私|key|密钥|外发|合规|泄露') {
    if ($slug -in @('engineering-security-engineer', 'web-scraping-compliance-engineer', 'testing-api-tester')) { $score += 16 }
  }

  if ($TopicText -notmatch '韩国|韩文|korea|korean|kakao' -and $slug -eq 'specialized-korean-business-navigator') {
    $score -= 30
  }

  return $score
}

function Get-PersonaMaterial {
  param(
    [object]$Role,
    [hashtable]$ChineseNames
  )

  $division = [string]$Role.division
  $slug = [string]$Role.slug
  $personaDir = Join-Path (Join-Path $PersonaRoot $division) $slug
  $profile = Read-TextFile (Join-Path $personaDir 'profile.md')
  $summary = Read-TextFile (Join-Path $personaDir 'memory_summary.md')
  $knowledge = Read-TextFile (Join-Path $personaDir 'knowledge.md')
  $memory = Read-TextFile (Join-Path $personaDir 'memory.md')
  $roleCard = Read-TextFile (Resolve-RolePath $RoleRoot $Role)
  $displayName = $ChineseNames["$division|$($Role.name)"]

  if (-not $displayName) {
    $displayName = [string]$Role.name
  }
  $displayName = ConvertTo-ChineseLabel $displayName

  $ability = New-Object System.Collections.Generic.List[string]
  $criteria = New-Object System.Collections.Generic.List[string]
  $deliverables = New-Object System.Collections.Generic.List[string]
  $risks = New-Object System.Collections.Generic.List[string]

  foreach ($line in ($knowledge -split "`r?`n")) {
    if ($line -match '^\s*#') {
      continue
    }

    $plain = ConvertTo-PlainLine $line
    if (-not $plain -or $plain.Length -lt 8) {
      continue
    }

    if ($script:TopicIsChinese -and -not (Test-ChineseFriendlyLine $plain)) {
      continue
    }

    if ($plain -match '本文件保存|收录规则|知识条目|暂无追加资料|初始化时仅保留|每条知识|不收录|与源角色卡冲突|Change Logs') {
      continue
    }

    if ($plain -match '核心领域|核心专长|技术栈|专项能力|部署模式|专业能力|思维模式|工作边界|发现能力|行为心理学|交互节奏|认知负荷|动机强化') {
      $ability.Add($plain)
    } elseif ($plain -match '判断准则|生产标准|数据驱动|原则|标准|方法') {
      $criteria.Add($plain)
    } elseif ($plain -match '常用交付物|模型与系统|基础设施|文档与报告|交付|用户偏好模式|推动序列|微冲刺|庆祝/强化') {
      $deliverables.Add($plain)
    } elseif ($plain -match '潜在风险|缓解措施|协作对象|风险|红线') {
      $risks.Add($plain)
    }
  }

  $fallback = ConvertTo-PlainLine ([string]$Role.description)

  return [pscustomobject]@{
    slug = $slug
    division = $division
    name = [string]$Role.name
    displayName = $displayName
    roleName = [string]$Role.name
    description = [string]$Role.description
    corpus = "$displayName $($Role.name) $slug $division $($Role.description) $profile $summary $knowledge $memory $roleCard"
    ability = @($ability | Select-Object -First 3)
    criteria = @($criteria | Select-Object -First 3)
    deliverables = @($deliverables | Select-Object -First 3)
    risks = @($risks | Select-Object -First 3)
    fallback = $fallback
  }
}

function Pick-Line {
  param(
    [object]$Role,
    [string]$Kind,
    [string]$Fallback
  )

  $items = @($Role.$Kind)
  if ($script:TopicIsChinese) {
    foreach ($item in $items) {
      if (Test-ChineseFriendlyLine ([string]$item)) {
        return $item
      }
    }

    return Get-ChineseFallbackLine $Role $Kind $Fallback
  }

  if ($items.Count -gt 0) {
    return $items[0]
  }

  if ($Role.fallback) {
    return $Role.fallback
  }

  return $Fallback
}

function New-Turn {
  param(
    [string]$Id,
    [string]$SpeakerId,
    [string]$Phase,
    [string]$Type,
    [string]$ScreenTitle,
    [string]$ScreenStatus,
    [string]$Text,
    [string]$TargetId = ''
  )

  $Text = ConvertTo-ChineseMeetingText $Text

  $turn = [ordered]@{
    id = $Id
    speakerId = $SpeakerId
    phase = $Phase
    type = $Type
    screenTitle = $ScreenTitle
    screenStatus = $ScreenStatus
    text = $Text
  }

  if ($TargetId) {
    $turn.targetId = $TargetId
  }

  return $turn
}

function Get-RoleLabel {
  param([object]$Role)

  if ($Role -and $Role.displayName) {
    return [string]$Role.displayName
  }

  return '这位专家'
}

function Get-TopicFocus {
  param([string]$Text)

  $focus = $Text -replace '^(专家团|会议室)\s*', ''
  if ($focus -match '[:：]') {
    $parts = $focus -split '[:：]'
    $tail = ($parts | Select-Object -Last 1).Trim()
    if ($tail.Length -ge 8) {
      $focus = $tail
    }
  }

  $focus = $focus -replace '请讨论|讨论一下|怎么解决|如何解决|更新方案|确认会|复核会|检查', ''
  $focus = $focus -replace '\s+', ''
  $focus = $focus.Trim('：', ':', '，', '。', '；', ';', ' ')

  if ($focus.Length -gt 34) {
    return $focus.Substring(0, 34) + '...'
  }

  if ($focus) {
    return $focus
  }

  return '这个议题'
}

function Get-RoleVoiceProfile {
  param([object]$Role)

  $slug = [string]$Role.slug
  $division = [string]$Role.division
  $name = Get-RoleLabel $Role

  $lens = switch -Regex ($slug) {
    'agents-orchestrator' { '谁应该回应谁、什么时候换人接话、上下文有没有真正传下去' ; break }
    'workflow' { '触发条件、状态流和什么时候该收束' ; break }
    'product|behavioral|utility' { '用户会不会误解承诺、流程会不会越过用户控制' ; break }
    'frontend|web|react|ui|ux|designer|visual|motion|empty-state|form' { '界面暗示、操作节奏和用户一眼看到的状态' ; break }
    'testing|qa|evidence|reality' { '失败路径、验收口径和回归检查' ; break }
    'ai|data|knowledge|technical-writer' { '资料怎样变成判断，而不是直接变成台词' ; break }
    'narratologist|psychologist|academic' { '人的注意力、转折感和对话里的真实犹豫' ; break }
    'copywriter|content|localization|marketing' { '表达是否像给人听，而不是像给系统读' ; break }
    default {
      switch ($division) {
        'engineering' { '实现边界、数据结构和维护成本' }
        'design' { '用户感知、画面状态和交互暗示' }
        'testing' { '验收、失败路径和证据' }
        'product' { '用户承诺、优先级和取舍' }
        'academic' { '概念是否成立、推理是否连贯' }
        'marketing' { '表达、受众理解和传播风险' }
        default { '这件事真正影响到的工作边界' }
      }
    }
  }

  $manner = switch ($division) {
    'testing' { '先挑失败场景' }
    'design' { '先看用户感知' }
    'engineering' { '先落到实现代价' }
    'product' { '先问承诺和边界' }
    'academic' { '先拆概念是否成立' }
    'marketing' { '先看表达会不会被误读' }
    default { '先把判断压实' }
  }

  return [pscustomobject]@{
    name = $name
    lens = $lens
    manner = $manner
  }
}

function New-OrganicMeetingLine {
  param(
    [object]$Role,
    [string]$Move,
    [object]$PreviousRole = $null
  )

  $voice = Get-RoleVoiceProfile $Role
  $previousName = Get-RoleLabel $PreviousRole
  $topicFocus = Get-TopicFocus $Topic

  switch ($Move) {
    'frame' {
      return ('我觉得先别急着下方案。{0}这个问题，真正要看的不是表面流程，而是{1}。如果这一层没弄清楚，后面再多动作也会显得很假。' -f $topicFocus, $voice.lens)
    }
    'build' {
      return ('我同意{0}前面说的方向，但我想补一层：{1}也要被放进判断里。否则大家看起来是在接话，实际还是各说各的。' -f $previousName, $voice.lens)
    }
    'challenge' {
      return ('我不太同意{0}这个前提。从我的专业来看，{1}如果没处理好，会直接导致后面的结论不可信，而不是简单少一个步骤。' -f $previousName, $voice.lens)
    }
    'implementation' {
      return '从我的角度看，可以先做一个很小的改动：每条发言都要说明它接了谁的话、改变了什么判断、留下什么动作。先把这个跑通，再谈更复杂的人格表现。'
    }
    'human' {
      return ('我觉得还要留一点现场感。人说话不会每句都像最终报告，可以有让步、犹豫和修正；但修正最后还是要回到{0}，不然就会变成闲聊。' -f $voice.lens)
    }
    'test' {
      return '从验收角度看，我会盯三件事：有没有接上一位的话，有没有讲出具体后果，有没有把争议压成下一步。缺一个，会议就还是在读稿。'
    }
    'final-check' {
      return ('我补最后一个检查点：这套规则不能只写在文档里，生成出来的每条发言都要能看出{0}。看不出来，就应该判定这轮会议不合格。' -f $voice.lens)
    }
    'response' {
      return ('我接受刚才的质疑，也修正一下我的说法。不是单纯让每个人更口语，而是让每个人有自己的判断位置；{0}要进入发言，但不能变成资料摘抄。' -f $voice.lens)
    }
    default {
      return ('我认为先别急着补复杂机制，先确认{0}。这个点一清楚，后面的方案才不会跑偏。' -f $voice.lens)
    }
  }
}

function Get-NaturalMeetingLine {
  param(
    [object]$Role,
    [string]$Move,
    [object]$PreviousRole = $null
  )

  $slug = [string]$Role.slug
  $name = Get-RoleLabel $Role
  $previousName = Get-RoleLabel $PreviousRole

  if ($script:TopicIsWorkerDispatchPlan) {
    switch ($slug) {
      'product-manager' {
        if ($Move -eq 'frame') { return '我先把边界说死：开会出方案是决策产品，不是执行入口。推荐员工可以出现，但状态必须叫“待确认”，否则用户会以为系统已经替他开工了。' }
        if ($Move -eq 'challenge') { return ('我不同意把推荐员工做得像一个自动按钮。{0} 说的执行链没问题，但产品上要先保护用户的控制感。' -f $previousName) }
        return '产品侧要把两个入口写成两种承诺：功能一承诺给方案和派工建议，功能二承诺真正动手执行。名字、按钮、会后文案都要围绕这个承诺走。'
      }
      'agents-orchestrator' {
        if ($Move -eq 'build') { return '我接着拆执行链：功能二不能只吃最近一次会议，也要支持用户直接丢任务。它启动前先列任务范围、文件边界、交付物和风险，再等一句确认。' }
        if ($Move -eq 'response') { return ('这个限制我接受。{0} 担心的不是技术问题，是越权感；所以派工入口要先展示任务卡，再由用户点头，之后才进入执行。' -f $previousName) }
        return '编排上我建议把推荐员工当候选队列，不是执行队列。候选队列只排序和解释理由，执行队列才分配具体工作。'
      }
      'specialized-workflow-architect' {
        if ($Move -eq 'build') { return '这里需要一张状态机，不然早晚又会混在一起：推荐中、待确认、已批准、执行中、已完成、被阻塞。功能一只能走到待确认。' }
        if ($Move -eq 'challenge') { return ('我补一个硬规则：{0} 的确认门如果只写在文案里不够，数据结构也要限制，功能一根本不能写入执行中状态。' -f $previousName) }
        return '接口上可以很简单：会议产物输出推荐任务；派工入口读取推荐任务并生成执行计划；两个入口共用任务编号，但不共用状态权限。'
      }
      'testing-workflow-optimizer' {
        if ($Move -eq 'challenge') { return '我先按失败场景看：如果用户只想听建议，却看到员工头像开始忙，体验就错了。验收必须检查开会后没有任何文件改动、命令执行或后台任务。' }
        return '测试口径要分两套：功能一测“有没有开会、有没有方案、有没有推荐”；功能二测“有没有确认、有没有执行记录、有没有回填结果”。'
      }
      'engineering-ai-engineer' {
        return '工程实现上，执行入口要重新构造上下文，不能直接拿会议台词当任务说明。它应该读取结构化推荐项，再补齐约束、路径、验收和失败回滚。'
      }
      'engineering-frontend-developer' {
        return '前端上我会把会议结果区分成两层：上面是方案结论，下面是“建议派工”。建议派工不显示运行态动画，只显示等待确认。'
      }
      'motion-graphics-director' {
        return '员工工作动画应该放在功能二启动后。功能一最多展示“推荐名单已生成”，不要让角色动起来，不然画面语言会骗用户。'
      }
    }
  }

  return New-OrganicMeetingLine $Role $Move $PreviousRole
}

function Add-NaturalTurn {
  param(
    [System.Collections.Generic.List[object]]$Turns,
    [string]$Id,
    [object]$Role,
    [string]$Phase,
    [string]$Type,
    [string]$ScreenTitle,
    [string]$ScreenStatus,
    [string]$Move,
    [object]$PreviousRole = $null
  )

  if (-not $Role) {
    return
  }

  $text = Get-NaturalMeetingLine $Role $Move $PreviousRole
  $targetId = if ($PreviousRole) { [string]$PreviousRole.slug } else { '' }
  $Turns.Add((New-Turn $Id ([string]$Role.slug) $Phase $Type $ScreenTitle $ScreenStatus $text $targetId))
}

function Get-SelectedRoleId {
  param(
    [object[]]$Roles,
    [string[]]$PreferredSlugs,
    [int]$FallbackIndex = 0
  )

  foreach ($slug in $PreferredSlugs) {
    $match = $Roles | Where-Object { $_.slug -eq $slug } | Select-Object -First 1
    if ($match) {
      return [string]$match.slug
    }
  }

  if ($Roles.Count -gt $FallbackIndex) {
    return [string]$Roles[$FallbackIndex].slug
  }

  return 'host'
}

function New-PlanItem {
  param(
    [string]$Id,
    [string]$Title,
    [string]$Owner,
    [string]$Deliverable,
    [string]$Acceptance
  )

  return [ordered]@{
    id = $Id
    title = $Title
    owner = $Owner
    deliverable = $Deliverable
    acceptance = $Acceptance
  }
}

function Get-WorkerTask {
  param([object]$Role)

  $slug = [string]$Role.slug
  $division = [string]$Role.division

  if ($slug -eq 'agents-orchestrator') {
    return '把会议触发链路拆成可执行子任务，标明每个子任务的输入、输出、验收口径和阻塞条件。'
  }
  if ($slug -eq 'specialized-workflow-architect') {
    return '设计会议状态机：开场、分歧、回应、修正、决议、员工派工、会后沉淀。'
  }
  if ($slug -eq 'product-manager') {
    return '定义会议室能力的产品成功标准：触发即开会、网页展示为主、聊天侧只同步必要结论。'
  }
  if ($slug -eq 'engineering-frontend-developer' -or $slug -eq 'web-game-engineer') {
    return '实现会议网页的会议产物展示区，并预留“员工正在工作”动画状态。'
  }
  if ($slug -match 'designer|visualization|dashboard|design') {
    return '设计网页里的实施方案、员工任务和会议结论展示层级，保证可扫描、不像报告堆字。'
  }
  if ($slug -match 'testing|qa|reality|evidence') {
    return '制定验收清单：是否真实开会、是否有反驳、是否有可派工任务、是否能复盘。'
  }
  if ($slug -match 'ai|data|knowledge') {
    return '检查人格资料、知识库和记忆摘要如何参与发言生成，避免角色卡原文混进台词。'
  }
  if ($division -eq 'engineering') {
    return '负责把会议方案落到脚本、JSON schema 和稳定运行链路。'
  }

  return '围绕本议题给出专业审查，输出一个能交给执行者继续推进的具体建议。'
}

$context = (& $buildContextScript -Topic $Topic -ParticipantCount 10 -SkillRoot $SkillRoot) | ConvertFrom-Json
if (-not $context.ok) {
  throw 'Failed to build meeting authoring context.'
}

$selected = @()
foreach ($item in @($context.roleContexts)) {
  $selected += [pscustomobject]@{
    slug = [string]$item.slug
    displayName = [string]$item.displayName
    roleName = [string]$item.roleName
    division = [string]$item.division
  }
}

$ParticipantCount = [Math]::Max(5, [Math]::Min(10, $ParticipantCount))
$liveParticipantCount = [Math]::Min($ParticipantCount, $selected.Count)
$ambientParticipantCount = [Math]::Max(0, [Math]::Min(10 - $liveParticipantCount, $selected.Count - $liveParticipantCount))
$liveParticipants = @($selected | Select-Object -First $liveParticipantCount)
$ambientStatePool = @(
  [ordered]@{ ambientState = 'zzz'; ambientVote = 'z' },
  [ordered]@{ ambientState = 'nod'; ambientVote = 'b' },
  [ordered]@{ ambientState = 'reserve'; ambientVote = 'z' },
  [ordered]@{ ambientState = 'thinking'; ambientVote = 'z' },
  [ordered]@{ ambientState = 'phone'; ambientVote = 'z' }
)
$ambientStateCycle = @($ambientStatePool | Sort-Object { Get-Random })
$ambientParticipants = @()
for ($ambientIndex = 0; $ambientIndex -lt $ambientParticipantCount; $ambientIndex++) {
  $role = $selected[$liveParticipantCount + $ambientIndex]
  $state = $ambientStateCycle[$ambientIndex % $ambientStateCycle.Count]
  $ambientParticipants += [ordered]@{
    slug = [string]$role.slug
    displayName = [string]$role.displayName
    roleName = [string]$role.roleName
    side = if ((($liveParticipantCount + $ambientIndex) % 2) -eq 0) { 'left' } else { 'right' }
    ambientState = [string]$state.ambientState
    ambientVote = [string]$state.ambientVote
    division = [string]$role.division
  }
}

function Get-AmbientSpeakingParticipants {
  param([object[]]$AmbientParticipants)
  return @($AmbientParticipants | Where-Object { $_.ambientState -in @('nod', 'reserve', 'thinking') })
}

function Get-AmbientSpeakingText {
  param(
    [object]$Ambient,
    [string]$PreviousSpeakerName = ''
  )

  $previous = if ($PreviousSpeakerName) { [string]$PreviousSpeakerName } else { '前面的意见' }
  switch ([string]$Ambient.ambientState) {
    'nod' { return "对对对，$previous 这句是有道理的。我先跟当前多数方案。" }
    'reserve' { return '我保留意见。现在我先投弃权，等验收口径和风险再清楚一点再落边。' }
    'thinking' { return '我再想想。现在我先弃权，但我还想再听一轮更具体的落地方案。' }
    default { return '' }
  }
}

function Get-JuryVoteCounts {
  param([hashtable]$Votes)
  $counts = [ordered]@{ a = 0; b = 0; z = 0 }
  foreach ($entry in $Votes.GetEnumerator()) {
    $side = ([string]$entry.Value).ToLowerInvariant()
    if ($counts.Contains($side)) { $counts[$side] += 1 }
  }
  return $counts
}

function New-JuryVoteRound {
  param(
    [int]$RoundNumber,
    [string]$AfterTurnId,
    [hashtable]$Votes
  )
  $roundVotes = [ordered]@{}
  foreach ($entry in $Votes.GetEnumerator()) {
    $roundVotes[[string]$entry.Key] = [string]$entry.Value
  }
  return [ordered]@{
    roundIndex = $RoundNumber
    label = "第${RoundNumber}轮投票"
    afterTurnId = $AfterTurnId
    votes = $roundVotes
  }
}

$r = $liveParticipants
$turns = New-Object System.Collections.Generic.List[object]
$voteRounds = @()
$deliberationConfig = [ordered]@{
  enabled = $true
  labelA = '方案A'
  labelB = '方案B'
  labelZ = '弃权'
  detailA = '支持继续推进'
  detailB = '支持暂缓推进'
  detailZ = '暂不表态'
  optionA = '支持继续推进'
  optionB = '支持暂缓推进'
  optionZ = '暂不表态'
  voteRounds = @()
}

$openingText = "大家好，本次会议的主题是：$Topic。我们先围绕两种观点选边，再在选边过程中补充方案，最后收束成一版优化后的方案。"
$turns.Add((New-Turn 'opening' 'host' '开场' 'speak' '议题拆解' 'OPEN' $openingText))

$initialVotes = [ordered]@{}
for ($i = 0; $i -lt $liveParticipants.Count; $i++) {
  $role = $liveParticipants[$i]
  $initialVotes[[string]$role.slug] = if ($i -lt [Math]::Ceiling($liveParticipants.Count / 2)) { 'a' } else { 'b' }
}
$initialCounts = Get-JuryVoteCounts $initialVotes
$turns.Add((New-Turn 'host-vote-1' 'host' '第一轮投票' 'vote' '投票' 'VOTE' '先做第一轮投票：支持路线 A 投 A，支持路线 B 投 B，暂不表态投弃权。'))
$voteRounds += (New-JuryVoteRound -RoundNumber 1 -AfterTurnId 'host-vote-1' -Votes $initialVotes)
$turns.Add((New-Turn 'host-r1-start' 'host' '第一轮发言' 'control' '票数' 'ROUND' ("第一轮票数公布：A $($initialCounts.a) 票，弃权 $($initialCounts.z) 票，B $($initialCounts.b) 票。下面进入第一轮发言。")))

if ($r.Count -ge 1) { Add-NaturalTurn $turns 'point-1' $r[0] '先定边界' 'speak' '边界' 'POINT' 'frame' }
if ($r.Count -ge 2) { Add-NaturalTurn $turns 'build-1' $r[1] '顺着推进' 'speak' '补充' 'BUILD' 'build' $r[0] }
if ($r.Count -ge 3) { Add-NaturalTurn $turns 'challenge-1' $r[2] '提出异议' 'speak' '异议' 'CHECK' 'challenge' $r[1] }
if ($r.Count -ge 4) { Add-NaturalTurn $turns 'implementation-1' $r[3] '压成做法' 'speak' '落地' 'PLAN' 'implementation' $r[0] }
if ($r.Count -ge 5) { Add-NaturalTurn $turns 'human-1' $r[4] '体验视角' 'speak' '体验' 'HUMAN' 'human' $r[3] }
if ($r.Count -ge 6) { Add-NaturalTurn $turns 'test-1' $r[5] '验收口径' 'speak' '验收' 'TEST' 'test' $r[4] }

$speakingAmbientParticipants = @(Get-AmbientSpeakingParticipants $ambientParticipants)
$ambientTurnIndex = 0
$ambientAnchorName = if ($r.Count -gt 0) { Get-RoleLabel $r[[Math]::Min([Math]::Max(0, $r.Count - 1), 4)] } else { '' }
foreach ($ambient in $speakingAmbientParticipants) {
  $ambientTurnIndex += 1
  $ambientText = Get-AmbientSpeakingText -Ambient $ambient -PreviousSpeakerName $ambientAnchorName
  if (-not [string]::IsNullOrWhiteSpace($ambientText)) {
    $phase = switch ([string]$ambient.ambientState) {
      'nod' { '氛围附和' }
      'reserve' { '保留意见' }
      'thinking' { '继续思考' }
      default { '氛围补充' }
    }
    $screenTitle = switch ([string]$ambient.ambientState) {
      'nod' { '附和' }
      'reserve' { '弃权' }
      'thinking' { '再想想' }
      default { '氛围' }
    }
    $screenStatus = switch ([string]$ambient.ambientState) {
      'nod' { 'BUILD' }
      'reserve' { 'HOLD' }
      'thinking' { 'THINK' }
      default { 'POINT' }
    }
    $turns.Add((New-Turn ("ambient-$($ambient.ambientState)-$ambientTurnIndex") ([string]$ambient.slug) $phase 'speak' $screenTitle $screenStatus $ambientText))
  }
}

$finalVotes = [ordered]@{}
foreach ($role in $liveParticipants) {
  $finalVotes[[string]$role.slug] = 'a'
}
$finalCounts = Get-JuryVoteCounts $finalVotes
$turns.Add((New-Turn 'host-vote-2' 'host' '最终一轮投票' 'vote' '最终投票' 'VOTE' '听完这一轮观点，我们做最终一轮投票，确认 A/B 正式票是否已经统一。'))
$voteRounds += (New-JuryVoteRound -RoundNumber 2 -AfterTurnId 'host-vote-2' -Votes $finalVotes)
$turns.Add((New-Turn 'host-r2-result' 'host' '最终结果' 'control' '结果公布' 'RESULT' ("最终结果公布：A $($finalCounts.a) 票，弃权 $($finalCounts.z) 票，B $($finalCounts.b) 票。A/B 正式票已经统一，会议收束。")))
$turns.Add((New-Turn 'host-final' 'host' '主持收束' 'conclusion' '结论' 'DONE' '主持收束：正式票已经统一，剩余弃权票记入保留意见。下一步把两边方案折成一版优化后的统一方案。'))
$deliberationConfig.voteRounds = @($voteRounds)

if ($script:TopicIsMeetingNaturalnessIssue) {
  $implementationPlan = @(
    (New-PlanItem 'P0-1' '删掉固定九段式台词' (Get-SelectedRoleId $selected @('specialized-workflow-architect', 'agents-orchestrator') 0) '把发言生成从固定句式改成会议动作：定边界、接话、反驳、修正、验收、收束。' '同一场会里不再反复出现“我先抛一个判断、我接一下、我来当刹车”等固定开头。'),
    (New-PlanItem 'P0-2' '资料只做依据，不直接进台词' (Get-SelectedRoleId $selected @('engineering-ai-engineer', 'engineering-technical-writer') 1) '角色资料和知识库只用于判断角色立场，不能整句摘抄到发言里。' '抽查会议发言时，不出现角色卡原文、英文资料句或说明书式长句。'),
    (New-PlanItem 'P1-1' '建立回应链' (Get-SelectedRoleId $selected @('academic-narratologist', 'product-manager') 2) '每个非开场发言必须回应上一位观点、提出取舍或把争议压成验收标准。' '连续发言之间有明确承接、反驳、让步或改向，不再像独立段落拼接。'),
    (New-PlanItem 'P1-2' '增加自然度验收' (Get-SelectedRoleId $selected @('testing-workflow-optimizer', 'academic-psychologist') 3) '增加重复句式、资料摘抄、无回应发言、过度完整书面语四类检查。' '生成后能自动标出机械句式风险，并阻止明显读稿式会议进入展示。'),
    (New-PlanItem 'P2-1' '保留现场感但不装腔' (Get-SelectedRoleId $selected @('brand-copywriter', 'academic-psychologist') 4) '允许短句、追问、承认不确定和半步修正，让角色像现场思考。' '发言更口语，但仍输出可执行结论，不变成闲聊。')
  )
} elseif ($script:TopicIsWorkerDispatchPlan) {
  $implementationPlan = @(
    (New-PlanItem 'P0-1' '拆成两个独立入口' (Get-SelectedRoleId $selected @('agents-orchestrator', 'specialized-workflow-architect') 0) '定义“开会出方案”和“员工执行子任务”两个可单独唤起的入口。' '用户说会议室开会时只进入功能一；用户说派工、执行、让员工跑时才进入功能二。'),
    (New-PlanItem 'P0-2' '功能一只推荐不执行' (Get-SelectedRoleId $selected @('product-manager', 'testing-workflow-optimizer') 1) '会议结束产出结论、实施方案、推荐员工和待确认子任务。' '功能一结束后所有推荐员工状态必须是“待用户确认”，不得自动执行。'),
    (New-PlanItem 'P0-3' '功能二读取会议产物执行' (Get-SelectedRoleId $selected @('agents-orchestrator', 'engineering-ai-engineer') 2) '功能二读取最近一次会议的推荐员工列表，也允许用户直接给任务清单。' '进入执行前必须再次列出任务范围、交付物和风险，得到确认后才开跑。'),
    (New-PlanItem 'P1-1' '补状态机和数据字段' (Get-SelectedRoleId $selected @('specialized-workflow-architect', 'engineering-frontend-developer') 3) '为推荐子任务增加 pending、approved、running、done、blocked 状态。' '网页和聊天侧都能区分“推荐中”和“执行中”，避免用户误以为已经开始干活。'),
    (New-PlanItem 'P1-2' '预留员工工作动画' (Get-SelectedRoleId $selected @('motion-graphics-director', 'engineering-frontend-developer') 4) '功能二启动后再展示员工进入工作台、任务卡流转和完成回填。' '员工工作动画只在执行入口触发，不在单纯开会时提前出现。')
  )
} else {
  $implementationPlan = @(
    (New-PlanItem 'P0-1' '触发即拉起内置会议页' (Get-SelectedRoleId $selected @('agents-orchestrator', 'specialized-workflow-architect') 0) '统一启动流程：准备会议内容、启动会议网页、导航内置浏览器。' '触发会议室后，内置浏览器必须确认加载本次会议主题；失败时才进入默认浏览器兜底。'),
    (New-PlanItem 'P0-2' '网页成为会议主载体' (Get-SelectedRoleId $selected @('admin-dashboard-designer', 'data-visualization-designer', 'design-system-architect') 1) '会议网页显示发言、实施方案、推荐员工子任务和结论。' '聊天侧回复只保留会议已启动、关键结论、执行建议，不再粘贴完整会议过程。'),
    (New-PlanItem 'P1-1' '会议必须产出可实施方案' (Get-SelectedRoleId $selected @('product-manager', 'specialized-workflow-architect') 2) '会议总结里的实施方案固定包含负责人、交付物和验收口径。' '每场会至少 3 条可执行方案，且能直接转成开发、研究或设计子任务。'),
    (New-PlanItem 'P1-2' '推荐专业员工跑子任务' (Get-SelectedRoleId $selected @('agents-orchestrator', 'product-manager') 3) '会议总结里的推荐员工固定包含角色、任务、范围、交付物和优先级。' '会议结束后能列出 3-6 个专业员工建议，不再只说“下一步”。'),
    (New-PlanItem 'P2-1' '员工工作中动画预留' (Get-SelectedRoleId $selected @('motion-graphics-director', 'web-game-engineer') 4) '新增后续动画构想，后续会议网页可切换为员工工作状态。' '当前不强做动画，但数据结构和界面文案为后续留入口。')
  )
}

$recommendedWorkers = @()
$workerIndex = 0
foreach ($role in ($liveParticipants | Select-Object -First ([Math]::Min(6, $liveParticipants.Count)))) {
  $workerIndex += 1
  $recommendedWorkers += [ordered]@{
    roleId = [string]$role.slug
    name = [string]$role.displayName
    title = Get-DisplayRoleTitle $role
    priority = if ($script:TopicIsChinese) {
      if ($workerIndex -le 2) { '高优先级' } elseif ($workerIndex -le 4) { '中优先级' } else { '低优先级' }
    } else {
      if ($workerIndex -le 2) { 'P0' } elseif ($workerIndex -le 4) { 'P1' } else { 'P2' }
    }
    task = Get-WorkerTask $role
    scope = '只负责本轮会议结论拆出的对应子任务，不跨边界修改无关模块。'
    deliverable = '输出可验收的改动、报告或方案，并在完成后回填会议行动项状态。'
  }
}

$roleMeta = [ordered]@{
  host = [ordered]@{ name = '主持人'; title = '会议主持'; lane = 'center' }
}

$experts = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $liveParticipants.Count; $i++) {
  $role = $liveParticipants[$i]
  $lane = if ($i % 2 -eq 0) { 'left' } else { 'right' }
  $roleMeta[$role.slug] = [ordered]@{
    name = $role.displayName
    title = Get-DisplayRoleTitle $role
    lane = $lane
  }
  $experts.Add([ordered]@{
    id = $role.slug
    displayName = $role.displayName
    roleName = Get-DisplayRoleTitle $role
    side = $lane
  })
}

foreach ($ambient in $ambientParticipants) {
  $roleMeta[$ambient.slug] = [ordered]@{
    name = [string]$ambient.displayName
    title = [string]$ambient.roleName
    lane = $ambient.side
    ambientState = $ambient.ambientState
    ambientVote = $ambient.ambientVote
    division = $ambient.division
  }
  $experts.Add([ordered]@{
    id = $ambient.slug
    displayName = [string]$ambient.displayName
    roleName = [string]$ambient.roleName
    side = $ambient.side
  })
}

$now = Get-Date
$participantIds = @('host')
$participantIds += @($liveParticipants | ForEach-Object { [string]$_.slug })
$participantIds += @($ambientParticipants | ForEach-Object { [string]$_.slug })
$turnArray = @()
foreach ($turn in $turns) {
  $turnArray += $turn
}
$expertArray = @()
foreach ($expert in $experts) {
  $expertArray += $expert
}
$timeline = @()
foreach ($turn in $turnArray) {
  $timelineItem = [ordered]@{
    type = $turn.type
    speaker = $turn.speakerId
    stance = $turn.phase
    text = $turn.text
  }
  if ($turn.targetId) {
    $timelineItem.target = $turn.targetId
  }
  $timeline += $timelineItem
}
$consensus = if ($script:TopicIsMeetingNaturalnessIssue) {
  @(
    '功能一发言机械的根因是生成器使用固定九段式台词，并把角色资料句直接拼进发言。',
    '修复方向不是增加更多模板，而是让每次发言必须回应上一位、提出取舍或贡献验收标准。',
    '角色专业知识只能作为判断依据，台词必须重新口语化，避免资料摘抄和说明书腔。'
  )
} elseif ($script:TopicIsWorkerDispatchPlan) {
  @(
    '会议室 skill 应明确拆成两个功能：功能一负责开会出方案，功能二负责员工执行子任务。',
    '功能一可以推荐功能二的员工和任务，但必须停在“待确认”状态，不允许自动执行。',
    '功能二既可以从最近一次会议产物接任务，也可以被用户直接用派工指令唤起。'
  )
} else {
  @(
    '会议应由真实筛选角色和人格资料驱动，不再只播放固定默认脚本。',
    '会议网页只负责播放已准备的会议内容，角色选择、资料读取和争议组织放在技能侧。',
    '讨论流程需要允许接话、反驳、修正和收束，而不是每人固定一句。'
  )
}
$nextActions = if ($script:TopicIsMeetingNaturalnessIssue) {
  @(
    '删除固定开头句式，改为按会议动作生成发言。',
    '增加自然度检查：重复句式、资料摘抄、无承接发言、书面语过重。',
    '用同一议题连续生成两场会议，检查发言是否仍像同一个模板。'
  )
} elseif ($script:TopicIsWorkerDispatchPlan) {
  @(
    '把 skill 规范写成两个入口：开会入口和派工入口。',
    '给推荐员工子任务增加待确认、已批准、执行中、完成、阻塞状态。',
    '先实现功能二的确认门，再考虑员工正在工作的动画。'
  )
} else {
  @(
    '继续完善筛人评分和关键词路由。',
    '把会后结论写回可控的记忆摘要或报告。',
    '用真实议题录制一轮会议，检查是否仍像读稿。'
  )
}
$futureAnimationIdea = if ($script:TopicIsMeetingNaturalnessIssue) {
  '后续可把会议动画和自然发言状态联动：角色被反驳时轻微停顿，回应时看向上一位发言者，收束时主持人再亮屏。'
} elseif ($script:TopicIsWorkerDispatchPlan) {
  '后续员工工作动画应绑定功能二：只有用户确认派工后，会议网页才切到员工工作台、任务卡流转、完成回填和复盘状态。'
} else {
  '后续可在会议网页增加“员工正在工作”状态：会议结束后展示被推荐员工进入工作台、任务卡流转、完成回填和下一场复盘。'
}
$session = [ordered]@{
  version = '1.1.0'
  id = 'meeting-' + $now.ToString('yyyyMMdd-HHmmss')
  startedAt = $now.ToUniversalTime().ToString('o')
  layout = 'vertical-long-table'
  title = $Topic
  topic = $Topic
  generator = 'meeting-room/new_visual_meeting_session.ps1'
  mode = $Mode
  deliberation = $deliberationConfig
  participants = $participantIds
  roleMeta = $roleMeta
  turns = $turnArray
  visualTranscript = [ordered]@{
    version = '1.0.0'
    layout = 'vertical-long-table'
    title = $Topic
    topic = $Topic
    participants = [ordered]@{
      host = [ordered]@{ id = 'host'; displayName = '主持人'; roleName = '会议主持' }
      experts = $expertArray
    }
    timeline = $timeline
  }
  summary = [ordered]@{
    consensus = $consensus
    nextActions = $nextActions
    implementationPlan = $implementationPlan
    recommendedWorkers = $recommendedWorkers
    futureAnimationIdea = $futureAnimationIdea
  }
}

$json = $session | ConvertTo-Json -Depth 12

if ($Apply) {
  Write-TextFile $OutFile $json
}

[pscustomobject]@{
  ok = $true
  topic = $Topic
  participant_count = $liveParticipants.Count
  participants = @($liveParticipants | ForEach-Object { $_.slug })
  out_file = if ($Apply) { [System.IO.Path]::GetFullPath($OutFile) } else { '' }
  session_url = 'current-session.json'
} | ConvertTo-Json -Depth 6
