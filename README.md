# session-tagger

Tag Claude Code sessions with human-readable names and resume them by tag — no more scrolling through opaque UUIDs.

```
$ cr                                        # opens fzf picker with incremental search
resume > gpu                                # type letters, list filters live
> 2026-07-20  can-you-tell-me-why-llms-need-gpu  workspace  can you tell me why llms need gpu
[Enter → resumes that session]
```

Every Claude Code session is auto-indexed on exit. You can add explicit tags with `/tag <name>` during a session, or let the plugin auto-derive a tag from your first message. Then find sessions later with a shell command, an fzf picker, or a slash command.

---

## Install (60 seconds)

**Prerequisites:** `jq` (required), `fzf` (strongly recommended — enables incremental picker).

```bash
brew install jq fzf   # macOS
```

**In Claude Code:**

```
/plugin marketplace add https://github.com/AryanChandna/claude-session-tagger
/plugin install session-tagger@session-tagger-marketplace
```

Then **exit and start a fresh `claude` session** so the `SessionStart` hook fires. That hook auto-symlinks the shell helpers (`claude-resume-tag` and its short alias `cr`) into `~/.local/bin/`.

**PATH check:** if `which cr` comes up empty, add `~/.local/bin` to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**Optional — enable the `claude resume` subcommand:**

```bash
echo 'source ~/.claude/plugins/marketplaces/session-tagger-marketplace/bin/claude-wrapper.sh' >> ~/.zshrc
source ~/.zshrc
```

That's it.

---

## Daily use

### From your shell — the main flow

```bash
cr                    # incremental fzf picker over every session
cr gpu                # picker pre-filtered to "gpu" (refine or clear)
cr --list             # print index as a table, no resume
cr --list refactor    # print index, filtered, no resume
```

If you added the wrapper, these all also work:

```bash
claude resume         # same picker
claude resume gpu     # pre-filtered
claude <anything>     # unchanged — pass-through to real claude
```

### Inside a Claude session — optional slash commands

```
/tag payments-refactor    # override the auto-tag for this session
/tags                     # list recent tagged sessions inline
/tags gpu                 # filter that list
```

You **don't need** to run `/tag` — every session is auto-tagged from a slug of your first user message. `/tag` is just for when you want a more memorable name.

---

## How it works

1. **`SessionStart` hook** — injects your current `session_id` into Claude's context so `/tag` knows which session to write for. Also idempotently symlinks `cr` and `claude-resume-tag` into `~/.local/bin/`.
2. **`/tag <name>`** — writes `<name>` to `~/.claude/session-tags/pending/<session-id>`.
3. **`SessionEnd` hook** — on exit, reads that pending file (if any), pulls the first user message from the transcript, derives an auto-slug if no manual tag was set, and appends one JSONL row to `~/.claude/session-tags/index.jsonl`.
4. **`cr` / `claude-resume-tag`** — reads the index, matches your query, and execs `claude --resume <session-id>`.

Index row:

```json
{
  "session_id": "5babcb25-…",
  "cwd": "/Users/you/project",
  "tag": "can-you-tell-me-why-llms-need-gpu",
  "tag_source": "auto",
  "first_msg": "can you tell me why llms need gpu",
  "ended_at": "2026-07-20T08:04:18Z",
  "transcript_path": "/Users/you/.claude/projects/…/…jsonl"
}
```

Everything lives in `~/.claude/session-tags/`. Plain JSONL, plain shell — inspect, back up, sync, or hand-edit freely.

### Resume behavior

When you resume a session and exit again, `SessionEnd` **replaces the existing row** rather than appending a duplicate — one row per session_id, always. `ended_at` updates to the latest exit time. If the session previously had a manual `/tag`, that tag is preserved across resumes (you don't lose it by not re-running `/tag`).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `zsh: command not found: cr` | Add `~/.local/bin` to PATH (see Install). |
| `claude resume` opens a normal Claude session instead of the picker | Wrapper not loaded in current shell — run `source ~/.zshrc` or open a new terminal. |
| Picker isn't incremental (no live filtering) | fzf isn't installed — `brew install fzf`. |
| A session doesn't appear in the index | The `SessionEnd` hook only runs when Claude exits cleanly. Force-killing the process (Ctrl-C spam, terminal close, machine crash) skips indexing. |
| Auto-tags collide (two sessions same slug) | Fine — the picker shows both; `cr <tag>` resolves to the newest by default. Use `/tag <unique-name>` to disambiguate. |
| Want to remove a session from the index | Hand-edit `~/.claude/session-tags/index.jsonl` — it's plain JSONL, one row per session. |

---

## Uninstall

```
/plugin uninstall session-tagger
```

Your index at `~/.claude/session-tags/` is left in place — delete it manually for a clean slate. Also remove any lines you added to `~/.zshrc` (PATH export, wrapper source) if you no longer want them.

---

## License

MIT
