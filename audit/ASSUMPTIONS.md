<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->
# Assumptions

## SRV3-ALLOC-ORDER

- Allocation inputs are source-shaped data, not extracted Solidity state.

## SRV3-ARITH-CHECKED

- Quantity bounds and units are model inputs; Solidity correspondence remains unproved.

## SRV3-CONSOLIDATION-E2E

- Mock-derived helper evidence is non-production evidence.

## SRV3-EVM-RUNTIME

- Current consolidation helper uses a Mock build and cannot establish production runtime identity.

## SRV3-LEGACY-ECON

- Legacy pure model is not a Solidity or deployed-bytecode correspondence proof.

## SRV3-MINFIRST-BOUND

- The handwritten MinFirst model has no established Solidity/EVM equivalence in M0.

## SRV3-SHA256-PRECOMPILE

- SHA-256 precompile hashing currently relies on opaque native FFI.

## SRV3-SOLIDITY-CORR

- Verity 4.31 is a non-certified development scaffold.
- Verity applies only to applicable Solidity/model components.

## SRV3-TX-REVERT

- TxObservation is an abstract transaction model, not an EVM execution trace.

## SRV3-VERITY-431

- Pinned target is explicitly non-certified and is not used by this Lean 4.24 M0 branch.

## SRV3-YUL-COMP

- Handwritten Yul/direct bytecode must not receive a fabricated Verity projection.
