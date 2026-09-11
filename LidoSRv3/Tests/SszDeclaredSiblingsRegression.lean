import LidoSRv3.Audit.Guarantees.PSsz1DeclaredSiblings
set_option autoImplicit false
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000
namespace LidoSRv3.Tests.SszDeclaredSiblingsRegression
open EvmYul EvmYul.EVM Audit.Source SszProofCommitted SszDeclaredSiblings SszWrapperIndex TrioReserve1

def bytes : ByteArray := ⟨(List.range 160 |>.map UInt8.ofNat).toArray⟩
def u := UInt256.ofNat

theorem ordinary_aligned : proofWords 4 bytes (u 0) (endOffset (u 0) 4) = declaredWords bytes (u 0) 4 := by first | rfl | (constructor <;> rfl) | decide +kernel
theorem ordinary_unaligned : proofWords 4 bytes (u 3) (endOffset (u 3) 4) = declaredWords bytes (u 3) 4 := by first | rfl | (constructor <;> rfl) | decide +kernel
theorem final_endpoint_equality : (advance (u 3) 4 < endOffset (u 3) 4) = False := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem immediate_wrap_complete : proofWords 4 bytes (u (2^256-16)) (endOffset (u (2^256-16)) 4) =
    declaredWords bytes (u (2^256-16)) 4 ∧
    (proofWords 4 bytes (u (2^256-16)) (endOffset (u (2^256-16)) 4)).length = 4 := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem exact_initial_wrap : proofWords 3 bytes (u (2^256-32)) (endOffset (u (2^256-32)) 3) =
    [rawWord bytes (u (2^256-32)),rawWord bytes (u 0),rawWord bytes (u 32)] := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem later_wrap_exits_first : proofWords 4 bytes (u (2^256-64)) (endOffset (u (2^256-64)) 4) =
    [rawWord bytes (u (2^256-64))] ∧
    (declaredWords bytes (u (2^256-64)) 4).length = 4 := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem wrapped_endpoint_zero : proofWords 4 bytes (u (2^256-128)) (endOffset (u (2^256-128)) 4) =
    [rawWord bytes (u (2^256-128))] := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem zero_count_view : proofWords 0 bytes (u 7) (endOffset (u 7) 0) = [] ∧ declaredWords bytes (u 7) 0 = [] := by first | rfl | (constructor <;> rfl) | decide +kernel
theorem one_count_view : proofWords 1 bytes (u (2^256-16)) (endOffset (u (2^256-16)) 1) =
    declaredWords bytes (u (2^256-16)) 1 := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem maximal_count_arithmetic :
    32*(2^64-1) < UInt256.size ∧
    ((2^256-16)+32*(2^64-2)) % UInt256.size < ((2^256-16)+32*(2^64-1)) % UInt256.size := by first | rfl | (constructor <;> rfl) | decide +kernel

theorem maximal_count_dichotomy (raw : ByteArray) (offset : UInt256) :
    proofWords (2^64-1) raw offset (endOffset offset (2^64-1)) = [rawWord raw offset] ∨
    proofWords (2^64-1) raw offset (endOffset offset (2^64-1)) = declaredWords raw offset (2^64-1) :=
  cursor_dichotomy raw offset (2^64-1) (by decide) maximal_count_arithmetic.1

-- Exact retained successful IO/FFI vector bytes. Pure indexed-list/byte checks below
-- are kernel proofs; opaque SHA whole-entry success is retained IO evidence.
def vectorCalldata : ByteArray := ⟨#[46,119,180,186,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,123,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,192,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,210,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,18,52,86,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,115,89,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,22,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,119,170,194,155,113,111,250,205,50,208,199,253,6,106,99,139,242,66,140,77,215,76,58,65,38,248,141,171,239,53,232,105,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,48,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]⟩
def vectorReply : ByteArray := ⟨#[236,183,182,168,41,215,72,130,157,239,164,79,209,128,132,107,8,235,255,173,212,191,179,7,244,47,210,66,213,129,251,124]⟩
def vectorContext : EVM.State := { (default : EVM.State) with
  gasAvailable := u 10000000
  memory := ⟨#[1,2,3]⟩
  executionEnv := { (default : EVM.State).executionEnv with calldata := vectorCalldata, codeOwner := ⟨99,by decide⟩ } }
def vectorWorld : Live.World := ⟨{Verity.defaultState with codeSize := fun _ => Live.word 1},fun _ => 0,[]⟩
def vectorExternal : StaticCall.External := fun req _ =>
  if req = SszRootCall.request (Verity.Core.Address.ofNat 99) (BitVec.ofNat 64 123)
  then .success vectorReply.data.toList else .rejected []

theorem retained_header_bytes : (vectorCalldata.data.toList.drop 100).take 32 = List.replicate 31 0 ++ [192] := by decide +kernel
theorem retained_count_bytes : (vectorCalldata.data.toList.drop 452).take 32 = List.replicate 31 0 ++ [50] := by decide +kernel

theorem retained_complete_list : proofWords 50 vectorCalldata (u 484) (endOffset (u 484) 50) =
    declaredWords vectorCalldata (u 484) 50 ∧ (declaredWords vectorCalldata (u 484) 50).length = 50 := by constructor <;> rfl

theorem retained_penultimate_index : (declaredWords vectorCalldata (u 484) 50)[48]? = some (rawWord vectorCalldata (u 2020)) :=
  declared_get vectorCalldata (u 484) 50 48 (by decide)

-- Exact archived bytes equal the independently computed SHA256(slotLE||proposerLE).
-- This does not evaluate or axiomatize the engine's opaque SHA/zero-padding FFI.
theorem retained_penultimate_bytes : (vectorCalldata.data.toList.drop 2020).take 32 = [119,170,194,155,113,111,250,205,50,208,199,253,6,106,99,139,242,66,140,77,215,76,58,65,38,248,141,171,239,53,232,105] := by decide +kernel

/-- The new whole-entry public theorem specialized to the exact retained vector
and caller/root context. h is exactly the prior whole-run success statement;
its archived IO diagnostic is not upgraded into a kernel execution theorem. -/
def public_retained_vector (afterState : EVM.State)
    (h : (SszCompiledClEntry.run 100 (pinnedConfiguration ⟨0,by decide⟩) vectorExternal vectorWorld vectorContext).outcome = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :=
  Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch 100
    (pinnedConfiguration ⟨0,by decide⟩) vectorExternal vectorWorld vectorContext afterState h hffi

#print axioms maximal_count_dichotomy
#print axioms public_retained_vector
end LidoSRv3.Tests.SszDeclaredSiblingsRegression
