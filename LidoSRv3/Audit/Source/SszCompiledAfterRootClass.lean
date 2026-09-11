import LidoSRv3.Audit.Source.SszCompiledClEntry
import LidoSRv3.Audit.Source.SszCompiledReply
import LidoSRv3.Audit.Source.SszProofCalldataLoop
import LidoSRv3.Audit.Source.SszCompiledGIndex
import LidoSRv3.Audit.Source.SszWitnessAbi
import LidoSRv3.Audit.Source.SszBlsComposition

/-!
Classification of `afterRoot` errors on the selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul` 116-417).

`afterRoot` is the unique divergence after `beforeRoot` / `rootCall`.
Every error constructor it can raise is named here against its
Solidity/IR site. Slot-panic constructors (`panic11`, `panic32`,
`invalidSlot`) belong to `beforeRoot` / `slotSibling` (IR 70-97) and
do not appear.

EIP-4788 authenticity/freshness remain declared. Compilation, crypto,
gas and consensus stay outside. Additive: no existing file is edited.

CLAIM: grok owns ssz-afterroot-class since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledAfterRootClass

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

def claimed : String := "grok owns ssz-afterroot-class since 2026-09-11"

/-- Constructors `afterRoot` (IR 116-417) can raise. -/
def isAfterRootClass : SszCompiledClEntry.Error → Prop
  | .reply _ => True
  | .abi _ => True
  | .gindex _ => True
  | .allocation _ => True
  | .bls _ => True
  | .proof _ => True
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

private theorem bind_ok {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β}
    (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error _ => cases h
  | ok x => exact ⟨x, rfl, h⟩

private theorem mapError_error {ε ε' α : Type} (f : ε → ε') (step : Except ε α)
    (e : ε') (h : step.mapError f = .error e) : ∃ x, step = .error x ∧ e = f x := by
  cases step with
  | error x =>
    cases h
    exact ⟨x, rfl, rfl⟩
  | ok _ => cases h

/-- `liftConsumer` (leaf field stores / merkle) is ABI, allocation, BLS or
proof — never a slot-panic. -/
theorem liftConsumer_is_afterRootClass (e : SszCompiledConsumer.Error) :
    isAfterRootClass (liftConsumer e) := by
  cases e <;> simp [isAfterRootClass, liftConsumer]

/-- Failed STATICCALL is `rootNotFound`
(`CLValidatorVerifier.sol:103-107`, IR 146-148). -/
theorem failed_staticcall_is_rootNotFound (st : EVM.State) (data : UInt256) :
    SszCompiledReply.decodeRoot st false data =
      .error SszCompiledReply.Error.rootNotFound := rfl

/-- `afterRoot` cannot succeed once the STATICCALL flag is false. -/
theorem afterRoot_of_failed_staticcall
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (afterState : EVM.State)
    (h : afterRoot fuel cfg st head false n = .ok afterState) : False := by
  unfold afterRoot at h
  rcases bind_ok h with ⟨p, _, hrest⟩
  rcases p with ⟨data, st'⟩
  have hdec : ((SszCompiledReply.decodeRoot st' false data).mapError
      SszCompiledClEntry.Error.reply) = .error (.reply .rootNotFound) := by
    simp [failed_staticcall_is_rootNotFound, Except.mapError]
  rcases bind_ok hrest with ⟨_, hroot, _⟩
  rw [hdec] at hroot
  cases hroot

/-- Empty proof list is `invalidProof` (`SSZ.verifyProof` count guard). -/
theorem empty_proof_is_invalidProof (fuel : Nat) (st : EVM.State)
    (rawIndex leaf root offset : UInt256) :
    SszProofCalldataLoop.verify fuel st rawIndex leaf root offset 0 =
      .error .invalidProof := by
  simp [SszProofCalldataLoop.verify]

/-- `afterRoot` errors are exactly the named after-prefix classes
(IR 116-417). Slot-panic constructors stay on `slotSibling` (IR 70-97). -/
theorem afterRoot_error_is_afterRootClass
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : afterRoot fuel cfg st head true n = .error e ∨
        afterRoot fuel cfg st head false n = .error e) :
    isAfterRootClass e := by
  have walk {success : Bool}
      (herr : afterRoot fuel cfg st head success n = .error e) :
      isAfterRootClass e := by
    unfold afterRoot at herr
    rcases bind_error herr with h | ⟨_, _, h⟩
    · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
      subst he; simp [isAfterRootClass]
    · rcases bind_error h with h | ⟨_, _, h⟩
      · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
        subst he; simp [isAfterRootClass]
      · rcases bind_error h with h | ⟨_, _, h⟩
        · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
          subst he; simp [isAfterRootClass]
        · rcases bind_error h with h | ⟨_, _, h⟩
          · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
            subst he; simp [isAfterRootClass]
          · rcases bind_error h with h | ⟨_, _, h⟩
            · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
              subst he; simp [isAfterRootClass]
            · rcases bind_error h with h | ⟨_, _, h⟩
              · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                subst he; simp [isAfterRootClass]
              · rcases bind_error h with h | ⟨_, _, h⟩
                · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                  subst he; simp [isAfterRootClass]
                · rcases bind_error h with h | ⟨_, _, h⟩
                  · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                    subst he
                    exact liftConsumer_is_afterRootClass _
                  · rcases bind_error h with h | ⟨_, _, h⟩
                    · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                      subst he
                      exact liftConsumer_is_afterRootClass _
                    · rcases bind_error h with h | ⟨_, _, h⟩
                      · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                        subst he; simp [isAfterRootClass]
                      · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                        subst he; simp [isAfterRootClass]
  cases h with
  | inl ht => exact walk ht
  | inr hf => exact walk hf

/-- Same classification, parameterized by the STATICCALL flag. -/
theorem afterRoot_error_class
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (success : Bool) (e : SszCompiledClEntry.Error)
    (h : afterRoot fuel cfg st head success n = .error e) :
    isAfterRootClass e :=
  afterRoot_error_is_afterRootClass fuel cfg st head n e <| by
    cases success
    · exact Or.inr h
    · exact Or.inl h

/-- Slot-panic constructors (`CLValidatorVerifier._verifySlot`, IR 70-97)
never come from `afterRoot`. -/
theorem afterRoot_never_slot_panic
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (success : Bool) (e : SszCompiledClEntry.Error)
    (h : afterRoot fuel cfg st head success n = .error e) :
    e ≠ .panic11 ∧ e ≠ .panic32 ∧ e ≠ .invalidSlot := by
  have hc := afterRoot_error_class fuel cfg st head n success e h
  revert hc
  cases e <;> simp [isAfterRootClass]

/-- Failed STATICCALL (`success = false`) can only raise `.reply`
(`copyReply` IR 116-145 or `decodeRoot` IR 146-148). Later binds are
unreachable. -/
theorem afterRoot_failed_flag_is_reply
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (e : SszCompiledClEntry.Error)
    (h : afterRoot fuel cfg st head false n = .error e) :
    ∃ r, e = .reply r := by
  unfold afterRoot at h
  rcases bind_error h with hcopy | ⟨p, _, hrest⟩
  · rcases mapError_error _ _ _ hcopy with ⟨r, _, he⟩
    exact ⟨r, he⟩
  · rcases p with ⟨data, st'⟩
    have hdec :
        ((SszCompiledReply.decodeRoot st' false data).mapError
            SszCompiledClEntry.Error.reply) =
          .error (.reply .rootNotFound) := by
      simp [failed_staticcall_is_rootNotFound, Except.mapError]
    rcases bind_error hrest with hroot | ⟨_, hroot, _⟩
    · rw [hdec] at hroot
      cases hroot
      exact ⟨.rootNotFound, rfl⟩
    · rw [hdec] at hroot
      cases hroot

/-- After a successful reply copy, `success = false` is exactly
`rootNotFound` (`CLValidatorVerifier.sol:103-107`). -/
theorem afterRoot_failed_flag_is_rootNotFound_of_copy
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (data : UInt256) (st' : EVM.State) (e : SszCompiledClEntry.Error)
    (hc : SszCompiledReply.copyReply st = .ok (data, st'))
    (h : afterRoot fuel cfg st head false n = .error e) :
    e = .reply .rootNotFound := by
  unfold afterRoot at h
  have hcopy :
      (SszCompiledReply.copyReply st).mapError SszCompiledClEntry.Error.reply =
        .ok (data, st') := by
    simp [hc, Except.mapError]
  rcases bind_error h with h1 | ⟨p, h1, hrest⟩
  · rw [hcopy] at h1
    cases h1
  · have hp : p = (data, st') := by
      rw [hcopy] at h1
      cases h1
      rfl
    subst hp
    have hdec :
        ((SszCompiledReply.decodeRoot st' false data).mapError
            SszCompiledClEntry.Error.reply) =
          .error (.reply .rootNotFound) := by
      simp [failed_staticcall_is_rootNotFound, Except.mapError]
    rcases bind_error hrest with h2 | ⟨_, h2, _⟩
    · rw [hdec] at h2
      cases h2
      rfl
    · rw [hdec] at h2
      cases h2

/-- Empty returndata still copies (`IR 116-145` size-0 branch). -/
theorem copyReply_empty_ok (st : EVM.State) (h : st.returnData.size = 0) :
    SszCompiledReply.copyReply st = .ok (UInt256.ofNat 96, st) := by
  unfold SszCompiledReply.copyReply
  simp [h]

/-- Oversized returndata is allocator panic 0x41 (`IR 116-145`). -/
theorem copyReply_oversized_is_panic41 (st : EVM.State)
    (h : st.returnData.size > 2 ^ 64 - 1) :
    SszCompiledReply.copyReply st = .error .panic41 := by
  have hne : st.returnData.size ≠ 0 :=
    Nat.ne_of_gt (Nat.lt_of_le_of_lt (Nat.zero_le _) h)
  unfold SszCompiledReply.copyReply
  dsimp only
  rw [if_neg hne, if_pos h]

/-- A word wider than uint64 is ABI (`read64` at calldata 36, IR 167). -/
theorem read64_wide_is_abi (st : EVM.State) (offset : UInt256)
    (h : ¬ (st.calldataload offset).toNat < 2 ^ 64) :
    SszWitnessAbi.read64 st offset = .error .abi := by
  unfold SszWitnessAbi.read64
  dsimp only
  rw [if_neg h]

/-- Wrong pubkey length is BLS (`CLValidatorVerifier` key SHA, IR 234+). -/
theorem pubkey_wrong_length_is_invalid
    (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat)
    (h : length ≠ 48) :
    SszBlsComposition.pubkeyRun fuel st offset length =
      .error .invalidPubkeyLength := by
  simp [SszBlsComposition.pubkeyRun, h]

#print axioms liftConsumer_is_afterRootClass
#print axioms failed_staticcall_is_rootNotFound
#print axioms afterRoot_of_failed_staticcall
#print axioms empty_proof_is_invalidProof
#print axioms afterRoot_error_is_afterRootClass
#print axioms afterRoot_error_class
#print axioms afterRoot_never_slot_panic
#print axioms afterRoot_failed_flag_is_reply
#print axioms afterRoot_failed_flag_is_rootNotFound_of_copy
#print axioms copyReply_empty_ok
#print axioms copyReply_oversized_is_panic41
#print axioms read64_wide_is_abi
#print axioms pubkey_wrong_length_is_invalid

end LidoSRv3.Audit.Source.SszCompiledAfterRootClass
