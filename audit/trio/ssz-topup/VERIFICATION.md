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
OPEN. The exact address-determining Solidity span is `StakingRouter.sol:88-99`:
line 89 accepts `_depositContract`, line 95 checks only that it is nonzero, and
line 99 assigns it unchanged to `DEPOSIT_CONTRACT`. The executed path reads
that immutable at `StakingRouter.sol:750` and passes it through
`BeaconChainDepositor.makeBeaconChainTopUp` (`BeaconChainDepositor.sol:66-108`).

`PTopup1.pinned_constructor_span_does_not_determine_beacon_address` proves the
source-only obstruction with the admitted constructor value `0xDEAD`, and
`PTopup1.no_source_only_beacon_address_derivation` refutes the corresponding
universal source-only closure claim. The missing parent is explicitly
`A-RUNTIME-PROVENANCE`: deployment evidence binding the constructor argument
(or the deployed runtime immutable) to the canonical beacon deposit address.

The only remaining item recorded here is constructor/deployment provenance for
`DEPOSIT_CONTRACT` (`A-TOPUP-BEACON-ADDRESS`).
