import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportAccountingSpec

inductive Outcome where
  | rewards_overflow
  | withdrawals_overflow
  | underflow
  | value (post : Nat)

/-- Independent ordered arithmetic rules. The buffer is the observation after
all external calls; no cap, cache or successful-execution premise is introduced. -/
inductive Computes (limit buffer rewards withdrawals locked : Nat) : Outcome → Prop where
  | rewards_overflow (h : limit ≤ buffer + rewards) :
      Computes limit buffer rewards withdrawals locked .rewards_overflow
  | withdrawals_overflow (hr : buffer + rewards < limit)
      (hw : limit ≤ buffer + rewards + withdrawals) :
      Computes limit buffer rewards withdrawals locked .withdrawals_overflow
  | underflow (hr : buffer + rewards < limit) (hw : buffer + rewards + withdrawals < limit)
      (hl : buffer + rewards + withdrawals < locked) :
      Computes limit buffer rewards withdrawals locked .underflow
  | value (hr : buffer + rewards < limit) (hw : buffer + rewards + withdrawals < limit)
      (hl : locked ≤ buffer + rewards + withdrawals) :
      Computes limit buffer rewards withdrawals locked (.value (buffer + rewards + withdrawals - locked))

theorem total (limit buffer rewards withdrawals locked : Nat) :
    ∃ outcome, Computes limit buffer rewards withdrawals locked outcome := by
  by_cases hr : buffer + rewards < limit
  · by_cases hw : buffer + rewards + withdrawals < limit
    · by_cases hl : locked ≤ buffer + rewards + withdrawals
      · exact ⟨_, .value hr hw hl⟩
      · exact ⟨_, .underflow hr hw (by omega)⟩
    · exact ⟨_, .withdrawals_overflow hr (by omega)⟩
  · exact ⟨_, .rewards_overflow (by omega)⟩

theorem unique (limit buffer rewards withdrawals locked : Nat) (a b : Outcome)
    (ha : Computes limit buffer rewards withdrawals locked a)
    (hb : Computes limit buffer rewards withdrawals locked b) : a = b := by
  cases ha <;> cases hb <;> first | rfl | omega

theorem success_bound (limit buffer rewards withdrawals locked post : Nat)
    (h : Computes limit buffer rewards withdrawals locked (.value post)) : post < limit := by
  cases h
  omega

end LidoSRv3.Audit.Source.TrioReserve1.ReportAccountingSpec
