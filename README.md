# Scryer Local Harness

This folder owns the local Scryer control plane for this machine.

Primary command:

```bash
scryer up
```

Phase one starts the operator interface:

- PM backend on `http://127.0.0.1:43210`
- Loom UI on `http://127.0.0.1:43211`

The desktop launcher and CLI both call the same script: `bin/scryer`.

See `docs/PORTS.md` for the permanent `43200-43299` port reservation.
