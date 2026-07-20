#!/usr/bin/env bash
# SessionStart hook — injects the current session_id into Claude's context so
# the /tag slash command can reference it when writing a pending tag file.
# Also idempotently ensures the claude-resume-tag helper is symlinked into
# a common user bin dir (~/.local/bin) so it's available from the shell.
set -euo pipefail

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')

if [ -z "$session_id" ]; then
  exit 0
fi

# Ensure state dirs exist
mkdir -p "$HOME/.claude/session-tags/pending"
touch "$HOME/.claude/session-tags/index.jsonl"

# Symlink shell helpers into ~/.local/bin (idempotent).
# We don't touch /usr/local/bin because that usually needs sudo.
plugin_root="${CLAUDE_PLUGIN_ROOT:-}"
if [ -n "$plugin_root" ]; then
  mkdir -p "$HOME/.local/bin"
  for name in claude-resume-tag cr session-tagger-backfill; do
    src="$plugin_root/bin/$name"
    dst="$HOME/.local/bin/$name"
    if [ -e "$src" ]; then
      if [ ! -L "$dst" ] || [ "$(readlink "$dst")" != "$src" ]; then
        ln -sf "$src" "$dst"
      fi
    fi
  done
fi

# Emit additionalContext so Claude knows its own session_id inside this session.
jq -nc \
  --arg sid "$session_id" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("[session-tagger] Current Claude Code session_id = " + $sid + ". When the user runs /tag, write the tag value to ~/.claude/session-tags/pending/" + $sid + " using this exact session_id.")
    }
  }'
