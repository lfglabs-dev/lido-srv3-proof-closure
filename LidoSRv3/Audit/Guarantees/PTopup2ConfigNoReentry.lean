import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Guarantees.PTopup2SameBlock

/-! # P-TOPUP-2 `ConfigStable` from A-NO-REENTRY (caveat C1, 2026-09-19)

`PTopup2SameBlock.same_block_actual_batches_le_cap` took `ConfigStable` as a
premise: a successful batch leaves the gateway's `minBlockDistance` field and
the router's packed block cap unchanged. This module derives it from the
accepted assumption A-NO-REENTRY and drops the premise from the registered
same-block bound.

The batch executor writes storage in exactly four places: Lido's own words
(`withdrawDepositableEther`, `ctx.self`), the world returned by the module
`allocateDeposits` CALL (`b.moduleExternal`), the worlds returned by the
Lido-side dispatch of `withdrawDepositableEther` (`b.withdrawalExternal`: the
locator, queue and oracle reads and the router's `receiveDepositableEther`
callback), and the beacon deposit contract (`TopupBeaconCallee.dispatch`).
`Keeps a k p` says a program leaves account `a`'s word `k` unchanged on every
entry world; it is closed under the `Live` monad, reads, foreign-account
writes, events, and CALLs whose callee is `KeepsSlot`-preserving, and
`KeepsSlot` follows from `NoReentry`.

* Gateway word (`minBlockDistance`): fully derived. The module callee and the
  beacon deposit contract do not re-enter the gateway (A-NO-REENTRY), Lido's
  dispatch of `withdrawDepositableEther` does not write the gateway
  (`NoReentry b.withdrawalExternal [gateway]`), and Lido is not the gateway.
* Router cap word: derived for the module callee and the beacon deposit
  contract from A-NO-REENTRY. The one residual premise is
  `KeepsSlot b.withdrawalExternal ctx.sender (routerRoot + 5)`: the router's
  own `receiveDepositableEther` callback, which `withdrawDepositableEther`
  legitimately CALLs, must not write the cap word. A-NO-REENTRY cannot supply
  it, because a router-protected interpreter would *reject* that callback and
  no batch could succeed; on the pinned source the callback updates only the
  depositable-ether counter. So: the gateway word is derived from
  A-NO-REENTRY alone, the router cap word up to the router's own callback.

**Status:** real theorems with complete proofs; axioms `propext`, `Classical.choice`,
`Quot.sound`. -/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PTopup2ConfigNoReentry

open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.NoReentry
open LidoSRv3.Audit.Guarantees.PTopup2SameBlock
open LidoSRv3.Audit.Source.TopupBatchConsumer (blockCap)

/-- A callee whose accepted replies leave account `a`'s storage word `k` as it
received it. -/
def KeepsSlot (ext : External) (a : Address) (k : Nat) : Prop :=
  ∀ (req : Request) (w : World),
    (∀ (d : Bytes) (after : World), ext req w = .success d after →
      after.core.readContractSlot a.val k = w.core.readContractSlot a.val k) ∧
    (∀ (d : Bytes) (after : World) (n : List NestedAttempt),
      ext req w = .successWithTrace d after n →
      after.core.readContractSlot a.val k = w.core.readContractSlot a.val k)

theorem keepsSlot_of_noReentry {ext : External} {self : List Address} (h : NoReentry ext self)
    {a : Address} (ha : a ∈ self) (k : Nat) : KeepsSlot ext a k :=
  fun _ _ => ⟨fun _ _ hc => (returns_success h hc a ha).1 k,
    fun _ _ _ hc => ((returns_successWithTrace h hc).1 a ha).1 k⟩

/-- A program leaves account `a`'s storage word `k` unchanged on every entry
world (success or failure). -/
def Keeps (a : Address) (k : Nat) {α : Type} (p : Exec α) : Prop :=
  ∀ w, (p w).world.core.readContractSlot a.val k = w.core.readContractSlot a.val k

