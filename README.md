# Agent Skills

Public Tako skill for web search and images.

This repository is only the skill definition and curl helpers. It does **not** include API keys, channel IDs, or production credentials.

## What works today

| Family | Method | Path | Last live check |
|---|---|---|---|
| Web search | `POST` | `/v1/search` | 200; kab returns sources, groq may return only `answer` |
| Image generate | `POST` | `/v1/images/generations` | 200 with `gpt-image-2` |
| Image edit | `POST` | `/v1/images/edits` | 200 with `gpt-image-2` |

Speech and video are **not** part of this skill. Those public paths exist on Tako, but current production e2e is not green (`/v1/audio/*` Xiaomi 400/404, `/v1/videos` no `sora-2` channel).

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
export TAKO_API_KEY="cr_..."
export TAKO_BASE_URL="https://tako.shiroha.tech"
```

## Claude Code prompt

```text
Use the agent-skills skill.
Search Tako for "capital of Japan" and cite the source URLs.
Then generate a simple photo of a tiny red apple on a white table with gpt-image-2.
Do not call /v1/audio/* or /v1/videos. Do not print TAKO_API_KEY.
```

## Codex prompt

```text
Follow https://github.com/Barrierml/agent-skills/blob/main/SKILL.md
Search POST $TAKO_BASE_URL/v1/search with query "capital of Japan".
If you need an image, POST /v1/images/generations with model gpt-image-2.
Do not call speech or video endpoints. Keep the API key in the Authorization header only.
```

## Helpers

```bash
./scripts/tako-search.sh "capital of Japan"
./scripts/tako-image.sh generate "a tiny red apple on a white table"
```

See [`SKILL.md`](./SKILL.md) for the contract agents should follow.

## Security

- Put the key in the environment only.
- Do not commit `.env`, tokens, or binary dumps that contain secrets.
- Do not send the key to any host other than `TAKO_BASE_URL`.
