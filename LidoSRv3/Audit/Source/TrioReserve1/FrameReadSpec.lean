namespace LidoSRv3.Audit.Source.TrioReserve1.FrameReadSpec

/-- Independent ordered frame getter rules. The entire two-word tuple is checked
before either field is returned. A successful malformed reply retains the callee
world and calls, with decoder failure distinct from an external-call failure. -/
inductive Reads {State Address Fault Payload Frame Event : Type} (malformed : Fault)
    (size : Payload → Nat) (decodeFrame : Payload → Frame)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (oracle : Address → State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Frame → State → List Event → Prop where
  | lookup_error {fault after trace} (hl : lookup before (.error fault) after trace) :
      Reads malformed size decodeFrame lookup oracle before (.error fault) after trace
  | call_error {target located after left right fault} (hl : lookup before (.ok target) located left)
      (hc : oracle target located (.error fault) after right) :
      Reads malformed size decodeFrame lookup oracle before (.error fault) after (left ++ right)
  | malformed {target located after left right data} (hl : lookup before (.ok target) located left)
      (hc : oracle target located (.ok data) after right) (hn : size data < 64) :
      Reads malformed size decodeFrame lookup oracle before (.error malformed) after (left ++ right)
  | decoded {target located after left right data} (hl : lookup before (.ok target) located left)
      (hc : oracle target located (.ok data) after right) (hn : 64 ≤ size data) :
      Reads malformed size decodeFrame lookup oracle before (.ok (decodeFrame data)) after (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.FrameReadSpec
