import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Verity.AddressRecipientCallBridge
import LidoSRv3.Audit.Guarantees.PAddress1NoReentry

/-! # P-ADDRESS-1 live renaming of the claim batch (step 3c of the "not proven" cleanup, 2026-09-19)

`AddressRecipientCallBridge.runClaimWithdrawalsTo` is the registered live
executor of `WithdrawalQueue.claimWithdrawalsTo`. This module proves that
renaming two nonzero addresses `a₁ ↔ a₂` in the sender and in the request
owners commutes with that executor, balances, code and the recipient fixed.

**What "renaming" is here, stated rather than hidden.** The queue's request
metadata words and the owner-indexed `EnumerableSet` cells live at keccak
slots (`Compiler.Proofs.mappingSlotLocation`, a computable keccak-256), so the
model offers no injectivity of slot families and no renaming can be written
as a total function on raw storage without a collision-freedom premise. The
renaming is therefore an abstract pair `LiveRenaming.state` (on the entered
`ContractState`) and `LiveRenaming.world` (on the live `World`) together with
the exact lens equations the claim body reads and the exact write commutations
it performs: the metadata word of every request has its owner field renamed
(`renameOwnerWord`), the owner-indexed length/value/index cells of `o` become
those of `renameAddress a₁ a₂ o`, every other claim channel (finalized id,
checkpoint index, locked ether, amounts, checkpoints) is unchanged, balances
and code are fixed, and the queue's own two events have their sender word
renamed. Existence of such a pair is an explicit premise. No concrete instance or
equivalence between its existence and slot-family collision freedom is proved
here. The conditional theorem does not close global live-state equivariance.

**Weakening, stated in the open.** The recipient is an arbitrary callee
`External := Request → World → Reply`; nothing forces it to answer the renamed
world the way it answers the original one. The theorems therefore take the
callee's equivariance under the same renaming as an explicit hypothesis
(`hcallee`). A recipient whose reply depends on the queue's owner words or on
the sender identity is outside this result. A-NO-REENTRY (the recipient does
not call back into the queue) is not needed for the commutation itself; it
enters only in the batch corollary, which composes the renamed chain with
`PAddress1NoReentry.chain_nested_rejects`. The other live writer bodies
(`transferFrom`, `requestWithdrawals`, `unwrap`) are not treated here.

**Status:** real theorems with complete proofs; axioms `propext`, `Classical.choice`,
`Quot.sound` (see the `#print axioms` lines). -/

namespace LidoSRv3.Audit.Guarantees.PAddress1LiveRenaming

open LidoSRv3.Audit.SolidityAddress (renameAddress renameAddress_involutive renameAddress_injective)
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live (Log Word Request Reply Result Fault transfer emit
  bindExec require)
open LidoSRv3.Audit.Source.NoReentry
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge

/-! `World`, `Context`, `External` and `Address` are the bridge's abbreviations
of the `Live` types. -/

/-- The renamed context: same queue, renamed sender. -/
def renameContext (a₁ a₂ : Address) (ctx : Context) : Context :=
  { ctx with sender := renameAddress a₁ a₂ ctx.sender }

theorem renameContext_self (a₁ a₂ : Address) (ctx : Context) :
    (renameContext a₁ a₂ ctx).self = ctx.self := rfl

theorem renameContext_sender (a₁ a₂ : Address) (ctx : Context) :
    (renameContext a₁ a₂ ctx).sender = renameAddress a₁ a₂ ctx.sender := rfl

/-- Rename the owner field (low 160 bits) of a packed request metadata word;
timestamp, claimed bit and report timestamp are untouched. -/
def renameOwnerWord (a₁ a₂ : Address) (w : Verity.Core.Uint256) : Verity.Core.Uint256 :=
  .ofNat (w.val - w.val % 2 ^ 160 + (renameAddress a₁ a₂ (requestOwner w)).toNat)

private theorem addr_lt (a : Address) : a.toNat < 2 ^ 160 := by
  have h := a.isLt
  change a.val < 2 ^ 160 at h
  exact h

private theorem uint_lt (w : Verity.Core.Uint256) : w.val < 2 ^ 256 := by
  have h := w.isLt
  change w.val < 2 ^ 256 at h
  exact h

private theorem requestOwner_toNat (w : Verity.Core.Uint256) :
    (requestOwner w).toNat = w.val % 2 ^ 160 := by
  show (w.val % 2 ^ 160) % Verity.Core.Address.modulus = w.val % 2 ^ 160
  exact Nat.mod_eq_of_lt (Nat.mod_lt _ (Nat.two_pow_pos 160))

