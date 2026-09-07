import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec
import LidoSRv3.Audit.Source.TrioAlloc2.Composition

/-!
Decoded public SRLib._getDepositAllocations path, pinned Solidity
17005714f151e5502c559932319a3f2f74ac2436, SRLib.sol:387–438.
Preserves the count-zero guard, division before producer calls, the separate
zero-demand branch and checked Ether conversions. The linked proportional library
is interpreted by its source executor; its DELEGATECALL/ABI and compiler memory
refinement are separate obligations. The transcript observes module calls only.
-/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1

structure ParentOutput where
  totalAllocated : Word
  allocated : List Word
  newAllocations : List Word
  deriving DecidableEq, Repr

/-- The external library's panic is propagated with its Solidity panic code. -/
def libraryResult (r : TrioAlloc2.Result α) : Except Failure α :=
  match r with
  | .ok x => .ok x
  | .error .arithmetic => .error (.panic (word 0x11))
  | .error .divisionByZero => .error (.panic (word 0x12))
  | .error .arrayBounds => .error (.panic (word 0x32))

/-- Count-driven conversion; delta subtraction, delta multiplication and new-total
multiplication are checked in that order, before moving to the next row. -/
def convertPositive (unit : Word) : Nat → List Word → List Word → Except Failure (List Word × List Word)
  | 0, _, _ => .ok ([], [])
  | n+1, old, fresh => do
    let next ← match fresh with
      | [] => .error (.panic (word 0x32))
      | value :: _ => .ok value
    let previous ← match old with
      | [] => .error (.panic (word 0x32))
      | value :: _ => .ok value
    let delta ← checkedSub next.val previous.val
    let deltaWei ← checked (delta.val * unit.val)
    let nextWei ← checked (next.val * unit.val)
    let (deltas, totals) ← convertPositive unit n old.tail fresh.tail
    pure (deltaWei :: deltas, nextWei :: totals)

/-- The zero-demand branch still checks every current allocation's Ether product. -/
def convertZero (unit : Word) : Nat → List Word → Except Failure (List Word × List Word)
  | 0, _ => .ok ([], [])
  | n+1, old => do
    let previous ← match old with
      | [] => .error (.panic (word 0x32))
      | value :: _ => .ok value
    let previousWei ← checked (previous.val * unit.val)
    let (deltas, totals) ← convertZero unit n old.tail
    pure (word 0 :: deltas, previousWei :: totals)

/-- Public wrapper over the actual producer and proportional consumer. The old
array is retained for subtraction, matching the external library's copy boundary. -/
def getDepositAllocations (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) : Execution ParentOutput := do
  let count := (storage (countSlot layout)).val
  if count = 0 then
    pure ⟨word 0, [], []⟩
  else
    let demand ← liftChecked (checkedDiv amount config.maxEBType1)
    let produced ← produce layout storage oracle ⟨config, demand, isTopUp⟩
    if demand.val > 0 then
      let result ← liftChecked (libraryResult
        (TrioAlloc2.allocate produced.allocations produced.capacities demand))
      let total ← liftChecked (checked (result.amount.val * config.maxEBType1.val))
      let (deltas, totals) ← liftChecked
        (convertPositive config.maxEBType1 count produced.allocations result.buckets)
      pure ⟨total, deltas, totals⟩
    else
      let (deltas, totals) ← liftChecked (convertZero config.maxEBType1 count produced.allocations)
      pure ⟨word 0, deltas, totals⟩

