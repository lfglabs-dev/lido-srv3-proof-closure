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
  (∀ k : Nat, w'.core.readContractSlot a.val k = w.core.readContractSlot a.val k) ∧
    w'.balances a = w.balances a

/-- Agreement on every protected account. -/
abbrev Agrees (self : List Address) (w w' : World) : Prop :=
  ∀ a ∈ self, AgreesOn a w w'

/-- A rejected reply: neither accepted constructor. -/
abbrev Rejected (r : Reply) : Prop :=
  (∀ (d : Bytes) (after : World), r ≠ .success d after) ∧
    (∀ (d : Bytes) (after : World) (nested : List NestedAttempt),
      r ≠ .successWithTrace d after nested)

/-- No recorded nested attempt into a protected address was accepted. -/
abbrev NestedRejects (self : List Address) (nested : List NestedAttempt) : Prop :=
  ∀ n ∈ nested, n.request.target ∈ self → n.accepted = false

/-- What a reply from a non-re-entering callee guarantees about the world it
hands back, relative to the world `w` it received: an accepted reply agrees
with `w` on the protected accounts, and a traced reply records no accepted
nested call into them. -/
abbrev Returns (self : List Address) (w : World) (r : Reply) : Prop :=
  (∀ (d : Bytes) (after : World), r = .success d after → Agrees self w after) ∧
    (∀ (d : Bytes) (after : World) (nested : List NestedAttempt),
      r = .successWithTrace d after nested → Agrees self w after ∧ NestedRejects self nested) ∧
    (∀ (d : Bytes) (nested : List NestedAttempt),
      r = .rejectedWithTrace d nested → NestedRejects self nested)

/-- A-NO-REENTRY on an external interpreter: calls targeting a protected
address are rejected, and every reply returns a world agreeing with the
received world on the protected addresses without accepted nested calls into
them. -/
def NoReentry (external : External) (self : List Address) : Prop :=
  ∀ (req : Request) (w : World),
    (req.target ∈ self → Rejected (external req w)) ∧ Returns self w (external req w)

theorem agrees_refl (self : List Address) (w : World) : Agrees self w w :=
  fun _ _ => ⟨fun _ => rfl, rfl⟩

theorem nestedRejects_nil (self : List Address) : NestedRejects self [] := by
  intro n hn
  first | exact nomatch hn | cases hn | simp at hn

/-- A successful reply returns a world agreeing on the protected accounts. -/
theorem returns_success {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes} {after : World}
    (hc : external req w = .success data after) : Agrees self w after :=
  (h req w).2.1 data after hc

/-- A successful traced reply returns a world agreeing on the protected
accounts and records no accepted nested call into them. -/
theorem returns_successWithTrace {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes} {after : World}
    {nested : List NestedAttempt}
    (hc : external req w = .successWithTrace data after nested) :
    Agrees self w after ∧ NestedRejects self nested :=
  (h req w).2.2.1 data after nested hc

/-- A rejected traced reply records no accepted nested call into the protected
accounts. -/
theorem returns_rejectedWithTrace {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} {data : Bytes}
    {nested : List NestedAttempt}
    (hc : external req w = .rejectedWithTrace data nested) : NestedRejects self nested :=
  (h req w).2.2.2 data nested hc

/-- A call into a protected address is never accepted (untraced). -/
theorem self_not_success {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} (ht : req.target ∈ self)
    {data : Bytes} {after : World} (hc : external req w = .success data after) : False :=
  ((h req w).1 ht).1 data after hc

/-- A call into a protected address is never accepted (traced). -/
theorem self_not_successWithTrace {external : External} {self : List Address}
    (h : NoReentry external self) {req : Request} {w : World} (ht : req.target ∈ self)
    {data : Bytes} {after : World} {nested : List NestedAttempt}
    (hc : external req w = .successWithTrace data after nested) : False :=
  ((h req w).1 ht).2 data after nested hc

/-- The provisional CALL transfer changes balances only. -/
theorem transfer_core (w : World) (sender recipient : Address) (value : Nat) :
    (transfer w sender recipient value).core = w.core := rfl

/-- The provisional CALL transfer leaves every storage word unchanged. -/
theorem transfer_slot (w : World) (sender recipient : Address) (value : Nat)
    (account k : Nat) :
    (transfer w sender recipient value).core.readContractSlot account k =
      w.core.readContractSlot account k := rfl

/-- Exhaustive branch shape of the high-level CALL: code check, balance check,
then the four callee replies on the provisionally transferred world. -/
theorem call_shape (external : External) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) :
    ((w.core.codeSize target.val).val = 0 ∧
      call external ctx target selector value w = ⟨.error .empty, w, []⟩) ∨
    ((w.core.codeSize target.val).val ≠ 0 ∧ w.balances ctx.self < value.val ∧
      call external ctx target selector value w =
        ⟨.error (.bubbled []), w, [⟨⟨ctx.self, target, value, encode 4 selector⟩, false, [], []⟩]⟩) ∨
    ((w.core.codeSize target.val).val ≠ 0 ∧ value.val ≤ w.balances ctx.self ∧
      ((∃ data, external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) = .rejected data ∧
        call external ctx target selector value w =
          ⟨.error (.bubbled data), w,
            [⟨⟨ctx.self, target, value, encode 4 selector⟩, false, data, []⟩]⟩) ∨
      (∃ data nested, external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) = .rejectedWithTrace data nested ∧
        call external ctx target selector value w =
          ⟨.error (.bubbled data), w,
            [⟨⟨ctx.self, target, value, encode 4 selector⟩, false, data, nested⟩]⟩) ∨
      (∃ data after, external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) = .success data after ∧
        call external ctx target selector value w =
          ⟨.ok data, after, [⟨⟨ctx.self, target, value, encode 4 selector⟩, true, data, []⟩]⟩) ∨
      (∃ data after nested, external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) = .successWithTrace data after nested ∧
        call external ctx target selector value w =
          ⟨.ok data, after,
            [⟨⟨ctx.self, target, value, encode 4 selector⟩, true, data, nested⟩]⟩))) := by
  unfold call
  by_cases hc : (w.core.codeSize target.val).val = 0
  · exact Or.inl ⟨hc, by simp [hc]⟩
  · by_cases hb : w.balances ctx.self < value.val
    · exact Or.inr (Or.inl ⟨hc, hb, by simp [hc, hb]⟩)
    · have hf : value.val ≤ w.balances ctx.self := Nat.not_lt.mp hb
      refine Or.inr (Or.inr ⟨hc, hf, ?_⟩)
      cases hr : external ⟨ctx.self, target, value, encode 4 selector⟩
          (transfer w ctx.self target value.val) with
      | rejected data => exact Or.inl ⟨data, rfl, by simp [hc, hb, hr]⟩
      | rejectedWithTrace data nested =>
          exact Or.inr (Or.inl ⟨data, nested, rfl, by simp [hc, hb, hr]⟩)
      | success data after =>
          exact Or.inr (Or.inr (Or.inl ⟨data, after, rfl, by simp [hc, hb, hr]⟩))
      | successWithTrace data after nested =>
          exact Or.inr (Or.inr (Or.inr ⟨data, after, nested, rfl, by simp [hc, hb, hr]⟩))

/-- A protected contract's storage is unchanged by any high-level CALL. -/
theorem call_storage {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (a : Address) (ha : a ∈ self) (k : Nat) :
    (call external ctx target selector value w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  rcases call_shape external ctx target selector value w with
    ⟨-, hc⟩ | ⟨-, -, hc⟩ | ⟨-, -, ⟨d, -, hc⟩ | ⟨d, n, -, hc⟩ | ⟨d, after, hr, hc⟩ |
      ⟨d, after, n, hr, hc⟩⟩
  · rw [hc]
  · rw [hc]
  · rw [hc]
  · rw [hc]
  · rw [hc]
    exact ((returns_success h hr a ha).1 k).trans
      (transfer_slot w ctx.self target value.val a.val k)
  · rw [hc]
    exact (((returns_successWithTrace h hr).1 a ha).1 k).trans
      (transfer_slot w ctx.self target value.val a.val k)

/-- A protected contract's balance after a high-level CALL is the incoming
balance on failure and the provisional transfer's balance on success. -/
theorem call_balance {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (a : Address) (ha : a ∈ self) :
    (call external ctx target selector value w).world.balances a = w.balances a ∨
      ((∃ data, (call external ctx target selector value w).outcome = .ok data) ∧
        (call external ctx target selector value w).world.balances a =
          (transfer w ctx.self target value.val).balances a) := by
  rcases call_shape external ctx target selector value w with
    ⟨-, hc⟩ | ⟨-, -, hc⟩ | ⟨-, -, ⟨d, -, hc⟩ | ⟨d, n, -, hc⟩ | ⟨d, after, hr, hc⟩ |
      ⟨d, after, n, hr, hc⟩⟩
  · rw [hc]; exact Or.inl rfl
  · rw [hc]; exact Or.inl rfl
  · rw [hc]; exact Or.inl rfl
  · rw [hc]; exact Or.inl rfl
  · rw [hc]; exact Or.inr ⟨⟨d, rfl⟩, (returns_success h hr a ha).2⟩
  · rw [hc]; exact Or.inr ⟨⟨d, rfl⟩, ((returns_successWithTrace h hr).1 a ha).2⟩

/-- A high-level CALL into a protected contract never succeeds. -/
theorem call_self_rejected {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) (ht : target ∈ self) (data : Bytes) :
    (call external ctx target selector value w).outcome ≠ .ok data := by
  rcases call_shape external ctx target selector value w with
    ⟨-, hc⟩ | ⟨-, -, hc⟩ | ⟨-, -, ⟨d, -, hc⟩ | ⟨d, n, -, hc⟩ | ⟨d, after, hr, hc⟩ |
      ⟨d, after, n, hr, hc⟩⟩
  · rw [hc]; intro he; first | cases he | simp at he
  · rw [hc]; intro he; first | cases he | simp at he
  · rw [hc]; intro he; first | cases he | simp at he
  · rw [hc]; intro he; first | cases he | simp at he
  · exact absurd hr (fun hr => self_not_success h ht hr)
  · exact absurd hr (fun hr => self_not_successWithTrace h ht hr)

/-- Every recorded nested attempt of a high-level CALL into a protected
contract was rejected. -/
theorem call_nested_rejects {external : External} {self : List Address}
    (h : NoReentry external self) (ctx : Context) (target : Address) (selector : Nat)
    (value : Word) (w : World) :
    ∀ attempt ∈ (call external ctx target selector value w).attempts,
      NestedRejects self attempt.nested := by
  rcases call_shape external ctx target selector value w with
    ⟨-, hc⟩ | ⟨-, -, hc⟩ | ⟨-, -, ⟨d, -, hc⟩ | ⟨d, n, hr, hc⟩ | ⟨d, after, hr, hc⟩ |
      ⟨d, after, n, hr, hc⟩⟩
  · rw [hc]; intro attempt hm; first | cases hm | simp at hm
  · rw [hc]; intro attempt hm
    have hm' := List.mem_singleton.mp hm
    subst hm'
    exact nestedRejects_nil self
  · rw [hc]; intro attempt hm
    have hm' := List.mem_singleton.mp hm
    subst hm'
    exact nestedRejects_nil self
  · rw [hc]; intro attempt hm
    have hm' := List.mem_singleton.mp hm
    subst hm'
    exact returns_rejectedWithTrace h hr
  · rw [hc]; intro attempt hm
    have hm' := List.mem_singleton.mp hm
    subst hm'
    exact nestedRejects_nil self
  · rw [hc]; intro attempt hm
    have hm' := List.mem_singleton.mp hm
    subst hm'
    exact (returns_successWithTrace h hr).2

/-- The three generic consequences of A-NO-REENTRY for every high-level CALL
issued to a residual interpreter `other`: protected storage is unchanged, a
CALL into a protected contract never succeeds, and no recorded nested attempt
into a protected contract was accepted. -/
def Confined (other : External) (self : List Address) : Prop :=
  ∀ (c : Context) (target : Address) (selector : Nat) (value : Word) (w : World),
    (∀ a ∈ self, ∀ k : Nat,
      (call other c target selector value w).world.core.readContractSlot a.val k =
        w.core.readContractSlot a.val k) ∧
    (target ∈ self → ∀ data, (call other c target selector value w).outcome ≠ .ok data) ∧
    (∀ attempt ∈ (call other c target selector value w).attempts,
      NestedRejects self attempt.nested)

theorem confined_of_noReentry {other : External} {self : List Address}
    (h : NoReentry other self) : Confined other self :=
  fun c target selector value w =>
    ⟨fun a ha k => call_storage h c target selector value w a ha k,
     fun ht data => call_self_rejected h c target selector value w ht data,
     call_nested_rejects h c target selector value w⟩

#print axioms call_storage
#print axioms call_balance
#print axioms call_self_rejected
#print axioms call_nested_rejects
#print axioms confined_of_noReentry

end LidoSRv3.Audit.Source.NoReentry
