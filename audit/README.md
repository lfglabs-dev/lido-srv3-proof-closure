# Audit control registry

`invariants.yaml` is the sole editable invariant truth. It intentionally uses
the JSON-compatible subset of YAML so the validator needs only Python's
standard library. `schema.json`, `dependencies.lock.json`, and `artifacts.json`
define its format, exact dependency topology, and available artifact hashes.
`external-source-targets.json` is the network-independent inventory of external
suffix targets verified at those exact dependency commits.

Run:

```sh
python3 scripts/audit_registry.py check
python3 scripts/audit_registry.py generate
python3 scripts/audit_registry.py test-negative
```

All `BY_*.md`, trust/assumption/reproduction views, and `MATRIX.csv` are
generated and must not be edited.
