/-! # ConsolidationGateway msgValue = n*fee source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
ConsolidationGateway Bus.lean:203 `msgValue = n * fee` semantics —
chantier 1 A-CONSOLIDATION-GATEWAY-NONZERO reinstatement.)**

Chantier 1 (per mandate): the P-CONSOLIDATION-1 assumption
A-CONSOLIDATION-GATEWAY-NONZERO needs to be reinstated. Bus.lean:203
passes a free `msgValue` to the vault; the vault receives `n * fee`,
which is zero when the EIP-7251 fee is zero. The "discharged by #263"
claim in fidelity.covered is false.

This composition names the pinned relationship `msgValue = n * fee`
as a source-level function, plus the nonzero/zero predicate that
distinguishes the two cases.

**Status:** first real derivation of the pinned msgValue semantics
past a free Nat — the vault-received value is a named source-level
function of (n, fee), not a caller-supplied opaque. -/

namespace LidoSRv3.Audit.Source.ConsolidationMsgValueSource

/-- Source-level definition of the pinned msgValue passed to the
vault: n * fee. -/
def msgValueForBatch (n fee : Nat) : Nat := n * fee

/-- Under the pinned "fee ≠ 0 and n ≠ 0" premise, msgValue is
nonzero. Real derivation. -/
theorem msgValueForBatch_pos_of_nonzero
    {n fee : Nat} (hN : 0 < n) (hFee : 0 < fee) :
    0 < msgValueForBatch n fee := by
  unfold msgValueForBatch
  exact Nat.mul_pos hN hFee

/-- Under the "fee = 0" degeneracy, msgValue is zero regardless of
n. This is the A-CONSOLIDATION-GATEWAY-NONZERO edge case. -/
theorem msgValueForBatch_zero_of_fee_zero
    (n : Nat) :
    msgValueForBatch n 0 = 0 := by
  unfold msgValueForBatch
  omega

/-- Under the "n = 0" degeneracy (empty batch), msgValue is zero
regardless of fee. -/
theorem msgValueForBatch_zero_of_empty_batch
    (fee : Nat) :
    msgValueForBatch 0 fee = 0 := by
  unfold msgValueForBatch
  omega

end LidoSRv3.Audit.Source.ConsolidationMsgValueSource
