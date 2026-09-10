import LidoSRv3.Audit.Source.SszProofCommitted

/-! Cursor and guard regressions, checked by the kernel. The cursor fixtures
are not claims that the compiled ABI decoder admits those arbitrary offsets.
Opaque SHA execution is covered by inherited, separately recorded Solidity
tests; it is not evaluated by these Lean fixtures. -/
namespace LidoSRv3.Tests.SszProofCommittedRegression
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszProofCommitted SszProofCalldataStep

theorem contiguous_two_words (raw : ByteArray) :
    proofWords 2 raw (UInt256.ofNat 0) (endOffset (UInt256.ofNat 0) 2) =
      [rawWord raw (UInt256.ofNat 0),rawWord raw (UInt256.ofNat 32)] := by rfl

/-- The actual unsigned continuation can stop before its supplied round bound.
This is why the consumer does not silently equate consumed and declared lists. -/
theorem wrapped_early_stop (raw : ByteArray) :
    proofWords 4 raw (UInt256.ofNat (2^256-96))
      (endOffset (UInt256.ofNat (2^256-96)) 4) =
      [rawWord raw (UInt256.ofNat (2^256-96))] := by rfl

theorem wrapped_two_words (raw : ByteArray) :
    proofWords 2 raw (UInt256.ofNat (2^256-32))
      (endOffset (UInt256.ofNat (2^256-32)) 2) =
      [rawWord raw (UInt256.ofNat (2^256-32)),rawWord raw (UInt256.ofNat 0)] := by rfl

example (raw : ByteArray) : (proofWords 4 raw (UInt256.ofNat (2^256-96))
    (endOffset (UInt256.ofNat (2^256-96)) 4)).length ≠ 4 := by
  rw [wrapped_early_stop]
  change (1 : Nat) ≠ 4
  decide +kernel

example (raw : ByteArray) : (proofWords 2 raw (UInt256.ofNat (2^256-32))
    (endOffset (UInt256.ofNat (2^256-32)) 2)).length = 2 := by
  rw [wrapped_two_words]
  rfl

example (fuel : Nat) (st : EVM.State) (rawIndex leaf root offset : UInt256) :
    SszProofCalldataLoop.verify fuel st rawIndex leaf root offset 0 = .error .invalidProof := by rfl

example (fuel : Nat) (st : EVM.State) (leaf offset ending : UInt256) :
    sourceStep fuel st (UInt256.ofNat 1) leaf offset ending = .error .extraItem := by
  exact sourceStep_extra fuel st _ leaf offset ending (by decide +kernel)

example (fuel : Nat) (st : EVM.State) (leaf offset ending : UInt256) :
    SszProofCalldataLoop.loop 0 fuel st (UInt256.ofNat 2) leaf offset ending =
      .error .engineFailure := by rfl

#print axioms contiguous_two_words
#print axioms wrapped_early_stop
#print axioms wrapped_two_words
#print axioms SszProofCommitted.run_success_branch
end LidoSRv3.Tests.SszProofCommittedRegression
