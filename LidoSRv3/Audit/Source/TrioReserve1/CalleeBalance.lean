import LidoSRv3.Audit.Source.TrioReserve1.Balance
import LidoSRv3.Audit.Source.TrioReserve1.Pipeline

namespace LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance
open Live

/-- Successful callees retain the provisional balances. Rejected replies carry
no committed world; CALL itself handles their restoration. -/
def ReplyPreserves (before : World) : Reply → Prop
  | .success _ after => after.balances = before.balances
  | .successWithTrace _ after _ => after.balances = before.balances
  | .rejected _ => True
  | .rejectedWithTrace _ _ => True

def Preserves (external : External) : Prop :=
  ∀ req before, ReplyPreserves before (external req before)

theorem locator (address : Address) (config : Locator.Config) (other : External)
    (h : Preserves other) : Preserves (Locator.dispatch address config other) := by
  intro req before
  unfold Locator.dispatch
  dsimp only
  split
  · split
    · exact h req before
    · split <;> simp [ReplyPreserves]
  · exact h req before

theorem queue (k : Queue.Keccak) (address : Address) (other : External)
    (h : Preserves other) : Preserves (Queue.dispatch k address other) := by
  intro req before
  unfold Queue.dispatch
  split
  · split
    · trivial
    · split <;> simp [ReplyPreserves]
  · split
    · split <;> simp [ReplyPreserves]
    · exact h req before

theorem router (address lido : Address) (other : External)
    (h : Preserves other) : Preserves (Router.dispatch address lido other) := by
  intro req before
  unfold Router.dispatch
  split
  · unfold Router.receiveDepositableEther
    split <;> simp [ReplyPreserves]
  · exact h req before

theorem oracle_frame (external : StaticCall.External) (address : Address)
    (config : Oracle.Config) (before : World) :
    ReplyPreserves before (Oracle.frame external address config before) := by
  unfold Oracle.frame
  dsimp only
  split
  · trivial
  · split
    · trivial
    · split <;> simp [ReplyPreserves]

theorem oracle (address : Address) (config : Oracle.Config)
    (staticExternal : StaticCall.External) (other : External) (h : Preserves other) :
    Preserves (Oracle.dispatch address config staticExternal other) := by
  intro req before
  unfold Oracle.dispatch
  split
  · split
    · trivial
    · exact oracle_frame staticExternal address config before
  · exact h req before

/-- Concrete dispatchers discharge balance preservation for every handled path,
including malformed data, panic, nonpayable rejection and nested STATICCALL.
Only selectors delegated outside this partial source interpreter retain a premise. -/
theorem pipeline (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (h : Preserves other) :
    Preserves (Pipeline.external k config staticOther other) :=
  locator config.locator config.contracts _
    (queue k config.contracts.queue _
      (oracle config.contracts.oracle config.oracle _ _
        (router config.contracts.router config.lido other h)))

/-- All CALL branches preserve a finite aggregate bound under a balance-preserving
callee. This includes code/funds failures and both traced reply variants. -/
theorem call_conserves (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) (before : World) (accounts : List Address) (limit : Nat)
    (hb : BalanceSpec.Bounded before.balances accounts limit) (he : Preserves external) :
    ∃ support, BalanceSpec.Bounded (call external ctx target selector value before).world.balances support limit ∧
      BalanceSpec.mass (call external ctx target selector value before).world.balances support =
        BalanceSpec.mass before.balances accounts := by
  unfold call
  dsimp only
  split
  · exact ⟨accounts, hb, rfl⟩
  · split
    · exact ⟨accounts, hb, rfl⟩
    · have hf : value.val ≤ before.balances ctx.self := by omega
      obtain ⟨support, bounded, mass⟩ := Balance.transfer_finite before ctx.self target value.val accounts limit hb hf
      have hp := he ⟨ctx.self, target, value, encode 4 selector⟩ (transfer before ctx.self target value.val)
      split <;> simp_all only [ReplyPreserves]
      · exact ⟨accounts, hb, rfl⟩
      · exact ⟨support, by simpa only [hp] using bounded, by simpa only [hp] using mass⟩
      · exact ⟨support, by simpa only [hp] using bounded, by simpa only [hp] using mass⟩
      · exact ⟨accounts, hb, rfl⟩

theorem call_uint256 (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) (before : World) (accounts : List Address)
    (hb : BalanceSpec.Bounded before.balances accounts Verity.Core.UINT256_MODULUS)
    (he : Preserves external) (account : Address) :
    (call external ctx target selector value before).world.balances account < Verity.Core.UINT256_MODULUS := by
  obtain ⟨support, bounded, _⟩ := call_conserves external ctx target selector value before accounts _ hb he
  exact BalanceSpec.account_bound _ support _ bounded account

theorem pipeline_call_uint256 (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (he : Preserves other)
    (ctx : Context) (target : Address) (selector : Nat) (value : Word)
    (before : World) (accounts : List Address)
    (hb : BalanceSpec.Bounded before.balances accounts Verity.Core.UINT256_MODULUS)
    (account : Address) :
    (call (Pipeline.external k config staticOther other) ctx target selector value before).world.balances account <
      Verity.Core.UINT256_MODULUS :=
  call_uint256 _ ctx target selector value before accounts hb (pipeline k config staticOther other he) account

end LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance
