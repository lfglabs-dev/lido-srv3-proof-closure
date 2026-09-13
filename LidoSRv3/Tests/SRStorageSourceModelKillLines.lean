import LidoSRv3.Audit.Source.SRStorageSourceModel

/-! # Kill-lines for `SRStorageSourceModel`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned SR-context source-model semantics.**

`SRStorageSourceModel.SRTopupCallerContext` groups three pinned SR
storage reads (`callerIsGatewayFromRead`, `moduleExistsFromRead`,
`wcTypeIsType2FromRead`) with `deriving DecidableEq, Repr`.  The three
`@[reducible, simp] def` accessors `isTopUpGatewayCall`,
`moduleExists`, `wcIsType2` unfold the context to its underlying
boolean fields.

These kill-lines pin each accessor and demonstrate that the def-chain
distinguishes the three fields. -/

namespace LidoSRv3.Tests.SRStorageSourceModelKillLines

open LidoSRv3.Audit.Source.SRStorageSourceModel

/-- **Kill-line: isTopUpGatewayCall reduces to callerIsGatewayFromRead.** -/
theorem isTopUpGatewayCall_projection
    (ctx : SRTopupCallerContext) :
    isTopUpGatewayCall ctx = ctx.callerIsGatewayFromRead := rfl

/-- **Kill-line: moduleExists reduces to moduleExistsFromRead.** -/
theorem moduleExists_projection
    (ctx : SRTopupCallerContext) :
    moduleExists ctx = ctx.moduleExistsFromRead := rfl

/-- **Kill-line: wcIsType2 reduces to wcTypeIsType2FromRead.** -/
theorem wcIsType2_projection
    (ctx : SRTopupCallerContext) :
    wcIsType2 ctx = ctx.wcTypeIsType2FromRead := rfl

/-- **Kill-line: at witness (all true), all three accessors are true.** -/
theorem all_accessors_true_at_witness :
    isTopUpGatewayCall ⟨true, true, true⟩ = true ∧
    moduleExists ⟨true, true, true⟩ = true ∧
    wcIsType2 ⟨true, true, true⟩ = true := ⟨rfl, rfl, rfl⟩

/-- **Kill-line: the three accessors distinguish their fields.**

At `⟨true, false, false⟩` only `isTopUpGatewayCall` is true. -/
theorem accessors_distinguish_gateway_only :
    isTopUpGatewayCall ⟨true, false, false⟩ = true ∧
    moduleExists ⟨true, false, false⟩ = false ∧
    wcIsType2 ⟨true, false, false⟩ = false := ⟨rfl, rfl, rfl⟩

/-- **Kill-line: at all-false context, all three accessors are false.** -/
theorem all_accessors_false_at_witness :
    isTopUpGatewayCall ⟨false, false, false⟩ = false ∧
    moduleExists ⟨false, false, false⟩ = false ∧
    wcIsType2 ⟨false, false, false⟩ = false := ⟨rfl, rfl, rfl⟩

/-- **Kill-line: moduleExistsFromMapping is decidable on the underlying
read.** -/
theorem moduleExistsFromMapping_at_witness :
    moduleExistsFromMapping
      ({ slotAt := fun n => if n = 5 then 100 else 0 }
        : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage) 5 = true := by
  unfold moduleExistsFromMapping
    LidoSRv3.Audit.Source.KeccakMappingStorageSource.read
  decide

/-- **Kill-line: wcTypeBitOffset is exactly 8 (per pinned SRUtils.sol
packing).** -/
theorem wcTypeBitOffset_pinned :
    wcTypeBitOffset = 8 := rfl

/-- **Kill-line: wcTypeBitWidth is exactly 8.** -/
theorem wcTypeBitWidth_pinned :
    wcTypeBitWidth = 8 := rfl

#print axioms isTopUpGatewayCall_projection
#print axioms moduleExists_projection
#print axioms wcIsType2_projection
#print axioms all_accessors_true_at_witness
#print axioms accessors_distinguish_gateway_only
#print axioms all_accessors_false_at_witness
#print axioms moduleExistsFromMapping_at_witness
#print axioms wcTypeBitOffset_pinned
#print axioms wcTypeBitWidth_pinned

end LidoSRv3.Tests.SRStorageSourceModelKillLines
