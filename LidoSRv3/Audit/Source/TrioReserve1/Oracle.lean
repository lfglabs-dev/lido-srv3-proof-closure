import LidoSRv3.Audit.Source.TrioReserve1.StaticCall
import LidoSRv3.Audit.Source.TrioReserve1.OracleSpec
import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.Oracle
open Live

def consensusSlot : Nat := 0xb0e01b719c2c32a677822ce1584cb6a66e576ee3c2c506b9621dbe626355aa65
def panic : Bytes := encode 4 0x4e487b71 ++ encode 32 0x11

structure Config where
  genesis : Word
  secondsPerSlot : Word

/-- Pinned AccountingOracle.sol:561-563, checked 0.8.9 multiplication then add. -/
def timestamp (genesis seconds slot : Nat) : OracleSpec.Timestamp :=
  if slot * seconds ≥ 2^256 then .overflow
  else if genesis + slot * seconds ≥ 2^256 then .overflow
  else .value (genesis + slot * seconds)

theorem timestamp_corresponds (genesis seconds slot : Nat) :
    OracleSpec.Describes genesis seconds slot (timestamp genesis seconds slot) := by
  unfold timestamp
  split
  · exact Or.inl (by assumption)
  · split
    · exact Or.inr (by assumption)
    · simp only [OracleSpec.Describes]
      exact ⟨True.intro, by omega, by omega⟩

/-- BaseOracle.sol:357-360 and AccountingOracle.sol:439-442. The consensus
address is read from physical storage, and its current frame is STATICCALLed.
Malformed tuple bytes and checked timestamp overflow reject after that call;
its nested attempt is retained even if the containing Lido transaction reverts.
-/
def frame (external : StaticCall.External) (oracle : Address) (c : Config) (w : World) : Live.Reply :=
  let consensus := Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val consensusSlot).val
  let r := StaticCall.call external oracle consensus 0x72f79b13 w
  match r.outcome with
  | .error data => .rejectedWithTrace data r.attempts
  | .ok data =>
    if data.length < 64 then .rejectedWithTrace [] r.attempts
    else
      let refSlot := (word (decode (data.take 32))).val
      match timestamp c.genesis.val c.secondsPerSlot.val refSlot with
      | .overflow => .rejectedWithTrace panic r.attempts
      | .value time => .successWithTrace (encode 32 refSlot ++ encode 32 time) w r.attempts

def dispatch (oracle : Address) (c : Config) (staticExternal : StaticCall.External)
    (other : Live.External) : Live.External := fun req w =>
  if req.target = oracle ∧ req.payload = encode 4 0x72f79b13 then
    if req.value.val ≠ 0 then .rejected [] else frame staticExternal oracle c w
  else other req w

/-- All successful executions preserve the complete incoming world; this is
derived from the source's read-only operations, not a callee frame premise. -/
theorem frame_preserves (external : StaticCall.External) (oracle : Address)
    (c : Config) (w after : World) (data : Bytes) (trace : List NestedAttempt)
    (h : frame external oracle c w = .successWithTrace data after trace) : after = w := by
  unfold frame at h
  dsimp only at h
  split at h
  · contradiction
  · split at h
    · contradiction
    · split at h
      · contradiction
      · cases h
        rfl

/-- Successful bytes are derived from the actual STATICCALL result and the
independent checked-timestamp rule. The nested trace and complete world frame
are also exact, including when the surrounding caller has already written. -/
theorem frame_success (external : StaticCall.External) (oracle : Address)
    (c : Config) (w after : World) (data : Bytes) (trace : List NestedAttempt)
    (h : frame external oracle c w = .successWithTrace data after trace) :
    let consensus := Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val consensusSlot).val
    let r := StaticCall.call external oracle consensus 0x72f79b13 w
    ∃ reply time,
      r.outcome = .ok reply ∧ 64 ≤ reply.length ∧
      OracleSpec.Describes c.genesis.val c.secondsPerSlot.val
        (word (decode (reply.take 32))).val (.value time) ∧
      data = encode 32 (word (decode (reply.take 32))).val ++ encode 32 time ∧
      trace = r.attempts ∧ after = w := by
  unfold frame at h
  dsimp only at h ⊢
  split at h
  · contradiction
  · rename_i reply hreply
    split at h
    · contradiction
    · rename_i hsize
      split at h
      · contradiction
      · rename_i time htime
        cases h
        refine ⟨reply, time, hreply, by omega, ?_, rfl, rfl, rfl⟩
        have ht := timestamp_corresponds c.genesis.val c.secondsPerSlot.val
          (word (decode (reply.take 32))).val
        simpa only [htime] using ht

end LidoSRv3.Audit.Source.TrioReserve1.Oracle
