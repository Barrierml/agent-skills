---
name: agent-skills
description: Tako skill for billed web search and OpenAI-compatible image generate/edit. Use when the user asks to search the web or generate/edit images through Tako.
---

# Agent Skills

Call Tako for web search and images. One public host, one user token.

Do not invent other hosts, paths, or auth schemes. Do not write the API key into this skill, a repo, a screenshot, or a chat log.

## Setup

```bash
export TAKO_BASE_URL="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
export TAKO_API_KEY="cr_..."   # user token from the Tako console
```

Auth on every call:

```text
Authorization: Bearer $TAKO_API_KEY
```

Compatible prefixes: `/v1`, `/api/v1`.

Helpers in this skill's `scripts/` directory:

```bash
./scripts/tako-search.sh "capital of Japan"
./scripts/tako-image.sh generate "a tiny red apple on a white table"
```

## Verified today

| Capability | Path | Production check |
|---|---|---|
| Web search | `POST /v1/search` | HTTP 200. Default/kab returns sources; `provider=groq` may return only `answer` |
| Image generate | `POST /v1/images/generations` | HTTP 200, `gpt-image-2`, `b64_json` |
| Image edit | `POST /v1/images/edits` | HTTP 200, multipart `image` + `prompt` |

Not in this skill until a live request succeeds:

- Speech ASR / TTS (`/v1/audio/*`) — Xiaomi path is not e2e-green
- Video (`/v1/videos`) — no available channel for `sora-2`

Do not invent brand ability names like `kab_search`.

## 1. Web search

`POST $TAKO_BASE_URL/v1/search`

```json
{
  "query": "capital of Japan",
  "count": 3
}
```

| Field | Required | Notes |
|---|---|---|
| `query` | yes | Non-empty string |
| `provider` | no | Family filter only: `kab`, `groq`, `grok`, `grok_x`. Omit uses channel priority/weight |
| `count` | no | Default 5, max 20 |

`200` example (kab):

```json
{
  "query": "capital of Japan",
  "provider": "kab",
  "answer": "Search results for: capital of Japan\n\n1. Capital of Japan\nhttps://en.wikipedia.org/wiki/Capital_of_Japan\n...",
  "results": [
    {"title": "Capital of Japan", "url": "https://en.wikipedia.org/wiki/Capital_of_Japan", "snippet": "..."}
  ]
}
```

Rules:

- Empty `results` can still be success. Groq short questions often return only `answer`.
- Prefer citing `results[].url` when present.

## 2. Images

Synchronous OpenAI-compatible image API. Do **not** poll `/v1/images/tasks/{id}` — that is PAR, not Tako.

Generate:

```bash
curl -sS "$TAKO_BASE_URL/v1/images/generations" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-image-2","prompt":"a tiny red apple on a white table, simple photo","n":1}'
```

Edit:

```bash
curl -sS "$TAKO_BASE_URL/v1/images/edits" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -F "image=@./input.png;type=image/png" \
  -F "prompt=make the apple green" \
  -F "model=gpt-image-2"
```

Default model: `gpt-image-2`. If Tako returns `data[].url`, show that URL. If only `b64_json` exists, decode to a file.

## Claude Code

Install once, then put the key in the environment of the Claude Code process:

```bash
bunx skills add Barrierml/agent-skills -g -y
export TAKO_API_KEY="cr_your_key"
export TAKO_BASE_URL="https://tako.shiroha.tech"
```

Or clone into the project Claude reads:

```bash
git clone https://github.com/Barrierml/agent-skills.git \
  .claude/skills/agent-skills
```

Prompt the model with a concrete task, not a generic “use tools”:

```text
Use the agent-skills skill.
Search Tako for "capital of Japan" and cite the source URLs.
Then generate a simple photo of a tiny red apple on a white table with gpt-image-2.
Do not call /v1/audio/* or /v1/videos. Do not print TAKO_API_KEY.
```

Claude Code should read `SKILL.md` and run the curl/helpers itself.

## Codex

Codex does not auto-load Claude skill folders. Give it the contract plus a prompt:

```bash
export TAKO_API_KEY="cr_your_key"
export TAKO_BASE_URL="https://tako.shiroha.tech"
```

```text
Follow https://github.com/Barrierml/agent-skills/blob/main/SKILL.md
or the local clone of that repo.

Search POST $TAKO_BASE_URL/v1/search with query "capital of Japan".
If you need an image, POST /v1/images/generations with model gpt-image-2.

Do not call speech or video endpoints.
Keep the API key in the Authorization header only.
```

If you already use `tako` to launch Codex, still export `TAKO_API_KEY` in that same shell. The Tako chat key and this skill key are the same user token.

## Workflow

1. Confirm `$TAKO_API_KEY`. If missing, stop and ask.
2. Search for facts. Image only when the user asked for a picture.
3. Prefer helper scripts when they exist; otherwise curl the paths above.
4. `401/403`: token invalid or no access. `402`: billing. `429`: wait and retry once.
5. Never print the full API key.

## Do not

- Do not send keys to any host other than `$TAKO_BASE_URL`.
- Do not use chat-completions as a substitute for `/v1/search`.
- Do not poll image task URLs on Tako.
- Do not hardcode channel IDs.
- Do not document or call speech/video from this skill until those paths return 200 on a real token.
