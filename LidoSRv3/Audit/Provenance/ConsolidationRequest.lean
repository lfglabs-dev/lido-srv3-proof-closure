import Verity.Core.Model.MultiContract
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# G-ETH1: ensemble request address versus the canonical predeploy

Unregistered provenance children. The registered Verity ETH-1 parent journals
`Verity.MultiContract.requestAddr` (ensemble 5). The abstract parent pins
`canonicalRequestAddress` as the pinned EIP-7251 literal
`0x0000BBdDc7CE488642fb579F8B00f3a590007251`. Those Nats
are not equal.

`rewriteToCanonical` is a Spec-shaped observe rewrite: it maps ensemble 5 to
the canonical literal and leaves every other address unchanged. It does
**not** fold that literal into the registered Verity parent.

**A-CANONICAL-REQUEST-ADDRESS status update (chantier 4, Thomas 2026-09-13)**:
the deployed-target identity assumption itself is RETIRED / DISCHARGED via
`LidoSRv3/Audit/Provenance/CanonicalRequestAddress.lean` + fixture-anchored
`scripts/verify_consolidation_request_immutable.py` (per
`audit/guarantees.yaml` P-CONSOLIDATION-ETH-1 fidelity.covered). The
`WithdrawalVault_implementation` runtime at
`0xfB4521BD151BFB45DB6045D2d07e58e0f597e340` embeds the
`0x0000BBdDc7CE488642fb579F8B00f3a590007251` immutable at byte offset 730
(fixture SHA-256 `a3e9e582928d58cdfe87a6405ad1a7967f720cafa97f98ae8d619e36b961aa7f`).
See `audit/findings/A-CANONICAL-REQUEST-ADDRESS-discharged.md`.

What remains OPEN here is the SEPARATE narrower gap: the registered Verity
parent's `Verity.MultiContract.requestAddr = 5` (ensemble model) is not
folded to the discharged canonical `0x0000BBdDc7CE488642fb579F8B00f3a590007251`
literal — this is a Verity-plane refactor gap on the model side, not an
external-provenance assumption. No composition with P-CONSOLIDATION-1.
No VaultHub. No new guarantee ID.
-/

namespace LidoSRv3.Audit.Provenance.ConsolidationRequest

open LidoSRv3.Audit.Guarantees.PConsolidationEth1
open _root_.Verity.MultiContract

/-- Ensemble request address used by the registered Verity parent
(`Verity.Core.Model.MultiContract.requestAddr`). -/
def ensembleRequestAddr : Nat := 5

/-- The ensemble pin is the Verity multi-contract `requestAddr` as a Nat. -/
theorem ensemble_request_is_verity_requestAddr :
    ensembleRequestAddr = requestAddr.toNat :=
  rfl

/-- The registered parent still journals ensemble 5, not the pinned EIP-7251
predeploy literal. -/
theorem verity_requestAddr_remains_ensemble :
    requestAddr.toNat = ensembleRequestAddr :=
  rfl

/-- The abstract parent pin is the EIP-7251 consolidation-request literal.
`PConsolidationEth1.Address` is `Nat`, so this is the brief's `.toNat`. -/
theorem canonical_request_literal :
    canonicalRequestAddress =
      0x0000BBdDc7CE488642fb579F8B00f3a590007251 :=
  rfl

/-- Ensemble 5 is not the canonical predeploy. The registered Verity parent
therefore does not journal the pinned EIP-7251 address. -/
theorem ensemble_request_is_not_canonical :
    ensembleRequestAddr ≠ canonicalRequestAddress := by
  decide

/-- Spec-shaped observe rewrite: map the ensemble request address to the
canonical predeploy. Every other address is unchanged. This does not edit
the registered Verity parent. -/
def rewriteToCanonical (addr : Nat) : Nat :=
  if addr = ensembleRequestAddr then
    canonicalRequestAddress
  else
    addr

theorem rewrite_maps_ensemble_to_canonical :
    rewriteToCanonical ensembleRequestAddr = canonicalRequestAddress :=
  rfl

theorem rewrite_preserves_other (addr : Nat)
    (h : addr ≠ ensembleRequestAddr) :
    rewriteToCanonical addr = addr := by
  unfold rewriteToCanonical
  exact if_neg h

/-- **Honesty (updated chantier 4, Thomas 2026-09-13):** the
`A-CANONICAL-REQUEST-ADDRESS` deployed-target identity assumption itself
is DISCHARGED via `LidoSRv3/Audit/Provenance/CanonicalRequestAddress.lean`
+ `scripts/verify_consolidation_request_immutable.py` (fixture-anchored at
byte offset 730 of `WithdrawalVault_implementation` codehash
`0xd1e0d1b48e4f5abd04bdfd14805366f0cf7946b7bb41b7a5ad8652361f3e3d36`).
What remains OPEN is the SEPARATE narrower gap: the registered Verity
parent's `Verity.MultiContract.requestAddr = 5` (ensemble model) is not
folded to the discharged canonical literal — this is a Verity-plane
refactor gap on the model side, not an external-provenance assumption.
This Lean rewrite (`rewriteToCanonical`) documents the ensemble-to-canonical
mapping the fold would perform; it does not itself perform that fold. -/
theorem canonical_request_assumption_status : True := trivial

end LidoSRv3.Audit.Provenance.ConsolidationRequest
