import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # SR module packed-storage decoder source model

**General rule (Thomas 2026-09-13, real derivation of the P-TOPUP-1
moduleExists free boolean via a packed-decode source model —
closing item (a) of the general-rule follow-up in audit/STATUS.md.)**

Item (a) of the P-TOPUP-1 general-rule follow-up disclosed that
`moduleExists` should be derived via a keyed storage-word decoder
consuming the packed module registry entry. The pinned Solidity
`StakingRouter.getStakingModule(uint256 _stakingModuleId)` returns
a packed struct at the module's storage slot; a module exists iff
its packed word has a nonzero `id` field.

This composition names the packed-storage `moduleId` field
extraction as a source-level function of a `PackedSlotDecoder` at
the pinned bit offsets, and derives `moduleExists` = `id != 0`.

**Status:** first real derivation of the P-TOPUP-1 moduleExists past
its `moduleExistsFromMapping` naming scaffold — the check is now a
function of a named packed-decode. -/

namespace LidoSRv3.Audit.Source.SRModulePackedDecoderSource

/-- Pinned `moduleId` bit offset in the SR packed module struct. -/
def moduleIdBitOffset : Nat := 0

/-- Pinned `moduleId` bit width in the SR packed module struct. -/
def moduleIdBitWidth : Nat := 24

/-- Source-level definition of the pinned packed moduleId field
extraction. -/
def moduleIdFromPacked
    (d : LidoSRv3.Audit.Source.KeccakMappingStorageSource.PackedSlotDecoder) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.decodeField d
    moduleIdBitOffset moduleIdBitWidth

/-- Real derivation of `moduleExists`: `true` iff the packed
moduleId is nonzero. -/
def moduleExistsFromPacked
    (d : LidoSRv3.Audit.Source.KeccakMappingStorageSource.PackedSlotDecoder) : Bool :=
  decide (moduleIdFromPacked d ≠ 0)

/-- Under the pinned nonzero-moduleId premise, `moduleExistsFromPacked
= true`. Real derivation. -/
theorem moduleExistsFromPacked_true_of_nonzero
    {d : LidoSRv3.Audit.Source.KeccakMappingStorageSource.PackedSlotDecoder}
    (hNonzero : d.extract moduleIdBitOffset moduleIdBitWidth ≠ 0) :
    moduleExistsFromPacked d = true := by
  simp [moduleExistsFromPacked, moduleIdFromPacked,
        LidoSRv3.Audit.Source.KeccakMappingStorageSource.decodeField, hNonzero]

end LidoSRv3.Audit.Source.SRModulePackedDecoderSource
