#!/usr/bin/env bash
# Runs tests. With Command Line Tools only (no Xcode.app), Swift Testing needs extra library paths.
set -euo pipefail
cd "$(dirname "$0")/.."
D=/Library/Developer/CommandLineTools/Library/Developer
if [[ "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" ]]; then
    exec swift test \
        -Xswiftc -F -Xswiftc "$D/Frameworks" \
        -Xlinker -F -Xlinker "$D/Frameworks" \
        -Xlinker -rpath -Xlinker "$D/Frameworks" \
        -Xlinker -rpath -Xlinker "$D/usr/lib" "$@"
fi
exec swift test "$@"
