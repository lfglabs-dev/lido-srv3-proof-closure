import LidoSRv3.Audit.Source.TrioReserve1.Live

namespace LidoSRv3.Audit.Source.TrioReserve1.ReplyABI
open Live

/-- Standard Error(string) ABI. Empty and already-bubbled failures retain their
original bytes. String bytes are UTF-8 and padded to a 32-byte boundary. -/
def reason (message : String) : Bytes :=
  let raw := message.toUTF8.data.toList
  encode 4 0x08c379a0 ++ encode 32 32 ++ encode 32 raw.length ++ raw ++
    List.replicate ((32 - raw.length % 32) % 32) 0

def fault : Fault → Bytes
  | .empty => []
  | .reason message => reason message
  | .bubbled data => data

/-- Lift direct and nested attempts into the calling frame without reordering. -/
def nested (attempts : List Attempt) : List NestedAttempt :=
  attempts.flatMap fun a =>
    ⟨a.request, false, a.accepted, a.returned, 1⟩ :: a.nested.map fun child => {child with depth := child.depth + 1}

/-- A source entry's failure carries no committed callee world; its caller
restores the incoming CALL world. Root execution still restores its own frame. -/
def reply (encodeValue : α → Bytes) (program : Exec α) (before : World) : Reply :=
  let r := run program before
  match r.outcome with
  | .ok value => .successWithTrace (encodeValue value) r.world (nested r.attempts)
  | .error e => .rejectedWithTrace (fault e) (nested r.attempts)

end LidoSRv3.Audit.Source.TrioReserve1.ReplyABI
