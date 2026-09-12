/-!
# Pinned mint-consumer source semantics

Nat-level model of `Accounting.sol:335-357,403-413`,
`StakingRouter.sol:266-270,808-873`, and `SRLib.sol:620-641,873-892` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The writer records the per-module balances/fee vector and the consumer reads
that same `RouterSnapshot.moduleFees`; it is deliberately not a second
consumer argument.  Omitted: LIDO `mintShares`/`transferShares` token
internals, REPORT_REWARDS_MINTED_ROLE, SRUtils registry-id check, module
address resolution, keccak, and events (the latter are observation facts
only).  The external `onRewardsMinted` callee is an opaque supplied outcome.
-/
namespace LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted

inductive CallbackOutcome where | accept | revertData | revertEmpty
  deriving DecidableEq, Repr

inductive ConsumerError where | arraysLengthMismatch | unrecoverableModuleError | feeTotalZero
  deriving DecidableEq, Repr

inductive Event where | minted | distributed (module : Nat) (shares : Nat)
  | treasury (shares : Nat) | callback (module : Nat) (shares : Nat) | callbackFailed (module : Nat)
  deriving DecidableEq, Repr

/-- Model-local projection of the SRLib 873-892 router storage. -/
structure RouterSnapshot where
  validatorBalances : List Nat
  moduleFees : List Nat
  deriving DecidableEq, Repr

/-- SRLib.sol:873-892 writer projection. -/
def writeValidatorBalances (balances fees : List Nat) : RouterSnapshot :=
  ⟨balances, fees⟩

/-- StakingRouter.sol:808-873 reader projection. -/
def getStakingRewardsDistribution (s : RouterSnapshot) : List Nat := s.moduleFees

/-- Accounting.sol:350 `shares * moduleFee / totalFee`; zero fee entries get
zero, as the source only enters the branch for positive module fees. -/
def moduleFeeShares (shares totalFee moduleFee : Nat) : Nat :=
  if 0 < moduleFee then shares * moduleFee / totalFee else 0

def feeShares (shares totalFee : Nat) : List Nat → List Nat
  | [] => []
  | f :: fs => moduleFeeShares shares totalFee f :: feeShares shares totalFee fs

structure FeeDistribution where
  moduleShares : List Nat
  treasuryShares : Nat
  deriving DecidableEq, Repr

/-- Accounting.sol:335-357 `_calculateFeeDistribution`, including the
L350 multiplication before division and the treasury remainder. -/
def calculateFeeDistribution (shares : Nat) (fees : List Nat) : FeeDistribution :=
  let totalFee := fees.foldl (· + ·) 0
  let ms := feeShares shares totalFee fees
  ⟨ms, shares - ms.foldl (· + ·) 0⟩

def callbacks : List Nat → List Nat → List CallbackOutcome →
    List Event → Except ConsumerError (List Event)
  | [], [], [], ev => .ok ev
  | id :: ids, sh :: ss, out :: os, ev =>
      if sh = 0 then callbacks ids ss os ev
      else match out with
      | .accept => callbacks ids ss os (ev ++ [.callback id sh])
      | .revertData => callbacks ids ss os (ev ++ [.callbackFailed id])
      | .revertEmpty => .error .unrecoverableModuleError
  | _, _, _, _ => .error .arraysLengthMismatch

/-- Accounting 403-413: mint, distribute, then *last* router callback;
SRLib 620-641 supplies zero-skip and try/catch behavior. -/
def consume (moduleIds : List Nat) (sharesToMint : Nat) (snapshot : RouterSnapshot)
    (outcomes : List CallbackOutcome) : Except ConsumerError (List Event × FeeDistribution) :=
  if sharesToMint = 0 then .ok ([], calculateFeeDistribution 0 (getStakingRewardsDistribution snapshot))
  else
    let fees := getStakingRewardsDistribution snapshot
    if fees.foldl (· + ·) 0 = 0 then .error .feeTotalZero
    else
      let d := calculateFeeDistribution sharesToMint fees
      let distributes := (moduleIds.zip d.moduleShares).filterMap (fun p =>
        if p.2 = 0 then none else some (Event.distributed p.1 p.2))
      -- Accounting.sol:471-487 completes distribution before router callback.
      match callbacks moduleIds d.moduleShares outcomes
          ([.minted] ++ distributes ++ [.treasury d.treasuryShares]) with
      | .error e => .error e
      | .ok ev => .ok (ev, d)

/-- A compact re-read statement: consumer fee inputs are exactly the vector
written into the snapshot, not an independent parameter. -/
theorem consumer_rereads_writer (balances fees : List Nat) :
    getStakingRewardsDistribution (writeValidatorBalances balances fees) = fees := rfl

theorem empty_revert_propagates (module shares : Nat) (ev : List Event) :
    callbacks [module] [shares + 1] [.revertEmpty] ev = .error .unrecoverableModuleError := by
  simp [callbacks]

end LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted
