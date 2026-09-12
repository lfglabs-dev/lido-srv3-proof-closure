import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx

/-!
P-ACCOUNT-1 packed uint64 accounting words.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `SRTypes.sol:157-164` `ModuleStateAccounting` (one slot):
  bits 0..63 `validatorsBalanceGwei`, bits 64..127 `exitedValidatorsCount`,
  bits 128..255 two reserved `uint64`s.
* `SRTypes.sol:166-172` `RouterStateAccounting` (one slot):
  bits 0..63 `validatorsBalanceGwei`, bits 64..255 reserved.
* `SRLib.sol:884` `uint64(_validatorBalancesGwei[i])` truncating cast.
* `SRLib.sol:886` `moduleAcc.validatorsBalanceGwei = validatorsBalanceGwei`
  (low-uint64 field write; preserves exited/reserved).
* `SRLib.sol:888` checked `uint64` `+=` on the router total.
* `SRLib.sol:891` `routerAcc.validatorsBalanceGwei = totalValidatorsBalanceGwei`.
* `StakingRouter.sol:396-403` `getStakingModuleStateAccounting` unpacks both
  uint64 fields of the module word.
* `StakingRouter.sol:819` / `SRUtils.sol:68` read the router word's
  `validatorsBalanceGwei` field.

The registered parent `handleOracleReport` persists balances through
`persistBalances` = `writeArray moduleBalancesSlot (bals.map ofNat)`
(`HandleOracleReportTx` 162–164) and the router total through
`writeSlot totalBalanceSlot total` (line 252). `observe` (282–287) reads
those same slots back as `.val`.

This lot proves those parent reads/writes are the pack/unpack of the pinned
structs on the committed admission domain (`balances ≤ MAX_VALUE_GWEI < 2^64`,
total `≤ uint64Max`), and that a source-shaped field write preserves bits 64+.
Width and offset mutants live in `AccountPackedWordsMutants`.

Additive: no existing file is edited.
-/
set_option autoImplicit false

namespace LidoSRv3.Audit.Source.AccountPackedWords

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

abbrev Word := Verity.Core.Uint256

/-- `2^64`. Destination width of every accounting field
(`SRTypes.sol:159`, `161`, `168`; `SRLib.sol:880`, `884`). -/
def two64 : Nat := 18446744073709551616

/-- `2^128`. Boundary after the two live `uint64` fields of
`ModuleStateAccounting` (`SRTypes.sol:157-164`). -/
def two128 : Nat := 340282366920938463463374607431768211456

/-- `2^192`. Tail width of `RouterStateAccounting` (bits 64..255). -/
def two192 : Nat :=
  6277101735386680763835789423207666416102355444464034512896

/-- `2^256`. One EVM word / Solidity slot. -/
def two256 : Nat :=
  115792089237316195423570985008687907853269984665640564039457584007913129639936

/-- Solidity `uint64(x)` truncating cast (`SRLib.sol:884`). -/
def uint64Cast (x : Nat) : Nat := x % two64

/-- One physical `ModuleStateAccounting` word (`SRTypes.sol:157-164`). -/
structure ModuleAccounting where
  validatorsBalanceGwei : Nat
  exitedValidatorsCount : Nat
  reservedHi : Nat
  deriving Repr, DecidableEq

/-- One physical `RouterStateAccounting` word (`SRTypes.sol:166-172`).
`reservedHi` is the 192-bit tail (bits 64..255). -/
structure RouterAccounting where
  validatorsBalanceGwei : Nat
  reservedHi : Nat
  deriving Repr, DecidableEq

/-- Pack `ModuleStateAccounting` into one 256-bit slot. Each field is masked
to its declared width before placement. -/
def packModule (m : ModuleAccounting) : Nat :=
  uint64Cast m.validatorsBalanceGwei +
    uint64Cast m.exitedValidatorsCount * two64 +
    (m.reservedHi % two128) * two128

def unpackModule (w : Nat) : ModuleAccounting where
  validatorsBalanceGwei := w % two64
  exitedValidatorsCount := (w / two64) % two64
  reservedHi := w / two128

/-- Pack `RouterStateAccounting` into one 256-bit slot. -/
def packRouter (r : RouterAccounting) : Nat :=
  uint64Cast r.validatorsBalanceGwei + (r.reservedHi % two192) * two64

