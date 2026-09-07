namespace LidoSRv3.Audit.Source.TrioReserve1.OptionalCallSpec

/-- Independent conditional high-level call rules. Zero amount skips lookup and
CALL. Only the reward operation validates a returned word; its value is unused.
Failures here retain the stage world; parent rules handle transaction rollback. -/
inductive Executes {State Address Fault Payload Event : Type}
    (malformed : Fault) (size : Payload → Nat) (amount : Nat) (checkWord : Bool)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (call : Address → State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | skipped (hz : amount = 0) : Executes malformed size amount checkWord lookup call before (.ok ()) before []
  | lookup_error {fault after trace} (hn : 0 < amount) (hl : lookup before (.error fault) after trace) :
      Executes malformed size amount checkWord lookup call before (.error fault) after trace
  | call_error {target located after left right fault} (hn : 0 < amount)
      (hl : lookup before (.ok target) located left) (hc : call target located (.error fault) after right) :
      Executes malformed size amount checkWord lookup call before (.error fault) after (left ++ right)
  | malformed {target located after left right data} (hn : 0 < amount)
      (hl : lookup before (.ok target) located left) (hc : call target located (.ok data) after right)
      (hw : checkWord = true) (hs : size data < 32) :
      Executes malformed size amount checkWord lookup call before (.error malformed) after (left ++ right)
  | success {target located after left right data} (hn : 0 < amount)
      (hl : lookup before (.ok target) located left) (hc : call target located (.ok data) after right)
      (hv : checkWord = false ∨ 32 ≤ size data) :
      Executes malformed size amount checkWord lookup call before (.ok ()) after (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.OptionalCallSpec
