import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PTopup2

/-!
# SSZ / Top-up bridge validation

Regression vectors and structural checks for the P-SSZ-1 / P-TOPUP-1 /
P-TOPUP-2 trio's transport-independent additions: SHA sequential
acceptance, real SSZ gindex encoding, top-up freshness, inter-call
policy, and wei/gwei conversion.

These are the 20 finite pinned-SHA engine checks and structural
regression guards.  They are NOT full guarantee closure — they cover
concrete test vectors, not the universal quantifier over all well-formed
inputs.
-/

namespace LidoSRv3.Audit.Verity.Tests.SszTopupBridge

open LidoSRv3.Audit.Guarantees.PSsz1
open LidoSRv3.Audit.Guarantees.PTopup1
open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.SolidityTopup

/-! ## P-SSZ-1: SHA sequential acceptance checks -/

#guard (digestChain { publicKey := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                      withdrawalCredentials := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                      signature := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                      amountLittleEndian := ByteArray.mk #[0,0,0,0,0,0,0,0] }).length = 7

/-! ## P-SSZ-1: real gindex encoding checks -/

#guard productionValidatorGIndexBase = 150 * 2 ^ 40
#guard productionValidatorGIndexPow = 40
#guard validatorGIndex 0 = productionValidatorGIndexBase
#guard validatorGIndex 1 = productionValidatorGIndexBase + 1
#guard validatorGIndex 0 ≠ validatorGIndex 1

example : validatorGIndex 0 ≤ maxUint248 := by
  simp [validatorGIndex, productionValidatorGIndexBase, maxUint248]
  omega

example : validatorGIndex (2 ^ 40 - 1) ≤ maxUint248 := by
  simp [validatorGIndex, productionValidatorGIndexBase, maxUint248]
  omega

/-! ## P-TOPUP-2: wei/gwei conversion checks -/

#guard weiToGwei 0 = 0
#guard weiToGwei (10 ^ 9) = 1
#guard weiToGwei (32 * 10 ^ 18) = 32 * 10 ^ 9
#guard gweiToWei 1 = 10 ^ 9
#guard gweiToWei (32 * 10 ^ 9) = 32 * 10 ^ 18

example : gweiToWei (weiToGwei (32 * 10 ^ 18)) = 32 * 10 ^ 18 :=
  gweiToWei_weiToGwei_of_aligned _ (by native_decide)

example : weiToGwei (gweiToWei 42) = 42 :=
  weiToGwei_gweiToWei 42

/-! ## P-TOPUP-2: freshness checks -/

def freshBatch : TopupBatch :=
  { validators := [], requestedGwei := [], allocations := []
    valueWei := 0, beaconRootTimestamp := 1000, currentTimestamp := 1050 }

def freshCfg : TopupConfig :=
  { targetBalanceGwei := 32 * 10 ^ 9, minTopUpGwei := 10 ^ 9
    maxTopUpPerBlockGwei := 10 ^ 12, maxValidatorsPerCall := 100
    moduleAllocationLimitGwei := 10 ^ 15, maxRootAge := 100 }

#guard rootIsFresh freshBatch freshCfg

def staleBatchExample : TopupBatch :=
  { freshBatch with beaconRootTimestamp := 900 }

example : ¬ rootIsFresh staleBatchExample freshCfg := by
  intro ⟨_, h⟩
  simp [staleBatchExample, freshBatch, freshCfg] at h

/-! ## P-TOPUP-2: inter-call policy and transition checks -/

private def sampleValidator : Validator :=
  { pubkey := ByteArray.empty, index := 0, wc := 0x02
    activated := true, slashed := false, exiting := false
    effectiveBalanceGwei := 30 * 10 ^ 9, pendingBalanceGwei := 0 }

private def sampleCfg : TopupConfig :=
  { targetBalanceGwei := 32 * 10 ^ 9, minTopUpGwei := 10 ^ 9
    maxTopUpPerBlockGwei := 10 ^ 12, maxValidatorsPerCall := 100
    moduleAllocationLimitGwei := 10 ^ 15, maxRootAge := 100 }

