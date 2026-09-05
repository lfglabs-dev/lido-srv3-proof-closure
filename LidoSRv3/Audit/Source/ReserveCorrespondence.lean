import LidoSRv3.Audit.Arithmetic
import Verity.Core
import Verity.EVM.Uint256
import Verity.Macro

namespace LidoSRv3.Audit.SolidityReserve

open Verity
open Verity.EVM.Uint256
open Verity.Stdlib.Math

/-!
# Pinned reserve-spend correspondence

This is a source-shaped model of `lidofinance/core` at
`17005714f151e5502c559932319a3f2f74ac2436`, specifically
`contracts/0.4.24/Lido.sol`:

* `_getBufferedEtherAllocation`, lines 605--616;
* `_getDepositableEther`, lines 831--833; and
* `_spendDepositableEther`, lines 839--859.

The public `getDepositableEther` wrapper is lines 823--825 and the external
caller `withdrawDepositableEther` is lines 869--886.  The model begins after
that caller's authorization/pause/nonzero guards and covers the reserve
non-interference transition itself.  Values returned by external getters
(`unfinalizedStETH` and the adjusted next-report counter) are explicit inputs.

Solidity 0.4.24 raw subtraction in the allocation helper is represented by
`safeSub` and proved unreachable on its failure branches from the two `min`
bounds. SafeMath additions/subtractions in the spend helper remain executable
checked-`Uint256` branches. No Yul, EVM, runtime-bytecode, cryptographic, or E2E
claim is made by this module.

## Revert strings

Only `NOT_ENOUGH_ETHER` (Lido.sol:842), `CAN_NOT_DEPOSIT` (870),
`APP_AUTH_FAILED` (872, via `_auth`) and `ZERO_AMOUNT` (873) are literal
Solidity revert reasons.  The five others are invented by the model for
branches where Solidity 0.4.24 reverts *without* a message:

* `ALLOCATION_ARITHMETIC`: the raw `remaining -= ...` at Lido.sol:610 and 613
  (unchecked in 0.4.24, here `safeSub`; proved unreachable from the `min`s);
* `DEPOSITABLE_OVERFLOW`: the raw `+` at Lido.sol:832;
* `DEPOSITED_POST_REPORT_OVERFLOW`: SafeMath `.add` at Lido.sol:846;
* `BUFFER_UNDERFLOW`: SafeMath `.sub` at Lido.sol:847;
* `DEPOSITED_NEXT_REPORT_OVERFLOW`: SafeMath `.add` at Lido.sol:852.

`Allocation` field order (`total, unreserved, depositsReserve,
withdrawalsReserve`) is *not* the Solidity assignment order (607, 609, 612,
615); the source-plane constructor is therefore written with named fields.
-/

abbrev Word := Verity.Core.Uint256

structure ReserveState where
  buffered : Word
  storedDepositsReserve : Word
  unfinalizedStETH : Word
  depositedPostReport : Word
  depositedNextReportAdjusted : Word
  deriving DecidableEq, Repr

structure Allocation where
  total : Word
  unreserved : Word
  depositsReserve : Word
  withdrawalsReserve : Word
  deriving DecidableEq, Repr

def minWord (a b : Word) : Word := if a ≤ b then a else b

private def min (a b : Word) : Word := minWord a b

def getBufferedEtherAllocation (s : ReserveState) : Option Allocation := do
  let depositsReserve := minWord s.buffered s.storedDepositsReserve
  let remaining ← safeSub s.buffered depositsReserve
  let withdrawalsReserve := minWord remaining s.unfinalizedStETH
  let unreserved ← safeSub remaining withdrawalsReserve
  pure ⟨s.buffered, unreserved, depositsReserve, withdrawalsReserve⟩

def getDepositableEther (a : Allocation) : Option Word :=
  safeAdd a.depositsReserve a.unreserved

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (after : ReserveState)
  deriving DecidableEq, Repr

/-- `_spendDepositableEther` (Lido.sol 839--859): consume `amount` from
`depositsReserve + unreserved`, then shrink `buffered` and
`storedDepositsReserve`. `withdrawalsReserve` is not written. -/
def spendDepositableEther (before : ReserveState) (amount : Word) : SourceOutcome :=
  match getBufferedEtherAllocation before with
  | none => .reverted "ALLOCATION_ARITHMETIC"
  | some allocation =>
      match getDepositableEther allocation with
      | none => .reverted "DEPOSITABLE_OVERFLOW"
      | some depositable =>
          if amount ≤ depositable then
            match safeAdd before.depositedPostReport amount with
            | none => .reverted "DEPOSITED_POST_REPORT_OVERFLOW"
            | some depositedPostReport =>
                match safeSub allocation.total amount with
                | none => .reverted "BUFFER_UNDERFLOW"
                | some remaining =>
                    match safeAdd before.depositedNextReportAdjusted amount with
                    | none => .reverted "DEPOSITED_NEXT_REPORT_OVERFLOW"
                    | some depositedNextReportAdjusted =>
                        let depositsReserve :=
                          if before.storedDepositsReserve > amount then
                            before.storedDepositsReserve - amount
                          else 0
                        .committed { before with
                          buffered := remaining
                          storedDepositsReserve := depositsReserve
                          depositedPostReport := depositedPostReport
                          depositedNextReportAdjusted := depositedNextReportAdjusted }
          else .reverted "NOT_ENOUGH_ETHER"

