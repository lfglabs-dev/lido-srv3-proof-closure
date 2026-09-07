import LidoSRv3.Audit.Source.TrioAlloc2.RowBounds

/-!
Pinned source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436,
contracts/0.8.25/sr/SRLib.sol:415–431. Ordered post-library conversion on decoded
separate arrays. The external-library copy relation and producer invocation are
separate boundaries; this module does not replace them with successful stubs.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion

structure Arrays where
  allocated : List Word
  newAllocations : List Word
  deriving DecidableEq, Repr

structure Output where
  totalAllocated : Word
  arrays : Arrays
  deriving DecidableEq, Repr

def read (values : List Word) (i : Nat) : Result Word :=
  match values[i]? with
  | none => .error .arrayBounds
  | some value => .ok value

/-- The counter is the exact number of remaining source for-loop iterations,
not a discretionary evaluation fuel. The index starts at zero at the entry. -/
def positiveRows : Nat → Nat → Word → Arrays → Result Arrays
  | 0, _, _, arrays => .ok arrays
  | remaining+1, i, unit, arrays => do
    let next ← read arrays.newAllocations i
    let previous ← read arrays.allocated i
    let delta ← checkedSub next previous
    let scaledDelta ← checkedMul delta unit
    let afterDelta := { arrays with allocated := arrays.allocated.set i scaledDelta }
    let nextAgain ← read afterDelta.newAllocations i
    let scaledNext ← checkedMul nextAgain unit
    positiveRows remaining (i+1) unit
      { afterDelta with newAllocations := afterDelta.newAllocations.set i scaledNext }

def zeroRows : Nat → Nat → Word → Arrays → Result Arrays
  | 0, _, _, arrays => .ok arrays
  | remaining+1, i, unit, arrays => do
    let previous ← read arrays.allocated i
    let scaled ← checkedMul previous unit
    let _ ← read arrays.newAllocations i
    let afterNext := { arrays with newAllocations := arrays.newAllocations.set i scaled }
    let _ ← read afterNext.allocated i
    zeroRows remaining (i+1) unit
      { afterNext with allocated := afterNext.allocated.set i zero }

/-- Source total multiplication occurs before any per-row reads or writes. -/
def positive (count : Nat) (unit total : Word) (arrays : Arrays) : Result Output := do
  let scaledTotal ← checkedMul total unit
  let result ← positiveRows count 0 unit arrays
  .ok ⟨scaledTotal, result⟩

/-- Zero demand still converts every original allocation and may overflow. -/
def zeroDemand (count : Nat) (unit : Word) (allocated : List Word) : Result Output := do
  let result ← zeroRows count 0 unit ⟨allocated, List.replicate count zero⟩
  .ok ⟨zero, result⟩

/-- Independent unbounded arithmetic conditions for one row conversion. -/
def RowSafe (previous next unit : Word) : Prop :=
  previous.val ≤ next.val ∧
  (next.val-previous.val)*unit.val < 2^256 ∧ next.val*unit.val < 2^256

def rowArithmetic (previous next unit : Word) : Result (Word × Word) := do
  let delta ← checkedSub next previous
  let scaledDelta ← checkedMul delta unit
  let scaledNext ← checkedMul next unit
  .ok (scaledDelta, scaledNext)

theorem rowArithmetic_success_iff (previous next unit : Word) :
    (∃ result, rowArithmetic previous next unit = .ok result) ↔ RowSafe previous next unit := by
  by_cases sub : previous.val ≤ next.val
  all_goals by_cases delta : (next.val-previous.val)*unit.val < 2^256
  all_goals by_cases scaled : next.val*unit.val < 2^256
  all_goals simp [rowArithmetic, RowSafe, checkedSub, checkedMul, sub, delta, scaled, bind, Except.bind]

theorem rowArithmetic_values (previous next unit : Word) (result : Word × Word)
    (executed : rowArithmetic previous next unit = .ok result) :
    result.1.val = (next.val-previous.val)*unit.val ∧ result.2.val = next.val*unit.val := by
  unfold rowArithmetic at executed
  cases sub : checkedSub next previous with
  | error e => simp [sub, bind, Except.bind] at executed
  | ok delta =>
    have difference := checkedSub_value next previous delta sub
    cases mulDelta : checkedMul delta unit with
    | error e => simp [sub, mulDelta, bind, Except.bind] at executed
    | ok scaledDelta =>
      cases mulNext : checkedMul next unit with
      | error e => simp [sub, mulDelta, mulNext, bind, Except.bind] at executed
      | ok scaledNext =>
        simp only [sub, mulDelta, mulNext, bind, Except.bind, Except.ok.injEq] at executed
        cases executed
        exact ⟨by rw [checkedMul_value _ _ _ mulDelta, difference], checkedMul_value _ _ _ mulNext⟩

theorem positive_total_error_first (count : Nat) (unit total : Word) (arrays : Arrays)
    (overflow : 2^256 ≤ total.val*unit.val) : positive count unit total arrays = .error .arithmetic := by
  simp [positive, checkedMul, show ¬ total.val*unit.val < 2^256 by omega, bind, Except.bind]

/-- Even when the original/returned row is monotone, multiplication can fail. -/
theorem zeroDemand_overflow (unit previous : Word) (overflow : 2^256 ≤ previous.val*unit.val) :
    zeroDemand 1 unit [previous] = .error .arithmetic := by
  simp [zeroDemand, zeroRows, read, checkedMul, show ¬ previous.val*unit.val < 2^256 by omega,
    bind, Except.bind]

/-- In the actual parent, total multiplication is safe because demand came from
division of a uint256 wei amount. This derives the bound from real division and
allocation results, instead of assuming multiplication succeeded. -/
theorem allocated_total_mul_success (amount unit demand : Word) (buckets capacities : List Word)
    (out : StepOutput) (divided : checkedDiv amount unit = .ok demand)
    (allocated : allocate buckets capacities demand = .ok out) :
    ∃ scaled, checkedMul out.amount unit = .ok scaled ∧ scaled.val ≤ amount.val := by
  have quotient := checkedDiv_value amount unit demand divided
  have totalBound := allocate_amount_le_demand buckets capacities demand out allocated
  rw [quotient] at totalBound
  have productBound : out.amount.val*unit.val ≤ amount.val :=
    Nat.le_trans (Nat.mul_le_mul_right unit.val totalBound) (Nat.div_mul_le_self amount.val unit.val)
  have representable : out.amount.val*unit.val < 2^256 := Nat.lt_of_le_of_lt productBound amount.isLt
  refine ⟨⟨out.amount.val*unit.val, representable⟩, ?_, productBound⟩
  simp [checkedMul, representable]

theorem source_index_increment_safe (count : Word) (i : Nat) (inside : i < count.val) :
    i+1 < 2^256 := by have := count.isLt; omega

#print axioms rowArithmetic_success_iff
#print axioms rowArithmetic_values
#print axioms positive_total_error_first
#print axioms zeroDemand_overflow
#print axioms allocated_total_mul_success
end LidoSRv3.Audit.Source.TrioAlloc2.ParentConversion