private theorem renameOwnerWord_val (a₁ a₂ : Address) (w : Verity.Core.Uint256) :
    (renameOwnerWord a₁ a₂ w).val =
      w.val - w.val % 2 ^ 160 + (renameAddress a₁ a₂ (requestOwner w)).toNat := by
  show (w.val - w.val % 2 ^ 160 + (renameAddress a₁ a₂ (requestOwner w)).toNat) %
      Verity.Core.Uint256.modulus = _
  apply Nat.mod_eq_of_lt
  have h1 := uint_lt w
  have h2 := addr_lt (renameAddress a₁ a₂ (requestOwner w))
  show _ < 2 ^ 256
  omega

theorem requestOwner_rename (a₁ a₂ : Address) (w : Verity.Core.Uint256) :
    requestOwner (renameOwnerWord a₁ a₂ w) = renameAddress a₁ a₂ (requestOwner w) := by
  apply Verity.Core.Address.toNat_injective
  rw [requestOwner_toNat, renameOwnerWord_val]
  have h2 := addr_lt (renameAddress a₁ a₂ (requestOwner w))
  omega

theorem requestClaimed_rename (a₁ a₂ : Address) (w : Verity.Core.Uint256) :
    requestClaimed (renameOwnerWord a₁ a₂ w) = requestClaimed w := by
  unfold requestClaimed
  rw [renameOwnerWord_val]
  have h2 := addr_lt (renameAddress a₁ a₂ (requestOwner w))
  have hdiv : (w.val - w.val % 2 ^ 160 + (renameAddress a₁ a₂ (requestOwner w)).toNat) / 2 ^ 200 =
      w.val / 2 ^ 200 := by omega
  rw [hdiv]

theorem markClaimed_rename (a₁ a₂ : Address) (w : Verity.Core.Uint256) :
    markClaimed (renameOwnerWord a₁ a₂ w) = renameOwnerWord a₁ a₂ (markClaimed w) := by
  have h1 := uint_lt w
  have hmod : ((w.val + 2 ^ 200) % 2 ^ 256) % 2 ^ 160 = w.val % 2 ^ 160 := by omega
  have howner : requestOwner (markClaimed w) = requestOwner w := by
    apply Verity.Core.Address.toNat_injective
    rw [requestOwner_toNat, requestOwner_toNat]
    show ((w.val + 2 ^ 200) % 2 ^ 256) % 2 ^ 160 = w.val % 2 ^ 160
    exact hmod
  apply Verity.Core.Uint256.ext
  show ((renameOwnerWord a₁ a₂ w).val + 2 ^ 200) % 2 ^ 256 =
    ((markClaimed w).val - (markClaimed w).val % 2 ^ 160 +
      (renameAddress a₁ a₂ (requestOwner (markClaimed w))).toNat) % 2 ^ 256
  rw [howner, renameOwnerWord_val]
  show _ = (((w.val + 2 ^ 200) % 2 ^ 256) - ((w.val + 2 ^ 200) % 2 ^ 256) % 2 ^ 160 +
      (renameAddress a₁ a₂ (requestOwner w)).toNat) % 2 ^ 256
  have h2 := addr_lt (renameAddress a₁ a₂ (requestOwner w))
  omega

theorem renameAddress_bne (a₁ a₂ x y : Address) :
    (renameAddress a₁ a₂ x != renameAddress a₁ a₂ y) = (x != y) := by
  show (!decide (renameAddress a₁ a₂ x = renameAddress a₁ a₂ y)) = (!decide (x = y))
  by_cases h : x = y
  · subst h
    simp
  · have h' : renameAddress a₁ a₂ x ≠ renameAddress a₁ a₂ y :=
      fun e => h (renameAddress_injective a₁ a₂ e)
    rw [decide_eq_false h, decide_eq_false h']

/-- Rename an address-valued event word. -/
def renameWord (a₁ a₂ : Address) (x : Word) : Word :=
  if x = Verity.Core.Uint256.ofNat a₁.toNat then Verity.Core.Uint256.ofNat a₂.toNat
  else if x = Verity.Core.Uint256.ofNat a₂.toNat then Verity.Core.Uint256.ofNat a₁.toNat
  else x

/-- The queue's two claim events carry the sender word (`WithdrawalClaimed` at
position 1, ERC-721 `Transfer` at position 0); every other log is unchanged. -/
def renameClaimLog (a₁ a₂ self : Address) (l : Log) : Log :=
  if l.emitter = self ∧ l.name = "WithdrawalClaimed" then
    ⟨l.emitter, l.name, l.values.set 1 (renameWord a₁ a₂ (l.values.getD 1 0))⟩
  else if l.emitter = self ∧ l.name = "Transfer" then
    ⟨l.emitter, l.name, l.values.set 0 (renameWord a₁ a₂ (l.values.getD 0 0))⟩
  else l

