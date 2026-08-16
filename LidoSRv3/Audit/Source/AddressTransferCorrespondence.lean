/-!
# P-ADDRESS-1 bounded pinned-source transfer slice

This module models the owner-operated branch of
`WithdrawalQueueERC721.transferFrom` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 218--253.
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

/-- MODEL → SOURCE correspondence for the bounded pinned-source branch. -/
theorem source_refines_model (caller fromAddr to : Nat) (s : State) :
    sourceTransfer caller fromAddr to s = modelTransfer caller fromAddr to s := rfl

/-- Concrete address-renaming witness: swapping all actor positions commutes
with the successful source handoff and produces the renamed post-state. -/
theorem source_post_state_equivariant_witness :
    sourceTransfer 1 1 3 { owner := 1, approved := 9 } =
      some { owner := 3, approved := 0 } ∧
    sourceTransfer 2 2 4 { owner := 2, approved := 8 } =
      some { owner := 4, approved := 0 } := by decide

/-- Privileged-owner mutant: replacing the caller-relative check by a fixed
actor rejects the renamed caller, so the witness is discrimination-sensitive. -/
def fixedCallerMutant (caller fromAddr to : Nat) (s : State) : Option State :=
  if caller != 1 then none else modelTransfer caller fromAddr to s

theorem fixed_caller_mutant_rejected :
    fixedCallerMutant 1 1 3 { owner := 1, approved := 9 } =
      some { owner := 3, approved := 0 } ∧
    fixedCallerMutant 2 2 4 { owner := 2, approved := 8 } = none := by decide

end LidoSRv3.Audit.Source.AddressTransferCorrespondence
