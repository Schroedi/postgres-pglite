#!/bin/bash
set -euo pipefail

. wasm-build/extension.sh

if ${WASI:-false}; then
    echo "Skipping TimescaleDB for WASI build"
    exit 0
fi

TS_SRC=${TIMESCALEDB_SRC:-${WORKSPACE}/timescaledb}
if [ ! -d "$TS_SRC" ]; then
    echo "TimescaleDB sources not found. Set TIMESCALEDB_SRC to the repository root." >&2
    exit 1
fi

SRC_DIR=${PG_EXTRA}/timescaledb-src
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR"
cp -a "$TS_SRC/." "$SRC_DIR/"

BUILD_DIR=${PG_EXTRA}/timescaledb-build
mkdir -p "$BUILD_DIR"

cmake_opts=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="${PGROOT}"
    -DPG_CONFIG="${PGROOT}/bin/pg_config"
    -DAPACHE_ONLY=ON
    -DREGRESS_CHECKS=OFF
    -DTAP_CHECKS=OFF
    -DUSE_OPENSSL=OFF
    -DUSE_TELEMETRY=OFF
    -DSEND_TELEMETRY_DEFAULT=OFF
    -DENABLE_DEBUG_UTILS=OFF
    -DWARNINGS_AS_ERRORS=OFF
    -DCMAKE_VERBOSE_MAKEFILE=ON
)

emcmake cmake -S "$SRC_DIR" -B "$BUILD_DIR" "${cmake_opts[@]}"

emmake make -C "$BUILD_DIR" -j$(nproc)
emmake make -C "$BUILD_DIR" install

