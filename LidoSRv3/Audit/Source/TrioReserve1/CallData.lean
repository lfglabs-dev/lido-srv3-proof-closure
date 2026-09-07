import LidoSRv3.Audit.Source.TrioReserve1.Live

namespace LidoSRv3.Audit.Source.TrioReserve1.CallData
open Live

/-- Argument-complete high-level CALL. Uses the same code/funds/provisional
transfer/reply rules as Live.call, retaining the supplied ABI bytes verbatim. -/
def invoke (external : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Word := word 0) : Exec Bytes := fun w =>
  let req : Request := ⟨ctx.self, target, value, payload⟩
  if (w.core.codeSize target.val).val = 0 then ⟨.error .empty, w, []⟩
  else if w.balances ctx.self < value.val then
    ⟨.error (.bubbled []), w, [⟨req, false, [], []⟩]⟩
  else
    match external req (transfer w ctx.self target value.val) with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨req, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨req, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok data, after, [⟨req, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested => ⟨.error (.bubbled data), w, [⟨req, false, data, nested⟩]⟩


theorem selector_call (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) :
    invoke external ctx target (encode 4 selector) value = Live.call external ctx target selector value := rfl

end LidoSRv3.Audit.Source.TrioReserve1.CallData
