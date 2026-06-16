param(
  [int]$Port = 5175,
  [switch]$OpenDefaultBrowser,
  [int]$TimeoutSeconds = 15
)

$ErrorActionPreference = 'Stop'

function Test-ViewerServer {
  param([string]$Url)

  try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
    return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
  } catch {
    return $false
  }
}

function Write-LaunchResult {
  param([hashtable]$Result)

  [pscustomobject]$Result | ConvertTo-Json -Depth 6
}

$skillRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')
$viewerPath = Join-Path $skillRoot 'assets\expert-meeting-viewer\react-viewer'
$url = "http://127.0.0.1:$Port/"
$result = [ordered]@{
  ok = $false
  url = $url
  viewerPath = $viewerPath
  server = 'not_started'
  processId = $null
  defaultBrowser = if ($OpenDefaultBrowser) { 'pending' } else { 'not_requested' }
  message = ''
}

if (-not (Test-Path -LiteralPath $viewerPath)) {
  $result.server = 'missing_viewer'
  $result.message = 'React viewer path does not exist. Return the URL only after fixing the skill assets.'
  Write-LaunchResult $result
  exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $viewerPath 'node_modules'))) {
  $packageLock = Join-Path $viewerPath 'package-lock.json'
  $installArgs = if (Test-Path -LiteralPath $packageLock) { @('ci') } else { @('install') }
  $install = Start-Process -FilePath 'npm.cmd' -ArgumentList $installArgs -WorkingDirectory $viewerPath -WindowStyle Hidden -Wait -PassThru

  if ($install.ExitCode -ne 0) {
    $result.server = 'dependency_install_failed'
    $result.message = 'Unable to install viewer dependencies. Return the URL and ask the user to review npm output.'
    Write-LaunchResult $result
    exit $install.ExitCode
  }
}

if (Test-ViewerServer $url) {
  $result.ok = $true
  $result.server = 'existing'
} else {
  $arguments = @('run', 'dev', '--', '--host', '127.0.0.1', '--port', [string]$Port, '--strictPort')
  $server = Start-Process -FilePath 'npm.cmd' -ArgumentList $arguments -WorkingDirectory $viewerPath -WindowStyle Hidden -PassThru
  $result.server = 'starting'
  $result.processId = $server.Id

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-ViewerServer $url) {
      $result.ok = $true
      $result.server = 'started'
      break
    }

    Start-Sleep -Milliseconds 400
  }

  if (-not $result.ok) {
    $result.server = 'start_timeout'
    $result.message = 'Viewer server did not become ready before timeout. Return the URL as manual fallback.'
    Write-LaunchResult $result
    exit 2
  }
}

if ($OpenDefaultBrowser) {
  try {
    Start-Process $url
    $result.defaultBrowser = 'opened'
  } catch {
    $result.defaultBrowser = 'failed'
    $result.message = 'Default browser launch failed or was blocked. Return the URL to the user.'
    Write-LaunchResult $result
    exit 3
  }
}

if (-not $result.message) {
  $result.message = 'Viewer is ready. Prefer Codex built-in browser first; use default browser fallback only when built-in browser is unavailable.'
}

Write-LaunchResult $result
