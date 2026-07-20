#!/usr/bin/env bash
# SessionStart hook — injects the current session_id into Claude's context so
# the /tag slash command can reference it when writing a pending tag file.
set -euo pipefail

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')

if [ -z "$session_id" ]; then
  exit 0
fi

# Ensure state dirs exist
mkdir -p "$HOME/.claude/session-tags/pending"
touch "$HOME/.claude/session-tags/index.jsonl"

# Emit additionalContext so Claude knows its own session_id inside this session.
jq -nc \
  --arg sid "$session_id" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("[session-tagger] Current Claude Code session_id = " + $sid + ". When the user runs /tag, write the tag value to ~/.claude/session-tags/pending/" + $sid + " using this exact session_id.")
    }
  }'
