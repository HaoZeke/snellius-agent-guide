# Snellius guidance for coding agents

This guide helps Codex, Claude Code, OpenCode and Pi use Snellius without running heavy work on shared login nodes.

## Copy and paste

Open [`snellius.md`](snellius.md) on GitHub and copy its contents into:

- Codex: `~/.codex/AGENTS.md`
- Claude Code: `~/.claude/CLAUDE.md`
- OpenCode: `~/.config/opencode/AGENTS.md`
- Pi: `~/.pi/agent/AGENTS.md`

Append it if the destination already contains personal instructions. This requires no clone or installer, but updates must be copied again manually.

## Clone and install

On Snellius, clone this repository at the expected location and run the setup:

```bash
git clone git@github.com:SURF-ML/snellius-agent-guide.git ~/.config/snellius-agent
~/.config/snellius-agent/install.sh
```

The setup adds the short rules in `instructions.md` to:

- Codex: `~/.codex/AGENTS.md`
- Claude Code: `~/.claude/CLAUDE.md`
- OpenCode: `~/.config/opencode/AGENTS.md`
- Pi: `~/.pi/agent/AGENTS.md`

It preserves existing content and creates a `.bak` copy when needed. The rules tell each agent to read `snellius.md` directly from the clone; no shell settings or jobs are changed.

Start a new agent session after installation. To update the guide later:

```bash
git -C ~/.config/snellius-agent pull
```

If this repository is already available in another fixed location, replace the path in `instructions.md` before running `install.sh`.
