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

# The follow options are supported for the `--modes` argument`:
#
#   `interpret`: use Formulog interpreter in semi-naive mode
#
#   `interpret-reorder`: reorder each rule body so delta atom is first, and then
#   use Formulog interpreter in semi-naive mode
#
#   `interpret-unbatched`: use Formulog interpreter in eager evaluation mode
#
#   `compile`: use Formulog compiler to generate code performing semi-naive
#   evaluation
#
#   `compile-reorder`: reorder each rule body so delta atom is first, and then
#   use Formulog compiler to generate code performing semi-naive evaluation
#
#   `compile-unbatched`: use Formulog compiler to generate code performing eager
#   evaluation
#
#   `klee`: use KLEE (symex only)
#
#   `cbmc`: use CBMC (symex only)
#
#   `scuba`: use the reference Scuba implementation (scuba only)

# Modify these variables to adjust the duration of the experiments.
ntrials=10
timeout=1800 # seconds
nthreads=40

# In what follows, comment out the benchmarks you do not want to run. For
# example, to run the dminor case study on only the `all-10` benchmark you'd
# modify the code below to be like this (ignoring the `#`s in the first column):
#
#    dminor_bms=(
#        # benchmarks/dminor/bms/all-1
#        benchmarks/dminor/bms/all-10
#        # benchmarks/dminor/bms/all-100
#    )
#
# Our data analysis script assumes that at least one benchmark is run per case
# study.
#
# It is also possible to comment out modes that you do not want to run; however,
# this can break our data analysis script, so we do not recommend it.
#
#    dminor_modes=(
#        # interpret-reorder
#        # interpret-unbatched
#        compile-reorder
#        compile-unbatched
#    )
#

################################################################################
# DMINOR
################################################################################

dminor_modes=(
    interpret-reorder
    interpret-unbatched
    compile-reorder
    compile-unbatched
)

dminor_bms=(
    benchmarks/dminor/bms/all-1
    benchmarks/dminor/bms/all-10
    benchmarks/dminor/bms/all-100
)

python3 -u scripts/bench.py -o --output-dir "$output_dir" \
    --modes "${dminor_modes[@]}" \
    --ntrials $ntrials -j $nthreads --smt-solver-modes push-pop \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs "${dminor_bms[@]}"

################################################################################
# SYMEX
################################################################################

symex_modes=(
    interpret-reorder
    interpret-unbatched
    compile-reorder
    compile-unbatched
    klee # the primary reference implementation
    cbmc # a secondary reference implementation
)

symex_bms=(
    benchmarks/symex/bms/interp-5
    benchmarks/symex/bms/interp-6
    benchmarks/symex/bms/numbrix-sat
    benchmarks/symex/bms/numbrix-unsat
    benchmarks/symex/bms/prioqueue-5
    benchmarks/symex/bms/prioqueue-6
    benchmarks/symex/bms/shuffle-4
    benchmarks/symex/bms/shuffle-5
    benchmarks/symex/bms/sort-6
    benchmarks/symex/bms/sort-7
)

python3 -u scripts/bench.py -o --output-dir "$output_dir" \
    --modes "${symex_modes[@]}" \
    --ntrials $ntrials -j $nthreads --smt-solver-modes check-sat-assuming \
    --record-work --small-tasks --timeout $timeout \
    --benchmark-dirs "${symex_bms[@]}"

################################################################################
# SCUBA
################################################################################

scuba_modes=(
    interpret
    interpret-unbatched
    compile
    compile-unbatched
    scuba # the reference implementation
)

scuba_bms=(
    benchmarks/scuba/bms/antlr
    benchmarks/scuba/bms/avrora
    benchmarks/scuba/bms/hedc
    benchmarks/scuba/bms/hsqldb
    benchmarks/scuba/bms/luindex
    benchmarks/scuba/bms/polyglot
    benchmarks/scuba/bms/sunflow
    benchmarks/scuba/bms/toba-s
    benchmarks/scuba/bms/weblech
    benchmarks/scuba/bms/xalan
)

python3 -u scripts/bench.py -o --output-dir "$output_dir" \
    --modes "${scuba_modes[@]}" \
    --ntrials $ntrials -j $nthreads --smt-solver-modes check-sat-assuming \
    --record-work --timeout $timeout \
    --benchmark-dirs "${scuba_bms[@]}"