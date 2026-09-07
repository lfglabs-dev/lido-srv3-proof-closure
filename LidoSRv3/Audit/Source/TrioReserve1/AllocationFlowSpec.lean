import LidoSRv3.Audit.Source.TrioReserve1.AllocationSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.AllocationFlowSpec

/-- Independent live-allocation rules. Buffer and reserve are saved before any
lookup or queue call. Success uses the maximal-priority allocation relation;
callee state changes are retained but cannot replace those saved observations. -/
inductive Evaluates {State Address Fault Payload Result Event : Type} (malformed : Fault)
    (buffer reserve : Nat) (size demand : Payload → Nat)
    (total : Result → Nat) (observe : Result → AllocationSpec.Allocation)
    (lookup : State → Except Fault Address → State → List Event → Prop)
    (queueCall : Address → State → Except Fault Payload → State → List Event → Prop)
    (before : State) : Except Fault Result → State → List Event → Prop where
  | lookup_error {fault after trace} (hl : lookup before (.error fault) after trace) :
      Evaluates malformed buffer reserve size demand total observe lookup queueCall before (.error fault) after trace
  | call_error {queue found after left right fault} (hl : lookup before (.ok queue) found left)
      (hc : queueCall queue found (.error fault) after right) :
      Evaluates malformed buffer reserve size demand total observe lookup queueCall before (.error fault) after (left ++ right)
  | malformed {queue found after left right data} (hl : lookup before (.ok queue) found left)
      (hc : queueCall queue found (.ok data) after right) (hn : size data < 32) :
      Evaluates malformed buffer reserve size demand total observe lookup queueCall before (.error malformed) after (left ++ right)
  | allocated {queue found after left right data result} (hl : lookup before (.ok queue) found left)
      (hc : queueCall queue found (.ok data) after right) (hn : 32 ≤ size data)
      (ht : total result = buffer) (hs : AllocationSpec.Describes buffer reserve (demand data) (observe result)) :
      Evaluates malformed buffer reserve size demand total observe lookup queueCall before (.ok result) after (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.AllocationFlowSpec
