import LidoSRv3.Audit.Source.SszCompiledBeforeRootClass
import LidoSRv3.Audit.Source.SszWitnessAbi

/-! Named kill-lines for compiled `beforeRoot` / `rootCall` error classification.
Each mutant refutes a universal “this class still succeeds” claim. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledBeforeRootClassMutants

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledBeforeRootClass
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

/-- Kill-line: a one-word proof tail is panic 0x11, not a slot check. -/
theorem slot_short_kill_line (st : EVM.State) (expected : UInt256) :
    slotSibling st ⟨UInt256.ofNat 0, 0⟩ expected = .error .panic11 :=
  slotSibling_short_is_panic11 st ⟨UInt256.ofNat 0, 0⟩ expected (by decide)

/-- Kill-line: a one-word tail is not panic 0x32. -/
theorem slot_short_not_panic32_kill_line (st : EVM.State) (expected : UInt256) :
    slotSibling st ⟨UInt256.ofNat 0, 1⟩ expected ≠ .error .panic32 := by
  have h := slotSibling_short_is_panic11 st ⟨UInt256.ofNat 0, 1⟩ expected (by decide)
  rw [h]
  intro hp
  cases hp

/-- Kill-line: a mismatched penultimate sibling is `InvalidSlot`. -/
theorem slot_mismatch_kill_line (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256)
    (hlen : 2 ≤ branch.length)
    (hne : st.calldataload
        (branch.offset + UInt256.ofNat ((branch.length - 2) * 32)) ≠ expected) :
    slotSibling st branch expected = .error .invalidSlot :=
  slotSibling_mismatch_is_invalidSlot st branch expected hlen hne

/-- Kill-line: nonzero `msg.value` is ABI, not a successful dispatcher. -/
theorem header_value_kill_line (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat ≠ 0) :
    header st = .error (.abi .abi) :=
  header_of_nonzero_value st hv

/-- Kill-line: nonzero value cannot be a successful compiled `run`. -/
theorem run_value_kills_success
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context afterState : EVM.State)
    (hv : context.executionEnv.weiValue.toNat ≠ 0)
    (h : (run fuel cfg external world context).outcome = .ok afterState) :
    False := by
  have hr := run_of_nonzero_value fuel cfg external world context hv
  rw [hr] at h
  cases h

/-- Kill-line: a `rootCall` error is allocator panic 0x41, not a proof/root
constructor. -/
theorem rootCall_error_not_proof_kill_line
    (external : StaticCall.External) (world : Live.World)
    (st : EVM.State) (ts : UInt256) (e : SszCompiledClEntry.Error)
    (h : rootCall external world st ts = .error e) :
    e ≠ .proof .invalidProof := by
  have he := rootCall_error_is_allocation external world st ts e h
  intro hp
  rw [he] at hp
  cases hp

#print axioms slot_short_kill_line
#print axioms slot_short_not_panic32_kill_line
#print axioms slot_mismatch_kill_line
#print axioms header_value_kill_line
#print axioms run_value_kills_success
#print axioms rootCall_error_not_proof_kill_line

end LidoSRv3.Tests.SszCompiledBeforeRootClassMutants
