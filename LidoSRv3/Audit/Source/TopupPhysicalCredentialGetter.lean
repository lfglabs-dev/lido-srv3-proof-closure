import LidoSRv3.Audit.Guarantees.PTopupCredentialCalls
import LidoSRv3.Audit.Source.DepositPhysicalAdmission

/-! Selected StakingRouter credentials getter, core17005714. Actual calldata
selects the module, registration precedes the packed config/type and router WC
reads, and the canonical bytes32 response is returned. No deposit Active or
uint8-type-validity guard belongs to this getter. Other router selectors,
deployed code identity and actual keccak computation remain outside. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupPhysicalCredentialGetter
open TrioReserve1 Live
open TopupCredentialCall (request)
abbrev Keccak := TopupRouterCredentials.Keccak

def asId (id : Word) : TrioAlloc1.Word := ⟨id.val,id.isLt⟩
def membership (hash : Keccak) (router : Address) (id : Word) (w : World) : Nat :=
  DepositPhysicalAdmission.membership hash router (asId id) w

def selected (hash : Keccak) (router : Address) (id : Word) (w : World) : Word :=
  word (DepositPhysicalAdmission.selected hash router (asId id) w).val

def unregistered : Bytes := encode 4 0xd41d6282

/-- This storage-only body has no status enum read or deposit authorization. -/
def body (hash : Keccak) (router : Address) (id : Word) (w : World) : StaticCall.Reply :=
  if membership hash router id w = 0 then .rejected unregistered
  else .success (encode 32 (selected hash router id w).val)

/-- Selected runtime dispatcher: calldata size/selector, nonpayability, signed
ABI head check, actual moduleId load, then the physical body. Only this selector
is claimed; rejected other selectors are outside the covered dispatch slice. -/
def dispatch (hash : Keccak) : StaticCall.External := fun req w =>
  if (word req.payload.length).val < 4 then .rejected []
  else if req.payload.take 4 ≠ encode 4 TopupCredentialCall.selector then .rejected []
  else if req.value.val ≠ 0 then .rejected []
  else if audit.trio.deposit.ModuleCall.signedLt
      (word ((word req.payload.length).val + 2^256 - 4)) (word 32) then .rejected []
  else body hash req.target (word (decode ((req.payload.drop 4).take 32))) w

@[simp] theorem word_val (w : Word) : word w.val = w := by
  apply Verity.Core.Uint256.ext
  exact Nat.mod_eq_of_lt w.isLt

theorem selected_fields (hash : Keccak) (router : Address) (id : Word) (w : World) :
    (selected hash router id w).val / 2^248 =
      TopupRouterCredentials.typeOf (w.core.readContractSlot router.val (TopupRouterCredentials.moduleSlot hash id)) ∧
    (selected hash router id w).val % 2^248 = (TopupRouterCredentials.raw router w).val % 2^248 := by
  have h := DepositPhysicalAdmission.selected_fields hash router (asId id) w
  have hb := (DepositPhysicalAdmission.selected hash router (asId id) w).isLt
  have hs : (selected hash router id w).val = (DepositPhysicalAdmission.selected hash router (asId id) w).val := by
    change _ % 2^256 = _
    exact Nat.mod_eq_of_lt hb
  simp only [DepositPhysicalAdmission.config,asId,word_val] at h
  simpa only [hs,asId] using h

/-- The generated STATICCALL really traverses dispatcher/ABI decoding; id is
not captured from an unrelated parameter in the external interpreter. -/
theorem dispatch_request (hash : Keccak) (gateway router : Address) (id : Word) (w : World) :
    dispatch hash (request gateway router id) w = body hash router id w := by
  have ht : (encode 4 TopupCredentialCall.selector ++ encode 32 id.val).take 4 = encode 4 TopupCredentialCall.selector := by
    simpa only [ABI.encode_length] using (List.take_left (l₁ := encode 4 TopupCredentialCall.selector) (l₂ := encode 32 id.val))
  have hd : (encode 4 TopupCredentialCall.selector ++ encode 32 id.val).drop 4 = encode 32 id.val := by
    simpa only [ABI.encode_length] using (List.drop_left (l₁ := encode 4 TopupCredentialCall.selector) (l₂ := encode 32 id.val))
  have htake : (encode 32 id.val).take 32 = encode 32 id.val := by simp [List.take_eq_self_iff,ABI.encode_length]
  simp only [dispatch,request,List.length_append,ABI.encode_length,ht,hd,htake,
    TopupRouterCredentials.octets_encode_roundtrip,word_val]
  have hv : (word 0).val = 0 := by decide
  have hlen : (word (4+32)).val = 36 := by decide
  rw [hv,hlen]
  simp only [show ¬ (36:Nat)<4 from by decide,if_false,ne_eq,not_true_eq_false]
  have hs : audit.trio.deposit.ModuleCall.signedLt (word (36+2^256-4)) (word 32) = false := by decide +kernel
  simp only [hs,Bool.false_eq_true,if_false]

theorem body_success (hash : Keccak) (router : Address) (id : Word) (w : World) (raw : Bytes)
    (h : body hash router id w = .success raw) :
    membership hash router id w ≠ 0 ∧ raw = encode 32 (selected hash router id w).val := by
  unfold body at h
  split at h
  · cases h
  · cases h; exact ⟨by assumption,rfl⟩

def run (credentialCursor returnBuffer : Word) (hash : Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List TopupGatewayWitnessBatch.Row) (allocation : Word) : TopupCredentialCall.Result :=
  TopupCredentialCall.run (dispatch hash) credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation

/-- Source correspondence for the actual successful response consumed by f008.
Canonical response is proved, while no registration/type/success premise is
added to the whole public run theorem. -/
theorem response_fields (hash : Keccak) (gateway router : Address) (id cursor : Word)
    (w : World) (wc next : Word) (raw : Bytes)
    (hcall : dispatch hash (request gateway router id) w = .success raw)
    (hdecode : TopupCredentialCall.decodeCredentials cursor raw = .ok (wc,next)) :
    membership hash router id w ≠ 0 ∧ raw = encode 32 (selected hash router id w).val ∧
    wc = selected hash router id w := by
  rw [dispatch_request] at hcall
  obtain ⟨hm,hr⟩ := body_success hash router id w raw hcall
  have hw := (TopupCredentialCall.decode_fields cursor raw wc next hdecode).2.1
  rw [hr] at hw
  have ht : (encode 32 (selected hash router id w).val).take 32 = encode 32 (selected hash router id w).val := by
    simp [List.take_eq_self_iff,ABI.encode_length]
  rw [ht,TopupRouterCredentials.octets_encode_roundtrip,word_val] at hw
  exact ⟨hm,hr,hw⟩

#print axioms selected_fields
#print axioms dispatch_request
#print axioms body_success
#print axioms response_fields
end LidoSRv3.Audit.Source.TopupPhysicalCredentialGetter
