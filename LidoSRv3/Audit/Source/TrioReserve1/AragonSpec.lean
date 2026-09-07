import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.AragonSpec

/-- Independent Aragon initialization and kernel-presence admission prefix.
Permission evaluation by the kernel/ACL follows only the `query` branch. -/
inductive Prefix where
  | deny
  | query
  deriving DecidableEq

def Describes (initializationBlock blockNumber kernel : Nat) (result : Prefix) : Prop :=
  match result with
  | .deny => initializationBlock = 0 ∨ blockNumber < initializationBlock ∨ kernel = 0
  | .query => initializationBlock ≠ 0 ∧ initializationBlock ≤ blockNumber ∧ kernel ≠ 0

theorem exclusive (initializationBlock blockNumber kernel : Nat) :
    ¬ (Describes initializationBlock blockNumber kernel .deny ∧
      Describes initializationBlock blockNumber kernel .query) := by
  unfold Describes
  omega

end LidoSRv3.Audit.Source.TrioReserve1.AragonSpec
