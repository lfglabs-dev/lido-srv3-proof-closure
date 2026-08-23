import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositNFrameTx

/-!
# P-DEPOSIT-1 n-frame kill-line

Parent-shaped: every premise of
`verity_tx_composes_nframe_deposit` is retained, and only `execute` is
replaced by the fixed-arity-2 mutant `executeTwoOnly` (the fold that
drops the tail).  On the 3-batch canonical witness the mutant journal
is two-legged, so the inductive journal / arity-n conjunct fails.
-/

namespace LidoSRv3.Tests.DepositNFrameTxMutants

open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Verity.DepositParentTx (observe)
open LidoSRv3.Audit.Verity.DepositNFrameTx

/-- Parent-shaped kill-line.  The statement is the n-frame parent's
inductive-journal conjunct with `executeTwoOnly` substituted for
`execute`.  Premises (`LinksSourceN`, `Preconditions`) are retained.
The 3-batch canonical witness refutes it: the mutant observes a
two-leg journal, not the arity-3 `sourceObservables`. -/
theorem executeTwoOnly_refutes_nframe_parent :
    ¬ (∀ (cfg : SourceDepositConfig) (inp : SourceDepositInput)
        (inputs : Inputs) (entry : _root_.Verity.ContractState),
          LinksSourceN cfg inp inputs →
          Preconditions inputs entry →
            observe entry (probes inputs)
                ((executeTwoOnly inputs).run entry)
              = sourceObservables inputs entry) := by
  intro derived
  have h :=
    derived canonicalSourceConfig nframeCanonicalSourceInput
      canonicalInputs canonicalState nframe_canonical_links
      canonical_preconditions
  have hTake :=
    execute_observes_source canonicalTakeTwo canonicalState
      canonicalTakeTwo_preconditions
  have hNames :
      (observe canonicalState (probes canonicalInputs)
          ((executeTwoOnly canonicalInputs).run canonicalState)).callNames
        = (sourceObservables canonicalTakeTwo canonicalState).callNames := by
    rw [executeTwoOnly_canonical]
    have hIndep :=
      observe_callNames_independent_of_probes canonicalState
        (probes canonicalInputs) (probes canonicalTakeTwo)
        ((execute canonicalTakeTwo).run canonicalState)
    exact hIndep.trans (congrArg (fun o => o.callNames) hTake)
  have h3 := executeTwoOnly_drops_tail_journal.1
  have h2 := executeTwoOnly_drops_tail_journal.2.1
  have hNe :
      (sourceObservables canonicalInputs canonicalState).callNames
        ≠ (sourceObservables canonicalTakeTwo canonicalState).callNames := by
    rw [h3, h2]
    decide
  have hContra :
      (observe canonicalState (probes canonicalInputs)
          ((executeTwoOnly canonicalInputs).run canonicalState)).callNames
        ≠ (sourceObservables canonicalInputs canonicalState).callNames := by
    intro hEq
    exact hNe (hEq.symm.trans hNames)
  exact hContra (congrArg (fun o => o.callNames) h)

/-- Non-vacuity of the kill-line: the honest n-frame parent holds on the
same 3-batch witness where the arity-2 mutant fails. -/
theorem honest_nframe_holds_where_mutant_fails :
    observe canonicalState (probes canonicalInputs)
        ((execute canonicalInputs).run canonicalState)
      = sourceObservables canonicalInputs canonicalState ∧
      (probes canonicalInputs).length = 3 ∧
      ((expectedCalls canonicalInputs).filter
          (fun c => decide (c.name = "depositToBeacon"))).length = 3 ∧
      (sourceObservables canonicalInputs canonicalState).callNames
        ≠ (sourceObservables canonicalTakeTwo canonicalState).callNames := by
  refine ⟨canonical_observes_source, rfl, depositToBeacon_count canonicalInputs, ?_⟩
  have h3 := executeTwoOnly_drops_tail_journal.1
  have h2 := executeTwoOnly_drops_tail_journal.2.1
  rw [h3, h2]
  decide

end LidoSRv3.Tests.DepositNFrameTxMutants
