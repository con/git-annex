-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.0
Source: git-annex
Binary: git-annex-standalone
Architecture: any
Version: 10.20220222-1~ndall+1
Maintainer: Richard Hartmann <richih@debian.org>
Homepage: http://git-annex.branchable.com/
Standards-Version: 3.9.8
Vcs-Git: git://git.joeyh.name/git-annex
Testsuite: autopkgtest
Testsuite-Triggers: git, gnupg, rsync
Build-Depends: debhelper (>= 9), ghc (>= 8.4.3), cabal-install, libghc-mtl-dev (>= 2.1.1), libghc-split-dev, libghc-data-default-dev, libghc-hslogger-dev, libghc-pcre-light-dev, libghc-cryptonite-dev, libghc-memory-dev, libghc-deepseq-dev, libghc-attoparsec-dev, libghc-sandi-dev, libghc-utf8-string-dev, libghc-aws-dev (>= 0.9.2-2~), libghc-conduit-dev, libghc-resourcet-dev, libghc-quickcheck2-dev, libghc-monad-control-dev (>= 0.3), libghc-transformers-dev, libghc-exceptions-dev (>= 0.6), libghc-unix-compat-dev, libghc-dlist-dev, libghc-uuid-dev, libghc-aeson-dev, libghc-tagsoup-dev, libghc-unordered-containers-dev, libghc-ifelse-dev, libghc-bloomfilter-dev, libghc-edit-distance-dev, libghc-hinotify-dev [linux-any], libghc-dbus-dev (>= 0.10.7) [linux-any], libghc-fdo-notify-dev (>= 0.3) [linux-any], libghc-yesod-dev (>= 1.2.6.1) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-core-dev (>= 1.2.19) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-form-dev (>= 1.3.15) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-static-dev (>= 1.2.4) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-shakespeare-dev (>= 2.0.0) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-clientsession-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-dev (>= 3.0.0.5) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-tls-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-extra-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 mips mips64el mipsel powerpc ppc64el s390x], libghc-dav-dev (>= 1.0), libghc-persistent-dev, libghc-persistent-template-dev, libghc-persistent-sqlite-dev, libghc-microlens-dev, libghc-securemem-dev, libghc-byteable-dev, libghc-stm-chans-dev, libghc-case-insensitive-dev, libghc-http-types-dev, libghc-http-conduit-dev, libghc-blaze-builder-dev, libghc-crypto-api-dev, libghc-network-multicast-dev, libghc-network-info-dev [linux-any kfreebsd-any], libghc-safesemaphore-dev, libghc-async-dev, libghc-monad-logger-dev, libghc-free-dev, libghc-feed-dev (>= 0.3.9.2), libghc-regex-tdfa-dev, libghc-tasty-dev (>= 0.7), libghc-tasty-hunit-dev, libghc-tasty-quickcheck-dev, libghc-tasty-rerun-dev, libghc-optparse-applicative-dev (>= 0.11.0), libghc-torrent-dev, libghc-concurrent-output-dev, libghc-disk-free-space-dev, libghc-mountpoints-dev, libghc-magic-dev, libghc-socks-dev, libghc-vector-dev, libghc-filepath-bytestring-dev, libghc-criterion-dev, lsof [linux-any], ikiwiki, libimage-magick-perl, git (>= 1:2.22), rsync, curl, locales, openssh-client, git-remote-gcrypt (>= 0.20130908-6), gnupg, gpg-agent
Package-List:
 git-annex-standalone deb utils optional arch=any
Checksums-Sha1:
 d150223a1d2cd0d8304d8249414344285846f8c1 66251824 git-annex_10.20220222-1~ndall+1.tar.gz
Checksums-Sha256:
 a57ea4d9b8ede0e76fdd9d0633d6b7cf81a5ee3468a1dec3ebb85ce98df10d4f 66251824 git-annex_10.20220222-1~ndall+1.tar.gz
Files:
 0b22e771c78b3deea8c6cbbbd415ac36 66251824 git-annex_10.20220222-1~ndall+1.tar.gz

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEE6EJMpYVRYQkXgMAyY/EnTbasX8FAmIVJl0ACgkQyY/EnTba
sX/Y9gv/VNHVtcceqQmcwsUIFYeqMCw3/3LUgmCS/N+YX/Xg6gsNU62siSZgK2Ka
qYIRbHfzJNsq2X4kM1RLDaWpDKCF039lsrV4GtYuS0UzkLPktc/SjWvheuypdPTT
TkYTdafJiFGuR1WSO5UGO7DeUutXZCab/hAxen1/1fk2meEo1mR5273V5B7sMZVb
68H27J8/EHP7OKeSig29YMRmIiSllFQ/6RUPwV8Uzpwdm7y6oL9cVNWJJIA/ndxJ
uFo46aMsHPBWgSia20xuH4aUTM/bUcUSZMUBOono8CYadyHaaUIwET16UJfj2CBV
DIPZ13n7utBxnQzRLxd1TrrpYhka19ca87B/XAak3iGNEDHXUw2+jgzVeTOotk84
aY+JZshE9kk4IGTTLBrco172Ub+5wxAUTnDiwF0LjtSz1891Ptdq0HEHopMeUvsa
6L7lRV73etphugU/CAZaDyhsdIZ4IXf4Gn9KUAAnsH2nMajsu5dDVDq2uHUEET6U
4gqFxhkd
=pPwk
-----END PGP SIGNATURE-----