def unpackRouter (w : Nat) : RouterAccounting where
  validatorsBalanceGwei := w % two64
  reservedHi := w / two64

/-- Solidity assignment to the low `uint64` field
(`SRLib.sol:886` `moduleAcc.validatorsBalanceGwei = validatorsBalanceGwei`
and `SRLib.sol:891` `routerAcc.validatorsBalanceGwei = total…`).
Preserves bits 64 and above. -/
def writeLow64 (word value : Nat) : Nat :=
  (word / two64) * two64 + uint64Cast value

/-- `StakingRouter.sol:396-403` `getStakingModuleStateAccounting`:
returns `(validatorsBalanceGwei, exitedValidatorsCount)` from the packed
module word. -/
def getStakingModuleStateAccounting (word : Nat) : Nat × Nat :=
  let m := unpackModule word
  (m.validatorsBalanceGwei, m.exitedValidatorsCount)

/-- `StakingRouter.sol:819` / `SRUtils.sol:68`: the router total is the
low `uint64` of the packed `RouterStateAccounting` word. -/
def getRouterValidatorsBalanceGwei (word : Nat) : Nat :=
  (unpackRouter word).validatorsBalanceGwei

theorem two64_pos : 0 < two64 := by decide

theorem two128_eq_sq : two128 = two64 * two64 := by decide

theorem two256_eq_mod : two256 = Verity.Core.Uint256.modulus := by decide

theorem maxValueGwei_lt_two64 : maxValueGwei < two64 := by decide

theorem uint64Max_lt_two64 : uint64Max < two64 := by decide

theorem two64_lt_two256 : two64 < two256 := by decide

theorem uint64Cast_lt (x : Nat) : uint64Cast x < two64 :=
  Nat.mod_lt _ two64_pos

theorem uint64Cast_eq_of_lt (x : Nat) (h : x < two64) : uint64Cast x = x :=
  Nat.mod_eq_of_lt h

theorem uint64Cast_eq_of_le_max (x : Nat) (h : x ≤ maxValueGwei) :
    uint64Cast x = x :=
  uint64Cast_eq_of_lt x (Nat.lt_of_le_of_lt h maxValueGwei_lt_two64)

theorem packModule_zero (b : Nat) :
    packModule ⟨b, 0, 0⟩ = uint64Cast b := by
  simp [packModule, uint64Cast]

theorem packModule_zero_of_lt (b : Nat) (h : b < two64) :
    packModule ⟨b, 0, 0⟩ = b := by
  simp [packModule_zero, uint64Cast_eq_of_lt b h]

theorem packRouter_zero (b : Nat) :
    packRouter ⟨b, 0⟩ = uint64Cast b := by
  simp [packRouter, uint64Cast]

theorem packRouter_zero_of_lt (b : Nat) (h : b < two64) :
    packRouter ⟨b, 0⟩ = b := by
  simp [packRouter_zero, uint64Cast_eq_of_lt b h]

private theorem omega64 {v e r : Nat}
    (hv : v < two64) (he : e < two64) (hr : r < two128) :
    (v + e * two64 + r * two128) % two64 = v ∧
      ((v + e * two64 + r * two128) / two64) % two64 = e ∧
      (v + e * two64 + r * two128) / two128 = r := by
  change v < 18446744073709551616 at hv
  change e < 18446744073709551616 at he
  change r < 340282366920938463463374607431768211456 at hr
  simp only [two64, two128]
  omega

theorem unpack_pack_module (m : ModuleAccounting)
    (hv : m.validatorsBalanceGwei < two64)
    (he : m.exitedValidatorsCount < two64)
    (hr : m.reservedHi < two128) :
    unpackModule (packModule m) = m := by
  cases m with
  | mk v e r =>
    change v < two64 at hv
    change e < two64 at he
    change r < two128 at hr
    simp [unpackModule, packModule, uint64Cast_eq_of_lt v hv, uint64Cast_eq_of_lt e he,
      Nat.mod_eq_of_lt hr]
    exact omega64 hv he hr

theorem pack_unpack_module (w : Nat) (hw : w < two256) :
    packModule (unpackModule w) = w := by
  simp only [packModule, unpackModule, uint64Cast, Nat.mod_mod]
  change w < 115792089237316195423570985008687907853269984665640564039457584007913129639936 at hw
  simp only [two64, two128]
  omega

