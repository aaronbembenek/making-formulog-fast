#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "usage: $0 OUTPUT_DIR"
    exit 1
fi

mkdir -p "$1"
output_dir=$(readlink -f -- "$1")
script_dir=$(dirname -- "$(readlink -f -- "$0")")
cd $script_dir/..

# Modify these variables to adjust the duration of the experiments.
ntrials=5
timeout=1800 # seconds
nthreads=(1 8 16 24 32 40)

################################################################################
# DMINOR
################################################################################

dminor_modes=(
    # interpret-reorder
    # interpret-unbatched
    compile-reorder
    compile-unbatched
)

dminor_bms=(
    # benchmarks/dminor/bms/all-1
    # benchmarks/dminor/bms/all-10
    benchmarks/dminor/bms/all-100
)

python3 -u scripts/bench.py -o --output-dir "$output_dir" \
    --modes "${dminor_modes[@]}" \
    --ntrials $ntrials -j "${nthreads[@]}" --smt-solver-modes push-pop \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs "${dminor_bms[@]}"

################################################################################
# SYMEX
################################################################################

symex_modes=(
    # interpret-reorder
    # interpret-unbatched
    compile-reorder
    compile-unbatched
)

symex_bms=(
    # benchmarks/symex/bms/interp-5
    benchmarks/symex/bms/interp-6
    benchmarks/symex/bms/numbrix-sat
    # benchmarks/symex/bms/numbrix-unsat
    # benchmarks/symex/bms/prioqueue-5
    benchmarks/symex/bms/prioqueue-6
    # benchmarks/symex/bms/shuffle-4
    benchmarks/symex/bms/shuffle-5
    # benchmarks/symex/bms/sort-6
    benchmarks/symex/bms/sort-7
)

python3 -u scripts/bench.py -o --output-dir "$output_dir" \
    --modes "${symex_modes[@]}" \
    --ntrials $ntrials -j "${nthreads[@]}" --smt-solver-modes check-sat-assuming \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs "${symex_bms[@]}"