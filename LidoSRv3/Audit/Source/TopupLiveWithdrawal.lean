import LidoSRv3.Audit.Source.TrioReserve1.Pipeline
import LidoSRv3.Audit.Source.TrioReserve1.CallFlow

namespace LidoSRv3.Audit.Source.TopupLiveWithdrawal
open TrioReserve1 TrioReserve1.Live

/-!
TOPUP withdrawal consumer of the delivered RESERVE pipeline.
Solidity pin: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436.
StakingRouter.sol:741-744 skips zero and calls withdrawDepositableEther(amount, 0).
Lido.sol:869-885 executes accounting then the authorized receiver at
StakingRouter.sol:665-669. No manually credited balance or successful reply is
an input here. The outer ABI/module prefix and the later beacon loop are outside
this consumer; the Word input is the source uint256 amount, not a derived sum.
-/

/-- The TOPUP-specific branch and second argument, in the same physical world. -/
def suffix (external : External) (ctx : Context) (amount : Word) : Exec Unit :=
  if amount.val = 0 then pureExec ()
  else withdrawDepositableEther external ctx amount (word 0)

/-- Independent pointwise ETH accounting. No executable or post-state equality
is embedded in this specification. Old router balances may be nonzero. -/
structure Balances (before after : Address → Nat) (lido router : Address)
    (amount : Nat) : Prop where
  lido_debit : after lido + amount = before lido
  router_credit : after router = before router + amount
  other_accounts : ∀ account, account ≠ lido → account ≠ router →
    after account = before account

/-- The receiver is the final successful value-bearing callback, followed by
its committed event. Prefixes include the source getter/accounting observations. -/
def Callback (lido router : Address) (amount : Word) (after : World)
    (attempts : List Attempt) : Prop :=
  (∃ tracePrefix, attempts = tracePrefix ++
    [⟨⟨lido, router, amount, encode 4 0x13ae8460⟩, true, [], []⟩]) ∧
  (∃ logPrefix, after.logs = logPrefix ++
    [⟨router, "DepositableEthReceived", [amount]⟩])

theorem transfer_balances (before : World) (lido router : Address) (amount : Nat)
    (hd : lido ≠ router) (hf : amount ≤ before.balances lido) :
    Balances before.balances (transfer before lido router amount).balances
      lido router amount := by
  have h := CallFlow.transfer_balances before lido router amount hf
  constructor
  · simpa [CallSpec.Balances, hd] using h lido
  · simpa [CallSpec.Balances, Ne.symm hd] using h router
  · intro account hl hr
    simpa [CallSpec.Balances, hl, hr] using h account

/-- Zero TOPUP skips the withdrawal even when all external calls would reject;
no active/code/funding hypotheses are required on this branch. -/
theorem zero_noop (external : External) (ctx : Context) (amount : Word)
    (before : World) (hz : amount.val = 0) :
    run (suffix external ctx amount) before = ⟨.ok (), before, []⟩ := by
  simp [suffix, hz, run, pureExec]

/-- The source's zero seed argument creates no seed-accounting tail. -/
theorem zero_seed_tail (ctx : Context) (before : World) :
    WithdrawalTail.updateSeeds ctx (word 0) before = ⟨.ok (), before, []⟩ := by
  simpa [Pipeline.seeded, word] using
    WithdrawalTail.seeds_zero ctx (word 0) before (by rfl)

/-- Concrete successful TOPUP withdrawal. All source/physical admission facts
remain explicit; getter and callback success, balance credit and seed bounds
are derived. In particular, `other` needs no assumed preservation/success law:
the concrete dispatch handles every call on this admitted path. -/
theorem positive_success (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (before : World) (amount : Word)
    (demand reference deadline time : Nat) (b : Pipeline.Bound c ctx before)
    (hb : Queue.isBunkerModeActive c.contracts.queue before = false)
    (hp : (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue before = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx before demand).deposits +
      (QueueCalls.allocationValues ctx before demand).unreserved)
    (hf : Consensus.compute c.frame
      (Pipeline.prepared ctx amount before demand).core.blockTimestamp.val
      ((Pipeline.prepared ctx amount before demand).core.readContractSlot
        c.consensus.val c.frame.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hfunds : amount.val ≤ before.balances ctx.self)
    (hlido : ctx.self = c.lido)
    (hrcode : (before.core.codeSize c.contracts.router.val).val ≠ 0)
    (hd : ctx.self ≠ c.contracts.router) :
    let result := run (suffix (Pipeline.external k c staticOther other) ctx amount) before
    result.outcome = .ok () ∧
      Balances before.balances result.world.balances ctx.self c.contracts.router amount.val ∧
      Callback ctx.self c.contracts.router amount result.world result.attempts := by
  have hseed : ((Pipeline.spent ctx amount before demand reference).core.readContractSlot
      ctx.self.val seedSlot).val % width + (word 0).val < Verity.Core.UINT256_MODULUS := by
    have h := Nat.mod_lt
      ((Pipeline.spent ctx amount before demand reference).core.readContractSlot
        ctx.self.val seedSlot).val (show 0 < width by decide)
    change _ % width + 0 < 2^256
    unfold width at h ⊢
    omega
  have he := Pipeline.success k c staticOther other ctx before amount (word 0)
    demand reference deadline time b hb hp hauth hn hq hamount hf ht hseed hfunds hlido hrcode
  dsimp only
  simp only [suffix, hn, ↓reduceIte]
  rw [he]
  dsimp only
  refine ⟨rfl, ?_, ?_⟩
  · have hbalance := Pipeline.final_balances ctx amount (word 0) before demand reference
    have hfunds' : amount.val ≤
        (Pipeline.seeded ctx (word 0) (Pipeline.spent ctx amount before demand reference)).balances ctx.self := by
      rwa [hbalance]
    have hresult := transfer_balances
      (Pipeline.seeded ctx (word 0) (Pipeline.spent ctx amount before demand reference))
      ctx.self c.contracts.router amount.val hd hfunds'
    rw [hbalance] at hresult
    exact hresult
  · exact ⟨⟨_, rfl⟩, ⟨_, rfl⟩⟩

end LidoSRv3.Audit.Source.TopupLiveWithdrawal
