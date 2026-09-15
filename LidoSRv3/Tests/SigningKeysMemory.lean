import LidoSRv3.Audit.Source.SigningKeys
import LidoSRv3.Audit.Source.SszWordBytes
import LidoSRv3.Audit.Source.ByteMemory

set_option maxRecDepth 16384
set_option maxHeartbeats 1000000

namespace LidoSRv3.Tests.SigningKeysMemory
open EvmYul LidoSRv3.Audit.Source.SigningKeys

private def u (n : Nat) : UInt256 := UInt256.ofNat n
private def repeated (n count : Nat) : List UInt8 := List.replicate count (UInt8.ofNat n)
private def packed (bytes : List UInt8) : UInt256 :=
  u (bytes.foldl (fun acc b => 256 * acc + b.toNat) 0)
private def key : List UInt8 := (List.range 48).map fun i => UInt8.ofNat (i+1)
private def storage (slot : UInt256) : UInt256 :=
  if slot.toNat = 10 then packed (key.take 32)
  else if slot.toNat = 11 then packed (key.drop 32 ++ repeated 255 16)
  else if slot.toNat = 12 then packed (repeated 51 32)
  else if slot.toNat = 13 then packed (repeated 52 32)
  else if slot.toNat = 14 then packed (repeated 53 32)
  else u 0
private def dirty : MachineState :=
  { (default : MachineState) with
    memory := (repeated 165 512).toByteArray, activeWords := u 16 }
private def result : MachineState :=
  loadOne dirty storage (u 10) (u 96) (u 224) (u 0) (u 0)

/-- All 48 public-key bytes survive the overlap. Poison in the unused low half
of the second storage word must not leak into the result. -/
theorem key_overlap_and_shift :
    (result.memory.readWithPadding 128 48).data.toList = key := by
  simp only [result, loadOne, loadKeysSigs, loadLoop, loadIteration, MachineState.mstore,
    MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

theorem signature_and_frame :
    (result.memory.readWithPadding 256 96).data.toList =
      repeated 51 32 ++ repeated 52 32 ++ repeated 53 32 ∧
    result.memory.data.getD 127 0 = 165 ∧
    result.memory.data.getD 176 0 = 165 ∧
    result.memory.data.getD 255 0 = 165 ∧
    result.memory.data.getD 352 0 = 165 := by
  simp only [result, loadOne, loadKeysSigs, loadLoop, loadIteration, MachineState.mstore,
    MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

/-- Assembly permits aliasing: the later signature stores overwrite the key.
An independent pair of output lists would miss this source behavior. -/
theorem aliased_buffers_overwrite_key :
    ((loadOne dirty storage (u 10) (u 96) (u 96) (u 0) (u 0)).memory.readWithPadding
      128 48).data.toList = repeated 51 32 ++ repeated 52 16 := by
  simp only [result, loadOne, loadKeysSigs, loadLoop, loadIteration, MachineState.mstore,
    MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

/-- The addition of buffer offset and loop index wraps before multiplication. -/
theorem destination_index_wraps :
    ((loadOne dirty storage (u 10) (u 96) (u 224) (u (2^256-1)) (u 1)).memory.readWithPadding
      128 48).data.toList = key := by
  simp only [result, loadOne, loadKeysSigs, loadLoop, loadIteration, MachineState.mstore,
    MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

-- Concrete intermediate memories keep the loop controls compositional.
-- Each equality is proved from the actual mstore sequence before being reused.
private def zeroMemory : ByteArray :=
  (repeated 165 128 ++ repeated 0 48 ++ repeated 165 80 ++
    repeated 0 96 ++ repeated 165 160).toByteArray

private theorem zero_first_memory :
    (loadOne dirty storage (u 20) (u 96) (u 224) (u 0) (u 0)).memory = zeroMemory := by
  simp only [loadOne, MachineState.mstore, MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes]
  decide +kernel

private def pointerMemory : ByteArray :=
  (repeated 165 64 ++ repeated 0 30 ++ [4, 0] ++ repeated 165 416).toByteArray

private theorem pointer_memory :
    (dirty.mstore (u 64) (u 1024)).memory = pointerMemory := by
  simp only [MachineState.mstore, MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes]
  decide +kernel

/-- Two iterations advance destinations and wrap the source key index. -/
theorem loop_source_index_wraps :
    let offset : KeyOffset := fun machine _ _ index => ((if index.toNat = 0 then u 10 else u 20), machine)
    let after := loadKeysSigs dirty storage offset (u 0) (u 0) (u (2^256-1))
      (u 2) (u 96) (u 224) (u 0)
    (after.memory.readWithPadding 128 96).data.toList = repeated 0 48 ++ key := by
  change ((loadOne (loadOne dirty storage (u 20) (u 96) (u 224) (u 0) (u 0))
    storage (u 10) (u 96) (u 224) (u 0) (u 1)).memory.readWithPadding
      128 96).data.toList = repeated 0 48 ++ key
  generalize first_eq : loadOne dirty storage (u 20) (u 96) (u 224) (u 0) (u 0) = first
  have memory_eq : first.memory = zeroMemory := by
    rw [← first_eq]
    exact zero_first_memory
  simp only [loadOne, MachineState.mstore, MachineState.writeWord, writeBytes,
    memory_eq, LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

/-- Consecutive storage slots use EVM word addition, including wrap at 2^256. -/
theorem storage_slot_wraps :
    let wrappedStorage : LidoSRv3.Audit.Source.SigningKeys.Storage := fun slot =>
      if slot.toNat = 0 then packed (repeated 77 16 ++ repeated 255 16) else u 0
    ((loadOne dirty wrappedStorage (u (2^256-1)) (u 96) (u 224) (u 0) (u 0)).memory.readWithPadding
      128 48).data.toList = repeated 0 32 ++ repeated 77 16 := by
  simp only [result, loadOne, loadKeysSigs, loadLoop, loadIteration, MachineState.mstore,
    MachineState.writeWord, writeBytes,
    LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

/-- The slot producer's ABI encoding can change memory. Discarding its updated
machine would lose this free-memory-pointer write. -/
theorem slot_producer_memory_survives :
    let offset : KeyOffset := fun machine _ _ _ =>
      (u 10, machine.mstore (u 64) (u 1024))
    let after := loadKeysSigs dirty storage offset (u 0) (u 0) (u 0)
      (u 1) (u 96) (u 224) (u 0)
    (after.memory.readWithPadding 64 32).data.toList = repeated 0 30 ++ [4, 0] := by
  change ((loadOne (dirty.mstore (u 64) (u 1024)) storage (u 10)
    (u 96) (u 224) (u 0) (u 0)).memory.readWithPadding 64 32).data.toList =
      repeated 0 30 ++ [4, 0]
  generalize first_eq : dirty.mstore (u 64) (u 1024) = first
  have memory_eq : first.memory = pointerMemory := by
    rw [← first_eq]
    exact pointer_memory
  simp only [loadOne, MachineState.mstore, MachineState.writeWord, writeBytes,
    memory_eq, LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

end LidoSRv3.Tests.SigningKeysMemory
