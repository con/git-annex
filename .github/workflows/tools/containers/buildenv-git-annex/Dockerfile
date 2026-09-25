FROM debian:forky

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
ARG DEBIAN_SNAPSHOT=20260924T000000Z
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
