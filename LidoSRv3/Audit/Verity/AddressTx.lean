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

/-- Address-only outcome boundary used for SOURCE correspondence.  It omits
the numeric balances and the claimed bit, so the theorem does not compare a
full state containing unrelated or representation-specific fields. -/
structure AddressOutcomeView where
  status : TxStatus
  ownerWrite : Option Uint256
  recipientWrite : Option Uint256
  deriving DecidableEq, Repr

def observe (requestId : Uint256) (caller : Address) (_before : ContractState) :
    ContractResult Unit → OutcomeView
  | .success _ after => ⟨.committed, after.readMapUint 3 requestId,
      after.readMapUint 5 requestId, after.readMap 1 caller, after.readMapUint 4 requestId⟩
  | .revert _ rollback => ⟨.reverted, rollback.readMapUint 3 requestId,
      rollback.readMapUint 5 requestId, rollback.readMap 1 caller,
      rollback.readMapUint 4 requestId⟩

def observeAddress (inp : Input) : ContractResult Unit → AddressOutcomeView
  | .success _ after =>
      let requestId : Uint256 := .ofNat inp.requestId
      match inp.entryPoint with
      | .transferFrom | .requestWithdrawals =>
          ⟨.committed, some (after.readMapUint 3 requestId),
            some (after.readMapUint 5 requestId)⟩
      | .claimWithdrawalsTo =>
          ⟨.committed, none, some (after.readMapUint 5 requestId)⟩
      | .unwrap =>
          ⟨.committed, none, some (after.readMapUint 5 (.ofNat inp.amount))⟩
  | .revert _ _ => ⟨.reverted, none, none⟩

def sourceAddressView (inp : Input) : AddressOutcomeView :=
  match run inp with
  | .reverted => ⟨.reverted, none, none⟩
  | .committed post =>
      match inp.entryPoint with
      | .transferFrom | .requestWithdrawals =>
          ⟨.committed, some (addressToWord post.owner),
            some (addressToWord post.recipient)⟩
      | .claimWithdrawalsTo | .unwrap =>
          ⟨.committed, none, some (addressToWord post.recipient)⟩

/-- Storage realization of the source-shaped facts.  The side conditions on
`pinned_source_observable_correspondence` exclude impossible abstract fact
combinations such as an insufficient balance for a zero amount. -/
def stateFor (inp : Input) : ContractState :=
  let amount : Uint256 := .ofNat inp.amount
  let requestId : Uint256 := .ofNat inp.requestId
  let balance := if inp.callerBalanceSufficient then amount else 0
  let allowance := if inp.callerAllowanceSufficient then amount else 0
  let claimed := if inp.requestClaimed then 1 else 0
  let paused := if inp.paused then 1 else 0
  { defaultState with sender := inp.caller }
    |>.writeSlot 0 paused
    |>.writeMap 1 inp.caller balance
    |>.writeMap2 2 inp.caller inp.recipient allowance
    |>.writeMapUint 3 requestId (addressToWord inp.requestOwner)
    |>.writeMapUint 4 requestId claimed
    |>.writeMapUint 5 requestId (addressToWord inp.requestOwner)

@[simp] theorem addressToWord_eq_iff (a b : Address) :
    addressToWord a = addressToWord b ↔ a = b := by
  constructor
  · intro h
    apply Verity.Core.Address.toNat_injective
    have hv := congrArg Verity.Core.Uint256.val h
    have hmodulus : Verity.Core.Address.modulus < Verity.Core.Uint256.modulus := by
      change 2 ^ 160 < 2 ^ 256
      exact Nat.pow_lt_pow_right (by decide) (by decide)
    have ha : a.toNat < Verity.Core.Uint256.modulus := Nat.lt_trans a.isLt hmodulus
    have hb : b.toNat < Verity.Core.Uint256.modulus := Nat.lt_trans b.isLt hmodulus
    change a.toNat % Verity.Core.Uint256.modulus =
      b.toNat % Verity.Core.Uint256.modulus at hv
    simpa [Nat.mod_eq_of_lt ha, Nat.mod_eq_of_lt hb] using hv
  · rintro rfl
    rfl

@[simp] theorem addressWordRaw_eq_iff (a b : Address) :
    Verity.Core.Uint256.ofNat a.toNat = Verity.Core.Uint256.ofNat b.toNat ↔ a = b := by
  simpa only [addressToWord] using addressToWord_eq_iff a b

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

set_option maxHeartbeats 2000000 in
private theorem transfer_observable_correspondence (inp : Input)
    (hEntry : inp.entryPoint = .transferFrom) :
    observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
      sourceAddressView inp := by
  have hone : (1 : Uint256) ≠ 0 := by decide
  simp_all (config := { maxSteps := 1000000 })
    [executePinnedSource, stateFor, observeAddress, sourceAddressView, run, admitted,
    successfulPost, AddressTxContract.transferFrom, _root_.Verity.require,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    _root_.Verity.msgSender, _root_.Verity.getMappingUint,
    _root_.Verity.setMappingUint, AddressTxContract.paused,
    AddressTxContract.balances, AddressTxContract.allowances,
    AddressTxContract.owners, AddressTxContract.claimed,
    AddressTxContract.recipients, ContractState.readSlot,
    ContractState.writeSlot, ContractState.readMap, ContractState.writeMap,
    ContractState.readMap2, ContractState.writeMap2,
    ContractState.readMapUint, ContractState.writeMapUint,
    ContractState.storage, ContractState.storageMap,
    ContractState.storageMap2, ContractState.storageMapUint]
  by_cases hz : inp.recipient = 0 <;> try simp_all (config := { maxSteps := 1000000 })
  by_cases hself : inp.recipient = inp.senderFrom <;> try simp_all (config := { maxSteps := 1000000 })
  cases hExists : inp.requestExists <;> try simp_all (config := { maxSteps := 1000000 })
  cases hClaimed : inp.requestClaimed <;> try simp_all (config := { maxSteps := 1000000 })
    [hone, _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  by_cases howner : inp.senderFrom = inp.requestOwner <;>
    try simp_all (config := { maxSteps := 1000000 })
      [show inp.requestOwner = inp.senderFrom ↔ inp.senderFrom = inp.requestOwner from eq_comm,
        _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  by_cases hcaller : inp.caller = inp.requestOwner <;> try simp_all (config := { maxSteps := 1000000 })
  cases hApprovedAll : inp.callerIsApprovedForAll <;> try simp_all (config := { maxSteps := 1000000 })
  cases hApprovedToken : inp.callerIsTokenApproved <;> simp_all (config := { maxSteps := 1000000 })

set_option maxHeartbeats 2000000 in
private theorem request_observable_correspondence (inp : Input)
    (hEntry : inp.entryPoint = .requestWithdrawals)
    (hAmount : inp.amount < 2 ^ 256)
    (hBalance : !inp.callerBalanceSufficient = true → inp.amount ≠ 0)
    (hAllowance : !inp.callerAllowanceSufficient = true → inp.amount ≠ 0) :
    observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
      sourceAddressView inp := by
  have hmod : inp.amount % Verity.Core.Uint256.modulus = inp.amount := by
    exact Nat.mod_eq_of_lt (by simpa [Verity.Core.Uint256.modulus,
      Verity.Core.UINT256_MODULUS] using hAmount)
  have hone : (1 : Uint256) ≠ 0 := by decide
  simp_all (config := { maxSteps := 1000000 })
    [executePinnedSource, stateFor, observeAddress, sourceAddressView, run, admitted,
    successfulPost, AddressTxContract.requestWithdrawal, _root_.Verity.require,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    _root_.Verity.msgSender, _root_.Verity.getStorage, _root_.Verity.getMapping,
    _root_.Verity.getMapping2, _root_.Verity.setMapping,
    _root_.Verity.setMappingUint, AddressTxContract.paused,
    AddressTxContract.balances, AddressTxContract.allowances,
    AddressTxContract.owners, AddressTxContract.claimed,
    AddressTxContract.recipients, ContractState.readSlot, ContractState.writeSlot,
    ContractState.readMap, ContractState.writeMap,
    ContractState.readMap2, ContractState.writeMap2,
    ContractState.readMapUint, ContractState.writeMapUint,
    ContractState.storage, ContractState.storageMap,
    ContractState.storageMap2, ContractState.storageMapUint,
    Verity.Core.Uint256.ofNat, hmod]
  cases hPaused : inp.paused <;> try simp_all (config := { maxSteps := 1000000 })
    [hone, _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hRange : inp.amountInRange <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hBalanceFact : inp.callerBalanceSufficient <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hAllowanceFact : inp.callerAllowanceSufficient <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hExternal : inp.externalCallSucceeds <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
      _root_.Verity.setMapping, ContractState.writeMap]
  by_cases hz : inp.recipient = 0 <;> simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.bind, Bind.bind, _root_.Verity.setMappingUint,
      _root_.Verity.Contract.run, observeAddress,
      ContractState.writeMapUint, ContractState.readMapUint,
      ContractState.storageMapUint, ContractState.storage]

set_option maxHeartbeats 2000000 in
private theorem claim_observable_correspondence (inp : Input)
    (hEntry : inp.entryPoint = .claimWithdrawalsTo) :
    observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
      sourceAddressView inp := by
  have hone : (1 : Uint256) ≠ 0 := by decide
  simp_all (config := { maxSteps := 1000000 })
    [executePinnedSource, stateFor, observeAddress, sourceAddressView, run, admitted,
    successfulPost, AddressTxContract.claimWithdrawal, _root_.Verity.require,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    _root_.Verity.msgSender, _root_.Verity.getMappingUint,
    _root_.Verity.setMappingUint, AddressTxContract.paused,
    AddressTxContract.balances, AddressTxContract.allowances,
    AddressTxContract.owners, AddressTxContract.claimed,
    AddressTxContract.recipients, ContractState.readSlot,
    ContractState.writeSlot, ContractState.readMap, ContractState.writeMap,
    ContractState.readMap2, ContractState.writeMap2,
    ContractState.readMapUint, ContractState.writeMapUint,
    ContractState.storage, ContractState.storageMap,
    ContractState.storageMap2, ContractState.storageMapUint]
  by_cases hz : inp.recipient = 0 <;> try simp_all (config := { maxSteps := 1000000 })
  cases hExists : inp.requestExists <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hClaimed : inp.requestClaimed <;> try simp_all (config := { maxSteps := 1000000 })
    [hone, _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hFinalized : inp.requestFinalized <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hHint : inp.hintValid <;> try simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  by_cases howner : inp.caller = inp.requestOwner <;>
    try simp_all (config := { maxSteps := 1000000 })
      [show inp.requestOwner = inp.caller ↔ inp.caller = inp.requestOwner from eq_comm,
        _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind]
  cases hExternal : inp.externalCallSucceeds <;> simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.bind, Bind.bind, _root_.Verity.setMappingUint,
      ContractState.writeMapUint, ContractState.readMapUint,
      ContractState.storageMapUint]

set_option maxHeartbeats 2000000 in
private theorem unwrap_observable_correspondence (inp : Input)
    (hEntry : inp.entryPoint = .unwrap)
    (hAmount : inp.amount < 2 ^ 256)
    (hBalance : !inp.callerBalanceSufficient = true → inp.amount ≠ 0) :
    observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
      sourceAddressView inp := by
  have hmod : inp.amount % Verity.Core.Uint256.modulus = inp.amount := by
    exact Nat.mod_eq_of_lt (by simpa [Verity.Core.Uint256.modulus,
      Verity.Core.UINT256_MODULUS] using hAmount)
  have hzero : (Verity.Core.Uint256.ofNat inp.amount = 0) ↔ inp.amount = 0 := by
    constructor
    · intro h
      have hv := congrArg Verity.Core.Uint256.val h
      simpa [Verity.Core.Uint256.val_ofNat, hmod] using hv
    · intro h
      simpa [h]
  simp_all (config := { maxSteps := 1000000 })
    [executePinnedSource, stateFor, observeAddress, sourceAddressView, run, admitted,
    successfulPost, AddressTxContract.redeem, _root_.Verity.require,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    _root_.Verity.msgSender, _root_.Verity.getMapping,
    _root_.Verity.setMapping, _root_.Verity.setMappingUint,
    AddressTxContract.paused, AddressTxContract.balances,
    AddressTxContract.allowances, AddressTxContract.owners,
    AddressTxContract.claimed, AddressTxContract.recipients,
    ContractState.readSlot, ContractState.writeSlot,
    ContractState.readMap, ContractState.writeMap,
    ContractState.readMap2, ContractState.writeMap2,
    ContractState.readMapUint, ContractState.writeMapUint,
    ContractState.storage, ContractState.storageMap,
    ContractState.storageMap2, ContractState.storageMapUint,
    Verity.Core.Uint256.ofNat, hzero]
  by_cases hz : inp.amount = 0 <;> try simp_all (config := { maxSteps := 1000000 })
  cases hBalanceFact : inp.callerBalanceSufficient <;> try simp_all (config := { maxSteps := 1000000 })
  cases hExternal : inp.externalCallSucceeds <;> simp_all (config := { maxSteps := 1000000 })
    [_root_.Verity.bind, Bind.bind, _root_.Verity.setMappingUint,
      ContractState.writeMapUint, ContractState.readMapUint,
      ContractState.storageMapUint]

/-- Behavioral SOURCE → executable-Verity correspondence on only the address
writes of the selected entrypoint.  `amount < 2^256` is the Solidity `uint256`
domain, while the two implications characterize realizable negative
balance/allowance facts. -/
theorem pinned_source_observable_correspondence (inp : Input)
    (hAmount : inp.amount < 2 ^ 256)
    (hBalance : !inp.callerBalanceSufficient = true → inp.amount ≠ 0)
    (hAllowance : !inp.callerAllowanceSufficient = true → inp.amount ≠ 0) :
    observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
      sourceAddressView inp := by
  cases hEntry : inp.entryPoint
  · exact transfer_observable_correspondence inp hEntry
  · exact request_observable_correspondence inp hEntry hAmount hBalance hAllowance
  · exact claim_observable_correspondence inp hEntry
  · exact unwrap_observable_correspondence inp hEntry hAmount hBalance

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
    (∀ inp, inp.amount < 2 ^ 256 →
      (!inp.callerBalanceSufficient = true → inp.amount ≠ 0) →
      (!inp.callerAllowanceSufficient = true → inp.amount ≠ 0) →
      observeAddress inp ((executePinnedSource inp).run (stateFor inp)) =
        sourceAddressView inp) ∧
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
    pinned_source_observable_correspondence, every_revert_restores_snapshot,
    request_external_failure_rolls_back, claim_external_failure_rolls_back⟩

end LidoSRv3.Audit.Verity.AddressTx
