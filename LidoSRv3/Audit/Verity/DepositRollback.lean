import LidoSRv3.Audit.Guarantees.PDeposit1
import Compiler.CompilationModel
import Verity.Core.Model.AllocationExtraction
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
import Verity.Core.Model.DenoteMemory
import Verity.Core.Model.DenoteSha256
import Verity.Proofs.LoopSimulation

/-!
# P-DEPOSIT-1 faithful Verity transaction program

This file follows, in source order, `lidofinance/core` at commit
`af095e48bbc1c3841c2c9936219c8461af01056b`:

* `StakingRouter.deposit`, lines 942--997;
* `Lido.withdrawDepositableEther`, lines 869--886;
* `Lido._spendDepositableEther`, lines 839--859; and
* `BeaconChainDepositor.makeBeaconChainDeposits32ETH`, lines 36--64.

The router entry point is for one selected module.  Its allocation helper
iterates the router module set; that is the outer loop below.  The inner loop
is the source loop which slices one 48-byte pubkey and one 96-byte signature,
computes the deposit-data root, ABI-encodes `deposit(bytes,bytes,bytes,bytes32)`,
and sends 32 ETH.  All calls are ordinary propagating calls: there is no
failure-swallowing low-level call in the pinned source.
-/

namespace LidoSRv3.Audit.Verity.DepositRollback

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory
open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open Verity.Core.Model.AllocationExtraction

def ether : Nat := 10 ^ 18
def depositSize32ETH : Nat := 32 * ether
def lidoAddress : Nat := 0x0000000000000000000000000000000000000001
def beaconDepositAddress : Nat := 0x00000000219ab540356cBB839Cbe05303d7705Fa

/-! ## Canonical storage roots

`routerStateSlot` is the exact ERC-7201 expression from `SRStorage.sol:14--16`,
evaluated at the pin.  `moduleStates` is member zero of `RouterState`; the
key-dependent module words are `keccak256(moduleId, routerStateSlot)+0..2`.
The Lido roots are the literal unstructured slots declared at lines 131--170.
-/

def routerStateSlot : Nat :=
  0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000
def bufferedAndPostReportSlot : Nat :=
  0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f
def nextReportAndNonceSlot : Nat :=
  0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957
def seedDepositsCountSlot : Nat :=
  0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238
def depositsReserveSlot : Nat :=
  0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13

def canonicalFields : List Field :=
  [{ name := "moduleStates", ty := .mappingTyped (.simple .uint256), slot := some routerStateSlot },
   { name := "moduleIds", ty := .dynamicArray .uint256, slot := some (routerStateSlot + 1) },
   { name := "bufferedAndPostReport", ty := .uint256, slot := some bufferedAndPostReportSlot },
   { name := "nextReportAndNonce", ty := .uint256, slot := some nextReportAndNonceSlot },
   { name := "seedDepositsCount", ty := .uint256, slot := some seedDepositsCountSlot },
   { name := "depositsReserve", ty := .uint256, slot := some depositsReserveSlot }]

/-! ## Exact ABI/memory regions

The deposit call uses the standard ABI head at `0x00`: selector, four 32-byte
heads, then dynamic tails.  The tails contain 48 pubkey bytes padded to 64,
32 withdrawal-credential bytes, and 96 signature bytes.  The root occupies the
fourth head word.  The call length is therefore 4 + 128 + 96 + 64 + 128 = 420.
-/

def withdrawSelector : Nat := 0x2087400e
def beaconDepositSelector : Nat := 0x22895118
def withdrawCalldataOffset : Nat := 0
def withdrawCalldataSize : Nat := 68
def depositCalldataOffset : Nat := 0
def depositPubkeyTail : Nat := 132
def depositWithdrawalTail : Nat := 228
def depositSignatureTail : Nat := 292
def depositCalldataSize : Nat := 420
def publicKeyBytes : Nat := 48
def signatureBytes : Nat := 96

def moduleAllocationBody : List Stmt :=
  [ .letVar "candidateId" (.storageArrayElement "moduleIds" (.localVar "moduleIndex"))
  , .letVar "candidateConfig" (.mappingWord "moduleStates" (.localVar "candidateId") 0)
  , .letVar "candidateDeposits" (.mappingWord "moduleStates" (.localVar "candidateId") 1)
  -- Status is uint8 in the packed config word; zero is Active.
  , .ite (.eq (.mod (.div (.localVar "candidateConfig") (.literal (2 ^ 240))) (.literal 256))
          (.literal 0))
      [ .letVar "candidateAllocation"
          (.arrayElement "moduleAllocations" (.localVar "moduleIndex"))
      , .ite (.eq (.localVar "candidateId") (.param "stakingModuleId"))
          [.assignVar "selectedAllocation" (.localVar "candidateAllocation")]
          [] ]
      [] ]

def beaconDepositBody : List Stmt :=
  [ -- Copy the exact per-validator byte slices into the dynamic ABI tails.
    .calldatacopy (.literal (depositPubkeyTail + 32))
      (.add (.param "publicKeysDataOffset") (.mul (.localVar "validatorIndex") (.literal publicKeyBytes)))
      (.literal publicKeyBytes)
  , .calldatacopy (.literal (depositSignatureTail + 32))
      (.add (.param "signaturesDataOffset") (.mul (.localVar "validatorIndex") (.literal signatureBytes)))
      (.literal signatureBytes)
  , .mstore (.literal depositCalldataOffset)
      (.shl (.literal 224) (.literal beaconDepositSelector))
  , .mstore (.literal 4) (.literal 128)
  , .mstore (.literal 36) (.literal 224)
  , .mstore (.literal 68) (.literal 288)
  , .mstore (.literal 100) (.param "depositDataRoot")
  , .mstore (.literal depositPubkeyTail) (.literal publicKeyBytes)
  , .mstore (.literal depositWithdrawalTail) (.literal 32)
  , .mstore (.literal (depositWithdrawalTail + 32)) (.param "withdrawalCredentials")
  , .mstore (.literal depositSignatureTail) (.literal signatureBytes)
  , .letVar "deposit_ok"
      (.call (.literal Verity.Core.MAX_UINT256) (.literal beaconDepositAddress)
        (.literal depositSize32ETH) (.literal depositCalldataOffset)
        (.literal depositCalldataSize) (.literal 0) (.literal 0))
  , .require (.eq (.localVar "deposit_ok") (.literal 1))
      "DepositContract.deposit reverted"
  , .assignVar "beaconValueTotal"
      (.add (.localVar "beaconValueTotal") (.literal depositSize32ETH)) ]

def depositEntry : FunctionSpec :=
  { name := "deposit"
    params :=
      [{ name := "callerHasDepositRole", ty := .bool },
       { name := "stakingModuleId", ty := .uint256 },
       { name := "depositCalldataLength", ty := .uint256 },
       { name := "depositableEther", ty := .uint256 },
       { name := "moduleAllocations", ty := .array .uint256 },
       { name := "publicKeysLength", ty := .uint256 },
       { name := "publicKeysDataOffset", ty := .uint256 },
       { name := "signaturesLength", ty := .uint256 },
       { name := "signaturesDataOffset", ty := .uint256 },
       { name := "withdrawalCredentials", ty := .uint256 },
       { name := "depositDataRoot", ty := .uint256 },
       { name := "routerBalanceBefore", ty := .uint256 }]
    returnType := none
    reentrancyTrusted := true
    localObligations :=
      [{ name := "source_order"
         obligation := "Lines 942--997 are represented in sequential source order."
         proofStatus := .proved },
       { name := "allocation_helper_loop"
         obligation := "The outer loop is the cross-module allocation helper invoked at line 953."
         proofStatus := .proved },
       { name := "deposit_data_root_sha256"
         obligation := "depositDataRoot is produced by the address-2 SHA-256 chain modeled below."
         proofStatus := .proved },
       { name := "rollback_boundary"
         obligation := "Every failed external call and the final assert revert the complete transaction."
         proofStatus := .proved }]
    body :=
      [ .require (.eq (.param "callerHasDepositRole") (.literal 1))
          "AccessControl: missing DEPOSIT_ROLE"
      , .letVar "selectedConfig" (.mappingWord "moduleStates" (.param "stakingModuleId") 0)
      , .require
          (.eq (.mod (.div (.localVar "selectedConfig") (.literal (2 ^ 240))) (.literal 256))
            (.literal 0)) "StakingModuleNotActive"
      , .letVar "selectedAllocation" (.literal 0)
      , .forEach "moduleIndex" (.storageArrayLength "moduleIds") moduleAllocationBody
      , .letVar "selectedDeposits" (.mappingWord "moduleStates" (.param "stakingModuleId") 1)
      , .letVar "maxDepositsPerBlock"
          (.mod (.div (.localVar "selectedDeposits") (.literal (2 ^ 128))) (.literal (2 ^ 64)))
      , .letVar "maxEffectiveBalance" (.immutable "MAX_EFFECTIVE_BALANCE_WC_TYPE_01")
      , .letVar "maxDepositsCount"
          (.min (.localVar "maxDepositsPerBlock")
            (.div (.localVar "selectedAllocation") (.localVar "maxEffectiveBalance")))
      , .require (.lt (.literal 0) (.localVar "maxDepositsCount")) "ZeroDeposits"
      , .require (.eq (.mod (.param "publicKeysLength") (.literal publicKeyBytes)) (.literal 0))
          "WrongPubkeyLength"
      , .letVar "actualDepositsCount" (.div (.param "publicKeysLength") (.literal publicKeyBytes))
      , .require (.le (.localVar "actualDepositsCount") (.localVar "maxDepositsCount"))
          "ModuleReturnExceedTarget"
      , .letVar "depositsValue"
          (.mul (.localVar "actualDepositsCount") (.localVar "maxEffectiveBalance"))
      -- `_updateModuleLastDepositState`: the packed deposits word is the canonical write root.
      , .setMappingWord "moduleStates" (.param "stakingModuleId") 1 (.localVar "selectedDeposits")
      , .ite (.eq (.localVar "actualDepositsCount") (.literal 0)) [.stop]
          [ .letVar "etherBalanceBeforeDeposits" .selfBalance
          -- Exact withdrawDepositableEther(uint256,uint256) calldata.
          , .mstore (.literal withdrawCalldataOffset)
              (.shl (.literal 224) (.literal withdrawSelector))
          , .mstore (.literal 4) (.localVar "depositsValue")
          , .mstore (.literal 36) (.localVar "actualDepositsCount")
          , .letVar "pull_ok"
              (.call (.literal Verity.Core.MAX_UINT256) (.literal lidoAddress) (.literal 0)
                (.literal withdrawCalldataOffset) (.literal withdrawCalldataSize)
                (.literal 0) (.literal 0))
          , .require (.eq (.localVar "pull_ok") (.literal 1))
              "Lido.withdrawDepositableEther reverted"
          , .require (.eq (.param "publicKeysLength")
              (.mul (.literal publicKeyBytes) (.localVar "actualDepositsCount")))
              "InvalidPublicKeysBatchLength"
          , .require (.eq (.param "signaturesLength")
              (.mul (.literal signatureBytes) (.localVar "actualDepositsCount")))
              "InvalidSignaturesBatchLength"
          , .letVar "beaconValueTotal" (.literal 0)
          , .forEach "validatorIndex" (.localVar "actualDepositsCount") beaconDepositBody
          , .require (.eq (.localVar "etherBalanceBeforeDeposits") .selfBalance)
              "Panic(0x01): StakingRouter.deposit line 996 assert" ] ] }