private theorem ofNat_toNat_inj (x y : Address)
    (h : Verity.Core.Uint256.ofNat x.toNat = Verity.Core.Uint256.ofNat y.toNat) : x = y := by
  apply Verity.Core.Address.toNat_injective
  have h' := congrArg Verity.Core.Uint256.val h
  rw [Verity.Core.Uint256.val_ofNat, Verity.Core.Uint256.val_ofNat] at h'
  have hx : x.toNat < Verity.Core.Uint256.modulus := Nat.lt_trans (addr_lt x) (by decide)
  have hy : y.toNat < Verity.Core.Uint256.modulus := Nat.lt_trans (addr_lt y) (by decide)
  rwa [Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt hy] at h'

theorem renameWord_sender (a₁ a₂ s : Address) :
    renameWord a₁ a₂ (Verity.Core.Uint256.ofNat s.toNat) =
      Verity.Core.Uint256.ofNat (renameAddress a₁ a₂ s).toNat := by
  unfold renameWord renameAddress
  by_cases h1 : s = a₁
  · subst h1
    simp
  · have e1 : ¬ (Verity.Core.Uint256.ofNat s.toNat = Verity.Core.Uint256.ofNat a₁.toNat) :=
      fun e => h1 (ofNat_toNat_inj _ _ e)
    by_cases h2 : s = a₂
    · subst h2
      simp [h1, e1]
    · have e2 : ¬ (Verity.Core.Uint256.ofNat s.toNat = Verity.Core.Uint256.ofNat a₂.toNat) :=
        fun e => h2 (ofNat_toNat_inj _ _ e)
      simp [h1, h2, e1, e2]

theorem renameClaimLog_claimed (a₁ a₂ self : Address) (requestId : Nat)
    (sender recipient : Address) (payout : Nat) :
    renameClaimLog a₁ a₂ self ⟨self, "WithdrawalClaimed",
        [Verity.Core.Uint256.ofNat requestId, Verity.Core.Uint256.ofNat sender.toNat,
          Verity.Core.Uint256.ofNat recipient.toNat, Verity.Core.Uint256.ofNat payout]⟩ =
      ⟨self, "WithdrawalClaimed",
        [Verity.Core.Uint256.ofNat requestId,
          Verity.Core.Uint256.ofNat (renameAddress a₁ a₂ sender).toNat,
          Verity.Core.Uint256.ofNat recipient.toNat, Verity.Core.Uint256.ofNat payout]⟩ := by
  unfold renameClaimLog
  rw [if_pos ⟨rfl, rfl⟩]
  show Log.mk self "WithdrawalClaimed"
    [_, renameWord a₁ a₂ (Verity.Core.Uint256.ofNat sender.toNat), _, _] = _
  rw [renameWord_sender]

theorem renameClaimLog_transfer (a₁ a₂ self : Address) (sender : Address) (requestId : Nat) :
    renameClaimLog a₁ a₂ self ⟨self, "Transfer",
        [Verity.Core.Uint256.ofNat sender.toNat, 0, Verity.Core.Uint256.ofNat requestId]⟩ =
      ⟨self, "Transfer",
        [Verity.Core.Uint256.ofNat (renameAddress a₁ a₂ sender).toNat, 0,
          Verity.Core.Uint256.ofNat requestId]⟩ := by
  unfold renameClaimLog
  rw [if_neg (fun h => absurd (show "Transfer" = "WithdrawalClaimed" from h.2)
    (by decide)), if_pos ⟨rfl, rfl⟩]
  show Log.mk self "Transfer" [renameWord a₁ a₂ (Verity.Core.Uint256.ofNat sender.toNat), _, _] = _
  rw [renameWord_sender]

/-- Transport helpers: the renaming applied to results and replies. -/
def mapCR (π : Verity.ContractState → Verity.ContractState) :
    Verity.ContractResult Nat → Verity.ContractResult Nat
  | .success payout s => .success payout (π s)
  | .revert reason s => .revert reason (π s)

def mapExcept (π : Verity.ContractState → Verity.ContractState) :
    Except String Verity.ContractState → Except String Verity.ContractState
  | .error e => .error e
  | .ok s => .ok (π s)

