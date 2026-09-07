namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalSpec

/-- Independent ordered withdrawal transaction rules. Stage relations supply
status, router lookup, spending and seed/receiver behavior. Unvisited stages need
no derivation. Every error restores the original world but retains ordered calls. -/
inductive Executes {State Address Fault Event : Type}
    (cannotDeposit unauthorized zeroAmount : Fault) (sender : Address) (nonzero : Prop)
    (status : State → Except Fault Bool → State → List Event → Prop)
    (router : State → Except Fault Address → State → List Event → Prop)
    (spend : State → Except Fault Unit → State → List Event → Prop)
    (tail : Address → State → Except Fault Unit → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | status_error {fault w s} (hs : status before (.error fault) w s) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error fault) before s
  | status_denied {w s} (hs : status before (.ok false) w s) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error cannotDeposit) before s
  | router_error {w v s r fault} (hs : status before (.ok true) w s) (hr : router w (.error fault) v r) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error fault) before (s ++ r)
  | unauthorized {w v s r target} (hs : status before (.ok true) w s) (hr : router w (.ok target) v r)
      (ha : sender ≠ target) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error unauthorized) before (s ++ r)
  | zero {w v s r target} (hs : status before (.ok true) w s) (hr : router w (.ok target) v r)
      (ha : sender = target) (hz : ¬nonzero) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error zeroAmount) before (s ++ r)
  | spend_error {w v u s r p target fault} (hs : status before (.ok true) w s) (hr : router w (.ok target) v r)
      (ha : sender = target) (hn : nonzero) (hp : spend v (.error fault) u p) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error fault) before (s ++ r ++ p)
  | finished {w v u after s r p t target} (hs : status before (.ok true) w s) (hr : router w (.ok target) v r)
      (ha : sender = target) (hn : nonzero) (hp : spend v (.ok ()) u p) (ht : tail target u (.ok ()) after t) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.ok ()) after (s ++ r ++ p ++ t)
  | tail_error {w v u after s r p t target fault} (hs : status before (.ok true) w s) (hr : router w (.ok target) v r)
      (ha : sender = target) (hn : nonzero) (hp : spend v (.ok ()) u p) (ht : tail target u (.error fault) after t) :
      Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail before (.error fault) before (s ++ r ++ p ++ t)

section
variable {State Address Fault Event : Type}
  {cannotDeposit unauthorized zeroAmount : Fault} {sender : Address} {nonzero : Prop}
  {status : State → Except Fault Bool → State → List Event → Prop}
  {router : State → Except Fault Address → State → List Event → Prop}
  {spend : State → Except Fault Unit → State → List Event → Prop}
  {tail : Address → State → Except Fault Unit → State → List Event → Prop}
  {before after : State} {trace : List Event}

theorem failure_restores {fault : Fault}
    (h : Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail
      before (.error fault) after trace) : after = before := by
  cases h <;> rfl

theorem success_nonzero
    (h : Executes cannotDeposit unauthorized zeroAmount sender nonzero status router spend tail
      before (.ok ()) after trace) : nonzero := by
  cases h with
  | finished hs hr ha hn hp ht => exact hn

end

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalSpec
