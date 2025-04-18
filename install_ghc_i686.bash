#!/bin/bash
set -ex

# Install GHC 9.6.4
python3 -c "import wget; wget.download('https://downloads.haskell.org/~ghc/9.6.4/ghc-9.6.4-i386-deb9-linux.tar.xz', '/tmp/ghc-9.6.4.tar.xz')"
python3 -c "import shutil; shutil.unpack_archive('/tmp/ghc-9.6.4.tar.xz', '/tmp')"
(mv "/tmp/ghc-9.6.4-i386-unknown-linux" "/tmp/ghc-9.6.4")
(cd "/tmp/ghc-9.6.4" && ./configure --prefix="/tmp/ghc-toolset-9.6.4/root/usr")
(cd "/tmp/ghc-9.6.4" && make install)
rm -rf "/tmp/ghc-9.6.4" "/tmp/ghc-9.6.4.tar.xz"

# Bootstrap Cabal 3.14.2.0
python3 -c "import wget; wget.download('https://github.com/haskell/cabal/archive/refs/tags/cabal-install-v3.14.2.0.zip', '/tmp/cabal.zip')"
python3 -c "import shutil; shutil.unpack_archive('/tmp/cabal.zip', '/tmp')"
mv "/tmp/cabal-cabal-install-v3.14.2.0" "/tmp/cabal"
sed -ie "s/+ofd-locking/-ofd-locking/" "/tmp/cabal/bootstrap/linux-9.6.4.json"
(cd "/tmp/cabal" && python3 "./bootstrap/bootstrap.py" -d "./bootstrap/linux-9.6.4.json" -w "/tmp/ghc-toolset-9.6.4/root/usr/bin/ghc-9.6.4")
PATH="/tmp/ghc-toolset-9.6.4/root/usr/bin:${PATH}" "/tmp/cabal/_build/bin/cabal" v2-update
PATH="/tmp/ghc-toolset-9.6.4/root/usr/bin:${PATH}" "/tmp/cabal/_build/bin/cabal" v2-install cabal-install --constraint="lukko -ofd-locking" --overwrite-policy=always --install-method=copy --installdir="/tmp/ghc-toolset-9.6.4/root/usr/bin"

# Bootstrap GHC 9.12.1
python3 -c "import wget; wget.download('https://downloads.haskell.org/~ghc/9.12.1/ghc-9.12.1-src.tar.xz', '/tmp/ghc-9.12.1-src.tar.xz')"
python3 -c "import shutil; shutil.unpack_archive('/tmp/ghc-9.12.1-src.tar.xz', '/tmp')"

#(cd "/tmp" && patch -p0 < "/tmp/ghc-9.12.1-patches/fpic-default.patch")
#rm -rf "/tmp/ghc-9.12.1-patches"

(cd "/tmp/ghc-9.12.1" && PATH="/tmp/ghc-toolset-9.6.4/root/usr/bin:${PATH}" ./configure GHC="/tmp/ghc-toolset-9.6.4/root/usr/bin/ghc-9.6.4")
(cd "/tmp/ghc-9.12.1" && PATH="/tmp/ghc-toolset-9.6.4/root/usr/bin:${PATH}" hadrian/build install --docs=none -j --prefix="/usr/local")
rm -rf "/tmp/ghc-toolset-9.6.4" "/tmp/ghc-9.12.1" "/tmp/ghc-9.12.1-src.tar.xz" "/tmp/ghc-9.12.1-patches"

# Unlink python3.12 from python3
unlink "/usr/local/bin/python3"

# Install Cabal 3.10.3.0
"/tmp/cabal/_build/bin/cabal" v2-install cabal-install --constraint="lukko -ofd-locking" --overwrite-policy=always --install-method=copy --installdir="/usr/local/bin"
rm -rf "/tmp/cabal" "/tmp/cabal.zip"
