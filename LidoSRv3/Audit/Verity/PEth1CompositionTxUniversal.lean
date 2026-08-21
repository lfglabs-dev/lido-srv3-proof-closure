import LidoSRv3.Audit.Verity.PEth1CompositionTx

/-!
# P-ETH-1: universal Verity-plane success shape

This module lifts the P-ETH-1 Verity plane from the five numeral witnesses of
`PEth1CompositionTx.verity_tx_composes_value_flow_and_rollback` to a universal
(`∀`) statement over funded, guard-passing, non-wrapping batches that fit the
dispatch fuel budget:

```
observe (run honest msgValue batchSize feePerRequest) =
  ⟨.success, batchSize + 3 + (if msgValue - batchSize * feePerRequest = 0 then 0 else 1),
    ⟨0, 0, 0, 0, 0, batchSize * feePerRequest, msgValue - batchSize * feePerRequest⟩⟩
```

The proof is a frame-by-frame chain through the recursive dispatcher
(`PEth1CompositionTx.step`): the root Bus hop, the Gateway hop (which journals
the vault leg and, when the remainder is positive, the refund leg), the Vault
hop (which journals `batchSize` consolidation-request legs), an induction over
the request phase, and the optional refund hop.  Every account balance in the
final sheet is computed symbolically from the iterated world.

## Premises and why they are load-bearing

- `0 < msgValue`: the Gateway body opens with a `ZeroArgument` guard (matching
  the abstract parent's `gatewayExecute`, which reverts `ZeroArgument` at
  `msgValue = 0`).  A zero-value call reverts instead of reaching the success
  shape.
- `msgValue < 2^256`, `batchSize < 2^256`, `feePerRequest < 2^256`,
  `batchSize * feePerRequest < 2^256`: the compiled bodies compute with
  wrapping `Expr.mul`/`Expr.sub` on 256-bit words; the no-wrap premises make
  the observed Uint256 arithmetic agree with the Nat arithmetic in the
  conclusion.
- `batchSize * feePerRequest ≤ msgValue`: the Gateway's `InsufficientValue`
  guard reverts underfunded batches.
- `batchSize + 4 ≤ fuelBudget`: the dispatcher is fuel-bounded
  (`fuelBudget = 32`); a batch of `n` requests needs `n + 3` frames when the
  remainder is zero and `n + 4` when it is not.

Each premise is refuted as droppable by an executable counterexample in
`LidoSRv3.Tests.PEth1CompositionTxMutants` (zero-value, underfunded, and
fuel-exhaustion kill-lines), and the honest wiring is refuted as replaceable by
four wiring-mutant kill-lines on the same universal predicate.

This is a model-plane ensemble.  It does not claim that the corresponding Lido
Solidity functions have been compiled by Verity.
-/

namespace LidoSRv3.Audit.Verity.PEth1CompositionTxUniversal

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteFunctionCalls
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PEth1CompositionTx

/-! ## MultiWorld lookup/upsert laws -/

private theorem upsert_eq_map (w : MultiWorld) (a : Address) (s : ContractState)
    (h : (w.accounts.any (fun x => x.address == a)) = true) :
    upsert w a s =
      { accounts := w.accounts.map (fun x => if x.address == a then
          { x with state := s } else x) } := by
  unfold upsert
  rw [if_pos h]

private theorem upsert_eq_append (w : MultiWorld) (a : Address) (s : ContractState)
    (h : (w.accounts.any (fun x => x.address == a)) = false) :
    upsert w a s = { accounts := w.accounts ++ [{ address := a, state := s }] } := by
  unfold upsert
  rw [if_neg]
  simpa using h

/-- `lookup` on a literal world, with the projection already reduced.  Used as a
controlled rewrite so `simp` does not pre-empt `find?_map_update` with its own
`List.find?_map` rewrite. -/
private theorem lookup_mk (l : List Account) (b : Address) :
    lookup { accounts := l } b =
      (match l.find? (fun x => x.address == b) with
        | some a => a.state | none => defaultState) := rfl

/-- The upsert map preserves the address projection, so finding any address in
the mapped list composes with the map. -/
private theorem find?_map_update (accounts : List Account) (a : Address) (s : ContractState)
    (b : Address) :
    (accounts.map (fun x => if x.address == a then { x with state := s } else x)).find?
        (fun y => y.address == b) =
      (accounts.find? (fun x => x.address == b)).map
        (fun x => if x.address == a then { x with state := s } else x) := by
  rw [List.find?_map]
  have hf : (fun y : Account => y.address == b) ∘
        (fun x : Account => if x.address == a then ({ x with state := s } : Account) else x) =
      (fun y : Account => y.address == b) := by
    funext x
    by_cases hxa : x.address = a <;> simp [Function.comp_apply, hxa]
  rw [hf]

