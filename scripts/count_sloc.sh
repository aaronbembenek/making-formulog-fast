#!/usr/bin/env bash

# This script counts the number of lines added to the Formulog interpreter and
# Souffle code generator to support eager evaluation.

set -e

script_dir=$(dirname -- "$(readlink -f -- "$0")")
cd "$script_dir/.."

echo "********************************************************************************"
echo "////////////////////////////////////////////////////////////////////////////////"
echo "********************************************************************************"
echo
echo Calculating eager eval SLOC for Formulog interpreter...
echo
echo

# The eager evaluation implementation in the Formulog interpreter primarily
# consists of two files, one with a class representing an abstract stratum
# evaluator (it is also used by the interpreter's implementation of semi-naive
# evaluation), and the other with a class specialized for eager evaluation.

cloc --include-lang Java \
	formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/AbstractStratumEvaluator.java \
	formulog/src/main/java/edu/harvard/seas/pl/formulog/eval/EagerStratumEvaluator.java 
echo
echo "********************************************************************************"
echo "////////////////////////////////////////////////////////////////////////////////"
echo "********************************************************************************"
echo
echo Calculating eager eval SLOC for Souffle...
echo
echo

# Calculate how much C++ code we have added to Souffle since forking from the
# main project. 

cd souffle
cloc --include-lang "C/C++ Header,C++" --git \
	--diff 314106da98c13b7a5c10a96f1a9143344300103c eager-eval