theorem two192_lt : two192 = two256 / two64 := by decide

private theorem omegaRouter {v hi : Nat}
    (hv : v < two64) (hhi : hi < two192) :
    (v + hi * two64) % two64 = v ∧ (v + hi * two64) / two64 = hi := by
  change v < 18446744073709551616 at hv
  change hi < 6277101735386680763835789423207666416102355444464034512896 at hhi
  simp only [two64]
  omega

theorem unpack_pack_router (r : RouterAccounting)
    (hv : r.validatorsBalanceGwei < two64)
    (hr : r.reservedHi < two192) :
    unpackRouter (packRouter r) = r := by
  cases r with
  | mk v hi =>
    change v < two64 at hv
    change hi < two192 at hr
    simp [unpackRouter, packRouter, uint64Cast_eq_of_lt v hv, Nat.mod_eq_of_lt hr]
    exact ⟨Nat.mod_eq_of_lt hv, (omegaRouter hv hr).2⟩

theorem pack_unpack_router (w : Nat) (hw : w < two256) :
    packRouter (unpackRouter w) = w := by
  have htail : w / two64 < two192 := by
    change w <
        115792089237316195423570985008687907853269984665640564039457584007913129639936 at hw
    change w / 18446744073709551616 <
        6277101735386680763835789423207666416102355444464034512896
    omega
  simp only [packRouter, unpackRouter, uint64Cast, Nat.mod_mod, Nat.mod_eq_of_lt htail]
  change w <
      115792089237316195423570985008687907853269984665640564039457584007913129639936 at hw
  simp only [two64]
  omega

theorem writeLow64_sets_balance (word value : Nat) :
    (unpackModule (writeLow64 word value)).validatorsBalanceGwei = uint64Cast value := by
  simp only [unpackModule, writeLow64]
  have hv := uint64Cast_lt value
  change uint64Cast value < 18446744073709551616 at hv
  simp only [two64]
  omega

theorem writeLow64_preserves_exited (word value : Nat) :
    (unpackModule (writeLow64 word value)).exitedValidatorsCount =
      (unpackModule word).exitedValidatorsCount := by
  simp only [unpackModule, writeLow64]
  have hv := uint64Cast_lt value
  change uint64Cast value < 18446744073709551616 at hv
  simp only [two64]
  omega

theorem writeLow64_preserves_reserved (word value : Nat) :
    (unpackModule (writeLow64 word value)).reservedHi =
      (unpackModule word).reservedHi := by
  simp only [unpackModule, writeLow64]
  have hv := uint64Cast_lt value
  change uint64Cast value < 18446744073709551616 at hv
  simp only [two64, two128]
  omega

theorem writeLow64_zero_eq_pack (b : Nat) :
    writeLow64 0 b = packModule ⟨b, 0, 0⟩ := by
  simp [writeLow64, packModule, uint64Cast]

theorem ofNat_val_of_lt {n : Nat} (h : n < Verity.Core.Uint256.modulus) :
    (Verity.Core.Uint256.ofNat n).val = n := by
  simpa [Verity.Core.Uint256.val_ofNat] using Nat.mod_eq_of_lt h

theorem ofNat_eq_pack_zero (b : Nat) (hb : b < two64) :
    (Verity.Core.Uint256.ofNat b).val = packModule ⟨b, 0, 0⟩ := by
  have hmod : b < Verity.Core.Uint256.modulus := by
    rw [← two256_eq_mod]
    exact Nat.lt_trans hb two64_lt_two256
  rw [ofNat_val_of_lt hmod, packModule_zero_of_lt b hb]

theorem ofNat_eq_writeLow64_zero (b : Nat) (hb : b < two64) :
    (Verity.Core.Uint256.ofNat b).val = writeLow64 0 b := by
  rw [ofNat_eq_pack_zero b hb, writeLow64_zero_eq_pack]

/-- Parent `persistBalances` (`HandleOracleReportTx` 162–164, citing
`SRLib.sol:886`) writes `ofNat` of each balance. -/
theorem persistBalances_readArray
    (bals : List Nat) (state : ContractState) :
    (persistBalances bals state).readArray moduleBalancesSlot =
      bals.map Verity.Core.Uint256.ofNat := by
  unfold persistBalances ContractState.readArray ContractState.writeArray
  simp [moduleBalancesSlot]

