-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.0
Source: git-annex
Binary: git-annex-standalone
Architecture: any
Version: 10.20250115-1~ndall+1
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
 a3b3e4ed68cc377f2c31f00bfa0dc47303bff917 9515362 git-annex_10.20250115-1~ndall+1.tar.gz
Checksums-Sha256:
 2d19009d7b778c73438ef264b313a6458f1b24a2e515e1e0d52b560652712528 9515362 git-annex_10.20250115-1~ndall+1.tar.gz
Files:
 81b202382f48dd85f33fefd75f0da43b 9515362 git-annex_10.20250115-1~ndall+1.tar.gz

-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEE6EJMpYVRYQkXgMAyY/EnTbasX8FAmeH/PkACgkQyY/EnTba
sX8BZAv9EEv/kh4lPX0YDgHV3ydZiZWedy6fVgAJKy+grYvxXnF+NS5z6nTNDhlx
2bOgQ8f1k3MojJ6O+CL9uucaGKDVKdt15PoLPSyUokztZCng5Sm43SjodNtr1cw8
Hvb0+Ef/CBSbdzOzvKzo+T1XzgTLRzLBuwxR/XxiTNw9/up+2k4pkJlysyPdZFJO
Jt9B9iKUFQRCYaAJrn8JYLLuwBCrf8MP0Zoty+7jAWZ1zeyEU9+VYSGha2/5mzXb
BF1KXaFxyrEiWhXytTU3/WkTsd8Cf3C/cDpiGLy2AZ15a/f7OkERIIkkLa8Dpvks
GWqaO2GtljWBhQpPdAIjBSGRckK0nwpw7lwT8nJLAcZTIjazzNOoLQajjMGpmuWz
sceoHhKz8M8TGgLy/6KkW2hR+tXMrZdo1d08TEeITtkIpNTUOi7O3luHORSNcwyF
DetFndF/0Eyt7Il/39g+IyVcZBzR8A3QqIZ12Xd5gZSvXODw5o+PzJFjbnOxpWDl
BiYYyfEY
=NHkf
-----END PGP SIGNATURE-----
