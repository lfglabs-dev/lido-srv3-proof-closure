import LidoSRv3.Audit.Source.TrioReserve1.ConsensusCalls
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalComposition
import LidoSRv3.Audit.Source.TrioReserve1.Writers

namespace LidoSRv3.Audit.Source.TrioReserve1.Pipeline
open Live

structure Config where
  locator : Address
  contracts : Locator.Config
  oracle : Oracle.Config
  consensus : Address
  frame : Consensus.Config
  lido : Address

def external (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) : External :=
  OracleCalls.external k c.locator c.contracts c.oracle
    (Consensus.dispatch c.consensus c.frame staticOther)
    (Router.dispatch c.contracts.router c.lido other)

theorem read_other_slot (core : Verity.ContractState) (writer reader written slot : Nat)
    (value : Word) (h : slot ≠ written) :
    (core.writeContractSlot writer written value).readContractSlot reader slot =
      core.readContractSlot reader slot := by
  by_cases hw : writer = 0 <;> by_cases hr : reader = 0 <;>
    simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
      Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
      Verity.ContractState.storage, Verity.ContractState.contractStorage, hw, hr, h]

theorem write_code (core : Verity.ContractState) (account slot : Nat) (value : Word) :
    (core.writeContractSlot account slot value).codeSize = core.codeSize := by
  unfold Verity.ContractState.writeContractSlot
  split <;> rfl

theorem prepared_locator (ctx : Context) (a : Live.Allocation) (amount : Word) (w : World) :
    (Spending.beforeFrame ctx a amount w).core.readContractSlot ctx.self.val locatorSlot =
      w.core.readContractSlot ctx.self.val locatorSlot := by
  apply read_other_slot
  decide

theorem prepared_consensus (ctx : Context) (a : Live.Allocation) (amount : Word)
    (oracle : Address) (w : World) :
    ConsensusCalls.consensusAddress oracle (Spending.beforeFrame ctx a amount w) =
      ConsensusCalls.consensusAddress oracle w := by
  unfold ConsensusCalls.consensusAddress
  congr 2
  apply read_other_slot
  decide

theorem prepared_code (ctx : Context) (a : Live.Allocation) (amount : Word) (w : World) :
    (Spending.beforeFrame ctx a amount w).core.codeSize = w.core.codeSize := by
  apply write_code

/-- All preceding dispatchers delegate this receiver selector. The final
source receiver still enforces its own immutable LIDO authorization. -/
theorem receiver (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount : Word)
    (ha : ctx.self = c.lido) (hc : (w.core.codeSize c.contracts.router.val).val ≠ 0)
    (hb : amount.val ≤ w.balances ctx.self) :
    call (external k c staticOther other) ctx c.contracts.router 0x13ae8460 amount w =
      ⟨.ok [], {transfer w ctx.self c.contracts.router amount.val with
        logs := w.logs ++ [⟨c.contracts.router, "DepositableEthReceived", [amount]⟩]},
        [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, true, [], []⟩]⟩ := by
  rw [ha] at hb
  have h1 : encode 4 0x13ae8460 ≠ encode 4 0x37d5fe99 := by decide
  have h2 : encode 4 0x13ae8460 ≠ encode 4 0xef6c064c := by decide
  have h3 : encode 4 0x13ae8460 ≠ encode 4 0x5a2031f9 := by decide
  have h4 : encode 4 0x13ae8460 ≠ encode 4 0xd0fb84e8 := by decide
  have h5 : encode 4 0x13ae8460 ≠ encode 4 0x2b95b781 := by decide
  have h6 : encode 4 0x13ae8460 ≠ encode 4 0x72f79b13 := by decide
  simp [call, external, OracleCalls.external, QueueCalls.external, Locator.dispatch,
    Queue.dispatch, Oracle.dispatch, Router.dispatch, Router.receiveDepositableEther,
    h1, h2, h3, h4, h5, h6, ha, hc, Nat.not_lt.mpr hb, transfer]

/-- Concrete address/code inputs, not successful call or permission flags. -/
structure Bound (c : Config) (ctx : Context) (w : World) : Prop where
  locator : c.locator = Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
  consensus : c.consensus = ConsensusCalls.consensusAddress c.contracts.oracle w
  queue_ne_locator : c.contracts.queue ≠ c.locator
  oracle_ne_locator : c.contracts.oracle ≠ c.locator
  oracle_ne_queue : c.contracts.oracle ≠ c.contracts.queue
  locator_code : (w.core.codeSize c.locator.val).val ≠ 0
  queue_code : (w.core.codeSize c.contracts.queue.val).val ≠ 0
  oracle_code : (w.core.codeSize c.contracts.oracle.val).val ≠ 0
  consensus_code : (w.core.codeSize c.consensus.val).val ≠ 0

def frameTrace (c : Config) (ctx : Context) (reference deadline time : Nat) : List Attempt :=
  [⟨⟨ctx.self, c.locator, word 0, encode 4 0x5a2031f9⟩, true, encode 32 c.contracts.oracle.val, []⟩,
    ⟨⟨ctx.self, c.contracts.oracle, word 0, encode 4 0x72f79b13⟩, true, encode 32 reference ++ encode 32 time,
      [ConsensusCalls.attempt c.contracts.oracle c.consensus true (encode 32 reference ++ encode 32 deadline)]⟩]

theorem frame_result (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (a : Live.Allocation) (amount : Word)
    (reference deadline time : Nat) (b : Bound c ctx w)
    (h : Consensus.compute c.frame (Spending.beforeFrame ctx a amount w).core.blockTimestamp.val
      ((Spending.beforeFrame ctx a amount w).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time) :
    getCurrentFrame (external k c staticOther other) ctx (Spending.beforeFrame ctx a amount w) =
      ⟨.ok (reference, time), Spending.beforeFrame ctx a amount w, frameTrace c ctx reference deadline time⟩ := by
  have hl : c.locator = Verity.Core.Address.ofNat
      ((Spending.beforeFrame ctx a amount w).core.readContractSlot ctx.self.val locatorSlot).val := by
    simpa only [prepared_locator] using b.locator
  have hc : c.consensus = ConsensusCalls.consensusAddress c.contracts.oracle
      (Spending.beforeFrame ctx a amount w) := by
    simpa only [prepared_consensus] using b.consensus
  have hg := ConsensusCalls.lido_frame k c.contracts c.oracle c.frame staticOther
    (Router.dispatch c.contracts.router c.lido other) ctx (Spending.beforeFrame ctx a amount w)
    reference deadline time
    (by simpa only [← hl] using b.oracle_ne_locator) b.oracle_ne_queue
    (by simpa only [← hl, prepared_code] using b.locator_code)
    (by simpa only [prepared_code] using b.oracle_code)
    (by simpa only [← hc, prepared_code] using b.consensus_code)
    (by simpa only [← hc] using h) ht
  simpa only [← hl, ← hc, external, frameTrace] using hg

def statusTrace (c : Config) (ctx : Context) (w : World) : List Attempt :=
  [QueueCalls.lookupAttempt ctx c.locator c.contracts.queue,
    ⟨⟨ctx.self, c.contracts.queue, word 0, encode 4 0x2b95b781⟩, true,
      QueueCalls.bunkerBytes c.contracts.queue w, []⟩]

def routerTrace (c : Config) (ctx : Context) : List Attempt :=
  [⟨⟨ctx.self, c.locator, word 0, encode 4 0xef6c064c⟩, true, encode 32 c.contracts.router.val, []⟩]

def allocationTrace (c : Config) (ctx : Context) (demand : Nat) : List Attempt :=
  [QueueCalls.lookupAttempt ctx c.locator c.contracts.queue,
    ⟨⟨ctx.self, c.contracts.queue, word 0, encode 4 0xd0fb84e8⟩, true, encode 32 demand, []⟩]

theorem status_result (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0) :
    canDeposit (external k c staticOther other) ctx w = ⟨.ok true, w, statusTrace c ctx w⟩ := by
  have hs := QueueCalls.status k c.contracts
    (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
      (Router.dispatch c.contracts.router c.lido other)) ctx w
    (by simpa only [← b.locator] using b.queue_ne_locator)
    (by simpa only [← b.locator] using b.locator_code) b.queue_code
  simpa [← b.locator, hb, hp, external, OracleCalls.external, statusTrace] using hs

theorem router_result (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (b : Bound c ctx w) :
    stakingRouter (external k c staticOther other) ctx w = ⟨.ok c.contracts.router, w, routerTrace c ctx⟩ := by
  have hr := CallResults.router_lookup ctx w c.contracts
    (Queue.dispatch k c.contracts.queue
      (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
        (Router.dispatch c.contracts.router c.lido other)))
    (by simpa only [← b.locator] using b.locator_code)
  simpa only [← b.locator, external, OracleCalls.external, QueueCalls.external, routerTrace] using hr

theorem allocation_result (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (demand : Nat) (b : Bound c ctx w)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand) :
    getBufferedEtherAllocation (external k c staticOther other) ctx w =
      ⟨.ok (QueueCalls.allocationValues ctx w demand), w, allocationTrace c ctx demand⟩ := by
  have ha := QueueCalls.allocation_success k c.contracts
    (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
      (Router.dispatch c.contracts.router c.lido other)) ctx w demand
    (by simpa only [← b.locator] using b.queue_ne_locator)
    (by simpa only [← b.locator] using b.locator_code) b.queue_code hq
  simpa only [← b.locator, external, OracleCalls.external, allocationTrace] using ha

def prepared (ctx : Context) (amount : Word) (w : World) (demand : Nat) : World :=
  Spending.beforeFrame ctx (QueueCalls.allocationValues ctx w demand) amount w

def spent (ctx : Context) (amount : Word) (w : World) (demand reference : Nat) : World :=
  let p := prepared ctx amount w demand
  Spending.afterFrame ctx amount (WithdrawalComposition.adjustedNext ctx p reference) reference p

/-- All prefix results are derived from the concrete source chain and its
physical inputs. There is no assumed successful status, lookup, allocation,
frame CALL or spending result in this parent theorem. -/
theorem before_tail (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount seeds : Word)
    (demand reference deadline time : Nat) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved)
    (hf : Consensus.compute c.frame (prepared ctx amount w demand).core.blockTimestamp.val
      ((prepared ctx amount w demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time) :
    let tail := WithdrawalTail.finish (external k c staticOther other) ctx c.contracts.router amount seeds
      (spent ctx amount w demand reference)
    withdrawDepositableEther (external k c staticOther other) ctx amount seeds w =
      ⟨tail.outcome, tail.world, statusTrace c ctx w ++ routerTrace c ctx ++
        allocationTrace c ctx demand ++ frameTrace c ctx reference deadline time ++ tail.attempts⟩ := by
  have hs := status_result k c staticOther other ctx w b hb hp
  have hr := router_result k c staticOther other ctx w b
  have ha := allocation_result k c staticOther other ctx w demand b hq
  have hframe := frame_result k c staticOther other ctx w _ amount reference deadline time b hf ht
  exact WithdrawalComposition.after_frame _ ctx c.contracts.router amount seeds w w w w _
    _ reference time _ _ _ _ hs hr hauth hn ha hamount hframe

def seeded (ctx : Context) (seeds : Word) (w : World) : World :=
  if seeds.val = 0 then w else WithdrawalTail.seedWorld ctx seeds w

theorem seed_result (ctx : Context) (seeds : Word) (w : World)
    (hb : (w.core.readContractSlot ctx.self.val seedSlot).val % width + seeds.val <
      Verity.Core.UINT256_MODULUS) :
    WithdrawalTail.updateSeeds ctx seeds w = ⟨.ok (), seeded ctx seeds w, []⟩ := by
  by_cases hz : seeds.val = 0
  · simpa only [seeded, hz, ite_true] using WithdrawalTail.seeds_zero ctx seeds w hz
  · simpa only [seeded, hz, ite_false] using WithdrawalTail.seeds_success ctx seeds w (by omega) hb

theorem after_frame_code (ctx : Context) (amount : Word) (next nonce : Nat) (w : World) :
    (Spending.afterFrame ctx amount next nonce w).core.codeSize = w.core.codeSize := by
  unfold Spending.afterFrame
  dsimp only
  split <;> simp only [write_code]

theorem after_frame_balances (ctx : Context) (amount : Word) (next nonce : Nat) (w : World) :
    (Spending.afterFrame ctx amount next nonce w).balances = w.balances := by
  unfold Spending.afterFrame
  dsimp only
  split <;> rfl

theorem seeded_code (ctx : Context) (seeds : Word) (w : World) :
    (seeded ctx seeds w).core.codeSize = w.core.codeSize := by
  unfold seeded
  split
  · rfl
  · exact write_code _ _ _ _

theorem seeded_balances (ctx : Context) (seeds : Word) (w : World) :
    (seeded ctx seeds w).balances = w.balances := by
  unfold seeded
  split <;> rfl

theorem final_code (ctx : Context) (amount seeds : Word) (w : World) (demand reference : Nat) :
    (seeded ctx seeds (spent ctx amount w demand reference)).core.codeSize = w.core.codeSize := by
  rw [seeded_code]
  unfold spent
  rw [after_frame_code]
  exact prepared_code _ _ _ _

theorem final_balances (ctx : Context) (amount seeds : Word) (w : World) (demand reference : Nat) :
    (seeded ctx seeds (spent ctx amount w demand reference)).balances = w.balances := by
  rw [seeded_balances]
  unfold spent
  rw [after_frame_balances]
  rfl

/-- Successful concrete withdrawal, including all accounting/seed writes,
committed events, actual ETH transfer and the source receiver. Bounds are
numeric input checks; no external successful-call reply is assumed. -/
theorem success (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount seeds : Word)
    (demand reference deadline time : Nat) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved)
    (hf : Consensus.compute c.frame (prepared ctx amount w demand).core.blockTimestamp.val
      ((prepared ctx amount w demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((spent ctx amount w demand reference).core.readContractSlot ctx.self.val seedSlot).val % width +
      seeds.val < Verity.Core.UINT256_MODULUS)
    (hfunds : amount.val ≤ w.balances ctx.self)
    (hlido : ctx.self = c.lido) (hrcode : (w.core.codeSize c.contracts.router.val).val ≠ 0) :
    let sw := seeded ctx seeds (spent ctx amount w demand reference)
    run (withdrawDepositableEther (external k c staticOther other) ctx amount seeds) w =
      ⟨.ok (), {transfer sw ctx.self c.contracts.router amount.val with
          logs := sw.logs ++ [⟨c.contracts.router, "DepositableEthReceived", [amount]⟩]},
        statusTrace c ctx w ++ routerTrace c ctx ++ allocationTrace c ctx demand ++
          frameTrace c ctx reference deadline time ++
          [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, true, [], []⟩]⟩ := by
  have hs := seed_result ctx seeds (spent ctx amount w demand reference) hseed
  have hc := receiver k c staticOther other ctx
    (seeded ctx seeds (spent ctx amount w demand reference)) amount hlido
    (by simpa only [final_code] using hrcode)
    (by simpa only [final_balances] using hfunds)
  have htail := WithdrawalTail.finish_call (external k c staticOther other) ctx c.contracts.router
    amount seeds (spent ctx amount w demand reference) _ _ [] _ hs hc
  have hparent := before_tail k c staticOther other ctx w amount seeds demand reference deadline time
    b hb hp hauth hn hq hamount hf ht
  simp only [htail] at hparent
  unfold run
  rw [hparent]

theorem receiver_rejection (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount : Word)
    (ha : ctx.self ≠ c.lido) (hc : (w.core.codeSize c.contracts.router.val).val ≠ 0)
    (hb : amount.val ≤ w.balances ctx.self) :
    call (external k c staticOther other) ctx c.contracts.router 0x13ae8460 amount w =
      ⟨.error (.bubbled Router.notAuthorized), w,
        [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, Router.notAuthorized, []⟩]⟩ := by
  have h1 : encode 4 0x13ae8460 ≠ encode 4 0x37d5fe99 := by decide
  have h2 : encode 4 0x13ae8460 ≠ encode 4 0xef6c064c := by decide
  have h3 : encode 4 0x13ae8460 ≠ encode 4 0x5a2031f9 := by decide
  have h4 : encode 4 0x13ae8460 ≠ encode 4 0xd0fb84e8 := by decide
  have h5 : encode 4 0x13ae8460 ≠ encode 4 0x2b95b781 := by decide
  have h6 : encode 4 0x13ae8460 ≠ encode 4 0x72f79b13 := by decide
  simp [call, external, OracleCalls.external, QueueCalls.external, Locator.dispatch,
    Queue.dispatch, Oracle.dispatch, Router.dispatch, Router.receiveDepositableEther,
    h1, h2, h3, h4, h5, h6, ha, hc, Nat.not_lt.mpr hb]

theorem receiver_shortage (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount : Word)
    (hc : (w.core.codeSize c.contracts.router.val).val ≠ 0)
    (hb : w.balances ctx.self < amount.val) :
    call (external k c staticOther other) ctx c.contracts.router 0x13ae8460 amount w =
      ⟨.error (.bubbled []), w,
        [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, [], []⟩]⟩ := by
  simp [call, hc, hb]

/-- Concrete receiver rejection rolls back the whole withdrawal, including
all spending and seed writes/events and the attempted ETH credit. -/
theorem rejected (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount seeds : Word)
    (demand reference deadline time : Nat) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved)
    (hf : Consensus.compute c.frame (prepared ctx amount w demand).core.blockTimestamp.val
      ((prepared ctx amount w demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((spent ctx amount w demand reference).core.readContractSlot ctx.self.val seedSlot).val % width +
      seeds.val < Verity.Core.UINT256_MODULUS)
    (hfunds : amount.val ≤ w.balances ctx.self)
    (hlido : ctx.self ≠ c.lido) (hrcode : (w.core.codeSize c.contracts.router.val).val ≠ 0) :
    run (withdrawDepositableEther (external k c staticOther other) ctx amount seeds) w =
      ⟨.error (.bubbled Router.notAuthorized), w,
        statusTrace c ctx w ++ routerTrace c ctx ++ allocationTrace c ctx demand ++
          frameTrace c ctx reference deadline time ++
          [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, Router.notAuthorized, []⟩]⟩ := by
  have hs := seed_result ctx seeds (spent ctx amount w demand reference) hseed
  have hc := receiver_rejection k c staticOther other ctx
    (seeded ctx seeds (spent ctx amount w demand reference)) amount hlido
    (by simpa only [final_code] using hrcode)
    (by simpa only [final_balances] using hfunds)
  have htail : WithdrawalTail.finish (external k c staticOther other) ctx c.contracts.router
      amount seeds (spent ctx amount w demand reference) =
      ⟨.error (.bubbled Router.notAuthorized), seeded ctx seeds (spent ctx amount w demand reference),
        [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, Router.notAuthorized, []⟩]⟩ := by
    simp [WithdrawalTail.finish, bind, bindExec, hs, hc]
  have hparent := before_tail k c staticOther other ctx w amount seeds demand reference deadline time
    b hb hp hauth hn hq hamount hf ht
  simp only [htail] at hparent
  unfold run
  rw [hparent]

/-- CALL balance failure is checked against the original account balance,
which all preceding source getters and accounting/seed writes preserve. -/
theorem shortage (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount seeds : Word)
    (demand reference deadline time : Nat) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved)
    (hf : Consensus.compute c.frame (prepared ctx amount w demand).core.blockTimestamp.val
      ((prepared ctx amount w demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((spent ctx amount w demand reference).core.readContractSlot ctx.self.val seedSlot).val % width +
      seeds.val < Verity.Core.UINT256_MODULUS)
    (hfunds : w.balances ctx.self < amount.val)
    (hrcode : (w.core.codeSize c.contracts.router.val).val ≠ 0) :
    run (withdrawDepositableEther (external k c staticOther other) ctx amount seeds) w =
      ⟨.error (.bubbled []), w,
        statusTrace c ctx w ++ routerTrace c ctx ++ allocationTrace c ctx demand ++
          frameTrace c ctx reference deadline time ++
          [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, [], []⟩]⟩ := by
  have hs := seed_result ctx seeds (spent ctx amount w demand reference) hseed
  have hc := receiver_shortage k c staticOther other ctx
    (seeded ctx seeds (spent ctx amount w demand reference)) amount
    (by simpa only [final_code] using hrcode)
    (by simpa only [final_balances] using hfunds)
  have htail : WithdrawalTail.finish (external k c staticOther other) ctx c.contracts.router
      amount seeds (spent ctx amount w demand reference) =
      ⟨.error (.bubbled []), seeded ctx seeds (spent ctx amount w demand reference),
        [⟨⟨ctx.self, c.contracts.router, amount, encode 4 0x13ae8460⟩, false, [], []⟩]⟩ := by
    simp [WithdrawalTail.finish, bind, bindExec, hs, hc]
  have hparent := before_tail k c staticOther other ctx w amount seeds demand reference deadline time
    b hb hp hauth hn hq hamount hf ht
  simp only [htail] at hparent
  unfold run
  rw [hparent]

end LidoSRv3.Audit.Source.TrioReserve1.Pipeline
