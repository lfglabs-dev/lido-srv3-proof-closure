import LidoSRv3.Audit.Guarantees.PTopup1

/-!
Executable falsifier vectors for the pinned P-TOPUP-1 beacon-chain top-up path
(`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`).

Each vector names the source line whose mutation it detects, so the
correspondence in `LidoSRv3.Audit.Source.TopupCorrespondence` cannot be silently
loosened into something that still type-checks.

Most vectors run against a scaled configuration -- `1 gwei` is 10 and
`MIN_DEPOSIT` is 100 -- so the guard boundaries stay readable.  The last block
re-runs the load-bearing ones against `pinnedConfig`, with real wei, so the
scaling cannot hide a constant that only works small.
-/

namespace LidoSRv3.Tests.TopupVectors

open LidoSRv3.Audit.SolidityTopup

/- Several vectors evaluate the whole 22-branch guard chain plus both loops
   inside `decide`; the default elaborator recursion budget is not quite enough
   for the longest of them.  This raises the budget only, and does not weaken any
   check. -/
set_option maxRecDepth 4000

/- A scaled deployment: both pubkey lengths are 48 (`StakingRouter.sol` line 57,
   `BeaconChainDepositor.sol` line 21), `1 gwei` is 10, `MIN_DEPOSIT`
   (`BeaconChainDepositor.sol` line 28) is 100, and `type(uint64).max` is 1000. -/
private def cfg : SourceTopupConfig := ⟨48, 48, 10, 100, 1000⟩

/- The gateway caller, three well-formed keys, an ample block cap and ample Lido
   liquidity.  The module returns 100 + 200 + 150 = 450 wei of allocations. -/
private def inp : SourceTopupInput :=
  ⟨true, 3, 3, [200, 200, 200], [48, 48, 48], true, true, true, 100, 900, true,
    [100, 200, 150], 5000, 5000⟩

/-! ## The committing push -/

/- Positive vector: three keys, 450 wei pulled at source line 744 and 450 wei
   pushed by the loop at `BeaconChainDepositor.sol` lines 79--107, and the router
   balance the line 755 assert observes equals the line 742 snapshot. -/
example : run cfg inp = .committedTopUp 3 450 450 5000 := by decide

/- The router does not need a prior balance: the pull at line 744 funds the push
   exactly.  Unlike the 32-ETH path there is no separately-configured push scale
   that could outrun the pull. -/
example : run cfg { inp with routerBalanceBefore := 0 } = .committedTopUp 3 450 450 0 := by
  decide

/- Conservation holds for every key count the block cap admits, and the two
   value-conservation guards stay unreachable throughout.  A mutation that made
   the pull and the push read different arrays would break this. -/
example :
    ∀ n : Fin 4,
      run cfg { inp with
                  keyIndicesLength := n.val + 1
                  operatorIdsLength := n.val + 1
                  topUpLimits := List.replicate (n.val + 1) 200
                  pubkeyLengths := List.replicate (n.val + 1) 48
                  allocations := List.replicate (n.val + 1) 100 }
        = .committedTopUp (n.val + 1) (100 * (n.val + 1)) (100 * (n.val + 1)) 5000 := by
  decide

/- The line 755 `assert` is *discharged*, not load-bearing: no key count reaches
   it as a failure, and no key count outruns the router's funded balance.  This
   is the top-up path's structural difference from P-DEPOSIT-1 and is the
   plausible place to silently weaken the model. -/
example :
    ∀ n : Fin 4,
      run cfg { inp with
                  keyIndicesLength := n.val + 1
                  operatorIdsLength := n.val + 1
                  topUpLimits := List.replicate (n.val + 1) 200
                  pubkeyLengths := List.replicate (n.val + 1) 48
                  allocations := List.replicate (n.val + 1) 100 }
            ≠ .revertAssertBalanceUnchanged ∧
        run cfg { inp with
                  keyIndicesLength := n.val + 1
                  operatorIdsLength := n.val + 1
                  topUpLimits := List.replicate (n.val + 1) 200
                  pubkeyLengths := List.replicate (n.val + 1) 48
                  allocations := List.replicate (n.val + 1) 100 }
            ≠ .revertInsufficientRouterBalance := by
  decide

