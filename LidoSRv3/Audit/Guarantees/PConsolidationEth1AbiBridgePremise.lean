import LidoSRv3.Audit.Guarantees.PConsolidation1
import LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource

/-! # P-CONSOLIDATION-ETH-1 ABI-bridge composition premise

**Chantier 2 continuation (Thomas 2026-09-13), item (a): compose the
executable gateway → vault frame boundary in a single-path bridge
statement.**

The pinned Solidity's `ConsolidationGateway.addConsolidationRequests`
(`ConsolidationGateway.sol:212-220`) forwards to the vault via:
```
withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)
```
where `totalFee = requestsCount * fee` and `fee` is the STATICCALL
result on the EIP-7251 predeploy. The vault side reads its inputs via
`readArray` over the calldata layout backed by
`sourcesBase` / `targetsBase` / `sourceLensBase` / `targetLensBase`.

The **executable-frame ABI bridge** is: under a premise that names the
ABI encoding contract crossing the frame boundary (the vault's
`readArray` decodes match the gateway's supplied lists), the vault's
observation-plane conclusion (`verity_tx_simulates_consolidation`)
follows on the gateway-supplied `Inputs`.

**Status: naming scaffold, not a full composition** — same status as
the sibling `PConsolidationEth1FeeStaticcallPremise` (fee STATICCALL)
and `PConsolidationEth1CLProofPremise` (CL-proof) modules. A full
composition additionally requires:

  - A Verity model of `abi.encodeCall(WithdrawalVault
    .addConsolidationRequests, (sourcePubkeys, targetPubkeys))`
    producing the calldata the vault-side `readArray` consumes;
  - A frame-boundary theorem: the gateway's `Contract.run` output
    state satisfies the four vault-side decode premises the
    registered parent `verity_tx_simulates_consolidation_from_gateway`
    (PR #644) needs (`hSources`, `hTargets`, `hSourceLens`,
    `hTargetLens`);
  - A `MultiContract`-level chaining that ties this frame to the
    P-CONSOLIDATION-ETH-1 registered parent
    (`verity_tx_success_and_revert_partition`).

None of the three are tree-resident yet; those residuals are named
here so the composition entry point is explicit and load-bearing on
the gateway-boundary shape rather than an isolated scaffold. -/

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1AbiBridgePremise

open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Verity.ConsolidationTx
open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.Source.ConsolidationFeeStaticcallSource

/-- **Pinned ABI-bridge shape.** A vault-side execution satisfies this
premise when the gateway-produced calldata decodes to the caller's
supplied lists. Bundles the four `readArray` decode facts the
registered parent `verity_tx_simulates_consolidation_from_gateway`
already names as premises (`hSources`, `hTargets`, `hSourceLens`,
`hTargetLens`), plus the gateway-boundary scalar linkage
(`hMsgValue`, `hFee`) that PR #644 introduces.

Under this shape, a caller has a single-path pinned assertion
covering the entire executable-frame contract between the gateway's
`abi.encodeCall` output and the vault's `readArray` input: the four
memory arrays decode to `inputs.{sources,targets,sourceLens,targetLens}`
and the two frame-boundary scalars come from `gatewayVaultBoundary
result inputs.sources.length`. -/
def PinnedAbiBridgeShape
    (result : PredeployStaticcallResult)
    (inputs : Inputs) (state : Verity.ContractState) : Prop :=
  inputs.msgValue.val = (gatewayVaultBoundary result inputs.sources.length).msgValue ∧
  inputs.fee.val = (gatewayVaultBoundary result inputs.sources.length).fee ∧
  readArray state "sources" sourcesBase inputs.sources.length = some inputs.sources ∧
  readArray state "targets" targetsBase inputs.targets.length = some inputs.targets ∧
  readArray state "sourceLens" sourceLensBase inputs.sourceLens.length = some inputs.sourceLens ∧
  readArray state "targetLens" targetLensBase inputs.targetLens.length = some inputs.targetLens

/-- **Chantier 2 (Thomas 2026-09-13) ABI-bridge derivation under the
pinned shape.** Under `PinnedAbiBridgeShape result inputs state` and
the two count/entry no-wrap premises, the P-CONSOLIDATION-1
gateway-bridge parent's conjunctive conclusion follows: (i) the
`observeFromJournal` view of `addRequestsSlotFree` equals `sourceView`,
and (ii) `inputs.msgValue.val = inputs.sources.length *
result.abiDecodedFee` (the exact-fee identity anchored on the shared
STATICCALL result). Load-bearing on the shape premise; consumes the
gateway-bridge parent from PR #644. -/
theorem eth1_abi_bridge_derived_under_pinned_shape
    (result : PredeployStaticcallResult)
    (inputs : Inputs) (state : Verity.ContractState)
    (hShape : PinnedAbiBridgeShape result inputs state)
    (hCountBound : (state.readSlot countSlot).val + inputs.sources.length <
      Verity.Core.Uint256.modulus)
    (hEntry : state.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus) :
    observeFromJournal state ((addRequestsSlotFree inputs).run state) =
      sourceView inputs (state.readSlot countSlot).val ∧
    inputs.msgValue.val = inputs.sources.length * result.abiDecodedFee := by
  obtain ⟨hMsgValue, hFee, hSources, hTargets, hSourceLens, hTargetLens⟩ :=
    hShape
  exact verity_tx_simulates_consolidation_from_gateway result inputs state
    hMsgValue hFee hCountBound hEntry hSources hTargets hSourceLens hTargetLens

end LidoSRv3.Audit.Guarantees.PConsolidationEth1AbiBridgePremise
