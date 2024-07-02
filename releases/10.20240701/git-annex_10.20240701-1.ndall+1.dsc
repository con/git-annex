-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.0
Source: git-annex
Binary: git-annex-standalone
Architecture: any
Version: 10.20240701-1~ndall+1
Maintainer: Richard Hartmann <richih@debian.org>
Homepage: http://git-annex.branchable.com/
Standards-Version: 3.9.8
Vcs-Git: git://git.joeyh.name/git-annex
Testsuite: autopkgtest
Testsuite-Triggers: git, gnupg, rsync
Build-Depends: debhelper (>= 9), ghc (>= 8.4.3), cabal-install, libghc-mtl-dev (>= 2.1.1), libghc-split-dev, libghc-data-default-dev, libghc-hslogger-dev, libghc-cryptonite-dev, libghc-memory-dev, libghc-deepseq-dev, libghc-attoparsec-dev, libghc-sandi-dev, libghc-utf8-string-dev, libghc-aws-dev (>= 0.9.2-2~), libghc-conduit-dev, libghc-resourcet-dev, libghc-quickcheck2-dev, libghc-monad-control-dev (>= 0.3), libghc-transformers-dev, libghc-exceptions-dev (>= 0.6), libghc-unix-compat-dev, libghc-dlist-dev, libghc-uuid-dev, libghc-aeson-dev, libghc-tagsoup-dev, libghc-unordered-containers-dev, libghc-ifelse-dev, libghc-bloomfilter-dev, libghc-edit-distance-dev, libghc-hinotify-dev [linux-any], libghc-dbus-dev (>= 0.10.7) [linux-any], libghc-fdo-notify-dev (>= 0.3) [linux-any], libghc-yesod-dev (>= 1.2.6.1) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-core-dev (>= 1.2.19) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-form-dev (>= 1.3.15) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-yesod-static-dev (>= 1.2.4) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-shakespeare-dev (>= 2.0.0) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-clientsession-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-dev (>= 3.0.0.5) [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-warp-tls-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-wai-extra-dev [i386 amd64 arm64 armel armhf kfreebsd-i386 kfreebsd-amd64 m68k mips mips64el mipsel powerpc ppc64el s390x], libghc-dav-dev (>= 1.0), libghc-persistent-dev, libghc-persistent-template-dev, libghc-persistent-sqlite-dev, libghc-microlens-dev, libghc-securemem-dev, libghc-byteable-dev, libghc-stm-chans-dev, libghc-case-insensitive-dev, libghc-http-types-dev, libghc-http-conduit-dev, libghc-http-client-restricted-dev, libghc-blaze-builder-dev, libghc-crypto-api-dev, libghc-network-multicast-dev, libghc-network-info-dev [linux-any kfreebsd-any], libghc-safesemaphore-dev, libghc-async-dev, libghc-monad-logger-dev, libghc-free-dev, libghc-feed-dev (>= 0.3.9.2), libghc-regex-tdfa-dev, libghc-tasty-dev (>= 0.7), libghc-tasty-hunit-dev, libghc-tasty-quickcheck-dev, libghc-tasty-rerun-dev, libghc-cabal-dev, libghc-ansi-terminal-dev, libghc-optparse-applicative-dev (>= 0.11.0), libghc-torrent-dev, libghc-concurrent-output-dev, libghc-disk-free-space-dev, libghc-mountpoints-dev, libghc-magic-dev, libghc-socks-dev, libghc-vector-dev, libghc-unliftio-core-dev, libghc-filepath-bytestring-dev, libghc-git-lfs-dev (>= 1.2.0), libghc-criterion-dev, lsof [linux-any], ikiwiki, libimage-magick-perl, git (>= 1:2.22), rsync, curl, locales, openssh-client, git-remote-gcrypt (>= 0.20130908-6), gnupg, gpg-agent
Package-List:
 git-annex-standalone deb utils optional arch=any
Checksums-Sha1:
 7fa05b7e0e73e2cec8e5fe83f499f0eb1ed5fc69 9711565 git-annex_10.20240701-1~ndall+1.tar.gz
Checksums-Sha256:
 f63680e42c024c1bc37d383cc687f73fbbf88777041818d38702f22e84b6c26b 9711565 git-annex_10.20240701-1~ndall+1.tar.gz
Files:
 ef1570102815f1d1a5a5ca0af49dfdfa 9711565 git-annex_10.20240701-1~ndall+1.tar.gz

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEE6EJMpYVRYQkXgMAyY/EnTbasX8FAmaEQywACgkQyY/EnTba
sX+W7Av9E5TXpv4PlTO9NuKBb3jChPNy64BQPjRvUkS3v+H+T5dS9iaXDKAgQnCl
IiKQ3w4ABonguaNp8texIRNy8Y5fPg8gWCbUslsWDmksnk4fjmuzMkbExCGBIHjB
+n48EBcY8jiRhOVQ0XMeq3q4v6h82ZBFECvi9wXrrTU7aa5Xu6ATar5MyJhXWj6K
ZkU3SXl+3KM4sTDdltDVT7LUslwGvXnjAJ0MWpVLCoxEH19mvd8nIlEJVTrayutl
cpyC1GzlGUUx2DemsoZYlhwwVw8y5858hF/iwkVk/3s0KLkg5HoVBYAXwmXp943U
clc0MJtMXH0QATyBZeWf/n6YxMb+t4L2trVvyrB1cEK/ifpXp3UjWu8fb/VGVKC5
JlMQimEEaFsvEbJVUrEerJsbNs70Ly3qFiwwvhpUq/f+wf88j8uwvvLm/VhodFJF
0dEgsZ3N5KPWqX1Vzcs8CorgGf+ORQTTLtiEmJR/ptOHO0IFoX9cSkdhTgXxhNTL
fB2nVHRK
=RuP3
-----END PGP SIGNATURE-----
