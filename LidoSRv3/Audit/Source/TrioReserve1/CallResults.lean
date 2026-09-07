import LidoSRv3.Audit.Source.TrioReserve1.ABI
import LidoSRv3.Audit.Source.TrioReserve1.Locator

/-! Composition through real CALL results. Reply premises below refer to the
executed call at its actual incoming world, not a supplied permission flag.
World effects and nested attempts are retained by the enclosing getters. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.CallResults
open Live

theorem transfer_zero (w : World) (sender recipient : Address) :
    transfer w sender recipient 0 = w := by
  simp [transfer]

theorem address_word (a : Address) : Verity.Core.Address.ofNat (word a.val).val = a := by
  apply Verity.Core.Address.ext
  have ha := a.isLt
  have hw : a.val < Verity.Core.UINT256_MODULUS := by
    unfold Verity.Core.ADDRESS_MODULUS at ha
    unfold Verity.Core.UINT256_MODULUS
    omega
  simp [word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus,
    Verity.Core.Address.ofNat, Nat.mod_eq_of_lt hw]

theorem locator_reply (external : External) (ctx : Context) (selector n : Nat)
    (w after : World) (suffix : Bytes) (trace : List Attempt)
    (h : call external ctx
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
      selector (word 0) w = ⟨.ok (encode 32 n ++ suffix), after, trace⟩) :
    locatorAddress external ctx selector w =
      ⟨.ok (Verity.Core.Address.ofNat (word n).val), after, trace⟩ := by
  simp only [locatorAddress, getLidoLocator, Live.read, bind, pure, bindExec, pureExec]
  rw [h]
  simp only [ABI.decode_word, List.nil_append, List.append_nil]

/-- Actual immutable locator execution, including the caller's physical
locator-pointer read, code guard, zero-value CALL, ABI decode, and address cast. -/
theorem queue_lookup (ctx : Context) (w : World) (c : Locator.Config) (other : External)
    (hcode : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    withdrawalQueue (Locator.dispatch locator c other) ctx w =
      ⟨.ok c.queue, w,
        [⟨⟨ctx.self, locator, word 0, encode 4 0x37d5fe99⟩, true, encode 32 c.queue.val, []⟩]⟩ := by
  dsimp only
  unfold withdrawalQueue
  have hc : call (Locator.dispatch
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val) c other)
      ctx (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
      0x37d5fe99 (word 0) w =
      ⟨.ok (encode 32 c.queue.val ++ []), w,
        [⟨⟨ctx.self, Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val,
          word 0, encode 4 0x37d5fe99⟩, true, encode 32 c.queue.val, []⟩]⟩ := by
    simp only [Verity.Core.Address.val_ofNat] at hcode
    simp [call, hcode, word, Verity.Core.Uint256.ofNat, transfer_zero, Locator.dispatch]
  have h := locator_reply _ ctx 0x37d5fe99 c.queue.val w w [] _ hc
  simpa only [address_word] using h

theorem frame_reply (external : External) (ctx : Context) (oracle : Address)
    (w located after : World) (nonce time : Nat) (suffix : Bytes)
    (lookupTrace callTrace : List Attempt)
    (hl : locatorAddress external ctx 0x5a2031f9 w = ⟨.ok oracle, located, lookupTrace⟩)
    (hc : call external ctx oracle 0x72f79b13 (word 0) located =
      ⟨.ok (encode 32 nonce ++ encode 32 time ++ suffix), after, callTrace⟩) :
    getCurrentFrame external ctx w =
      ⟨.ok ((word nonce).val, (word time).val), after, lookupTrace ++ callTrace⟩ := by
  have hlen : 64 ≤ (encode 32 nonce ++ encode 32 time ++ suffix).length := by
    simp only [List.length_append, ABI.encode_length]
    omega
  simp only [getCurrentFrame, bind, hl, bindExec, hc, require, hlen, decide_true,
    ite_true, pure, pureExec]
  have hfirst := ABI.decode_word nonce (encode 32 time ++ suffix) after
  rw [← List.append_assoc] at hfirst
  rw [hfirst]
  simp only [ABI.decode_second_word, List.append_nil]

theorem adjusted_frame (external : External) (ctx : Context) (w after : World)
    (nonce time : Nat) (trace : List Attempt)
    (h : getCurrentFrame external ctx w = ⟨.ok (nonce, time), after, trace⟩) :
    getDepositedNextReportAdjusted external ctx w =
      ⟨.ok (if nonce ≠ (w.core.readContractSlot ctx.self.val nextSlot).val / width then 0
        else (w.core.readContractSlot ctx.self.val nextSlot).val % width, nonce), after, trace⟩ := by
  simp [getDepositedNextReportAdjusted, Live.read, bind, bindExec, pure, pureExec, h]

theorem frame_call_failure (external : External) (ctx : Context) (oracle : Address)
    (w located after : World) (fault : Fault) (lookupTrace callTrace : List Attempt)
    (hl : locatorAddress external ctx 0x5a2031f9 w = ⟨.ok oracle, located, lookupTrace⟩)
    (hc : call external ctx oracle 0x72f79b13 (word 0) located =
      ⟨.error fault, after, callTrace⟩) :
    getCurrentFrame external ctx w = ⟨.error fault, after, lookupTrace ++ callTrace⟩ := by
  simp [getCurrentFrame, bind, bindExec, hl, hc]

theorem frame_short_reply (external : External) (ctx : Context) (oracle : Address)
    (w located after : World) (data : Bytes) (lookupTrace callTrace : List Attempt)
    (hl : locatorAddress external ctx 0x5a2031f9 w = ⟨.ok oracle, located, lookupTrace⟩)
    (hc : call external ctx oracle 0x72f79b13 (word 0) located =
      ⟨.ok data, after, callTrace⟩) (hshort : data.length < 64) :
    getCurrentFrame external ctx w = ⟨.error .empty, after, lookupTrace ++ callTrace⟩ := by
  simp [getCurrentFrame, bind, bindExec, hl, hc, require, Nat.not_le.mpr hshort, fail]

end LidoSRv3.Audit.Source.TrioReserve1.CallResults
