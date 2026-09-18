import LidoSRv3.Audit.Source.SszCompiledClEntry
import LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry
import LidoSRv3.Audit.Source.SszCompiledReply
import LidoSRv3.Audit.Source.SszProofCalldataLoop
import LidoSRv3.Audit.Source.SszProofFold
import LidoSRv3.Audit.Source.SszCompiledGIndex

/-!
Rollback of the selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul` 43-417).

`PSsz1.actual_compiled_cl_entry_tree` already relates one successful
`SszCompiledClEntry.run` to its root, index, leaf and proof loop. This
file is the complementary error arm: a proof-loop or root-comparison
failure produces no committed `EVM.State`, hence no committed storage
write, event, returned memory or value. Success and that failure share
the definitional prefix `beforeRoot` (IR 43-100) then `rootCall`
(IR 101-114, EIP-4788 STATICCALL) until `afterRoot` diverges
(`decodeRoot` IR 146-166 / `SSZ.verifyProof`).

EIP-4788 authenticity/freshness remain declared premises. Compilation,
crypto, gas and consensus stay outside. Additive: no existing file is
edited.
-/
set_option autoImplicit false
set_option maxRecDepth 4096
namespace LidoSRv3.Audit.Source.SszCompiledEntryRollback

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszCompiledMemory
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

/-- Committed post-state of the compiled entry, if any. An error outcome
has none. -/
def committedState (r : Result) : Option EVM.State :=
  match r.outcome with
  | .ok st => some st
  | .error _ => none

/-- Proof-loop (`SSZ.verifyProof`, after IR 332) or root-comparison
(`decodeRoot`, IR 146-166 / `CLValidatorVerifier.sol:103-107`) failure. -/
def isProofOrRoot : SszCompiledClEntry.Error → Prop
  | .proof _ => True
  | .reply _ => True
  | _ => False

theorem committedState_of_error {e : SszCompiledClEntry.Error} {r : Result}
    (h : r.outcome = .error e) : committedState r = none := by
  simp [committedState, h]

/-- `mstore` of the compiled frame (IR free-pointer / ABI encode) writes
machine memory only. It does not update the account map or the log series. -/
theorem store_preserves_accountMap (st : EVM.State) (offset : Nat) (word : UInt256) :
    (store st offset word).accountMap = st.accountMap := rfl

theorem store_preserves_logSeries (st : EVM.State) (offset : Nat) (word : UInt256) :
    (store st offset word).substate.logSeries = st.substate.logSeries := rfl

/-- `fresh` / `prologue` (`mstore(64,128)`, IR first memory write) keep the
caller's account map and logs. -/
theorem prologue_preserves_accountMap (context : EVM.State) :
    (prologue context).accountMap = context.accountMap := rfl

theorem prologue_preserves_logSeries (context : EVM.State) :
    (prologue context).substate.logSeries = context.substate.logSeries := rfl

private theorem bind_error {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {e : ε}
    (h : (step >>= next) = .error e) :
    step = .error e ∨ ∃ x, step = .ok x ∧ next x = .error e := by
  cases step with
  | error e' =>
    cases h
    exact Or.inl rfl
  | ok x =>
    exact Or.inr ⟨x, rfl, h⟩

private theorem bind_ok {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β}
    (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error _ => cases h
  | ok x => exact ⟨x, rfl, h⟩

private theorem mapError_error {ε ε' α : Type} (f : ε → ε') (step : Except ε α)
    (e : ε') (h : step.mapError f = .error e) : ∃ x, step = .error x ∧ e = f x := by
  cases step with
  | error x =>
    cases h
    exact ⟨x, rfl, rfl⟩
  | ok _ => cases h

/-- `header` (IR 50-53) rejects a nonzero `weiValue` as `.abi`. -/
theorem header_of_nonzero_value (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat ≠ 0) :
    header st = .error (.abi .abi) := by
  fun_cases header st
  all_goals
    first
    | rfl
    | (exact (hv rfl).elim)
    | contradiction

theorem header_ok_is_nonpayable {st : EVM.State} {head : UInt256}
    (h : header st = .ok head) : st.executionEnv.weiValue.toNat = 0 := by
  by_contra hv
  have : header st = .error (.abi .abi) := header_of_nonzero_value st hv
  rw [this] at h
  cases h

/-- `slotSibling` (IR 70-97) is panic 0x11 / 0x32 / `invalidSlot` / success. -/
theorem slotSibling_shape (st : EVM.State) (branch : SszWitnessAbi.Slice)
    (expected : UInt256) :
    slotSibling st branch expected = .error .panic11 ∨
      slotSibling st branch expected = .error .panic32 ∨
        slotSibling st branch expected = .error .invalidSlot ∨
          slotSibling st branch expected = .ok () := by
  unfold slotSibling
  dsimp only
  split
  · exact Or.inl rfl
  · split
    · exact Or.inr (Or.inl rfl)
    · split
      · exact Or.inr (Or.inr (Or.inr rfl))
      · exact Or.inr (Or.inr (Or.inl rfl))

theorem slotSibling_error_not_proof_or_root (st : EVM.State)
    (branch : SszWitnessAbi.Slice) (expected : UInt256) (e : SszCompiledClEntry.Error)
    (h : slotSibling st branch expected = .error e) : ¬ isProofOrRoot e := by
  rcases slotSibling_shape st branch expected with h' | h' | h' | h'
  · rw [h'] at h; cases h; exact id
  · rw [h'] at h; cases h; exact id
  · rw [h'] at h; cases h; exact id
  · rw [h'] at h; cases h

/-- A `header` error is the first `beforeRoot` bind (IR 43-55). -/
theorem beforeRoot_of_header_error (fuel : Nat) (context : EVM.State)
    (e : SszCompiledClEntry.Error)
    (h : header (prologue context) = .error e) :
    beforeRoot fuel context = .error e := by
  unfold beforeRoot
  change (header (prologue context) >>= _) = .error e
  rw [h]
  rfl

/-- After `header` succeeds, `beforeRoot` errors are ABI / BLS / slot-panic,
never proof-loop or root-comparison. -/
theorem beforeRoot_tail_error_not_proof_or_root (fuel : Nat) (context : EVM.State)
    (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e)
    (hhead : ∀ e', header (prologue context) = .error e' → False) :
    ¬ isProofOrRoot e := by
  unfold beforeRoot at h
  rcases bind_error h with h | ⟨_, _, h⟩
  · exact (hhead _ h).elim
  · rcases bind_error h with h | ⟨_, _, h⟩
    · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
      subst he; exact id
    · rcases bind_error h with h | ⟨_, _, h⟩
      · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
        subst he; exact id
      · rcases bind_error h with h | ⟨_, _, h⟩
        · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
          subst he; exact id
        · rcases bind_error h with h | ⟨_, _, h⟩
          · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
            subst he; exact id
          · rcases bind_error h with h | ⟨_, _, h⟩
            · exact slotSibling_error_not_proof_or_root _ _ _ _ h
            · rcases bind_error h with h | ⟨_, _, h⟩
              · rcases mapError_error _ _ _ h with ⟨_, _, he⟩
                subst he; exact id
              · cases h

/-- `rootCall` (IR 101-114) errors only as `.allocation .panic41`. -/
theorem rootCall_shape (external : StaticCall.External) (world : Live.World)
    (st : EVM.State) (ts : UInt256) :
    rootCall external world st ts = .error (.allocation .panic41) ∨
      ∃ st' out, rootCall external world st ts = .ok (st', out) := by
  unfold rootCall
  dsimp only
  split
  · exact Or.inl rfl
  · exact Or.inr ⟨_, _, rfl⟩

theorem rootCall_error_not_proof_or_root (external : StaticCall.External)
    (world : Live.World) (st : EVM.State) (ts : UInt256) (e : SszCompiledClEntry.Error)
    (h : rootCall external world st ts = .error e) :
    ¬ isProofOrRoot e := by
  rcases rootCall_shape external world st ts with ha | ⟨_, _, hok⟩
  · rw [ha] at h; cases h; exact id
  · rw [hok] at h; cases h

/-- A proof-loop or root-comparison failure of `run` is either the
`afterRoot` divergence after the shared prefix (`beforeRoot` IR 43-100,
`rootCall` IR 101-114), or a `header` error. The source `header` only
throws `.abi`; excluding that disjunct needs a do-free rewrite of
`SszCompiledClEntry.header` (see README). The error outcome commits no
`EVM.State` in both disjuncts. -/
theorem proof_or_root_failure_after_prefix
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : (run fuel cfg external world context).outcome = .error e)
    (he : isProofOrRoot e) :
    (∃ b : Before, ∃ st : EVM.State, ∃ out : RootOutcome,
      beforeRoot fuel context = .ok b ∧
        rootCall external world b.state b.timestamp = .ok (st, out) ∧
        afterRoot fuel cfg st b.head out.success b.index = .error e ∧
        (run fuel cfg external world context).attempts = out.attempts ∧
        committedState (run fuel cfg external world context) = none ∧
        b.state.executionEnv = context.executionEnv) ∨
      header (prologue context) = .error e := by
  have hrun : (run fuel cfg external world context).outcome = .error e := h
  unfold run at h
  cases hb : beforeRoot fuel context with
  | error e' =>
    have hbr0 := hb
    simp only [hb] at h
    cases h
    unfold beforeRoot at hbr0
    rcases bind_error hbr0 with hh | ⟨_, _, hrest⟩
    · exact Or.inr hh
    · have htail : ¬ isProofOrRoot e := by
        rcases bind_error hrest with h | ⟨_, _, h⟩
        · rcases mapError_error _ _ _ h with ⟨_, _, heq⟩
          subst heq; exact id
        · rcases bind_error h with h | ⟨_, _, h⟩
          · rcases mapError_error _ _ _ h with ⟨_, _, heq⟩
            subst heq; exact id
          · rcases bind_error h with h | ⟨_, _, h⟩
            · rcases mapError_error _ _ _ h with ⟨_, _, heq⟩
              subst heq; exact id
            · rcases bind_error h with h | ⟨_, _, h⟩
              · rcases mapError_error _ _ _ h with ⟨_, _, heq⟩
                subst heq; exact id
              · rcases bind_error h with h | ⟨_, _, h⟩
                · exact slotSibling_error_not_proof_or_root _ _ _ _ h
                · rcases bind_error h with h | ⟨_, _, h⟩
                  · rcases mapError_error _ _ _ h with ⟨_, _, heq⟩
                    subst heq; exact id
                  · cases h
      exact (htail he).elim
  | ok b =>
    simp only [hb] at h
    cases hr : rootCall external world b.state b.timestamp with
    | error e' =>
      simp only [hr] at h
      cases h
      exact (rootCall_error_not_proof_or_root external world b.state b.timestamp e hr he).elim
    | ok pr =>
      rcases pr with ⟨st, out⟩
      simp only [hr] at h
      have hatt : (run fuel cfg external world context).attempts = out.attempts := by
        simp only [run, hb, hr]
      have hafter : afterRoot fuel cfg st b.head out.success b.index = .error e := h
      obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, henv, _, _, _⟩ :=
        beforeRoot_success fuel context b hb
      exact Or.inl ⟨b, st, out, rfl, hr, hafter, hatt, committedState_of_error hrun, henv⟩

/-- Same `run` cannot be both the success arm of
`actual_compiled_cl_entry_tree` and a proof/root failure. The two arms
are the same prefix through `rootCall`, then `afterRoot` decides. -/
theorem tree_success_excludes_proof_or_root_failure
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context afterState : EVM.State)
    (e : SszCompiledClEntry.Error)
    (hs : (run fuel cfg external world context).outcome = .ok afterState)
    (hf : (run fuel cfg external world context).outcome = .error e)
    (_he : isProofOrRoot e) : False := by
  cases hs.symm.trans hf

/-- On a proof/root failure the entry was nonpayable
(`header` IR 50-53 / `weiValue = 0`). No value is committed. -/
theorem proof_or_root_failure_is_nonpayable
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : (run fuel cfg external world context).outcome = .error e)
    (he : isProofOrRoot e) :
    context.executionEnv.weiValue.toNat = 0 := by
  by_contra hv
  have henv : (prologue context).executionEnv = context.executionEnv :=
    prologue_environment context
  have hh : header (prologue context) = .error (.abi .abi) :=
    header_of_nonzero_value (prologue context) (by rw [henv]; exact hv)
  have hbr : beforeRoot fuel context = .error (.abi .abi) :=
    beforeRoot_of_header_error fuel context _ hh
  have habi : (run fuel cfg external world context).outcome = .error (.abi .abi) := by
    simp [run, hbr]
  rw [h] at habi
  cases habi
  exact he

/-- Failed STATICCALL is exactly `rootNotFound`
(`CLValidatorVerifier.sol:103-107`, IR 146-148). -/
theorem failed_staticcall_is_rootNotFound (st : EVM.State) (data : UInt256) :
    SszCompiledReply.decodeRoot st false data =
      .error SszCompiledReply.Error.rootNotFound := rfl

/-- `afterRoot` cannot succeed once the STATICCALL flag is false: `copyReply`
may still allocate, but `decodeRoot` (IR 146-148) reverts `.rootNotFound`. -/
theorem afterRoot_of_failed_staticcall
    (fuel : Nat) (cfg : Configuration) (st : EVM.State) (head n : UInt256)
    (afterState : EVM.State)
    (h : afterRoot fuel cfg st head false n = .ok afterState) : False := by
  unfold afterRoot at h
  rcases bind_ok h with ⟨p, hcopy, hrest⟩
  rcases p with ⟨data, st'⟩
  have hdec : ((SszCompiledReply.decodeRoot st' false data).mapError
      SszCompiledClEntry.Error.reply) = .error (.reply .rootNotFound) := by
    simp [failed_staticcall_is_rootNotFound, Except.mapError]
  rcases bind_ok hrest with ⟨_, hroot, _⟩
  rw [hdec] at hroot
  cases hroot

/-- Empty proof list is `invalidProof` (`SSZ.verifyProof` count guard). -/
theorem empty_proof_is_invalidProof (fuel : Nat) (st : EVM.State)
    (rawIndex leaf root offset : UInt256) :
    SszProofCalldataLoop.verify fuel st rawIndex leaf root offset 0 =
      .error .invalidProof := by
  simp [SszProofCalldataLoop.verify]

/-- An extra sibling cannot authenticate the same index: `Branch` depth is
`index.log2` (`SszProofFold.branch_depth`). -/
theorem extra_sibling_refutes_branch {α : Type} {hash : SszProofFold.Hash α}
    {index : Nat} {leaf sib root : α} {proof : List α}
    (h1 : SszProofFold.Branch hash index leaf proof root)
    (h2 : SszProofFold.Branch hash index leaf (sib :: proof) root) : False := by
  have d1 := SszProofFold.branch_depth h1
  have d2 := SszProofFold.branch_depth h2
  exact Nat.ne_of_lt (Nat.lt_succ_self proof.length) (d1.symm.trans d2)

#print axioms committedState_of_error
#print axioms store_preserves_accountMap
#print axioms store_preserves_logSeries
#print axioms prologue_preserves_accountMap
#print axioms prologue_preserves_logSeries
#print axioms header_of_nonzero_value
#print axioms header_ok_is_nonpayable
#print axioms slotSibling_shape
#print axioms slotSibling_error_not_proof_or_root
#print axioms beforeRoot_of_header_error
#print axioms beforeRoot_tail_error_not_proof_or_root
#print axioms rootCall_shape
#print axioms rootCall_error_not_proof_or_root
#print axioms proof_or_root_failure_after_prefix
#print axioms tree_success_excludes_proof_or_root_failure
#print axioms proof_or_root_failure_is_nonpayable
#print axioms failed_staticcall_is_rootNotFound
#print axioms afterRoot_of_failed_staticcall
#print axioms empty_proof_is_invalidProof
#print axioms extra_sibling_refutes_branch

end LidoSRv3.Audit.Source.SszCompiledEntryRollback
