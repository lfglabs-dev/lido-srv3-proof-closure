# P-CONSOLIDATION-1 Verity framework gaps

Re-assessed at the currently pinned Verity head
`04729a9de9099e065dd09283e4f733a5fd4c2a16`.

The previous revision of this file was written against pin
`f485b2ca7502793ce227ede0076b7d070a0697b7` and was never refreshed across the
two intervening re-pins.  Two of its six items had since moved, so the document
was overstating the blocker set.  It is restated below against the current pin,
and the load-bearing item is now backed by machine-checked theorems in
`LidoSRv3/Audit/Verity/ConsolidationCallFragment.lean` rather than by prose, so
that it cannot go stale silently again.

P-CONSOLIDATION-1 remains `theorem: null`, `theorem_planes: []`, transaction
plane OPEN.  Nothing below closes a plane.

## Item 1 — event/log observation: PARTIALLY CLOSED

Still true for the external-call plane: `CallProgram`
(`Verity/Core/Model/DenoteExternalCalls.lean:162`) has only `pure` and `bind`
over a `CallSite`, with no log instruction, and `CallState` (`:114`) carries
only `world`, `gasRemaining`, `returndata`.

No longer true for the `FunctionSpec` plane: `Stmt.emit` has a real denotation
arm (`Verity/Core/Model/Denote.lean:1342-1353`) appending to
`world.events`, and `DenoteResult.events` (`Denote.lean:1405`) observes it.
Caveats: the semantics are event-*less* in the sense that `indexedArgs := []`
always, so topics and `EventDef` encoding are not modelled
(`Denote.lean:39-45`), and `Stmt.rawLog` (`Types.lean:1122`) has no arm.

## Item 2 — `FunctionSpec` to `CallProgram`: STILL OPEN, and load-bearing

This is the item that blocks the transaction plane, and it is now pinned by
theorem rather than by assertion.

The pinned deep EDSL does have first-class external calls: `Expr.call`,
`Expr.staticcall`, `Expr.delegatecall` (`Types.lean:744`, `:747`, `:750`) and
`Stmt.externalCallBind`, `Stmt.tryExternalCallBind`, `Stmt.ecm`
(`Types.lean:1125`, `:1133`, `:1141`).

The official denotation implements **none** of them.  Each falls through to
`| _ => none` (`Denote.lean:1030`) or `| _, _ => .revert`
(`Denote.lean:1371`); the upstream header states this outright
(`Denote.lean:55-62`).  There is no definition or theorem anywhere in the
package mentioning both `denoteFunction`/`FunctionSpec` and `CallProgram`.
`denoteNonCall` (`DenoteExternalCalls.lean:404`) is a re-export of
`execStmtList` whose `denotation_eq` (`:414`) is `rfl`; it never produces a
`CallSite` and supplies no connection.

An EIP-7251 consolidation request is irreducibly an external call.  The raw
fragment names the call's `[0, 96)` input window but performs no memory writes,
so it does **not** claim that `source ‖ target` reaches the predeploy.  Its exact
result is narrower: under the official denotation the unsupported `Expr.call`
denotes as **unconditional revert irrespective of payload preparation**.
Machine-checked at this head:

- `ConsolidationCallFragment.raw_call_entrypoint_always_reverts` — for every
  oracle, transaction and world, the `Expr.call` entrypoint reports failure.
- `ConsolidationCallFragment.external_call_bind_entrypoint_always_reverts` —
  likewise for the `Stmt.externalCallBind` formulation; that function is now
  included in `spec.functions`.
- `ConsolidationCallFragment.requestConsolidationBind_registered`,
  the official-compiler `#guard` over that registered list element, and
  `registered_external_call_bind_entrypoint_always_reverts` — membership,
  official compilation, and denotation of the registered bind entrypoint,
  without accepting an arbitrary caller-supplied `FunctionSpec`.
- `ConsolidationCallFragment.guards_only_succeeds` — the identically shaped
  entrypoint with the call deleted succeeds, so the revert is attributable to
  the call and not to the guards or to calldata decoding.
- `ConsolidationCallFragment.success_hypotheses_are_vacuous` — for an arbitrary
  predicate `P`, `success = true → P` is derivable.  Any consolidation
  transaction claim phrased as an implication out of success is therefore
  contentless.

