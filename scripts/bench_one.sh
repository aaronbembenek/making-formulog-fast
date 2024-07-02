#!/usr/bin/env bash
set -e

trap 'if [ ! -z "$mytimeoutpid" ] ; then kill -9 -$mytimeoutpid ; fi ; exit 1' INT

mytimeout() {
    timeout -s 9 ${@} &
    mytimeoutpid=$!
    wait $mytimeoutpid
    if [ "$?" -ne 0 ]; then
        exit 124
    fi
    true
}

if [ "$#" -ne 8 ]; then
    echo "usage: $0 MODE SOLVER_MODE DETAILED_SMT_STATS PARALLELISM TIMEOUT BENCH_DIR RECORD_WORK SMALL_TASKS"
    exit 1
fi

script_dir=$(dirname -- "$(readlink -f -- "$0")")

mode="$1"
solver_mode="$2"
detailed_smt_stats="$3"
parallelism="$4"
timeout="$5"
bench_dir="$6"
record_work="$7"
small_tasks="$8"

cd $bench_dir
bench_dir="$PWD"
zip_file=facts.zip
if [[ "$mode" == compile* ]] && [ -f codegen_facts.zip ]; then
    zip_file=codegen_facts.zip
fi
unzip -oqq "$zip_file"

jvm_flags="-Xmx180g -Xss256m"
if [ "$small_tasks" -eq 1 ]; then
    jvm_flags="$jvm_flags -DsmtTaskSize=1 -DtaskSize=8"
fi
jvm_flags="$jvm_flags -DmemoizeThreshold=0"
jvm_flags="$jvm_flags -DsmtDoubleCheckUnknowns=false"
if [[ "$mode" == interpret* ]]; then
    if [ "$detailed_smt_stats" -eq 1 ]; then
        jvm_flags="$jvm_flags -DtimeSmt"
    fi
    if [ "$record_work" -eq 1 ]; then
        jvm_flags="$jvm_flags -DrecordWork"
    fi
fi
exe_flags="--dump-sizes --smt-stats --smt-solver-mode=$solver_mode"
exe_flags="$exe_flags -j $parallelism -D $bench_dir/out -F $bench_dir/facts"

cd ../..
if [ -f lib_facts.zip ]; then
    unzip -nqq lib_facts.zip
    exe_flags="$exe_flags -F $PWD/lib_facts"
fi

case "$mode" in

interpret | souffle | klee | cbmc | scuba) ;;

souffle-unbatched)
    souffle_opts="$souffle_opts -DEAGER_EVAL=On"
    ;;

souffle-reorder)
    souffle_opts="$souffle_opts -DSIPS=delta"
    ;;

interpret-reorder)
    jvm_flags="$jvm_flags -Doptimize=5"
    ;;

interpret-unbatched)
    jvm_flags="$jvm_flags -DeagerSemiNaive"
    ;;

compile | compile-unbatched)
    flg_flags="-c --codegen-dir $bench_dir/../../codegen"
    ;;

compile-reorder)
    jvm_flags="$jvm_flags -Doptimize=5"
    flg_flags="-c --codegen-dir $bench_dir/../../codegen"
    ;;

*)
    echo "unrecognized mode: $mode"
    exit 1
    ;;

esac

set_time_cmd() {
    time_cmd=/usr/bin/time
    if command -v gtime &>/dev/null; then
        time_cmd=gtime
    fi
    time_cmd="$time_cmd -f LOG:$1;ELAPSED=%es;USER=%Us;SYSTEM=%Ss;CPU=%P;MEM=%Mkb"
}

echo "LOG:Benchmark directory: $bench_dir"
echo "LOG:Timeout: $timeout"
echo "LOG:Eval repo commit:" $(git rev-parse --short HEAD)
echo "LOG:Formulog commit:" $(cat ../../lib/formulog_commit.txt)
echo "LOG:Z3 version:" $(z3 --version)
echo "LOG:Java version start"
echo $(java -version)
echo "LOG:Java version end"
echo "LOG:Mode: $mode"
echo "LOG:Solver mode: $solver_mode"
echo "LOG:Parallelism: $parallelism"

jar=$(readlink -f ../../lib/formulog.jar)
cmd="java $jvm_flags -jar $jar bench.flg $exe_flags $flg_flags"

if [[ "$mode" == interpret* ]]; then
    set_time_cmd INTERPRET
    cmd="$time_cmd $cmd"
    echo "LOG:Interpret command: timeout $timeout $cmd"
    mytimeout $timeout $cmd
    echo "LOG:Success!"
    exit 0
fi

if [[ "$mode" == klee ]]; then
    echo "LOG:KLEE info start"
    klee --version
    echo "LOG:KLEE info end"
    klee_tmp="$bench_dir/../../klee-tmp"
    rm -rf "$klee_tmp"
    mkdir "$klee_tmp"
    out="$klee_tmp/bench.bc"
    cmd="clang-13 $bench_dir/bench.c -DSYMEXEC -DKLEE -emit-llvm -c -S -o $out"
    echo "LOG:Compile command: $cmd"
    $cmd
    set_time_cmd EXECUTE
    cmd="$time_cmd klee -write-no-tests -solver-backend=z3 $out"
    echo "LOG:Execute command: timeout $timeout $cmd"
    mytimeout $timeout $cmd
    echo "LOG:Success!"
    exit 0
fi

if [[ "$mode" == cbmc ]]; then
    echo "LOG:CBMC info start"
    cbmc --version
    echo "LOG:CBMC info end"
    set_time_cmd EXECUTE
    cmd="$time_cmd cbmc $bench_dir/bench.c -DSYMEXEC -DCBMC --z3 --bounds-check --pointer-check --unwind 10"
    echo "LOG:Execute command: timeout $timeout $cmd"
    mytimeout $timeout $cmd
    echo "LOG:Success!"
    exit 0
fi

if [[ "$mode" == scuba ]]; then
    scuba_tmp=$(readlink -f -- "$bench_dir/../../scuba-tmp")
    rm -rf "$scuba_tmp"
    mkdir "$scuba_tmp"
   
    entry=$(cat $bench_dir/entry.txt)
    lib_dir=$(readlink -f -- "$scuba_tmp/../../../lib")
    z3_jar="$lib_dir/z3/build/com.microsoft.z3.jar"
    chord_jar="$lib_dir/scuba/chord.jar"
    scuba_jar="$lib_dir/scuba/scuba.jar"
    props_file="$scuba_tmp/chord.properties"
    bm=$(basename -- "$(readlink -f -- "$bench_dir")")
    echo chord.main.class=$entry >> $props_file
    echo chord.class.path=$bench_dir/bench.jar >> $props_file
    echo chord.ext.dlog.analysis.path=$scuba_jar >> $props_file
    echo chord.java.analysis.path=$chord_jar:$scuba_jar:$z3_jar >> $props_file
    echo chord.max.heap=180g >> $props_file
    echo chord.bddbddb.max.heap=24g >> $props_file
    echo chord.max.stack=256m >> $props_file
    echo chord.out.dir=$scuba_tmp >> $props_file
    echo chord.run.analyses=cspa-0cfa-dlog,prune-dlog,vv-refine-java,cspa-downcast-java,cspa-query-resolve-dlog,cipa-java,sum-java >> $props_file
    echo chord.scuba.proj=$bm >> $props_file

    set_time_cmd EXECUTE
    export PATH="$lib_dir/java7/bin:$PATH"
    java_lib_path="$lib_dir/z3/build"
    cmd="$time_cmd java -Xmx180G -Xss256m -Djava.library.path=$java_lib_path -Dchord.work.dir=$bm_dir -Dchord.props.file=$props_file -cp $chord_jar chord.project.Boot"
    echo "LOG:Execute command: timeout $timeout $cmd"
    mytimeout $timeout $cmd
    echo "LOG:Success!"
    exit 0
fi

echo "LOG:Souffle info start"
souffle --version
echo "LOG:Souffle info end"

if [[ "$mode" == souffle* ]]; then
    codegen_dir="$bench_dir/../../souffle-codegen"
    if [ ! -d "$codegen_dir" ]; then
        mkdir -p "$codegen_dir/src"
        set_time_cmd COMPILE
        cp "$script_dir/CMakeLists.txt" "$codegen_dir"
        cp bench.dl "$codegen_dir/src/bench.dl"
        cmd="cmake -B $codegen_dir/build -S $codegen_dir -DCMAKE_BUILD_TYPE=Release $souffle_opts && \
        cmake --build $codegen_dir/build -j"
        echo "LOG:Compile command: $time_cmd bash -c $cmd"
        $time_cmd bash -c "$cmd"
    fi

    set_time_cmd EXECUTE
    rm -rf "$bench_dir/out"
    mkdir "$bench_dir/out"
    cmd="$time_cmd $codegen_dir/build/bench -j $parallelism"
    cmd="$cmd -D $bench_dir/out -F $bench_dir/facts"
    echo "LOG:Execute command: timeout $timeout $cmd"
    mytimeout $timeout $cmd

    echo "LOG:Success!"
    exit 0
fi

codegen_dir="$bench_dir/../../codegen"
if [ ! -d "$codegen_dir" ]; then
    set_time_cmd TRANSPILE
    cmd="$time_cmd $cmd"
    echo "LOG:Transpile command: $cmd"
    $cmd

    set_time_cmd COMPILE

    if [[ "$mode" == compile-unbatched ]]; then
        flg_eager_eval="-DFLG_EAGER_EVAL=On"
    fi
    if [ "$record_work" -eq 1 ]; then
        flg_record_work="-DFLG_RECORD_WORK=On"
    fi
    cmd="cmake -B $codegen_dir/build -S $codegen_dir -DCMAKE_BUILD_TYPE=Release \
    $flg_eager_eval $flg_record_work && cmake --build $codegen_dir/build -j"
    echo "LOG:Compile command: $time_cmd bash -c $cmd"
    $time_cmd bash -c "$cmd"
fi

set_time_cmd EXECUTE
cmd="$time_cmd $codegen_dir/build/flg $exe_flags --no-smt-double-check"
echo "LOG:Execute command: timeout $timeout $cmd"
mytimeout $timeout $cmd

echo "LOG:Success!"
