FROM debian:forky

# Apparently snapshots.debian.org has heavy rate limiting policy so we better
# provide some apt conf tune ups with hope to make apt more robust in talking to it
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=959518  for more info
# (later apt as now in sid should be more robust)
RUN echo 'Acquire::http::Dl-Limit "200";' >| /etc/apt/apt.conf.d/20snapshots \
    && echo 'Acquire::https::Dl-Limit "200";' >> /etc/apt/apt.conf.d/20snapshots \
    && echo 'Acquire::Retries "10";' >> /etc/apt/apt.conf.d/20snapshots

# Notes:
# - in APT for NeuroDebian we have #deb-src  for debian-devel, so we need to change
#   that too.
# - APT specification switched away from .list to .sources format in bookworm.
#   nd_freeze works on policy output so works fine but does not disable old source
#   file, so we are moving it to .disabled "manually" here if we do not detect
#   use of snapshot url there (we might implement support that way).
#   Remove after https://github.com/neurodebian/neurodebian/issues/90 is fixed/released
#   for the used date of nd_freeze.
# - Originally used neurodebian, now switched to debian based for trixie
RUN set -ex; \
    apt update; \
    apt install neurodebian-freeze; \
    nd_freeze 20260425; \
    f=/etc/apt/sources.list.d/debian.sources; if [ -e "$f" ] && ! grep -q "^URIs:.*snapshot\." "$f"; then mv "$f" "$f.disabled"; fi; \
    sed -i -e 's,\(^deb\) \(.*\),\1 \2\ndeb-src \2,g' /etc/apt/sources.list.d/*.list; \
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
