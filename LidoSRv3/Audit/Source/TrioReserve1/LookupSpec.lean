namespace LidoSRv3.Audit.Source.TrioReserve1.LookupSpec

/-- Independent typed getter result rules. Failed calls propagate; successful
short replies fail decoding in the returned world. Extra bytes are allowed.
The supplied decode projection identifies the first ABI word and address narrowing. -/
inductive Returns {State Fault Payload Address Event : Type} (malformed : Fault)
    (size : Payload → Nat) (decodeAddress : Payload → Address)
    (call : State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Address → State → List Event → Prop where
  | call_error {fault after trace} (hc : call before (.error fault) after trace) :
      Returns malformed size decodeAddress call before (.error fault) after trace
  | malformed {data after trace} (hc : call before (.ok data) after trace) (hn : size data < 32) :
      Returns malformed size decodeAddress call before (.error malformed) after trace
  | decoded {data after trace} (hc : call before (.ok data) after trace) (hn : 32 ≤ size data) :
      Returns malformed size decodeAddress call before (.ok (decodeAddress data)) after trace

end LidoSRv3.Audit.Source.TrioReserve1.LookupSpec
