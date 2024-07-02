# Making Formulog Fast

Welcome to the artifact for "Making Formulog Fast" (artifact #45, paper #434).

This README is organized as follows:

- Introduction
- Hardware Dependencies
- Getting Started Guide
- Step-by-Step Instructions
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
- Our improvements to Formulog---compilation and (on SMT-heavy benchmarks) eager evaluation---help Formulog be competitive with previously published, non-Datalog implementations of a range of SMT-based program analyses; this claim can be evaluated using the experiment scripts in the artifact.
- Eager evaluation can be added to existing Datalog infrastructure with relatively low amounts of new code (~200 SLOC in the Formulog interpreter, and ~500 SLOC in Soufflé); this claim can be evaluated by running the utility `sloccount` on the source directories contained in this artifact.

More details about evaluating each claim are given in the instructions below.

### Unsupported Claims

The paper reviewers have requested that we include some limited scalability experiments in the final version of the paper; these experiments have not been designed yet and so are not part of this artifact.

### Artifact Layout

XXX

## Hardware Dependencies

For the "kick-the-tires" phase of the artifact evaluation, a reasonably powerful laptop (x86 or ARM) that can run Docker should be sufficient---say, a laptop with at least 4 vCPUs and 8 GB RAM.
We have tested the "kick-the-tires" phase on these machines:
- a 2023 M2 MacBook Pro with 10 vCPUs and 16 GB RAM
- an x86 Ubuntu server with 4 vCPUs and 16 GB RAM 

For the full evaluation of the artifact, a more powerful machine is necessary (~40 vCPUs, ~200 GB of memory).
We will give artifact reviewers SSH access to an AWS EC2 with the correct specs.
Access will be coordinated by the AEC chairs.

## Getting Started Guide

## Step-by-Step Instructions

## Reusability Guide
