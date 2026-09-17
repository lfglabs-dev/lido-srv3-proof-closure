import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! # A-NO-REENTRY: external callees that do not re-enter the protected contracts

**Assumption A-NO-REENTRY (Thomas 2026-09-17, step 1b of the "not proven"
cleanup):** module `obtainDepositData` bodies, the beacon deposit contract, the
EIP-7251 predeploy, the WithdrawalQueue finalization callback and the
configured refund recipient do not call back into Lido, the router or the
gateway.

The `Live` model executes every high-level CALL through an explicit
interpreter `External := Request → World → Reply` that may return any world.
`NoReentry external self` names the assumption on that interpreter for a
protected address list `self`:

- a call whose target is a protected address is rejected;
- an accepted reply hands back a world that agrees with the received world on
  every protected address (all storage words and the balance), and none of
  its recorded nested attempts into a protected address was accepted.

The lemmas below are the generic consequences for `Live.call`: a protected
contract's storage is unchanged by any CALL, its balance is the provisional
transfer's balance on success and the incoming balance on failure, and a CALL
into a protected contract never succeeds.

**Status:** `NoReentry` is an accepted registry assumption
(`audit/assumptions.yaml`, `A-NO-REENTRY`), not a theorem about the deployed
callee bodies. `audit/topup-call-history/README.md` argues that a `noReentry`
premise alone does not close the TOPUP-2 per-block cap; the owner overrides
that reading for the five ledger rows named in the registry, where the premise
constrains only the callee interpreter of already exact-returned-world
theorems. -/

namespace LidoSRv3.Audit.Source.NoReentry

open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Two worlds agree on one protected account: every storage word and the
balance. -/
abbrev AgreesOn (a : Address) (w w' : World) : Prop :=
  (∀ slot, w'.core.readContractSlot a.val slot = w.core.readContractSlot a.val slot) ∧
    w'.balances a = w.balances a

/-- Agreement on every protected account. -/
abbrev Agrees (self : List Address) (w w' : World) : Prop :=
  ∀ a ∈ self, AgreesOn a w w'

/-- A rejected reply. -/
def Rejected : Reply → Prop
  | .rejected _ => True
  | .rejectedWithTrace _ _ => True
  | .success _ _ => False
  | .successWithTrace _ _ _ => False

/-- No recorded nested attempt into a protected address was accepted. -/
abbrev NestedRejects (self : List Address) (nested : List NestedAttempt) : Prop :=
  ∀ n ∈ nested, n.request.target ∈ self → n.accepted = false

/-- What a reply from a non-re-entering callee guarantees about the world it
hands back, relative to the world `w` it received. -/
def Returns (self : List Address) (w : World) : Reply → Prop
  | .success _ after => Agrees self w after
  | .successWithTrace _ after nested => Agrees self w after ∧ NestedRejects self nested
  | .rejected _ => True
  | .rejectedWithTrace _ nested => NestedRejects self nested

/-- A-NO-REENTRY on an external interpreter: calls targeting a protected
address are rejected, and every reply returns a world agreeing with the
received world on the protected addresses without accepted nested calls into
them. -/
def NoReentry (external : External) (self : List Address) : Prop :=
  ∀ (req : Request) (w : World),
    (req.target ∈ self → Rejected (external req w)) ∧ Returns self w (external req w)

theorem agrees_refl (self : List Address) (w : World) : Agrees self w w :=
  fun _ _ => ⟨fun _ => rfl, rfl⟩

/-- A successful reply returns a world agreeing on the protected accounts. -/
theorem returns_success {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes} {after : World}
    (hc : external req w = .success data after) : Agrees self w after := by
  have hr := (h req w).2
  rw [hc] at hr
  exact hr

/-- A successful traced reply returns a world agreeing on the protected
accounts and records no accepted nested call into them. -/
theorem returns_successWithTrace {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes} {after : World}
    {nested : List NestedAttempt}
    (hc : external req w = .successWithTrace data after nested) :
    Agrees self w after ∧ NestedRejects self nested := by
  have hr := (h req w).2
  rw [hc] at hr
  exact hr

/-- A rejected traced reply records no accepted nested call into the protected
accounts. -/
theorem returns_rejectedWithTrace {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes}
    {nested : List NestedAttempt}
    (hc : external req w = .rejectedWithTrace data nested) : NestedRejects self nested := by
  have hr := (h req w).2
  rw [hc] at hr
  exact hr

/-- The provisional CALL transfer changes balances only. -/
theorem transfer_core (w : World) (sender recipient : Address) (value : Nat) :
    (transfer w sender recipient value).core = w.core := rfl

/-- A protected contract's storage is unchanged by any high-level CALL. -/
theorem call_storage {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (a : Address) (ha : a ∈ self) (slot : Nat) :
    (call external ctx target selector value w).world.core.readContractSlot a.val slot =
      w.core.readContractSlot a.val slot := by
  simp only [call]
  split
  · rfl
  · split
    · rfl
    · have hr := (h ⟨ctx.self, target, value, encode 4 selector⟩
        (transfer w ctx.self target value.val)).2
      revert hr
      cases external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) with
      | rejected data => intro _; rfl
      | rejectedWithTrace data nested => intro _; rfl
      | success data after => intro hr; exact ((hr a ha).1 slot).trans rfl
      | successWithTrace data after nested => intro hr; exact ((hr.1 a ha).1 slot).trans rfl

/-- A protected contract's balance after a high-level CALL is the incoming
balance on failure and the provisional transfer's balance on success. -/
theorem call_balance {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (a : Address) (ha : a ∈ self) :
    (call external ctx target selector value w).world.balances a = w.balances a ∨
      ((∃ data, (call external ctx target selector value w).outcome = .ok data) ∧
        (call external ctx target selector value w).world.balances a =
          (transfer w ctx.self target value.val).balances a) := by
  simp only [call]
  split
  · exact Or.inl rfl
  · split
    · exact Or.inl rfl
    · have hr := (h ⟨ctx.self, target, value, encode 4 selector⟩
        (transfer w ctx.self target value.val)).2
      revert hr
      cases external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) with
      | rejected data => intro _; exact Or.inl rfl
      | rejectedWithTrace data nested => intro _; exact Or.inl rfl
      | success data after => intro hr; exact Or.inr ⟨⟨data, rfl⟩, (hr a ha).2⟩
      | successWithTrace data after nested => intro hr; exact Or.inr ⟨⟨data, rfl⟩, (hr.1 a ha).2⟩

/-- A high-level CALL into a protected contract never succeeds. -/
theorem call_self_rejected {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (ht : target ∈ self) (data : Bytes) :
    (call external ctx target selector value w).outcome ≠ .ok data := by
  simp only [call]
  split
  · intro hc; cases hc
  · split
    · intro hc; cases hc
    · have hrej := (h ⟨ctx.self, target, value, encode 4 selector⟩
        (transfer w ctx.self target value.val)).1 ht
      revert hrej
      cases external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) with
      | rejected d => intro _ hc; cases hc
      | rejectedWithTrace d nested => intro _ hc; cases hc
      | success d after => intro hf; exact False.elim hf
      | successWithTrace d after nested => intro hf; exact False.elim hf

/-- Every recorded nested attempt of a high-level CALL into a protected
contract was rejected. -/
theorem call_nested_rejects {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) :
    ∀ attempt ∈ (call external ctx target selector value w).attempts,
      NestedRejects self attempt.nested := by
  simp only [call]
  split
  · intro attempt hmem; cases hmem
  · split
    · intro attempt hmem
      rw [List.mem_singleton] at hmem
      subst hmem
      intro n hn; cases hn
    · have hr := (h ⟨ctx.self, target, value, encode 4 selector⟩
        (transfer w ctx.self target value.val)).2
      revert hr
      cases external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) with
      | rejected d =>
        intro _ attempt hmem
        rw [List.mem_singleton] at hmem
        subst hmem
        intro n hn; cases hn
      | rejectedWithTrace d nested =>
        intro hr attempt hmem
        rw [List.mem_singleton] at hmem
        subst hmem
        exact hr
      | success d after =>
        intro _ attempt hmem
        rw [List.mem_singleton] at hmem
        subst hmem
        intro n hn; cases hn
      | successWithTrace d after nested =>
        intro hr attempt hmem
        rw [List.mem_singleton] at hmem
        subst hmem
        exact hr.2

/-- The three generic consequences of A-NO-REENTRY for every high-level CALL
issued to a residual interpreter `other`: protected storage is unchanged, a
CALL into a protected contract never succeeds, and no recorded nested attempt
into a protected contract was accepted. -/
def Confined (other : External) (self : List Address) : Prop :=
  ∀ (c : Context) (target : Address) (selector : Nat) (value : Word) (w : World),
    (∀ a ∈ self, ∀ slot,
      (call other c target selector value w).world.core.readContractSlot a.val slot =
        w.core.readContractSlot a.val slot) ∧
    (target ∈ self → ∀ data, (call other c target selector value w).outcome ≠ .ok data) ∧
    (∀ attempt ∈ (call other c target selector value w).attempts,
      NestedRejects self attempt.nested)

theorem confined_of_noReentry {other : External} {self : List Address}
    (h : NoReentry other self) : Confined other self :=
  fun c target selector value w =>
    ⟨fun a ha slot => call_storage h c target selector value w a ha slot,
     fun ht data => call_self_rejected h c target selector value w ht data,
     call_nested_rejects h c target selector value w⟩

end LidoSRv3.Audit.Source.NoReentry
