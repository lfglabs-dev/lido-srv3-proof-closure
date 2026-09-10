import Std

/-!
Physical-storage equivariance of address-bearing packed words for the
P-ADDRESS-1 slice at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
No registered guarantee model is imported.

Two pinned packed storage words carry an address field:

* `contracts/0.8.25/sr/SRTypes.sol:118-135` `ModuleStateConfig`, one slot,
  reached as `RouterState.moduleStates[moduleId].config` (`SRTypes.sol:174-176`
  struct offset 0, mapping declared at `SRTypes.sol:187`; the mapping value
  slot is `keccak256(abi.encode(moduleId, ROUTER_STORAGE_POSITION))`).
  Layout from the low bit: `moduleAddress` 0..159, `moduleFee` 160..175,
  `treasuryFee` 176..191, `stakeShareLimit` 192..207,
  `priorityExitShareThreshold` 208..223, `status` 224..231,
  `withdrawalCredentialsType` 232..239, reserved 240..255.
  The address is written at `SRLib.sol:213` (`_addModule`) and compared in
  the duplicate scan at `SRLib.sol:200-206`.
* `contracts/0.4.24/nos/NodeOperatorsRegistry.sol:171-175` `NodeOperator`
  first slot: `active` bits 0..7, `rewardAddress` bits 8..167, bits 168..255
  unused (`name` starts the next slot). The address is written at
  `NodeOperatorsRegistry.sol:300` (`addNodeOperator`) and `:374`
  (`setNodeOperatorRewardAddress`, guarded by the inequality at `:373`).

A renaming `rho : Address -> Address` acts on a physical word by rewriting
exactly the address field. Equivariance means: decoding the renamed word is
the renamed decoding, every non-address bit is preserved, no write wraps past
`2^256`, and the pinned source comparisons on the address field are
transported by an injective renaming. Slot derivation is an explicit
`keccak` parameter, never an injectivity axiom. Execution-to-storage
refinement is outside this slice.
-/

namespace AccountAddress.PAddress1Physical

def two8 : Nat := 2 ^ 8
def two16 : Nat := 2 ^ 16
def two88 : Nat := 2 ^ 88
def two160 : Nat := 2 ^ 160
def two168 : Nat := 2 ^ 168
def two176 : Nat := 2 ^ 176
def two192 : Nat := 2 ^ 192
def two208 : Nat := 2 ^ 208
def two224 : Nat := 2 ^ 224
def two232 : Nat := 2 ^ 232
def two240 : Nat := 2 ^ 240
def two256 : Nat := 2 ^ 256

instance : NeZero two160 := ⟨by decide⟩

/-- Solidity `address`: exactly the values representable in 160 bits. -/
abbrev Address := Fin two160
/-- One physical EVM storage word. -/
abbrev Word := Fin two256

/-- An address renaming is any function on addresses. Injectivity is an
explicit hypothesis where a source comparison is transported. -/
abbrev Renaming := Address → Address

def Injective (rho : Renaming) : Prop := ∀ x y, rho x = rho y → x = y

/-- Transposition of two addresses; every other address is fixed. -/
def swap (a b : Address) : Renaming :=
  fun x => if x = a then b else if x = b then a else x

theorem swap_swap (a b x : Address) : swap a b (swap a b x) = x := by
  unfold swap
  by_cases hxa : x = a <;> by_cases hxb : x = b <;> by_cases hab : a = b <;> simp_all

theorem swap_injective (a b : Address) : Injective (swap a b) := by
  intro x y h
  have := congrArg (swap a b) h
  rwa [swap_swap, swap_swap] at this

/-! ## SRStorage `ModuleStateConfig` word -/

/-- Logical view of one `ModuleStateConfig` slot. Every field is bounded to
its declared width, so encode and decode are mutually inverse. -/
@[ext] structure ModuleConfig where
  moduleAddress : Address
  moduleFee : Fin two16
  treasuryFee : Fin two16
  stakeShareLimit : Fin two16
  priorityExitShareThreshold : Fin two16
  status : Fin two8
  wcType : Fin two8
  reserved : Fin two16
  deriving Repr, DecidableEq

def moduleAddressOf (w : Nat) : Address := ⟨w % two160, Nat.mod_lt _ (by decide)⟩

def decodeModule (w : Nat) : ModuleConfig :=
  { moduleAddress := moduleAddressOf w
    moduleFee := ⟨w / two160 % two16, Nat.mod_lt _ (by decide)⟩
    treasuryFee := ⟨w / two176 % two16, Nat.mod_lt _ (by decide)⟩
    stakeShareLimit := ⟨w / two192 % two16, Nat.mod_lt _ (by decide)⟩
    priorityExitShareThreshold := ⟨w / two208 % two16, Nat.mod_lt _ (by decide)⟩
    status := ⟨w / two224 % two8, Nat.mod_lt _ (by decide)⟩
    wcType := ⟨w / two232 % two8, Nat.mod_lt _ (by decide)⟩
    reserved := ⟨w / two240 % two16, Nat.mod_lt _ (by decide)⟩ }

def encodeModule (c : ModuleConfig) : Nat :=
  c.moduleAddress.val + c.moduleFee.val * two160 + c.treasuryFee.val * two176 +
    c.stakeShareLimit.val * two192 + c.priorityExitShareThreshold.val * two208 +
    c.status.val * two224 + c.wcType.val * two232 + c.reserved.val * two240

/-- Packed assignment `moduleState.config.moduleAddress = _moduleAddress`
(`SRLib.sol:213`): bits 0..159 replaced, bits 160..255 untouched. -/
def writeModuleAddress (w : Nat) (a : Address) : Nat :=
  (w / two160) * two160 + a.val

/-- Physical renaming of one config word: rewrite exactly the address field. -/
def renameModuleWord (rho : Renaming) (w : Nat) : Nat :=
  writeModuleAddress w (rho (moduleAddressOf w))

/-- Logical renaming of the decoded view. -/
def renameModuleConfig (rho : Renaming) (c : ModuleConfig) : ModuleConfig :=
  { c with moduleAddress := rho c.moduleAddress }

theorem moduleAddressOf_writeModuleAddress (w : Nat) (a : Address) :
    moduleAddressOf (writeModuleAddress w a) = a := by
  have ha : a.val < 2 ^ 160 := a.isLt
  apply Fin.ext
  simp only [moduleAddressOf, writeModuleAddress, two160]
  omega

theorem writeModuleAddress_tail (w : Nat) (a : Address) :
    writeModuleAddress w a / two160 = w / two160 := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeModuleAddress, two160]
  omega

theorem writeModuleAddress_lt (w : Nat) (hw : w < two256) (a : Address) :
    writeModuleAddress w a < two256 := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeModuleAddress, two160, two256] at *
  omega

theorem writeModuleAddress_writeModuleAddress (w : Nat) (a b : Address) :
    writeModuleAddress (writeModuleAddress w a) b = writeModuleAddress w b := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeModuleAddress, two160]
  omega

theorem writeModuleAddress_moduleAddressOf (w : Nat) :
    writeModuleAddress w (moduleAddressOf w) = w := by
  simp only [writeModuleAddress, moduleAddressOf, two160]
  omega

/-- Decoding after the packed address write changes only the address field. -/
theorem decodeModule_writeModuleAddress (w : Nat) (a : Address) :
    decodeModule (writeModuleAddress w a) = { decodeModule w with moduleAddress := a } := by
  have ha : a.val < 2 ^ 160 := a.isLt
  ext <;> simp only [decodeModule, moduleAddressOf, writeModuleAddress, two8, two16, two160,
    two176, two192, two208, two224, two232, two240] <;> omega

