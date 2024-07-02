#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "usage: $0 OUTPUT_DIR"
    exit 1
fi

script_dir=$(dirname -- "$(readlink -f -- "$0")")
cd $script_dir/..

python3 -u scripts/bench.py --output-dir "$1" \
    --modes interpret-reorder interpret-unbatched compile-reorder compile-unbatched \
    --ntrials 10 -j 40 --smt-solver-modes push-pop \
    --benchmark-dirs benchmarks/dminor/bms/* --record-work --small-tasks

python3 -u scripts/bench.py -o --output-dir "$1" \
    --modes interpret-reorder interpret-unbatched compile-reorder compile-unbatched \
    --ntrials 10 -j 40 --smt-solver-modes check-sat-assuming \
    --benchmark-dirs benchmarks/symex/bms/* --record-work --small-tasks

python3 -u scripts/bench.py -o --output-dir "$1" \
    --modes interpret compile \
    --ntrials 10 -j 40 --smt-solver-modes check-sat-assuming \
    --benchmark-dirs benchmarks/scuba/bms/* --record-work