def mapResult {α : Type} (ω : World → World) (r : Result α) : Result α :=
  ⟨r.outcome, ω r.world, r.attempts⟩

def mapReply (ω : World → World) : Reply → Reply
  | .success d w => .success d (ω w)
  | .rejected d => .rejected d
  | .successWithTrace d w n => .successWithTrace d (ω w) n
  | .rejectedWithTrace d n => .rejectedWithTrace d n

theorem mapCR_success (π : Verity.ContractState → Verity.ContractState) (payout : Nat)
    (s : Verity.ContractState) : mapCR π (.success payout s) = .success payout (π s) := rfl

theorem mapCR_revert (π : Verity.ContractState → Verity.ContractState) (reason : String)
    (s : Verity.ContractState) : mapCR π (.revert reason s) = .revert reason (π s) := rfl

theorem mapExcept_ok (π : Verity.ContractState → Verity.ContractState) (s : Verity.ContractState) :
    mapExcept π (.ok s) = .ok (π s) := rfl

theorem mapExcept_error (π : Verity.ContractState → Verity.ContractState) (e : String) :
    mapExcept π (.error e) = .error e := rfl

theorem mapReply_success (ω : World → World) (d : Live.Bytes) (w : World) :
    mapReply ω (.success d w) = .success d (ω w) := rfl

theorem mapReply_rejected (ω : World → World) (d : Live.Bytes) :
    mapReply ω (.rejected d) = .rejected d := rfl

theorem mapReply_successWithTrace (ω : World → World) (d : Live.Bytes) (w : World)
    (n : List Live.NestedAttempt) :
    mapReply ω (.successWithTrace d w n) = .successWithTrace d (ω w) n := rfl

theorem mapReply_rejectedWithTrace (ω : World → World) (d : Live.Bytes)
    (n : List Live.NestedAttempt) :
    mapReply ω (.rejectedWithTrace d n) = .rejectedWithTrace d n := rfl

theorem mapCR_ite (π : Verity.ContractState → Verity.ContractState) (c : Prop) [Decidable c]
    (a b : Verity.ContractResult Nat) :
    mapCR π (if c then a else b) = if c then mapCR π a else mapCR π b := by
  by_cases h : c
  · rw [if_pos h, if_pos h]
  · rw [if_neg h, if_neg h]

theorem mapExcept_ite (π : Verity.ContractState → Verity.ContractState) (c : Prop) [Decidable c]
    (a b : Except String Verity.ContractState) :
    mapExcept π (if c then a else b) = if c then mapExcept π a else mapExcept π b := by
  by_cases h : c
  · rw [if_pos h, if_pos h]
  · rw [if_neg h, if_neg h]