theorem persistBalances_writes_packed_zero
    (bals : List Nat) (state : ContractState)
    (h : ∀ x ∈ bals, x < two64) :
    (persistBalances bals state).readArray moduleBalancesSlot =
      bals.map (fun b => Verity.Core.Uint256.ofNat (packModule ⟨b, 0, 0⟩)) := by
  rw [persistBalances_readArray]
  induction bals with
  | nil => simp
  | cons b bs ih =>
      have hb : b < two64 := h b (List.mem_cons_self)
      have hbs : ∀ x ∈ bs, x < two64 := fun x hx => h x (List.mem_cons_of_mem _ hx)
      have hword :
          Verity.Core.Uint256.ofNat b =
            Verity.Core.Uint256.ofNat (packModule ⟨b, 0, 0⟩) := by
        apply Verity.Core.Uint256.ext
        have hmod : b < Verity.Core.Uint256.modulus := by
          rw [← two256_eq_mod]
          exact Nat.lt_trans hb two64_lt_two256
        have hpack : packModule ⟨b, 0, 0⟩ < Verity.Core.Uint256.modulus := by
          rw [packModule_zero_of_lt b hb]
          exact hmod
        rw [ofNat_val_of_lt hmod, ofNat_val_of_lt hpack, packModule_zero_of_lt b hb]
      simp [hword, ih hbs]

/-- Parent array words, read back through the pinned getter
`StakingRouter.sol:396-403`. -/
theorem persistBalances_getter_recovers
    (bals : List Nat) (state : ContractState)
    (h : ∀ x ∈ bals, x < two64) :
    ((persistBalances bals state).readArray moduleBalancesSlot).map
        (fun w => (getStakingModuleStateAccounting w.val).1) =
      bals := by
  rw [persistBalances_writes_packed_zero bals state h]
  induction bals with
  | nil => simp
  | cons b bs ih =>
      have hb : b < two64 := h b (List.mem_cons_self)
      have hbs : ∀ x ∈ bs, x < two64 := fun x hx => h x (List.mem_cons_of_mem _ hx)
      have hunp := unpack_pack_module ⟨b, 0, 0⟩ hb two64_pos (by
        change (0 : Nat) < two128
        decide)
      have hpacklt : packModule ⟨b, 0, 0⟩ < Verity.Core.Uint256.modulus := by
        rw [packModule_zero_of_lt b hb, ← two256_eq_mod]
        exact Nat.lt_trans hb two64_lt_two256
      have hhead :
          (getStakingModuleStateAccounting
            (Verity.Core.Uint256.ofNat (packModule ⟨b, 0, 0⟩)).val).1 = b := by
        simp only [getStakingModuleStateAccounting]
        have hval :
            (Verity.Core.Uint256.ofNat (packModule ⟨b, 0, 0⟩)).val =
              packModule ⟨b, 0, 0⟩ :=
          ofNat_val_of_lt hpacklt
        rw [hval]
        exact congrArg ModuleAccounting.validatorsBalanceGwei hunp
      change
          (getStakingModuleStateAccounting
              (Verity.Core.Uint256.ofNat (packModule ⟨b, 0, 0⟩)).val).1 ::
            _ =
        b :: bs
      rw [hhead]
      exact congrArg (List.cons b) (ih hbs)

theorem writeSlot_total_is_packed_router
    (total : Word) (state : ContractState) (h : total.val < two64) :
    ((state.writeSlot totalBalanceSlot total).readSlot totalBalanceSlot).val =
      packRouter ⟨total.val, 0⟩ := by
  simp [ContractState.readSlot_writeSlot_same, packRouter_zero_of_lt total.val h]

theorem writeSlot_total_eq_ofNat_pack
    (total : Word) (state : ContractState) (h : total.val < two64) :
    (state.writeSlot totalBalanceSlot total).readSlot totalBalanceSlot =
      Verity.Core.Uint256.ofNat (packRouter ⟨total.val, 0⟩) := by
  apply Verity.Core.Uint256.ext
  rw [writeSlot_total_is_packed_router total state h]
  have hpack : packRouter ⟨total.val, 0⟩ < Verity.Core.Uint256.modulus := by
    rw [packRouter_zero_of_lt total.val h, ← two256_eq_mod]
    exact Nat.lt_trans h two64_lt_two256
  exact (ofNat_val_of_lt hpack).symm

