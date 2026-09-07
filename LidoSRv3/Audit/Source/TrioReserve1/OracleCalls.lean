import LidoSRv3.Audit.Source.TrioReserve1.QueueCalls
import LidoSRv3.Audit.Source.TrioReserve1.Oracle

namespace LidoSRv3.Audit.Source.TrioReserve1.OracleCalls
open Live

def external (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (config : Oracle.Config) (staticExternal : StaticCall.External) (other : External) : External :=
  QueueCalls.external keccak locator c (Oracle.dispatch c.oracle config staticExternal other)

/-- Execute through the concrete locator/queue/oracle dispatch chain. The
oracle result is its actual physical consensus read and nested STATICCALL. -/
theorem frame_call (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (config : Oracle.Config) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (w after : World) (data : Bytes) (nested : List NestedAttempt)
    (hl : c.oracle ≠ locator) (hq : c.oracle ≠ c.queue)
    (hc : (w.core.codeSize c.oracle.val).val ≠ 0)
    (hf : Oracle.frame staticExternal c.oracle config w = .successWithTrace data after nested) :
    call (external keccak locator c config staticExternal other) ctx c.oracle 0x72f79b13 (word 0) w =
      ⟨.ok data, after,
        [⟨⟨ctx.self, c.oracle, word 0, encode 4 0x72f79b13⟩, true, data, nested⟩]⟩ := by
  simp [call, external, QueueCalls.external, Locator.dispatch, Queue.dispatch,
    Oracle.dispatch, hl, hq, hc, word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero, hf]

theorem frame_rejection (keccak : Queue.Keccak) (locator : Address) (c : Locator.Config)
    (config : Oracle.Config) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (w : World) (data : Bytes) (nested : List NestedAttempt)
    (hl : c.oracle ≠ locator) (hq : c.oracle ≠ c.queue)
    (hc : (w.core.codeSize c.oracle.val).val ≠ 0)
    (hf : Oracle.frame staticExternal c.oracle config w = .rejectedWithTrace data nested) :
    call (external keccak locator c config staticExternal other) ctx c.oracle 0x72f79b13 (word 0) w =
      ⟨.error (.bubbled data), w,
        [⟨⟨ctx.self, c.oracle, word 0, encode 4 0x72f79b13⟩, false, data, nested⟩]⟩ := by
  simp [call, external, QueueCalls.external, Locator.dispatch, Queue.dispatch,
    Oracle.dispatch, hl, hq, hc, word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero, hf]

/-- Actual immutable lookup and oracle tuple bytes are decoded by the caller;
both direct attempts and all nested STATICCALL observations are retained. -/
theorem current_frame (keccak : Queue.Keccak) (c : Locator.Config) (config : Oracle.Config)
    (staticExternal : StaticCall.External) (other : External) (ctx : Context) (w : World)
    (nonce time : Nat) (nested : List NestedAttempt)
    (hd : c.oracle ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hq : c.oracle ≠ c.queue)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (hc : (w.core.codeSize c.oracle.val).val ≠ 0)
    (hf : Oracle.frame staticExternal c.oracle config w =
      .successWithTrace (encode 32 nonce ++ encode 32 time) w nested) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    getCurrentFrame (external keccak locator c config staticExternal other) ctx w =
      ⟨.ok ((word nonce).val, (word time).val), w,
        [⟨⟨ctx.self, locator, word 0, encode 4 0x5a2031f9⟩, true, encode 32 c.oracle.val, []⟩,
          ⟨⟨ctx.self, c.oracle, word 0, encode 4 0x72f79b13⟩, true,
            encode 32 nonce ++ encode 32 time, nested⟩]⟩ := by
  dsimp only
  have hlookup := CallResults.oracle_lookup ctx w c
    (Queue.dispatch keccak c.queue (Oracle.dispatch c.oracle config staticExternal other)) hl
  change locatorAddress (external keccak _ c config staticExternal other) ctx 0x5a2031f9 w = _ at hlookup
  have hcall := frame_call keccak _ c config staticExternal other ctx w w _ nested hd hq hc hf
  have h := CallResults.frame_reply (external keccak _ c config staticExternal other)
    ctx c.oracle w w w nonce time [] _ _ hlookup (by simpa using hcall)
  simpa using h

theorem current_frame_rejection (keccak : Queue.Keccak) (c : Locator.Config) (config : Oracle.Config)
    (staticExternal : StaticCall.External) (other : External) (ctx : Context) (w : World)
    (data : Bytes) (nested : List NestedAttempt)
    (hd : c.oracle ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hq : c.oracle ≠ c.queue)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (hc : (w.core.codeSize c.oracle.val).val ≠ 0)
    (hf : Oracle.frame staticExternal c.oracle config w =
      .rejectedWithTrace data nested) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    getCurrentFrame (external keccak locator c config staticExternal other) ctx w =
      ⟨.error (.bubbled data), w,
        [⟨⟨ctx.self, locator, word 0, encode 4 0x5a2031f9⟩, true, encode 32 c.oracle.val, []⟩,
          ⟨⟨ctx.self, c.oracle, word 0, encode 4 0x72f79b13⟩, false, data, nested⟩]⟩ := by
  dsimp only
  have hlookup := CallResults.oracle_lookup ctx w c
    (Queue.dispatch keccak c.queue (Oracle.dispatch c.oracle config staticExternal other)) hl
  change locatorAddress (external keccak _ c config staticExternal other) ctx 0x5a2031f9 w = _ at hlookup
  have hcall := frame_rejection keccak _ c config staticExternal other ctx w data nested hd hq hc hf
  have h := CallResults.frame_call_failure (external keccak _ c config staticExternal other)
    ctx c.oracle w w w (.bubbled data) _ _ hlookup hcall
  simpa using h

end LidoSRv3.Audit.Source.TrioReserve1.OracleCalls
