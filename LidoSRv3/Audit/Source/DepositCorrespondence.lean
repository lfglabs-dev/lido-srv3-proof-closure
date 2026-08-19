import LidoSRv3.Audit.Trace

/-!
Pinned source correspondence for the SRv3 deposit beacon-chain push at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

Four spans make up the pinned deposit path:

* `contracts/0.8.25/sr/StakingRouter.sol`, `deposit`, lines 942--997 -- the
  entry point. It first authenticates the caller against the locator-derived
  DepositSecurityModule at lines 943 and 1173--1179, then rejects an inactive module (line 946), computes
  `maxDepositsCount` (lines 954--957) and rejects zero (line 959), obtains the
  key batch (lines 962--963), rejects a misaligned pubkey batch (line 966),
  derives `actualDepositsCount` (line 967) and rejects an over-target module
  return (line 969), computes `depositsValue = actualDepositsCount *
  MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (line 972), commits the reentrancy-guard
  state update (line 976), returns early on an empty batch (line 978), snapshots
  `address(this).balance` (line 980), pulls `depositsValue` from Lido (line 983),
  pushes to the beacon deposit contract (lines 985--991), and asserts the router
  balance is unchanged (lines 993--996).
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886 -- the
  pull side.  It rejects a stopped/bunkered protocol (line 870), rejects a zero
  amount (line 873), spends the depositable buffer through
  `_spendDepositableEther` (line 875), and forwards exactly `_amount` wei to the
  router (line 885).
* `contracts/0.4.24/Lido.sol`, `_spendDepositableEther`, lines 839--859 -- the
  internal buffer update.  It computes the available depositable ether (line
  841), rejects an amount larger than that buffer (line 842), and applies the
  accounting update (lines 844--858).
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`,
  `makeBeaconChainDeposits32ETH`, lines 36--64 -- the push side.  It rejects a
  pubkey batch whose length is not `PUBLIC_KEY_LENGTH * _keysCount` (lines
  43--45) and a signature batch whose length is not `SIGNATURE_LENGTH *
  _keysCount` (lines 46--48), then sends exactly `DEPOSIT_SIZE` wei per key in
  the loop at lines 53--63.

`run` below is the source-shaped presentation of that control flow: it returns
the *first* guard that fires, matching Solidity's sequential evaluation, and
otherwise the committed push. Caller authentication is an external locator/app
fact outside this data-only model; the line 996 `assert` is one of the modelled guards: a
failing `assert` is a `Panic(0x01)` revert under Solidity 0.8, so a deployment
that pulls a different amount than it pushes aborts the whole transaction rather
than stranding the difference in the router.  `Outcome.pulled` and
`Outcome.pushed` are the wei actually moved in from Lido (line 983 / `Lido.sol`
line 885) and out to the deposit contract (`BeaconChainDepositor.sol` line 57).

Scope.  This module covers the deposit-path conservation and revert structure
only.  It makes no claim about the allocation amounts feeding
`_getModuleDepositAllocation` (that slice is P-ALLOC-1/P-ALLOC-2), about the
top-up path `makeBeaconChainTopUp` (`BeaconChainDepositor.sol` lines 66--108,
P-TOPUP-1), about SSZ deposit-data roots (P-SSZ-1), or about Yul or
deployed-bytecode behaviour.

Arithmetic. Solidity `uint256` `+`, `-`, `*`, and `/` are modelled by unbounded
`Nat` operations. Locator-derived DSM authentication is not represented in this
data-only model. `Nat` division truncates exactly as EVM `DIV` does, but the
`Nat` encoding cannot observe `uint256` overflow, so this is a correspondence
under the no-overflow reading of the pinned spans, recorded as `A-SOURCE-SHAPED`
in `audit/assumptions.yaml`.  Storage reads, the `IStakingModule.obtainDepositData`
external call at line 963, the `IDepositContract.deposit` external call at
`BeaconChainDepositor.sol` line 57, memory allocation, and the BLS/SSZ contents
of the batches are interface facts, not modelled here.

