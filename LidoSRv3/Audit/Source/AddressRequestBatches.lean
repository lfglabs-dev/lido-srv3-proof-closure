import LidoSRv3.Audit.Guarantees.PAddress1RequestCalls
import LidoSRv3.Audit.Guarantees.PAddress1WrappedTransferCalls

/-! Pinned WQ request batch's entry pause check and ordered typed-array loop.
Physical memory allocation, outer ABI decoding and gas are outside this source
slice; a List Word represents the decoded input and typed result-array domain.
The queue retains the accepted designated root storage lens. -/
namespace LidoSRv3.Audit.Source.AddressRequestBatches
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)

/-- keccak256("lido.PausableUntil.resumeSinceTimestamp"), full uint256 slot. -/
def resumeSlot : Nat := 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02

def Resumed (w : World) : Prop :=
  (w.core.readSlot resumeSlot).val ≤ w.core.blockTimestamp.val

/-- Ordered typed iteration. A later failure keeps all attempted calls; the
entry runner below rolls back all preceding successful item worlds and logs. -/
def loop (step : Word → Exec Nat) : List Word → Exec (List Nat)
  | [] => pureExec []
  | amount :: amounts => fun before =>
    let first := step amount before
    match first.outcome with
    | .error e => ⟨.error e, first.world, first.attempts⟩
    | .ok id =>
      let rest := loop step amounts first.world
      match rest.outcome with
      | .error e => ⟨.error e, rest.world, first.attempts ++ rest.attempts⟩
      | .ok ids => ⟨.ok (id :: ids), rest.world, first.attempts ++ rest.attempts⟩

/-- Each constructor connects the entire supplied item effect to the next
item's actual world, result ID and ordered call journal. -/
inductive Transcript (effect : Word → Nat → World → World → List Attempt → Prop) :
    List Word → List Nat → World → World → List Attempt → Prop
  | nil (w : World) : Transcript effect [] [] w w []
  | cons {amount : Word} {amounts : List Word} {id : Nat} {ids : List Nat}
      {before middle after : World} {first rest : List Attempt} :
      effect amount id before middle first →
      Transcript effect amounts ids middle after rest →
      Transcript effect (amount :: amounts) (id :: ids) before after (first ++ rest)

theorem transcript_length {effect : Word → Nat → World → World → List Attempt → Prop}
    {amounts : List Word} {ids : List Nat} {before after : World} {attempts : List Attempt}
    (h : Transcript effect amounts ids before after attempts) : ids.length = amounts.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simpa only [List.length_cons] using congrArg Nat.succ ih

/-- Generic composition lemma. Its item implication is discharged below by the
existing public theorems; it is not an extra premise of either public consumer. -/
theorem loop_success (step : Word → Exec Nat)
    (effect : Word → Nat → World → World → List Attempt → Prop)
    (item : ∀ amount id before, (step amount before).outcome = .ok id →
      effect amount id before (step amount before).world (step amount before).attempts)
    (amounts : List Word) (ids : List Nat) (before : World)
    (h : (loop step amounts before).outcome = .ok ids) :
    Transcript effect amounts ids before (loop step amounts before).world
      (loop step amounts before).attempts := by
  induction amounts generalizing ids before with
  | nil =>
    simp only [loop, pureExec, Except.ok.injEq] at h
    subst ids
    exact Transcript.nil before
  | cons amount amounts ih =>
    cases hf : (step amount before).outcome with
    | «error» e => simp only [loop, hf] at h; contradiction
    | ok id =>
      cases hr : (loop step amounts (step amount before).world).outcome with
      | «error» e => simp only [loop, hf, hr] at h; contradiction
      | ok rest =>
        simp only [loop, hf, hr, Except.ok.injEq] at h
        subst ids
        simp only [loop, hf, hr]
        exact Transcript.cons (item amount id before hf) (ih rest _ hr)

/-- _checkResumed executes ONCE before owner selection and even an empty loop.
A callee changing resumeSlot later does not insert a second pause check. -/
def entry (step : Address → Word → Exec Nat) (ctx : Context) (owner : Address)
    (amounts : List Word) : Exec (List Nat) := fun before =>
  if before.core.blockTimestamp.val < (before.core.readSlot resumeSlot).val then
    fail (.reason "ResumedExpected") before
  else loop (step (resolvedOwner ctx owner)) amounts before

def runBatch (step : Address → Word → Exec Nat) (ctx : Context) (owner : Address)
    (amounts : List Word) : Exec (List Nat) := fun before => run (entry step ctx owner amounts) before

theorem entry_success (step : Address → Word → Exec Nat)
    (effect : Address → Word → Nat → World → World → List Attempt → Prop)
    (item : ∀ owner amount id before, (step owner amount before).outcome = .ok id →
      effect owner amount id before (step owner amount before).world (step owner amount before).attempts)
    (ctx : Context) (owner : Address) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch step ctx owner amounts before).outcome = .ok ids) :
    Resumed before ∧ Transcript (effect (resolvedOwner ctx owner)) amounts ids before
      (runBatch step ctx owner amounts before).world (runBatch step ctx owner amounts before).attempts := by
  have he : (entry step ctx owner amounts before).outcome = .ok ids := by
    unfold runBatch run at h
    cases hx : (entry step ctx owner amounts before).outcome <;> simp_all
  by_cases hp : before.core.blockTimestamp.val < (before.core.readSlot resumeSlot).val
  · simp only [entry, if_pos hp, fail] at he; contradiction
  · have hl : (loop (step (resolvedOwner ctx owner)) amounts before).outcome = .ok ids := by
      simpa only [entry, if_neg hp] using he
    refine ⟨Nat.le_of_not_gt hp, ?_⟩
    simpa only [runBatch, run, entry, if_neg hp, hl] using
      loop_success _ _ (item (resolvedOwner ctx owner)) amounts ids before hl

theorem batch_failure_restores (step : Address → Word → Exec Nat) (ctx : Context)
    (owner : Address) (amounts : List Word) (before : World) (fault : Fault)
    (h : (runBatch step ctx owner amounts before).outcome = .error fault) :
    (runBatch step ctx owner amounts before).world = before := by
  unfold runBatch run at h ⊢
  cases he : (entry step ctx owner amounts before).outcome <;> simp_all

theorem owner_idempotent (ctx : Context) (owner : Address) :
    resolvedOwner ctx (resolvedOwner ctx owner) = resolvedOwner ctx owner := by
  unfold resolvedOwner
  split
  · split <;> simp_all
  · rfl

/-- stETH checks each amount before CALL; the accepted item captures that item's
entry timestamp. Arbitrary model callee worlds are not given an environment frame. -/
def stETHStep (callee : External) (quote : StaticExternal) (ctx : Context) (stETH : Address)
    (owner : Address) (amount : Word) : Exec Nat :=
  AddressRequestCalls.runRequest callee quote ctx stETH amount.val owner

def wrappedStep (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (owner : Address) (amount : Word) : Exec Nat :=
  AddressWrappedTransferCalls.runRequest conversion tokenTransfer otherCalls quote ctx wstETH stETH amount owner

def stETHEffect (callee : External) (quote : StaticExternal) (ctx : Context) (stETH : Address)
    (owner : Address) (amount : Word) :=
  AddressRequestCalls.RequestEffect callee quote ctx stETH amount.val owner

def wrappedEffect (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (owner : Address) (amount : Word) :=
  AddressWrappedTransferCalls.JoinedEffect conversion tokenTransfer otherCalls quote ctx wstETH stETH amount owner

theorem stETH_batch_success (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH owner : Address) (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).outcome = .ok ids) :
    Resumed before ∧ Transcript (stETHEffect callee quote ctx stETH (resolvedOwner ctx owner))
      amounts ids before (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).world
      (runBatch (stETHStep callee quote ctx stETH) ctx owner amounts before).attempts :=
  entry_success _ _ (fun own amount id w hs =>
    LidoSRv3.Audit.Guarantees.PAddress1.actual_request_withdrawal_enqueue
      callee quote ctx stETH amount.val own id w hs) ctx owner amounts ids before h

theorem wrapped_batch_success (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH owner : Address)
    (amounts : List Word) (ids : List Nat) (before : World)
    (h : (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH)
      ctx owner amounts before).outcome = .ok ids) :
    Resumed before ∧ Transcript (wrappedEffect conversion tokenTransfer otherCalls quote ctx wstETH stETH
      (resolvedOwner ctx owner)) amounts ids before
      (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts before).world
      (runBatch (wrappedStep conversion tokenTransfer otherCalls quote ctx wstETH stETH) ctx owner amounts before).attempts :=
  entry_success _ _ (fun own amount id w hs =>
    LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_transfer_request_enqueue
      conversion tokenTransfer otherCalls quote ctx wstETH stETH amount own id w hs)
    ctx owner amounts ids before h

end LidoSRv3.Audit.Source.AddressRequestBatches
