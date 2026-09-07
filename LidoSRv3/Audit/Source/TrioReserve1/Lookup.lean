import LidoSRv3.Audit.Source.TrioReserve1.LookupSpec
import LidoSRv3.Audit.Source.TrioReserve1.Status

namespace LidoSRv3.Audit.Source.TrioReserve1.Lookup
open Live

def decodedAddress (data : Bytes) : Address :=
  Verity.Core.Address.ofNat (word (decode (data.take 32))).val

theorem address_narrowing (data : Bytes) :
    (decodedAddress data).val = (word (decode (data.take 32))).val % 2^160 := rfl

/-- The CALL target is the low 160 bits of the physical locator word. The result
is decoded from actual bytes, retaining every returned world and attempted call. -/
def Describes (external : External) (ctx : Context) (selector : Nat) (before : World) :
    Except Fault Address → World → List Attempt → Prop :=
  LookupSpec.Returns .empty List.length decodedAddress
    (fun w outcome after trace => call external ctx
      (Verity.Core.Address.ofNat (before.core.readContractSlot ctx.self.val locatorSlot).val)
      selector (word 0) w = ⟨outcome, after, trace⟩) before

theorem of_spec (external : External) (ctx : Context) (selector : Nat) (before after : World)
    (outcome : Except Fault Address) (trace : List Attempt)
    (h : Describes external ctx selector before outcome after trace) :
    locatorAddress external ctx selector before = ⟨outcome, after, trace⟩ := by
  cases h <;> simp_all [locatorAddress, getLidoLocator, Live.read, decodeWord, decodedAddress,
    bind, bindExec, require, pure, pureExec, fail, Nat.not_le.mpr]

theorem exists_spec (external : External) (ctx : Context) (selector : Nat) (before : World) :
    ∃ outcome after trace, Describes external ctx selector before outcome after trace := by
  generalize hc : call external ctx
    (Verity.Core.Address.ofNat (before.core.readContractSlot ctx.self.val locatorSlot).val)
    selector (word 0) before = callResult
  rcases callResult with ⟨outcome, after, trace⟩
  cases outcome with
  | error fault => exact ⟨_, _, _, .call_error hc⟩
  | ok data =>
    by_cases hn : 32 ≤ data.length
    · exact ⟨_, _, _, .decoded hc hn⟩
    · exact ⟨_, _, _, .malformed hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (selector : Nat) (before after : World)
    (outcome : Except Fault Address) (trace : List Attempt)
    (h : locatorAddress external ctx selector before = ⟨outcome, after, trace⟩) :
    Describes external ctx selector before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx selector before
  have he := of_spec external ctx selector before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (selector : Nat) (before after : World)
    (outcome : Except Fault Address) (trace : List Attempt) :
    Describes external ctx selector before outcome after trace ↔
      locatorAddress external ctx selector before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx selector before after outcome trace, to_spec external ctx selector before after outcome trace⟩

/-- Status with its queue lookup replaced by physical locator and independent
CALL/ABI/address rules. The bunker CALL remains the next explicit boundary. -/
def Status (external : External) (ctx : Context) (before : World) :
    Except Fault Bool → World → List Attempt → Prop :=
  StatusSpec.Evaluates .empty List.length (fun data => (word (decode (data.take 32))).val)
    (fun w => (w.core.readContractSlot ctx.self.val activeSlot).val)
    (fun w outcome after trace => Describes external ctx 0x37d5fe99 w outcome after trace)
    (fun queue w outcome after trace => call external ctx queue 0x2b95b781 (word 0) w = ⟨outcome, after, trace⟩)
    before

theorem status_corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Bool) (trace : List Attempt) :
    Status external ctx before outcome after trace ↔ canDeposit external ctx before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Describes external ctx 0x37d5fe99 w outcome after trace) =
      (fun w outcome after trace => withdrawalQueue external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx 0x37d5fe99 w after outcome trace)
  unfold Status
  rw [he]
  exact LidoSRv3.Audit.Source.TrioReserve1.Status.corresponds external ctx before after outcome trace

def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Status external ctx w outcome after trace)
    (fun w outcome after trace => Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩)
    (fun target w outcome after trace => WithdrawalTail.finish external ctx target amount seeds w = ⟨outcome, after, trace⟩)
    before

/-- Both live address lookups and status are expanded into independent rules in
the exhaustive parent relation. CALL/primitive binding and spending/tail internals
remain explicit, rather than assumed covered by this substitution. -/
theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  have hs : (fun w outcome after trace => Status external ctx w outcome after trace) =
      (fun w outcome after trace => canDeposit external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (status_corresponds external ctx w after outcome trace)
  have hr : (fun w outcome after trace => Describes external ctx 0xef6c064c w outcome after trace) =
      (fun w outcome after trace => stakingRouter external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx 0xef6c064c w after outcome trace)
  unfold Withdrawal
  rw [hs, hr]
  exact WithdrawalParent.corresponds external ctx amount seeds before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.Lookup
