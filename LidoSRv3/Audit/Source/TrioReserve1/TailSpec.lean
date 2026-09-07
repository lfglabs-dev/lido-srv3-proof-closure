namespace LidoSRv3.Audit.Source.TrioReserve1.TailSpec

/-- Independent seed-update rules. The checked full sum governs overflow;
physical narrowing and its event are supplied by the write-state projection. -/
inductive Seeds {State Fault : Type} (overflow : Fault) (limit count : Nat)
    (current : State → Nat) (write : State → State) (before : State) : Except Fault Unit → State → Prop where
  | zero (h : count = 0) : Seeds overflow limit count current write before (.ok ()) before
  | updated (hn : 0 < count) (hb : current before + count < limit) :
      Seeds overflow limit count current write before (.ok ()) (write before)
  | overflow (hn : 0 < count) (hb : limit ≤ current before + count) :
      Seeds overflow limit count current write before (.error overflow) before

/-- Independent ordered tail rules. A seed failure skips the receiver; successful
seed update always reaches the receiver. Receiver return bytes are discarded on
success. These are stage worlds, before transaction-root rollback. -/
inductive Finishes {State Fault Payload Event : Type}
    (seed : State → Except Fault Unit → State → Prop)
    (receiver : State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | seed_error {fault after} (hs : seed before (.error fault) after) :
      Finishes seed receiver before (.error fault) after []
  | receiver_error {seeded after trace fault} (hs : seed before (.ok ()) seeded)
      (hc : receiver seeded (.error fault) after trace) :
      Finishes seed receiver before (.error fault) after trace
  | success {seeded after trace data} (hs : seed before (.ok ()) seeded)
      (hc : receiver seeded (.ok data) after trace) :
      Finishes seed receiver before (.ok ()) after trace

end LidoSRv3.Audit.Source.TrioReserve1.TailSpec
