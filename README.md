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

## Hardware note

Only GPUs exposed by WSL can be selected. NVIDIA documents WSL CUDA support for
WDDM-capable GeForce and Quadro products; compute-only/TCC devices may remain
available only to native Windows software. This launcher does not claim to make
an unavailable GPU accessible to WSL.

## Upstream

The official Racer releases are published by
[king-2386/tsc-miner](https://github.com/king-2386/tsc-miner). This companion
repository has no affiliation with Tiger Pool or its author.
