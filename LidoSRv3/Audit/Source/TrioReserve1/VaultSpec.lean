import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.VaultSpec

/-- The greatest amount bounded by both the observed balance and caller limit. -/
def Capped (balance maximum amount : Nat) : Prop :=
  amount ≤ balance ∧ amount ≤ maximum ∧ (amount = balance ∨ amount = maximum)

theorem capped_iff (balance maximum amount : Nat) :
    Capped balance maximum amount ↔ amount = min balance maximum := by
  unfold Capped
  omega

/-- Independent reward entry rules. Rejection precedes balance capping; zero
returns without a callback. Callback outcomes retain their stage worlds. -/
inductive Rewards {State Fault Payload Event Value : Type}
    (denied : Fault) (encode : Nat → Value) (authorized : Prop)
    (balance maximum : Nat)
    (callback : Nat → State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Value → State → List Event → Prop where
  | denied (ha : ¬ authorized) : Rewards denied encode authorized balance maximum callback before (.error denied) before []
  | zero (ha : authorized) (hc : Capped balance maximum 0) :
      Rewards denied encode authorized balance maximum callback before (.ok (encode 0)) before []
  | failed {amount fault after trace} (ha : authorized) (hc : Capped balance maximum amount)
      (hn : 0 < amount) (hcall : callback amount before (.error fault) after trace) :
      Rewards denied encode authorized balance maximum callback before (.error fault) after trace
  | paid {amount data after trace} (ha : authorized) (hc : Capped balance maximum amount)
      (hn : 0 < amount) (hcall : callback amount before (.ok data) after trace) :
      Rewards denied encode authorized balance maximum callback before (.ok (encode amount)) after trace

/-- Independent withdrawal entry rules, with exact ordered guard failures. -/
inductive Withdrawals {State Fault Payload Event : Type}
    (denied zero insufficient : Fault) (authorized : Prop) (balance amount : Nat)
    (callback : State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | denied (ha : ¬ authorized) : Withdrawals denied zero insufficient authorized balance amount callback before (.error denied) before []
  | zero (ha : authorized) (hz : amount = 0) :
      Withdrawals denied zero insufficient authorized balance amount callback before (.error zero) before []
  | insufficient (ha : authorized) (hn : amount ≠ 0) (hb : balance < amount) :
      Withdrawals denied zero insufficient authorized balance amount callback before (.error insufficient) before []
  | failed {fault after trace} (ha : authorized) (hn : amount ≠ 0) (hb : amount ≤ balance)
      (hcall : callback before (.error fault) after trace) :
      Withdrawals denied zero insufficient authorized balance amount callback before (.error fault) after trace
  | paid {data after trace} (ha : authorized) (hn : amount ≠ 0) (hb : amount ≤ balance)
      (hcall : callback before (.ok data) after trace) :
      Withdrawals denied zero insufficient authorized balance amount callback before (.ok ()) after trace

/-- Transaction boundary: successful stage worlds commit, while failures restore
all incoming state and retain attempted interactions. -/
inductive Root {State Fault Value Event : Type}
    (stage : State → Except Fault Value → State → List Event → Prop)
    (before : State) : Except Fault Value → State → List Event → Prop where
  | committed {value after trace} (hs : stage before (.ok value) after trace) :
      Root stage before (.ok value) after trace
  | reverted {fault intermediate trace} (hs : stage before (.error fault) intermediate trace) :
      Root stage before (.error fault) before trace

theorem root_failure_restores {State Fault Value Event : Type}
    {stage : State → Except Fault Value → State → List Event → Prop}
    {before after : State} {fault : Fault} {trace : List Event}
    (h : Root stage before (.error fault) after trace) : after = before := by
  cases h
  rfl

end LidoSRv3.Audit.Source.TrioReserve1.VaultSpec
