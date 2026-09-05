# Tiger Racer Windows Launcher

An honest Windows control launcher for the official **Linux-only** Tiger Racer
client. It starts the unchanged Racer binary inside WSL and keeps the owning
`wsl.exe` process alive on Windows.

This project is not a Windows port of Racer. It does not reimplement the
TensorCash proof, alter the pool protocol, patch Racer, or manufacture shares.

## Scope

- Windows starts and supervises the official Racer process.
- GPU computation remains inside WSL.
- The launcher checks Windows and WSL GPU visibility before starting work.
- Pool credentials stay in a local environment file and are never printed.

## Requirements

1. Windows 11 with WSL 2 and a working NVIDIA CUDA-on-WSL setup.
2. A verified official Racer installation in WSL, including the model required
   by Tiger Pool.
3. A local secret file containing only:

   ```text
   RACER_TENSORCASH_POOL_TOKEN=...
   ```

## Usage

Run from PowerShell:

```powershell
.\scripts\tiger-windows-bridge.ps1 `
  -Action Status `
  -Distro Ubuntu `
  -WslRacerRoot /home/<linux-user>/tiger-racer
```

Start a worker after the status check succeeds:

```powershell
.\scripts\tiger-windows-bridge.ps1 `
  -Action Start `
  -Distro Ubuntu `
  -WslRacerRoot /home/<linux-user>/tiger-racer `
  -SecretFile C:\path\to\tiger-pool.env `
  -WorkerName my-windows-launcher
```

The script intentionally refuses a second Racer process. Logs are written under
`<WslRacerRoot>/logs/`.

## Docker Desktop mode

`compose.yaml` runs the unchanged Racer binary inside a Docker Desktop container
and therefore shows its lifecycle and logs in Docker Desktop. Run Compose from
the WSL distribution that holds Racer and the model:

```bash
set -a
. /mnt/c/path/to/tiger-pool.env
set +a
export TIGER_GPU_UUID=GPU-REPLACE-WITH-WSL-VISIBLE-RTX-UUID
export RACER_ROOT=/home/linux-user/tiger-racer
export RACER_LOG_DIR="$RACER_ROOT/logs"
export RACER_CACHE_DIR="$RACER_ROOT/model/.racer-cache"
docker compose -f /mnt/c/path/to/tiger-racer-windows-launcher/compose.yaml up -d
```

The Compose file uses `NVIDIA_VISIBLE_DEVICES` with one WSL-visible RTX UUID
instead of `--gpus all`. This is intentional: a Windows-only TCC GPU can make
an all-GPU WSL container request fail even when the RTX is healthy. The Racer
API is bound to `127.0.0.1:4000`; it is not exposed to the network.

## Hardware note

Only GPUs exposed by WSL can be selected. NVIDIA documents WSL CUDA support for
WDDM-capable GeForce and Quadro products; compute-only/TCC devices may remain
available only to native Windows software. This launcher does not claim to make
an unavailable GPU accessible to WSL.

## Upstream

The official Racer releases are published by
[king-2386/tsc-miner](https://github.com/king-2386/tsc-miner). This companion
repository has no affiliation with Tiger Pool or its author.
