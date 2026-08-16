import Verity.Core
import Verity.Stdlib.Math

/-!
# P-ETH-1a gateway/vault refund transaction

Source-shaped `Contract.run` ledger for the inventoried P-ETH-1a ETH paths at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `ConsolidationGateway.addConsolidationRequests` (lines 185--223) sends
  `requestsCount * fee` to `WithdrawalVault`
* `ConsolidationGateway._refundFee` (lines 295--307) refunds `msg.value - fee`
  to `refundRecipient`, or `msg.sender` if the recipient is zero
* `WithdrawalVault.withdrawWithdrawals` (lines 107--121) sends `_amount` to
  `LIDO.receiveWithdrawals`

This is a single-contract storage ledger executed by official
`Verity.Contract.run`. It is not a multi-contract EVM claim and does not use
the vacuous `Contracts.Common.externalCallBind` stub. Intermediate writes
happen before later `require`s so a failed refund discards the vault fee
credit.
-/

namespace LidoSRv3.Audit.Verity.PEth1RefundTx

open _root_.Verity
open _root_.Verity.Stdlib.Math

def gatewaySlot : StorageSlot Uint256 := ⟨0⟩
def vaultSlot : StorageSlot Uint256 := ⟨1⟩
def refundSlot : StorageSlot Uint256 := ⟨2⟩
def lidoSlot : StorageSlot Uint256 := ⟨3⟩

/-- Gateway path with a positive remainder. The vault fee write precedes the
refund `require`, matching source order: vault call then `_refundFee`. -/
def gatewayRefund (msgValue fee : Uint256) (vaultOk refundOk : Bool) : Contract Unit := do
  require (msgValue != 0) "ZeroArgument(msg.value)"
  require (decide (fee ≤ msgValue)) "InsufficientFee"
  require (fee != msgValue) "ExactFeeHasNoRefund"
  let g ← getStorage gatewaySlot
  let v ← getStorage vaultSlot
  let gReceived ← addPanic g msgValue
  setStorage gatewaySlot gReceived
  require vaultOk "VaultCallFailed"
  let vAfter ← addPanic v fee
  let gAfterFee ← subPanic gReceived fee
  setStorage vaultSlot vAfter
  setStorage gatewaySlot gAfterFee
  require refundOk "FeeRefundFailed"
  let refund ← subPanic msgValue fee
  let r ← getStorage refundSlot
  let rAfter ← addPanic r refund
  let gAfterRefund ← subPanic gAfterFee refund
  setStorage refundSlot rAfter
  setStorage gatewaySlot gAfterRefund

/-- Gateway path where `msg.value = fee`, so source skips `_refundFee`. -/
def gatewayExactFee (msgValue : Uint256) (vaultOk : Bool) : Contract Unit := do
  require (msgValue != 0) "ZeroArgument(msg.value)"
  require vaultOk "VaultCallFailed"
  let g ← getStorage gatewaySlot
  let v ← getStorage vaultSlot
  let gReceived ← addPanic g msgValue
  setStorage gatewaySlot gReceived
  let vAfter ← addPanic v msgValue
  let gAfter ← subPanic gReceived msgValue
  setStorage vaultSlot vAfter
  setStorage gatewaySlot gAfter

def withdrawToLido (amount : Uint256) (callerIsLido : Bool) : Contract Unit := do
  require callerIsLido "NotLido"
  require (amount != 0) "ZeroAmount"
  let v ← getStorage vaultSlot
  require (decide (amount ≤ v)) "NotEnoughEther"
  let l ← getStorage lidoSlot
  let vAfter ← subPanic v amount
  let lAfter ← addPanic l amount
  setStorage vaultSlot vAfter
  setStorage lidoSlot lAfter

structure Ledger where
  gateway : Nat
  vault : Nat
  refundDest : Nat
  lido : Nat
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
  { gateway := (s.readSlot 0).val
    vault := (s.readSlot 1).val
    refundDest := (s.readSlot 2).val
    lido := (s.readSlot 3).val }

def stateFor (l : Ledger) (base : ContractState) : ContractState :=
  { base with
    storage := fun sl =>
      if sl = 0 then Core.Uint256.ofNat l.gateway
      else if sl = 1 then Core.Uint256.ofNat l.vault
      else if sl = 2 then Core.Uint256.ofNat l.refundDest
      else if sl = 3 then Core.Uint256.ofNat l.lido
      else base.storage sl }

def observe (result : ContractResult Unit) : TxView :=
  match result with
  | .success _ after => ⟨.committed, decode after⟩
  | .revert _ rollback => ⟨.reverted, decode rollback⟩

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (feeToVault refundToDest : Nat)
  deriving DecidableEq, Repr

