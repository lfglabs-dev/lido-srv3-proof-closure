import StETHMintShares

/-!
# Committed report → getter → fee products → physical Lido mint

Pinned to `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:
`Accounting.sol:403-413`, `Lido.sol:894-900`, and
`StETH.sol:518-527,559-571`.

This is the ACCOUNT continuation of the physical router slice.  A successful
SRLib report writes a router `Core`; the StakingRouter getter then reads that
same post-write core; `feeProductsFromCommittedGetter` consumes that exact
getter result; and the resulting `sharesToMintAsFees` is passed once to the
physical Lido/StETH mint.  In particular there is no caller-supplied fee
product, mint quantity, equality premise, or assumed successful mint.
-/

namespace AccountAddress.ReportFeeMint

open AccountAddress.PAccount1
open AccountAddress.ReportWriteFee
open AccountAddress.StETHMintShares

/-- All mutable state touched by this suffix.  Router words and StETH words
are distinct contracts, while the packed StETH total-share word and the
`shares` mapping deliberately live in this one `steth` state and are updated
by the same `mintShares` execution. -/
structure World where
  router : Core
  steth : State
  deriving Repr

structure Input where
  layout : Layout
  registeredModuleIds : List Nat
  reportedModuleIds : List Nat
  balancesGwei : List Nat
  report : ReportWei
  deriving Repr

inductive Error where
  | invalidReport (e : AccountAddress.ReportWriteFee.Error)
  | getter (e : GetterError)
  /-- A Solidity 0.8 uint256 operation in Accounting 317/323/325/331 panics. -/
  | feeArithmetic
  | fee (e : FeeError)
  | mint (e : AccountAddress.StETHMintShares.Error)
  deriving Repr, DecidableEq

inductive Outcome where
  | reverted (error : Error) (rollback : World)
  | committed (post : World) (fee : FeeResult) (events : List Event)
  deriving Repr

private def uint256Max : Nat := two256 - 1

private def checkedWord (n : Nat) : Option Nat :=
  if n ≤ uint256Max then some n else none

private def checkedAdd (a b : Nat) : Option Nat :=
  if a + b ≤ uint256Max then some (a + b) else none

private def checkedSub (a b : Nat) : Option Nat :=
  if b ≤ a then some (a - b) else none

private def checkedMul (a b : Nat) : Option Nat :=
  if a * b ≤ uint256Max then some (a * b) else none

private def checkedDiv (a b : Nat) : Option Nat :=
  if b = 0 then none else some (a / b)

/-- The checked Accounting 317, 323, 325 and 331 products over the exact
post-write getter result.  This is deliberately an executable failure surface
rather than a bounded-domain premise: any out-of-word field, overflow,
underflow, or zero divisor rejects the whole composed transaction. -/
private def checkedFeeProductsFromCommittedGetter (r : ReportWei) (d : Distribution) :
    Option FeeResult := do
  let validators ← checkedWord r.clValidatorsBalance
  let pending ← checkedWord r.clPendingBalance
  let withdrawals ← checkedWord r.withdrawalsVaultTransfer
  let principal ← checkedWord r.principalClBalance
  let elRewards ← checkedWord r.elRewardsVaultTransfer
  let postEther ← checkedWord r.postInternalEther
  let internalShares ← checkedWord r.internalSharesBeforeFees
  let totalFee ← checkedWord d.totalFee
  let precision ← checkedWord d.precisionPoints
  let prefix ← checkedAdd validators pending
  let unified ← checkedAdd prefix withdrawals
  if principal < unified then
    let rewardBeforeEl ← checkedSub unified principal
    let rewards ← checkedAdd rewardBeforeEl elRewards
    let feeProduct ← checkedMul rewards totalFee
    let feeEther ← checkedDiv feeProduct precision
    let denominator ← checkedSub postEther feeEther
    let sharesProduct ← checkedMul feeEther internalShares
    let shares ← checkedDiv sharesProduct denominator
    some (feeResultOf d shares)
  else some (feeResultOf d 0)

/-- The precise `Accounting.sol:403-413` tail.  The zero-share branch skips
`LIDO.mintShares`, so it also emits no synthetic mint event.  On any StETH
revert the enclosing report transaction is rolled back to its entry world. -/
private def mintCommittedFee (before : World) (fee : FeeResult) : Outcome :=
  if 0 < fee.sharesToMintAsFees then
    match mintShares before.steth.locatorAccounting before.steth.locatorAccounting
        fee.sharesToMintAsFees before.steth with
    | .reverted e _ => .reverted (.mint e) before
    | .committed steth events => .committed { before with steth } fee events
  else .committed before fee []

/-- One complete physical ACCOUNT suffix.  `getStakingRewardsDistribution`
is intentionally exposed as its own match between the report write and the
fee continuation: this makes the post-write getter dependency executable,
rather than an informal assertion hidden inside a fee wrapper. -/
def handleOracleReportFromCommittedFeeProducts (x : Input) (before : World) : Outcome :=
  match reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds
      x.balancesGwei before.router with
  | .reverted e _ => .reverted (.invalidReport e) before
  | .committed postRouter =>
      match getStakingRewardsDistribution x.layout x.registeredModuleIds postRouter with
      | .error e => .reverted (.getter e) before
      | .ok distribution =>
          match checkedFeeProductsFromCommittedGetter x.report distribution with
          | none => .reverted .feeArithmetic before
          | .ok fee =>
              match mintCommittedFee { before with router := postRouter } fee with
              | .reverted e _ => .reverted e before
              | .committed post fee events => .committed post fee events

/-- On a successful nonzero fee, the emitted transfer-share amount is the
very `FeeResult` produced from the committed getter, and the packed word and
recipient mapping are both observations of that one post-mint `State`. -/
theorem committed_nonzero_mint_uses_fee_result (x : Input) (before post : World)
    (fee : FeeResult) (events : List Event)
    (h : handleOracleReportFromCommittedFeeProducts x before = .committed post fee events)
    (hfee : 0 < fee.sharesToMintAsFees) :
    ∃ pooled, events = [.transfer 0 before.steth.locatorAccounting pooled,
      .transferShares 0 before.steth.locatorAccounting fee.sharesToMintAsFees] := by
  unfold handleOracleReportFromCommittedFeeProducts at h
  split at h
  · cases h
  rename_i postRouter hreport
  split at h
  · cases h
  rename_i distribution hgetter
  split at h
  · cases h
  rename_i products hproducts
  unfold mintCommittedFee at h
  simp only [hfee, ↓reduceIte] at h
  split at h
  · cases h
  · rename_i steth mintedEvents hmint
    simp only [Outcome.committed.injEq, World.mk.injEq] at h
    obtain ⟨_, _, rfl⟩ := h
    exact committed_mint_has_paired_events _ _ _ _ _ _ hmint

end AccountAddress.ReportFeeMint
