/-! Independent receiver rule for pinned StakingRouter.sol:665-669,1177-1179.
Addresses and the incoming ETH amount are input values. The immutable binding
must separately be related to deployment bytecode/configuration. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.RouterSpec

inductive Outcome where
  | accepted (eventAmount : Nat)
  | notAuthorized
  deriving DecidableEq, Repr

def Describes (authorized caller amount : Nat) : Outcome → Prop
  | .accepted eventAmount => caller = authorized ∧ eventAmount = amount
  | .notAuthorized => caller ≠ authorized

end LidoSRv3.Audit.Source.TrioReserve1.RouterSpec
