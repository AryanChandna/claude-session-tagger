#!/usr/bin/env bash
# SessionEnd hook — appends a row to ~/.claude/session-tags/index.jsonl
# with { session_id, cwd, tag, first_msg, ended_at, transcript_path }.
# If the user ran /tag <name> during the session, that pending tag is used;
# otherwise the tag is left null and the first user message serves as the label.
set -euo pipefail

INDEX_DIR="$HOME/.claude/session-tags"
INDEX_FILE="$INDEX_DIR/index.jsonl"
PENDING_DIR="$INDEX_DIR/pending"

mkdir -p "$PENDING_DIR"
touch "$INDEX_FILE"

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [ -z "$session_id" ]; then
  exit 0
fi

# Extract the first user message text (truncated) from the transcript, if any.
first_msg=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  first_msg=$(
    jq -r '
      select(.type == "user")
      | .message.content
      | if type == "string" then .
        elif type == "array" then (map(select(.type=="text") | .text) | join(" "))
        else "" end
    ' "$transcript" 2>/dev/null \
    | grep -v '^$' \
    | head -1 \
    | tr '\n\r\t' '   ' \
    | cut -c1-120
  )
fi

# Pick up a tag the user set with /tag during the session.
tag=""
pending_file="$PENDING_DIR/$session_id"
if [ -f "$pending_file" ]; then
  tag=$(tr -d '\n\r' < "$pending_file" | head -c 100)
  rm -f "$pending_file"
fi

# Append a single JSONL row.
jq -nc \
  --arg sid "$session_id" \
  --arg cwd "$cwd" \
  --arg tag "$tag" \
  --arg first "$first_msg" \
  --arg tp "$transcript" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    session_id: $sid,
    cwd: $cwd,
    tag: (if $tag == "" then null else $tag end),
    first_msg: $first,
    ended_at: $ts,
    transcript_path: $tp
  }' >> "$INDEX_FILE"
