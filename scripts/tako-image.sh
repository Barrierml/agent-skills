#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tako-image.sh generate <prompt> [--model gpt-image-2] [--n 1] [--size 1024x1024] [--out file.json]
  tako-image.sh edit <image-path> <prompt> [--model gpt-image-2] [--out file.json]

Requires TAKO_API_KEY. Optional TAKO_BASE_URL (default https://tako.shiroha.tech).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
  usage
  exit 0
fi

cmd="$1"
shift

if [[ -z "${TAKO_API_KEY:-}" ]]; then
  echo "TAKO_API_KEY is required" >&2
  exit 1
fi

base="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
base="${base%/}"
model="gpt-image-2"
n=1
size=""
out=""

case "$cmd" in
  generate)
    prompt=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) model="${2:-}"; shift 2 ;;
        --n) n="${2:-1}"; shift 2 ;;
        --size) size="${2:-}"; shift 2 ;;
        --out) out="${2:-}"; shift 2 ;;
        -*)
          echo "unknown flag: $1" >&2
          usage >&2
          exit 2
          ;;
        *)
          if [[ -n "$prompt" ]]; then
            prompt+=" $1"
          else
            prompt="$1"
          fi
          shift
          ;;
      esac
    done
    if [[ -z "$prompt" ]]; then
      echo "prompt is required" >&2
      exit 2
    fi
    body=$(python3 - "$model" "$prompt" "$n" "$size" <<'PY'
import json, sys
model, prompt, n, size = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
payload = {"model": model, "prompt": prompt, "n": n}
if size:
    payload["size"] = size
print(json.dumps(payload, ensure_ascii=False))
PY
)
    resp=$(curl -sS "$base/v1/images/generations" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body")
    ;;
  edit)
    image_path="${1:-}"
    shift || true
    if [[ -z "$image_path" || ! -f "$image_path" ]]; then
      echo "image file is required" >&2
      exit 2
    fi
    prompt=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) model="${2:-}"; shift 2 ;;
        --out) out="${2:-}"; shift 2 ;;
        -*)
          echo "unknown flag: $1" >&2
          usage >&2
          exit 2
          ;;
        *)
          if [[ -n "$prompt" ]]; then
            prompt+=" $1"
          else
            prompt="$1"
          fi
          shift
          ;;
      esac
    done
    if [[ -z "$prompt" ]]; then
      echo "prompt is required" >&2
      exit 2
    fi
    resp=$(curl -sS "$base/v1/images/edits" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -F "image=@${image_path};type=image/png" \
      -F "prompt=${prompt}" \
      -F "model=${model}")
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ -n "$out" ]]; then
  printf '%s\n' "$resp" > "$out"
fi
printf '%s\n' "$resp"
