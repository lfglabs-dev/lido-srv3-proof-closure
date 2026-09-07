import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalBalance
import LidoSRv3.Audit.Source.TrioReserve1.ACLCalls

namespace LidoSRv3.Audit.Source.TrioReserve1.AuthorizationBalance
open Live CalleeBalance WithdrawalBalance

/-- Completed ACL evaluation has no balance effects, including oracle attempts.
Exhaustion and unhandled requests remain explicitly delegated. -/
theorem acl (k : Queue.Keccak) (staticExternal : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (fuel : Nat) (onExhausted other : External)
    (hx : Preserves onExhausted) (ho : Preserves other) :
    Preserves (ACL.dispatch k staticExternal self ctx role fuel onExhausted other) := by
  intro req before
  unfold ACL.dispatch
  split
  · split
    · trivial
    · dsimp only
      split
      · exact hx req before
      · trivial
      · rfl
  · exact ho req before

theorem decoded (req : Request) (data : Bytes) (before after : World)
    (children : List NestedAttempt) (hb : after.balances = before.balances) :
    ReplyPreserves before (Kernel.decodedReply req data after children) := by
  unfold Kernel.decodedReply
  split
  · trivial
  · exact hb

theorem kernel_permission (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role : Word) (before : World) (he : Preserves external) :
    ReplyPreserves before (Kernel.hasPermission k external self ctx role before) := by
  unfold Kernel.hasPermission
  dsimp only
  split
  · rfl
  · split
    · trivial
    · have hp := he ⟨self, Kernel.acl k self before, word 0, Aragon.permissionPayload ctx role⟩ before
      split <;> simp_all only [ReplyPreserves]
      all_goals exact decoded _ _ _ _ _ hp

theorem kernel (k : Queue.Keccak) (self : Address) (ctx : Context) (role : Word)
    (aclExternal other : External) (ha : Preserves aclExternal) (ho : Preserves other) :
    Preserves (Kernel.dispatch k self ctx role aclExternal other) := by
  intro req before
  unfold Kernel.dispatch
  split
  · split
    · trivial
    · exact kernel_permission k aclExternal self ctx role before ha
  · exact ho req before

theorem external (k : Queue.Keccak) (staticExternal : StaticCall.External)
    (kernelAddress aclAddress : Address) (ctx : Context) (role : Word) (fuel : Nat)
    (other : External) (ho : Preserves other) :
    Preserves (ACLCalls.external k staticExternal kernelAddress aclAddress ctx role fuel other) :=
  kernel k kernelAddress ctx role _ other
    (acl k staticExternal aclAddress ctx role fuel other other ho ho) ho

/-- The argument-complete zero-value permission CALL preserves balances on every
outcome under the callee property; rejection restores its incoming world. -/
theorem permission_call {external : External} (he : Preserves external)
    (ctx : Context) (target : Address) (role : Word) :
    Conserves (Aragon.permissionCall external ctx target role) := by
  apply unchanged
  intro before
  unfold Aragon.permissionCall
  dsimp only
  split
  · rfl
  · have hp := he ⟨ctx.self, target, word 0, Aragon.permissionPayload ctx role⟩ before
    split <;> simp_all only [ReplyPreserves]

theorem can_perform {external : External} (he : Preserves external)
    (ctx : Context) (role : Word) : Conserves (Aragon.canPerform external ctx role) := by
  intro before accounts limit hb
  unfold Aragon.canPerform
  split
  · exact ⟨accounts, hb, rfl⟩
  · split
    · exact ⟨accounts, hb, rfl⟩
    · have hp : Conserves (do
          let data ← Aragon.permissionCall external ctx (Aragon.kernel ctx before) role
          let value ← decodeWord data
          pure (decide (value.val ≠ 0))) := by
        unfold decodeWord
        repeat' first
          | apply bind_preserves
          | solve | apply permission_call he
          | solve | apply require_preserves
          | solve | apply pure_preserves
          | intro x
      exact hp before accounts limit hb

/-- Every external target-setter outcome conserves total balances and the incoming
aggregate bound. Authorization denial/fault and decoder failure need no success
premise; root rollback and all allowed physical writes are included. -/
theorem set_target {external : External} (he : Preserves external)
    (ctx : Context) (requested : Word) : Conserves (run (Aragon.setTarget external ctx requested)) := by
  apply root_preserves
  unfold Aragon.setTarget
  repeat' first
    | solve | apply can_perform he
    | solve | apply require_preserves
    | solve | apply WithdrawalBalance.target
    | apply bind_preserves
    | intro x

theorem concrete_target (k : Queue.Keccak) (staticExternal : StaticCall.External)
    (kernelAddress aclAddress : Address) (ctx : Context) (fuel : Nat)
    (other : External) (ho : Preserves other) (requested : Word) :
    Conserves (run (Aragon.setTarget
      (ACLCalls.external k staticExternal kernelAddress aclAddress ctx Aragon.bufferReserveManagerRole fuel other)
      ctx requested)) :=
  set_target (external k staticExternal kernelAddress aclAddress ctx Aragon.bufferReserveManagerRole fuel other ho)
    ctx requested

end LidoSRv3.Audit.Source.TrioReserve1.AuthorizationBalance
