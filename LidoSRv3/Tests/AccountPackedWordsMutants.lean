import LidoSRv3.Audit.Source.AccountPackedWords
import LidoSRv3.Audit.Verity.HandleOracleReportTx

/-!
Width/offset kill-lines for P-ACCOUNT-1 packed uint64 accounting words.

Each mutant edits the field width or bit offset of the pinned
`ModuleStateAccounting` / `RouterStateAccounting` layout
(`SRTypes.sol:157-172`) and is shown to disagree with the registered
parent write `persistBalances` / `ofNat` (`HandleOracleReportTx` 162–164,
`SRLib.sol:884-891`).
-/
set_option autoImplicit false

namespace LidoSRv3.Tests.AccountPackedWordsMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Source.AccountPackedWords
open LidoSRv3.Audit.Verity.HandleOracleReportTx

def two32 : Nat := 4294967296

/-- Wrong-width pack: treat the balance field as `uint32` (`SRTypes.sol:159`
is `uint64`). -/
def unpackWidth32 (w : Nat) : Nat := w % two32

/-- Wrong-offset field write: place `validatorsBalanceGwei` at bits 64..127
(the `exitedValidatorsCount` field) instead of bits 0..63. -/
def writeOffset64 (word value : Nat) : Nat :=
  (word % two64) + uint64Cast value * two64 + (word / two128) * two128

def sampleInput : ReportInput := ⟨[1, 2], [1, 2], [10, 20]⟩

theorem two32_succ_lt_two64 : two32 + 1 < two64 := by decide

/-- Honest pack recovers a balance that sits above `2^32` and below `2^64`.
`SRLib.sol:884` is a `uint64` cast, not `uint32`. -/
theorem width32_misses_parent_balance :
    unpackWidth32 (Verity.Core.Uint256.ofNat (two32 + 1)).val ≠ two32 + 1 ∧
      (unpackModule (Verity.Core.Uint256.ofNat (two32 + 1)).val).validatorsBalanceGwei =
        two32 + 1 := by
  have hval : (Verity.Core.Uint256.ofNat (two32 + 1)).val = two32 + 1 := by
    rw [ofNat_eq_pack_zero (two32 + 1) two32_succ_lt_two64,
      packModule_zero_of_lt (two32 + 1) two32_succ_lt_two64]
  constructor
  · rw [hval]
    decide
  · rw [hval]
    simp [unpackModule, Nat.mod_eq_of_lt two32_succ_lt_two64]

/-- Writing the balance at bit 64 disagrees with the parent `ofNat` write
(`HandleOracleReportTx` 164) and lands in the exited field
(`SRTypes.sol:161`). -/
theorem offset64_disagrees_parent_ofNat
    (b : Nat) (h0 : 0 < b) (hb : b < two64) :
    writeOffset64 0 b ≠ (Verity.Core.Uint256.ofNat b).val := by
  have hparent : (Verity.Core.Uint256.ofNat b).val = b := by
    rw [ofNat_eq_pack_zero b hb, packModule_zero_of_lt b hb]
  have hmut : writeOffset64 0 b = b * two64 := by
    simp [writeOffset64, uint64Cast_eq_of_lt b hb]
  rw [hmut, hparent]
  have hlt : b < b * two64 := by
    change b < b * 18446744073709551616
    have hone : 1 < (18446744073709551616 : Nat) := by decide
    omega
  exact Ne.symm (Nat.ne_of_lt hlt)

theorem offset64_lands_in_exited (b : Nat) (hb : b < two64) :
    (unpackModule (writeOffset64 0 b)).validatorsBalanceGwei = 0 ∧
      (unpackModule (writeOffset64 0 b)).exitedValidatorsCount = b := by
  have hmut : writeOffset64 0 b = b * two64 := by
    simp [writeOffset64, uint64Cast_eq_of_lt b hb]
  have hunp := unpack_pack_module ⟨0, b, 0⟩ two64_pos hb (by
    change (0 : Nat) < two128
    decide)
  have hpack : packModule ⟨0, b, 0⟩ = b * two64 := by
    simp [packModule, uint64Cast, Nat.mod_eq_of_lt hb]
  simpa [hmut, hpack] using
    (congrArg (fun m => (m.validatorsBalanceGwei, m.exitedValidatorsCount)) hunp)

/-- Source field write (`SRLib.sol:886`) preserves a nonzero
`exitedValidatorsCount`. The parent `ofNat` write (`HandleOracleReportTx` 164)
equals that field write only on a zero word. -/
theorem parent_ofNat_clobbers_exited
    (exited b : Nat) (he : 0 < exited) (he64 : exited < two64) (hb : b < two64) :
    let word := packModule ⟨0, exited, 0⟩
    (Verity.Core.Uint256.ofNat b).val ≠ writeLow64 word b ∧
      (unpackModule (writeLow64 word b)).exitedValidatorsCount = exited ∧
      (unpackModule (Verity.Core.Uint256.ofNat b).val).exitedValidatorsCount = 0 := by
  intro word
  have hword : word = exited * two64 := by
    simp [word, packModule, uint64Cast, Nat.mod_eq_of_lt he64]
  have hparent : (Verity.Core.Uint256.ofNat b).val = b := by
    rw [ofNat_eq_pack_zero b hb, packModule_zero_of_lt b hb]
  have hwrite : writeLow64 word b = b + exited * two64 := by
    have hdiv : exited * two64 / two64 = exited :=
      Nat.mul_div_cancel exited two64_pos
    simp [writeLow64, uint64Cast_eq_of_lt b hb, hword, hdiv]
    omega
  refine ⟨?_, ?_, ?_⟩
  · rw [hparent, hwrite]
    have : 0 < exited * two64 := Nat.mul_pos he two64_pos
    omega
  · have hw := writeLow64_preserves_exited word b
    have hunp := unpack_pack_module ⟨0, exited, 0⟩ two64_pos he64 (by
      change (0 : Nat) < two128
      decide)
    simpa [word, hunp] using hw
  · have hdiv : b / two64 = 0 := Nat.div_eq_of_lt hb
    rw [hparent]
    simp only [unpackModule]
    rw [hdiv]
    exact Nat.zero_mod two64

/-- Skipping the `uint64` cast (`SRLib.sol:884`) and writing the raw parent
`ofNat` of `2^64+1` packs `exitedValidatorsCount = 1`. The source cast then
pack writes `packModule ⟨1, 0, 0⟩`. -/
theorem raw_ofNat_past_uint64_is_not_source_pack :
    packModule ⟨uint64Cast (two64 + 1), 0, 0⟩ ≠
      (Verity.Core.Uint256.ofNat (two64 + 1)).val := by
  have hcast : uint64Cast (two64 + 1) = 1 := by
    simp [uint64Cast, two64]
  have hpack : packModule ⟨uint64Cast (two64 + 1), 0, 0⟩ = 1 := by
    rw [hcast]
    simp [packModule, uint64Cast]
    decide
  have hmod : two64 + 1 < Verity.Core.Uint256.modulus := by
    rw [← two256_eq_mod]
    decide
  have hval : (Verity.Core.Uint256.ofNat (two64 + 1)).val = two64 + 1 :=
    ofNat_val_of_lt hmod
  rw [hpack, hval]
  decide

/-- On the registered happy path the parent observe unpacks to the reported
balances and total. Same witness as `HandleOracleReportTxMutants`. -/
theorem sample_observe_balances :
    (observe sampleInput ((handleOracleReport sampleInput 1).run defaultState)).balances =
      [10, 20] := by
  native_decide

theorem sample_observe_total :
    (observe sampleInput ((handleOracleReport sampleInput 1).run defaultState)).total =
      30 := by
  native_decide

theorem sample_observe_unpacks :
    (storedModuleWords ((handleOracleReport sampleInput 1).run defaultState)).map
        (fun w => (unpackModule w.val).validatorsBalanceGwei) =
      [10, 20] := by
  native_decide

theorem sample_router_getter
    (r : Result) (post : ContractState)
    (h : (handleOracleReport sampleInput 1).run defaultState = .success r post) :
    getRouterValidatorsBalanceGwei (post.readSlot totalBalanceSlot).val = 30 := by
  have hobs := observe_total_eq_unpacked_router_word sampleInput 1 defaultState
  have htot := sample_observe_total
  rw [h] at hobs htot
  exact hobs.symm.trans htot

theorem sample_persist_is_packed_zero :
    ((persistBalances [10, 20] defaultState).readArray moduleBalancesSlot).map
        (fun w => w.val) =
      [packModule ⟨10, 0, 0⟩, packModule ⟨20, 0, 0⟩] := by
  native_decide

theorem sample_getter_recovers :
    ((persistBalances [10, 20] defaultState).readArray moduleBalancesSlot).map
        (fun w => (getStakingModuleStateAccounting w.val).1) =
      [10, 20] := by
  native_decide

theorem sample_width32_kill_line :
    unpackWidth32 (packModule ⟨two32 + 1, 0, 0⟩) = 1 ∧
      (unpackModule (packModule ⟨two32 + 1, 0, 0⟩)).validatorsBalanceGwei =
        two32 + 1 := by
  native_decide

theorem sample_offset64_kill_line :
    writeOffset64 0 10 ≠ packModule ⟨10, 0, 0⟩ ∧
      (unpackModule (writeOffset64 0 10)).exitedValidatorsCount = 10 := by
  native_decide

#print axioms width32_misses_parent_balance
#print axioms offset64_disagrees_parent_ofNat
#print axioms offset64_lands_in_exited
#print axioms parent_ofNat_clobbers_exited
#print axioms raw_ofNat_past_uint64_is_not_source_pack
#print axioms sample_observe_balances
#print axioms sample_observe_total
#print axioms sample_observe_unpacks
#print axioms sample_router_getter
#print axioms sample_persist_is_packed_zero
#print axioms sample_getter_recovers
#print axioms sample_width32_kill_line
#print axioms sample_offset64_kill_line

end LidoSRv3.Tests.AccountPackedWordsMutants
