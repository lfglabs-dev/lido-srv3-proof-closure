import LidoSRv3.Audit.Source.SszScratchEvmMemory

set_option maxRecDepth 4096

namespace LidoSRv3.Tests.SszScratchEvmMemoryMutants
open EvmYul LidoSRv3.Audit.Source
open SszScratchEvmMemory SszScratchByteArray

private def key : ByteArray := ((List.range 48).map fun i => UInt8.ofNat (i + 1)).toByteArray
private def raw (off : Nat) : ByteArray :=
  (List.replicate off (250 : UInt8)).toByteArray ++ key ++
    (List.replicate 64 (251 : UInt8)).toByteArray
private def fixture (oldSize off : Nat) : SharedState .EVM :=
  { (default : SharedState .EVM) with
    memory := (List.replicate oldSize (165 : UInt8)).toByteArray
    executionEnv.calldata := raw off }

private theorem vector (oldSize : Nat) :
    (scratch (fixture oldSize 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 =
      key ++ zeros 16 := by
  rw [read_exact _ _ (by change (UInt256.ofNat 7).toNat + 48 ≤ (raw 7).size; decide +kernel)]
  change rawBlock (raw 7) (UInt256.ofNat 7).toNat = key ++ zeros 16
  decide +kernel

-- Short, boundary, and long dirty memories all exercise the actual primitive block.
example : (scratch (fixture 0 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 0
example : (scratch (fixture 1 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 1
example : (scratch (fixture 31 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 31
example : (scratch (fixture 32 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 32
example : (scratch (fixture 47 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 47
example : (scratch (fixture 48 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 48
example : (scratch (fixture 63 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 63
example : (scratch (fixture 64 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 64
example : (scratch (fixture 65 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 65
example : (scratch (fixture 256 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64 = key ++ zeros 16 := vector 256

-- Distinct raw offsets, including an empty prefix and a prefix exceeding a word.
example : (scratch (fixture 129 0) (UInt256.ofNat 0)).memory.readWithPadding 0 64 = key ++ zeros 16 := by
  rw [read_exact _ _ (by decide +kernel)]
  decide +kernel
example : (scratch (fixture 0 257) (UInt256.ofNat 257)).memory.readWithPadding 0 64 = key ++ zeros 16 := by
  rw [read_exact _ _ (by decide +kernel)]
  decide +kernel

example : typedBytes ((scratch (fixture 129 7) (UInt256.ofNat 7)).memory.readWithPadding 0 64) =
    SszValidatorLeaf.pubkeyBlock (typedBytes key) := by
  exact typed_pubkeyBlock _ _ ((List.replicate 7 (250 : UInt8)).toByteArray) key
    ((List.replicate 64 (251 : UInt8)).toByteArray) rfl (by decide +kernel) (by decide +kernel)

-- Every one of the 48 key positions survives, including the partial second word.
example : ∀ i : Fin 48,
    (scratch (fixture 129 7) (UInt256.ofNat 7)).memory.data.getD i.val 0 = UInt8.ofNat (i.val + 1) := by
  rw [memory_exact _ _ (by decide +kernel)]
  decide +kernel

-- All sixteen padding bytes are cleared despite dirty old memory and a dirty suffix.
example : ∀ i : Fin 16,
    (scratch (fixture 129 7) (UInt256.ofNat 7)).memory.data.getD (48 + i.val) 255 = 0 := by
  rw [memory_exact _ _ (by decide +kernel)]
  decide +kernel

example : (scratch (fixture 129 7) (UInt256.ofNat 7)).memory.data.getD 64 0 = 165 := by
  rw [frame _ _ (by decide +kernel) _ (by omega)]
  decide +kernel
example : (scratch (fixture 129 7) (UInt256.ofNat 7)).memory.data.getD 96 0 = 165 := by
  rw [frame _ _ (by decide +kernel) _ (by omega)]
  decide +kernel
example : (scratch (fixture 1 7) (UInt256.ofNat 7)).memory.data.getD 999 0 = 0 := by
  rw [frame _ _ (by decide +kernel) _ (by omega)]
  decide +kernel

-- Wrong ABI offset: copying from the prefix produces a different key byte.
example : (scratch (fixture 129 7) (UInt256.ofNat 6)).memory.data.getD 0 0 ≠ 1 := by
  rw [memory_exact _ _ (by decide +kernel)]
  decide +kernel
example : (scratch (fixture 129 7) (UInt256.ofNat 8)).memory.data.getD 0 0 ≠ 1 := by
  rw [memory_exact _ _ (by decide +kernel)]
  decide +kernel

/-- Real primitive variant used only to kill length/destination mutants. -/
private def changedCopy (st : SharedState .EVM) (n dest : Nat) : SharedState .EVM :=
  let cleared : SharedState .EVM :=
    { st with toMachineState := st.toMachineState.mstore (UInt256.ofNat 32) (UInt256.ofNat 0) }
  cleared.calldatacopy (UInt256.ofNat dest) (UInt256.ofNat 7) (UInt256.ofNat n)

-- Copying one word loses key byte 33. A 64-byte copy contaminates zero padding.
example : (changedCopy (fixture 129 7) 32 0).memory.data.getD 32 0 ≠ 33 := by
  change ((raw 7).write 7 ((UInt256.ofNat 0).toByteArray.write 0 (fixture 129 7).memory 32 32) 0 32).data.getD 32 0 ≠ 33
  rw [word_zero, write_fit _ _ 7 0 32 (by omega) (by decide +kernel) (by omega)]
  simp only [ByteArray.size, clear_shape]
  decide +kernel

example : (changedCopy (fixture 129 7) 64 0).memory.data.getD 48 0 ≠ 0 := by
  change ((raw 7).write 7 ((UInt256.ofNat 0).toByteArray.write 0 (fixture 129 7).memory 32 32) 0 64).data.getD 48 0 ≠ 0
  rw [word_zero, write_fit _ _ 7 0 64 (by omega) (by decide +kernel) (by omega)]
  simp only [ByteArray.size, clear_shape]
  decide +kernel

example : (changedCopy (fixture 129 7) 48 32).memory.data.getD 0 0 ≠ 1 := by
  change ((raw 7).write 7 ((UInt256.ofNat 0).toByteArray.write 0 (fixture 129 7).memory 32 32) 32 48).data.getD 0 0 ≠ 1
  rw [word_zero, write_fit _ _ 7 32 48 (by omega) (by decide +kernel) (by omega)]
  simp only [ByteArray.size, clear_shape]
  decide +kernel

-- Omitted clear leaves byte 48 dirty, using the actual CALLDATACOPY primitive.
example : ((fixture 129 7).calldatacopy (UInt256.ofNat 0) (UInt256.ofNat 7)
    (UInt256.ofNat 48)).memory.data.getD 48 0 ≠ 0 := by
  change ((raw 7).write 7 (fixture 129 7).memory 0 48).data.getD 48 0 ≠ 0
  rw [write_fit _ _ 7 0 48 (by omega) (by decide +kernel) (by omega)]
  decide +kernel

-- Reversing the actual operations overwrites bytes 32..47 of the copied key.
example : (((fixture 129 7).calldatacopy (UInt256.ofNat 0) (UInt256.ofNat 7)
    (UInt256.ofNat 48)).toMachineState.mstore (UInt256.ofNat 32)
      (UInt256.ofNat 0)).memory.data.getD 32 0 ≠ 33 := by
  change ((UInt256.ofNat 0).toByteArray.write 0 ((raw 7).write 7 (fixture 129 7).memory 0 48) 32 32).data.getD 32 0 ≠ 33
  rw [word_zero, clear_shape, write_fit _ _ 7 0 48 (by omega) (by decide +kernel) (by omega)]
  simp only [ByteArray.size, write_fit (raw 7) (fixture 129 7).memory 7 0 48 (by omega) (by decide +kernel) (by omega)]
  decide +kernel

#print axioms SszScratchByteArray.write_fit
#print axioms SszScratchByteArray.word_zero
#print axioms SszScratchByteArray.scratch_shape
#print axioms SszScratchEvmMemory.memory_exact
#print axioms SszScratchEvmMemory.read_exact
#print axioms SszScratchEvmMemory.frame
#print axioms SszScratchEvmMemory.memory_size
#print axioms SszScratchEvmMemory.typed_pubkeyBlock

end LidoSRv3.Tests.SszScratchEvmMemoryMutants
