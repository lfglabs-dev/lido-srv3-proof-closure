import LidoSRv3.Audit.Source.ERC20StateViaOracleSource

/-! # P-ADDRESS-1 composite balance/allowance guard source model

**General rule (Thomas 2026-09-13): compose the ERC-20 state via
KeccakOracle source model with the ADDRESS-1 transferFrom balance +
allowance guards into a single named composite derivation.**

Downstream P-ADDRESS-1 consumers of the two free booleans
`callerBalanceSufficient` and `callerAllowanceSufficient` can now
replace them with `bothGuardsPassFromOracle`, a source-level
function of `(oracle, balancesBaseSlot, allowancesBaseSlot, owner,
spender, amount)`.

**Status:** first real composition of the P-ADDRESS-1 balance +
allowance guards through the shared oracle-backed ERC-20 state. -/

namespace LidoSRv3.Audit.Source.Address1CompositeGuardSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ERC20StorageSource
open LidoSRv3.Audit.Source.ERC20StateViaOracleSource

/-- Composite guard: caller balance ≥ amount AND caller allowance ≥
amount, both from the shared oracle-backed ERC-20 state. -/
def bothGuardsPassFromOracle
    (oracle : KeccakOracle)
    (balancesBaseSlot allowancesBaseSlot owner spender amount : Nat) : Bool :=
  let state := realERC20State oracle balancesBaseSlot allowancesBaseSlot
  decide (amount ≤ balanceOf state owner)
    && decide (amount ≤ allowanceOf state owner spender)

/-- Under the pinned "both bounds hold" premise, the composite guard
passes. -/
theorem bothGuardsPassFromOracle_true_of_bounds
    {oracle : KeccakOracle}
    {balancesBaseSlot allowancesBaseSlot owner spender amount : Nat}
    (hBalance : amount ≤
      balanceOf (realERC20State oracle balancesBaseSlot allowancesBaseSlot)
        owner)
    (hAllowance : amount ≤
      allowanceOf (realERC20State oracle balancesBaseSlot allowancesBaseSlot)
        owner spender) :
    bothGuardsPassFromOracle oracle balancesBaseSlot allowancesBaseSlot
      owner spender amount = true := by
  simp [bothGuardsPassFromOracle, hBalance, hAllowance]

end LidoSRv3.Audit.Source.Address1CompositeGuardSource
