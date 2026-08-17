#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tako-search.sh <query> [--provider kab|groq|grok|grok_x] [--count N]

Requires TAKO_API_KEY. Optional TAKO_BASE_URL (default https://tako.shiroha.tech).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

query=""
provider=""
count=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      provider="${2:-}"
      shift 2
      ;;
    --count)
      count="${2:-5}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "unknown flag: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$query" ]]; then
        query+=" $1"
      else
        query="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "${TAKO_API_KEY:-}" ]]; then
  echo "TAKO_API_KEY is required" >&2
  exit 1
fi

base="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
base="${base%/}"

body=$(python3 - "$query" "$provider" "$count" <<'PY'
import json, sys
query, provider, count = sys.argv[1], sys.argv[2], int(sys.argv[3] or "5")
payload = {"query": query, "count": count}
if provider:
    payload["provider"] = provider
print(json.dumps(payload, ensure_ascii=False))
PY
)

curl -sS "$base/v1/search" \
  -H "Authorization: Bearer ${TAKO_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$body"
echo
