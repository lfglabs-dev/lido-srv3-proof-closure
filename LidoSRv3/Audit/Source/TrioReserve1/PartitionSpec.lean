import Lean.Elab.Tactic.Omega

/-!
Independent mathematical reserve specification. This module imports neither
an executor nor the old cached-queue declaration. `demand` is a mathematical
observation to be related to the actual live queue read by a future theorem.
It is NOT a freshness premise discharged by this module.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec

/-- Amount protected for the observed withdrawal demand after deposit priority. -/
def protectedReserve (buffer reserve demand : Nat) : Nat :=
  min (buffer - min buffer reserve) demand

/-- Independent condition for a spend to leave withdrawal protection intact. -/
def AllowedSpend (buffer reserve demand amount : Nat) : Prop :=
  amount ≤ buffer - protectedReserve buffer reserve demand

/-- No bound on stored reserve relative to buffer is needed. Report rebalance
may legitimately restore a reserve target larger than the current buffer. -/
theorem spend_preserves (buffer reserve demand amount : Nat)
    (allowed : AllowedSpend buffer reserve demand amount) :
    protectedReserve (buffer - amount) (reserve - amount) demand =
      protectedReserve buffer reserve demand := by
  unfold AllowedSpend protectedReserve at *
  omega

/-- Lowering the stored reserve cannot reduce withdrawal protection. -/
theorem lowering_reserve (buffer demand before after : Nat) (h : after ≤ before) :
    protectedReserve buffer before demand ≤ protectedReserve buffer after demand := by
  unfold protectedReserve
  omega

/-- A new live queue observation can change protection between transactions.
Consequently spend preservation is not a global constancy claim across queue writers. -/
theorem demand_monotone (buffer reserve oldDemand newDemand : Nat)
    (h : oldDemand ≤ newDemand) :
    protectedReserve buffer reserve oldDemand ≤ protectedReserve buffer reserve newDemand := by
  unfold protectedReserve
  omega

/-- Sequential spending preserves protection for a fixed queue observation,
with each step admitted against its own updated partition. Queue-changing
sequences require an additional queue-writer relation. -/
theorem two_spends (buffer reserve demand first second : Nat)
    (hfirst : AllowedSpend buffer reserve demand first)
    (hsecond : AllowedSpend (buffer - first) (reserve - first) demand second) :
    protectedReserve (buffer - first - second) (reserve - first - second) demand =
      protectedReserve buffer reserve demand := by
  exact (spend_preserves _ _ _ _ hsecond).trans (spend_preserves _ _ _ _ hfirst)

end LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec
