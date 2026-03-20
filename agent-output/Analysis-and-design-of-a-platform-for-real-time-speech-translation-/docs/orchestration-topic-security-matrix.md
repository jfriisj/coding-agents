# Epic 3.10 Orchestration Topic Security Matrix (v0.12.9)

This matrix defines least-privilege publish/consume permissions for orchestration topics in active Epic 3.10 topologies.

| Topic | Identity | Publish | Consume | Transport Security | Deny-by-Default Note |
|---|---|---|---|---|---|
| `speech.orchestration.command` | `asr-service` | Allow | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.command` | `translation-service` | Allow | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.command` | `orchestrator-service` | Deny | Allow | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.command` | `tts-service` | Deny | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.decision` | `orchestrator-service` | Allow | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.decision` | `tts-service` | Deny | Allow | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.decision` | `asr-service` | Deny | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |
| `speech.orchestration.decision` | `translation-service` | Deny | Deny | Internal cluster network boundary (`speech_net` overlay/bridge), no public listener exposure for service traffic | Non-listed identities: denied |

## Deny-by-default

- Deny-by-default posture applies to all orchestration topics.
- Non-listed identities: denied for publish and consume operations.