/-- An address renaming of the live claim world. `state` acts on the entered
queue state, `world` on the whole `World`; the fields are the lens equations the
claim body reads and the write commutations it performs (see the module
docstring). -/
structure LiveRenaming (a₁ a₂ : Address) (ctx : Context) where
  state : Verity.ContractState → Verity.ContractState
  world : World → World
  state_sender : ∀ s, (state s).sender = renameAddress a₁ a₂ s.sender
  state_lastFinalized : ∀ s, (state s).readSlot lastFinalizedRequestIdPosition =
    s.readSlot lastFinalizedRequestIdPosition
  state_lastCheckpoint : ∀ s, (state s).readSlot lastCheckpointIndexPosition =
    s.readSlot lastCheckpointIndexPosition
  state_locked : ∀ s, (state s).readSlot lockedEtherAmountPosition =
    s.readSlot lockedEtherAmountPosition
  state_metadata : ∀ s requestId, requestMetadataWord (state s) requestId =
    renameOwnerWord a₁ a₂ (requestMetadataWord s requestId)
  state_amounts : ∀ s requestId, requestAmountsWord (state s) requestId =
    requestAmountsWord s requestId
  state_checkpointFrom : ∀ s hint, checkpointFromWord (state s) hint = checkpointFromWord s hint
  state_checkpointRate : ∀ s hint, checkpointRateWord (state s) hint = checkpointRateWord s hint
  state_setLength : ∀ s owner, ownerRequestValuesLength (state s) (renameAddress a₁ a₂ owner) =
    ownerRequestValuesLength s owner
  state_setValue : ∀ s owner index,
    ownerRequestValue (state s) (renameAddress a₁ a₂ owner) index = ownerRequestValue s owner index
  state_setIndex : ∀ s owner requestId,
    ownerRequestIndex (state s) (renameAddress a₁ a₂ owner) requestId =
      ownerRequestIndex s owner requestId
  state_writeMetadata : ∀ s requestId v,
    state (s.writeSlot (queueMetadataPhysicalSlot requestId) v) =
      (state s).writeSlot (queueMetadataPhysicalSlot requestId) (renameOwnerWord a₁ a₂ v)
  state_writeLocked : ∀ s v, state (s.writeSlot lockedEtherAmountPosition v) =
    (state s).writeSlot lockedEtherAmountPosition v
  state_writeSetValue : ∀ s owner index v,
    state (s.writeSlot (ownerRequestValueSlot owner index) v) =
      (state s).writeSlot (ownerRequestValueSlot (renameAddress a₁ a₂ owner) index) v
  state_writeSetIndex : ∀ s owner requestId v,
    state (s.writeSlot (ownerRequestIndexSlot owner requestId) v) =
      (state s).writeSlot (ownerRequestIndexSlot (renameAddress a₁ a₂ owner) requestId) v
  state_writeSetLength : ∀ s owner v,
    state (s.writeSlot (ownerRequestValuesLengthSlot owner) v) =
      (state s).writeSlot (ownerRequestValuesLengthSlot (renameAddress a₁ a₂ owner)) v
  world_enter : ∀ w, AccountFrame.enter (renameContext a₁ a₂ ctx) (world w).core =
    state (AccountFrame.enter ctx w.core)
  world_commit : ∀ w d, world {w with core := AccountFrame.commit ctx.self w.core d} =
    {world w with core := AccountFrame.commit ctx.self (world w).core (state d)}
  world_balances : ∀ w, (world w).balances = w.balances
  world_codeSize : ∀ w a, (world w).core.codeSize a = w.core.codeSize a
  world_transfer : ∀ w s r v, world (transfer w s r v) = transfer (world w) s r v
  world_logs : ∀ w, (world w).logs = w.logs.map (renameClaimLog a₁ a₂ ctx.self)
  world_logsUpdate : ∀ w l, world {w with logs := w.logs ++ l} =
    {world w with logs := (world w).logs ++ l.map (renameClaimLog a₁ a₂ ctx.self)}

variable {a₁ a₂ : Address} {ctx : Context}

theorem readRequest_rename (R : LiveRenaming a₁ a₂ ctx) (s : Verity.ContractState)
    (requestId hint : Nat) :
    readRequest (R.state s) requestId hint =
      { readRequest s requestId hint with
        owner := renameAddress a₁ a₂ (readRequest s requestId hint).owner } := by
  unfold readRequest
  simp only [R.state_amounts, R.state_metadata, R.state_checkpointFrom, R.state_checkpointRate,
    requestOwner_rename, requestClaimed_rename]

theorem removeOwnerRequestChecked_rename (R : LiveRenaming a₁ a₂ ctx)
    (s : Verity.ContractState) (owner : Address) (requestId : Nat) :
    removeOwnerRequestChecked (R.state s) (renameAddress a₁ a₂ owner) requestId =
      mapExcept R.state (removeOwnerRequestChecked s owner requestId) := by
  unfold removeOwnerRequestChecked
  dsimp only
  rw [R.state_setIndex, R.state_setLength]
  by_cases h0 : ownerRequestIndex s owner requestId = 0
  · rw [if_pos h0, if_pos h0]
    rfl
  rw [if_neg h0, if_neg h0]
  by_cases hl : ownerRequestValuesLength s owner = 0
  · rw [if_pos hl, if_pos hl]
    rfl
  rw [if_neg hl, if_neg hl]
  by_cases hne : (ownerRequestIndex s owner requestId - 1 != ownerRequestValuesLength s owner - 1) = true
  · rw [if_pos hne, if_pos hne]
    by_cases hge : ownerRequestIndex s owner requestId - 1 ≥ ownerRequestValuesLength s owner
    · rw [if_pos hge, if_pos hge]
      rfl
    rw [if_neg hge, if_neg hge, R.state_setValue, ← R.state_writeSetValue, ← R.state_writeSetIndex]
    dsimp only
    rw [R.state_setLength, mapExcept_ite, ← R.state_writeSetValue, ← R.state_writeSetLength,
      ← R.state_writeSetIndex]
    rfl
  · rw [if_neg hne, if_neg hne]
    dsimp only
    rw [R.state_setLength, mapExcept_ite, ← R.state_writeSetValue, ← R.state_writeSetLength,
      ← R.state_writeSetIndex]
    rfl

