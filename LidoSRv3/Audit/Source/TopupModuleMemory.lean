import audit.trio.deposit.ModuleCall
import LidoSRv3.Audit.Source.TopupRootCallEffects

/-! Scalar guards of the pinned solc 0.8.25 allocateDeposits return decoder.
The phase cursor is supplied, not derived from earlier memory execution.
Returndata copy correctness and gas retain their existing boundaries. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupModuleMemory
open TrioReserve1 Live
open audit.trio.deposit.ModuleCall (round32 finalizeAllocation signed signedLt)

/-- Raw return allocation, signed head and length-word bounds, uint64 count,
array allocation at the post-return cursor, then the unsigned payload extent.
All pointer additions and returndatasize are uint256 projections. -/
def decodeReturn (cursor : Word) (raw : Bytes) : Except Fault (List Word × Word) := do
  let size := word raw.length
  let postRaw ← finalizeAllocation cursor size.val
  let dataEnd := word (cursor.val + size.val)
  if signedLt (word (dataEnd.val + 2^256 - cursor.val)) (word 32) then .error .empty else
  let offset := decode (raw.take 32)
  if offset ≥ 2^64 then .error .empty else
  let location := word (cursor.val + offset)
  if !signedLt (word (location.val + 31)) dataEnd then .error .empty else
  let count := decode ((raw.drop offset).take 32)
  if count ≥ 2^64 then .error (.reason "Panic(0x41)") else
  let next ← finalizeAllocation postRaw (32*count+32)
  if (word (location.val + 32*count+32)).val > dataEnd.val then .error .empty else
  .ok (TopupModuleCall.readWords count (raw.drop (offset+32)),next)

theorem raw_bounds (cursor size next : Word)
    (ha : finalizeAllocation cursor size.val = .ok next)
    (hh : signedLt size (word 32) = false) :
    32 ≤ size.val ∧ cursor.val + size.val ≤ next.val ∧ next.val < 2^64 := by
  obtain ⟨hn,hc,he⟩ := audit.trio.deposit.ModuleCall.finalizeAllocation_ok cursor next size.val ha
  have hsize : 32 ≤ size.val ∧ size.val < 2^255 := by
    have hh : (32 : Int) ≤ signed size := by
      have hn := of_decide_eq_false hh
      change ¬ signed size < 32 at hn
      omega
    by_cases hs : size.val < 2^255
    · simp only [signed,hs,if_true,Int.ofNat_eq_natCast] at hh
      exact ⟨by omega,hs⟩
    · simp only [signed,hs,if_false,Int.ofNat_eq_natCast] at hh
      have hb := size.isLt
      change size.val < 2^256 at hb
      omega
  have hr : size.val + 31 < 2^256 := by omega
  have hsum : cursor.val + (size.val + 31) / 32 * 32 < 2^256 := by omega
  have hv : next.val = cursor.val + (size.val + 31) / 32 * 32 := by
    rw [he]
    simp only [word,Verity.Core.Uint256.val_ofNat,round32,Nat.mod_eq_of_lt hr]
    exact Nat.mod_eq_of_lt hsum
  exact ⟨hsize.1,by omega,hn⟩

