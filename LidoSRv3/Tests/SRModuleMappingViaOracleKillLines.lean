import LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource

/-! # Kill-lines for `SRModuleMappingViaOracleSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the oracle-backed SR moduleExists composition through the shared
KeccakOracle.** -/

namespace LidoSRv3.Tests.SRModuleMappingViaOracleKillLines

open LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
open LidoSRv3.Audit.Source.SRStorageSourceModel
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- **Kill-line: `moduleExistsFromOracle` = `moduleExistsFromMapping`
applied to `realMappingStorage`.**

A mutant that swapped the mapping-storage source or dropped the
composition would refute. -/
theorem moduleExistsFromOracle_composition
    (oracle : KeccakOracle) (moduleRegBase moduleId : Nat) :
    moduleExistsFromOracle oracle moduleRegBase moduleId =
      moduleExistsFromMapping
        (realMappingStorage oracle moduleRegBase) moduleId :=
  rfl

/-- Non-trivial oracle mapping every input to 42 — witnesses the
non-zero-slot case. -/
def nonZeroOracle : KeccakOracle where
  hash := fun _ => 42
  determinism := fun _ _ _ => rfl

/-- **Kill-line: with the always-42 oracle, `moduleExistsFromOracle`
= true.** -/
theorem moduleExistsFromOracle_nonzero_oracle
    (moduleRegBase moduleId : Nat) :
    moduleExistsFromOracle nonZeroOracle moduleRegBase moduleId = true := by
  apply moduleExistsFromOracle_true_of_nonzero
  -- (realMappingStorage nonZeroOracle moduleRegBase).slotAt moduleId
  --   = concreteMappingSlot nonZeroOracle (encodeMappingKey moduleId moduleRegBase)
  --   = nonZeroOracle.hash [_] = 42 ≠ 0
  unfold realMappingStorage realSlotDerivation concreteMappingSlot
  simp [nonZeroOracle]

#print axioms moduleExistsFromOracle_composition
#print axioms moduleExistsFromOracle_nonzero_oracle

end LidoSRv3.Tests.SRModuleMappingViaOracleKillLines
