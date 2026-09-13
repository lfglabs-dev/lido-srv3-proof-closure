import LidoSRv3.Audit.Source.Topup1CompositeGateSource

/-! # Kill-lines for `Topup1CompositeGateSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 composite entry-gate composition (ACL role ∧ module
exists ∧ WC type-2).** -/

namespace LidoSRv3.Tests.Topup1CompositeGateKillLines

open LidoSRv3.Audit.Source.Topup1CompositeGateSource
open LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
open LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
open LidoSRv3.Audit.Source.WCType2ByteDecodeSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- **Kill-line: `entryGatePasses` = ACL ∧ moduleExists ∧ wcIsType2.**

A mutant that dropped a conjunct or flipped a polarity would refute. -/
theorem entryGatePasses_composition
    (oracle : KeccakOracle)
    (aclBase moduleRegBase moduleId wcWord : Nat) :
    entryGatePasses oracle aclBase moduleRegBase moduleId wcWord =
      (isTopUpGatewayFromOracle oracle aclBase &&
        moduleExistsFromOracle oracle moduleRegBase moduleId &&
        wcIsType2 wcWord) :=
  rfl

/-- **Kill-line: with WC top-byte 1, the whole gate fails.**

Even if the other two premises were `true`, wrong WC-type refutes
the gate. -/
theorem entryGatePasses_false_of_wc_type_one
    (oracle : KeccakOracle) (aclBase moduleRegBase moduleId : Nat) :
    entryGatePasses oracle aclBase moduleRegBase moduleId
        (1 * 2 ^ 248) =
      false := by
  unfold entryGatePasses
  have : wcIsType2 (1 * 2 ^ 248) = false := by decide
  rw [this]
  simp

#print axioms entryGatePasses_composition
#print axioms entryGatePasses_false_of_wc_type_one

end LidoSRv3.Tests.Topup1CompositeGateKillLines
