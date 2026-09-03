import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
Executable falsifier vectors for the pinned P-DEPOSIT-1 deposit path
(`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`).

Each vector names the source line whose mutation it detects, so the
correspondence in `LidoSRv3.Audit.Source.DepositCorrespondence` cannot be
silently loosened into something that still type-checks.
-/

namespace LidoSRv3.Tests.DepositVectors

open LidoSRv3.Audit.SolidityDeposit

/- The deployed configuration: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` equals
   `DEPOSIT_SIZE` (`StakingRouter.sol` line 65 / `BeaconChainDepositor.sol` line
   24), and both pubkey-length constants are 48 (`StakingRouter.sol` line 57,
   `BeaconChainDepositor.sol` line 21).  Units are 1-ether words. -/
def cfg : SourceDepositConfig := ⟨32, 32, 48, 48, 96⟩

/- A hypothetical deployment whose pull scale is twice its push scale. -/
def cfgSkewed : SourceDepositConfig := ⟨64, 32, 48, 48, 96⟩

/- Three well-formed keys, an ample block cap and ample
   Lido liquidity. -/
def inp : SourceDepositInput := ⟨true, 10, 320, 144, 288, 1000, true, 1000⟩

/- Positive vector: three keys are pulled and pushed at 32 each, and the router
   balance at `StakingRouter.sol` line 993 equals the line 980 snapshot. -/
example : run cfg inp = .committedDeposits 3 96 96 1000 := by decide

/- The deployed configuration is conserving, so the line 996 assert holds. -/
example : ConservingConfig cfg := by decide

/- The line 996 assert is load-bearing, not decorative: a deployment whose
   `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (line 972) exceeds `DEPOSIT_SIZE`
   (`BeaconChainDepositor.sol` line 24) would leave 96 wei in the router, so the
   assert fails and the whole transaction reverts.  Modelling this branch as a
   commit -- stranding the 96 wei -- is the plausible mistake, and it is rejected
   here: `run` must not return `committedDeposits` for a non-conserving config. -/
example :
    run cfgSkewed inp = .revertAssertBalanceUnchanged ∧
      ¬ ConservingConfig cfgSkewed := by decide

/- The mutant that drops the line 996 assert branch and commits instead is caught
   in both directions: the reverting classification and the absence of any commit
   for the skewed deployment. -/
example : (run cfgSkewed inp).reverts = true := by decide

example :
    ∀ n : Fin 4,
      run cfgSkewed { inp with publicKeysBatchLength := 48 * (n.val + 1)
                               signaturesBatchLength := 96 * (n.val + 1) }
        ≠ .committedDeposits (n.val + 1) (64 * (n.val + 1)) (32 * (n.val + 1))
            (1000 + 32 * (n.val + 1)) := by decide

/- No wei is stranded on that branch: a failing `assert` is a `Panic(0x01)` that
   rolls the whole transaction back. -/
example :
    (run cfgSkewed inp).pulled = 0 ∧ (run cfgSkewed inp).pushed = 0 := by decide

/- The trace/observation model agrees: the skewed deployment yields `.reverted`,
   not a commit. -/
example :
    (observation (0 : Nat) 1 [] ⟨[], [], []⟩ (run cfgSkewed inp)).result
      = .reverted := by rfl

/- A push scale that exceeds the pull scale reverts at line 996 as well; the
   assert is symmetric, not a one-sided "excess" check. -/
example :
    run ⟨32, 64, 48, 48, 96⟩ inp = .revertAssertBalanceUnchanged := by decide

/- If the router cannot fund a larger push scale, the value transfer at
   `BeaconChainDepositor.sol` line 57 reverts before the line 996 assert. -/
example :
    run ⟨32, 64, 48, 48, 96⟩ { inp with routerBalanceBefore := 0 }
      = .revertInsufficientRouterBalance := by decide

/- Status guard, `StakingRouter.sol` line 946. -/
example : run cfg { inp with moduleActive := false } = .revertStakingModuleNotActive := by decide

/- Zero-deposit guard, line 959: a zero block cap aborts before any pull. -/
example : run cfg { inp with maxDepositsPerBlock := 0 } = .revertZeroDeposits := by decide

/- The division at line 956 panics when the constructor immutable is zero;
   Lean's total `Nat.div` must not turn that source panic into `ZeroDeposits`. -/
example : run { cfg with maxEBType1 := 0 } inp = .revertMaxDepositsDivisionByZero := by decide

/- The modulo at line 966 likewise panics when `PUBKEY_LENGTH` is zero;
   Lean's total `% 0` must not allow the empty-batch commit. -/
example :
    run { cfg with pubkeyLength := 0 } inp = .revertPubkeyModuloByZero := by decide

example :
    run { cfg with pubkeyLength := 0 } { inp with publicKeysBatchLength := 0 }
      = .revertPubkeyModuloByZero := by decide

/- Alignment guard, line 966: a batch length that is not a multiple of 48
   reverts rather than truncating. -/
example : run cfg { inp with publicKeysBatchLength := 145 } = .revertWrongPubkeyLength := by decide

/- Over-target guard, line 969: the module may not return more keys than the
   block cap computed at lines 954--957. -/
example :
    run cfg { inp with maxDepositsPerBlock := 2 } = .revertModuleReturnExceedTarget := by decide

