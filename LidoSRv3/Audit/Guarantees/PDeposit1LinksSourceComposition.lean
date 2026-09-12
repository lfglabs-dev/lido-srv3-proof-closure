import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Source.DepositLinksSource

/-! # P-DEPOSIT-1 registered abstract parent — LinksSource-derived composition

**General rule (Thomas 2026-09-12), applied to DEPOSIT-1 LinksSource.**

The prior registered Verity parent
`LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit`
takes `hLink : NFrame.LinksSource cfg inp inputs` as a caller
hypothesis — a free premise about the caller's construction of
`inputs.batches`. Per the general rule (Thomas 2026-09-12): identify
in the pinned Solidity the source of that input (the router's
per-batch amount computation and pubkey splitting) and compose the
already-integrated grok #405 consumer into the parent's ENUNCE so
`LinksSource` is DERIVED, not a free hypothesis.

The pinned router (`StakingRouter.sol:686-756` `topUp` +
`StakingRouter.sol:966-967` splitting `_pubkeys` into per-batch chunks
via `BeaconChainDepositor.sol:43-45` `PUBLIC_KEY_LENGTH = 48`)
computes per-batch amounts as `keys * cfg.depositSize` and validates
`publicKeysBatchLength = 48 * keys`. The `LidoSRv3.Audit.Source.
DepositLinksSource` module (grok #405, integrated as PR #415)
proves `nframe_linksSource_of_router_fields`: given a router-shape
input, `NFrame.LinksSource` is derivable.

The composition below is the new registered abstract parent of
P-DEPOSIT-1 (per general rule Thomas 2026-09-12); the old
`verity_tx_composes_nframe_deposit` is retained as an unregistered
lemma used inside this composition.

Residual (in `fidelity.missing`): the router-fields premise
(`hSize`, `hDerived`, `hAmounts`) assumes the caller invokes the
pinned `StakingRouter.topUp` at 17005714 with the fields as the
router constructs them. Under `StakingRouter.topUp:686`
(`_checkAppAuth(_getTopUpGateway())`) the top-up gateway is the only
admitted caller today; module `allocateDeposits` policy still is
open. -/

namespace LidoSRv3.Audit.Guarantees.PDeposit1.NFrame

open LidoSRv3.Audit.SolidityDeposit

/-- **P-DEPOSIT-1, Verity plane (general rule Thomas 2026-09-12):
new registered Verity parent under the router-shape premise.**

Instead of taking `hLink : LinksSource cfg inp inputs` as a free
premise, this composition takes the three router-shape hypotheses
(`hSize`, `hDerived`, `hAmounts`) that the pinned router construction
enforces, and derives `LinksSource` via the already-integrated grok
#405 consumer `nframe_linksSource_of_router_fields`. The four
registered conjuncts of `verity_tx_composes_nframe_deposit` are then
delivered on that derived link.

The old `verity_tx_composes_nframe_deposit` is retained in
`PDeposit1.lean` as unregistered lemma used inside this composition. -/
theorem verity_tx_composes_nframe_deposit_under_router_shape
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : LidoSRv3.Audit.Verity.DepositNFrameTx.Inputs)
    (entry : _root_.Verity.ContractState)
    (hSize : inputs.depositSize.val = cfg.depositSize)
    (hDerived :
      LidoSRv3.Audit.Source.DepositLinksSource.derivedKeys cfg
          inp.publicKeysBatchLength =
        some (LidoSRv3.Audit.Verity.DepositNFrameTx.exactKeys inputs.batches))
    (hAmounts : ∀ batch ∈ inputs.batches,
      LidoSRv3.Audit.Source.DepositLinksSource.routerShapedAmount cfg batch)
    (hPre : LidoSRv3.Audit.Verity.DepositNFrameTx.Preconditions inputs entry) :
    (CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp) ∧
      ExecutesNFrameJournal inputs entry ∧
      ExactTotalIsSourcePush cfg inp inputs ∧
      ConservingDeploymentPullsExactTotal cfg inp inputs := by
  have hLink : LinksSource cfg inp inputs :=
    LidoSRv3.Audit.Source.DepositLinksSource.nframe_linksSource_of_router_fields
      cfg inp inputs hSize hDerived hAmounts
  exact verity_tx_composes_nframe_deposit cfg inp inputs entry hLink hPre

end LidoSRv3.Audit.Guarantees.PDeposit1.NFrame
