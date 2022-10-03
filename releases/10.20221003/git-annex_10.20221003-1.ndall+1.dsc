-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.0
Source: git-annex
Binary: git-annex-standalone
Architecture: any
Version: 10.20221003-1~ndall+1
Maintainer: Richard Hartmann <richih@debian.org>
Homepage: http://git-annex.branchable.com/
Standards-Version: 3.9.8
Vcs-Git: git://git.joeyh.name/git-annex
Testsuite: autopkgtest
Testsuite-Triggers: git, gnupg, rsync
Build-Depends: debhelper (>= 9), ghc (>= 8.4.3), cabal-install, libghc-mtl-dev (>= 2.1.1), libghc-split-dev, libghc-data-default-dev, libghc-hslogger-dev, libghc-pcre-light-dev, libghc-cryptonite-dev, libghc-memory-dev, libghc-deepseq-dev, libghc-attoparsec-dev, libghc-sandi-dev, libghc-utf8-string-dev, libghc-aws-dev (>= 0.9.2-2~), libghc-conduit-dev, libghc-resourcet-dev, libghc-quickcheck2-dev, libghc-monad-control-dev (>= 0.3), libghc-transformers-dev, libghc-exceptions-dev (>= 0.6), libghc-unix-compat-dev, libghc-dlist-dev, libghc-uuid-dev, libghc-aeson-dev, libghc-tagsoup-dev, libghc-unordered-containers-dev, libghc-ifelse-dev, libghc-bloomfilter-dev, libghc-edit-distance-dev, libghc-hinotify-dev [linux-any], libghc-dbus-dev (>= 0.10.7) [linux-any], libghc-fdo-notify-dev (>= 0.3) [linux-any], libghc-yesod-dev (>= 1.2.6.1) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-core-dev (>= 1.2.19) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-form-dev (>= 1.3.15) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-static-dev (>= 1.2.4) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-shakespeare-dev (>= 2.0.0) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-clientsession-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-dev (>= 3.0.0.5) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-tls-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-extra-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-dav-dev (>= 1.0), libghc-persistent-dev, libghc-persistent-template-dev, libghc-persistent-sqlite-dev, libghc-microlens-dev, libghc-securemem-dev, libghc-byteable-dev, libghc-stm-chans-dev, libghc-case-insensitive-dev, libghc-http-types-dev, libghc-http-conduit-dev, libghc-http-client-restricted-dev, libghc-blaze-builder-dev, libghc-crypto-api-dev, libghc-network-multicast-dev, libghc-network-info-dev [linux-any kfreebsd-any], libghc-safesemaphore-dev, libghc-async-dev, libghc-monad-logger-dev, libghc-free-dev, libghc-feed-dev (>= 0.3.9.2), libghc-regex-tdfa-dev, libghc-tasty-dev (>= 0.7), libghc-tasty-hunit-dev, libghc-tasty-quickcheck-dev, libghc-tasty-rerun-dev, libghc-ansi-terminal-dev, libghc-optparse-applicative-dev (>= 0.11.0), libghc-torrent-dev, libghc-concurrent-output-dev, libghc-disk-free-space-dev, libghc-mountpoints-dev, libghc-magic-dev, libghc-socks-dev, libghc-vector-dev, libghc-filepath-bytestring-dev, libghc-criterion-dev, lsof [linux-any], ikiwiki, libimage-magick-perl, git (>= 1:2.22), rsync, curl, locales, openssh-client, git-remote-gcrypt (>= 0.20130908-6), gnupg, gpg-agent
Package-List:
 git-annex-standalone deb utils optional arch=any
Checksums-Sha1:
 cf5e8651ac5ff45948384664612a76efd8359bb0 68017130 git-annex_10.20221003-1~ndall+1.tar.gz
Checksums-Sha256:
 7b6fe5fed6dc030637b071ce1276e96805e36f9a1664786546fe726374fa9198 68017130 git-annex_10.20221003-1~ndall+1.tar.gz
Files:
 9be18e9c66bdb9abf754a80b9586ebce 68017130 git-annex_10.20221003-1~ndall+1.tar.gz

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEE6EJMpYVRYQkXgMAyY/EnTbasX8FAmM7KIIACgkQyY/EnTba
sX95twwAr1gjigCkMRKPPaSJhw8BQLSmk52BGeWkJ0i8or/f0+9kSIqrLc679BPM
ZXifXYFTdqIQYBkE/gLOlBuKnesc+EcccpyQ4wiOKP69ZjfnjPVfYnlm8niYC3IU
kMMl6GOrTzL0S6CBM6KGSPyqsbE2Wpea8U6ndlQDq8LsLQMyVtNtAsZFvj4CWZVf
iEkTjggik0Tk2nkS0Q1T32try4FaPFlJAtK3xh8eur1mwimvdrY2HOcUQO6raJTR
PGl7YYM+ENWFcGbuSyo5ZWGgrKfH8w50KnaKg7Kar+okPvS59nGNHHhw3CXm2td9
DR+D53RKDNQPv41tmwyChpJE4eJIPYV9AYNLvFwK/z579cDypY9XcIYjaPW1G/rc
TC5T2WVwxaZVUrw1nyJlfDPTaZnSQ0W+odXdiMzQK7fTd06VRFFiYyRXALA9hlo4
RnxDeGZe8lLKfJdF7o+JqthLTOd2ARonEAuxSirOq/nS3L4YZM0G7rMtVFMj2YWg
IJQcH/EV
=5WRI
-----END PGP SIGNATURE-----
