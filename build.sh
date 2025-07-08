#!/usr/bin/env bash
set -e
set -x

# --- 0. packages -------------------------------------------------------------
apt-get update
apt-get install -y build-essential python3-dev python3-venv wget

# --- 1. python venv ----------------------------------------------------------
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt

# --- 2. emsdk ---------------------------------------------------------------
if [ ! -d "emsdk" ]; then
  git clone https://github.com/emscripten-core/emsdk.git --branch 1.39.20
  ./emsdk/emsdk install 1.39.20
  ./emsdk/emsdk activate 1.39.20
fi
source ./emsdk/emsdk_env.sh >/dev/null

# --- 3. build ---------------------------------------------------------------
[ ! -f doomgeneric/doom1.wad ] && \
  wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad -O doomgeneric/doom1.wad

[ "$1" = clean ] && emmake make -C doomgeneric -f Makefile.pdfjs clean
emmake make -C doomgeneric -f Makefile.pdfjs -j"$(nproc)"

mkdir -p out
cp web/* out/
python3 embed_file.py file_template.js doomgeneric/doom1.wad out/data.js
cat pre.js out/data.js doomgeneric/doomgeneric.js > out/compiled.js
cat pre.js file_template.js doomgeneric/doomgeneric.js > out/compiled_nowad.js
python3 generate.py out/compiled.js out/doom.pdf
python3 generate.py out/compiled_nowad.js out/doom_nowad.pdf
