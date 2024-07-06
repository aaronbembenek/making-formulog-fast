# Artifact for "Making Formulog Fast"

These are internal instructions for building the artifact.
Instructions for reviewers are in [434/README.md](434/README.md).

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

