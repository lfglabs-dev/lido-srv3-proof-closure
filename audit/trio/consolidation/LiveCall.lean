import audit.trio.consolidation.Producer
import audit.trio.consolidation.Gateway
import audit.trio.consolidation.LowLevel
import LidoSRv3.Audit.Source.TrioReserve1.CallFlow

/-!
# Live CALL of the vault hop (`WithdrawalVaultEIP7685.sol:113-121`)

The producer increment stopped at the concatenation `source ++ target`.
This file consumes that payload as the argument of an actual low-level CALL
(`lowLevelCall`, the EVM CALL opcode rule without a target-code precheck) in
the existing physical `Live.World` (Verity storage lenses, account balances,
committed logs, attempted calls):

```
function _callAddConsolidationRequest(
    bytes calldata sourcePubkey, bytes calldata targetPubkey, uint256 fee
) internal {
    bytes memory request = abi.encodePacked(sourcePubkey, targetPubkey); // 114
    (bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);    // 115
    if (!success) { revert RequestAdditionFailed(request); }             // 116-118
    emit ConsolidationRequestAdded(request);                             // 120
}
```

* `hopRequest` is the CALL of line 115: callee `CONSOLIDATION_REQUEST`,
  value `fee`, payload `vaultCallPayload pair = source ++ target`.
* `callAddConsolidationRequest` is that CALL through `lowLevelCall`,
  then the source's own revert (`RequestAdditionFailed`) on a failed CALL,
  then `emit ConsolidationRequestAdded(request)` on success. Low-level
  `.call` has no target-code guard: a code-less target accepts with empty
  return data after the value transfer (`callAdd_no_code_accepted`).
* `addConsolidationRequestsLoop` is the per-pair loop of lines 68-72
  (`_validatePublicKey` source, `_validatePublicKey` target, hop).
* `getConsolidationRequestFee` is `_getConsolidationRequestFee` /
  `_getFeeFromContract(CONSOLIDATION_REQUEST)` (lines 79-95): an actual
  low-level `staticcall("")`, then the `FeeReadFailed` / `FeeInvalidData`
  ladder, then the 32-byte decode. The fee is read, not supplied.
* `addConsolidationRequestsVault` is `WithdrawalVault.addConsolidationRequests`
  (`WithdrawalVault.sol:199-208`) with the inherited guards of lines 60-66
  and the `preservesEthBalance` modifier (`WithdrawalVault.sol:81-85`).
* `executeVault` is the root transaction under `Live.run`: any failure
  restores every slot, balance and committed event of the entry world.
* `refundFee` is `ConsolidationGateway._refundFee`
  (`ConsolidationGateway.sol:295-307`) as the same low-level CALL primitive
  with an empty payload and value `refund`. The refund recipient may be an
  EOA: `refund_no_code_accepted`.

The vault-hop callee is an arbitrary `External`. Frame conditions on accepted
replies (`LogFrame`, `BalanceFrame`) are explicit premises where a generic
theorem needs them; `Predeploy.lean` derives them from the concrete EIP-7251
body instead of assuming them.

## Residuals (stated, not claimed)

* `RequestAdditionFailed(request)` and `InvalidPublicKeyLength(pubkey)`
  carry their argument in the source. Here the fault is `Fault.reason`
  with the error name; the request octets of the failed hop remain
  observable in the attempt trace (`callAdd_attempt_request`).
* Checked-multiplication overflow and the modifier `assert` are
  `Fault.reason "Panic(0x11)"` / `"Panic(0x01)"`, not ABI panic data.
* The EIP-7251 fake-exponential fee update rule is abstracted into the
  predeploy fee slot (`Predeploy.lean`); per-block excess updates remain
  OPEN. The gateway→vault ABI hop is composed in `Composition.lean`.

