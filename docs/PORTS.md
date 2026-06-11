# Scryer Local Harness Reserved Ports

The entire `43200-43299` range is permanently reserved for the local Scryer harness on this machine.

Do not use any port in this range for unrelated development servers, previews, experiments, one-off services, tunnels, database UIs, or scratch processes.

## Allocations

| Port | Service | Status |
|---:|---|---|
| 43210 | PM backend (`just-enuf-pm`) | active |
| 43211 | Loom UI | active |
| 43212 | Scryer orchestrator | reserved |
| 43213 | Tmuxer | reserved |
| 43214 | Vault / secrets | reserved |
| 43215 | Interaction service | reserved |
| 43216 | STT / voice | reserved |
| 43217-43299 | Future Scryer harness services only | reserved |

## Rule

If a port in `43200-43299` is occupied, it must be occupied by a known Scryer harness service. `scryer up` should refuse to start when it detects an unknown listener in this range.
