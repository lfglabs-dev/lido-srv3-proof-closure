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

end LidoSRv3.Audit.Source.TrioAlloc2.Runtime
