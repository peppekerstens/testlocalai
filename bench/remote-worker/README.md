# Remote worker orchestration scripts

The actual scripts driving the autonomous Claude Code loop on the
remote worker machine described in `docs/REMOTE-WSL2-SETUP.md`. Saved
here for durability/reproducibility — these only existed on the remote
machine's own filesystem (`~/claude-remote/`) until now. Deployed
paths assume `~/github/testlocalai` (the repo) and `~/claude-remote/`
(state/scripts) on that machine — adjust if reusing elsewhere.

No secrets in any of these files (checked before committing): the
OAuth token is sourced from `~/.bashrc` at runtime
(`source <(grep '^export CLAUDE_CODE_OAUTH_TOKEN=' ~/.bashrc)`), never
embedded; SSH/Windows credentials never touched these files at all.

## Files

- **`run.sh`** — the actual unit of work. Acquires a `flock` (single-
  instance protection — see `docs/REMOTE-WSL2-SETUP.md`'s "two real
  bugs" section for why this is load-bearing, not optional), checks a
  top-level inbox for override instructions, otherwise follows
  `orchestrator.md` to find the active role and continues its
  AGENTS.md quality-loop work, streams live progress, and appends a
  summary to `status.md` when done.
- **`stream_progress.py`** — parses `claude -p --output-format
  stream-json`'s event stream into human-readable "step N: X
  running/done" lines, written live to `progress.md` as the run
  happens (not just a summary after the fact).
- **`orchestrator.md.example`** — the sequential role-order file
  `run.sh` reads. Named `.example` because it's specific to this
  deployment's actual role list (qwen3.5:9b, 5 untested roles) — copy
  to `orchestrator.md` and adjust for a different model/role set.
- **`claude-autonomous.service` / `claude-autonomous.timer`** —
  systemd user units. Install to `~/.config/systemd/user/`, then
  `systemctl --user daemon-reload && systemctl --user enable --now
  claude-autonomous.timer`. First fire needs a manual
  `systemctl --user start claude-autonomous.service` once, to give
  `OnUnitActiveSec` a baseline — see `docs/REMOTE-WSL2-SETUP.md`.

## Not included here

Per-role live state (`roles/<role>/{inbox,roadmap,status}.md`,
top-level `inbox.md`/`status.md`/`progress.md`) is runtime evidence,
not a script — it lives on the remote machine itself and gets
synced into this repo's own `models/`/`tasks/` structure as real
quality-loop commits, the same way any other steering session's
findings do.
