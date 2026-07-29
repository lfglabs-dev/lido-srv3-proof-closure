import LidoSRv3.SpecProofs

namespace LidoSRv3

private def shapeTestModule : Module :=
  { id := 1
    status := ModuleStatus.active
    stakeShareLimitBps := 10000
    priorityExitShareThresholdBps := 0
    depositableValidators := 0
    maxDepositsPerBlock := 1
    minDepositBlockDistance := 1
    lastDepositWei := 0
    depositedValidatorsCount := 0
    exitedValidatorsCount := 0
    validatorsBalanceGwei := 0
    totalModuleStakeWei := 0
    supportsTopUp := true
    moduleFeeBps := 0
    treasuryFeeBps := 0
    rewardRecipient := 0 }

private def shapeTestState : State :=
  { bufferedEther := 10 * oneGweiWei
    depositReserve := 10 * oneGweiWei
    withdrawalReserve := 0
    routerEthBalanceWei := 0
    beaconDepositSinkWei := 0
    routerBalanceGwei := 0
    modules := [shapeTestModule]
    lastAcceptedReport := none }

private def shapeRun (allocations : List Wei) : Option State :=
  topUpTransition shapeTestState 1 (10 * oneGweiWei) 10 true
    2 2 2 [2 * oneGweiWei, 2 * oneGweiWei] allocations

-- Boundary matrix. The two short zero-sum cases are mutation tests: restoring
-- an unconditional returned-length equality makes these examples fail.
example : shapeRun [] = some shapeTestState := by native_decide
example : shapeRun [0] = some shapeTestState := by native_decide
example : shapeRun [oneGweiWei] = none := by native_decide
example : shapeRun [0, 0] = some shapeTestState := by native_decide
example : (shapeRun [oneGweiWei, oneGweiWei]).isSome := by native_decide
example : shapeRun [0, 0, 0] = none := by native_decide
example : shapeRun [oneGweiWei, oneGweiWei, oneGweiWei] = none := by
  native_decide

end LidoSRv3