theorem prepareClaim_rename (R : LiveRenaming a₁ a₂ ctx) (requestId hint : Nat)
    (recipient : Address) (st : Verity.ContractState) :
    prepareClaim requestId hint recipient (R.state st) =
      mapCR R.state (prepareClaim requestId hint recipient st) := by
  by_cases h0 : requestId = 0
  · simp only [prepareClaim, h0, eq_self_iff_true, if_true, mapCR_revert]
  by_cases h1 : requestId > (st.readSlot lastFinalizedRequestIdPosition).val
  · simp only [prepareClaim, h0, h1, R.state_lastFinalized, Bool.false_eq_true, eq_self_iff_true, if_false, if_true, mapCR_success, mapCR_revert]
  by_cases hc : requestClaimed (requestMetadataWord st requestId) = true
  · simp only [prepareClaim, h0, h1, hc, R.state_lastFinalized, R.state_metadata,
      requestClaimed_rename, Bool.false_eq_true, eq_self_iff_true, if_false, if_true, mapCR_success, mapCR_revert]
  by_cases ho : (requestOwner (requestMetadataWord st requestId) != st.sender) = true
  · simp only [prepareClaim, h0, h1, hc, ho, R.state_lastFinalized, R.state_metadata,
      R.state_sender, requestClaimed_rename, requestOwner_rename, renameAddress_bne,
      Bool.false_eq_true, eq_self_iff_true, if_false, if_true, mapCR_success, mapCR_revert]
  cases hrem : removeOwnerRequestChecked
      (st.writeSlot (queueMetadataPhysicalSlot requestId)
        (markClaimed (requestMetadataWord st requestId)))
      (requestOwner (requestMetadataWord
        (st.writeSlot (queueMetadataPhysicalSlot requestId)
          (markClaimed (requestMetadataWord st requestId))) requestId)) requestId with
  | «error» reason =>
    simp only [prepareClaim, h0, h1, hc, ho, R.state_lastFinalized, R.state_metadata,
      R.state_sender, requestClaimed_rename, requestOwner_rename, renameAddress_bne,
      markClaimed_rename, ← R.state_writeMetadata, removeOwnerRequestChecked_rename R, hrem,
      mapExcept_error, Bool.false_eq_true, eq_self_iff_true, if_false, if_true, mapCR_success, mapCR_revert]
  | ok removed =>
    simp only [prepareClaim, h0, h1, hc, ho, R.state_lastFinalized, R.state_metadata,
      R.state_sender, requestClaimed_rename, requestOwner_rename, renameAddress_bne,
      markClaimed_rename, ← R.state_writeMetadata, removeOwnerRequestChecked_rename R, hrem,
      mapExcept_ok, mapExcept_error, R.state_lastCheckpoint, readRequest_rename R, R.state_checkpointFrom,
      Bool.false_eq_true, eq_self_iff_true, if_false, if_true, mapCR_ite, mapCR_success, mapCR_revert]

theorem claimOne_rename (R : LiveRenaming a₁ a₂ ctx) (requestId hint : Nat)
    (recipient : Address) (st : Verity.ContractState) :
    claimOne requestId hint recipient (R.state st) =
      mapCR R.state (claimOne requestId hint recipient st) := by
  unfold claimOne
  rw [prepareClaim_rename R]
  cases hp : prepareClaim requestId hint recipient st with
  | «revert» reason rollback => rfl
  | success payout removed =>
    simp only [mapCR_success, mapCR_revert, R.state_locked, ← R.state_writeLocked, mapCR_ite]

