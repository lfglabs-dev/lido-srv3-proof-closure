import LidoSRv3.Audit.Source.ReportRewardsMintedCorrespondence
import Verity.Core

/-! Executable model-local storage projection for the pinned mint consumer.
Slots below are model-local observations, not Solidity slot numbers. -/
namespace LidoSRv3.Audit.Verity.ReportRewardsMintedTx

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted

abbrev Word := Verity.Core.Uint256
def feesSlot : Nat := 40
def callbacksSlot : Nat := 41

structure Input where
  moduleIds : List Nat
  balances : List Nat
  moduleFeesWritten : List Nat
  sharesToMint : Nat
  outcomes : List CallbackOutcome
  deriving DecidableEq, Repr

structure Result where
  events : List LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted.Event
  distribution : FeeDistribution
  deriving DecidableEq, Repr

/-- SRLib 873-892 write followed by Accounting's 277 reader. -/
def routerSnapshot (i : Input) : RouterSnapshot :=
  writeValidatorBalances i.balances i.moduleFeesWritten

def reportRewardsMinted (i : Input) : Contract Result := fun state =>
  let dirty := state.writeArray feesSlot (i.moduleFeesWritten.map Verity.Core.Uint256.ofNat)
  match consume i.moduleIds i.sharesToMint (routerSnapshot i) i.outcomes with
  | .error .arraysLengthMismatch => .revert "ArraysLengthMismatch" dirty
  | .error .unrecoverableModuleError => .revert "UnrecoverableModuleError" dirty
  | .error .feeTotalZero => .revert "ASSERT_TOTAL_FEE_POSITIVE" dirty
  | .ok (events, d) => .success ⟨events, d⟩ (dirty.writeSlot callbacksSlot events.length)

inductive Status where | committed | reverted deriving DecidableEq, Repr
structure View where
  status : Status
  events : List LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted.Event
  distribution : FeeDistribution
  deriving DecidableEq, Repr

def observe : ContractResult Result → View
  | .success r _ => ⟨.committed, r.events, r.distribution⟩
  | .revert _ _ => ⟨.reverted, [], ⟨[], 0⟩⟩

/-- Independently stated source observation: it calls source `consume`, never
the executable transaction. -/
def sourceView (i : Input) : View :=
  match consume i.moduleIds i.sharesToMint (routerSnapshot i) i.outcomes with
  | .ok (ev, d) => ⟨.committed, ev, d⟩
  | .error _ => ⟨.reverted, [], ⟨[], 0⟩⟩

theorem observe_eq_sourceView (i : Input) (state : ContractState) :
    observe ((reportRewardsMinted i).run state) = sourceView i := by
  cases h : consume i.moduleIds i.sharesToMint (routerSnapshot i) i.outcomes with
  | error e =>
      cases e <;> simp [reportRewardsMinted, Contract.run, observe, sourceView, h]
  | ok p =>
      rcases p with ⟨ev, d⟩
      simp [reportRewardsMinted, Contract.run, observe, sourceView, h]

/-- `Contract.run` rolls back intermediate writer and callback-observation
writes, including an empty-revert UnrecoverableModuleError. -/
theorem revert_restores_snapshot (i : Input) (state rollback : ContractState)
    (reason : String) (h : (reportRewardsMinted i).run state = .revert reason rollback) :
    rollback = state := by
  unfold reportRewardsMinted Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.ReportRewardsMintedTx
