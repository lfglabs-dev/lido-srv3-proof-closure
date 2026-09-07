import LidoSRv3.Audit.Source.TrioReserve1.ACL

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLCalls
open Live

def external (k : Queue.Keccak) (staticExternal : StaticCall.External) (kernel acl : Address)
    (ctx : Context) (role : Word) (fuel : Nat) (other : External) : External :=
  Kernel.dispatch k kernel ctx role
    (ACL.dispatch k staticExternal acl ctx role fuel other other) other

/-- A terminating physical ACL evaluation, including oracle attempts, supplies
the actual nested source execution. No Kernel/ACL reply bytes are assumed. -/
theorem canPerform (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (role : Word) (w : World) (fuel : Nat) (allowed : Bool)
    (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (he : ACL.hasPermission k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx role [] w fuel = ⟨.ok allowed, trace⟩) :
    (Aragon.canPerform (external k staticExternal (Aragon.kernel ctx w)
      (Kernel.acl k (Aragon.kernel ctx w) w) ctx role fuel other) ctx role w).outcome = .ok allowed := by
  have hz : (word 0).val = 0 := rfl
  have h1 : (word 1).val = 1 := rfl
  have hr : ACL.dispatch k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w) ctx role fuel other other
      ⟨Aragon.kernel ctx w, Kernel.acl k (Aragon.kernel ctx w) w, word 0, Aragon.permissionPayload ctx role⟩ w =
        .successWithTrace (encode 32 (if allowed then 1 else 0)) w trace := by
    simp [ACL.dispatch, hz, he]
  cases allowed
  · have result := Kernel.aragon_from_acl_traced k _ other ctx role (word 0) w w [] trace
      hi hk hkc ha hac (by simpa [hz] using hr)
    simpa [external, hz] using congrArg Live.Result.outcome result
  · have result := Kernel.aragon_from_acl_traced k _ other ctx role (word 1) w w [] trace
      hi hk hkc ha hac (by simpa [h1] using hr)
    simpa [external, h1] using congrArg Live.Result.outcome result

/-- Physical unconditional permission derives admission through the full
Lido→Kernel→ACL path, independently of parameter/oracle interpretation or fuel. -/
theorem unconditional_specific (k : Queue.Keccak) (staticExternal : StaticCall.External)
    (other : External) (ctx : Context) (role : Word) (w : World) (fuel : Nat)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : (w.core.readContractSlot (Kernel.acl k (Aragon.kernel ctx w) w).val
      (ACL.permissionSlot k ctx.sender ctx.self role)).val = ACL.emptyParams) :
    (Aragon.canPerform (external k staticExternal (Aragon.kernel ctx w)
      (Kernel.acl k (Aragon.kernel ctx w) w) ctx role fuel other) ctx role w).outcome = .ok true :=
  canPerform k staticExternal other ctx role w fuel true [] hi hk hkc ha hac
    (ACL.unconditional_specific k staticExternal _ ctx role [] w fuel hs)

end LidoSRv3.Audit.Source.TrioReserve1.ACLCalls