/-! ## Authorization, source line 686 -/

/- `_checkAppAuth(_getTopUpGateway())` runs before `_validateTopUpInputs` at line
   687 and before the module lookup at line 689, so it must win over every later
   guard.  Modelling it after input validation -- or omitting it, which
   classifies an unauthorized call as a commit -- is the plausible mistake. -/
example : run cfg { inp with callerIsTopUpGateway := false } = .revertNotAuthorized := by decide

example :
    run cfg { inp with callerIsTopUpGateway := false, keyIndicesLength := 0,
                       moduleActive := false } = .revertNotAuthorized := by decide

/- An unauthorized call with an empty allocation set must not slip into the line
   741 commit. -/
example :
    run cfg { inp with callerIsTopUpGateway := false, allocations := [] }
      ≠ .committedNoTopUp := by decide

/-! ## Input validation, `_validateTopUpInputs`, source lines 761--782 -/

/- `EmptyKeysList`, lines 769--771: it precedes the length comparison at line
   773, so a zero `n` against nonempty arrays is `EmptyKeysList`, not
   `ArraysLengthMismatch`. -/
example : run cfg { inp with keyIndicesLength := 0 } = .revertEmptyKeysList := by decide

/- `ArraysLengthMismatch`, lines 773--775, once for each of the three compared
   arrays. -/
example : run cfg { inp with operatorIdsLength := 2 } = .revertArraysLengthMismatch := by decide

example : run cfg { inp with topUpLimits := [200, 200] } = .revertArraysLengthMismatch := by
  decide

example : run cfg { inp with pubkeyLengths := [48, 48] } = .revertArraysLengthMismatch := by
  decide

/- `WrongPubkeyLength`, lines 778--780. -/
example : run cfg { inp with pubkeyLengths := [48, 47, 48] } = .revertWrongPubkeyLength := by
  decide

/- The whole of `_validateTopUpInputs` runs at line 687, *before* the module
   lookup at line 689 and the status check at line 691.  Reordering them is a
   plausible mistake and is rejected here. -/
example :
    run cfg { inp with pubkeyLengths := [48, 47, 48], moduleExists := false,
                       moduleActive := false } = .revertWrongPubkeyLength := by decide

/-! ## Module state, source lines 689--694 -/

example : run cfg { inp with moduleExists := false } = .revertStakingModuleUnregistered := by
  decide

example : run cfg { inp with moduleActive := false } = .revertStakingModuleNotActive := by decide

/- `SRUtils._requireWCType2`, line 694: top-up is only supported for 0x02
   withdrawal credentials. -/
example :
    run cfg { inp with wcTypeIsType2 := false } = .revertWrongWithdrawalCredentialsType := by
  decide

/- The status check at line 691 precedes the credentials check at line 694. -/
example :
    run cfg { inp with moduleActive := false, wcTypeIsType2 := false }
      = .revertStakingModuleNotActive := by decide

/-! ## The cap and the gwei rounding, source lines 696--706 -/

/- `1 gwei` is a unit literal, so a zero divisor is a totality guard for Lean's
   total `%`, not a reachable source branch.  Lean's `n % 0 = n` must not be
   allowed to fabricate a rounded amount. -/
example : run { cfg with gwei := 0 } inp = .revertGweiModuloByZero := by decide

/- Line 700 is a `min`, not the module allocation alone: a block cap below the
   allocation binds. -/
example :
    run cfg { inp with maxTopUpPerBlockGwei := 40 } = .revertModuleReturnExceedTarget := by
  decide

/- Line 706 rounds the cap *down* to a gwei multiple.  455 rounds to 450 and
   admits the 450-wei top-up; 449 rounds to 440 and rejects it.  Dropping the
   rounding would wrongly accept the second. -/
example : run cfg { inp with moduleAllocationEth := 455 } = .committedTopUp 3 450 450 5000 := by
  decide

example :
    run cfg { inp with moduleAllocationEth := 449 } = .revertModuleReturnExceedTarget := by
  decide

