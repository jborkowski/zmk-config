#!/usr/bin/env bash
# Fetch latest successful CI UF2s and flash Aurora Sweep halves.
set -euo pipefail

REPO="${ZMK_CONFIG_REPO:-jborkowski/zmk-config}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${ROOT}/firmware-artifacts"
LEFT_UF2=""
RIGHT_UF2=""

need() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
need gh

download() {
  mkdir -p "$OUT"
  rm -rf "${OUT:?}/"*
  local run
  run="$(gh run list -R "$REPO" --workflow build.yml --branch master --limit 20 \
    --json databaseId,conclusion,status \
    --jq '[.[] | select(.conclusion=="success" and .status=="completed")][0].databaseId')"
  if [[ -z "$run" || "$run" == "null" ]]; then
    echo "no successful build.yml run found" >&2
    exit 1
  fi
  echo "downloading artifacts from run $run ..."
  gh run download "$run" -R "$REPO" -D "$OUT"
  LEFT_UF2="$(/usr/bin/find "$OUT" -name 'splitkb_aurora_sweep_left-*.uf2' | head -1)"
  RIGHT_UF2="$(/usr/bin/find "$OUT" -name 'splitkb_aurora_sweep_right-*.uf2' | head -1)"
  if [[ -z "$LEFT_UF2" || -z "$RIGHT_UF2" ]]; then
    echo "UF2s not found under $OUT" >&2
    /usr/bin/find "$OUT" -name '*.uf2' >&2 || true
    exit 1
  fi
  echo "left:  $LEFT_UF2"
  echo "right: $RIGHT_UF2"
}

wait_bootloader() {
  local half="$1"
  echo
  echo ">>> Plug in ${half} half only, then double-tap RST until NICENANO mounts."
  echo "    Waiting for /Volumes/NICENANO ..."
  while [[ ! -d /Volumes/NICENANO ]]; do sleep 0.5; done
  echo "NICENANO detected."
}

flash_uf2() {
  local uf2="$1"
  local half="$2"
  wait_bootloader "$half"
  # Board reboots mid-copy; I/O error is normal.
  cp "$uf2" /Volumes/NICENANO/ 2>/dev/null || true
  local i=0
  while [[ -d /Volumes/NICENANO ]]; do
    i=$((i + 1))
    if (( i > 30 )); then
      echo "NICENANO still mounted after 30s — check cable / retry." >&2
      exit 1
    fi
    sleep 1
  done
  echo "${half} flashed."
}

usage() {
  cat <<EOF
usage: $0 [download|left|right|both]

  download  fetch latest successful CI UF2s
  left      flash left (waits for NICENANO)
  right     flash right (waits for NICENANO)
  both      download if needed, then left then right

default: both
EOF
}

cmd="${1:-both}"
case "$cmd" in
  -h|--help|help) usage; exit 0 ;;
  download)
    download
    ;;
  left)
    download
    flash_uf2 "$LEFT_UF2" left
    ;;
  right)
    download
    flash_uf2 "$RIGHT_UF2" right
    ;;
  both)
    download
    flash_uf2 "$LEFT_UF2" left
    echo
    echo "Unplug left, then continue with right."
    flash_uf2 "$RIGHT_UF2" right
    echo
    echo "done."
    ;;
  *)
    usage
    exit 1
    ;;
esac
