import LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-TOKEN-1 bounded withdrawal-request ownership custody parent

One named conclusion over the pinned WithdrawalQueue request surface at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.  For every
minting function that binds a fresh request to its created owner, every
nonzero caller, every supplied owner, every amount, and **every chain of later
`transferFrom` hops that executed**, the composed slice yields:

1. the two-sided `_checkWithdrawalRequestAmount` bound (lines 395--402);
2. the line-130 `msg.sender` fallback as the exact created owner;
3. an owner that is never the zero address after any number of hops; and
4. an owner-operated authorization obligation on every executed hop.

**This is not a broad ERC-20 or token guarantee.**  `approve`, allowance
state, `STETH.transferFrom` at line 134, `getSharesByPooledEth` at line 376,
`_enqueue` and request-id storage at line 378, events at lines 380 and 253,
`claimWithdrawals*` / finalization / redemption, `requestWithdrawalsWstETH`,
unwrap and permit, `_checkResumed` at line 129, whole-transaction rollback,
the approved-operator and `isApprovedForAll` branches at line 242, the
request-id validity and claimed checks at lines 233 and 236, the owner-indexed
`EnumerableSet` updates at lines 250--251, and multi-item request lists are
all unmodeled.  See `audit/P-TOKEN-1-T2-SCOPE.md`.
-/

namespace LidoSRv3.Audit.Guarantees.PToken1

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount
  (minStethWithdrawalAmount maxStethWithdrawalAmount checkedWithdrawalRequestAmount)
open LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl
  (resolvedOwner requestWithdrawalsSingleControl)
open LidoSRv3.Audit.Source.AddressTransferCorrespondence (State sourceTransfer)
open LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody

def guarantee : Guarantee := ⟨.pToken1, [.model, .source]⟩

/-- **P-TOKEN-1 parent.**  The bounded request-ownership custody invariant for
the pinned creation prefix composed with the owner-operated custody hop. -/
theorem request_owner_custody_invariant :
    RequestOwnerCustodyInvariant requestWithdrawalsSingleControl sourceTransfer := by
  intro mint hMint caller suppliedOwner amount owner steps final hCaller hCreate hChain
  unfold requestWithdrawalsSingleControl at hCreate
  split at hCreate
  · rename_i hAmount
    have hBounds : minStethWithdrawalAmount ≤ amount ∧
        amount ≤ maxStethWithdrawalAmount := by
      simpa [checkedWithdrawalRequestAmount] using hAmount
    have hOwner : owner = resolvedOwner caller suppliedOwner := by
      injection hCreate with hOwner
      exact hOwner.symm
    have hStart : (mint owner).owner ≠ 0 := by
      rw [hMint owner, hOwner]
      exact resolvedOwner_ne_zero caller suppliedOwner hCaller
    obtain ⟨hFinal, hSteps⟩ := custody_chain_preserved steps (mint owner) final hStart hChain
    exact ⟨hBounds.1, hBounds.2, hOwner, hFinal, hSteps⟩
  · cases hCreate

/-- Non-vacuity: the parent's premises are inhabited by a concrete two-hop
custody chain at the pinned minimum amount, so the conclusion is not reached
by an empty antecedent. -/
theorem custody_premises_inhabited :
    requestWithdrawalsSingleControl 7 0 minStethWithdrawalAmount = .proceeds 7 ∧
      applySteps sourceTransfer { owner := 7, approved := 9 }
          [⟨7, 7, 3⟩, ⟨3, 3, 5⟩] = some { owner := 5, approved := 0 } := by
  constructor
  · decide
  · decide

/-- Non-vacuity: an explicitly supplied nonzero owner is also inhabited, and
its custody chain is likewise nonempty. -/
theorem supplied_owner_premises_inhabited :
    requestWithdrawalsSingleControl 7 4 maxStethWithdrawalAmount = .proceeds 4 ∧
      applySteps sourceTransfer { owner := 4, approved := 9 } [⟨4, 4, 6⟩] =
        some { owner := 6, approved := 0 } := by
  refine ⟨?_, by decide⟩
  simp [requestWithdrawalsSingleControl, checkedWithdrawalRequestAmount,
    resolvedOwner, minStethWithdrawalAmount, maxStethWithdrawalAmount]

end LidoSRv3.Audit.Guarantees.PToken1