theorem lookup_upsert_same (w : MultiWorld) (a : Address) (s : ContractState) :
    lookup (upsert w a s) a = s := by
  by_cases hAny : (w.accounts.any (fun x => x.address == a)) = true
  · rw [upsert_eq_map w a s hAny]
    obtain ⟨y, hy⟩ : ∃ y, w.accounts.find? (fun x => x.address == a) = some y := by
      have hh : (w.accounts.find? (fun x => x.address == a)).isSome :=
        List.find?_isSome.mpr (List.any_eq_true.mp hAny)
      exact Option.isSome_iff_exists.mp hh
    have hyt := List.find?_some hy
    rw [lookup_mk, find?_map_update, hy]
    simp [beq_iff_eq.mp hyt]
  · have hAny' : (w.accounts.any (fun x => x.address == a)) = false := by
      simpa using hAny
    rw [upsert_eq_append w a s hAny']
    have hnone : w.accounts.find? (fun x => x.address == a) = none := by
      rw [List.find?_eq_none]
      intro x hx
      have hf := (List.any_eq_false.mp hAny') x hx
      simpa using hf
    simp [lookup, List.find?_append, hnone]

theorem lookup_upsert_diff (w : MultiWorld) (a : Address) (s : ContractState) (b : Address)
    (h : a ≠ b) :
    lookup (upsert w a s) b = lookup w b := by
  by_cases hAny : (w.accounts.any (fun x => x.address == a)) = true
  · rw [upsert_eq_map w a s hAny]
    cases hfind : w.accounts.find? (fun x => x.address == b) with
    | none =>
        rw [lookup_mk, find?_map_update, hfind]
        simp [lookup, hfind]
    | some y =>
        have hyt := List.find?_some hfind
        have hya : (y.address == a) = false := by
          apply beq_eq_false_iff_ne.mpr
          intro heq
          exact h (heq.symm.trans (beq_iff_eq.mp hyt))
        rw [lookup_mk, find?_map_update, hfind]
        simp [lookup, hfind, beq_eq_false_iff_ne.mp hya]
  · have hAny' : (w.accounts.any (fun x => x.address == a)) = false := by
      simpa using hAny
    rw [upsert_eq_append w a s hAny']
    have hb : (a == b) = false := beq_eq_false_iff_ne.mpr h
    simp [lookup, List.find?_append, hb]

/-! ## Uint256 surface-syntax rewrite toolkit

Each lemma is stated with the `ofNat`/notation form that `evalExpr` produces,
and proved by definitional unfolding (`show`) plus the library def and Nat
lemmas. -/

/-- Product of two `ofNat`s is `ofNat` of the product. -/
theorem mul_ofNat (x y : Nat) :
    Core.Uint256.ofNat x * Core.Uint256.ofNat y = Core.Uint256.ofNat (x * y) :=
  Core.Uint256.ext (Nat.mul_mod x y _).symm

/-- Value form of `mul_ofNat`. -/
theorem mul_ofNat_val (x y : Nat) :
    (Core.Uint256.ofNat x * Core.Uint256.ofNat y).val = (x * y) % Core.Uint256.modulus :=
  (Nat.mul_mod x y _).symm

/-- `ofNat` equality is residue equality. -/
theorem ofNat_eq_iff (x y : Nat) :
    Core.Uint256.ofNat x = Core.Uint256.ofNat y ↔
      x % Core.Uint256.modulus = y % Core.Uint256.modulus :=
  ⟨fun h => congrArg Core.Uint256.val h, fun h => Core.Uint256.ext h⟩

/-- `ofNat` ≤ is residue ≤. -/
theorem ofNat_le_iff (x y : Nat) :
    Core.Uint256.ofNat x ≤ Core.Uint256.ofNat y ↔
      x % Core.Uint256.modulus ≤ y % Core.Uint256.modulus :=
  Iff.rfl

/-- `ofNat` < is residue <. -/
theorem ofNat_lt_iff (x y : Nat) :
    Core.Uint256.ofNat x < Core.Uint256.ofNat y ↔
      x % Core.Uint256.modulus < y % Core.Uint256.modulus :=
  Iff.rfl

/-- Division of `ofNat`s with zero (wrapped) divisor is `ofNat 0`. -/
theorem div_ofNat_eq_zero (x y : Nat) (hy : y % Core.Uint256.modulus = 0) :
    Core.Uint256.ofNat x / Core.Uint256.ofNat y = Core.Uint256.ofNat 0 := by
  show Core.Uint256.div (Core.Uint256.ofNat x) (Core.Uint256.ofNat y) = _
  simp [Core.Uint256.div, Core.Uint256.ofNat, hy]

/-- Division of `ofNat`s with nonzero (wrapped) divisor. -/
theorem div_ofNat_of_ne_zero (x y : Nat) (hy : y % Core.Uint256.modulus ≠ 0) :
    Core.Uint256.ofNat x / Core.Uint256.ofNat y =
      Core.Uint256.ofNat ((x % Core.Uint256.modulus) / (y % Core.Uint256.modulus)) := by
  show Core.Uint256.div (Core.Uint256.ofNat x) (Core.Uint256.ofNat y) = _
  simp [Core.Uint256.div, Core.Uint256.ofNat, hy]

/-- Subtraction of `ofNat`s when the wrapped subtraction does not underflow. -/
theorem sub_ofNat (x y : Nat)
    (h : y % Core.Uint256.modulus ≤ x % Core.Uint256.modulus) :
    Core.Uint256.ofNat x - Core.Uint256.ofNat y =
      Core.Uint256.ofNat (x % Core.Uint256.modulus - y % Core.Uint256.modulus) := by
  show Core.Uint256.sub (Core.Uint256.ofNat x) (Core.Uint256.ofNat y) = _
  simp [Core.Uint256.sub, Core.Uint256.ofNat, h]

/-- The panic-check shape: `(n * fee) / n = fee` as Uint256s, given no wrap. -/
theorem mul_div_ofNat_self (n fee : Nat) (hn : n ≠ 0)
    (hnf : n * fee < Core.Uint256.modulus) :
    (Core.Uint256.ofNat n * Core.Uint256.ofNat fee) / Core.Uint256.ofNat n =
      Core.Uint256.ofNat fee := by
  rw [mul_ofNat]
  by_cases hfee : fee = 0
  · subst hfee
    rw [Nat.mul_zero]
    by_cases hnM : n % Core.Uint256.modulus = 0
    · rw [div_ofNat_eq_zero 0 n hnM]
    · rw [div_ofNat_of_ne_zero 0 n hnM]
      simp [Nat.zero_mod]
  · have hnlt : n < Core.Uint256.modulus :=
      Nat.lt_of_le_of_lt (Nat.le_mul_of_pos_right n (Nat.pos_of_ne_zero hfee)) hnf
    have hflt : fee < Core.Uint256.modulus :=
      Nat.lt_of_le_of_lt (Nat.le_mul_of_pos_left fee (Nat.pos_of_ne_zero hn)) hnf
    have hnM : n % Core.Uint256.modulus ≠ 0 := by
      rw [Nat.mod_eq_of_lt hnlt]; exact hn
    rw [div_ofNat_of_ne_zero (n * fee) n hnM, Nat.mod_eq_of_lt hnf, Nat.mod_eq_of_lt hnlt,
      Nat.mul_div_cancel_left fee (Nat.pos_of_ne_zero hn)]

/-- The refund shape: `mv - (n * fee)` as Uint256s, given no wrap and funding. -/
theorem sub_mul_ofNat_val (mv n fee : Nat) (hmv : mv < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    (Core.Uint256.ofNat mv - (Core.Uint256.ofNat n * Core.Uint256.ofNat fee)).val =
      mv - n * fee := by
  rw [mul_ofNat]
  have hle' : (n * fee) % Core.Uint256.modulus ≤ mv % Core.Uint256.modulus := by
    rw [Nat.mod_eq_of_lt hnf, Nat.mod_eq_of_lt hmv]; exact hle
  rw [sub_ofNat mv (n * fee) hle', Nat.mod_eq_of_lt hnf, Nat.mod_eq_of_lt hmv]
  exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le mv (n * fee)) hmv)

/-- Value of a subtraction of small `ofNat`s. -/
theorem sub_ofNat_val (x y : Nat) (hx : x < Core.Uint256.modulus)
    (hy : y < Core.Uint256.modulus) (h : y ≤ x) :
    (Core.Uint256.ofNat x - Core.Uint256.ofNat y).val = x - y := by
  have h' : y % Core.Uint256.modulus ≤ x % Core.Uint256.modulus := by
    rw [Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt hy]; exact h
  rw [sub_ofNat x y h', Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt hy]
  exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le x y) hx)

/-- Value of `1 + ofNat m` when `m + 1` does not wrap: the exact normal form the
parameter decoder produces for a successor batch size (`ofNat_add` distributes
the cast before `val_ofNat` can collapse it). -/
theorem one_add_ofNat_val (m : Nat) (h : m + 1 < Core.Uint256.modulus) :
    (1 + Core.Uint256.ofNat m).val = m + 1 := by
  have hm : m % Core.Uint256.modulus = m := Nat.mod_eq_of_lt (Nat.lt_of_succ_lt h)
  show (Core.Uint256.add 1 (Core.Uint256.ofNat m)).val = m + 1
  rw [Core.Uint256.add, Core.Uint256.val_ofNat, Core.Uint256.val_one, Core.Uint256.val_ofNat, hm]
  rw [Nat.mod_eq_of_lt (by omega : 1 + m < Core.Uint256.modulus)]
  exact Nat.add_comm 1 m

/-- The panic-check shape at the point the local variable is read:
`ofNat (n * fee) / ofNat n = ofNat fee`, given a small nonzero `n` and no wrap. -/
theorem div_mul_ofNat (n fee : Nat) (hn : n ≠ 0) (hnM : n < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) :
    Core.Uint256.ofNat (n * fee) / Core.Uint256.ofNat n = Core.Uint256.ofNat fee := by
  have hnM' : n % Core.Uint256.modulus ≠ 0 := by
    rw [Nat.mod_eq_of_lt hnM]; exact hn
  rw [div_ofNat_of_ne_zero (n * fee) n hnM', Nat.mod_eq_of_lt hnf, Nat.mod_eq_of_lt hnM,
    Nat.mul_div_cancel_left fee (Nat.pos_of_ne_zero hn)]

/-- The panic-check division against the decoder's successor normal form: the
decoded successor batch size appears as `(1 + ofNat m).val` because `ofNat_add`
distributes the cast, so the divisor is `1 + ofNat m` rather than `ofNat (m+1)`. -/
theorem div_mul_one_add_ofNat (m fee : Nat) (hm : m + 1 < Core.Uint256.modulus)
    (hnf : (m + 1) * fee < Core.Uint256.modulus) :
    (Core.Uint256.ofNat ((m + 1) * fee) / (1 + Core.Uint256.ofNat m)).val =
      fee % Core.Uint256.modulus := by
  rw [Core.Uint256.ofNat_one.symm, ← Core.Uint256.ofNat_add, Nat.add_comm 1 m,
    div_mul_ofNat (m + 1) fee (Nat.succ_ne_zero m) hm hnf,
    Core.Uint256.val_ofNat]

/-! ## Bus body execution -/

/-- The ConsolidationBus body: the declared-value check passes (the frame
credits exactly the declared amount), one gateway call is journaled, and the
body stops. -/
theorem bus_body_exec (w : ContractState) (mv n callerNat thisNat : Nat) :
    executeFunctionWithCalls busEnv busSpec busFn
      { sender := callerNat, msgValue := mv, thisAddress := thisNat
        functionSelector := 1, args := [mv, n] } w =
    { result := .success []
      world := { withPayableCallContext w
          { sender := callerNat, msgValue := mv, thisAddress := thisNat
            functionSelector := 1, args := [mv, n] } with
        calls := w.calls ++ [journalEntry
          { siteId := 1, kind := .call, target := gatewayAddr.toNat, value := 0
            calldata := [wordNormalize mv, wordNormalize n], gas := 0 }
          (.success [])] } } := by
  simp [executeFunctionWithCalls, busFn, busSpec, declaredValueCheck,
    effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
    execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
    boolWord, lookupValue, withPayableCallContext, withTransactionContext,
    wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, busEnv, envWith,
    link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
    debitSelfBalance, bindResultWords]

/-! ## Gateway body execution -/

/-- The gateway transaction literal (factored so nested structure literals
parse cleanly). -/
def gwTx (mv n callerNat thisNat : Nat) : DenoteTransaction :=
  { sender := callerNat, msgValue := mv, thisAddress := thisNat
    functionSelector := 2, args := [mv, n] }

/-- The `feePerRequest` field resolves to slot 0 in the gateway/vault field
list (kernel-evaluated through the private `findFieldByName`).  Stated with
the unfolded field literal so it matches the goal after `simp` unfolds
`feeField`. -/
theorem gateway_fee_slot :
    findFieldWithResolvedSlot
      (applySlotAliasRanges [{ name := "feePerRequest", ty := FieldType.uint256, slot := some 0 }] [])
      "feePerRequest" =
      some ({ name := "feePerRequest", ty := FieldType.uint256, slot := some 0 }, 0) := rfl

/-- Reading `feePerRequest` from a state whose slot 0 holds `ofNat fee`. -/
theorem gateway_fee_read (w : ContractState) (fee : Nat)
    (hstorage : w.readSlot 0 = Core.Uint256.ofNat fee) :
    (readFieldWord w feeField 0).val = fee % Core.Uint256.modulus := by
  simp [readFieldWord, feeField, wordNormalize, hstorage]

/-- The Gateway body under the honest wiring, on a funded, guard-passing,
non-wrapping batch: the declared-value and zero guards pass, the panic check
divides back, the fee covers check passes, and the body journals exactly the
vault call (declaring the product fee) plus the refund call (declaring the
remainder) when the remainder is positive. -/
theorem gateway_body_exec (w : ContractState) (mv n fee callerNat thisNat : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus)
    (hle : n * fee ≤ mv)
    (hstorage : w.readSlot 0 = Core.Uint256.ofNat fee) :
    executeFunctionWithCalls (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest)
      (gwTx mv n callerNat thisNat) w =
    { result := .success []
      world := { withPayableCallContext w (gwTx mv n callerNat thisNat) with
        calls := w.calls ++
          [journalEntry
            { siteId := 2, kind := .call, target := vaultAddr.toNat, value := 0
              calldata := [n * fee, n], gas := 0 } (.success [])] ++
          (if mv - n * fee = 0 then []
           else [journalEntry
             { siteId := 3, kind := .call, target := refundAddr.toNat, value := 0
               calldata := [mv - n * fee], gas := 0 } (.success [])]) } } := by
  have hnf' : (n * fee) % Core.Uint256.modulus = n * fee := Nat.mod_eq_of_lt hnf
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hnM' : n % Core.Uint256.modulus = n := Nat.mod_eq_of_lt hnM
  have hstorageW : w.storageWords (StorageKey.slot 0) = Core.Uint256.ofNat fee := hstorage
  by_cases hn : n = 0
  · subst hn
    have hmv0 : mv ≠ 0 := Nat.pos_iff_ne_zero.mp hpos
    simp only [Nat.zero_mul] at hnf' ⊢
    simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
      effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
      DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
      execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
      boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
      wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
      link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
      debitSelfBalance, bindResultWords, honest, hpos, hmv', hmv0,
      gateway_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
      hstorageW, mul_ofNat_val, hnf']
  · have hdiv : Core.Uint256.ofNat (n * fee) / Core.Uint256.ofNat n = Core.Uint256.ofNat fee :=
      div_mul_ofNat n fee hn hnM hnf
    have hsub : (Core.Uint256.ofNat mv - Core.Uint256.ofNat (n * fee)).val = mv - n * fee :=
      sub_ofNat_val mv (n * fee) hmv hnf hle
    by_cases hz : mv - n * fee = 0
    · simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
        effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
        DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
        execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
        boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
        wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
        link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
        debitSelfBalance, bindResultWords, honest, hpos, hmv', hnM', hn, hz,
        gateway_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
        hstorageW, mul_ofNat_val, hdiv, hsub, hnf', hle]
    · simp [executeFunctionWithCalls, gwTx, gatewayFn, gatewaySpec, declaredValueCheck,
        effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
        DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
        execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr, evalExprList,
        boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
        wordNormalize, DynamicAbi.wordNormalize, execExternalCallBind, gatewayEnv, envWith,
        link, denoteCallJournaled, denoteCall, identityAdversary, chargedGas, journalEntry,
        debitSelfBalance, bindResultWords, honest, hpos, hmv', hnM', hn, hz,
        gateway_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
        hstorageW, mul_ofNat_val, hdiv, hsub, hnf', hle]

/-! ## Vault body execution -/

/-- The vault transaction literal. -/
def vaultTx (amt n callerNat thisNat : Nat) : DenoteTransaction :=
  { sender := callerNat, msgValue := amt, thisAddress := thisNat
    functionSelector := 3, args := [amt, n] }

/-- The journal entry one vault request-loop iteration appends (the loop body
reads the same storage slot every iteration and never writes). -/
def requestJournalEntry (feeWord : Nat) : Verity.ExternalCall :=
  journalEntry
    { siteId := 4, kind := .call, target := requestAddr.toNat, value := 0
      calldata := [feeWord], gas := 0 }
    (.success [])

/-- Rebinding the same name overwrites the previous binding. -/
theorem bindValue_same (b : Env) (name : String) (x y : Nat) :
    bindValue (bindValue b name x) name y = bindValue b name y := by
  simp [bindValue, List.filter_filter]

/-- One iteration of the vault request loop, stated about `execExternalCallBind`
directly (not the `match` normal form the body simplifier produces, whose matcher
constant would not unify): the declared-amount convention debits nothing at the
link, the identity adversary commits no transition, and exactly one request entry
is journaled. -/
theorem vault_request_call (st : DenoteState) :
    execExternalCallBind (vaultEnv honest) (effectiveFields (vaultSpec honest)) st []
      "request" [.storage "feePerRequest"] =
      .continue { st with world := { st.world with
        calls := st.world.calls ++ [requestJournalEntry ((st.world.readSlot 0).val)] } } := by
  simp [execExternalCallBind, vaultEnv, envWith, honest, link, evalExpr, evalExprList,
    vaultSpec, effectiveFields, gateway_fee_slot, readFieldWord, feeField,
    ContractState.readSlot, ContractState.storage, debitSelfBalance, denoteCallJournaled,
    denoteCall, identityAdversary, chargedGas, journalEntry, requestJournalEntry,
    bindResultWords, wordNormalize]

/-- The vault request loop, executed symbolically over any body that journals
exactly one request entry per iteration: after `k` iterations the world has
exactly `k` request journal entries appended, and nothing else changed. -/
theorem vault_request_loop (k j : Nat) (st : DenoteState) (runBody : DenoteState → StmtOutcome)
    (hbody : ∀ s, runBody s = .continue { s with world := { s.world with
      calls := s.world.calls ++ [requestJournalEntry ((s.world.readSlot 0).val)] } }) :
    execForEachLoop "i" runBody st j k =
      .continue (match k with
        | 0 => st
        | k + 1 => { st with
            bindings := bindValue st.bindings "i" (wordNormalize (j + k))
            world := { st.world with
              calls := st.world.calls ++
                List.replicate (k + 1) (requestJournalEntry ((st.world.readSlot 0).val)) } }) := by
  induction k generalizing j st with
  | zero => simp [execForEachLoop]
  | succ k ih =>
    simp only [execForEachLoop]
    rw [hbody]
    dsimp only
    rw [ih]
    cases k with
    | zero =>
      simp [ContractState.readSlot, ContractState.storage]
    | succ k' =>
      have hadd : j + 1 + k' = j + (k' + 1) := by omega
      simp [bindValue_same, List.replicate_succ, List.append_assoc, hadd,
        ContractState.readSlot, ContractState.storage]

/-- The vault's `feePerRequest` resolves to slot 0, stated against the
unevaluated field table so the `forEach` loop lambda keeps its shape. -/
theorem vault_fee_slot :
    findFieldWithResolvedSlot (effectiveFields (vaultSpec honest)) "feePerRequest" =
      some (feeField, 0) := rfl

/-- Reading `feePerRequest` is a slot-0 read. -/
theorem vault_fee_read (w : ContractState) :
    readFieldWord w feeField 0 = w.readSlot 0 := by
  simp [readFieldWord, feeField, wordNormalize]

/-- `honest.perRequestCalls` without unfolding `honest` (keeps the loop lambda
matching `vault_request_loop`). -/
theorem honest_perRequestCalls : honest.perRequestCalls = true := rfl

/-- The Vault body under the honest wiring, on a guard-passing non-wrapping
batch whose declared amount is exactly the product fee: the checks pass and the
body journals exactly `n` consolidation-request calls, each declaring the
stored per-request fee. -/
theorem vault_body_exec (w : ContractState) (n fee callerNat thisNat : Nat)
    (hnM : n < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus)
    (hstorage : w.readSlot 0 = Core.Uint256.ofNat fee) :
    executeFunctionWithCalls (vaultEnv honest) (vaultSpec honest) (vaultFn honest)
      (vaultTx (n * fee) n callerNat thisNat) w =
    { result := .success []
      world := { withPayableCallContext w (vaultTx (n * fee) n callerNat thisNat) with
        calls := w.calls ++
          List.replicate n (requestJournalEntry (fee % Core.Uint256.modulus)) } } := by
  have hnf' : (n * fee) % Core.Uint256.modulus = n * fee := Nat.mod_eq_of_lt hnf
  have hstorageW : w.storageWords (StorageKey.slot 0) = Core.Uint256.ofNat fee := hstorage
  by_cases hn : n = 0
  · subst hn
    simp only [Nat.zero_mul] at hnf' ⊢
    simp [executeFunctionWithCalls, vaultTx, vaultFn, declaredValueCheck,
      bindExternalParams, DynamicAbi.bindExternalParams, DynamicAbi.bindSupportedParams,
      DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
      execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr,
      boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
      wordNormalize, DynamicAbi.wordNormalize, hnf', honest_perRequestCalls,
      vault_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
      hstorageW, mul_ofNat_val, vault_request_loop, vault_request_call]
  · obtain ⟨m, rfl⟩ : ∃ k, n = Nat.succ k := ⟨n - 1, by omega⟩
    have hdiv : (Core.Uint256.ofNat ((m + 1) * fee) / (1 + Core.Uint256.ofNat m)).val =
        fee % Core.Uint256.modulus :=
      div_mul_one_add_ofNat m fee hnM hnf
    have hdec : (1 + Core.Uint256.ofNat m).val = m + 1 := one_add_ofNat_val m hnM
    simp [executeFunctionWithCalls, vaultTx, vaultFn, declaredValueCheck,
      bindExternalParams, DynamicAbi.bindExternalParams, DynamicAbi.bindSupportedParams,
      DynamicAbi.decodeSupportedParamWord, amountParam, batchParam,
      execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr,
      boolWord, lookupValue, bindValue, withPayableCallContext, withTransactionContext,
      wordNormalize, DynamicAbi.wordNormalize, hnf', hdec, honest_perRequestCalls,
      vault_fee_slot, readFieldWord, feeField, ContractState.readSlot, ContractState.storage,
      hstorageW, mul_ofNat_val, hdiv, vault_request_loop, vault_request_call]

/-! ## Frame and step chaining

Each hop of the dispatch is pinned twice: once as the exact frame equation
`callFunction ... = some { frame, result, world }` produced by `callEntry`, and
once as a one-step rewrite of the dispatcher `step` that consumes the head
pending and prepends the pendings the committed body journaled. -/

/-- Round-trip an address through its word form (used by `childPending`). -/
theorem addr_ofNat_toNat (a : Address) : Core.Address.ofNat a.toNat = a := by
  ext
  simp [Core.Address.toNat]

/-! ### Hop 1: sender → Bus -/

/-- The bus transaction literal. -/
def busTx (mv n : Nat) : DenoteTransaction :=
  { sender := senderAddr.toNat, msgValue := mv, thisAddress := busAddr.toNat
    functionSelector := 1, args := [mv, n] }

/-- The frame `callEntry` constructs for the root call on the initial world. -/
def busFrame (mv n fee : Nat) : CallFrame :=
  { caller := senderAddr, callee := busAddr, site := rootSite mv n
    callerBefore := lookup (initial mv fee) senderAddr
    calleeBefore := lookup (initial mv fee) busAddr
    calleeEntry := withCallContext (lookup (initial mv fee) busAddr) senderAddr busAddr
      (mv : Core.Uint256) }

/-- The world after the bus frame commits: the sender is debited `mv` (and
journals the root call), the bus is credited and journals one gateway call. -/
def busPostWorld (mv n fee : Nat) : MultiWorld :=
  upsert (upsert (initial mv fee) senderAddr
      { lookup (initial mv fee) senderAddr with
        calls := (lookup (initial mv fee) senderAddr).calls ++
          [journalEntry (rootSite mv n) (.success [])]
        selfBalance := (lookup (initial mv fee) senderAddr).selfBalance - (mv : Core.Uint256) })
    busAddr
    { withPayableCallContext (lookup (initial mv fee) busAddr) (busTx mv n) with
      calls := (lookup (initial mv fee) busAddr).calls ++ [journalEntry
        { siteId := 1, kind := .call, target := gatewayAddr.toNat, value := 0
          calldata := [wordNormalize mv, wordNormalize n], gas := 0 } (.success [])] }

/-- The bus frame on the literal initial world, as one equation. -/
theorem bus_frame (mv n fee : Nat) (hmv : mv < Core.Uint256.modulus) :
    callFunction busEnv busSpec busFn 1 (initial mv fee) senderAddr busAddr
        (rootSite mv n) =
      some { frame := busFrame mv n fee, result := .success [],
             world := busPostWorld mv n fee } := by
  have hne : (senderAddr ≠ busAddr) := by decide
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  unfold callFunction MultiContract.call
  simp [callEntry, hne, rootSite, initial, account, lookup, hmv',
    executeCall, runFunctionInFrame, bus_body_exec, framedJournalEntry,
    busFrame, busPostWorld, busTx]

/-- The pending frame the bus body emits (the gateway leg). -/
def gwSite (mv n : Nat) : CallSite :=
  { siteId := 1, kind := .call, target := gatewayAddr.toNat, value := mv
    calldata := [mv, n], gas := gasBudget }

def gwPending (mv n : Nat) : Pending :=
  { caller := busAddr, callee := gatewayAddr, site := gwSite mv n }

/-- The compiled form of the root call, prepended to the program. -/
def busCompiled (mv n : Nat) : CompiledCall :=
  { env := busEnv, spec := busSpec, fn := busFn, selector := 1
    caller := senderAddr, callee := busAddr, site := rootSite mv n }

/-- The bus account's journal is empty in the initial world (kernel reduction
through the literal account list; the symbolic balances are never inspected). -/
theorem lookup_initial_bus_calls (mv fee : Nat) :
    (lookup (initial mv fee) busAddr).calls = [] := rfl

/-- Dispatch of the root pending: one hop, leaving the gateway leg pending. -/
theorem hop_bus (mv n fee f h : Nat) (prog : List CompiledCall)
    (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus) :
    step (nodeAt honest) (initial mv fee) (f + 1) (initial mv fee)
        [{ caller := senderAddr, callee := busAddr, site := rootSite mv n }] h prog =
      step (nodeAt honest) (initial mv fee) f (busPostWorld mv n fee)
        [gwPending mv n] (h + 1) (busCompiled mv n :: prog) := by
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hnM' : n % Core.Uint256.modulus = n := Nat.mod_eq_of_lt hnM
  have hnode : nodeAt honest busAddr =
      some { env := busEnv, spec := busSpec, fn := busFn, selector := 1 } := rfl
  simp only [step]
  simp only [hnode]
  rw [bus_frame mv n fee hmv]
  simp [busFrame, busPostWorld, gwPending, gwSite, busCompiled, busTx, rootSite,
    lookup_upsert_same, childPending, journalEntry,
    addr_ofNat_toNat, wordNormalize, hmv', hnM',
    lookup_initial_bus_calls, ExternalCallResult.succeeded]

/-! ### Hop 2: Bus → Gateway -/

/-- The bus account starts with zero balance. -/
theorem lookup_initial_bus_balance (mv fee : Nat) :
    (lookup (initial mv fee) busAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The gateway account starts with zero balance. -/
theorem lookup_initial_gateway_balance (mv fee : Nat) :
    (lookup (initial mv fee) gatewayAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The gateway account's journal is empty in the initial world. -/
theorem lookup_initial_gateway_calls (mv fee : Nat) :
    (lookup (initial mv fee) gatewayAddr).calls = [] := rfl

/-- The gateway account stores `feePerRequest` at slot 0. -/
theorem lookup_initial_gateway_fee (mv fee : Nat) :
    (lookup (initial mv fee) gatewayAddr).readSlot 0 = Core.Uint256.ofNat fee := rfl

/-- The bus post-state carries the credited `mv`. -/
theorem lookup_busPostWorld_bus_balance (mv n fee : Nat) :
    (lookup (busPostWorld mv n fee) busAddr).selfBalance = Core.Uint256.ofNat mv := by
  have hub : (lookup (initial mv fee) busAddr).selfBalance = Core.Uint256.ofNat 0 :=
    lookup_initial_bus_balance mv fee
  simp [busPostWorld, lookup_upsert_same, selfBalance_withPayableCallContext, busTx,
    hub, -Core.Uint256.ofNat_add]

/-- The bus hop does not touch the gateway account. -/
theorem lookup_busPostWorld_gateway (mv n fee : Nat) :
    lookup (busPostWorld mv n fee) gatewayAddr = lookup (initial mv fee) gatewayAddr := by
  unfold busPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : busAddr ≠ gatewayAddr),
    lookup_upsert_diff _ _ _ _ (by decide : senderAddr ≠ gatewayAddr)]

/-- The frame `callEntry` constructs for the gateway leg. -/
def gwFrame (mv n fee : Nat) : CallFrame :=
  { caller := busAddr, callee := gatewayAddr, site := gwSite mv n
    callerBefore := lookup (busPostWorld mv n fee) busAddr
    calleeBefore := lookup (busPostWorld mv n fee) gatewayAddr
    calleeEntry := withCallContext (lookup (busPostWorld mv n fee) gatewayAddr) busAddr
      gatewayAddr (mv : Core.Uint256) }

/-- The world after the gateway frame commits: the bus is debited `mv`, the
gateway is credited and journals the vault call (declaring the product fee)
plus the refund call (declaring the remainder) when the remainder is
positive. -/
def gwPostWorld (mv n fee : Nat) : MultiWorld :=
  upsert (upsert (busPostWorld mv n fee) busAddr
      { lookup (busPostWorld mv n fee) busAddr with
        calls := (lookup (busPostWorld mv n fee) busAddr).calls ++
          [journalEntry (gwSite mv n) (.success [])]
        selfBalance := (lookup (busPostWorld mv n fee) busAddr).selfBalance - (mv : Core.Uint256) })
    gatewayAddr
    { withPayableCallContext (lookup (busPostWorld mv n fee) gatewayAddr)
        (gwTx mv n busAddr.toNat gatewayAddr.toNat) with
      calls := (lookup (busPostWorld mv n fee) gatewayAddr).calls ++
        [journalEntry
          { siteId := 2, kind := .call, target := vaultAddr.toNat, value := 0
            calldata := [n * fee, n], gas := 0 } (.success [])] ++
        (if mv - n * fee = 0 then [] else [journalEntry
          { siteId := 3, kind := .call, target := refundAddr.toNat, value := 0
            calldata := [mv - n * fee], gas := 0 } (.success [])]) }

/-- The gateway frame on the bus post-world, as one equation. -/
theorem gateway_frame (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    callFunction (gatewayEnv honest) (gatewaySpec honest) (gatewayFn honest) 2
        (busPostWorld mv n fee) busAddr gatewayAddr (gwSite mv n) =
      some { frame := gwFrame mv n fee, result := .success [],
             world := gwPostWorld mv n fee } := by
  have hne : (busAddr ≠ gatewayAddr) := by decide
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hbal := lookup_busPostWorld_bus_balance mv n fee
  have hstorage : (lookup (busPostWorld mv n fee) gatewayAddr).readSlot 0 =
      Core.Uint256.ofNat fee := by
    rw [lookup_busPostWorld_gateway, lookup_initial_gateway_fee]
  have hbody := gateway_body_exec (lookup (busPostWorld mv n fee) gatewayAddr) mv n fee
    busAddr.toNat gatewayAddr.toNat hpos hmv hnM hnf hle hstorage
  simp only [gwTx] at hbody
  unfold callFunction MultiContract.call
  simp [callEntry, hne, hbal, hmv', gwSite, gwFrame, gwPostWorld, gwTx,
    executeCall, runFunctionInFrame, framedJournalEntry, hbody]

/-- The pending frame the gateway body emits for the vault leg. -/
def vaultSite (n fee : Nat) : CallSite :=
  { siteId := 2, kind := .call, target := vaultAddr.toNat, value := n * fee
    calldata := [n * fee, n], gas := gasBudget }

def vaultPending (n fee : Nat) : Pending :=
  { caller := gatewayAddr, callee := vaultAddr, site := vaultSite n fee }

/-- The pending frame the gateway body emits for the refund leg. -/
def refundSite (mv n fee : Nat) : CallSite :=
  { siteId := 3, kind := .call, target := refundAddr.toNat, value := mv - n * fee
    calldata := [mv - n * fee], gas := gasBudget }

def refundPending (mv n fee : Nat) : Pending :=
  { caller := gatewayAddr, callee := refundAddr, site := refundSite mv n fee }

/-- The compiled form of the gateway leg. -/
def gwCompiled (mv n : Nat) : CompiledCall :=
  { env := gatewayEnv honest, spec := gatewaySpec honest, fn := gatewayFn honest,
    selector := 2, caller := busAddr, callee := gatewayAddr, site := gwSite mv n }

/-- Dispatch of the gateway pending: one hop, leaving the vault leg (and the
refund leg, when the remainder is positive) pending. -/
theorem hop_gateway (mv n fee f h : Nat) (prog : List CompiledCall)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    step (nodeAt honest) (initial mv fee) (f + 1) (busPostWorld mv n fee)
        [gwPending mv n] h prog =
      step (nodeAt honest) (initial mv fee) f (gwPostWorld mv n fee)
        (vaultPending n fee :: (if mv - n * fee = 0 then [] else [refundPending mv n fee]))
        (h + 1) (gwCompiled mv n :: prog) := by
  have hnode : nodeAt honest gatewayAddr =
      some { env := gatewayEnv honest, spec := gatewaySpec honest, fn := gatewayFn honest,
             selector := 2 } := rfl
  by_cases hz : mv - n * fee = 0
  · simp only [step, gwPending]
    simp only [hnode]
    rw [gateway_frame mv n fee hpos hmv hnM hnf hle]
    simp [gwFrame, gwPostWorld, gwSite, vaultPending, vaultSite,
      gwCompiled, lookup_upsert_same, childPending,
      journalEntry, addr_ofNat_toNat, hz,
      lookup_busPostWorld_gateway, lookup_initial_gateway_calls,
      ExternalCallResult.succeeded]
  · simp only [step, gwPending]
    simp only [hnode]
    rw [gateway_frame mv n fee hpos hmv hnM hnf hle]
    simp [gwFrame, gwPostWorld, gwSite, vaultPending, vaultSite, refundPending,
      refundSite, gwCompiled, lookup_upsert_same, childPending,
      journalEntry, addr_ofNat_toNat, hz,
      lookup_busPostWorld_gateway, lookup_initial_gateway_calls,
      ExternalCallResult.succeeded]

/-! ### Hop 3: Gateway → Vault -/

/-- The vault account starts with zero balance. -/
theorem lookup_initial_vault_balance (mv fee : Nat) :
    (lookup (initial mv fee) vaultAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The vault account's journal is empty in the initial world. -/
theorem lookup_initial_vault_calls (mv fee : Nat) :
    (lookup (initial mv fee) vaultAddr).calls = [] := rfl

/-- The vault account stores `feePerRequest` at slot 0. -/
theorem lookup_initial_vault_fee (mv fee : Nat) :
    (lookup (initial mv fee) vaultAddr).readSlot 0 = Core.Uint256.ofNat fee := rfl

/-- The gateway hop does not touch the vault account. -/
theorem lookup_gwPostWorld_vault (mv n fee : Nat) :
    lookup (gwPostWorld mv n fee) vaultAddr = lookup (initial mv fee) vaultAddr := by
  unfold gwPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : gatewayAddr ≠ vaultAddr)]
  exact lookup_busPostWorld_vault mv n fee
where
  lookup_busPostWorld_vault (mv n fee : Nat) :
      lookup (busPostWorld mv n fee) vaultAddr = lookup (initial mv fee) vaultAddr := by
    unfold busPostWorld
    rw [lookup_upsert_diff _ _ _ _ (by decide : busAddr ≠ vaultAddr),
      lookup_upsert_diff _ _ _ _ (by decide : senderAddr ≠ vaultAddr)]

/-- The gateway post-state (after its own frame commits) carries the credited
`mv`. -/
theorem lookup_gwPostWorld_gateway_balance (mv n fee : Nat) :
    (lookup (gwPostWorld mv n fee) gatewayAddr).selfBalance = Core.Uint256.ofNat mv := by
  have hub : (lookup (initial mv fee) gatewayAddr).selfBalance = Core.Uint256.ofNat 0 :=
    lookup_initial_gateway_balance mv fee
  simp [gwPostWorld, lookup_upsert_same, selfBalance_withPayableCallContext, gwTx,
    lookup_busPostWorld_gateway, hub, -Core.Uint256.ofNat_add]

/-- The frame `callEntry` constructs for the vault leg. -/
def vaultFrame (mv n fee : Nat) : CallFrame :=
  { caller := gatewayAddr, callee := vaultAddr, site := vaultSite n fee
    callerBefore := lookup (gwPostWorld mv n fee) gatewayAddr
    calleeBefore := lookup (gwPostWorld mv n fee) vaultAddr
    calleeEntry := withCallContext (lookup (gwPostWorld mv n fee) vaultAddr) gatewayAddr
      vaultAddr ((n * fee : Nat) : Core.Uint256) }

/-- The world after the vault frame commits: the gateway is debited the product
fee, the vault is credited and journals `n` consolidation-request calls. -/
def vaultPostWorld (mv n fee : Nat) : MultiWorld :=
  upsert (upsert (gwPostWorld mv n fee) gatewayAddr
      { lookup (gwPostWorld mv n fee) gatewayAddr with
        calls := (lookup (gwPostWorld mv n fee) gatewayAddr).calls ++
          [journalEntry (vaultSite n fee) (.success [])]
        selfBalance := (lookup (gwPostWorld mv n fee) gatewayAddr).selfBalance -
          ((n * fee : Nat) : Core.Uint256) })
    vaultAddr
    { withPayableCallContext (lookup (gwPostWorld mv n fee) vaultAddr)
        (vaultTx (n * fee) n gatewayAddr.toNat vaultAddr.toNat) with
      calls := (lookup (gwPostWorld mv n fee) vaultAddr).calls ++
        List.replicate n (requestJournalEntry (fee % Core.Uint256.modulus)) }

/-- The vault frame on the gateway post-world, as one equation. -/
theorem vault_frame (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    callFunction (vaultEnv honest) (vaultSpec honest) (vaultFn honest) 3
        (gwPostWorld mv n fee) gatewayAddr vaultAddr (vaultSite n fee) =
      some { frame := vaultFrame mv n fee, result := .success [],
             world := vaultPostWorld mv n fee } := by
  have hne : (gatewayAddr ≠ vaultAddr) := by decide
  have hmv' : mv % Core.Uint256.modulus = mv := Nat.mod_eq_of_lt hmv
  have hbal := lookup_gwPostWorld_gateway_balance mv n fee
  have hstorage : (lookup (gwPostWorld mv n fee) vaultAddr).readSlot 0 =
      Core.Uint256.ofNat fee := by
    rw [lookup_gwPostWorld_vault, lookup_initial_vault_fee]
  have hbody := vault_body_exec (lookup (gwPostWorld mv n fee) vaultAddr) n fee
    gatewayAddr.toNat vaultAddr.toNat hnM hnf hstorage
  simp only [vaultTx] at hbody
  unfold callFunction MultiContract.call
  simp [callEntry, hne, hbal, hmv', hle, vaultSite, vaultFrame, vaultPostWorld, vaultTx,
    executeCall, runFunctionInFrame, framedJournalEntry, hbody]

/-- The pending frame one vault request-loop iteration emits. -/
def requestSite (fee : Nat) : CallSite :=
  { siteId := 4, kind := .call, target := requestAddr.toNat, value := fee
    calldata := [fee], gas := gasBudget }

def requestPending (fee : Nat) : Pending :=
  { caller := vaultAddr, callee := requestAddr, site := requestSite fee }

/-- The compiled form of the vault leg. -/
def vaultCompiled (n fee : Nat) : CompiledCall :=
  { env := vaultEnv honest, spec := vaultSpec honest, fn := vaultFn honest,
    selector := 3, caller := gatewayAddr, callee := vaultAddr, site := vaultSite n fee }

/-- `childPending` of one journaled request entry is the request pending. -/
theorem childPending_requestEntry (fee : Nat) (hfee : fee < Core.Uint256.modulus) :
    childPending vaultAddr gasBudget (requestJournalEntry (fee % Core.Uint256.modulus)) =
      requestPending fee := by
  have hfee' : fee % Core.Uint256.modulus = fee := Nat.mod_eq_of_lt hfee
  simp [childPending, requestJournalEntry, journalEntry, requestPending, requestSite,
    addr_ofNat_toNat, hfee']

/-- Dispatch of the vault pending: one hop, leaving `n` request legs (and the
refund leg, when present) pending. -/
theorem hop_vault (mv n fee f h : Nat) (prog : List CompiledCall)
    (hmv : mv < Core.Uint256.modulus) (hnM : n < Core.Uint256.modulus)
    (hfee : fee < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus)
    (hle : n * fee ≤ mv) :
    step (nodeAt honest) (initial mv fee) (f + 1) (gwPostWorld mv n fee)
        (vaultPending n fee :: (if mv - n * fee = 0 then [] else [refundPending mv n fee]))
        h prog =
      step (nodeAt honest) (initial mv fee) f (vaultPostWorld mv n fee)
        (List.replicate n (requestPending fee) ++
          (if mv - n * fee = 0 then [] else [refundPending mv n fee]))
        (h + 1) (vaultCompiled n fee :: prog) := by
  have hnode : nodeAt honest vaultAddr =
      some { env := vaultEnv honest, spec := vaultSpec honest, fn := vaultFn honest,
             selector := 3 } := rfl
  simp only [step, vaultPending]
  simp only [hnode]
  rw [vault_frame mv n fee hmv hnM hnf hle]
  simp [vaultFrame, vaultPostWorld, vaultSite, requestPending, requestSite,
    refundPending, refundSite, vaultCompiled, lookup_upsert_same,
    List.map_replicate, childPending_requestEntry fee hfee,
    lookup_gwPostWorld_vault, lookup_initial_vault_calls, ExternalCallResult.succeeded]

/-! ### Hop 4..3+n: Vault → CONSOLIDATION_REQUEST (request phase) -/

/-- The sink transaction literal for one request leg. -/
def requestTx (fee : Nat) : DenoteTransaction :=
  { sender := vaultAddr.toNat, msgValue := fee, thisAddress := requestAddr.toNat
    functionSelector := 4, args := [fee] }

/-- `withPayableCallContext` preserves the call journal. -/
theorem calls_withPayableCallContext (w : ContractState) (tx : DenoteTransaction) :
    (withPayableCallContext w tx).calls = w.calls := rfl

/-- The sink body, generalized over the function selector (the selector is
not consulted by the body). -/
theorem sink_body_exec_sel (name : String) (w : ContractState) (v callerNat thisNat sel : Nat) :
    executeFunctionWithCalls sinkEnv (sinkSpec name true) (sinkFn name true)
      { sender := callerNat, msgValue := v, thisAddress := thisNat
        functionSelector := sel, args := [v] } w =
    { result := .success []
      world := withPayableCallContext w
        { sender := callerNat, msgValue := v, thisAddress := thisNat
          functionSelector := sel, args := [v] } } := by
  simp [executeFunctionWithCalls, sinkFn, sinkSpec, declaredValueCheck,
    effectiveFields, bindExternalParams, DynamicAbi.bindExternalParams,
    DynamicAbi.bindSupportedParams, DynamicAbi.decodeSupportedParamWord, amountParam,
    execStmtListWithCalls, execStmtWithCalls, execStmt, evalExpr,
    boolWord, lookupValue, withPayableCallContext, withTransactionContext,
    wordNormalize, DynamicAbi.wordNormalize]

/-- The frame `callEntry` constructs for one request leg on world `W`. -/
def requestFrame (W : MultiWorld) (fee : Nat) : CallFrame :=
  { caller := vaultAddr, callee := requestAddr, site := requestSite fee
    callerBefore := lookup W vaultAddr
    calleeBefore := lookup W requestAddr
    calleeEntry := withCallContext (lookup W requestAddr) vaultAddr requestAddr
      (fee : Core.Uint256) }

/-- The world after one request frame commits on `W`: the vault is debited
`fee` (and journals the call), the request predeploy is credited. -/
def requestPostWorld (W : MultiWorld) (fee : Nat) : MultiWorld :=
  upsert (upsert W vaultAddr
      { lookup W vaultAddr with
        calls := (lookup W vaultAddr).calls ++
          [journalEntry (requestSite fee) (.success [])]
        selfBalance := (lookup W vaultAddr).selfBalance - (fee : Core.Uint256) })
    requestAddr
    (withPayableCallContext (lookup W requestAddr) (requestTx fee))

/-- One request frame on an arbitrary world, as one equation. -/
theorem request_frame (W : MultiWorld) (fee : Nat)
    (hle : fee ≤ (lookup W vaultAddr).selfBalance.val) :
    callFunction sinkEnv (sinkSpec "ConsolidationRequest" true)
        (sinkFn "ConsolidationRequest" true) 4 W vaultAddr requestAddr (requestSite fee) =
      some { frame := requestFrame W fee, result := .success [],
             world := requestPostWorld W fee } := by
  have hne : (vaultAddr ≠ requestAddr) := by decide
  unfold callFunction MultiContract.call
  simp [callEntry, hne, hle, requestSite, requestFrame, requestPostWorld, requestTx,
    executeCall, runFunctionInFrame, framedJournalEntry,
    sink_body_exec_sel "ConsolidationRequest" (lookup W requestAddr) fee vaultAddr.toNat
      requestAddr.toNat 4]

/-- The compiled form of one request leg. -/
def requestCompiled (fee : Nat) : CompiledCall :=
  { env := sinkEnv, spec := sinkSpec "ConsolidationRequest" true,
    fn := sinkFn "ConsolidationRequest" true, selector := 4,
    caller := vaultAddr, callee := requestAddr, site := requestSite fee }

/-- Dispatch of one request pending on an arbitrary world: one hop, and the
sink journals nothing, so no new pendings are emitted. -/
theorem hop_request (E W : MultiWorld) (fee f h : Nat) (prog : List CompiledCall)
    (rest : List Pending)
    (hle : fee ≤ (lookup W vaultAddr).selfBalance.val) :
    step (nodeAt honest) E (f + 1) W (requestPending fee :: rest) h prog =
      step (nodeAt honest) E f (requestPostWorld W fee) rest (h + 1)
        (requestCompiled fee :: prog) := by
  have hnode : nodeAt honest requestAddr =
      some { env := sinkEnv, spec := sinkSpec "ConsolidationRequest" true,
             fn := sinkFn "ConsolidationRequest" true, selector := 4 } := rfl
  simp only [step, requestPending]
  simp only [hnode]
  rw [request_frame W fee hle]
  simp [requestFrame, requestPostWorld, requestSite, requestCompiled, requestTx,
    lookup_upsert_same, calls_withPayableCallContext,
    List.drop_length, ExternalCallResult.succeeded]

/-- The world after `k` request hops, by primitive recursion so the step
direction is definitional. -/
def requestPhaseWorld (fee : Nat) : Nat → MultiWorld → MultiWorld
  | 0, W => W
  | k + 1, W => requestPhaseWorld fee k (requestPostWorld W fee)

/-- The request phase: `k` request pendings dispatch in `k` hops, threading the
world through `requestPostWorld` and accumulating the compiled request calls. -/
theorem request_phase (k : Nat) (E W : MultiWorld) (fee f h : Nat)
    (prog : List CompiledCall) (rest : List Pending)
    (hguard : ∀ j, j < k →
      fee ≤ (lookup (requestPhaseWorld fee j W) vaultAddr).selfBalance.val) :
    step (nodeAt honest) E (k + f) W
        (List.replicate k (requestPending fee) ++ rest) h prog =
      step (nodeAt honest) E f (requestPhaseWorld fee k W) rest (h + k)
        (List.replicate k (requestCompiled fee) ++ prog) := by
  induction k generalizing W h prog with
  | zero => simp [requestPhaseWorld]
  | succ k ih =>
    have h0 : fee ≤ (lookup W vaultAddr).selfBalance.val :=
      hguard 0 (Nat.zero_lt_succ k)
    have hguard' : ∀ j, j < k →
        fee ≤ (lookup (requestPhaseWorld fee j (requestPostWorld W fee))
          vaultAddr).selfBalance.val :=
      fun j hj => hguard (j + 1) (Nat.succ_lt_succ hj)
    rw [List.replicate_succ, List.cons_append, Nat.succ_add, Nat.succ_eq_add_one,
      hop_request E W fee (k + f) h prog _ h0,
      ih (requestPostWorld W fee) (h + 1) (requestCompiled fee :: prog) hguard']
    have hhops : h + 1 + k = h + (k + 1) := by omega
    have hprog : List.replicate k (requestCompiled fee) ++ (requestCompiled fee :: prog) =
        List.replicate (k + 1) (requestCompiled fee) ++ prog := by
      simp [List.replicate_succ', List.append_assoc]
    rw [hhops, hprog]
    simp only [requestPhaseWorld]

/-! ### Iterated request-phase account facts -/

/-- The vault holds the product fee right after its own frame commits. -/
theorem lookup_vaultPostWorld_vault_balance (mv n fee : Nat) :
    (lookup (vaultPostWorld mv n fee) vaultAddr).selfBalance =
      Core.Uint256.ofNat (n * fee) := by
  have hub : (lookup (initial mv fee) vaultAddr).selfBalance = Core.Uint256.ofNat 0 :=
    lookup_initial_vault_balance mv fee
  simp [vaultPostWorld, lookup_upsert_same, selfBalance_withPayableCallContext, vaultTx,
    lookup_gwPostWorld_vault, hub, -Core.Uint256.ofNat_add]

/-- The vault's balance after `j` request hops, starting from a world where it
holds `ofNat b`, while the hops do not underflow. -/
theorem lookup_requestPhaseWorld_vault_balance (fee j : Nat) (W : MultiWorld) (b : Nat)
    (hb : (lookup W vaultAddr).selfBalance = Core.Uint256.ofNat b)
    (hfeeM : fee < Core.Uint256.modulus) (hbM : b < Core.Uint256.modulus)
    (hjfb : j * fee ≤ b) :
    (lookup (requestPhaseWorld fee j W) vaultAddr).selfBalance =
      Core.Uint256.ofNat (b - j * fee) := by
  induction j generalizing W b with
  | zero => simp [requestPhaseWorld, hb]
  | succ j ih =>
    have hfeeb : fee ≤ b :=
      Nat.le_trans (Nat.le_mul_of_pos_left fee (Nat.succ_pos j)) hjfb
    have hstep : (lookup (requestPostWorld W fee) vaultAddr).selfBalance =
        Core.Uint256.ofNat (b - fee) := by
      unfold requestPostWorld
      rw [lookup_upsert_diff _ _ _ _ (by decide : requestAddr ≠ vaultAddr),
        lookup_upsert_same]
      show (lookup W vaultAddr).selfBalance - Core.Uint256.ofNat fee = _
      rw [hb]
      have hle' : fee % Core.Uint256.modulus ≤ b % Core.Uint256.modulus := by
        rw [Nat.mod_eq_of_lt hfeeM, Nat.mod_eq_of_lt hbM]; exact hfeeb
      rw [sub_ofNat b fee hle', Nat.mod_eq_of_lt hbM, Nat.mod_eq_of_lt hfeeM]
    have hjfb' : j * fee ≤ b - fee := by
      have h1 : j * fee + fee ≤ b := by
        have h2 : (j + 1) * fee = j * fee + fee := Nat.succ_mul j fee
        rw [h2] at hjfb; exact hjfb
      exact (Nat.le_sub_iff_add_le hfeeb).mpr h1
    have hbf : b - fee < Core.Uint256.modulus := Nat.lt_of_le_of_lt (Nat.sub_le b fee) hbM
    simp only [requestPhaseWorld]
    rw [ih (requestPostWorld W fee) (b - fee) hstep hbf hjfb']
    have hsub : b - fee - j * fee = b - (j + 1) * fee := by
      rw [Nat.sub_sub, Nat.succ_mul, Nat.add_comm (j * fee) fee]
    rw [hsub]

/-- The request predeploy's balance after `j` request hops, starting from a
world where it holds `ofNat b`. -/
theorem lookup_requestPhaseWorld_request_balance (fee j : Nat) (W : MultiWorld) (b : Nat)
    (hb : (lookup W requestAddr).selfBalance = Core.Uint256.ofNat b) :
    (lookup (requestPhaseWorld fee j W) requestAddr).selfBalance =
      Core.Uint256.ofNat (b + j * fee) := by
  induction j generalizing W b with
  | zero => simp [requestPhaseWorld, hb]
  | succ j ih =>
    have hstep : (lookup (requestPostWorld W fee) requestAddr).selfBalance =
        Core.Uint256.ofNat (b + fee) := by
      simp [requestPostWorld, lookup_upsert_same, selfBalance_withPayableCallContext,
        requestTx, hb, ← Core.Uint256.ofNat_add, Nat.add_comm]
    simp only [requestPhaseWorld]
    rw [ih (requestPostWorld W fee) (b + fee) hstep]
    have hadd : b + fee + j * fee = b + (j + 1) * fee := by
      rw [Nat.succ_mul]; omega
    rw [hadd]

/-- Request hops touch only the vault and the request predeploy. -/
theorem lookup_requestPhaseWorld_ne (fee j : Nat) (W : MultiWorld) (a : Address)
    (hv : a ≠ vaultAddr) (hr : a ≠ requestAddr) :
    lookup (requestPhaseWorld fee j W) a = lookup W a := by
  induction j generalizing W with
  | zero => rfl
  | succ j ih =>
    simp only [requestPhaseWorld]
    rw [ih (requestPostWorld W fee)]
    unfold requestPostWorld
    rw [lookup_upsert_diff _ _ _ _ hr.symm, lookup_upsert_diff _ _ _ _ hv.symm]

/-- The concrete per-hop guard: at request hop `j < n` the vault still holds at
least `fee`. -/
theorem request_phase_guard (mv n fee : Nat) (hfeeM : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) :
    ∀ j, j < n →
      fee ≤ (lookup (requestPhaseWorld fee j (vaultPostWorld mv n fee))
          vaultAddr).selfBalance.val := by
  intro j hj
  have hjfb : j * fee ≤ n * fee := Nat.mul_le_mul_right fee (Nat.le_of_lt hj)
  have hbal := lookup_requestPhaseWorld_vault_balance fee j (vaultPostWorld mv n fee)
    (n * fee) (lookup_vaultPostWorld_vault_balance mv n fee) hfeeM hnf hjfb
  rw [hbal, Core.Uint256.val_ofNat,
    Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le _ _) hnf)]
  have h1 : fee ≤ (n - j) * fee := by
    by_cases hf0 : fee = 0
    · simp [hf0]
    · have hpos : 1 ≤ n - j := Nat.sub_pos_of_lt hj
      calc fee = 1 * fee := (Nat.one_mul fee).symm
        _ ≤ (n - j) * fee := Nat.mul_le_mul_right fee hpos
  have h2 : n * fee - j * fee = (n - j) * fee := (Nat.sub_mul n j fee).symm
  rw [h2]
  exact h1

/-! ### Hop 4+n: Gateway → refund recipient -/

/-- The sink transaction literal for the refund leg. -/
def refundTx (v : Nat) : DenoteTransaction :=
  { sender := gatewayAddr.toNat, msgValue := v, thisAddress := refundAddr.toNat
    functionSelector := 5, args := [v] }

/-- The frame `callEntry` constructs for the refund leg on world `W`. -/
def refundFrame (W : MultiWorld) (mv n fee : Nat) : CallFrame :=
  { caller := gatewayAddr, callee := refundAddr, site := refundSite mv n fee
    callerBefore := lookup W gatewayAddr
    calleeBefore := lookup W refundAddr
    calleeEntry := withCallContext (lookup W refundAddr) gatewayAddr refundAddr
      ((mv - n * fee : Nat) : Core.Uint256) }

/-- The world after the refund frame commits on `W`: the gateway is debited the
remainder (and journals the call), the refund recipient is credited. -/
def refundPostWorld (W : MultiWorld) (mv n fee : Nat) : MultiWorld :=
  upsert (upsert W gatewayAddr
      { lookup W gatewayAddr with
        calls := (lookup W gatewayAddr).calls ++
          [journalEntry (refundSite mv n fee) (.success [])]
        selfBalance := (lookup W gatewayAddr).selfBalance -
          ((mv - n * fee : Nat) : Core.Uint256) })
    refundAddr
    (withPayableCallContext (lookup W refundAddr) (refundTx (mv - n * fee)))

/-- The refund frame on an arbitrary world, as one equation. -/
theorem refund_frame (W : MultiWorld) (mv n fee : Nat)
    (hle : mv - n * fee ≤ (lookup W gatewayAddr).selfBalance.val) :
    callFunction sinkEnv (sinkSpec "RefundRecipient" true) (sinkFn "RefundRecipient" true) 5
        W gatewayAddr refundAddr (refundSite mv n fee) =
      some { frame := refundFrame W mv n fee, result := .success [],
             world := refundPostWorld W mv n fee } := by
  have hne : (gatewayAddr ≠ refundAddr) := by decide
  unfold callFunction MultiContract.call
  simp [callEntry, hne, hle, refundSite, refundFrame, refundPostWorld, refundTx,
    executeCall, runFunctionInFrame, framedJournalEntry,
    sink_body_exec_sel "RefundRecipient" (lookup W refundAddr) (mv - n * fee)
      gatewayAddr.toNat refundAddr.toNat 5]

/-- The compiled form of the refund leg. -/
def refundCompiled (mv n fee : Nat) : CompiledCall :=
  { env := sinkEnv, spec := sinkSpec "RefundRecipient" true,
    fn := sinkFn "RefundRecipient" true, selector := 5,
    caller := gatewayAddr, callee := refundAddr, site := refundSite mv n fee }

/-- Dispatch of the refund pending on an arbitrary world: one hop, no new
pendings. -/
theorem hop_refund (E W : MultiWorld) (mv n fee f h : Nat) (prog : List CompiledCall)
    (hle : mv - n * fee ≤ (lookup W gatewayAddr).selfBalance.val) :
    step (nodeAt honest) E (f + 1) W [refundPending mv n fee] h prog =
      step (nodeAt honest) E f (refundPostWorld W mv n fee) [] (h + 1)
        (refundCompiled mv n fee :: prog) := by
  have hnode : nodeAt honest refundAddr =
      some { env := sinkEnv, spec := sinkSpec "RefundRecipient" true,
             fn := sinkFn "RefundRecipient" true, selector := 5 } := rfl
  simp only [step, refundPending]
  simp only [hnode]
  rw [refund_frame W mv n fee hle]
  simp [step, refundFrame, refundPostWorld, refundSite, refundCompiled, refundTx,
    lookup_upsert_same, calls_withPayableCallContext,
    List.drop_length, ExternalCallResult.succeeded]

/-! ### Assembly: the universal success shape -/

/-- The sender account starts with the full `msgValue`. -/
theorem lookup_initial_sender_balance (mv fee : Nat) :
    (lookup (initial mv fee) senderAddr).selfBalance = Core.Uint256.ofNat mv := rfl

/-- The lido account starts empty. -/
theorem lookup_initial_lido_balance (mv fee : Nat) :
    (lookup (initial mv fee) lidoAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The request account starts empty. -/
theorem lookup_initial_request_balance (mv fee : Nat) :
    (lookup (initial mv fee) requestAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The refund account starts empty. -/
theorem lookup_initial_refund_balance (mv fee : Nat) :
    (lookup (initial mv fee) refundAddr).selfBalance = Core.Uint256.ofNat 0 := rfl

/-- The bus hop touches only the sender and the bus. -/
theorem lookup_busPostWorld_ne (mv n fee : Nat) (a : Address)
    (hs : a ≠ senderAddr) (hb : a ≠ busAddr) :
    lookup (busPostWorld mv n fee) a = lookup (initial mv fee) a := by
  unfold busPostWorld
  rw [lookup_upsert_diff _ _ _ _ hb.symm, lookup_upsert_diff _ _ _ _ hs.symm]

/-- The gateway hop touches only the bus and the gateway. -/
theorem lookup_gwPostWorld_ne (mv n fee : Nat) (a : Address)
    (hb : a ≠ busAddr) (hg : a ≠ gatewayAddr) :
    lookup (gwPostWorld mv n fee) a = lookup (busPostWorld mv n fee) a := by
  unfold gwPostWorld
  rw [lookup_upsert_diff _ _ _ _ hg.symm, lookup_upsert_diff _ _ _ _ hb.symm]

/-- The vault hop touches only the gateway and the vault. -/
theorem lookup_vaultPostWorld_ne (mv n fee : Nat) (a : Address)
    (hg : a ≠ gatewayAddr) (hv : a ≠ vaultAddr) :
    lookup (vaultPostWorld mv n fee) a = lookup (gwPostWorld mv n fee) a := by
  unfold vaultPostWorld
  rw [lookup_upsert_diff _ _ _ _ hv.symm, lookup_upsert_diff _ _ _ _ hg.symm]

/-- The refund hop touches only the gateway and the refund recipient. -/
theorem lookup_refundPostWorld_ne (W : MultiWorld) (mv n fee : Nat) (a : Address)
    (hg : a ≠ gatewayAddr) (hr : a ≠ refundAddr) :
    lookup (refundPostWorld W mv n fee) a = lookup W a := by
  unfold refundPostWorld
  rw [lookup_upsert_diff _ _ _ _ hr.symm, lookup_upsert_diff _ _ _ _ hg.symm]

/-- `ofNat mv - ofNat (n * fee) = ofNat (mv - n * fee)` under no-wrap and
funding. -/
theorem ofNat_sub_mul (mv n fee : Nat) (hmv : mv < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    Core.Uint256.ofNat mv - Core.Uint256.ofNat (n * fee) =
      Core.Uint256.ofNat (mv - n * fee) := by
  have hle' : (n * fee) % Core.Uint256.modulus ≤ mv % Core.Uint256.modulus := by
    rw [Nat.mod_eq_of_lt hnf, Nat.mod_eq_of_lt hmv]; exact hle
  rw [sub_ofNat mv (n * fee) hle', Nat.mod_eq_of_lt hmv, Nat.mod_eq_of_lt hnf]

/-- The gateway's balance after the request phase: still the post-fee
remainder. -/
theorem phase4_gateway_balance_val (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus)
    (hle : n * fee ≤ mv) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) gatewayAddr).selfBalance.val =
      mv - n * fee := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : gatewayAddr ≠ vaultAddr)
    (by decide : gatewayAddr ≠ requestAddr)]
  unfold vaultPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : vaultAddr ≠ gatewayAddr), lookup_upsert_same]
  show ((lookup (gwPostWorld mv n fee) gatewayAddr).selfBalance -
    Core.Uint256.ofNat (n * fee)).val = _
  rw [lookup_gwPostWorld_gateway_balance, sub_ofNat_val mv (n * fee) hmv hnf hle]

/-- The gateway's balance after the request phase, as a `Uint256` equation. -/
theorem phase4_gateway_balance (mv n fee : Nat) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) gatewayAddr).selfBalance =
      Core.Uint256.ofNat mv - Core.Uint256.ofNat (n * fee) := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : gatewayAddr ≠ vaultAddr)
    (by decide : gatewayAddr ≠ requestAddr)]
  unfold vaultPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : vaultAddr ≠ gatewayAddr), lookup_upsert_same]
  show (lookup (gwPostWorld mv n fee) gatewayAddr).selfBalance - Core.Uint256.ofNat (n * fee) = _
  rw [lookup_gwPostWorld_gateway_balance]

/-- Sender balance after the request phase. -/
theorem phase4_sender_val (mv n fee : Nat) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) senderAddr).selfBalance.val = 0 := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : senderAddr ≠ vaultAddr)
    (by decide : senderAddr ≠ requestAddr),
    lookup_vaultPostWorld_ne _ _ _ _ (by decide : senderAddr ≠ gatewayAddr)
      (by decide : senderAddr ≠ vaultAddr),
    lookup_gwPostWorld_ne _ _ _ _ (by decide : senderAddr ≠ busAddr)
      (by decide : senderAddr ≠ gatewayAddr)]
  unfold busPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : busAddr ≠ senderAddr), lookup_upsert_same]
  show ((lookup (initial mv fee) senderAddr).selfBalance - Core.Uint256.ofNat mv).val = 0
  rw [lookup_initial_sender_balance]
  simp

/-- Bus balance after the request phase. -/
theorem phase4_bus_val (mv n fee : Nat) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) busAddr).selfBalance.val = 0 := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : busAddr ≠ vaultAddr)
    (by decide : busAddr ≠ requestAddr),
    lookup_vaultPostWorld_ne _ _ _ _ (by decide : busAddr ≠ gatewayAddr)
      (by decide : busAddr ≠ vaultAddr)]
  unfold gwPostWorld
  rw [lookup_upsert_diff _ _ _ _ (by decide : gatewayAddr ≠ busAddr), lookup_upsert_same]
  show ((lookup (busPostWorld mv n fee) busAddr).selfBalance - Core.Uint256.ofNat mv).val = 0
  rw [lookup_busPostWorld_bus_balance]
  simp

/-- Vault balance after the request phase. -/
theorem phase4_vault_val (mv n fee : Nat)
    (hfee : fee < Core.Uint256.modulus) (hnf : n * fee < Core.Uint256.modulus) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) vaultAddr).selfBalance.val = 0 := by
  rw [lookup_requestPhaseWorld_vault_balance fee n _ (n * fee)
    (lookup_vaultPostWorld_vault_balance mv n fee) hfee hnf (Nat.le_refl _)]
  simp

/-- Lido balance after the request phase. -/
theorem phase4_lido_val (mv n fee : Nat) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) lidoAddr).selfBalance.val = 0 := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : lidoAddr ≠ vaultAddr)
    (by decide : lidoAddr ≠ requestAddr),
    lookup_vaultPostWorld_ne _ _ _ _ (by decide : lidoAddr ≠ gatewayAddr)
      (by decide : lidoAddr ≠ vaultAddr),
    lookup_gwPostWorld_ne _ _ _ _ (by decide : lidoAddr ≠ busAddr)
      (by decide : lidoAddr ≠ gatewayAddr),
    lookup_busPostWorld_ne _ _ _ _ (by decide : lidoAddr ≠ senderAddr)
      (by decide : lidoAddr ≠ busAddr),
    lookup_initial_lido_balance]
  simp

