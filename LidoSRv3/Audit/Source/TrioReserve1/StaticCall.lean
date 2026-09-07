import LidoSRv3.Audit.Source.TrioReserve1.Live

namespace LidoSRv3.Audit.Source.TrioReserve1.StaticCall
open Live

/-- Read-only external semantics expose no writable world. A forbidden state
operation is a distinct failure, not a successful reply with effects erased.
Deployed-source interpretation and EVM primitive correctness remain explicit.
-/
inductive Reply where
  | success (data : Bytes)
  | rejected (data : Bytes)
  | forbiddenStateChange

abbrev External := Request → World → Reply

structure Result where
  outcome : Except Bytes Bytes
  attempts : List NestedAttempt

/-- Solidity 0.8.9 typed STATICCALL, including its target-code guard. -/
def call (external : External) (caller target : Address) (selector : Nat) (w : World) : Result :=
  let req : Request := ⟨caller, target, word 0, encode 4 selector⟩
  if (w.core.codeSize target.val).val = 0 then ⟨.error [], []⟩
  else match external req w with
    | .success data => ⟨.ok data, [⟨req, true, true, data, 1⟩]⟩
    | .rejected data => ⟨.error data, [⟨req, true, false, data, 1⟩]⟩
    | .forbiddenStateChange => ⟨.error [], [⟨req, true, false, [], 1⟩]⟩

theorem state_change_rejected (external : External) (caller target : Address)
    (selector : Nat) (w : World)
    (h : external ⟨caller, target, word 0, encode 4 selector⟩ w = .forbiddenStateChange) :
    (call external caller target selector w).outcome = .error [] := by
  by_cases hc : (w.core.codeSize target.val).val = 0 <;> simp [call, h, hc]

end LidoSRv3.Audit.Source.TrioReserve1.StaticCall
