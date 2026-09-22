import LidoSRv3.Audit.Guarantees.PConsolidation1GatewayAdmission
import audit.trio.consolidation.GatewayWitnessAdmission

/-! Step 3a of the "not proven" cleanup (2026-09-18): the whole-prefix
gateway admission. The displayed executor starts after the gateway's
DSM/locator/witness prefix (ConsolidationGateway.sol:201-207); this module
registers the executor that runs that prefix on the entry World first.

Assumptions stated, not hidden: SHA-256 is the opaque engine FFI (A-SHA256-FFI,
`shaOutput`; the source's returndata-size guards are executed, ShaWidth is not
needed by this typed fold) and the beacon root is whatever the accepted
StaticCall.External returns for the pinned BEACON_ROOTS request. EIP-4788
authenticity is an explicit hypothesis of the second theorem. -/
namespace LidoSRv3.Audit.Guarantees.PConsolidation1
open Source.TrioReserve1 Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Whole-prefix registered parent. A committed gateway run derives the prior
modifier admission, the accepted count, the executed DSM/Lido preconditions,
the executed locator vault read, and for every request group the passed
`_validatePubKeyWCProof` check of its target pubkey and the read vault's 0x02
credentials against the beacon root received from the EIP-4788 STATICCALL
(slot/proposer sibling, 48-byte key, fork-aware generalized index, P-SSZ-1's
Merkle branch under the opaque pair digest), in addition to the complete
GatewayVaultEffects on that vault. Any failure, in the prefix, in a witness
check or in the retained executor, restores the entry World. -/
theorem gateway_witness_admission_live_success_and_revert
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (cfg : Source.SszWrapperIndex.Configuration)
    (msgValue : Live.Word) (groups : List WitnessProof.WitnessGroup) (before : World) :
    let result := GatewayWitnessAdmission.execute callee sexternal ctx locator gateway inbox
      recipient cfg msgValue groups before
    match result.outcome with
    | .ok _ => ∃ vault,
        GatewayAdmission.Admitted sexternal ctx locator msgValue
          (GatewayWitnessAdmission.bytesOf groups) before vault ∧
        (∀ g ∈ groups, WitnessProof.Passed sexternal cfg ctx
          (WitnessProof.credentialsWord vault) g.witness before) ∧
        GatewayVaultEffects callee sexternal ctx vault gateway inbox recipient msgValue
          (GatewayWitnessAdmission.bytesOf groups) before ∧
        result.world = (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox
          recipient msgValue (GatewayWitnessAdmission.bytesOf groups) before).world
    | .error _ => result.world = before := by
  dsimp only
  cases h : (GatewayWitnessAdmission.execute callee sexternal ctx locator gateway inbox
      recipient cfg msgValue groups before).outcome with
  | ok value =>
      cases value
      obtain ⟨vault,⟨ha,_,hw⟩,hs,he⟩ := GatewayWitnessAdmission.execute_success
        callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before h
      refine ⟨vault,ha,hw,PConsolidationEth1.actual_physical_entry_quota_settlement_requests
        callee sexternal ctx vault gateway inbox recipient msgValue
        (GatewayWitnessAdmission.bytesOf groups) before hs,?_⟩
      rw [he]
  | «error» fault =>
      exact GatewayWitnessAdmission.failure_restores
        callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before fault h

/-- The same run under an explicit EIP-4788 authenticity hypothesis: if every
32-byte reply the accepted interpreter returns for the pinned BEACON_ROOTS
request on the entry World decodes to `beaconRoot timestamp`, then a committed
run proves, for every request group, P-SSZ-1's Merkle branch from the group's
key/credentials leaf to `beaconRoot childBlockTimestamp` at the executed
fork-aware generalized index. `beaconRoot` is a hypothesis, not a model. -/
theorem gateway_witness_admission_authentic_root
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (locator gateway inbox recipient : Address) (cfg : Source.SszWrapperIndex.Configuration)
    (msgValue : Live.Word) (groups : List WitnessProof.WitnessGroup) (before : World)
    (beaconRoot : BitVec 64 → EvmYul.UInt256)
    (hauth : ∀ timestamp data,
      (Source.SszRootCall.call sexternal ctx.self timestamp before).outcome = .ok data →
      32 ≤ data.length →
      Source.SszTypedFfiBridge.toWord (Source.SszVerifierEntry.firstWord
        (Source.SszRootCall.fromBytes data)) = beaconRoot timestamp)
    (h : (GatewayWitnessAdmission.execute callee sexternal ctx locator gateway inbox
      recipient cfg msgValue groups before).outcome = .ok ()) :
    ∃ vault,
      GatewayAdmission.Admitted sexternal ctx locator msgValue
        (GatewayWitnessAdmission.bytesOf groups) before vault ∧
      ∀ g ∈ groups, ∃ gi,
        WitnessProof.gatewayIndex cfg g.witness = .ok gi ∧
        g.witness.pubkey.length = 48 ∧
        Source.SszProofFold.Branch Source.SszProofCalldataStep.ffiPair gi.index.val
          (WitnessProof.leafDigest g.witness.pubkey (WitnessProof.credentialsWord vault))
          g.witness.proof (beaconRoot g.witness.childBlockTimestamp) := by
  obtain ⟨vault,⟨ha,_,hw⟩,_,_⟩ := GatewayWitnessAdmission.execute_success
    callee sexternal ctx locator gateway inbox recipient cfg msgValue groups before h
  refine ⟨vault,ha,fun g hg => ?_⟩
  obtain ⟨_,_,h48,gi,data,hgi,hcall,hlen,hb⟩ := hw g hg
  have hroot := hauth g.witness.childBlockTimestamp data (by rw [hcall]) hlen
  rw [hroot] at hb
  exact ⟨gi,hgi,h48,hb⟩

#print axioms gateway_witness_admission_live_success_and_revert
#print axioms gateway_witness_admission_authentic_root
end LidoSRv3.Audit.Guarantees.PConsolidation1
