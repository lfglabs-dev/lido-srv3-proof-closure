import LidoSRv3.Audit.Source.TrioReserve1.ACLPermissionSpec
import LidoSRv3.Audit.Source.TrioReserve1.ACLLeaf
import LidoSRv3.Audit.Source.TrioReserve1.ACLCalls

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLPermission
open Live

/-- Proof-side normal form for ordered permission selection. -/
def select (specific wildcard : ACL.Result Bool) : ACL.Result Bool :=
  match specific.outcome with
  | .error e => ⟨.error e, specific.attempts⟩
  | .ok true => ⟨.ok true, specific.attempts⟩
  | .ok false => ⟨wildcard.outcome, specific.attempts ++ wildcard.attempts⟩

section
variable (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
  (where_ : Address) (role : Word) (how : List Word) (w : World)

def stored (who : Address) : Word := w.core.readContractSlot self.val (ACL.permissionSlot k who where_ role)

def attempt (who : Address) (fuel : Nat) : ACL.Result Bool :=
  let hash := stored k self where_ role w who
  if hash.val = 0 then ⟨.ok false, []⟩ else ACL.evalParams k external self hash who where_ role how w fuel

/-- Projects the actual permission hash and graph into independent attempt rules.
The wildcard caller identity is chosen by `Describes`, not supplied by a reply. -/
def Attempt (who : Address) : ACLTreeSpec.Outcome → List NestedAttempt → Prop :=
  let hash := stored k self where_ role w who
  ACLPermissionSpec.Attempt (hash.val ≠ 0) (hash.val = ACL.emptyParams)
    (ACLTreeSpec.Evaluates (ACLTree.node k self hash w)
      (ACLLeaf.Describes k external self hash who where_ role how w) 0)

theorem attempt_of_spec (who : Address) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : Attempt k external self where_ role how w who outcome trace) :
    ∃ fuel, attempt k external self where_ role how w who fuel = ACLTree.result outcome trace := by
  cases hs with
  | absent h => exact ⟨0, by simp_all [attempt, ACLTree.result]⟩
  | unconditional hp hu => exact ⟨0, by simp [attempt, ACL.evalParams, hu, ACL.emptyParams, pure, ACLTree.result]⟩
  | parameters hp hu ht =>
    obtain ⟨fuel, hf⟩ := (ACLLeaf.tree_corresponds k external self _ who where_ role how w 0 outcome trace).mp ht
    exact ⟨fuel, by simpa [attempt, hp, ACL.evalParams, hu] using hf⟩

theorem attempt_to_spec (who : Address) (fuel : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : attempt k external self where_ role how w who fuel = ACLTree.result outcome trace) :
    Attempt k external self where_ role how w who outcome trace := by
  by_cases hp : (stored k self where_ role w who).val = 0
  · have he : ACLTree.result (.value false) [] = ACLTree.result outcome trace := by
      simpa [attempt, hp, ACLTree.result] using hs
    obtain ⟨rfl, rfl⟩ := ACLTree.result_injective _ _ _ _ he
    exact .absent (by simp [hp])
  · by_cases hu : (stored k self where_ role w who).val = ACL.emptyParams
    · have he : ACLTree.result (.value true) [] = ACLTree.result outcome trace := by
        simpa only [attempt, if_neg hp, ACL.evalParams, if_pos hu, pure, ACLTree.result] using hs
      obtain ⟨rfl, rfl⟩ := ACLTree.result_injective _ _ _ _ he
      exact .unconditional hp hu
    · apply ACLPermissionSpec.Attempt.parameters hp hu
      apply (ACLLeaf.tree_corresponds k external self _ who where_ role how w 0 outcome trace).mpr
      exact ⟨fuel, by simpa [attempt, hp, ACL.evalParams, hu] using hs⟩

theorem attempt_lift (who : Address) (fuel extra : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : attempt k external self where_ role how w who fuel = ACLTree.result outcome trace) :
    attempt k external self where_ role how w who (fuel+extra) = ACLTree.result outcome trace := by
  by_cases hp : (stored k self where_ role w who).val = 0
  · simpa [attempt, hp] using hs
  · by_cases hu : (stored k self where_ role w who).val = ACL.emptyParams
    · simpa [attempt, hp, ACL.evalParams, hu] using hs
    · simp only [attempt, hp, ite_false, ACL.evalParams, hu] at hs ⊢
      exact ACLTree.lift k external self _ who where_ role how w fuel extra 0 outcome trace hs

end

section
variable (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
  (ctx : Context) (role : Word) (how : List Word) (w : World)

def Describes : ACLTreeSpec.Outcome → List NestedAttempt → Prop :=
  ACLPermissionSpec.Select
    (Attempt k external self ctx.self role how w ctx.sender)
    (Attempt k external self ctx.self role how w ACL.anyEntity)

theorem selection_source (fuel : Nat) :
    ACL.hasPermission k external self ctx role how w fuel =
      select (attempt k external self ctx.self role how w ctx.sender fuel)
        (attempt k external self ctx.self role how w ACL.anyEntity fuel) := by
  unfold ACL.hasPermission attempt stored
  dsimp only
  by_cases hp : (w.core.readContractSlot self.val (ACL.permissionSlot k ctx.sender ctx.self role)).val = 0 <;>
    by_cases hw : (w.core.readContractSlot self.val (ACL.permissionSlot k ACL.anyEntity ctx.self role)).val = 0 <;>
    generalize hs : ACL.evalParams k external self
      (w.core.readContractSlot self.val (ACL.permissionSlot k ctx.sender ctx.self role))
      ctx.sender ctx.self role how w fuel = first <;>
    generalize ht : ACL.evalParams k external self
      (w.core.readContractSlot self.val (ACL.permissionSlot k ACL.anyEntity ctx.self role))
      ACL.anyEntity ctx.self role how w fuel = second <;>
    rcases first with ⟨fo, ft⟩ <;> rcases second with ⟨so, st⟩ <;>
    cases fo <;> cases so <;> simp_all [select, bind, ACL.bindResult, pure] <;>
    split <;> simp_all <;> split <;> simp_all

theorem of_spec (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : Describes k external self ctx role how w outcome trace) :
    ∃ fuel, ACL.hasPermission k external self ctx role how w fuel = ACLTree.result outcome trace := by
  cases hs with
  | accepted h =>
    obtain ⟨fuel, hf⟩ := attempt_of_spec k external self ctx.self role how w ctx.sender _ _ h
    exact ⟨fuel, by rw [selection_source, hf]; rfl⟩
  | failed h =>
    obtain ⟨fuel, hf⟩ := attempt_of_spec k external self ctx.self role how w ctx.sender _ _ h
    exact ⟨fuel, by rw [selection_source, hf]; rfl⟩
  | fallback hs hw =>
    obtain ⟨f, hf⟩ := attempt_of_spec k external self ctx.self role how w ctx.sender _ _ hs
    obtain ⟨g, hg⟩ := attempt_of_spec k external self ctx.self role how w ACL.anyEntity _ _ hw
    have hsf := attempt_lift k external self ctx.self role how w ctx.sender f g _ _ hf
    have hwf := attempt_lift k external self ctx.self role how w ACL.anyEntity g f _ _ hg
    rw [Nat.add_comm g f] at hwf
    exact ⟨f+g, by rw [selection_source, hsf, hwf]; rfl⟩

private theorem transport (predicate : ACLTreeSpec.Outcome → List NestedAttempt → Prop)
    (first second : ACLTreeSpec.Outcome) (left right : List NestedAttempt)
    (h : ACLTree.result first left = ACLTree.result second right) (hp : predicate first left) :
    predicate second right := by
  obtain ⟨rfl, rfl⟩ := ACLTree.result_injective _ _ _ _ h
  exact hp

theorem to_spec (fuel : Nat) (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : ACL.hasPermission k external self ctx role how w fuel = ACLTree.result outcome trace) :
    Describes k external self ctx role how w outcome trace := by
  rw [selection_source] at hs
  generalize hf : attempt k external self ctx.self role how w ctx.sender fuel = first at hs
  rcases first with ⟨fo, ft⟩
  cases fo with
  | error halt =>
    cases halt with
    | exhausted => cases outcome <;> simp [select, ACLTree.result] at hs
    | invalidOpcode =>
      apply transport _ .invalidOpcode outcome ft trace hs
      exact ACLPermissionSpec.Select.failed
        (attempt_to_spec k external self ctx.self role how w ctx.sender fuel _ _ hf)
  | ok allowed =>
    cases allowed with
    | true =>
      apply transport _ (.value true) outcome ft trace hs
      exact ACLPermissionSpec.Select.accepted
        (attempt_to_spec k external self ctx.self role how w ctx.sender fuel _ _ hf)
    | false =>
      have hfirst := attempt_to_spec k external self ctx.self role how w ctx.sender fuel (.value false) ft hf
      generalize hw : attempt k external self ctx.self role how w ACL.anyEntity fuel = second at hs
      rcases second with ⟨so, st⟩
      cases so with
      | error halt =>
        cases halt with
        | exhausted => cases outcome <;> simp [select, ACLTree.result] at hs
        | invalidOpcode =>
          apply transport _ .invalidOpcode outcome (ft ++ st) trace hs
          exact ACLPermissionSpec.Select.fallback hfirst
            (attempt_to_spec k external self ctx.self role how w ACL.anyEntity fuel _ _ hw)
      | ok answer =>
        apply transport _ (.value answer) outcome (ft ++ st) trace hs
        exact ACLPermissionSpec.Select.fallback hfirst
          (attempt_to_spec k external self ctx.self role how w ACL.anyEntity fuel _ _ hw)

/-- Completed physical permission queries correspond in both directions to the
independent ordered attempt/graph/leaf rules, including exact oracle traces.
No evaluation of an unvisited wildcard graph is required. -/
theorem corresponds (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt) :
    Describes k external self ctx role how w outcome trace ↔
      ∃ fuel, ACL.hasPermission k external self ctx role how w fuel = ACLTree.result outcome trace := by
  constructor
  · exact of_spec k external self ctx role how w outcome trace
  · rintro ⟨fuel, hs⟩
    exact to_spec k external self ctx role how w fuel outcome trace hs

theorem of_spec_stable (outcome : ACLTreeSpec.Outcome) (trace : List NestedAttempt)
    (hs : Describes k external self ctx role how w outcome trace) :
    ∃ fuel, ∀ extra, ACL.hasPermission k external self ctx role how w (fuel+extra) = ACLTree.result outcome trace := by
  obtain ⟨fuel, hf⟩ := of_spec k external self ctx role how w outcome trace hs
  refine ⟨fuel, fun extra => ?_⟩
  have hn : (ACL.hasPermission k external self ctx role how w fuel).outcome ≠ .error .exhausted := by
    rw [hf]; cases outcome <;> simp [ACLTree.result]
  exact (ACLBounds.permission_mono k external self ctx role how w fuel extra hn).trans hf

end

/-- Independent permission derivations supply the actual Lido→Kernel→ACL admission
result. Initialization, physical code/pointers and the static-call interpreter
remain explicit deployment/primitive inputs. -/
theorem canPerform (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (role : Word) (w : World) (allowed : Bool) (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : Describes k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx role [] w (.value allowed) trace) :
    ∃ fuel, ∀ extra, (Aragon.canPerform (ACLCalls.external k staticExternal (Aragon.kernel ctx w)
      (Kernel.acl k (Aragon.kernel ctx w) w) ctx role (fuel+extra) other) ctx role w).outcome = .ok allowed := by
  obtain ⟨fuel, hf⟩ := of_spec_stable k staticExternal _ ctx role [] w (.value allowed) trace hs
  exact ⟨fuel, fun extra => ACLCalls.canPerform k staticExternal other ctx role w (fuel+extra)
    allowed trace hi hk hkc ha hac (hf extra)⟩

def admissionTrace (k : Queue.Keccak) (ctx : Context) (role : Word) (w : World)
    (allowed : Bool) (children : List NestedAttempt) : List Live.Attempt :=
  [⟨⟨ctx.self, Aragon.kernel ctx w, word 0, Aragon.permissionPayload ctx role⟩, true,
    encode 32 (if allowed then 1 else 0),
    Kernel.attempted ⟨Aragon.kernel ctx w, Kernel.acl k (Aragon.kernel ctx w) w, word 0,
      Aragon.permissionPayload ctx role⟩ true (encode 32 (if allowed then 1 else 0)) children⟩]

theorem canPerform_traced (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (role : Word) (w : World) (allowed : Bool) (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : Describes k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx role [] w (.value allowed) trace) :
    ∃ fuel, ∀ extra, Aragon.canPerform (ACLCalls.external k staticExternal (Aragon.kernel ctx w)
      (Kernel.acl k (Aragon.kernel ctx w) w) ctx role (fuel+extra) other) ctx role w =
        ⟨.ok allowed, w, admissionTrace k ctx role w allowed trace⟩ := by
  obtain ⟨fuel, hf⟩ := of_spec_stable k staticExternal _ ctx role [] w (.value allowed) trace hs
  refine ⟨fuel, fun extra => ?_⟩
  have hz : (word 0).val = 0 := rfl
  have ho : (word 1).val = 1 := rfl
  have hr : ACL.dispatch k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx role (fuel+extra) other other
      ⟨Aragon.kernel ctx w, Kernel.acl k (Aragon.kernel ctx w) w, word 0, Aragon.permissionPayload ctx role⟩ w =
        .successWithTrace (encode 32 (if allowed then 1 else 0)) w trace := by
    simp [ACL.dispatch, hz, hf extra, ACLTree.result]
  cases allowed
  · have he := Kernel.aragon_from_acl_traced k _ other ctx role (word 0) w w [] trace hi hk hkc ha hac
      (by simpa [hz] using hr)
    simpa [ACLCalls.external, admissionTrace, hz] using he
  · have he := Kernel.aragon_from_acl_traced k _ other ctx role (word 1) w w [] trace hi hk hkc ha hac
      (by simpa [ho] using hr)
    simpa [ACLCalls.external, admissionTrace, ho] using he

/-- Source authorization from an independent permission derivation admits the
actual target writer and its independent accounting relation. -/
theorem target_allowed (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (requested : Word) (w : World) (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : Describes k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx Aragon.bufferReserveManagerRole [] w (.value true) trace) :
    ∃ fuel, ∀ extra, WriterSpec.Target (Writers.project ctx w) requested.val
      (Writers.project ctx (run (Aragon.setTarget (ACLCalls.external k staticExternal (Aragon.kernel ctx w)
        (Kernel.acl k (Aragon.kernel ctx w) w) ctx Aragon.bufferReserveManagerRole (fuel+extra) other)
          ctx requested) w).world) := by
  obtain ⟨fuel, hf⟩ := canPerform_traced k staticExternal other ctx Aragon.bufferReserveManagerRole w true trace
    hi hk hkc ha hac hs
  exact ⟨fuel, fun extra => Aragon.allowed _ ctx requested w w _ (hf extra)⟩

/-- Independent denial restores the full original world and retains the complete
Lido→Kernel→ACL/oracle attempt trace. -/
theorem target_denied (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (requested : Word) (w : World) (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : Describes k staticExternal (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx Aragon.bufferReserveManagerRole [] w (.value false) trace) :
    ∃ fuel, ∀ extra, run (Aragon.setTarget (ACLCalls.external k staticExternal (Aragon.kernel ctx w)
      (Kernel.acl k (Aragon.kernel ctx w) w) ctx Aragon.bufferReserveManagerRole (fuel+extra) other)
        ctx requested) w = ⟨.error (.reason "APP_AUTH_FAILED"), w,
          admissionTrace k ctx Aragon.bufferReserveManagerRole w false trace⟩ := by
  obtain ⟨fuel, hf⟩ := canPerform_traced k staticExternal other ctx Aragon.bufferReserveManagerRole w false trace
    hi hk hkc ha hac hs
  exact ⟨fuel, fun extra => Aragon.denied _ ctx requested w w _ (hf extra)⟩

end LidoSRv3.Audit.Source.TrioReserve1.ACLPermission
