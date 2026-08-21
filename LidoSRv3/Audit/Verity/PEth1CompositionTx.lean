import Verity.Core.Model.DenoteFunctionCalls

/-!
# P-ETH-1: composed multi-contract ETH transaction

Recursive dispatch of source-shaped `FunctionSpec` bodies through Verity's
external-call frames (`MultiContract.callFunction`) over one shared
`MultiWorld`.

Nothing about the call tree is written down by hand.  A single root call
`sender → ConsolidationBus` is dispatched; every subsequent hop is *discovered*
by reading the journal entries that the executing callee body emitted, and is
then executed against the same world.  The Gateway's fee/refund split and the
Vault's per-request fan-out are therefore computed by the executed bodies, not
by the harness.

## Declared-amount calling convention

`LinkedExternal.value` is `0` at every link site, so a body never moves ETH by
itself.  The amount a body wants to forward is passed as calldata word `0`, the
dispatcher lifts it into the frame's `CallSite.value`, and every callee opens
with `require(msg.value == amount)`.  ETH therefore moves exactly once per hop —
at the `MultiContract` frame boundary — while the amount stays body-computed.

## Atomicity

A hop that cannot be entered (insufficient balance, unknown target) or whose
body reverts aborts the whole transaction: `finalWorld` returns the
transaction-entry world.  `TxOutcome.lastWorld` retains the non-atomic world so
that the atomicity requirement itself is falsifiable (see the rollback mutant).

This is a model-plane ensemble.  It does not claim that the corresponding Lido
Solidity functions have been compiled by Verity.
-/

namespace LidoSRv3.Audit.Verity.PEth1CompositionTx

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteFunctionCalls
open _root_.Verity.MultiContract

/-! ## Ensemble addresses

`busAddr`/`gatewayAddr`/`vaultAddr`/`lidoAddr`/`requestAddr` come from
`Verity.MultiContract`. -/

/-- Refund recipient supplied by the consolidation caller. -/
def refundAddr : Address := (6 : Address)

/-- Externally owned account that funds the transaction. -/
def senderAddr : Address := (7 : Address)

def gasBudget : Nat := 1_000_000

/-- Bound on the number of dispatched frames.  Exceeding it is reported as
`TxControl.exhausted` rather than silently truncating the trace. -/
def fuelBudget : Nat := 32

/-! ## Wiring

Every deviation from the source route is a non-default field, so a mutant is a
`Wiring` literal rather than a forked copy of the ensemble. -/

structure Wiring where
  /-- Link target of `Gateway → WithdrawalVault`. -/
  vaultTarget : Address := vaultAddr
  /-- Link target of `Gateway → refundRecipient`. -/
  refundTarget : Address := refundAddr
  /-- Link target of `WithdrawalVault → CONSOLIDATION_REQUEST`. -/
  requestTarget : Address := requestAddr
  /-- Gateway emits the refund leg at all. -/
  emitRefund : Bool := true
  /-- Gateway declares the whole `msg.value` to the refund recipient instead of
  the post-fee remainder. -/
  refundWholeValue : Bool := false
  /-- Vault issues one request per batch entry instead of a single request. -/
  perRequestCalls : Bool := true
  /-- The consolidation-request predeploy accepts the call. -/
  requestAccepts : Bool := true
  deriving Repr

/-- The pinned source route. -/
def honest : Wiring := {}

/-! ## Compiled ensemble -/

def oracle : DenoteOracle :=
  { mappingSlot := fun _ _ => 0
    keccakMemorySlice := fun _ _ _ => 0 }

/-- Link-time resolution under the declared-amount convention: value `0`, so the
frame boundary is the only place ETH moves. -/
def link (target : Address) (siteId : Nat) : LinkedExternal :=
  { target := target.toNat, value := 0, siteId := siteId }

def envWith (resolve : String → Option LinkedExternal) : CallEnv :=
  { oracle := oracle, adversary := identityAdversary, resolve := resolve }

def feeField : Field :=
  { name := "feePerRequest", ty := .uint256, slot := some 0 }

def amountParam : Param := { name := "amount", ty := .uint256 }
def batchParam : Param := { name := "batchSize", ty := .uint256 }

/-- `require(msg.value == amount)` — the receiving half of the declared-amount
convention. -/
def declaredValueCheck : Stmt :=
  .require (.eq .msgValue (.param "amount")) "DeclaredValueMismatch"

/-! ### ConsolidationBus -/

def busFn : FunctionSpec :=
  { name := "executeConsolidation"
    params := [amountParam, batchParam]
    returnType := none
    isPayable := true
    body :=
      [ declaredValueCheck
      , .externalCallBind [] "gateway" [.param "amount", .param "batchSize"]
      , .stop ] }

def busSpec : CompilationModel :=
  { name := "ConsolidationBus", fields := [], constructor := none, functions := [busFn] }

def busEnv : CallEnv :=
  envWith (fun name => if name == "gateway" then some (link gatewayAddr 1) else none)

/-! ### TriggerableWithdrawalsGateway -/

def gatewayFn (w : Wiring) : FunctionSpec :=
  { name := "addConsolidationRequests"
    params := [amountParam, batchParam]
    returnType := none
    isPayable := true
    body :=
      [ declaredValueCheck
      , .require (.lt (.literal 0) .msgValue) "ZeroArgument"
      , .letVar "fee" (.mul (.param "batchSize") (.storage "feePerRequest"))
      , .ite (.eq (.param "batchSize") (.literal 0)) []
          [ .require (.eq (.div (.localVar "fee") (.param "batchSize"))
              (.storage "feePerRequest")) "Panic(0x11)" ]
      , .require (.le (.localVar "fee") (.param "amount")) "InsufficientValue"
      , .letVar "refund" (.sub (.param "amount") (.localVar "fee"))
      , .externalCallBind [] "vault" [.localVar "fee", .param "batchSize"] ]
      ++ (if w.emitRefund then
            [ .ite (.gt (.localVar "refund") (.literal 0))
                [ .externalCallBind [] "refund"
                    [if w.refundWholeValue then .param "amount" else .localVar "refund"] ]
                [] ]
          else [])
      ++ [ .stop ] }

def gatewaySpec (w : Wiring) : CompilationModel :=
  { name := "ConsolidationGateway", fields := [feeField]
    constructor := none, functions := [gatewayFn w] }

def gatewayEnv (w : Wiring) : CallEnv :=
  envWith (fun name =>
    if name == "vault" then some (link w.vaultTarget 2)
    else if name == "refund" then some (link w.refundTarget 3)
    else none)

/-! ### WithdrawalVault -/

def vaultFn (w : Wiring) : FunctionSpec :=
  { name := "addConsolidationRequests"
    params := [amountParam, batchParam]
    returnType := none
    isPayable := true
    body :=
      [ declaredValueCheck
      , .letVar "fee" (.mul (.param "batchSize") (.storage "feePerRequest"))
      , .ite (.eq (.param "batchSize") (.literal 0)) []
          [ .require (.eq (.div (.localVar "fee") (.param "batchSize"))
              (.storage "feePerRequest")) "Panic(0x11)" ]
      , .require (.eq (.param "amount") (.localVar "fee")) "FeeMismatch" ]
      ++ (if w.perRequestCalls then
            [ .forEach "i" (.param "batchSize")
                [ .externalCallBind [] "request" [.storage "feePerRequest"] ] ]
          else
            [ .externalCallBind [] "request" [.storage "feePerRequest"] ])
      ++ [ .stop ] }

def vaultSpec (w : Wiring) : CompilationModel :=
  { name := "WithdrawalVault", fields := [feeField]
    constructor := none, functions := [vaultFn w] }

def vaultEnv (w : Wiring) : CallEnv :=
  envWith (fun name => if name == "request" then some (link w.requestTarget 4) else none)

/-! ### Terminal receivers

The EIP-7251 predeploy, the refund recipient, and Lido make no onward calls. -/

def sinkFn (name : String) (accepts : Bool) : FunctionSpec :=
  { name := name
    params := [amountParam]
    returnType := none
    isPayable := true
    body :=
      [ declaredValueCheck
      , .require (.literal (if accepts then 1 else 0)) "ReceiverRejected"
      , .stop ] }

def sinkSpec (name : String) (accepts : Bool) : CompilationModel :=
  { name := name, fields := [], constructor := none, functions := [sinkFn name accepts] }

def sinkEnv : CallEnv := envWith (fun _ => none)

/-! ## Address-keyed registry -/

structure Node where
  env : CallEnv
  spec : CompilationModel
  fn : FunctionSpec
  selector : Nat

def sinkNode (name : String) (accepts : Bool) (selector : Nat) : Node :=
  { env := sinkEnv, spec := sinkSpec name accepts, fn := sinkFn name accepts
    selector := selector }

def nodeAt (w : Wiring) (addr : Address) : Option Node :=
  if addr = busAddr then
    some { env := busEnv, spec := busSpec, fn := busFn, selector := 1 }
  else if addr = gatewayAddr then
    some { env := gatewayEnv w, spec := gatewaySpec w, fn := gatewayFn w, selector := 2 }
  else if addr = vaultAddr then
    some { env := vaultEnv w, spec := vaultSpec w, fn := vaultFn w, selector := 3 }
  else if addr = requestAddr then
    some (sinkNode "ConsolidationRequest" w.requestAccepts 4)
  else if addr = refundAddr then
    some (sinkNode "RefundRecipient" true 5)
  else if addr = lidoAddr then
    some (sinkNode "Lido" true 6)
  else
    none

/-! ## Recursive dispatch over one shared world -/

/-- A call the dispatcher still owes, in source order. -/
structure Pending where
  caller : Address
  callee : Address
  site : CallSite

inductive TxControl where
  | success
  | unknownTarget (callee : Address)
  | cannotEnter (callee : Address)
  | calleeReverted (callee : Address)
  | exhausted
  deriving DecidableEq, Repr

structure TxOutcome where
  control : TxControl
  /-- Frames actually entered. -/
  hops : Nat
  entryWorld : MultiWorld
  /-- World produced by the executed prefix, *without* the atomicity rule. -/
  lastWorld : MultiWorld
  /-- The flattened program the dispatch discovered, in execution order. -/
  program : List CompiledCall

/-- Lift one journal entry emitted by a callee body into the next frame.  The
declared amount is calldata word `0`. -/
def childPending (caller : Address) (gas : Nat) (entry : ExternalCall) : Pending :=
  { caller := caller
    callee := Core.Address.ofNat entry.target
    site :=
      { siteId := entry.siteId
        kind := .call
        target := entry.target
        value := entry.calldata.headD 0
        calldata := entry.calldata
        gas := gas } }

/-- Depth-first dispatch.  Each step executes the head frame against the shared
world, then prepends the calls that frame's body emitted, so a callee's whole
subtree completes before its caller's next call — matching Solidity ordering. -/
def step (registry : Address → Option Node) (entry : MultiWorld) :
    Nat → MultiWorld → List Pending → Nat → List CompiledCall → TxOutcome
  | _, last, [], hops, prog =>
      { control := .success, hops := hops, entryWorld := entry
        lastWorld := last, program := prog.reverse }
  | 0, last, _ :: _, hops, prog =>
      { control := .exhausted, hops := hops, entryWorld := entry
        lastWorld := last, program := prog.reverse }
  | fuel + 1, last, p :: rest, hops, prog =>
      match registry p.callee with
      | none =>
          { control := .unknownTarget p.callee, hops := hops, entryWorld := entry
            lastWorld := last, program := prog.reverse }
      | some node =>
          let compiled : CompiledCall :=
            { env := node.env, spec := node.spec, fn := node.fn
              selector := node.selector, caller := p.caller, callee := p.callee
              site := p.site }
          match callFunction node.env node.spec node.fn node.selector last
              p.caller p.callee p.site with
          | none =>
              { control := .cannotEnter p.callee, hops := hops, entryWorld := entry
                lastWorld := last, program := prog.reverse }
          | some obs =>
              if obs.result.succeeded then
                let emitted :=
                  (lookup obs.world p.callee).calls.drop obs.frame.calleeBefore.calls.length
                step registry entry fuel obs.world
                  (emitted.map (childPending p.callee p.site.gas) ++ rest)
                  (hops + 1) (compiled :: prog)
              else
                { control := .calleeReverted p.callee, hops := hops + 1
                  entryWorld := entry, lastWorld := obs.world
                  program := (compiled :: prog).reverse }

def account (addr : Address) (balance fee : Nat) : Account :=
  { address := addr
    state :=
      ({ defaultState with thisAddress := addr, selfBalance := balance } :
        ContractState).writeSlot 0 (fee : Core.Uint256) }