/-- Empty storage enumeration bypasses even division by a zero configuration. -/
theorem getDepositAllocations_empty (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (empty : (storage (countSlot layout)).val = 0) :
    getDepositAllocations layout storage oracle config amount isTopUp before =
      (.ok ⟨word 0, [], []⟩, before) := by
  simp [getDepositAllocations, empty, pure, pureExec]

/-- For nonempty enumeration, zero unit fails before any adversarial module call. -/
theorem getDepositAllocations_zero_unit (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool) (before : Transcript)
    (nonempty : (storage (countSlot layout)).val ≠ 0) (zeroUnit : config.maxEBType1.val = 0) :
    getDepositAllocations layout storage oracle config amount isTopUp before =
      (.error (.panic (word 0x12)), before) := by
  simp [getDepositAllocations, nonempty, checkedDiv, zeroUnit, bind, bindExec, liftChecked]

/-- Independent per-row conversion equation; unbounded mathematics with no
source calls, checked helpers or executable conversion loop. -/
inductive Converted (unit : Nat) : List Word → List Word → List Word → List Word → Prop where
  | nil : Converted unit [] [] [] []
  | cons (old fresh delta total : Word) (olds freshs deltas totals : List Word)
      (ordered : old.val ≤ fresh.val)
      (deltaValue : delta.val = (fresh.val - old.val) * unit)
      (totalValue : total.val = fresh.val * unit)
      (rest : Converted unit olds freshs deltas totals) :
      Converted unit (old :: olds) (fresh :: freshs) (delta :: deltas) (total :: totals)

theorem checkedSub_value {a b : Nat} {out : Word}
    (h : TrioAlloc1.checkedSub a b = .ok out) : b ≤ a ∧ out.val = a - b := by
  unfold TrioAlloc1.checkedSub at h
  split at h
  · exact ⟨by assumption, (checked_success h).1⟩
  · cases h

/-- The conversion loop refines exact per-row Ether equations. Lengths are
explicit here and are discharged by producer/consumer composition upstream. -/
theorem convertPositive_refines (unit : Word) (count : Nat)
    (old fresh deltas totals : List Word)
    (oldLength : old.length = count) (freshLength : fresh.length = count)
    (executed : convertPositive unit count old fresh = .ok (deltas, totals)) :
    Converted unit.val old fresh deltas totals := by
  induction count generalizing old fresh deltas totals with
  | zero =>
    have oldEmpty : old = [] := by simpa using oldLength
    have freshEmpty : fresh = [] := by simpa using freshLength
    subst old; subst fresh
    simp [convertPositive] at executed
    obtain ⟨rfl, rfl⟩ := executed
    exact .nil
  | succ count ih =>
    cases old with
    | nil => simp at oldLength
    | cons previous olds =>
      cases fresh with
      | nil => simp at freshLength
      | cons next freshs =>
        simp only [convertPositive, bind, Except.bind, List.tail_cons, pure, Except.pure] at executed
        cases subEq : TrioAlloc1.checkedSub next.val previous.val with
        | error error => simp [subEq] at executed
        | ok delta =>
          simp only [subEq] at executed
          cases deltaEq : checked (delta.val * unit.val) with
          | error error => simp [deltaEq] at executed
          | ok deltaWei =>
            simp only [deltaEq] at executed
            cases totalEq : checked (next.val * unit.val) with
            | error error => simp [totalEq] at executed
            | ok nextWei =>
              simp only [totalEq] at executed
              cases restEq : convertPositive unit count olds freshs with
              | error error => simp [restEq] at executed
              | ok pair =>
                obtain ⟨ds, ts⟩ := pair
                simp only [restEq, Except.ok.injEq, Prod.mk.injEq] at executed
                obtain ⟨rfl, rfl⟩ := executed
                have subValue := checkedSub_value subEq
                exact .cons previous next deltaWei nextWei olds freshs ds ts subValue.1
                  (by rw [(checked_success deltaEq).1, subValue.2])
                  (checked_success totalEq).1
                  (ih olds freshs ds ts (by simpa using oldLength)
                    (by simpa using freshLength) restEq)

/-- The zero-demand conversion returns zero deltas and preserves each current
allocation in Ether, subject to the same checked multiplication as Solidity. -/
theorem convertZero_refines (unit : Word) (count : Nat)
    (old deltas totals : List Word) (oldLength : old.length = count)
    (executed : convertZero unit count old = .ok (deltas, totals)) :
    Converted unit.val old old deltas totals := by
  induction count generalizing old deltas totals with
  | zero =>
    have oldEmpty : old = [] := by simpa using oldLength
    subst old
    simp [convertZero] at executed
    obtain ⟨rfl, rfl⟩ := executed
    exact .nil
  | succ count ih =>
    cases old with
    | nil => simp at oldLength
    | cons previous olds =>
      simp only [convertZero, bind, Except.bind, List.tail_cons, pure, Except.pure] at executed
      cases valueEq : checked (previous.val * unit.val) with
      | error error => simp [valueEq] at executed
      | ok previousWei =>
        simp only [valueEq] at executed
        cases restEq : convertZero unit count olds with
        | error error => simp [restEq] at executed
        | ok pair =>
          obtain ⟨ds, ts⟩ := pair
          simp only [restEq, Except.ok.injEq, Prod.mk.injEq] at executed
          obtain ⟨rfl, rfl⟩ := executed
          exact .cons previous previous (word 0) previousWei olds olds ds ts (Nat.le_refl _)
            (by simp [word]) (checked_success valueEq).1
            (ih olds ds ts (by simpa using oldLength) restEq)

/-- The public returned Ether amount never exceeds the requested amount. The
validator bound comes from the actual consumer run, and the Ether conversion
uses the actual checked product. No successful module or consumer premise. -/
theorem getDepositAllocations_total_bound
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (config : Config) (amount : Word) (isTopUp : Bool)
    (before after : Transcript) (out : ParentOutput)
    (executed : getDepositAllocations layout storage oracle config amount isTopUp before =
      (.ok out, after)) : out.totalAllocated.val ≤ amount.val := by
  by_cases empty : (storage (countSlot layout)).val = 0
  · rw [getDepositAllocations_empty layout storage oracle config amount isTopUp before empty] at executed
    cases executed
    exact Nat.zero_le _
  · simp only [getDepositAllocations, empty, ↓reduceIte, bind, bindExec, liftChecked] at executed
    cases divEq : checkedDiv amount config.maxEBType1 with
    | error error => simp [divEq] at executed
    | ok demand =>
      simp only [divEq] at executed
      cases prodEq : produce layout storage oracle ⟨config, demand, isTopUp⟩ before with
      | mk produced middle =>
        simp only [prodEq] at executed
        cases produced with
        | error error => cases executed
        | ok produced =>
          by_cases positive : demand.val > 0
          · simp only [positive, ↓reduceIte] at executed
            cases allocEq : TrioAlloc2.allocate produced.allocations produced.capacities demand with
            | error error => cases error <;> simp [allocEq, libraryResult, bindExec, liftChecked] at executed
            | ok result =>
              simp only [allocEq, libraryResult, bindExec, liftChecked] at executed
              cases totalEq : checked (result.amount.val * config.maxEBType1.val) with
              | error error => simp [totalEq] at executed
              | ok total =>
                simp only [totalEq] at executed
                cases rowsEq : convertPositive config.maxEBType1 (storage (countSlot layout)).val
                    produced.allocations result.buckets with
                | error error => simp [rowsEq] at executed
                | ok rows =>
                  obtain ⟨deltas, totals⟩ := rows
                  simp only [rowsEq, pure, pureExec] at executed
                  cases executed
                  have bound := TrioAlloc2.allocate_amount_le_demand _ _ _ _ allocEq
                  have divisor := checkedDiv_success divEq
                  have product := (checked_success totalEq).1
                  change total.val ≤ amount.val
                  rw [product]
                  calc
                    result.amount.val * config.maxEBType1.val ≤ demand.val * config.maxEBType1.val :=
                      Nat.mul_le_mul_right _ bound
                    _ = (amount.val / config.maxEBType1.val) * config.maxEBType1.val := by rw [divisor.1]
                    _ ≤ amount.val := Nat.div_mul_le_self _ _
          · simp only [positive, ↓reduceIte] at executed
            cases rowsEq : convertZero config.maxEBType1 (storage (countSlot layout)).val produced.allocations with
            | error error => simp [rowsEq, bindExec, liftChecked] at executed
            | ok rows =>
              obtain ⟨deltas, totals⟩ := rows
              simp only [rowsEq, bindExec, liftChecked, pure, pureExec] at executed
              cases executed
              exact Nat.zero_le _

#print axioms getDepositAllocations_total_bound
#print axioms convertPositive_refines
#print axioms convertZero_refines
end LidoSRv3.Audit.Source.TrioComposition
