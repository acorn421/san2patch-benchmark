FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y

RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    autopoint \
    bear \
    bison \
    ca-certificates \
    cmake \
    curl \
    flex \
    gettext \
    git \
    gperf \
    libass-dev \
    libfreetype6 \
    libfreetype6-dev \
    libjpeg-dev \
    libnuma-dev \
    libpciaccess-dev \
    libpython-dev \
    libpython3-dev \
    libsdl1.2-dev \
    libsqlite3-dev \
    libtool \
    libvdpau-dev \
    libx11-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxml2-dev \
    nasm \
    nano \
    openssl \
    pkg-config \
    psmisc \
    python3 \
    texinfo \
    xutils-dev \
    yasm \
    m4 \
    libglib2.0-dev \
    libldap-dev \
    libbz2-dev \
    libssl-dev \
    libgdbm-dev \
    subversion \
    libc6-dev-i386 \
    mercurial \
    libncurses-dev \
    libsqlite-dev \
    libreadline-gplv2-dev \
    gcc-multilib \
    g++-multilib \
    tk-dev \
    tcl-dev \
    tix-dev \
    unzip \
    wget \
    clang \
    rsync \
    libmysqlclient-dev \
    default-mysql-server \
    libc++-dev \
    libc++abi-dev \
    libyaml-dev

WORKDIR /san2patch-benchmark
COPY . .

RUN chmod +x setup_all.sh build_all.sh install_additional_deps.sh

RUN bash setup_all.sh | tee setup_all.log
# RUN bash build_all.sh | tee build_all.log
RUN bash install_additional_deps.sh

ENV UBSAN_OPTIONS=print_stacktrace=1