Conservation caveat.  `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is a constructor
immutable (`StakingRouter.sol` line 65, assigned at line 105), not a compile-time
constant, while `DEPOSIT_SIZE` is the literal `32 ether`
(`BeaconChainDepositor.sol` line 24).  A deployment that sets them apart is a
real possibility, and `pulled_eq_pushed_iff_conserving` shows the pull and the
push agree *exactly when* the deployment satisfies `ConservingConfig`: the line
996 assert is load-bearing.  Because that assert is modelled as the revert it is,
a non-conserving deployment never reaches a committed push --
`committed_implies_conserving` -- so whole-path conservation (`run_conserves`)
holds for every configuration rather than only under `ConservingConfig`.

Rollback caveat.  The pinned path contains no `try`/`catch` and no failure-
swallowing low-level call, so every guard listed above aborts the whole
transaction.  The early `return` at line 978 is deliberately *not* a rollback:
the reentrancy-guard write at line 976 has already committed by then, and
`committedNoDeposits` records that honestly.
-/

namespace LidoSRv3.Audit.SolidityDeposit

open LidoSRv3.Audit

/--
The pinned deposit-path constants.  Each field names the exact source
declaration it stands for.
-/
structure SourceDepositConfig where
  /-- `StakingRouter.MAX_EFFECTIVE_BALANCE_WC_TYPE_01`, declared at source line
  65 and read at lines 956 and 972. -/
  maxEBType1 : Nat
  /-- `BeaconChainDepositor.DEPOSIT_SIZE`, source line 24, the per-key value sent
  at source line 57. -/
  depositSize : Nat
  /-- `StakingRouter.PUBKEY_LENGTH`, source line 57, the divisor at source lines
  966 and 967. -/
  pubkeyLength : Nat
  /-- `BeaconChainDepositor.PUBLIC_KEY_LENGTH`, source line 21, checked at source
  line 43. -/
  publicKeyLength : Nat
  /-- `BeaconChainDepositor.SIGNATURE_LENGTH`, source line 22, checked at source
  line 46. -/
  signatureLength : Nat
  deriving Repr, DecidableEq

/--
Per-call data the pinned deposit path reads.  Each field names the exact source
expression it stands for.
-/
structure SourceDepositInput where
  /-- `stateConfig.status == StakingModuleStatus.Active`, source line 946. -/
  moduleActive : Bool
  /-- `state.deposits.maxDepositsPerBlock`, source line 955. -/
  maxDepositsPerBlock : Nat
  /-- `_getModuleDepositAllocation(...)`, source lines 952--953. -/
  moduleDepositableEth : Nat
  /-- `publicKeysBatch.length` from `obtainDepositData`, source lines 963--967. -/
  publicKeysBatchLength : Nat
  /-- `signaturesBatch.length` from `obtainDepositData`, source line 963, checked
  at `BeaconChainDepositor.sol` line 46. -/
  signaturesBatchLength : Nat
  /-- `etherBalanceBeforeDeposits = address(this).balance`, source line 980. -/
  routerBalanceBefore : Nat
  /-- `Lido.canDeposit()`, `Lido.sol` line 870. -/
  lidoCanDeposit : Bool
  /-- `_getDepositableEther(allocation)`, `Lido.sol` line 841, compared at line
  842. -/
  lidoDepositableEther : Nat
  deriving Repr, DecidableEq

/--
The branch the pinned deposit path takes.  Every `revert*` constructor names the
exact source revert it stands for; the two `committed*` constructors are the two
paths that leave state changes behind.
-/
inductive Outcome
  /-- `revert StakingModuleNotActive()`, source line 946. -/
  | revertStakingModuleNotActive
  /-- Solidity arithmetic panic from division by a zero
  `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`, source line 956. -/
  | revertMaxDepositsDivisionByZero
  /-- `revert ZeroDeposits()`, source line 959. -/
  | revertZeroDeposits
  /-- Solidity arithmetic panic from modulo by a zero `PUBKEY_LENGTH`, source
  line 966. -/
  | revertPubkeyModuloByZero
  /-- `revert WrongPubkeyLength()`, source line 966. -/
  | revertWrongPubkeyLength
  /-- `revert ModuleReturnExceedTarget()`, source line 969. -/
  | revertModuleReturnExceedTarget
  /-- `require(canDeposit(), "CAN_NOT_DEPOSIT")`, `Lido.sol` line 870. -/
  | revertLidoCannotDeposit
  /-- `require(_amount != 0, "ZERO_AMOUNT")`, `Lido.sol` line 873. -/
  | revertLidoZeroAmount
  /-- `require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER")`,
  `Lido.sol` line 842. -/
  | revertLidoNotEnoughEther
  /-- `revert InvalidPublicKeysBatchLength(...)`, `BeaconChainDepositor.sol`
  lines 43--45. -/
  | revertInvalidPublicKeysBatchLength
  /-- `revert InvalidSignaturesBatchLength(...)`, `BeaconChainDepositor.sol`
  lines 46--48. -/
  | revertInvalidSignaturesBatchLength
  /-- The value transfer at `BeaconChainDepositor.sol` line 57 reverts when
  the router cannot fund the deposit loop. -/
  | revertInsufficientRouterBalance
  /-- `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)`, source
  lines 993--996.  Under Solidity 0.8 a failing `assert` is a `Panic(0x01)` that
  aborts the whole transaction, so this is a revert like every guard above it --
  not a commit that leaves the difference stranded in the router. -/
  | revertAssertBalanceUnchanged
  /-- The early `return` at source line 978, reached after the committed
  reentrancy-guard write at source line 976.  This is a commit, not a rollback. -/
  | committedNoDeposits
  /-- The full push at source lines 980--996, carrying the key count, the wei
  pulled from Lido, the wei pushed to the deposit contract, and the router
  balance the line 996 assert observes. -/
  | committedDeposits (keys pulled pushed balanceAfter : Nat)
  deriving Repr, DecidableEq

