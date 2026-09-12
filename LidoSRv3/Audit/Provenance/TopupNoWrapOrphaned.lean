import LidoSRv3.Audit.Guarantees.PTopup1

/-!
# A-TOPUP-NOWRAP is orphaned from the registered P-TOPUP-1 parents

The registered P-TOPUP-1 theorems
`LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back`
and
`LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close`
do **not** consume the caller-supplied premise `NoUncheckedWrap inp`.

- The source-side parent proves `WrapMovesNoValue cfg inp` as a **conclusion**
  (via `source_wrap_precludes_value_moving_commit`), not as a premise. Its
  proof term goes through `run_conserves`, `reverting_outcome_rolls_back`,
  `source_module_guard_required`, `source_wrap_precludes_value_moving_commit`,
  `source_wc_type2_guard_required`, `source_allocation_guards_required`,
  `source_over_target_guard_required` — none of which are premised on
  `NoUncheckedWrap`.
- The Verity-side parent takes `SourceTopupCallCorresponds cfg inp call`,
  the call, and the contract state; the discharge goes through
  `executeGuarded_binds_returndata`, `executeGuarded_reverts_on_*`, and
  the guarded-simulation family, none of which are premised on
  `NoUncheckedWrap`.

The theorems below exhibit the proof: for **any** wrapping input (i.e.
`¬ NoUncheckedWrap inp`) the parent conclusion still fires. The
`NoUncheckedWrap` premise is ignored by the parent's proof term.

This documents that `A-TOPUP-NOWRAP` is orphaned from the two registered
parents. The full retirement of the assumption from
`audit/assumptions.yaml` and from `P-TOPUP-1`'s assumption list in
`audit/guarantees.yaml` requires the R1 review basis to advance and is
therefore a policy decision, not a mechanical follow-up. See
`audit/findings/A-TOPUP-NOWRAP-orphaned.md` for the reproduction.

The `A-TOPUP-NOWRAP` registry text itself already records this fact:
"the current P-TOPUP-1 parent explicitly models wrapping and does not
require a general no-wrap premise" and its removal_path is "Review each
consuming theorem before removing this registry identifier."
-/

namespace LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned

open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Guarantees.PTopup1

/-- The registered source parent's conclusion holds on **any** input,
including inputs that violate `NoUncheckedWrap`. The `hWrap` hypothesis is
introduced only to make the orphanage explicit — the parent's proof term
ignores it. -/
theorem source_parent_ignores_no_unchecked_wrap
    {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace)
    (_hWrap : ¬ NoUncheckedWrap inp) :
    ConservesAndRollsBack cfg inp before after attempts trace ∧
      UnregisteredModuleReverts cfg inp ∧
      WrapMovesNoValue cfg inp ∧
      WrongWcTypeReverts cfg inp ∧
      RunFollowsAllocationLoop cfg inp :=
  PTopup1.source_topup_conserves_and_rolls_back cfg inp before after attempts trace

/-- Same statement without the ignored `hWrap` hypothesis: the parent applies
to every input, wrapping or not. -/
theorem source_parent_applies_universally
    {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    ConservesAndRollsBack cfg inp before after attempts trace ∧
      UnregisteredModuleReverts cfg inp ∧
      WrapMovesNoValue cfg inp ∧
      WrongWcTypeReverts cfg inp ∧
      RunFollowsAllocationLoop cfg inp :=
  PTopup1.source_topup_conserves_and_rolls_back cfg inp before after attempts trace

/-- The registered Verity-side parent's first two conjuncts hold on **any**
input: the `hCall : SourceTopupCallCorresponds cfg inp call` premise is the
call-shape correspondence, not a `NoUncheckedWrap` premise. Chantier 2
(mandate 2026-09-12): the parent's ENUNCE now has four conjuncts; this
orphelinat projects the first two to match the historical no-wrap-orphan
shape and is retained as unregistered structural evidence only. -/
theorem verity_parent_ignores_no_unchecked_wrap
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (call : Verity.TopupTx.TopupCall)
    (state : Verity.ContractState)
    (hCall : SourceTopupCallCorresponds cfg inp call)
    (_hWrap : ¬ NoUncheckedWrap inp) :
    SourceTopupCallCorresponds cfg inp call ∧
      VerityGuardedReturndataSimulation cfg call state :=
  let ⟨h1, h2, _, _⟩ :=
    PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close cfg inp call state hCall
  ⟨h1, h2⟩

end LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned
