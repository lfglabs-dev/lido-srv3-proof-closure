import LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec
import LidoSRv3.Audit.Source.TrioReserve1.QueueSpec

/-!
Independent allocation relation: priority is expressed by maximality, rather
than by copying the executable min/subtraction expression. Demand is tied to
the current queue state. This is a specification foundation, not an assertion
that the CALL/ABI/storage interpreter already refines it.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.AllocationSpec

structure Allocation where
  deposits : Nat
  withdrawals : Nat
  unreserved : Nat

def Describes (buffer reserve demand : Nat) (a : Allocation) : Prop :=
  a.deposits ≤ buffer ∧ a.deposits ≤ reserve ∧
  (∀ n, n ≤ buffer → n ≤ reserve → n ≤ a.deposits) ∧
  a.deposits + a.withdrawals ≤ buffer ∧ a.withdrawals ≤ demand ∧
  (∀ n, a.deposits + n ≤ buffer → n ≤ demand → n ≤ a.withdrawals) ∧
  a.deposits + a.withdrawals + a.unreserved = buffer

def LiveDescribes (queue : QueueSpec.State) (buffer reserve demand : Nat)
    (a : Allocation) : Prop :=
  QueueSpec.Describes queue (.value demand) ∧ Describes buffer reserve demand a

theorem unique (buffer reserve demand : Nat) (a b : Allocation)
    (ha : Describes buffer reserve demand a)
    (hb : Describes buffer reserve demand b) : a = b := by
  rcases ha with ⟨haB, haR, haMax, haW, haD, haWMax, haSum⟩
  rcases hb with ⟨hbB, hbR, hbMax, hbW, hbD, hbWMax, hbSum⟩
  have hd : a.deposits = b.deposits := Nat.le_antisymm
    (hbMax _ haB haR) (haMax _ hbB hbR)
  have hw : a.withdrawals = b.withdrawals := Nat.le_antisymm
    (hbWMax _ (by omega) haD) (haWMax _ (by omega) hbD)
  have hu : a.unreserved = b.unreserved := by omega
  cases a
  cases b
  simp_all

theorem exists_allocation (buffer reserve demand : Nat) :
    Describes buffer reserve demand
      ⟨min buffer reserve, min (buffer - min buffer reserve) demand,
       buffer - min buffer reserve - min (buffer - min buffer reserve) demand⟩ := by
  unfold Describes
  dsimp
  refine ⟨by omega, by omega, ?_, by omega, by omega, ?_, by omega⟩
  · intro n hnB hnR
    omega
  · intro n hnB hnD
    omega

theorem withdrawals_eq_protected (buffer reserve demand : Nat) (a : Allocation)
    (ha : Describes buffer reserve demand a) :
    a.withdrawals = PartitionSpec.protectedReserve buffer reserve demand := by
  have h := unique buffer reserve demand a _ ha (exists_allocation buffer reserve demand)
  cases h
  rfl

/-- Each spend protects its own actual queue observation. The second queue
may have unrelated ids/rows; no stale-demand equality is imposed. This theorem
does not supply a queue-writer or physical-execution correspondence premise. -/
theorem two_live_spends (firstQueue secondQueue : QueueSpec.State)
    (buffer reserve firstDemand secondDemand first second : Nat)
    (a b : Allocation)
    (ha : LiveDescribes firstQueue buffer reserve firstDemand a)
    (hb : LiveDescribes secondQueue (buffer - first) (reserve - first) secondDemand b)
    (hfirst : first ≤ a.deposits + a.unreserved)
    (hsecond : second ≤ b.deposits + b.unreserved) :
    PartitionSpec.protectedReserve (buffer - first) (reserve - first) firstDemand =
      a.withdrawals ∧
    PartitionSpec.protectedReserve (buffer - first - second)
      (reserve - first - second) secondDemand = b.withdrawals := by
  have hwa := withdrawals_eq_protected _ _ _ _ ha.2
  have hwb := withdrawals_eq_protected _ _ _ _ hb.2
  have hsa := ha.2.2.2.2.2.2.2
  have hsb := hb.2.2.2.2.2.2.2
  constructor
  · rw [PartitionSpec.spend_preserves]
    · exact hwa.symm
    · unfold PartitionSpec.AllowedSpend
      omega
  · rw [PartitionSpec.spend_preserves]
    · exact hwb.symm
    · unfold PartitionSpec.AllowedSpend
      omega

end LidoSRv3.Audit.Source.TrioReserve1.AllocationSpec
