import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-!
# P-CONSOLIDATION-ETH-1: universal Verity-plane revert shapes

This module lifts the P-CONSOLIDATION-ETH-1 Verity plane's non-success arms from the four
numeral witnesses of
`PConsolidationEth1CompositionTx.honest_revert_partition` to universal (`∀`) statements,
matching the revert clauses of the abstract parent `eth_flow_parent`:

```
msgValue = 0                    → calleeReverted gatewayAddr, 2 hops, entry rollback
2^256 ≤ batchSize * feePerRequest → calleeReverted gatewayAddr, 2 hops, entry rollback
batchSize * feePerRequest > msgValue (no wrap)
                                → calleeReverted gatewayAddr, 2 hops, entry rollback
funded, guard-passing, no-wrap, but the batch needs more frames than fuelBudget
                                → exhausted, fuelBudget hops, entry rollback
```

Every arm is read through `observe`, i.e. through `finalWorld`, so each statement also
asserts transaction-entry rollback, not only a control tag.  The three gateway-revert arms
are proved by executing the Gateway body symbolically until the failing `require`
(`ZeroArgument`, the post-`mul` wrap check `Panic(0x11)`, `InsufficientValue`); the fuel arm
is proved by the same `request_phase` induction as the success parent, run for exactly
`fuelBudget - 3` request hops until the dispatcher reports `TxControl.exhausted`.

The success/exhaustion boundary is exact: a funded batch commits iff it needs at most
`fuelBudget` frames (`batchSize + 3` when the remainder is zero, `batchSize + 4` otherwise).
`run_success_at_zero_remainder_boundary` covers the zero-remainder corner
(`batchSize + 3 = fuelBudget`) that the registered success parent's conservative
`batchSize + 4 ≤ fuelBudget` premise excludes, so the registered partition classifies every
word-sized input.

Hypotheses are explicit and load-bearing: the positivity/word-size/no-wrap/funding premises
are exactly the abstract parent's non-revert conditions, and the fuel premise is the model's
`fuelBudget = 32` dispatch bound (report issues 9 and 12).

This is a model-plane ensemble.  It does not claim that the corresponding Lido
Solidity functions have been compiled by Verity.
-/

namespace LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversalRevert

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteFunctionCalls
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
open LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal

/-- The transaction-entry balance sheet: the sender holds the whole `msgValue`,
every protocol account is zero. -/
theorem balances_initial (mv fee : Nat) (hmv : mv < Core.Uint256.modulus) :
    balances (initial mv fee) = ⟨mv, 0, 0, 0, 0, 0, 0⟩ := by
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  simp [balances, lookup_initial_sender_balance, lookup_initial_bus_balance,
    lookup_initial_gateway_balance, lookup_initial_vault_balance, lookup_initial_lido_balance,
    lookup_initial_request_balance, lookup_initial_refund_balance, hmv']

/-! ## Gateway body reverts -/

/-- The Gateway body under the honest wiring on a zero-value call: the
declared-value check passes (`0 == 0`) and the `ZeroArgument` guard reverts
before any onward call is journaled. -/
theorem gateway_body_reverts_zero (w : ContractState) (n callerNat thisNat : Nat) :
    executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
      (gwTx 0 n callerNat thisNat) w =
    { result := .revert [],
      world := withPayableCallContext w (gwTx 0 n callerNat thisNat) } := by
  simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
    effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
    execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
    boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
    wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
    link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
    debitSelfBalance, bindResultWords, honest]

/-- The wrapped product never divides back to the per-request fee: if
`(n * fee) % 2^256 / n = fee` then `n * fee ≤ (n * fee) % 2^256 < 2^256`. -/
theorem wrapped_div_ne (n fee : Nat) (hn : n ≠ 0)
    (hover : Core.Uint256.modulus ≤ n * fee) :
    (n * fee) % Core.Uint256.modulus / n ≠ fee := by
  intro h
  have hle1 : (n * fee) % Core.Uint256.modulus / n * n ≤ (n * fee) % Core.Uint256.modulus :=
    Nat.div_mul_le_self _ _
  have hlt : (n * fee) % Core.Uint256.modulus < Core.Uint256.modulus :=
    Nat.mod_lt _ Core.Uint256.modulus_pos
  rw [h] at hle1
  have hfn : fee * n = n * fee := Nat.mul_comm fee n
  omega

/-- Word-level form of `wrapped_div_ne`, in exactly the shape the Gateway's
post-`mul` guard evaluates: the stored per-request fee is never recovered by
dividing the wrapped product back by the batch size. -/
theorem wrapped_div_ofNat_val_ne (n fee : Nat) (hn : n ≠ 0)
    (hnM : n < Core.Uint256.modulus)
    (hover : Core.Uint256.modulus ≤ n * fee) :
    (Core.Uint256.ofNat (n * fee % Core.Uint256.modulus) /
        Core.Uint256.ofNat n).val ≠ fee := by
  have ha : n * fee % Core.Uint256.modulus < Core.Uint256.modulus :=
    Nat.mod_lt _ Core.Uint256.modulus_pos
  have hnM' : n % Core.Uint256.modulus ≠ 0 := by
    rw [Nat.mod_eq_of_lt hnM]; exact hn
  rw [div_ofNat_of_ne_zero _ n hnM', Core.Uint256.val_ofNat,
    Nat.mod_eq_of_lt ha, Nat.mod_eq_of_lt hnM,
    Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt
      (Nat.div_le_self (n * fee % Core.Uint256.modulus) n) ha)]
  exact wrapped_div_ne n fee hn hover

/-- The Gateway body under the honest wiring on a batch whose product fee wraps
the 256-bit word: the `ZeroArgument` guard passes, the post-`mul` wrap check
(`fee / batchSize == feePerRequest`) fails, and the body reverts
(`Panic(0x11)`) before any onward call is journaled. -/
theorem gateway_body_reverts_overflow (w : ContractState) (mv n fee callerNat thisNat : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus) (hn : n ≠ 0)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hover : Core.Uint256.modulus ≤ n * fee)
    (hstorage : w.readSlot 0 = Core.Uint256.ofNat fee) :
    executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
      (gwTx mv n callerNat thisNat) w =
    { result := .revert [],
      world := withPayableCallContext w (gwTx mv n callerNat thisNat) } := by
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hnM' : n % Core.Uint256.modulus = n := Nat.mod_eq_of_lt hnM
  have hfee' : fee % Core.Uint256.modulus = fee := Nat.mod_eq_of_lt hfee
  have hwrap : (Core.Uint256.ofNat (n * fee % Core.Uint256.modulus) /
      Core.Uint256.ofNat n).val ≠ fee := wrapped_div_ofNat_val_ne n fee hn hnM hover
  have hstorageW : w.storageWords (StorageKey.slot 0) = Core.Uint256.ofNat fee := hstorage
  simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
    effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
    execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
    boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
    wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
    link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
    debitSelfBalance, bindResultWords, honest, hpos, hmv', hnM', hn, hfee',
    gateway_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
    hstorageW, mul_ofNat_val, hwrap]

/-- The Gateway body under the honest wiring on a funded-check-failing batch:
the wrap check divides back (no wrap), and the `InsufficientValue` guard
(`fee ≤ amount`) reverts before any onward call is journaled. -/
theorem gateway_body_reverts_underfunded (w : ContractState) (mv n fee callerNat thisNat : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hfee : fee < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus)
    (hgt : mv < n * fee)
    (hstorage : w.readSlot 0 = Core.Uint256.ofNat fee) :
    executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
      (gwTx mv n callerNat thisNat) w =
    { result := .revert [],
      world := withPayableCallContext w (gwTx mv n callerNat thisNat) } := by
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hnM' : n % Core.Uint256.modulus = n := Nat.mod_eq_of_lt hnM
  have hnf' : (n * fee) % Core.Uint256.modulus = n * fee := Nat.mod_eq_of_lt hnf
  have hn : n ≠ 0 := by
    intro h0
    subst h0
    simp at hgt
  have hdiv : Core.Uint256.ofNat (n * fee) / Core.Uint256.ofNat n = Core.Uint256.ofNat fee :=
    div_mul_ofNat n fee hn hnM hnf
  have hle : ¬ n * fee ≤ mv := Nat.not_le.mpr hgt
  have hstorageW : w.storageWords (StorageKey.slot 0) = Core.Uint256.ofNat fee := hstorage
  simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
    effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
    execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
    boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
    wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
    link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
    debitSelfBalance, bindResultWords, honest, hpos, hmv', hnM', hn, hnf',
    gateway_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
    hstorageW, mul_ofNat_val, hdiv, hle]

/-! ## Reverted gateway frame and dispatcher step -/

/-- The world after a reverted gateway frame: the bus journal records the
revert and the gateway snapshot is restored (the value transfer is rolled
back).  `observe` never reads this world — `finalWorld` returns the
transaction-entry world — but the frame equation pins it exactly. -/
def gwRevertWorld (mv n fee : Nat) : MultiWorld :=
  upsert (upsert (busPostWorld mv n fee) busAddr
      { lookup (busPostWorld mv n fee) busAddr with
        calls := (lookup (busPostWorld mv n fee) busAddr).calls ++
          [journalEntry (gwSite mv n) (.revert [])] })
    gatewayAddr (lookup (busPostWorld mv n fee) gatewayAddr)

/-- The gateway frame on the bus post-world when the gateway body reverts, as
one equation. -/
theorem gateway_frame_reverts (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus)
    (hbody : executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
        (gwTx mv n busAddr.toNat gatewayAddr.toNat)
        (lookup (busPostWorld mv n fee) gatewayAddr) =
      { result := .revert [],
        world := withPayableCallContext (lookup (busPostWorld mv n fee) gatewayAddr)
          (gwTx mv n busAddr.toNat gatewayAddr.toNat) }) :
    callFunction (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest) 2
        (busPostWorld mv n fee) busAddr gatewayAddr (gwSite mv n) =
      some { frame := gwFrame mv n fee, result := .revert [],
             world := gwRevertWorld mv n fee } := by
  have hne : (busAddr ≠ gatewayAddr) := by decide
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hbal := lookup_busPostWorld_bus_balance mv n fee
  simp only [gwTx] at hbody
  unfold callFunction MultiContract.call
  simp [callEntry, hne, hbal, hmv', gwSite, gwFrame, gwRevertWorld,
    executeCall, runFunctionInFrame, framedJournalEntry, hbody]

/-- Dispatch of the gateway pending when the gateway frame reverts: the whole
transaction aborts with `.calleeReverted gatewayAddr` after one more hop. -/
theorem hop_gateway_revert (mv n fee f h : Nat) (prog : List CompiledCall)
    (hcall : ∃ obs, callFunction (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest) 2
        (busPostWorld mv n fee) busAddr gatewayAddr (gwSite mv n) = some obs ∧
      obs.result.succeeded = false) :
    ∃ W : MultiWorld,
      step (nodeAt honest) (initial mv fee) (f + 1) (busPostWorld mv n fee)
          [gwPending mv n] h prog =
        { control := .calleeReverted gatewayAddr, hops := h + 1,
          entryWorld := initial mv fee, lastWorld := W,
          program := (gwCompiled mv n :: prog).reverse } := by
  obtain ⟨obs, hsome, hfail⟩ := hcall
  refine ⟨obs.world, ?_⟩
  simp only [step, gwPending]
  simp only [show nodeAt honest gatewayAddr =
      some { env := gatewayEnv honest, spec := gatewaySpec honest, fn := gatewayFn honest,
             selector := 2 } from rfl]
  rw [hsome]
  simp [hfail, gwCompiled]

/-- Two-hop gateway-revert run, observable level: after the committing bus hop
and the reverting gateway hop, the observable is `.calleeReverted gatewayAddr`
at two hops with the transaction-entry balance sheet. -/
theorem observe_run_reverts_gateway (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hcall : ∃ obs, callFunction (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest) 2
        (busPostWorld mv n fee) busAddr gatewayAddr (gwSite mv n) = some obs ∧
      obs.result.succeeded = false) :
    observe (run honest mv n fee) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨mv, 0, 0, 0, 0, 0, 0⟩⟩ := by
  unfold run
  rw [show fuelBudget = 31 + 1 from rfl]
  rw [hop_bus mv n fee 31 0 [] hmv hnM]
  show observe (step (nodeAt honest) (initial mv fee) 31 (busPostWorld mv n fee)
    [gwPending mv n] 1 [busCompiled mv n]) = _
  obtain ⟨W, hstep⟩ := hop_gateway_revert mv n fee 30 1 [busCompiled mv n] hcall
  rw [hstep]
  simp only [observe, finalWorld]
  rw [balances_initial mv fee hmv]

/-- Packaging: any gateway-body revert hypothesis yields the two-hop
gateway-revert observable with entry rollback. -/
theorem run_reverts_at_gateway (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hbody : executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
        (gwTx mv n busAddr.toNat gatewayAddr.toNat)
        (lookup (busPostWorld mv n fee) gatewayAddr) =
      { result := .revert [],
        world := withPayableCallContext (lookup (busPostWorld mv n fee) gatewayAddr)
          (gwTx mv n busAddr.toNat gatewayAddr.toNat) }) :
    observe (run honest mv n fee) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨mv, 0, 0, 0, 0, 0, 0⟩⟩ :=
  observe_run_reverts_gateway mv n fee hmv hnM
    ⟨{ frame := gwFrame mv n fee, result := .revert [], world := gwRevertWorld mv n fee },
      gateway_frame_reverts mv n fee hmv hbody, rfl⟩

/-! ## The three universal gateway-revert arms -/

/-- **Universal zero-value revert (Verity plane).**  Every zero-value call —
any word-sized batch size, any stored fee — reverts at the Gateway
`ZeroArgument` guard after two entered frames and rolls back to the
transaction-entry balance sheet.  This is the Verity-plane form of the
abstract parent's first clause. -/
theorem run_zero_value_reverts (n fee : Nat)
    (hnM : n < Core.Uint256.modulus) :
    observe (run honest 0 n fee) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨0, 0, 0, 0, 0, 0, 0⟩⟩ :=
  run_reverts_at_gateway 0 n fee Core.Uint256.modulus_pos hnM
    (gateway_body_reverts_zero _ _ _ _)

/-- **Universal overflow revert (Verity plane).**  Every positive-valued,
word-sized batch whose product fee reaches `2^256` fails the post-`mul` wrap
check (`Panic(0x11)`) at the Gateway after two entered frames and rolls back
to the transaction-entry balance sheet.  This is the Verity-plane form of the
abstract parent's overflow clause; the wrapping `Expr.mul` (report issue 12)
is exactly what the wrap check catches. -/
theorem run_overflow_reverts (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus) (hn : 0 < n)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hover : Core.Uint256.modulus ≤ n * fee) :
    observe (run honest mv n fee) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨mv, 0, 0, 0, 0, 0, 0⟩⟩ := by
  have hstorage : (lookup (busPostWorld mv n fee) gatewayAddr).readSlot 0 =
      Core.Uint256.ofNat fee := by
    rw [lookup_busPostWorld_gateway, lookup_initial_gateway_fee]
  exact run_reverts_at_gateway mv n fee hmv hnM
    (gateway_body_reverts_overflow _ mv n fee _ _
      hpos hmv (Nat.pos_iff_ne_zero.mp hn) hnM hfee hover hstorage)

/-- **Universal underfunded revert (Verity plane).**  Every positive-valued,
word-sized, non-wrapping batch whose product fee exceeds `msg.value` reverts
at the Gateway `InsufficientValue` guard after two entered frames and rolls
back to the transaction-entry balance sheet.  This is the Verity-plane form of
the abstract parent's third clause. -/
theorem run_underfunded_reverts (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hgt : mv < n * fee) :
    observe (run honest mv n fee) =
      ⟨.calleeReverted gatewayAddr, 2, ⟨mv, 0, 0, 0, 0, 0, 0⟩⟩ := by
  have hstorage : (lookup (busPostWorld mv n fee) gatewayAddr).readSlot 0 =
      Core.Uint256.ofNat fee := by
    rw [lookup_busPostWorld_gateway, lookup_initial_gateway_fee]
  exact run_reverts_at_gateway mv n fee hmv hnM
    (gateway_body_reverts_underfunded _ mv n fee _ _ hpos hmv hnM hfee hnf hgt hstorage)

/-! ## Fuel exhaustion arm -/

/-- **Universal fuel exhaustion (Verity plane).**  Every positive-valued,
word-sized, non-wrapping, funded batch whose dispatch needs more than
`fuelBudget` frames — i.e. `batchSize ≥ fuelBudget - 3`, with a strictly
larger batch or a nonzero remainder still pending at the boundary — reports
`TxControl.exhausted` after exactly `fuelBudget` entered frames and rolls back
to the transaction-entry balance sheet.  This is the general form of the
`(30, 29, 1)` witness (report issue 9): 3 route frames plus 29 request frames
consume the whole budget. -/
theorem run_exhausts_fuel (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hbig : 29 ≤ n) (hpend : 29 < n ∨ 0 < mv - n * fee) :
    observe (run honest mv n fee) =
      ⟨.exhausted, fuelBudget, ⟨mv, 0, 0, 0, 0, 0, 0⟩⟩ := by
  unfold run
  rw [show fuelBudget = 31 + 1 from rfl]
  rw [hop_bus mv n fee 31 0 [] hmv hnM]
  show observe (step (nodeAt honest) (initial mv fee) 31 (busPostWorld mv n fee)
    [gwPending mv n] 1 [busCompiled mv n]) = _
  rw [hop_gateway mv n fee 30 1 [busCompiled mv n] hpos hmv hnM hnf hle]
  show observe (step (nodeAt honest) (initial mv fee) 30 (gwPostWorld mv n fee)
    (vaultPending n fee :: (if mv - n * fee = 0 then [] else [refundPending mv n fee])) 2
    [gwCompiled mv n, busCompiled mv n]) = _
  rw [hop_vault mv n fee 29 2 _ hmv hnM hfee hnf hle]
  show observe (step (nodeAt honest) (initial mv fee) 29 (vaultPostWorld mv n fee)
    (List.replicate n (requestPending fee) ++
      (if mv - n * fee = 0 then [] else [refundPending mv n fee])) 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]) = _
  have hsplit : n = 29 + (n - 29) := by omega
  have hrep : List.replicate n (requestPending fee) =
      List.replicate 29 (requestPending fee) ++ List.replicate (n - 29) (requestPending fee) := by
    rw [List.replicate_append_replicate, ← hsplit]
  rw [hrep, List.append_assoc]
  show observe (step (nodeAt honest) (initial mv fee) (29 + 0) (vaultPostWorld mv n fee)
    (List.replicate 29 (requestPending fee) ++
      (List.replicate (n - 29) (requestPending fee) ++
        (if mv - n * fee = 0 then [] else [refundPending mv n fee]))) 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]) = _
  rw [request_phase 29 (initial mv fee) (vaultPostWorld mv n fee) fee 0 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]
    (List.replicate (n - 29) (requestPending fee) ++
      (if mv - n * fee = 0 then [] else [refundPending mv n fee]))
    (fun j hj => request_phase_guard mv n fee hfee hnf j (by omega))]
  have hcons : ∃ p ps, List.replicate (n - 29) (requestPending fee) ++
      (if mv - n * fee = 0 then [] else [refundPending mv n fee]) = p :: ps := by
    by_cases hlt : 29 < n
    · obtain ⟨k, hk⟩ : ∃ k, n - 29 = k + 1 := ⟨n - 30, by omega⟩
      exact ⟨requestPending fee,
        List.replicate k (requestPending fee) ++
          (if mv - n * fee = 0 then [] else [refundPending mv n fee]), by
        rw [hk, List.replicate_succ, List.cons_append]⟩
    · have hn29 : n = 29 := by omega
      have hz : mv - n * fee ≠ 0 := by
        rcases hpend with h | h
        · omega
        · exact Nat.pos_iff_ne_zero.mp h
      exact ⟨refundPending mv n fee, [], by rw [hn29] at hz ⊢; simp [hz]⟩
  obtain ⟨p, ps, hps⟩ := hcons
  rw [hps]
  simp only [step]
  simp only [observe, finalWorld]
  rw [balances_initial mv fee hmv]

