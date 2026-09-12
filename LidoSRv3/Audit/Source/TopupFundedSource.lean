import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Source.TopupWeiBounds

namespace LidoSRv3.Audit.Source.TopupFundedSource
open _root_.Verity _root_.Contracts
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Verity.TopupTx
open DepositDataRootCorrespondence

/-! The actual source-byte loop, not the legacy scheduled-deposit executor.
Pin 17005714f151e5502c559932319a3f2f74ac2436:
BeaconChainDepositor.sol:79-107, StakingRouter.sol:741-756.
The journal specification selects paired source inputs with nonzero amounts;
it never substitutes validator IDs or independently supplied roots for bytes.
-/

def journal (inputs : List SourceDepositDataRootInput) (amounts : List Nat) : List ExternalCall :=
  (inputs.zip amounts).filterMap fun p =>
    if p.2 = 0 then none else
      some (linkedCallEntryTo "deposit" beaconAddress (p.2 : Uint256) (sourceBeaconCalldata p.1))

/-- These are precisely the two guards executed before each nonzero push.
They do not include the earlier router alignment/per-index admission guards.
The source correspondence specializes cfg to pinnedConfig: sourceDeposits
constructs amountGwei using the fixed 10^9 unit, independently of cfg. -/
def Guards (cfg : SourceTopupConfig) (amounts : List Nat) : Prop :=
  ∀ a ∈ amounts, a ≠ 0 → cfg.minDeposit ≤ a ∧ a / cfg.gwei ≤ cfg.uint64Max

theorem beacon_frame (input : SourceDepositDataRootInput) (amount : Nat)
    (state : ContractState) (hle : (amount : Uint256) ≤ state.selfBalance) :
    beaconPush input amount state = .success () {state with
      selfBalance := state.selfBalance - (amount : Uint256)
      calls := state.calls ++ [linkedCallEntryTo "deposit" beaconAddress
        (amount : Uint256) (sourceBeaconCalldata input)]} := by
  simp [beaconPush, externalCallBindTo, hle, beaconStub, linkedCallEntryTo,
    linkedCallEntry, ExternalArg.toWords]

/-- Induction over the actual paired loop derives both the exact debit and
all ordered calldata-bearing call frames. Storage and every other local field
are preserved by the stated final record. No result or journal premise occurs. -/
theorem loop_run (cfg : SourceTopupConfig) (amounts : List Nat) :
    ∀ (inputs : List SourceDepositDataRootInput) (state : ContractState),
    inputs.length = amounts.length → Guards cfg amounts →
    allocSum amounts ≤ state.selfBalance.val →
    sourcePushLoop cfg inputs amounts state = .success () {state with
      selfBalance := ((state.selfBalance.val - allocSum amounts : Nat) : Uint256)
      calls := state.calls ++ journal inputs amounts} := by
  induction amounts with
  | nil =>
    intro inputs state hlen _ _
    have hi : inputs = [] := List.length_eq_zero_iff.mp hlen
    subst inputs
    simp [sourcePushLoop, journal, allocSum, _root_.Verity.pure, ofNat_val]
  | cons a amounts ih =>
    intro inputs state hlen hg hb
    cases inputs with
    | nil => simp at hlen
    | cons input inputs =>
      have hl : inputs.length = amounts.length := by simpa using hlen
      have ht : Guards cfg amounts := fun x hx => hg x (by simp [hx])
      have hsplit : allocSum (a :: amounts) = a + allocSum amounts := rfl
      by_cases hz : a = 0
      · subst a
        rw [sourcePushLoop, if_pos rfl, ih inputs state hl ht (by simpa [allocSum] using hb)]
        simp [journal, allocSum]
      · have haLe : a ≤ state.selfBalance.val := by omega
        have haLt : a < uint256Modulus := Nat.lt_of_le_of_lt haLe (val_lt state.selfBalance)
        have hval : (a : Uint256).val = a := word_val haLt
        have hle : (a : Uint256) ≤ state.selfBalance := by
          show (a : Uint256).val ≤ state.selfBalance.val
          omega
        have hnext : (state.selfBalance - (a : Uint256)).val = state.selfBalance.val - a := by
          rw [Core.Uint256.sub_eq_of_le (by omega), hval]
        obtain ⟨hmin, hmax⟩ := hg a (by simp) hz
        rw [sourcePushLoop, if_neg hz]
        simp only [makeBeaconChainTopUpGuards, Bind.bind, _root_.Verity.bind,
          _root_.Verity.require, hmin, hmax, decide_true, if_true,
          beacon_frame input a state hle]
        rw [ih inputs _ hl ht (by simp only [hnext]; omega)]
        have hend : (state.selfBalance - (a : Uint256)).val - allocSum amounts =
            state.selfBalance.val - allocSum (a :: amounts) := by rw [hnext, hsplit]; omega
        simp [hend, journal, hz, List.append_assoc]