/-! ## The paused-Lido guard, source lines 713--715 -/

/- The guard fires only on the *zero* rounded-amount path, where the
   `CAN_NOT_DEPOSIT` check inside `withdrawDepositableEther` would be bypassed.
   The module call at lines 717--718 is still made when Lido is live, precisely
   so the module queue cursor can advance. -/
example :
    run cfg { inp with moduleAllocationEth := 0, lidoCanDeposit := false, allocations := [] }
      = .revertLidoDepositsPaused := by decide

example :
    run cfg { inp with moduleAllocationEth := 0, allocations := [] } = .committedNoTopUp := by
  decide

/- With a nonzero rounded amount the same paused flag produces a *different*
   revert: `CAN_NOT_DEPOSIT` at `Lido.sol` line 870, reached through line 744.
   Collapsing the two into one guard is the plausible mistake. -/
example : run cfg { inp with lidoCanDeposit := false } = .revertLidoCannotDeposit := by decide

/-! ## The allocation loop, source lines 722--734 -/

/- `AmountNotAlignedToGwei`, lines 724--726. -/
example :
    run cfg { inp with allocations := [100, 205, 150] } = .revertAmountNotAlignedToGwei := by
  decide

/- `_topUpLimits[i]` at line 728 is an out-of-bounds read -- `Panic(0x32)` -- when
   the module returns more allocations than there are keys.  The `unchecked`
   block at line 722 disables arithmetic wrap checks, not array bounds checks, so
   this really is a whole-transaction abort. -/
example :
    run cfg { inp with allocations := [100, 200, 150, 100] }
      = .revertTopUpLimitIndexOutOfBounds := by decide

/- Within that index the alignment check at line 724 still runs first. -/
example :
    run cfg { inp with allocations := [100, 200, 150, 105] }
      = .revertAmountNotAlignedToGwei := by decide

/- `AllocationExceedsLimit`, lines 728--730: the per-key limit binds. -/
example :
    run cfg { inp with allocations := [100, 250, 150] } = .revertAllocationExceedsLimit := by
  decide

/- The comparison at line 728 is `>`, not `>=`: an allocation exactly at the
   limit is admitted. -/
example :
    run cfg { inp with allocations := [100, 200, 200] } = .committedTopUp 3 500 500 5000 := by
  decide

/-! ## The over-target guard, source lines 737--739 -/

example :
    run cfg { inp with moduleAllocationEth := 400 } = .revertModuleReturnExceedTarget := by
  decide

