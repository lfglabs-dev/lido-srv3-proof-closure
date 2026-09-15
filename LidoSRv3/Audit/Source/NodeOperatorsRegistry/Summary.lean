import LidoSRv3.Audit.Source.Packed64x4
import LidoSRv3.Audit.Source.TrioAlloc1.FirstPass

/-!
The NOR summary getter, from its loaded packed word through the ALLOC decoder.
[Getter and offsets](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/nos/NodeOperatorsRegistry.sol#L1257-L1265),
[packed extraction](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/lib/Packed64x4.sol#L24-L27).
`field` expresses right shift and low-bit masking as division and remainder.
The input is the word loaded by `_loadSummarySigningKeysStats`; this module
does not invent its compiler storage slot or assume aggregate consistency.
The 0.4.24 SafeMath failure is Error("MATH_SUB_UNDERFLOW"), not Panic(0x11).
SafeMath is pinned by @aragon/os 4.4.0 in core's yarn.lock.

Widths hold for every packed word. They do not imply exited <= deposited,
router/module synchronization, or successful execution. Those require the
writer invariants and account/code/storage relation separately.
-/
namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry

open TrioAlloc1

abbrev packedGet := Packed64x4.get
abbrev packedGet_width := Packed64x4.get_width

def mathSubUnderflow : Bytes := Packed64x4.errorString "MATH_SUB_UNDERFLOW"

def getStakingModuleSummary (packed : Word) : Except Bytes Summary :=
  let exited := packedGet packed 1
  let deposited := packedGet packed 3
  let maximum := packedGet packed 0
  if deposited.val ≤ maximum.val then
    .ok { exited, deposited, depositable := word (maximum.val - deposited.val) }
  else .error mathSubUnderflow

/-- No ABI-width premise: all three bounds follow from the actual packed read. -/
theorem summary_widths (packed : Word) (summary : Summary)
    (h : getStakingModuleSummary packed = .ok summary) :
    summary.exited.val < 2^64 ∧ summary.deposited.val < 2^64 ∧
      summary.depositable.val < 2^64 := by
  dsimp only [getStakingModuleSummary] at h
  split at h
  · cases h
    refine ⟨packedGet_width packed 1, packedGet_width packed 3, ?_⟩
    have bound : (packedGet packed 0).val - (packedGet packed 3).val < 2^64 :=
      Nat.lt_of_le_of_lt (Nat.sub_le _ _) (packedGet_width packed 0)
    have wordBound : (packedGet packed 0).val - (packedGet packed 3).val < 2^256 :=
      Nat.lt_trans bound (by decide)
    simpa only [word, Nat.mod_eq_of_lt wordBound] using bound
  · cases h

def summaryReply (packed : Word) : CallResponse :=
  match getStakingModuleSummary packed with
  | .error reason => .reverted reason
  | .ok summary => .returned
      (encodeWord summary.exited ++ encodeWord summary.deposited ++
        encodeWord summary.depositable)

/-- Transport the source-derived widths through the existing router ABI decoder. -/
theorem reply_decoded_widths (packed : Word) (bytes : Bytes)
    (reply : summaryReply packed = .returned bytes) :
    ∃ summary, decodeSummary bytes = .ok summary ∧
      summary.exited.val < 2^64 ∧ summary.deposited.val < 2^64 ∧
      summary.depositable.val < 2^64 := by
  cases h : getStakingModuleSummary packed with
  | error reason => simp [summaryReply, h] at reply
  | ok summary =>
    simp only [summaryReply, h, CallResponse.returned.injEq] at reply
    subst bytes
    refine ⟨summary, ?_, summary_widths packed summary h⟩
    simpa only [List.append_nil] using
      decodeSummary_encoded summary.exited summary.deposited summary.depositable []

/-- A live router iteration consumes the NOR reply at its actual first call.
The premise identifies that call's producer, not its desired decoded values.
Success remains explicit: in particular, excessive router accounting exits
still cause the router's arithmetic panic after a successful NOR getter. -/
theorem firstRow_nor_widths (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) (before after : Transcript)
    (packed : Word) (row : CachedRow) (next : Word)
    (response : oracle before
      { target := (readModule l s i).identity.moduleAddress, payload := summaryPayload } =
        summaryReply packed)
    (success : firstRow l s oracle input i total before = (.ok (row, next), after)) :
    row.summary.exited.val < 2^64 ∧ row.summary.deposited.val < 2^64 ∧
      row.summary.depositable.val < 2^64 ∧ row.active.val < 2^64 := by
  have widths : row.summary.exited.val < 2^64 ∧ row.summary.deposited.val < 2^64 ∧
      row.summary.depositable.val < 2^64 := by
    cases getter : getStakingModuleSummary packed with
    | error reason =>
      simp only [summaryReply, getter] at response
      unfold firstRow at success
      simp only [bind, pure] at success
      split at success
      · simp [failExec] at success
      · simp [bindExec, staticCall, response] at success
    | ok summary =>
      simp only [summaryReply, getter] at response
      have decoded := decodeSummary_encoded
        summary.exited summary.deposited summary.depositable []
      simp only [List.append_nil] at decoded
      have same : row.summary = summary := by
        unfold firstRow at success
        simp only [bind, pure] at success
        split at success
        · simp [failExec] at success
        · simp only [bindExec, staticCall, response, liftChecked, decoded] at success
          repeat first
            | (split at success)
            | (simp only [bindExec, pureExec, liftChecked] at success)
            | (simp at success)
            | (obtain ⟨⟨rfl, _⟩, _⟩ := success; rfl)
      rw [same]
      exact summary_widths packed summary getter
  have conservation := firstRow_active_count l s oracle input i total before after row next success
  exact ⟨widths.1, widths.2.1, widths.2.2, by omega⟩

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
