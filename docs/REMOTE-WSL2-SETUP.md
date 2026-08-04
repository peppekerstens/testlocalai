# Remote WSL2 host — setup findings (condensed)

A second machine (Windows 11, AMD system, RTX 3060-class GPU / 8GB VRAM,
32GB RAM) was set up as a second llama.cpp host over SSH, to take
larger models (9B and up) off the primary host's 4GB-VRAM card. Driven
entirely remotely via SSH into a Windows admin account, no physical
access. Findings below are infrastructure gotchas worth knowing before
repeating this, not steering technique — see `SETUP.md` for that.

## Access pattern
Bridge through the Windows-side SSH connection into WSL2 rather than
exposing WSL2's own sshd separately at first:
`ssh <user>@<host>` then `wsl -d <distro> -- <command>`. This was 100%
reliable throughout; a second, direct sshd inside WSL2 (its own port)
also works but needed one extra fix — see "WSL2 idle-shutdown" below.

## Windows/SSH gotchas
- **IPv6 was broken on the target network** — every HTTP client
  (`curl.exe`, `Invoke-WebRequest`) tried IPv6 first and hung until
  timeout before ever trying IPv4. Force IPv4 explicitly (`curl -4`).
- **`cmd.exe` (the default SSH shell) does not understand single-quote
  grouping** — nested quoting through it breaks silently and
  unpredictably. Use PowerShell `-EncodedCommand` (base64 UTF-16LE) for
  PowerShell, and stdin-piped heredocs
  (`ssh host "wsl -d distro -- bash -s" <<'EOF' ... EOF`) for bash —
  both sidestep the quoting problem entirely rather than fighting it.
- **Detached/background processes launched over an SSH session do not
  reliably survive that session disconnecting**, even via
  `Start-Process`. Long downloads/builds need one continuously-held-open
  foreground SSH connection (with `-o ServerAliveInterval=15` so it
  doesn't idle-timeout), not a detach-and-poll pattern. Anything that
  must persist independently needs a Windows Scheduled Task instead —
  fully separate process ancestry, immune to this.
- **`wsl --install` fails silently from a non-interactive SSH
  session** (no error, just "not installed") — its Store-based download
  needs a real desktop session it doesn't have here. Fix: sideload the
  WSL launcher MSIX directly from the project's GitHub releases via
  `Add-AppxPackage`, and install a distro via `wsl --import` against a
  plain rootfs tarball (Canonical publishes these) instead of
  `wsl --install -d <distro>`, which hits the same Store dependency.

## WSL2 idle-shutdown (the real root cause behind a lot of flakiness)
WSL2 tears the **entire VM** down shortly after the last attached
`wsl.exe` client disconnects — killing every process inside it,
including any always-on service. This is a Windows-level VM lifecycle
decision, **not** prevented by enabling Linux-side systemd lingering
(different layer entirely), and `vmIdleTimeout=-1` in `.wslconfig`
(the documented fix) did not reliably prevent it on the tested WSL
version. This produced a very confusing symptom: a direct SSH
connection into WSL2's own sshd would work once, then fail
unpredictably — which first looked like a mirrored-networking bug, but
was actually the whole VM restarting between attempts. Fix that
actually worked: a Windows Scheduled Task running
`wsl.exe -d <distro> -- sleep infinity`, holding a permanent client
connection open independent of any interactive session.

## Mirrored networking
`networkingMode=mirrored` in `.wslconfig` makes WSL2 share the host's
real LAN IP directly instead of a separate NAT subnet — genuinely
LAN-discoverable, which was the goal. Once the idle-shutdown issue
above was actually fixed, mirrored mode's inbound port-sharing turned
out to be fully reliable too — worth stating clearly since it's easy to
misdiagnose idle-shutdown symptoms as a mirrored-mode bug (this
happened during setup and cost real debugging time).

## Direct SSH into WSL2 (port 2222)
Once the idle-shutdown fix above is in place, a second `sshd` inside
WSL2 itself (own port, e.g. 2222, since mirrored mode shares the host's
IP and port 22 is already taken by the Windows-side `sshd`) works
reliably — needs its own Windows Firewall inbound rule for that port.
Before the idle-shutdown fix, this looked flaky in a specific, misleading
way: `nc -z`/raw TCP connect would succeed, but a real SSH session would
still time out or reset — the handshake can complete against a VM that's
mid-teardown even though the actual session never does. Don't trust a
bare port-connect check as proof a service is reachable; a full
protocol-level round trip is the only real test.

## Windows session management
- No `quser`/`logoff.exe` on this Windows edition (Home lacks the RDS
  session tools). To list real sessions: `Get-CimInstance
  Win32_LoggedOnUser`, cross-checked against `Get-Process -IncludeUserName`
  (a session with no owned processes is stale/not really active — one
  with `explorer`, browser, chat apps etc. is a real, in-use desktop,
  worth confirming before touching it).
- To force-end a session without `logoff.exe`: P/Invoke `WTSLogoffSession`
  from `wtsapi32.dll` via PowerShell `Add-Type` (get the session ID from
  any process owned by that user, e.g. `explorer`'s `SessionId`). Use a
  PowerShell **single-quoted** here-string (`@'...'@`) for the embedded
  C#, not double-quoted (`@"..."@`) — the latter needs escaping that
  breaks easily through an SSH-relayed base64-encoded command.
- A logged-off session's own processes (including anything that user had
  running in the background, e.g. a separately-installed Ollama instance)
  die with it — don't assume a background service needs killing
  separately if it was only ever running under that user's session.

## Git organization on this machine
- Git repos live under `~/github/<repo>` (not mixed in with model
  weights or scratch); large temp files go in `/mnt/c/tmp` (same
  workaround as `SETUP.md`'s CUDA-install case — WSL2's own `/tmp` is a
  small tmpfs).
- **No push credentials on this machine** — cloned via plain HTTPS, no
  credential helper, no SSH deploy key. `git push` doesn't error, it
  hangs waiting for an interactive credential prompt that never comes
  (non-interactive SSH session, no TTY) — looks identical to every other
  "needs a real terminal" wall hit during this setup. Workaround that
  actually works: from a machine that already has push access, fetch the
  remote's commits directly over git+ssh
  (`git fetch ssh://user@host:2222/home/user/path/to/repo main:tmp-branch`,
  password via `GIT_SSH_COMMAND="sshpass -p '...' ssh ..."`), fast-forward
  merge, push from there. Provisioning real push credentials on the
  remote (SSH deploy key or a stored token) would remove the need for
  this relay — not done here, flagged as a follow-up.

## Claude Code running autonomously on the remote
Same Claude subscription as the driving session, authenticated via
`claude setup-token` — this needs a **real interactive terminal** (shows
a URL, waits for browser auth, confirms in-terminal) and could not be
driven through any SSH-piped/non-interactive path, including `ssh -t`;
the user had to run it themselves in their own terminal window. The
resulting long-lived token goes in `CLAUDE_CODE_OAUTH_TOKEN`, exported
from `~/.bashrc` — but non-interactive invocations (systemd, a script)
don't source `.bashrc` automatically, so anything that runs the agent
headlessly needs `source <(grep '^export CLAUDE_CODE_OAUTH_TOKEN=' ~/.bashrc)`
(or equivalent) explicitly. A workspace also needs its trust dialog
accepted before `.claude/settings.json`'s permission grants apply — set
`projects["<path>"].hasTrustDialogAccepted: true` directly in
`~/.claude.json` since there's no interactive session to click through
the dialog either.

**Why headless `claude -p`, not a persistent interactive session:**
considered driving a real interactive session over SSH (raw stdin
injection, or `tmux send-keys`/`capture-pane` for a real pty). Headless
`-p` won instead: it's the actually-supported scriptable mode (clean
exit code + result when done, no ANSI/redraw chrome to fight), and — more
importantly — a persistent session reopens the exact problems already
solved for everything else here (staying alive across SSH disconnects,
needing a real TTY, coordinating access from multiple callers). A
file-based inbox/status/roadmap pattern instead: each cycle is a
brand-new, independent `claude -p` invocation with no memory of the last
one; continuity comes entirely from files it reads and writes, not a
live session.

