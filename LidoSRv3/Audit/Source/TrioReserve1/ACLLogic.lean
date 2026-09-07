import LidoSRv3.Audit.Source.TrioReserve1.ACL
import LidoSRv3.Audit.Source.TrioReserve1.ACLLogicSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLLogic
open Live

def follow (child : Nat → ACL.Result Bool) : ACLLogicSpec.Route → ACL.Result Bool
  | .finish value => ⟨.ok value, []⟩
  | .visit index negate => ACL.bindResult (child index) fun value =>
      ⟨.ok (if negate then !value else value), []⟩

/-- Independent control rules determine the exact remaining source child and
trace. Unselected children have no evaluation premise and contribute no calls. -/
theorem corresponds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (first : Bool) (trace : List NestedAttempt) (route : ACLLogicSpec.Route)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (hl : (ACL.param k self hash index w).id = 204)
    (hv : (ACL.param k self hash index w).op ≤ 12)
    (hf : ACL.eval k external self hash who where_ role how w fuel
      ((ACL.param k self hash index w).value % 2^32) = ⟨.ok first, trace⟩)
    (hs : ACLLogicSpec.Describes (ACL.param k self hash index w).op
      ((ACL.param k self hash index w).value / 2^32 % 2^32)
      ((ACL.param k self hash index w).value / 2^64 % 2^32) first route) :
    let rest := follow (ACL.eval k external self hash who where_ role how w fuel) route
    ACL.eval k external self hash who where_ role how w (fuel+1) index =
      ⟨rest.outcome, trace ++ rest.attempts⟩ := by
  rw [ACL.eval]
  cases hs with
  | conditional hc =>
    simp [Nat.not_le.mpr hb, hl, hc, hf, bind, ACL.bindResult, pure, follow]
  | negate hn =>
    simp [Nat.not_le.mpr hb, hl, hn, hf, bind, ACL.bindResult, pure, follow]
  | or_short ho hfirst =>
    subst first
    simp [Nat.not_le.mpr hb, hl, ho, hf, bind, ACL.bindResult, pure, follow]
  | and_short ha hfirst =>
    subst first
    simp [Nat.not_le.mpr hb, hl, ha, hf, bind, ACL.bindResult, pure, follow]
  | binary hc hn hor hand =>
    cases first <;> simp_all [Nat.not_le.mpr hb, Nat.not_lt.mpr hv,
      bind, ACL.bindResult, pure, follow]

theorem out_of_bounds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (h : (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ≤ index) :
    ACL.eval k external self hash who where_ role how w (fuel+1) index = ⟨.ok false, []⟩ := by
  rw [ACL.eval]
  simp [h, pure]

/-- Invalid logic operators fail before any child or oracle is evaluated. -/
theorem invalid_before_children (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (hl : (ACL.param k self hash index w).id = 204)
    (hi : 12 < (ACL.param k self hash index w).op) :
    ACL.eval k external self hash who where_ role how w (fuel+1) index = ⟨.error .invalidOpcode, []⟩ := by
  rw [ACL.eval]
  simp [Nat.not_le.mpr hb, hl, hi, bind, ACL.bindResult, pure]

/-- First-child failure stops the logic node with its existing trace. Host
exhaustion remains distinguishable from the source invalid-opcode alternative. -/
theorem first_failure (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (fault : ACL.Halt) (trace : List NestedAttempt)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (hl : (ACL.param k self hash index w).id = 204)
    (hv : (ACL.param k self hash index w).op ≤ 12)
    (hf : ACL.eval k external self hash who where_ role how w fuel
      ((ACL.param k self hash index w).value % 2^32) = ⟨.error fault, trace⟩) :
    ACL.eval k external self hash who where_ role how w (fuel+1) index = ⟨.error fault, trace⟩ := by
  rw [ACL.eval]
  simp [Nat.not_le.mpr hb, hl, Nat.not_lt.mpr hv, hf, bind, ACL.bindResult, pure]

end LidoSRv3.Audit.Source.TrioReserve1.ACLLogic
