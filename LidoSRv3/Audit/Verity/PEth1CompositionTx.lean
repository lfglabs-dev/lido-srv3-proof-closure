import Verity.Core.Model.DenoteFunctionCalls

/-!
# P-ETH-1 composed multi-contract transaction slice

Execution-backed `CallFrame` composition for the pinned Lido source route
Bus → Gateway → Vault → request, including Gateway → refund recipient.  The
Gateway splits `msg.value` into the request fee and refund.  Each callee result
is produced by an executed frame; the outer transaction restores its initial
world when any later hop fails.

This is the approved MultiContract intermediate slice.  It does not by itself
claim that the four Lido Solidity functions have been compiled by Verity.
-/

namespace LidoSRv3.Audit.Verity.PEth1CompositionTx

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteFunctionCalls
open _root_.Verity.MultiContract

def refundAddr : Address := (6 : Address)

def site (callee : Address) (value : Nat) (id : Nat) : CallSite :=
  { siteId := id
    kind := .call
    target := callee.toNat
    value := value
    calldata := []
    gas := 1_000_000 }

def oracle : DenoteOracle :=
  { mappingSlot := fun _ _ => 0
    keccakMemorySlice := fun _ _ _ => 0 }

def env : CallEnv :=
  { oracle := oracle
    adversary := identityAdversary
    resolve := fun _ => none }

/-- A source-shaped payable entrypoint for one protocol hop.  Caller
authorization is executed inside `FunctionSpec`; `ok = false` represents the
source caller's checked low-level call failure. -/
def receiver (name : String) (expectedCaller : Address) (ok : Bool) : FunctionSpec :=
  { name := name
    params := []
    returnType := none
    isPayable := true
    body :=
      [ .require (.eq .caller (.literal expectedCaller.toNat)) "UnauthorizedCaller"
      , .require (.literal (if ok then 1 else 0)) "ExternalCallFailed"
      , .stop ] }

def receiverSpec (fn : FunctionSpec) : CompilationModel :=
  { name := fn.name
    fields := []
    constructor := none
    functions := [fn] }

def executeHop (w : MultiWorld) (caller callee : Address) (value id : Nat)
    (ok : Bool) : Option FramedCallObservation :=
  let fn := receiver (s!"hop-{id}") caller ok
  callFunction env (receiverSpec fn) fn id w caller callee (site callee value id)

inductive FailedHop where
  | invalidFee
  | busToGateway
  | gatewayToVault
  | gatewayToRefund
  | vaultToRequest
  deriving DecidableEq, Repr

inductive TxResult where
  | committed (world : MultiWorld)
  | reverted (failedAt : FailedHop) (world : MultiWorld)

def advance (before : MultiWorld) (failedAt : FailedHop)
    (observation : Option FramedCallObservation)
    (next : MultiWorld → TxResult) : TxResult :=
  match observation with
  | some obs =>
      if obs.result.succeeded then next obs.world
      else .reverted failedAt before
  | none => .reverted failedAt before

/-- One atomic run of the source-ordered split route.  A failure at any hop
returns the transaction-entry world, not the last successfully committed
prefix. -/
def run (before : MultiWorld) (msgValue fee : Nat)
    (busOk vaultOk refundOk requestOk : Bool) : TxResult :=
  if fee > msgValue then .reverted .invalidFee before
  else
    advance before .busToGateway
      (executeHop before busAddr gatewayAddr msgValue 1 busOk) fun w1 =>
    advance before .gatewayToVault
      (executeHop w1 gatewayAddr vaultAddr fee 2 vaultOk) fun w2 =>
    advance before .gatewayToRefund
      (executeHop w2 gatewayAddr refundAddr (msgValue - fee) 3 refundOk) fun w3 =>
    advance before .vaultToRequest
      (executeHop w3 vaultAddr requestAddr fee 4 requestOk) fun w4 =>
    .committed w4

def initial (msgValue : Nat) : MultiWorld :=
  { accounts :=
      [accountAt busAddr msgValue,
       accountAt gatewayAddr 0,
       accountAt vaultAddr 0,
       accountAt lidoAddr 0,
       accountAt requestAddr 0,
       accountAt refundAddr 0] }

structure BalanceView where
  bus : Nat
  gateway : Nat
  vault : Nat
  request : Nat
  refund : Nat
  deriving DecidableEq, Repr

def balances (w : MultiWorld) : BalanceView :=
  { bus := (lookup w busAddr).selfBalance.val
    gateway := (lookup w gatewayAddr).selfBalance.val
    vault := (lookup w vaultAddr).selfBalance.val
    request := (lookup w requestAddr).selfBalance.val
    refund := (lookup w refundAddr).selfBalance.val }

structure TxView where
  committed : Bool
  failedAt : Option FailedHop
  balances : BalanceView
  deriving DecidableEq, Repr

def observe : TxResult → TxView
  | .committed world => ⟨true, none, balances world⟩
  | .reverted failedAt world => ⟨false, some failedAt, balances world⟩

theorem split_fee_refund_composes_in_one_run :
    observe (run (initial 10) 10 3 true true true true) =
      ⟨true, none, ⟨0, 0, 0, 3, 7⟩⟩ := by decide

theorem later_failure_rolls_back_committed_prefixes :
    observe (run (initial 10) 10 3 true true true false) =
      ⟨false, some .vaultToRequest, ⟨10, 0, 0, 0, 0⟩⟩ := by decide

theorem refund_failure_rolls_back_vault_prefix :
    observe (run (initial 10) 10 3 true true false true) =
      ⟨false, some .gatewayToRefund, ⟨10, 0, 0, 0, 0⟩⟩ := by decide

/-- Registry-facing composed Verity transaction theorem.  It binds the
execution-backed `callFunction` route, its fee/refund observable, and rollback
of a committed three-hop prefix when the final request call fails. -/
theorem verity_tx_composes_value_flow_and_rollback :
    observe (run (initial 10) 10 3 true true true true) =
        ⟨true, none, ⟨0, 0, 0, 3, 7⟩⟩ ∧
    observe (run (initial 10) 10 3 true true true false) =
        ⟨false, some .vaultToRequest, ⟨10, 0, 0, 0, 0⟩⟩ :=
  ⟨split_fee_refund_composes_in_one_run,
   later_failure_rolls_back_committed_prefixes⟩

end LidoSRv3.Audit.Verity.PEth1CompositionTx