theorem idsAndBalancesValid_balances_lt_two64 (i : ReportInput)
    (h : idsAndBalancesValid i = true) :
    ∀ x ∈ i.balancesGwei, x < two64 := by
  simp [idsAndBalancesValid, Bool.and_eq_true] at h
  intro x hx
  exact Nat.lt_of_le_of_lt (h.2 x hx) maxValueGwei_lt_two64

theorem accept_inv (i : ReportInput) (acc : AcceptedReport)
    (h : accept i = some acc) :
    idsAndBalancesValid i = true ∧
      checkedTotal64 i.balancesGwei = some acc.totalBalanceGwei ∧
      acc.balancesGwei = i.balancesGwei ∧
      acc.moduleIds = i.reportedModuleIds := by
  unfold accept at h
  cases hValid : idsAndBalancesValid i
  · simp [hValid] at h
  · simp [hValid, Option.bind_eq_some_iff] at h
    rcases h with ⟨total, hTot, hAcc⟩
    cases hAcc
    exact ⟨rfl, hTot, rfl, rfl⟩

theorem sourceView_balances_lt_two64 (i : ReportInput) (fees : Nat) :
    ∀ b ∈ (sourceView i fees).balances, b < two64 := by
  intro b hb
  simp only [sourceView] at hb
  cases hacc : accept i with
  | none =>
      simp [hacc] at hb
  | some acc =>
      simp [hacc] at hb
      have hinv := accept_inv i acc hacc
      rw [hinv.2.2.1] at hb
      exact idsAndBalancesValid_balances_lt_two64 i hinv.1 b hb

theorem sourceView_total_lt_two64 (i : ReportInput) (fees : Nat) :
    (sourceView i fees).total < two64 := by
  simp only [sourceView]
  cases hacc : accept i with
  | none =>
      change 0 < two64
      exact two64_pos
  | some acc =>
      simp
      have hinv := accept_inv i acc hacc
      have hle := checkedTotal64_le i.balancesGwei acc.totalBalanceGwei hinv.2.1
      exact Nat.lt_of_le_of_lt hle uint64Max_lt_two64

/-- Registered Verity parent: `observe` of `handleOracleReport` equals
`sourceView`. Cited so the packing theorems speak about the same committed
run. -/
theorem parent_observe_eq_sourceView
    (i : ReportInput) (fees : Nat) (state : ContractState) :
    observe i ((handleOracleReport i fees).run state) =
      sourceView i fees :=
  LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report i fees state

def storedModuleWords (result : ContractResult Result) : List Word :=
  match result with
  | .success _ post => post.readArray moduleBalancesSlot
  | .revert _ _ => []

/-- Parent `observe` balances (`HandleOracleReportTx` 284) are the unpacked
low-uint64 of the words `persistBalances` wrote. On revert both sides are
`[]`. -/
theorem observe_balances_eq_unpacked_module_words
    (i : ReportInput) (fees : Nat) (state : ContractState) :
    (observe i ((handleOracleReport i fees).run state)).balances =
      (storedModuleWords ((handleOracleReport i fees).run state)).map
        (fun w => (unpackModule w.val).validatorsBalanceGwei) := by
  generalize hrun : (handleOracleReport i fees).run state = result
  have hobs : observe i result = sourceView i fees := by
    simpa [hrun] using parent_observe_eq_sourceView i fees state
  cases result with
  | revert _ _ =>
      simp [observe, storedModuleWords]
  | success r post =>
      have hvals :
          (post.readArray moduleBalancesSlot).map (fun w => w.val) =
            (sourceView i fees).balances := by
        simpa [observe] using congrArg View.balances hobs
      have hleft :
          (observe i (.success r post)).balances =
            (post.readArray moduleBalancesSlot).map (fun w => w.val) := by
        simp [observe]
      refine Eq.trans hleft ?_
      simp only [storedModuleWords]
      refine List.map_congr_left ?_
      intro w hw
      have hmem : w.val ∈ (post.readArray moduleBalancesSlot).map (fun x => x.val) :=
        List.mem_map_of_mem hw
      have hlt : w.val < two64 :=
        sourceView_balances_lt_two64 i fees w.val (hvals ▸ hmem)
      simp [unpackModule, Nat.mod_eq_of_lt hlt]

