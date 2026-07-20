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

Restart your Claude Code session so the `SessionStart` hook fires.

**Shell helper (`claude-resume-tag`):** the plugin's `SessionStart` hook auto-symlinks the helper into `~/.local/bin/` the first time it runs — no manual step needed. If `~/.local/bin` isn't on your `PATH` (most modern setups have it; if `which claude-resume-tag` comes up empty, add this to your shell rc):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

Inside a Claude Code session:

```
/tag payments-refactor
```

The tag gets attached to the current session and written to the index when the session ends.

**If you never run `/tag`**, the session is still indexed — the plugin auto-derives a tag from a slug of your first user message (e.g. `Refactor the payment retry loop` → `refactor-the-payment-retry-loop`). The row's `tag_source` field records whether the tag was `manual` or `auto`, so you can filter or re-tag later.

List and search:

```
/tags                 # last 30 tagged sessions
/tags payments        # filter by tag or first-message substring
```

Resume from your shell — three equivalent forms:

```bash
claude-resume-tag payments-refactor       # full name
cr payments-refactor                      # short alias (same command)
claude-resume-tag                          # fzf picker (if fzf installed)
claude-resume-tag --list refactor         # print index, filtered, no resume
```

### Optional: `claude resume` subcommand

If you'd like `claude resume <tag>` to feel like a first-class subcommand, source the shell wrapper from your rc file:

```bash
echo 'source ~/.claude/plugins/marketplaces/session-tagger-marketplace/bin/claude-wrapper.sh' >> ~/.zshrc
source ~/.zshrc
```

Then:

```bash
claude resume                # fzf picker over all tagged sessions
claude resume payments       # pre-filtered picker (or exact-match without fzf)
claude <anything-else>       # unchanged — passes through to the real claude
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
  "tag_source": "manual",
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
