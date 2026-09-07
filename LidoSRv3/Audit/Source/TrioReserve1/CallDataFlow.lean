import LidoSRv3.Audit.Source.TrioReserve1.CallFlow
import LidoSRv3.Audit.Source.TrioReserve1.CallData

namespace LidoSRv3.Audit.Source.TrioReserve1.CallDataFlow
open Live CallFlow

/-- Independent CALL rules for complete ABI payloads, retaining supplied bytes
and traced/untraced raw primitive replies. No selector-only restriction. -/
def Describes (external : External) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before : World) : Except Fault Bytes → World → List Attempt → Prop :=
  let req : Request := ⟨ctx.self, target, value, payload⟩
  let credited := transfer before ctx.self target value.val
  CallSpec.Invokes .empty Fault.bubbled [] (fun accepted data nested => ⟨req, accepted, data, nested⟩)
    (before.core.codeSize target.val).val (before.balances ctx.self) value.val before credited
    (fun w => ReplyDescribes (external req w) w)

theorem of_spec (external : External) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt)
    (h : Describes external ctx target payload value before outcome after trace) :
    CallData.invoke external ctx target payload value before = ⟨outcome, after, trace⟩ := by
  cases h with
  | no_code hc => simp [CallData.invoke, hc]
  | unfunded hc hb => simp [CallData.invoke, hc, hb]
  | accepted hc hb hr =>
    unfold ReplyDescribes at hr
    split at hr <;> simp_all [CallData.invoke, Nat.not_lt.mpr]
  | rejected hc hb hr =>
    unfold ReplyDescribes at hr
    split at hr <;> simp_all [CallData.invoke, Nat.not_lt.mpr]

theorem exists_spec (external : External) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before : World) : ∃ outcome after trace, Describes external ctx target payload value before outcome after trace := by
  by_cases hc : (before.core.codeSize target.val).val = 0
  · exact ⟨_, _, _, .no_code hc⟩
  · by_cases hb : before.balances ctx.self < value.val
    · exact ⟨_, _, _, .unfunded hc hb⟩
    · have hf : value.val ≤ before.balances ctx.self := by omega
      cases hr : external ⟨ctx.self, target, value, payload⟩ (transfer before ctx.self target value.val) with
      | success bytes w => exact ⟨_, _, _, .accepted hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | successWithTrace bytes w nested => exact ⟨_, _, _, .accepted hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | rejected bytes => exact ⟨_, _, _, .rejected hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | rejectedWithTrace bytes nested => exact ⟨_, _, _, .rejected hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩

theorem to_spec (external : External) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt)
    (h : CallData.invoke external ctx target payload value before = ⟨outcome, after, trace⟩) :
    Describes external ctx target payload value before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx target payload value before
  have he := of_spec external ctx target payload value before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt) :
    Describes external ctx target payload value before outcome after trace ↔
      CallData.invoke external ctx target payload value before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx target payload value before after outcome trace,
   to_spec external ctx target payload value before after outcome trace⟩


end LidoSRv3.Audit.Source.TrioReserve1.CallDataFlow