theorem bindExec_rename {α β : Type} (ω : World → World) (f f' : Exec α)
    (g g' : α → Exec β)
    (hf : ∀ w, f' (ω w) = mapResult ω (f w))
    (hg : ∀ a w, g' a (ω w) = mapResult ω (g a w)) (w : World) :
    bindExec f' g' (ω w) = mapResult ω (bindExec f g w) := by
  unfold bindExec
  rw [hf w]
  cases h : (f w).outcome with
  | «error» e => simp only [mapResult, h]
  | ok a => simp only [mapResult, h, hg]

theorem claimStorage_rename (R : LiveRenaming a₁ a₂ ctx) (requestId hint : Nat)
    (recipient : Address) (w : World) :
    claimStorage (renameContext a₁ a₂ ctx) requestId hint recipient (R.world w) =
      mapResult R.world (claimStorage ctx requestId hint recipient w) := by
  unfold claimStorage
  dsimp only
  rw [R.world_enter, claimOne_rename R]
  cases hc : claimOne requestId hint recipient (AccountFrame.enter ctx w.core) with
  | success payout after =>
    simp only [mapCR_success, mapResult, renameContext_self, R.world_commit]
  | «revert» reason rollback =>
    simp only [mapCR_revert, mapResult]

theorem emptyCodeAccount_rename (R : LiveRenaming a₁ a₂ ctx) (w : World) (recipient : Address) :
    emptyCodeAccount (R.world w) recipient ↔ emptyCodeAccount w recipient := by
  simp only [emptyCodeAccount, R.world_codeSize]

theorem emptyValueCall_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (recipient : Address) (payout : Nat) (w : World) :
    emptyValueCall callee (renameContext a₁ a₂ ctx) recipient payout (R.world w) =
      mapResult R.world (emptyValueCall callee ctx recipient payout w) := by
  simp only [emptyValueCall, renameContext_self, R.world_balances]
  by_cases hf : w.balances ctx.self < (Verity.Core.Uint256.ofNat payout).val
  · simp only [if_pos hf, mapResult]
  by_cases he : emptyCodeAccount w recipient
  · simp only [if_neg hf, if_pos he, if_pos ((emptyCodeAccount_rename R w recipient).mpr he),
      ← R.world_transfer, mapResult]
  · have he' : ¬ emptyCodeAccount (R.world w) recipient :=
      fun h => he ((emptyCodeAccount_rename R w recipient).mp h)
    simp only [if_neg hf, if_neg he, if_neg he', ← R.world_transfer, hcallee]
    cases hc : callee ⟨ctx.self, recipient, .ofNat payout, []⟩
        (transfer w ctx.self recipient (Verity.Core.Uint256.ofNat payout).val) with
    | rejected data => simp only [hc, mapReply_success, mapReply_rejected, mapReply_successWithTrace,
        mapReply_rejectedWithTrace, mapResult]
    | rejectedWithTrace data nested => simp only [hc, mapReply_success, mapReply_rejected, mapReply_successWithTrace,
        mapReply_rejectedWithTrace, mapResult]
    | success data after => simp only [hc, mapReply_success, mapReply_rejected, mapReply_successWithTrace,
        mapReply_rejectedWithTrace, mapResult]
    | successWithTrace data after nested => simp only [hc, mapReply_success, mapReply_rejected, mapReply_successWithTrace,
        mapReply_rejectedWithTrace, mapResult]

theorem payoutCall_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (recipient : Address) (payout : Nat) (w : World) :
    payoutCall callee (renameContext a₁ a₂ ctx) recipient payout (R.world w) =
      mapResult R.world (payoutCall callee ctx recipient payout w) :=
  emptyValueCall_rename R callee hcallee recipient payout w

theorem emit_rename (R : LiveRenaming a₁ a₂ ctx) (name : String) (vals vals' : List Word)
    (h : renameClaimLog a₁ a₂ ctx.self ⟨ctx.self, name, vals⟩ = ⟨ctx.self, name, vals'⟩)
    (w : World) :
    emit (renameContext a₁ a₂ ctx) name vals' (R.world w) =
      mapResult R.world (emit ctx name vals w) := by
  simp only [emit, mapResult, renameContext_self, R.world_logsUpdate, List.map_cons,
    List.map_nil, h]

theorem claimTo_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (requestId hint : Nat) (recipient : Address) (w : World) :
    claimTo callee (renameContext a₁ a₂ ctx) requestId hint recipient (R.world w) =
      mapResult R.world (claimTo callee ctx requestId hint recipient w) := by
  show bindExec _ _ (R.world w) = mapResult R.world (bindExec _ _ w)
  refine bindExec_rename R.world _ _ _ _ (claimStorage_rename R requestId hint recipient)
    (fun payout w => ?_) w
  refine bindExec_rename R.world _ _ _ _ (payoutCall_rename R callee hcallee recipient payout)
    (fun _ w => ?_) w
  exact bindExec_rename R.world _ _ _ _
    (emit_rename R _ _ _ (renameClaimLog_claimed a₁ a₂ ctx.self requestId ctx.sender recipient payout))
    (fun _ w => emit_rename R _ _ _ (renameClaimLog_transfer a₁ a₂ ctx.self ctx.sender requestId) w) w

theorem claimWithdrawalsLoop_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (recipient : Address) :
    ∀ (requestIds hints : List Nat) (w : World),
      claimWithdrawalsLoop callee (renameContext a₁ a₂ ctx) requestIds hints recipient (R.world w) =
        mapResult R.world (claimWithdrawalsLoop callee ctx requestIds hints recipient w)
  | [], [], _ => rfl
  | requestId :: requestIds, hint :: hints, w => by
      show bindExec _ _ (R.world w) = mapResult R.world (bindExec _ _ w)
      exact bindExec_rename R.world _ _ _ _ (claimTo_rename R callee hcallee requestId hint recipient)
        (fun _ w => claimWithdrawalsLoop_rename R callee hcallee recipient requestIds hints w) w
  | [], _ :: _, _ => rfl
  | _ :: _, [], _ => rfl

theorem require_rename (ω : World → World) (c : Bool) (f : Fault) (w : World) :
    require c f (ω w) = mapResult ω (require c f w) := by
  unfold require
  cases c
  · rfl
  · rfl

theorem claimWithdrawalsTo_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (requestIds hints : List Nat) (recipient : Address) (w : World) :
    claimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient (R.world w) =
      mapResult R.world (claimWithdrawalsTo callee ctx requestIds hints recipient w) := by
  show bindExec _ _ (R.world w) = mapResult R.world (bindExec _ _ w)
  refine bindExec_rename R.world _ _ _ _ (require_rename R.world _ _) (fun _ w => ?_) w
  exact bindExec_rename R.world _ _ _ _ (require_rename R.world _ _)
    (fun _ w => claimWithdrawalsLoop_rename R callee hcallee recipient requestIds hints w) w

/-- **Live renaming commutes with the registered claim batch.** For every
address renaming `R` of the queue world (owner words and owner-indexed cells
renamed, balances and code fixed, recipient fixed) and every recipient callee
equivariant under it, running `claimWithdrawalsTo` from the renamed sender on
the renamed world yields the same outcome and the same CALL transcript, and the
renamed final world. Root rollback is included: a failing batch returns
`R.world before` on the renamed side exactly when it returns `before` on the
original side. -/
theorem runClaimWithdrawalsTo_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (requestIds hints : List Nat) (recipient : Address) (w : World) :
    runClaimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient (R.world w) =
      mapResult R.world (runClaimWithdrawalsTo callee ctx requestIds hints recipient w) := by
  unfold runClaimWithdrawalsTo LidoSRv3.Audit.Source.TrioReserve1.Live.run
  rw [claimWithdrawalsTo_rename R callee hcallee]
  cases h : (claimWithdrawalsTo callee ctx requestIds hints recipient w).outcome with
  | «error» e => simp only [mapResult, h]
  | ok a => simp only [mapResult, h]

/-- Batch corollary: a committed batch stays committed under the renaming,
with the renamed final world, the same attempts, and the transported claim
chain; under A-NO-REENTRY for the recipient the renamed transcript has no
accepted nested call into the queue either. -/
theorem actual_claim_batch_rename (R : LiveRenaming a₁ a₂ ctx) (callee : External)
    (hcallee : ∀ (req : Request) (w : World), callee req (R.world w) = mapReply R.world (callee req w))
    (requestIds hints : List Nat) (recipient : Address) (w : World)
    (hNo : NoReentry callee [ctx.self])
    (h : (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).outcome = .ok ()) :
    (runClaimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient
      (R.world w)).outcome = .ok () ∧
    (runClaimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient
      (R.world w)).world =
      R.world (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).world ∧
    (runClaimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient
      (R.world w)).attempts =
      (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).attempts ∧
    ClaimChain callee (renameContext a₁ a₂ ctx) recipient requestIds hints (R.world w)
      (R.world (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).world)
      (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).attempts ∧
    ∀ attempt ∈ (runClaimWithdrawalsTo callee ctx requestIds hints recipient w).attempts,
      NestedRejects [ctx.self] attempt.nested := by
  have e := runClaimWithdrawalsTo_rename R callee hcallee requestIds hints recipient w
  have hs : (runClaimWithdrawalsTo callee (renameContext a₁ a₂ ctx) requestIds hints recipient
      (R.world w)).outcome = .ok () := (congrArg Result.outcome e).trans h
  have hchain := (runClaimWithdrawalsTo_success callee (renameContext a₁ a₂ ctx) requestIds hints
    recipient (R.world w) hs).2.2
  rw [e] at hchain
  refine ⟨hs, (congrArg Result.world e).trans rfl, (congrArg Result.attempts e).trans rfl, hchain, ?_⟩
  exact LidoSRv3.Audit.Guarantees.PAddress1NoReentry.chain_nested_rejects callee
    (renameContext a₁ a₂ ctx) recipient hNo hchain

#print axioms runClaimWithdrawalsTo_rename
#print axioms actual_claim_batch_rename

end LidoSRv3.Audit.Guarantees.PAddress1LiveRenaming
