namespace LidoSRv3.Audit.Source.TrioReserve1.StatusSpec

/-- Independent live-status rules. Decode checks the first ABI word; pause state
is observed in the world returned by the bunker call. Nonzero bunker status denies
without consulting pause state. These are stage results, before root rollback. -/
inductive Evaluates {State Address Fault Payload Event : Type} (malformed : Fault)
    (size decoded : Payload → Nat) (active : State → Nat)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (bunkerCall : Address → State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Bool → State → List Event → Prop where
  | lookup_error {fault after trace} (h : lookup before (.error fault) after trace) :
      Evaluates malformed size decoded active lookup bunkerCall before (.error fault) after trace
  | call_error {queue found after left right fault}
      (hl : lookup before (.ok queue) found left) (hc : bunkerCall queue found (.error fault) after right) :
      Evaluates malformed size decoded active lookup bunkerCall before (.error fault) after (left ++ right)
  | malformed {queue found after left right data}
      (hl : lookup before (.ok queue) found left) (hc : bunkerCall queue found (.ok data) after right)
      (hn : size data < 32) :
      Evaluates malformed size decoded active lookup bunkerCall before (.error malformed) after (left ++ right)
  | bunker {queue found after left right data}
      (hl : lookup before (.ok queue) found left) (hc : bunkerCall queue found (.ok data) after right)
      (hn : 32 ≤ size data) (hb : decoded data ≠ 0) :
      Evaluates malformed size decoded active lookup bunkerCall before (.ok false) after (left ++ right)
  | paused {queue found after left right data}
      (hl : lookup before (.ok queue) found left) (hc : bunkerCall queue found (.ok data) after right)
      (hn : 32 ≤ size data) (hb : decoded data = 0) (ha : active after = 0) :
      Evaluates malformed size decoded active lookup bunkerCall before (.ok false) after (left ++ right)
  | allowed {queue found after left right data}
      (hl : lookup before (.ok queue) found left) (hc : bunkerCall queue found (.ok data) after right)
      (hn : 32 ≤ size data) (hb : decoded data = 0) (ha : active after ≠ 0) :
      Evaluates malformed size decoded active lookup bunkerCall before (.ok true) after (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.StatusSpec
