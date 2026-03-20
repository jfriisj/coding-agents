# Swarm Stack Deployment Runbook (IaC Context)

This runbook deploys the existing Swarm stack on the Pulumi-provisioned cluster. The canonical stack definition remains `deploy/swarm-stack.yml`.

## Preconditions

- Swarm cluster is initialized (see `docs/iac-swarm-bootstrap.md`).
- Manager node has required disks mounted for Kafka + MinIO (see `infrastructure/pulumi/README.md`).
- Image digests and secrets are prepared per the Epic 2.5 runbook.
- Runtime configuration is maintained in the single root `.env` file.

## Deployment

Follow the existing Swarm verification runbook and apply the stack as-is:

- Runbook: [docs/swarm-deployment-runbook.md](swarm-deployment-runbook.md)
- Stack file: [deploy/swarm-stack.yml](../deploy/swarm-stack.yml)

Load runtime variables from the single root `.env` before deploy:

```bash
set -a
. ./.env
set +a
docker stack deploy -c deploy/swarm-stack.yml speech
```

The IaC blueprint does **not** duplicate or re-model the stack definition.
