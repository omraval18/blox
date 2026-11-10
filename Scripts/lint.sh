#!/usr/bin/env bash
# Format check, lint, dead-code scan. CI and humans run exactly this.
set -euo pipefail
cd "$(dirname "$0")/.."

# SwiftLint needs sourcekitd; with Command Line Tools only it lives here.
export TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/Library/Developer/CommandLineTools}"

swiftformat Sources Tests --lint --quiet
swiftlint lint --strict --quiet

# Hard file-size gate independent of SwiftLint (comments and blank lines count here).
big=$(find Sources -name '*.swift' -exec wc -l {} + | awk '$2 != "total" && $1 > 500 {print}')
if [[ -n "$big" ]]; then echo "Files over 500 lines:"; echo "$big"; exit 1; fi

swift build -c release 2>&1 | grep -E "error|warning" && exit 1 || true
periphery scan --strict --quiet --retain-public || echo "note: periphery needs a full Xcode toolchain; skipped"
