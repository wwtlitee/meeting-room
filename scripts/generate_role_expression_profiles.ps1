param(
  [string]$SkillRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not $SkillRoot) {
  $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
  $SkillRoot = Split-Path -Parent $scriptDir
}

$SkillRoot = [System.IO.Path]::GetFullPath($SkillRoot)
$manifestPath = Join-Path $SkillRoot 'references\roles_manifest.json'
$outPath = Join-Path $SkillRoot 'assets\expert-meeting-viewer\react-viewer\src\roleExpressionProfiles.generated.js'

if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "roles_manifest.json not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$divisionPalettes = @{
  'academic' = @(@('half','soft'), @('half','long'), @('bean','flat'), @('narrow','soft'))
  'design' = @(@('round','smile'), @('wide','smile'), @('bean','firm'), @('focus','flat'), @('surprised','small-o'))
  'engineering' = @(@('focus','long'), @('focus','flat'), @('narrow','long'), @('bean','flat'))
  'finance' = @(@('narrow','firm'), @('focus','firm'), @('half','long'))
  'game-development' = @(@('wide','smile'), @('round','smile'), @('surprised','small-o'), @('focus','flat'), @('bean','firm'))
  'marketing' = @(@('bean','smile'), @('wide','smile'), @('round','smile'), @('surprised','small-o'), @('dot','flat'))
  'paid-media' = @(@('focus','firm'), @('narrow','firm'), @('wide','flat'))
  'product' = @(@('wide','flat'), @('half','soft'), @('focus','long'))
  'project-management' = @(@('dot','flat'), @('wide','flat'), @('half','soft'))
  'sales' = @(@('wide','smile'), @('bean','smile'), @('focus','firm'))
  'spatial-computing' = @(@('surprised','small-o'), @('wide','smile'), @('focus','long'))
  'specialized' = @(@('dot','flat'), @('half','soft'), @('focus','long'), @('narrow','firm'), @('bean','flat'))
  'support' = @(@('half','soft'), @('wide','flat'), @('bean','smile'))
  'testing' = @(@('narrow','firm'), @('focus','firm'), @('half','long'))
}

function Get-StableIndex {
  param(
    [string]$Text,
    [int]$Modulo
  )

  $sum = 0
  $chars = $Text.ToCharArray()
  for ($index = 0; $index -lt $chars.Length; $index += 1) {
    $sum = ($sum + ([int][char]$chars[$index] * ($index + 1))) % 1000003
  }

  return $sum % $Modulo
}

function Get-KeywordProfile {
  param([object]$Role)

  $text = (([string]$Role.slug) + ' ' + ([string]$Role.name)).ToLowerInvariant()

  if ($text -match 'icon|logo|brand|identity') { return @('bean','firm') }
  if ($text -match 'motion|animation|animator|game-feel|gameplay|prototype') { return @('surprised','small-o') }
  if ($text -match 'qa|test|testing|inspector|auditor|reviewer|compliance|legal|risk|security|validator') { return @('narrow','firm') }
  if ($text -match 'architect|system|strategy|strategist|planner|chief|principal') { return @('half','long') }
  if ($text -match 'engineer|developer|scripter|programmer|technical|database|devops|backend|frontend|integration') { return @('focus','long') }
  if ($text -match 'designer|artist|visual|\bui\b|\bux\b|hud|sprite|avatar|asset|creative') { return @('round','smile') }
  if ($text -match 'writer|narrative|story|content|copy|editor|translator|localization') { return @('bean','smile') }
  if ($text -match 'research|analyst|analytics|reporter|data|historian|geographer|psychologist|anthropologist') { return @('half','soft') }
  if ($text -match 'manager|producer|coordinator|coach|scrum|operations|onboarding') { return @('wide','flat') }
  if ($text -match 'sales|outbound|closer|account|customer|community|support') { return @('wide','smile') }
  if ($text -match 'finance|billing|accounting|tax|loan|payment') { return @('narrow','firm') }

  return $null
}

$roles = @($manifest.roles | Sort-Object division, slug)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('// Generated from references/roles_manifest.json. Do not edit by hand.')
$lines.Add('// Regenerate with scripts/generate_role_expression_profiles.ps1, then sync to global.')
$lines.Add('export const generatedRoleExpressionProfileCount = ' + $roles.Count + ';')
$lines.Add('')
$lines.Add('export const generatedRoleExpressionProfiles = {')

$comboCounts = @{}
for ($index = 0; $index -lt $roles.Count; $index += 1) {
  $role = $roles[$index]
  $palette = $divisionPalettes[[string]$role.division]
  if (-not $palette) {
    $palette = @(@('dot','flat'), @('wide','flat'), @('half','soft'))
  }

  $profile = Get-KeywordProfile $role
  if (-not $profile) {
    $profile = $palette[(Get-StableIndex -Text ([string]$role.slug) -Modulo $palette.Count)]
  }

  $comboKey = "$($profile[0])/$($profile[1])"
  $comboCounts[$comboKey] = 1 + [int]$comboCounts[$comboKey]
  $comma = if ($index -lt $roles.Count - 1) { ',' } else { '' }
  $lines.Add("  '$($role.slug)': { eyeVariant: '$($profile[0])', mouthVariant: '$($profile[1])' }$comma")
}

$lines.Add('};')
[System.IO.File]::WriteAllText($outPath, ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))

[pscustomobject]@{
  ok = $true
  outFile = $outPath
  roleCount = $roles.Count
  comboCount = $comboCounts.Count
} | ConvertTo-Json -Depth 4
