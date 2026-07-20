---
description: Tag the current Claude Code session so you can resume it later by name.
argument-hint: <tag-name>
allowed-tools: Bash(mkdir:*), Bash(printf:*), Bash(tee:*)
---

The user wants to tag the current Claude Code session with: **$ARGUMENTS**

Your context contains a line that starts with `[session-tagger] Current Claude Code session_id = <uuid>`. Extract that UUID (call it `SID`).

Then run exactly this shell command, substituting `SID` and the tag:

```bash
mkdir -p ~/.claude/session-tags/pending && printf '%s' "$ARGUMENTS" > ~/.claude/session-tags/pending/SID
```

After it succeeds, respond with a single line confirming: `Tagged session as "$ARGUMENTS" — will be indexed when this session ends.`

If `$ARGUMENTS` is empty, don't run anything. Just tell the user: `Usage: /tag <name>`.

If you can't find the session_id in your context, tell the user the session-tagger SessionStart hook didn't run — they may need to restart the session.
