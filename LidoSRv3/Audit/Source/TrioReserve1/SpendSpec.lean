namespace LidoSRv3.Audit.Source.TrioReserve1.SpendSpec

/-- Independent ordered spending-stage rules. Allocation precedes admission and
prepared accounting; frame evaluation uses that prepared world. Commit retains
both saved accounting inputs and the frame's returned world. No root rollback is
performed here: the withdrawal parent owns transaction rollback. -/
inductive Executes {State Allocation Frame Fault Event : Type} (insufficient : Fault)
    (amount : Nat) (available : Allocation → Nat)
    (prepare : Allocation → State → State) (commit : Allocation → State → Frame → State → State)
    (allocate : State → Except Fault Allocation → State → List Event → Prop)
    (frame : State → Except Fault Frame → State → List Event → Prop)
    (before : State) : Except Fault Unit → State → List Event → Prop where
  | allocation_error {fault after trace} (ha : allocate before (.error fault) after trace) :
      Executes insufficient amount available prepare commit allocate frame before (.error fault) after trace
  | insufficient {a allocated trace} (ha : allocate before (.ok a) allocated trace) (hn : available a < amount) :
      Executes insufficient amount available prepare commit allocate frame before (.error insufficient) allocated trace
  | frame_error {a allocated failed left right fault} (ha : allocate before (.ok a) allocated left)
      (hn : amount ≤ available a) (hf : frame (prepare a allocated) (.error fault) failed right) :
      Executes insufficient amount available prepare commit allocate frame before (.error fault) failed (left ++ right)
  | success {a allocated framed left right value} (ha : allocate before (.ok a) allocated left)
      (hn : amount ≤ available a) (hf : frame (prepare a allocated) (.ok value) framed right) :
      Executes insufficient amount available prepare commit allocate frame before (.ok ())
        (commit a allocated value framed) (left ++ right)

end LidoSRv3.Audit.Source.TrioReserve1.SpendSpec
