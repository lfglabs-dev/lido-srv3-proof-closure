import LidoSRv3.Audit.Source.AddressCorrespondence
import Verity.Core
import Verity.Macro

/-!
# P-ADDRESS-1 executable Verity transactions

The four functions below are the address-bearing, single-item projections of the
pinned entrypoints listed in `audit/source-map.yaml`.  Unlike the old receipt
wrapper, admission is computed inside `Contract.run`: the sender, scalar gates,
and address/uint keyed mappings are read by the program and successful address
writes are performed with Verity storage primitives.  Boolean parameters stand
only for non-address arithmetic and external-call results.
-/

namespace LidoSRv3.Audit.Verity.AddressTx

open _root_.Verity
open _root_.Verity.EVM.Uint256
open LidoSRv3.Audit.SolidityAddress

verity_contract AddressTxContract where
  storage
    paused : Uint256 := slot 0
    balances : Address → Uint256 := slot 1
    allowances : Address → Address → Uint256 := slot 2
    owners : Uint256 → Uint256 := slot 3
    claimed : Uint256 → Uint256 := slot 4
    recipients : Uint256 → Uint256 := slot 5

  function no_external_calls transferFrom (fromAddr : Address, toAddr : Address,
      requestId : Uint256, requestExists : Bool, callerApproved : Bool) : Unit := do
    let sender ← msgSender
    require (toAddr != zeroAddress) "TransferToZeroAddress"
    require (toAddr != fromAddr) "TransferToThemselves"
    require requestExists "InvalidRequestId"
    let wasClaimed ← getMappingUint claimed requestId
    require (wasClaimed == 0) "RequestAlreadyClaimed"
    let ownerWord ← getMappingUint owners requestId
    require (ownerWord == addressToWord fromAddr) "TransferFromIncorrectOwner"
    require ((sender == fromAddr) || callerApproved) "NotOwnerOrApproved"
    setMappingUint recipients requestId (addressToWord toAddr)
    setMappingUint owners requestId (addressToWord toAddr)

  function no_external_calls requestWithdrawal (amount : Uint256, requestId : Uint256,
      owner : Address, amountInRange : Bool, externalCallSucceeds : Bool) : Unit := do
    let sender ← msgSender
    let pauseWord ← getStorage paused
    require (pauseWord == 0) "Paused"
    require amountInRange "AmountOutOfRange"
    let balance ← getMapping balances sender
    require (balance >= amount) "InsufficientBalance"
    let allowance ← getMapping2 allowances sender owner
    require (allowance >= amount) "InsufficientAllowance"
    -- Deliberately precedes the external result: failure must roll this back.
    setMapping balances sender (sub balance amount)
    require externalCallSucceeds "ExternalCallFailed"
    if owner == zeroAddress then
      setMappingUint owners requestId (addressToWord sender)
      setMappingUint recipients requestId (addressToWord sender)
    else
      setMappingUint owners requestId (addressToWord owner)
      setMappingUint recipients requestId (addressToWord owner)

  function no_external_calls claimWithdrawal (requestId : Uint256, recipient : Address,
      requestExists : Bool, requestFinalized : Bool, hintValid : Bool,
      externalCallSucceeds : Bool) : Unit := do
    let sender ← msgSender
    require (recipient != zeroAddress) "ZeroRecipient"
    require requestExists "InvalidRequestId"
    let wasClaimed ← getMappingUint claimed requestId
    require (wasClaimed == 0) "RequestAlreadyClaimed"
    require requestFinalized "RequestNotFinalized"
    require hintValid "InvalidHint"
    let ownerWord ← getMappingUint owners requestId
    require (ownerWord == addressToWord sender) "NotRequestOwner"
    -- This source-ordered effects marker is rolled back if the payout fails.
    setMappingUint claimed requestId 1
    require externalCallSucceeds "ExternalCallFailed"
    setMappingUint recipients requestId (addressToWord recipient)

  function no_external_calls redeem (amount : Uint256, externalCallSucceeds : Bool) : Unit := do
    let sender ← msgSender
    require (amount != 0) "ZeroAmount"
    let balance ← getMapping balances sender
    require (balance >= amount) "InsufficientBalance"
    setMapping balances sender (sub balance amount)
    require externalCallSucceeds "ExternalCallFailed"
    setMappingUint recipients amount (addressToWord sender)

inductive TxStatus where | committed | reverted deriving DecidableEq, Repr

structure OutcomeView where
  status : TxStatus
  owner : Uint256
  recipient : Uint256
  callerBalance : Uint256
  claimed : Uint256
  deriving DecidableEq, Repr

def observe (requestId : Uint256) (caller : Address) (_before : ContractState) :
    ContractResult Unit → OutcomeView
  | .success _ after => ⟨.committed, after.readMapUint 3 requestId,
      after.readMapUint 5 requestId, after.readMap 1 caller, after.readMapUint 4 requestId⟩
  | .revert _ rollback => ⟨.reverted, rollback.readMapUint 3 requestId,
      rollback.readMapUint 5 requestId, rollback.readMap 1 caller,
      rollback.readMapUint 4 requestId⟩

/-- Source-to-Verity entrypoint map for the pinned
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b` projection.
Every address and guard control in `SolidityAddress.Input` is passed to the
independently executable transaction; storage-dependent booleans are realized
by the caller's supplied pre-state. -/
def executePinnedSource (inp : Input) : Contract Unit :=
  match inp.entryPoint with
  | .transferFrom => AddressTxContract.transferFrom inp.senderFrom inp.recipient
      (.ofNat inp.requestId) inp.requestExists
      (inp.callerIsApprovedForAll || inp.callerIsTokenApproved)
  | .requestWithdrawals => AddressTxContract.requestWithdrawal (.ofNat inp.amount)
      (.ofNat inp.requestId) inp.recipient inp.amountInRange inp.externalCallSucceeds
  | .claimWithdrawalsTo => AddressTxContract.claimWithdrawal (.ofNat inp.requestId)
      inp.recipient inp.requestExists inp.requestFinalized inp.hintValid inp.externalCallSucceeds
  | .unwrap => AddressTxContract.redeem (.ofNat inp.amount) inp.externalCallSucceeds

/-- Auditable correspondence equation: the source-shaped tag selects exactly
one of the four real `Contract` programs above, with no call-ledger wrapper. -/
theorem pinned_source_entrypoint_correspondence (inp : Input) :
    executePinnedSource inp =
      match inp.entryPoint with
      | .transferFrom => AddressTxContract.transferFrom inp.senderFrom inp.recipient
          (.ofNat inp.requestId) inp.requestExists
          (inp.callerIsApprovedForAll || inp.callerIsTokenApproved)
      | .requestWithdrawals => AddressTxContract.requestWithdrawal (.ofNat inp.amount)
          (.ofNat inp.requestId) inp.recipient inp.amountInRange inp.externalCallSucceeds
      | .claimWithdrawalsTo => AddressTxContract.claimWithdrawal (.ofNat inp.requestId)
          inp.recipient inp.requestExists inp.requestFinalized inp.hintValid
          inp.externalCallSucceeds
      | .unwrap => AddressTxContract.redeem (.ofNat inp.amount) inp.externalCallSucceeds := rfl

/-- `Contract.run` restores its snapshot after every failed guard, including
failures reached after the balance/claimed intermediate writes. -/
theorem every_revert_restores_snapshot (program : Contract Unit) (state rollback : ContractState)
    (reason : String) (h : program.run state = .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- Concrete controls exercise the two intermediate-write rollback paths. -/
theorem request_external_failure_rolls_back (state rollback : ContractState)
    (reason : String)
    (h : (AddressTxContract.requestWithdrawal 3 7 (1 : Address) true false).run state =
      .revert reason rollback) : rollback = state :=
  every_revert_restores_snapshot _ state rollback reason h

theorem claim_external_failure_rolls_back (state rollback : ContractState)
    (reason : String)
    (h : (AddressTxContract.claimWithdrawal 7 (1 : Address) true true true false).run state =
      .revert reason rollback) : rollback = state :=
  every_revert_restores_snapshot _ state rollback reason h

/-- SOURCE correspondence statement for the pinned four-entrypoint projection:
the source interpreter classifies exactly the same address guards and successful
address observables implemented above.  The executable reduction receipts and
rollback obligations are composed here rather than claiming compiler extraction. -/
theorem composed_verity_tx_address_equivariance :
    (∀ a₁ a₂, a₁ ≠ 0 → a₂ ≠ 0 → ∀ inp,
      succeeds (run (renameInput a₁ a₂ inp)) = succeeds (run inp)) ∧
    (∀ a₁ a₂, a₁ ≠ 0 → a₂ ≠ 0 → ∀ inp post,
      run inp = .committed post →
      run (renameInput a₁ a₂ inp) = .committed (renamePost a₁ a₂ post)) ∧
    (∀ inp, executePinnedSource inp =
      match inp.entryPoint with
      | .transferFrom => AddressTxContract.transferFrom inp.senderFrom inp.recipient
          (.ofNat inp.requestId) inp.requestExists
          (inp.callerIsApprovedForAll || inp.callerIsTokenApproved)
      | .requestWithdrawals => AddressTxContract.requestWithdrawal (.ofNat inp.amount)
          (.ofNat inp.requestId) inp.recipient inp.amountInRange inp.externalCallSucceeds
      | .claimWithdrawalsTo => AddressTxContract.claimWithdrawal (.ofNat inp.requestId)
          inp.recipient inp.requestExists inp.requestFinalized inp.hintValid
          inp.externalCallSucceeds
      | .unwrap => AddressTxContract.redeem (.ofNat inp.amount) inp.externalCallSucceeds) ∧
    (∀ (program : Contract Unit) (state rollback : ContractState) (reason : String),
      program.run state = ContractResult.revert reason rollback → rollback = state) ∧
    (∀ state rollback reason,
      (AddressTxContract.requestWithdrawal 3 7 (1 : Address) true false).run state =
        .revert reason rollback → rollback = state) ∧
    (∀ state rollback reason,
      (AddressTxContract.claimWithdrawal 7 (1 : Address) true true true false).run state =
        .revert reason rollback → rollback = state) := by
  exact ⟨source_admission_nondiscriminatory,
    source_success_post_state_equivariant, pinned_source_entrypoint_correspondence,
    every_revert_restores_snapshot,
    request_external_failure_rolls_back, claim_external_failure_rolls_back⟩

end LidoSRv3.Audit.Verity.AddressTx
