#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "usage: $0 OUTPUT_DIR"
    exit 1
fi

script_dir=$(dirname -- "$(readlink -f -- "$0")")
cd $script_dir/..

python3 -u scripts/bench.py --output-dir "$1" \
    --modes scuba --ntrials 10 \
    --benchmark-dirs benchmarks/scuba/bms/*

python3 -u scripts/bench.py -o --output-dir "$1" \
    --modes cbmc klee --ntrials 10 \
    --benchmark-dirs benchmarks/symex/bms/*