/-- `maxDepositsCount`, source lines 954--957. -/
def maxDepositsCount (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Nat :=
  min inp.maxDepositsPerBlock (inp.moduleDepositableEth / cfg.maxEBType1)

/-- `actualDepositsCount = publicKeysBatch.length / PUBKEY_LENGTH`, source line 967. -/
def actualDepositsCount (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Nat :=
  inp.publicKeysBatchLength / cfg.pubkeyLength

/-- `depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01`,
source line 972; the amount pulled from Lido at source line 983. -/
def depositsValue (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Nat :=
  actualDepositsCount cfg inp * cfg.maxEBType1

/-- The wei the deposit loop at `BeaconChainDepositor.sol` lines 53--63 sends:
one `DEPOSIT_SIZE` transfer per key, at source line 57.  This is the loop's own
accumulation shape, not a closed form. -/
def loopPushed (cfg : SourceDepositConfig) : Nat → Nat
  | 0 => 0
  | n + 1 => loopPushed cfg n + cfg.depositSize

/-- The wei pushed to the beacon deposit contract for one `deposit` call. -/
def pushedValue (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Nat :=
  loopPushed cfg (actualDepositsCount cfg inp)

/-- `etherBalanceAfterDeposits`, the `address(this).balance` read at source line
993: the line 980 snapshot, plus the pull at line 983, minus what the loop at
`BeaconChainDepositor.sol` lines 53--63 sent out. -/
def routerBalanceAfter (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Nat :=
  inp.routerBalanceBefore + depositsValue cfg inp - pushedValue cfg inp

/--
Deployment condition under which the pinned path conserves stake: the router's
immutable type-1 max effective balance (source line 65) is the deposit
contract's fixed `DEPOSIT_SIZE` (`BeaconChainDepositor.sol` line 24).
-/
def ConservingConfig (cfg : SourceDepositConfig) : Prop :=
  cfg.maxEBType1 = cfg.depositSize

instance (cfg : SourceDepositConfig) : Decidable (ConservingConfig cfg) :=
  inferInstanceAs (Decidable (cfg.maxEBType1 = cfg.depositSize))

/--
The pinned deposit path, as a first-guard-wins function.  The guard order is the
source order after locator-derived DSM authentication: the body guards at
lines 946, 959, 966, 969, 978, then the
`Lido.withdrawDepositableEther` guards reached at line 983, then the
`BeaconChainDepositor.makeBeaconChainDeposits32ETH` guards reached at line 985,
and finally the `assert` at line 996.

That last guard is written as `depositsValue ≠ pushedValue` rather than as a
comparison of `routerBalanceAfter` with the line 980 snapshot.  The two readings
coincide whenever the router can cover what the loop sends -- which it always can
on chain, since a transfer of wei the router does not hold reverts inside the
loop -- and `balanceAssert_iff_pulled_eq_pushed` proves that equivalence.  The
pull/push form is preferred here because truncating `Nat` subtraction, unlike a
real balance, can silently bottom out at zero.
-/
def run (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Outcome :=
  if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if cfg.maxEBType1 = 0 then
    .revertMaxDepositsDivisionByZero
  else if maxDepositsCount cfg inp = 0 then
    .revertZeroDeposits
  else if cfg.pubkeyLength = 0 then
    .revertPubkeyModuloByZero
  else if inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0 then
    .revertWrongPubkeyLength
  else if maxDepositsCount cfg inp < actualDepositsCount cfg inp then
    .revertModuleReturnExceedTarget
  else if actualDepositsCount cfg inp = 0 then
    .committedNoDeposits
  else if inp.lidoCanDeposit = false then
    .revertLidoCannotDeposit
  else if depositsValue cfg inp = 0 then
    .revertLidoZeroAmount
  else if inp.lidoDepositableEther < depositsValue cfg inp then
    .revertLidoNotEnoughEther
  else if inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp then
    .revertInvalidPublicKeysBatchLength
  else if inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp then
    .revertInvalidSignaturesBatchLength
  else if inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp then
    .revertInsufficientRouterBalance
  else if depositsValue cfg inp ≠ pushedValue cfg inp then
    .revertAssertBalanceUnchanged
  else
    .committedDeposits (actualDepositsCount cfg inp) (depositsValue cfg inp)
      (pushedValue cfg inp) (routerBalanceAfter cfg inp)

/-- Whether the outcome aborts the whole transaction.  The pinned path has no
`try`/`catch` and no failure-swallowing low-level call, so every `revert*` guard
is a whole-transaction abort. -/
def Outcome.reverts : Outcome → Bool
  | .committedNoDeposits => false
  | .committedDeposits _ _ _ _ => false
  | _ => true

/-- Wei moved from Lido into the router on this branch (source line 983,
`Lido.sol` line 885). -/
def Outcome.pulled : Outcome → Nat
  | .committedDeposits _ pulled _ _ => pulled
  | _ => 0

/-- Wei moved from the router to the beacon deposit contract on this branch
(`BeaconChainDepositor.sol` line 57). -/
def Outcome.pushed : Outcome → Nat
  | .committedDeposits _ _ pushed _ => pushed
  | _ => 0

/-- The deposit loop at `BeaconChainDepositor.sol` lines 53--63 sends exactly
`DEPOSIT_SIZE` per key. -/
theorem loopPushed_eq (cfg : SourceDepositConfig) (n : Nat) :
    loopPushed cfg n = n * cfg.depositSize := by
  induction n with
  | zero => simp [loopPushed]
  | succ n ih => rw [loopPushed, ih, Nat.succ_mul]

/-- The pull at source line 983 and the push at `BeaconChainDepositor.sol` line
57 move the same wei under a conserving deployment. -/
theorem pulled_eq_pushed (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (hCfg : ConservingConfig cfg) :
    depositsValue cfg inp = pushedValue cfg inp := by
  unfold depositsValue pushedValue
  rw [loopPushed_eq, hCfg]

/--
The line 996 assert is load-bearing: for a nonempty key batch the pulled and
pushed wei agree *exactly when* the deployment satisfies `ConservingConfig`.
-/
theorem pulled_eq_pushed_iff_conserving {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hKeys : 0 < actualDepositsCount cfg inp) :
    depositsValue cfg inp = pushedValue cfg inp ↔ ConservingConfig cfg := by
  unfold depositsValue pushedValue ConservingConfig
  rw [loopPushed_eq]
  exact ⟨fun h => Nat.eq_of_mul_eq_mul_left hKeys (by omega), fun h => by rw [h]⟩

/--
The two readings of the line 996 `assert` agree.  Comparing
`etherBalanceAfterDeposits` (source line 993) with the line 980 snapshot is the
same test as comparing the pull with the push, provided the router can cover what
the loop sends -- on chain it always can, because sending wei the router does not
hold reverts inside the loop at `BeaconChainDepositor.sol` line 57.  The side
condition is exactly where truncating `Nat` subtraction stops standing in for a
balance.
-/
theorem balanceAssert_iff_pulled_eq_pushed (cfg : SourceDepositConfig)
    (inp : SourceDepositInput)
    (hCovered : pushedValue cfg inp ≤ inp.routerBalanceBefore + depositsValue cfg inp) :
    routerBalanceAfter cfg inp = inp.routerBalanceBefore
      ↔ depositsValue cfg inp = pushedValue cfg inp := by
  unfold routerBalanceAfter
  refine ⟨fun h => Nat.add_left_cancel ((Nat.sub_eq_iff_eq_add hCovered).1 h), fun h => ?_⟩
  rw [h, Nat.add_sub_cancel]

/--
What a committed push at source lines 980--996 records.  Reaching it means every
guard passed, including the line 996 `assert`, so the pull and the push agree and
the router balance is back at its line 980 snapshot -- with no `ConservingConfig`
hypothesis, because the assert itself rejects the deployments that would violate
it.
-/
theorem committed_deposits_spec {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    keys = actualDepositsCount cfg inp ∧ 0 < actualDepositsCount cfg inp ∧
      pulled = depositsValue cfg inp ∧ pushed = pushedValue cfg inp ∧
      pulled = pushed ∧ balanceAfter = inp.routerBalanceBefore := by
  rw [run] at hRun
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule] at hRun; cases hRun
  rw [if_neg hModule] at hRun
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB] at hRun; cases hRun
  rw [if_neg hMaxEB] at hRun
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax] at hRun; cases hRun
  rw [if_neg hMax] at hRun
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero] at hRun; cases hRun
  rw [if_neg hPubkeyZero] at hRun
  by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hAligned] at hRun; cases hRun
  rw [if_neg hAligned] at hRun
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver] at hRun; cases hRun
  rw [if_neg hOver] at hRun
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · rw [if_pos hKeys] at hRun; cases hRun
  rw [if_neg hKeys] at hRun
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit] at hRun; cases hRun
  rw [if_neg hCanDeposit] at hRun
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount] at hRun; cases hRun
  rw [if_neg hZeroAmount] at hRun
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity] at hRun; cases hRun
  rw [if_neg hLiquidity] at hRun
  by_cases hPublicKeys :
      inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp
  · rw [if_pos hPublicKeys] at hRun; cases hRun
  rw [if_neg hPublicKeys] at hRun
  by_cases hSignatures :
      inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp
  · rw [if_pos hSignatures] at hRun; cases hRun
  rw [if_neg hSignatures] at hRun
  by_cases hFunded : inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp
  · rw [if_pos hFunded] at hRun; cases hRun
  rw [if_neg hFunded] at hRun
  by_cases hAssert : depositsValue cfg inp ≠ pushedValue cfg inp
  · rw [if_pos hAssert] at hRun; cases hRun
  rw [if_neg hAssert] at hRun
  have hEq : depositsValue cfg inp = pushedValue cfg inp := Decidable.of_not_not hAssert
  simp only [Outcome.committedDeposits.injEq] at hRun
  obtain ⟨hKeysEq, hPulled, hPushed, hBalance⟩ := hRun
  refine ⟨hKeysEq.symm, Nat.pos_of_ne_zero hKeys, hPulled.symm, hPushed.symm,
    by rw [← hPulled, ← hPushed, hEq], ?_⟩
  rw [← hBalance]
  unfold routerBalanceAfter
  rw [hEq, Nat.add_sub_cancel]

