import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.PTopup1

/-!
# Pack J-TOPUP: Spec.EthJournal projection of the top-up call journal

Unregistered child. It projects `TopupTx.sourceObservables` onto
`Spec.EthJournal` (`lidoPull` then `beaconDeposit`s). It does not replace
the registered P-TOPUP-1 parent, does not discharge `A-TOPUP-NOWRAP`, and
does not invent a guarantee ID. This is not all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Verity.TopupTx
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Guarantees

/-- Destinations this Join journal may name. Pack B consolidation tags
are out; VaultHub stays out. -/
def isTopupJournalDest : ApprovedDestination → Bool
  | .lidoPull | .beaconDeposit => true
  | _ => false

/-- Projection of the pinned top-up call journal onto `Spec.EthJournal`.

Value-moving success (`wrapped ≠ 0`) is one `lidoPull` of the wrapped
total followed by one `beaconDeposit` per nonzero `sourcePushes` amount.
Wrap-to-zero (and the ordinary zero batch) is the empty journal: the
source schedule skips the pull and every push. Call-value 0 on the Lido
hop is the frame; Spec wei on that hop is the pulled wrapped total. -/
def specJournalOfTopup (allocations : List Nat) : EthJournal :=
  let wrapped := allocSumUnchecked allocations
  let pushes := sourcePushes allocations 0
  if wrapped = 0 then []
  else { dest := .lidoPull, wei := ⟨wrapped⟩ } ::
       pushes.map (fun p => { dest := .beaconDeposit, wei := ⟨p.2⟩ })

/-- Every projected dest is a Join approval. -/
theorem specJournalOfTopup_dests_restricted (allocations : List Nat) :
    ∀ leg ∈ specJournalOfTopup allocations, isTopupJournalDest leg.dest = true := by
  intro leg hmem
  by_cases hZero : allocSumUnchecked allocations = 0
  · simp [specJournalOfTopup, hZero] at hmem
  · simp [specJournalOfTopup, hZero] at hmem
    rcases hmem with h | ⟨_, _, hp⟩
    · subst h; rfl
    · subst hp; rfl

/-- Concrete value-moving success: `[3, 0, 5]` wraps to 8, skips the zero
slot, and projects `lidoPull` then two `beaconDeposit`s. The source
observable names / targets / call-values are the journal this projects. -/
theorem topup_value_moving_journal_projects :
    let allocations := [3, 0, 5]
    let j := specJournalOfTopup allocations
    let obs := sourceObservables allocations
    j.map (·.dest) = [.lidoPull, .beaconDeposit, .beaconDeposit] ∧
      j.map (fun leg => leg.wei.value) = [8, 3, 5] ∧
      obs.callNames =
        ["withdrawDepositableEther", "makeBeaconChainTopUp", "makeBeaconChainTopUp"] ∧
      obs.callTargets =
        [lidoAddress.toNat, beaconAddress.toNat, beaconAddress.toNat] ∧
      obs.callValues = [0, 3, 5] := by
  native_decide

/-- Wrap-to-zero (or any unchecked total of 0) projects to the empty
journal. This does not discharge `A-TOPUP-NOWRAP`. -/
theorem topup_wrap_to_zero_journal_empty
    (allocations : List Nat)
    (hZero : allocSumUnchecked allocations = 0) :
    specJournalOfTopup allocations = [] := by
  simp [specJournalOfTopup, hZero]

/-- Registered parent wrap conjunct. Citation only: this node does not
re-prove wrap and does not discharge `A-TOPUP-NOWRAP`. -/
theorem wrap_precludes_value_moving_commit_parent
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hWrap : ¬ NoUncheckedWrap inp) :
    (run cfg inp).pulled = 0 ∧ (run cfg inp).pushed = 0 :=
  PTopup1.source_wrap_precludes_value_moving_commit cfg inp hWrap

end LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence
