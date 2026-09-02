import LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody

/-!
# P-TOKEN-1 exact-parent kill-lines

Each mutant below deletes exactly one guard of the pinned source at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b` and refutes the
**same** `RequestOwnerCustodyInvariant` predicate proved for the honest
composition, so the parent is not tautological on either leg.

These regressions say nothing about approve, ERC-20 movement, redemption, or
any other token surface; they are confined to the modeled guards.
-/

namespace LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount
  (minStethWithdrawalAmount checkedWithdrawalRequestAmount)
open LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl
  (Outcome requestWithdrawalsSingleControl)
open LidoSRv3.Audit.Source.AddressTransferCorrespondence (State sourceTransfer)
open LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody

/-- The mint the honest parent's `mint` argument is instantiated with here:
it satisfies the parent's only named binding hypothesis. -/
def witnessMint (owner : Nat) : State := { owner := owner, approved := 0 }

theorem witnessMint_binds_owner : ∀ owner, (witnessMint owner).owner = owner :=
  fun _ => rfl

/-- Mutant A: `WithdrawalQueueERC721.sol:231`'s `TransferToZeroAddress` guard
is deleted; every other guard of `_transfer` is retained verbatim. -/
def sourceTransferZeroRecipientDropped
    (caller fromAddr to : Nat) (s : State) : Option State :=
  if to = fromAddr then none
  else if s.owner != fromAddr then none
  else if caller != fromAddr then none
  else some { owner := to, approved := 0 }

/-- Exact-parent kill-line A. The owner may burn custody of a live request to
the zero address, refuting the same universal custody invariant. -/
theorem zero_recipient_drop_kill_line_refutes_exact_parent :
    ¬ RequestOwnerCustodyInvariant
        requestWithdrawalsSingleControl sourceTransferZeroRecipientDropped := by
  intro h
  have hStep := h witnessMint witnessMint_binds_owner 7 0 minStethWithdrawalAmount 7
    [⟨7, 7, 0⟩] { owner := 0, approved := 0 } (by decide) (by decide) (by decide)
  exact hStep.2.2.2.1 rfl

/-- Mutant B: `WithdrawalQueueERC721.sol:241-245`'s caller authorization is
deleted; the zero-recipient, self-transfer, and owner guards are retained. -/
def sourceTransferCallerAuthorizationDropped
    (_caller fromAddr to : Nat) (s : State) : Option State :=
  if to = 0 then none
  else if to = fromAddr then none
  else if s.owner != fromAddr then none
  else some { owner := to, approved := 0 }

/-- Exact-parent kill-line B. An unrelated account moves another account's
request, refuting the parent's owner-operated hop obligation. -/
theorem caller_authorization_drop_kill_line_refutes_exact_parent :
    ¬ RequestOwnerCustodyInvariant
        requestWithdrawalsSingleControl sourceTransferCallerAuthorizationDropped := by
  intro h
  have hStep := h witnessMint witnessMint_binds_owner 7 0 minStethWithdrawalAmount 7
    [⟨9, 7, 3⟩] { owner := 3, approved := 0 } (by decide) (by decide) (by decide)
  have hOp := hStep.2.2.2.2
  unfold OwnerOperated at hOp
  exact absurd hOp.2.1 (by decide)

/-- Mutant D: `WithdrawalQueueERC721.sol:238`'s owner check
(`_getRequestOwner(_requestId) == _from`) is deleted; the zero-recipient,
self-transfer, and caller-authorization guards are retained verbatim. -/
def sourceTransferOwnerGuardDropped
    (caller fromAddr to : Nat) (s : State) : Option State :=
  if to = 0 then none
  else if to = fromAddr then none
  else if caller != fromAddr then none
  else some { owner := to, approved := 0 }

/-- Exact-parent kill-line D. Account 5 moves account 7's request from a state
it does not own; the hop's `fromAddr` differs from the pre-state owner, which
refutes the parent's `OwnerOperated` conjunct. A per-step conjunct that did
not look at the pre-state owner could not be refuted by this mutant. -/
theorem owner_guard_drop_kill_line_refutes_exact_parent :
    ¬ RequestOwnerCustodyInvariant
        requestWithdrawalsSingleControl sourceTransferOwnerGuardDropped := by
  intro h
  have hStep := h witnessMint witnessMint_binds_owner 7 0 minStethWithdrawalAmount 7
    [⟨5, 5, 9⟩] { owner := 9, approved := 0 } (by decide) (by decide) (by decide)
  have hOp := hStep.2.2.2.2
  unfold OwnerOperated at hOp
  exact absurd hOp.1 (by decide)

/-- Mutant C: `WithdrawalQueue.sol:130`'s `msg.sender` owner fallback is
deleted; the two-sided amount check at lines 395-402 is retained. -/
def requestWithdrawalsSingleControlOwnerFallbackDropped
    (_caller suppliedOwner amount : Nat) : Outcome :=
  if checkedWithdrawalRequestAmount amount then .proceeds suppliedOwner
  else .revertedAmount

/-- Exact-parent kill-line C. Without the fallback a request is created
ownerless, refuting the same parent on the creation leg. -/
theorem owner_fallback_drop_kill_line_refutes_exact_parent :
    ¬ RequestOwnerCustodyInvariant
        requestWithdrawalsSingleControlOwnerFallbackDropped sourceTransfer := by
  intro h
  have hStep := h witnessMint witnessMint_binds_owner 7 0 minStethWithdrawalAmount 0
    [] { owner := 0, approved := 0 } (by decide) (by decide) (by decide)
  exact hStep.2.2.2.1 rfl

end LidoSRv3.Tests.WithdrawalQueueRequestCustodyMutants
