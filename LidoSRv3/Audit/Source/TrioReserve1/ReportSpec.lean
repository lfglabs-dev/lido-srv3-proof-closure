namespace LidoSRv3.Audit.Source.TrioReserve1.ReportSpec

/-- Independent report transaction order. Stage observations are needed only
when reached. Every failure restores the original world and retains all visited
attempts in order; the saved locator is bound by the physical adapter. -/
inductive Executes {State Address Fault Event : Type}
    (stopped unauthorized : Fault) (active : Prop) (sender : Address)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (rewards withdrawals finalize accounting : State → Except Fault Unit → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | stopped (h : ¬active) : Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error stopped) before []
  | lookup_error {fault w trace} (ha : active) (h : lookup before (.error fault) w trace) :
      Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error fault) before trace
  | unauthorized {address w trace} (ha : active) (h : lookup before (.ok address) w trace)
      (hn : sender ≠ address) : Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error unauthorized) before trace
  | rewards_error {address w0 w1 t0 t1 fault} (ha : active) (hl : lookup before (.ok address) w0 t0) (he : sender = address)
      (hf : rewards w0 (.error fault) w1 t1) :
      Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error fault) before (t0 ++ t1)
  | withdrawals_error {address w0 w1 w2 t0 t1 t2 fault} (ha : active) (hl : lookup before (.ok address) w0 t0) (he : sender = address)
      (h0 : rewards w0 (.ok ()) w1 t1)
      (hf : withdrawals w1 (.error fault) w2 t2) :
      Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error fault) before (t0 ++ t1 ++ t2)
  | finalize_error {address w0 w1 w2 w3 t0 t1 t2 t3 fault} (ha : active) (hl : lookup before (.ok address) w0 t0) (he : sender = address)
      (h0 : rewards w0 (.ok ()) w1 t1)
      (h1 : withdrawals w1 (.ok ()) w2 t2)
      (hf : finalize w2 (.error fault) w3 t3) :
      Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error fault) before (t0 ++ t1 ++ t2 ++ t3)
  | accounting_error {address w0 w1 w2 w3 w4 t0 t1 t2 t3 t4 fault} (ha : active) (hl : lookup before (.ok address) w0 t0) (he : sender = address)
      (h0 : rewards w0 (.ok ()) w1 t1)
      (h1 : withdrawals w1 (.ok ()) w2 t2)
      (h2 : finalize w2 (.ok ()) w3 t3)
      (hf : accounting w3 (.error fault) w4 t4) :
      Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.error fault) before (t0 ++ t1 ++ t2 ++ t3 ++ t4)
  | finished {address w0 w1 w2 w3 after t0 t1 t2 t3 t4}
      (ha : active) (hl : lookup before (.ok address) w0 t0) (he : sender = address)
      (h0 : rewards w0 (.ok ()) w1 t1)
      (h1 : withdrawals w1 (.ok ()) w2 t2)
      (h2 : finalize w2 (.ok ()) w3 t3)
      (h3 : accounting w3 (.ok ()) after t4)
      : Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting before (.ok ()) after (t0 ++ t1 ++ t2 ++ t3 ++ t4)

section
variable {State Address Fault Event : Type} {stopped unauthorized : Fault} {active : Prop} {sender : Address}
  {lookup : State → Except Fault Address → State → List Event → Prop}
  {rewards withdrawals finalize accounting : State → Except Fault Unit → State → List Event → Prop}
  {before after : State} {trace : List Event}

theorem failure_restores {fault : Fault}
    (h : Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting
      before (.error fault) after trace) : after = before := by
  cases h <;> rfl

theorem success_active
    (h : Executes stopped unauthorized active sender lookup rewards withdrawals finalize accounting
      before (.ok ()) after trace) : active := by
  cases h with
  | finished ha _ _ _ _ _ _ => exact ha

end
end LidoSRv3.Audit.Source.TrioReserve1.ReportSpec
