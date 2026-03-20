# IaC Security & Maintainability Checklist (Epic 3.0)

Use this checklist before sharing evidence or handing off to QA/UAT.

## Secrets & Evidence Safety

- [ ] Pulumi state files are not committed and are excluded from evidence bundles.
- [ ] Pulumi config exported for evidence is sanitized (no secret values).
- [ ] Evidence bundle passes denylist scan (no credentials, presigned URLs, or raw content).

## Exposure Posture

- [ ] Kafka, Schema Registry, and MinIO are internal-only (no public ingress).
- [ ] Gateway is internal-only; verification runs from within the VPC.
- [ ] SSH ingress is restricted to trusted source ranges.

## Operator Access

- [ ] Preferred: no external IPs on nodes; access via controlled private path (bastion/IAP/VPN).
- [ ] If external IPs exist: confirm no service ports are publicly reachable.

## Rollback

- [ ] `pulumi destroy` documented and reviewed for safe cleanup.
- [ ] Evidence artifacts preserved separately from infrastructure state.
