import PAddress1Physical

/-!
Concrete vectors and mutant kill-lines for the physical-storage address
equivariance slice. Every check is kernel-checked `decide` (the storage-level vectors use
`decide +kernel`, which is the same kernel evaluation without the elaborator
pre-pass); no `native_decide`, `sorry`, or `admit`.
-/

namespace AccountAddress.Tests.Verity.PAddress1PhysicalTest
open AccountAddress.PAddress1Physical

/-! ## SRStorage `ModuleStateConfig` vectors -/

/-- Two distinct illustrative module addresses. -/
def a1 : Address := ⟨0x55032650b14df07b85bF18A3a3eC8E0Af2e028d5, by decide⟩
def a2 : Address := ⟨0xFdDf38947aFB03C621C71b06C9C70bce73f12999, by decide⟩

def rho : Renaming := swap a1 a2

/-- `moduleAddress = a1`, fees 500/500 BP, share 10000, priority 10000,
`status = Active`, WC type `0x01`, reserved bits `0xBEEF` (exercised, not
assumed zero). -/
def moduleWord : Nat :=
  a1.val + 500 * two160 + 500 * two176 + 10000 * two192 + 10000 * two208 +
    0 * two224 + 1 * two232 + 0xBEEF * two240

def moduleView : ModuleConfig :=
  { moduleAddress := a1, moduleFee := ⟨500, by decide⟩, treasuryFee := ⟨500, by decide⟩
    stakeShareLimit := ⟨10000, by decide⟩, priorityExitShareThreshold := ⟨10000, by decide⟩
    status := ⟨0, by decide⟩, wcType := ⟨1, by decide⟩, reserved := ⟨0xBEEF, by decide⟩ }

example : decodeModule moduleWord = moduleView := by decide
example : encodeModule moduleView = moduleWord := by decide
example : moduleWord < two256 := by decide

example : rho a1 = a2 ∧ rho a2 = a1 ∧ rho 7 = 7 := by decide

/-- The physical renaming moves exactly the address bits. -/
example : renameModuleWord rho moduleWord =
    a2.val + 500 * two160 + 500 * two176 + 10000 * two192 + 10000 * two208 +
      0 * two224 + 1 * two232 + 0xBEEF * two240 := by decide

example : decodeModule (renameModuleWord rho moduleWord) =
    { moduleView with moduleAddress := a2 } := by decide

example : renameModuleWord rho (renameModuleWord rho moduleWord) = moduleWord := by decide

/-- A word with every reserved and high bit set does not wrap. -/
def fullTailWord : Nat := a1.val + (two256 / two160 - 1) * two160

example : fullTailWord < two256 ∧ renameModuleWord rho fullTailWord < two256 ∧
    renameModuleWord rho fullTailWord / two160 = fullTailWord / two160 := by decide

/-! ## Storage-level vectors -/

/-- Toy hash for the vector only; the theorems never assume anything about it. -/
def toyKeccak (bs : List Byte) : Word :=
  toWord (bs.foldl (fun acc b => acc * 31 + b.val + 1) 0)

def layout : Layout := { routerSlot := ⟨0x1234, by decide⟩, keccak := toyKeccak }

def id1 : Word := ⟨1, by decide⟩
def id2 : Word := ⟨2, by decide⟩
def freeSlot : Word := ⟨77, by decide⟩

def otherWord : Nat := a2.val + 250 * two160 + 750 * two176 + 5000 * two192 + 6000 * two208 +
  1 * two224 + 2 * two232

def storage : Storage := fun slot =>
  if slot = configSlot layout id1 then toWord moduleWord
  else if slot = configSlot layout id2 then toWord otherWord
  else if slot = freeSlot then toWord (a1.val + 3 * two160)
  else toWord 0

example : configSlot layout id1 ≠ configSlot layout id2 ∧
    configSlot layout id1 ≠ freeSlot ∧ configSlot layout id2 ≠ freeSlot := by decide +kernel

example : decodeModule (renameStorage rho layout [id1, id2] storage (configSlot layout id1)).val =
    { moduleView with moduleAddress := a2 } := by decide +kernel

example : moduleAddressOf (renameStorage rho layout [id1, id2] storage (configSlot layout id2)).val =
    a1 := by decide +kernel

/-- A non-config slot that happens to hold `a1` in its low bits is untouched. -/
example : renameStorage rho layout [id1, id2] storage freeSlot = toWord (a1.val + 3 * two160) := by
  decide +kernel

/-- Only the enumerated ids are renamed: with `id2` absent, its word stays. -/
example : renameStorage rho layout [id1] storage (configSlot layout id2) = toWord otherWord := by
  decide +kernel

