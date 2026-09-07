import LidoSRv3.Audit.Source.TrioAlloc2.Word

/-!
Decoded candidate step, transcribed from pinned
contracts/common/lib/MinFirstAllocationStrategy.sol:63–107 at
17005714f151e5502c559932319a3f2f74ac2436.
Lists represent decoded arrays. Nat scan positions are ghost traversal indices;
relating them to bounded Solidity indices and byte memory remains an obligation.
The first scan finishes before the second scan begins. No eager length guard.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2

structure Candidate where
  index : Nat
  allocation : Word
  count : Word
  deriving DecidableEq, Repr

/-- Recursion consumes buckets only: surplus capacities are never read. -/
def firstScan (buckets capacities : List Word) (index : Nat)
    (candidate : Candidate) : Result Candidate :=
  match buckets with
  | [] => .ok candidate
  | bucket :: tail =>
    match capacities with
    | [] => .error .arrayBounds
    | capacity :: rest => do
      let next ←
        if bucket.val ≥ capacity.val then pure candidate
        else if candidate.allocation.val > bucket.val then
          pure { index, allocation := bucket, count := one }
        else if candidate.allocation.val = bucket.val then do
          let count ← checkedAdd candidate.count one
          pure { candidate with count }
        else pure candidate
      firstScan tail rest (index + 1) next

def secondScan (buckets capacities : List Word) (best upper : Word) : Result Word :=
  match buckets with
  | [] => .ok upper
  | bucket :: tail =>
    match capacities with
    | [] => .error .arrayBounds
    | capacity :: rest =>
      let next :=
        if bucket.val ≥ capacity.val then upper
        else if bucket.val > best.val && bucket.val < upper.val then bucket
        else upper
      secondScan tail rest best next

structure StepOutput where
  amount : Word
  buckets : List Word
  deriving DecidableEq, Repr

def step (buckets capacities : List Word) (demand : Word) : Result StepOutput := do
  if demand.val = 0 then return { amount := zero, buckets }
  let candidate ← firstScan buckets capacities 0
    { index := buckets.length, allocation := maxWord, count := zero }
  if candidate.count.val = 0 then return { amount := zero, buckets }
  let upper ← secondScan buckets capacities candidate.allocation maxWord
  let share ← if candidate.count.val > 1 then ceilDiv demand candidate.count else pure demand
  let capacity ← match capacities[candidate.index]? with
    | none => .error .arrayBounds
    | some capacity => .ok capacity
  let space ← checkedSub (minWord upper capacity) candidate.allocation
  let amount := minWord share space
  let previous ← match buckets[candidate.index]? with
    | none => .error .arrayBounds
    | some previous => .ok previous
  let updated ← checkedAdd previous amount
  return { amount, buckets := buckets.set candidate.index updated }

theorem step_zero_demand (buckets capacities : List Word) :
    step buckets capacities zero = .ok { amount := zero, buckets } := by
  rfl

theorem firstScan_empty (capacities : List Word) (i : Nat) (c : Candidate) :
    firstScan [] capacities i c = .ok c := rfl

theorem firstScan_short_first (b : Word) (bs : List Word) (i : Nat) (c : Candidate) :
    firstScan (b :: bs) [] i c = .error .arrayBounds := rfl

end LidoSRv3.Audit.Source.TrioAlloc2
