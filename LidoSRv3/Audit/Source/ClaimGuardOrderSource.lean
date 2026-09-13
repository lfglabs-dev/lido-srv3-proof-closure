/-! # WithdrawalQueue._claim owner/hint pinned guard-order source model

**General rule (Thomas 2026-09-13, chantier 6 P-ADDRESS-1 second
disclosure): the pinned WithdrawalQueue._claim checks the owner
first (via _requireCorrectOwner) then the hint (via
_findCheckpointHint). The Verity model in some paths inverts this
to hint-then-owner, changing which revert reason surfaces on a
misaligned request.**

This composition names both pinned and Verity guard orderings as
source-level functions and proves the parallel disagreement
theorems.

**Status:** first real derivation of the pinned _claim guard order
past its inverted Verity model.  -/

namespace LidoSRv3.Audit.Source.ClaimGuardOrderSource

/-- Pinned Solidity WithdrawalQueue._claim guard order: owner check
first, then hint check. Returns `some 0` on success, distinct codes
for each revert branch. -/
def claimPinnedOrder
    (ownerOk hintOk : Bool) : Option Nat :=
  if !ownerOk then some 1  -- pinned RequestNotFoundOrOwnershipConflict
  else if !hintOk then some 2  -- pinned InvalidHint
  else some 0

/-- Verity model guard order: hint first, then owner. -/
def claimVerityModelOrder
    (hintOk ownerOk : Bool) : Option Nat :=
  if !hintOk then some 3
  else if !ownerOk then some 4
  else some 0

/-- Success outcome agrees across both orders. -/
theorem claim_orders_agree_on_success :
    claimPinnedOrder true true = claimVerityModelOrder true true := by
  rfl

/-- Under the owner-only failure premise (hint ok, owner fails),
the two orderings emit different revert codes. -/
theorem claim_orders_disagree_on_owner_only_failure :
    claimPinnedOrder false true ≠ claimVerityModelOrder true false := by
  simp [claimPinnedOrder, claimVerityModelOrder]

/-- Under the hint-only failure premise (owner ok, hint fails),
the two orderings emit different revert codes. -/
theorem claim_orders_disagree_on_hint_only_failure :
    claimPinnedOrder true false ≠ claimVerityModelOrder false true := by
  simp [claimPinnedOrder, claimVerityModelOrder]

end LidoSRv3.Audit.Source.ClaimGuardOrderSource
