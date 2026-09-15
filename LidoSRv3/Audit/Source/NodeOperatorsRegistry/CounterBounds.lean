import LidoSRv3.Audit.Source.NodeOperatorsRegistry.AllocatedKeys

namespace LidoSRv3.Audit.Source.NodeOperatorsRegistry
open TrioAlloc1

/-- Each summand is an actual packed read, so its width requires no ABI premise. -/
theorem counterSum_width_bound (s : State) (field : Fin 4) (ids : List Word) :
    counterSum s field ids ≤ ids.length * (2^64 - 1) := by
  induction ids with
  | nil => simp [counterSum]
  | cons id rest ih =>
    have width := packedGet_width (s.operators id).signingKeysStats field
    simp only [counterSum, List.length_cons]
    calc
      (packedGet (s.operators id).signingKeysStats field).val + counterSum s field rest
          ≤ (2^64 - 1) + rest.length * (2^64 - 1) :=
        Nat.add_le_add (by omega) ih
      _ = (rest.length + 1) * (2^64 - 1) := by omega

/-- NOR's source cap is 200 (line 93), enforced when adding an operator
(line 289). Binding the enumerated ids to initialized registry storage and all
writers is still required. In particular, addNodeOperator (lines 283–303)
does not clear packed counters: zero counters for a newly admitted id require
initial-storage freshness and prior-writer exclusion, not just the count guard.
This theorem proves the arithmetic implication of
that understandable cap rather than assuming a 256-bit sum bound. -/
theorem counterSum_lt_word (s : State) (field : Fin 4) (ids : List Word)
    (countBound : ids.length ≤ 200) : counterSum s field ids < 2^256 := by
  have bounded := counterSum_width_bound s field ids
  have cap := Nat.mul_le_mul_right (2^64 - 1) countBound
  have fits : 200 * (2^64 - 1) < 2^256 := by decide +kernel
  omega

/-- A successful source row derives the deposited-sum increment. Together
with the registry cap and an incoming loaded-count accounting relation, it
implies that the source's unchecked loaded-count addition cannot wrap.
The incoming relation must still be derived through the actual loader loop. -/
theorem allocatedRow_loaded_add_no_overflow (s after : State) (ids : List Word)
    (id active start count loaded next : Word) (events : List (Word × Word))
    (unique : ids.Nodup) (member : id ∈ ids) (countBound : ids.length ≤ 200)
    (loadedBound : loaded.val ≤ counterSum s 3 ids)
    (consistent : (packedGet (s.operators id).signingKeysStats 1).val ≤
      (packedGet (s.operators id).signingKeysStats 3).val)
    (hPrefix : allocatedKeyPrefix (s.operators id).signingKeysStats active =
      .ok (.load start count))
    (success : commitAllocatedRow s id
      (allocatedDepositedAfter (s.operators id).signingKeysStats active) loaded count =
        .ok (after, next, events)) :
    loaded.val + count.val < 2^256 := by
  have delta := allocatedRow_deposited_sum s after ids id active start count loaded next
    events unique member consistent hPrefix success
  have bounded := counterSum_lt_word after 3 ids countBound
  omega

end LidoSRv3.Audit.Source.NodeOperatorsRegistry