section generic
variable {a : Address} {k : Nat} {α β : Type}

theorem keeps_pure (x : α) : Keeps a k (pure x : Exec α) := fun _ => rfl
theorem keeps_pureExec (x : α) : Keeps a k (pureExec x) := fun _ => rfl
theorem keeps_fail (f : Fault) : Keeps a k (fail f : Exec α) := fun _ => rfl
theorem keeps_require (c : Bool) (f : Fault) : Keeps a k (require c f) := by
  intro w
  cases c
  · rfl
  · rfl

theorem keeps_bind {f : Exec α} {g : α → Exec β} (hf : Keeps a k f)
    (hg : ∀ x, Keeps a k (g x)) : Keeps a k (f >>= g) := by
  intro w
  show (bindExec f g w).world.core.readContractSlot a.val k = _
  unfold bindExec
  cases h : (f w).outcome with
  | «error» e => simpa only [h] using hf w
  | ok x => simpa only [h] using (hg x (f w).world).trans (hf w)

theorem keeps_ite {c : Prop} [Decidable c] {p q : Exec α} (hp : Keeps a k p) (hq : Keeps a k q) :
    Keeps a k (if c then p else q) := by
  intro w
  by_cases hc : c
  · rw [if_pos hc]
    exact hp w
  · rw [if_neg hc]
    exact hq w

theorem keeps_run {p : Exec α} (hp : Keeps a k p) : Keeps a k (Live.run p) := by
  intro w
  unfold Live.run
  cases h : (p w).outcome with
  | ok x => simpa only [h] using hp w
  | «error» e => simp only [h]

theorem keeps_read (ctx : Context) (pos : Nat) : Keeps a k (read ctx pos) := fun _ => rfl
theorem keeps_emit (ctx : Context) (name : String) (values : List Word) :
    Keeps a k (emit ctx name values) := fun _ => rfl

theorem read_other_account (core : Verity.ContractState) (writer reader pos key : Nat)
    (v : Word) (h : writer ≠ reader) :
    (core.writeContractSlot writer pos v).readContractSlot reader key =
      core.readContractSlot reader key := by
  have h' : reader ≠ writer := fun e => h e.symm
  by_cases hw : writer = 0
  · by_cases hr : reader = 0
    · exact absurd (hw.trans hr.symm) h
    · simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
        Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
        Verity.ContractState.storage, Verity.ContractState.contractStorage, hw, hr]
  · by_cases hr : reader = 0
    · simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
        Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
        Verity.ContractState.storage, Verity.ContractState.contractStorage, hw, hr]
    · simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
        Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
        Verity.ContractState.storage, Verity.ContractState.contractStorage, hw, hr, h, h']

theorem keeps_write (ctx : Context) (pos : Nat) (v : Word) (hself : ctx.self ≠ a) :
    Keeps a k (write ctx pos v) := by
  intro w
  show (w.core.writeContractSlot ctx.self.val pos v).readContractSlot a.val k = _
  exact read_other_account _ _ _ _ _ _
    (fun e => hself (Verity.Core.Address.toNat_injective _ _ e))

