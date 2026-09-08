# TOPUP / SSZ closure verification

- Base SHA: `741f836990e2e0ba97708b5b53c81f2c8b22bbb5`
- Base first parent: `141af3330c222c39c59cd5271764bdfc364e3731`
- Branch: `codex/topup-ssz-closure`
- Toolchain observed: `Lake version 5.0.0-src+68218e8 (Lean version 4.31.0)`.

Executed after joining the source-byte beacon path, all with exit 0:

```text
/root/.elan/toolchains/leanprover--lean4---v4.31.0/bin/lake build LidoSRv3.Audit.Verity.TopupTx
```

## Result: source-to-executed-call gaps closed

`TopupTx.beaconPush_binds_source_ssz_fields` proves the live input against the
independent pinned `PinnedMakeBeaconChainTopUpFields` transcription. It binds
router WC after `setType`, the corresponding `_pubkeys[i]`, the 96-byte zero
dummy signature, the gwei amount, the computed SSZ root width, and exact
32/48/96-byte field widths. It is not `rfl` against the call encoder.

The registered executor now composes the corrections:

1. `executeGuarded` reaches `guardedSourceStage`, which invokes
   `executeSourceDerived` on `sourceDeposits`. Those inputs are constructed
   from router-state WC plus credential type, the exact `_pubkeys` array, the
   fixed dummy signature, and the journalled module returndata. Malformed
   bytes32/48-byte inputs and non-octets fail before execution.
2. The module frame's `allocateCalldata` now contains selector `0x783b8a65`,
   a five-word ABI head, dynamic offsets, a canonical `bytes[]` tail for
   public keys (including element offsets/length/padding), and canonical
   `uint256[]` tails for key indices, operator IDs, and limits. It is no
   longer the former length-prefixed flattening abstraction.

The beacon literal remains a source pin only. `A-TOPUP-BEACON-ADDRESS` remains
OPEN: the supplied `StakingRouter` constructor fixture (88--99) assigns
`DEPOSIT_CONTRACT` from `_depositContract`, but this proof has no deployment
input or constructor execution that derives the runtime address.

The only remaining item recorded here is constructor/deployment provenance for
`DEPOSIT_CONTRACT` (`A-TOPUP-BEACON-ADDRESS`).
