/-! # StakingRouter.deposit distinct-modules source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
StakingRouter.deposit single-module-per-call semantics as a source-
level guard.)**

Chantier: grok differential #412 flags D-NFRAME-1 — the pinned
`StakingRouter.deposit` admits one module per call (a single
`stakingModuleId` parameter). Verity `DepositNFrameTx` is a list
lift over `batches`; the `distinctModules` constraint sits in
`Preconditions`, not in `execute` as an executable guard. Duplicate
module ids therefore break the parent premise silently rather than
reverting in-body.

This composition names an in-body executable guard as a source-
level function of a `List Nat` batch module-ids: `distinctModules l
= true iff l has no repeated entries`. Real derivation from a
canonical `List.Nodup`-analog check.

Pinned Solidity (17005714):

- `StakingRouter.sol:686-716`: `deposit(uint256 stakingModuleId, ...)`
  takes exactly one module id per call; the list-lift is a
  higher-level convenience for the Verity plane.

**Status:** first real derivation naming the D-NFRAME-1 divergence
(grok #412) as a source-level guard. -/

namespace LidoSRv3.Audit.Source.DepositDistinctModulesSource

/-- Definition of the source-level `distinctModules` executable guard:
`true` iff no module id appears twice in the batch list. -/
def distinctModules (moduleIds : List Nat) : Bool :=
  match moduleIds with
  | [] => true
  | id :: rest => decide (id ∉ rest) && distinctModules rest

/-- Under the pinned single-module premise (a list of length ≤ 1),
`distinctModules` returns `true`. -/
theorem distinctModules_true_of_singleton (id : Nat) :
    distinctModules [id] = true := by
  simp [distinctModules]

/-- Under the pinned empty premise (no batch — the empty-batch path
that hits the line-978 early return), `distinctModules` returns
`true`. -/
theorem distinctModules_true_of_empty :
    distinctModules [] = true := by
  simp [distinctModules]

/-- A cons preserves distinctness iff the head is fresh and the
tail is itself distinct. -/
theorem distinctModules_cons (id : Nat) (rest : List Nat) :
    distinctModules (id :: rest) =
      (decide (id ∉ rest) && distinctModules rest) := by
  simp [distinctModules]

end LidoSRv3.Audit.Source.DepositDistinctModulesSource
