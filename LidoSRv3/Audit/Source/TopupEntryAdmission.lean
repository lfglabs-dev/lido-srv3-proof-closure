import LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall

/-! Physical TopUpGateway onlyRole/whenResumed admission before the complete
locator/credentials/root/module/history executor. Typed entry after the outer
ABI head checks; caller and deployed gateway identity remain call-context inputs.
Unlike the legacy Lido flag, OZ5.2 hasRole reads only the low byte. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupEntryAdmission
open TrioReserve1 Live TopupGatewayWitnessBatch

def role : Nat := 0x5e4bd437d29fad01c10cdcfff414f0d6b0e84b96d2dade88d780d45b5630696b
def accessSlot : Nat := 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800
def resumeSlot : Nat := 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02

def roleSlot (caller : Address) : Nat := Compiler.Proofs.solidityMappingSlot
  (Compiler.Proofs.solidityMappingSlot accessSlot role) caller.val

/-- Exact inner role/base and outer caller/inner two-word Keccak preimages. -/
theorem roleSlot_bytes (caller : Address) : roleSlot caller =
    EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
      ((EvmYul.UInt256.ofNat caller.val).toByteArray ++
       (EvmYul.UInt256.ofNat (EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
         ((EvmYul.UInt256.ofNat role).toByteArray ++ (EvmYul.UInt256.ofNat accessSlot).toByteArray)))).toByteArray)) := by rfl

def roleByte (gateway caller : Address) (before : World) : Nat :=
  (before.core.readContractSlot gateway.val (roleSlot caller)).val % 256

def Admitted (gateway caller : Address) (before : World) : Prop :=
  roleByte gateway caller before ≠ 0 ∧
  (before.core.readContractSlot gateway.val resumeSlot).val ≤ before.core.blockTimestamp.val

def unauthorized (caller : Address) : Bytes := encode 4 0xe2517d3f ++ encode 32 caller.val ++ encode 32 role

def gates (gateway caller : Address) (before : World) : Except Fault Unit :=
  if roleByte gateway caller before = 0 then .error (.bubbled (unauthorized caller)) else
  if before.core.blockTimestamp.val < (before.core.readContractSlot gateway.val resumeSlot).val then
    .error (.bubbled (encode 4 0x14378398)) else .ok ()

theorem gates_success (gateway caller : Address) (before : World)
    (h : gates gateway caller before = .ok ()) : Admitted gateway caller before := by
  unfold gates at h
  split at h
  · cases h
  · rename_i hr
    split at h
    · cases h
    · rename_i hp
      exact ⟨hr,Nat.le_of_not_gt hp⟩

inductive Error where
  | admission (fault : Fault)
  | phase (fault : TopupRouterLocatorCall.Error)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  suffix : Option TopupRouterLocatorCall.Result

def ofPrior (prior : TopupRouterLocatorCall.Result) : Result :=
  ⟨prior.outcome.mapError Error.phase,prior.world,some prior⟩

def run (caller : Address) (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : TopupGatewayRootCalls.Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word) : Result :=
  match gates e.gateway caller e.before with
  | .error f => ⟨.error (.admission f),e.before,none⟩
  | .ok () => ofPrior (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation)

theorem run_success (caller : Address) (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : TopupGatewayRootCalls.Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word)
    (h : (run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    Admitted e.gateway caller e.before ∧
    (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok () ∧
    run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation = ofPrior (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation) := by
  unfold run at h ⊢
  cases hg : gates e.gateway caller e.before with
  | «error» f => simp [hg] at h
  | ok u =>
    cases u
    simp only [hg] at h ⊢
    have hp : (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok () := by
      cases ho : (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome with
      | «error» f => simp [ofPrior,ho,Except.mapError] at h
      | ok u => cases u; rfl
    exact ⟨gates_success _ _ _ hg,hp,trivial⟩

theorem failure_restores (caller : Address) (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : TopupGatewayRootCalls.Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word) (fault : Error)
    (h : (run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hg : gates e.gateway caller e.before with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hg,ofPrior] at h ⊢
    cases ho : (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome with
    | ok u => simp [ho,Except.mapError] at h
    | «error» f => exact TopupRouterLocatorCall.failure_restores locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation f ho

#print axioms roleSlot_bytes
#print axioms gates_success
#print axioms run_success
#print axioms failure_restores
end LidoSRv3.Audit.Source.TopupEntryAdmission