/--
The `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at source
line 996 holds on the committed-push branch: the router forwards every pulled wei
and keeps none.
-/
theorem committed_balance_preserved {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    pulled = pushed ∧ balanceAfter = inp.routerBalanceBefore :=
  let ⟨_, _, _, _, hMoved, hBalance⟩ := committed_deposits_spec hRun
  ⟨hMoved, hBalance⟩

/--
The line 996 assert is modelled as the gate it is: a non-conserving deployment
cannot reach the committed push at all, so the excess is never left stranded in
the router -- the transaction reverts instead.
-/
theorem committed_implies_conserving {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    ConservingConfig cfg := by
  obtain ⟨-, hKeys, hPulled, hPushed, hMoved, -⟩ := committed_deposits_spec hRun
  exact (pulled_eq_pushed_iff_conserving hKeys).1 (by rw [← hPulled, ← hPushed, hMoved])

/-- Contrapositive of `committed_implies_conserving`: a deployment whose pull
scale differs from `DEPOSIT_SIZE` reverts at source line 996. -/
theorem not_conserving_reverts {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    (hCfg : ¬ ConservingConfig cfg) :
    ∀ keys pulled pushed balanceAfter,
      run cfg inp ≠ .committedDeposits keys pulled pushed balanceAfter :=
  fun _ _ _ _ hRun => hCfg (committed_implies_conserving hRun)

/--
The empty-batch early return at source line 978 is reachable only for a zero key
count -- it is the one non-reverting escape that never reaches the line 996
`assert`.
-/
theorem committedNoDeposits_implies_empty_batch {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hRun : run cfg inp = .committedNoDeposits) :
    actualDepositsCount cfg inp = 0 := by
  rw [run] at hRun
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule] at hRun; cases hRun
  rw [if_neg hModule] at hRun
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB] at hRun; cases hRun
  rw [if_neg hMaxEB] at hRun
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax] at hRun; cases hRun
  rw [if_neg hMax] at hRun
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero] at hRun; cases hRun
  rw [if_neg hPubkeyZero] at hRun
  by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hAligned] at hRun; cases hRun
  rw [if_neg hAligned] at hRun
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver] at hRun; cases hRun
  rw [if_neg hOver] at hRun
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · exact hKeys
  rw [if_neg hKeys] at hRun
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit] at hRun; cases hRun
  rw [if_neg hCanDeposit] at hRun
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount] at hRun; cases hRun
  rw [if_neg hZeroAmount] at hRun
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity] at hRun; cases hRun
  rw [if_neg hLiquidity] at hRun
  by_cases hPublicKeys :
      inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp
  · rw [if_pos hPublicKeys] at hRun; cases hRun
  rw [if_neg hPublicKeys] at hRun
  by_cases hSignatures :
      inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp
  · rw [if_pos hSignatures] at hRun; cases hRun
  rw [if_neg hSignatures] at hRun
  by_cases hFunded : inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp
  · rw [if_pos hFunded] at hRun; cases hRun
  rw [if_neg hFunded] at hRun
  by_cases hAssert : depositsValue cfg inp ≠ pushedValue cfg inp
  · rw [if_pos hAssert] at hRun; cases hRun
  rw [if_neg hAssert] at hRun
  cases hRun

/--
For a *nonempty* key batch a non-conserving deployment genuinely reverts, rather
than merely failing to commit a full push: the only non-reverting escape from the
line 996 `assert` is the empty-batch early return at line 978, and a nonempty
batch excludes it.
-/
theorem not_conserving_nonempty_reverts {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hCfg : ¬ ConservingConfig cfg)
    (hKeys : 0 < actualDepositsCount cfg inp) :
    (run cfg inp).reverts = true := by
  cases hRun : run cfg inp with
  | committedNoDeposits =>
      exact absurd (committedNoDeposits_implies_empty_batch hRun) (Nat.ne_of_gt hKeys)
  | committedDeposits keys pulled pushed balanceAfter =>
      exact absurd (committed_implies_conserving hRun) hCfg
  | _ => rfl

/--
Whole-path stake conservation: on *every* branch of the pinned deposit path --
each revert, the empty-batch commit, and the full push -- the wei pulled from
Lido equals the wei pushed to the beacon deposit contract.  No `ConservingConfig`
hypothesis is needed, because a non-conserving deployment reverts at line 996
instead of committing.
-/
theorem run_conserves (cfg : SourceDepositConfig) (inp : SourceDepositInput) :
    (run cfg inp).pulled = (run cfg inp).pushed := by
  cases hRun : run cfg inp with
  | committedDeposits keys pulled pushed balanceAfter =>
      exact (committed_balance_preserved hRun).1
  | _ => rfl

/-- No wei crosses either boundary on a reverting branch: the pull at source line
983 is strictly after every guard at lines 946--978. -/
theorem reverting_moves_no_ether {o : Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 := by
  cases o <;> simp_all [Outcome.reverts, Outcome.pulled, Outcome.pushed]

/-! ## The line 996 assert is the conservation load-bearer

`mutantRun` is the pinned `run` with exactly one branch removed: the line 996
`assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` guard
(`StakingRouter.sol` lines 993--996), modelled in `run` as the
`depositsValue ≠ pushedValue → .revertAssertBalanceUnchanged` branch.  Every
other guard keeps its source order.  The two characterization theorems pin the
mutation down exactly: where the assert passes the mutant *is* the honest
`run`, and where the honest run hits the assert the mutant instead commits the
push.  The executable falsifier for the registered P-DEPOSIT-1 parent built on
this mutant lives in `LidoSRv3.Tests.DepositVectors`
(`dropped_conservation_assert_breaks_pulled_eq_pushed`). -/

/-- The pinned deposit path with the line 996 conservation assert dropped: a
deployment whose pull scale differs from `DEPOSIT_SIZE` commits the mismatched
push instead of reverting. -/
def mutantRun (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Outcome :=
  if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if cfg.maxEBType1 = 0 then
    .revertMaxDepositsDivisionByZero
  else if maxDepositsCount cfg inp = 0 then
    .revertZeroDeposits
  else if cfg.pubkeyLength = 0 then
    .revertPubkeyModuloByZero
  else if inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0 then
    .revertWrongPubkeyLength
  else if maxDepositsCount cfg inp < actualDepositsCount cfg inp then
    .revertModuleReturnExceedTarget
  else if actualDepositsCount cfg inp = 0 then
    .committedNoDeposits
  else if inp.lidoCanDeposit = false then
    .revertLidoCannotDeposit
  else if depositsValue cfg inp = 0 then
    .revertLidoZeroAmount
  else if inp.lidoDepositableEther < depositsValue cfg inp then
    .revertLidoNotEnoughEther
  else if inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp then
    .revertInvalidPublicKeysBatchLength
  else if inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp then
    .revertInvalidSignaturesBatchLength
  else if inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp then
    .revertInsufficientRouterBalance
  else
    .committedDeposits (actualDepositsCount cfg inp) (depositsValue cfg inp)
      (pushedValue cfg inp) (routerBalanceAfter cfg inp)

/-- The mutation is surgical: wherever the line 996 assert passes, the mutant
coincides with the honest `run`, branch for branch. -/
theorem mutantRun_eq_run_of_assert_passing {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (h : depositsValue cfg inp = pushedValue cfg inp) :
    mutantRun cfg inp = run cfg inp := by
  rw [mutantRun, run]
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule, if_pos hModule]
  rw [if_neg hModule, if_neg hModule]
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB, if_pos hMaxEB]
  rw [if_neg hMaxEB, if_neg hMaxEB]
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax, if_pos hMax]
  rw [if_neg hMax, if_neg hMax]
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero, if_pos hPubkeyZero]
  rw [if_neg hPubkeyZero, if_neg hPubkeyZero]
  by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hAligned, if_pos hAligned]
  rw [if_neg hAligned, if_neg hAligned]
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver, if_pos hOver]
  rw [if_neg hOver, if_neg hOver]
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · rw [if_pos hKeys, if_pos hKeys]
  rw [if_neg hKeys, if_neg hKeys]
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit, if_pos hCanDeposit]
  rw [if_neg hCanDeposit, if_neg hCanDeposit]
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount, if_pos hZeroAmount]
  rw [if_neg hZeroAmount, if_neg hZeroAmount]
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity, if_pos hLiquidity]
  rw [if_neg hLiquidity, if_neg hLiquidity]
  by_cases hPublicKeys :
      inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp
  · rw [if_pos hPublicKeys, if_pos hPublicKeys]
  rw [if_neg hPublicKeys, if_neg hPublicKeys]
  by_cases hSignatures :
      inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp
  · rw [if_pos hSignatures, if_pos hSignatures]
  rw [if_neg hSignatures, if_neg hSignatures]
  by_cases hFunded : inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp
  · rw [if_pos hFunded, if_pos hFunded]
  rw [if_neg hFunded, if_neg hFunded]
  rw [if_neg (not_not_intro h)]

/-- And the mutation bites exactly where the honest run hits the line 996
assert: there, and only there, the mutant commits the push the honest run
rolls back. -/
theorem mutantRun_commits_where_assert_fires {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hRun : run cfg inp = .revertAssertBalanceUnchanged) :
    mutantRun cfg inp = .committedDeposits (actualDepositsCount cfg inp)
      (depositsValue cfg inp) (pushedValue cfg inp) (routerBalanceAfter cfg inp) := by
  rw [run] at hRun
  rw [mutantRun]
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule] at hRun; cases hRun
  rw [if_neg hModule] at hRun; rw [if_neg hModule]
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB] at hRun; cases hRun
  rw [if_neg hMaxEB] at hRun; rw [if_neg hMaxEB]
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax] at hRun; cases hRun
  rw [if_neg hMax] at hRun; rw [if_neg hMax]
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero] at hRun; cases hRun
  rw [if_neg hPubkeyZero] at hRun; rw [if_neg hPubkeyZero]
  by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hAligned] at hRun; cases hRun
  rw [if_neg hAligned] at hRun; rw [if_neg hAligned]
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver] at hRun; cases hRun
  rw [if_neg hOver] at hRun; rw [if_neg hOver]
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · rw [if_pos hKeys] at hRun; cases hRun
  rw [if_neg hKeys] at hRun; rw [if_neg hKeys]
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit] at hRun; cases hRun
  rw [if_neg hCanDeposit] at hRun; rw [if_neg hCanDeposit]
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount] at hRun; cases hRun
  rw [if_neg hZeroAmount] at hRun; rw [if_neg hZeroAmount]
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity] at hRun; cases hRun
  rw [if_neg hLiquidity] at hRun; rw [if_neg hLiquidity]
  by_cases hPublicKeys :
      inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp
  · rw [if_pos hPublicKeys] at hRun; cases hRun
  rw [if_neg hPublicKeys] at hRun; rw [if_neg hPublicKeys]
  by_cases hSignatures :
      inp.signaturesBatchLength ≠ cfg.signatureLength * actualDepositsCount cfg inp
  · rw [if_pos hSignatures] at hRun; cases hRun
  rw [if_neg hSignatures] at hRun; rw [if_neg hSignatures]
  by_cases hFunded : inp.routerBalanceBefore + depositsValue cfg inp < pushedValue cfg inp
  · rw [if_pos hFunded] at hRun; cases hRun
  rw [if_neg hFunded] at hRun
  by_cases hAssert : depositsValue cfg inp ≠ pushedValue cfg inp
  · rw [if_pos hAssert] at hRun; rw [if_neg hFunded]
  rw [if_neg hAssert] at hRun; cases hRun

/--
`Lido.withdrawDepositableEther`'s `ZERO_AMOUNT` guard (`Lido.sol` line 873) is
unreachable from `StakingRouter.deposit`: the empty-batch early return at source
line 978 already excluded a zero key count, and a zero
`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` would already have panicked the division at
source line 956.
-/
theorem lidoZeroAmount_unreachable {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    (hCfg : cfg.maxEBType1 ≠ 0) (hKeys : 0 < actualDepositsCount cfg inp) :
    depositsValue cfg inp ≠ 0 := by
  unfold depositsValue
  exact Nat.mul_ne_zero (by omega) hCfg

/--
`BeaconChainDepositor`'s `InvalidPublicKeysBatchLength` guard (source lines
43--45) is discharged by the router's own alignment check at source lines
966--967, provided the two pubkey-length constants agree
(`StakingRouter.PUBKEY_LENGTH` line 57 and
`BeaconChainDepositor.PUBLIC_KEY_LENGTH` line 21 are both 48).
-/
theorem publicKeysBatchLength_guard_discharged {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hLengths : cfg.publicKeyLength = cfg.pubkeyLength)
    (hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength = 0) :
    inp.publicKeysBatchLength = cfg.publicKeyLength * actualDepositsCount cfg inp := by
  unfold actualDepositsCount
  rw [hLengths, Nat.mul_comm]
  exact (Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero hAligned)).symm

/-- Consequently the pinned path never reaches the `InvalidPublicKeysBatchLength`
revert. -/
theorem run_ne_invalidPublicKeysBatchLength {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} (hLengths : cfg.publicKeyLength = cfg.pubkeyLength) :
    run cfg inp ≠ .revertInvalidPublicKeysBatchLength := by
  rw [run]
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule]; intro h; cases h
  rw [if_neg hModule]
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB]; intro h; cases h
  rw [if_neg hMaxEB]
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax]; intro h; cases h
  rw [if_neg hMax]
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero]; intro h; cases h
  rw [if_neg hPubkeyZero]
  by_cases hMisaligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hMisaligned]; intro h; cases h
  rw [if_neg hMisaligned]
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver]; intro h; cases h
  rw [if_neg hOver]
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · rw [if_pos hKeys]; intro h; cases h
  rw [if_neg hKeys]
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit]; intro h; cases h
  rw [if_neg hCanDeposit]
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount]; intro h; cases h
  rw [if_neg hZeroAmount]
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity]; intro h; cases h
  rw [if_neg hLiquidity]
  have hOK : inp.publicKeysBatchLength = cfg.publicKeyLength * actualDepositsCount cfg inp :=
    publicKeysBatchLength_guard_discharged hLengths (Decidable.of_not_not hMisaligned)
  rw [if_neg (by simp [hOK])]
  split; · simp
  split; · simp
  split <;> simp

/--
The abstract transaction observation the pinned outcome produces: a reverting
guard yields the model's `.reverted` result, and the two committing branches
yield `.committed`.
-/
def observation {State : Type} (before after : State) (attempts : List CallAttempt)
    (trace : CommitTrace) (o : Outcome) : TxObservation State :=
  ⟨before, attempts, if o.reverts then .reverted else .committed after trace⟩

/--
Rollback correspondence: because every pinned guard aborts the whole
transaction, the model's `revert_restores_state_value_and_logs` applies directly
to the source-shaped outcome -- pre-state restored, no committed ETH movement,
no committed logs.
-/
theorem reverting_outcome_rolls_back {State : Type} (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) {o : Outcome}
    (h : o.reverts = true) :
    (observation before after attempts trace o).committedState = before ∧
      (observation before after attempts trace o).committedTrace.ethMoves = [] ∧
      (observation before after attempts trace o).committedTrace.logs = [] :=
  revert_restores_state_value_and_logs (observation before after attempts trace o)
    (by simp [observation, h])

/--
The empty-batch early return at source line 978 is honestly *not* a rollback: the
reentrancy-guard write at source line 976 has already committed, so the model
observation stays on the committed branch.
-/
theorem committedNoDeposits_is_not_a_rollback {State : Type} (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) :
    (observation before after attempts trace .committedNoDeposits).result
      = .committed after trace := by
  simp [observation, Outcome.reverts]

end LidoSRv3.Audit.SolidityDeposit
