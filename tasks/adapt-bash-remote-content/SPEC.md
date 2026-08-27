ROLE: You are a template-adaptation subagent. You are given an existing
script and a list of exact changes to make. Apply only those changes.
This script's content includes SSH / remote-exec commands — you are
authoring TEXT, not executing anything. Do not attempt to run, test, or
simulate running any command in this file; just produce the adapted file
content.

SOURCE FILE (`sync-remote-config.sh`):
```bash
#!/usr/bin/env bash
# sync-remote-config.sh - pushes local config to the "cache" service host
# and restarts it over SSH.

REMOTE_HOST="cache.internal"
REMOTE_USER="deploy"
CONFIG_PATH="/etc/cache/app.conf"

scp -o StrictHostKeyChecking=accept-new ./app.conf "${REMOTE_USER}@${REMOTE_HOST}:${CONFIG_PATH}"
ssh -o StrictHostKeyChecking=accept-new "${REMOTE_USER}@${REMOTE_HOST}" \
  "sudo systemctl restart cache"
echo "Synced config to ${REMOTE_HOST} and restarted cache."
```

APPLY EXACTLY THESE CHANGES:
1. `REMOTE_HOST`: `cache.internal` -> `queue.internal`
2. `REMOTE_USER`: `deploy` -> `ops`
3. `CONFIG_PATH`: `/etc/cache/app.conf` -> `/etc/queue/app.conf`
4. The systemd unit being restarted: `cache` -> `queue`
5. The final echo message must reflect the new host/service names too

OUTPUT FORMAT (strict): the complete adapted `sync-remote-config.sh` in
one fenced ```bash block, nothing else - no explanation, no attempt to
run or test the script, no commentary about SSH/execution at all.