**Two real bugs found running this unattended, both fixed:**
- `--output-format stream-json --verbose` gives real-time, per-tool-call
  JSON events on stdout — parse this (not the final plain-text result)
  for live progress visibility during a long run. The final human-readable
  summary is the last line's `.result` field, not the raw stream.
- **`systemctl start` on a `Type=oneshot` service does not reliably
  block until the underlying process actually finishes** — confirmed
  directly: the command returned while the real `claude -p` process was
  still running and making progress minutes later. Don't treat the
  command's own return as proof the work is done; check the actual
  process (or a live progress file) instead.
- **Systemd's single-instance protection only covers the *timer*
  double-firing — not a direct manual invocation of the same script**,
  which has no knowledge of the systemd unit at all. Running the script
  by hand (e.g. for a diagnostic trace) while a real timer-triggered run
  was still active produced two genuinely concurrent unattended agents
  editing the same shared files — caught this time because the second
  instance noticed the collision itself and backed off, which is luck,
  not a guarantee. Fixed with a real `flock` at the top of the script
  (`exec 200>lockfile; flock -n 200 || exit 0`) — robust against both
  systemd and manual invocation, and safe on a crash since the OS
  releases the lock when the file descriptor closes.

## Hardware / performance
- CUDA passthrough into WSL2 worked out of the box, no manual driver
  install needed inside Linux (same as the primary host's experience).
- With real `sudo` available (unlike the primary host), `apt install
  nvidia-cuda-toolkit` + `build-essential` + `cmake` was far simpler
  than the primary host's no-sudo manual runfile install — CUDA 12.x
  from apt is plenty sufficient despite a newer driver; CUDA maintains
  driver forward-compatibility.
- `-DCMAKE_CUDA_ARCHITECTURES=86` for this GPU generation (Ampere),
  not the primary host's `75` (Turing) — check
  `nvidia-smi --query-gpu=compute_cap` on new hardware rather than
  assuming.
- Real measured performance, 9B Q4_K_M model, full GPU offload
  (`-ngl 99` — safe here since the model comfortably fits in 8GB,
  unlike the oversubscription trap on the primary host's 4GB card):
  **~70 tok/s generation, ~45 tok/s prompt eval.**
