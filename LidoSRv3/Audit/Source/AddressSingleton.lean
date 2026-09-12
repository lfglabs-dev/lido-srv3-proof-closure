import LidoSRv3.Audit.Source.AddressCorrespondence
import Verity.Core.Address

/-!
# P-ADDRESS-1 live singleton-actor exclusion

The registered parent sets `singletonActorEntryPoint := False` for every
modeled tag (`AddressCorrespondence.lean:110-111`).  That is exclusion by
omission.  This module does **not** edit that predicate.  It states a live
exclusion: a tag requires a protocol singleton only if some **fixed** address
is the caller of every admitted run, independently of request-indexed
fields.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `WithdrawalQueue.sol:125-136` `requestWithdrawals` — `public`,
  `_checkResumed()` only; no `onlyRole` / `onlyOwner`
* `WithdrawalQueue.sol:244-256` `claimWithdrawalsTo` — request-owner gate
  via `_claim` (`WithdrawalQueueBase.sol:467` `request.owner != msg.sender`),
  not a protocol admin
* `WithdrawalQueueERC721.sol:218-220` / `241-245` `transferFrom` —
  `NotOwnerOrApproved`; caller-relative owner or approval
* `WstETH.sol:69-75` `unwrap` — nonzero amount and caller balance; no
  `onlyOwner`

Unmodeled singleton-actor surfaces (`WithdrawalQueue.sol:97` `RESUME_ROLE`,
`322` `ORACLE_ROLE`, and the vault/gateway helpers named in `PAddress1`)
are outside the four modeled tags and outside this entry.
-/

namespace LidoSRv3.Audit.Source.AddressSingleton

open Verity
open LidoSRv3.Audit.SolidityAddress

abbrev Address := Verity.Address

/-- A protocol singleton: some fixed `owner` is required on every admitted
call of this tag.  Request-relative owners (`caller = requestOwner`) do not
satisfy this: they move with the request. -/
def requiresFixedActor (ep : EntryPoint) : Prop :=
  ∃ owner : Address, ∀ inp : Input,
    inp.entryPoint = ep → admitted inp = true → inp.caller = owner

/-- Same predicate over an arbitrary admission function, so the fixed-owner
mutant is checked against the identical statement. -/
def requiresFixedActorOf (adm : Input → Bool) (ep : EntryPoint) : Prop :=
  ∃ owner : Address, ∀ inp : Input,
    inp.entryPoint = ep → adm inp = true → inp.caller = owner

theorem requiresFixedActor_iff (ep : EntryPoint) :
    requiresFixedActor ep ↔ requiresFixedActorOf admitted ep :=
  Iff.rfl

/-- Eligible single-item witness: recipient `3` is a nonzero third party,
`requestOwner` / `senderFrom` travel with the caller so the
request-relative gates rename, and pause/balance/allowance flags are open. -/
def eligible (ep : EntryPoint) (caller : Address) : Input where
  entryPoint := ep
  caller := caller
  senderFrom := caller
  recipient := 3
  requestOwner := caller
  amount := 1
  requestId := 1
  paused := false
  requestExists := true
  requestClaimed := false
  requestFinalized := true
  hintValid := true
  callerIsApprovedForAll := false
  callerIsTokenApproved := false
  amountInRange := true
  callerBalanceSufficient := true
  callerAllowanceSufficient := true
  externalCallSucceeds := true

theorem eligible_entryPoint (ep : EntryPoint) (caller : Address) :
    (eligible ep caller).entryPoint = ep := rfl

theorem eligible_caller (ep : EntryPoint) (caller : Address) :
    (eligible ep caller).caller = caller := rfl

/-- WithdrawalQueue.sol:125-136: `requestWithdrawals` admits any caller
once resumed with in-range amount, balance, and allowance. -/
theorem requestWithdrawals_admitted (caller : Address) :
    admitted (eligible .requestWithdrawals caller) = true := by
  simp [admitted, eligible]

/-- WstETH.sol:69-75: `unwrap` admits any caller with a nonzero amount and
sufficient balance. -/
theorem unwrap_admitted (caller : Address) :
    admitted (eligible .unwrap caller) = true := by
  simp [admitted, eligible]

/-- WithdrawalQueue.sol:244-256 / WithdrawalQueueBase.sol:467: the claim
gate is `msg.sender = request.owner`, not a fixed admin.  Distinct request
owners therefore admit distinct callers. -/
theorem claimWithdrawalsTo_admitted (caller : Address) :
    admitted (eligible .claimWithdrawalsTo caller) = true := by
  have hrec : (3 : Address) ≠ 0 := by decide
  simp [admitted, eligible, hrec]

/-- WithdrawalQueueERC721.sol:241-245: owner-operated `transferFrom`
(`caller = requestOwner = senderFrom`) admits any such caller as long as
the recipient is a distinct nonzero address. -/
theorem transferFrom_admitted
    (caller : Address) (hCaller : caller ≠ 3) :
    admitted (eligible .transferFrom caller) = true := by
  have hrec : (3 : Address) ≠ 0 := by decide
  simp [admitted, eligible, hrec, Ne.symm hCaller]

theorem two_callers_admitted (ep : EntryPoint) :
    admitted (eligible ep 1) = true ∧ admitted (eligible ep 2) = true := by
  cases ep with
  | requestWithdrawals =>
    exact ⟨requestWithdrawals_admitted 1, requestWithdrawals_admitted 2⟩
  | unwrap =>
    exact ⟨unwrap_admitted 1, unwrap_admitted 2⟩
  | claimWithdrawalsTo =>
    exact ⟨claimWithdrawalsTo_admitted 1, claimWithdrawalsTo_admitted 2⟩
  | transferFrom =>
    exact ⟨transferFrom_admitted 1 (by decide),
      transferFrom_admitted 2 (by decide)⟩

/-- Live exclusion for every modeled tag: no fixed owner/admin is required.
This is the content `singletonActorEntryPoint := False` omitted. -/
theorem no_fixed_actor (ep : EntryPoint) : ¬ requiresFixedActor ep := by
  intro ⟨owner, howner⟩
  have ⟨h1, h2⟩ := two_callers_admitted ep
  have c1 : (1 : Address) = owner := by
    simpa [eligible_caller] using howner (eligible ep 1) rfl h1
  have c2 : (2 : Address) = owner := by
    simpa [eligible_caller] using howner (eligible ep 2) rfl h2
  exact absurd (c1.trans c2.symm) (by decide)

theorem no_fixed_actor_of_admitted (ep : EntryPoint) :
    ¬ requiresFixedActorOf admitted ep :=
  no_fixed_actor ep

/-- Kill-line: adding `caller = 7` to admission makes
`requestWithdrawals` a singleton-actor tag.  The live predicate is therefore
not another `False`. -/
def admittedFixedOwner (inp : Input) : Bool :=
  admitted inp && decide (inp.caller = 7)

theorem fixed_owner_mutant_requires_actor :
    requiresFixedActorOf admittedFixedOwner .requestWithdrawals :=
  ⟨7, fun inp _ hadm => by
    simp [admittedFixedOwner, Bool.and_eq_true, decide_eq_true_eq] at hadm
    exact hadm.2⟩

/-- The parent omission predicate is still definitional `False`; this lot
does not treat that as the exclusion proof. -/
theorem parent_omission_is_definitional (ep : EntryPoint) :
    singletonActorEntryPoint ep = False := rfl

#print axioms requiresFixedActor_iff
#print axioms requestWithdrawals_admitted
#print axioms unwrap_admitted
#print axioms claimWithdrawalsTo_admitted
#print axioms transferFrom_admitted
#print axioms two_callers_admitted
#print axioms no_fixed_actor
#print axioms no_fixed_actor_of_admitted
#print axioms fixed_owner_mutant_requires_actor
#print axioms parent_omission_is_definitional

end LidoSRv3.Audit.Source.AddressSingleton
