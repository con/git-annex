# Use a dated tag, not the floating debian:forky, and keep it no newer than
# DEBIAN_SNAPSHOT below (bump both together): packages preinstalled in a newer
# image (e.g. libc6) are newer than the snapshot's, and apt then cannot satisfy
# the build-deps (libc6-dev from the snapshot requires the snapshot's libc6).
# NB: the build-linux-buildenv workflow takes the suite name from this line.
FROM debian:forky-20261005

# Apparently snapshots.debian.org has heavy rate limiting policy so we better
# provide some apt conf tune ups with hope to make apt more robust in talking to it
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=959518  for more info
# (later apt as now in sid should be more robust)
RUN echo 'Acquire::http::Dl-Limit "200";' >| /etc/apt/apt.conf.d/20snapshots \
    && echo 'Acquire::https::Dl-Limit "200";' >> /etc/apt/apt.conf.d/20snapshots \
    && echo 'Acquire::Retries "10";' >> /etc/apt/apt.conf.d/20snapshots

# Pin APT to a snapshot.debian.org timestamp by writing the deb822 sources
# directly, instead of via nd_freeze.  nd_freeze scrapes snapshot.debian.org
# with a raw HTTP/1.1 socket read that has no timeout, and a build once hung
# there silently until the 6h job limit.  snapshot.debian.org serves the most
# recent snapshot at or before the given timestamp.  deb-src is needed for
# `apt-get build-dep`.  The Release files on snapshots are past their
# Valid-Until, hence Check-Valid-Until=false.
# NB: the build-linux-buildenv workflow parses DEBIAN_SNAPSHOT for image tags.
ARG DEBIAN_SNAPSHOT=20261006T000000Z
RUN set -ex; \
    echo 'Acquire::Check-Valid-Until "false";' >| /etc/apt/apt.conf.d/10no-check-valid-until; \
    echo 'Acquire::http::Timeout "120";' >> /etc/apt/apt.conf.d/20snapshots; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*; \
    printf '%s\n' \
      'Types: deb deb-src' \
      "URIs: http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}" \
      'Suites: forky forky-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      '' \
      'Types: deb deb-src' \
      "URIs: http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}" \
      'Suites: forky-security' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      >| /etc/apt/sources.list.d/debian-snapshot.sources; \
    cat /etc/apt/sources.list.d/debian-snapshot.sources; \
    apt-get update -qq; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get build-dep -y -q git-annex; \
    # git-annex >= 10.20261005 Build-Depends on ram, Debian's git-annex not (yet)
    apt-get install -y libghc-ram-dev; \
    # git-annex >= 10.20261105 requires Botan 3 (C++ library; its Haskell
    # bindings are built below).  It is in upstream's debian/control
    # Build-Depends, but not in those of Debian's git-annex (yet)
    apt-get install -y libbotan-3-dev pkgconf; \
    pkg-config --modversion botan-3; \
    # Needed additional tools etc
    apt-get install -y devscripts quilt locales; \
    # Some helper utilities just in case
    apt-get install -y vim wget strace time ncdu gnupg curl procps datalad pigz less tree; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# git-annex's OsPath build flag (Default: True, but automatic, so ./Setup
