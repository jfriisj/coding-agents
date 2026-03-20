# IaC Evidence Runbook (Epic 3.0)

This runbook produces the IaC evidence bundle at `agent-output/validation/iac/<run_id>/` and runs the denylist scan.

## Prerequisites

- Pulumi local backend configured (`PULUMI_BACKEND_URL=file://$HOME/.pulumi-local`).
- Pulumi passphrase configured (`PULUMI_CONFIG_PASSPHRASE` or `PULUMI_CONFIG_PASSPHRASE_FILE`).
- Stack selected/created locally (e.g. `devlocal`).
- Swarm verification evidence already captured (Epic 2.5).
- `tools/iac_evidence.py` available in this repo.

## Step 1: Capture Pulumi metadata

```bash
PULUMI_BACKEND_URL=file://$HOME/.pulumi-local \
PULUMI_CONFIG_PASSPHRASE='<your-passphrase>' \
STACK=devlocal \
ACTION=outputs \
LOCAL_ONLY=1 \
RUN_ID=run-001 \
./.github/skills/pulumi-iac-operations/scripts/run-operations.sh

cp agent-output/validation/iac/run-001/pulumi_outputs.json /tmp/pulumi_outputs.json
cp agent-output/validation/iac/run-001/pulumi_stack_name.txt /tmp/pulumi_stack_name.txt
cp agent-output/validation/iac/run-001/pulumi_version.txt /tmp/pulumi_version.txt
cp agent-output/validation/iac/run-001/provider_versions.json /tmp/provider_versions.json
cp agent-output/validation/iac/run-001/pulumi_config_sanitized.json /tmp/sanitized_config.json

python - <<'PY'
import json
from pathlib import Path

path = Path("/tmp/sanitized_config.json")
payload = json.loads(path.read_text(encoding="utf-8"))
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
```

## Step 2: Define redaction policy

```bash
cat > /tmp/redaction_policy.json <<'JSON'
{
  "notes": "Redact project identifiers and external IPs if evidence is shared outside the project."
}
JSON
```

## Step 3: Run the IaC evidence writer

```bash
./.venv/bin/python - <<'PY'
import json
from pathlib import Path
from tools.iac_evidence import run_iac_evidence

run_id = "run-001"
output_dir = Path("agent-output/validation/iac")

pulumi_stack_name = Path("/tmp/pulumi_stack_name.txt").read_text(encoding="utf-8").strip()
pulumi_version = Path("/tmp/pulumi_version.txt").read_text(encoding="utf-8").strip()
provider_versions = json.loads(Path("/tmp/provider_versions.json").read_text(encoding="utf-8"))
sanitized_config = json.loads(Path("/tmp/sanitized_config.json").read_text(encoding="utf-8"))
outputs = json.loads(Path("/tmp/pulumi_outputs.json").read_text(encoding="utf-8"))

swarm_evidence_ref = {
    "path": "agent-output/validation/swarm/run-006",
    "note": "Replace with the actual Epic 2.5 evidence run id",
}
redaction_policy = json.loads(Path("/tmp/redaction_policy.json").read_text(encoding="utf-8"))

run_iac_evidence(
    run_id=run_id,
    output_dir=output_dir,
    pulumi_stack_name=pulumi_stack_name,
    pulumi_version=pulumi_version,
    provider_versions=provider_versions,
    sanitized_config=sanitized_config,
    outputs=outputs,
    swarm_evidence_ref=swarm_evidence_ref,
    redaction_policy=redaction_policy,
)
PY
```

If the denylist scan fails, the script raises an error and writes a `denylist_scan.json` with findings for remediation.

In local-only mode, infrastructure outputs may be empty (`{}`) if no provider-backed apply has been executed; this is expected for smoke/evidence preflight.