/- The comparison at line 737 is `>`, not `>=': a sum exactly at the rounded
   target is admitted. -/
example : run cfg { inp with moduleAllocationEth := 450 } = .committedTopUp 3 450 450 5000 := by
  decide

/-! ## The zero-sum short circuit, source line 741 -/

/- `amount > 0` is false, so no pull and no push happen and control falls through
   to the event at line 758.  This is a *commit*, not a rollback: the
   `allocateDeposits` call at lines 717--718 has already advanced the module's
   queue cursor.  Classifying it as a revert is the plausible mistake. -/
example :
    run cfg { inp with allocations := [] } = .committedNoTopUp ∧
      (run cfg { inp with allocations := [] }).reverts = false := by decide

/- A list of zero allocations is the same zero-sum branch, and must not become a
   `ZERO_AMOUNT` revert at `Lido.sol` line 873 -- line 741 short-circuits before
   the pull. -/
example : run cfg { inp with allocations := [0, 0, 0] } = .committedNoTopUp := by decide

/- The observation model agrees that the zero-sum branch commits. -/
example :
    (observation (0 : Nat) 1 [] ⟨[], [], []⟩ (run cfg { inp with allocations := [] })).result
      = .committed 1 ⟨[], [], []⟩ := by rfl

/-! ## The pull, `Lido.sol` lines 839--886 -/

/- `NOT_ENOUGH_ETHER`, `Lido.sol` line 842, reached through line 875. -/
example : run cfg { inp with lidoDepositableEther := 100 } = .revertLidoNotEnoughEther := by
  decide

/- Every reverting branch moves no wei in either direction: the pull at line 744
   is strictly after all of these guards. -/
example :
    (run cfg { inp with lidoDepositableEther := 100 }).pulled = 0 ∧
      (run cfg { inp with lidoDepositableEther := 100 }).pushed = 0 := by decide

/- The observation model classifies a reverting branch as `.reverted`. -/
example :
    (observation (0 : Nat) 1 [] ⟨[], [], []⟩ (run cfg { inp with lidoCanDeposit := false })).result
      = .reverted := by rfl

/-! ## The push loop, `BeaconChainDepositor.sol` lines 66--108 -/

/- `ArrayLengthMismatch`, line 74: the router validates `_pubkeys` against `n`,
   but `allocations` is the module's return value and is not length-checked
   before line 750. -/
example : run cfg { inp with allocations := [100, 200] } = .revertArrayLengthMismatch := by
  decide

/- `DepositAmountTooLow`, lines 92--94: an allocation below `MIN_DEPOSIT`. -/
example : run cfg { inp with allocations := [100, 200, 50] } = .revertDepositAmountTooLow := by
  decide

/- The `if (amount == 0) continue` at line 89 means a *zero* allocation is
   skipped rather than rejected as `DepositAmountTooLow`, and it contributes zero
   to the pull as well, so conservation is unaffected.  Treating zero as
   below-minimum is the plausible mistake. -/
example : run cfg { inp with allocations := [100, 200, 0] } = .committedTopUp 3 300 300 5000 := by
  decide

/- `AmountTooLarge`, lines 97--99: an allocation whose gwei value exceeds
   `type(uint64).max`. -/
example :
    run cfg { inp with topUpLimits := [200, 200, 30000], maxTopUpPerBlockGwei := 10000,
                       moduleAllocationEth := 50000, allocations := [100, 200, 20000],
                       routerBalanceBefore := 50000, lidoDepositableEther := 50000 }
      = .revertAmountTooLarge := by decide

/- The router's own pubkey check at lines 777--779 discharges
   `BeaconChainDepositor`'s per-key check at lines 82--84 whenever the two
   constants agree, and the check goes live again when they are split apart.
   Deleting the constructor -- rather than proving it unreachable -- is the
   plausible mistake. -/
example : run cfg inp ≠ .revertInvalidPublicKeyLength := by decide

example : run { cfg with publicKeyLength := 32 } inp = .revertInvalidPublicKeyLength := by decide

/-! ## The pinned constants, at real wei scale -/

/- Two 1-ETH top-ups under `pinnedConfig`: `1 gwei = 10^9`, `MIN_DEPOSIT = 1 ETH`,
   `type(uint64).max` as deployed.  The block cap is 10 ETH and the module is
   allocated 5 ETH. -/
private def inpPinned : SourceTopupInput :=
  ⟨true, 2, 2, [2000000000000000000, 2000000000000000000], [48, 48], true, true, true,
    10000000000, 5000000000000000000, true,
    [1000000000000000000, 1000000000000000000], 0, 10000000000000000000⟩

example :
    run pinnedConfig inpPinned
      = .committedTopUp 2 2000000000000000000 2000000000000000000 0 := by decide

/- `MIN_DEPOSIT` is 1 ether at the pinned scale: one gwei short of it reverts. -/
example :
    run pinnedConfig
        { inpPinned with allocations := [1000000000000000000, 999999999000000000] }
      = .revertDepositAmountTooLow := by decide

/- Alignment at the pinned scale is to 10^9 wei. -/
example :
    run pinnedConfig
        { inpPinned with allocations := [1000000000000000000, 1000000000000000001] }
      = .revertAmountNotAlignedToGwei := by decide

/- Conservation and the two discharged guards hold at the pinned scale too. -/
example :
    (run pinnedConfig inpPinned).pulled = (run pinnedConfig inpPinned).pushed ∧
      run pinnedConfig inpPinned ≠ .revertAssertBalanceUnchanged ∧
        run pinnedConfig inpPinned ≠ .revertInsufficientRouterBalance := by decide

end LidoSRv3.Tests.TopupVectors