/-- Every success derives bounded nonwrapping copied pointers and certifies
that the *same* decoded values satisfy the retained byte decoder. -/
theorem decode_success (cursor next : Word) (raw : Bytes) (xs : List Word)
    (h : decodeReturn cursor raw = .ok (xs,next)) :
    TopupModuleCall.decodeReturn raw = .ok xs ∧
    ∃ postRaw, finalizeAllocation cursor (word raw.length).val = .ok postRaw ∧
      cursor.val + (word raw.length).val ≤ postRaw.val ∧ postRaw.val < 2^64 ∧
      finalizeAllocation postRaw (32*(decode ((raw.drop (decode (raw.take 32))).take 32))+32) = .ok next ∧
      postRaw.val ≤ next.val ∧ next.val < 2^64 := by
  unfold decodeReturn at h
  cases ha : finalizeAllocation cursor (word raw.length).val with
  | «error» fault => simp [ha,bind,Except.bind] at h
  | ok postRaw =>
    simp only [ha,bind,Except.bind] at h
    rw [audit.trio.deposit.ModuleCall.end_sub_base] at h
    split at h
    · cases h
    · rename_i hh
      have hh' : signedLt (word raw.length) (word 32) = false := Bool.eq_false_iff.mpr hh
      obtain ⟨hs,hraw,hr⟩ := raw_bounds cursor (word raw.length) postRaw ha hh'
      split at h
      · cases h
      · rename_i hoff
        split at h
        · cases h
        · rename_i hloc
          split at h
          · cases h
          · rename_i hcount
            cases hn : finalizeAllocation postRaw (32*decode ((raw.drop (decode (raw.take 32))).take 32)+32) with
            | «error» fault => simp [hn] at h
            | ok result =>
              simp only [hn] at h
              split at h
              · cases h
              · rename_i hend
                cases h
                obtain ⟨hnext,hmono,_⟩ := audit.trio.deposit.ModuleCall.finalizeAllocation_ok _ _ _ hn
                refine ⟨?_,postRaw,rfl,hraw,hr,hn,hmono,hnext⟩
                have hcur : cursor.val < 2^64 := by omega
                have hsize : (word raw.length).val < 2^64 := by omega
                have hmod : (word raw.length).val ≤ raw.length := Nat.mod_le _ _
                have hoff' : decode (raw.take 32) < 2^64 := by omega
                have hcount' : decode ((raw.drop (decode (raw.take 32))).take 32) < 2^64 := by omega
                have hptr : (word (cursor.val + decode (raw.take 32))).val = cursor.val + decode (raw.take 32) := by
                  simp only [word,Verity.Core.Uint256.val_ofNat,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS]
                  apply Nat.mod_eq_of_lt; omega
                have hendptr : (word (cursor.val + (word raw.length).val)).val = cursor.val + (word raw.length).val := by
                  change (cursor.val + (word raw.length).val) % 2^256 = _
                  apply Nat.mod_eq_of_lt; omega
                have hlptr : (word ((word (cursor.val + decode (raw.take 32))).val + 31)).val = cursor.val + decode (raw.take 32) + 31 := by
                  rw [hptr]
                  simp only [word,Verity.Core.Uint256.val_ofNat,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS]
                  apply Nat.mod_eq_of_lt; omega
                have heptr : (word ((word (cursor.val + decode (raw.take 32))).val + 32*decode ((raw.drop (decode (raw.take 32))).take 32)+32)).val = cursor.val + decode (raw.take 32) + 32*decode ((raw.drop (decode (raw.take 32))).take 32)+32 := by
                  rw [hptr]
                  simp only [word,Verity.Core.Uint256.val_ofNat,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS]
                  apply Nat.mod_eq_of_lt; omega
                have hl : decode (raw.take 32) + 32 ≤ (word raw.length).val := by
                  have hbool : signedLt (word ((word (cursor.val + decode (raw.take 32))).val + 31)) (word (cursor.val + (word raw.length).val)) = true := by simpa using hloc
                  have ht := of_decide_eq_true hbool
                  simp only [signed,hlptr,hendptr] at ht
                  rw [if_pos (by omega),if_pos (by omega)] at ht
                  omega
                rw [heptr,hendptr] at hend
                unfold TopupModuleCall.decodeReturn
                rw [if_neg (by omega),if_neg (by omega),if_neg (by omega),if_neg (by omega),if_neg (by omega)]

/-- The module is called once. Its actual return and World enter the guarded
memory decoder, then the very same existing continuation. -/
def program (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (deposit : Address) (i : TopupModuleCall.Input) : Exec Unit := do
  let raw ← TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i
  match decodeReturn cursor raw with
  | .error fault => fail fault
  | .ok (allocations,_) => TopupRouterContinuation.program hash x ctx deposit (TopupModuleCall.continuationInput i allocations)

def execute (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (deposit : Address) (i : TopupModuleCall.Input) : Exec Unit :=
  Live.run (program cursor hash m x ctx deposit i)

/-- Projection is an equality of executions, not a second execution within the
program. Successful scalar guards refine the earlier memory-abstract decoder. -/
theorem program_success (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (deposit : Address) (i : TopupModuleCall.Input) (before : World)
    (h : (program cursor hash m x ctx deposit i before).outcome = .ok ()) :
    program cursor hash m x ctx deposit i before = TopupModuleCall.program hash m x ctx deposit i before ∧
    ∃ raw after trace allocations next,
      TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before = ⟨.ok raw,after,trace⟩ ∧
      decodeReturn cursor raw = .ok (allocations,next) := by
  cases hc : TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before with
  | mk outcome after trace =>
    cases outcome with
    | «error» fault => simp [program,bind,bindExec,hc] at h
    | ok raw =>
      cases hd : decodeReturn cursor raw with
      | «error» fault => simp [program,bind,bindExec,hc,hd,fail] at h
      | ok pair =>
        rcases pair with ⟨allocations,next⟩
        have hold := (decode_success cursor next raw allocations hd).1
        refine ⟨?_,raw,after,trace,allocations,next,rfl,hd⟩
        simp [program,TopupModuleCall.program,bind,bindExec,hc,hd,hold]

theorem execute_success (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (deposit : Address) (i : TopupModuleCall.Input) (before : World)
    (h : (execute cursor hash m x ctx deposit i before).outcome = .ok ()) :
    execute cursor hash m x ctx deposit i before = TopupModuleCall.execute hash m x ctx deposit i before ∧
    ∃ raw after trace allocations next,
      TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before = ⟨.ok raw,after,trace⟩ ∧
      decodeReturn cursor raw = .ok (allocations,next) := by
  have hp : (program cursor hash m x ctx deposit i before).outcome = .ok () := by
    unfold execute Live.run at h
    dsimp only at h
    split at h <;> simp_all
  obtain ⟨he,hd⟩ := program_success cursor hash m x ctx deposit i before hp
  exact ⟨by simp only [execute,TopupModuleCall.execute,Live.run,he],hd⟩

#print axioms raw_bounds
#print axioms decode_success
#print axioms program_success
#print axioms execute_success
end LidoSRv3.Audit.Source.TopupModuleMemory
