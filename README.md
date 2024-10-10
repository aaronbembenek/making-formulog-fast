# Artifact for "Making Formulog Fast"

This repository contains the material for the artifact for the OOPSLA'24 paper [Making Formulog Fast: An Argument for Unconventional Datalog Evaluation](https://dl.acm.org/doi/10.1145/3689754) by Aaron Bembenek, Michael Greenberg, and Stephen Chong.
The [official artifact on Zenodo](https://zenodo.org/records/13372573) was reviewed as being "Reusable" and "Reproducible," and was recognized as a [Distinguished Artifact](https://2024.splashcon.org/track/splash-2024-oopsla-artifacts#distinguished-artifacts).

The two primary purposes for open sourcing this repository are:

1. the repository includes the experimental infrastructure, results, and analysis for the scaling experiments reported in Section 5.3.4, which are not present in the reviewed artifact (check out the `scaling` branch of this repository); and
2. the GitHub UI makes it easy to skim the artifact's material without downloading the Docker images (for example, you can easily examine the case study implementations in the `benchmarks/` directory).

Instructions for reviewers (and folks interested in running the artifact) are in the file [434/README.md](434/README.md); you'll need to download the appropriate Docker image from the "Releases" section of the GitHub repository.

## Build Instructions

These are internal instructions for building the artifact.

First, you need to download `lib_facts.zip` from the GitHub repo "Releases" to the base directory.

We build two images, one for AMD64/x86_64 and one for ARM64/AArch64:

```bash
docker build --platform linux/amd64 -t mff-amd64 .
docker build --platform linux/arm64 -t mff-arm64 .
```

To distribute the images, save them as archives:

```bash
docker save mff-amd64 | gzip > 434/vms/mff-amd64.tar.gz
docker save mff-arm64 | gzip > 434/vms/mff-arm64.tar.gz
```

Saved images will be put in the "Releases" section of the GitHub repo.

## Ubuntu 22.04 Setup

- Put script `setup_ubuntu_x86.sh` in `scripts/` directory
- Run script `./scripts/setup_ubuntu_x86.sh`
- Put archive `lib_facts.zip` in `benchmarks/scuba/` directory
- Add `/usr/local/lib/` to `LD_LIBRARY_PATH` variable

```bash
echo "export LD_LIBRARY_PATH=/usr/local/lib/" >> ~/.bashrc
```

