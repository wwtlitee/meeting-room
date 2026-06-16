param(
  [string]$LinkText = '打开可视化会议',
  [string]$WindowTitlePattern = 'Codex',
  [int]$TimeoutSeconds = 6
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class AgencyMeetingLinkClickWin32 {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int processId);
}
'@

function Get-VisibleWindow {
  param([string]$TitlePattern)

  $windows = New-Object System.Collections.Generic.List[object]
  [AgencyMeetingLinkClickWin32]::EnumWindows({
    param($handle, $lParam)

    if (-not [AgencyMeetingLinkClickWin32]::IsWindowVisible($handle)) {
      return $true
    }

    $titleBuilder = New-Object System.Text.StringBuilder 512
    [void][AgencyMeetingLinkClickWin32]::GetWindowText($handle, $titleBuilder, $titleBuilder.Capacity)
    $title = $titleBuilder.ToString()
    if ($title -notmatch $TitlePattern) {
      return $true
    }

    $processId = 0
    [void][AgencyMeetingLinkClickWin32]::GetWindowThreadProcessId($handle, [ref]$processId)
    $windows.Add([pscustomobject]@{
      Handle = $handle
      ProcessId = $processId
      Title = $title
    })
    return $true
  }, [IntPtr]::Zero) | Out-Null

  return @($windows | Select-Object -First 1)
}

function Invoke-ElementOrAncestor {
  param([System.Windows.Automation.AutomationElement]$Element)

  $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
  $current = $Element
  for ($depth = 0; $depth -lt 5 -and $current; $depth++) {
    try {
      $current.SetFocus()
    } catch {
    }

    try {
      $invokePattern = $current.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
      $invokePattern.Invoke()
      return [pscustomobject]@{
        ok = $true
        method = 'invoke'
        depth = $depth
        controlType = $current.Current.ControlType.ProgrammaticName
        name = $current.Current.Name
      }
    } catch {
    }

    $current = $walker.GetParent($current)
  }

  try {
    $Element.SetFocus()
    $shell = New-Object -ComObject WScript.Shell
    $shell.SendKeys('{ENTER}')
    return [pscustomobject]@{
      ok = $true
      method = 'enter'
      depth = 0
      controlType = $Element.Current.ControlType.ProgrammaticName
      name = $Element.Current.Name
    }
  } catch {
  }

  return [pscustomobject]@{
    ok = $false
    method = 'none'
    depth = 0
    controlType = $Element.Current.ControlType.ProgrammaticName
    name = $Element.Current.Name
  }
}

function Find-LatestMeetingLink {
  param(
    [System.Windows.Automation.AutomationElement]$Root,
    [string]$Text
  )

  $rootRect = $Root.Current.BoundingRectangle
  $all = $Root.FindAll(
    [System.Windows.Automation.TreeScope]::Descendants,
    [System.Windows.Automation.Condition]::TrueCondition
  )

  $candidates = New-Object System.Collections.Generic.List[object]
  for ($i = 0; $i -lt $all.Count; $i++) {
    $element = $all.Item($i)
    $name = $element.Current.Name
    if ([string]::IsNullOrWhiteSpace($name) -or $name -notmatch [regex]::Escape($Text)) {
      continue
    }

    $rect = $element.Current.BoundingRectangle
    if (
      $rect.Width -le 0 -or
      $rect.Height -le 0 -or
      $rect.Top -lt $rootRect.Top -or
      $rect.Top -gt $rootRect.Bottom
    ) {
      continue
    }

    $controlType = $element.Current.ControlType.ProgrammaticName
    $score = 0
    if ($name -eq $Text) { $score += 100 }
    if ($name -match ('^' + [regex]::Escape($Text))) { $score += 40 }
    if ($controlType -match 'Hyperlink|Button') { $score += 30 }
    if ($rect.Top -gt ($rootRect.Top + ($rootRect.Height * 0.35))) { $score += 10 }

    $candidates.Add([pscustomobject]@{
      Element = $element
      Name = $name
      ControlType = $controlType
      Score = $score
      Left = $rect.Left
      Top = $rect.Top
      Width = $rect.Width
      Height = $rect.Height
    })
  }

  return @($candidates | Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, @{ Expression = 'Top'; Descending = $true } | Select-Object -First 1)
}

$window = Get-VisibleWindow $WindowTitlePattern
if (-not $window) {
  throw "Codex window not found: $WindowTitlePattern"
}

[void][AgencyMeetingLinkClickWin32]::SetForegroundWindow($window.Handle)
$root = [System.Windows.Automation.AutomationElement]::FromHandle($window.Handle)
if (-not $root) {
  throw "Unable to create UIAutomation root for window: $($window.Title)"
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$target = $null
do {
  $target = Find-LatestMeetingLink -Root $root -Text $LinkText
  if ($target) {
    break
  }
  Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $deadline)

if (-not $target) {
  [pscustomobject]@{
    ok = $false
    linkText = $LinkText
    hostWindow = $window.Title
    message = "Visible meeting link not found: $LinkText"
  } | ConvertTo-Json -Depth 4
  exit 1
}

$invoke = Invoke-ElementOrAncestor -Element $target.Element

[pscustomobject]@{
  ok = [bool]$invoke.ok
  linkText = $LinkText
  hostWindow = $window.Title
  matchedName = $target.Name
  matchedControlType = $target.ControlType
  bounds = [pscustomobject]@{
    left = [math]::Round($target.Left)
    top = [math]::Round($target.Top)
    width = [math]::Round($target.Width)
    height = [math]::Round($target.Height)
  }
  invoke = $invoke
  message = if ($invoke.ok) { "Latest visible meeting link invoked." } else { "Meeting link found, but invoke failed." }
} | ConvertTo-Json -Depth 5

if (-not $invoke.ok) {
  exit 2
}
