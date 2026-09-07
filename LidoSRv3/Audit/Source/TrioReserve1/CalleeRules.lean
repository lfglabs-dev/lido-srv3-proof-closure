import LidoSRv3.Audit.Source.TrioReserve1.EntryRules
import LidoSRv3.Audit.Source.TrioReserve1.ReportRules

namespace LidoSRv3.Audit.Source.TrioReserve1.CalleeRules
open Live

abbrev Replies := Request → World → Reply → Prop

/-- Independent CALL rules consume a callee reply relation. A reply witness is
required only on the funded, code-present paths that actually invoke the callee. -/
def Calls (replies : Replies) (ctx : Context) (target : Address) (payload : Bytes) (value : Word)
    (before : World) : Except Fault Bytes → World → List Attempt → Prop :=
  let req : Request := ⟨ctx.self, target, value, payload⟩
  let credited := transfer before ctx.self target value.val
  CallSpec.Invokes .empty Fault.bubbled [] (fun accepted data nested => ⟨req, accepted, data, nested⟩)
    (before.core.codeSize target.val).val (before.balances ctx.self) value.val before credited
    (fun w accepted data after children => ∃ reply,
      replies req w reply ∧ CallFlow.ReplyDescribes reply w accepted data after children)

theorem calls_observations (replies : Replies) (external : External)
    (hr : ∀ req w reply, replies req w reply ↔ external req w = reply)
    (ctx : Context) (target : Address) (payload : Bytes) (value : Word) :
    Calls replies ctx target payload value = CallDataFlow.Describes external ctx target payload value := by
  have he (req : Request) :
      (fun w accepted data after children => ∃ reply,
        replies req w reply ∧ CallFlow.ReplyDescribes reply w accepted data after children) =
      (fun w => CallFlow.ReplyDescribes (external req w) w) := by
    funext w accepted data after children
    apply propext
    constructor
    · rintro ⟨reply, hs, hd⟩
      have eq := (hr req w reply).mp hs
      rw [← eq] at hd
      exact hd
    · intro hd
      exact ⟨_, (hr req w _).mpr rfl, hd⟩
  unfold Calls CallDataFlow.Describes
  simp only [he]

theorem selector_observations (replies : Replies) (external : External)
    (hr : ∀ req w reply, replies req w reply ↔ external req w = reply)
    (ctx : Context) (target : Address) (selector : Nat) (value : Word) :
    Calls replies ctx target (encode 4 selector) value = CallFlow.Describes external ctx target selector value :=
  calls_observations replies external hr ctx target (encode 4 selector) value

end LidoSRv3.Audit.Source.TrioReserve1.CalleeRules