**Consequence for reviewers.** A PR that exhibits a consolidation
`FunctionSpec` and proves properties conditioned on successful execution has
proved nothing: the hypothesis is provably false.  Such a PR must not be
accepted as transaction-plane evidence.

## Item 3 — `DenoteMemory`: STILL OPEN

`Verity/Core/Model/DenoteMemory.lean` is a real byte-precise model
(`Memory.bytes : Nat → Byte`, `:39`), but it is not in `denoteFunction`'s
import closure; its only importer is `Contracts/Examples/DenoteMemory.lean`.
Inside `denoteFunction` memory is word-per-offset (`Denote.lean:1010-1012`),
which the `DenoteMemory` header itself flags as unfaithful (`:20-22`).
`Stmt.calldatacopy` and `Stmt.returndataCopy` have no arms, and dynamic
`bytes[]` loading is explicitly outside the fragment (`Denote.lean:52-56`).

## Item 4 — transaction-frame rollback: PARTIALLY CLOSED upstream; LOCAL COMPOSITION OPEN

`denoteTransaction` (`Verity/Core/Model/CallProgramRollback.lean:74`) is the
transaction-frame operator: on `.revert` it restores `world`, discarding
committed mutable calls.  The strong law
`forEachCall_abort_discards_committed_prefix` (`:322-339`) additionally pins
the discarded intermediate world to `commitWorlds … (CallsIn …)`, so it is not
satisfiable by a trivial wrapper.  Separately, `denoteFunction` reverts to
`worldWithTx` (`Denote.lean:1496`), restoring storage *and* events.

The local consolidation evidence does not consume that operator. Its separate
handwritten `CallProgram` still proves only all-observed-calls rollback, and no
theorem connects that program to the `FunctionSpec`. Thus the upstream
primitive is available, but parent atomicity and transaction-frame composition
remain open here; this item must not be read as a P-CONSOLIDATION-1 closure.

Caveat: `denoteTransaction` is built on `denote`, not `denoteJournaled`, so a
top-level revert also erases `ContractState.calls`.

## Item 5 — `preservesEthBalance` / self-balance: PARTIALLY CLOSED

`Expr.selfBalance` is readable (`Denote.lean:751`) but inert:
`withTransactionContext` (`Denote.lean:1466-1478`) never sets it, and
`selfBalance` does not occur anywhere in `DenoteExternalCalls.lean` or
`CallProgramRollback.lean`.  `AdversaryModel.stateTransition`
(`DenoteExternalCalls.lean:125`) may change it arbitrarily with no constraining
law, so no self-balance-versus-external-call invariant is available.

## Item 6 — local-obligation statuses: STILL OPEN

Unchanged: local-obligation statuses are metadata and do not accept a theorem
witness, so the dynamic ABI loader obligation remains `unchecked`.

## Vacuous stubs that must not be built on

All in `Contracts/Common.lean` at this pin.  External-call path:
`externalCallBind` `:582`, `safeTransfer` `:622`, `safeTransferFrom` `:623`,
`safeApprove` `:624`, `legacyStringSafeTransfer` `:625`,
`legacyStringSafeTransferFrom` `:626` — all `pure ()`; `tryExternalCallWords`
`:580` is `pure (false, default)`.  Memory/return path: `calldatacopy` `:408`,
`returndataCopy` `:409`, `revertReturndata` `:410`, `returnValues` `:442`,
`mstore` `:496`.  Storage path: `getMappingWord` `:599` and `getMappingN` `:603`
return `pure 0`; `setMappingWord` `:601`, `setMappingN` `:605`,
`setStructMember` `:618`, `setStructMember2` `:620` are `pure ()`.

A conservation or rollback statement routed through any of these holds for
every pre- and post-state and is not evidence.

## What could honestly be attempted next

- In the `CallProgram` plane only: a Lido-shaped atomicity property built
  directly on `forEachCall` and `denoteTransaction`, discharged through
  `forEachCall_abort_discards_committed_prefix`, with hypotheses stated over
  `ObservedCalls`/`CallsIn`.
- In the `denoteFunction` plane only: storage-and-event refinement for
  call-free, memory-light entrypoints, including revert restoring both storage
  and the event list.

Neither yields a consolidation transaction closure while item 2 stands.  The
two planes remain entirely unconnected, and that connection — not the
consolidation model itself — is the gate.
