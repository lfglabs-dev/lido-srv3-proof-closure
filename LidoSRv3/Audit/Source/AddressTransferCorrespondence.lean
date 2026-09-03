/-!
# P-ADDRESS-1 bounded pinned-source transfer slice

This module models the owner-operated branch of
`WithdrawalQueueERC721.transferFrom` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`, lines 218--253.
It covers the caller/owner check, approval deletion, and request-owner handoff.
The owner-indexed enumerable sets and emitted event are outside this bounded
slice and therefore remain open for the parent guarantee.
-/

namespace LidoSRv3.Audit.Source.AddressTransferCorrespondence

/-- The state touched by the bounded owner-operated transfer slice. -/
structure State where
  owner : Nat
  approved : Nat
  deriving Repr, DecidableEq

/-- MODEL plane: the address-bearing transition, independent of Solidity syntax. -/
def modelTransfer (caller fromAddr to : Nat) (s : State) : Option State :=
  if to = 0 then none
  else if to = fromAddr then none
  else if s.owner != fromAddr then none
  else if caller != fromAddr then none
  else some { owner := to, approved := 0 }

/-- SOURCE plane: lines 231--248 on the owner-operated branch of `_transfer`.
The two definitions are kept separate so the correspondence theorem is the
reviewable boundary rather than a registry status assertion. -/
def sourceTransfer (caller fromAddr to : Nat) (s : State) : Option State :=
  if to = 0 then none
  else if to = fromAddr then none
  else if s.owner != fromAddr then none
  else if caller != fromAddr then none
  else some { owner := to, approved := 0 }

/-- Equality of two audit-authored definitions for the bounded pinned-source-
shaped branch. This `rfl` is not Solidity extraction or compiler refinement. -/
theorem source_refines_model (caller fromAddr to : Nat) (s : State) :
    sourceTransfer caller fromAddr to s = modelTransfer caller fromAddr to s := rfl

/-- The concrete caller swap used by the bounded witness. -/
def swap12 (address : Nat) : Nat :=
  if address = 1 then 2 else if address = 2 then 1 else address

def renameState12 (s : State) : State :=
  { owner := swap12 s.owner, approved := swap12 s.approved }

/-- Concrete address-renaming witness. Recipient 3 and approval 9 are fixed by
the 1/2 swap; only caller, `from`, and the pre-state owner change. -/
theorem source_post_state_equivariant_witness :
    sourceTransfer 1 1 3 { owner := 1, approved := 9 } =
      some { owner := 3, approved := 0 } ∧
    sourceTransfer 2 2 (swap12 3) (renameState12 { owner := 1, approved := 9 }) =
      (sourceTransfer 1 1 3 { owner := 1, approved := 9 }).map renameState12 := by decide

/-- Mutant controls: changing fixed recipient 3 to 4, or fixed approval 9 to 8,
cannot be presented as the result of the 1/2 address permutation. -/
theorem recipient_stomp_not_swap : swap12 3 != 4 := by decide
theorem approval_stomp_not_swap : swap12 9 != 8 := by decide

/-- Privileged-owner mutant: replacing the caller-relative check by a fixed
actor rejects the renamed caller, so the witness is discrimination-sensitive. -/
def fixedCallerMutant (caller fromAddr to : Nat) (s : State) : Option State :=
  if caller != 1 then none else modelTransfer caller fromAddr to s

theorem fixed_caller_mutant_rejected :
    fixedCallerMutant 1 1 3 { owner := 1, approved := 9 } =
      some { owner := 3, approved := 0 } ∧
    fixedCallerMutant 2 2 3 { owner := 2, approved := 9 } = none := by decide

end LidoSRv3.Audit.Source.AddressTransferCorrespondence
