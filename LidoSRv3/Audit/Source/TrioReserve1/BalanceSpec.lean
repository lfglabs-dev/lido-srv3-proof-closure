import LidoSRv3.Audit.Source.TrioReserve1.CallSpec
import Lean.Elab.Tactic.Omega

namespace LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec

def mass {Address : Type} (balances : Address → Nat) : List Address → Nat
  | [] => 0
  | account :: rest => balances account + mass balances rest

/-- A finite account support with a strict bound on total balances. This is an
explicit world invariant, not a consequence of individual uint256 bounds. -/
def Bounded {Address : Type} (balances : Address → Nat) (accounts : List Address) (limit : Nat) : Prop :=
  accounts.Nodup ∧ (∀ account, account ∉ accounts → balances account = 0) ∧ mass balances accounts < limit

theorem member_bound {Address : Type} (balances : Address → Nat) (accounts : List Address)
    (account : Address) (h : account ∈ accounts) : balances account ≤ mass balances accounts := by
  induction accounts with
  | nil => simp at h
  | cons first rest ih =>
    simp only [List.mem_cons] at h
    rcases h with rfl | h
    · simp [mass]
    · have hb := ih h
      simp only [mass]
      omega

theorem account_bound {Address : Type} (balances : Address → Nat) (accounts : List Address)
    (limit : Nat) (h : Bounded balances accounts limit) (account : Address) : balances account < limit := by
  by_cases hm : account ∈ accounts
  · have hb := member_bound balances accounts account hm
    exact Nat.lt_of_le_of_lt hb h.2.2
  · rw [h.2.1 account hm]
    have hb := h.2.2
    omega

/-- Sum the pointwise CALL conservation rule over a duplicate-free support.
Aliased sender/recipient positions cancel exactly. -/
theorem mass_equation {Address : Type} [DecidableEq Address]
    (before after : Address → Nat) (sender recipient : Address) (amount : Nat)
    (accounts : List Address) (hn : accounts.Nodup)
    (h : CallSpec.Balances before after sender recipient amount) :
    mass after accounts + (if sender ∈ accounts then amount else 0) =
      mass before accounts + (if recipient ∈ accounts then amount else 0) := by
  induction accounts with
  | nil => simp [mass]
  | cons account rest ih =>
    obtain ⟨hnot, hrest⟩ := List.nodup_cons.mp hn
    have hi := ih hrest
    have ha := h account
    have count (who : Address) :
        (if who ∈ account :: rest then amount else 0) =
          (if account = who then amount else 0) + (if who ∈ rest then amount else 0) := by
      by_cases he : account = who
      · subst who
        simp [hnot]
      · simp [List.mem_cons, Ne.symm he, he]
    rw [count sender, count recipient]
    simp only [mass]
    omega

/-- Extending support with a previously absent account adds zero balance. -/
def includeAccount {Address : Type} [DecidableEq Address] (account : Address)
    (accounts : List Address) : List Address :=
  if account ∈ accounts then accounts else account :: accounts

theorem include_member {Address : Type} [DecidableEq Address] (account : Address)
    (accounts : List Address) : account ∈ includeAccount account accounts := by
  by_cases h : account ∈ accounts <;> simp [includeAccount, h]

theorem include_retains {Address : Type} [DecidableEq Address] (account other : Address)
    (accounts : List Address) (h : other ∈ accounts) : other ∈ includeAccount account accounts := by
  by_cases hm : account ∈ accounts <;> simp [includeAccount, hm, h]

theorem include_bounded {Address : Type} [DecidableEq Address] (balances : Address → Nat)
    (account : Address) (accounts : List Address) (limit : Nat)
    (h : Bounded balances accounts limit) :
    Bounded balances (includeAccount account accounts) limit ∧
      mass balances (includeAccount account accounts) = mass balances accounts := by
  by_cases hm : account ∈ accounts
  · simp only [includeAccount, hm, if_true]
    exact ⟨h, trivial⟩
  · have hz := h.2.1 account hm
    simp only [includeAccount, hm, if_false]
    refine ⟨⟨List.nodup_cons.mpr ⟨hm, h.1⟩, ?_, ?_⟩, ?_⟩
    · intro other hn
      exact h.2.1 other (fun he => hn (List.mem_cons_of_mem account he))
    · simpa [mass, hz] using h.2.2
    · simp [mass, hz]

theorem preserves {Address : Type} [DecidableEq Address]
    (before after : Address → Nat) (sender recipient : Address) (amount : Nat)
    (accounts : List Address) (limit : Nat)
    (hb : Bounded before accounts limit) (hs : sender ∈ accounts) (hr : recipient ∈ accounts)
    (h : CallSpec.Balances before after sender recipient amount) :
    Bounded after accounts limit ∧ mass after accounts = mass before accounts := by
  have he := mass_equation before after sender recipient amount accounts hb.1 h
  simp only [hs, hr, ite_true] at he
  have hm : mass after accounts = mass before accounts := Nat.add_right_cancel he
  refine ⟨⟨hb.1, ?_, by rw [hm]; exact hb.2.2⟩, hm⟩
  intro account hn
  have hns : account ≠ sender := by intro he; subst account; exact hn hs
  have hnr : account ≠ recipient := by intro he; subst account; exact hn hr
  have ha := h account
  simpa [hns, hnr, hb.2.1 account hn] using ha

end LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec
