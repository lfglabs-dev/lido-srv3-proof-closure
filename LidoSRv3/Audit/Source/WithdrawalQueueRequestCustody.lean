import LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl
import LidoSRv3.Audit.Source.AddressTransferCorrespondence

/-!
# P-TOKEN-1 bounded request-ownership custody composition

This module composes the two pinned-source slices that already exist for the
withdrawal-request surface at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* the creation prefix `WithdrawalQueue.requestWithdrawals` lines 125--135
  (owner fallback at line 130, two-sided amount check at lines 395--402), and
* the owner-operated custody transition
  `WithdrawalQueueERC721.transferFrom`/`_transfer` lines 218--253.

The composed parent is a multi-step reachability statement, not the
conjunction of the two slices: for **any** number of subsequent custody hops
it fixes the created owner, keeps the two-sided amount bound, and shows that
every hop that executed was owner-operated to a fresh nonzero recipient, so
the request never becomes ownerless.

The unmodeled owner binding performed by `_enqueue` and `_emitTransfer`
(lines 378 and 380) is an explicit universally quantified `mint` argument with
a single named hypothesis `∀ o, (mint o).owner = o`.  It is a caller
obligation, not a smuggled assumption: `(mint o).approved` is deliberately
left unconstrained, and no ERC-20 movement, share conversion, queue storage,
finalization, or claim path is represented anywhere below.
-/

namespace LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount
  (minStethWithdrawalAmount maxStethWithdrawalAmount)
open LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl
  (Outcome resolvedOwner requestWithdrawalsSingleControl)
open LidoSRv3.Audit.Source.AddressTransferCorrespondence (State sourceTransfer)

/-- Addresses are unbounded `Nat` here: the 160-bit Solidity address domain is
not enforced, so a hop may name a recipient (for example `2^160`) that no
Solidity address can, and `final.owner ≠ 0` below is stated on that wider
domain. `audit/guarantees.yaml` records this as an open fidelity gap. -/
abbrev Address := Nat

/-- One later custody hop, i.e. one `transferFrom` call at line 218. -/
structure Step where
  caller : Address
  fromAddr : Address
  to : Address
  deriving Repr, DecidableEq

/-- Sequential composition of custody hops.  A reverting hop aborts the whole
chain, which is the only transaction-level effect this bounded slice models. -/
def applySteps (transfer : Address → Address → Address → State → Option State) :
    State → List Step → Option State
  | s, [] => some s
  | s, step :: rest =>
      match transfer step.caller step.fromAddr step.to s with
      | none => none
      | some s' => applySteps transfer s' rest

/-- **The P-TOKEN-1 parent predicate.**  Universal over the unmodeled minting
function, the request inputs, and an arbitrary chain of later custody hops. -/
def RequestOwnerCustodyInvariant
    (create : Address → Address → Nat → Outcome)
    (transfer : Address → Address → Address → State → Option State) : Prop :=
  ∀ mint : Address → State, (∀ o, (mint o).owner = o) →
    ∀ caller suppliedOwner amount owner steps final,
      caller ≠ 0 →
      create caller suppliedOwner amount = .proceeds owner →
      applySteps transfer (mint owner) steps = some final →
        minStethWithdrawalAmount ≤ amount ∧
        amount ≤ maxStethWithdrawalAmount ∧
        owner = resolvedOwner caller suppliedOwner ∧
        final.owner ≠ 0 ∧
        ∀ step ∈ steps,
          step.caller = step.fromAddr ∧ step.to ≠ 0 ∧ step.to ≠ step.fromAddr

/-- Inversion of the pinned owner-operated branch: a hop that returned a state
passed the four modeled guards -- the zero-recipient check at line 231, the
self-transfer check at line 232, the owner check at line 238, and the
owner-operated caller authorization at lines 241--245 -- and wrote line 248's
new owner. The request-validity and claimed checks at lines 233 and 236 are
outside this slice (`audit/P-TOKEN-1-T2-SCOPE.md`), so nothing here says they
passed. -/
theorem sourceTransfer_some
    (caller fromAddr to : Address) (s s' : State)
    (h : sourceTransfer caller fromAddr to s = some s') :
    to ≠ 0 ∧ to ≠ fromAddr ∧ s.owner = fromAddr ∧ caller = fromAddr ∧
      s' = { owner := to, approved := 0 } := by
  by_cases h1 : to = 0
  · simp [sourceTransfer, h1] at h
  by_cases h2 : to = fromAddr
  · simp [sourceTransfer, h2] at h
  by_cases h3 : s.owner = fromAddr
  · by_cases h4 : caller = fromAddr
    · simp [sourceTransfer, h1, h2, h3, h4] at h
      exact ⟨h1, h2, h3, h4, h.symm⟩
    · simp [sourceTransfer, h1, h2, h3, h4] at h
  · simp [sourceTransfer, h1, h2, h3] at h

/-- Custody preservation over an arbitrary hop chain: ownership never reaches
the zero address and every executed hop was operated by the current owner. -/
theorem custody_chain_preserved :
    ∀ (steps : List Step) (s final : State), s.owner ≠ 0 →
      applySteps sourceTransfer s steps = some final →
        final.owner ≠ 0 ∧ ∀ step ∈ steps,
          step.caller = step.fromAddr ∧ step.to ≠ 0 ∧ step.to ≠ step.fromAddr
  | [], s, final, hOwner, h => by
      simp only [applySteps, Option.some.injEq] at h
      exact ⟨h ▸ hOwner, by simp⟩
  | step :: rest, s, final, hOwner, h => by
      simp only [applySteps] at h
      cases hStep : sourceTransfer step.caller step.fromAddr step.to s with
      | none => rw [hStep] at h; exact absurd h (by simp)
      | some s' =>
          rw [hStep] at h
          obtain ⟨hTo, hSelf, _, hCaller, hState⟩ :=
            sourceTransfer_some step.caller step.fromAddr step.to s s' hStep
          have hOwner' : s'.owner ≠ 0 := by rw [hState]; exact hTo
          obtain ⟨hFinal, hRest⟩ := custody_chain_preserved rest s' final hOwner' h
          refine ⟨hFinal, ?_⟩
          intro other hOther
          rcases List.mem_cons.mp hOther with hEq | hIn
          · exact hEq ▸ ⟨hCaller, hTo, hSelf⟩
          · exact hRest other hIn

/-- The created owner is never the zero address: the line-130 fallback selects
a nonzero caller, and an explicitly supplied owner is nonzero by definition of
that fallback. -/
theorem resolvedOwner_ne_zero (caller suppliedOwner : Address) (h : caller ≠ 0) :
    resolvedOwner caller suppliedOwner ≠ 0 := by
  unfold resolvedOwner
  split
  · exact h
  · assumption

end LidoSRv3.Audit.Source.WithdrawalQueueRequestCustody
