import LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix
import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-! Early parent failures: real division then emitted allocation guards. These
vectors stop before producer module calls; no successful producer is stubbed. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.MemoryVectors
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes word encodeWord byte)
private def hex (bytes : Bytes) : String := "0x" ++ String.ofList (bytes.flatMap fun b =>
  [("0123456789abcdef".toList)[b.val/16]!, ("0123456789abcdef".toList)[b.val%16]!])
private def early (count unit amount : Word) : Except Nat Word := do
  let _ ← (checkedDiv amount unit).mapError fun _ => 0x12
  (MemoryPrefix.execute (word 128) count).mapError fun _ => 0x41
private def emit (name : String) (count unit amount : Nat) : IO Unit := do
  let code ← match early (word count) (word unit) (word amount) with
    | .error code => pure code
    | .ok _ => throw (IO.userError "early memory vector unexpectedly reached producer calls")
  let data := [byte 0x4e,byte 0x48,byte 0x7b,byte 0x71] ++ encodeWord (word code)
  IO.println ("ALLOC2_MEMORY_VECTOR {\"name\":\"" ++ name ++ "\",\"count\":\"" ++ toString count ++
    "\",\"unit\":\"" ++ toString unit ++ "\",\"amount\":\"" ++ toString amount ++
    "\",\"reverted\":true,\"actual\":\"" ++ hex data ++ "\",\"calls\":[]}")
#eval do
  emit "memory-max-count" (2^256-1) 32 0
  emit "memory-length-limit" (2^64) 32 0
  emit "memory-size-limit" (2^59) 32 0
  emit "division-before-memory-limit" (2^64) 0 320
end LidoSRv3.Audit.Source.TrioAlloc2.MemoryVectors
