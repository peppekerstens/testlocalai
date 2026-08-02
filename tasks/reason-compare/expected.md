Candidate A is the correct fix: it loads and validates the config once at
boot, before `app.listen`, so a bad file fails the startup instead of the
first session — matching the documented fix's part (1) and preserving the
"process is running ⇒ config was valid" property. Candidate B is incomplete
on its own: it reproduces the original lazy-load timing (bad config still
isn't detected until the first client connects), and while the try/catch
converts the crash into a `500`, the process still boots with an invalid
config and every affected request keeps failing until a restart. Candidate C
is wrong: an auto-restart on first connect is a workaround, not a fix — the
config still isn't validated at boot, the first client still hits the error,
and the process can crash/loop between the check and the restart. The
try/catch from part (2) is still worth keeping alongside A as defense in
depth for any *other* runtime error reaching the `/mcp` handler — but it is
not a substitute for eager boot-time validation.