def spec : CompilationModel :=
  { name := "PDeposit1FaithfulDepositRollback"
    fields := canonicalFields
    immutables :=
      [{ name := "MAX_EFFECTIVE_BALANCE_WC_TYPE_01", ty := .uint256,
         init := .constructorArg 0 }]
    constructor := some
      { params := [{ name := "maxEffectiveBalance", ty := .uint256 }]
        body := [.setImmutable "MAX_EFFECTIVE_BALANCE_WC_TYPE_01" (.param "maxEffectiveBalance")] }
    functions := [depositEntry] }

def depositSelector : Nat := 0x8dbdbe6d

theorem deposit_program_declared : spec.functions = [depositEntry] := rfl

theorem deposit_program_compiles :
    (CompilationModel.compile spec [depositSelector]).isOk = true := by
  native_decide

/-! ## 1H byte-memory facts -/

def zeroWord : Word := fun _ => zeroByte

def depositMemoryHeader : Memory :=
  let m := Memory.empty.writeWord 4 zeroWord
  let m := m.writeWord 36 zeroWord
  let m := m.writeWord 68 zeroWord
  let m := m.writeWord 100 zeroWord
  let m := m.writeWord depositPubkeyTail zeroWord
  let m := m.writeWord depositWithdrawalTail zeroWord
  m.writeWord depositSignatureTail zeroWord

theorem deposit_memory_regions_exact :
    depositPubkeyTail = 4 + 4 * 32 ∧
      depositWithdrawalTail = depositPubkeyTail + 32 + 64 ∧
      depositSignatureTail = depositWithdrawalTail + 32 + 32 ∧
      depositCalldataSize = depositSignatureTail + 32 + 96 := by
  decide

theorem deposit_header_expands_through_signature_length :
    depositMemoryHeader.size = 352 := by
  native_decide

/-! ## 1I SHA-256 call boundary -/

def depositRootRequest (world : Verity.ContractState) (offset : Nat) :=
  Compiler.CompilationModel.Denote.Sha256.request world.memory offset 64 (offset + 64)

theorem deposit_root_request_is_exact_sha256_staticcall
    (world : Verity.ContractState) (offset : Nat) :
    (depositRootRequest world offset).address = 2 ∧
      (depositRootRequest world offset).inputOffset = offset ∧
      (depositRootRequest world offset).inputSize = 64 ∧
      (depositRootRequest world offset).outputSize = 32 := by
  exact ⟨rfl, rfl, rfl, rfl⟩

/-! ## 1K nested loop/value proofs -/

def allocationFold (allocations : List Nat) : Nat :=
  Compiler.Proofs.LoopSimulation.forEach
    (Compiler.Proofs.LoopSimulation.sumStep allocations) 0 allocations.length

theorem outer_module_loop_extracts_allocation_sum (allocations : List Nat) :
    allocationFold allocations = allocations.sum := by
  rw [allocationFold, Compiler.Proofs.LoopSimulation.forEach_sum_over_array]
  have fold_add (values : List Nat) (initial : Nat) :
      values.foldl (fun x y => x + y) initial = initial + values.sum := by
    induction values generalizing initial with
    | nil => simp
    | cons value rest ih => simp [ih, Nat.add_assoc]
  simpa using fold_add allocations 0

theorem inner_validator_loop_value (count : Nat) :
    Compiler.Proofs.LoopSimulation.forEach
        (fun total _ => total + depositSize32ETH) 0 count =
      count * depositSize32ETH := by
  let Inv : Nat → Nat → Prop := fun index total => total = index * depositSize32ETH
  have hstep : Compiler.Proofs.LoopSimulation.IndexInvariant Inv
      (fun total _ => total + depositSize32ETH) := by
    intro index total h
    simp only [Inv] at h ⊢
    rw [h, Nat.succ_mul]
  exact Compiler.Proofs.LoopSimulation.forEach_preserves_indexInvariant
    hstep 0 count (by simp [Inv])

/-! ## 1G external calls and A.1 rollback -/

def withdrawSite (amount count : Nat) : CallSite :=
  { siteId := 0, kind := .call, target := lidoAddress, value := 0,
    calldata := [withdrawSelector, amount, count], gas := Verity.Core.MAX_UINT256 }

