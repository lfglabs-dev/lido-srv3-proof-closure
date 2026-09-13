import LidoSRv3.Audit.Verity.TopupRollback

/-!
Kill-lines pinning `Verity.TopupRollback` external-call site shapes
and program-level declarations that anchor the P-TOPUP-1 transaction
plane. These pin the two call-site constructors (`lidoPullSite` and
`topUpSite`) plus the top-level spec and selector declarations.
-/

namespace LidoSRv3.Tests.VerityTopupRollbackCallSitesKillLines

open LidoSRv3.Audit.Verity.TopupRollback
open Compiler.CompilationModel.DenoteExternalCalls

/-! ## Program-level declarations. -/

theorem topup_program_declared_restated :
    spec.functions = [topUpEntry] := rfl

theorem spec_name :
    spec.name = "PTopup1TopupRollback" := rfl

theorem spec_fields_empty :
    spec.fields = [] := rfl

theorem spec_constructor_none :
    spec.«constructor» = none := rfl

/-! ## `lidoPullSite` — the fixed pull-target line 744. -/

theorem lidoPullSite_siteId : lidoPullSite.siteId = 0 := rfl

theorem lidoPullSite_kind : lidoPullSite.kind = CallKind.call := rfl

theorem lidoPullSite_target : lidoPullSite.target = lidoAddress := rfl

theorem lidoPullSite_value : lidoPullSite.value = 0 := rfl

theorem lidoPullSite_calldata_empty : lidoPullSite.calldata = [] := rfl

/-! ## `topUpSite` — the parametric per-key value-bearing beacon call. -/

theorem topUpSite_siteId (index amount : Nat) :
    (topUpSite index amount).siteId = index + 1 := rfl

theorem topUpSite_kind (index amount : Nat) :
    (topUpSite index amount).kind = CallKind.call := rfl

theorem topUpSite_target (index amount : Nat) :
    (topUpSite index amount).target = beaconDepositAddress := rfl

theorem topUpSite_value (index amount : Nat) :
    (topUpSite index amount).value = amount := rfl

theorem topUpSite_calldata_empty (index amount : Nat) :
    (topUpSite index amount).calldata = [] := rfl

/-! ## Distinct site-ids: pull vs any top-up call. -/

theorem pull_and_topup_siteIds_distinct (index amount : Nat) :
    lidoPullSite.siteId ≠ (topUpSite index amount).siteId := by
  simp [lidoPullSite, topUpSite]

/-! ## `topUpSelector` pin. -/

theorem topUpSelector_val : topUpSelector = 0x0f6b3d8b := rfl

/-! ## Address literals used by the two sites. -/

theorem lidoAddress_val : lidoAddress = 1 := rfl

theorem beaconDepositAddress_val :
    beaconDepositAddress = 0x00000000219ab540356cBB839Cbe05303d7705Fa := rfl

end LidoSRv3.Tests.VerityTopupRollbackCallSitesKillLines
