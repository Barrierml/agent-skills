#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tako-video.sh create <prompt> [--model sora-2]
  tako-video.sh status <task-id>
  tako-video.sh download <task-id> [--out file.mp4]

Requires TAKO_API_KEY. Optional TAKO_BASE_URL (default https://tako.shiroha.tech).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
  usage
  exit 0
fi

if [[ -z "${TAKO_API_KEY:-}" ]]; then
  echo "TAKO_API_KEY is required" >&2
  exit 1
fi

base="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
base="${base%/}"
cmd="$1"
shift

case "$cmd" in
  create)
    prompt=""
    model="sora-2"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) model="${2:-}"; shift 2 ;;
        -*) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
        *)
          if [[ -n "$prompt" ]]; then prompt+=" $1"; else prompt="$1"; fi
          shift
          ;;
      esac
    done
    if [[ -z "$prompt" ]]; then
      echo "prompt is required" >&2
      exit 2
    fi
    body=$(python3 - "$model" "$prompt" <<'PY'
import json, sys
print(json.dumps({"model": sys.argv[1], "prompt": sys.argv[2]}, ensure_ascii=False))
PY
)
    curl -sS "$base/v1/videos" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body"
    echo
    ;;
  status)
    task_id="${1:-}"
    if [[ -z "$task_id" ]]; then
      echo "task id is required" >&2
      exit 2
    fi
    curl -sS "$base/v1/videos/${task_id}" \
      -H "Authorization: Bearer ${TAKO_API_KEY}"
    echo
    ;;
  download)
    task_id="${1:-}"
    shift || true
    out="./tako-video.mp4"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --out) out="${2:-}"; shift 2 ;;
        *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
      esac
    done
    if [[ -z "$task_id" ]]; then
      echo "task id is required" >&2
      exit 2
    fi
    curl -fsSL "$base/v1/videos/${task_id}/content" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -o "$out"
    echo "$out"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
