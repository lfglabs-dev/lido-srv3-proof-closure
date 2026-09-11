import LidoSRv3.Audit.Source.SszCompiledEntryRollback
import LidoSRv3.Tests.SszCompiledClEntryRegression
import LidoSRv3.Audit.Source.SszCompiledReply
import LidoSRv3.Audit.Source.SszProofCalldataLoop
import LidoSRv3.Audit.Source.SszProofCalldataStep
import LidoSRv3.Audit.Source.SszProofFold

/-! Named kill-lines for compiled CL-entry rollback. Each mutant is a
concrete refutation of a universal “success still holds after this
corruption” claim. No always-success stub, no renamed SSZ premise. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledEntryRollbackMutants

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledEntryRollback
open LidoSRv3.Audit.Source.SszCompiledGIndex
open LidoSRv3.Audit.Source.SszWrapperIndex
open LidoSRv3.Tests.SszCompiledClEntryRegression

/-- Kill-line: a failed BEACON_ROOTS STATICCALL is not a successful
`decodeRoot` (`CLValidatorVerifier.sol:103-107`, IR 146-148). -/
theorem falsified_root_staticcall_kill_line (st : EVM.State) (data : UInt256) :
    ¬ SszCompiledReply.decodeRoot st false data = .ok (data, st) := by
  simp [failed_staticcall_is_rootNotFound]

/-- Kill-line: `afterRoot` success does not survive `success = false`.
`decodeRoot` is the first after-prefix root comparison. -/
theorem falsified_root_kills_afterRoot_success
    (fuel : Nat) (cfg : Configuration) (st afterState : EVM.State) (head n : UInt256) :
    ¬ SszCompiledClEntry.afterRoot fuel cfg st head false n = .ok afterState :=
  afterRoot_of_failed_staticcall fuel cfg st head n afterState

/-- Kill-line: an index outside the configured subtree is rejected by the
compiled `wrapper` (`_getValidatorGI` / IR 168-233). -/
theorem out_of_range_index_kill_line :
    wrapper (cfgWords (pinnedConfiguration ⟨0, by decide⟩)) 100 (2 ^ 40) =
      .error .indexOutOfRange :=
  compiled_index_out_of_range

/-- Kill-line: `afterRoot` success does not imply the compiled wrapper
accepts an out-of-range validator offset. -/
theorem out_of_range_index_kills_wrapper_success :
    ¬ (∀ (cfg : Configuration) (slot n : Nat),
        wrapper (cfgWords cfg) slot n = .ok ((1430 * 2 ^ 40 + 1234) * 256 + 40)) := by
  intro h
  have hx := h (pinnedConfiguration ⟨0, by decide⟩) 100 (2 ^ 40)
  rw [compiled_index_out_of_range] at hx
  cases hx

/-- Kill-line: the empty sibling list is `invalidProof`, not a successful
`SSZ.verifyProof`. -/
theorem missing_sibling_kill_line (st : EVM.State) :
    SszProofCalldataLoop.verify 0 st (UInt256.ofNat 0) (UInt256.ofNat 0)
      (UInt256.ofNat 0) (UInt256.ofNat 0) 0 = .error .invalidProof :=
  empty_proof_is_invalidProof 0 st (UInt256.ofNat 0) (UInt256.ofNat 0)
    (UInt256.ofNat 0) (UInt256.ofNat 0)

/-- Kill-line: a `Branch` of length `n` and a `Branch` of length `n+1`
cannot authenticate the same index (`branch_depth`). Duplicate/extra
sibling. -/
theorem duplicate_sibling_kill_line :
    ¬ (∀ (α : Type) (hash : SszProofFold.Hash α) (index : Nat)
        (leaf sib root : α) (proof : List α),
        SszProofFold.Branch hash index leaf proof root →
        SszProofFold.Branch hash index leaf (sib :: proof) root) := by
  intro h
  have hroot : SszProofFold.Branch
      (fun _ _ : Nat => some (0 : Nat)) 1 0 [] 0 := .root 0
  exact extra_sibling_refutes_branch hroot (h Nat _ 1 0 0 0 [] hroot)

/-- Kill-line: when the loop has reduced the index to 1, a leaf that is
not the decoded root is `invalidProof` (`finish`, IR root compare). -/
theorem altered_leaf_kill_line (st : EVM.State) :
    SszProofCalldataLoop.finish (UInt256.ofNat 1)
      ⟨st, UInt256.ofNat 1, UInt256.ofNat 0, UInt256.ofNat 0, false⟩ =
        .error .invalidProof := by
  simp [SszProofCalldataLoop.finish]
  decide

#print axioms falsified_root_staticcall_kill_line
#print axioms falsified_root_kills_afterRoot_success
#print axioms out_of_range_index_kill_line
#print axioms out_of_range_index_kills_wrapper_success
#print axioms missing_sibling_kill_line
#print axioms duplicate_sibling_kill_line
#print axioms altered_leaf_kill_line

end LidoSRv3.Tests.SszCompiledEntryRollbackMutants
