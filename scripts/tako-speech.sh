#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tako-speech.sh asr <audio-file> [--model mimo-v2.5-asr]
  tako-speech.sh tts <text> [--model mimo-v2.5-tts] [--voice 冰糖] [--format wav] [--out file.wav]

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
  asr)
    file="${1:-}"
    shift || true
    model="mimo-v2.5-asr"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) model="${2:-}"; shift 2 ;;
        *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
      esac
    done
    if [[ -z "$file" || ! -f "$file" ]]; then
      echo "audio file is required" >&2
      exit 2
    fi
    curl -sS "$base/v1/audio/transcriptions" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -F "file=@${file}" \
      -F "model=${model}" \
      -F "response_format=json"
    echo
    ;;
  tts)
    text=""
    model="mimo-v2.5-tts"
    voice="冰糖"
    format="wav"
    out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) model="${2:-}"; shift 2 ;;
        --voice) voice="${2:-}"; shift 2 ;;
        --format) format="${2:-}"; shift 2 ;;
        --out) out="${2:-}"; shift 2 ;;
        -*) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
        *)
          if [[ -n "$text" ]]; then text+=" $1"; else text="$1"; fi
          shift
          ;;
      esac
    done
    if [[ -z "$text" ]]; then
      echo "text is required" >&2
      exit 2
    fi
    body=$(python3 - "$model" "$text" "$voice" "$format" <<'PY'
import json, sys
print(json.dumps({
    "model": sys.argv[1],
    "input": sys.argv[2],
    "voice": sys.argv[3],
    "response_format": sys.argv[4],
}, ensure_ascii=False))
PY
)
    if [[ -z "$out" ]]; then
      out="./tako-tts.${format}"
    fi
    curl -sS "$base/v1/audio/speech" \
      -H "Authorization: Bearer ${TAKO_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" \
      -o "$out"
    echo "$out"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
