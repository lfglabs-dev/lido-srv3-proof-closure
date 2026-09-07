namespace LidoSRv3.Audit.Source.TrioReserve1.CallbackSpec

/-- A payable callback looks up its authorized sender in the incoming world.
Only admitted callbacks execute the post-lookup update. No pause or value guard
is added; lookup effects and attempts remain observable on stage failure. -/
inductive Receives {State Address Fault Event : Type}
    (denied : Fault) (caller : Address)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (update : State → Except Fault Unit → State → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | lookup_error {fault after trace} (hl : lookup before (.error fault) after trace) :
      Receives denied caller lookup update before (.error fault) after trace
  | unauthorized {vault located trace} (hl : lookup before (.ok vault) located trace) (ha : caller ≠ vault) :
      Receives denied caller lookup update before (.error denied) located trace
  | admitted {vault located after trace outcome} (hl : lookup before (.ok vault) located trace)
      (ha : caller = vault) (hu : update located outcome after) :
      Receives denied caller lookup update before outcome after trace

/-- Counter bounds use the world returned by the authorization lookup. The
successful update writes the full sum and then emits; overflow has no writes. -/
inductive RewardUpdate {State Fault : Type}
    (overflow : Fault) (limit value : Nat) (total : State → Nat)
    (commit : State → Nat → State) (before : State) : Except Fault Unit → State → Prop where
  | overflow (hb : limit ≤ total before + value) :
      RewardUpdate overflow limit value total commit before (.error overflow) before
  | collected (hb : total before + value < limit) :
      RewardUpdate overflow limit value total commit before (.ok ()) (commit before (total before + value))

end LidoSRv3.Audit.Source.TrioReserve1.CallbackSpec