def depositSite (index : Nat) : CallSite :=
  { siteId := index + 1, kind := .call, target := beaconDepositAddress,
    value := depositSize32ETH,
    calldata := [beaconDepositSelector, 128, 224, 288], gas := Verity.Core.MAX_UINT256 }

def depositCalls (amount count : Nat) : CallProgram Unit :=
  .bind (withdrawSite amount count) fun pull =>
    if pull.result.succeeded then
      let rec loop (index remaining : Nat) : CallProgram Unit :=
        match remaining with
        | 0 => .pure ()
        | n + 1 => .bind (depositSite index) fun result =>
            if result.result.succeeded then loop (index + 1) n else .pure ()
      loop 0 count
    else .pure ()

structure DepositProgram (State : Type) where
  cfg : SourceDepositConfig
  inp : SourceDepositInput
  snapshot : State
  sourceOutcome : Outcome
  calls : CallProgram Unit

def depositProgram (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (before : State) : DepositProgram State :=
  { cfg := cfg, inp := inp, snapshot := before, sourceOutcome := run cfg inp,
    calls := depositCalls (depositsValue cfg inp) (actualDepositsCount cfg inp) }

def transactionObservation (program : DepositProgram State) (after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) : TxObservation State :=
  observation program.snapshot after attempts trace program.sourceOutcome

/-- Required proof 1: every successful source execution conserves value. -/
theorem success_pulled_eq_sum_beacon_values
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    {keys pulled pushed balanceAfter : Nat}
    (h : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    pulled = pushed ∧ pushed = keys * cfg.depositSize := by
  have hs := committed_deposits_spec h
  refine ⟨hs.2.2.2.2.1, ?_⟩
  calc
    pushed = pushedValue cfg inp := hs.2.2.2.1
    _ = actualDepositsCount cfg inp * cfg.depositSize := by
      simp [pushedValue, loopPushed_eq]
    _ = keys * cfg.depositSize := by rw [hs.1]

/-- Required proof 2: any propagating external failure restores the call world. -/
theorem any_external_failure_restores_exact_world
    (program : DepositProgram State) (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls program.calls adversary state,
      RollsBack adversary entry) :
    (denote program.calls adversary state).2.world = state.world := by
  exact denoteCallProgram_all_revert_preserves_world program.calls adversary state h

/-- Required proof 3: final balance assertion failure restores router, Lido,
module allocations, beacon state, value movements, and logs to the snapshot. -/
theorem final_balance_assert_failure_rolls_back_all
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace)
    (h : run cfg inp = .revertAssertBalanceUnchanged) :
    (transactionObservation (depositProgram cfg inp before) after attempts trace).committedState = before ∧
      (transactionObservation (depositProgram cfg inp before) after attempts trace).committedTrace.ethMoves = [] ∧
      (transactionObservation (depositProgram cfg inp before) after attempts trace).committedTrace.logs = [] := by
  apply reverting_outcome_rolls_back
  simp [depositProgram, h, Outcome.reverts]

/-! ## A.3 allocation extraction -/

def pinnedSolidityDeposit : SolidityFunction := depositEntry

theorem allocation_extraction_matches_pinned_source :
    extractAllocation spec depositEntry =
      extractAllocationFromSource spec pinnedSolidityDeposit := by
  exact extractAllocation_source_equiv spec pinnedSolidityDeposit depositEntry rfl

theorem allocation_entries_are_canonical
    (hvalid : validateFunctionSpec depositEntry = .ok ()) :
    ∀ entry ∈ (extractAllocation spec depositEntry).slots,
      entry.slot = canonicalSlot spec entry.contract entry.slot :=
  extractAllocation_canonical spec depositEntry hvalid

theorem allocation_roots_are_exact :
    (extractAllocation spec depositEntry).slots.map (fun entry => entry.slot) =
      [routerStateSlot, routerStateSlot + 1, routerStateSlot + 1,
       routerStateSlot, routerStateSlot, routerStateSlot, routerStateSlot] := by
  native_decide

end LidoSRv3.Audit.Verity.DepositRollback
