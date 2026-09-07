import LidoSRv3.Audit.Source.TrioReserve1.AllocationSpec

/-! Independent arithmetic spending relation. Observations distinguish saved
allocation, post-lookup accounting, saved next-report accounting, and reserve
after the frame call; arbitrary callee effects need not preserve these values. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.SpendingSpec

structure Observations where
  total : Nat
  allocationReserve : Nat
  demand : Nat
  allocation : AllocationSpec.Allocation
  amount : Nat
  post : Nat
  next : Nat
  savedNonce : Nat
  frameNonce : Nat
  finalReserve : Nat

structure Accounting where
  buffer : Nat
  post : Nat
  next : Nat
  nonce : Nat
  reserve : Nat

def Admitted (o : Observations) : Prop :=
  AllocationSpec.Describes o.total o.allocationReserve o.demand o.allocation ∧
  o.amount ≤ o.allocation.deposits + o.allocation.unreserved

/-- Conservation specifies the untruncated quantities. Physical writes must
separately implement their uint128 projections; events expose the full sums. -/
def Describes (o : Observations) (a : Accounting) : Prop :=
  Admitted o ∧
  a.buffer + o.amount = o.total ∧
  a.post = o.post + o.amount ∧
  a.next = (if o.frameNonce = o.savedNonce then o.next else 0) + o.amount ∧
  a.nonce = o.frameNonce ∧ a.reserve = o.finalReserve - o.amount

theorem admitted_bound (o : Observations) (h : Admitted o) : o.amount ≤ o.total := by
  have hc := h.1.2.2.2.2.2.2
  have ha := h.2
  omega

def accounting (o : Observations) : Accounting :=
  ⟨o.total - o.amount, o.post + o.amount,
    (if o.frameNonce = o.savedNonce then o.next else 0) + o.amount,
    o.frameNonce, o.finalReserve - o.amount⟩

theorem accounting_corresponds (o : Observations) (h : Admitted o) :
    Describes o (accounting o) := by
  have hb := admitted_bound o h
  exact ⟨h, by simp only [accounting]; omega, rfl, rfl, rfl, rfl⟩

end LidoSRv3.Audit.Source.TrioReserve1.SpendingSpec
