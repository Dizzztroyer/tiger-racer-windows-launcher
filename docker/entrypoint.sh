#!/usr/bin/env bash
set -euo pipefail

: "${RACER_TENSORCASH_POOL_TOKEN:?Pool token is required}"
: "${TIGER_MODEL:?Model path is required}"

RACER_ROOT=/opt/tiger
RACER_DIR="$RACER_ROOT/bin/racer"
test -x "$RACER_DIR/racer"
test -f "$TIGER_MODEL"

cd "$RACER_DIR"
export LD_LIBRARY_PATH="$RACER_DIR/infer${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

exec ./racer \
  -a tensorcash \
  --gpu "$TIGER_GPU_LIST" \
  --tensorcash-gpu-groups "$TIGER_GPU_GROUPS" \
  --tensorcash-model "$TIGER_MODEL" \
  --tensorcash-sync-mode spin \
  --tensorcash-cpu-threads 0 \
  -o wss://tsc.tiger-pool.com:443/v1/ws \
  -u "$TIGER_WORKER_NAME" \
  --tensorcash-pool-difficulty-normalizer 1000000