theorem call_slot {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) (w : World) :
    (call ext ctx target selector value w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  simp only [call]
  split
  · rfl
  · split
    · rfl
    · split
      all_goals first
        | rfl
        | exact ((hK _ _).1 _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)
        | exact ((hK _ _).2 _ _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)

theorem keeps_call {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) : Keeps a k (call ext ctx target selector value) :=
  fun w => call_slot hK ctx target selector value w

theorem lowLevelCall_slot {ext : External} (hK : KeepsSlot ext a k) (ctx : Context)
    (target : Address) (payload : Bytes) (value : Word) (w : World) :
    (audit.trio.consolidation.lowLevelCall ext ctx target payload value w).world.core.readContractSlot
        a.val k = w.core.readContractSlot a.val k := by
  simp only [audit.trio.consolidation.lowLevelCall]
  split
  · rfl
  · split
    · exact transfer_slot w ctx.self target value.val a.val k
    · split
      all_goals first
        | rfl
        | exact ((hK _ _).1 _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)
        | exact ((hK _ _).2 _ _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)

theorem invoke_slot {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Word) (w : World) :
    (CallData.invoke ext ctx target payload value w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  simp only [CallData.invoke]
  split
  · rfl
  · split
    · rfl
    · split
      all_goals first
        | rfl
        | exact ((hK _ _).1 _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)
        | exact ((hK _ _).2 _ _ _ (by assumption)).trans
            (transfer_slot w ctx.self target value.val a.val k)

end generic

section lido
variable {a : Address} {k : Nat}

theorem keeps_decodeWord (data : Bytes) (offset : Nat) : Keeps a k (decodeWord data offset) := by
  unfold decodeWord
  exact keeps_bind (keeps_require _ _) (fun _ => keeps_pure _)

theorem keeps_checkedAdd (x y : Nat) : Keeps a k (checkedAdd x y) := by
  unfold checkedAdd
  exact keeps_bind (keeps_require _ _) (fun _ => keeps_pure _)

theorem keeps_checkedSub (x y : Nat) : Keeps a k (checkedSub x y) := by
  unfold checkedSub
  exact keeps_bind (keeps_require _ _) (fun _ => keeps_pure _)

theorem keeps_getLidoLocator (ctx : Context) : Keeps a k (getLidoLocator ctx) := by
  unfold getLidoLocator
  exact keeps_bind (keeps_read _ _) (fun _ => keeps_pure _)

theorem keeps_locatorAddress {ext : External} (hK : KeepsSlot ext a k) (ctx : Context)
    (selector : Nat) : Keeps a k (locatorAddress ext ctx selector) := by
  unfold locatorAddress
  exact keeps_bind (keeps_getLidoLocator ctx) (fun _ => keeps_bind (keeps_call hK _ _ _ _)
    (fun _ => keeps_bind (keeps_decodeWord _ _) (fun _ => keeps_pure _)))

theorem keeps_stakingRouter {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) :
    Keeps a k (stakingRouter ext ctx) := keeps_locatorAddress hK ctx _

theorem keeps_withdrawalQueue {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) :
    Keeps a k (withdrawalQueue ext ctx) := keeps_locatorAddress hK ctx _

theorem keeps_canDeposit {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) :
    Keeps a k (canDeposit ext ctx) := by
  unfold canDeposit
  exact keeps_bind (keeps_withdrawalQueue hK ctx) (fun _ => keeps_bind (keeps_call hK _ _ _ _)
    (fun _ => keeps_bind (keeps_decodeWord _ _) (fun _ => keeps_ite (keeps_pure _)
      (keeps_bind (keeps_read _ _) (fun _ => keeps_pure _)))))

theorem keeps_getBufferedEtherAllocation {ext : External} (hK : KeepsSlot ext a k)
    (ctx : Context) : Keeps a k (getBufferedEtherAllocation ext ctx) := by
  unfold getBufferedEtherAllocation
  exact keeps_bind (keeps_read _ _) (fun _ => keeps_bind (keeps_read _ _)
    (fun _ => keeps_bind (keeps_withdrawalQueue hK ctx) (fun _ => keeps_bind (keeps_call hK _ _ _ _)
      (fun _ => keeps_bind (keeps_decodeWord _ _) (fun _ => keeps_pure _)))))

theorem keeps_getCurrentFrame {ext : External} (hK : KeepsSlot ext a k) (ctx : Context) :
    Keeps a k (getCurrentFrame ext ctx) := by
  unfold getCurrentFrame
  exact keeps_bind (keeps_locatorAddress hK ctx _) (fun _ => keeps_bind (keeps_call hK _ _ _ _)
    (fun _ => keeps_bind (keeps_require _ _) (fun _ => keeps_bind (keeps_decodeWord _ _)
      (fun _ => keeps_bind (keeps_decodeWord _ _) (fun _ => keeps_pure _)))))

theorem keeps_getDepositedNextReportAdjusted {ext : External} (hK : KeepsSlot ext a k)
    (ctx : Context) : Keeps a k (getDepositedNextReportAdjusted ext ctx) := by
  unfold getDepositedNextReportAdjusted
  exact keeps_bind (keeps_read _ _) (fun _ => keeps_bind (keeps_getCurrentFrame hK ctx)
    (fun x => by
      rcases x with ⟨nonce, t⟩
      exact keeps_pure _))

theorem keeps_setDepositsReserve (ctx : Context) (hself : ctx.self ≠ a) (reserve : Nat) :
    Keeps a k (setDepositsReserve ctx reserve) := by
  unfold setDepositsReserve
  exact keeps_bind (keeps_write _ _ _ hself) (fun _ => keeps_emit _ _ _)

theorem keeps_spendDepositableEther {ext : External} (hK : KeepsSlot ext a k) (ctx : Context)
    (hself : ctx.self ≠ a) (amount : Word) : Keeps a k (spendDepositableEther ext ctx amount) := by
  unfold spendDepositableEther
  exact keeps_bind (keeps_getBufferedEtherAllocation hK ctx) (fun _ =>
    keeps_bind (keeps_require _ _) (fun _ => keeps_bind (keeps_read _ _) (fun _ =>
      keeps_bind (keeps_checkedAdd _ _) (fun _ => keeps_bind (keeps_checkedSub _ _) (fun _ =>
        keeps_bind (keeps_write _ _ _ hself) (fun _ => keeps_bind (keeps_emit _ _ _) (fun _ =>
          keeps_bind (keeps_emit _ _ _) (fun _ =>
            keeps_bind (keeps_getDepositedNextReportAdjusted hK ctx) (fun x => by
              rcases x with ⟨next, nonce⟩
              exact keeps_bind (keeps_checkedAdd _ _) (fun _ =>
                keeps_bind (keeps_write _ _ _ hself) (fun _ => keeps_bind (keeps_read _ _) (fun _ =>
                  keeps_ite (keeps_setDepositsReserve ctx hself _) (keeps_pure _)))))))))))))

theorem keeps_withdrawDepositableEther {ext : External} (hK : KeepsSlot ext a k) (ctx : Context)
    (hself : ctx.self ≠ a) (amount seeds : Word) :
    Keeps a k (withdrawDepositableEther ext ctx amount seeds) := by
  unfold withdrawDepositableEther
  exact keeps_bind (keeps_canDeposit hK ctx) (fun _ => keeps_bind (keeps_require _ _) (fun _ =>
    keeps_bind (keeps_stakingRouter hK ctx) (fun _ => keeps_bind (keeps_require _ _) (fun _ =>
      keeps_bind (keeps_require _ _) (fun _ =>
        keeps_bind (keeps_spendDepositableEther hK ctx hself amount) (fun _ =>
          keeps_ite
            (keeps_bind (keeps_read _ _) (fun _ => keeps_bind (keeps_checkedAdd _ _) (fun _ =>
              keeps_bind (keeps_write _ _ _ hself) (fun _ => keeps_bind (keeps_emit _ _ _) (fun _ =>
                keeps_bind (keeps_call hK _ _ _ _) (fun _ => keeps_pure _))))))
            (keeps_bind (keeps_pure _) (fun _ =>
              keeps_bind (keeps_call hK _ _ _ _) (fun _ => keeps_pure _)))))))))

theorem keeps_suffix {ext : External} (hK : KeepsSlot ext a k) (ctx : Context)
    (hself : ctx.self ≠ a) (amount : Word) : Keeps a k (TopupLiveWithdrawal.suffix ext ctx amount) := by
  unfold TopupLiveWithdrawal.suffix
  exact keeps_ite (keeps_pureExec _) (keeps_withdrawDepositableEther hK ctx hself amount _)

end lido

section beacon
variable {a : Address} {k : Nat}

theorem keeps_push (hash : TopupBeaconCallee.Hash) (target : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch hash target) a k) (ctx : Context)
    (payload : Bytes) (amount : Word) :
    Keeps a k (TopupBeaconEffects.push hash ctx target payload amount) :=
  fun w => invoke_slot hB ctx target payload amount w

theorem keeps_beaconLoop (target : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256 target) a k)
    (ctx : Context) :
    ∀ (inputs : List DepositDataRootCorrespondence.SourceDepositDataRootInput) (amounts : List Nat),
      Keeps a k (TopupBeaconBatch.loop ctx target inputs amounts)
  | [], [] => keeps_pureExec _
  | [], _ :: _ => keeps_fail _
  | _ :: _, [] => keeps_fail _
  | input :: inputs, amt :: amounts => by
      unfold TopupBeaconBatch.loop
      exact keeps_bind (keeps_require _ _) (fun _ =>
        keeps_ite (keeps_beaconLoop target hB ctx inputs amounts)
          (keeps_bind (keeps_require _ _) (fun _ => keeps_bind (keeps_require _ _) (fun _ =>
            keeps_bind (keeps_push _ target hB _ _ _)
              (fun _ => keeps_beaconLoop target hB ctx inputs amounts)))))

