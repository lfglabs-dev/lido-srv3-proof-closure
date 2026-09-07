namespace LidoSRv3.Audit.Source.TrioReserve1.EntrySpec

/-- Returned replies are derived from complete transaction observations. Rejected
replies contain failure bytes and attempts, with no committed callee state. -/
inductive Returns {State Fault Value Event Reply : Type}
    (success : Value → State → List Event → Reply) (failure : Fault → List Event → Reply)
    (transaction : State → Except Fault Value → State → List Event → Prop)
    (before : State) : Reply → Prop where
  | success {value after trace} (ht : transaction before (.ok value) after trace) :
      Returns success failure transaction before (success value after trace)
  | failure {fault after trace} (ht : transaction before (.error fault) after trace) :
      Returns success failure transaction before (failure fault trace)

/-- Ordered two-entry selection with a shared ABI/value admission condition.
Fallback is used only after both selector/target matches fail. -/
inductive Dispatch {Reply : Type} (first second valid : Prop) (invalid fallback : Reply)
    (firstReply secondReply : Reply → Prop) : Reply → Prop where
  | first_invalid (hf : first) (hv : ¬ valid) : Dispatch first second valid invalid fallback firstReply secondReply invalid
  | first (hf : first) (hv : valid) {reply} (hr : firstReply reply) :
      Dispatch first second valid invalid fallback firstReply secondReply reply
  | second_invalid (hf : ¬ first) (hs : second) (hv : ¬ valid) :
      Dispatch first second valid invalid fallback firstReply secondReply invalid
  | second (hf : ¬ first) (hs : second) (hv : valid) {reply} (hr : secondReply reply) :
      Dispatch first second valid invalid fallback firstReply secondReply reply
  | fallback (hf : ¬ first) (hs : ¬ second) :
      Dispatch first second valid invalid fallback firstReply secondReply fallback

end LidoSRv3.Audit.Source.TrioReserve1.EntrySpec
