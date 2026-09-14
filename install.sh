#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
snippet="$repo_dir/instructions.md"
start='<!-- BEGIN SNELLIUS GUIDANCE -->'

add_instructions() {
    target=$1
    mkdir -p "$(dirname -- "$target")"

    if [ -f "$target" ] && grep -Fq "$start" "$target"; then
        echo "Already configured: $target"
        return
    fi

    if [ -s "$target" ]; then
        cp -p "$target" "$target.bak"
        printf '\n' >> "$target"
    fi

    {
        printf '%s\n' "$start"
        cat "$snippet"
        printf '%s\n' '<!-- END SNELLIUS GUIDANCE -->'
    } >> "$target"
    echo "Configured: $target"
}

codex_dir=${CODEX_HOME:-"$HOME/.codex"}
add_instructions "$codex_dir/AGENTS.md"
add_instructions "$HOME/.claude/CLAUDE.md"
add_instructions "$HOME/.config/opencode/AGENTS.md"
add_instructions "$HOME/.pi/agent/AGENTS.md"

if [ -s "$codex_dir/AGENTS.override.md" ]; then
    echo "Warning: $codex_dir/AGENTS.override.md may override AGENTS.md."
fi

echo 'Start a new Codex, Claude Code, OpenCode or Pi session.'
