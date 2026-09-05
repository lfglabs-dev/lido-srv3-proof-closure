import LidoSRv3.Audit.Source.AddressTransferCorrespondence
import Verity.Core.Model.Denote

/-!
# P-ADDRESS-1 bounded transfer under official Verity Denote

The program below is the executable deep-EDSL counterpart of the pinned
owner-operated `WithdrawalQueueERC721._transfer` slice. It has no external call,
so it does not pass through the historical `externalCallBind := pure ()` stub.
The official denotation observes the real sender, both mapping writes, and the
committed post-state.
-/

namespace LidoSRv3.Audit.Verity.AddressTransferTx

open Compiler Compiler.CompilationModel Compiler.CompilationModel.Denote
open LidoSRv3.Audit.Source.AddressTransferCorrespondence

def ownersSlot : Nat := 11
def approvalsSlot : Nat := 12

def ownersField : Field :=
  { name := "owners", ty := .mappingTyped (.simple .uint256), slot := some ownersSlot }

def approvalsField : Field :=
  { name := "approvals", ty := .mappingTyped (.simple .uint256), slot := some approvalsSlot }

/-- `WithdrawalQueueERC721.sol:218-220 transferFrom` -> `230-254 _transfer`, the
same owner-operated slice as `sourceTransfer`, as a deep-EDSL `FunctionSpec`.
Line map: 231 `TransferToZeroAddress`, 232 `TransferToThemselves`, 238
`TransferFromIncorrectOwner`, 241-245 `NotOwnerOrApproved` (owner disjunct
only), 247 `delete _getTokenApprovals()[_requestId]`, 248 `request.owner = _to`.
Not transcribed: 233, 235-236, 250-251, 253 (see `sourceTransfer`). -/
def transfer : FunctionSpec :=
  { name := "transferFrom"
    params := [{ name := "from", ty := .address }, { name := "to", ty := .address },
      { name := "requestId", ty := .uint256 }]
    returnType := none
    body :=
      [ .require (.logicalNot (.eq (.param "to") (.literal 0))) "TransferToZeroAddress"
      , .require (.logicalNot (.eq (.param "to") (.param "from"))) "TransferToThemselves"
      , .require (.eq (.mappingUint "owners" (.param "requestId")) (.param "from"))
          "TransferFromIncorrectOwner"
      , .require (.eq .caller (.param "from")) "NotOwnerOrApproved"
      , .setMappingUint "approvals" (.param "requestId") (.literal 0)
      , .setMappingUint "owners" (.param "requestId") (.param "to")
      , .stop ] }

/-- Solidity-facing name, WithdrawalQueueERC721.sol:218. -/
abbrev transferFrom := transfer

def spec : CompilationModel :=
  { name := "WithdrawalQueueERC721TransferSlice"
    fields := [ownersField, approvalsField]
    constructor := none
    functions := [transfer] }

def oracle : DenoteOracle :=
  { mappingSlot := fun base key => base * 100 + key
    keccakMemorySlice := fun _ _ _ => 0 }

def worldFor (owner approval : Nat) : Verity.ContractState :=
  (Verity.defaultState.writeSlot (oracle.mappingSlot ownersSlot 7) owner
    ).writeSlot (oracle.mappingSlot approvalsSlot 7) approval

def tx (caller fromAddr to : Nat) : DenoteTransaction :=
  { sender := caller, functionSelector := 0x23b872dd, args := [fromAddr, to, 7] }

def run (caller fromAddr to owner approval : Nat) : DenoteResult :=
  denoteFunction oracle spec transfer (tx caller fromAddr to) (worldFor owner approval)

def observe (r : DenoteResult) : Bool × Nat × Nat :=
  (r.success,
    r.finalStorage (oracle.mappingSlot ownersSlot 7),
    r.finalStorage (oracle.mappingSlot approvalsSlot 7))

/-- TX plane: the official denotation commits the two source-prescribed writes. -/
theorem run_commits_owner_handoff :
    observe (run 1 1 3 1 9) = (true, 3, 0) := by decide

/-- The renamed run commits the correspondingly renamed post-state. -/
theorem run_post_state_equivariant_witness :
    observe (run 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }).owner
      (renameState12 { owner := 1, approved := 9 }).approved) =
      (true, swap12 3, swap12 0) := by decide

/-- Caller discrimination is load-bearing: the same eligible state and
arguments revert when the transaction sender is not the owner. -/
theorem wrong_caller_reverts :
    observe (run 9 1 3 1 9) = (false, 1, 9) := by decide

/-- Exact SOURCE → TX receipt on the first address-renaming witness. -/
theorem tx_refines_source_witness :
    sourceTransfer 1 1 3 { owner := 1, approved := 9 } =
      some { owner := (observe (run 1 1 3 1 9)).2.1,
             approved := (observe (run 1 1 3 1 9)).2.2 } := by decide

/-- Registry-facing horizontal composition. Removing the MODEL→SOURCE theorem,
either renamed TX receipt, the SOURCE post-state witness, or the negative caller
control breaks this theorem. -/
theorem model_source_tx_address_equivariance_slice :
    (∀ caller fromAddr to s, sourceTransfer caller fromAddr to s = modelTransfer caller fromAddr to s) ∧
    sourceTransfer 1 1 3 { owner := 1, approved := 9 } = some { owner := 3, approved := 0 } ∧
    sourceTransfer 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }) =
      (sourceTransfer 1 1 3 { owner := 1, approved := 9 }).map renameState12 ∧
    observe (run 1 1 3 1 9) = (true, 3, 0) ∧
    observe (run 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }).owner
      (renameState12 { owner := 1, approved := 9 }).approved) =
      (true, swap12 3, swap12 0) ∧
    swap12 3 != 4 ∧
    swap12 9 != 8 ∧
    observe (run 9 1 3 1 9) = (false, 1, 9) := by
  exact ⟨source_refines_model, source_post_state_equivariant_witness.1,
    source_post_state_equivariant_witness.2, run_commits_owner_handoff,
    run_post_state_equivariant_witness, recipient_stomp_not_swap,
    approval_stomp_not_swap, wrong_caller_reverts⟩

end LidoSRv3.Audit.Verity.AddressTransferTx