# configure silently drops it when a dependency is missing) needs
# file-io >= 0.2.0 since 10.20260213.  GHC 9.10 here already provides
# filepath >= 1.5.2, os-string >= 2.0 and directory >= 1.3.8.3, but Debian
# ships only libghc-file-io-dev 0.1.5, so without this builds lack OsPath
# (and with it the fixes e.g. for rename handling on BeeGFS:
# https://git-annex.branchable.com/bugs/35_failed_tests_on_beegfs/).
# file-io only needs GHC boot packages, so register it into the global
# package db.  Drop once Debian provides libghc-file-io-dev (>= 0.2.0).
ARG FILE_IO_VERSION=0.2.0
ARG FILE_IO_SHA256=8e75f8905d7c9f114e6164779e7a19ff0e2968015ecf686934e38250575dabe7
RUN set -ex; \
    cd /tmp; \
    curl -fsSL -o file-io.tar.gz "https://hackage.haskell.org/package/file-io-${FILE_IO_VERSION}/file-io-${FILE_IO_VERSION}.tar.gz"; \
    echo "${FILE_IO_SHA256}  file-io.tar.gz" | sha256sum -c -; \
    tar xzf file-io.tar.gz; \
    cd "file-io-${FILE_IO_VERSION}"; \
    printf 'import Distribution.Simple\nmain = defaultMain\n' > Setup.hs; \
    runghc Setup.hs configure --global --prefix=/usr/local; \
    runghc Setup.hs build; \
    runghc Setup.hs install; \
    ghc-pkg field file-io version; \
    cd /; rm -rf /tmp/file-io*

# git-annex's MagicMime build flag (automatic as well) needs the Haskell
# libmagic >= 1.3 binding since upstream c51f910bc4 (2026-10-27), which Debian
# does not package yet.  Drop once Debian provides libghc-libmagic-dev (>= 1.3).
ARG LIBMAGIC_VERSION=1.3.1
ARG LIBMAGIC_SHA256=da224c70e95758fb38fab3956724fcff54d838001fd463493e52cd52bc2228e0
RUN set -ex; \
    cd /tmp; \
    curl -fsSL -o libmagic.tar.gz "https://hackage.haskell.org/package/libmagic-${LIBMAGIC_VERSION}/libmagic-${LIBMAGIC_VERSION}.tar.gz"; \
    echo "${LIBMAGIC_SHA256}  libmagic.tar.gz" | sha256sum -c -; \
    tar xzf libmagic.tar.gz; \
    cd "libmagic-${LIBMAGIC_VERSION}"; \
    printf 'import Distribution.Simple\nmain = defaultMain\n' > Setup.hs; \
    runghc Setup.hs configure --global --prefix=/usr/local; \
    runghc Setup.hs build; \
    runghc Setup.hs install; \
    ghc-pkg field libmagic version; \
    cd /; rm -rf /tmp/libmagic*

# git-annex unconditionally depends on the Haskell botan-low (< 0.3) binding
# since upstream 023d3a32d8 (2026-11-05, "Botan is enabled by default; removed
# build flag"), which Debian does not package yet (libghc-botan-low-dev is
# commented out in upstream's debian/control).  Versions match upstream's
# stack.yaml.  botan-bindings locates libbotan-3-dev via pkg-config.
# Drop once Debian provides libghc-botan-low-dev.
ARG BOTAN_BINDINGS_VERSION=0.3.0.0
ARG BOTAN_BINDINGS_SHA256=b6c6ab21cdcb71428f812599fb17063d618ed9ff4e17a4961c1ea7997fef258c
ARG BOTAN_LOW_VERSION=0.2.0.1
ARG BOTAN_LOW_SHA256=c82f8624334ee7c4c8735f7b3209ffbeaa6de1f63762084b8497e61a4423b319
RUN set -ex; \
    cd /tmp; \
    for spec in \
        "botan-bindings ${BOTAN_BINDINGS_VERSION} ${BOTAN_BINDINGS_SHA256}" \
        "botan-low ${BOTAN_LOW_VERSION} ${BOTAN_LOW_SHA256}" \
    ; do \
        set -- $spec; \
        curl -fsSL -o "$1.tar.gz" "https://hackage.haskell.org/package/$1-$2/$1-$2.tar.gz"; \
        echo "$3  $1.tar.gz" | sha256sum -c -; \
        tar xzf "$1.tar.gz"; \
        ( cd "$1-$2"; \
          printf 'import Distribution.Simple\nmain = defaultMain\n' > Setup.hs; \
          runghc Setup.hs configure --global --prefix=/usr/local; \
          runghc Setup.hs build; \
          runghc Setup.hs install ); \
        ghc-pkg field "$1" version; \
        rm -rf "/tmp/$1"*; \
    done
