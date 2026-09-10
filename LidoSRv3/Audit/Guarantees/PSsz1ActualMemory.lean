import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Source.SszCompiledMerkle

/-! Public SSZ-1 consumer of the initialized allocator/store/load/SHA pipeline.
The real proof loop consumes its computed typed leaf on the same frame.
The list is the actual consumed proof words; the full CL entry and complete
ABI-declared-list connection remain separate required obligations. -/
namespace LidoSRv3.Audit.Guarantees.PSsz1
open EvmYul EvmYul.EVM Source

theorem actual_memory_validator_branch (fuel : Nat) (context afterState : EVM.State)
    (h : SszCompiledConsumer.run fuel context = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :
    ∃ head keySlice f branch,
      SszWitnessAbi.header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧
      keySlice.length = 48 ∧ SszWitnessAbi.FieldsMatch context head f ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      branch.length ≤ 2^64-1 ∧
      let words := SszProofCommitted.proofWords branch.length context.executionEnv.calldata
        branch.offset (SszProofCommitted.endOffset branch.offset branch.length)
      words ≠ [] ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair
        (SszProofCalldataStep.decodeIndex (context.calldataload (UInt256.ofNat 100))).toNat
        (SszProofCommitted.validatorLeaf context keySlice.offset f) words
        (context.calldataload (UInt256.ofNat 68)) ∧
      afterState.executionEnv = context.executionEnv ∧ afterState.activeWords.toNat ≤ 20 :=
  SszCompiledMerkle.run_success_branch fuel context afterState h hffi

#print axioms actual_memory_validator_branch
end LidoSRv3.Audit.Guarantees.PSsz1
