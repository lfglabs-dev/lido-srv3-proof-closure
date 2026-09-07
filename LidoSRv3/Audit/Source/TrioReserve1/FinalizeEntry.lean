import LidoSRv3.Audit.Source.TrioReserve1.FinalizeRules
import LidoSRv3.Audit.Source.TrioReserve1.EntryRules

namespace LidoSRv3.Audit.Source.TrioReserve1.FinalizeEntry
open Live

def Active (ctx : Context) (w : World) : Prop :=
  (w.core.readContractSlot ctx.self.val QueueFinalize.resumeSlot).val ≤ w.core.blockTimestamp.val

def Authorized (keccak : Queue.Keccak) (ctx : Context) (w : World) : Prop :=
  (w.core.readContractSlot ctx.self.val (QueueFinalize.memberSlot keccak ctx.sender)).val % 256 ≠ 0

def FirstFits (ctx : Context) (w : World) : Prop :=
  FinalizeRules.finalized ctx w + 1 < Verity.Core.UINT256_MODULUS

/-- Metadata uses the saved first ID and the post-body physical tail, including
possible mapping-slot alias effects. Failed bodies emit no metadata. -/
def metadata (ctx : Context) (before : World) (body : Result Unit) : Result Unit :=
  match body.outcome with
  | .error fault => ⟨.error fault, body.world, body.attempts⟩
  | .ok _ => ⟨.ok (), {body.world with logs := body.world.logs ++
      [⟨ctx.self, "BatchMetadataUpdate", [word (FinalizeRules.finalized ctx before + 1),
        body.world.core.readContractSlot ctx.self.val Queue.lastSlot]⟩]}, body.attempts⟩

/-- Ordered ERC721 admission followed by independent base-body observations.
There is no source executor in this predicate. -/
def Describes (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (observed : Result Unit) : Prop :=
  (¬ Active ctx before ∧ observed = ⟨.error (.bubbled (encode 4 0x14378398)), before, []⟩) ∨
  (Active ctx before ∧ ¬ Authorized keccak ctx before ∧
    observed = ⟨.error (QueueFinalize.missingRole ctx.sender), before, []⟩) ∨
  (Active ctx before ∧ Authorized keccak ctx before ∧ ¬ FirstFits ctx before ∧
    observed = ⟨.error (.bubbled (Queue.panicBytes 0x11)), before, []⟩) ∨
  (Active ctx before ∧ Authorized keccak ctx before ∧ FirstFits ctx before ∧
    ∃ body, FinalizeRules.Describes keccak ctx last amount rate before body ∧
      observed = metadata ctx before body)

private theorem admitted (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (ha : Active ctx before) (hu : Authorized keccak ctx before)
    (hf : FirstFits ctx before) :
    QueueFinalize.entry keccak ctx last amount rate before =
      metadata ctx before (QueueFinalize.finalize keccak ctx last amount rate before) := by
  simp only [Active] at ha
  simp only [Authorized] at hu
  simp only [FirstFits, FinalizeRules.finalized] at hf
  simp [QueueFinalize.entry, QueueFinalize.add, Live.read, require, bind, bindExec,
    pure, pureExec, ha, hu, hf, metadata, FinalizeRules.finalized, emit]
  split <;> simp_all

theorem corresponds (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (observed : Result Unit) :
    Describes keccak ctx last amount rate before observed ↔
      QueueFinalize.entry keccak ctx last amount rate before = observed := by
  by_cases ha : Active ctx before
  · by_cases hu : Authorized keccak ctx before
    · by_cases hf : FirstFits ctx before
      · rw [admitted keccak ctx last amount rate before ha hu hf]
        simp only [Describes, ha, hu, hf, not_true_eq_false, false_and, true_and,
          false_or, FinalizeRules.corresponds]
        constructor
        · rintro ⟨body, rfl, h⟩
          exact h.symm
        · intro h
          exact ⟨_, rfl, h.symm⟩
      · simp only [Active] at ha
        simp only [Authorized] at hu
        simp only [FirstFits, FinalizeRules.finalized] at hf
        simp [Describes, ha, hu, hf, QueueFinalize.entry, QueueFinalize.add,
          Live.read, require, bind, bindExec, pure, pureExec, fail,
          Active, Authorized, FirstFits, FinalizeRules.finalized] at *
        exact eq_comm
    · simp only [Active] at ha
      simp only [Authorized] at hu
      simp [Describes, ha, hu, QueueFinalize.entry, Live.read, require, bind, bindExec,
        pure, pureExec, fail, Active, Authorized] at *
      exact eq_comm
  · simp only [Active] at ha
    simp [Describes, ha, QueueFinalize.entry, Live.read, require, bind, bindExec,
      pure, pureExec, fail, Active] at *
    exact eq_comm

theorem complete (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) : Describes keccak ctx last amount rate before
      (QueueFinalize.entry keccak ctx last amount rate before) :=
  (corresponds keccak ctx last amount rate before _).mpr rfl

theorem root_corresponds (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    VaultSpec.Root (fun w o a t => Describes keccak ctx last amount rate w ⟨o, a, t⟩)
      before outcome after trace ↔
      run (QueueFinalize.entry keccak ctx last amount rate) before = ⟨outcome, after, trace⟩ :=
  VaultRules.root_corresponds _ _
    (fun w a o t => corresponds keccak ctx last amount rate w ⟨o, a, t⟩)
    before after outcome trace

def Replies (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) :=
  EntryRules.Returns (fun _ => [])
    (VaultSpec.Root (fun w o a t => Describes keccak ctx last amount rate w ⟨o, a, t⟩))

theorem replies_corresponds (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word)
    (before : World) (reply : Reply) :
    Replies keccak ctx last amount rate before reply ↔
      ReplyABI.reply (fun _ => []) (QueueFinalize.entry keccak ctx last amount rate) before = reply :=
  EntryRules.returns_corresponds _ _ _
    (fun w a o t => root_corresponds keccak ctx last amount rate w a o t) before reply

/-- Payable ABI selection: short payloads reject, trailing bytes are ignored,
and nonmatching requests use the supplied fallback. -/
def Dispatches (keccak : Queue.Keccak) (queue : Address) (other : External)
    (req : Request) (before : World) (reply : Reply) : Prop :=
  let selected := req.target = queue ∧ req.payload.take 4 = encode 4 0xb6013cef
  (¬ selected ∧ reply = other req before) ∨
  (selected ∧ req.payload.length < 68 ∧ reply = .rejected []) ∨
  (selected ∧ ¬ req.payload.length < 68 ∧
    Replies keccak ⟨queue, req.caller⟩ (word (decode ((req.payload.drop 4).take 32)))
      req.value (word (decode ((req.payload.drop 36).take 32))) before reply)

theorem dispatch_corresponds (keccak : Queue.Keccak) (queue : Address) (other : External)
    (req : Request) (before : World) (reply : Reply) :
    Dispatches keccak queue other req before reply ↔
      QueueFinalize.dispatch keccak queue other req before = reply := by
  by_cases hs : req.target = queue ∧ req.payload.take 4 = encode 4 0xb6013cef
  · by_cases hl : req.payload.length < 68
    · simp [Dispatches, QueueFinalize.dispatch, hs, hl]
      exact eq_comm
    · simp [Dispatches, QueueFinalize.dispatch, hs, hl, replies_corresponds]
  · simp [Dispatches, QueueFinalize.dispatch, hs]
    exact eq_comm

end LidoSRv3.Audit.Source.TrioReserve1.FinalizeEntry