theorem keeps_helper (beacon : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256 beacon) a k)
    (hash : TopupRouterCredentials.Keccak) (ctx : Context) (i : TopupRouterContinuation.Input) :
    Keeps a k (TopupRouterContinuation.helper hash ctx beacon i) := by
  intro w
  unfold TopupRouterContinuation.helper
  split
  · rfl
  · split
    · rfl
    · exact keeps_beaconLoop beacon hB ctx _ _ w

theorem keeps_finish (router : Address) (i : TopupRouterContinuation.Input) (total old : Nat) :
    Keeps a k (TopupRouterContinuation.finish router i total old) := by
  intro w
  unfold TopupRouterContinuation.finish
  split
  · rfl
  · rfl

end beacon

section batch
variable {a : Address} {k : Nat}

theorem keeps_continuation {ext : External} (hW : KeepsSlot ext a k) (beacon : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256 beacon) a k)
    (hash : TopupRouterCredentials.Keccak) (ctx : Context) (hself : ctx.self ≠ a)
    (i : TopupRouterContinuation.Input) :
    Keeps a k (TopupRouterContinuation.program hash ext ctx beacon i) := by
  intro w
  unfold TopupRouterContinuation.program
  split
  · rfl
  · split
    · rfl
    · split
      · rfl
      · exact keeps_bind (keeps_run (keeps_suffix hW ctx hself _))
          (fun _ => keeps_bind (keeps_helper beacon hB hash _ i) (fun _ => keeps_finish _ _ _ _)) w

theorem keeps_moduleCall {ext : External} (hM : KeepsSlot ext a k)
    (hash : TopupRouterCredentials.Keccak) (ctx : Context) (i : TopupModuleCall.Input) :
    Keeps a k (TopupModuleCall.call hash ext ctx i) :=
  fun w => lowLevelCall_slot hM ctx _ _ _ w

theorem keeps_moduleProgram {m x : External} (hM : KeepsSlot m a k) (hW : KeepsSlot x a k)
    (beacon : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256 beacon) a k)
    (hash : TopupRouterCredentials.Keccak) (ctx : Context) (hself : ctx.self ≠ a)
    (i : TopupModuleCall.Input) :
    Keeps a k (TopupModuleCall.program hash m x ctx beacon i) := by
  unfold TopupModuleCall.program
  exact keeps_bind (keeps_moduleCall hM hash _ i) (fun raw => by
    cases TopupModuleCall.decodeReturn raw with
    | «error» e => exact keeps_fail _
    | ok allocations => exact keeps_continuation hW beacon hB hash ctx hself _)

theorem keeps_execute {m x : External} (hM : KeepsSlot m a k) (hW : KeepsSlot x a k)
    (beacon : Address)
    (hB : KeepsSlot (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256 beacon) a k)
    (hash : TopupRouterCredentials.Keccak) (ctx : Context) (hself : ctx.self ≠ a)
    (i : TopupModuleCall.Input) :
    Keeps a k (TopupModuleCall.execute hash m x ctx beacon i) := by
  unfold TopupModuleCall.execute
  exact keeps_run (keeps_moduleProgram hM hW beacon hB hash ctx hself i)

