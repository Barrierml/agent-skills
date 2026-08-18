This skill is for any coding agent that can read SKILL.md and run curl.

It is not an Agent Harness. Install it as its own skill, then pass a search or image prompt.

Primary install:

```bash
bunx skills add Barrierml/agent-skills -g -y
```

Claude Code can also clone into `.claude/skills/agent-skills`.

Codex does not auto-load that folder; paste the prompt from README.md / SKILL.md.
