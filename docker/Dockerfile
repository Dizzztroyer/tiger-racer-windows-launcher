FROM nvidia/cuda:13.1.0-base-ubuntu24.04

# Racer's bundled ggml CPU runtime requires the GNU OpenMP runtime.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*
