---
name: tako-web-media
description: Call Tako public search and image APIs. Use when the user asks to web search, look something up online, generate or edit an image through Tako, or wrap Tako POST /v1/search and /v1/images/* for an agent.
---

# Tako Web + Media

Call Tako's public HTTP APIs. Do not invent other hosts, paths, or auth schemes.

## Setup

Required environment:

```bash
export TAKO_BASE_URL="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
export TAKO_API_KEY="sk-..."   # user token, never commit
```

Never write the key into this skill, a repo, a screenshot, or a chat log.

Helpers live in `${CLAUDE_SKILL_DIR}/scripts/`:

```bash
"${CLAUDE_SKILL_DIR}/scripts/tako-search.sh" "capital of Japan"
"${CLAUDE_SKILL_DIR}/scripts/tako-image.sh" generate "a corgi on Mars"
```

## Auth

Every mutating call uses:

```text
Authorization: Bearer $TAKO_API_KEY
```

Compatible prefixes: `/v1`, `/api/v1`.

## 1. Web search

`POST $TAKO_BASE_URL/v1/search`

```json
{
  "query": "capital of Japan",
  "provider": "kab",
  "count": 5
}
```

| Field | Required | Notes |
|---|---|---|
| `query` | yes | Non-empty string |
| `provider` | no | Optional family filter: `kab`, `groq`, `grok`, `grok_x`. Omit or `auto` to let Tako pick by channel priority/weight |
| `count` | no | Default 5, max 20 |

Success `200`:

```json
{
  "query": "capital of Japan",
  "provider": "kab",
  "answer": "optional short answer",
  "results": [
    {
      "title": "Tokyo",
      "url": "https://en.wikipedia.org/wiki/Tokyo",
      "snippet": "...",
      "published_at": "optional"
    }
  ]
}
```

Rules:

- Empty `results` can still be success. Groq short questions often return only `answer`.
- `provider` is a filter, not a second router. Do not invent `kab_search` / `groq_search` model names.
- Unknown provider → `400`. Empty query → `400`.
- Prefer citing `results[].url`. If `results` is empty, quote `answer` and say sources were not returned.

```bash
curl -sS "$TAKO_BASE_URL/v1/search" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"capital of Japan","count":5}'
```

## 2. Image generation

Tako image is OpenAI-compatible and **synchronous**. This is not the PAR async `task_id` flow.

`POST $TAKO_BASE_URL/v1/images/generations`

```json
{
  "model": "gpt-image-2",
  "prompt": "a corgi drinking coffee on the moon, cyberpunk, 4k",
  "n": 1,
  "size": "1024x1024"
}
```

| Field | Required | Notes |
|---|---|---|
| `prompt` | yes | Image description |
| `model` | yes | Default to `gpt-image-2` unless the user names another Tako image model |
| `n` | no | Default 1 |
| `size` | no | Common: `1024x1024` |
| `quality` | no | Upstream-dependent |
| `response_format` | no | `url` or `b64_json` |

Success `200` looks like OpenAI:

```json
{
  "created": 1710000000,
  "data": [
    {"url": "https://...", "b64_json": null, "revised_prompt": "..."}
  ]
}
```

If `data[].url` exists, download or show that URL. If only `b64_json` exists, decode to a PNG and save it. Do not claim a shareable public URL unless Tako returned one.

```bash
curl -sS "$TAKO_BASE_URL/v1/images/generations" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-image-2","prompt":"a corgi on Mars","n":1}'
```

## 3. Image edit

`POST $TAKO_BASE_URL/v1/images/edits` as `multipart/form-data`.

```bash
curl -sS "$TAKO_BASE_URL/v1/images/edits" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -F "image=@./input.png;type=image/png" \
  -F "prompt=replace the background with a night city" \
  -F "model=gpt-image-2"
```

Response shape matches generations.

## Agent workflow

1. Confirm `$TAKO_API_KEY` is set. If missing, stop and ask the user for a Tako token.
2. Search: call `/v1/search`, then summarize with source URLs.
3. Generate image: call `/v1/images/generations` with `gpt-image-2` unless told otherwise.
4. Edit image: only if the user supplied a local file.
5. On `401/403`, say the token is invalid or has no access. On `402` / insufficient quota, say billing failed. On `429`, wait and retry once.
6. Never print the full API key.

## Do not

- Do not send keys to any host other than `$TAKO_BASE_URL`.
- Do not use chat-completions as a substitute for `/v1/search`.
- Do not poll `/v1/images/tasks/{id}` on Tako. That path is PAR, not Tako new-api.
- Do not hardcode channel IDs or brand model aliases.
