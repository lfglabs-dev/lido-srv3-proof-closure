import LidoSRv3.Audit.Source.TrioReserve1.ACLLeafSpec
import LidoSRv3.Audit.Source.TrioReserve1.ACLTree

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLLeaf
open Live

/-- Proof-side normal form for the atomic operator after input acquisition. -/
def finish (op compared : Nat) : Option Nat → ACL.Result Bool
  | none => ⟨.ok false, []⟩
  | some value => if op > 12 then ⟨.error .invalidOpcode, []⟩
      else ⟨.ok (if op = 7 then decide (0 < value) else ACL.compare op value compared), []⟩

theorem finish_of_spec (op compared : Nat) (input : Option Nat) (outcome : ACLTreeSpec.Outcome)
    (h : ACLLeafSpec.Evaluates op compared input outcome) :
    finish op compared input = ACLTree.result outcome [] := by
  cases h with
  | missing => rfl
  | invalid value hv => simp [finish, hv, ACLTree.result]
  | ret value hr => simp [finish, hr, ACLTree.result]
  | comparison value answer hv hr hc =>
    have he : ACL.compare op value compared = answer := by
      have hs := ACL.compare_corresponds op value compared
      unfold ACLSpec.Comparison at hs hc
      have he := hs.trans hc.symm
      clear hs hc
      cases answer <;> cases hh : ACL.compare op value compared <;> simp_all
    simp [finish, show ¬op > 12 by omega, hr, he, ACLTree.result]

theorem finish_exists (op compared : Nat) (input : Option Nat) :
    ∃ outcome, ACLLeafSpec.Evaluates op compared input outcome := by
  cases input with
  | none => exact ⟨_, .missing⟩
  | some value =>
    by_cases hv : 12 < op
    · exact ⟨_, .invalid value hv⟩
    · by_cases hr : op = 7
      · exact ⟨_, .ret value hr⟩
      · exact ⟨_, .comparison value _ (by omega) hr (ACL.compare_corresponds op value compared)⟩

theorem finish_corresponds (op compared : Nat) (input : Option Nat) (outcome : ACLTreeSpec.Outcome) :
    ACLLeafSpec.Evaluates op compared input outcome ↔ finish op compared input = ACLTree.result outcome [] := by
  constructor
  · exact finish_of_spec op compared input outcome
  · intro h
    obtain ⟨other, hs⟩ := finish_exists op compared input
    have he := ACLTree.result_injective other outcome [] [] ((finish_of_spec op compared input other hs).symm.trans h)
    exact he.1 ▸ hs

