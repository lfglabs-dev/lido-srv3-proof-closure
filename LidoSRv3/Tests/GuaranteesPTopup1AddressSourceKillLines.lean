import LidoSRv3.Audit.Guarantees.PTopup1

/-!
Kill-lines pinning the P-TOPUP-1 address-provenance impossibility
witnesses. These re-state the module's two headline theorems for the
constructor-span provenance argument, plus the concrete witness input
and the guarantee-plane frozen shape.
-/

namespace LidoSRv3.Tests.GuaranteesPTopup1AddressSourceKillLines

open LidoSRv3.Audit.Guarantees.PTopup1
open LidoSRv3.Audit.Guarantees

/-! ## Guarantee-plane declaration -/

theorem guarantee_id : guarantee.id = Id.pTopup1 := rfl

theorem guarantee_checkedLayers :
    guarantee.checkedLayers =
      [CheckedLayer.model, CheckedLayer.abstractTx,
       CheckedLayer.source, CheckedLayer.verityTx] := rfl

/-! ## The pinned canonical value is exactly Mainnet Beacon deposit. -/

theorem canonicalBeaconDepositAddress_pinned :
    canonicalBeaconDepositAddress =
      0x00000000219ab540356cBB839Cbe05303d7705Fa := by
  decide

/-! ## The concrete witness admitted by the source constructor. -/

theorem wrongBeaconConstructorInput_depositContract :
    wrongBeaconConstructorInput.depositContract = 0xDEAD := rfl

theorem wrongBeaconConstructorInput_admitted :
    PinnedTopupConstructorAdmitted wrongBeaconConstructorInput :=
  pinned_constructor_span_does_not_determine_beacon_address.1

theorem wrongBeaconConstructorInput_wrong :
    wrongBeaconConstructorInput.depositContract ≠
      canonicalBeaconDepositAddress :=
  pinned_constructor_span_does_not_determine_beacon_address.2

/-! ## Kernel-checked source-only impossibility, kill-line restated. -/

theorem constructor_span_does_not_determine_beacon_restated :
    PinnedTopupConstructorAdmitted wrongBeaconConstructorInput ∧
      wrongBeaconConstructorInput.depositContract ≠
        canonicalBeaconDepositAddress :=
  pinned_constructor_span_does_not_determine_beacon_address

theorem no_source_only_beacon_address_derivation_restated :
    ¬ (∀ input : TopupConstructorInput,
        PinnedTopupConstructorAdmitted input →
          input.depositContract = canonicalBeaconDepositAddress) :=
  no_source_only_beacon_address_derivation

/-! ## Constructor admission predicate: zero rejected, canonical accepted. -/

theorem admission_rejects_zero :
    ¬ PinnedTopupConstructorAdmitted { depositContract := 0 } := by
  intro h; exact h rfl

theorem admission_accepts_canonical :
    PinnedTopupConstructorAdmitted
      { depositContract := canonicalBeaconDepositAddress } := by
  unfold PinnedTopupConstructorAdmitted
  decide

end LidoSRv3.Tests.GuaranteesPTopup1AddressSourceKillLines