theorem source_deposits_run (cfg : SourceTopupConfig) (call : TopupCall)
    (hw : SourceTopupCallWellFormed call) (state : ContractState)
    (hg : Guards cfg call.moduleReturndata)
    (hb : allocSum call.moduleReturndata ≤ state.selfBalance.val) :
    sourcePushLoop cfg (sourceDeposits call hw) call.moduleReturndata state =
      .success () {state with
        selfBalance := ((state.selfBalance.val - allocSum call.moduleReturndata : Nat) : Uint256)
        calls := state.calls ++ journal (sourceDeposits call hw) call.moduleReturndata} :=
  loop_run cfg call.moduleReturndata _ state (sourceDeposits_length call hw) hg hb

theorem allocSum_eq_sum (amounts : List Nat) : allocSum amounts = amounts.sum := by
  induction amounts with
  | nil => rfl
  | cons a amounts ih => simp [allocSum, ih]

/-- Values read back from the calldata-bearing frames sum to the mathematical
allocation sum; zero allocations contribute neither a frame nor value. -/
theorem journal_value (amounts : List Nat) :
    ∀ (inputs : List SourceDepositDataRootInput), inputs.length = amounts.length →
    (∀ a ∈ amounts, a < uint256Modulus) →
    ((journal inputs amounts).map (·.value)).sum = allocSum amounts := by
  induction amounts with
  | nil =>
    intro inputs hlen _
    have hi : inputs = [] := List.length_eq_zero_iff.mp hlen
    subst inputs
    rfl
  | cons a amounts ih =>
    intro inputs hlen ha
    cases inputs with
    | nil => simp at hlen
    | cons input inputs =>
      have hl : inputs.length = amounts.length := by simpa using hlen
      have ht := ih inputs hl (fun x hx => ha x (by simp [hx]))
      have hw : a % Core.Uint256.modulus = a := word_val (ha a (by simp))
      by_cases hz : a = 0
      · subst a
        simpa [journal, allocSum] using ht
      · simpa [journal, hz, linkedCallEntryTo, hw, allocSum] using congrArg (a + ·) ht

/-- Reuse the delivered uint64/count bounds on arbitrary allocations. The
lists are shared parameters, not independently supplied sums or post-states. -/
theorem gateway_sum_exact (cfg : TopupWeiBounds.GatewayConfig)
    (validators : List TopupWeiBounds.ValidatorInput) (limits amounts : List Nat)
    (hc : validators.length ≤ cfg.maxValidators.val)
    (hl : TopupWeiBounds.limits cfg validators = some limits)
    (hg : TopupWeiBounds.allocationGuards amounts (TopupWeiBounds.weiLimits limits)) :
    allocSum amounts < uint256Modulus ∧ allocSumUnchecked amounts = allocSum amounts := by
  have hbound := (TopupWeiBounds.gateway_wei_bounds cfg validators limits hc hl).2.1
  have hle := TopupWeiBounds.allocations_sum_le amounts _ hg
  have hfit : allocSum amounts < uint256Modulus := by
    rw [allocSum_eq_sum]
    exact Nat.lt_of_le_of_lt hle hbound
  exact ⟨hfit, allocSumUnchecked_eq_allocSum hfit⟩

end LidoSRv3.Audit.Source.TopupFundedSource