private theorem bind_success {ε α β : Type} {first : Except ε α}
    {next : α → Except ε β} {value : β} (h : (first >>= next) = .ok value) :
    ∃ x, first = .ok x ∧ next x = .ok value := by
  cases first with
  | «error» e => cases h
  | ok x => exact ⟨x, rfl, h⟩

/-- A committed batch is the executor run on the entry world: its final world
keeps every word that `TopupModuleCall.execute` keeps. -/
theorem consume_keeps (gateway : Address) (ctx : Context) (b : Batch) (w : World)
    (r : Result Unit) (h : consume gateway ctx b w = .ok r)
    (hk : ∀ i, Keeps a k (TopupModuleCall.execute b.hash b.moduleExternal b.withdrawalExternal
      ctx b.depositContract i)) :
    r.world.core.readContractSlot a.val k = w.core.readContractSlot a.val k := by
  unfold consume TopupBatchConsumer.run at h
  dsimp only at h
  obtain ⟨u, _, h⟩ := bind_success h
  cases u
  obtain ⟨out, _, h⟩ := bind_success h
  change Except.ok _ = Except.ok r at h
  cases h
  exact hk _ w

end batch

/-- **`ConfigStable` from A-NO-REENTRY.** The module callee and the beacon
deposit contract do not re-enter the gateway or the router (A-NO-REENTRY),
Lido's dispatch of `withdrawDepositableEther` does not write the gateway, Lido
is neither the gateway nor the router, and the router's own
`receiveDepositableEther` callback keeps the cap word. Then every successful
batch leaves the gateway's `minBlockDistance` field and the router's packed
block cap unchanged. -/
theorem configStable_of_noReentry (gateway : Address) (ctx : Context) (b : Batch)
    (hLidoGateway : ctx.self ≠ gateway) (hLidoRouter : ctx.self ≠ ctx.sender)
    (hModule : NoReentry b.moduleExternal [gateway, ctx.sender])
    (hBeacon : NoReentry (TopupBeaconCallee.dispatch DepositDataRootCorrespondence.sha256
      b.depositContract) [gateway, ctx.sender])
    (hWithdrawal : NoReentry b.withdrawalExternal [gateway])
    (hCapCallback : KeepsSlot b.withdrawalExternal ctx.sender (TopupRouterCredentials.routerRoot + 5)) :
    ConfigStable gateway ctx b := by
  intro w r h _
  have hg : gateway ∈ [gateway, ctx.sender] := List.mem_cons_self
  have hr : ctx.sender ∈ [gateway, ctx.sender] :=
    List.mem_cons_of_mem _ (List.mem_singleton.mpr rfl)
  refine ⟨?_, ?_⟩
  · unfold TopupTimingHistory.minDistance TopupTimingHistory.stored
    rw [consume_keeps gateway ctx b w r h (fun i => keeps_execute
      (keepsSlot_of_noReentry hModule hg _) (keepsSlot_of_noReentry hWithdrawal
        (List.mem_singleton.mpr rfl) _) b.depositContract
      (keepsSlot_of_noReentry hBeacon hg _) b.hash ctx hLidoGateway i)]
  · simp only [blockCap]
    rw [consume_keeps gateway ctx b w r h (fun i => keeps_execute
      (keepsSlot_of_noReentry hModule hr _) hCapCallback b.depositContract
      (keepsSlot_of_noReentry hBeacon hr _) b.hash ctx hLidoRouter i)]