def initial (msgValue feePerRequest : Nat) : MultiWorld :=
  { accounts :=
      [ account senderAddr msgValue 0
      , account busAddr 0 0
      , account gatewayAddr 0 feePerRequest
      , account vaultAddr 0 feePerRequest
      , account lidoAddr 0 0
      , account requestAddr 0 0
      , account refundAddr 0 0 ] }

def rootSite (msgValue batchSize : Nat) : CallSite :=
  { siteId := 0
    kind := .call
    target := busAddr.toNat
    value := msgValue
    calldata := [msgValue, batchSize]
    gas := gasBudget }

/-- One consolidation transaction: `senderAddr` calls the Bus with `msgValue`
for a `batchSize` batch, against an ensemble configured with `feePerRequest`. -/
def run (w : Wiring) (msgValue batchSize feePerRequest : Nat) : TxOutcome :=
  let before := initial msgValue feePerRequest
  step (nodeAt w) before fuelBudget before
    [{ caller := senderAddr, callee := busAddr, site := rootSite msgValue batchSize }]
    0 []

/-- Atomicity: anything other than full success restores the entry world. -/
def finalWorld (o : TxOutcome) : MultiWorld :=
  match o.control with
  | .success => o.lastWorld
  | _ => o.entryWorld

/-! ## Outcome observables

The proofs below compare projections of the outcome, never whole worlds. -/

structure BalanceView where
  sender : Nat
  bus : Nat
  gateway : Nat
  vault : Nat
  lido : Nat
  request : Nat
  refund : Nat
  deriving DecidableEq, Repr

def balances (w : MultiWorld) : BalanceView :=
  { sender := (lookup w senderAddr).selfBalance.val
    bus := (lookup w busAddr).selfBalance.val
    gateway := (lookup w gatewayAddr).selfBalance.val
    vault := (lookup w vaultAddr).selfBalance.val
    lido := (lookup w lidoAddr).selfBalance.val
    request := (lookup w requestAddr).selfBalance.val
    refund := (lookup w refundAddr).selfBalance.val }

structure TxView where
  control : TxControl
  hops : Nat
  balances : BalanceView
  deriving DecidableEq, Repr

def observe (o : TxOutcome) : TxView :=
  { control := o.control, hops := o.hops, balances := balances (finalWorld o) }

/-- Projection that drops the atomicity rule — used only to state that dropping
it is observable. -/
def observeWithoutRollback (o : TxOutcome) : TxView :=
  { control := o.control, hops := o.hops, balances := balances o.lastWorld }

/-- Replay the discovered flat program through the merged atomic-multicall
semantics. -/
def replay (o : TxOutcome) : BalanceView :=
  balances (denoteTransaction o.entryWorld o.program).world

/-- Total ETH held by the ensemble after the transaction. -/
def escrowed (o : TxOutcome) : Nat :=
  totalSelfBalance (finalWorld o)

/-! ## Laws

Every statement below compares outcome observables — control, hop count,
per-account balances, total ETH — never a whole `MultiWorld`. -/

/-- On these three witnessed batches, the committing run delivers the entire
per-request fee to the EIP-7251 consolidation-request predeploy and the
remainder to the caller's refund recipient.  No protocol contract on the
route retains ETH, and none reaches an address outside the approved set
(`lido = 0` on the consolidation path).

**Scope.** These three tuples are regression witnesses.  The general
statement is the universal parent
`PEth1CompositionTxUniversal.run_success_shape` (registered as
`Guarantees.PEth1.verity_tx_universal_success_shape`), which proves this
success shape for every funded, guard-passing, non-wrapping batch that fits
`fuelBudget`; each witness below is that theorem instantiated.  Outside the
premises,
`PEth1CompositionTxMutants.large_funded_batch_exhausts_fuel_budget` exhibits
a funded, guard-passing tuple whose dispatch exhausts `fuelBudget` instead of
reaching this success shape. -/
theorem batch_splits_fee_and_refund :
    observe (run honest 10 2 3) =
        ⟨.success, 6, ⟨0, 0, 0, 0, 0, 6, 4⟩⟩ ∧
    observe (run honest 10 1 3) =
        ⟨.success, 5, ⟨0, 0, 0, 0, 0, 3, 7⟩⟩ ∧
    observe (run honest 6 2 3) =
        ⟨.success, 5, ⟨0, 0, 0, 0, 0, 6, 0⟩⟩ := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- A rejecting terminal predeploy discovered three hops deep unwinds the two
