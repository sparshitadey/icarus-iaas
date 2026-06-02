#!/usr/bin/env bash
# check_env.sh -- confirm you're in YOUR local MRB build, not global cvmfs lar.
# Run this whenever you hit a "file not found" / Error 90 (see docs/07).

echo "MRB_TOP            = ${MRB_TOP:-<EMPTY -- you are NOT in a local build!>}"
echo "which lar          = $(which lar 2>/dev/null)"
echo "SETUP_ICARUSCODE   = ${SETUP_ICARUSCODE:-<unset>}"
echo
echo "FHICL_FILE_PATH entries mentioning icaruscode:"
echo "${FHICL_FILE_PATH:-}" | tr ':' '\n' | grep icaruscode | head -n 10 \
  || echo "  <none -- only cvmfs on path; your local fcls won't be found>"
echo
echo "CET_PLUGIN_PATH (first entries -- want a local build dir, not only cvmfs):"
echo "${CET_PLUGIN_PATH:-}" | tr ':' '\n' | head -n 5

# Heuristic verdict
if [ -z "${MRB_TOP:-}" ]; then
  echo
  echo ">> MRB_TOP is empty: re-enter your dev area and run:"
  echo "   source localProducts*/setup && mrbsetenv && mrb i -j4 && mrbslp"
fi
