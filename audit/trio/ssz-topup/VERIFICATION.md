# TOPUP / SSZ closure verification

- Base SHA: `741f836990e2e0ba97708b5b53c81f2c8b22bbb5`
- Base first parent: `141af3330c222c39c59cd5271764bdfc364e3731`
- Branch: `codex/topup-ssz-closure`
- Toolchain observed: `Lake version 5.0.0-src+68218e8 (Lean version 4.31.0)`.

Executed after the source-byte beacon and canonical ABI change, all with exit 0:

```text
/root/.elan/toolchains/leanprover--lean4---v4.31.0/bin/lake build LidoSRv3.Audit.Verity.TopupTx
```

## Result: TOPUP remains OPEN

This revision does **not** claim TOPUP delivered. It preserves the concrete
block on the legacy allocation-only derivation:
`TopupTx.scheduledDeposit_not_sourceDerived` constructs a byte-valid source
deposit input with a nonzero public key while legacy `scheduledDeposit 0 0`
emits public-key word zero.

There are now two explicit executable corrections, neither silently promoted
into the old theorem:

1. `TopupTx.executeSourceDerived` / `sourcePushLoop` takes
   `SourceDepositDataRootInput` per validator, requires source amount-gwei
   agreement and exact key/allocation cardinality, and calls
   `TopupTx.beaconPush`. Its `deposit(bytes,bytes,bytes,bytes32)` calldata has
   dynamic byte tails and offsets; public key, withdrawal credentials and
   signature come from that one source input, while the root comes from the
   pinned `_computeDepositDataRootWithAmount` computation on it. It never
   calls `scheduledDeposit`.
2. The module frame's `allocateCalldata` now contains selector `0x783b8a65`,
   a five-word ABI head, dynamic offsets, a canonical `bytes[]` tail for
   public keys (including element offsets/length/padding), and canonical
   `uint256[]` tails for key indices, operator IDs, and limits. It is no
   longer the former length-prefixed flattening abstraction.

The remaining join is deliberately OPEN: no theorem derives the source-byte
batch consumed by `executeSourceDerived` from the pinned router/gateway
transaction inputs and the `allocateDeposits` returndata. The registered
parent continues to use the legacy allocation-only execution, so the new
source-byte plane is not an end-to-end delivery claim.

The beacon literal remains a source pin only. `A-TOPUP-BEACON-ADDRESS` remains
OPEN: the supplied `StakingRouter` constructor fixture (88--99) assigns
`DEPOSIT_CONTRACT` from `_depositContract`, but this proof has no deployment
input or constructor execution that derives the runtime address.

To close these items, compose the source-byte batch with the pinned public
router/gateway inputs and module returndata, then model the constructor and
deployment provenance path for `DEPOSIT_CONTRACT`.
