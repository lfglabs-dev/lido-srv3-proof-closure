# TOPUP / SSZ closure verification

- Base SHA: `741f836990e2e0ba97708b5b53c81f2c8b22bbb5`
- Base first parent: `141af3330c222c39c59cd5271764bdfc364e3731`
- Branch: `codex/topup-ssz-closure`
- Toolchain observed: `Lake version 5.0.0-src+68218e8 (Lean version 4.31.0)`.

Executed after the source-provenance counterexample change, all with exit 0:

```text
/root/.elan/toolchains/leanprover--lean4---v4.31.0/bin/lake build LidoSRv3.Audit.Verity.TopupTx
```

## Result: TOPUP remains OPEN

This revision does **not** claim TOPUP delivered. It proves a concrete block on
the current derivation: `TopupTx.scheduledDeposit_not_sourceDerived` constructs
a byte-valid source deposit input with a nonzero public-key commitment, while
the legacy `scheduledDeposit 0 0` necessarily emits public-key word zero. The
current executable accepts only allocation amounts and therefore cannot derive
the public key, withdrawal credentials, signature, or SSZ deposit-data root
that `BeaconChainDepositor.makeBeaconChainTopUp` passes to `deposit`.

The module `allocateDeposits` journal is also deliberately a length-prefixed
word abstraction, not canonical Solidity ABI encoding with a selector, heads,
and dynamic offsets. No ABI-fidelity conclusion is made from it.

The beacon literal remains a source pin only. `A-TOPUP-BEACON-ADDRESS` remains
OPEN: the supplied constructor fixture shows assignment from `_depositContract`,
but this proof has no deployment input or constructor execution that derives
the runtime address. SSZ field/root provenance remains OPEN for the same reason:
the source-shaped SSZ model can construct a field-derived call value, but the
executed TOPUP transaction does not consume that input.

To close these items, replace the allocation-only transaction input with a
source-byte deposit batch, implement canonical ABI calldata, execute the
source-derived field/root construction through the beacon frame, and supply a
deployment/constructor provenance path for `DEPOSIT_CONTRACT`.
