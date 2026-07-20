#!/usr/bin/env bash
# SessionEnd hook — writes one row per session to ~/.claude/session-tags/index.jsonl
# with { session_id, cwd, tag, tag_source, first_msg, ended_at, transcript_path }.
#
# If the session_id already has a row (i.e. the user resumed and re-exited),
# that row is REPLACED — the index stays canonical, one row per session.
#
# Tag precedence on write:
#   1. Explicit tag from /tag <name>          → tag_source = "manual"
#   2. Prior row's tag (preserved on resume)  → tag_source unchanged
#   3. Slug derived from first user message   → tag_source = "auto"
#   4. Falls back to short session id         → tag_source = "auto"
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
tag_source=""
pending_file="$PENDING_DIR/$session_id"
if [ -f "$pending_file" ]; then
  tag=$(tr -d '\n\r' < "$pending_file" | head -c 100)
  rm -f "$pending_file"
  if [ -n "$tag" ]; then
    tag_source="manual"
  fi
fi

# If no manual tag AND a prior row exists for this session_id (resume case),
# preserve the prior tag + tag_source so we don't clobber a manual tag.
if [ -z "$tag" ] && [ -s "$INDEX_FILE" ]; then
  prior=$(jq -rc --arg sid "$session_id" \
    'select(.session_id == $sid) | {tag, tag_source}' \
    "$INDEX_FILE" 2>/dev/null | tail -1)
  if [ -n "$prior" ]; then
    tag=$(printf '%s' "$prior" | jq -r '.tag // ""')
    tag_source=$(printf '%s' "$prior" | jq -r '.tag_source // ""')
  fi
fi

# Auto-derive a tag from the first user message if still none.
# slugify: lowercase, non-alnum → dash, collapse dashes, trim, first 40 chars.
if [ -z "$tag" ] && [ -n "$first_msg" ]; then
  tag=$(
    printf '%s' "$first_msg" \
      | tr '[:upper:]' '[:lower:]' \
      | LC_ALL=C sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
      | cut -c1-40 \
      | sed -E 's/-+$//'
  )
  [ -n "$tag" ] && tag_source="auto"
fi

# Final fallback: short session id (first 8 chars).
if [ -z "$tag" ]; then
  tag="session-${session_id:0:8}"
  tag_source="auto"
fi

# Build the new row.
new_row=$(jq -nc \
  --arg sid "$session_id" \
  --arg cwd "$cwd" \
  --arg tag "$tag" \
  --arg tag_source "$tag_source" \
  --arg first "$first_msg" \
  --arg tp "$transcript" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    session_id: $sid,
    cwd: $cwd,
    tag: $tag,
    tag_source: $tag_source,
    first_msg: $first,
    ended_at: $ts,
    transcript_path: $tp
  }')

# Rewrite the index: drop any prior rows for this session_id, then append the new one.
# Atomic replace via temp file so a crash mid-write can't corrupt the index.
tmp=$(mktemp "${INDEX_FILE}.XXXXXX")
if [ -s "$INDEX_FILE" ]; then
  jq -c --arg sid "$session_id" 'select(.session_id != $sid)' "$INDEX_FILE" > "$tmp" || true
fi
printf '%s\n' "$new_row" >> "$tmp"
mv "$tmp" "$INDEX_FILE"
