import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Source.DepositCorrespondence

/-!
# Leftover J-DEPOSIT: Spec.EthJournal projection of deposit ETH

Unregistered child. It does not replace the registered P-DEPOSIT-1
parent, does not discharge `LinksSource`, does not merge ALLOC into
DEPOSIT, does not add VaultHub, and does not invent a guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Common
open LidoSRv3.Audit.Verity.DepositParentTx
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.SolidityDeposit

/-- Deposit-success destinations only. Consolidation and refund Spec tags
are approved for the consolidation journal, not for the Join deposit
success journal. -/
def isDepositSuccessDest : ApprovedDestination → Bool
  | .lidoPull | .beaconDeposit => true
  | .consolidationRequest | .refundRecipient => false

/-- Source-level destinations of value-moving deposit legs. Residual tags
have no Spec destination. The two `obtainDepositData` frames are not
value-moving ETH legs and are not represented here. -/
inductive DepositSourceDest
  | lidoWithdraw
  | beaconPush
  | residual (tag : Nat)
  deriving DecidableEq, Repr

structure DepositValueLeg where
  dest : DepositSourceDest
  wei : Nat
  deriving DecidableEq, Repr

def specDest : DepositSourceDest → Option ApprovedDestination
  | .lidoWithdraw => some .lidoPull
  | .beaconPush => some .beaconDeposit
  | .residual _ => none

def specOfMove (m : DepositValueLeg) : Option EthJournalLeg :=
  match specDest m.dest with
  | some dest => some { dest := dest, wei := ⟨m.wei⟩ }
  | none => none

def specJournal (moves : List DepositValueLeg) : EthJournal :=
  moves.filterMap specOfMove

/-- Honest two-batch success journal. The Lido pull is value 0 on the
`withdrawDepositableEther` call (credit is explicit) and is still
projected as `lidoPull` with wei = `pulled` / `totalAmount`. Each
`depositToBeacon` is `beaconDeposit` with wei = `batch.amount`. -/
def specJournalOfDeposit (inputs : Inputs) : EthJournal :=
  [{ dest := .lidoPull, wei := ⟨(totalAmount inputs).val⟩ },
   { dest := .beaconDeposit, wei := ⟨inputs.first.amount.val⟩ },
   { dest := .beaconDeposit, wei := ⟨inputs.second.amount.val⟩ }]

def honestDepositLegs (inputs : Inputs) : List DepositValueLeg :=
  [{ dest := .lidoWithdraw, wei := (totalAmount inputs).val },
   { dest := .beaconPush, wei := inputs.first.amount.val },
   { dest := .beaconPush, wei := inputs.second.amount.val }]

theorem specDest_lidoWithdraw : specDest .lidoWithdraw = some .lidoPull := rfl

theorem specDest_beaconPush : specDest .beaconPush = some .beaconDeposit := rfl

theorem specDest_residual (tag : Nat) : specDest (.residual tag) = none := rfl

theorem isDepositSuccessDest_lidoPull :
    isDepositSuccessDest .lidoPull = true := rfl

theorem isDepositSuccessDest_beaconDeposit :
    isDepositSuccessDest .beaconDeposit = true := rfl

theorem isDepositSuccessDest_consolidation :
    isDepositSuccessDest .consolidationRequest = false := rfl

theorem isDepositSuccessDest_refund :
    isDepositSuccessDest .refundRecipient = false := rfl

/-- If every value-moving deposit leg has a Spec destination, the Spec
journal preserves amounts in order. -/
theorem specJournal_amounts_of_projected
    (moves : List DepositValueLeg)
    (h : ∀ m, m ∈ moves → specDest m.dest ≠ none) :
    (specJournal moves).map (fun leg => leg.wei.value) = moves.map DepositValueLeg.wei := by
  induction moves with
  | nil => simp [specJournal]
  | cons m ms ih =>
      have hm : specDest m.dest ≠ none :=
        h m (List.mem_cons.mpr (Or.inl rfl))
      have hms : ∀ x, x ∈ ms → specDest x.dest ≠ none := fun x hx =>
        h x (List.mem_cons.mpr (Or.inr hx))
      cases hDest : specDest m.dest with
      | none => exact absurd hDest hm
      | some dest =>
          simp [specJournal, specOfMove, hDest] at *
          exact ih hms

theorem specJournal_of_honest_legs (inputs : Inputs) :
    specJournal (honestDepositLegs inputs) = specJournalOfDeposit inputs := rfl

/-- Unregistered child: the two-batch committing deposit projects onto
`Spec.EthJournal`. Destinations are only the Join deposit approvals;
Spec wei amounts are the Lido pull (`pulled` / `totalAmount`) and the
two beacon batch amounts. `LinksSource` is not a hypothesis here. -/
theorem deposit_success_journal_projects_to_spec (inputs : Inputs) :
    (specJournalOfDeposit inputs).map (fun leg => leg.wei.value) =
      [(totalAmount inputs).val, inputs.first.amount.val, inputs.second.amount.val] ∧
    (specJournalOfDeposit inputs).map (fun leg => leg.dest) =
      [.lidoPull, .beaconDeposit, .beaconDeposit] ∧
    (∀ leg, leg ∈ specJournalOfDeposit inputs → isDepositSuccessDest leg.dest = true) := by
  simp [specJournalOfDeposit, isDepositSuccessDest]

/-- Same projection, named against `sourceObservables`: pull wei is
`pulled`, not the zero-value withdraw call. The two
`obtainDepositData` frames stay off the Spec journal. -/
theorem deposit_success_journal_matches_source_observables
    (inputs : Inputs) (before : _root_.Verity.ContractState) :
    let obs := sourceObservables inputs before
    (specJournalOfDeposit inputs).map (fun leg => leg.wei.value) =
      [obs.pulled, inputs.first.amount.val, inputs.second.amount.val] ∧
    obs.callNames =
      ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
       "depositToBeacon", "depositToBeacon"] ∧
    obs.callValues =
      [0, 0, 0, inputs.first.amount.val, inputs.second.amount.val] := by
  simp [specJournalOfDeposit, sourceObservables]

/-- Named `LinksSource` child, kept as a hypothesis: pulled / total equals
the two batch amounts, and those amounts are `keys * depositSize`.
Not a parent conjunct; ALLOC is not merged into DEPOSIT. -/
theorem deposit_pulled_eq_batch_amounts_under_linkssource
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs)
    (hLink : PDeposit1.LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus) :
    (totalAmount inputs).val = inputs.first.amount.val + inputs.second.amount.val ∧
      inputs.first.amount.val + inputs.second.amount.val =
        (inputs.first.keys.val + inputs.second.keys.val) * cfg.depositSize := by
  refine ⟨total_val inputs hNoWrap, ?_⟩
  rw [hLink.firstAmount, hLink.secondAmount, Nat.add_mul]

end LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence
