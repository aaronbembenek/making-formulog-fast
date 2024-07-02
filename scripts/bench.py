#!/usr/bin/env python3

import argparse
import os
import pathlib
import shutil
import subprocess
import sys


def run_one(
    output_file,
    bench_dir,
    mode,
    solver_mode,
    timeout,
    script_dir,
    parallelism,
    detailed_smt_stats,
    record_work,
    small_tasks,
):
    with open(output_file, "w") as f:
        script = os.path.join(script_dir, "bench_one.sh")
        subprocess.run(
            [
                script,
                mode,
                solver_mode,
                str(int(detailed_smt_stats)),
                str(parallelism),
                str(timeout),
                bench_dir,
                str(int(record_work)),
                str(int(small_tasks)),
            ],
            stderr=subprocess.STDOUT,
            stdout=f,
        )


def is_formulog_mode(mode):
    non_prefixes = ["souffle", "klee", "cbmc", "scuba"]
    for non_prefix in non_prefixes:
        if mode.startswith(non_prefix):
            return False
    return True


def run(
    output_dir,
    benchmark_dirs,
    modes,
    smt_solver_modes,
    ntrials,
    timeout,
    script_dir,
    overwrite,
    parallelism,
    detailed_smt_stats,
    first_trial,
    record_work,
    small_tasks,
):
    try:
        os.makedirs(output_dir, exist_ok=overwrite)
    except FileExistsError:
        print(
            f"Output directory `{output_dir}` already exists... not running experiments"
        )
        exit(1)

    def rm_dir(codegen_dir):
        if os.path.exists(codegen_dir):
            assert os.path.isdir(codegen_dir)
            shutil.rmtree(codegen_dir)

    short_solver_modes = {
        "naive": "naive",
        "NA": "NA",
        "push-pop": "pp",
        "check-sat-assuming": "csa",
    }
    for mode in modes:
        visited_case_studies = set()
        for bench_dir in benchmark_dirs:
            p = pathlib.Path(bench_dir)
            case_study = p.parent.parent.stem
            benchmark = p.stem
            name_prefix = case_study + "__" + benchmark
            if case_study not in visited_case_studies:
                visited_case_studies.add(case_study)
                if mode.startswith("compile"):
                    rm_dir(p.parent.parent / "codegen")
                elif mode.startswith("souffle"):
                    rm_dir(p.parent.parent / "souffle-codegen")
            solver_modes = smt_solver_modes if is_formulog_mode(mode) else ["NA"]
            for solver_mode in solver_modes:
                short_solver_mode = short_solver_modes[solver_mode]
                name_intermediate = f"{name_prefix}__{short_solver_mode}__{mode}"
                for trial in range(first_trial, first_trial + ntrials):
                    name = f"{name_intermediate}__{trial:0>2d}.txt"
                    output_file = os.path.join(output_dir, name)
                    print(case_study, benchmark, solver_mode, mode, trial)
                    run_one(
                        output_file,
                        bench_dir,
                        mode,
                        solver_mode,
                        timeout,
                        script_dir,
                        parallelism,
                        detailed_smt_stats,
                        record_work,
                        small_tasks,
                    )


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    modes = [
        "interpret",
        "interpret-reorder",
        "interpret-unbatched",
        "compile",
        "compile-reorder",
        "compile-unbatched",
        "souffle",
        "souffle-reorder",
        "souffle-unbatched",
        "klee",
        "cbmc",
        "scuba",
    ]
    solver_modes = ["naive", "push-pop", "check-sat-assuming"]
    parser.add_argument(
        "--output-dir", required=True, help="directory to place output files"
    )
    parser.add_argument(
        "--benchmark-dirs", nargs="+", required=True, help="benchmark directories"
    )
    parser.add_argument("--modes", nargs="+", choices=modes, help="evaluation modes")
    parser.add_argument(
        "--ntrials", type=int, default=1, help="number of trials to run"
    )
    parser.add_argument(
        "--first-trial", type=int, default=0, help="numeric ID of first trial"
    )
    parser.add_argument("--timeout", type=int, default=1800, help="timeout in seconds")
    parser.add_argument(
        "-o",
        "--overwrite",
        action="store_true",
        help="proceed even if output directory exists",
    )
    parser.add_argument(
        "-j", "--parallelism", type=int, default=40, help="number of threads to use"
    )
    parser.add_argument(
        "--smt-solver-modes",
        nargs="+",
        choices=solver_modes,
        help="incremental SMT strategies",
        default=["check-sat-assuming"],
    )
    parser.add_argument(
        "--detailed-smt-stats",
        action="store_true",
        help="record detailed statistics about SMT solver usage",
    )
    parser.add_argument(
        "--record-work", action="store_true", help="record amount of work performed"
    )
    parser.add_argument(
        "--small-tasks",
        action="store_true",
        help="use small granularity tasks (in interpreter)",
    )
    args = parser.parse_args()
    run(**vars(args), script_dir=sys.path[0])


if __name__ == "__main__":
    main()
