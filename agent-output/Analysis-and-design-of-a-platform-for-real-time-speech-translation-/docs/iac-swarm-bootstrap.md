# Swarm Bootstrap Runbook (Epic 3.0 IaC)

This runbook bootstraps the Swarm cluster using Pulumi outputs. It intentionally avoids Pulumi remote-exec.

## Prerequisites

- Pulumi stack already applied (`pulumi up`).
- SSH access to manager and worker nodes.
- Manager + worker internal IPs from Pulumi outputs.
- Runtime config available from the single root `.env` file.

Note: If the stack is configured with no external IPs (preferred), use a bastion host, IAP TCP forwarding, or a VPN to reach the private IPs.

## Step 1: Capture Pulumi outputs

From the Pulumi project directory:

```bash
cd infrastructure/pulumi
pulumi stack output --json > /tmp/pulumi_outputs.json
```

## Step 2: Read manager + worker IPs

```bash
MANAGER_IP=$(python - <<'PY'
import json
print(json.load(open("/tmp/pulumi_outputs.json"))["manager_internal_ip"])
PY
)

WORKER_IPS=$(python - <<'PY'
import json
print(" ".join(json.load(open("/tmp/pulumi_outputs.json"))["worker_internal_ips"]))
PY
)
```

## Step 2b: Stage runtime `.env` on manager

Copy the same root `.env` used locally to the manager node (single runtime source of truth):

```bash
scp .env "$SSH_USER@$MANAGER_IP:~/speech.env"
```

Use this file when running `docker stack deploy` from the manager shell.

## Step 3: Initialize Swarm on manager

```bash
ssh "$SSH_USER@$MANAGER_IP" "docker swarm init --advertise-addr $MANAGER_IP"
```

Capture the worker join token:

```bash
WORKER_TOKEN=$(ssh "$SSH_USER@$MANAGER_IP" "docker swarm join-token -q worker")
```

## Step 4: Join workers

```bash
for ip in $WORKER_IPS; do
  ssh "$SSH_USER@$ip" "docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377"
done
```

## Step 5: Label the manager for stateful services

```bash
MANAGER_NAME=$(ssh "$SSH_USER@$MANAGER_IP" "docker node ls --format '{{.Hostname}}' | head -n 1")
ssh "$SSH_USER@$MANAGER_IP" "docker node update --label-add role=stateful $MANAGER_NAME"
```

## Step 6: Mount persistent disks on the manager

The Pulumi blueprint provisions disks for Kafka + MinIO. Format and mount them on the manager before stack deployment. Example placeholder mount points:

- `/mnt/kafka`
- `/mnt/minio`

Use your OS-specific disk device names (e.g., `/dev/disk/by-id/google-kafka-disk`) and update the stack or service configs accordingly.
