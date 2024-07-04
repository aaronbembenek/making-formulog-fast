# Making Formulog Fast

Welcome to the artifact for "Making Formulog Fast" (artifact #45, paper #434).

This README is organized as follows:

- Introduction
- Hardware Dependencies
- Getting Started Guide (Phase 1)
- Step-by-Step Instructions (Phase 2)
- Reusability Guide

## Introduction

Formulog extends the logic programming language Datalog with first-order functional programming and SMT solving; its goal is to make it possible to write SMT-based program analyses (e.g., symbolic execution and refinement type checking) in a way that is declarative (at the level of mathematical specification) while still being amenable to high-level optimizations and efficient evaluation.

Our paper explores two approaches to making Formulog faster:

- We implement a compiler that transpiles the functional and SMT fragment of Formulog to C++ and the Datalog fragment to Soufflé, a leading Datalog solver that compiles Datalog to C++.
- We develop eager evaluation, a novel Datalog evaluation algorithm that can lead to advantageous distributions of Formulog's SMT workload on SMT-heavy benchmarks.

### Supported Claims

This artifact supports the following claims:

- On the Formulog benchmark suite, compiling Formulog leads to speedups over interpreting Formulog (~2x arithmetic mean speedup in our experiments); this claim can be evaluated using the experiment scripts in the artifact.
- On SMT-heavy benchmarks, interpreting Formulog using eager evaluation leads to speedups over compiling Formulog to off-the-shelf Soufflé (~5x arithmetic mean speedup in our experiments); this claim can be evaluated using the experiment scripts in the artifact.
- On SMT-heavy benchmarks, compiling Formulog to our modified version of Soufflé that uses eager evaluation leads to speedups over interpreting Formulog with eager evaluation (~2x arithmetic mean speedup in our experiments); this claim can be evaluated using the experiment scripts in the artifact.
- On SMT-heavy benchmarks, using eager evaluation typically (although not universally) leads to faster SMT solving times compared to using semi-naive evaluation; this claim can be evaluated using the experiment scripts in the artifact.
- Our improvements to Formulog---compilation and (on SMT-heavy benchmarks) eager evaluation---help Formulog be competitive with previously published, non-Datalog implementations of a range of SMT-based program analyses; this claim can be evaluated using the experiment scripts in the artifact.
- Eager evaluation can be added to existing Datalog infrastructure with relatively low amounts of new code (~500 SLOC in the Formulog interpreter, and ~500 SLOC in Soufflé); this claim can be evaluated by running the utility `cloc` on the source directories contained in this artifact (we provide a script for this).

More details about evaluating each claim are given in the instructions below.

### Unsupported Claims

Our experimental setup does not run the original (non-Formulog) version of the Dminor type checker; as noted in Section 6.1 of our paper, the original Dminor implementation can run only on an old, resource-constrained version of .NET, and so we just report the performance numbers given for it in the original Formulog paper.

The paper reviewers have requested that we include some limited scalability experiments in the final version of the paper; these experiments have not been designed yet and so are not part of this artifact.

## Hardware Dependencies

For the "kick-the-tires" phase of the artifact evaluation, a moderately powerful laptop (x86 or ARM) that can run Docker should be sufficient---say, a laptop with at least 4 vCPUs and 8 GB RAM.
We have tested the "kick-the-tires" phase on these machines:
- a 2023 M2 MacBook Pro with 10 vCPUs and 16 GB RAM
- an x86 Ubuntu server with 4 vCPUs and 16 GB RAM 

For the full evaluation of the artifact, a more powerful machine is necessary (~40 vCPUs, ~200 GB of memory).
We will give artifact reviewers anonymous SSH access to an AWS EC2 with the correct specs.
Access will be coordinated via the AEC chairs.
Reviewers will need to ensure that only one reviewer is running experiments on the EC2 at a time. 

## Getting Started Guide (Phase 1)

You should be able to run these experiments on a moderately powerful laptop that has Docker.
In the `vms/` directory, there are two archived Docker images, one for x86 and one for ARM.
Both images contain the software (and scripts) necessary for running the Formulog experiments in the paper; however, only the x86 one also supports running the reference implementations from Section 6.1 (e.g., KLEE and the original Scuba points-to analysis), as we were unable to get them to work on ARM.
We recommend using whichever image matches your architecture (it might be possible to run the other image via emulation, but this will be quite slow).

Make sure Docker is configured to give containers at least 4 CPUs and 8 GB RAM (more is better); to see what the current setting is, grep for "CPUs" and "Total Memory" in the output of the command `docker info`.
If you are using Docker Desktop on Mac, you can increase the resource limits following [these instructions](https://docs.docker.com/desktop/settings/mac/#advanced).

To load the x86 image and start an interactive Docker container based on it named `mff` (for "Making Formulog Fast"), run these commands:

```bash
docker load < vms/mff-amd64.tar.gz
docker run --name mff -it mff-amd64
```

To do the same for the ARM image, run these commands:

```bash
docker load < vms/mff-arm64.tar.gz
docker run --name mff -it mff-arm64
```

### Experiment #1: Run Formulog

Once you are in the Docker container, you can run a script that will run a set of relatively small experiments:

```
./scripts/kicktires.sh phase1-results
```

On a 2023 M2 MacBook Pro with 10 vCPUS and 16 GB RAM this takes 16 minutes; XXX.

The previous command will populate the directory `~/phase1-results` with output files from the experiment.
Each file is named according to this convention:

```
[case-study]__[benchmark]__[SMT-mode]__[eval-mode]__[trial-num].txt
```

We use two SMT modes in our experiments, `csa` (short for `check-sat-assuming`) and `pp` (short for `push-pop`).
These determine the encoding the Formulog runtime uses for incremental SMT solving (see [an ICLP'20 extended abstract](https://aaronbembenek.github.io/papers/datalog-incr-smt-iclp2020.pdf) for more details).

The possible values for `[eval-mode]` are:

- `interpret`: use Formulog interpreter in semi-naive mode
- `interpret-reorder`: reorder each rule body so delta atom is first, and then use Formulog interpreter in semi-naive mode
- `interpret-unbatched`: use Formulog interpreter in eager evaluation mode
- `compile`: use Formulog compiler to generate code performing semi-naive evaluation
- `compile-reorder`: reorder each rule body so delta atom is first, and then use Formulog compiler to generate code performing semi-naive evaluation
- `compile-unbatched`: use Formulog compiler to generate code performing eager evaluation

The raw output logs can be turned into a CSV using the script `scripts/process_logs.py`, and the CSV values can be summarized using the script `scripts/summarize_kicktires.py`:

```bash
./scripts/process_logs.py phase1-results/* | ./scripts/summarize_kicktires.py
```

This is the summary we received on the Mac laptop:

```
dminor/all-10
	compile-reorder 6.87s
	compile-unbatched 1.54s
	interpret-reorder 9.24s
	interpret-unbatched 4.74s
scuba/polyglot
	scuba NA
	compile-unbatched 329.59s
	compile 115.07s
symex/shuffle-4
	klee NA
	compile-reorder 1.47s
	compile-unbatched 0.38s
	interpret-reorder 2.10s
	interpret-unbatched 1.29s
```

This is the output we received on the Linux server:

```
XXX
```

### Experiment #2: Count SLOC for Eager Evaluation Implementations

In the paper, we claim that eager evaluation can be relatively easily added to existing Datalog infrastructure.
To demonstrate this, we have provided a script to count the number of lines of code needed to support eager evaluation in the Formulog interpreter and Soufflé code generator:

```
./scripts/count_sloc
```

This should print out some statistics about lines of code using the `cloc` utility; in particular, that our eager evaluation implementation in the Formulog interpreter consists of 481 SLOC Java, and our extensions to Souffle required modifying 59 SLOC, adding 558 SLOC, and removing 2 SLOC (all in C++).

### Exploring the Artifact

Feel free to explore the artifact; we are happy to answer questions that come up.
The artifact has the following content:

- `benchmarks/`: the case studies and benchmarks used in the experiments
    - `benchmarks/[case-study]/bench.flg`: the Formulog implementation of the case study
    - `benchmarks/[case-study]/bms/`: the benchmarks themselves, each one with its own directory containing the archived facts (i.e., the EDB) for that benchmark
- `formulog/`: the Formulog source code
    - `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/`: the code for the compiler
        - `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/CodeGen.java`: the entry point for the compiler
        - `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/*(Cpp|Hpp).java`: code for specializing a C++ file (from the Formulog runtime) to the program being compiled
        - `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/[Construct]CodeGen.java`: code for compiling a particular Formulog language construct (e.g., a type, a term, a rule)
    - `formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/EagerStratumEvaluator`: the implementation of eager evaluation in the Formulog interpreter
- `souffle/`: our eager evaluation extension to Soufflé (see `souffle/README.md` for more details)
- `lib/`: various libraries used during the experiments, including a symlink to the Formulog JAR
- `paper-results/`: the experimental data we report on in the paper
    - `paper-results/regular/figures/`: the figures and tables for the paper 
    - `paper-results/regular/raw/`: the raw output logs from the experiments
    - `paper-results/regular/results.csv`: the results in CSV format
    - `paper-results/regular/stats.txt`: the statistics we report in the paper
- `scripts/`: scripts for running the experiments and analyzing results
    - `scripts/analysis.ipynb`: Jupyter notebook for analyzing results from full experiments
    - `scripts/analysis.py`: script version of Jupyter notebook
    - `scripts/bench.py`: script for running multiple tool configurations on the same set of benchmarks
    - `scripts/bench_one.sh`: script for running a single tool configuration on a single benchmark (should not be used directly)
    - `scripts/count_sloc.sh`: script for calculating the size (in terms of SLOC) of our eager evaluation extensions
    - `scripts/eval_full.sh`: script for running full experiments reported in the paper
    - `scripts/kicktires.sh`: script for running Phase 1 "kick-the-tires" experiments
    - `scripts/process_logs.sh`: script that takes raw output logs and turns them into CSV data
    - `scripts/summarize_kicktires.sh`: script for summarizing the results of the Phase 1 "kick-the-tires" experiments

If you are interested in trying out the Formulog compiler and/or eager evaluation on your own Formulog program, see the subsection "Trying Out Our Formulog Extensions" in the "Reusability Guide" part of this document.

## Step-by-Step Instructions (Phase 2)

- Run experiment script
- Run analysis script
- What to expect
- Note about scuba/luindex

```bash
grep non-zero phase2-results/raw/scuba__luindex*scuba*
```

To use Jupyter Notebook, need
- notebook
- matplotlib
- pandas
- seaborn

## Reusability Guide

The primary reusable components of our artifact are our contributions to the Formulog platform:

1. a compiler from Formulog to off-the-shelf Soufflé;
2. an eager evaluation mode for the Formulog interpreter; and
3. an eager evaluation extension to the Formulog compiler.

**All three extensions are feature complete---that is, they work with the full Formulog language, and should work with arbitrary Formulog programs (modulo bugs).**

All three extensions have passed the ~300 Formulog test cases in the `formulog/src/test/resources/` directory.
To run these unit tests, enter the `formulog` directory and run this command (takes roughly an hour on our laptop):

```bash
mvn -DtestCodeGen -DtestCodeGenEager package
```

In the subsection "Trying Out Our Formulog Extensions" below we discuss how you can try out our different Formulog extensions for yourself.

In what follows, we discuss each of our extensions in turn.

### Compiler from Formulog to Off-the-Shelf Soufflé

We have built a compiler for Formulog that transpiles the functional and SMT fragment of Formulog to C++ and the Datalog fragment to Soufflé.
Off-the-shelf Soufflé is then used to compile the Soufflé code to C++, which can be linked with the C++ generated by the Formulog compiler.
The compiler consists of ~4.4k lines of Java, plus ~3k lines of C++ for the skeleton Formulog runtime.

Relevant source directories:

- `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/`
- `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/ast/cpp/`
- `formulog/src/main/java/edu/harvard/seas/pl/formulog/codegen/ast/souffle/`
- `formulog/src/main/resources/codegen/`

The entry point for the compiler is the `CodeGen` class.
Some classes in the `codegen` package translate specific Formulog language constructs; these classes have names like `[Construct]CodeGen`.
For example, the class `TermCodeGen` defines how to translate a Formulog term (like a constructor or primitive).
Other classes specialize the skeleton Formulog C++ runtime to the program being translated; these classes are named after the C++ file that they fill in (e.g., `SymbolHpp` and `SymbolCpp` for `Symbol.hpp` and `SymbolCpp`, respectively).
The skeleton Formulog C++ runtime can be found in the `formulog/src/main/resources/codegen/` directory.

We expect that the amount of work needed to extend the compiler to support a new Formulog feature will typically be commensurate with the amount of work needed to extend the Formulog interpreter to handle that feature (an exception might be if Soufflé already supports some feature that Formulog does not, in which case extending the Formulog compiler might be easier than extending the interpreter).
Thus, it should be lightweight to extend the compiler with a non-invasive feature (say, new primitive terms representing character literals).

### Eager Evaluation for the Formulog Interpreter

We have extended the Formulog interpreter to support eager evaluation.

Relevant source files:

- `formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/AbstractStratumEvaluator` 
- `formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/EagerStratumEvaluator` 
- `formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/RoundBasedStratumEvaluator` 

We have abstracted stratum-level evaluation in the Formulog interpreter with an `AbstractStratumEvaluator` class that includes core functionality shared between evaluation methods.
This abstract class is extended by classes for traditional semi-naive evaluation (`RoundBasedStratumEvaluator`) and eager evaluation (`EagerStratumEvaluator`).
This design makes it easy to extend the Formulog interpreter with alternative evaluation methods.
First, it would be simple to use different evaluation methods for different strata, by dynamically choosing which stratum evaluator class to use on a per-stratum basis.
Second, it is relatively lightweight to add an alternative stratum-level evaluation method by extending the `AbstractStratumEvaluator` class.
For example, using the `EagerStratumEvaluator` class as a guide, it should not be hard to implement a proof-of-concept evaluation method that explore the logical inference space with an order different than DFS (eager evaluation) and BFS (semi-naive evaluation); for example, by choosing which inferences to explore based on some notion of priority.
This should require a few hundred lines of code, while reusing much of the Formulog codebase (>20k SLOC Java, excluding compiler).

### Eager Evaluation for the Formulog Compiler 

We have extended the Soufflé code generator with preliminary support for eager evaluation.
This extension to Soufflé works in a seamless way with our Formulog compiler.
However, it can also be used to generate eager evaluation code for Soufflé programs in general (i.e., ones not resulting from Formulog compilation).
This means that it can be reused by (the many) tools written in Soufflé, as well as tools that generate Soufflé code.

See `souffle/README.md` for additional information, such as usage and limitations.
The main current limitation is our extension does not support Soufflé's aggregation constructs; however, this is not a fundamental limitation and support could be added in the future.

### Trying Out Our Formulog Extensions

You can try running our extensions to Formulog on an arbitrary Formulog program; say, one you write yourself, or one of the example programs in `formulog/examples`.
To learn more about the Formulog language, check out the language reference in the `formulog/docs/` directory (or [rendered online](https://github.com/aaronbembenek/formulog-fork/tree/mff-artifact/docs)).

Let's assume you want to evaluate the program `formulog/examples/greeting.flg`.
To run it with the Formulog interpreter using semi-naive evaluation, run this command:

```bash
java -jar lib/formulog.jar formulog/examples/greeting.flg --dump-idb
```

To run it with eager evaluation, add the `--eager-eval` flag:

```bash
java -jar lib/formulog.jar formulog/examples/greeting.flg --dump-idb --eager-eval
```

To compile it, run it with the `--codegen` flag:

```bash
java -jar lib/formulog.jar formulog/examples/greeting.flg --codegen
```

This will create a directory `codegen/`.
The directory `codegen/src/` contains the files output by our compiler; the C++ ones are the Formulog runtime (specialized to the program being compiled) and the file `codegen/src/formulog.dl` is the Soufflé version of the Datalog rules from the Formulog program.
To build and run the semi-naive evaluation of this program, run these commands:

```bash
cd ~/codegen
cmake -S . -B build
cmake --build build -j
./build/flg --dump-idb
```

To instead build and run the eager evaluation of this program, add the appropriate flag when configuring the build: 

```bash
cd ~/codegen
cmake -S . -B build -DFLG_EAGER_EVAL=On
cmake --build build -j
./build/flg --dump-idb
```

The generated C++ file implementing semi-naive or eager evaluation for the program is `codegen/build/formulog.cpp`; you might want to format it first before checking it out:

```bash
clang-format -i ~/codegen/build/formulog.cpp
```

### Extending Our Experimental Infrastructure

Finally, we believe that the experimental infrastructure in this artifact can be adapted and reused for future experiments (it itself builds on the artifact published in the OOPSLA'20 Formulog paper).

- Creating new benchmarks
- Running different experiments (such as just Soufflé code)