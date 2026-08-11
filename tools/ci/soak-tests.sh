#!/usr/bin/env bash
#
# Soak-test harness: runs the parallel PHPUnit suite N times in a row,
# wiping the compiled-view caches between each run, to empirically catch
# rare test-isolation races (e.g. workers colliding on shared Blade
# compiled-view directories) that a single run wouldn't reveal.
#
# Usage: tools/ci/soak-tests.sh [ITERATIONS]
#   ITERATIONS  Number of times to run the suite (default: 40).
#
# Must be run from the repository root. Aborts on the FIRST failing
# iteration with a non-zero exit code -- that first failure is the
# reproduction and later iterations are not worth running past it.

set -euo pipefail

TOTAL="${1:-40}"

VIEW_DIRS=(
  "storage/framework/views"
  "storage/framework/testing/views"
)

clean_view_dirs() {
  for dir in "${VIEW_DIRS[@]}"; do
    if [ -d "$dir" ]; then
      find "$dir" -mindepth 1 ! -name '.gitignore' -delete
    fi
  done
}

for ((i = 1; i <= TOTAL; i++)); do
  echo "Iteration $i/$TOTAL"

  clean_view_dirs

  if ! php artisan test --parallel --processes=8; then
    echo "FAILED on iteration $i"
    exit 1
  fi
done

echo "Soak test complete: $TOTAL/$TOTAL iterations passed"
