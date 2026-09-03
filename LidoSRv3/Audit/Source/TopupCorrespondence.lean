import LidoSRv3.Audit.Trace

/-!
Pinned source correspondence for the SRv3 beacon-chain *top-up* push at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

This is the transactionally distinct sibling of the 32-ETH deposit path modelled
in `LidoSRv3.Audit.Source.DepositCorrespondence`.  Where that path pushes a fixed
`DEPOSIT_SIZE` per key through `makeBeaconChainDeposits32ETH`, the top-up path
pushes a *per-key variable amount* through `IDepositContract.deposit` with an
all-zero signature, topping validator balances above 32 ETH.

Six groups of pinned spans make up the top-up path; every one of them is listed
in `audit/source-map.yaml` under `P-TOPUP-1`, including the transitive helpers
that carry the guards modelled below and the constant declarations that
`pinnedConfig` reads:

* `contracts/0.8.25/sr/StakingRouter.sol`, `topUp`, lines 679--759 -- the entry
  point.  It rejects a caller other than the top-up gateway (line 686, via
  `_getTopUpGateway` at lines 1169--1171 and `_checkAppAuth` at lines
  1177--1179), validates the input arrays (line 687, body at
  lines 761--782), rejects an unregistered module (line 689, via
  `_getModuleState` at lines 1099--1107, which calls
  `SRUtils._requireModuleIdExists` at `SRUtils.sol` lines 45--47 from line
  1104), rejects an
  inactive module (line 691), rejects a module whose withdrawal-credentials type
  is not 0x02 (line 694, via `SRUtils._requireWCType2` at `SRUtils.sol` lines
  41--43), computes the per-block cap (line 696), the module allocation (line
  700) and its gwei-rounded form (line 706), rejects a paused Lido on the
  zero-allocation path (lines 713--715), obtains the per-key allocation from the
  module (lines 717--718), sums it under the per-index guards of the loop at
  lines 722--734, rejects an over-target module return (lines 737--739), and --
  only when the sum is positive (line 741) -- snapshots `address(this).balance`
  (line 742), pulls the sum from Lido (line 744), pushes it to the beacon deposit
  contract (line 750), and asserts the router balance is unchanged (lines
  752--755).
* `contracts/0.8.25/sr/StakingRouter.sol`, `_validateTopUpInputs`, lines
  761--782 -- reached from line 687.  It rejects an empty key list (lines
  769--771), arrays whose lengths disagree with `_keyIndices.length` (lines
  773--775), and any pubkey whose length is not `PUBKEY_LENGTH` (line 57) in the
  loop at lines 777--781.
* The three `StakingRouter` helpers reached from `topUp`, plus the two `SRUtils`
  guards they delegate to.  `_getTopUpGateway`, lines 1169--1171, returns
  `LIDO_LOCATOR.topUpGateway()`; `_checkAppAuth`, lines 1177--1179, reverts
  `NotAuthorized` when `_msgSender()` differs from that address -- this is the
  single source site behind `callerIsTopUpGateway` and `revertNotAuthorized`
  below.  `_getModuleState`, lines 1099--1107, calls
  `SRUtils._requireModuleIdExists`, `SRUtils.sol` lines 45--47, which reverts
  `StakingModuleUnregistered` when `SRStorage.isModuleExists(_moduleId)` is
  false -- the site behind `moduleExists`.  `SRUtils._requireWCType2`,
  `SRUtils.sol` lines 41--43, reverts `WrongWithdrawalCredentialsType` when
  `WithdrawalCredentials.isType2(_wcType)` is false -- the site behind
  `wcTypeIsType2`.  The predicates *inside* those helpers
  (`LIDO_LOCATOR.topUpGateway()`, `SRStorage.isModuleExists`,
  `WithdrawalCredentials.isType2`, and the `_msgSender()` comparison) are
  storage/interface facts and stay abstract: the model takes each helper's
  boolean verdict as an input field rather than recomputing it.
* The constant declarations `pinnedConfig` reads: `StakingRouter.PUBKEY_LENGTH`,
  line 57, `BeaconChainDepositor.PUBLIC_KEY_LENGTH`, line 21, and
  `BeaconChainDepositor.MIN_DEPOSIT`, line 28.  They are pinned rather than
  assumed because `pinnedConfig` hard-codes their values, and
  `source_pinned_config_discharges_pubkey_guard` holds only while the first two
  agree; registering the declarations makes a change to either one break the
  source-map gate instead of silently invalidating that theorem.  The remaining
  two fields need no declaration span: `gwei` is a Solidity unit literal and
  `uint64Max` is `type(uint64).max`, read at `BeaconChainDepositor.sol` line 97
  inside the already-pinned lines 66--108.
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886, and
  `_spendDepositableEther`, lines 839--859 -- the pull side, reached from line
  744 with `_seedDepositsCount = 0`.  It rejects a stopped/bunkered protocol
  (line 870), rejects a zero amount (line 873), rejects an amount larger than the
  depositable buffer (line 842), and forwards exactly `_amount` wei to the router
  (line 885).
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `makeBeaconChainTopUp`, lines
  66--108 -- the push side, reached from line 750.  It returns early on an empty
  pubkey list (line 73), rejects a mismatched amount array (line 74), and then in
  the loop at lines 79--107 rejects a pubkey whose length is not
  `PUBLIC_KEY_LENGTH` (lines 82--84), *skips* a zero amount (line 89), rejects an
  amount below `MIN_DEPOSIT` (lines 92--94), rejects an amount whose gwei form
  overflows `uint64` (lines 97--99), and otherwise sends exactly that amount to
  the deposit contract (line 106).

`run` below is the source-shaped presentation of that control flow: it returns
the *first* guard that fires, matching Solidity's sequential evaluation, and
otherwise the committed push.  The two loops are modelled as recursive
first-guard-wins functions over the actual lists, not as scalar counts, because
the whole point of this path is that each key carries its own amount.

