# Audit control registry

`invariants.yaml` is the sole editable invariant truth. It intentionally uses
the JSON-compatible subset of YAML so the validator needs only Python's
standard library. `schema.json`, `dependencies.lock.json`, and `artifacts.json`
define its format, two-plane dependency topology, and available artifact hashes.
`external-source-targets.json` is the network-independent inventory of external
suffix targets verified at those exact dependency commits.

The active current plane is the repository root: Lean 4.24, Verity
`538c4a9ce2baa25b56062bdc727eb0191ad9e67f`, and its one inherited EVMYulLean
`38d53df8b4488d5322894619ea8385fcbb2e6f5d`. The proposed target plane is
immutable audit metadata in `target-4.31/`; it is not an active root
configuration. Its status is `DEV-431-READY`, target `PrintAxioms` is `FAIL`,
and `AUDIT-CERT=false`.

Run:

```sh
python3 scripts/audit_registry.py check
python3 scripts/audit_registry.py generate
python3 scripts/audit_registry.py test-negative
```

Those routine commands are deterministic and do not fetch remote provenance.
The explicit online gate verifies immutable Git identities without rewriting
inventories:

```sh
python3 scripts/audit_registry.py refresh-provenance
```

Run `python3 scripts/audit_registry.py check-lean` separately for the current
root theorem-name and `#print axioms` trust gate.

All `BY_*.md`, trust/assumption/reproduction views, and `MATRIX.csv` are
generated and must not be edited.
