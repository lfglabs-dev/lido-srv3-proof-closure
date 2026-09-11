import LidoSRv3.Audit.Source.TopupModuleMemory
import LidoSRv3.Audit.Source.TopupCredentialCall

/-!
Pointer origin and interval aliasing for the Verity memory model actually used
by the existing TOPUP theorems.

That model is `finalizeAllocation` plus immutable returndata bytes
(`audit.trio.deposit.ModuleCall.finalizeAllocation`, solc 0.8.25
`finalize_allocation`). It is not a shared byte-addressable EVM store. A
pointer's origin is the cursor that produced the zone; two zones alias when
their half-open intervals overlap.

Sequential allocations from a chained cursor are disjoint. Independently
supplied TOPUP cursors (`credentialCursor` vs `returnBuffer`) are not chained
in `TopupCredentialCall.run` / `TopupBatchMemory.run`; the same admitted
pointer can decode both a credentials word and a module return, and those
zones then alias. Existing TOPUP success premises do not mention `Disjoint`.
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupPointerOrigin
open TrioReserve1 Live
open audit.trio.deposit.ModuleCall (round32 finalizeAllocation finalizeAllocation_ok)

/-- Half-open interval `[origin, next)` produced by one successful
`finalizeAllocation`. `requested` is the size argument before `round32`. -/
structure AllocatedZone where
  origin : Nat
  next : Nat
  requested : Nat
  deriving Repr, DecidableEq

def AllocatedZone.valid (z : AllocatedZone) : Prop :=
  z.origin ≤ z.next ∧ z.next < 2 ^ 64

/-- A pointer is read or written in `z` when it lies in the allocated interval. -/
def AllocatedZone.contains (z : AllocatedZone) (p : Nat) : Prop :=
  z.origin ≤ p ∧ p < z.next

/-- Interval non-aliasing on the Verity TOPUP address line. -/
def Disjoint (a b : AllocatedZone) : Prop :=
  a.next ≤ b.origin ∨ b.next ≤ a.origin

def ofAllocation (cursor : Word) (size : Nat) (next : Word) : AllocatedZone :=
  ⟨cursor.val, next.val, size⟩

/-- 32-byte STATICCALL copy used by locator `stakingRouter()` and the
credentials getter (`TopUpGateway.sol:185` IR498–511; credentials decode
`TopupCredentialCall.decodeCredentials`). -/
def scalar32 (cursor next : Word) : AllocatedZone :=
  ofAllocation cursor 32 next

@[simp] theorem ofAllocation_origin (cursor : Word) (size : Nat) (next : Word) :
    (ofAllocation cursor size next).origin = cursor.val := rfl
@[simp] theorem ofAllocation_next (cursor : Word) (size : Nat) (next : Word) :
    (ofAllocation cursor size next).next = next.val := rfl
@[simp] theorem scalar32_origin (cursor next : Word) :
    (scalar32 cursor next).origin = cursor.val := rfl
@[simp] theorem scalar32_next (cursor next : Word) :
    (scalar32 cursor next).next = next.val := rfl

theorem disjoint_comm (a b : AllocatedZone) : Disjoint a b ↔ Disjoint b a := by
  constructor
  · intro h; exact h.elim Or.inr Or.inl
  · intro h; exact h.elim Or.inr Or.inl

/-- Sequential chaining: the next cursor of `a` is the origin of `b`.
`TopUpGateway.sol:185` IR512–538 feeds the locator allocator's next pointer
into the credentials getter (`_24 = mload(64)`). -/
theorem sequential_disjoint (a b : AllocatedZone) (h : b.origin = a.next) :
    Disjoint a b := by
  exact Or.inl (Nat.le_of_eq h.symm)

/-- `finalizeAllocation` success (`finalize_allocation` IR3149–3159): the
output pointer originates at the input cursor of the same allocation. -/
theorem allocation_origin (cursor next : Word) (size : Nat)
    (h : finalizeAllocation cursor size = .ok next) :
    let z := ofAllocation cursor size next
    z.origin = cursor.val ∧ z.next = next.val ∧ z.valid ∧
      next = word (cursor.val + round32 size) ∧ cursor.val ≤ next.val := by
  obtain ⟨hn, hm, he⟩ := finalizeAllocation_ok cursor next size h
  exact ⟨rfl, rfl, And.intro hm hn, he, hm⟩

/-- The 32-byte allocator used by both locator and credentials copies does
not wrap: `next = cursor + 32`. -/
theorem finalize32_next (cursor next : Word)
    (h : finalizeAllocation cursor 32 = .ok next) :
    next.val = cursor.val + 32 ∧ next.val < 2 ^ 64 ∧ cursor.val ≤ next.val := by
  obtain ⟨hn, hm, he⟩ := finalizeAllocation_ok cursor next 32 h
  have hr : round32 32 = 32 := by decide
  have hmod : (cursor.val + 32) % 2 ^ 256 = cursor.val + 32 := by
    have hc := cursor.isLt
    change cursor.val < 2 ^ 256 at hc
    have : cursor.val + 32 < 2 ^ 256 := by omega
    exact Nat.mod_eq_of_lt this
  have hv : next.val = cursor.val + 32 := by
    have heval : next.val = (cursor.val + round32 32) % 2 ^ 256 := by
      rw [he]
      change (cursor.val + round32 32) % 2 ^ 256 = _
      rfl
    rw [hr] at heval
    exact heval.trans hmod
  exact ⟨hv, hn, hm⟩

/-- Chained 32-byte allocations (locator then credentials) do not alias.
Reflects `TopUpGateway.sol:185` locator STATICCALL then the credentials
STATICCALL that consumes `mload(64)` after that allocation. -/
theorem chained_scalar32_disjoint (cursor mid next : Word)
    (h1 : finalizeAllocation cursor 32 = .ok mid)
    (h2 : finalizeAllocation mid 32 = .ok next) :
    Disjoint (scalar32 cursor mid) (scalar32 mid next) ∧
      (scalar32 cursor mid).valid ∧ (scalar32 mid next).valid ∧
      (scalar32 cursor mid).contains cursor.val ∧
      (scalar32 mid next).contains mid.val := by
  obtain ⟨he1, hn1, hm1⟩ := finalize32_next cursor mid h1
  obtain ⟨he2, hn2, hm2⟩ := finalize32_next mid next h2
  refine ⟨sequential_disjoint _ _ rfl, ⟨hm1, hn1⟩, ⟨hm2, hn2⟩, ?_, ?_⟩
  · exact ⟨Nat.le_refl _, by simp [he1]⟩
  · exact ⟨Nat.le_refl _, by simp [he2]⟩

/-- Successful credentials decode (`decodeCredentials`; getter
`StakingRouter.sol:1012–1014` / `_getWithdrawalCredentialsWithType` at
`StakingRouter.sol:1046–1048`, consumed after the gateway STATICCALL)
originates a 32-byte zone at the supplied cursor. -/
theorem credentials_zone (cursor wc next : Word) (raw : Bytes)
    (h : TopupCredentialCall.decodeCredentials cursor raw = .ok (wc, next)) :
    finalizeAllocation cursor 32 = .ok next ∧
      (scalar32 cursor next).origin = cursor.val ∧
      (scalar32 cursor next).next = cursor.val + 32 ∧
      (scalar32 cursor next).valid ∧
      (scalar32 cursor next).contains cursor.val := by
  obtain ⟨_, _, ha, he, hb⟩ := TopupCredentialCall.decode_fields cursor raw wc next h
  have hm : cursor.val ≤ next.val := by omega
  refine ⟨ha, rfl, ?_, ⟨hm, hb⟩, ?_⟩
  · simpa [scalar32, ofAllocation] using he.symm
  · refine ⟨Nat.le_refl _, ?_⟩
    rw [scalar32_next, ← he]
    exact Nat.lt_add_of_pos_right (by decide : (0 : Nat) < 32)

/-- Locator `LOCATOR.stakingRouter()` (`TopUpGateway.sol:185`, selector
`0xef6c064c`) uses the same 32-byte allocation as `decodeCredentials` before
the canonical-160 guard (`TopupRouterLocatorCall.decodeRouter`). -/
theorem locator_zone (cursor wc next : Word) (raw : Bytes)
    (h : TopupCredentialCall.decodeCredentials cursor raw = .ok (wc, next))
    (_h160 : wc.val < 2 ^ 160) :
    finalizeAllocation cursor 32 = .ok next ∧
      (scalar32 cursor next).origin = cursor.val ∧
      (scalar32 cursor next).next = cursor.val + 32 ∧
      (scalar32 cursor next).valid := by
  obtain ⟨ha, ho, hn, hv, _⟩ := credentials_zone cursor wc next raw h
  exact ⟨ha, ho, hn, hv⟩

/-- Successful module return decode (`StakingRouter.sol:717–719`
`allocateDeposits` returndata; IR1082–1086 copy + `finalize_allocation`,
then IR3323–3353 array allocation at the post-return free pointer) produces
two sequential, hence non-aliasing, zones: the copied return and the
decoded `uint256[]`. -/
theorem module_decode_zones (cursor next : Word) (raw : Bytes) (xs : List Word)
    (h : TopupModuleMemory.decodeReturn cursor raw = .ok (xs, next)) :
    ∃ postRaw : Word,
      let rawZ := ofAllocation cursor (word raw.length).val postRaw
      let arrZ := ofAllocation postRaw
        (32 * decode ((raw.drop (decode (raw.take 32))).take 32) + 32) next
      finalizeAllocation cursor (word raw.length).val = .ok postRaw ∧
        finalizeAllocation postRaw
          (32 * decode ((raw.drop (decode (raw.take 32))).take 32) + 32) = .ok next ∧
        rawZ.origin = cursor.val ∧ arrZ.origin = postRaw.val ∧
        arrZ.origin = rawZ.next ∧ Disjoint rawZ arrZ ∧
        rawZ.valid ∧ arrZ.valid ∧
        cursor.val + (word raw.length).val ≤ postRaw.val := by
  have hex := (TopupModuleMemory.decode_success cursor next raw xs h).right
  rcases hex with ⟨postRaw, hpost⟩
  have ha := hpost.left
  have hraw := hpost.right.left
  have hr := hpost.right.right.left
  have hn := hpost.right.right.right.left
  have hmono := hpost.right.right.right.right.left
  have hnext := hpost.right.right.right.right.right
  refine ⟨postRaw, ha, hn, rfl, rfl, rfl, sequential_disjoint _ _ rfl, ?_, ?_, hraw⟩
  · exact ⟨Nat.le_trans (Nat.le_add_right _ _) hraw, hr⟩
  · exact ⟨hmono, hnext⟩

/-- Successful `decodeReturn` copied at least 32 bytes
(`StakingRouter.sol:717–719` ABI head). -/
theorem module_return_copied_size (cursor next : Word) (raw : Bytes) (xs : List Word)
    (h : TopupModuleMemory.decodeReturn cursor raw = .ok (xs, next)) :
    32 ≤ (word raw.length).val := by
  have h' := h
  unfold TopupModuleMemory.decodeReturn at h'
  cases ha : finalizeAllocation cursor (word raw.length).val with
  | «error» fault =>
    simp [ha, bind, Except.bind] at h'
  | ok postRaw =>
    simp only [ha, bind, Except.bind] at h'
    rw [audit.trio.deposit.ModuleCall.end_sub_base] at h'
    split at h'
    · exact nomatch h'
    · rename_i hh
      have hh' : audit.trio.deposit.ModuleCall.signedLt (word raw.length) (word 32) = false :=
        Bool.eq_false_iff.mpr hh
      exact (TopupModuleMemory.raw_bounds cursor (word raw.length) postRaw ha hh').1

/-- Same independently supplied cursor succeeding for credentials and for
the module return decoder. The two zones both contain that cursor, so they
alias. `TopupCredentialCall.run` / `TopupBatchMemory.run` take
`credentialCursor` and `returnBuffer` as separate `Word`s and never require
`Disjoint`; the existing TOPUP success premises therefore do not exclude
this alias. A reading of those premises as “zones of the same execution do
not alias” is false. -/
theorem same_cursor_successful_decodes_alias
    (cursor nextCred nextMod : Word) (rawCred rawMod : Bytes) (wc : Word)
    (xs : List Word)
    (hc : TopupCredentialCall.decodeCredentials cursor rawCred = .ok (wc, nextCred))
    (hm : TopupModuleMemory.decodeReturn cursor rawMod = .ok (xs, nextMod)) :
    ∃ postRaw : Word,
      ¬ Disjoint (scalar32 cursor nextCred)
          (ofAllocation cursor (word rawMod.length).val postRaw) := by
  obtain ⟨_, _, _, he, _⟩ := TopupCredentialCall.decode_fields cursor rawCred wc nextCred hc
  have hex := (TopupModuleMemory.decode_success cursor nextMod rawMod xs hm).right
  rcases hex with ⟨postRaw, hpost⟩
  have hraw := hpost.right.left
  have hsz := module_return_copied_size cursor nextMod rawMod xs hm
  refine ⟨postRaw, ?_⟩
  intro hd
  simp [Disjoint, scalar32, ofAllocation] at hd
  cases hd with
  | inl hle =>
    omega
  | inr hle =>
    omega

/-- Conventional free-memory slot `mstore(64)` / `0x40`. The Verity TOPUP
model has no such cell; a credentials decode at cursor 64 is still admitted
by the same scalar allocator. This alias with the compiler free pointer is
not excluded. -/
theorem free_memory_slot_finalize32 (next : Word)
    (h : finalizeAllocation (word 64) 32 = .ok next) :
    next.val = 96 ∧ (scalar32 (word 64) next).contains 64 ∧
      (scalar32 (word 64) next).contains 80 := by
  obtain ⟨he, _, _⟩ := finalize32_next (word 64) next h
  have hv : (word 64).val = 64 := by decide
  rw [hv] at he
  refine ⟨he, ?_, ?_⟩
  · simp [AllocatedZone.contains, scalar32, ofAllocation, hv, he]
  · simp [AllocatedZone.contains, scalar32, ofAllocation, hv, he]

#print axioms ofAllocation_origin
#print axioms ofAllocation_next
#print axioms scalar32_origin
#print axioms scalar32_next
#print axioms disjoint_comm
#print axioms sequential_disjoint
#print axioms allocation_origin
#print axioms finalize32_next
#print axioms chained_scalar32_disjoint
#print axioms credentials_zone
#print axioms locator_zone
#print axioms module_decode_zones
#print axioms module_return_copied_size
#print axioms same_cursor_successful_decodes_alias
#print axioms free_memory_slot_finalize32
end LidoSRv3.Audit.Source.TopupPointerOrigin
