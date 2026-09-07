import LidoSRv3.Audit.Source.TrioReserve1.CallSpec
import LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow

namespace LidoSRv3.Audit.Source.TrioReserve1.CallFlow
open Live

/-- Relational interpretation of the explicit primitive reply, normalizing the
two trace encodings. Rejected replies expose no committed callee world. -/
def ReplyDescribes (reply : Reply) (credited : World) (accepted : Bool) (data : Bytes)
    (after : World) (children : List NestedAttempt) : Prop :=
  match reply with
  | .success bytes w => accepted = true ∧ data = bytes ∧ after = w ∧ children = []
  | .successWithTrace bytes w nested => accepted = true ∧ data = bytes ∧ after = w ∧ children = nested
  | .rejected bytes => accepted = false ∧ data = bytes ∧ after = credited ∧ children = []
  | .rejectedWithTrace bytes nested => accepted = false ∧ data = bytes ∧ after = credited ∧ children = nested

theorem transfer_balances (before : World) (sender recipient : Address) (amount : Nat)
    (hb : amount ≤ before.balances sender) :
    CallSpec.Balances before.balances (transfer before sender recipient amount).balances sender recipient amount := by
  intro account
  by_cases hs : account = sender <;> by_cases hr : account = recipient <;>
    simp_all [transfer] <;> omega

theorem transfer_frame (before : World) (sender recipient : Address) (amount : Nat) :
    (transfer before sender recipient amount).core = before.core ∧
      (transfer before sender recipient amount).logs = before.logs := ⟨rfl, rfl⟩

def Describes (external : External) (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before : World) : Except Fault Bytes → World → List Attempt → Prop :=
  let req : Request := ⟨ctx.self, target, value, encode 4 selector⟩
  let credited := transfer before ctx.self target value.val
  CallSpec.Invokes .empty Fault.bubbled [] (fun accepted data nested => ⟨req, accepted, data, nested⟩)
    (before.core.codeSize target.val).val (before.balances ctx.self) value.val before credited
    (fun w => ReplyDescribes (external req w) w)

theorem of_spec (external : External) (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt)
    (h : Describes external ctx target selector value before outcome after trace) :
    call external ctx target selector value before = ⟨outcome, after, trace⟩ := by
  cases h with
  | no_code hc => simp [call, hc]
  | unfunded hc hb => simp [call, hc, hb]
  | accepted hc hb hr =>
    unfold ReplyDescribes at hr
    split at hr <;> simp_all [call, Nat.not_lt.mpr]
  | rejected hc hb hr =>
    unfold ReplyDescribes at hr
    split at hr <;> simp_all [call, Nat.not_lt.mpr]

theorem exists_spec (external : External) (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before : World) : ∃ outcome after trace, Describes external ctx target selector value before outcome after trace := by
  by_cases hc : (before.core.codeSize target.val).val = 0
  · exact ⟨_, _, _, .no_code hc⟩
  · by_cases hb : before.balances ctx.self < value.val
    · exact ⟨_, _, _, .unfunded hc hb⟩
    · have hf : value.val ≤ before.balances ctx.self := by omega
      cases hr : external ⟨ctx.self, target, value, encode 4 selector⟩ (transfer before ctx.self target value.val) with
      | success bytes w => exact ⟨_, _, _, .accepted hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | successWithTrace bytes w nested => exact ⟨_, _, _, .accepted hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | rejected bytes => exact ⟨_, _, _, .rejected hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩
      | rejectedWithTrace bytes nested => exact ⟨_, _, _, .rejected hc hf (by rw [hr]; exact ⟨rfl, rfl, rfl, rfl⟩)⟩

theorem to_spec (external : External) (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt)
    (h : call external ctx target selector value before = ⟨outcome, after, trace⟩) :
    Describes external ctx target selector value before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx target selector value before
  have he := of_spec external ctx target selector value before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before after : World) (outcome : Except Fault Bytes) (trace : List Attempt) :
    Describes external ctx target selector value before outcome after trace ↔
      call external ctx target selector value before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx target selector value before after outcome trace,
   to_spec external ctx target selector value before after outcome trace⟩

end LidoSRv3.Audit.Source.TrioReserve1.CallFlow
