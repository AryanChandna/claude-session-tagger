# session-tagger — shell wrapper that adds a `claude resume [tag]` subcommand.
#
# INSTALL: source this file from your shell rc, e.g.:
#   echo 'source ~/.claude/plugins/marketplaces/session-tagger-marketplace/bin/claude-wrapper.sh' >> ~/.zshrc
#
# USAGE:
#   claude resume             # fzf picker over all tagged sessions (needs fzf)
#   claude resume payments    # fzf pre-filtered, or exact-tag match without fzf
#   claude <anything-else>    # unchanged — passes straight through to real claude
#
# The wrapper delegates to claude-resume-tag under the hood, so behavior stays
# in sync with the CLI helper.

claude() {
  if [ "${1:-}" = "resume" ]; then
    shift
    if command -v claude-resume-tag >/dev/null 2>&1; then
      command claude-resume-tag "$@"
    else
      echo "session-tagger: claude-resume-tag not found on PATH." >&2
      echo "  Add ~/.local/bin to PATH, or restart a Claude session to trigger auto-symlink." >&2
      return 1
    fi
  else
    command claude "$@"
  fi
}
