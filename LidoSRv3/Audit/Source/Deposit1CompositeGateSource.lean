import LidoSRv3.Audit.Source.DepositEmptyBatchEarlyReturnSource
import LidoSRv3.Audit.Source.DepositPerKeyCallSource
import LidoSRv3.Audit.Source.DepositDistinctModulesSource

/-! # P-DEPOSIT-1 composite entry-gate source model

**General rule (Thomas 2026-09-13): compose the three P-DEPOSIT-1
divergence-derived source models (D-EMPTY-PULL shouldPull +
D-NFRAME-1 distinctModules + per-key deposit journal shape) into a
single named composite gate.**

Under the pinned entry-gate premises (nonzero deposits ⇒ pull;
per-module deposit is distinct; per-key journal follows pinned
shape), the composite derivation names the on-chain observable
plane's structure — no free Bool per key.

**Status:** first real composition of the three P-DEPOSIT-1
divergence-derived source models. -/

namespace LidoSRv3.Audit.Source.Deposit1CompositeGateSource

open LidoSRv3.Audit.Source.DepositEmptyBatchEarlyReturnSource
open LidoSRv3.Audit.Source.DepositPerKeyCallSource
open LidoSRv3.Audit.Source.DepositDistinctModulesSource

/-- Composite P-DEPOSIT-1 gate: batch is non-empty AND all module
IDs are distinct. -/
def entryGatePasses
    (actualDepositsCount : Nat) (moduleIds : List Nat) : Bool :=
  shouldPull actualDepositsCount && distinctModules moduleIds

/-- Under the pinned nonzero + distinct-modules premise, the gate
passes. -/
theorem entryGatePasses_true_of_premises
    {actualDepositsCount : Nat} {moduleIds : List Nat}
    (hCount : actualDepositsCount ≠ 0)
    (hDistinct : distinctModules moduleIds = true) :
    entryGatePasses actualDepositsCount moduleIds = true := by
  simp [entryGatePasses, shouldPull_true_of_nonzero hCount, hDistinct]

/-- The per-key journal length equals the pinned deposit count. -/
theorem journal_length_eq_deposit_count
    (actualDepositsCount : Nat) (moduleIds : List Nat) :
    entryGatePasses actualDepositsCount moduleIds = true →
    (perKeyDepositFrames actualDepositsCount).length = actualDepositsCount :=
  fun _ => perKeyDepositFrames_length actualDepositsCount

end LidoSRv3.Audit.Source.Deposit1CompositeGateSource
