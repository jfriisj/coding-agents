# Epic 3.10 Orchestration Topology Matrix (v0.12.9)

This matrix defines the runtime-claim truth table for FR-012 under Epic 3.10.

| Topology | Orchestrator Deployed | Primary Decision Consumer Active | FR-012 Claim Allowed | Validation Evidence |
|---|---|---|---|---|
| Default Compose | Yes (`orchestrator-service` in `docker-compose.yml`) | Yes (`tts-service` decision enforcement path) | Yes | `tests/test_orchestration_runtime_activation_contract.py` + `tests/test_orchestration_primary_owner_contract.py` + `docs/orchestration-topic-security-matrix.md` + `docs/orchestration-security-control-evidence-matrix.md` + `docker-compose.yml` |
| Compose + GPU Overlay | Yes (inherits base compose orchestrator deployment) | Yes (inherits base compose decision consumer path; overlay does not disable enforcement) | Yes | `docker-compose.gpu.yml` + `docker-compose.yml` |
| Compose + Observability Overlay | Yes (inherits base compose orchestrator deployment) | Yes (inherits base compose decision consumer path; overlay is observability-only) | Yes | `docker-compose.observability.yml` + `docker-compose.yml` |
| Swarm / Release-Target Topology | Yes (`orchestrator-service` in `deploy/swarm-stack.yml`) | Yes (`tts-service` decision enforcement path) | Yes | `deploy/swarm-stack.yml` + `tests/test_orchestration_runtime_activation_contract.py` + `tests/test_orchestration_primary_owner_contract.py` + `docs/orchestration-topic-security-matrix.md` + `docs/orchestration-security-control-evidence-matrix.md` |

## Primary enforcement owner

- `tts-service` is the active downstream decision-enforcement owner.
- Explicit env contract: `ORCH_PRIMARY_DECISION_CONSUMER=${ORCH_PRIMARY_DECISION_CONSUMER:-tts-service}`.

## Claim discipline

- FR-012 runtime-activation claim is permitted only when orchestrator deployment and decision-consumer enforcement are both active for the selected topology.