/- Liquidity guard, `Lido.sol` line 842 reached through line 875. -/
example :
    run cfg { inp with lidoDepositableEther := 50 } = .revertLidoNotEnoughEther := by decide

/- Pause guard, `Lido.sol` line 870. -/
example : run cfg { inp with lidoCanDeposit := false } = .revertLidoCannotDeposit := by decide

/- Signature batch guard, `BeaconChainDepositor.sol` lines 46--48. -/
example :
    run cfg { inp with signaturesBatchLength := 200 } = .revertInvalidSignaturesBatchLength := by
  decide

/- Every reverting branch moves no wei in either direction: the pull at line 983
   is strictly after all of these guards. -/
example :
    (run cfg { inp with lidoDepositableEther := 50 }).pulled = 0 ∧
      (run cfg { inp with lidoDepositableEther := 50 }).pushed = 0 := by decide

/- The empty-batch path at line 978 is a commit, not a rollback: the
   reentrancy-guard write at line 976 has already happened.  Classifying it as a
   revert is a plausible mistake and is rejected here. -/
example :
    run cfg { inp with publicKeysBatchLength := 0 } = .committedNoDeposits ∧
      (run cfg { inp with publicKeysBatchLength := 0 }).reverts = false := by decide

/- The empty-batch return at line 978 short-circuits *before* the line 996
   assert, so a skewed deployment does not revert on that path.  This is exactly
   why `source_nonconserving_deployment_reverts` carries a nonempty-batch
   hypothesis: without it the revert claim would be false here. -/
example :
    run cfgSkewed { inp with publicKeysBatchLength := 0 } = .committedNoDeposits ∧
      (run cfgSkewed { inp with publicKeysBatchLength := 0 }).reverts = false := by decide

/- With a nonempty batch the skewed deployment does revert, for every key count
   the block cap admits. -/
example :
    ∀ n : Fin 4,
      (run cfgSkewed { inp with publicKeysBatchLength := 48 * (n.val + 1)
                                signaturesBatchLength := 96 * (n.val + 1) }).reverts
        = true := by decide

/- Batches are checked against `PUBLIC_KEY_LENGTH * keysCount`, so the router's
   own alignment check at lines 966--967 already discharges
   `BeaconChainDepositor`'s line 43 guard: that revert is unreachable. -/
example :
    ∀ n : Fin 5,
      run cfg { inp with
                  publicKeysBatchLength := 48 * n.val
                  signaturesBatchLength := 96 * n.val }
        ≠ .revertInvalidPublicKeysBatchLength := by decide

/-! ## Kill-line for the registered abstract P-DEPOSIT-1 parent

The registered parent `PDeposit1.source_deposit_conserves_and_rolls_back`
proves, as its first conjunct, that every committed push of
`SolidityDeposit.run` moves the same wei in from Lido as out to the beacon
deposit contract (`pulled = pushed`, with the independently written
`depositsValue`/`pushedValue` formulas agreeing).  `SolidityDeposit.mutantRun`
is that same source-shaped model with the line 996 conservation assert dropped.
The theorems below are the kill-line: on the skewed deployment above, the
mutant *commits* a push whose pulled and pushed wei disagree -- the very
predicate the registered parent proves, false of the mutant of its own model. -/

/- Where the line 996 assert passes, the mutant is the honest `run` -- the
   deployed conserving configuration commits identically under both. -/
example : mutantRun cfg inp = run cfg inp := by decide

/- And on a guard-driven revert (a paused Lido), the mutant is again the honest
   `run`: the dropped assert changes nothing upstream of it. -/
example :
    mutantRun cfg { inp with lidoCanDeposit := false }
      = run cfg { inp with lidoCanDeposit := false } := by decide

/-- With the line 996 assert dropped, the skewed deployment commits the
mismatched push the honest `run` rolls back: 192 wei pulled from Lido against
96 wei pushed to the beacon deposit contract, stranding 96 wei in the router. -/
theorem dropped_conservation_assert_commits_skewed :
    mutantRun cfgSkewed inp = .committedDeposits 3 192 96 1096 := by
  decide

/-- **Kill-line for the registered P-DEPOSIT-1 parent.**  The parent's first
conjunct is `pulled = pushed` on every committed push of `SolidityDeposit.run`;
applied to the mutant of that same model that drops the line 996 assert, the
same predicate fails on a committing outcome. -/
theorem dropped_conservation_assert_breaks_pulled_eq_pushed :
    (mutantRun cfgSkewed inp).pulled ≠ (mutantRun cfgSkewed inp).pushed := by
  decide

/-- The same refutation in the registered parent's exact first-conjunct shape:
the universally quantified commit-branch conservation predicate, transported
onto `mutantRun`, is false. -/
theorem dropped_conservation_assert_refutes_commit_conservation :
    ¬ (∀ keys pulled pushed balanceAfter,
        mutantRun cfgSkewed inp = .committedDeposits keys pulled pushed balanceAfter →
          pulled = pushed ∧ depositsValue cfgSkewed inp = pushedValue cfgSkewed inp) :=
  fun h => absurd (h 3 192 96 1096 dropped_conservation_assert_commits_skewed).1
    (by decide)

end LidoSRv3.Tests.DepositVectors
