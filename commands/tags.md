---
description: List tagged Claude Code sessions, optionally filtered by a query.
argument-hint: [query]
allowed-tools: Bash(cat:*), Bash(jq:*), Bash(grep:*), Bash(test:*)
---

Show the user their tagged Claude Code sessions from `~/.claude/session-tags/index.jsonl`.

If `$ARGUMENTS` is non-empty, filter to entries where either `tag` or `first_msg` contains that substring (case-insensitive).

Run this to fetch and format:

```bash
test -s ~/.claude/session-tags/index.jsonl || { echo "No tagged sessions yet."; exit 0; }
jq -r '
  [.ended_at[0:10], (.tag // "-"), (.cwd | split("/") | last), (.first_msg // "")[0:60], .session_id]
  | @tsv
' ~/.claude/session-tags/index.jsonl
```

Then present the result as a compact table with columns: **Date | Tag | Project | First message | Session ID**.

If a query was given, apply case-insensitive filtering in your presentation (do not modify the underlying data). Sort newest first. Only show the last 30 rows unless the user asked otherwise.

Remind the user at the bottom: `Resume with: claude --resume <session-id>  (or use the claude-resume-tag shell helper)`.
