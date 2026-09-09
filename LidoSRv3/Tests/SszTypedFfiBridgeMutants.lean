import LidoSRv3.Audit.Source.SszTypedFfiBridge
namespace LidoSRv3.Tests.SszTypedFfiBridgeMutants
open EvmYul LidoSRv3.Audit.Source SszTypedFfiBridge SszValidatorLeaf

-- Kernel checks normalize through the proved codec bridge, with independent
-- byte-position expectations and a metadata-stripping regression.
example : (bytes (digestBytes (BitVec.ofNat 256 1))).data[31]! = 1 := by rw [digest_bytes];decide +kernel
example : (bytes (digestBytes (BitVec.ofNat 256 1))).data[0]! = 0 := by rw [digest_bytes];decide +kernel
example : (bytes (digestBytes (BitVec.ofNat 256 (2^248)))).data[0]! = 1 := by rw [digest_bytes];decide +kernel
example : (bytes (digestBytes (BitVec.ofNat 256 (2^248)))).data[31]! = 0 := by rw [digest_bytes];decide +kernel
example : bytes (digestBytes (BitVec.ofNat 256 (2^255))) ≠ bytes (digestBytes (BitVec.ofNat 256 128)) := by
  rw [digest_bytes,digest_bytes];decide +kernel
example : (toWord (BitVec.ofNat 256 (2^256-1))).toNat = 2^256-1 := by decide +kernel
example : (typedIndex (UInt256.ofNat (1430*2^40*256+255))).val = 1430*2^40 := by decide +kernel
example : (typedIndex (UInt256.ofNat (1430*2^40*256+255))).val ≠ 1430*2^40*256+255 := by decide +kernel


#print axioms digest_bytes
#print axioms digest_actual_word
#print axioms pair_transport
#print axioms proof_bytes
#print axioms branch_transport
#print axioms primitive_typed_success
end LidoSRv3.Tests.SszTypedFfiBridgeMutants