/-! ## Exact fuel boundary: the zero-remainder corner -/

/-- **Zero-remainder boundary success.**  A funded batch whose fee consumes
`msgValue` exactly (no refund leg) needs only `batchSize + 3` frames, so it
still commits when `batchSize + 3 = fuelBudget` — the corner the registered
success parent's conservative `batchSize + 4 ≤ fuelBudget` premise excludes.
Together with `run_success_shape` and `run_exhausts_fuel` this makes the
success/exhaustion classification of word-sized inputs exact. -/
theorem run_success_at_zero_remainder_boundary (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hz : mv - n * fee = 0) (hfuel : n + 3 ≤ fuelBudget) :
    observe (run honest mv n fee) =
      ⟨.success, n + 3, ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩⟩ := by
  have hn29 : n ≤ 29 := by
    have : fuelBudget = 32 := rfl
    omega
  unfold run
  rw [show fuelBudget = 31 + 1 from rfl]
  rw [hop_bus mv n fee 31 0 [] hmv hnM]
  show observe (step (nodeAt honest) (initial mv fee) 31 (busPostWorld mv n fee)
    [gwPending mv n] 1 [busCompiled mv n]) = _
  rw [hop_gateway mv n fee 30 1 [busCompiled mv n] hpos hmv hnM hnf hle]
  show observe (step (nodeAt honest) (initial mv fee) 30 (gwPostWorld mv n fee)
    (vaultPending n fee :: (if mv - n * fee = 0 then [] else [refundPending mv n fee])) 2
    [gwCompiled mv n, busCompiled mv n]) = _
  rw [hop_vault mv n fee 29 2 _ hmv hnM hfee hnf hle]
  show observe (step (nodeAt honest) (initial mv fee) 29 (vaultPostWorld mv n fee)
    (List.replicate n (requestPending fee) ++
      (if mv - n * fee = 0 then [] else [refundPending mv n fee])) 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]) = _
  rw [show (29 : Nat) = n + (29 - n) from by omega]
  rw [request_phase n (initial mv fee) (vaultPostWorld mv n fee) fee (29 - n) 3
    [vaultCompiled n fee, gwCompiled mv n, busCompiled mv n]
    (if mv - n * fee = 0 then [] else [refundPending mv n fee])
    (request_phase_guard mv n fee hfee hnf)]
  rw [if_pos hz]
  simp only [step]
  simp only [observe, finalWorld]
  rw [balances_phase4 mv n fee hmv hfee hnf hle hz]
  simp only [TxView.mk.injEq]
  exact ⟨trivial, by omega, trivial⟩

end LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversalRevert
