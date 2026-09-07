import LidoSRv3.Audit.Source.TrioReserve1.ACLTreeSpec
import LidoSRv3.Audit.Source.TrioReserve1.ACLLogic
import LidoSRv3.Audit.Source.TrioReserve1.ACLBounds

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLTree
open Live

def node (k : Queue.Keccak) (self : Address) (hash : Word) (w : World) (index : Nat) : ACLTreeSpec.Node :=
  if index ≥ (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val then .missing
  else
    let p := ACL.param k self hash index w
    if p.id = 204 then
      if p.op > 12 then .invalid
      else .logic p.op (p.value % 2^32) (p.value / 2^32 % 2^32) (p.value / 2^64 % 2^32)
    else .atom

def result (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt) : ACL.Result Bool :=
  ⟨match outcome with | .value b => .ok b | .invalidOpcode => .error .invalidOpcode, trace⟩

theorem lift (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel extra index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (h : ACL.eval k external self hash who where_ role how w fuel index = result outcome trace) :
    ACL.eval k external self hash who where_ role how w (fuel+extra) index = result outcome trace := by
  have hn : (ACL.eval k external self hash who where_ role how w fuel index).outcome ≠ .error .exhausted := by
    rw [h]
    cases outcome <;> simp [result]
  exact (ACLBounds.eval_mono k external self hash who where_ role how w fuel extra index hn).trans h

theorem logic_view (k : Queue.Keccak) (self : Address) (hash : Word) (w : World)
    (index op a b c : Nat) (h : node k self hash w index = .logic op a b c) :
    index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ∧
    (ACL.param k self hash index w).id = 204 ∧ (ACL.param k self hash index w).op ≤ 12 ∧
    (ACL.param k self hash index w).op = op ∧
    (ACL.param k self hash index w).value % 2^32 = a ∧
    (ACL.param k self hash index w).value / 2^32 % 2^32 = b ∧
    (ACL.param k self hash index w).value / 2^64 % 2^32 = c := by
  unfold node at h
  split at h
  · contradiction
  · rename_i hb
    dsimp only at h
    split at h
    · rename_i hl
      split at h
      · contradiction
      · rename_i hv
        simp only [ACLTreeSpec.Node.logic.injEq] at h
        exact ⟨by omega, hl, by omega, h⟩
    · contradiction

/-- Every finite independent tree derivation has a matching completed source
evaluation, including its oracle trace. Leaf correspondence is the sole open
semantic interface here; no acyclicity or fixed global depth is assumed. -/
theorem of_spec (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (leaf_source : ∀ index outcome trace, node k self hash w index = .atom → leaf index outcome trace →
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace)
    (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (h : ACLTreeSpec.Evaluates (node k self hash w) leaf index outcome trace) :
    ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace := by
  induction h with
  | atom hn hl => exact leaf_source _ _ _ hn hl
  | @missing i hn =>
    refine ⟨1, ?_⟩
    have hb : (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ≤ i := by
      unfold node at hn
      split at hn
      · assumption
      · dsimp only at hn
        split at hn
        · split at hn <;> contradiction
        · contradiction
    exact ACLLogic.out_of_bounds k external self hash who where_ role how w 0 _ hb
  | invalid hn =>
    refine ⟨1, ?_⟩
    unfold node at hn
    split at hn
    · contradiction
    · rename_i hb
      dsimp only at hn
      split at hn
      · rename_i hl
        split at hn
        · rename_i hv
          exact ACLLogic.invalid_before_children k external self hash who where_ role how w 0 _ (by omega) hl hv
        · contradiction
      · contradiction
  | first_failure hn ha ih =>
    obtain ⟨fuel, hf⟩ := ih
    obtain ⟨bound, logic, valid, hop, hfirst, hsecond, hthird⟩ := logic_view k self hash w _ _ _ _ _ hn
    refine ⟨fuel+1, ?_⟩
    exact ACLLogic.first_failure k external self hash who where_ role how w fuel _ .invalidOpcode _
      bound logic valid (by simpa only [hfirst, result] using hf)
  | finish hn ha hr ih =>
    obtain ⟨fuel, hf⟩ := ih
    obtain ⟨bound, logic, valid, hop, hfirst, hsecond, hthird⟩ := logic_view k self hash w _ _ _ _ _ hn
    refine ⟨fuel+1, ?_⟩
    have e := ACLLogic.corresponds k external self hash who where_ role how w fuel _ _ _ (.finish _)
      bound logic valid (by simpa only [hfirst, result] using hf)
      (by simpa only [hop, hsecond, hthird] using hr)
    simpa only [ACLLogic.follow, List.append_nil, result] using e
  | visit hn ha hr hb iha ihb =>
    obtain ⟨f, hf⟩ := iha
    obtain ⟨g, hg⟩ := ihb
    have hf' := lift k external self hash who where_ role how w f g _ _ _ hf
    have hg' := lift k external self hash who where_ role how w g f _ _ _ hg
    rw [Nat.add_comm g f] at hg'
    obtain ⟨bound, logic, valid, hop, hfirst, hsecond, hthird⟩ := logic_view k self hash w _ _ _ _ _ hn
    refine ⟨f+g+1, ?_⟩
    have e := ACLLogic.corresponds k external self hash who where_ role how w (f+g) _ _ _ (.visit _ _)
      bound logic valid (by simpa only [hfirst, result] using hf')
      (by simpa only [hop, hsecond, hthird] using hr)
    simpa [ACLLogic.follow, hg', ACL.bindResult, result] using e
  | visit_failure hn ha hr hb iha ihb =>
    obtain ⟨f, hf⟩ := iha
    obtain ⟨g, hg⟩ := ihb
    have hf' := lift k external self hash who where_ role how w f g _ _ _ hf
    have hg' := lift k external self hash who where_ role how w g f _ _ _ hg
    rw [Nat.add_comm g f] at hg'
    obtain ⟨bound, logic, valid, hop, hfirst, hsecond, hthird⟩ := logic_view k self hash w _ _ _ _ _ hn
    refine ⟨f+g+1, ?_⟩
    have e := ACLLogic.corresponds k external self hash who where_ role how w (f+g) _ _ _ (.visit _ _)
      bound logic valid (by simpa only [hfirst, result] using hf')
      (by simpa only [hop, hsecond, hthird] using hr)
    simpa [ACLLogic.follow, hg', ACL.bindResult, result] using e

/-- A finite derivation supplies a stable sufficient depth, rather than an
assumed global cutoff or an acyclicity restriction on all stored parameters. -/
theorem of_spec_stable (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (leaf_source : ∀ index outcome trace, node k self hash w index = .atom → leaf index outcome trace →
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace)
    (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (h : ACLTreeSpec.Evaluates (node k self hash w) leaf index outcome trace) :
    ∃ fuel, ∀ extra, ACL.eval k external self hash who where_ role how w (fuel+extra) index =
      result outcome trace := by
  obtain ⟨fuel, hf⟩ := of_spec k external self hash who where_ role how w leaf leaf_source index outcome trace h
  exact ⟨fuel, fun extra => lift k external self hash who where_ role how w fuel extra index outcome trace hf⟩

/-- Related finite derivations cannot disagree on their result or trace.
This theorem uses the stated leaf-source interface; it does not discharge it. -/
theorem derivations_agree (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (leaf_source : ∀ index outcome trace, node k self hash w index = .atom → leaf index outcome trace →
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace)
    (index : Nat) (a b : ACLTreeSpec.Outcome) (ta tb : List NestedAttempt)
    (ha : ACLTreeSpec.Evaluates (node k self hash w) leaf index a ta)
    (hb : ACLTreeSpec.Evaluates (node k self hash w) leaf index b tb) : a = b ∧ ta = tb := by
  obtain ⟨fa, hfa⟩ := of_spec k external self hash who where_ role how w leaf leaf_source index a ta ha
  obtain ⟨fb, hfb⟩ := of_spec k external self hash who where_ role how w leaf leaf_source index b tb hb
  have hna : (ACL.eval k external self hash who where_ role how w fa index).outcome ≠ .error .exhausted := by
    rw [hfa]; cases a <;> simp [result]
  have hnb : (ACL.eval k external self hash who where_ role how w fb index).outcome ≠ .error .exhausted := by
    rw [hfb]; cases b <;> simp [result]
  have he := ACLBounds.eval_unique k external self hash who where_ role how w fa fb index hna hnb
  rw [hfa, hfb] at he
  cases a <;> cases b <;> simp_all [result, ACL.Result.mk.injEq]

theorem result_injective (a b : ACLTreeSpec.Outcome) (ta tb : List NestedAttempt)
    (h : result a ta = result b tb) : a = b ∧ ta = tb := by
  cases a <;> cases b <;> simp_all [result, ACL.Result.mk.injEq]

theorem transport (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (nodes : Nat → ACLTreeSpec.Node) (index : Nat) (a b : ACLTreeSpec.Outcome)
    (ta tb : List NestedAttempt) (h : result a ta = result b tb)
    (ha : ACLTreeSpec.Evaluates nodes leaf index a ta) : ACLTreeSpec.Evaluates nodes leaf index b tb := by
  obtain ⟨rfl, rfl⟩ := result_injective a b ta tb h
  exact ha

/-- Completed source evaluation has a finite independent derivation whenever
the leaf relation covers completed atomic evaluations. Host exhaustion has no
specification outcome and cannot discharge this theorem's source premise. -/
theorem to_spec (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (leaf_complete : ∀ fuel index outcome trace, node k self hash w index = .atom →
      ACL.eval k external self hash who where_ role how w fuel index = result outcome trace →
      leaf index outcome trace)
    (fuel index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (h : ACL.eval k external self hash who where_ role how w fuel index = result outcome trace) :
    ACLTreeSpec.Evaluates (node k self hash w) leaf index outcome trace := by
  induction fuel generalizing index outcome trace with
  | zero => cases outcome <;> simp [ACL.eval, result] at h
  | succ fuel ih =>
    by_cases hb : index < (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val
    · by_cases hl : (ACL.param k self hash index w).id = 204
      · by_cases hv : (ACL.param k self hash index w).op ≤ 12
        · have hn : node k self hash w index = .logic (ACL.param k self hash index w).op
              ((ACL.param k self hash index w).value % 2^32)
              ((ACL.param k self hash index w).value / 2^32 % 2^32)
              ((ACL.param k self hash index w).value / 2^64 % 2^32) := by
            simp [node, Nat.not_le.mpr hb, hl, Nat.not_lt.mpr hv]
          cases he : ACL.eval k external self hash who where_ role how w fuel
              ((ACL.param k self hash index w).value % 2^32) with
          | mk firstResult firstTrace =>
            cases firstResult with
            | error fault =>
              have e := ACLLogic.first_failure k external self hash who where_ role how w fuel index fault firstTrace hb hl hv he
              rw [e] at h
              cases fault with
              | exhausted => cases outcome <;> simp [result] at h
              | invalidOpcode =>
                exact transport leaf _ index .invalidOpcode outcome firstTrace trace h
                  (.first_failure hn (ih _ _ _ he))
            | ok first =>
              have ha := ih _ (.value first) firstTrace he
              obtain ⟨route, hr⟩ := ACLLogicSpec.exists_route (ACL.param k self hash index w).op
                ((ACL.param k self hash index w).value / 2^32 % 2^32)
                ((ACL.param k self hash index w).value / 2^64 % 2^32) first
              have e := ACLLogic.corresponds k external self hash who where_ role how w fuel index first firstTrace route hb hl hv he hr
              rw [e] at h
              cases route with
              | finish value =>
                apply transport leaf _ index (.value value) outcome firstTrace trace
                  (by simpa [ACLLogic.follow, result] using h)
                exact .finish hn ha hr
              | visit next negate =>
                cases hc : ACL.eval k external self hash who where_ role how w fuel next with
                | mk secondResult secondTrace =>
                  cases secondResult with
                  | error fault =>
                    cases fault with
                    | exhausted => cases outcome <;> simp [ACLLogic.follow, hc, ACL.bindResult, result] at h
                    | invalidOpcode =>
                      apply transport leaf _ index .invalidOpcode outcome (firstTrace ++ secondTrace) trace
                        (by simpa [ACLLogic.follow, hc, ACL.bindResult, result] using h)
                      exact .visit_failure hn ha hr (ih _ _ _ hc)
                  | ok second =>
                    apply transport leaf _ index (.value (if negate then !second else second)) outcome
                      (firstTrace ++ secondTrace) trace
                      (by simpa [ACLLogic.follow, hc, ACL.bindResult, result] using h)
                    exact .visit hn ha hr (ih _ _ _ hc)
        · have hi : 12 < (ACL.param k self hash index w).op := by omega
          rw [ACLLogic.invalid_before_children k external self hash who where_ role how w fuel index hb hl hi] at h
          apply transport leaf _ index .invalidOpcode outcome [] trace h
          exact .invalid (by simp [node, Nat.not_le.mpr hb, hl, hi])
      · have hn : node k self hash w index = .atom := by simp [node, Nat.not_le.mpr hb, hl]
        exact .atom hn (leaf_complete _ _ _ _ hn h)
    · have hm : (w.core.readContractSlot self.val (ACL.paramsSlot k hash)).val ≤ index := by omega
      rw [ACLLogic.out_of_bounds k external self hash who where_ role how w fuel index hm] at h
      apply transport leaf _ index (.value false) outcome [] trace h
      exact .missing (by simp [node, hm])

/-- Bidirectional recursive correspondence, parameterized by explicitly stated
soundness and completeness obligations for atomic leaf semantics. -/
theorem corresponds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (leaf : Nat → ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (leaf_source : ∀ index outcome trace, node k self hash w index = .atom → leaf index outcome trace →
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace)
    (leaf_complete : ∀ fuel index outcome trace, node k self hash w index = .atom →
      ACL.eval k external self hash who where_ role how w fuel index = result outcome trace →
      leaf index outcome trace)
    (index : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt) :
    ACLTreeSpec.Evaluates (node k self hash w) leaf index outcome trace ↔
      ∃ fuel, ACL.eval k external self hash who where_ role how w fuel index = result outcome trace := by
  constructor
  · exact of_spec k external self hash who where_ role how w leaf leaf_source index outcome trace
  · rintro ⟨fuel, h⟩
    exact to_spec k external self hash who where_ role how w leaf leaf_complete fuel index outcome trace h

end LidoSRv3.Audit.Source.TrioReserve1.ACLTree
