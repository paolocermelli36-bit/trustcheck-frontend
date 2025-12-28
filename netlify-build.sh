#!/usr/bin/env bash
set -euo pipefail

echo "== Installing Flutter (stable) =="
if [ ! -d ".flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git .flutter
fi

export PATH="$PWD/.flutter/bin:$PATH"

flutter --version
flutter config --enable-web

echo "== Pub get =="
flutter pub get

echo "== Build web (release) =="
flutter build web --release