/-- Physical-storage equivariance of the module address: decoding the renamed
word is the renamed decoding. -/
theorem decodeModule_renameModuleWord (rho : Renaming) (w : Nat) :
    decodeModule (renameModuleWord rho w) = renameModuleConfig rho (decodeModule w) := by
  unfold renameModuleWord
  rw [decodeModule_writeModuleAddress]
  rfl

theorem moduleAddressOf_renameModuleWord (rho : Renaming) (w : Nat) :
    moduleAddressOf (renameModuleWord rho w) = rho (moduleAddressOf w) :=
  moduleAddressOf_writeModuleAddress _ _

theorem renameModuleWord_tail (rho : Renaming) (w : Nat) :
    renameModuleWord rho w / two160 = w / two160 :=
  writeModuleAddress_tail _ _

theorem renameModuleWord_lt (rho : Renaming) (w : Nat) (hw : w < two256) :
    renameModuleWord rho w < two256 :=
  writeModuleAddress_lt _ hw _

theorem renameModuleWord_id (w : Nat) : renameModuleWord id w = w :=
  writeModuleAddress_moduleAddressOf w

theorem renameModuleWord_comp (rho sigma : Renaming) (w : Nat) :
    renameModuleWord rho (renameModuleWord sigma w) = renameModuleWord (rho ∘ sigma) w := by
  simp only [renameModuleWord, moduleAddressOf_writeModuleAddress,
    writeModuleAddress_writeModuleAddress, Function.comp]

theorem renameModuleWord_swap_swap (a b : Address) (w : Nat) :
    renameModuleWord (swap a b) (renameModuleWord (swap a b) w) = w := by
  rw [renameModuleWord_comp]
  have : (swap a b ∘ swap a b) = id := funext (swap_swap a b)
  rw [this, renameModuleWord_id]

theorem renameModuleWord_injective (rho : Renaming) (h : Injective rho) (w₁ w₂ : Nat)
    (heq : renameModuleWord rho w₁ = renameModuleWord rho w₂) : w₁ = w₂ := by
  have htail : w₁ / two160 = w₂ / two160 := by
    rw [← renameModuleWord_tail rho w₁, ← renameModuleWord_tail rho w₂, heq]
  have haddr : moduleAddressOf w₁ = moduleAddressOf w₂ := by
    apply h
    rw [← moduleAddressOf_renameModuleWord rho w₁, ← moduleAddressOf_renameModuleWord rho w₂, heq]
  have hval : w₁ % two160 = w₂ % two160 := congrArg Fin.val haddr
  simp only [two160] at htail hval
  omega

theorem encodeModule_lt (c : ModuleConfig) : encodeModule c < two256 := by
  have h0 : c.moduleAddress.val < 2 ^ 160 := c.moduleAddress.isLt
  have h1 : c.moduleFee.val < 2 ^ 16 := c.moduleFee.isLt
  have h2 : c.treasuryFee.val < 2 ^ 16 := c.treasuryFee.isLt
  have h3 : c.stakeShareLimit.val < 2 ^ 16 := c.stakeShareLimit.isLt
  have h4 : c.priorityExitShareThreshold.val < 2 ^ 16 := c.priorityExitShareThreshold.isLt
  have h5 : c.status.val < 2 ^ 8 := c.status.isLt
  have h6 : c.wcType.val < 2 ^ 8 := c.wcType.isLt
  have h7 : c.reserved.val < 2 ^ 16 := c.reserved.isLt
  simp only [encodeModule, two160, two176, two192, two208, two224, two232, two240, two256]
  omega

/-- Every logical view has exactly one physical word. -/
theorem decodeModule_encodeModule (c : ModuleConfig) : decodeModule (encodeModule c) = c := by
  have h0 : c.moduleAddress.val < 2 ^ 160 := c.moduleAddress.isLt
  have h1 : c.moduleFee.val < 2 ^ 16 := c.moduleFee.isLt
  have h2 : c.treasuryFee.val < 2 ^ 16 := c.treasuryFee.isLt
  have h3 : c.stakeShareLimit.val < 2 ^ 16 := c.stakeShareLimit.isLt
  have h4 : c.priorityExitShareThreshold.val < 2 ^ 16 := c.priorityExitShareThreshold.isLt
  have h5 : c.status.val < 2 ^ 8 := c.status.isLt
  have h6 : c.wcType.val < 2 ^ 8 := c.wcType.isLt
  have h7 : c.reserved.val < 2 ^ 16 := c.reserved.isLt
  ext <;> simp only [decodeModule, encodeModule, moduleAddressOf, two8, two16, two160, two176,
    two192, two208, two224, two232, two240] <;> omega

/-- Every physical word is exactly its logical view: the layout has no hidden bits. -/
theorem encodeModule_decodeModule (w : Nat) (hw : w < two256) :
    encodeModule (decodeModule w) = w := by
  simp only [decodeModule, encodeModule, moduleAddressOf, two8, two16, two160, two176, two192,
    two208, two224, two232, two240, two256] at *
  omega

/-- The physical renaming is the logical renaming transported through the layout. -/
theorem renameModuleWord_eq_encode (rho : Renaming) (w : Nat) (hw : w < two256) :
    renameModuleWord rho w = encodeModule (renameModuleConfig rho (decodeModule w)) := by
  rw [← decodeModule_renameModuleWord, encodeModule_decodeModule _ (renameModuleWord_lt rho w hw)]

theorem renameModuleWord_encodeModule (rho : Renaming) (c : ModuleConfig) :
    renameModuleWord rho (encodeModule c) = encodeModule (renameModuleConfig rho c) := by
  rw [renameModuleWord_eq_encode rho _ (encodeModule_lt c), decodeModule_encodeModule]

/-- `SRLib.sol:203` duplicate-address comparison, transported by an injective
renaming: the candidate `rho a` collides with the renamed stored word exactly
when `a` collides with the original stored word. -/
theorem duplicate_check_equivariant (rho : Renaming) (h : Injective rho) (a : Address)
    (w : Nat) :
    (rho a = moduleAddressOf (renameModuleWord rho w)) ↔ (a = moduleAddressOf w) := by
  rw [moduleAddressOf_renameModuleWord]
  exact ⟨fun heq => h _ _ heq, fun heq => congrArg rho heq⟩

/-! ## Storage-level renaming over `RouterState.moduleStates` -/

abbrev Byte := Fin 256
def byte (n : Nat) : Byte := ⟨n % 256, Nat.mod_lt _ (by decide)⟩

/-- Fixed-width big-endian ABI word encoding, truncating only above the width. -/
def encodeBE : Nat → Nat → List Byte
  | 0, _ => []
  | width + 1, n => encodeBE width (n / 256) ++ [byte n]

def encodeWord (w : Word) : List Byte := encodeBE 32 w.val

def toWord (n : Nat) : Word := ⟨n % two256, Nat.mod_lt _ (by decide)⟩

/-- A physical storage is a total word map. -/
abbrev Storage := Word → Word

/-- `ROUTER_STORAGE_POSITION` and the hash are explicit parameters. No
injectivity or collision-freedom of `keccak` is assumed anywhere below. -/
structure Layout where
  routerSlot : Word
  keccak : List Byte → Word

/-- `moduleStates[moduleId].config`: value slot of the mapping at struct offset
0 of `RouterState`, i.e. `keccak256(abi.encode(moduleId, ROUTER_STORAGE_POSITION))`,
plus the `ModuleState.config` offset 0. -/
def configSlot (l : Layout) (id : Word) : Word :=
  l.keccak (encodeWord id ++ encodeWord l.routerSlot)

/-- Physical renaming of every module config word for the enumerated ids, and
nothing else. `ids` plays the role of the `getModuleIdAt` enumeration. -/
def renameStorage (rho : Renaming) (l : Layout) (ids : List Word) (s : Storage) : Storage :=
  fun slot =>
    if slot ∈ ids.map (configSlot l) then toWord (renameModuleWord rho (s slot).val)
    else s slot

theorem toWord_renameModuleWord (rho : Renaming) (w : Word) :
    (toWord (renameModuleWord rho w.val)).val = renameModuleWord rho w.val := by
  simp [toWord, Nat.mod_eq_of_lt (renameModuleWord_lt rho w.val w.isLt)]

theorem renameStorage_config (rho : Renaming) (l : Layout) (ids : List Word) (s : Storage)
    (id : Word) (h : id ∈ ids) :
    (renameStorage rho l ids s (configSlot l id)).val =
      renameModuleWord rho (s (configSlot l id)).val := by
  have hmem : configSlot l id ∈ ids.map (configSlot l) := List.mem_map_of_mem h
  simp only [renameStorage, if_pos hmem]
  exact toWord_renameModuleWord rho _

/-- Storage-level equivariance of the stored module address. -/
theorem moduleAddress_renameStorage (rho : Renaming) (l : Layout) (ids : List Word)
    (s : Storage) (id : Word) (h : id ∈ ids) :
    moduleAddressOf (renameStorage rho l ids s (configSlot l id)).val =
      rho (moduleAddressOf (s (configSlot l id)).val) := by
  rw [renameStorage_config rho l ids s id h]
  exact moduleAddressOf_renameModuleWord rho _

/-- Storage-level equivariance of the whole decoded config. -/
theorem decodeModule_renameStorage (rho : Renaming) (l : Layout) (ids : List Word)
    (s : Storage) (id : Word) (h : id ∈ ids) :
    decodeModule (renameStorage rho l ids s (configSlot l id)).val =
      renameModuleConfig rho (decodeModule (s (configSlot l id)).val) := by
  rw [renameStorage_config rho l ids s id h]
  exact decodeModule_renameModuleWord rho _

/-- Slots outside the enumerated config slots are untouched, word for word. -/
theorem renameStorage_untouched (rho : Renaming) (l : Layout) (ids : List Word) (s : Storage)
    (slot : Word) (h : slot ∉ ids.map (configSlot l)) :
    renameStorage rho l ids s slot = s slot := by
  simp only [renameStorage, if_neg h]

/-- At every slot, all bits at or above 160 are preserved. -/
theorem renameStorage_tail (rho : Renaming) (l : Layout) (ids : List Word) (s : Storage)
    (slot : Word) :
    (renameStorage rho l ids s slot).val / two160 = (s slot).val / two160 := by
  unfold renameStorage
  split
  · rw [toWord_renameModuleWord]
    exact renameModuleWord_tail rho _
  · rfl

/-- The enumerated module addresses of the renamed storage are the renamed
enumerated module addresses. -/
theorem moduleAddresses_renameStorage (rho : Renaming) (l : Layout) (ids : List Word)
    (s : Storage) :
    ids.map (fun id => moduleAddressOf (renameStorage rho l ids s (configSlot l id)).val) =
      ids.map (fun id => rho (moduleAddressOf (s (configSlot l id)).val)) :=
  List.map_congr_left (fun id h => moduleAddress_renameStorage rho l ids s id h)

/-- The `SRLib.sol:200-206` duplicate scan over the enumeration is transported
by an injective renaming. -/
theorem duplicate_scan_equivariant (rho : Renaming) (hinj : Injective rho) (l : Layout)
    (ids : List Word) (s : Storage) (a : Address) :
    (rho a ∈ ids.map (fun id => moduleAddressOf (renameStorage rho l ids s (configSlot l id)).val))
      ↔ (a ∈ ids.map (fun id => moduleAddressOf (s (configSlot l id)).val)) := by
  rw [moduleAddresses_renameStorage]
  simp only [List.mem_map]
  constructor
  · rintro ⟨id, hid, heq⟩
    exact ⟨id, hid, hinj _ _ heq⟩
  · rintro ⟨id, hid, heq⟩
    exact ⟨id, hid, congrArg rho heq⟩

/-! ## NodeOperatorsRegistry `NodeOperator` first word -/

