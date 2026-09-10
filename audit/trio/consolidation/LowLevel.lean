import LidoSRv3.Audit.Source.TrioReserve1.StaticCall

/-!
# Low-level CALL and STATICCALL (no target-code guard)

Solidity's low-level `<address>.call{value: v}(payload)` and
`<address>.staticcall(payload)` issue the EVM CALL/STATICCALL opcode directly.
Unlike a Solidity high-level (interface) call there is no `extcodesize`
precheck: a code-less target (EOA or not-yet-deployed address) *accepts* with
empty return data, after the value transfer for CALL. Only an unfunded caller
fails before the callee runs.

Pinned usages at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `WithdrawalVaultEIP7685.sol:115`
  `(bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);`
* `WithdrawalVaultEIP7685.sol:84`
  `(bool success, bytes memory feeData) = contractAddress.staticcall("");`
* `ConsolidationGateway.sol:302`
  `(bool success, ) = recipient.call{value: refund}("");` — the recipient may
  legitimately be an EOA, so the code-less acceptance arm is load-bearing.

The existing `CallData.invoke` / `StaticCall.call` model the *high-level*
typed call discipline (target-code guard). Those are untouched; this file adds
the low-level opcode rule for the consolidation lane.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Low-level `target.call{value: value}(payload)`. No target-code guard: a
code-less target accepts with empty return data after the value transfer. An
unfunded caller records a failed attempt without running any callee. A coded
target runs the supplied external interpreter on the credited world; rejection
rolls the transfer and all callee effects back. -/
def lowLevelCall (external : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Word) : Exec Bytes := fun w =>
  let req : Request := ⟨ctx.self, target, value, payload⟩
  if w.balances ctx.self < value.val then
    ⟨.error (.bubbled []), w, [⟨req, false, [], []⟩]⟩
  else if (w.core.codeSize target.val).val = 0 then
    ⟨.ok [], transfer w ctx.self target value.val, [⟨req, true, [], []⟩]⟩
  else
    match external req (transfer w ctx.self target value.val) with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨req, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨req, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok data, after, [⟨req, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested => ⟨.error (.bubbled data), w, [⟨req, false, data, nested⟩]⟩

/-- Low-level `target.staticcall(payload)` (e.g. `_getFeeFromContract`'s
`staticcall("")`). No target-code guard: a code-less target answers success
with empty return data, and the caller-side returndata checks decide.
STATICCALL never moves value or state; the incoming world is observed, not
modified. -/
def lowLevelStaticCall (external : StaticCall.External) (caller target : Address)
    (payload : Bytes) (w : World) : StaticCall.Result :=
  let req : Request := ⟨caller, target, word 0, payload⟩
  if (w.core.codeSize target.val).val = 0 then ⟨.ok [], [⟨req, true, true, [], 1⟩]⟩
  else match external req w with
    | .success data => ⟨.ok data, [⟨req, true, true, data, 1⟩]⟩
    | .rejected data => ⟨.error data, [⟨req, true, false, data, 1⟩]⟩
    | .forbiddenStateChange => ⟨.error [], [⟨req, true, false, [], 1⟩]⟩

/-- Exhaustive branch shape of the low-level CALL on any world. -/
theorem lowLevelCall_shape (external : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Word) (w : World) :
    (w.balances ctx.self < value.val ∧
      lowLevelCall external ctx target payload value w =
        ⟨.error (.bubbled []), w, [⟨⟨ctx.self, target, value, payload⟩, false, [], []⟩]⟩) ∨
    (value.val ≤ w.balances ctx.self ∧ (w.core.codeSize target.val).val = 0 ∧
      lowLevelCall external ctx target payload value w =
        ⟨.ok [], transfer w ctx.self target value.val,
          [⟨⟨ctx.self, target, value, payload⟩, true, [], []⟩]⟩) ∨
    (value.val ≤ w.balances ctx.self ∧ (w.core.codeSize target.val).val ≠ 0 ∧
      ((∃ data, external ⟨ctx.self, target, value, payload⟩
          (transfer w ctx.self target value.val) = .rejected data ∧
        lowLevelCall external ctx target payload value w =
          ⟨.error (.bubbled data), w, [⟨⟨ctx.self, target, value, payload⟩, false, data, []⟩]⟩) ∨
      (∃ data nested, external ⟨ctx.self, target, value, payload⟩
          (transfer w ctx.self target value.val) = .rejectedWithTrace data nested ∧
        lowLevelCall external ctx target payload value w =
          ⟨.error (.bubbled data), w,
            [⟨⟨ctx.self, target, value, payload⟩, false, data, nested⟩]⟩) ∨
      (∃ data after, external ⟨ctx.self, target, value, payload⟩
          (transfer w ctx.self target value.val) = .success data after ∧
        lowLevelCall external ctx target payload value w =
          ⟨.ok data, after, [⟨⟨ctx.self, target, value, payload⟩, true, data, []⟩]⟩) ∨
      (∃ data after nested, external ⟨ctx.self, target, value, payload⟩
          (transfer w ctx.self target value.val) = .successWithTrace data after nested ∧
        lowLevelCall external ctx target payload value w =
          ⟨.ok data, after, [⟨⟨ctx.self, target, value, payload⟩, true, data, nested⟩]⟩))) := by
  unfold lowLevelCall
  by_cases hb : w.balances ctx.self < value.val
  · exact Or.inl ⟨hb, by simp [hb]⟩
  · have hf : value.val ≤ w.balances ctx.self := Nat.not_lt.mp hb
    by_cases hc : (w.core.codeSize target.val).val = 0
    · exact Or.inr (Or.inl ⟨hf, hc, by simp [hb, hc]⟩)
    · refine Or.inr (Or.inr ⟨hf, hc, ?_⟩)
      cases hr : external ⟨ctx.self, target, value, payload⟩
        (transfer w ctx.self target value.val) with
      | rejected data => exact Or.inl ⟨data, rfl, by simp [hb, hc, hr]⟩
      | rejectedWithTrace data nested =>
          exact Or.inr (Or.inl ⟨data, nested, rfl, by simp [hb, hc, hr]⟩)
      | success data after =>
          exact Or.inr (Or.inr (Or.inl ⟨data, after, rfl, by simp [hb, hc, hr]⟩))
      | successWithTrace data after nested =>
          exact Or.inr (Or.inr (Or.inr ⟨data, after, nested, rfl, by simp [hb, hc, hr]⟩))

/-- A successful low-level CALL needs a funded caller; the target needs no
code (EOA acceptance arm). -/
theorem lowLevelCall_success_funded (external : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Word) (w : World) (data : Bytes) (after : World)
    (attempts : List Attempt)
    (h : lowLevelCall external ctx target payload value w = ⟨.ok data, after, attempts⟩) :
    value.val ≤ w.balances ctx.self := by
  by_cases hb : w.balances ctx.self < value.val
  · unfold lowLevelCall at h
    simp [hb] at h
  · exact Nat.not_lt.mp hb

/-- Exhaustive branch shape of the low-level STATICCALL. -/
theorem lowLevelStaticCall_shape (external : StaticCall.External) (caller target : Address)
    (payload : Bytes) (w : World) :
    ((w.core.codeSize target.val).val = 0 ∧
      lowLevelStaticCall external caller target payload w =
        ⟨.ok [], [⟨⟨caller, target, word 0, payload⟩, true, true, [], 1⟩]⟩) ∨
    ((w.core.codeSize target.val).val ≠ 0 ∧
      ((∃ data, external ⟨caller, target, word 0, payload⟩ w = .success data ∧
        lowLevelStaticCall external caller target payload w =
          ⟨.ok data, [⟨⟨caller, target, word 0, payload⟩, true, true, data, 1⟩]⟩) ∨
      (∃ data, external ⟨caller, target, word 0, payload⟩ w = .rejected data ∧
        lowLevelStaticCall external caller target payload w =
          ⟨.error data, [⟨⟨caller, target, word 0, payload⟩, true, false, data, 1⟩]⟩) ∨
      (external ⟨caller, target, word 0, payload⟩ w = .forbiddenStateChange ∧
        lowLevelStaticCall external caller target payload w =
          ⟨.error [], [⟨⟨caller, target, word 0, payload⟩, true, false, [], 1⟩]⟩))) := by
  unfold lowLevelStaticCall
  by_cases hc : (w.core.codeSize target.val).val = 0
  · exact Or.inl ⟨hc, by simp [hc]⟩
  · refine Or.inr ⟨hc, ?_⟩
    cases hr : external ⟨caller, target, word 0, payload⟩ w with
    | success data => exact Or.inl ⟨data, rfl, by simp [hc, hr]⟩
    | rejected data => exact Or.inr (Or.inl ⟨data, rfl, by simp [hc, hr]⟩)
    | forbiddenStateChange => exact Or.inr (Or.inr ⟨rfl, by simp [hc, hr]⟩)

end audit.trio.consolidation
