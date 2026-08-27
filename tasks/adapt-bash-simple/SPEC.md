ROLE: You are a template-adaptation subagent. You are given an existing,
working bash script and a list of EXACT substitutions to make. Apply
only those substitutions, everywhere they occur (including comments and
log/echo strings), and change nothing else - no reformatting, no added
comments, no "improvements."

SOURCE FILE (`deploy-check.sh`):
```bash
#!/usr/bin/env bash
# deploy-check.sh - health check for the Widget service, hits /health
# through the shared edge proxy and reports pass/fail.

SERVICE_NAME="widget"
SERVICE_PORT="4000"
SCRATCH_FILE="/tmp/widget-check.tmp"

echo "Checking ${SERVICE_NAME} on port ${SERVICE_PORT}..."
curl -sf "http://localhost:${SERVICE_PORT}/health" -o "${SCRATCH_FILE}" \
  && echo "${SERVICE_NAME}: healthy" \
  || echo "${SERVICE_NAME}: FAILED, see ${SCRATCH_FILE}"
```

APPLY EXACTLY THESE SUBSTITUTIONS, NOTHING ELSE:
1. `SERVICE_NAME` value: `widget` -> `gadget`
2. `SERVICE_PORT` value: `4000` -> `4100`
3. `SCRATCH_FILE` value: `/tmp/widget-check.tmp` -> `/tmp/gadget-check.tmp`

Do not touch the comment header's wording beyond the literal word
substitution implied above if "Widget" appears there too (it does - the
header comment says "Widget service", check it needs the same rename).

OUTPUT FORMAT (strict): the complete adapted `deploy-check.sh` in one
fenced ```bash block, nothing else - no explanation, no diff, just the
final file content.
