# TOPUP / SSZ closure verification

- Base SHA: `741f836990e2e0ba97708b5b53c81f2c8b22bbb5`
- Base first parent: `141af3330c222c39c59cd5271764bdfc364e3731`
- Branch: `codex/topup-ssz-closure`
- Toolchain observed: `Lake version 5.0.0-src+68218e8 (Lean version 4.31.0)`.

Executed in the clean worktree, all with exit 0:

```text
lake env lean LidoSRv3/Audit/Verity/TopupTx.lean
lake env lean LidoSRv3/Audit/Guarantees/PTopup1.lean
lake env lean LidoSRv3/Tests/TopupTxMutants.lean
lake build LidoSRv3.Audit.Guarantees.PTopup1
```

The beacon literal remains a source pin only. `A-TOPUP-BEACON-ADDRESS`
remains OPEN: this closure does not model a deployment constructor assignment.
