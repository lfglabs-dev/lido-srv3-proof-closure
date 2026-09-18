import LidoSRv3.Audit.Source.TrioReserve1.Live

/-!
An explicit frame for source interpreters that use Verity's unqualified word
lenses. Entry reads the executing account's contract-qualified words; commit
writes only that account's physical words back. It never equates independent
storage channels or assumes that a callback preserves another account.

Contract id zero follows the pinned Verity API's documented unqualified alias.
This adapter is a representation law, not deployed-bytecode correspondence.
Local memory, sender, events and other interpreter fields are not committed by
this storage-only frame; caller/callee balances and logs remain in Live.World.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.AccountFrame
open Verity
open Live

def enter (ctx : Context) (outer : ContractState) : ContractState :=
  { outer with
    storageWords := fun key => match key with
      | .slot slot => outer.readContractSlot ctx.self.val slot
      | _ => outer.storageWords key
    sender := ctx.sender
    thisAddress := ctx.self }

def commit (account : Verity.Address) (outer localState : ContractState) : ContractState :=
  { outer with storageWords := fun key => match key with
      | .slot slot => if account.val = 0 then localState.readSlot slot else outer.storageWords key
      | .contractSlot owner slot =>
          if account.val ≠ 0 ∧ owner = account.val then localState.readSlot slot
          else outer.storageWords key
      | _ => outer.storageWords key }

@[simp] theorem enter_read (ctx : Context) (outer : ContractState) (slot : Nat) :
    (enter ctx outer).readSlot slot = outer.readContractSlot ctx.self.val slot := rfl

@[simp] theorem enter_sender (ctx : Context) (outer : ContractState) :
    (enter ctx outer).sender = ctx.sender := rfl

@[simp] theorem commit_read (account : Verity.Address) (outer localState : ContractState) (slot : Nat) :
    (commit account outer localState).readContractSlot account.val slot = localState.readSlot slot := by
  by_cases h : account.val = 0 <;>
    simp [commit, ContractState.readContractSlot, ContractState.contractStorage,
      ContractState.readSlot, ContractState.storage, h]

/-- A storage-only frame cannot commit a local interpreter's changes to a
foreign contract, including Verity's legacy unqualified account zero. -/
theorem commit_other_account (account : Verity.Address) (outer localState : ContractState)
    (other slot : Nat) (h : other ≠ account.val) :
    (commit account outer localState).readContractSlot other slot =
      outer.readContractSlot other slot := by
  by_cases ha : account.val = 0 <;> by_cases ho : other = 0 <;>
    simp_all [commit, ContractState.readContractSlot, ContractState.contractStorage,
      ContractState.readSlot, ContractState.storage]

/-- Reading a word after an actual contract-qualified write reaches that write
through the local frame. No cross-channel equality is supplied as a premise. -/
theorem enter_after_write (ctx : Context) (outer : ContractState) (slot : Nat) (value : Word) :
    (enter ctx (outer.writeContractSlot ctx.self.val slot value)).readSlot slot = value := by
  rw [enter_read]
  exact ContractState.readContractSlot_writeContractSlot_same outer ctx.self.val slot value

/-- Local source writes return to the same executing account's physical word. -/
theorem commit_after_write (ctx : Context) (outer : ContractState) (slot : Nat) (value : Word) :
    (commit ctx.self outer ((enter ctx outer).writeSlot slot value)).readContractSlot
      ctx.self.val slot = value := by
  rw [commit_read]
  simp [ContractState.readSlot, ContractState.storage, ContractState.writeSlot]

/-- Entering and committing without writes leaves every physical account read
unchanged, including the account-zero alias. -/
theorem commit_enter_read (ctx : Context) (outer : ContractState) (account slot : Nat) :
    (commit ctx.self outer (enter ctx outer)).readContractSlot account slot =
      outer.readContractSlot account slot := by
  by_cases h : account = ctx.self.val
  · subst account
    rw [commit_read, enter_read]
  · exact commit_other_account ctx.self outer (enter ctx outer) account slot h

#print axioms enter_after_write
#print axioms commit_after_write
#print axioms commit_other_account
#print axioms commit_enter_read
end LidoSRv3.Audit.Source.TrioReserve1.AccountFrame