Pin `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Codec lemmas are reused, not reopened. P-CONSOLIDATION remains OPEN.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-! ## Vault hop: `_callAddConsolidationRequest` -/

/-- `emit ConsolidationRequestAdded(request)` (line 120), retaining every
request octet as one word (the lossless representation used by
`TopupBeaconCallee.depositEvent`). Not a LOG topic/ABI claim. -/
def requestAddedEvent (self : Live.Address) (request : Bytes) : Log :=
  ⟨self, "ConsolidationRequestAdded", request.map fun b => Live.word b.toNat⟩

/-- The CALL of line 115: `CONSOLIDATION_REQUEST.call{value: fee}(request)`
with `request = abi.encodePacked(sourcePubkey, targetPubkey)`. -/
def hopRequest (ctx : Context) (inbox : Live.Address) (pair : ProducedPair)
    (fee : Live.Word) : Request :=
  ⟨ctx.self, inbox, fee, vaultCallPayload pair⟩

/-- Lines 113-121 in the physical world. The CALL primitive is the low-level
opcode rule `lowLevelCall` (no target-code guard) on the producer payload and
the per-request fee. A failed CALL is the vault's own `RequestAdditionFailed`
revert; success appends the `ConsolidationRequestAdded` event to the
callee-returned world (or, for a code-less target, to the transferred
world). -/
def callAddConsolidationRequest (callee : External) (ctx : Context)
    (inbox : Live.Address) (pair : ProducedPair) (fee : Live.Word) : Exec Unit := fun w =>
  let request := vaultCallPayload pair
  let r := lowLevelCall callee ctx inbox request fee w
  match r.outcome with
  | .ok _ =>
      ⟨.ok (), { r.world with logs := r.world.logs ++ [requestAddedEvent ctx.self request] },
        r.attempts⟩
  | .error _ => ⟨.error (.reason "RequestAdditionFailed"), r.world, r.attempts⟩

/-- The CALL payload is the producer concatenation and the value is `fee`. -/
theorem hopRequest_payload (ctx : Context) (inbox : Live.Address) (pair : ProducedPair)
    (fee : Live.Word) :
    (hopRequest ctx inbox pair fee).payload = pair.source ++ pair.target ∧
      (hopRequest ctx inbox pair fee).value = fee ∧
      (hopRequest ctx inbox pair fee).target = inbox := ⟨rfl, rfl, rfl⟩

/-- The CALL payload is the existing packed encoder output. Reuses
`vaultCallPayload_is_packed` / `encodePackedRequest_of_bytes`; nothing is
reopened. -/
theorem hopRequest_is_packed (ctx : Context) (inbox : Live.Address) (pair : ProducedPair)
    (fee : Live.Word) (h : widthOk pair) :
    (encodePackedRequest
        (raw48Pubkey (sourceRaw48 pair h))
        (raw48Pubkey (targetRaw48 pair h))).map (List.map UInt8.ofNat) =
      some (hopRequest ctx inbox pair fee).payload :=
  vaultCallPayload_is_packed pair h

theorem hopRequest_length (ctx : Context) (inbox : Live.Address) (pair : ProducedPair)
    (fee : Live.Word) (h : widthOk pair) :
    (hopRequest ctx inbox pair fee).payload.length = 96 :=
  widthOk_payload_length pair h

/-- Every attempted call of the hop is the line-115 request: callee
`CONSOLIDATION_REQUEST`, value `fee`, payload `source ++ target`. This holds
on success and on the failed paths, where the source reverts with
`RequestAdditionFailed(request)`. -/
theorem callAdd_attempt_request (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World) (a : Attempt)
    (ha : a ∈ (callAddConsolidationRequest callee ctx inbox pair fee w).attempts) :
    a.request = hopRequest ctx inbox pair fee := by
  rcases lowLevelCall_shape callee ctx inbox (vaultCallPayload pair) fee w with
    ⟨-, h⟩ | ⟨-, -, h⟩ | ⟨-, -, h⟩
  · simp [callAddConsolidationRequest, h] at ha
    simp [ha, hopRequest]
  · simp [callAddConsolidationRequest, h] at ha
    simp [ha, hopRequest]
  · rcases h with ⟨data, -, h⟩ | ⟨data, nested, -, h⟩ | ⟨data, after, -, h⟩ |
        ⟨data, after, nested, -, h⟩ <;>
      simp [callAddConsolidationRequest, h] at ha <;> simp [ha, hopRequest]

/-- Failed hop: the fault is the vault's own error, not bubbled callee data. -/
theorem callAdd_fault (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World) (fault : Fault)
    (h : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome = .error fault) :
    fault = .reason "RequestAdditionFailed" := by
  rcases lowLevelCall_shape callee ctx inbox (vaultCallPayload pair) fee w with
    ⟨-, hs⟩ | ⟨-, -, hs⟩ | ⟨-, -, hs⟩
  · simp [callAddConsolidationRequest, hs] at h
    exact h.symm
  · simp [callAddConsolidationRequest, hs] at h
  · rcases hs with ⟨data, -, hs⟩ | ⟨data, nested, -, hs⟩ | ⟨data, after, -, hs⟩ |
        ⟨data, after, nested, -, hs⟩ <;>
      simp [callAddConsolidationRequest, hs] at h
    · exact h.symm
    · exact h.symm

/-- Failed hop restores the incoming world: the provisional value transfer
and every callee effect are rolled back, and no event is committed. -/
theorem callAdd_error_restores (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World) (fault : Fault)
    (h : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome = .error fault) :
    (callAddConsolidationRequest callee ctx inbox pair fee w).world = w := by
  rcases lowLevelCall_shape callee ctx inbox (vaultCallPayload pair) fee w with
    ⟨-, hs⟩ | ⟨-, -, hs⟩ | ⟨-, -, hs⟩
  · simp [callAddConsolidationRequest, hs] at h ⊢
  · simp [callAddConsolidationRequest, hs] at h
  · rcases hs with ⟨data, -, hs⟩ | ⟨data, nested, -, hs⟩ | ⟨data, after, -, hs⟩ |
        ⟨data, after, nested, -, hs⟩ <;>
      simp [callAddConsolidationRequest, hs] at h ⊢

/-- Successful hop: exactly one accepted attempt with the line-115 request,
and the committed world is the callee-returned world plus the
`ConsolidationRequestAdded(request)` event. The code-less (EOA) arm is the
`data = []`, `after = transfer w ctx.self inbox fee.val`, `nested = []`
instance. -/
theorem callAdd_success (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (h : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome = .ok ()) :
    ∃ data after nested,
      lowLevelCall callee ctx inbox (vaultCallPayload pair) fee w =
        ⟨.ok data, after, [⟨hopRequest ctx inbox pair fee, true, data, nested⟩]⟩ ∧
      (callAddConsolidationRequest callee ctx inbox pair fee w).world =
        { after with logs := after.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] } ∧
      (callAddConsolidationRequest callee ctx inbox pair fee w).attempts =
        [⟨hopRequest ctx inbox pair fee, true, data, nested⟩] := by
  rcases lowLevelCall_shape callee ctx inbox (vaultCallPayload pair) fee w with
    ⟨-, hs⟩ | ⟨-, -, hs⟩ | ⟨-, -, hs⟩
  · simp [callAddConsolidationRequest, hs] at h
  · exact ⟨[], _, [], hs, by simp [callAddConsolidationRequest, hs],
      by simp [callAddConsolidationRequest, hs, hopRequest]⟩
  · rcases hs with ⟨data, -, hs⟩ | ⟨data, nested, -, hs⟩ | ⟨data, after, -, hs⟩ |
        ⟨data, after, nested, -, hs⟩
    · simp [callAddConsolidationRequest, hs] at h
    · simp [callAddConsolidationRequest, hs] at h
    · exact ⟨data, after, [], hs, by simp [callAddConsolidationRequest, hs],
        by simp [callAddConsolidationRequest, hs, hopRequest]⟩
    · exact ⟨data, after, nested, hs, by simp [callAddConsolidationRequest, hs],
        by simp [callAddConsolidationRequest, hs, hopRequest]⟩

/-- Successful hop requires a funded caller. The target needs no code: the
low-level CALL accepts code-less recipients (EOA). -/
theorem callAdd_success_funded (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (h : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome = .ok ()) :
    fee.val ≤ w.balances ctx.self := by
  obtain ⟨data, after, nested, hinv, -, -⟩ := callAdd_success callee ctx inbox pair fee w h
  exact lowLevelCall_success_funded callee ctx inbox (vaultCallPayload pair) fee w data after
    [⟨hopRequest ctx inbox pair fee, true, data, nested⟩] hinv

/-! ### Concrete reply arms -/

/-- Code-less target (EOA, or an undeployed address): the low-level CALL
accepts with empty return data after the value transfer, so the vault emits
`ConsolidationRequestAdded` and continues. This is the EVM rule the
code-guarded primitive misstated. -/
theorem callAdd_no_code_accepted (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (hc : (w.core.codeSize inbox.val).val = 0) (hb : fee.val ≤ w.balances ctx.self) :
    callAddConsolidationRequest callee ctx inbox pair fee w =
      ⟨.ok (), { transfer w ctx.self inbox fee.val with
          logs := w.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] },
        [⟨hopRequest ctx inbox pair fee, true, [], []⟩]⟩ := by
  unfold callAddConsolidationRequest lowLevelCall
  simp [hc, Nat.not_lt.mpr hb, hopRequest, transfer]

/-- Stable name of the no-code arm inspected since #281. Under `lowLevelCall`
it is the acceptance arm (`callAdd_no_code_accepted`), not the revert the
code-guarded primitive produced. -/
theorem callAdd_no_code (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (hc : (w.core.codeSize inbox.val).val = 0) (hb : fee.val ≤ w.balances ctx.self) :
    callAddConsolidationRequest callee ctx inbox pair fee w =
      ⟨.ok (), { transfer w ctx.self inbox fee.val with
          logs := w.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] },
        [⟨hopRequest ctx inbox pair fee, true, [], []⟩]⟩ :=
  callAdd_no_code_accepted callee ctx inbox pair fee w hc hb

/-- Insufficient vault balance for `fee`: failed attempt, no callee run. -/
theorem callAdd_unfunded (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (hb : w.balances ctx.self < fee.val) :
    callAddConsolidationRequest callee ctx inbox pair fee w =
      ⟨.error (.reason "RequestAdditionFailed"), w,
        [⟨hopRequest ctx inbox pair fee, false, [], []⟩]⟩ := by
  unfold callAddConsolidationRequest lowLevelCall
  simp [hb, hopRequest]

/-- Callee rejects: the value transfer is rolled back, the vault reverts
with `RequestAdditionFailed`, and no event is committed. -/
theorem callAdd_rejected (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World) (data : Bytes)
    (hc : (w.core.codeSize inbox.val).val ≠ 0) (hb : fee.val ≤ w.balances ctx.self)
    (hr : callee (hopRequest ctx inbox pair fee) (transfer w ctx.self inbox fee.val) =
      .rejected data) :
    callAddConsolidationRequest callee ctx inbox pair fee w =
      ⟨.error (.reason "RequestAdditionFailed"), w,
        [⟨hopRequest ctx inbox pair fee, false, data, []⟩]⟩ := by
  unfold hopRequest at hr ⊢
  unfold callAddConsolidationRequest lowLevelCall
  simp [hc, Nat.not_lt.mpr hb, hr]

/-- Callee accepts: the committed world is the callee's world after the
value transfer, plus `ConsolidationRequestAdded(source ++ target)`. -/
theorem callAdd_accepted (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w after : World) (data : Bytes)
    (hc : (w.core.codeSize inbox.val).val ≠ 0) (hb : fee.val ≤ w.balances ctx.self)
    (hr : callee (hopRequest ctx inbox pair fee) (transfer w ctx.self inbox fee.val) =
      .success data after) :
    callAddConsolidationRequest callee ctx inbox pair fee w =
      ⟨.ok (), { after with logs := after.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] },
        [⟨hopRequest ctx inbox pair fee, true, data, []⟩]⟩ := by
  unfold hopRequest at hr ⊢
  unfold callAddConsolidationRequest lowLevelCall
  simp [hc, Nat.not_lt.mpr hb, hr]

/-- The provisional transfer of the accepted hop is the CALL ledger rule:
`fee` leaves the vault and reaches `CONSOLIDATION_REQUEST` before the callee
runs. -/
theorem callAdd_credited_balances (ctx : Context) (inbox : Live.Address) (fee : Live.Word)
    (w : World) (hb : fee.val ≤ w.balances ctx.self) :
    CallSpec.Balances w.balances (transfer w ctx.self inbox fee.val).balances
      ctx.self inbox fee.val :=
  CallFlow.transfer_balances w ctx.self inbox fee.val hb

/-! ## Per-pair loop (`WithdrawalVaultEIP7685.sol:68-72`) -/

/-- `_validatePublicKey` (lines 97-101). -/
def validatePublicKey (pubkey : Bytes) : Exec Unit :=
  Live.require (decide (pubkey.length = pubkeyLength)) (.reason "InvalidPublicKeyLength")

/-- Lines 68-72: validate source, validate target, hop. A later failure in
the loop is a root revert of earlier hops (`executeVault_failure_restores`). -/
def addConsolidationRequestsLoop (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) : List ProducedPair → Exec Unit
  | [] => pure ()
  | pair :: rest => do
      validatePublicKey pair.source
      validatePublicKey pair.target
      callAddConsolidationRequest callee ctx inbox pair fee
      addConsolidationRequestsLoop callee ctx inbox fee rest

/-- The accepted attempt trace of the loop, one line-115 request per pair. -/
def hopRequests (ctx : Context) (inbox : Live.Address) (fee : Live.Word)
    (pairs : List ProducedPair) : List Request :=
  pairs.map fun pair => hopRequest ctx inbox pair fee

private theorem bind_ok {α β : Type} (first : Exec α) (next : α → Exec β) (w : World)
    (a : α) (w' : World) (attempts : List Attempt)
    (h : first w = ⟨.ok a, w', attempts⟩) :
    (first >>= next) w =
      ⟨(next a w').outcome, (next a w').world, attempts ++ (next a w').attempts⟩ := by
  change bindExec first next w = _
  simp [bindExec, h]

private theorem bind_error {α β : Type} (first : Exec α) (next : α → Exec β) (w : World)
    (fault : Fault) (w' : World) (attempts : List Attempt)
    (h : first w = ⟨.error fault, w', attempts⟩) :
    (first >>= next) w = ⟨.error fault, w', attempts⟩ := by
  change bindExec first next w = _
  simp [bindExec, h]

private theorem validate_ok (pubkey : Bytes) (w : World) (h : pubkey.length = pubkeyLength) :
    validatePublicKey pubkey w = ⟨.ok (), w, []⟩ := by
  simp [validatePublicKey, Live.require, h, pure, pureExec]

private theorem validate_fail (pubkey : Bytes) (w : World) (h : pubkey.length ≠ pubkeyLength) :
    validatePublicKey pubkey w = ⟨.error (.reason "InvalidPublicKeyLength"), w, []⟩ := by
  simp [validatePublicKey, Live.require, h, fail]

/-- Loop step on a width-valid pair: the hop runs, then the rest. -/
private theorem loop_cons_valid (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) (pair : ProducedPair) (rest : List ProducedPair) (w : World)
    (h : widthOk pair) :
    addConsolidationRequestsLoop callee ctx inbox fee (pair :: rest) w =
      (callAddConsolidationRequest callee ctx inbox pair fee >>=
        fun _ => addConsolidationRequestsLoop callee ctx inbox fee rest) w := by
  rw [addConsolidationRequestsLoop, bind_ok _ _ w () w [] (validate_ok pair.source w h.1),
    bind_ok _ _ w () w [] (validate_ok pair.target w h.2)]
  simp only [List.nil_append]

/-- Loop step on a width-invalid pair: `InvalidPublicKeyLength`, no hop. -/
private theorem loop_cons_invalid (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) (pair : ProducedPair) (rest : List ProducedPair) (w : World)
    (h : ¬ widthOk pair) :
    addConsolidationRequestsLoop callee ctx inbox fee (pair :: rest) w =
      ⟨.error (.reason "InvalidPublicKeyLength"), w, []⟩ := by
  rw [addConsolidationRequestsLoop]
  by_cases hs : pair.source.length = pubkeyLength
  · have ht : pair.target.length ≠ pubkeyLength := fun ht => h ⟨hs, ht⟩
    rw [bind_ok _ _ w () w [] (validate_ok pair.source w hs),
      bind_error _ _ w _ w [] (validate_fail pair.target w ht)]
    simp
  · rw [bind_error _ _ w _ w [] (validate_fail pair.source w hs)]

/-- A successful loop: every pair passed `_validatePublicKey`, exactly one
accepted line-115 attempt per pair in `_prepareConsolidationPairs` order,
and every hop payload is the packed producer concatenation. -/
theorem loop_success (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) (pairs : List ProducedPair) (w : World)
    (h : (addConsolidationRequestsLoop callee ctx inbox fee pairs w).outcome = .ok ()) :
    (∀ pair ∈ pairs, widthOk pair) ∧
      (addConsolidationRequestsLoop callee ctx inbox fee pairs w).attempts.map (·.request) =
        hopRequests ctx inbox fee pairs ∧
      ∀ a ∈ (addConsolidationRequestsLoop callee ctx inbox fee pairs w).attempts,
        a.accepted = true := by
  induction pairs generalizing w with
  | nil =>
      refine ⟨by simp, ?_, by simp [addConsolidationRequestsLoop, pure, pureExec]⟩
      simp [addConsolidationRequestsLoop, pure, pureExec, hopRequests]
  | cons pair rest ih =>
      by_cases hw : widthOk pair
      · rw [loop_cons_valid callee ctx inbox fee pair rest w hw] at h ⊢
        rcases hcall : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome with fault | u
        ·
            rw [bind_error _ _ w fault _ _ (by rw [← hcall])] at h
            simp at h
        · 
            obtain ⟨data, after, nested, -, hworld, hattempts⟩ :=
              callAdd_success callee ctx inbox pair fee w (by rw [hcall])
            have hfirst : callAddConsolidationRequest callee ctx inbox pair fee w =
                ⟨.ok (), { after with logs :=
                    after.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] },
                  [⟨hopRequest ctx inbox pair fee, true, data, nested⟩]⟩ := by
              rw [← hworld, ← hattempts]
              cases u
              rw [← hcall]
            rw [bind_ok _ _ w () _ _ hfirst] at h ⊢
            simp only at h
            obtain ⟨hvalid, hreq, hacc⟩ := ih _ h
            refine ⟨?_, ?_, ?_⟩
            · intro p hp
              rcases List.mem_cons.mp hp with rfl | hp
              · exact hw
              · exact hvalid p hp
            · simp only [List.map_append, List.map_cons, List.map_nil, hreq, hopRequests]
              rfl
            · intro a ha
              simp only [List.mem_append, List.mem_singleton] at ha
              rcases ha with rfl | ha
              · rfl
              · exact hacc a ha
      · rw [loop_cons_invalid callee ctx inbox fee pair rest w hw] at h
        simp at h

/-- Every attempted call of the loop, on any outcome, is a line-115 request
for some pair of the batch: callee `CONSOLIDATION_REQUEST`, value `fee`,
payload `source ++ target`. -/
theorem loop_attempt_request (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) (pairs : List ProducedPair) (w : World) (a : Attempt)
    (ha : a ∈ (addConsolidationRequestsLoop callee ctx inbox fee pairs w).attempts) :
    ∃ pair ∈ pairs, a.request = hopRequest ctx inbox pair fee := by
  induction pairs generalizing w with
  | nil => simp [addConsolidationRequestsLoop, pure, pureExec] at ha
  | cons pair rest ih =>
      by_cases hw : widthOk pair
      · rw [loop_cons_valid callee ctx inbox fee pair rest w hw] at ha
        rcases hcall : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome with fault | u
        ·
            rw [bind_error _ _ w fault _ _ (by rw [← hcall])] at ha
            exact ⟨pair, List.mem_cons_self .., callAdd_attempt_request callee ctx inbox pair fee w a ha⟩
        · 
            cases u
            rw [bind_ok _ _ w () _ _ (by rw [← hcall])] at ha
            simp only [List.mem_append] at ha
            rcases ha with ha | ha
            · exact ⟨pair, List.mem_cons_self .., callAdd_attempt_request callee ctx inbox pair fee w a ha⟩
            · obtain ⟨p, hp, hreq⟩ := ih _ ha
              exact ⟨p, List.mem_cons_of_mem pair hp, hreq⟩
      · rw [loop_cons_invalid callee ctx inbox fee pair rest w hw] at ha
        simp at ha

/-! ### Frame conditions on the callee (explicit premises, not assumptions
about the predeploy) -/

/-- Accepted replies commit no logs of their own. -/
def LogFrame (callee : External) : Prop :=
  ∀ req w data after, callee req w = .success data after → after.logs = w.logs

/-- Accepted replies leave balances as credited by the CALL transfer. -/
def BalanceFrame (callee : External) : Prop :=
  ∀ req w data after, callee req w = .success data after → after.balances = w.balances

/-- Accepted replies are untraced primitive successes (no nested calls). -/
def Untraced (callee : External) : Prop :=
  ∀ req w data after nested, callee req w ≠ .successWithTrace data after nested

private theorem callAdd_success_frame (callee : External) (ctx : Context) (inbox : Live.Address)
    (pair : ProducedPair) (fee : Live.Word) (w : World)
    (hlog : LogFrame callee) (hbal : BalanceFrame callee) (hun : Untraced callee)
    (h : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome = .ok ()) :
    (callAddConsolidationRequest callee ctx inbox pair fee w).world.logs =
        w.logs ++ [requestAddedEvent ctx.self (vaultCallPayload pair)] ∧
      CallSpec.Balances w.balances
        (callAddConsolidationRequest callee ctx inbox pair fee w).world.balances
        ctx.self inbox fee.val := by
  have hb := callAdd_success_funded callee ctx inbox pair fee w h
  by_cases hc : (w.core.codeSize inbox.val).val = 0
  · -- EOA arm: no callee run; the transfer itself is the frame.
    rw [callAdd_no_code_accepted callee ctx inbox pair fee w hc hb]
    refine ⟨?_, ?_⟩
    · rfl
    · exact CallFlow.transfer_balances w ctx.self inbox fee.val hb
  · cases hr : callee ⟨ctx.self, inbox, fee, vaultCallPayload pair⟩
        (transfer w ctx.self inbox fee.val) with
    | rejected data =>
        have := callAdd_rejected callee ctx inbox pair fee w data hc hb hr
        rw [this] at h
        simp at h
    | rejectedWithTrace data nested =>
        unfold callAddConsolidationRequest lowLevelCall at h
        simp [hc, Nat.not_lt.mpr hb, hr] at h
    | successWithTrace data after nested => exact absurd hr (hun _ _ _ _ _)
    | success data after =>
        rw [callAdd_accepted callee ctx inbox pair fee w after data hc hb hr]
        have hl := hlog _ _ _ _ hr
        have hbl := hbal _ _ _ _ hr
        refine ⟨?_, ?_⟩
        · simp only [hl]
          rfl
        · simp only [hbl]
          exact CallFlow.transfer_balances w ctx.self inbox fee.val hb

/-- Aggregate ledger of `n` hops of `fee` each. -/
private theorem balances_trans {before mid after : Live.Address → Nat}
    (self inbox : Live.Address) (a b : Nat)
    (h₁ : CallSpec.Balances before mid self inbox a)
    (h₂ : CallSpec.Balances mid after self inbox b) :
    CallSpec.Balances before after self inbox (a + b) := by
  intro account
  have e₁ := h₁ account
  have e₂ := h₂ account
  by_cases hs : account = self
  · by_cases hr : account = inbox
    · rw [if_pos hs, if_pos hr] at e₁ e₂ ⊢
      omega
    · rw [if_pos hs, if_neg hr] at e₁ e₂ ⊢
      omega
  · by_cases hr : account = inbox
    · rw [if_neg hs, if_pos hr] at e₁ e₂ ⊢
      omega
    · rw [if_neg hs, if_neg hr] at e₁ e₂ ⊢
      omega

private theorem balances_refl (before : Live.Address → Nat) (self inbox : Live.Address) :
    CallSpec.Balances before before self inbox 0 := by
  intro account
  simp

/-- Committed loop under the callee frame: the vault's events are exactly
one `ConsolidationRequestAdded(source ++ target)` per pair, appended in
order, and the ledger moved exactly `pairs.length * fee` from the vault to
`CONSOLIDATION_REQUEST`. -/
theorem loop_success_frame (callee : External) (ctx : Context) (inbox : Live.Address)
    (fee : Live.Word) (pairs : List ProducedPair) (w : World)
    (hlog : LogFrame callee) (hbal : BalanceFrame callee) (hun : Untraced callee)
    (h : (addConsolidationRequestsLoop callee ctx inbox fee pairs w).outcome = .ok ()) :
    (addConsolidationRequestsLoop callee ctx inbox fee pairs w).world.logs =
        w.logs ++ pairs.map (fun pair => requestAddedEvent ctx.self (vaultCallPayload pair)) ∧
      CallSpec.Balances w.balances
        (addConsolidationRequestsLoop callee ctx inbox fee pairs w).world.balances
        ctx.self inbox (pairs.length * fee.val) := by
  induction pairs generalizing w with
  | nil =>
      constructor
      · simp [addConsolidationRequestsLoop, pure, pureExec]
      · simpa [addConsolidationRequestsLoop, pure, pureExec] using
          balances_refl w.balances ctx.self inbox
  | cons pair rest ih =>
      by_cases hw : widthOk pair
      · rw [loop_cons_valid callee ctx inbox fee pair rest w hw] at h ⊢
        rcases hcall : (callAddConsolidationRequest callee ctx inbox pair fee w).outcome with fault | u
        ·
            rw [bind_error _ _ w fault _ _ (by rw [← hcall])] at h
            simp at h
        · 
            cases u
            obtain ⟨hlogs, hbalances⟩ :=
              callAdd_success_frame callee ctx inbox pair fee w hlog hbal hun hcall
            rw [bind_ok _ _ w () _ _ (by rw [← hcall])] at h ⊢
            simp only at h ⊢
            obtain ⟨ihl, ihb⟩ := ih _ h
            refine ⟨?_, ?_⟩
            · rw [ihl, hlogs, List.map_cons, List.append_assoc, List.singleton_append]
            · have := balances_trans ctx.self inbox fee.val (rest.length * fee.val) hbalances ihb
              simpa [List.length_cons, Nat.succ_mul, Nat.add_comm] using this
      · rw [loop_cons_invalid callee ctx inbox fee pair rest w hw] at h
        simp at h

/-! ## Vault entrypoint and root rollback -/

/-- `address(this).balance` in the current world. -/
def selfBalance (ctx : Context) : Exec Nat := fun w => ⟨.ok (w.balances ctx.self), w, []⟩

/-- `sources.zip targets` as producer pairs (line 71 indexes both arrays). -/
def pairsOf (sources targets : List Bytes) : List ProducedPair :=
  (sources.zip targets).map fun st => { source := st.1, target := st.2 }

/-- `_getConsolidationRequestFee()` / `_getFeeFromContract(CONSOLIDATION_REQUEST)`
(`WithdrawalVaultEIP7685.sol:79-95`): an actual low-level `staticcall("")` to
the predeploy, then the source's own ladder — `FeeReadFailed` on a failed
STATICCALL, `FeeInvalidData` on returndata other than 32 bytes, otherwise the
big-endian word decode (`abi.decode(feeData, (uint256))`). A code-less target
answers empty success, so it fails here as `FeeInvalidData`, matching the
source. The fee is read, not supplied. -/
def getConsolidationRequestFee (sexternal : StaticCall.External) (ctx : Context)
    (inbox : Live.Address) : Exec Live.Word := fun w =>
  let r := lowLevelStaticCall sexternal ctx.self inbox [] w
  match r.outcome with
  | .error _ => ⟨.error (.reason "FeeReadFailed"), w, []⟩
  | .ok data =>
      if data.length = 32 then ⟨.ok (Live.word (decode data)), w, []⟩
      else ⟨.error (.reason "FeeInvalidData"), w, []⟩

/-- `WithdrawalVault.addConsolidationRequests` (`WithdrawalVault.sol:199-208`)
with the inherited guards (`WithdrawalVaultEIP7685.sol:60-66`) and the
`preservesEthBalance` modifier (`WithdrawalVault.sol:81-85`). The entry world
is the callee world after the payable credit of `msgValue`, as the CALL rule
hands it to a callee. `fee` is actually read by `getConsolidationRequestFee`
(lines 65 / 79-95), after the `ZeroArgument` / `ArraysLengthMismatch` guards
and before the checked exact-fee requirement, as in the source. -/
def addConsolidationRequestsVault (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) : Exec Unit := do
  -- WithdrawalVault.sol:82  balanceBeforeCall = address(this).balance - msg.value
  let entry ← selfBalance ctx
  -- WithdrawalVault.sol:203-205
  Live.require (decide (ctx.sender = gateway)) (.reason "NotConsolidationGateway")
  -- WithdrawalVaultEIP7685.sol:60-61
  Live.require (decide (sources.length ≠ 0)) (.reason "ZeroArgument")
  -- WithdrawalVaultEIP7685.sol:62-63
  Live.require (decide (sources.length = targets.length)) (.reason "ArraysLengthMismatch")
  -- WithdrawalVaultEIP7685.sol:65 / 79-95: the fee STATICCALL
  let fee ← getConsolidationRequestFee sexternal ctx inbox
  -- WithdrawalVaultEIP7685.sol:66 / 123-126: checked `requestsCount * fee`, exact fee
  Live.require (decide (sources.length * fee.val < Verity.Core.UINT256_MODULUS))
    (.reason "Panic(0x11)")
  Live.require (decide (sources.length * fee.val = msgValue.val)) (.reason "IncorrectFee")
  -- WithdrawalVaultEIP7685.sol:68-72
  addConsolidationRequestsLoop callee ctx inbox fee (pairsOf sources targets)
  -- WithdrawalVault.sol:84  assert(address(this).balance == balanceBeforeCall)
  let exit ← selfBalance ctx
  Live.require (decide (exit = entry - msgValue.val)) (.reason "Panic(0x01)")

/-- Root transaction of the vault entrypoint under `Live.run`. -/
def executeVault (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World) : Result Unit :=
  Live.run (addConsolidationRequestsVault callee sexternal ctx gateway inbox msgValue
    sources targets) before

/-- Root revert restores the entire entry world: every account slot, balance
and committed event, including those of earlier accepted hops. Attempted
calls remain observable to the audit. -/
theorem executeVault_failure_restores (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World) (fault : Fault)
    (h : (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).outcome =
      .error fault) :
    (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).world =
      before := by
  unfold executeVault Live.run at *
  dsimp only at *
  split <;> simp_all

/-- Root success is the unrolled-back body result. -/
theorem executeVault_success_body (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World)
    (h : (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).outcome =
      .ok ()) :
    executeVault callee sexternal ctx gateway inbox msgValue sources targets before =
      addConsolidationRequestsVault callee sexternal ctx gateway inbox msgValue sources targets
        before := by
  unfold executeVault Live.run at *
  dsimp only at *
  split <;> simp_all

private theorem require_ok (c : Bool) (fault : Fault) (w : World) (h : c = true) :
    Live.require c fault w = ⟨.ok (), w, []⟩ := by
  simp [Live.require, h, pure, pureExec]

private theorem require_fail (c : Bool) (fault : Fault) (w : World) (h : c = false) :
    Live.require c fault w = ⟨.error fault, w, []⟩ := by
  simp [Live.require, h, fail]

/-- A successful 32-byte STATICCALL reply yields the decoded fee word. -/
theorem feeRead_ok (sexternal : StaticCall.External) (ctx : Context)
    (inbox : Live.Address) (w : World) (feeData : Bytes) (sattempts : List NestedAttempt)
    (h : lowLevelStaticCall sexternal ctx.self inbox [] w = ⟨.ok feeData, sattempts⟩)
    (hlen : feeData.length = 32) :
    getConsolidationRequestFee sexternal ctx inbox w =
      ⟨.ok (Live.word (decode feeData)), w, []⟩ := by
  simp [getConsolidationRequestFee, h, hlen]

/-- A failed STATICCALL is `FeeReadFailed` (lines 86-88). -/
private theorem feeRead_failed (sexternal : StaticCall.External) (ctx : Context)
    (inbox : Live.Address) (w : World) (sdata : Bytes) (sattempts : List NestedAttempt)
    (h : lowLevelStaticCall sexternal ctx.self inbox [] w = ⟨.error sdata, sattempts⟩) :
    getConsolidationRequestFee sexternal ctx inbox w =
      ⟨.error (.reason "FeeReadFailed"), w, []⟩ := by
  simp [getConsolidationRequestFee, h]

/-- Malformed returndata (length ≠ 32) is `FeeInvalidData` (lines 90-92). A
code-less target lands here: its low-level STATICCALL succeeds with empty
return data. -/
private theorem feeRead_invalid (sexternal : StaticCall.External) (ctx : Context)
    (inbox : Live.Address) (w : World) (feeData : Bytes) (sattempts : List NestedAttempt)
    (h : lowLevelStaticCall sexternal ctx.self inbox [] w = ⟨.ok feeData, sattempts⟩)
    (hlen : feeData.length ≠ 32) :
    getConsolidationRequestFee sexternal ctx inbox w =
      ⟨.error (.reason "FeeInvalidData"), w, []⟩ := by
  simp [getConsolidationRequestFee, h, hlen]

/-- Committed vault entrypoint: the guards of lines 60-66 held (gateway
caller, nonempty equal-length arrays), the fee was actually read by the
line-84 `staticcall("")` (32-byte success reply), the checked exact-fee held
for that read word, the loop committed one accepted line-115 attempt per
zipped pair, and the modifier assertion held on the committed world: the
vault balance is the entry balance minus `msg.value`. -/
theorem executeVault_success (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World)
    (h : (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).outcome =
      .ok ()) :
    ctx.sender = gateway ∧ sources ≠ [] ∧ sources.length = targets.length ∧
      ∃ feeData sattempts,
        lowLevelStaticCall sexternal ctx.self inbox [] before = ⟨.ok feeData, sattempts⟩ ∧
        feeData.length = 32 ∧
        sources.length * (Live.word (decode feeData)).val = msgValue.val ∧
        (∀ pair ∈ pairsOf sources targets, widthOk pair) ∧
        (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).attempts.map
            (·.request) =
          hopRequests ctx inbox (Live.word (decode feeData)) (pairsOf sources targets) ∧
        (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).world.balances
            ctx.self = before.balances ctx.self - msgValue.val := by
  have hbody := executeVault_success_body callee sexternal ctx gateway inbox msgValue sources
    targets before h
  rw [hbody] at h ⊢
  unfold addConsolidationRequestsVault at h ⊢
  rw [bind_ok (selfBalance ctx) _ before _ before [] rfl] at h ⊢
  by_cases hsender : ctx.sender = gateway
  · rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hsender]))] at h ⊢
    by_cases hnonempty : sources.length ≠ 0
    · rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hnonempty]))] at h ⊢
      by_cases hlen : sources.length = targets.length
      · rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hlen]))] at h ⊢
        rcases hs : lowLevelStaticCall sexternal ctx.self inbox [] before with ⟨sout, satt⟩
        match sout with
        | .error sdata =>
            rw [bind_error _ _ before _ before []
              (feeRead_failed sexternal ctx inbox before sdata satt hs)] at h
            simp at h
        | .ok feeData =>
            by_cases hflen : feeData.length = 32
            · rw [bind_ok _ _ before _ before []
                (feeRead_ok sexternal ctx inbox before feeData satt hs hflen)] at h ⊢
              by_cases hfit : sources.length * (Live.word (decode feeData)).val <
                  Verity.Core.UINT256_MODULUS
              · rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hfit]))] at h ⊢
                by_cases hexact : sources.length * (Live.word (decode feeData)).val = msgValue.val
                · rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hexact]))]
                    at h ⊢
                  rcases hloop : (addConsolidationRequestsLoop callee ctx inbox
                      (Live.word (decode feeData))
                      (pairsOf sources targets) before).outcome with fault | u
                  · rw [bind_error _ _ before fault _ _ (by rw [← hloop])] at h
                    simp at h
                  · cases u
                    rw [bind_ok _ _ before () _ _ (by rw [← hloop])] at h ⊢
                    obtain ⟨hvalid, hreq, -⟩ :=
                      loop_success callee ctx inbox (Live.word (decode feeData))
                        (pairsOf sources targets) before hloop
                    set after := (addConsolidationRequestsLoop callee ctx inbox
                      (Live.word (decode feeData)) (pairsOf sources targets) before).world
                      with hafter
                    rw [bind_ok (selfBalance ctx) _ after _ after [] rfl] at h ⊢
                    by_cases hassert :
                        after.balances ctx.self = before.balances ctx.self - msgValue.val
                    · rw [require_ok _ _ after (by simp [hassert])] at h ⊢
                      refine ⟨hsender, ?_, hlen, feeData, satt, rfl, hflen, hexact, hvalid, ?_,
                        hassert⟩
                      · intro hnil
                        exact hnonempty (by simp [hnil])
                      · simp only [List.nil_append, List.append_nil, hreq]
                    · rw [require_fail _ _ after (by simp [hassert])] at h
                      simp at h
                · rw [bind_error _ _ before _ before [] (require_fail _ _ before
                    (by simp [hexact]))] at h
                  simp at h
              · rw [bind_error _ _ before _ before [] (require_fail _ _ before (by simp [hfit]))]
                  at h
                simp at h
            · rw [bind_error _ _ before _ before []
                (feeRead_invalid sexternal ctx inbox before feeData satt hs hflen)] at h
              simp at h
      · rw [bind_error _ _ before _ before [] (require_fail _ _ before (by simp [hlen]))] at h
        simp at h
    · rw [bind_error _ _ before _ before [] (require_fail _ _ before (by simp [hnonempty]))] at h
      simp at h
  · rw [bind_error _ _ before _ before [] (require_fail _ _ before (by simp [hsender]))] at h
    simp at h

/-- Under the callee frame, a committed vault entrypoint emitted exactly the
per-pair `ConsolidationRequestAdded(source ++ target)` events in order, and
the ledger moved exactly `msg.value` from the vault to `CONSOLIDATION_REQUEST`. -/
theorem executeVault_success_frame (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World)
    (hlog : LogFrame callee) (hbal : BalanceFrame callee) (hun : Untraced callee)
    (h : (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).outcome =
      .ok ()) :
    (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).world.logs =
        before.logs ++ (pairsOf sources targets).map
          (fun pair => requestAddedEvent ctx.self (vaultCallPayload pair)) ∧
      CallSpec.Balances before.balances
        (executeVault callee sexternal ctx gateway inbox msgValue sources targets before).world.balances
        ctx.self inbox msgValue.val := by
  obtain ⟨hsender, hnonempty, hlen, feeData, satt, hs, hflen, hexact, -, -, -⟩ :=
    executeVault_success callee sexternal ctx gateway inbox msgValue sources targets before h
  have hbody := executeVault_success_body callee sexternal ctx gateway inbox msgValue sources
    targets before h
  rw [hbody] at h ⊢
  unfold addConsolidationRequestsVault at h ⊢
  rw [bind_ok (selfBalance ctx) _ before _ before [] rfl] at h ⊢
  have hne : sources.length ≠ 0 := by
    intro hz
    exact hnonempty (List.eq_nil_of_length_eq_zero hz)
  have hfit : sources.length * (Live.word (decode feeData)).val < Verity.Core.UINT256_MODULUS := by
    rw [hexact]
    exact msgValue.isLt
  rw [bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hsender])),
    bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hne])),
    bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hlen])),
    bind_ok _ _ before _ before [] (feeRead_ok sexternal ctx inbox before feeData satt hs hflen),
    bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hfit])),
    bind_ok _ _ before () before [] (require_ok _ _ before (by simp [hexact]))] at h ⊢
  rcases hloop : (addConsolidationRequestsLoop callee ctx inbox (Live.word (decode feeData))
      (pairsOf sources targets) before).outcome with fault | u
  ·
      rw [bind_error _ _ before fault _ _ (by rw [← hloop])] at h
      simp at h
  ·
      cases u
      obtain ⟨hlogs, hbalances⟩ :=
        loop_success_frame callee ctx inbox (Live.word (decode feeData))
          (pairsOf sources targets) before hlog hbal hun hloop
      rw [bind_ok _ _ before () _ _ (by rw [← hloop])] at h ⊢
      set after := (addConsolidationRequestsLoop callee ctx inbox (Live.word (decode feeData))
        (pairsOf sources targets) before).world with hafter
      rw [bind_ok (selfBalance ctx) _ after _ after [] rfl] at h ⊢
      by_cases hassert : after.balances ctx.self = before.balances ctx.self - msgValue.val
      · rw [require_ok _ _ after (by simp [hassert])]
        have hcount : (pairsOf sources targets).length = sources.length := by
          simp [pairsOf, List.length_zip, hlen]
        refine ⟨hlogs, ?_⟩
        rw [← hexact, ← hcount]
        exact hbalances
      · rw [require_fail _ _ after (by simp [hassert])] at h
        simp at h

/-! ## Gateway refund hop (`ConsolidationGateway.sol:295-307`)

```
function _refundFee(uint256 refund, address recipient) internal {
    if (refund > 0) {
        if (recipient == address(0)) { recipient = msg.sender; }
        (bool success, ) = recipient.call{value: refund}("");
        if (!success) { revert FeeRefundFailed(); }
    }
}
```
-/

/-- Line 298-300 on physical addresses; agrees with `resolveRecipient` on
their word values. -/
def resolveAddress (recipient sender : Live.Address) : Live.Address :=
  if recipient = 0 then sender else recipient

theorem resolveAddress_val (recipient sender : Live.Address) :
    (resolveAddress recipient sender).val = resolveRecipient recipient.val sender.val := by
  unfold resolveAddress resolveRecipient
  by_cases h : recipient = 0
  · subst h
    simp
  · have hv : recipient.val ≠ 0 := by
      intro hv
      exact h (Verity.Core.Address.ext hv)
    simp [h, hv]

/-- The refund CALL of line 302: recipient, value `refund`, empty payload. -/
def refundRequest (ctx : Context) (refund : Live.Word) (recipient : Live.Address) : Request :=
  ⟨ctx.self, resolveAddress recipient ctx.sender, refund, []⟩

/-- `_refundFee` in the physical world through the same low-level CALL
primitive. The recipient may be an EOA: low-level `.call` accepts a code-less
target after the value transfer (`refund_no_code_accepted`). -/
def refundFee (callee : External) (ctx : Context) (refund : Live.Word)
    (recipient : Live.Address) : Exec Unit := fun w =>
  if refund.val = 0 then ⟨.ok (), w, []⟩
  else
    let r := lowLevelCall callee ctx (resolveAddress recipient ctx.sender) [] refund w
    match r.outcome with
    | .ok _ => ⟨.ok (), r.world, r.attempts⟩
    | .error _ => ⟨.error (.reason "FeeRefundFailed"), r.world, r.attempts⟩

/-- Line 296: a zero remainder issues no CALL and changes nothing. -/
theorem refund_zero (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w : World) (h : refund.val = 0) :
    refundFee callee ctx refund recipient w = ⟨.ok (), w, []⟩ := by
  simp [refundFee, h]

/-- Every attempted refund call carries the resolved recipient, the exact
remainder as value, and an empty payload. -/
theorem refund_attempt_request (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w : World) (a : Attempt)
    (ha : a ∈ (refundFee callee ctx refund recipient w).attempts) :
    a.request = refundRequest ctx refund recipient := by
  by_cases hz : refund.val = 0
  · simp [refundFee, hz] at ha
  · rcases lowLevelCall_shape callee ctx (resolveAddress recipient ctx.sender) [] refund w with
      ⟨-, h⟩ | ⟨-, -, h⟩ | ⟨-, -, h⟩
    · simp [refundFee, hz, h] at ha
      simp [ha, refundRequest]
    · simp [refundFee, hz, h] at ha
      simp [ha, refundRequest]
    · rcases h with ⟨data, -, h⟩ | ⟨data, nested, -, h⟩ | ⟨data, after, -, h⟩ |
          ⟨data, after, nested, -, h⟩ <;>
        simp [refundFee, hz, h] at ha <;> simp [ha, refundRequest]

/-- Failed refund: `FeeRefundFailed`, and the world is restored. -/
theorem refund_error_restores (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w : World) (fault : Fault)
    (h : (refundFee callee ctx refund recipient w).outcome = .error fault) :
    fault = .reason "FeeRefundFailed" ∧ (refundFee callee ctx refund recipient w).world = w := by
  by_cases hz : refund.val = 0
  · simp [refundFee, hz] at h
  · rcases lowLevelCall_shape callee ctx (resolveAddress recipient ctx.sender) [] refund w with
      ⟨-, hs⟩ | ⟨-, -, hs⟩ | ⟨-, -, hs⟩
    · simp [refundFee, hz, hs] at h ⊢
      exact h.symm
    · simp [refundFee, hz, hs] at h
    · rcases hs with ⟨data, -, hs⟩ | ⟨data, nested, -, hs⟩ | ⟨data, after, -, hs⟩ |
          ⟨data, after, nested, -, hs⟩ <;>
        simp [refundFee, hz, hs] at h ⊢ <;> simp [h]

/-- Recipient rejects the plain value transfer (line 302-305). -/
theorem refund_rejected (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w : World) (data : Bytes) (hz : refund.val ≠ 0)
    (hc : (w.core.codeSize (resolveAddress recipient ctx.sender).val).val ≠ 0)
    (hb : refund.val ≤ w.balances ctx.self)
    (hr : callee (refundRequest ctx refund recipient)
      (transfer w ctx.self (resolveAddress recipient ctx.sender) refund.val) = .rejected data) :
    refundFee callee ctx refund recipient w =
      ⟨.error (.reason "FeeRefundFailed"), w,
        [⟨refundRequest ctx refund recipient, false, data, []⟩]⟩ := by
  unfold refundRequest at hr ⊢
  unfold refundFee lowLevelCall
  simp [hz, hc, Nat.not_lt.mpr hb, hr]

/-- Recipient accepts: the remainder left the gateway. -/
theorem refund_accepted (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w after : World) (data : Bytes) (hz : refund.val ≠ 0)
    (hc : (w.core.codeSize (resolveAddress recipient ctx.sender).val).val ≠ 0)
    (hb : refund.val ≤ w.balances ctx.self)
    (hr : callee (refundRequest ctx refund recipient)
      (transfer w ctx.self (resolveAddress recipient ctx.sender) refund.val) = .success data after) :
    refundFee callee ctx refund recipient w =
      ⟨.ok (), after, [⟨refundRequest ctx refund recipient, true, data, []⟩]⟩ := by
  unfold refundRequest at hr ⊢
  unfold refundFee lowLevelCall
  simp [hz, hc, Nat.not_lt.mpr hb, hr]

/-- EOA refund recipient: code-less, funded — the low-level `.call` accepts
with empty return data after the value transfer, so `_refundFee` succeeds.
This is the valid refund path the code-guarded primitive rejected. -/
theorem refund_no_code_accepted (callee : External) (ctx : Context) (recipient : Live.Address)
    (refund : Live.Word) (w : World) (hz : refund.val ≠ 0)
    (hc : (w.core.codeSize (resolveAddress recipient ctx.sender).val).val = 0)
    (hb : refund.val ≤ w.balances ctx.self) :
    refundFee callee ctx refund recipient w =
      ⟨.ok (), transfer w ctx.self (resolveAddress recipient ctx.sender) refund.val,
        [⟨refundRequest ctx refund recipient, true, [], []⟩]⟩ := by
  unfold refundFee lowLevelCall refundRequest
  simp [hz, hc, Nat.not_lt.mpr hb]

/-- Gateway value split (`ConsolidationGateway.sol:212-213, 220, 302`): the
vault hop value `totalFee` and the refund CALL value reconstruct
`msg.value`. Reuses `checkFee_additive`. -/
theorem refund_value_split (ctx : Context) (recipient : Live.Address)
    (msgValue totalFee : Live.Word) (hle : totalFee.val ≤ msgValue.val) :
    totalFee.val +
      (refundRequest ctx (audit.trio.consolidation.word (msgValue.val - totalFee.val)) recipient).value.val =
        msgValue.val :=
  checkFee_additive msgValue totalFee hle

/-- The Live refund request is the `RefundHop` of the reviewed gateway
model: same resolved recipient word, same remainder. -/
theorem refund_request_is_hop (ctx : Context) (recipient : Live.Address) (refund : Live.Word) :
    (refundRequest ctx refund recipient).target.val =
        (RefundHop.mk (resolveRecipient recipient.val ctx.sender.val) refund).recipient ∧
      (refundRequest ctx refund recipient).value =
        (RefundHop.mk (resolveRecipient recipient.val ctx.sender.val) refund).value :=
  ⟨resolveAddress_val recipient ctx.sender, rfl⟩

end audit.trio.consolidation
