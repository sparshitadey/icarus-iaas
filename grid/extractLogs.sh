#!/bin/bash
#
# extractLogs.sh -- pull and unpack log.tar from a list of (usually failed) grid jobs
# into a local bad_logs/ dir, so you can grep them for failure modes.
#
# ──────────────────────────────────────────────────────────────────────────
# PATHS ARE PARAMETERISED so you don't read/write anyone else's area.
# Set BASE to YOUR job output directory (the <outdir> from your grid XML),
# either by exporting it or editing the default below.
#
#   export BASE=/pnfs/icarus/scratch/users/$USER/v10_06_00_01p01/ng2_eaf_v1
#   ./extractLogs.sh
#
# It expects a file  $BASE/bad.list  containing one job subdir name per line
# (the jobs whose logs you want). Build that from the dashboard or a --check.
#
# WHERE TO RUN: from any working dir you can write to (it creates ./bad_logs,
# ./tmp_extract and a couple of summary txt files in $PWD). Run it on a GPVM
# after the jobs have finished. Original campaign value was:
#   /pnfs/icarus/scratch/users/sdey2/v10_06_00_01p01/ng2_eaf_v1
# ──────────────────────────────────────────────────────────────────────────

set -euo pipefail

# TODO: point this at YOUR job output area (no trailing slash).
BASE="${BASE:-/pnfs/icarus/scratch/users/${USER:-CHANGEME_username}/CHANGEME_release/CHANGEME_campaign}"

BADLIST="$BASE/bad.list"
OUTDIR="$PWD/bad_logs"
TMPDIR="$PWD/tmp_extract"

if [[ "$BASE" == *CHANGEME* ]]; then
  echo "ERROR: set BASE to your own job output dir first (see header). Refusing to run with CHANGEME paths." >&2
  exit 2
fi

mkdir -p "$OUTDIR"
mkdir -p "$TMPDIR"

# optional bookkeeping
: > "$PWD/missing_logs.txt"
: > "$PWD/extract_failures.txt"

while read -r job; do
    [[ -z "$job" ]] && continue

    LOGTAR="$BASE/$job/log.tar"
    JOBOUT="$OUTDIR/$job"

    echo "Processing $job"

    rm -rf "$TMPDIR"/*
    mkdir -p "$JOBOUT"

    if [[ ! -f "$LOGTAR" ]]; then
        echo "$job : missing $LOGTAR" >> "$PWD/missing_logs.txt"
        continue
    fi

    if ! tar -xf "$LOGTAR" -C "$TMPDIR"; then
        echo "$job : failed to extract $LOGTAR" >> "$PWD/extract_failures.txt"
        continue
    fi

    shopt -s nullglob
    for f in "$TMPDIR"/*; do
        mv "$f" "$JOBOUT/${job}_$(basename "$f")"
    done
    shopt -u nullglob

done < "$BADLIST"

rm -rf "$TMPDIR"

echo "Done."
echo "Extracted logs are in: $OUTDIR"
echo "Missing log summary: $PWD/missing_logs.txt"
echo "Extraction failures: $PWD/extract_failures.txt"
