import LidoSRv3.Audit.Verity.DepositNFrameTx

/-! # P-DEPOSIT-1 list-batch parent kill-line -/

namespace LidoSRv3.Tests.DepositNFrameTxMutants

open _root_.Verity
open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Verity.DepositParentTx
open LidoSRv3.Audit.Verity.DepositNFrameTx

def batchC : DepositNFrameTx.Batch :=
  { moduleId := 11, keys := 1, amount := 32, dynamicDataCommitment := 0xa3,
    depositDataRoot := 0xd3, dataValid := true, rootValid := true,
    moduleCallOk := true, beaconCallOk := true }

def threeBatchInputs : DepositNFrameTx.Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, depositSize := 32, maxEBType1 := 32,
    lido := 101, module := 202, beacon := 303,
    batches := [batchA, batchB, batchC] }

def threeBatchState : ContractState :=
  (defaultState.writeSlot DepositNFrameTx.lidoDepositableSlot 1000).writeSlot
    DepositNFrameTx.counterSlot 41

theorem three_batch_preconditions :
    DepositNFrameTx.Preconditions threeBatchInputs threeBatchState where
  authorized := rfl
  moduleActive := rfl
  allocationValid := rfl
  lidoCallOk := rfl
  healthy := by
    intro batch hBatch
    have hCases : batch = batchA ∨ batch = batchB ∨ batch = batchC := by
      simpa [threeBatchInputs] using hBatch
    rcases hCases with rfl | rfl | rfl <;> exact ⟨rfl, rfl, rfl, rfl⟩
  distinctModules := by decide
  valueMatches := by decide
  conserving := rfl
  entryBalance := by decide
  funded := by decide
  foldStable :=
    .cons (by decide) (.cons (by decide) (.cons (by decide) (.nil (by decide))))

/-- Fixed-arity mutation: silently truncate the caller's list. -/
def executeTwoOnly (inputs : DepositNFrameTx.Inputs) : Contract Unit :=
  DepositNFrameTx.execute { inputs with batches := inputs.batches.take 2 }

def twoBatchInputs : DepositNFrameTx.Inputs :=
  { threeBatchInputs with batches := [batchA, batchB] }

theorem two_batch_preconditions :
    DepositNFrameTx.Preconditions twoBatchInputs threeBatchState where
  authorized := rfl
  moduleActive := rfl
  allocationValid := rfl
  lidoCallOk := rfl
  healthy := by
    intro batch hBatch
    have hCases : batch = batchA ∨ batch = batchB := by
      simpa [twoBatchInputs, threeBatchInputs] using hBatch
    rcases hCases with rfl | rfl <;> exact ⟨rfl, rfl, rfl, rfl⟩
  distinctModules := by decide
  valueMatches := by decide
  conserving := rfl
  entryBalance := by decide
  funded := by decide
  foldStable := .cons (by decide) (.cons (by decide) (.nil (by decide)))

theorem honest_three_batch_parent :
    ParentConclusion DepositNFrameTx.execute threeBatchInputs threeBatchState :=
  nframe_deposit_parent threeBatchInputs threeBatchState three_batch_preconditions

theorem executeTwoOnly_drops_third_frame :
    (observe threeBatchState ((executeTwoOnly threeBatchInputs).run threeBatchState)).journal
      ≠ (sourceObservables threeBatchInputs threeBatchState).journal := by
  change (observe threeBatchState
    ((DepositNFrameTx.execute twoBatchInputs).run threeBatchState)).journal ≠ _
  rw [execute_observes_source twoBatchInputs threeBatchState two_batch_preconditions]
  decide

/-- Parent-shaped kill-line: all quantifiers and premises are retained, and a
healthy arity-three witness refutes the fixed-two executable. -/
theorem fixed_two_only_refutes_nframe_parent :
    ¬ (∀ (inputs : DepositNFrameTx.Inputs) (entry : ContractState),
      DepositNFrameTx.Preconditions inputs entry →
        ParentConclusion executeTwoOnly inputs entry) := by
  intro mutantParent
  have h := mutantParent threeBatchInputs threeBatchState three_batch_preconditions
  exact executeTwoOnly_drops_third_frame (congrArg Observables.journal h.1)

def wrappingBatch : DepositNFrameTx.Batch :=
  { batchC with amount := (_root_.Verity.Core.Uint256.ofNat
      (_root_.Verity.Core.Uint256.modulus - 1)) }

def wrappingInputs : DepositNFrameTx.Inputs :=
  { threeBatchInputs with
    batches := [wrappingBatch, { batchC with moduleId := 12, amount := 1 }] }

theorem wrapping_witness_moves_no_journal :
    (DepositNFrameTx.execute wrappingInputs).run threeBatchState =
        .revert "Panic(0x11)" threeBatchState ∧
      (observe threeBatchState
        ((DepositNFrameTx.execute wrappingInputs).run threeBatchState)).journal = [] := by
  have hWrap : _root_.Verity.Core.Uint256.modulus ≤
      exactTotal wrappingInputs.batches := by
    simp [wrappingInputs, wrappingBatch, exactTotal,
      _root_.Verity.Core.Uint256.val_ofNat]
    have hPositive : 1 ≤ _root_.Verity.Core.Uint256.modulus := by decide
    omega
  obtain ⟨hRun, hObs⟩ := wrapping_fold_reverts_without_journal
    wrappingInputs threeBatchState rfl rfl rfl hWrap
  exact ⟨hRun, congrArg Observables.journal hObs⟩

/-! ## D-NFRAME-1 in-body distinctModules guard kill-line -/

/-- Two batches with the same `moduleId` — pinned `StakingRouter.deposit` admits
one module per call, so this is not a pinned scenario; the model rejects at the
new in-body guard rather than silently breaking the parent premise. -/
def duplicateModuleInputs : DepositNFrameTx.Inputs :=
  { threeBatchInputs with
    batches := [batchA, { batchB with moduleId := batchA.moduleId }] }

theorem duplicate_module_input_reverts_at_in_body_guard :
    (DepositNFrameTx.execute duplicateModuleInputs).run threeBatchState =
      .revert "DuplicateModuleId" threeBatchState := by
  -- After the auth/active/allocation and word-overflow guards pass, the new
  -- `Nodup` check on `batches.map moduleId` fires because both batches carry
  -- moduleId = batchA.moduleId.
  have hAuthorized : duplicateModuleInputs.authorized = true := rfl
  have hActive : duplicateModuleInputs.moduleActive = true := rfl
  have hAllocation : duplicateModuleInputs.allocationValid = true := rfl
  have hNoWrapGuard :
      decide (exactTotal duplicateModuleInputs.batches <
        _root_.Verity.Core.Uint256.modulus) = true := by decide
  have hDistinctGuard :
      decide ((duplicateModuleInputs.batches.map fun batch => batch.moduleId).Nodup) =
        false := by decide
  simp [Contract.run, DepositNFrameTx.execute, Bind.bind, _root_.Verity.bind,
    _root_.Verity.require, hAuthorized, hActive, hAllocation, hNoWrapGuard,
    hDistinctGuard]

end LidoSRv3.Tests.DepositNFrameTxMutants
