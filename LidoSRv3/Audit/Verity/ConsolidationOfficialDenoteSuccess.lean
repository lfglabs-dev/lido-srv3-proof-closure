import LidoSRv3.Audit.Verity.ConsolidationCallFragment
import LidoSRv3.Audit.Verity.ConsolidationValueTx
import Verity.Core.Model.DenoteFunctionCalls

/-!
# Official denotation success on value-bearing request CALLs

`P-CONSOLIDATION-VALUE-1` carried one named OPEN: "this parent keeps the
justified interpreter; it does not claim official denotation success."  This
module discharges exactly that OPEN, at the pinned Verity head
`e977aaad6e1a9e92e0132d41b3d33a14135a4d46`, on the *official upstream*
widened-call denotation `Compiler.CompilationModel.DenoteFunctionCalls`
(`Verity/Core/Model/DenoteFunctionCalls.lean`), not on a local interpreter.

Two distinct official semantic fragments exist at the pin:

* the base fragment `Denote.denoteFunction` still maps `Expr.call` /
  `Stmt.externalCallBind` outside its arms and therefore still reverts on
  the registered bind entrypoint (`ConsolidationBridgeGap.
  official_external_call_reverts` remains true and named — nothing here
  contradicts or hides it, and no compiled-artifact behaviour is claimed);
* the widened fragment `DenoteFunctionCalls.denoteFunctionWithCalls` is
  upstream Verity's canonical `FunctionSpec` denotation of raw and linked
  external calls: it executes `Stmt.externalCallBind` against an explicit
  `CallEnv` (link-time target/value resolution plus an `AdversaryModel`
  for the callee), debits real ETH from `selfBalance`, and journals one
  value-bearing CALL frame per request.

The theorem below is a ∀ statement over that official widened denotation:
for every oracle, every accepting predeploy model, every link target and
fee, and every transaction and world satisfying the source guards
(gateway caller with admitted-nonzero `msg.value`, nonzero aligned keys,
exact `msg.value = 1 * fee` for the single-request bind entrypoint, funded
non-wrapping vault balance), the official denotation of the registered
bind entrypoint `spec.functions[1]`:

1. succeeds (`.success = true`);
2. journals exactly one fresh CALL frame carrying the nonzero `fee`;
3. forwards exactly `msg.value` and re-establishes `preservesEthBalance`;
4. produces only request frames to the linked predeploy — no
   consensus-layer verification frame (`onlyRequestFrames`).

`A-CONSOLIDATION-GATEWAY-NONZERO` stays a named caller premise
(`hGatewayAdmittedNonzero`).  This module does not start the Bus, does not
add delay/quota logic, and does not discharge the gateway premise.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteFunctionCalls
open LidoSRv3.Audit.Verity.ConsolidationCallFragment
open LidoSRv3.Audit.Verity.ConsolidationValueTx

/-- Link-time environment for the registered bind entrypoint: the named
`consolidationPredeploy` external resolves to `target` and carries `fee`
wei on each request frame.  The oracle and the predeploy model are
parameters, not choices made here. -/
def officialEnv (oracle : DenoteOracle) (adversary : AdversaryModel)
    (target fee : Nat) : CallEnv :=
  { oracle := oracle
    adversary := adversary
    resolve := fun name =>
      if name = "consolidationPredeploy" then
        some { target := target, value := fee, siteId := 0 }
      else none }

/-- An accepting EIP-7251 predeploy model: the callee cannot mutate the
vault's own account state (an EVM callee cannot write caller storage or
caller balance except through reentrant frames, which are out of this
fragment), and it answers success with nonempty returndata, so the bind's
result variable binds.  This is the explicit callee-model premise of the
official-success parent; a rejecting predeploy is exhibited as a mutant. -/
def AcceptingPredeploy (adversary : AdversaryModel) : Prop :=
  (∀ site world, adversary.stateTransition site world = world) ∧
  (∀ site world, ∃ data,
    adversary.result site world = .success data ∧ data ≠ [])

/-- Witness model: the predeploy queue accepts and answers one word. -/
def queueAdversary : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun _ _ => .success [1]
    gasUsed := fun _ _ => 0 }

theorem queueAdversary_accepting : AcceptingPredeploy queueAdversary :=
  ⟨fun _ _ => rfl, fun _ _ => ⟨[1], rfl, by simp⟩⟩

/-- No consensus-layer verification in the official run: every fresh
journal frame is a plain CALL to the linked consolidation predeploy.  This
is the denotation-plane counterpart of
`ConsolidationValueTx.noConsensusLayerVerify` (model-plane journal entries
are address-keyed, not name-keyed, so the request-only fact is stated on
`target`/`kind`). -/
def onlyRequestFrames (target : Nat) (before after : ContractState) : Prop :=
  ∀ call ∈ freshCalls before after,
    call.target = target ∧ call.kind = .call

/-- Official denotation of the registered bind entrypoint under the
widened-call fragment. -/
def officialDenote (env : CallEnv) (tx : DenoteTransaction)
    (world : ContractState) : DenoteResult :=
  denoteFunctionWithCalls env spec spec.functions[1] tx world

/-- Composable execution-level result (keeps the post-world). -/
def officialExec (env : CallEnv) (tx : DenoteTransaction)
    (world : ContractState) : FunctionExecution :=
  executeFunctionWithCalls env spec spec.functions[1] tx world

/-- Static two-word ABI binding for the bind entrypoint. -/
private theorem bind_params (sel sourceKey targetKey : Nat)
    (hs : sourceKey < Verity.Core.Uint256.modulus)
    (ht : targetKey < Verity.Core.Uint256.modulus) :
    bindExternalParams sel ConsolidationCallFragment.params
        [sourceKey, targetKey] =
      some [("sourceKey", sourceKey), ("targetKey", targetKey)] := by
  simp [bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord,
    DynamicAbi.wordNormalize, ConsolidationCallFragment.params,
    Nat.mod_eq_of_lt hs, Nat.mod_eq_of_lt ht]

/-- The widened statement interpreter delegates non-call statements to the
base fragment. -/
private theorem execStmtWithCalls_require (env : CallEnv) (fields : List Field)
    (st : DenoteState) (cond : Expr) (msg : String) :
    execStmtWithCalls env fields st (.require cond msg) =
      execStmt env.oracle fields st (.require cond msg) := rfl

private theorem execStmtWithCalls_bind (env : CallEnv) (fields : List Field)
    (st : DenoteState) (resultVars : List String) (name : String)
    (args : List Expr) :
    execStmtWithCalls env fields st (.externalCallBind resultVars name args) =
      execExternalCallBind env fields st resultVars name args := rfl

/-- A passing `require` continues in the same state. -/
private theorem execStmt_require_pass (oracle : DenoteOracle)
    (fields : List Field) (st : DenoteState) (cond : Expr) (msg : String)
    (word : Nat) (heval : evalExpr oracle fields st cond = some word)
    (hword : word ≠ 0) :
    execStmt oracle fields st (.require cond msg) = .continue st := by
  simp [execStmt, heval, hword]

/-- Closed form of one accepting linked call: ETH is debited by exactly the
link value, one value-bearing CALL frame is journaled, and execution
continues. -/
private theorem execExternalCallBind_accepting
    (env : CallEnv) (fields : List Field) (st : DenoteState)
    (resultVars : List String) (name : String) (args : List Expr)
    (link : LinkedExternal) (argWords : List Nat)
    (hresolve : env.resolve name = some link)
    (hargs : evalExprList env.oracle fields st args = some argWords)
    (hfunds : link.value ≤ st.world.selfBalance.val)
    (hIdentity : ∀ site world, env.adversary.stateTransition site world = world)
    (hAccepts : ∀ site world, ∃ data,
      env.adversary.result site world = .success data ∧ data ≠ [])
    (hVars : resultVars.length ≤ 1) :
    ∃ data, data ≠ [] ∧
      execExternalCallBind env fields st resultVars name args =
        .continue
          { st with
            world :=
              { st.world with
                selfBalance :=
                  st.world.selfBalance - (link.value : Verity.Core.Uint256)
                calls := st.world.calls ++
                  [journalEntry
                    { siteId := link.siteId, kind := .call
                      target := link.target, value := link.value
                      calldata := argWords
                      gas := (st.world.selfBalance -
                        (link.value : Verity.Core.Uint256)).val }
                    (.success data)] }
            bindings := bindResultWords st.bindings resultVars data } := by
  obtain ⟨data, hres, hne⟩ := hAccepts
    { siteId := link.siteId, kind := .call, target := link.target
      value := link.value, calldata := argWords
      gas := (st.world.selfBalance - (link.value : Verity.Core.Uint256)).val }
    { st.world with
      selfBalance := st.world.selfBalance - (link.value : Verity.Core.Uint256) }
  refine ⟨data, hne, ?_⟩
  have hlen : ¬ data.length < resultVars.length := by
    have : 0 < data.length := List.length_pos_iff.mpr hne
    omega
  simp only [execExternalCallBind, hresolve, hargs,
    debitSelfBalance_some _ _ hfunds, denoteCallJournaled, denoteCall, hres,
    hIdentity, hlen, if_false]

/-- A continuing head statement passes control to the tail. -/
private theorem execStmtListWithCalls_cons_continue
    (env : CallEnv) (fields : List Field) (st st' : DenoteState)
    (stmt : Stmt) (rest : List Stmt)
    (h : execStmtWithCalls env fields st stmt = .continue st') :
    execStmtListWithCalls env fields st (stmt :: rest) =
      execStmtListWithCalls env fields st' rest := by
  show (match execStmtWithCalls env fields st stmt with
        | .continue next => execStmtListWithCalls env fields next rest
        | .stop next => .stop next
        | .return value next => .return value next
        | .revert => .revert) =
      execStmtListWithCalls env fields st' rest
  rw [h]

/-- A returning head statement decides the list. -/
private theorem execStmtListWithCalls_cons_return
    (env : CallEnv) (fields : List Field) (st st' : DenoteState)
    (stmt : Stmt) (rest : List Stmt) (value : Nat)
    (h : execStmtWithCalls env fields st stmt = .return value st') :
    execStmtListWithCalls env fields st (stmt :: rest) = .return value st' := by
  show (match execStmtWithCalls env fields st stmt with
        | .continue next => execStmtListWithCalls env fields next rest
        | .stop next => .stop next
        | .return value next => .return value next
        | .revert => .revert) = .return value st'
  rw [h]

/-! ## The discharged OPEN: official denotation success

∀ oracle, ∀ accepting predeploy model, ∀ link target and fee, ∀ transaction
and world satisfying the source guards.  The conjuncts are exactly the
campaign-product items: official `.success = true`, one fresh CALL frame
carrying the nonzero fee, forwarded value equal to `msg.value`,
`preservesEthBalance`, the vault back at its pre-credit balance, and only
request frames (no consensus-layer verification frame). -/
theorem official_denote_succeeds_on_value_bearing_request_calls
    (oracle : DenoteOracle) (adversary : AdversaryModel)
    (target fee gateway : Nat)
    (tx : DenoteTransaction) (world : ContractState)
    (sourceKey targetKey : Nat)
    (hAccepting : AcceptingPredeploy adversary)
    (hArgs : tx.args = [sourceKey, targetKey])
    (hSourceAligned : sourceKey < Verity.Core.Uint256.modulus)
    (hTargetAligned : targetKey < Verity.Core.Uint256.modulus)
    (hSourceKey : sourceKey ≠ 0)
    (hTargetKey : targetKey ≠ 0)
    (hCaller : tx.sender = gateway)
    (hGatewayAdmittedNonzero : tx.sender = gateway → tx.msgValue ≠ 0)
    (hExactValue : tx.msgValue = 1 * fee)
    (hFunded : world.selfBalance.val + fee < Verity.Core.Uint256.modulus) :
    (officialDenote (officialEnv oracle adversary target fee) tx world).success
        = true ∧
    fee ≠ 0 ∧
    ((freshCalls (withPayableCallContext world tx)
        (officialExec (officialEnv oracle adversary target fee) tx
          world).world).map (fun call => call.value)) = [fee] ∧
    forwardedValue (withPayableCallContext world tx)
        (officialExec (officialEnv oracle adversary target fee) tx world).world
      = tx.msgValue ∧
    preservesEthBalance (withPayableCallContext world tx)
      (officialExec (officialEnv oracle adversary target fee) tx world).world ∧
    (officialExec (officialEnv oracle adversary target fee) tx
          world).world.selfBalance.val + tx.msgValue
      = (withPayableCallContext world tx).selfBalance.val ∧
    (officialExec (officialEnv oracle adversary target fee) tx
        world).world.selfBalance = world.selfBalance ∧
    onlyRequestFrames target (withPayableCallContext world tx)
      (officialExec (officialEnv oracle adversary target fee) tx world).world := by
  obtain ⟨hIdentity, hAccepts⟩ := hAccepting
  have hFee : fee ≠ 0 := by
    have hMsg := hGatewayAdmittedNonzero hCaller
    omega
  have hFeeLt : fee < Verity.Core.Uint256.modulus := by omega
  have hFeeVal : ((fee : Verity.Core.Uint256) : Nat) = fee := by
    simpa using Nat.mod_eq_of_lt hFeeLt
  have hMsgFee : ((tx.msgValue : Verity.Core.Uint256)) =
      ((fee : Verity.Core.Uint256)) := by
    rw [hExactValue, Nat.one_mul]
  have hEntryVal :
      (withPayableCallContext world tx).selfBalance.val =
        world.selfBalance.val + fee := by
    rw [selfBalance_withPayableCallContext, hMsgFee]
    have := Verity.Core.Uint256.add_eq_of_lt
      (a := world.selfBalance) (b := (fee : Verity.Core.Uint256))
      (by rw [hFeeVal]; exact hFunded)
    rw [this, hFeeVal]
  have hFunds : fee ≤ (withPayableCallContext world tx).selfBalance.val := by
    rw [hEntryVal]; omega
  -- The registered bind entrypoint and its two-word static ABI binding.
  have hBind := bind_params tx.functionSelector sourceKey targetKey
    hSourceAligned hTargetAligned
  set env := officialEnv oracle adversary target fee with hEnvDef
  set fields := effectiveFields spec with hFieldsDef
  set st0 : DenoteState :=
    { world := withPayableCallContext world tx
      bindings := [("sourceKey", sourceKey), ("targetKey", targetKey)]
      selector := tx.functionSelector } with hSt0Def
  -- Both key guards pass.
  have hg1 : execStmtWithCalls env fields st0
      (.require (.lt (.literal 0) (.param "sourceKey")) "empty source key") =
      .continue st0 := by
    rw [execStmtWithCalls_require]
    refine execStmt_require_pass _ _ _ _ _ 1 ?_ one_ne_zero
    simp [evalExpr, lookupValue, hSt0Def, wordNormalize, boolWord,
      Nat.pos_of_ne_zero hSourceKey]
  have hg2 : execStmtWithCalls env fields st0
      (.require (.lt (.literal 0) (.param "targetKey")) "empty target key") =
      .continue st0 := by
    rw [execStmtWithCalls_require]
    refine execStmt_require_pass _ _ _ _ _ 1 ?_ one_ne_zero
    simp [evalExpr, lookupValue, hSt0Def, wordNormalize, boolWord,
      Nat.pos_of_ne_zero hTargetKey]
  -- The linked request call: debit, journal, continue.
  have hresolve : env.resolve "consolidationPredeploy" =
      some { target := target, value := fee, siteId := 0 } := by
    simp [hEnvDef, officialEnv]
  have hargsEval : evalExprList env.oracle fields st0
      [.param "sourceKey", .param "targetKey"] = some [sourceKey, targetKey] := by
    simp [evalExprList, evalExpr, lookupValue, hSt0Def]
  obtain ⟨data, hne, hCall⟩ := execExternalCallBind_accepting env fields st0
    ["ok"] "consolidationPredeploy" [.param "sourceKey", .param "targetKey"]
    { target := target, value := fee, siteId := 0 } [sourceKey, targetKey]
    hresolve hargsEval (by simpa [hSt0Def] using hFunds)
    (by simpa [hEnvDef, officialEnv] using hIdentity)
    (by simpa [hEnvDef, officialEnv] using hAccepts)
    (by simp)
  have hCallStep : execStmtWithCalls env fields st0
      (.externalCallBind ["ok"] "consolidationPredeploy"
        [.param "sourceKey", .param "targetKey"]) = .continue
      { st0 with
        world :=
          { st0.world with
            selfBalance :=
              st0.world.selfBalance - (fee : Verity.Core.Uint256)
            calls := st0.world.calls ++
              [journalEntry
                { siteId := 0, kind := .call, target := target, value := fee
                  calldata := [sourceKey, targetKey]
                  gas := (st0.world.selfBalance -
                    (fee : Verity.Core.Uint256)).val }
                (.success data)] }
        bindings := bindResultWords st0.bindings ["ok"] data } := by
    rw [execStmtWithCalls_bind]
    exact hCall
  -- Whole-body closed form.
  have hBody : execStmtListWithCalls env fields st0
      requestConsolidationBind.body = .return (wordNormalize 1)
      { st0 with
        world :=
          { st0.world with
            selfBalance :=
              st0.world.selfBalance - (fee : Verity.Core.Uint256)
            calls := st0.world.calls ++
              [journalEntry
                { siteId := 0, kind := .call, target := target, value := fee
                  calldata := [sourceKey, targetKey]
                  gas := (st0.world.selfBalance -
                    (fee : Verity.Core.Uint256)).val }
                (.success data)]
            memory := fun offset => if offset = 0 then wordNormalize 1 else
              st0.world.memory offset }
        bindings := bindResultWords st0.bindings ["ok"] data } := by
    show execStmtListWithCalls env fields st0
      (.require (.lt (.literal 0) (.param "sourceKey")) "empty source key" ::
        .require (.lt (.literal 0) (.param "targetKey")) "empty target key" ::
        .externalCallBind ["ok"] "consolidationPredeploy"
          [.param "sourceKey", .param "targetKey"] ::
        .return (.literal 1) :: []) = _
    rw [execStmtListWithCalls_cons_continue _ _ _ _ _ _ hg1,
      execStmtListWithCalls_cons_continue _ _ _ _ _ _ hg2,
      execStmtListWithCalls_cons_continue _ _ _ _ _ _ hCallStep]
    exact execStmtListWithCalls_cons_return _ _ _ _ _ _ _ rfl
  -- Execution-level closed form.
  have hExec : officialExec env tx world =
    { result := .success [wordNormalize 1]
      world :=
        { st0.world with
          selfBalance := st0.world.selfBalance - (fee : Verity.Core.Uint256)
          calls := st0.world.calls ++
            [journalEntry
              { siteId := 0, kind := .call, target := target, value := fee
                calldata := [sourceKey, targetKey]
                gas := (st0.world.selfBalance -
                  (fee : Verity.Core.Uint256)).val }
              (.success data)]
          memory := fun offset => if offset = 0 then wordNormalize 1 else
            st0.world.memory offset } } := by
    simp only [officialExec, executeFunctionWithCalls,
      show spec.functions[1] = requestConsolidationBind from rfl, hArgs,
      show requestConsolidationBind.params = ConsolidationCallFragment.params
        from rfl,
      hBind, ← hFieldsDef, ← hSt0Def, hBody]
  -- Conjuncts.
  have hFreshCalls : freshCalls (withPayableCallContext world tx)
      (officialExec env tx world).world =
      [journalEntry
        { siteId := 0, kind := .call, target := target, value := fee
          calldata := [sourceKey, targetKey]
          gas := (st0.world.selfBalance - (fee : Verity.Core.Uint256)).val }
        (.success data)] := by
    rw [hExec]
    simp [freshCalls, hSt0Def]
  have hSelfBalance : (officialExec env tx world).world.selfBalance =
      (withPayableCallContext world tx).selfBalance -
        (fee : Verity.Core.Uint256) := by
    rw [hExec]
  have hSelfBalanceVal : (officialExec env tx world).world.selfBalance.val =
      world.selfBalance.val := by
    rw [hSelfBalance, Verity.Core.Uint256.sub_eq_of_le
      (by rw [hFeeVal]; exact hFunds), hEntryVal, hFeeVal]
    omega
  refine ⟨?_, hFee, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · show (denoteFunctionWithCalls env spec spec.functions[1] tx world).success
        = true
    simp only [denoteFunctionWithCalls,
      show executeFunctionWithCalls env spec spec.functions[1] tx world =
        officialExec env tx world from rfl,
      hExec, successResult]
  · rw [hFreshCalls]
    simp [journalEntry]
  · rw [forwardedValue, hFreshCalls, hExactValue]
    simp [journalEntry]
  · show (officialExec env tx world).world.selfBalance =
      (withPayableCallContext world tx).selfBalance -
        (withPayableCallContext world tx).msgValue
    rw [hSelfBalance,
      show (withPayableCallContext world tx).msgValue =
        ((tx.msgValue : Verity.Core.Uint256)) from rfl, hMsgFee]
  · rw [hSelfBalanceVal, hEntryVal, hExactValue]
    omega
  · exact Verity.Core.Uint256.ext hSelfBalanceVal
  · intro call hmem
    rw [hFreshCalls] at hmem
    rcases List.mem_singleton.mp hmem with rfl
    exact ⟨rfl, rfl⟩

end LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess
