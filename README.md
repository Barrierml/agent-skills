# Agent Skills

Public multimodal agent skill for Tako.

This repository is only the skill definition and curl helpers. It does **not** include API keys, channel IDs, or production credentials.

## What it wraps

| Family | Method | Path |
|---|---|---|
| Web search | `POST` | `/v1/search` |
| Image generate | `POST` | `/v1/images/generations` |
| Image edit | `POST` | `/v1/images/edits` |
| Speech ASR | `POST` | `/v1/audio/transcriptions` |
| Speech TTS | `POST` | `/v1/audio/speech` |
| Video create | `POST` | `/v1/videos` |
| Video poll | `GET` | `/v1/videos/{id}` |
| Video download | `GET` | `/v1/videos/{id}/content` |

Default host: `https://tako.shiroha.tech`

Auth: `Authorization: Bearer $TAKO_API_KEY`

## Install

```bash
bunx skills add Barrierml/agent-skills -g -y
```

Or clone into a project:

```bash
git clone https://github.com/Barrierml/agent-skills.git \
  .claude/skills/agent-skills
```

Then set a user token:

```bash
export TAKO_API_KEY="sk-..."
export TAKO_BASE_URL="https://tako.shiroha.tech"
```

## Helpers

```bash
./scripts/tako-search.sh "capital of Japan"
./scripts/tako-image.sh generate "a corgi on Mars"
./scripts/tako-speech.sh tts "你好"
./scripts/tako-speech.sh asr ./clip.wav
./scripts/tako-video.sh create "a cat playing piano"
```

See [`SKILL.md`](./SKILL.md) for the contract agents should follow.

## Security

- Put the key in the environment only.
- Do not commit `.env`, tokens, or binary dumps that contain secrets.
- Do not send the key to any host other than `TAKO_BASE_URL`.
