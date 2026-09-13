import LidoSRv3.Audit.Source.SRStorageSourceModel

/-!
Kill-lines pinning `Source.SRStorageSourceModel`
`SRTopupCallerContext` reductions and the four real-derivation
composition theorems (ACL gateway, mapping-existence, packed-byte
wcType).
-/

namespace LidoSRv3.Tests.SourceSRStorageSourceModelKillLines

open LidoSRv3.Audit.Source.SRStorageSourceModel
open LidoSRv3.Audit.Source.AragonACLSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! ## `SRTopupCallerContext` — three-field structure witnesses. -/

private def all_true : SRTopupCallerContext :=
  { callerIsGatewayFromRead := true, moduleExistsFromRead := true
    wcTypeIsType2FromRead := true }

private def all_false : SRTopupCallerContext :=
  { callerIsGatewayFromRead := false, moduleExistsFromRead := false
    wcTypeIsType2FromRead := false }

theorem srCtx_decEq_self : (decide (all_true = all_true)) = true := by decide

theorem srCtx_decEq_neg : (decide (all_true = all_false)) = false := by decide

/-! ## `isTopUpGatewayCall` reduces to callerIsGatewayFromRead. -/

theorem isTopUpGatewayCall_reduces (ctx : SRTopupCallerContext) :
    isTopUpGatewayCall ctx = ctx.callerIsGatewayFromRead := rfl

/-! ## `moduleExists` reduces to moduleExistsFromRead. -/

theorem moduleExists_reduces (ctx : SRTopupCallerContext) :
    moduleExists ctx = ctx.moduleExistsFromRead := rfl

/-! ## `wcIsType2` reduces to wcTypeIsType2FromRead. -/

theorem wcIsType2_reduces (ctx : SRTopupCallerContext) :
    wcIsType2 ctx = ctx.wcTypeIsType2FromRead := rfl

/-! ## Truth-table on `all_true` and `all_false`. -/

theorem isTopUpGatewayCall_all_true :
    isTopUpGatewayCall all_true = true := rfl

theorem moduleExists_all_true :
    moduleExists all_true = true := rfl

theorem wcIsType2_all_true :
    wcIsType2 all_true = true := rfl

theorem isTopUpGatewayCall_all_false :
    isTopUpGatewayCall all_false = false := rfl

/-! ## Combined witness — all three guards pass. -/

theorem all_guards_pass_of_pinned_sr_reads_restated
    {ctx : SRTopupCallerContext}
    (hGateway : ctx.callerIsGatewayFromRead = true)
    (hModule : ctx.moduleExistsFromRead = true)
    (hWc : ctx.wcTypeIsType2FromRead = true) :
    isTopUpGatewayCall ctx = true ∧
      moduleExists ctx = true ∧
      wcIsType2 ctx = true :=
  all_guards_pass_of_pinned_sr_reads hGateway hModule hWc

/-! ## `callerIsGateway_derived_from_acl` — restated. -/

theorem callerIsGateway_derived_from_acl_restated
    {ctx : SRTopupCallerContext}
    {acl : ACLState}
    (hLink : CallerIsGatewayFromACL ctx acl)
    (hApp : acl.hasRole "TOP_UP_GATEWAY_APP" = true) :
    ctx.callerIsGatewayFromRead = true :=
  callerIsGateway_derived_from_acl hLink hApp

/-! ## `moduleExists_true_of_mapping_nonzero` — restated. -/

theorem moduleExists_true_of_mapping_nonzero_restated
    {m : MappingStorage} {moduleId : Nat}
    (hNonzero : m.slotAt moduleId ≠ 0) :
    moduleExistsFromMapping m moduleId = true :=
  moduleExists_true_of_mapping_nonzero hNonzero

/-! ## Pinned bit-offsets for wcType. -/

theorem wcTypeBitOffset_val : wcTypeBitOffset = 8 := rfl

theorem wcTypeBitWidth_val : wcTypeBitWidth = 8 := rfl

end LidoSRv3.Tests.SourceSRStorageSourceModelKillLines
