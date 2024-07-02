#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "usage: $0 OUTPUT_DIR"
    exit 1
fi

script_dir=$(dirname -- "$(readlink -f -- "$0")")
cd $script_dir/..

ncores=$(nproc)
timeout=480 # seconds

python3 -u scripts/bench.py --output-dir "$1" \
    --modes interpret-reorder interpret-unbatched compile-reorder compile-unbatched \
    --ntrials 1 -j $ncores --smt-solver-modes push-pop \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs benchmarks/dminor/bms/all-10

python3 -u scripts/bench.py -o --output-dir "$1" \
    --modes interpret-reorder interpret-unbatched compile-reorder compile-unbatched klee \
    --ntrials 1 -j $ncores --smt-solver-modes check-sat-assuming \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs benchmarks/symex/bms/shuffle-4

python3 -u scripts/bench.py -o --output-dir "$1" \
    --modes interpret compile scuba \
    --ntrials 1 -j $ncores --smt-solver-modes check-sat-assuming \
    --record-work --timeout $timeout \
    --benchmark-dirs benchmarks/scuba/bms/polyglot
