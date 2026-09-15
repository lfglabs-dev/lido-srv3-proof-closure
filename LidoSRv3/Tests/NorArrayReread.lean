import LidoSRv3.Audit.Source.SigningKeys
import LidoSRv3.Audit.Source.SszWordBytes
import LidoSRv3.Audit.Source.ByteMemory

set_option maxRecDepth 16384
set_option maxHeartbeats 1000000

namespace LidoSRv3.Tests.NorArrayReread
open EvmYul LidoSRv3.Audit.Source.SigningKeys

private def u (n : Nat) : UInt256 := UInt256.ofNat n
private def initial : MachineState :=
  ({ (default : MachineState) with
    memory := (List.replicate 512 (0 : UInt8)).toByteArray,
    activeWords := u 16 }).mstore (u 128) (u 1)
private def keys (slot : UInt256) : UInt256 :=
  if slot.toNat = 10 then u 2 else u 0
private def copied : MachineState :=
  loadOne initial keys (u 10) (u 96) (u 224) (u 0) (u 0)

/-- NOR rereads `_nodeOperatorIds[i]` after loadKeysSigs at lines 855, 857,
and 858. If its array cell aliases the public-key destination, that read can
change. This is an unconstrained-pointer counterexample, not a claim that the
supported Solidity allocator produces this alias. A producer-derived memory
frame must exclude it before replacing the later reads with the original id. -/
theorem aliased_key_copy_changes_array_cell :
    (initial.mload (u 128)).1 = u 1 ∧
    (copied.mload (u 128)).1 = u 2 := by
  simp only [initial, copied, loadOne, MachineState.mload,
    MachineState.lookupMemory, MachineState.mstore, MachineState.writeWord,
    writeBytes, LidoSRv3.Audit.Source.SszWordBytes.actual_word_bytes]
  simp (disch := decide +kernel) only
    [LidoSRv3.Audit.Source.ByteMemory.write_in_bounds_bytes,
      LidoSRv3.Audit.Source.ByteMemory.read_in_bounds]
  decide +kernel

end LidoSRv3.Tests.NorArrayReread
