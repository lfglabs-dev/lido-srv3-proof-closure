import LidoSRv3.Audit.Source.NodeOperatorsRegistry.ExitedInvariant

/-!
Arithmetic prefix of one iteration of
[`_loadAllocatedSigningKeys`](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L833-L849).
The active count is the element already read from the Solidity memory array.
Addition wraps, equality continues before the assertion, and assertion failure
is Solidity 0.4.24 INVALID, not an Error(string) or a Solidity 0.8 Panic.
This prefix stops before SigningKeys memory writes, events, packed setters and
aggregate updates. Array access, loop execution and those effects remain separate.
-/
namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry
open TrioAlloc1

inductive AllocationAssertionFailure where
  | invalid
  deriving DecidableEq

inductive AllocatedKeyAction where
  | unchanged
  | load (start count : Word)
  deriving DecidableEq

def allocatedDepositedAfter (signing active : Word) : Word :=
  word ((packedGet signing 1).val + active.val)

def allocatedKeyPrefix (signing active : Word) :
    Except AllocationAssertionFailure AllocatedKeyAction :=
  let before := packedGet signing 3
  let after := allocatedDepositedAfter signing active
  if after = before then .ok .unchanged
  else if after.val > before.val then
    .ok (.load before (word (after.val - before.val)))
  else .error .invalid

theorem allocatedKeyPrefix_nondecreasing (signing active : Word)
    (action : AllocatedKeyAction)
    (success : allocatedKeyPrefix signing active = .ok action) :
    (packedGet signing 3).val ≤ (allocatedDepositedAfter signing active).val := by
  dsimp only [allocatedKeyPrefix] at success
  split at success
  · rename_i equal
    rw [equal]
    exact Nat.le_refl _
  · split at success
    · omega
    · cases success

/-- The source assertion detects wrapping only when the incoming local
accounting invariant holds. The equal-value branch needs that invariant too. -/
theorem allocatedKeyPrefix_no_overflow (signing active : Word)
    (action : AllocatedKeyAction)
    (consistent : (packedGet signing 1).val ≤ (packedGet signing 3).val)
    (success : allocatedKeyPrefix signing active = .ok action) :
    (packedGet signing 1).val + active.val < 2^256 := by
  have monotone := allocatedKeyPrefix_nondecreasing signing active action success
  have activeBound := active.isLt
  have exitedBound := (packedGet signing 1).isLt
  simp only [allocatedDepositedAfter, word] at monotone
  omega

/-- A loaded row's exact delta is derived from the actual wrapping prefix,
not from a checked-add replacement or an assumed post-allocation count. -/
theorem allocatedKeyPrefix_load_delta (signing active start count : Word)
    (consistent : (packedGet signing 1).val ≤ (packedGet signing 3).val)
    (success : allocatedKeyPrefix signing active = .ok (.load start count)) :
    start = packedGet signing 3 ∧ 0 < count.val ∧
      count.val + start.val = (packedGet signing 1).val + active.val := by
  have noOverflow := allocatedKeyPrefix_no_overflow signing active (.load start count)
    consistent success
  dsimp only [allocatedKeyPrefix] at success
  split at success
  · cases success
  · split at success
    · simp only [Except.ok.injEq, AllocatedKeyAction.load.injEq] at success
      rcases success with ⟨rfl, rfl⟩
      have afterBound := (allocatedDepositedAfter signing active).isLt
      simp only [allocatedDepositedAfter, word, Nat.mod_eq_of_lt noOverflow] at *
      exact ⟨True.intro, by omega, by omega⟩
    · cases success

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
