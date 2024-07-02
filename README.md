# Artifact for "Making Formulog Fast"

These are internal instructions for building the artifact.
Instructions for reviewers are in [docs/README.md](docs/README.md).

First, you need to download `lib_facts.zip` from the GitHub repo releases section and put it in the base directory of the repo.

We build two images, one for AMD64/x86_64 and one for ARM64/AArch64:

```bash
docker build --platform linux/amd64 -t mff-amd64 .
docker build --platform linux/arm64 -t mff-arm64 .
```

To distribute the images, save them as archives:

```bash
docker save mff-amd64 | gzip > vms/mff-amd64.tar.gz
docker save mff-arm64 | gzip > vms/mff-arm64.tar.gz
```

