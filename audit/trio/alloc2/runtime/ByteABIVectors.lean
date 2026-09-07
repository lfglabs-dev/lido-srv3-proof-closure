import audit.trio.alloc2.runtime.ByteABIFrame

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes word byte)
private def hex (bytes : Bytes) : String :=
  "0x" ++ String.ofList (bytes.flatMap fun b =>
    [("0123456789abcdef".toList)[b.val / 16]!, ("0123456789abcdef".toList)[b.val % 16]!])
private def emit (name : String) (bytes : Bytes) : IO Unit := do
  let calldataResult := DenoteMemory.denoteMemoryOp
    (.calldatacopy 128 0 bytes.length (DenoteMemory.listByte bytes)) DenoteMemory.Memory.empty
  let returnResult := DenoteMemory.denoteMemoryOp
    (.returndatacopy 128 0 bytes.length bytes) DenoteMemory.Memory.empty
  match calldataResult, returnResult with
  | .ok cm, .ok rm =>
    IO.println ("ALLOC2_BYTE_COPY {\"name\":\"" ++ name ++ "\",\"input\":\"" ++ hex bytes ++
      "\",\"calldata\":\"" ++ hex (readBytes cm 128 bytes.length) ++
      "\",\"returndata\":\"" ++ hex (readBytes rm 128 bytes.length) ++ "\"}")
  | _, _ => throw (IO.userError "unexpected copy failure")
#eval do
  emit "empty" []
  emit "31-bytes" (List.range 31 |>.map byte)
  emit "33-bytes" (List.range 33 |>.map byte)
  emit "empty-arguments" (LibraryABI.encodeArguments ⟨[], [], word 3⟩)
  emit "ties-arguments" (LibraryABI.encodeArguments ⟨[zero, zero], [word 100, word 100], word 31⟩)
  emit "zero-short-arguments" (LibraryABI.encodeArguments ⟨[word 7], [], zero⟩)
  emit "return-array" (LibraryABI.encodeReturn ⟨word 31, [word 16, word 15]⟩)
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
