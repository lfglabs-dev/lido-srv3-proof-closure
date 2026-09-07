import audit.trio.alloc2.runtime.Library

namespace LidoSRv3.Audit.Source.TrioAlloc2.Runtime
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes word encodeWord)
open LibraryABI

private def state : _root_.Verity.ContractState :=
  { _root_.Verity.defaultState with
    memory := fun _ => _root_.Verity.Core.Uint256.ofNat 73
    selfBalance := _root_.Verity.Core.Uint256.ofNat 99 }

private def emit (name : String) (bytes : Bytes) : IO Unit := do
  let (reverted, data) := match (execute bytes).run state with
    | .success data _ => (false, hex data)
    | .revert reason _ => (true, reason)
  IO.println ("ALLOC2_VERITY_VECTOR {\"name\":\"" ++ name ++ "\",\"arguments\":\"" ++ hex bytes ++
    "\",\"reverted\":" ++ (if reverted then "true" else "false") ++ ",\"data\":\"" ++ data ++ "\"}")

#eval do
  emit "empty" (encodeArguments ⟨[], [], word 3⟩)
  emit "zero-short" (encodeArguments ⟨[word 7], [], zero⟩)
  emit "positive-short" (encodeArguments ⟨[zero], [], one⟩)
  emit "ties" (encodeArguments ⟨[zero, zero], [word 100, word 100], word 31⟩)
  emit "maximum" (encodeArguments ⟨[zero], [maxWord], maxWord⟩)
  emit "surplus" (encodeArguments ⟨[zero], [word 5, zero], word 3⟩)
  emit "overfull" (encodeArguments ⟨[word 9], [word 8], word 3⟩)
  emit "illustration" (encodeArguments ⟨[word 9998, word 70, zero], [word 10000, word 101, word 100], word 101⟩)
  emit "short-head" []
  emit "oversized-offset" (encodeWord maxWord ++ encodeWord (word 96) ++ encodeWord zero ++ encodeWord zero)
  let packet := encodeArguments ⟨[zero], [word 9], zero⟩
  emit "truncated-tail-zero-demand" (packet.take (packet.length-1))

private def memorySequence (name : String) (ap cp : Nat) (bs cs : List Nat) (d1 d2 : Nat) : IO Unit := do
  let buckets := bs.map word
  let capacities := cs.map word
  let initial := MemoryWrite.writeWords
    (MemoryWrite.writeWords (fun _ => word 0xcafe) ap (word buckets.length :: buckets))
    cp (word capacities.length :: capacities)
  let initialState := installMemory state initial
  match (indexedMemoryExecute ap cp (word d1)).run initialState with
  | .revert reason _ => throw (IO.userError reason)
  | .success firstAmount firstState =>
    match (indexedMemoryExecute ap cp (word d2)).run firstState with
    | .revert reason _ => throw (IO.userError reason)
    | .success secondAmount secondState =>
      let json := fun values : List Word => "[" ++ String.intercalate ","
        (values.map fun x => "\"" ++ toString x.val ++ "\"") ++ "]"
      if secondState.selfBalance ≠ initialState.selfBalance then throw (IO.userError "balance changed")
      if secondState.memory 7 ≠ initialState.memory 7 then throw (IO.userError "frame changed")
      if MemoryWrite.readArray (wordMemory secondState) cp ≠ capacities then throw (IO.userError "capacities changed")
      IO.println ("ALLOC2_VERITY_MEMORY_SEQUENCE {\"name\":\"" ++ name ++ "\",\"firstAmount\":\"" ++
        toString firstAmount.val ++ "\",\"secondAmount\":\"" ++ toString secondAmount.val ++
        "\",\"first\":" ++ json (MemoryWrite.readArray (wordMemory firstState) ap) ++
        ",\"second\":" ++ json (MemoryWrite.readArray (wordMemory secondState) ap) ++ "}")

#eval do
  memorySequence "two-calls" 128 512 [0,0] [100,100] 5 5
  memorySequence "reverse-regions" 512 128 [0,0] [100,100] 5 5
  memorySequence "below-capacity" 128 512 [7,0] [3,10] 3 20
  memorySequence "zero-first" 128 512 [0,0] [100,100] 0 5
  memorySequence "129-rows" 128 8192 (List.replicate 129 0) (List.replicate 129 2) 129 129

#eval do
  let shortMemory := MemoryWrite.writeWords
    (MemoryWrite.writeWords (fun _ => word 0xcafe) 128 [word 1, zero]) 512 [zero]
  let enclosing : _root_.Verity.Contract Unit := fun before =>
    .success () (installMemory { before.writeSlot 77 (_root_.Verity.Core.Uint256.ofNat 42) with
      selfBalance := _root_.Verity.Core.Uint256.ofNat 0 } shortMemory)
  match (_root_.Verity.bind enclosing (fun _ => indexedMemoryExecute 128 512 (word 1))).run state with
  | .success _ _ => throw (IO.userError "short capacities unexpectedly succeeded")
  | .revert reason restored =>
    if reason ≠ reprStr Panic.arrayBounds then throw (IO.userError "wrong indexing error")
    if restored.readSlot 77 ≠ state.readSlot 77 then throw (IO.userError "storage enclosing committed")
    if restored.selfBalance ≠ state.selfBalance then throw (IO.userError "balance enclosing committed")
    if restored.memory 128 ≠ state.memory 128 then throw (IO.userError "memory enclosing committed")
    IO.println "ALLOC2_INDEXED_PREFIX_ROLLBACK {\"panic\":50,\"storageRestored\":true,\"balanceRestored\":true,\"memoryRestored\":true}"

end LidoSRv3.Audit.Source.TrioAlloc2.Runtime