/-- Logical view of the first `NodeOperator` slot: `active` byte, packed
`rewardAddress`, and the unused high 88 bits. -/
@[ext] structure OperatorSlot where
  active : Fin two8
  rewardAddress : Address
  unused : Fin two88
  deriving Repr, DecidableEq

def activeOf (w : Nat) : Fin two8 := ⟨w % two8, Nat.mod_lt _ (by decide)⟩
def rewardAddressOf (w : Nat) : Address := ⟨w / two8 % two160, Nat.mod_lt _ (by decide)⟩
def unusedOf (w : Nat) : Fin two88 := ⟨w / two168 % two88, Nat.mod_lt _ (by decide)⟩

def decodeOperator (w : Nat) : OperatorSlot :=
  { active := activeOf w, rewardAddress := rewardAddressOf w, unused := unusedOf w }

def encodeOperator (o : OperatorSlot) : Nat :=
  o.active.val + o.rewardAddress.val * two8 + o.unused.val * two168

/-- Packed assignment `operator.rewardAddress = _rewardAddress`
(`NodeOperatorsRegistry.sol:300`, `:374`): bits 8..167 replaced, the `active`
byte and bits 168..255 untouched. -/
def writeRewardAddress (w : Nat) (a : Address) : Nat :=
  (w / two168) * two168 + a.val * two8 + w % two8

def renameOperatorWord (rho : Renaming) (w : Nat) : Nat :=
  writeRewardAddress w (rho (rewardAddressOf w))

def renameOperatorSlot (rho : Renaming) (o : OperatorSlot) : OperatorSlot :=
  { o with rewardAddress := rho o.rewardAddress }

theorem rewardAddressOf_writeRewardAddress (w : Nat) (a : Address) :
    rewardAddressOf (writeRewardAddress w a) = a := by
  have ha : a.val < 2 ^ 160 := a.isLt
  apply Fin.ext
  simp only [rewardAddressOf, writeRewardAddress, two8, two160, two168]
  omega

theorem writeRewardAddress_active (w : Nat) (a : Address) :
    writeRewardAddress w a % two8 = w % two8 := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeRewardAddress, two8, two168]
  omega

theorem writeRewardAddress_tail (w : Nat) (a : Address) :
    writeRewardAddress w a / two168 = w / two168 := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeRewardAddress, two8, two168]
  omega

theorem writeRewardAddress_lt (w : Nat) (hw : w < two256) (a : Address) :
    writeRewardAddress w a < two256 := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeRewardAddress, two8, two168, two256] at *
  omega

theorem writeRewardAddress_writeRewardAddress (w : Nat) (a b : Address) :
    writeRewardAddress (writeRewardAddress w a) b = writeRewardAddress w b := by
  have ha : a.val < 2 ^ 160 := a.isLt
  simp only [writeRewardAddress, two8, two168]
  omega

theorem writeRewardAddress_rewardAddressOf (w : Nat) :
    writeRewardAddress w (rewardAddressOf w) = w := by
  simp only [writeRewardAddress, rewardAddressOf, two8, two160, two168]
  omega

theorem decodeOperator_writeRewardAddress (w : Nat) (a : Address) :
    decodeOperator (writeRewardAddress w a) = { decodeOperator w with rewardAddress := a } := by
  have ha : a.val < 2 ^ 160 := a.isLt
  ext <;> simp only [decodeOperator, activeOf, rewardAddressOf, unusedOf, writeRewardAddress,
    two8, two88, two160, two168] <;> omega

/-- Physical-storage equivariance of the operator reward address. -/
theorem decodeOperator_renameOperatorWord (rho : Renaming) (w : Nat) :
    decodeOperator (renameOperatorWord rho w) = renameOperatorSlot rho (decodeOperator w) := by
  unfold renameOperatorWord
  rw [decodeOperator_writeRewardAddress]
  rfl