/-- Every physically present non-logic, non-oracle leaf reads its actual block,
timestamp, constant or uint240 argument. No recursive or external-result premise
is needed, and an absent argument precedes enum failure. -/
theorem input_source (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (input : Option Nat)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (hl : (ACL.param k self hash index w).id ≠ 204)
    (ho : (ACL.param k self hash index w).id ≠ 203)
    (hi : ACLLeafSpec.Input (ACL.param k self hash index w).id (ACL.param k self hash index w).value
      w.core.blockNumber.val w.core.blockTimestamp.val how.length (fun i => (how[i]!).val) input) :
    ACL.eval k external self hash who where_ role how w (fuel+1) index =
      finish (ACL.param k self hash index w).op (ACL.param k self hash index w).value input := by
  have hnb : ¬(w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ≤ index := by omega
  rw [ACL.eval]
  cases hi <;>
    simp_all [finish, bind, ACL.bindResult, pure, Nat.not_le.mpr]

theorem nonoracle_corresponds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (input : Option Nat) (outcome : ACLTreeSpec.Outcome)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (hl : (ACL.param k self hash index w).id ≠ 204)
    (ho : (ACL.param k self hash index w).id ≠ 203)
    (hi : ACLLeafSpec.Input (ACL.param k self hash index w).id (ACL.param k self hash index w).value
      w.core.blockNumber.val w.core.blockTimestamp.val how.length (fun i => (how[i]!).val) input) :
    ACLLeafSpec.Evaluates (ACL.param k self hash index w).op (ACL.param k self hash index w).value input outcome ↔
      ACL.eval k external self hash who where_ role how w (fuel+1) index = ACLTree.result outcome [] := by
  rw [input_source k external self hash who where_ role how w fuel index input hb hl ho hi]
  exact finish_corresponds _ _ _ _

/-- Adapts primitive bytes to the independent scalar oracle rule. -/
def OracleReply (reply : StaticCall.Reply) (answer : Bool) : Prop :=
  match reply with
  | .success data => ACLLeafSpec.OracleAllows true data.length (word (decode data)).val answer
  | .rejected _ => ACLLeafSpec.OracleAllows false 0 0 answer
  | .forbiddenStateChange => ACLLeafSpec.OracleAllows false 0 0 answer

def oracleTrace (req : Request) : StaticCall.Reply → List NestedAttempt
  | .success data => [⟨req, true, true, data, 1⟩]
  | .rejected data => [⟨req, true, false, data, 1⟩]
  | .forbiddenStateChange => [⟨req, true, false, [], 1⟩]

theorem oracle_reply_source (external : StaticCall.External) (self target who where_ : Address)
    (role : Word) (how : List Word) (w : World) (reply : StaticCall.Reply) (answer : Bool)
    (hp : external ⟨self, target, word 0, ACL.oraclePayload who where_ role how⟩ w = reply)
    (hs : OracleReply reply answer) :
    ACL.oracle external self target who where_ role how w =
      ⟨.ok answer, oracleTrace ⟨self, target, word 0, ACL.oraclePayload who where_ role how⟩ reply⟩ := by
  cases reply <;> cases answer <;>
    simp_all [ACL.oracle, OracleReply, ACLLeafSpec.OracleAllows, oracleTrace]

/-- Oracle acquisition precedes enum conversion, so even invalid operators retain
the raw static-call attempt. The only external premise is the primitive reply. -/
theorem oracle_corresponds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) (reply : StaticCall.Reply) (answer : Bool) (outcome : ACLTreeSpec.Outcome)
    (hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val)
    (ho : (ACL.param k self hash index w).id = 203)
    (hp : external ⟨self, Verity.Core.Address.ofNat (ACL.param k self hash index w).value,
      word 0, ACL.oraclePayload who where_ role how⟩ w = reply)
    (hs : OracleReply reply answer) :
    ACLLeafSpec.Evaluates (ACL.param k self hash index w).op 1 (some (if answer then 1 else 0)) outcome ↔
      ACL.eval k external self hash who where_ role how w (fuel+1) index =
        ACLTree.result outcome (oracleTrace ⟨self, Verity.Core.Address.ofNat (ACL.param k self hash index w).value,
          word 0, ACL.oraclePayload who where_ role how⟩ reply) := by
  have hcall := oracle_reply_source external self _ who where_ role how w reply answer hp hs
  have hnb : ¬(w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ≤ index := by omega
  rw [finish_corresponds, ACL.eval]
  cases outcome <;> cases answer <;>
    by_cases hv : 12 < (ACL.param k self hash index w).op <;>
    simp_all [finish, ACLTree.result, bind, ACL.bindResult, pure, Nat.not_le.mpr, Nat.not_lt.mpr]

theorem oracle_reply_exists (reply : StaticCall.Reply) : ∃ answer, OracleReply reply answer := by
  cases reply with
  | success data =>
    refine ⟨data.length == 32 && (word (decode data)).val != 0, ?_⟩
    simp [OracleReply, ACLLeafSpec.OracleAllows]
  | rejected data => exact ⟨false, by simp [OracleReply, ACLLeafSpec.OracleAllows]⟩
  | forbiddenStateChange => exact ⟨false, by simp [OracleReply, ACLLeafSpec.OracleAllows]⟩

section
variable (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
  (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)

/-- Physical projection into independent atomic rules. Only oracle leaves consult
the raw static-call interpreter. This relation never calls `ACL.eval`. -/
def Describes (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt) : Prop :=
  let p := ACL.param k self hash index w
  if p.id = 203 then
    let req : Request := ⟨self, Verity.Core.Address.ofNat p.value, word 0, ACL.oraclePayload who where_ role how⟩
    ∃ answer, OracleReply (external req w) answer ∧
      ACLLeafSpec.Evaluates p.op 1 (some (if answer then 1 else 0)) outcome ∧
      trace = oracleTrace req (external req w)
  else ∃ input, ACLLeafSpec.Input p.id p.value w.core.blockNumber.val w.core.blockTimestamp.val
      how.length (fun i => (how[i]!).val) input ∧ ACLLeafSpec.Evaluates p.op p.value input outcome ∧ trace = []

theorem atom_view (index : Nat) (hn : ACLTree.node k self hash w index = .atom) :
    index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ∧
      (ACL.param k self hash index w).id ≠ 204 := by
  unfold ACLTree.node at hn
  split at hn
  · contradiction
  · rename_i hb
    dsimp only at hn
    split at hn
    · split at hn <;> contradiction
    · exact ⟨by omega, by assumption⟩

theorem describes_source (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hn : ACLTree.node k self hash w index = .atom)
    (hs : Describes k external self hash who where_ role how w index outcome trace) :
    ACL.eval k external self hash who where_ role how w 1 index = ACLTree.result outcome trace := by
  obtain ⟨hb, hl⟩ := atom_view k self hash w index hn
  unfold Describes at hs
  dsimp only at hs
  split at hs
  · rename_i ho
    obtain ⟨answer, hr, he, ht⟩ := hs
    subst trace
    exact (oracle_corresponds k external self hash who where_ role how w 0 index _ answer outcome hb ho rfl hr).mp he
  · rename_i ho
    obtain ⟨input, hi, he, ht⟩ := hs
    subst trace
    exact (nonoracle_corresponds k external self hash who where_ role how w 0 index input outcome hb hl ho hi).mp he

theorem describes_exists (index : Nat) :
    ∃ outcome trace, Describes k external self hash who where_ role how w index outcome trace := by
  unfold Describes
  dsimp only
  by_cases ho : (ACL.param k self hash index w).id = 203
  · simp only [ho, ite_true]
    obtain ⟨answer, hr⟩ := oracle_reply_exists (external
      ⟨self, Verity.Core.Address.ofNat (ACL.param k self hash index w).value, word 0,
        ACL.oraclePayload who where_ role how⟩ w)
    obtain ⟨outcome, he⟩ := finish_exists (ACL.param k self hash index w).op 1 (some (if answer then 1 else 0))
    exact ⟨outcome, _, answer, hr, he, rfl⟩
  · simp only [ho, ite_false]
    obtain ⟨input, hi⟩ := ACLLeafSpec.input_exists (ACL.param k self hash index w).id
      (ACL.param k self hash index w).value w.core.blockNumber.val w.core.blockTimestamp.val
      how.length (fun i => (how[i]!).val)
    obtain ⟨outcome, he⟩ := finish_exists (ACL.param k self hash index w).op (ACL.param k self hash index w).value input
    exact ⟨outcome, [], input, hi, he, rfl⟩

theorem describes_complete (fuel index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hn : ACLTree.node k self hash w index = .atom)
    (hs : ACL.eval k external self hash who where_ role how w fuel index = ACLTree.result outcome trace) :
    Describes k external self hash who where_ role how w index outcome trace := by
  obtain ⟨other, otherTrace, hd⟩ := describes_exists k external self hash who where_ role how w index
  have he := describes_source k external self hash who where_ role how w index other otherTrace hn hd
  have h1 : (ACL.eval k external self hash who where_ role how w 1 index).outcome ≠ .error .exhausted := by
    rw [he]; cases other <;> simp [ACLTree.result]
  have h2 : (ACL.eval k external self hash who where_ role how w fuel index).outcome ≠ .error .exhausted := by
    rw [hs]; cases outcome <;> simp [ACLTree.result]
  have hu := ACLBounds.eval_unique k external self hash who where_ role how w 1 fuel index h1 h2
  have hi := ACLTree.result_injective other outcome otherTrace trace (he.symm.trans (hu.trans hs))
  rcases hi with ⟨rfl, rfl⟩
  exact hd

/-- Recursive correspondence with all atomic premises discharged by the scalar
leaf rules and explicit primitive reply interpretation. This does not identify
the primitive with deployed bytecode or convert host depth into EVM gas. -/
theorem tree_corresponds (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt) :
    ACLTreeSpec.Evaluates (ACLTree.node k self hash w)
      (Describes k external self hash who where_ role how w) index outcome trace ↔
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = ACLTree.result outcome trace := by
  apply ACLTree.corresponds
  · intro i o t hn hs
    exact ⟨1, describes_source k external self hash who where_ role how w i o t hn hs⟩
  · exact describes_complete k external self hash who where_ role how w

end

end LidoSRv3.Audit.Source.TrioReserve1.ACLLeaf
