import LidoSRv3.Audit.Source.SszCompiledClEntry
import LidoSRv3.Audit.Source.SszCompiledMemory
import LidoSRv3.Audit.Source.SszWitnessAbi

/-!
Do-free constructor analysis of `header` on the selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol` dispatcher at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul` 40-55).

`SszCompiledClEntry.header` is now an explicit `if`/`.error`/`.ok` nest
with the same seven guards in the same order. Every header failure is
`.abi .abi`. Combined with the `beforeRoot` walk, a `beforeRoot` error
is ABI / BLS / slot-panic — no header join-point remainder.

EIP-4788 authenticity/freshness remain declared. Compilation, crypto,
gas and consensus stay outside.

CLAIM: grok owns ssz-header-ite since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledHeaderIte

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszCompiledMemory
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

def claimed : String := "grok owns ssz-header-ite since 2026-09-11"

theorem claimed_string : claimed = "grok owns ssz-header-ite since 2026-09-11" := rfl

/-- Constructors `beforeRoot` can raise once `header` is constructor-visible. -/
def isBeforeRootClass : SszCompiledClEntry.Error → Prop
  | .abi _ => True
  | .bls _ => True
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

/-- Every `header` failure is the dispatcher ABI error (IR 40-55). -/
theorem header_error_is_abi (st : EVM.State) (e : SszCompiledClEntry.Error)
    (h : header st = .error e) : e = .abi .abi := by
  unfold header at h
  dsimp only at h
  split at h
  · cases h; rfl
  · split at h
    · cases h; rfl
    · split at h
      · cases h; rfl
      · split at h
        · cases h; rfl
        · split at h
          · cases h; rfl
          · split at h
            · cases h; rfl
            · split at h
              · cases h; rfl
              · cases h

/-- Nonpayable guard (IR 40-55, first). -/
theorem header_of_nonzero_value (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat ≠ 0) :
    header st = .error (.abi .abi) := by
  unfold header
  dsimp only
  rw [if_pos hv]

/-- Calldata shorter than the 4-byte selector (IR 40-55, second). -/
theorem header_of_short_calldata (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat = 0)
    (hs : (UInt256.ofNat st.executionEnv.calldata.size).toNat < 4) :
    header st = .error (.abi .abi) := by
  unfold header
  dsimp only
  rw [if_neg (by simp [hv]), if_pos hs]

theorem header_ok_is_nonpayable {st : EVM.State} {head : UInt256}
    (h : header st = .ok head) : st.executionEnv.weiValue.toNat = 0 := by
  by_contra hv
  have : header st = .error (.abi .abi) := header_of_nonzero_value st hv
  rw [this] at h
  cases h

/-- Successful `header` returns the witness offset at word 100. -/
theorem header_ok_is_offset {st : EVM.State} {head : UInt256}
    (h : header st = .ok head) :
    head = st.calldataload (UInt256.ofNat 100) := by
  unfold header at h
  dsimp only at h
  split at h
  · cases h
  · split at h
    · cases h
    · split at h
      · cases h
      · split at h
        · cases h
        · split at h
          · cases h
          · split at h
            · cases h
            · split at h
              · cases h
              · exact (Except.ok.inj h).symm

/-- A `header` error is the first `beforeRoot` bind. -/
theorem beforeRoot_of_header_error (fuel : Nat) (context : EVM.State)
    (e : SszCompiledClEntry.Error)
    (h : header (prologue context) = .error e) :
    beforeRoot fuel context = .error e := by
  unfold beforeRoot
  change (header (prologue context) >>= _) = .error e
  rw [h]
  rfl

theorem slotSibling_error_is_slot_class (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : slotSibling st branch expected = .error e) :
    e = .panic11 ∨ e = .panic32 ∨ e = .invalidSlot := by
  unfold slotSibling at h
  dsimp only at h
  split at h
  · cases h
    exact Or.inl rfl
  · split at h
    · cases h
      exact Or.inr (Or.inl rfl)
    · split at h
      · cases h
      · cases h
        exact Or.inr (Or.inr rfl)

/-- After the do-free rewrite, every `beforeRoot` error is a named
beforeRoot class. There is no header join-point remainder. -/
theorem beforeRoot_error_is_beforeRootClass
    (fuel : Nat) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    isBeforeRootClass e := by
  unfold beforeRoot at h
  rcases bind_error h with hh | ⟨_, _, hrest⟩
  · have he := header_error_is_abi (prologue context) e hh
    subst he
    simp [isBeforeRootClass]
  · rcases bind_error hrest with h | ⟨_, _, h⟩
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
            · rcases slotSibling_error_is_slot_class _ _ _ _ h with h11 | h32 | hinv
              · subst h11; simp [isBeforeRootClass]
              · subst h32; simp [isBeforeRootClass]
              · subst hinv; simp [isBeforeRootClass]
            · rcases bind_error h with h | ⟨_, _, h⟩
              · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                subst he
                simp [isBeforeRootClass]
              · cases h

/-- Nonzero `msg.value` fails the compiled entry at the dispatcher. -/
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
#print axioms header_error_is_abi
#print axioms header_of_nonzero_value
#print axioms header_of_short_calldata
#print axioms header_ok_is_nonpayable
#print axioms header_ok_is_offset
#print axioms beforeRoot_of_header_error
#print axioms slotSibling_error_is_slot_class
#print axioms beforeRoot_error_is_beforeRootClass
#print axioms run_of_nonzero_value

end LidoSRv3.Audit.Source.SszCompiledHeaderIte
