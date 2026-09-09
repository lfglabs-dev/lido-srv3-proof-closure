import LidoSRv3.Audit.Source.TopupWeiBounds

/-! Kernel-checked witnesses for source branches and unit/guard mutations.
These are regression witnesses, not differential tests against deployed EVM. -/
namespace LidoSRv3.Tests.TopupWeiBoundsMutants
open LidoSRv3.Audit.Source.TopupWeiBounds

def cfg : GatewayConfig := ⟨⟨64, by decide⟩, ⟨10, by decide⟩, ⟨4, by decide⟩⟩
def validator : ValidatorInput :=
  ⟨⟨50, by decide⟩, ⟨10, by decide⟩, ⟨uint64Modulus - 1, by decide⟩, false⟩

example : evaluate cfg validator = some 4 := by decide
example : evaluate cfg { validator with effective := ⟨61, by decide⟩, pending := ⟨0, by decide⟩ } =
    some 0 := by decide
example : evaluate cfg { validator with effective := ⟨64, by decide⟩, pending := ⟨0, by decide⟩ } =
    some 0 := by decide

/-- The unchecked caller does not make the helper's addition unchecked. -/
def overflowing : ValidatorInput :=
  { validator with effective := ⟨1, by decide⟩, pending := ⟨wordModulus - 1, by decide⟩ }
example : evaluate cfg overflowing = none := by decide
/-- Exit/slash branches precede the potentially overflowing addition. -/
example : evaluate cfg { overflowing with slashed := true } = some 0 := by decide
example : evaluate cfg { overflowing with exitEpoch := ⟨0, by decide⟩ } = some 0 := by decide

/-- Dropping pending balance changes the accepted gap from four to fourteen. -/
example : evaluate cfg { validator with pending := ⟨0, by decide⟩ } = some 14 ∧
    evaluate cfg { validator with pending := ⟨0, by decide⟩ } ≠ evaluate cfg validator := by decide

/-- A raw-gwei limit substituted at line 226 loses nine decimal digits. -/
example : weiLimits [4] = [4000000000] ∧ [4] ≠ weiLimits [4] := by decide
/-- Multiplying by ether instead of gwei also breaks the roundtrip. -/
example : (4 * 10 ^ 18 % wordModulus) / gwei ≠ 4 := by decide

/-- Extremal real storage bounds fit, without an artificial 32 ETH ceiling. -/
example : (uint64Modulus - 1) * (uint64Modulus - 1) * gwei < wordModulus := by decide
example : ((uint64Modulus - 1) * gwei % wordModulus) / gwei =
    uint64Modulus - 1 := by decide

/-- Arbitrary allocations, including a short list, are admitted by the actual
loop's local guards; a greedy walk is not assumed. -/
example : allocationGuards [gwei, 3 * gwei] [4 * gwei, 4 * gwei] := by decide
example : allocationGuards [gwei] [4 * gwei, 4 * gwei] := by decide
example : ¬allocationGuards [gwei, gwei] [4 * gwei] := by decide
/-- Reject the missing per-key cap and missing alignment mutants. -/
example : ¬allocationGuards [5 * gwei] [4 * gwei] := by decide
example : ¬allocationGuards [gwei + 1] [4 * gwei] := by decide

/-- Per-key caps alone do not enforce the aggregate budget: the real final
comparison is necessary and rejects this excess. -/
example : allocationGuards [3 * gwei, 3 * gwei] [4 * gwei, 4 * gwei] ∧
    ¬uncheckedSum 0 [3 * gwei, 3 * gwei] ≤ 5 * gwei := by decide

/-- The cardinality/domain argument is load-bearing: unchecked sums on
unbounded arbitrary words can wrap and falsely satisfy a zero budget. -/
example : uncheckedSum 0 [wordModulus - 1, 1] = 0 ∧
    ([wordModulus - 1, 1] : List Nat).sum > 0 := by decide

/-- Rounding discards wei dust before module admission. -/
example : routerBudget (5 * gwei + 17) ⟨10, by decide⟩ = 5 * gwei := by decide
example : routerBudget (5 * gwei + 17) ⟨4, by decide⟩ = 4 * gwei := by decide
example : routerAccept [3 * gwei, 3 * gwei] [4 * gwei, 4 * gwei] (5 * gwei) = none := by decide
example : routerAccept [gwei, 3 * gwei] [4 * gwei, 4 * gwei] (5 * gwei) = some (4 * gwei) := by decide

end LidoSRv3.Tests.TopupWeiBoundsMutants

#print axioms LidoSRv3.Audit.Source.TopupWeiBounds.gateway_wei_bounds
#print axioms LidoSRv3.Audit.Source.TopupWeiBounds.router_success
