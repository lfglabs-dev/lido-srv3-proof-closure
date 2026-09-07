namespace LidoSRv3.Audit.Source.TrioReserve1.CallSpec

/-- Independent pointwise balance accounting for CALL's provisional transfer.
The equation handles self-calls without double-counting an aliased account. -/
def Balances {Address : Type} [DecidableEq Address] (before after : Address → Nat)
    (sender recipient : Address) (amount : Nat) : Prop :=
  ∀ account, after account + (if account = sender then amount else 0) =
    before account + (if account = recipient then amount else 0)

/-- Independent high-level CALL rules. No-code fails before an attempt or callee
observation. Insufficient funds records failure without invoking a callee. Funded
execution starts in the provisionally credited world. Rejection restores the
incoming world, while success retains the callee-returned world and nested calls. -/
inductive Invokes {State Fault Payload Nested Event : Type} (empty : Fault)
    (bubble : Payload → Fault) (emptyData : Payload) (attempt : Bool → Payload → List Nested → Event)
    (code balance amount : Nat) (before credited : State)
    (callee : State → Bool → Payload → State → List Nested → Prop) : Except Fault Payload → State → List Event → Prop where
  | no_code (hc : code = 0) :
      Invokes empty bubble emptyData attempt code balance amount before credited callee (.error empty) before []
  | unfunded (hc : code ≠ 0) (hb : balance < amount) :
      Invokes empty bubble emptyData attempt code balance amount before credited callee
        (.error (bubble emptyData)) before [attempt false emptyData []]
  | accepted {data after children} (hc : code ≠ 0) (hb : amount ≤ balance)
      (hr : callee credited true data after children) :
      Invokes empty bubble emptyData attempt code balance amount before credited callee
        (.ok data) after [attempt true data children]
  | rejected {data after children} (hc : code ≠ 0) (hb : amount ≤ balance)
      (hr : callee credited false data after children) :
      Invokes empty bubble emptyData attempt code balance amount before credited callee
        (.error (bubble data)) before [attempt false data children]

section
variable {State Fault Payload Nested Event : Type} {empty : Fault} {bubble : Payload → Fault}
  {emptyData : Payload} {attempt : Bool → Payload → List Nested → Event}
  {code balance amount : Nat} {before credited after : State}
  {callee : State → Bool → Payload → State → List Nested → Prop} {trace : List Event}

theorem failure_restores {fault : Fault}
    (h : Invokes empty bubble emptyData attempt code balance amount before credited callee (.error fault) after trace) :
    after = before := by
  cases h <;> rfl

theorem success_funded {data : Payload}
    (h : Invokes empty bubble emptyData attempt code balance amount before credited callee (.ok data) after trace) :
    code ≠ 0 ∧ amount ≤ balance := by
  cases h with
  | accepted hc hb hr => exact ⟨hc, hb⟩

end

end LidoSRv3.Audit.Source.TrioReserve1.CallSpec
