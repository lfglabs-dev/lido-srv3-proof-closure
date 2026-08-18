# P-CONSOLIDATION-1 Verity gaps

Parent P-CONSOLIDATION-1 is CHECKED on both planes via
`LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_simulates_consolidation`
(`Contract.run`, memory-array decode, journaled CALL/event observables,
`writeMapUint`/`writeSlot`). The notes below remain a historical record of
the official `denoteFunction` fragment; they are not parent blockers.

Assessed at Verity `04729a9de9099e065dd09283e4f733a5fd4c2a16`. The repo pin is
now `1fe0218863a4c8d6113e6cdd4de3766a54df81c7`; item 2 is still machine-checked
in `LidoSRv3/Audit/Verity/ConsolidationCallFragment.lean`.

## Item 1 — events: PARTIAL

`CallProgram` has `pure` and `bind` only. `CallState` has `world`,
`gasRemaining`, `returndata`. No log.

`FunctionSpec` `Stmt.emit` appends to `world.events`. `indexedArgs` is always
`[]`. `Stmt.rawLog` has no arm.

## Item 2 — `FunctionSpec` to `CallProgram`: OPEN, load-bearing

The EDSL has `Expr.call` / `staticcall` / `delegatecall` and
`Stmt.externalCallBind` / `tryExternalCallBind` / `ecm`.

Official denotation implements none of them. They become `none` or `.revert`.
No definition mentions both `denoteFunction` and `CallProgram`.

An EIP-7251 request is an external call. Under official denotation, `Expr.call`
reverts for every oracle, transaction, and world, whatever the payload.

Checked:

- `raw_call_entrypoint_always_reverts`
- `external_call_bind_entrypoint_always_reverts`
- `requestConsolidationBind_registered` and
  `registered_external_call_bind_entrypoint_always_reverts`
- `guards_only_succeeds` — same entrypoint without the call succeeds
- `success_hypotheses_are_vacuous` — `success = true → P` for any `P`

A proof that assumes consolidation success has proved nothing.

## Item 3 — `DenoteMemory`: OPEN

`DenoteMemory` is byte-precise and is not imported by `denoteFunction`.
`denoteFunction` uses one word per offset. `Stmt.calldatacopy` and
`returndataCopy` have no arms. Dynamic `bytes[]` is out of the fragment.

## Item 4 — transaction-frame rollback: CLOSED upstream, unused here

`denoteTransaction` restores `world` on revert.
`forEachCall_abort_discards_committed_prefix` names the discarded prefix.
`denoteFunction` reverts to `worldWithTx` (storage and events).

Local consolidation code does not use that operator. Parent atomicity stays
OPEN. `denoteTransaction` uses `denote`, not `denoteJournaled`, so a top-level
revert also drops `ContractState.calls`.

## Item 5 — `selfBalance`: PARTIAL

`Expr.selfBalance` is readable. `withTransactionContext` never sets it.
`AdversaryModel.stateTransition` may change it with no law.

## Item 6 — local-obligation statuses: OPEN

Statuses are metadata. They take no theorem. Dynamic ABI stays `unchecked`.

## Stubs that prove nothing

In `Contracts/Common.lean` at this assessment pin: `externalCallBind`,
`safeTransfer`, `safeTransferFrom`, `safeApprove`, and the legacy string
transfers are `pure ()`. `tryExternalCallWords` is `pure (false, default)`.
Several memory, return, and mapping helpers are `pure ()` or `pure 0`.

A conservation or rollback claim through these holds for every state.

## Honest next steps

- `CallProgram` only: atomicity on `forEachCall` / `denoteTransaction`.
- `denoteFunction` only: storage and events on call-free, memory-light
  entrypoints.

Neither closes consolidation while item 2 stands.
