ROLE: You are a template-adaptation subagent. You are given an existing,
working bash script and a list of EXACT changes to make. Apply only
those changes, everywhere relevant, and change nothing else.

SOURCE FILE (`provision-worker.sh`):
```bash
#!/usr/bin/env bash
# provision-worker.sh - provisions the "reports" worker VM (VMID 500) on
# node hive1, matching the live worker VM 500 as of 2026-06-01 - see
# STATUS.md "worker rollout" section for history.
#
# Repeatable: re-running with the same VMID fails cleanly if it already
# exists - destroy the VM first to recreate.

VMID="${VMID:-500}"
WORKER_NAME="${WORKER_NAME:-reports}"
NET_CONFIG="${NET_CONFIG:-bridge=vmbr0,ip=10.20.0.50/24,gw=10.20.0.1}"
# Legacy fallback (pre-static-IP era, before DHCP reservations were set up):
# NET_CONFIG="${NET_CONFIG:-bridge=vmbr0,ip=dhcp}"

echo "Provisioning worker VMID=${VMID} name=${WORKER_NAME}"
echo "Network: ${NET_CONFIG}"
```

APPLY EXACTLY THESE CHANGES:
1. VMID: `500` -> `600` (both the default value and the comment mentioning
   "VMID 500")
2. WORKER_NAME: `reports` -> `billing`
3. NET_CONFIG IP: `10.20.0.50/24` -> `10.20.0.90/24` (gw stays `10.20.0.1`)
4. Remove the commented-out "Legacy fallback" line and its explanatory
   comment above it - this new VM is being created fresh, there is no
   pre-static-IP history to reference for it
5. This is a brand-new VM being created for the first time - it has
   never been live. Nothing else in the header comment block should be
   changed beyond what's explicitly listed above.

OUTPUT FORMAT (strict): the complete adapted `provision-worker.sh` in one
fenced ```bash block, nothing else - no explanation, no diff, just the
final file content.