/-- Duplicate scan (`SRLib.sol:200-206`) on the renamed storage sees `a2`
where the original saw `a1`, and not the other way round. -/
example :
    (a1 ∈ [id1, id2].map (fun id => moduleAddressOf (storage (configSlot layout id)).val)) ∧
    (rho a1 ∈ [id1, id2].map (fun id =>
      moduleAddressOf (renameStorage rho layout [id1, id2] storage (configSlot layout id)).val)) ∧
    ¬ (⟨7, by decide⟩ ∈ [id1, id2].map (fun id => moduleAddressOf (storage (configSlot layout id)).val)) ∧
    ¬ (rho ⟨7, by decide⟩ ∈ [id1, id2].map (fun id =>
      moduleAddressOf (renameStorage rho layout [id1, id2] storage (configSlot layout id)).val)) := by
  decide +kernel

/-! ## NodeOperatorsRegistry `NodeOperator` vectors -/

/-- `active = 1`, `rewardAddress = a1`, unused high bits `0x2A` (exercised). -/
def operatorWord : Nat := 1 + a1.val * two8 + 0x2A * two168

def operatorView : OperatorSlot :=
  { active := ⟨1, by decide⟩, rewardAddress := a1, unused := ⟨0x2A, by decide⟩ }

example : decodeOperator operatorWord = operatorView := by decide
example : encodeOperator operatorView = operatorWord := by decide

example : renameOperatorWord rho operatorWord = 1 + a2.val * two8 + 0x2A * two168 := by decide

example : decodeOperator (renameOperatorWord rho operatorWord) =
    { operatorView with rewardAddress := a2 } := by decide

example : renameOperatorWord rho (renameOperatorWord rho operatorWord) = operatorWord := by decide

/-! ## Mutant kill-lines

Each mutant is a plausible wrong physical renaming. Each is refuted on a
concrete word against the exact equivariance shape proved for the real
`renameModuleWord` / `renameOperatorWord`. -/

/-- Mutant 1: the operator layout (address at bit 8) applied to the module
word. Kills a model that confuses the two pinned layouts. -/
def mutantOffsetByte (rho : Renaming) (w : Nat) : Nat :=
  (w / two168) * two168 + (rho (moduleAddressOf w)).val * two8 + w % two8

theorem mutant_offset_byte_killed :
    decodeModule (mutantOffsetByte rho moduleWord) ≠
      renameModuleConfig rho (decodeModule moduleWord) := by decide

/-- Mutant 2: writes only the low 152 bits of the renamed address (drops the
top address byte). Kills a model with a 19-byte address mask. -/
def mutantTruncate (rho : Renaming) (w : Nat) : Nat :=
  (w / two160) * two160 + (rho (moduleAddressOf w)).val % 2 ^ 152

theorem mutant_truncate_killed :
    decodeModule (mutantTruncate rho moduleWord) ≠
      renameModuleConfig rho (decodeModule moduleWord) := by decide

/-- Mutant 3: a fixed module address that the renaming never moves, the
physical-storage analogue of the parent's fixed-owner gate kill-line. -/
def mutantFixedModule (fixed : Address) (rho : Renaming) (w : Nat) : Nat :=
  if moduleAddressOf w = fixed then w else renameModuleWord rho w

theorem mutant_fixed_module_killed :
    decodeModule (mutantFixedModule a1 rho moduleWord) ≠
      renameModuleConfig rho (decodeModule moduleWord) := by decide

/-- Mutant 4: renames the module address but also clears the reserved bits.
Kills a model that "normalizes" the word while renaming. -/
def mutantClearReserved (rho : Renaming) (w : Nat) : Nat :=
  renameModuleWord rho w % two240

theorem mutant_clear_reserved_killed :
    decodeModule (mutantClearReserved rho moduleWord) ≠
      renameModuleConfig rho (decodeModule moduleWord) := by decide

/-- Mutant 5: the module layout (address at bit 0) applied to the operator
word, clobbering the `active` byte. -/
def mutantClobberActive (rho : Renaming) (w : Nat) : Nat :=
  (w / two160) * two160 + (rho (rewardAddressOf w)).val

theorem mutant_clobber_active_killed :
    decodeOperator (mutantClobberActive rho operatorWord) ≠
      renameOperatorSlot rho (decodeOperator operatorWord) := by decide

/-- The real definitions pass the same checks the mutants fail. -/
example : decodeModule (renameModuleWord rho moduleWord) =
    renameModuleConfig rho (decodeModule moduleWord) := decodeModule_renameModuleWord rho _

example : decodeOperator (renameOperatorWord rho operatorWord) =
    renameOperatorSlot rho (decodeOperator operatorWord) :=
  decodeOperator_renameOperatorWord rho _

end AccountAddress.Tests.Verity.PAddress1PhysicalTest
