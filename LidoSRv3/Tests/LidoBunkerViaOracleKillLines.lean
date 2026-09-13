import LidoSRv3.Audit.Source.LidoBunkerViaOracleSource

/-! # Kill-lines for `LidoBunkerViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the oracle-backed isBunkerActive composition through the shared
KeccakOracle.** -/

namespace LidoSRv3.Tests.LidoBunkerViaOracleKillLines

open LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource
open LidoSRv3.Audit.Source.LidoStakingStateStorage

/-- Concrete oracle mapping every input to zero — used as a witness
for the bunker-off closure. -/
def zeroOracle : KeccakOracle where
  hash := fun _ => 0
  determinism := fun _ _ _ => rfl

/-- **Kill-line: `isBunkerActiveFromOracle` = `isBunkerActiveFromStorage`
applied to `realMappingStorage`.**

A mutant that redirected the composition to a different
mapping-storage would refute this. -/
theorem isBunkerActiveFromOracle_composition
    (oracle : KeccakOracle) (bunkerBase bunkerKey : Nat) :
    isBunkerActiveFromOracle oracle bunkerBase bunkerKey =
      isBunkerActiveFromStorage
        (realMappingStorage oracle bunkerBase) bunkerKey :=
  rfl

/-- **Kill-line: with the zero-oracle, the bunker slot is zero, and
`isBunkerActiveFromOracle` = false.** -/
theorem isBunkerActiveFromOracle_zero_oracle
    (bunkerBase bunkerKey : Nat) :
    isBunkerActiveFromOracle zeroOracle bunkerBase bunkerKey = false := by
  apply isBunkerActiveFromOracle_false_of_zero
  rfl

#print axioms isBunkerActiveFromOracle_composition
#print axioms isBunkerActiveFromOracle_zero_oracle

end LidoSRv3.Tests.LidoBunkerViaOracleKillLines
