import LidoSRv3.Audit.Source.TrioReserve1.CallDataFlow
import LidoSRv3.Audit.Source.TrioReserve1.ReportCalls
import LidoSRv3.Audit.Source.TrioReserve1.Lookup

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportLookup
open Live

def Describes (external : External) (ctx : Context) (locator : Address) (selector : Nat) (before : World) :
    Except Fault Address → World → List Attempt → Prop :=
  LookupSpec.Returns .empty List.length Lookup.decodedAddress
    (CallDataFlow.Describes external ctx locator (encode 4 selector) (word 0)) before

theorem getter_observations (external : External) (ctx : Context) (locator : Address) (selector : Nat) :
    CallDataFlow.Describes external ctx locator (encode 4 selector) (word 0) =
      (fun w outcome after trace => call external ctx locator selector (word 0) w = ⟨outcome, after, trace⟩) := by
  funext w outcome after trace
  apply propext
  simpa only [CallData.selector_call] using
    CallDataFlow.corresponds external ctx locator (encode 4 selector) (word 0) w after outcome trace

theorem of_spec (external : External) (ctx : Context) (locator : Address) (selector : Nat)
    (before after : World) (outcome : Except Fault Address) (trace : List Attempt)
    (h : Describes external ctx locator selector before outcome after trace) :
    Report.lookup external ctx locator selector before = ⟨outcome, after, trace⟩ := by
  unfold Describes at h
  rw [getter_observations] at h
  cases h <;> simp_all [Report.lookup, decodeWord, Lookup.decodedAddress,
    bind, bindExec, require, pure, pureExec, fail, Nat.not_le.mpr]

theorem exists_spec (external : External) (ctx : Context) (locator : Address) (selector : Nat) (before : World) :
    ∃ outcome after trace, Describes external ctx locator selector before outcome after trace := by
  unfold Describes
  rw [getter_observations]
  generalize hc : call external ctx locator selector (word 0) before = called
  rcases called with ⟨outcome, after, trace⟩
  cases outcome with
  | error fault => exact ⟨_, _, _, .call_error hc⟩
  | ok data =>
    by_cases hn : 32 ≤ data.length
    · exact ⟨_, _, _, .decoded hc hn⟩
    · exact ⟨_, _, _, .malformed hc (by omega)⟩

theorem corresponds (external : External) (ctx : Context) (locator : Address) (selector : Nat)
    (before after : World) (outcome : Except Fault Address) (trace : List Attempt) :
    Describes external ctx locator selector before outcome after trace ↔
      Report.lookup external ctx locator selector before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact of_spec external ctx locator selector before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := exists_spec external ctx locator selector before
    have he := of_spec external ctx locator selector before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

end LidoSRv3.Audit.Source.TrioReserve1.ReportLookup