/-- Independent source interpreter for gateway fee + refund. Recipient
resolution (`refundRecipient == 0 ? msg.sender : refundRecipient`) is applied
by the caller when selecting which ledger slot is `refundDest`. -/
def sourceGateway (msgValue fee : Nat) (vaultOk refundOk : Bool) : SourceOutcome :=
  if msgValue = 0 then .reverted "ZeroArgument(msg.value)"
  else if fee > msgValue then .reverted "InsufficientFee"
  else if !vaultOk then .reverted "VaultCallFailed"
  else if fee < msgValue && !refundOk then .reverted "FeeRefundFailed"
  else .committed fee (msgValue - fee)

def sourceWithdraw (amount vault : Nat) (callerIsLido : Bool) : SourceOutcome :=
  if !callerIsLido then .reverted "NotLido"
  else if amount = 0 then .reverted "ZeroAmount"
  else if amount > vault then .reverted "NotEnoughEther"
  else .committed amount 0

def sourceGatewayView (before : Ledger) (msgValue fee : Nat)
    (vaultOk refundOk : Bool) : TxView :=
  match sourceGateway msgValue fee vaultOk refundOk with
  | .reverted _ => ⟨.reverted, before⟩
  | .committed feeToVault refundToDest =>
      ⟨.committed,
        { gateway := before.gateway
          vault := before.vault + feeToVault
          refundDest := before.refundDest + refundToDest
          lido := before.lido }⟩

def sourceWithdrawView (before : Ledger) (amount : Nat) (callerIsLido : Bool) :
    TxView :=
  match sourceWithdraw amount before.vault callerIsLido with
  | .reverted _ => ⟨.reverted, before⟩
  | .committed moved _ =>
      ⟨.committed,
        { before with vault := before.vault - moved, lido := before.lido + moved }⟩

def word (n : Nat) : Uint256 := Core.Uint256.ofNat n

theorem refund_failure_restores_snapshot
    (msgValue fee : Uint256) (vaultOk refundOk : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (gatewayRefund msgValue fee vaultOk refundOk).run state =
      .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem exact_fee_failure_restores_snapshot
    (msgValue : Uint256) (vaultOk : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (gatewayExactFee msgValue vaultOk).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem withdraw_failure_restores_snapshot
    (amount : Uint256) (callerIsLido : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (withdrawToLido amount callerIsLido).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem gateway_refund_success_moves_value :
    observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
      ⟨.committed, ⟨10, 4, 6, 7⟩⟩ := by decide

#guard decide
  (observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.committed, ⟨10, 4, 6, 7⟩⟩)

theorem gateway_refund_failure_keeps_prefix_out :
    observe ((gatewayRefund (word 5) (word 3) true false).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
      ⟨.reverted, ⟨10, 1, 4, 7⟩⟩ := by decide

#guard decide
  (observe ((gatewayRefund (word 5) (word 3) true false).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 1, 4, 7⟩⟩)

#guard decide
  (observe ((gatewayRefund (word 5) (word 3) false true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 1, 4, 7⟩⟩)

#guard decide
  (observe ((gatewayRefund (word 0) (word 0) true true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 1, 4, 7⟩⟩)

#guard decide
  (observe ((gatewayRefund (word 2) (word 3) true true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 1, 4, 7⟩⟩)

#guard decide
  (observe ((gatewayExactFee (word 5) true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)) =
    ⟨.committed, ⟨10, 6, 4, 7⟩⟩)

theorem withdraw_success_moves_to_lido :
    observe ((withdrawToLido (word 5) true).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) =
      ⟨.committed, ⟨10, 3, 4, 12⟩⟩ := by decide

#guard decide
  (observe ((withdrawToLido (word 5) true).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) =
    ⟨.committed, ⟨10, 3, 4, 12⟩⟩)

#guard decide
  (observe ((withdrawToLido (word 5) false).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 8, 4, 7⟩⟩)

#guard decide
  (observe ((withdrawToLido (word 0) true).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 8, 4, 7⟩⟩)

#guard decide
  (observe ((withdrawToLido (word 9) true).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)) =
    ⟨.reverted, ⟨10, 8, 4, 7⟩⟩)

#guard decide
  (sourceGatewayView ⟨10, 1, 4, 7⟩ 5 3 true true =
    observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor ⟨10, 1, 4, 7⟩ defaultState)))

#guard decide
  (sourceWithdrawView ⟨10, 8, 4, 7⟩ 5 true =
    observe ((withdrawToLido (word 5) true).run
      (stateFor ⟨10, 8, 4, 7⟩ defaultState)))

#guard decide
  ((observe ((gatewayRefund (word 5) (word 3) true true).run
      (stateFor ⟨10, 1, 0, 7⟩ defaultState))).ledger.refundDest = 2)

end LidoSRv3.Audit.Verity.PEth1RefundTx
