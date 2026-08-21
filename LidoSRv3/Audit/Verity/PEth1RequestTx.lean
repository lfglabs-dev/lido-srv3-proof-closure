import Verity.Core
import Verity.Stdlib.Math

/-!
# P-ETH-1 fee-leg evidence (former P-ETH-1b)

Source-shaped `Contract.run` ledger for the inventoried consolidation-fee ETH
paths at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`. These
theorems are parent evidence under `A-CANONICAL-REQUEST-ADDRESS`, not a sibling
guarantee row.

* `ConsolidationBus.executeConsolidation` (lines 383--406) forwards
  `msg.value` to `ConsolidationGateway.addConsolidationRequests`
* `WithdrawalVaultEIP7685._callAddWithdrawalRequest` (lines 103--111) sends
  the per-request EIP-7002 fee to immutable `WITHDRAWAL_REQUEST`
* `WithdrawalVaultEIP7685._callAddConsolidationRequest` (lines 113--121)
  sends the per-request EIP-7251 fee to immutable `CONSOLIDATION_REQUEST`

Exact-fee guard is `_requireExactFee` (lines 123--127): `msg.value` must equal
`requestsCount * fee`. The two-step request program writes the first fee
before the second `require`, so a later call failure discards the prefix.

This is a single-contract storage ledger under official `Contract.run`. It is
not a multi-contract EVM claim and does not use vacuous `externalCallBind`.
-/

namespace LidoSRv3.Audit.Verity.PEth1RequestTx

open _root_.Verity
open _root_.Verity.Stdlib.Math

def busSlot : StorageSlot Uint256 := ⟨0⟩
def gatewaySlot : StorageSlot Uint256 := ⟨1⟩
def vaultSlot : StorageSlot Uint256 := ⟨2⟩
def withdrawalSlot : StorageSlot Uint256 := ⟨3⟩
def consolidationSlot : StorageSlot Uint256 := ⟨4⟩

def busForward (msgValue : Uint256) (gatewayOk : Bool) : Contract Unit := do
  let b ← getStorage busSlot
  let g ← getStorage gatewaySlot
  let bReceived ← addPanic b msgValue
  setStorage busSlot bReceived
  require gatewayOk "GatewayCallFailed"
  let bAfter ← subPanic bReceived msgValue
  let gAfter ← addPanic g msgValue
  setStorage busSlot bAfter
  setStorage gatewaySlot gAfter

def sendWithdrawalFee (fee msgValue : Uint256) (callOk : Bool) : Contract Unit := do
  require (msgValue == fee) "IncorrectFee"
  let v ← getStorage vaultSlot
  require (decide (fee ≤ v)) "NotEnoughEther"
  require callOk "RequestAdditionFailed"
  let t ← getStorage withdrawalSlot
  let vAfter ← subPanic v fee
  let tAfter ← addPanic t fee
  setStorage vaultSlot vAfter
  setStorage withdrawalSlot tAfter

/-- Two EIP-7251 fee sends. `firstOk` defaults to true so existing numerals stay. -/
def sendTwoConsolidationFees (fee : Uint256) (secondOk : Bool)
    (firstOk : Bool := true) : Contract Unit := do
  require firstOk "RequestAdditionFailed"
  let required ← addPanic fee fee
  let v ← getStorage vaultSlot
  require (decide (required ≤ v)) "NotEnoughEther"
  let t ← getStorage consolidationSlot
  let v1 ← subPanic v fee
  let t1 ← addPanic t fee
  setStorage vaultSlot v1
  setStorage consolidationSlot t1
  require secondOk "RequestAdditionFailed"
  let v2 ← subPanic v1 fee
  let t2 ← addPanic t1 fee
  setStorage vaultSlot v2
  setStorage consolidationSlot t2

structure Ledger where
  bus : Nat
  gateway : Nat
  vault : Nat
  withdrawalRequest : Nat
  consolidationRequest : Nat
  deriving DecidableEq, Repr

inductive TxStatus where
  | committed
  | reverted
  deriving DecidableEq, Repr

structure TxView where
  status : TxStatus
  ledger : Ledger
  deriving DecidableEq, Repr

def decode (s : ContractState) : Ledger :=
  { bus := (s.readSlot 0).val
    gateway := (s.readSlot 1).val
    vault := (s.readSlot 2).val
    withdrawalRequest := (s.readSlot 3).val
    consolidationRequest := (s.readSlot 4).val }

def stateFor (l : Ledger) (base : ContractState) : ContractState :=
  ((((base.writeSlot 0 (Core.Uint256.ofNat l.bus)
         ).writeSlot 1 (Core.Uint256.ofNat l.gateway)
         ).writeSlot 2 (Core.Uint256.ofNat l.vault)
         ).writeSlot 3 (Core.Uint256.ofNat l.withdrawalRequest)
         ).writeSlot 4 (Core.Uint256.ofNat l.consolidationRequest)

def observe (result : ContractResult Unit) : TxView :=
  match result with
  | .success _ after => ⟨.committed, decode after⟩
  | .revert _ rollback => ⟨.reverted, decode rollback⟩

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (moved : Nat)
  deriving DecidableEq, Repr

def sourceBus (msgValue : Nat) (gatewayOk : Bool) : SourceOutcome :=
  if !gatewayOk then .reverted "GatewayCallFailed"
  else .committed msgValue

def sourceWithdrawalFee (fee msgValue vault : Nat) (callOk : Bool) : SourceOutcome :=
  if msgValue ≠ fee then .reverted "IncorrectFee"
  else if fee > vault then .reverted "NotEnoughEther"
  else if !callOk then .reverted "RequestAdditionFailed"
  else .committed fee

def sourceTwoConsolidationFees (fee : Nat) (secondOk : Bool)
    (firstOk : Bool := true) : SourceOutcome :=
  if !firstOk then .reverted "RequestAdditionFailed"
  else if !secondOk then .reverted "RequestAdditionFailed"
  else .committed (fee + fee)

def sourceBusView (before : Ledger) (msgValue : Nat) (gatewayOk : Bool) : TxView :=
  match sourceBus msgValue gatewayOk with
  | .reverted _ => ⟨.reverted, before⟩
  | .committed moved =>
      ⟨.committed, { before with bus := before.bus, gateway := before.gateway + moved }⟩

def sourceWithdrawalView (before : Ledger) (fee msgValue : Nat) (callOk : Bool) :
    TxView :=
  match sourceWithdrawalFee fee msgValue before.vault callOk with
  | .reverted _ => ⟨.reverted, before⟩
  | .committed moved =>
      ⟨.committed,
        { before with
          vault := before.vault - moved
          withdrawalRequest := before.withdrawalRequest + moved }⟩

def sourceConsolidationView (before : Ledger) (fee : Nat) (secondOk : Bool) :
    TxView :=
  match sourceTwoConsolidationFees fee secondOk with
  | .reverted _ => ⟨.reverted, before⟩
  | .committed moved =>
      ⟨.committed,
        { before with
          vault := before.vault - moved
          consolidationRequest := before.consolidationRequest + moved }⟩

def word (n : Nat) : Uint256 := Core.Uint256.ofNat n

theorem bus_failure_restores_snapshot
    (msgValue : Uint256) (gatewayOk : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (busForward msgValue gatewayOk).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem withdrawal_fee_failure_restores_snapshot
    (fee msgValue : Uint256) (callOk : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (sendWithdrawalFee fee msgValue callOk).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem consolidation_prefix_failure_restores_snapshot
    (fee : Uint256) (secondOk : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (sendTwoConsolidationFees fee secondOk).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem bus_forward_success :
    observe ((busForward (word 5) true).run (stateFor ⟨3, 1, 20, 0, 0⟩ defaultState)) =
      ⟨.committed, ⟨3, 6, 20, 0, 0⟩⟩ := by decide

#guard decide
  (observe ((busForward (word 5) true).run (stateFor ⟨3, 1, 20, 0, 0⟩ defaultState)) =
    ⟨.committed, ⟨3, 6, 20, 0, 0⟩⟩)

#guard decide
  (observe ((busForward (word 5) false).run (stateFor ⟨3, 1, 20, 0, 0⟩ defaultState)) =
    ⟨.reverted, ⟨3, 1, 20, 0, 0⟩⟩)

theorem withdrawal_fee_success :
    observe ((sendWithdrawalFee (word 5) (word 5) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
      ⟨.committed, ⟨3, 1, 15, 7, 4⟩⟩ := by decide

#guard decide
  (observe ((sendWithdrawalFee (word 5) (word 5) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.committed, ⟨3, 1, 15, 7, 4⟩⟩)

#guard decide
  (observe ((sendWithdrawalFee (word 5) (word 4) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.reverted, ⟨3, 1, 20, 2, 4⟩⟩)

#guard decide
  (observe ((sendWithdrawalFee (word 0) (word 0) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.committed, ⟨3, 1, 20, 2, 4⟩⟩)

#guard decide
  (observe ((sendTwoConsolidationFees (word 5) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.committed, ⟨3, 1, 10, 2, 14⟩⟩)

/-- Registered fee-target witness: two successful EIP-7251 fee sends debit the
vault by ten and credit the configured consolidation-request target by ten.
This is a model-local target slot; identifying it with canonical
`0x00…007251` remains `A-CANONICAL-REQUEST-ADDRESS`. -/
theorem consolidation_fee_target_success :
    observe ((sendTwoConsolidationFees (word 5) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
      ⟨.committed, ⟨3, 1, 10, 2, 14⟩⟩ := by
  decide

theorem consolidation_second_failure_discards_prefix :
    observe ((sendTwoConsolidationFees (word 5) false).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
      ⟨.reverted, ⟨3, 1, 20, 2, 4⟩⟩ := by decide

#guard decide
  (observe ((sendTwoConsolidationFees (word 5) false).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.reverted, ⟨3, 1, 20, 2, 4⟩⟩)

#guard decide
  (observe ((sendTwoConsolidationFees (word 0) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)) =
    ⟨.committed, ⟨3, 1, 20, 2, 4⟩⟩)

#guard decide
  (sourceBusView ⟨3, 1, 20, 0, 0⟩ 5 true =
    observe ((busForward (word 5) true).run (stateFor ⟨3, 1, 20, 0, 0⟩ defaultState)))

#guard decide
  (sourceConsolidationView ⟨3, 1, 20, 2, 4⟩ 5 true =
    observe ((sendTwoConsolidationFees (word 5) true).run
      (stateFor ⟨3, 1, 20, 2, 4⟩ defaultState)))

end LidoSRv3.Audit.Verity.PEth1RequestTx
