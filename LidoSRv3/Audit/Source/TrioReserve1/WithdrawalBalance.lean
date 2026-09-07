import LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance

namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalBalance
open Live

/-- Every execution result retains a finite aggregate bound and the initial total
balance. This includes failed intermediate stages before root rollback. -/
def Conserves (program : Exec α) : Prop :=
  ∀ before accounts limit, BalanceSpec.Bounded before.balances accounts limit →
    ∃ support, BalanceSpec.Bounded (program before).world.balances support limit ∧
      BalanceSpec.mass (program before).world.balances support = BalanceSpec.mass before.balances accounts

theorem unchanged (program : Exec α)
    (h : ∀ before, (program before).world.balances = before.balances) : Conserves program := by
  intro before accounts limit hb
  exact ⟨accounts, by simpa only [h] using hb, by rw [h]⟩

theorem pure_preserves (value : α) : Conserves (pureExec value) := unchanged _ (fun _ => rfl)
theorem fail_preserves (fault : Fault) : Conserves (fail (α := α) fault) := unchanged _ (fun _ => rfl)
theorem read_preserves (ctx : Context) (slot : Nat) : Conserves (Live.read ctx slot) := unchanged _ (fun _ => rfl)
theorem write_preserves (ctx : Context) (slot : Nat) (value : Word) : Conserves (write ctx slot value) :=
  unchanged _ (fun _ => rfl)
theorem emit_preserves (ctx : Context) (name : String) (values : List Word) : Conserves (emit ctx name values) :=
  unchanged _ (fun _ => rfl)
theorem require_preserves (condition : Bool) (fault : Fault) : Conserves (require condition fault) := by
  cases condition <;> exact unchanged _ (fun _ => rfl)

theorem bind_preserves (first : Exec α) (next : α → Exec β)
    (hf : Conserves first) (hn : ∀ value, Conserves (next value)) : Conserves (bindExec first next) := by
  intro before accounts limit hb
  obtain ⟨middle, hm, hmass⟩ := hf before accounts limit hb
  unfold bindExec
  dsimp only
  split
  · exact ⟨middle, hm, hmass⟩
  · rename_i value _
    obtain ⟨support, hs, htotal⟩ := hn value (first before).world middle limit hm
    exact ⟨support, hs, htotal.trans hmass⟩

theorem ite_preserves (condition : Prop) [Decidable condition] (left right : Exec α)
    (hl : Conserves left) (hr : Conserves right) : Conserves (if condition then left else right) := by
  split <;> assumption

theorem call_preserves {external : External} (he : CalleeBalance.Preserves external)
    (ctx : Context) (target : Address) (selector : Nat) (value : Word) :
    Conserves (call external ctx target selector value) := by
  intro before accounts limit hb
  exact CalleeBalance.call_conserves external ctx target selector value before accounts limit hb he

/-- No success, authorization, ABI-validity or physical accounting premise is
needed for balance conservation through the complete source withdrawal program.
Storage/event writes preserve balances and each actual CALL carries the invariant. -/
theorem withdrawal {external : External} (he : CalleeBalance.Preserves external)
    (ctx : Context) (amount seeds : Word) : Conserves (withdrawDepositableEther external ctx amount seeds) := by
  unfold withdrawDepositableEther canDeposit stakingRouter spendDepositableEther
    getBufferedEtherAllocation withdrawalQueue locatorAddress getLidoLocator decodeWord
    checkedAdd checkedSub getDepositedNextReportAdjusted getCurrentFrame setDepositsReserve
  unfold locatorAddress getLidoLocator decodeWord
  repeat' first
    | apply bind_preserves
    | solve | apply pure_preserves
    | solve | apply require_preserves
    | solve | apply read_preserves
    | solve | apply write_preserves
    | solve | apply emit_preserves
    | solve | apply call_preserves he
    | apply ite_preserves
    | split
    | intro x

theorem root_preserves (program : Exec α) (h : Conserves program) : Conserves (run program) := by
  intro before accounts limit hb
  unfold run
  dsimp only
  split
  · exact h before accounts limit hb
  · exact ⟨accounts, hb, rfl⟩

theorem withdrawal_uint256 {external : External} (he : CalleeBalance.Preserves external)
    (ctx : Context) (amount seeds : Word) (before : World) (accounts : List Address)
    (hb : BalanceSpec.Bounded before.balances accounts Verity.Core.UINT256_MODULUS) (account : Address) :
    (run (withdrawDepositableEther external ctx amount seeds) before).world.balances account <
      Verity.Core.UINT256_MODULUS := by
  obtain ⟨support, bounded, _⟩ := root_preserves _ (withdrawal he ctx amount seeds) before accounts _ hb
  exact BalanceSpec.account_bound _ support _ bounded account

/-- Specialization to the concrete dispatch chain. Its handled selectors discharge
callee preservation; the remaining interpreter is still an explicit boundary. -/
theorem pipeline_withdrawal (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (he : CalleeBalance.Preserves other)
    (ctx : Context) (amount seeds : Word) :
    Conserves (run (withdrawDepositableEther (Pipeline.external k config staticOther other) ctx amount seeds)) :=
  root_preserves _ (withdrawal (CalleeBalance.pipeline k config staticOther other he) ctx amount seeds)

theorem target (ctx : Context) (requested : Word) : Conserves (setDepositsReserveTarget ctx requested) := by
  unfold setDepositsReserveTarget setDepositsReserve
  repeat' first
    | apply bind_preserves
    | solve | apply pure_preserves
    | solve | apply read_preserves
    | solve | apply write_preserves
    | solve | apply emit_preserves
    | apply ite_preserves
    | intro x

theorem rebalance (ctx : Context) : Conserves (updateBufferedEtherAllocation ctx) := by
  unfold updateBufferedEtherAllocation setDepositsReserve
  repeat' first
    | apply bind_preserves
    | solve | apply pure_preserves
    | solve | apply read_preserves
    | solve | apply write_preserves
    | solve | apply emit_preserves
    | apply ite_preserves
    | intro x

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalBalance
