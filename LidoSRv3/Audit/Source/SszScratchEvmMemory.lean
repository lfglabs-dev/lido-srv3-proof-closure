import LidoSRv3.Audit.Source.SszScratchByteArray
import LidoSRv3.Audit.Source.SszValidatorLeaf

/-!
BLS.sol:538-550 at Lido pin 17005714f151e5502c559932319a3f2f74ac2436:
after the length-48 guard, `mstore(0x20, 0); calldatacopy(0, pubkey.offset, 48)`.
The program below calls the EXISTING EvmYul primitives on the actual shared
state and actual execution-environment calldata. Its specification is the SSZ
48-byte key followed by sixteen zero bytes, independently of dirty old memory.
This proves the primitive memory block, not gas-charged EVM.X execution, the
Solidity ABI decoder, SHA execution, returndata copying, or a BLS root result.
-/
namespace LidoSRv3.Audit.Source.SszScratchEvmMemory
open EvmYul SszScratchByteArray

/-- The two source operations, with their original order and literal sizes. -/
def scratch {τ : OperationType} (st : SharedState τ) (offset : UInt256) : SharedState τ :=
  let cleared : SharedState τ :=
    { st with toMachineState := st.toMachineState.mstore (UInt256.ofNat 32) (UInt256.ofNat 0) }
  cleared.calldatacopy (UInt256.ofNat 0) offset (UInt256.ofNat 48)

/-- Independent expected SHA input, sliced from the original raw calldata. -/
def rawBlock (raw : ByteArray) (offset : Nat) : ByteArray :=
  raw.extract offset (offset + 48) ++ zeros 16

theorem rawBlock_size (raw : ByteArray) (offset : Nat) (hfit : offset + 48 ≤ raw.size) :
    (rawBlock raw offset).size = 64 := by
  simp only [rawBlock, ByteArray.size_append, zeros_size, ByteArray.size_extract]
  omega

/-- Complete final-memory normal form; dirty bytes beyond scratch are retained. -/
theorem memory_exact {τ : OperationType} (st : SharedState τ) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size) :
    (scratch st offset).memory = rawBlock st.executionEnv.calldata offset.toNat ++
      st.memory.extract 64 st.memory.size := by
  apply ByteArray.ext
  change (st.executionEnv.calldata.write offset.toNat
    ((UInt256.ofNat 0).toByteArray.write 0 st.memory 32 32) 0 48).data = _
  rw [word_zero, scratch_shape _ _ _ hfit]
  simp [rawBlock, zeros]

/-- Universal readback through the actual EvmYul padded memory reader. No read,
copy result, or zero-initialized scratch premise is assumed. -/
theorem read_exact {τ : OperationType} (st : SharedState τ) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size) :
    (scratch st offset).memory.readWithPadding 0 64 =
      rawBlock st.executionEnv.calldata offset.toNat := by
  rw [memory_exact st offset hfit]
  exact read_prefix _ _ (rawBlock_size _ _ hfit)

/-- Independent pointwise frame using zero-extended byte observations. -/
theorem frame {τ : OperationType} (st : SharedState τ) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size) (i : Nat) (hi : 64 ≤ i) :
    (scratch st offset).memory.data.getD i 0 = st.memory.data.getD i 0 := by
  rw [memory_exact st offset hfit]
  simp only [ByteArray.data_append, ByteArray.data_extract]
  exact frame_byte (rawBlock st.executionEnv.calldata offset.toNat) st.memory
    (rawBlock_size _ _ hfit) i hi

/-- Exact memory allocation follows from the writes, including initially short
arrays. This is byte-array length, distinct from EVM memory-expansion gas. -/
theorem memory_size {τ : OperationType} (st : SharedState τ) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size) :
    (scratch st offset).memory.size = max 64 st.memory.size := by
  rw [memory_exact st offset hfit]
  simp only [ByteArray.size_append, rawBlock_size _ _ hfit, ByteArray.size_extract,
    Nat.min_self]
  omega

/-- The primitives retain the world/environment and prior call-result buffers.
They do not debit gas; charging by EVM.X remains outside this block theorem. -/
theorem context_preserved {τ : OperationType} (st : SharedState τ) (offset : UInt256) :
    (scratch st offset).toState = st.toState ∧
    (scratch st offset).gasAvailable = st.gasAvailable ∧
    (scratch st offset).returnData = st.returnData ∧
    (scratch st offset).H_return = st.H_return := by
  exact ⟨rfl, rfl, rfl, rfl⟩

/-- Raw byte-to-typed-byte interpretation; no encoded key is an input premise. -/
def typedBytes (bytes : ByteArray) : List SszValidatorLeaf.Byte :=
  bytes.data.toList.map UInt8.toBitVec

/-- A concrete prefix/key/suffix layout derives the readback's connection to
`pubkeyBlock`. The byte offset and key extent express the ABI-layout boundary;
this theorem does not claim to execute the Solidity ABI decoder. -/
theorem typed_pubkeyBlock {τ : OperationType} (st : SharedState τ) (offset : UInt256)
    (prebytes pubkey suffix : ByteArray)
    (hlayout : st.executionEnv.calldata = prebytes ++ pubkey ++ suffix)
    (hoffset : offset.toNat = prebytes.size) (hlen : pubkey.size = 48) :
    typedBytes ((scratch st offset).memory.readWithPadding 0 64) =
      SszValidatorLeaf.pubkeyBlock (typedBytes pubkey) := by
  have hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size := by
    rw [hlayout, hoffset]
    simp only [ByteArray.size_append, hlen]
    omega
  rw [read_exact st offset hfit]
  have hslice : st.executionEnv.calldata.extract offset.toNat (offset.toNat + 48) = pubkey := by
    rw [hlayout, hoffset]
    apply ByteArray.ext
    simp [-ByteArray.size_data, ByteArray.data_extract, ByteArray.data_append,
      Array.extract_append, ByteArray.size] at hlen ⊢
    rw [hlen]
    simp
    right
    change pubkey.data.size ≤ 48
    omega
  simp [typedBytes, rawBlock, hslice, SszValidatorLeaf.pubkeyBlock, zeros]

end LidoSRv3.Audit.Source.SszScratchEvmMemory
