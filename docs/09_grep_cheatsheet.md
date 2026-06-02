# 09 - Grep cheat sheet for diagnostics

This is a quick reference for searching grid logs, resolved fcls, and Triton client/server output. It is deliberately practical: copy the command, then narrow the pattern.

## Basic recursive searches

```bash
# case-insensitive recursive search, with line numbers
grep -Rni "pattern" .

# search only log-like files
grep -Rni --include="*.log" --include="*.out" --include="*.err" "pattern" .

# search for any of several common failure words
grep -Rni "error\|exception\|failed\|cannot\|segmentation\|art::Exception" .
```

## Grid log triage

Run this after unpacking `log.tar` into a directory such as `log_unpack/`:

```bash
cd log_unpack

grep -Rni "art::Exception\|cet::exception\|TritonServerFailure\|DictionaryNotFound" .
grep -Rni "error\|exception\|failed\|triton\|cannot\|file not found" .
grep -Rni "exit status\|status [0-9]\|Art has completed" .
```

Useful files to inspect by hand:

```bash
less larStage0.err
less larStage0.out
less Stage0.fcl
```

## Triton-specific searches

```bash
# client-side signs that requests reached Triton
grep -Rni "Triton\|serverURL\|model\|Infer\|inference" .

# model loading problems on the server side
grep -Rni "failed to load\|unknown model\|no available versions\|ModuleNotFoundError" .

# successful request counters in metrics output
grep -Rni "nv_inference_request_success\|nv_inference_request_failure" .
```

## FHiCL / environment path checks

```bash
# Is my local MRB build visible?
echo "$FHICL_FILE_PATH" | tr ':' '\n' | grep icaruscode | head -n 20
echo "$CET_PLUGIN_PATH" | tr ':' '\n' | head -n 20

# Search for includes or producer labels in fcls
grep -Rni "#include\|NuGraph\|TritonConfig\|serverURL" "$MRB_SOURCE/icaruscode/icaruscode/TPC/NuGraph"
```

## Pattern tips

- `-R` means recursive.
- `-n` prints line numbers.
- `-i` ignores case.
- `--include="*.err"` restricts file types.
- `A` and `B` show context around a match:

```bash
grep -Rni -A 5 -B 5 "DictionaryNotFound" .
```

