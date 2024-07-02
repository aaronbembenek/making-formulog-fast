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

The paper reviewers have requested that we include some limited scalability experiments in the final version of the paper; these experiments have not been designed yet and so are not part of this artifact.

## Hardware Dependencies

For the "kick-the-tires" phase of the artifact evaluation, a moderately powerful laptop (x86 or ARM) that can run Docker should be sufficient---say, a laptop with at least 4 vCPUs and 8 GB RAM.
We have tested the "kick-the-tires" phase on these machines:
- a 2023 M2 MacBook Pro with 10 vCPUs and 16 GB RAM
- an x86 Ubuntu server with 4 vCPUs and 16 GB RAM 

For the full evaluation of the artifact, a more powerful machine is necessary (~40 vCPUs, ~200 GB of memory).
We will give artifact reviewers SSH access to an AWS EC2 with the correct specs.
Access will be coordinated via the AEC chairs.

## Getting Started Guide (Phase 1)

You should be able to run these experiments on a moderately powerful laptop that has Docker.
In the `vms/` directory, there are two archived Docker images, one for x86 and one for ARM; we recommend using whichever one matches your architecture.
These Ubuntu-based images contain all the software (and scripts) needed to run the experiments we report on in the paper.

Make sure Docker is configured to give containers at least 4 CPUs and 8 GB RAM; to see what the current setting is, grep for "CPUs" and "Total Memory" in the output of the command `docker info`.
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
./scripts/kicktires.sh phase1_results
```

This will populate the directory `~/phase1_results` with output files from the experiment.
On a 2023 M2 MacBook Pro with 10 vCPUS and 16GB RAM this takes 8.5 minutes; XXX.
Each file is named according to this convention:

```
[case study]__[benchmark]__[SMT mode]__[eval mode]__[trial num].txt
```

We use two SMT modes in our experiments, `csa` (short for `check-sat-assuming`) and `pp` (short for `push-pop`).
These determine the incremental SMT solving encoding used by the Formulog runtime (for more details, see [an ICLP'20 extended abstract](https://aaronbembenek.github.io/papers/datalog-incr-smt-iclp2020.pdf)).

The possible values for `[eval mode]` are:

- `interpret`: use Formulog interpreter in semi-naive mode
- `interpret-reorder`: reorder each rule body so delta atom is first, and then use Formulog interpreter in semi-naive mode
- `interpret-unbatched`: use Formulog interpreter in eager evaluation mode
- `compile`: use Formulog compiler to generate code performing semi-naive evaluation
- `compile-reorder`: reorder each rule body so delta atom is first, and then use Formulog compiler to generate code performing semi-naive evaluation
- `compile-unbatched`: use Formulog compiler to generate code performing eager evaluation

XXX

- Turn into CSV
- Run analysis script on it
- Expected results
- Reference impls

### Experiment #2: Count SLOC for Eager Evaluation Implementations

In the paper, we claim that eager evaluation can be relatively easily added to existing Datalog infrastructure.
To demonstrate this, we have provided a script to count the number of lines of code needed to support eager evaluation in the Formulog interpreter and Soufflé code generator:

```
./scripts/count_sloc
```

This should print out some statistics about lines of code using the `cloc` utility; in particular, that our eager evaluation implementation in the Formulog interpreter consists of 481 SLOC Java, and our extensions to Souffle consist of 59 SLOC modifications, 558 SLOC additions, and 2 SLOC removals.

### Exploring the Artifact

- Layout
- Where to find various modifications
- Running an example Formulog program, interpreter and compiled, eager and non-eager

## Step-by-Step Instructions (Phase 2)

- Run experiment script
- Run analysis script
- What to expect

## Reusability Guide

- Implementation of eager eval in Formulog interpreter is reusable in that we have abstract class that could support other types of evaluation; also would be easy to use eager eval for some stratum and semi-naive for others
- Can use eager eval for other Formulog programs, both with interpreter and Souffle
- Could potentially use eager eval for other Souffle programs
- Experimental infrastructure and benchmarks