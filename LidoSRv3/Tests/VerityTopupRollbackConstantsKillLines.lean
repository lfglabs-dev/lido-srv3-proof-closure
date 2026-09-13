import LidoSRv3.Audit.Verity.TopupRollback

/-! # Kill-lines for `Verity.TopupRollback` addresses + topUp selector

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 rollback-plane pinned addresses (Lido stub, beacon
deposit), the topUp entry selector, and compilation-spec identity. -/

namespace LidoSRv3.Tests.VerityTopupRollbackConstantsKillLines

open LidoSRv3.Audit.Verity.TopupRollback

/-- **Kill-line: rollback-plane model Lido address is 0x1.** -/
theorem lidoAddress_pinned :
    lidoAddress = 1 := rfl

/-- **Kill-line: pinned canonical beacon deposit contract address.** -/
theorem beaconDepositAddress_pinned :
    beaconDepositAddress = 0x00000000219ab540356cBB839Cbe05303d7705Fa := rfl

/-- **Kill-line: pinned topUp entry ABI selector.**

`bytes4(keccak256("topUp(uint256,bytes[],uint256[],uint256[],uint256[],bytes32)"))`
= 0x0f6b3d8b. -/
theorem topUpSelector_pinned :
    topUpSelector = 0x0f6b3d8b := rfl

/-- **Kill-line: topUp selector fits uint32.** -/
theorem topUpSelector_fits_uint32 :
    topUpSelector < 2 ^ 32 := by decide

/-- **Kill-line: topUp selector is non-zero.** -/
theorem topUpSelector_nonzero :
    topUpSelector ≠ 0 := by decide

/-- **Kill-line: beacon deposit address fits uint160.** -/
theorem beaconDepositAddress_fits_uint160 :
    beaconDepositAddress < 2 ^ 160 := by decide

/-- **Kill-line: lido rollback address is distinct from beacon deposit.** -/
theorem addresses_distinct :
    lidoAddress ≠ beaconDepositAddress := by decide

/-- **Kill-line: spec name is "PTopup1TopupRollback".** -/
theorem spec_name : spec.name = "PTopup1TopupRollback" := rfl

/-- **Kill-line: spec has no storage fields.** -/
theorem spec_no_fields : spec.fields = [] := rfl

/-- **Kill-line: spec has no constructor.** -/
theorem spec_no_constructor : spec.constructor = none := rfl

/-- **Kill-line: spec has exactly one function.** -/
theorem spec_one_function : spec.functions.length = 1 := rfl

#print axioms lidoAddress_pinned
#print axioms beaconDepositAddress_pinned
#print axioms topUpSelector_pinned
#print axioms addresses_distinct
#print axioms spec_name
#print axioms spec_one_function

end LidoSRv3.Tests.VerityTopupRollbackConstantsKillLines
