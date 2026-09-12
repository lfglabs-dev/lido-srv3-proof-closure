import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Guarantees.PReserve1

/-!
# P-RESERVE-1 live `unfinalizedStETH` STATICCALL

Additive consumer beside the registered parent
`PReserve1.source_spend_preserves_withdrawal_reserve`, which still takes
`freshQueueCache before live` as a free hypothesis.  This module derives
that live word from a STATICCALL observation of
`WithdrawalQueue.unfinalizedStETH()` and fails closed on every other
outcome.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `Lido.sol:612` `_withdrawalQueue().unfinalizedStETH()`
  (view STATICCALL, value 0)
* `WithdrawalQueueBase.sol:143-146` `unfinalizedStETH()` returns one
  `uint256`
* Artifact selector `unfinalizedStETH()` = `0xd0fb84e8`
  (`RequestHarness.json` methodIdentifiers)

The parent `freshQueueCache` definition is not edited.
-/

namespace LidoSRv3.Audit.Source.ReserveUnfinalizedCall

open Verity
open LidoSRv3.Audit.SolidityReserve

abbrev Word := Verity.Core.Uint256

/-- Pinned 4-byte selector of `unfinalizedStETH()`. -/
def unfinalizedStETHSelector : Nat := 0xd0fb84e8

/-- STATICCALL observation of `WithdrawalQueue.unfinalizedStETH`
(`Lido.sol:612`).  `returndata` is the raw byte string; a successful view
returns exactly 32 ABI bytes. -/
structure UnfinalizedStaticcall where
  success : Bool
  returndata : List Nat
  value : Nat
  selector : Nat
  deriving Repr, DecidableEq

/-- Big-endian ABI word. Each byte is taken modulo 256 so a 32-byte
string is always a uint256. -/
def beWord : List Nat → Nat
  | [] => 0
  | b :: bs => (b % 256) * 256 ^ bs.length + beWord bs

/-- ABI uint256 decode: exactly 32 bytes, else `none` (short/long
returndata).  Solidity 0.4.24 view ABI-decode of a `uint256` requires
`returndatasize() == 32`. -/
def decodeWord32 (bytes : List Nat) : Option Word :=
  if bytes.length = 32 then
    some (Verity.Core.Uint256.ofNat (beWord bytes))
  else none

/-- Live queue word: well-formed STATICCALL (selector, value 0) that
succeeds and ABI-decodes 32 bytes.  Failure, wrong selector, nonzero
value, or bad size is `none` — not an always-success stub. -/
def liveUnfinalizedStETH (c : UnfinalizedStaticcall) : Option Word :=
  if c.selector = unfinalizedStETHSelector && c.value = 0 && c.success then
    decodeWord32 c.returndata
  else none

/-- Freshness derived from the STATICCALL observation, not a free `live`
word. -/
def freshQueueCacheFromCall (state : ReserveState) (c : UnfinalizedStaticcall) : Prop :=
  match liveUnfinalizedStETH c with
  | none => False
  | some w => freshQueueCache state w

private theorem live_cond {c : UnfinalizedStaticcall} {w : Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.selector = unfinalizedStETHSelector ∧ c.value = 0 ∧ c.success = true ∧
      c.returndata.length = 32 := by
  unfold liveUnfinalizedStETH at h
  by_cases hsel : c.selector = unfinalizedStETHSelector
  · by_cases hval : c.value = 0
    · by_cases hok : c.success = true
      · simp [hsel, hval, hok, decodeWord32] at h
        by_cases hlen : c.returndata.length = 32
        · exact ⟨hsel, hval, hok, hlen⟩
        · simp [hlen] at h
      · simp [hsel, hval, hok] at h
    · simp [hsel, hval] at h
  · simp [hsel] at h

theorem live_requires_selector (c : UnfinalizedStaticcall) {w : Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.selector = unfinalizedStETHSelector :=
  (live_cond h).1

theorem live_requires_zero_value (c : UnfinalizedStaticcall) {w : Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.value = 0 :=
  (live_cond h).2.1

theorem live_requires_success (c : UnfinalizedStaticcall) {w : Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.success = true :=
  (live_cond h).2.2.1

theorem live_requires_32_bytes (c : UnfinalizedStaticcall) {w : Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.returndata.length = 32 :=
  (live_cond h).2.2.2

theorem failed_call_not_fresh (state : ReserveState) (c : UnfinalizedStaticcall)
    (h : liveUnfinalizedStETH c = none) :
    ¬ freshQueueCacheFromCall state c := by
  simp [freshQueueCacheFromCall, h]

theorem success_fresh_iff (state : ReserveState) (c : UnfinalizedStaticcall)
    (w : Word) (h : liveUnfinalizedStETH c = some w) :
    freshQueueCacheFromCall state c ↔ freshQueueCache state w := by
  simp [freshQueueCacheFromCall, h]

/-- Derived spend consumer: freshness comes from the STATICCALL, then the
unchanged parent applies at the decoded word. -/
theorem spend_preserves_from_live_call
    (inputs : WithdrawInputs) (before after : ReserveState) (amount : Word)
    (c : UnfinalizedStaticcall) (w : Word)
    (hlive : liveUnfinalizedStETH c = some w)
    (hfresh : freshQueueCacheFromCall before c)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after w =
        liveEffectiveWithdrawalsReserve before w := by
  have hf : freshQueueCache before w :=
    (success_fresh_iff before c w hlive).mp hfresh
  exact LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve
    inputs before after amount w hf h

/-- 32-byte encoding of a small Nat as ABI returndata (leading zeros). -/
def abiWord (n : Nat) : List Nat :=
  List.replicate 31 0 ++ [n % 256]

theorem abiWord_length (n : Nat) : (abiWord n).length = 32 := by
  simp [abiWord]

theorem beWord_zeros_snoc (k n : Nat) :
    beWord (List.replicate k 0 ++ [n]) = n % 256 := by
  induction k with
  | zero => simp [beWord]
  | succ k ih =>
    simp [List.replicate_succ, beWord, ih]

theorem decode_abiWord_small (n : Nat) (hn : n < 256) :
    decodeWord32 (abiWord n) = some (Verity.Core.Uint256.ofNat n) := by
  have hbe : beWord (abiWord n) = n := by
    simp only [abiWord]
    rw [beWord_zeros_snoc]
    simp [Nat.mod_eq_of_lt hn]
  simp [decodeWord32, abiWord_length, hbe]

#print axioms live_requires_selector
#print axioms live_requires_zero_value
#print axioms live_requires_success
#print axioms live_requires_32_bytes
#print axioms failed_call_not_fresh
#print axioms success_fresh_iff
#print axioms spend_preserves_from_live_call
#print axioms decode_abiWord_small

end LidoSRv3.Audit.Source.ReserveUnfinalizedCall
