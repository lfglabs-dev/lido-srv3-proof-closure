import LidoSRv3.Audit.Source.SszCompiledClEntry
import LidoSRv3.Audit.Source.SszCompiledMemory
import LidoSRv3.Audit.Source.SszWitnessAbi

/-!
Classification of `beforeRoot` / `slotSibling` / `rootCall` errors on the
selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul` 43-114).

Positive constructor classes (not merely “not proof/root”). `run`
failures partition into the three compiled phases. EIP-4788
authenticity/freshness remain declared. Compilation, crypto, gas and
consensus stay outside. Additive: no existing file is edited.

CLAIM: grok owns ssz-beforeroot-class since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledBeforeRootClass

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszCompiledMemory
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

def claimed : String := "grok owns ssz-beforeroot-class since 2026-09-11"

theorem claimed_string : claimed = "grok owns ssz-beforeroot-class since 2026-09-11" := rfl

/-- Constructors `beforeRoot` (IR 43-100) can raise after a successful
header, plus the dispatcher ABI that `header` itself throws. -/
def isBeforeRootClass : SszCompiledClEntry.Error → Prop
  | .abi _ => True
  | .bls _ => True
  | .panic11 => True
  | .panic32 => True
  | .invalidSlot => True
  | _ => False

/-- Constructors `slotSibling` (IR 70-97) can raise. -/
def isSlotSiblingClass : SszCompiledClEntry.Error → Prop
  | .panic11 => True
  | .panic32 => True
  | .invalidSlot => True
  | _ => False

private theorem bind_error {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {e : ε}
    (h : (step >>= next) = .error e) :
    step = .error e ∨ ∃ x, step = .ok x ∧ next x = .error e := by
  cases step with
  | error e' =>
    cases h
    exact Or.inl rfl
  | ok x =>
    exact Or.inr ⟨x, rfl, h⟩

private theorem mapError_error {ε ε' α : Type} (f : ε → ε') (step : Except ε α)
    (e : ε') (h : step.mapError f = .error e) : ∃ x, step = .error x ∧ e = f x := by
  cases step with
  | error x =>
    cases h
    exact ⟨x, rfl, rfl⟩
  | ok _ => cases h

/-- Nonpayable dispatcher guard (`CLValidatorVerifier` selector head, IR 40-55). -/
theorem header_of_nonzero_value (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat ≠ 0) :
    header st = .error (.abi .abi) := by
  fun_cases header st
  all_goals
    first
    | rfl
    | (exact (hv rfl).elim)
    | contradiction

theorem header_ok_is_nonpayable {st : EVM.State} {head : UInt256}
    (h : header st = .ok head) : st.executionEnv.weiValue.toNat = 0 := by
  by_contra hv
  have : header st = .error (.abi .abi) := header_of_nonzero_value st hv
  rw [this] at h
  cases h

/-- A `header` error is the first `beforeRoot` bind (IR 43-55). -/
theorem beforeRoot_of_header_error (fuel : Nat) (context : EVM.State)
    (e : SszCompiledClEntry.Error)
    (h : header (prologue context) = .error e) :
    beforeRoot fuel context = .error e := by
  unfold beforeRoot
  change (header (prologue context) >>= _) = .error e
  rw [h]
  rfl

/-- Short proof tail is panic 0x11 (`_verifySlot` checked `length-2`, IR 70-97). -/
theorem slotSibling_short_is_panic11 (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (h : branch.length < 2) :
    slotSibling st branch expected = .error .panic11 := by
  unfold slotSibling
  dsimp only
  rw [if_pos h]

/-- Mismatched penultimate sibling is `InvalidSlot` (IR 70-97). The Lean
`Nat` subtraction after `2 ≤ length` makes the panic-0x32 guard
unreachable; that guard remains a Solidity checked-sub, documented in
the README as a model/IR fidelity gap. -/
theorem slotSibling_mismatch_is_invalidSlot (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (hlen : 2 ≤ branch.length)
    (hne : st.calldataload
        (branch.offset + UInt256.ofNat ((branch.length - 2) * 32)) ≠ expected) :
    slotSibling st branch expected = .error .invalidSlot := by
  unfold slotSibling
  dsimp only
  split
  · rename_i h2
    exact (Nat.not_lt.mpr hlen h2).elim
  ·     have hlt : branch.length - 2 < branch.length := by omega
    simp [hlt, hne] -- `hne` closes the sibling-compare branch when it remains

/-- In this model, `.panic32` is unreachable: after `length ≥ 2`,
`length - 2 < length` holds for saturating `Nat` subtraction. -/
theorem slotSibling_error_not_panic32 (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : slotSibling st branch expected = .error e) :
    e ≠ .panic32 := by
  unfold slotSibling at h
  dsimp only at h
  split at h
  · cases h
    intro h32
    cases h32
  · rename_i hlen
    have hlt : branch.length - 2 < branch.length := by omega
    split at h
    · rename_i h32
      exact (h32 hlt).elim
    · split at h
      · cases h
      · cases h
        intro h32
        cases h32

theorem slotSibling_error_is_slot_class (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : slotSibling st branch expected = .error e) :
    isSlotSiblingClass e := by
  unfold slotSibling at h
  dsimp only at h
  split at h
  · cases h
    simp [isSlotSiblingClass]
  · split at h
    · cases h
      simp [isSlotSiblingClass]
    · split at h
      · cases h
      · cases h
        simp [isSlotSiblingClass]

/-- A header failure is the remainder; otherwise the error is a named
beforeRoot class. Excluding the remainder needs a do-free rewrite of
`header` (same seven guards). -/
theorem beforeRoot_error_is_class_or_header
    (fuel : Nat) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    isBeforeRootClass e ∨ header (prologue context) = .error e := by
  unfold beforeRoot at h
  rcases bind_error h with hh | ⟨_, _, hrest⟩
  · exact Or.inr hh
  · refine Or.inl ?_
    rcases bind_error hrest with h | ⟨_, _, h⟩
    · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
      subst he
      simp [isBeforeRootClass]
    · rcases bind_error h with h | ⟨_, _, h⟩
      · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
        subst he
        simp [isBeforeRootClass]
      · rcases bind_error h with h | ⟨_, _, h⟩
        · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
          subst he
          simp [isBeforeRootClass]
        · rcases bind_error h with h | ⟨_, _, h⟩
          · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
            subst he
            simp [isBeforeRootClass]
          · rcases bind_error h with h | ⟨_, _, h⟩
            · have hs := slotSibling_error_is_slot_class _ _ _ _ h
              revert hs
              cases e <;> simp [isSlotSiblingClass, isBeforeRootClass]
            · rcases bind_error h with h | ⟨_, _, h⟩
              · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                subst he
                simp [isBeforeRootClass]
              · cases h

/-- After `header` succeeds, every `beforeRoot` error is
`isBeforeRootClass` (IR 56-100). -/
theorem beforeRoot_error_class_of_header_ok
    (fuel : Nat) (context : EVM.State) (head : UInt256)
    (e : SszCompiledClEntry.Error)
    (hh : header (prologue context) = .ok head)
    (h : beforeRoot fuel context = .error e) :
    isBeforeRootClass e := by
  have hdis := beforeRoot_error_is_class_or_header fuel context e h
  cases hdis with
  | inl hc => exact hc
  | inr he =>
    rw [hh] at he
    cases he

/-- `rootCall` (IR 101-114) errors only as `.allocation .panic41`. -/
theorem rootCall_error_is_allocation (external : StaticCall.External)
    (world : Live.World) (st : EVM.State) (ts : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : rootCall external world st ts = .error e) :
    e = .allocation .panic41 := by
  unfold rootCall at h
  dsimp only at h
  split at h
  · cases h
    rfl
  · cases h

/-- `run` errors are exactly one of the three compiled phases. -/
theorem run_error_phase
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : (run fuel cfg external world context).outcome = .error e) :
    beforeRoot fuel context = .error e ∨
      (∃ b, beforeRoot fuel context = .ok b ∧
        rootCall external world b.state b.timestamp = .error e) ∨
      (∃ b st out,
        beforeRoot fuel context = .ok b ∧
          rootCall external world b.state b.timestamp = .ok (st, out) ∧
          afterRoot fuel cfg st b.head out.success b.index = .error e) := by
  cases hbr : beforeRoot fuel context with
  | error e' =>
    have hr : (run fuel cfg external world context).outcome = .error e' := by
      simp [run, hbr]
    rw [hr] at h
    cases h
    exact Or.inl rfl
  | ok b =>
    cases hrc : rootCall external world b.state b.timestamp with
    | error e' =>
      have hr : (run fuel cfg external world context).outcome = .error e' := by
        simp [run, hbr, hrc]
      rw [hr] at h
      cases h
      exact Or.inr (Or.inl ⟨b, rfl, hrc⟩)
    | ok pr =>
      rcases pr with ⟨st, out⟩
      have hr :
          (run fuel cfg external world context).outcome =
            afterRoot fuel cfg st b.head out.success b.index := by
        simp [run, hbr, hrc]
      rw [hr] at h
      exact Or.inr (Or.inr ⟨b, st, out, rfl, hrc, h⟩)

/-- A `run` failure that is the `rootCall` phase is allocator panic 0x41. -/
theorem run_rootCall_failure_is_allocation
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (b : Before)
    (_hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .error e)
    (_h : (run fuel cfg external world context).outcome = .error e) :
    e = .allocation .panic41 :=
  rootCall_error_is_allocation external world b.state b.timestamp e hrc

/-- Nonzero `msg.value` fails the compiled entry before the root call. -/
theorem run_of_nonzero_value
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State)
    (hv : context.executionEnv.weiValue.toNat ≠ 0) :
    (run fuel cfg external world context).outcome = .error (.abi .abi) := by
  have henv : (prologue context).executionEnv = context.executionEnv := rfl
  have hh : header (prologue context) = .error (.abi .abi) :=
    header_of_nonzero_value (prologue context) (by rw [henv]; exact hv)
  have hbr : beforeRoot fuel context = .error (.abi .abi) :=
    beforeRoot_of_header_error fuel context _ hh
  simp [run, hbr]

#print axioms claimed_string
#print axioms header_of_nonzero_value
#print axioms header_ok_is_nonpayable
#print axioms beforeRoot_of_header_error
#print axioms slotSibling_short_is_panic11
#print axioms slotSibling_mismatch_is_invalidSlot
#print axioms slotSibling_error_not_panic32
#print axioms slotSibling_error_is_slot_class
#print axioms beforeRoot_error_class_of_header_ok
#print axioms beforeRoot_error_is_class_or_header
#print axioms rootCall_error_is_allocation
#print axioms run_error_phase
#print axioms run_rootCall_failure_is_allocation
#print axioms run_of_nonzero_value

end LidoSRv3.Audit.Source.SszCompiledBeforeRootClass