/-- **Same-block bound without the `ConfigStable` premise.** The registered
`same_block_actual_batches_le_cap` with `ConfigStable` replaced by
A-NO-REENTRY on every batch's module callee and beacon deposit contract, the
gateway half of A-NO-REENTRY on Lido's dispatch, and the router callback's
cap-word preservation. -/
theorem same_block_actual_batches_le_cap_no_reentry (gateway : Address) (ctx : Context)
    (blockNumber timestamp cap : Nat) (hBlock : blockNumber ≠ 0) (hWidth : blockNumber < 2^32)
    (calls : List Batch) (w : World) (hDist : 0 < TopupTimingHistory.minDistance gateway w)
    (hCap : (blockCap ctx.sender w).val = cap)
    (hLidoGateway : ctx.self ≠ gateway) (hLidoRouter : ctx.self ≠ ctx.sender)
    (hModule : ∀ b ∈ calls, NoReentry b.moduleExternal [gateway, ctx.sender])
    (hBeacon : ∀ b ∈ calls, NoReentry (TopupBeaconCallee.dispatch
      DepositDataRootCorrespondence.sha256 b.depositContract) [gateway, ctx.sender])
    (hWithdrawal : ∀ b ∈ calls, NoReentry b.withdrawalExternal [gateway])
    (hCapCallback : ∀ b ∈ calls,
      KeepsSlot b.withdrawalExternal ctx.sender (TopupRouterCredentials.routerRoot + 5)) :
    (runMany gateway ctx blockNumber timestamp w calls).1.sum ≤ cap * 10^9 :=
  same_block_actual_batches_le_cap gateway ctx blockNumber timestamp cap hBlock hWidth calls w
    hDist hCap (fun b hb => configStable_of_noReentry gateway ctx b hLidoGateway hLidoRouter
      (hModule b hb) (hBeacon b hb) (hWithdrawal b hb) (hCapCallback b hb))

theorem same_block_actual_batches_le_blockCap_no_reentry (gateway : Address) (ctx : Context)
    (blockNumber timestamp : Nat) (hBlock : blockNumber ≠ 0) (hWidth : blockNumber < 2^32)
    (calls : List Batch) (w : World) (hDist : 0 < TopupTimingHistory.minDistance gateway w)
    (hLidoGateway : ctx.self ≠ gateway) (hLidoRouter : ctx.self ≠ ctx.sender)
    (hModule : ∀ b ∈ calls, NoReentry b.moduleExternal [gateway, ctx.sender])
    (hBeacon : ∀ b ∈ calls, NoReentry (TopupBeaconCallee.dispatch
      DepositDataRootCorrespondence.sha256 b.depositContract) [gateway, ctx.sender])
    (hWithdrawal : ∀ b ∈ calls, NoReentry b.withdrawalExternal [gateway])
    (hCapCallback : ∀ b ∈ calls,
      KeepsSlot b.withdrawalExternal ctx.sender (TopupRouterCredentials.routerRoot + 5)) :
    (runMany gateway ctx blockNumber timestamp w calls).1.sum ≤
      (blockCap ctx.sender w).val * PTopup2.GWEI :=
  same_block_actual_batches_le_cap_no_reentry gateway ctx blockNumber timestamp _ hBlock hWidth
    calls w hDist rfl hLidoGateway hLidoRouter hModule hBeacon hWithdrawal hCapCallback

#print axioms configStable_of_noReentry
#print axioms same_block_actual_batches_le_cap_no_reentry
#print axioms same_block_actual_batches_le_blockCap_no_reentry

end LidoSRv3.Audit.Guarantees.PTopup2ConfigNoReentry
