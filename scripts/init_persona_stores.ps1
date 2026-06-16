[CmdletBinding()]
param(
    [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$RoleSlug,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$Utf8Bom = [System.Text.UTF8Encoding]::new($true)

function Read-TextFile {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content,
        [bool]$Overwrite
    )

    if ((Test-Path -LiteralPath $Path) -and (-not $Overwrite)) {
        return $false
    }

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8Bom)
    return $true
}

function Expand-Template {
    param(
        [string]$Template,
        [hashtable]$Values
    )

    $result = $Template
    foreach ($key in $Values.Keys) {
        $value = ""
        if ($null -ne $Values[$key]) {
            $value = [string]$Values[$key]
        }
        $result = $result.Replace("{{" + $key + "}}", $value)
    }
    return $result
}

$manifestPath = Join-Path $SkillRoot "references\roles_manifest.json"
$templateRoot = Join-Path $SkillRoot "references\persona_templates"
$personasRoot = Join-Path $SkillRoot "references\personas"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "roles_manifest.json not found: $manifestPath"
}

$templates = @{
    "profile" = Read-TextFile (Join-Path $templateRoot "PROFILE_TEMPLATE.md")
    "knowledge" = Read-TextFile (Join-Path $templateRoot "KNOWLEDGE_TEMPLATE.md")
    "memory" = Read-TextFile (Join-Path $templateRoot "MEMORY_TEMPLATE.md")
    "memory_summary" = Read-TextFile (Join-Path $templateRoot "MEMORY_SUMMARY_TEMPLATE.md")
}

$manifest = Get-Content -Raw -Encoding UTF8 -Path $manifestPath | ConvertFrom-Json
$roles = @($manifest.roles)

if ($RoleSlug) {
    $roles = @($roles | Where-Object { $_.slug -eq $RoleSlug })
    if ($roles.Count -eq 0) {
        throw "RoleSlug not found in manifest: $RoleSlug"
    }
}

$created = 0
$skipped = 0
$generatedAt = Get-Date -Format "yyyy-MM-dd"

foreach ($role in $roles) {
    $division = [string]$role.division
    $slug = [string]$role.slug
    $roleDir = Join-Path (Join-Path $personasRoot $division) $slug
    $rolePath = "../../../roles/$division/$slug.md"

    $values = @{
        "name" = [string]$role.name
        "slug" = $slug
        "division" = $division
        "description" = ([string]$role.description).Replace("`r", " ").Replace("`n", " ")
        "role_path" = $rolePath
        "generated_at" = $generatedAt
    }

    $files = @{
        "profile.md" = Expand-Template $templates.profile $values
        "knowledge.md" = Expand-Template $templates.knowledge $values
        "memory.md" = Expand-Template $templates.memory $values
        "memory_summary.md" = Expand-Template $templates.memory_summary $values
    }

    foreach ($fileName in $files.Keys) {
        $targetPath = Join-Path $roleDir $fileName
        if (Write-TextFile $targetPath $files[$fileName] ([bool]$Force)) {
            $created++
        }
        else {
            $skipped++
        }
    }
}

$storeManifest = [ordered]@{
    generated_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
    source_manifest = "references/roles_manifest.json"
    source_role_count = [int]$manifest.role_count
    initialized_role_count = [int]$roles.Count
    store_root = "references/personas"
    files_per_role = @("profile.md", "knowledge.md", "memory.md", "memory_summary.md")
    compaction_script = "scripts/compact_persona_memory.ps1"
    default_recent_memory_entries = 12
    default_summary_bullets = 24
}

$manifestJson = $storeManifest | ConvertTo-Json -Depth 4
Write-TextFile (Join-Path $SkillRoot "references\persona_store_manifest.json") $manifestJson $true | Out-Null

Write-Host "Persona store initialization complete."
Write-Host "Roles processed: $($roles.Count)"
Write-Host "Files created or overwritten: $created"
Write-Host "Files skipped: $skipped"