transfers that had already committed: the observable is the transaction-entry
balance sheet. -/
theorem rejected_request_restores_entry_world :
    observe (run { honest with requestAccepts := false } 10 2 3) =
      ⟨.calleeReverted requestAddr, 4, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ := by
  decide +kernel

/-- A batch whose fee exceeds `msg.value` is rejected by the Gateway body
before any onward transfer is dispatched. -/
theorem underfunded_batch_reverts_in_gateway :
    observe (run honest 10 4 3) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ := by
  decide +kernel

/-- ETH is conserved across the ensemble on both the committing and the
reverting route. -/
theorem dispatch_conserves_eth :
    escrowed (run honest 10 2 3) = 10 ∧
    escrowed (run honest 6 2 3) = 6 ∧
    escrowed (run { honest with requestAccepts := false } 10 2 3) = 10 := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- Recursive dispatch and the merged atomic-multicall semantics agree: the six
frames were *discovered* by executing the Bus, Gateway and Vault bodies, and
replaying that flattened program through `denoteTransaction` reproduces the
same balance sheet. -/
theorem dispatch_matches_atomic_multicall :
    (run honest 10 2 3).program.length = 6 ∧
    replay (run honest 10 2 3) = (observe (run honest 10 2 3)).balances := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- Auxiliary P-ETH-1 Verity-plane evidence (numeral witnesses plus rollback,
conservation, and replay facts).

A single root call is dispatched into a shared `MultiWorld`; every onward hop
is derived from the journal the executing callee emitted, so the Bus → Gateway
→ Vault → CONSOLIDATION_REQUEST route and the Gateway's refund leg are produced
by the compiled bodies rather than by the harness.  On the five witnessed
`(msgValue, batchSize, feePerRequest)` tuples below, the observables pin down
that (i) the fee reaches only the approved request predeploy and the remainder
only the caller's refund recipient, (ii) ETH is conserved, (iii) a failure
anywhere on the route restores the transaction-entry balance sheet, and (iv)
the recursive dispatch agrees with the atomic compiled-multicall semantics.

**Scope.** The registered Verity-plane parent is the universal
`Guarantees.PEth1.verity_tx_universal_success_shape`
(`PEth1CompositionTxUniversal.run_success_shape`): every funded,
guard-passing, non-wrapping batch within `fuelBudget` reaches the success
shape, of which the three committing witnesses below are instances.  The
fuel-bounded recursive dispatch (`fuelBudget = 32`) and the wrapping
`Expr.mul` in the compiled bodies (report issues 9 and 12) are exactly the
universal parent's premises rather than silent scope limits; see
`PEth1CompositionTxMutants.large_funded_batch_exhausts_fuel_budget` for the
fuel-premise counterexample.  Composition into `P-CONSOLIDATION-1` is out of
scope regardless (`audit/P-ETH-1-COMPOSITION.md`). -/
theorem verity_tx_composes_value_flow_and_rollback :
    (observe (run honest 10 2 3) = ⟨.success, 6, ⟨0, 0, 0, 0, 0, 6, 4⟩⟩ ∧
      observe (run honest 10 1 3) = ⟨.success, 5, ⟨0, 0, 0, 0, 0, 3, 7⟩⟩ ∧
      observe (run honest 6 2 3) = ⟨.success, 5, ⟨0, 0, 0, 0, 0, 6, 0⟩⟩) ∧
    observe (run { honest with requestAccepts := false } 10 2 3) =
      ⟨.calleeReverted requestAddr, 4, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    observe (run honest 10 4 3) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    (escrowed (run honest 10 2 3) = 10 ∧
      escrowed (run honest 6 2 3) = 6 ∧
      escrowed (run { honest with requestAccepts := false } 10 2 3) = 10) ∧
    ((run honest 10 2 3).program.length = 6 ∧
      replay (run honest 10 2 3) = (observe (run honest 10 2 3)).balances) :=
  ⟨batch_splits_fee_and_refund,
   rejected_request_restores_entry_world,
   underfunded_batch_reverts_in_gateway,
   dispatch_conserves_eth,
   dispatch_matches_atomic_multicall⟩

end LidoSRv3.Audit.Verity.PEth1CompositionTx