theorem rewardAddressOf_renameOperatorWord (rho : Renaming) (w : Nat) :
    rewardAddressOf (renameOperatorWord rho w) = rho (rewardAddressOf w) :=
  rewardAddressOf_writeRewardAddress _ _

theorem renameOperatorWord_active (rho : Renaming) (w : Nat) :
    renameOperatorWord rho w % two8 = w % two8 :=
  writeRewardAddress_active _ _

theorem renameOperatorWord_tail (rho : Renaming) (w : Nat) :
    renameOperatorWord rho w / two168 = w / two168 :=
  writeRewardAddress_tail _ _

theorem renameOperatorWord_lt (rho : Renaming) (w : Nat) (hw : w < two256) :
    renameOperatorWord rho w < two256 :=
  writeRewardAddress_lt _ hw _

theorem renameOperatorWord_id (w : Nat) : renameOperatorWord id w = w :=
  writeRewardAddress_rewardAddressOf w

theorem renameOperatorWord_comp (rho sigma : Renaming) (w : Nat) :
    renameOperatorWord rho (renameOperatorWord sigma w) =
      renameOperatorWord (rho ∘ sigma) w := by
  simp only [renameOperatorWord, rewardAddressOf_writeRewardAddress,
    writeRewardAddress_writeRewardAddress, Function.comp]

theorem renameOperatorWord_swap_swap (a b : Address) (w : Nat) :
    renameOperatorWord (swap a b) (renameOperatorWord (swap a b) w) = w := by
  rw [renameOperatorWord_comp]
  have : (swap a b ∘ swap a b) = id := funext (swap_swap a b)
  rw [this, renameOperatorWord_id]

theorem encodeOperator_lt (o : OperatorSlot) : encodeOperator o < two256 := by
  have h0 : o.active.val < 2 ^ 8 := o.active.isLt
  have h1 : o.rewardAddress.val < 2 ^ 160 := o.rewardAddress.isLt
  have h2 : o.unused.val < 2 ^ 88 := o.unused.isLt
  simp only [encodeOperator, two8, two168, two256]
  omega

theorem decodeOperator_encodeOperator (o : OperatorSlot) :
    decodeOperator (encodeOperator o) = o := by
  have h0 : o.active.val < 2 ^ 8 := o.active.isLt
  have h1 : o.rewardAddress.val < 2 ^ 160 := o.rewardAddress.isLt
  have h2 : o.unused.val < 2 ^ 88 := o.unused.isLt
  ext <;> simp only [decodeOperator, encodeOperator, activeOf, rewardAddressOf, unusedOf,
    two8, two88, two160, two168] <;> omega

theorem encodeOperator_decodeOperator (w : Nat) (hw : w < two256) :
    encodeOperator (decodeOperator w) = w := by
  simp only [decodeOperator, encodeOperator, activeOf, rewardAddressOf, unusedOf, two8, two88,
    two160, two168, two256] at *
  omega

theorem renameOperatorWord_encodeOperator (rho : Renaming) (o : OperatorSlot) :
    renameOperatorWord rho (encodeOperator o) = encodeOperator (renameOperatorSlot rho o) := by
  rw [← encodeOperator_decodeOperator (renameOperatorWord rho (encodeOperator o))
    (renameOperatorWord_lt rho _ (encodeOperator_lt o)), decodeOperator_renameOperatorWord,
    decodeOperator_encodeOperator]

/-- `NodeOperatorsRegistry.sol:373` `_requireNotSameValue(rewardAddress != _rewardAddress)`,
transported by an injective renaming. -/
theorem reward_address_change_check_equivariant (rho : Renaming) (h : Injective rho)
    (a : Address) (w : Nat) :
    (rewardAddressOf (renameOperatorWord rho w) ≠ rho a) ↔ (rewardAddressOf w ≠ a) := by
  rw [rewardAddressOf_renameOperatorWord]
  exact ⟨fun hne heq => hne (congrArg rho heq), fun hne heq => hne (h _ _ heq)⟩

end AccountAddress.PAddress1Physical
