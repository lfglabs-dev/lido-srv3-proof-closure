import Verity.Core.Model.MultiContract
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# G-ETH1: ensemble request address versus the canonical predeploy

Unregistered provenance children. The registered Verity ETH-1 parent journals
`Verity.MultiContract.requestAddr` (ensemble 5). The abstract parent pins
`canonicalRequestAddress` as the EIP-7251 literal `0x00…7251`. Those Nats
are not equal.

`rewriteToCanonical` is a Spec-shaped observe rewrite: it maps ensemble 5 to
the canonical literal and leaves every other address unchanged. It does
**not** fold that literal into the registered Verity parent and does
**not** discharge `A-CANONICAL-REQUEST-ADDRESS` (deployed-target identity).
No composition with P-CONSOLIDATION-1. No VaultHub. No new guarantee ID.
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

/-- The registered parent still journals ensemble 5, not `0x00…7251`. -/
theorem verity_requestAddr_remains_ensemble :
    requestAddr.toNat = ensembleRequestAddr :=
  rfl

/-- The abstract parent pin is the EIP-7251 consolidation-request literal.
`PConsolidationEth1.Address` is `Nat`, so this is the brief's `.toNat`. -/
theorem canonical_request_literal :
    canonicalRequestAddress =
      0x0000000000000000000000000000000000007251 :=
  rfl

/-- Ensemble 5 is not the canonical predeploy. The registered Verity parent
therefore does not journal `0x00…7251`. -/
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

/-- Honesty: `A-CANONICAL-REQUEST-ADDRESS` is deployed-target identity, not
this Lean rewrite. The assumption remains OPEN. -/
theorem canonical_request_assumption_remains_open : True := trivial

end LidoSRv3.Audit.Provenance.ConsolidationRequest
