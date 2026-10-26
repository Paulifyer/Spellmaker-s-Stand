param(
    [ValidateRange(5, 30)]
    [int]$Seconds = 15
)

$ErrorActionPreference = 'Stop'
$taskIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$taskPrincipal = New-Object Security.Principal.WindowsPrincipal($taskIdentity)
if (-not $taskPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open PowerShell as administrator, then run this script again.'
}

$taskXperf = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/Windows Performance Toolkit/xperf.exe'
if (-not (Test-Path -LiteralPath $taskXperf)) {
    throw 'xperf.exe was not found. Install the Windows Performance Toolkit first.'
}

$taskProject = Split-Path -Parent $PSScriptRoot
$taskStamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$taskFolder = Join-Path $taskProject "diagnostics/traces/device-changes-$taskStamp"
New-Item -ItemType Directory -Path $taskFolder -Force | Out-Null
$taskTrace = Join-Path $taskFolder 'device-changes.etl'
$taskSession = 'SpellDeviceChanges-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$taskStarted = $false

Get-Process | Select-Object ProcessName, Id |
    Export-Csv -LiteralPath (Join-Path $taskFolder 'processes-start.csv') -NoTypeInformation -Encoding UTF8

try {
    # MessagePump records window-message sender/receiver IDs; PnP records device changes.
    $taskProviders = 'Microsoft-Windows-Win32k:0x400000:5+Microsoft-Windows-Kernel-PnP:0xffffffffffffffff:5'
    & $taskXperf -start $taskSession -on $taskProviders -f $taskTrace
    if ($LASTEXITCODE -ne 0) {
        throw "Starting the trace failed (exit code $LASTEXITCODE)."
    }
    $taskStarted = $true
    Write-Host "Recording for $Seconds seconds. Switch to the already-running game now."
    Start-Sleep -Seconds $Seconds
} finally {
    if ($taskStarted) {
        & $taskXperf -stop $taskSession
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Stopping the trace failed. Run: & '$taskXperf' -stop '$taskSession'"
        }
    }
}

Get-Process | Select-Object ProcessName, Id |
    Export-Csv -LiteralPath (Join-Path $taskFolder 'processes-end.csv') -NoTypeInformation -Encoding UTF8
Write-Host "Capture saved to: $taskFolder"
