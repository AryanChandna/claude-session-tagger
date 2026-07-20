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

# Symlink the shell helper into ~/.local/bin (idempotent).
# We don't touch /usr/local/bin because that usually needs sudo.
plugin_root="${CLAUDE_PLUGIN_ROOT:-}"
helper_src="$plugin_root/bin/claude-resume-tag"
helper_dst="$HOME/.local/bin/claude-resume-tag"
if [ -n "$plugin_root" ] && [ -x "$helper_src" ]; then
  mkdir -p "$HOME/.local/bin"
  if [ ! -L "$helper_dst" ] || [ "$(readlink "$helper_dst")" != "$helper_src" ]; then
    ln -sf "$helper_src" "$helper_dst"
  fi
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