def effectiveWithdrawalsReserve (s : ReserveState) : Word :=
  let deposits := minWord s.buffered s.storedDepositsReserve
  minWord (s.buffered - deposits) s.unfinalizedStETH

/-! ## Verity plane: Lido._spendDepositableEther (Lido.sol:839-859) as a `verity_contract`

Concrete Verity storage projection. These are model-local slots, not a claim
about the proxy's deployed keccak-derived storage positions.

`withdraw` inlines `_getBufferedEtherAllocation` (605-616),
`_getDepositableEther` (832) and `_spendDepositableEther` (839-859) into one
body.  Its four `setStorage` writes are issued in a different order than the
Solidity writes (Lido.sol:847 buffered + depositedPostReport, 853
depositedNextReport, 857 deposits reserve): here `buffered`,
`storedDepositsReserve`, `depositedPostReport`, `depositedNextReportAdjusted`.
The slots are distinct so the post-state is the same; the order is kept as is
because `verity_execution_simulates_spec` unfolds this exact normal form. -/
verity_contract ReserveContract where
  storage
    buffered : Uint256 := slot 0
    storedDepositsReserve : Uint256 := slot 1
    unfinalizedStETH : Uint256 := slot 2
    depositedPostReport : Uint256 := slot 3
    depositedNextReportAdjusted : Uint256 := slot 4

  function withdraw (amount : Uint256) : Unit := do
    let currentBuffered ← getStorage buffered
    let currentStoredDepositsReserve ← getStorage storedDepositsReserve
    let currentUnfinalizedStETH ← getStorage unfinalizedStETH
    let currentDepositedPostReport ← getStorage depositedPostReport
    let currentDepositedNextReportAdjusted ← getStorage depositedNextReportAdjusted

    let depositsReserve := min currentBuffered currentStoredDepositsReserve
    let remaining ← requireSomeUint
      (safeSub currentBuffered depositsReserve) "ALLOCATION_ARITHMETIC"
    let withdrawalsReserve := min remaining currentUnfinalizedStETH
    let unreserved ← requireSomeUint
      (safeSub remaining withdrawalsReserve) "ALLOCATION_ARITHMETIC"
    let depositable ← requireSomeUint
      (safeAdd depositsReserve unreserved) "DEPOSITABLE_OVERFLOW"
    require (amount ≤ depositable) "NOT_ENOUGH_ETHER"

    let nextDepositedPostReport ← requireSomeUint
      (safeAdd currentDepositedPostReport amount) "DEPOSITED_POST_REPORT_OVERFLOW"
    let nextBuffered ← requireSomeUint
      (safeSub currentBuffered amount) "BUFFER_UNDERFLOW"
    let nextDepositedNextReportAdjusted ← requireSomeUint
      (safeAdd currentDepositedNextReportAdjusted amount) "DEPOSITED_NEXT_REPORT_OVERFLOW"
    let nextStoredDepositsReserve :=
      ite (currentStoredDepositsReserve > amount)
        (sub currentStoredDepositsReserve amount) 0

    setStorage buffered nextBuffered
    setStorage storedDepositsReserve nextStoredDepositsReserve
    setStorage depositedPostReport nextDepositedPostReport
    setStorage depositedNextReportAdjusted nextDepositedNextReportAdjusted

def decode (s : ContractState) : ReserveState :=
  { buffered := s.storage ReserveContract.buffered.slot
    storedDepositsReserve := s.storage ReserveContract.storedDepositsReserve.slot
    unfinalizedStETH := s.storage ReserveContract.unfinalizedStETH.slot
    depositedPostReport := s.storage ReserveContract.depositedPostReport.slot
    depositedNextReportAdjusted := s.storage ReserveContract.depositedNextReportAdjusted.slot }

/-! ## Independent pinned-source execution

The definitions below deliberately do not call `spendDepositableEther` or its
helpers.  They transcribe the five pinned Solidity spans into a second,
source-shaped interpreter.  This separation makes the MODEL → SOURCE →
VERITY_TX refinement non-vacuous and mutant-sensitive.

`WithdrawInputs` exposes the two wrapper guards whose implementations lie
outside the pinned spans.  This reserve projection does not model the seed
deposit counter, event log payloads, or the final router value transfer.
-/

structure WithdrawInputs where
  canDeposit : Bool
  authorizedRouter : Bool
  deriving DecidableEq, Repr

/-! ## Lido._getBufferedEtherAllocation (Lido.sol:605-616) -/

/-- `Lido.sol:605-616 _getBufferedEtherAllocation() returns (BufferedEtherAllocation allocation)`.

Not transcribed: the two external reads `_getBufferedEther()` (606) and
`_withdrawalQueue().unfinalizedStETH()` (612) are the `ReserveState` fields
`buffered` / `unfinalizedStETH`; `DEPOSITS_RESERVE_POSITION.getStorageUint256()`
(609) is `storedDepositsReserve`.
Added by the model: the `safeSub` failure branches (`none`) for the two raw
0.4.24 subtractions; both are proved unreachable from the `min` bounds. -/
def sourceGetBufferedEtherAllocation (s : ReserveState) : Option Allocation := do
  -- Lido.sol:609  allocation.depositsReserve = Math256.min(remaining, DEPOSITS_RESERVE_POSITION.getStorageUint256());
  let depositsReserve := minWord s.buffered s.storedDepositsReserve
  -- Lido.sol:610  remaining -= allocation.depositsReserve;
  -- (raw 0.4.24 subtraction; `safeSub` cannot fail here since depositsReserve ≤ buffered)
  let remainingAfterDeposits ← safeSub s.buffered depositsReserve
  -- Lido.sol:612  allocation.withdrawalsReserve = Math256.min(remaining, _withdrawalQueue().unfinalizedStETH());
  let withdrawalsReserve := minWord remainingAfterDeposits s.unfinalizedStETH
  -- Lido.sol:613  remaining -= allocation.withdrawalsReserve;
  -- (raw 0.4.24 subtraction; `safeSub` cannot fail here since withdrawalsReserve ≤ remaining)
  let unreserved ← safeSub remainingAfterDeposits withdrawalsReserve
  pure {
    -- Lido.sol:606-607  uint256 remaining = _getBufferedEther(); allocation.total = remaining;
    total := s.buffered
    depositsReserve := depositsReserve
    withdrawalsReserve := withdrawalsReserve
    -- Lido.sol:615  allocation.unreserved = remaining;
    unreserved := unreserved }

/-! ## Lido._getDepositableEther (Lido.sol:831-833) -/

/-- `Lido.sol:831-833 _getDepositableEther(BufferedEtherAllocation allocation) returns (uint256)`. -/
def sourceGetDepositableEther (a : Allocation) : Option Word :=
  -- Lido.sol:832  return allocation.depositsReserve + allocation.unreserved;
  safeAdd a.depositsReserve a.unreserved

/-! ## Lido._spendDepositableEther (Lido.sol:839-859) -/

/-- `Lido.sol:839-859 _spendDepositableEther(uint256 _depositAmount)`.

Not transcribed: the events Lido.sol:848 `emit DepositedPostReportUpdated(...)`
and 849 `emit Unbuffered(_depositAmount)`; the nonce half of 851
`(uint256 depositedNextReport, uint256 curNonce) = _getDepositedNextReportAdjusted();`
and of 853 `_setDepositedNextReportAndLastDepositNonce(depositedNextReport, curNonce);`
(`curNonce` is written back unchanged; `depositedNextReportAdjusted` is an
explicit input); the guard 856 `if (storedDepositsReserve > 0)` (absorbed, see
below).
Added by the model: the revert strings other than `NOT_ENOUGH_ETHER` (see
module header). -/
def sourceSpendDepositableEther (before : ReserveState) (amount : Word) : SourceOutcome :=
  -- Lido.sol:840  BufferedEtherAllocation memory allocation = _getBufferedEtherAllocation();
  match sourceGetBufferedEtherAllocation before with
  | none => .reverted "ALLOCATION_ARITHMETIC"
  | some allocation =>
      -- Lido.sol:841  uint256 depositableEther = _getDepositableEther(allocation);
      match sourceGetDepositableEther allocation with
      | none => .reverted "DEPOSITABLE_OVERFLOW"
      | some depositable =>
          -- Lido.sol:842  require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER");
          if amount ≤ depositable then
            -- Lido.sol:846  uint256 depositedPostReport = _getDepositedPostReport().add(_depositAmount);
            match safeAdd before.depositedPostReport amount with
            | none => .reverted "DEPOSITED_POST_REPORT_OVERFLOW"
            | some depositedPostReport =>
                -- Lido.sol:847  _setBufferedEtherAndDepositedPostReport(allocation.total.sub(_depositAmount), depositedPostReport);
                match safeSub allocation.total amount with
                | none => .reverted "BUFFER_UNDERFLOW"
                | some buffered =>
                    -- Lido.sol:852  depositedNextReport = depositedNextReport.add(_depositAmount);
                    match safeAdd before.depositedNextReportAdjusted amount with
                    | none => .reverted "DEPOSITED_NEXT_REPORT_OVERFLOW"
                    | some depositedNextReportAdjusted =>
                        -- Lido.sol:857  _setDepositsReserve(storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0);
                        -- The guard Lido.sol:856 `if (storedDepositsReserve > 0)` is absorbed: when the
                        -- stored reserve is 0 the ternary yields 0, so writing it unconditionally is a no-op.
                        let storedDepositsReserve :=
                          if before.storedDepositsReserve > amount then
                            before.storedDepositsReserve - amount
                          else 0
                        -- Writes: Lido.sol:847 (buffered, depositedPostReport), 853 (depositedNextReport), 857 (deposits reserve)
                        .committed { before with
                          buffered := buffered
                          storedDepositsReserve := storedDepositsReserve
                          depositedPostReport := depositedPostReport
                          depositedNextReportAdjusted := depositedNextReportAdjusted }
          else .reverted "NOT_ENOUGH_ETHER"

/-! ## Lido.getDepositableEther (Lido.sol:823-825) -/

/-- Source-shaped `getDepositableEther` wrapper at lines 823--825
(`Lido.sol:824  return _getDepositableEther(_getBufferedEtherAllocation());`). -/
def sourceDepositableEtherView (s : ReserveState) : Option Word := do
  sourceGetDepositableEther (← sourceGetBufferedEtherAllocation s)

/-! ## Lido.withdrawDepositableEther (Lido.sol:869-886) -/

/-- `Lido.sol:869-886 withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount)`,
reserve projection.

Not transcribed: 877-882 the deprecated `_seedDepositsCount` bookkeeping and
its event; 885 `stakingRouter.receiveDepositableEther.value(_amount)();` (the
final value transfer).
Added by the model: `WithdrawInputs` carries the results of `canDeposit()` and
`_auth(...)`, whose implementations are outside the pinned spans. -/
def sourceWithdrawDepositableEther (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  -- Lido.sol:870  require(canDeposit(), "CAN_NOT_DEPOSIT");
  if !inputs.canDeposit then .reverted "CAN_NOT_DEPOSIT"
  -- Lido.sol:871-872  IStakingRouter stakingRouter = _stakingRouter(); _auth(address(stakingRouter));
  else if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  -- Lido.sol:873  require(_amount != 0, "ZERO_AMOUNT");
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  -- Lido.sol:875  _spendDepositableEther(_amount);
  else sourceSpendDepositableEther before amount

/-- Abstract wrapper semantics.  It uses only the MODEL spend transition. -/
def modelWithdrawDepositableEther (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  if !inputs.canDeposit then .reverted "CAN_NOT_DEPOSIT"
  else if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  else spendDepositableEther before amount

/-- Checked-Uint256 correspondence between the independent pinned-source
interpreter and the abstract MODEL transition. -/
theorem source_spend_matches_model (before : ReserveState) (amount : Word) :
    sourceSpendDepositableEther before amount = spendDepositableEther before amount := by
  simp [sourceSpendDepositableEther, spendDepositableEther,
    sourceGetBufferedEtherAllocation, getBufferedEtherAllocation,
    sourceGetDepositableEther, getDepositableEther]

theorem source_withdraw_matches_model (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) :
    sourceWithdrawDepositableEther inputs before amount =
      modelWithdrawDepositableEther inputs before amount := by
  simp [sourceWithdrawDepositableEther, modelWithdrawDepositableEther,
    source_spend_matches_model]

namespace ReserveContract

/-- `Lido.sol:869-886 withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount)`
on the Verity plane.  The wrapper guards live outside the pinned reserve-spend
spans. Once they pass, execution delegates to the typed `verity_contract`
entrypoint `withdraw` (= `_spendDepositableEther`).  Same omissions as
`sourceWithdrawDepositableEther`. -/
def withdrawWithGuards (inputs : WithdrawInputs) (amount : Word) : Contract Unit := do
  -- Lido.sol:870  require(canDeposit(), "CAN_NOT_DEPOSIT");
  require inputs.canDeposit "CAN_NOT_DEPOSIT"
  -- Lido.sol:871-872  IStakingRouter stakingRouter = _stakingRouter(); _auth(address(stakingRouter));
  require inputs.authorizedRouter "APP_AUTH_FAILED"
  -- Lido.sol:873  require(_amount != 0, "ZERO_AMOUNT");
  require (amount != 0) "ZERO_AMOUNT"
  -- Lido.sol:875  _spendDepositableEther(_amount);
  withdraw amount

/-- Solidity-facing name, Lido.sol:869. -/
abbrev withdrawDepositableEther := withdrawWithGuards

/-- Solidity-facing name, Lido.sol:839: the `verity_contract` entrypoint
`withdraw` transcribes `_spendDepositableEther`. -/
abbrev spendDepositableEther := withdraw

end ReserveContract

inductive TxOutcome where | committed | reverted
  deriving DecidableEq, Repr

structure ReserveTx where
  outcome : TxOutcome
  before : ReserveState
  after : ReserveState
  deriving DecidableEq, Repr

/-- Independent abstract transaction/spec: source commits its post-state;
source reverts restore the pre-state. -/
def specTx (inputs : WithdrawInputs) (before : ReserveState) (amount : Word) : ReserveTx :=
  match modelWithdrawDepositableEther inputs before amount with
  | .reverted _ => ⟨.reverted, before, before⟩
  | .committed after => ⟨.committed, before, after⟩

def observeVerity (before : ContractState) (result : ContractResult Unit) : ReserveTx :=
  match result with
  | .revert _ rollback => ⟨.reverted, decode before, decode rollback⟩
  | .success _ after => ⟨.committed, decode before, decode after⟩

/-- VERITY_TX closure: executable `Contract.run` simulates the abstract spec,
including the rollback observable on every checked-arithmetic/source revert. -/
theorem verity_execution_simulates_spec (state : ContractState) (amount : Word) :
    ∀ inputs, observeVerity state ((ReserveContract.withdrawWithGuards inputs amount).run state) =
      specTx inputs (decode state) amount := by
  rintro ⟨canDeposit, authorizedRouter⟩
  cases canDeposit <;> cases authorizedRouter <;> try rfl
  by_cases hzero : amount = 0
  · subst amount
    rfl
  · by_cases hdeposits :
        (state.storage ReserveContract.buffered.slot).val ≤
          (state.storage ReserveContract.storedDepositsReserve.slot).val
    all_goals
      let depositsReserve :=
        minWord (state.storage ReserveContract.buffered.slot)
          (state.storage ReserveContract.storedDepositsReserve.slot)
      cases hremaining : safeSub (state.storage ReserveContract.buffered.slot) depositsReserve with
    | none =>
        simp [depositsReserve, minWord, hdeposits] at hremaining
        simp [ReserveContract.withdrawWithGuards, ReserveContract.withdraw,
          observeVerity, specTx, modelWithdrawDepositableEther,
          spendDepositableEther, getBufferedEtherAllocation, decode,
          min, minWord, requireSomeUint, getStorage, setStorage,
          ContractState.readSlot, ContractState.writeSlot, Verity.require,
          Verity.bind, Bind.bind, Pure.pure, Contract.run,
          hzero, hdeposits, depositsReserve, hremaining]
    | some remaining =>
        simp [depositsReserve, minWord, hdeposits] at hremaining
        by_cases hwithdrawals : remaining.val ≤
            (state.storage ReserveContract.unfinalizedStETH.slot).val
        all_goals
          let withdrawalsReserve :=
            minWord remaining (state.storage ReserveContract.unfinalizedStETH.slot)
          cases hunreserved : safeSub remaining withdrawalsReserve with
        | none =>
            simp [withdrawalsReserve, minWord, hwithdrawals] at hunreserved
            simp [ReserveContract.withdrawWithGuards, ReserveContract.withdraw,
              observeVerity, specTx, modelWithdrawDepositableEther,
              spendDepositableEther, getBufferedEtherAllocation, decode,
              min, minWord, requireSomeUint, getStorage, setStorage,
              ContractState.readSlot, ContractState.writeSlot, Verity.require,
              Verity.bind, Bind.bind, Pure.pure, Contract.run,
              hzero, hdeposits, hwithdrawals, depositsReserve,
              withdrawalsReserve, hremaining, hunreserved]
        | some unreserved =>
            simp [withdrawalsReserve, minWord, hwithdrawals] at hunreserved
            cases hdepositable : safeAdd depositsReserve unreserved with
            | none =>
                simp [depositsReserve, minWord, hdeposits] at hdepositable
                simp [ReserveContract.withdrawWithGuards, ReserveContract.withdraw,
                  observeVerity, specTx, modelWithdrawDepositableEther,
                  spendDepositableEther, getBufferedEtherAllocation,
                  getDepositableEther, decode, min, minWord, requireSomeUint,
                  getStorage, setStorage, ContractState.readSlot,
                  ContractState.writeSlot, Verity.require, Verity.bind,
                  Bind.bind, Pure.pure, Contract.run, hzero, hdeposits,
                  hwithdrawals, depositsReserve, withdrawalsReserve, hremaining,
                  hunreserved, hdepositable]
            | some depositable =>
                simp [depositsReserve, minWord, hdeposits] at hdepositable
                by_cases henough : amount.val ≤ depositable.val
                · cases hpost : safeAdd
                      (state.storage ReserveContract.depositedPostReport.slot) amount with
                  | none =>
                      simp [ReserveContract.withdrawWithGuards,
                        ReserveContract.withdraw, observeVerity, specTx,
                        modelWithdrawDepositableEther, spendDepositableEther,
                        getBufferedEtherAllocation, getDepositableEther, decode,
                        min, minWord, requireSomeUint, getStorage, setStorage,
                        ContractState.readSlot, ContractState.writeSlot,
                        Verity.require, Verity.bind, Bind.bind, Pure.pure,
                        Contract.run, hzero, hdeposits, hwithdrawals, depositsReserve,
                        withdrawalsReserve, hremaining, hunreserved,
                        hdepositable, henough, hpost]
                  | some depositedPostReport =>
                      cases hbuffered : safeSub
                          (state.storage ReserveContract.buffered.slot) amount with
                      | none =>
                          simp [ReserveContract.withdrawWithGuards,
                            ReserveContract.withdraw, observeVerity, specTx,
                            modelWithdrawDepositableEther, spendDepositableEther,
                            getBufferedEtherAllocation, getDepositableEther, decode,
                            min, minWord, requireSomeUint, getStorage, setStorage,
                            ContractState.readSlot, ContractState.writeSlot,
                            Verity.require, Verity.bind, Bind.bind, Pure.pure,
                            Contract.run, hzero, hdeposits, hwithdrawals, depositsReserve,
                            withdrawalsReserve, hremaining, hunreserved,
                            hdepositable, henough, hpost, hbuffered]
                      | some buffered =>
                          cases hnext : safeAdd
                              (state.storage ReserveContract.depositedNextReportAdjusted.slot)
                              amount with
                          | none =>
                              simp [ReserveContract.withdrawWithGuards,
                                ReserveContract.withdraw, observeVerity, specTx,
                                modelWithdrawDepositableEther,
                                spendDepositableEther, getBufferedEtherAllocation,
                                getDepositableEther, decode, min, minWord,
                                requireSomeUint, getStorage, setStorage,
                                ContractState.readSlot, ContractState.writeSlot,
                                Verity.require, Verity.bind, Bind.bind, Pure.pure,
                                Contract.run, hzero, hdeposits, hwithdrawals, depositsReserve,
                                withdrawalsReserve, hremaining, hunreserved,
                                hdepositable, henough, hpost, hbuffered, hnext]
                          | some depositedNextReportAdjusted =>
                              simp only [ReserveContract.buffered,
                                ReserveContract.storedDepositsReserve,
                                ReserveContract.unfinalizedStETH,
                                ReserveContract.depositedPostReport,
                                ReserveContract.depositedNextReportAdjusted] at hdeposits hwithdrawals hremaining hunreserved hdepositable hpost hbuffered hnext
                              simp [ReserveContract.withdrawWithGuards,
                                ReserveContract.withdraw, observeVerity, specTx,
                                ReserveContract.buffered,
                                ReserveContract.storedDepositsReserve,
                                ReserveContract.unfinalizedStETH,
                                ReserveContract.depositedPostReport,
                                ReserveContract.depositedNextReportAdjusted,
                                modelWithdrawDepositableEther,
                                spendDepositableEther, getBufferedEtherAllocation,
                                getDepositableEther, decode, min, minWord,
                                requireSomeUint, getStorage, setStorage,
                                ContractState.readSlot, ContractState.writeSlot,
                                Verity.require, Verity.bind, Bind.bind, Pure.pure,
                                Contract.run, hzero, hdeposits, hwithdrawals, depositsReserve,
                                withdrawalsReserve, hremaining, hunreserved,
                                hdepositable, henough, hpost, hbuffered, hnext]
                              simp [ContractState.storage, HSub.hSub]
                · simp [ReserveContract.withdrawWithGuards,
                    ReserveContract.withdraw, observeVerity, specTx,
                    modelWithdrawDepositableEther, spendDepositableEther,
                    getBufferedEtherAllocation, getDepositableEther, decode,
                    min, minWord, requireSomeUint, getStorage, setStorage,
                    ContractState.readSlot, ContractState.writeSlot,
                    Verity.require, Verity.bind, Bind.bind, Pure.pure,
                    Contract.run, hzero, hdeposits, hwithdrawals, depositsReserve,
                    withdrawalsReserve, hremaining, hunreserved,
                    hdepositable, henough]

theorem verity_revert_rolls_back (inputs : WithdrawInputs) (state : ContractState) (amount : Word)
    (reason : String) (rollback : ContractState)
    (h : (ReserveContract.withdrawWithGuards inputs amount).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  cases hc : ReserveContract.withdrawWithGuards inputs amount state <;>
    simp [hc] at h
  exact h.2.symm

/- Explicit partition/spend invariant: the pre-state allocation is retained as
the witness, the amount is bounded by its depositable partitions, the committed
buffer is exactly the checked subtraction from the allocation total, and the
stored deposits reserve follows the pinned source update. Together these
exclude consuming the allocation's withdrawals reserve. -/
def withdrawalPartitionSpendInvariant
    (before after : ReserveState) (amount : Word) : Prop :=
  ∃ allocation depositable,
    getBufferedEtherAllocation before = some allocation ∧
    getDepositableEther allocation = some depositable ∧
    amount ≤ depositable ∧
    safeSub allocation.total amount = some after.buffered ∧
    after.storedDepositsReserve =
      (if before.storedDepositsReserve > amount then
        before.storedDepositsReserve - amount
      else 0) ∧
    after.unfinalizedStETH = before.unfinalizedStETH

theorem committed_preserves_withdrawal_reserve
    (before after : ReserveState) (amount : Word)
    (h : spendDepositableEther before amount = .committed after) :
    withdrawalPartitionSpendInvariant before after amount := by
  unfold spendDepositableEther at h
  cases ha : getBufferedEtherAllocation before with
  | none => simp [ha] at h
  | some allocation =>
      simp only [ha] at h
      cases hd : getDepositableEther allocation with
      | none => simp [hd] at h
      | some depositable =>
          simp only [hd] at h
          by_cases henough : amount ≤ depositable
          · simp [henough] at h
            cases hp : safeAdd before.depositedPostReport amount with
            | none => simp [hp] at h
            | some depositedPostReport =>
                simp only [hp] at h
                cases hb : safeSub allocation.total amount with
                | none => simp [hb] at h
                | some buffered =>
                    simp only [hb] at h
                    cases hn : safeAdd before.depositedNextReportAdjusted amount with
                    | none => simp [hn] at h
                    | some depositedNextReportAdjusted =>
                        simp [hn] at h
                        subst after
                        exact ⟨allocation, depositable, ha, hd, henough, hb, rfl, rfl⟩
          · simp [henough] at h

/-- Observable non-interference at the actual Verity boundary. -/
theorem verity_commit_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (ReserveContract.withdrawWithGuards inputs amount).run state = .success () after) :
    withdrawalPartitionSpendInvariant (decode state) (decode after) amount := by
  have hsim := verity_execution_simulates_spec state amount inputs
  rw [h] at hsim
  cases hm : modelWithdrawDepositableEther inputs (decode state) amount with
  | reverted reason => simp [observeVerity, specTx, hm] at hsim
  | committed reserveAfter =>
      simp [observeVerity, specTx, hm] at hsim
      have hspend : spendDepositableEther (decode state) amount = .committed reserveAfter := by
        unfold modelWithdrawDepositableEther at hm
        split at hm <;> try contradiction
        split at hm <;> try contradiction
        split at hm <;> try contradiction
        exact hm
      rw [hsim]
      exact committed_preserves_withdrawal_reserve _ _ amount hspend

/-! ## Wave 1 registered-parent strengthening: wrapper guards and queue freshness

`unfinalizedStETH` on `ReserveState` is a cached word (issue #2 of
`report/P-RESERVE-1.md`): the real allocation calls
`_withdrawalQueue().unfinalizedStETH()` on every read. The definitions below
name that gap explicitly instead of leaving it implicit, and the theorem
`committed_preserves_effective_withdrawals_reserve` proves the property the
report says the CHECKED guarantee never established: the *effective*
queue-facing reserve — not just the restated `storedDepositsReserve` field —
is unchanged by a legal spend. `staleQueueCacheKillLine` then shows that
guarantee is only as strong as the freshness hypothesis it depends on: once
the cache is stale, the same "spend only depositsReserve + unreserved" spend
can still shrink the reserve a live WithdrawalQueue call would report. -/

/-- Registered guard bundle for the Wave 1 parent: both `withdrawDepositableEther`
wrapper booleans must hold. `canDeposit` is Lido's live bunker/pause
deposit-enabled check (line ~815); `authorizedRouter` is the router-only
`_auth` guard. Neither is bypassed by the registered parent below — see
`modelWithdrawDepositableEther`, which the parent now takes as its premise
instead of jumping straight to `spendDepositableEther`. -/
def scopedWithdrawGuards (inputs : WithdrawInputs) : Prop :=
  inputs.canDeposit ∧ inputs.authorizedRouter

/-- The state's cached `unfinalizedStETH` field equals a live
`WithdrawalQueue.unfinalizedStETH()` CALL (source line 612) taken at spend
time. This names the freshness the registered parent depends on: it is not
derivable from `ReserveState` alone, and nothing in this file enforces it —
see `staleQueueCacheKillLine` for what fails when it does not hold. -/
def freshQueueCache (state : ReserveState) (liveUnfinalizedStETH : Word) : Prop :=
  state.unfinalizedStETH = liveUnfinalizedStETH

/-- The queue-facing reserve computed against an arbitrary (live or stale)
`unfinalizedStETH` value instead of the state's cached field. Under
`freshQueueCache`, this coincides with `effectiveWithdrawalsReserve`
(`liveEffectiveWithdrawalsReserve_eq_of_eq`). -/
def liveEffectiveWithdrawalsReserve (s : ReserveState) (liveUnfinalizedStETH : Word) : Word :=
  let deposits := minWord s.buffered s.storedDepositsReserve
  minWord (s.buffered - deposits) liveUnfinalizedStETH

private theorem safeAdd_val {a b c : Word} (h : safeAdd a b = some c) :
    c.val = a.val + b.val := by
  by_cases hc : a.val + b.val > Verity.Core.MAX_UINT256
  · exfalso
    have hnone : safeAdd a b = none := by simp [safeAdd, hc]
    rw [hnone] at h
    cases h
  · have heq : safeAdd a b = some (a + b) := by simp [safeAdd, hc]
    rw [heq] at h
    obtain rfl := Option.some.inj h
    have hlt : a.val + b.val < Verity.Core.Uint256.modulus := by
      have hm := Verity.Core.Uint256.max_uint256_succ_eq_modulus
      omega
    exact Verity.Core.Uint256.add_eq_of_lt hlt

private theorem safeSub_val {a b c : Word} (h : safeSub a b = some c) :
    c.val = a.val - b.val ∧ b.val ≤ a.val := by
  unfold safeSub at h
  split at h
  · cases h
  · rename_i hle
    obtain rfl := Option.some.inj h
    have hle' : b.val ≤ a.val := by omega
    exact ⟨Verity.Core.Uint256.sub_eq_of_le hle', hle'⟩

private theorem minWord_val (a b : Word) : (minWord a b).val = Min.min a.val b.val := by
  unfold minWord
  split
  · next h => simp only [Verity.Core.Uint256.le_def] at h; omega
  · next h => simp only [Verity.Core.Uint256.le_def] at h; omega

/-- Unpacks a successful `getBufferedEtherAllocation`: the two internal
`safeSub` calls both succeeded, and the resulting allocation's fields are
exactly the pinned formulas (not merely some opaque witness). -/
private theorem getBufferedEtherAllocation_some (s : ReserveState) (a : Allocation)
    (h : getBufferedEtherAllocation s = some a) :
    ∃ r u,
      safeSub s.buffered (minWord s.buffered s.storedDepositsReserve) = some r ∧
      safeSub r (minWord r s.unfinalizedStETH) = some u ∧
      a = ⟨s.buffered, u, minWord s.buffered s.storedDepositsReserve,
        minWord r s.unfinalizedStETH⟩ := by
  unfold getBufferedEtherAllocation at h
  cases hrem : safeSub s.buffered (minWord s.buffered s.storedDepositsReserve) with
  | none => simp [hrem] at h
  | some r =>
    cases hunr : safeSub r (minWord r s.unfinalizedStETH) with
    | none => simp [hrem, hunr] at h
    | some u =>
      refine ⟨r, u, rfl, hunr, ?_⟩
      simp [hrem, hunr] at h
      exact h.symm

theorem effectiveWithdrawalsReserve_val (s : ReserveState) :
    (effectiveWithdrawalsReserve s).val =
      Min.min (s.buffered.val - Min.min s.buffered.val s.storedDepositsReserve.val)
        s.unfinalizedStETH.val := by
  unfold effectiveWithdrawalsReserve
  have hDle : minWord s.buffered s.storedDepositsReserve ≤ s.buffered := by
    have hv := minWord_val s.buffered s.storedDepositsReserve
    simp only [Verity.Core.Uint256.le_def]
    omega
  rw [minWord_val, Verity.Core.Uint256.sub_eq_of_le hDle, minWord_val]

/-- The non-restatement form of `withdrawalPartitionSpendInvariant` (report
issue #1): a legal spend leaves the *effective*, min-capped queue-facing
reserve unchanged, not merely the raw `storedDepositsReserve` field. Proved
independently of `withdrawalPartitionSpendInvariant`, from the pinned
`getBufferedEtherAllocation` formulas. -/
theorem committed_preserves_effective_withdrawals_reserve
    (before after : ReserveState) (amount : Word)
    (h : spendDepositableEther before amount = .committed after) :
    effectiveWithdrawalsReserve after = effectiveWithdrawalsReserve before := by
  obtain ⟨allocation, depositable, ha, hd, henough, hb, hs, hu⟩ :=
    committed_preserves_withdrawal_reserve before after amount h
  obtain ⟨r, u, hrem, hunr, haeq⟩ := getBufferedEtherAllocation_some before allocation ha
  subst haeq
  simp only [getDepositableEther] at hd
  have hd' := safeAdd_val hd
  have hrem' := safeSub_val hrem
  have hunr' := safeSub_val hunr
  have hb' := safeSub_val hb
  have henough' : amount.val ≤ depositable.val := henough
  have hDminBefore := minWord_val before.buffered before.storedDepositsReserve
  have hWRminBefore := minWord_val r before.unfinalizedStETH
  have hsval : after.storedDepositsReserve.val =
      if amount.val < before.storedDepositsReserve.val
      then before.storedDepositsReserve.val - amount.val else 0 := by
    simp only [hs, Verity.Core.Uint256.val_ite, Verity.Core.Uint256.lt_def]
    split
    · rename_i hc
      exact Verity.Core.Uint256.sub_eq_of_le (Nat.le_of_lt hc)
    · exact Verity.Core.Uint256.val_zero
  apply Verity.Core.Uint256.ext
  rw [effectiveWithdrawalsReserve_val, effectiveWithdrawalsReserve_val, hu, hsval]
  have hbval : after.buffered.val = before.buffered.val - amount.val := hb'.1
  rw [hbval]
  split <;> omega

theorem liveEffectiveWithdrawalsReserve_eq_of_eq (s : ReserveState) (v : Word)
    (h : s.unfinalizedStETH = v) :
    liveEffectiveWithdrawalsReserve s v = effectiveWithdrawalsReserve s := by
  unfold liveEffectiveWithdrawalsReserve effectiveWithdrawalsReserve
  rw [← h]

/-- Under a fresh queue cache, a legal spend preserves the *live*
WithdrawalQueue-facing reserve too, not just the cached-field version. This is
what `freshQueueCache` buys the registered parent — see
`staleQueueCacheKillLine` for the counterexample without it. -/
theorem committed_preserves_live_effective_withdrawals_reserve
    (before after : ReserveState) (amount live : Word)
    (hfresh : freshQueueCache before live)
    (h : spendDepositableEther before amount = .committed after) :
    liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live := by
  obtain ⟨_, _, _, _, _, _, _, hu⟩ := committed_preserves_withdrawal_reserve before after amount h
  have hafterfresh : after.unfinalizedStETH = live := hu.trans hfresh
  rw [liveEffectiveWithdrawalsReserve_eq_of_eq after live hafterfresh,
    liveEffectiveWithdrawalsReserve_eq_of_eq before live hfresh]
  exact committed_preserves_effective_withdrawals_reserve before after amount h

/-- Named premise-necessity kill-line: without a fresh queue cache, the same
"spend only depositsReserve + unreserved" transition that
`committed_preserves_effective_withdrawals_reserve` shows is always safe
against the *cached* field can still raid the reserve a live
`WithdrawalQueue.unfinalizedStETH()` call would report. Concretely witnessed
by `staleQueueCacheKillLine_holds` and by
`LidoSRv3.Tests.ReserveMutants.stale_queue_cache_mutant_counterexample`.

Scope note: this refutes the freshness-DROPPED sibling of the registered
parent `PReserve1.source_spend_preserves_withdrawal_reserve` — it demonstrates
that the parent's `freshQueueCache` hypothesis cannot be removed, not that the
parent is false (the parent cannot be instantiated on the stale-cache
witness). The parent kill-lines, each with freshness retained, are
`LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_kill_line_refutes_parent`
(a mutation of the spend transition, killing the partition-invariant and
live-reserve conjuncts) and
`LidoSRv3.Tests.ReserveMutants.guard_drop_kill_line_refutes_parent`
(a dropped `canDeposit` guard, killing the `scopedWithdrawGuards` conjunct). -/
def staleQueueCacheKillLine : Prop :=
  ¬ ∀ (before after : ReserveState) (amount live : Word),
    spendDepositableEther before amount = .committed after →
    liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live

private def staleQueueCacheBefore : ReserveState :=
  { buffered := Verity.Core.Uint256.ofNat 100
    storedDepositsReserve := Verity.Core.Uint256.ofNat 20
    unfinalizedStETH := Verity.Core.Uint256.ofNat 50
    depositedPostReport := Verity.Core.Uint256.ofNat 3
    depositedNextReportAdjusted := Verity.Core.Uint256.ofNat 2 }

private def staleQueueCacheAfter : ReserveState :=
  { buffered := Verity.Core.Uint256.ofNat 50
    storedDepositsReserve := Verity.Core.Uint256.ofNat 0
    unfinalizedStETH := Verity.Core.Uint256.ofNat 50
    depositedPostReport := Verity.Core.Uint256.ofNat 53
    depositedNextReportAdjusted := Verity.Core.Uint256.ofNat 52 }

theorem staleQueueCacheKillLine_holds : staleQueueCacheKillLine := by
  intro hforall
  have hcex := hforall staleQueueCacheBefore staleQueueCacheAfter
    (Verity.Core.Uint256.ofNat 50) (Verity.Core.Uint256.ofNat 80) (by decide)
  exact absurd hcex (by decide)

end LidoSRv3.Audit.SolidityReserve
