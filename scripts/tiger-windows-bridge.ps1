<#
Windows launcher for an unchanged official Tiger Racer binary in WSL.
It does not alter GPU driver modes, pool protocol, proof data, or Racer files.
#>
[CmdletBinding()]
param(
    [ValidateSet('Status', 'Start')]
    [string]$Action = 'Status',
    [Parameter(Mandatory = $true)]
    [string]$WslRacerRoot,
    [string]$Distro = 'Ubuntu',
    [string]$WorkerName = 'windows-launcher',
    [string]$SecretFile,
    [string]$GpuList = '0',
    [string]$GpuGroups = '0'
)

$ErrorActionPreference = 'Stop'
$runner = "$WslRacerRoot/run_tiger_racer.sh"
$logFile = "$WslRacerRoot/logs/$WorkerName.log"

function Invoke-Wsl {
    param(
        [string[]]$Arguments,
        [switch]$AllowFailure
    )
    & wsl.exe -d $Distro -- $Arguments
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) {
        throw "WSL command failed with exit code $LASTEXITCODE."
    }
}

function Convert-WindowsPathToWsl {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ($Path -notmatch '^[A-Za-z]:\\') {
        throw 'SecretFile must be an absolute Windows path.'
    }
    $drive = $Path.Substring(0, 1).ToLowerInvariant()
    return '/mnt/' + $drive + '/' + $Path.Substring(3).Replace('\', '/')
}

$windowsGpus = & nvidia-smi --query-gpu=index,name,uuid,pci.bus_id,driver_model.current,memory.total --format=csv,noheader 2>&1
$wslGpus = Invoke-Wsl -Arguments @('bash', '-lc', 'LD_LIBRARY_PATH=/usr/lib/wsl/lib nvidia-smi -L') -AllowFailure
Write-Host "Windows GPUs:`n$($windowsGpus -join "`n")"
Write-Host "WSL GPUs:`n$($wslGpus -join "`n")"

if ($Action -eq 'Status') {
    exit 0
}

if ($WorkerName -notmatch '^[A-Za-z0-9_-]+$') {
    throw 'WorkerName may contain only letters, digits, hyphen, and underscore.'
}
if ([string]::IsNullOrWhiteSpace($SecretFile) -or -not (Test-Path -LiteralPath $SecretFile)) {
    throw 'A readable -SecretFile is required for Start.'
}
if ([string]::IsNullOrWhiteSpace($wslGpus)) {
    throw 'WSL does not expose an NVIDIA GPU; Racer was not started.'
}

$secretWsl = Convert-WindowsPathToWsl -Path $SecretFile
$bash = @"
set -euo pipefail
test -x '$runner'
if pgrep -x racer >/dev/null; then
  echo 'Racer is already running; refusing to start a duplicate worker.' >&2
  exit 12
fi
set -a
. '$secretWsl'
set +a
exec env TIGER_WORKER_NAME='$WorkerName' TIGER_GPU_LIST='$GpuList' TIGER_GPU_GROUPS='$GpuGroups' '$runner' pool > '$logFile' 2>&1
"@

$process = Start-Process -FilePath 'wsl.exe' -ArgumentList @('-d', $Distro, '--', 'bash', '-lc', $bash) -WindowStyle Hidden -PassThru
Write-Host "Racer launched under Windows PID $($process.Id)."
Write-Host "WSL log: $logFile"
