# Tako Web + Media Skill

Agent skill for Tako's public **web search** and **image** APIs.

This repository contains only the skill definition and helpers. It does **not** include API keys, channel IDs, or production credentials.

## What it wraps

| Action | Method | Path |
|---|---|---|
| Web search | `POST` | `/v1/search` |
| Generate image | `POST` | `/v1/images/generations` |
| Edit image | `POST` | `/v1/images/edits` |

Default host: `https://tako.shiroha.tech`

Auth: `Authorization: Bearer $TAKO_API_KEY`

## Install

### Claude Code / Codex project skill

```bash
git clone https://github.com/Barrierml/tako-web-media-skill.git \
  .claude/skills/tako-web-media
```

Or as a submodule:

```bash
git submodule add https://github.com/Barrierml/tako-web-media-skill.git \
  .claude/skills/tako-web-media
```

### Skills CLI

```bash
bunx skills add Barrierml/tako-web-media-skill -g -y
```

Then set a user token:

```bash
export TAKO_API_KEY="sk-..."
export TAKO_BASE_URL="https://tako.shiroha.tech"
```

## Manual helpers

```bash
./scripts/tako-search.sh "capital of Japan"
./scripts/tako-search.sh "capital of Japan" --provider kab --count 3
./scripts/tako-image.sh generate "a corgi on Mars"
```

See [`SKILL.md`](./SKILL.md) for the request/response contract agents should follow.

## Security

- Put the key in the environment only.
- Do not commit `.env`, tokens, or response dumps that contain secrets.
- Do not send the key to any host other than `TAKO_BASE_URL`.
