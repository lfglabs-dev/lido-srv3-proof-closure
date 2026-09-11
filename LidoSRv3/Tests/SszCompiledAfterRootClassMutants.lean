import LidoSRv3.Audit.Source.SszCompiledAfterRootClass
import LidoSRv3.Tests.SszCompiledClEntryRegression
import LidoSRv3.Audit.Source.SszCompiledReply
import LidoSRv3.Audit.Source.SszProofCalldataLoop
import LidoSRv3.Audit.Source.SszWitnessAbi
import LidoSRv3.Audit.Source.SszBlsComposition

/-! Named kill-lines for compiled `afterRoot` error classification.
Each mutant refutes a universal “this class still succeeds” claim. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledAfterRootClassMutants

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledAfterRootClass
open LidoSRv3.Audit.Source.SszCompiledGIndex
open LidoSRv3.Audit.Source.SszWrapperIndex
open LidoSRv3.Tests.SszCompiledClEntryRegression

/-- Kill-line: failed STATICCALL is not a successful `decodeRoot`
(`CLValidatorVerifier.sol:103-107`, IR 146-148). -/
theorem reply_rootNotFound_kill_line (st : EVM.State) (data : UInt256) :
    ¬ SszCompiledReply.decodeRoot st false data = .ok (data, st) := by
  simp [failed_staticcall_is_rootNotFound]

/-- Kill-line: `afterRoot` success does not survive `success = false`. -/
theorem reply_kills_afterRoot_success
    (fuel : Nat) (cfg : Configuration) (st afterState : EVM.State) (head n : UInt256) :
    ¬ SszCompiledClEntry.afterRoot fuel cfg st head false n = .ok afterState :=
  afterRoot_of_failed_staticcall fuel cfg st head n afterState

/-- Kill-line: an index outside the configured subtree is `.indexOutOfRange`
(`_getValidatorGI` / IR 168-233). -/
theorem gindex_out_of_range_kill_line :
    wrapper (cfgWords (pinnedConfiguration ⟨0, by decide⟩)) 100 (2 ^ 40) =
      .error .indexOutOfRange :=
  compiled_index_out_of_range

/-- Kill-line: empty sibling list is `invalidProof`, not a successful
`SSZ.verifyProof`. -/
theorem proof_empty_kill_line (st : EVM.State) :
    SszProofCalldataLoop.verify 0 st (UInt256.ofNat 0) (UInt256.ofNat 0)
      (UInt256.ofNat 0) (UInt256.ofNat 0) 0 = .error .invalidProof :=
  empty_proof_is_invalidProof 0 st (UInt256.ofNat 0) (UInt256.ofNat 0)
    (UInt256.ofNat 0) (UInt256.ofNat 0)

/-- Kill-line: `liftConsumer` of a proof error is a `.proof`, not a
slot-panic. -/
theorem liftConsumer_proof_not_slot_panic
    (e : SszProofCalldataLoop.VerifyError) :
    ¬ SszCompiledClEntry.liftConsumer (.proof e) =
        SszCompiledClEntry.Error.panic11 := by
  intro h
  cases h

/-- Kill-line: a uint64 field wider than 64 bits is ABI, not a decoded slot. -/
theorem abi_wide_slot_kill_line (st : EVM.State) (offset : UInt256)
    (h : ¬ (st.calldataload offset).toNat < 2 ^ 64) :
    ¬ SszWitnessAbi.read64 st offset = .ok (BitVec.ofNat 64 (st.calldataload offset).toNat) := by
  simp [read64_wide_is_abi st offset h]

/-- Kill-line: returndata larger than uint64 is panic 0x41, not a copied root. -/
theorem copyReply_oversized_kill_line (st : EVM.State)
    (h : st.returnData.size > 2 ^ 64 - 1) :
    ¬ ∃ data st', SszCompiledReply.copyReply st = .ok (data, st') := by
  intro ⟨_, _, hc⟩
  have := copyReply_oversized_is_panic41 st h
  rw [this] at hc
  cases hc

/-- Kill-line: a pubkey slice that is not 48 bytes is BLS, not a leaf digest. -/
theorem bls_wrong_pubkey_length_kill_line
    (fuel : Nat) (st : EVM.State) (offset : UInt256) :
    SszBlsComposition.pubkeyRun fuel st offset 0 =
      .error .invalidPubkeyLength :=
  pubkey_wrong_length_is_invalid fuel st offset 0 (by decide)

/-- Kill-line: `afterRoot` success requires the STATICCALL flag. -/
theorem afterRoot_ok_requires_success_kill_line
    (fuel : Nat) (cfg : Configuration) (st afterState : EVM.State)
    (head n : UInt256)
    (h : SszCompiledClEntry.afterRoot fuel cfg st head false n = .ok afterState) :
    False :=
  afterRoot_of_failed_staticcall fuel cfg st head n afterState h

#print axioms reply_rootNotFound_kill_line
#print axioms reply_kills_afterRoot_success
#print axioms gindex_out_of_range_kill_line
#print axioms proof_empty_kill_line
#print axioms liftConsumer_proof_not_slot_panic
#print axioms abi_wide_slot_kill_line
#print axioms copyReply_oversized_kill_line
#print axioms bls_wrong_pubkey_length_kill_line
#print axioms afterRoot_ok_requires_success_kill_line

end LidoSRv3.Tests.SszCompiledAfterRootClassMutants
