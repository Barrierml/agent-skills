---
name: agent-skills
description: Multimodal Tako agent for web search, images, speech, and video. Use when the user asks to search the web, generate or edit images, transcribe audio, synthesize speech, or create/poll videos through Tako.
---

# Agent Skills

Call Tako as a multimodal agent. One public host, one user token, four media families.

Do not invent other hosts, paths, or auth schemes. Do not write the API key into this skill, a repo, a screenshot, or a chat log.

## Setup

```bash
export TAKO_BASE_URL="${TAKO_BASE_URL:-https://tako.shiroha.tech}"
export TAKO_API_KEY="sk-..."   # user token only
```

Auth on every call:

```text
Authorization: Bearer $TAKO_API_KEY
```

Compatible prefixes: `/v1`, `/api/v1`.

Helpers in `${CLAUDE_SKILL_DIR}/scripts/`:

```bash
"${CLAUDE_SKILL_DIR}/scripts/tako-search.sh" "capital of Japan"
"${CLAUDE_SKILL_DIR}/scripts/tako-image.sh" generate "a corgi on Mars"
"${CLAUDE_SKILL_DIR}/scripts/tako-speech.sh" tts "你好，这是语音合成测试"
"${CLAUDE_SKILL_DIR}/scripts/tako-speech.sh" asr ./clip.wav
"${CLAUDE_SKILL_DIR}/scripts/tako-video.sh" create "a cat playing piano"
```

## Capability map

| Ability | Status on Tako today | Agent call |
|---|---|---|
| `web_search` | live | `POST /v1/search` |
| image | live | `POST /v1/images/generations`, `POST /v1/images/edits` |
| speech / ASR / TTS | chat/audio models exist; dedicated speech ability not landed | `POST /v1/audio/transcriptions`, `POST /v1/audio/speech` |
| video | live OpenAI video path | `POST /v1/videos`, then poll `GET /v1/videos/{id}` |

Future Tako work (not this skill): add Xiaomi MiMo ASR/TTS as a first-class speech ability, same inventory model as `web_search`. Until that ships, use the OpenAI-compatible audio routes below.

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
| `provider` | no | Family filter only: `kab`, `groq`, `grok`, `grok_x`. Omit/`auto` uses channel priority/weight |
| `count` | no | Default 5, max 20 |

`200`:

```json
{
  "query": "capital of Japan",
  "provider": "kab",
  "answer": "optional short answer",
  "results": [
    {"title": "Tokyo", "url": "https://en.wikipedia.org/wiki/Tokyo", "snippet": "..."}
  ]
}
```

Rules:

- Empty `results` can still be success. Groq short questions often return only `answer`.
- Do not invent brand model names like `kab_search`.
- Prefer citing `results[].url`.

## 2. Images

Synchronous OpenAI-compatible image API. Do **not** poll `/v1/images/tasks/{id}` — that is PAR, not Tako.

Generate:

```bash
curl -sS "$TAKO_BASE_URL/v1/images/generations" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-image-2","prompt":"a corgi on Mars","n":1}'
```

Edit:

```bash
curl -sS "$TAKO_BASE_URL/v1/images/edits" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -F "image=@./input.png;type=image/png" \
  -F "prompt=replace the background with a night city" \
  -F "model=gpt-image-2"
```

Default model: `gpt-image-2`. If Tako returns `data[].url`, show that URL. If only `b64_json` exists, decode to a file.

## 3. Speech

Use these until Tako grows a dedicated `speech` ability.

### ASR — recognize speech

`POST $TAKO_BASE_URL/v1/audio/transcriptions` as multipart.

```bash
curl -sS "$TAKO_BASE_URL/v1/audio/transcriptions" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -F "file=@./clip.wav" \
  -F "model=mimo-v2.5-asr" \
  -F "response_format=json"
```

Default model: `mimo-v2.5-asr`. Expected `{"text":"..."}`.

Current production fact: Xiaomi channel `23` already publishes `mimo-v2.5-asr`. Official Xiaomi docs also accept chat-style `input_audio`. Prefer the OpenAI transcriptions path first; if it fails with model/path errors, fall back to:

```bash
# fallback only
python3 - <<'PY'
# send wav as chat input_audio to /v1/chat/completions with model=mimo-v2.5-asr
PY
```

Keep files small. Xiaomi's documented limit is about 10MB after base64.

### TTS — create speech

`POST $TAKO_BASE_URL/v1/audio/speech`

```json
{
  "model": "mimo-v2.5-tts",
  "input": "你好，这是语音合成测试。",
  "voice": "冰糖",
  "response_format": "wav"
}
```

```bash
curl -sS "$TAKO_BASE_URL/v1/audio/speech" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"mimo-v2.5-tts","input":"你好","voice":"冰糖","response_format":"wav"}' \
  -o ./out.wav
```

Default model: `mimo-v2.5-tts`. Common Xiaomi voices: `冰糖`, `茉莉`, `苏打`, `白桦`, `Mia`, `mimo_default`.

Save the raw audio bytes. Do not pretty-print binary as JSON.

## 4. Video

OpenAI-compatible async video. This is **not** `/v1/search`.

Create:

```bash
curl -sS "$TAKO_BASE_URL/v1/videos" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"sora-2","prompt":"a calico cat playing piano on stage"}'
```

Poll:

```bash
curl -sS "$TAKO_BASE_URL/v1/videos/$TASK_ID" \
  -H "Authorization: Bearer $TAKO_API_KEY"
```

Download when ready:

```bash
curl -L "$TAKO_BASE_URL/v1/videos/$TASK_ID/content" \
  -H "Authorization: Bearer $TAKO_API_KEY" \
  -o ./out.mp4
```

Use a model the user names. Do not assume every Tako token can call every video model.

## Agent workflow

1. Confirm `$TAKO_API_KEY`. If missing, stop and ask.
2. Pick the smallest family that answers the request. Do not call image/video for a search question.
3. Search → summarize with source URLs.
4. Image → generate or edit, then show the file/URL.
5. Speech → ASR file in, or TTS text out.
6. Video → create, poll until succeeded/failed, then fetch content.
7. `401/403`: token invalid or no access. `402`: billing. `429`: wait and retry once.
8. Never print the full API key.

## Do not

- Do not send keys to any host other than `$TAKO_BASE_URL`.
- Do not use chat-completions as a substitute for `/v1/search`.
- Do not poll image task URLs on Tako.
- Do not hardcode channel IDs.
- Do not claim Xiaomi speech is a first-class Tako ability until New API lands `speech` the same way as `web_search`.
