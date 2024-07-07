#!/usr/bin/env python3

import argparse
import csv
import pathlib
import re
import sys

schema = [
    "case_study",
    "benchmark",
    "mode",
    "success",
    "interpret_time",
    "interpret_cpu",
    "interpret_mem",
    "transpile_time",
    "transpile_cpu",
    "transpile_mem",
    "compile_time",
    "compile_cpu",
    "compile_mem",
    "execute_time",
    "execute_cpu",
    "execute_mem",
    "smt_calls",
    "smt_time",
    "smt_mode",
    "smt_eval_time",
    "smt_wait_time",
    "smt_cache_hits",
    "smt_cache_misses",
    "smt_cache_clears",
    "work",
    "parallelism",
]

benchmark_pat = re.compile(r"^LOG:Benchmark directory: (.*)\n", re.MULTILINE)

mode_pat = re.compile(r"^LOG:Mode: (.*)\n", re.MULTILINE)

success_pat = re.compile(r"^LOG:Success!\n", re.MULTILINE)

pat_dict = {
    "work": re.compile(r"^\[WORK\] (.*)\n", re.MULTILINE),
    "smt_calls": re.compile(r"^SMT calls: (.*)\n", re.MULTILINE),
    "smt_eval_time": re.compile(r"^SMT time \(ms\): (.*)\n", re.MULTILINE),
    "smt_wait_time": re.compile(r"^SMT wait time \(ms\): (.*)\n", re.MULTILINE),
    "smt_mode": re.compile(r"^LOG:Solver mode: (.*)\n", re.MULTILINE),
    "smt_cache_hits": re.compile(r"^SMT cache hits: (.*)\n", re.MULTILINE),
    "smt_cache_misses": re.compile(r"^SMT cache misses: (.*)\n", re.MULTILINE),
    "smt_cache_clears": re.compile(
        r"^(?:SMT cache clears:|\[CSA CACHE CLEARS\]) (.*)\n", re.MULTILINE
    ),
    "parallelism": re.compile(r"^LOG:Parallelism: (.*)\n", re.MULTILINE)
}

data_pat = re.compile(
    r"^LOG:(.*);ELAPSED=(.*)s;USER=.*s;SYSTEM.*s;CPU=(.*)%;MEM=(.*)kb\n", re.MULTILINE
)


def get_idb_size(data):
    size = 0
    lines = iter(data.split("\n"))
    try:
        line = next(lines)
        while line != "==================== RELATION SIZES ====================":
            line = next(lines)
        p = re.compile(r"[a-z][a-zA-Z0-9_]*: (\d+)$")
        while True:
            line = next(lines)
            m = p.match(line)
            if not m:
                break
            size += int(m.group(1))
    except StopIteration:
        pass
    return size


def parse(file):
    d = {}

    def parse_data(stage, time, cpu, mem):
        stage = stage.lower()
        d[stage + "_time"] = time
        d[stage + "_cpu"] = cpu
        d[stage + "_mem"] = float(mem) / 1e6  # convert kb to gb

    with open(file, "r") as f:
        data = f.read()
        m = benchmark_pat.search(data)
        assert m, file
        p = pathlib.Path(m.group(1))
        d["case_study"] = p.parent.parent.stem
        d["benchmark"] = p.stem
        m = mode_pat.search(data)
        assert m, file
        d["mode"] = m.group(1)
        m = success_pat.search(data)
        d["success"] = "y" if m else "n"
        # Work is slightly over-recorded in "compile" mode: it counts the loop
        # iterations involved in moving tuples from auxiliary relations to the
        # full relation. Since this is just bookkeeping (and could be
        # implemented by single `add_all` calls instead of loops), we won't
        # count these iterations as work.
        idb_size = 0
        if d["mode"] == "compile":
            idb_size = get_idb_size(data)
        for parts in data_pat.findall(data):
            parse_data(*parts)
        for label, pat in pat_dict.items():
            m = pat.search(data)
            if m:
                d[label] = m.group(1)
                # convert some values to a different magnitude
                if label in ("smt_eval_time", "smt_wait_time"):
                    d[label] = float(d[label]) / 1000
                elif label == "work":
                    d[label] = (float(d[label]) - idb_size) / 1e6
                elif label in ("smt_cache_hits", "smt_cache_misses"):
                    d[label] = float(d[label]) / 1e6
        d["smt_time"] = d.get("smt_eval_time", 0) + d.get("smt_wait_time", 0)

    return d


def main():
    parser = argparse.ArgumentParser(description="Process experiment output logs.")
    parser.add_argument("logs", nargs="*", help="logs to process")
    args = parser.parse_args()
    w = csv.DictWriter(sys.stdout, schema, restval="NA")
    w.writeheader()
    w.writerows(parse(f) for f in args.logs)
    sys.stdout.flush()


if __name__ == "__main__":
    main()
