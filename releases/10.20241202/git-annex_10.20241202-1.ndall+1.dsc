-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.0
Source: git-annex
Binary: git-annex-standalone
Architecture: any
Version: 10.20241202-1~ndall+1
Maintainer: Richard Hartmann <richih@debian.org>
Homepage: http://git-annex.branchable.com/
Standards-Version: 3.9.8
Vcs-Git: git://git.joeyh.name/git-annex
Testsuite: autopkgtest
Testsuite-Triggers: git, gnupg, rsync
Build-Depends: debhelper (>= 9), ghc (>= 8.4.3), cabal-install, libghc-mtl-dev (>= 2.1.1), libghc-split-dev, libghc-data-default-dev, libghc-hslogger-dev, libghc-cryptonite-dev, libghc-memory-dev, libghc-deepseq-dev, libghc-attoparsec-dev, libghc-sandi-dev, libghc-utf8-string-dev, libghc-aws-dev (>= 0.9.2-2~), libghc-conduit-dev, libghc-resourcet-dev, libghc-quickcheck2-dev, libghc-monad-control-dev (>= 0.3), libghc-transformers-dev, libghc-exceptions-dev (>= 0.6), libghc-unix-compat-dev, libghc-dlist-dev, libghc-uuid-dev, libghc-aeson-dev, libghc-tagsoup-dev, libghc-unordered-containers-dev, libghc-ifelse-dev, libghc-bloomfilter-dev, libghc-edit-distance-dev, libghc-hinotify-dev [linux-any], libghc-dbus-dev (>= 0.10.7) [linux-any], libghc-fdo-notify-dev (>= 0.3) [linux-any], libghc-yesod-dev (>= 1.2.6.1) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-core-dev (>= 1.2.19) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-form-dev (>= 1.3.15) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-static-dev (>= 1.2.4) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-shakespeare-dev (>= 2.0.0) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-clientsession-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-dev (>= 3.0.0.5) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-tls-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-extra-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-dav-dev (>= 1.0), libghc-persistent-dev, libghc-persistent-template-dev, libghc-persistent-sqlite-dev, libghc-microlens-dev, libghc-securemem-dev, libghc-byteable-dev, libghc-stm-chans-dev, libghc-case-insensitive-dev, libghc-http-types-dev, libghc-http-conduit-dev, libghc-http-client-restricted-dev, libghc-blaze-builder-dev, libghc-crypto-api-dev, libghc-network-multicast-dev, libghc-network-info-dev [linux-any kfreebsd-any], libghc-safesemaphore-dev, libghc-async-dev, libghc-monad-logger-dev, libghc-free-dev, libghc-feed-dev (>= 0.3.9.2), libghc-regex-tdfa-dev, libghc-tasty-dev (>= 0.7), libghc-tasty-hunit-dev, libghc-tasty-quickcheck-dev, libghc-tasty-rerun-dev, libghc-cabal-dev, libghc-ansi-terminal-dev, libghc-optparse-applicative-dev (>= 0.11.0), libghc-torrent-dev, libghc-concurrent-output-dev, libghc-disk-free-space-dev, libghc-mountpoints-dev, libghc-magic-dev, libghc-socks-dev, libghc-vector-dev, libghc-unliftio-core-dev, libghc-filepath-bytestring-dev, libghc-git-lfs-dev (>= 1.2.0), libghc-criterion-dev, libghc-clock-dev, libghc-servant-dev, libghc-servant-server-dev, libghc-servant-client-dev, libghc-servant-client-core-dev, lsof [linux-any], ikiwiki, libimage-magick-perl, git (>= 1:2.22), rsync, curl, locales, openssh-client, git-remote-gcrypt (>= 0.20130908-6), gnupg, gpg-agent
Package-List:
 git-annex-standalone deb utils optional arch=any
Checksums-Sha1:
 024e23fca62c7915f715848110362f6546b082e8 9928348 git-annex_10.20241202-1~ndall+1.tar.gz
Checksums-Sha256:
 bce7e2bbb3ac712bef5ee989b08b61c5674be182f27593569dedbb0a70401b64 9928348 git-annex_10.20241202-1~ndall+1.tar.gz
Files:
 0e05b04bfce73d8351b25558239de2e0 9928348 git-annex_10.20241202-1~ndall+1.tar.gz

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEE6EJMpYVRYQkXgMAyY/EnTbasX8FAmdN+WEACgkQyY/EnTba
sX9pUgwApTRAdbBvwJQ83peTG99SLNt+TgxwkOfYYDuQ26NRwEVMngNku6Te1JkR
x+pEK82pX5t3EP9tqc1Xe6UfmlaKIuA9E5L5OM46wJvdpUipACGv4psXcLxkjhmO
DHwflb5gtrqmpL8RfuVtxyU7QRToy//YS5nSrWRKfqVJvISOQFUpxNvsSUwtuqgk
JdUyY2eE8oK4TuO+zco7KRL8MhgHZ4SnWix7Jw4BUmGjwrJ+sFPSIxuGBqb6/I/S
8LE+BU9iad8xE2ceQ/AaSqXcpB+jKE0vavLeLY9AdZqhe6+rZP7uQxB9pK+Fhkwh
NlhBtCaZjh/4k1jcgggQvJi2iOiDvt7n5bMAHLAt0L81FekX+M7TZDZ1VM9VTr2C
G1+ekET6LrkNZunWZs4FdpCKONI28qUKfgDcH2i0FnqYZ/Iy1mHE2ZnKij8MoYV6
V8MPPNXOvOD8qwSpTrs/mhYVjQbVQeEJG92f8/yr+4bKNmQmr46n3G692reok0Ml
nfJV+910
=OBZy
-----END PGP SIGNATURE-----
