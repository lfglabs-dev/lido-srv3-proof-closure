import audit.trio.alloc2.runtime.ByteWordCopy
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes byte)
private def hex (bytes : Bytes) : String :=
  "0x" ++ String.ofList (bytes.flatMap fun b =>
    [("0123456789abcdef".toList)[b.val / 16]!, ("0123456789abcdef".toList)[b.val % 16]!])
private def emit (name : String) (offset count : Nat) : IO Unit := do
  let bytes := (List.range (offset+32*count+17)).map (fun i => byte (17*i+3))
  let memory := DenoteMemory.Memory.empty.copyFrom (DenoteMemory.listByte bytes) 128 0 bytes.length
  let dest := memory.size+64
  let copied := copyWords memory (128+offset) dest count
  IO.println ("ALLOC2_WORD_COPY {\"name\":\"" ++ name ++ "\",\"input\":\"" ++ hex bytes ++
    "\",\"offset\":" ++ toString offset ++ ",\"count\":" ++ toString count ++
    ",\"original\":\"" ++ hex (readBytes copied 128 bytes.length) ++
    "\",\"copied\":\"" ++ hex (readBytes copied dest (32*count)) ++ "\"}")
#eval do
  emit "zero" 0 0
  emit "one" 0 1
  emit "two" 0 2
  emit "unaligned-one" 1 2
  emit "unaligned-last" 31 3
  emit "129-words" 0 129
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
