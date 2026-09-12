import LidoSRv3.Audit.Source.SszProofCalldataLoop

namespace LidoSRv3.Tests.SszProofCalldataLoopMutants
open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open SszProofCalldataLoop SszProofCalldataStep SszProofLoopResources SszShaCallMemory

private def cold (gas : Nat) : EVM.State := { (default : EVM.State) with gasAvailable := UInt256.ofNat gas }
private def warm (gas : Nat) : EVM.State :=
  { cold gas with substate := ((cold gas).addAccessedAccount shaAddress).substate }
private def cap (st : EVM.State) : Nat :=
  Ccallgas shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable st.accountMap st.toMachineState st.substate
private def fee (st : EVM.State) : Nat :=
  Ccall shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable st.accountMap st.toMachineState st.substate

-- Real engine gas cap: the EIP-150 retained unit matters at both thresholds.
example : cap (cold 2684) = 83 := by decide +kernel
example : cap (cold 2685) = 84 := by decide +kernel
example : fee (cold 2685) = 2684 := by decide +kernel
example : cap (warm 184) = 83 := by decide +kernel
example : cap (warm 185) = 84 := by decide +kernel
example : fee (warm 185) = 184 := by decide +kernel
example : Caccess shaAddress (cold 2685).substate = 2600 := by decide +kernel
example : Caccess shaAddress (warm 185).substate = 100 := by decide +kernel
example : budget 0 = 1 := by decide +kernel
example : budget 1 = 2685 := by decide +kernel
example : budget 2 = 5369 := by decide +kernel
example : budget 247 = 662949 := by decide +kernel
example : budget 2 ≠ 2685 := by decide +kernel
example : 2684 * 247 < budget 247 := by decide +kernel
example : budget 248 > 662949 := by decide +kernel

private def tag (out : Except StepError StepResult) : Option StepError :=
  match out with | .error e => some e | .ok _ => none
private def vtag (out : Except VerifyError EVM.State) : Option VerifyError :=
  match out with | .error e => some e | .ok _ => none
private def zero : UInt256 := UInt256.ofNat 0
private def one : UInt256 := UInt256.ofNat 1

-- Loop interpreter fuel is distinct from the +2 CALL/Theta fuel argument.
example : tag (loop 0 10 (cold 100000) (UInt256.ofNat 4) zero zero (UInt256.ofNat 64)) = some .engineFailure := by rfl
example : tag (loop 3 0 (cold 100000) zero zero zero (UInt256.ofNat 96)) = some .extraItem := by
  rw [loop_extra _ _ _ _ _ _ _ (by decide +kernel)];rfl
example : tag (loop 3 0 (cold 100000) one zero zero (UInt256.ofNat 96)) = some .extraItem := by
  rw [loop_extra _ _ _ _ _ _ _ (by decide +kernel)];rfl
example : tag (loop 2 0 {cold 100000 with executionEnv := {(cold 100000).executionEnv with depth := 1024}}
    (UInt256.ofNat 4) zero zero (UInt256.ofNat 64)) = some .hashFailure := by rfl

-- Empty guard wins over decoded index and depth faults; metadata are discarded.
example : vtag (verify 0 (cold 0) zero zero one zero 0) = some .invalidProof := by rfl
example : vtag (verify 0 (cold 0) (UInt256.ofNat 511) zero one zero 0) = some .invalidProof := by rfl
example : vtag (verify 0 (cold 100000) (UInt256.ofNat 255) zero one zero 2) = some .extraItem := by rfl
example : vtag (verify 0 (cold 100000) (UInt256.ofNat 511) zero one zero 2) = some .extraItem := by rfl
example : vtag (verify 0 {cold 100000 with executionEnv := {(cold 100000).executionEnv with depth := 1024}}
    (UInt256.ofNat (4*256+99)) zero one zero 2) = some .hashFailure := by rfl

-- Standalone final-stage priority, not a constructed successful hash execution.
private def result (index leaf : Nat) : StepResult :=
  ⟨cold 100000,UInt256.ofNat index,UInt256.ofNat leaf,zero,false⟩
example : vtag (finish one (result 2 0)) = some .missingItem := by rfl
example : vtag (finish one (result 2 1)) = some .missingItem := by rfl
example : vtag (finish one (result 1 0)) = some .invalidProof := by rfl
example : vtag (finish one (result 1 1)) = none := by rfl
example : vtag (finish one (result 0 1)) = some .missingItem := by rfl

#print axioms call_admitted
#print axioms call_observations
#print axioms returned_gas
#print axioms call_resource
#print axioms step_resources
#print axioms step_complete
#print axioms loop_refines
#print axioms verify_success_iff
#print axioms decoded_branch_budget
#print axioms verify_empty
end LidoSRv3.Tests.SszProofCalldataLoopMutants