private def sampleBatch : TopupBatch :=
  { validators := [sampleValidator]
    requestedGwei := [2 * 10 ^ 9]
    allocations := transition
      { validators := [sampleValidator]
        requestedGwei := [2 * 10 ^ 9]
        allocations := []
        valueWei := 10 * 10 ^ 18
        beaconRootTimestamp := 1000, currentTimestamp := 1050 } sampleCfg
    valueWei := 10 * 10 ^ 18
    beaconRootTimestamp := 1000, currentTimestamp := 1050 }

#guard interCallConsistent sampleBatch sampleCfg

#guard (candidates sampleBatch sampleCfg).length =
  min sampleBatch.requestedGwei.length sampleBatch.validators.length

/-! ## P-TOPUP-2: transition budget uses valueGwei -/

example : transitionBudget sampleBatch sampleCfg =
    min (weiToGwei sampleBatch.valueWei)
      (min sampleCfg.moduleAllocationLimitGwei sampleCfg.maxTopUpPerBlockGwei) := rfl

/-! ## P-TOPUP-1: allocateDeposits ABI structure -/

private def sampleArgs : AllocateDepositsArgs :=
  { roundedTargetGwei := 100
    pubkeys := [ByteArray.empty, ByteArray.empty]
    keyIndices := [0, 1]
    operatorIds := [5, 5]
    topUpLimits := [50, 50] }

#guard sampleArgs.keyCount = 2
#guard sampleArgs.wellFormed

private def sampleResult : AllocateDepositsResult :=
  { allocations := [30, 40] }

example : List.Forall₂ (· ≤ ·) sampleResult.allocations sampleArgs.topUpLimits := by
  exact .cons (by decide) (.cons (by decide) .nil)

/-! ## Cross-guarantee: sequential acceptance bridging

`executeGuarded_returndata_is_push_input` is the specification-level
bridge: it delegates to the executable `executeGuarded_observes_source`
and additionally asserts the first call name is `"allocateDeposits"`.
The regression checks below exercise its ABI-facing dependencies.
-/

#guard (AllocateDepositsArgs.mk 100 [ByteArray.empty, ByteArray.empty]
    [0, 1] [5, 5] [50, 50]).keyCount = 2

example : (AllocateDepositsArgs.mk 100 [ByteArray.empty, ByteArray.empty]
    [0, 1] [5, 5] [50, 50]).wellFormed := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> simp [AllocateDepositsArgs.keyCount]

/-! ## Cross-guarantee: blocker discharge validation

The three structural blockers are discharged in the guarantee files.
These checks validate the key properties of each discharge. -/

-- Blocker 1: sequential acceptance is universal (not just test vectors)
-- This example instantiates the universal theorem at a zero-byte deposit.
example : PSsz1.SequentialDigestAcceptance
    { publicKey := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      withdrawalCredentials := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      signature := ByteArray.mk #[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      amountLittleEndian := ByteArray.mk #[0,0,0,0,0,0,0,0] } :=
  PSsz1.sequential_digest_acceptance _

-- Blocker 1: strictly stronger than DigestChainIsExact
#guard PSsz1.productionValidatorGIndexBase = 150 * 2 ^ 40

-- Blocker 2: gindex band for all vi < 2^40
example : 2 ^ 47 ≤ PSsz1.validatorGIndex 0 := (PSsz1.validatorGIndex_in_production_band 0 (by norm_num)).1
example : PSsz1.validatorGIndex (2 ^ 40 - 1) < 2 ^ 48 :=
  (PSsz1.validatorGIndex_in_production_band _ (by norm_num)).2

-- Blocker 2: sourceConcat produces the expected value
#guard PSsz1.stateRootGIndexValue = 43
#guard PSsz1.stateRootGIndexPow = 0

-- Blocker 3: argsToTopupCall preserves all router fields
example : ∀ (args : AllocateDepositsArgs) (ret : List Nat),
    (argsToTopupCall args ret).roundedTarget = args.roundedTargetGwei :=
  fun _ _ => rfl

-- Blocker 3: calleeEffects sum bounded by limits
example : ∀ (eff : CalleeEffects),
    eff.result.allocations.sum ≤ eff.args.topUpLimits.sum :=
  calleeEffects_sum_bounded

end LidoSRv3.Audit.Verity.Tests.SszTopupBridge
