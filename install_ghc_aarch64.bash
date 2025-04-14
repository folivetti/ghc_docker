#!/bin/bash
set -ex

# Install GHC 9.6.4
mkdir -p /tmpghc
python3 -c "import wget; wget.download('https://downloads.haskell.org/~ghc/9.6.4/ghc-9.6.4-aarch64-deb10-linux.tar.xz', '/tmpghc/ghc-9.6.4.tar.xz')"
python3 -c "import shutil; shutil.unpack_archive('/tmpghc/ghc-9.6.4.tar.xz', '/tmpghc')"
(mv "/tmpghc/ghc-9.6.4-aarch64-unknown-linux" "/tmpghc/ghc-9.6.4")
(cd "/tmpghc/ghc-9.6.4" && ./configure --prefix="/tmpghc/ghc-toolset-9.6.4/root/usr")
(cd "/tmpghc/ghc-9.6.4" && make install)
rm -rf "/tmpghc/ghc-9.6.4" "/tmpghc/ghc-9.6.4.tar.xz"

# Bootstrap Cabal 3.14.2.0
python3 -c "import wget; wget.download('https://github.com/haskell/cabal/archive/refs/tags/cabal-install-v3.14.2.0.zip', '/tmpghc/cabal.zip')"
python3 -c "import shutil; shutil.unpack_archive('/tmpghc/cabal.zip', '/tmpghc')"
mv "/tmpghc/cabal-cabal-install-v3.14.2.0" "/tmpghc/cabal"
sed -ie "s/+ofd-locking/-ofd-locking/" "/tmpghc/cabal/bootstrap/linux-9.6.4.json"
/tmpghc/ghc-toolset-9.6.4/root/usr/bin/ghc-pkg-9.6.4 recache
(cd "/tmpghc/cabal" && ./_build/bin/cabal build --with-compiler="/tmpghc/ghc-toolset-9.6.4/root/usr/bin/ghc-9.6.4" --dry-run cabal-install:exe:cabal)
(cd "/tmpghc/cabal" && cp dist-newstyle/cache/plan.json bootstrap/aarch64-9.6.4.plan.json)
(cd "/tmpghc/cabal/bootstrap" && cabal run -v0 cabal-bootstrap-gen -- aarch64-9.6.4.plan.json | tee aarch64-9.6.4.json)
# (cd "/tmpghc/cabal" && python3 "./bootstrap/bootstrap.py" -d "./bootstrap/linux-9.6.4.json" -w "/tmpghc/ghc-toolset-9.6.4/root/usr/bin/ghc-9.6.4")
PATH="/tmpghc/ghc-toolset-9.6.4/root/usr/bin:${PATH}" "/tmpghc/cabal/_build/bin/cabal" v2-update
PATH="/tmpghc/ghc-toolset-9.6.4/root/usr/bin:${PATH}" "/tmpghc/cabal/_build/bin/cabal" v2-install cabal-install --constraint="lukko -ofd-locking" --overwrite-policy=always --install-method=copy --installdir="/tmpghc/ghc-toolset-9.6.4/root/usr/bin"

# Bootstrap GHC 9.12.1
python3 -c "import wget; wget.download('https://downloads.haskell.org/~ghc/9.12.1/ghc-9.12.1-src.tar.xz', '/tmpghc/ghc-9.12.1-src.tar.xz')"
python3 -c "import shutil; shutil.unpack_archive('/tmpghc/ghc-9.12.1-src.tar.xz', '/tmpghc')"

#(cd "/tmpghc" && patch -p0 < "/tmpghc/ghc-9.12.1-patches/fpic-default.patch")
#rm -rf "/tmpghc/ghc-9.12.1-patches"

(cd "/tmpghc/ghc-9.12.1" && PATH="/tmpghc/ghc-toolset-9.6.4/root/usr/bin:${PATH}" ./configure GHC="/tmpghc/ghc-toolset-9.6.4/root/usr/bin/ghc-9.6.4")
(cd "/tmpghc/ghc-9.12.1" && PATH="/tmpghc/ghc-toolset-9.6.4/root/usr/bin:${PATH}" hadrian/build install --docs=none -j --prefix="/usr/local")
rm -rf "/tmpghc/ghc-toolset-9.6.4" "/tmpghc/ghc-9.12.1" "/tmpghc/ghc-9.12.1-src.tar.xz" "/tmpghc/ghc-9.12.1-patches"

# Unlink python3.12 from python3
unlink "/usr/local/bin/python3"

# Install Cabal 3.10.3.0
"/tmpghc/cabal/_build/bin/cabal" v2-install cabal-install --constraint="lukko -ofd-locking" --overwrite-policy=always --install-method=copy --installdir="/usr/local/bin"
rm -rf "/tmpghc/cabal" "/tmpghc/cabal.zip"
