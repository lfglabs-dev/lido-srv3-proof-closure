import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
Executable falsifier vectors for the pinned P-DEPOSIT-1 deposit path
(`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`).

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
private def cfg : SourceDepositConfig := ⟨32, 32, 48, 48, 96⟩

/- A hypothetical deployment whose pull scale is twice its push scale. -/
private def cfgSkewed : SourceDepositConfig := ⟨64, 32, 48, 48, 96⟩

/- Three well-formed keys, an ample block cap and ample Lido liquidity. -/
private def inp : SourceDepositInput := ⟨true, 10, 320, 144, 288, 1000, true, 1000⟩

/- Positive vector: three keys are pulled and pushed at 32 each, and the router
   balance at `StakingRouter.sol` line 993 equals the line 980 snapshot. -/
example : run cfg inp = .committedDeposits 3 96 96 1000 := by decide

/- The deployed configuration is conserving, so the line 996 assert holds. -/
example : ConservingConfig cfg := by decide

/- The line 996 assert is load-bearing, not decorative: a deployment whose
   `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (line 972) exceeds `DEPOSIT_SIZE`
   (`BeaconChainDepositor.sol` line 24) strands 96 wei in the router. -/
example :
    run cfgSkewed inp = .committedDeposits 3 192 96 1096 ∧
      ¬ ConservingConfig cfgSkewed := by decide

/- Status guard, `StakingRouter.sol` line 946. -/
example : run cfg { inp with moduleActive := false } = .revertStakingModuleNotActive := by decide

/- Zero-deposit guard, line 959: a zero block cap aborts before any pull. -/
example : run cfg { inp with maxDepositsPerBlock := 0 } = .revertZeroDeposits := by decide

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

/- Batches are checked against `PUBLIC_KEY_LENGTH * keysCount`, so the router's
   own alignment check at lines 966--967 already discharges
   `BeaconChainDepositor`'s line 43 guard: that revert is unreachable. -/
example :
    ∀ n : Fin 5,
      run cfg { inp with
                  publicKeysBatchLength := 48 * n.val
                  signaturesBatchLength := 96 * n.val }
        ≠ .revertInvalidPublicKeysBatchLength := by decide

end LidoSRv3.Tests.DepositVectors