/-- Parent `observe` total (`HandleOracleReportTx` 285) is the unpacked
low-uint64 of `totalBalanceSlot`. -/
theorem observe_total_eq_unpacked_router_word
    (i : ReportInput) (fees : Nat) (state : ContractState) :
    (observe i ((handleOracleReport i fees).run state)).total =
      match (handleOracleReport i fees).run state with
      | .success _ post =>
          getRouterValidatorsBalanceGwei (post.readSlot totalBalanceSlot).val
      | .revert _ _ => 0 := by
  generalize hrun : (handleOracleReport i fees).run state = result
  have hobs : observe i result = sourceView i fees := by
    simpa [hrun] using parent_observe_eq_sourceView i fees state
  cases result with
  | revert _ _ =>
      simp [observe]
  | success r post =>
      have htot : (observe i (.success r post)).total =
          (post.readSlot totalBalanceSlot).val := by
        simp [observe]
      have hsrc : (observe i (.success r post)).total =
          (sourceView i fees).total := congrArg View.total hobs
      have hlt : (post.readSlot totalBalanceSlot).val < two64 := by
        rw [← htot, hsrc]
        exact sourceView_total_lt_two64 i fees
      simp [getRouterValidatorsBalanceGwei, unpackRouter, Nat.mod_eq_of_lt hlt]
      exact htot

theorem sourceView_success_balances
    (i : ReportInput) (fees : Nat)
    (h : (sourceView i fees).status = .committed) :
    (sourceView i fees).balances = i.balancesGwei ∧
      idsAndBalancesValid i = true := by
  simp only [sourceView] at h ⊢
  cases hacc : accept i with
  | none =>
      simp [hacc] at h
  | some acc =>
      have hinv := accept_inv i acc hacc
      simp [hinv.2.2.1, hinv.1]

/-- On a committed parent run, every stored module word value is
`packModule ⟨balance, 0, 0⟩`. -/
theorem committed_module_words_are_packed_zero
    (i : ReportInput) (fees : Nat) (state : ContractState)
    (r : Result) (post : ContractState)
    (h : (handleOracleReport i fees).run state = .success r post) :
    (post.readArray moduleBalancesSlot).map (fun w => w.val) =
      i.balancesGwei.map (fun b => packModule ⟨b, 0, 0⟩) := by
  have hobs : observe i (.success r post) = sourceView i fees := by
    simpa [h] using parent_observe_eq_sourceView i fees state
  have hstat : (sourceView i fees).status = .committed := by
    simpa [observe] using (congrArg View.status hobs).symm
  have hsucc := sourceView_success_balances i fees hstat
  have hvals :
      (post.readArray moduleBalancesSlot).map (fun w => w.val) =
        i.balancesGwei := by
    have := congrArg View.balances hobs
    simpa [observe, hsucc.1] using this
  rw [hvals]
  have hpack : ∀ b ∈ i.balancesGwei, packModule ⟨b, 0, 0⟩ = b :=
    fun b hb => packModule_zero_of_lt b
      (idsAndBalancesValid_balances_lt_two64 i hsucc.2 b hb)
  rw [List.map_congr_left hpack]
  exact (List.map_id' i.balancesGwei).symm

#print axioms unpack_pack_module
#print axioms pack_unpack_module
#print axioms unpack_pack_router
#print axioms pack_unpack_router
#print axioms writeLow64_sets_balance
#print axioms writeLow64_preserves_exited
#print axioms writeLow64_preserves_reserved
#print axioms persistBalances_writes_packed_zero
#print axioms persistBalances_getter_recovers
#print axioms writeSlot_total_is_packed_router
#print axioms observe_balances_eq_unpacked_module_words
#print axioms observe_total_eq_unpacked_router_word
#print axioms committed_module_words_are_packed_zero
#print axioms parent_observe_eq_sourceView

end LidoSRv3.Audit.Source.AccountPackedWords