/-- The vault's request account starts empty even after its own frame. -/
theorem lookup_vaultPostWorld_request_balance (mv n fee : Nat) :
    (lookup (vaultPostWorld mv n fee) requestAddr).selfBalance = Core.Uint256.ofNat 0 := by
  rw [lookup_vaultPostWorld_ne _ _ _ _ (by decide : requestAddr ≠ gatewayAddr)
    (by decide : requestAddr ≠ vaultAddr),
    lookup_gwPostWorld_ne _ _ _ _ (by decide : requestAddr ≠ busAddr)
      (by decide : requestAddr ≠ gatewayAddr),
    lookup_busPostWorld_ne _ _ _ _ (by decide : requestAddr ≠ senderAddr)
      (by decide : requestAddr ≠ busAddr),
    lookup_initial_request_balance]

/-- Request predeploy balance after the request phase: the whole product fee. -/
theorem phase4_request_val (mv n fee : Nat) (hnf : n * fee < Core.Uint256.modulus) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) requestAddr).selfBalance.val =
      n * fee := by
  rw [lookup_requestPhaseWorld_request_balance fee n _ 0
    (lookup_vaultPostWorld_request_balance mv n fee)]
  simp [Nat.mod_eq_of_lt hnf]

/-- Refund account balance after the request phase (refund leg not yet run). -/
theorem phase4_refund_val (mv n fee : Nat) :
    (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) refundAddr).selfBalance.val = 0 := by
  rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : refundAddr ≠ vaultAddr)
    (by decide : refundAddr ≠ requestAddr),
    lookup_vaultPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ gatewayAddr)
      (by decide : refundAddr ≠ vaultAddr),
    lookup_gwPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ busAddr)
      (by decide : refundAddr ≠ gatewayAddr),
    lookup_busPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ senderAddr)
      (by decide : refundAddr ≠ busAddr),
    lookup_initial_refund_balance]
  simp

/-- The balance sheet when the batch exactly exhausts `msgValue` (no refund
leg). -/
theorem balances_phase4 (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hz : mv - n * fee = 0) :
    balances (requestPhaseWorld fee n (vaultPostWorld mv n fee)) =
      ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩ := by
  simp [balances, phase4_sender_val mv n fee, phase4_bus_val mv n fee,
    phase4_vault_val mv n fee hfee hnf, phase4_lido_val mv n fee,
    phase4_request_val mv n fee hnf, phase4_refund_val mv n fee,
    phase4_gateway_balance_val mv n fee hmv hnf hle, hz]

/-- The balance sheet after the refund leg commits. -/
theorem balances_final_refund (mv n fee : Nat)
    (hmv : mv < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv) :
    balances (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee)) mv n fee) =
      ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩ := by
  have hsender : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) senderAddr).selfBalance.val = 0 := by
    rw [lookup_refundPostWorld_ne _ _ _ _ _ (by decide : senderAddr ≠ gatewayAddr)
      (by decide : senderAddr ≠ refundAddr)]
    exact phase4_sender_val mv n fee
  have hbus : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) busAddr).selfBalance.val = 0 := by
    rw [lookup_refundPostWorld_ne _ _ _ _ _ (by decide : busAddr ≠ gatewayAddr)
      (by decide : busAddr ≠ refundAddr)]
    exact phase4_bus_val mv n fee
  have hgateway : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) gatewayAddr).selfBalance.val = 0 := by
    unfold refundPostWorld
    rw [lookup_upsert_diff _ _ _ _ (by decide : refundAddr ≠ gatewayAddr), lookup_upsert_same]
    show ((lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee)) gatewayAddr).selfBalance -
      Core.Uint256.ofNat (mv - n * fee)).val = 0
    rw [phase4_gateway_balance, ofNat_sub_mul mv n fee hmv hnf hle]
    simp
  have hvault : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) vaultAddr).selfBalance.val = 0 := by
    rw [lookup_refundPostWorld_ne _ _ _ _ _ (by decide : vaultAddr ≠ gatewayAddr)
      (by decide : vaultAddr ≠ refundAddr)]
    exact phase4_vault_val mv n fee hfee hnf
  have hlido : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) lidoAddr).selfBalance.val = 0 := by
    rw [lookup_refundPostWorld_ne _ _ _ _ _ (by decide : lidoAddr ≠ gatewayAddr)
      (by decide : lidoAddr ≠ refundAddr)]
    exact phase4_lido_val mv n fee
  have hrequest : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) requestAddr).selfBalance.val = n * fee := by
    rw [lookup_refundPostWorld_ne _ _ _ _ _ (by decide : requestAddr ≠ gatewayAddr)
      (by decide : requestAddr ≠ refundAddr)]
    exact phase4_request_val mv n fee hnf
  have hrefund : (lookup (refundPostWorld (requestPhaseWorld fee n (vaultPostWorld mv n fee))
        mv n fee) refundAddr).selfBalance.val = mv - n * fee := by
    unfold refundPostWorld
    rw [lookup_upsert_same, selfBalance_withPayableCallContext]
    have href : (lookup (requestPhaseWorld fee n (vaultPostWorld mv n fee))
          refundAddr).selfBalance = Core.Uint256.ofNat 0 := by
      rw [lookup_requestPhaseWorld_ne _ _ _ _ (by decide : refundAddr ≠ vaultAddr)
        (by decide : refundAddr ≠ requestAddr),
        lookup_vaultPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ gatewayAddr)
          (by decide : refundAddr ≠ vaultAddr),
        lookup_gwPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ busAddr)
          (by decide : refundAddr ≠ gatewayAddr),
        lookup_busPostWorld_ne _ _ _ _ (by decide : refundAddr ≠ senderAddr)
          (by decide : refundAddr ≠ busAddr),
        lookup_initial_refund_balance]
    rw [href]
    show (Core.Uint256.ofNat 0 + Core.Uint256.ofNat (mv - n * fee)).val = mv - n * fee
    rw [← Core.Uint256.ofNat_add, Core.Uint256.val_ofNat, Nat.zero_add,
      Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le mv (n * fee)) hmv)]
  simp [balances, hsender, hbus, hgateway, hvault, hlido, hrequest, hrefund]

/-- **P-ETH-1 Verity-plane universal parent.**  For every funded, guard-passing,
non-wrapping batch that fits the dispatch fuel budget, the honest wiring
commits: the whole product fee lands at the consolidation-request predeploy,
the remainder lands at the refund recipient, and no protocol contract on the
route retains ETH. -/
theorem run_success_shape (mv n fee : Nat)
    (hpos : 0 < mv) (hmv : mv < Core.Uint256.modulus)
    (hnM : n < Core.Uint256.modulus) (hfee : fee < Core.Uint256.modulus)
    (hnf : n * fee < Core.Uint256.modulus) (hle : n * fee ≤ mv)
    (hfuel : n + 4 ≤ fuelBudget) :
    observe (run honest mv n fee) =
      ⟨.success, n + 3 + (if mv - n * fee = 0 then 0 else 1),
        ⟨0, 0, 0, 0, 0, n * fee, mv - n * fee⟩⟩ := by
  have hn28 : n ≤ 28 := by
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
  by_cases hz : mv - n * fee = 0
  · rw [if_pos hz]
    simp only [step]
    simp only [observe, finalWorld]
    rw [balances_phase4 mv n fee hmv hfee hnf hle hz, if_pos hz]
    simp only [TxView.mk.injEq]
    exact ⟨trivial, by omega, trivial⟩
  · rw [if_neg hz]
    rw [show 29 - n = (28 - n) + 1 from by omega]
    rw [hop_refund (initial mv fee) (requestPhaseWorld fee n (vaultPostWorld mv n fee))
      mv n fee (28 - n) (3 + n) _
      (by rw [phase4_gateway_balance_val mv n fee hmv hnf hle]; exact Nat.le_refl _)]
    simp only [step]
    simp only [observe, finalWorld]
    rw [balances_final_refund mv n fee hmv hfee hnf hle, if_neg hz]
    simp only [TxView.mk.injEq]
    exact ⟨trivial, by omega, trivial⟩

end LidoSRv3.Audit.Verity.PEth1CompositionTxUniversal