Conservation.  This is where the top-up path differs sharply from the deposit
path.  The amount pulled from Lido at line 744 is `amount`, accumulated at line
732 from the very same `allocations` array that line 750 hands to the push loop,
and the push loop sends `_amount[i]` per key at line 106.  So the pull and the
push are two readings of one sum, and `pulled_eq_pushed` proves the *exact* `Nat`
readings agree with *no* deployment-configuration hypothesis at all -- unlike
the deposit path, where `ConservingConfig` related two independent constants
(`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and `DEPOSIT_SIZE`).

The pull is routed through the on-chain `unchecked` semantics.  The
accumulation at line 732 sits inside an `unchecked` block (line 722), so on
chain `amount` is the sum *reduced modulo `2^256`* (`wrappedTotal =
exactTotal % 2^256`, `accumulated`).  The over-target comparison at line 737,
the zero-sum test at line 741, the Lido-side amount guards at `Lido.sol` lines
842/873, the line 744 pull, the funded router balance, and the line 755
`assert` all read that wrapped word.  Under a wrap that is not to zero the
wrapped pull is smaller than the exact pushed total, so the push is
underfunded or the assert fires.  A sum that wraps to exactly zero takes the
line 741 empty commit (`committedNoTopUp`) instead of reverting: wrap
precludes a *value-moving* commit, not every commit.  Under
`NoUncheckedWrap` the wrapped and exact readings coincide
(`totalAllocated_faithful`), the assert can never fire
(`run_ne_revertAssertBalanceUnchanged`), and conservation on the commit branch
is genuinely assert-backed rather than a same-array `Nat` fact.

The bound that rules the wrap out is *not* derivable from the pinned P-TOPUP-1
spans: line 728 caps each allocation by `_topUpLimits[i]`, whose derivation lives
in `TopUpGateway` (P-TOPUP-2, out of scope here), and the key count is not
bounded by any guard on this path.  It is therefore carried explicitly.
`NoUncheckedWrap` below states it as `totalAllocated inp < 2 ^ 256`, and
`allocSumUnchecked_eq_allocSum` proves that under exactly that hypothesis the
source's `unchecked` accumulation and this module's `Nat` sum are the same
number -- so the guard-discharge theorems transfer to the source reading.  The
two guard-discharge theorems take the hypothesis as a linked side condition, and
it is recorded as `A-TOPUP-NOWRAP` in `audit/assumptions.yaml`.  Nothing here
claims the `unchecked` block is safe; it says which fact the source-plane claim
rests on.

The three residual guards now read the same wrapped word the chain reads.
Wrap-to-zero is therefore a no-top-up commit rather than a revert, which is
why the registered wrap fact is `run_wrap_precludes_value_moving_commit`
rather than wrap-implies-revert.

Rollback.  The pinned path contains no `try`/`catch` and no failure-swallowing
low-level call, so every guard listed above aborts the whole transaction.  A
failing `assert` is a Solidity 0.8 `Panic(0x01)`; an out-of-bounds
`_topUpLimits[i]` read at line 728 is a `Panic(0x32)` -- `unchecked` disables
arithmetic wrap checks, not array bounds checks -- and both are whole-transaction
aborts.  The zero-sum path at line 741 is deliberately *not* a rollback: the
`allocateDeposits` module call at lines 717--718 has already committed its queue
cursor by then, and `committedNoTopUp` records that honestly.

Scope.  This module covers the top-up-path conservation and revert structure
only.  It makes no claim about how `TopUpGateway` derives `_topUpLimits`
(P-TOPUP-2), about the allocation amounts returned by `_getModuleDepositAllocation`
or `allocateDeposits` (P-ALLOC-1/P-ALLOC-2), about the deposit-data roots computed
at `BeaconChainDepositor.sol` lines 103--104 (P-SSZ-1), about the 32-ETH deposit
path (P-DEPOSIT-1), or about Yul or deployed-bytecode behaviour.

Arithmetic.  Solidity `uint256` `+`, `-`, `*`, `/` and `%` are modelled by
unbounded `Nat` operations; `Nat` division and modulo truncate exactly as EVM
`DIV`/`MOD` do.  Storage reads, the `IStakingModuleV2.allocateDeposits` external
call at lines 717--718, the `IDepositContract.deposit` external call at
`BeaconChainDepositor.sol` line 106, memory allocation, and the BLS/SSZ contents
of the batches are interface facts, not modelled here.
-/

namespace LidoSRv3.Audit.SolidityTopup

open LidoSRv3.Audit

/--
The pinned top-up-path constants.  Each field names the exact source declaration
it stands for.
-/
structure SourceTopupConfig where
  /-- `StakingRouter.PUBKEY_LENGTH`, source line 57, checked at source line 778. -/
  pubkeyLength : Nat
  /-- `BeaconChainDepositor.PUBLIC_KEY_LENGTH`, `BeaconChainDepositor.sol` line
  21, checked at `BeaconChainDepositor.sol` line 82. -/
  publicKeyLength : Nat
  /-- The Solidity unit literal `1 gwei`, used at source lines 696, 706 and 724
  and at `BeaconChainDepositor.sol` line 96. -/
  gwei : Nat
  /-- `BeaconChainDepositor.MIN_DEPOSIT`, `BeaconChainDepositor.sol` line 28,
  checked at `BeaconChainDepositor.sol` line 92. -/
  minDeposit : Nat
  /-- `type(uint64).max`, the bound at `BeaconChainDepositor.sol` line 97. -/
  uint64Max : Nat
  deriving Repr, DecidableEq

/--
Per-call data the pinned top-up path reads.  Each field names the exact source
expression it stands for.
-/
structure SourceTopupInput where
  /-- Whether `_msgSender()` is the top-up gateway, as `_checkAppAuth` reads it
  at source line 1178 for the argument computed at source line 686.  It runs
  before any other statement of `topUp`. -/
  callerIsTopUpGateway : Bool
  /-- `n = _keyIndices.length`, source line 767. -/
  keyIndicesLength : Nat
  /-- `_operatorIds.length`, compared at source line 773. -/
  operatorIdsLength : Nat
  /-- `_topUpLimits`: its length is compared at source line 773 and its entries
  are the bounds at source line 728. -/
  topUpLimits : List Nat
  /-- `_pubkeys`: its length is compared at source line 773, and each
  `_pubkeys[i].length` is checked at source line 778 and again at
  `BeaconChainDepositor.sol` line 82. -/
  pubkeyLengths : List Nat
  /-- `SRStorage.isModuleExists(_moduleId)`, `SRUtils.sol` line 46, reached from
  source line 689. -/
  moduleExists : Bool
  /-- `stateConfig.status == StakingModuleStatus.Active`, source line 691. -/
  moduleActive : Bool
  /-- `WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)`,
  `SRUtils.sol` line 42, reached from source line 694. -/
  wcTypeIsType2 : Bool
  /-- `SRStorage.getRouterState().maxTopUpPerBlockGwei`, source line 696. -/
  maxTopUpPerBlockGwei : Nat
  /-- `_getModuleDepositAllocation(_stakingModuleId, depositableEther, true)`,
  source line 700.  Its value is the P-ALLOC-1/P-ALLOC-2 slice, so it enters here
  as an input rather than being derived. -/
  moduleAllocationEth : Nat
  /-- `LIDO.canDeposit()`, read at source line 713 and again at `Lido.sol` line
  870. -/
  lidoCanDeposit : Bool
  /-- `allocations`, the per-key wei returned by
  `IStakingModuleV2.allocateDeposits` at source lines 717--718.  This is the one
  array that is both summed at source line 732 and pushed at
  `BeaconChainDepositor.sol` line 106. -/
  allocations : List Nat
  /-- `etherBalanceBeforeDeposits = address(this).balance`, source line 742. -/
  routerBalanceBefore : Nat
  /-- `_getDepositableEther(allocation)`, `Lido.sol` line 841, compared at
  `Lido.sol` line 842. -/
  lidoDepositableEther : Nat
  deriving Repr, DecidableEq

/--
The branch the pinned top-up path takes.  Every `revert*` constructor names the
exact source revert or panic it stands for; the two `committed*` constructors are
the two paths that leave state changes behind.
-/
inductive Outcome
  /-- `revert NotAuthorized()`, source line 1178, reached from the
  `_checkAppAuth(_getTopUpGateway())` at source line 686.  It runs before every
  other statement of `topUp`, so it precedes the input validation at line 687. -/
  | revertNotAuthorized
  /-- `revert EmptyKeysList()`, source lines 769--771. -/
  | revertEmptyKeysList
  /-- `revert ArraysLengthMismatch()`, source lines 773--775. -/
  | revertArraysLengthMismatch
  /-- `revert WrongPubkeyLength()`, source lines 778--780. -/
  | revertWrongPubkeyLength
  /-- `revert StakingModuleUnregistered()`, `SRUtils.sol` line 46, reached from
  source line 689. -/
  | revertStakingModuleUnregistered
  /-- `revert StakingModuleNotActive()`, source line 691. -/
  | revertStakingModuleNotActive
  /-- `revert WrongWithdrawalCredentialsType()`, `SRUtils.sol` line 42, reached
  from source line 694. -/
  | revertWrongWithdrawalCredentialsType
  /-- Solidity arithmetic panic from a modulo by a zero `1 gwei` at source line
  706.  `1 gwei` is a unit literal, so this guard is dead in every real
  deployment; `pinnedConfig_gwei_ne_zero` records that. -/
  | revertGweiModuloByZero
  /-- `revert LidoDepositsPaused()`, source lines 713--715. -/
  | revertLidoDepositsPaused
  /-- `revert AmountNotAlignedToGwei()`, source lines 724--726. -/
  | revertAmountNotAlignedToGwei
  /-- `Panic(0x32)` from the out-of-bounds `_topUpLimits[i]` read at source line
  728, reachable when the module returns more allocations than there are keys.
  The `unchecked` block at source line 722 disables arithmetic wrap checks, not
  array bounds checks, so this really is a whole-transaction abort. -/
  | revertTopUpLimitIndexOutOfBounds
  /-- `revert AllocationExceedsLimit()`, source lines 728--730. -/
  | revertAllocationExceedsLimit
  /-- `revert ModuleReturnExceedTarget()`, source lines 737--739. -/
  | revertModuleReturnExceedTarget
  /-- `require(canDeposit(), "CAN_NOT_DEPOSIT")`, `Lido.sol` line 870, reached
  from source line 744. -/
  | revertLidoCannotDeposit
  /-- `require(_amount != 0, "ZERO_AMOUNT")`, `Lido.sol` line 873. -/
  | revertLidoZeroAmount
  /-- `require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER")`,
  `Lido.sol` line 842. -/
  | revertLidoNotEnoughEther
  /-- `revert ArrayLengthMismatch()`, `BeaconChainDepositor.sol` line 74. -/
  | revertArrayLengthMismatch
  /-- `revert InvalidPublicKeysBatchLength(...)`, `BeaconChainDepositor.sol`
  lines 82--84. -/
  | revertInvalidPublicKeyLength
  /-- `revert DepositAmountTooLow()`, `BeaconChainDepositor.sol` lines 92--94. -/
  | revertDepositAmountTooLow
  /-- `revert AmountTooLarge()`, `BeaconChainDepositor.sol` lines 97--99. -/
  | revertAmountTooLarge
  /-- The value transfer at `BeaconChainDepositor.sol` line 106 reverts when the
  router cannot fund the push loop.  Live exactly on the wrap branch: the router
  holds the line 742 snapshot plus the *wrapped* pull, while the loop sends the
  exact per-key amounts.  Under `NoUncheckedWrap` it is unreachable -- see
  `run_ne_revertInsufficientRouterBalance`. -/
  | revertInsufficientRouterBalance
  /-- `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)`, source
  lines 752--755.  A failing `assert` is a Solidity 0.8 `Panic(0x01)` that aborts
  the whole transaction rather than stranding the difference in the router.
  Load-bearing on a nonzero wrap: a wrapped pull is smaller than the exact
  pushed total, so the assert fires.  Wrap-to-zero never reaches it (line 741
  commits `committedNoTopUp`).  `run_wrap_precludes_value_moving_commit` is
  the honest wrap fact.  Under `NoUncheckedWrap` the assert can never fire --
  see `run_ne_revertAssertBalanceUnchanged`. -/
  | revertAssertBalanceUnchanged
  /-- The zero-sum path: `amount > 0` is false at source line 741, so no pull and
  no push happen and control falls straight through to the event at source line
  758.  This is a commit, not a rollback: the `allocateDeposits` module call at
  source lines 717--718 has already advanced the module's queue cursor. -/
  | committedNoTopUp
  /-- The full push at source lines 741--756, carrying the key count, the wei
  pulled from Lido at source line 744, the wei pushed to the deposit contract by
  the loop at `BeaconChainDepositor.sol` lines 79--107, and the router balance
  the line 755 assert observes. -/
  | committedTopUp (keys pulled pushed balanceAfter : Nat)
  deriving Repr, DecidableEq

/-- `maxTopUpPerBlockWei`, source line 696. -/
def maxTopUpPerBlockWei (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Nat :=
  inp.maxTopUpPerBlockGwei * cfg.gwei

/-- `smDepositableEthAmount`, source line 700. -/
def smDepositableEthAmount (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Nat :=
  min inp.moduleAllocationEth (maxTopUpPerBlockWei cfg inp)

/-- `smDepositableEthAmountRounded`, source line 706. -/
def smDepositableEthAmountRounded (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Nat :=
  smDepositableEthAmount cfg inp - smDepositableEthAmount cfg inp % cfg.gwei

/-- `amount`, accumulated by the loop at source lines 722--734 and pulled from
Lido at source line 744.  This is the loop's own accumulation shape, not a closed
form.

On chain the accumulation at source line 732 is `unchecked` (source line 722), so
a `uint256` sum can wrap; the `Nat` reading here is exact.  See the module
docstring. -/
def allocSum : List Nat → Nat
  | [] => 0
  | a :: as => a + allocSum as

/-- The exact `Nat` reading of `amount`: the unbounded sum the push loop
sends.  Over-target (line 737), zero-sum (line 741), Lido-side amount guards
(`Lido.sol` 842/873), the line 744 pull, and the line 755 assert all read
the wrapped `accumulated` (`wrappedTotal = exactTotal % 2^256`).  The two
readings coincide under `NoUncheckedWrap` (`totalAllocated_faithful`). -/
def totalAllocated (inp : SourceTopupInput) : Nat := allocSum inp.allocations

/-- The `uint256` modulus the `unchecked` block at source line 722 reduces by. -/
def uint256Modulus : Nat := 2 ^ 256

/-- The on-chain reading of the accumulation at source line 732: the same
recursion as `allocSum`, but with each `+=` reduced modulo `2 ^ 256` because the
enclosing block at source line 722 is `unchecked`. -/
def allocSumUnchecked : List Nat → Nat
  | [] => 0
  | a :: as => (a + allocSumUnchecked as) % uint256Modulus

theorem allocSumUnchecked_eq_mod :
    ∀ as : List Nat, allocSumUnchecked as = allocSum as % uint256Modulus
  | [] => by simp [allocSumUnchecked, allocSum]
  | a :: as => by
      rw [allocSumUnchecked, allocSum, allocSumUnchecked_eq_mod as, Nat.add_mod_mod]

/-- The exact `Nat` sum used throughout this module is a faithful reading of the
source's `unchecked` accumulation precisely when the sum stays below `2 ^ 256`.
This is what makes the guard-discharge theorems below transfer from the `Nat`
model to source line 732. -/
theorem allocSumUnchecked_eq_allocSum {as : List Nat}
    (h : allocSum as < uint256Modulus) : allocSumUnchecked as = allocSum as := by
  rw [allocSumUnchecked_eq_mod, Nat.mod_eq_of_lt h]

/-- The on-chain reading of `amount`: the accumulation at source line 732
reduced modulo `2 ^ 256`, as the enclosing `unchecked` block at source line 722
computes it (`wrappedTotal = exactTotal % 2^256`).  Over-target, zero-sum,
Lido-side amount guards, the line 744 pull, the funded router balance, and
the line 755 `assert` all read this word. -/
def accumulated (inp : SourceTopupInput) : Nat := allocSumUnchecked inp.allocations

/-- Alias used in the wrap-plane statement: `wrappedTotal = exactTotal % 2^256`. -/
def wrappedTotal (inp : SourceTopupInput) : Nat := accumulated inp

/-- The no-wrap side condition on one `topUp` call.

It is *not* provable from the pinned P-TOPUP-1 spans -- the per-index cap at
source line 728 comes from `TopUpGateway` (P-TOPUP-2) and the key count is
unbounded on this path -- so it is carried as an explicit hypothesis and recorded
as `A-TOPUP-NOWRAP` in `audit/assumptions.yaml`. -/
def NoUncheckedWrap (inp : SourceTopupInput) : Prop :=
  totalAllocated inp < uint256Modulus

/-- Under `NoUncheckedWrap`, the source's `unchecked` accumulation at line 732
equals `totalAllocated`, the exact `Nat` sum.  After Wave 6 the over-target,
zero-sum, Lido-side, pull, funded-balance, and line-755 guards all read
`accumulated` (`wrappedTotal`); this lemma is the coincidence of those two
readings, not a claim that any remaining guard still reasons about the exact
sum. -/
theorem totalAllocated_faithful {inp : SourceTopupInput} (h : NoUncheckedWrap inp) :
    accumulated inp = totalAllocated inp :=
  allocSumUnchecked_eq_allocSum h

/-- The wei the push loop at `BeaconChainDepositor.sol` lines 79--107 sends: one
transfer of `_amount[i]` per key at line 106, with the `continue` at line 89
skipping zero amounts.  This is the loop's own accumulation shape, written with
the skip explicit so that `loopPushed_eq_allocSum` can record that the skip loses
nothing. -/
def loopPushed : List Nat → List Nat → Nat
  | [], _ => 0
  | _ :: _, [] => 0
  | _ :: ps, a :: as => (if a = 0 then 0 else a) + loopPushed ps as

/-- The wei pushed to the beacon deposit contract for one `topUp` call. -/
def pushedValue (inp : SourceTopupInput) : Nat :=
  loopPushed inp.pubkeyLengths inp.allocations

/-- `etherBalanceAfterDeposits`, the `address(this).balance` read at source line
752: the line 742 snapshot, plus the *wrapped* pull at line 744, minus what the
loop at `BeaconChainDepositor.sol` lines 79--107 sent out. -/
def routerBalanceAfter (inp : SourceTopupInput) : Nat :=
  inp.routerBalanceBefore + accumulated inp - pushedValue inp

/--
The router's allocation loop, source lines 722--734, as a first-guard-wins
function: it returns the first index whose guard fires, or `none` if the whole
loop runs to completion.

The second pattern is the out-of-bounds `_topUpLimits[i]` read at source line
728, reached when the module returns more allocations than there are keys.  It
sits *after* the alignment check at source line 724 for the same index, because
that is the order the two statements appear in.
-/
def allocationLoop (cfg : SourceTopupConfig) : List Nat → List Nat → Option Outcome
  | [], _ => none
  | a :: _, [] =>
      if a % cfg.gwei ≠ 0 then some .revertAmountNotAlignedToGwei
      else some .revertTopUpLimitIndexOutOfBounds
  | a :: as, l :: ls =>
      if a % cfg.gwei ≠ 0 then some .revertAmountNotAlignedToGwei
      else if l < a then some .revertAllocationExceedsLimit
      else allocationLoop cfg as ls

/--
The push loop, `BeaconChainDepositor.sol` lines 79--107, as a first-guard-wins
function.  The `continue` at line 89 is the `a = 0` branch: it skips the
`MIN_DEPOSIT` and `uint64` guards for that index rather than reverting, which is
why a zero allocation is *not* a `DepositAmountTooLow`.

The second pattern is unreachable: the `ArrayLengthMismatch` guard at
`BeaconChainDepositor.sol` line 74 has already equalised the two lists.
-/
def pushLoop (cfg : SourceTopupConfig) : List Nat → List Nat → Option Outcome
  | [], _ => none
  | _ :: _, [] => none
  | p :: ps, a :: as =>
      if p ≠ cfg.publicKeyLength then some .revertInvalidPublicKeyLength
      else if a = 0 then pushLoop cfg ps as
      else if a < cfg.minDeposit then some .revertDepositAmountTooLow
      else if cfg.uint64Max < a / cfg.gwei then some .revertAmountTooLarge
      else pushLoop cfg ps as

/--
The pull-and-push tail of the pinned path, as a first-guard-wins function: the
`LIDO.withdrawDepositableEther(amount)` call at source line 744 (`Lido.sol` lines
869--886, delegating to `_spendDepositableEther` at `Lido.sol` lines 839--859),
then the `makeBeaconChainTopUp` call at source line 750
(`BeaconChainDepositor.sol` lines 66--108), then the `assert` at source line 755.

Split out from `run` because it is the tail that actually moves wei; every guard
before it is a pure rejection.

The value-moving readings are the on-chain `unchecked` ones: the Lido-side
amount guards (`Lido.sol` lines 842/873), the line 744 pull, the funded
router balance, and the line 755 `assert` all read `accumulated inp`
(`wrappedTotal = exactTotal % 2^256`).

The `BeaconChainDepositor.sol` line 73 early return is not a separate branch: the
line 769 and line 773 guards have already forced `_publicKeys.length = n ≠ 0` by
the time line 750 is reached, and `committed_pubkeys_nonempty` records that.
-/
def runPush (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.lidoCanDeposit = false then
    .revertLidoCannotDeposit
  else if accumulated inp = 0 then
    .revertLidoZeroAmount
  else if inp.lidoDepositableEther < accumulated inp then
    .revertLidoNotEnoughEther
  else if inp.pubkeyLengths.length ≠ inp.allocations.length then
    .revertArrayLengthMismatch
  else match pushLoop cfg inp.pubkeyLengths inp.allocations with
    | some o => o
    | none =>
      if inp.routerBalanceBefore + accumulated inp < pushedValue inp then
        .revertInsufficientRouterBalance
      else if accumulated inp ≠ pushedValue inp then
        .revertAssertBalanceUnchanged
      else
        .committedTopUp inp.pubkeyLengths.length (accumulated inp) (pushedValue inp)
          (routerBalanceAfter inp)

/--
The pinned top-up path, as a first-guard-wins function.  The guard order is the
source order: `_checkAppAuth` at line 686, the `_validateTopUpInputs` guards at
lines 769/773/778, the module guards at lines 689/691/694, the gwei modulo at
line 706, the paused-Lido guard at line 713, the allocation-loop guards at lines
724/728, the over-target guard at line 737, the zero-sum short circuit at line
741, and then `runPush` for the value-moving tail at lines 742--756.
-/
def run (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.callerIsTopUpGateway = false then
    .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then
    .revertEmptyKeysList
  else if inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength then
    .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) then
    .revertWrongPubkeyLength
  else if inp.moduleExists = false then
    .revertStakingModuleUnregistered
  else if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if inp.wcTypeIsType2 = false then
    .revertWrongWithdrawalCredentialsType
  else if cfg.gwei = 0 then
    .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false then
    .revertLidoDepositsPaused
  else match allocationLoop cfg inp.allocations inp.topUpLimits with
    | some o => o
    | none =>
      if smDepositableEthAmountRounded cfg inp < accumulated inp then
        .revertModuleReturnExceedTarget
      else if accumulated inp = 0 then
        .committedNoTopUp
      else
        runPush cfg inp

/-- Whether the outcome aborts the whole transaction.  The pinned path has no
`try`/`catch` and no failure-swallowing low-level call, so every `revert*` guard
-- including the two Solidity panics -- is a whole-transaction abort. -/
def Outcome.reverts : Outcome → Bool
  | .committedNoTopUp => false
  | .committedTopUp _ _ _ _ => false
  | _ => true

/-- Wei moved from Lido into the router on this branch (source line 744,
`Lido.sol` line 885). -/
def Outcome.pulled : Outcome → Nat
  | .committedTopUp _ pulled _ _ => pulled
  | _ => 0

/-- Wei moved from the router to the beacon deposit contract on this branch
(`BeaconChainDepositor.sol` line 106). -/
def Outcome.pushed : Outcome → Nat
  | .committedTopUp _ _ pushed _ => pushed
  | _ => 0

/-- The deployed constants: both pubkey lengths are 48 (`StakingRouter.sol` line
57, `BeaconChainDepositor.sol` line 21), `1 gwei` is `10^9`, `MIN_DEPOSIT` is
`1 ether` (`BeaconChainDepositor.sol` line 28), and the `uint64` bound at
`BeaconChainDepositor.sol` line 97 is `2^64 - 1`. -/
def pinnedConfig : SourceTopupConfig :=
  ⟨48, 48, 1000000000, 1000000000000000000, 18446744073709551615⟩

/-- `1 gwei` is a Solidity unit literal, so the modulo at source line 706 never
panics in the pinned deployment: `revertGweiModuloByZero` is a totality guard for
`Nat`'s total `%`, not a reachable source branch. -/
theorem pinnedConfig_gwei_ne_zero : pinnedConfig.gwei ≠ 0 := by decide

/-- The two pubkey-length constants agree in the pinned deployment. -/
theorem pinnedConfig_pubkey_lengths_agree :
    pinnedConfig.publicKeyLength = pinnedConfig.pubkeyLength := rfl

/-! ## Loop lemmas -/

/-- The allocation loop at source lines 722--734 can only produce its own three
guards: the gwei-alignment revert at line 724, the out-of-bounds `_topUpLimits[i]`
panic at line 728, and the over-limit revert at line 728. -/
theorem allocationLoop_range {cfg : SourceTopupConfig} :
    ∀ (as ls : List Nat) {o : Outcome},
      allocationLoop cfg as ls = some o →
        o = .revertAmountNotAlignedToGwei ∨ o = .revertTopUpLimitIndexOutOfBounds ∨
          o = .revertAllocationExceedsLimit
  | [], _, _, h => by simp [allocationLoop] at h
  | _ :: _, [], _, h => by
      unfold allocationLoop at h
      split at h
      · cases h; exact Or.inl rfl
      · cases h; exact Or.inr (Or.inl rfl)
  | _ :: as, _ :: ls, _, h => by
      unfold allocationLoop at h
      split at h
      · cases h; exact Or.inl rfl
      · split at h
        · cases h; exact Or.inr (Or.inr rfl)
        · exact allocationLoop_range as ls h

/-- Every outcome the allocation loop at source lines 722--734 can produce is a
whole-transaction abort; the loop never commits. -/
theorem allocationLoop_reverts {cfg : SourceTopupConfig} (as ls : List Nat) {o : Outcome}
    (h : allocationLoop cfg as ls = some o) : o.reverts = true := by
  rcases allocationLoop_range as ls h with h | h | h <;> rw [h] <;> rfl

/-- The push loop at `BeaconChainDepositor.sol` lines 79--107 can only produce its
own three guards: the pubkey-length revert at line 83, the `MIN_DEPOSIT` revert at
line 93, and the `uint64` revert at line 98. -/
theorem pushLoop_range {cfg : SourceTopupConfig} :
    ∀ (ps as : List Nat) {o : Outcome},
      pushLoop cfg ps as = some o →
        o = .revertInvalidPublicKeyLength ∨ o = .revertDepositAmountTooLow ∨
          o = .revertAmountTooLarge
  | [], _, _, h => by simp [pushLoop] at h
  | _ :: _, [], _, h => by simp [pushLoop] at h
  | _ :: ps, _ :: as, _, h => by
      unfold pushLoop at h
      split at h
      · cases h; exact Or.inl rfl
      · split at h
        · exact pushLoop_range ps as h
        · split at h
          · cases h; exact Or.inr (Or.inl rfl)
          · split at h
            · cases h; exact Or.inr (Or.inr rfl)
            · exact pushLoop_range ps as h

/-- Every outcome the push loop at `BeaconChainDepositor.sol` lines 79--107 can
produce is a whole-transaction abort; the loop never commits. -/
theorem pushLoop_reverts {cfg : SourceTopupConfig} (ps as : List Nat) {o : Outcome}
    (h : pushLoop cfg ps as = some o) : o.reverts = true := by
  rcases pushLoop_range ps as h with h | h | h <;> rw [h] <;> rfl

/--
`BeaconChainDepositor`'s per-key pubkey-length guard (`BeaconChainDepositor.sol`
lines 82--84) is discharged by the router's own validation loop at source lines
777--781, provided the two constants agree (`StakingRouter.PUBKEY_LENGTH` line 57
and `BeaconChainDepositor.PUBLIC_KEY_LENGTH` line 21 are both 48).
-/
theorem pushLoop_ne_invalidPublicKeyLength {cfg : SourceTopupConfig}
    (hLengths : cfg.publicKeyLength = cfg.pubkeyLength) :
    ∀ (ps as : List Nat), (∀ l ∈ ps, l = cfg.pubkeyLength) →
      pushLoop cfg ps as ≠ some .revertInvalidPublicKeyLength
  | [], _, _ => by simp [pushLoop]
  | _ :: _, [], _ => by simp [pushLoop]
  | p :: ps, _ :: as, hAll => by
      have hp : p = cfg.pubkeyLength := hAll p (List.mem_cons_self ..)
      have hRest : ∀ l ∈ ps, l = cfg.pubkeyLength :=
        fun l hl => hAll l (List.mem_cons_of_mem _ hl)
      unfold pushLoop
      rw [if_neg (by rw [hLengths, hp]; exact fun h => h rfl)]
      split
      · exact pushLoop_ne_invalidPublicKeyLength hLengths ps as hRest
      split
      · intro h; cases h
      split
      · intro h; cases h
      · exact pushLoop_ne_invalidPublicKeyLength hLengths ps as hRest

/--
The `continue` at `BeaconChainDepositor.sol` line 89 loses nothing: skipping a
zero amount is the same as sending it, so the push loop moves exactly the sum the
router accumulated at source line 732 -- provided the two arrays have the same
length, which the `ArrayLengthMismatch` guard at `BeaconChainDepositor.sol` line
74 enforces.
-/
theorem loopPushed_eq_allocSum :
    ∀ (ps as : List Nat), ps.length = as.length → loopPushed ps as = allocSum as
  | [], [], _ => rfl
  | [], _ :: _, h => Nat.noConfusion h
  | _ :: _, [], h => Nat.noConfusion h
  | _ :: ps, a :: as, h => by
      have hLen : ps.length = as.length := Nat.succ.inj h
      rw [loopPushed, allocSum, loopPushed_eq_allocSum ps as hLen]
      by_cases ha : a = 0
      · rw [if_pos ha, ha]
      · rw [if_neg ha]

/--
The pull at source line 744 and the push at `BeaconChainDepositor.sol` line 106
move the same wei.  Unlike the deposit path, this needs *no* deployment-
configuration hypothesis: both sides are readings of the one `allocations` array
that source line 750 hands to the push loop.
-/
theorem pulled_eq_pushed {inp : SourceTopupInput}
    (hLen : inp.pubkeyLengths.length = inp.allocations.length) :
    totalAllocated inp = pushedValue inp :=
  (loopPushed_eq_allocSum _ _ hLen).symm

/--
The two readings of the line 755 `assert` agree.  Comparing
`etherBalanceAfterDeposits` (source line 752) with the line 742 snapshot is the
same test as comparing the (wrapped) pull with the push, provided the router can
cover what the loop sends -- on chain it always can, because sending wei the
router does not hold reverts inside the loop at `BeaconChainDepositor.sol` line
106.  The side condition is exactly where truncating `Nat` subtraction stops
standing in for a balance.
-/
theorem balanceAssert_iff_pulled_eq_pushed (inp : SourceTopupInput)
    (hCovered : pushedValue inp ≤ inp.routerBalanceBefore + accumulated inp) :
    routerBalanceAfter inp = inp.routerBalanceBefore
      ↔ accumulated inp = pushedValue inp := by
  unfold routerBalanceAfter
  refine ⟨fun h => Nat.add_left_cancel ((Nat.sub_eq_iff_eq_add hCovered).1 h), fun h => ?_⟩
  rw [h, Nat.add_sub_cancel]

/-! ## Branch analysis -/

/--
Inversion for the value-moving tail at source lines 742--756.

Reached with a positive *wrapped* sum (source line 741 reads
`accumulated`), `runPush` can only produce one of *seven* outcomes.  The two
balance guards it syntactically contains --
`revertInsufficientRouterBalance` at `BeaconChainDepositor.sol` line 106 and
`revertAssertBalanceUnchanged` at source line 755 -- are live exactly on the
nonzero wrap branch, so their disjuncts carry the firing conditions: past the
`ArrayLengthMismatch` guard at `BeaconChainDepositor.sol` line 74 the exact push
is `totalAllocated`, while the pull, Lido-side amount guards, and the funded
balance read the wrapped `accumulated`.
-/
theorem runPush_inversion (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hZero : accumulated inp ≠ 0) {o : Outcome} (hRun : runPush cfg inp = o) :
    o = .revertLidoCannotDeposit ∨
    o = .revertLidoNotEnoughEther ∨
    o = .revertArrayLengthMismatch ∨
    (∃ p, pushLoop cfg inp.pubkeyLengths inp.allocations = some p ∧ o = p) ∨
    (inp.pubkeyLengths.length = inp.allocations.length ∧
      inp.routerBalanceBefore + accumulated inp < pushedValue inp ∧
      o = .revertInsufficientRouterBalance) ∨
    (inp.pubkeyLengths.length = inp.allocations.length ∧
      ¬ (inp.routerBalanceBefore + accumulated inp < pushedValue inp) ∧
      accumulated inp ≠ pushedValue inp ∧
      o = .revertAssertBalanceUnchanged) ∨
    (inp.pubkeyLengths.length = inp.allocations.length ∧
      accumulated inp = pushedValue inp ∧
      o = .committedTopUp inp.pubkeyLengths.length (accumulated inp) (pushedValue inp)
        (routerBalanceAfter inp)) := by
  unfold runPush at hRun
  by_cases h1 : inp.lidoCanDeposit = false
  · rw [if_pos h1] at hRun
    exact Or.inl hRun.symm
  rw [if_neg h1, if_neg hZero] at hRun
  by_cases h3 : inp.lidoDepositableEther < accumulated inp
  · rw [if_pos h3] at hRun
    exact Or.inr (Or.inl hRun.symm)
  rw [if_neg h3] at hRun
  by_cases h4 : inp.pubkeyLengths.length ≠ inp.allocations.length
  · rw [if_pos h4] at hRun
    exact Or.inr (Or.inr (Or.inl hRun.symm))
  rw [if_neg h4] at hRun
  have hLen : inp.pubkeyLengths.length = inp.allocations.length := Decidable.of_not_not h4
  split at hRun
  · rename_i p hp
    exact Or.inr (Or.inr (Or.inr (Or.inl ⟨p, hp, hRun.symm⟩)))
  · by_cases hBal : inp.routerBalanceBefore + accumulated inp < pushedValue inp
    · rw [if_pos hBal] at hRun
      exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hLen, hBal, hRun.symm⟩))))
    rw [if_neg hBal] at hRun
    by_cases hAssert : accumulated inp ≠ pushedValue inp
    · rw [if_pos hAssert] at hRun
      exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hLen, hBal, hAssert, hRun.symm⟩)))))
    rw [if_neg hAssert] at hRun
    exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr
      ⟨hLen, Decidable.of_not_not hAssert, hRun.symm⟩)))))

/--
Inversion for the whole pinned path.

Every outcome of `run` is one of the nine guard rejections at source lines
686--715, an allocation-loop guard from lines 722--734, the over-target revert at
line 737, the zero-sum commit at line 741, or the value-moving tail at lines
742--756.  The last disjunct carries the facts the earlier guards established, so
downstream proofs never have to re-peel the guard chain.
-/
theorem run_inversion {cfg : SourceTopupConfig} {inp : SourceTopupInput} {o : Outcome}
    (hRun : run cfg inp = o) :
    o = .revertNotAuthorized ∨
    o = .revertEmptyKeysList ∨
    o = .revertArraysLengthMismatch ∨
    o = .revertWrongPubkeyLength ∨
    o = .revertStakingModuleUnregistered ∨
    o = .revertStakingModuleNotActive ∨
    o = .revertWrongWithdrawalCredentialsType ∨
    o = .revertGweiModuloByZero ∨
    o = .revertLidoDepositsPaused ∨
    (∃ p, allocationLoop cfg inp.allocations inp.topUpLimits = some p ∧ o = p) ∨
    o = .revertModuleReturnExceedTarget ∨
    (o = .committedNoTopUp ∧ accumulated inp = 0) ∨
    (o = runPush cfg inp ∧
      inp.callerIsTopUpGateway = true ∧
      0 < inp.keyIndicesLength ∧
      inp.pubkeyLengths.length = inp.keyIndicesLength ∧
      (∀ l ∈ inp.pubkeyLengths, l = cfg.pubkeyLength) ∧
      accumulated inp ≠ 0) := by
  unfold run at hRun
  by_cases h1 : inp.callerIsTopUpGateway = false
  · rw [if_pos h1] at hRun
    exact Or.inl hRun.symm
  rw [if_neg h1] at hRun
  by_cases h2 : inp.keyIndicesLength = 0
  · rw [if_pos h2] at hRun
    exact Or.inr <| Or.inl hRun.symm
  rw [if_neg h2] at hRun
  by_cases h3 : inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength
  · rw [if_pos h3] at hRun
    exact Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h3] at hRun
  by_cases h4 : (inp.pubkeyLengths.any fun l => l != cfg.pubkeyLength) = true
  · rw [if_pos h4] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h4] at hRun
  by_cases h5 : inp.moduleExists = false
  · rw [if_pos h5] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h5] at hRun
  by_cases h6 : inp.moduleActive = false
  · rw [if_pos h6] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h6] at hRun
  by_cases h7 : inp.wcTypeIsType2 = false
  · rw [if_pos h7] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h7] at hRun
  by_cases h8 : cfg.gwei = 0
  · rw [if_pos h8] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h8] at hRun
  by_cases h9 : smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false
  · rw [if_pos h9] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h9] at hRun
  have hAuth : inp.callerIsTopUpGateway = true := by
    cases hc : inp.callerIsTopUpGateway
    · exact absurd hc h1
    · rfl
  have hKeysLen : inp.pubkeyLengths.length = inp.keyIndicesLength :=
    Decidable.of_not_not (fun hne => h3 (Or.inr (Or.inr hne)))
  have hAll : ∀ l ∈ inp.pubkeyLengths, l = cfg.pubkeyLength := by
    intro x hx
    refine Decidable.of_not_not (fun hne => h4 ?_)
    exact List.any_eq_true.2 ⟨x, hx, by simpa using hne⟩
  split at hRun
  · rename_i p hp
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨p, hp, hRun.symm⟩
  by_cases h10 : smDepositableEthAmountRounded cfg inp < accumulated inp
  · rw [if_pos h10] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl hRun.symm
  rw [if_neg h10] at hRun
  by_cases h11 : accumulated inp = 0
  · rw [if_pos h11] at hRun
    exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨hRun.symm, h11⟩
  rw [if_neg h11] at hRun
  exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| ⟨hRun.symm, hAuth, Nat.pos_of_ne_zero h2, hKeysLen, hAll, h11⟩

/--
What a committed push at source lines 741--756 records.  Reaching it means every
guard passed -- including the line 755 `assert`, so the wrapped pull and the
exact pushed wei agree -- the router balance is back at its line 742 snapshot,
the key count is nonzero, and the module returned exactly one allocation per
key.
-/
theorem committed_topup_spec {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    keys = inp.pubkeyLengths.length ∧ 0 < keys ∧
      inp.pubkeyLengths.length = inp.allocations.length ∧
      pulled = accumulated inp ∧ pushed = pushedValue inp ∧
      pulled = pushed ∧ 0 < pulled ∧ balanceAfter = inp.routerBalanceBefore := by
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨h, -⟩ | ⟨h, -, hKeys, hKeysLen, -, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    have := allocationLoop_reverts _ _ hp
    rw [← h] at this
    exact absurd this (by simp [Outcome.reverts])
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨-, -, h'⟩ | ⟨-, -, -, h'⟩ | ⟨hLen, hAssertPass, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · have := pushLoop_reverts _ _ hp
      rw [← h'] at this
      exact absurd this (by simp [Outcome.reverts])
    · cases h'
    · cases h'
    · cases h'
      refine ⟨rfl, ?_, hLen, rfl, rfl, hAssertPass, ?_, ?_⟩
      · rw [hKeysLen]; exact hKeys
      · exact Nat.pos_of_ne_zero hZero
      · unfold routerBalanceAfter; rw [hAssertPass, Nat.add_sub_cancel]

/--
The `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at source
line 755 holds on the committed-push branch: the router forwards every pulled wei
and keeps none.
-/
theorem committed_balance_preserved {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    pulled = pushed ∧ balanceAfter = inp.routerBalanceBefore :=
  let ⟨_, _, _, _, _, hMoved, _, hBalance⟩ := committed_topup_spec hRun
  ⟨hMoved, hBalance⟩

/--
The `BeaconChainDepositor.sol` line 73 early return is unreachable on the
committed-push branch: the line 769 and line 773 guards have already forced
`_publicKeys.length = n ≠ 0`.
-/
theorem committed_pubkeys_nonempty {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    inp.pubkeyLengths ≠ [] := by
  obtain ⟨hK, hPos, -, -, -, -, -, -⟩ := committed_topup_spec hRun
  intro hNil
  rw [hK, hNil] at hPos
  simp at hPos

/--
Whole-path value conservation: on *every* branch of the pinned top-up path --
each revert, each Solidity panic, the zero-sum commit at source line 741, and the
full push -- the wei pulled from Lido at source line 744 equals the wei pushed to
the beacon deposit contract by the loop at `BeaconChainDepositor.sol` lines
79--107.
-/
theorem run_conserves (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    (run cfg inp).pulled = (run cfg inp).pushed := by
  cases hRun : run cfg inp with
  | committedTopUp keys pulled pushed balanceAfter =>
      exact (committed_balance_preserved hRun).1
  | _ => rfl

/-- No wei crosses either boundary on a reverting branch: the pull at source line
744 is strictly after every guard at lines 686--739, and every later guard aborts
the whole transaction. -/
theorem reverting_moves_no_ether {o : Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 := by
  cases o <;> simp_all [Outcome.reverts, Outcome.pulled, Outcome.pushed]

/--
The `_checkAppAuth(_getTopUpGateway())` at source line 686 is the *first* guard,
not one hidden behind the input validation at line 687: a caller other than the
top-up gateway reverts whatever the rest of the per-call data says.
-/
theorem unauthorized_reverts (cfg : SourceTopupConfig) {inp : SourceTopupInput}
    (hAuth : inp.callerIsTopUpGateway = false) :
    run cfg inp = .revertNotAuthorized := by
  simp only [run, if_pos hAuth]

/--
Contrapositive: neither committing branch is reachable from a caller other than
the top-up gateway, so the access-control revert is inside the rollback
implication rather than being classified as a committed outcome.
-/
theorem committing_implies_authorized {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    (hCommit : (run cfg inp).reverts = false) :
    inp.callerIsTopUpGateway = true := by
  by_cases hAuth : inp.callerIsTopUpGateway = false
  · rw [unauthorized_reverts cfg hAuth] at hCommit
    simp [Outcome.reverts] at hCommit
  · simpa using hAuth

/--
The zero-sum commit at source line 741 is reachable only when the wrapped
accumulator is zero -- either the module returned nothing to deposit, or the
unchecked sum wrapped to exactly zero.  It is the one non-reverting escape
that never reaches the line 755 `assert`.
-/
theorem committedNoTopUp_implies_zero_total {cfg : SourceTopupConfig}
    {inp : SourceTopupInput} (hRun : run cfg inp = .committedNoTopUp) :
    accumulated inp = 0 := by
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨-, hZero⟩ | ⟨h, -, -, -, -, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    have := allocationLoop_reverts _ _ hp
    rw [← h] at this
    exact absurd this (by simp [Outcome.reverts])
  case _ => cases h
  case _ => exact hZero
  case _ =>
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨-, -, h'⟩ | ⟨-, -, -, h'⟩ | ⟨-, -, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · have := pushLoop_reverts _ _ hp
      rw [← h'] at this
      exact absurd this (by simp [Outcome.reverts])
    · cases h'
    · cases h'
    · cases h'

/--
Under `NoUncheckedWrap` the `assert` at source line 755 can never fire: the
wrapped pull and the exact push are the same number
(`totalAllocated_faithful`), so the commit branch is the only way past it.
This is the sharpest difference from the deposit path, where the corresponding
assert at `StakingRouter.sol` line 996 is the guard that rejects a
misconfigured deployment.  Here the pull and the push are two readings of the
one `allocations` array, so no configuration can separate them -- unless the
sum itself wraps, which is exactly what the hypothesis excludes.

The `NoUncheckedWrap` hypothesis is the recorded side condition
(`A-TOPUP-NOWRAP`) under which the wrapped reading the value-moving tail uses
equals the exact sum.  On a nonzero wrap the assert is load-bearing:
`run_wrap_nonzero_reverts` shows every wrapping input with `accumulated ≠ 0`
reverts, and `run_wrap_precludes_value_moving_commit` shows wrap never
produces a value-moving commit.
-/
theorem run_ne_revertAssertBalanceUnchanged (cfg : SourceTopupConfig)
    (inp : SourceTopupInput) (hNoWrap : NoUncheckedWrap inp) :
    run cfg inp ≠ .revertAssertBalanceUnchanged := by
  intro hRun
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨h, -⟩ | ⟨h, -, -, -, -, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases allocationLoop_range _ _ hp with h' | h' | h' <;> rw [h'] at h <;> cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    have hFaithful : accumulated inp = totalAllocated inp := totalAllocated_faithful hNoWrap
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨-, -, h'⟩ | ⟨hLen, -, hAssert, h'⟩ | ⟨-, -, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · rcases pushLoop_range _ _ hp with h'' | h'' | h'' <;> rw [h''] at h' <;> cases h'
    · cases h'
    · exact absurd (hFaithful.trans (pulled_eq_pushed hLen)) hAssert
    · cases h'

/--
Under `NoUncheckedWrap` the push loop at `BeaconChainDepositor.sol` line 106 can
always be funded: the router pulled exactly what it is about to send.  Carries
the same recorded `NoUncheckedWrap` side condition (`A-TOPUP-NOWRAP`), for the
same reason as `run_ne_revertAssertBalanceUnchanged`.
-/
theorem run_ne_revertInsufficientRouterBalance (cfg : SourceTopupConfig)
    (inp : SourceTopupInput) (hNoWrap : NoUncheckedWrap inp) :
    run cfg inp ≠ .revertInsufficientRouterBalance := by
  intro hRun
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨h, -⟩ | ⟨h, -, -, -, -, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases allocationLoop_range _ _ hp with h' | h' | h' <;> rw [h'] at h <;> cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    have hFaithful : accumulated inp = totalAllocated inp := totalAllocated_faithful hNoWrap
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨hLen, hBal, h'⟩ | ⟨-, -, -, h'⟩ | ⟨-, -, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · rcases pushLoop_range _ _ hp with h'' | h'' | h'' <;> rw [h''] at h' <;> cases h'
    · have hEq : accumulated inp = pushedValue inp :=
        hFaithful.trans (pulled_eq_pushed hLen)
      rw [hEq] at hBal
      omega
    · cases h'
    · cases h'

/--
`Lido.withdrawDepositableEther`'s `ZERO_AMOUNT` guard (`Lido.sol` line 873) is
unreachable from `StakingRouter.topUp`: the `amount > 0` test at source line 741
has already excluded a zero sum before the pull at source line 744 happens.
-/
theorem run_ne_revertLidoZeroAmount (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    run cfg inp ≠ .revertLidoZeroAmount := by
  intro hRun
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨h, -⟩ | ⟨h, -, -, -, -, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases allocationLoop_range _ _ hp with h' | h' | h' <;> rw [h'] at h <;> cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨-, -, h'⟩ | ⟨-, -, -, h'⟩ | ⟨-, -, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · rcases pushLoop_range _ _ hp with h'' | h'' | h'' <;> rw [h''] at h' <;> cases h'
    · cases h'
    · cases h'
    · cases h'

/-- Consequently the pinned path never reaches the `BeaconChainDepositor.sol`
line 83 revert: the router's own validation loop at source lines 777--781 has
already rejected every wrong-length pubkey. -/
theorem run_ne_revertInvalidPublicKeyLength {cfg : SourceTopupConfig}
    {inp : SourceTopupInput} (hLengths : cfg.publicKeyLength = cfg.pubkeyLength) :
    run cfg inp ≠ .revertInvalidPublicKeyLength := by
  intro hRun
  rcases run_inversion hRun with
    h | h | h | h | h | h | h | h | h | ⟨p, hp, h⟩ | h | ⟨h, -⟩ | ⟨h, -, -, -, hAll, hZero⟩
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases allocationLoop_range _ _ hp with h' | h' | h' <;> rw [h'] at h <;> cases h
  case _ => cases h
  case _ => cases h
  case _ =>
    rcases runPush_inversion cfg inp hZero h.symm with
      h' | h' | h' | ⟨p, hp, h'⟩ | ⟨-, -, h'⟩ | ⟨-, -, -, h'⟩ | ⟨-, -, h'⟩
    · cases h'
    · cases h'
    · cases h'
    · exact pushLoop_ne_invalidPublicKeyLength hLengths _ _ hAll (h' ▸ hp)
    · cases h'
    · cases h'
    · cases h'

/--
A wrapping batch never moves wei.  When the exact sum reaches `2 ^ 256` the
`unchecked` accumulation at source line 732 wraps.  If the wrapped word is
zero, line 741 takes `committedNoTopUp`.  If it is nonzero, the wrapped pull
is strictly below the exact push and the value-moving tail aborts -- either
the router cannot fund the loop (`revertInsufficientRouterBalance`) or the
line 755 `assert` fires (`revertAssertBalanceUnchanged`).  Either way
`pulled = pushed = 0`.
-/
theorem run_wrap_precludes_value_moving_commit
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hWrap : ¬ NoUncheckedWrap inp) :
    (run cfg inp).pulled = 0 ∧ (run cfg inp).pushed = 0 := by
  have hModulusPos : 0 < uint256Modulus := by decide
  cases hRun : run cfg inp with
  | committedNoTopUp => exact ⟨rfl, rfl⟩
  | committedTopUp keys pulled pushed balanceAfter =>
      obtain ⟨-, -, hLen, hPull, hPush, hMoved, -, -⟩ := committed_topup_spec hRun
      have hEq : accumulated inp = pushedValue inp :=
        hPull.symm.trans (hMoved.trans hPush)
      have hTotalEq : totalAllocated inp = pushedValue inp := pulled_eq_pushed hLen
      have hMod : accumulated inp = totalAllocated inp % uint256Modulus :=
        allocSumUnchecked_eq_mod _
      have hModEq : totalAllocated inp % uint256Modulus = totalAllocated inp := by
        rw [← hMod, hEq]; exact hTotalEq.symm
      have hLt : totalAllocated inp < uint256Modulus := by
        have hModLt : totalAllocated inp % uint256Modulus < uint256Modulus :=
          Nat.mod_lt _ hModulusPos
        rwa [hModEq] at hModLt
      exact absurd hLt hWrap
  | _ => exact ⟨rfl, rfl⟩

/-- Nonzero wrap still reverts: the empty-commit exception is only wrap-to-zero. -/
theorem run_wrap_nonzero_reverts (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hWrap : ¬ NoUncheckedWrap inp) (hNz : accumulated inp ≠ 0) :
    (run cfg inp).reverts = true := by
  have ⟨hp, _⟩ := run_wrap_precludes_value_moving_commit cfg inp hWrap
  cases hRun : run cfg inp with
  | committedNoTopUp =>
      exact absurd (committedNoTopUp_implies_zero_total hRun) hNz
  | committedTopUp keys pulled pushed balanceAfter =>
      rw [hRun] at hp
      simp [Outcome.pulled] at hp
      obtain ⟨-, -, -, hPull, -, -, hPos, -⟩ := committed_topup_spec hRun
      exact absurd hp (Nat.ne_of_gt (hPull ▸ hPos))
  | _ => rfl

/-- A committed source run is either no-wrap or a wrap-to-zero empty commit. -/
theorem committed_implies_nowrap_or_wrapped_zero
    {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    (hCommit : (run cfg inp).reverts = false) :
    NoUncheckedWrap inp ∨ accumulated inp = 0 := by
  by_cases hNoWrap : NoUncheckedWrap inp
  · exact Or.inl hNoWrap
  · by_cases hZero : accumulated inp = 0
    · exact Or.inr hZero
    · exact absurd hCommit (by
        simp only [Bool.not_eq_false]
        exact run_wrap_nonzero_reverts cfg inp hNoWrap hZero)

/-! ## Abstract-transaction correspondence -/

/--
The abstract transaction observation the pinned outcome produces: a reverting
guard yields the model's `.reverted` result, and the two committing branches
yield `.committed`.
-/
def observation {State : Type} (before after : State) (attempts : List CallAttempt)
    (trace : CommitTrace) (o : Outcome) : TxObservation State :=
  ⟨before, attempts, if o.reverts then .reverted else .committed after trace⟩

/--
Rollback correspondence: because every pinned guard aborts the whole transaction,
the model's `revert_restores_state_value_and_logs` applies directly to the
source-shaped outcome -- pre-state restored, no committed ETH movement, no
committed logs.
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
The zero-sum path at source line 741 is honestly *not* a rollback: the
`allocateDeposits` module call at source lines 717--718 has already committed, so
the model observation stays on the committed branch.
-/
theorem committedNoTopUp_is_not_a_rollback {State : Type} (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) :
    (observation before after attempts trace .committedNoTopUp).result
      = .committed after trace := by
  simp [observation, Outcome.reverts]

end LidoSRv3.Audit.SolidityTopup
