ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:22.04 AS base

FROM base AS build-arm64
ARG DEBIAN_FRONTEND
WORKDIR /root/lib/
RUN apt-get update && apt-get install -y build-essential cmake git python3 \
    # Install Z3
    && git clone https://github.com/Z3Prover/z3.git \
    && cd z3 \
    && git checkout f7c9c9ef72fde0e00ef9409e6c24456effb8b930 \
    && cmake -B build -S . -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j$(nproc) \
    && cmake --build build --target install \
    && cd .. \
    && rm -rf z3

FROM base AS build-amd64
ARG DEBIAN_FRONTEND
WORKDIR /root/lib/
ADD lib/ /root/lib/
ARG JAVA_VERSION=zulu7.56.0.11-ca-jdk7.0.352-linux_x64
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    cmake \
    git \
    python3 \
    curl \
    file \
    g++-multilib \
    gcc-multilib \
    libcap-dev \
    libgoogle-perftools-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libtcmalloc-minimal4 \
    python3-pip \
    unzip \
    clang-13 \
    llvm-13 \
    llvm-13-dev \
    llvm-13-tools \
    bash-completion \
    tmux \
    sloccount \
    # Install Java 7
    && wget "https://cdn.azul.com/zulu/bin/$JAVA_VERSION.tar.gz" -O java7.tar.gz \
    && tar -xf java7.tar.gz \
    && mv "$JAVA_VERSION" java7 \
    && rm -rf java7.tar.gz \
    # Install Z3
    && git clone https://github.com/Z3Prover/z3.git \
    && cd z3 \
    && git checkout f7c9c9ef72fde0e00ef9409e6c24456effb8b930 \
    && git apply ../z3.patch \
    && export JAVA_HOME=$PWD/../java7/ \
    && export PATH="$JAVA_HOME/bin:$PATH" \
    && cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DZ3_BUILD_JAVA_BINDINGS=TRUE -DZ3_INSTALL_JAVA_BINDINGS=TRUE \
    && cmake --build build -j$(nproc) \
    && cmake --build build --target install \
    && cd .. \
    && rm -rf z3 \
    # Install KLEE
    && git clone https://github.com/klee/klee-uclibc.git \
    && cd klee-uclibc \
    && git checkout 955d502 \
    && ./configure --make-llvm-lib --with-cc clang-13 --with-llvm-config llvm-config-13 \
    && make -j$(nproc) \
    && cd .. \
    && git clone --depth 1 --branch v3.0 https://github.com/klee/klee.git \
    && cd klee \
    && cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DENABLE_SOLVER_Z3=ON -DENABLE_POSIX_RUNTIME=ON -DKLEE_UCLIBC_PATH=../klee-uclibc -DENABLE_UNIT_TESTS=OFF -DENABLE_SYSTEM_TESTS=OFF -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j$(nproc) \
    && cmake --build build --target install \
    && cmake --build build --target clean \
    # Install CBMC
    && wget "https://github.com/diffblue/cbmc/releases/download/cbmc-5.85.0/ubuntu-22.04-cbmc-5.85.0-Linux.deb" -O cbmc.deb \
    && dpkg -i cbmc.deb \
    && rm cbmc.deb

FROM build-${TARGETARCH} AS build
ARG DEBIAN_FRONTEND
WORKDIR /root/lib/
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    bison \
    build-essential \
    cmake \
    doxygen \
    flex \
    g++ \
    git \
    libffi-dev \
    libncurses5-dev \
    libsqlite3-dev \
    mcpp \
    python3 \
    sqlite3 \
    zlib1g-dev \
    wget \
    unzip \
    vim \
    clang-13 \
    maven \
    time \
    # Install TBB
    && git clone --depth 1 --branch v2021.13.0 https://github.com/oneapi-src/oneTBB.git \
    && cd oneTBB \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DTBB_TEST=OFF \
    && cmake --build build -j$(nproc) \
    && cmake --install build \
    && cd .. \
    && rm -rf oneTBB \
    # Install Boost
    && wget https://boostorg.jfrog.io/artifactory/main/release/1.81.0/source/boost_1_81_0.tar.gz \
    && tar -xf boost_1_81_0.tar.gz \
    && cd boost_1_81_0 \
    && ./bootstrap.sh \
    && ./b2 \
    && ./b2 install \
    && cd .. \
    && rm -rf boost_1_81_0 boost_1_81_0.tar.gz \
    # Install modified Souffle
    && cd \
    && git clone --branch eager-eval https://github.com/aaronbembenek/souffle.git \
    && cd souffle \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DSOUFFLE_ENABLE_TESTING=OFF \
    && cmake --build build -j$(nproc) \
    && cmake --build build --target install \
    && cmake --build build --target clean \
    && cd .. \
    # Install Formulog
    && cd \
    && git clone --branch mff-artifact https://github.com/aaronbembenek/formulog-fork.git \
    && mv formulog-fork formulog \
    && cd formulog \
    && mvn package \
    && git rev-parse --short HEAD >../lib/formulog_commit.txt \
    && cd ../lib/ \
    && ln -s $PWD/../formulog/target/formulog-0.7.0-SNAPSHOT-jar-with-dependencies.jar formulog.jar \
    && cd \
    # Set up vim syntax highlighting
    && mkdir -p .vim/syntax .vim/ftdetect \
    && cp formulog/misc/flg.vim .vim/syntax/ \
    && echo "au BufRead,BufNewFile *.flg set filetype=flg" > .vim/ftdetect/flg.vim

WORKDIR /root/
COPY benchmarks/ benchmarks/
COPY scripts/ scripts/
COPY results/ results/
COPY lib_facts.zip benchmarks/scuba/lib_facts.zip
ENV LD_LIBRARY_PATH=/usr/local/lib/