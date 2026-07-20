# session-tagger

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin that lets you tag sessions with human-readable names and resume them later — no more scrolling through opaque UUIDs in `claude --resume`.

## Why

`claude --resume` shows the first user message and a timestamp. That's fine for "the session I had an hour ago," useless for "the session where I was refactoring payments last week." This plugin adds:

- `/tag <name>` — tag the current session from inside Claude
- `/tags [query]` — list & search tagged sessions from inside Claude
- `claude-resume-tag <name>` — shell helper to resume by tag (with optional `fzf` picker)
- A `SessionEnd` hook that indexes every session automatically, tag or not

Tags and metadata live in `~/.claude/session-tags/index.jsonl` — a plain JSONL file you own, back up, or sync however you want.

## Install

Requires `jq`. Optional: `fzf` for the interactive picker.

```bash
# Inside Claude Code:
/plugin marketplace add https://github.com/AryanChandna/claude-session-tagger
/plugin install session-tagger@session-tagger-marketplace
```

For the shell helper, either symlink it or add the plugin's `bin/` to your `PATH`:

```bash
ln -s ~/.claude/plugins/cache/session-tagger-marketplace/session-tagger/bin/claude-resume-tag \
      /usr/local/bin/claude-resume-tag
```

Restart your Claude Code session so the `SessionStart` hook fires.

## Usage

Inside a Claude Code session:

```
/tag payments-refactor
```

The tag gets attached to the current session and written to the index when the session ends. If you never run `/tag`, the session is still indexed with its first user message as a fallback label.

List and search:

```
/tags                 # last 30 tagged sessions
/tags payments        # filter by tag or first-message substring
```

Resume from your shell:

```bash
claude-resume-tag payments-refactor       # resume newest session with this tag
claude-resume-tag                          # fzf picker (if fzf installed)
claude-resume-tag --list refactor         # print index, filtered, no resume
```

## How it works

- **`SessionStart` hook** injects a line into Claude's context: `[session-tagger] Current Claude Code session_id = <uuid>`. This lets the `/tag` command reference the session_id when writing a pending tag file.
- **`/tag <name>`** writes `<name>` to `~/.claude/session-tags/pending/<session-id>`.
- **`SessionEnd` hook** reads the pending file (if any), extracts the first user message from the transcript, appends one JSONL row to `~/.claude/session-tags/index.jsonl`, and deletes the pending file.

Index row shape:

```json
{
  "session_id": "…",
  "cwd": "/Users/you/project",
  "tag": "payments-refactor",
  "first_msg": "help me refactor the payment retry loop",
  "ended_at": "2026-07-20T14:32:00Z",
  "transcript_path": "/Users/you/.claude/projects/…/…jsonl"
}
```

## Uninstall

```
/plugin uninstall session-tagger
```

Your index at `~/.claude/session-tags/` is left untouched — delete it manually if you want a clean slate.

## License

MIT
