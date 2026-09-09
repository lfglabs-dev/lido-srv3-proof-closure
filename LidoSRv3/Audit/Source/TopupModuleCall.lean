import LidoSRv3.Audit.Source.TopupRouterContinuation

/-! StakingRouter.sol:717–758 at core@17005714. This adapter starts AFTER
the preamble computed the rounded target. The module's physical address,
argument bytes, raw reply and returned World flow through the real Live CALL
interface into the accepted continuation. The external interpreter remains
arbitrary: no module implementation, authorization, target computation, full
compiler ABI/memory/gas equivalence, or pre-module balance invariant is proved.
The decoder implements byte bounds and the uint64 offset/count guards; its
canonical roundtrip does not certify compiler memory allocation failures. -/
namespace LidoSRv3.Audit.Source.TopupModuleCall
open TrioReserve1 Live
open LidoSRv3.Audit.Verity.TopupTx

structure Input where
  moduleId : Word
  roundedTarget : Word
  pubkeys : List Bytes
  keyIndices : List Word
  operatorIds : List Word
  limits : List Word

def moduleAddress (hash : TopupRouterCredentials.Keccak) (router : Address)
    (moduleId : Word) (w : World) : Address :=
  Verity.Core.Address.ofNat
    (w.core.readContractSlot router.val (TopupRouterCredentials.moduleSlot hash moduleId)).val

theorem address_packed (config : Word) (address high : Nat)
    (ha : address < 2^160) (hc : config.val = address + high * 2^160) :
    (Verity.Core.Address.ofNat config.val).val = address := by
  change config.val % (2^160) = address
  rw [hc]
  omega

def typedCall (i : Input) : TopupCall :=
  { roundedTarget := i.roundedTarget.val
    routerWithdrawalCredentials := []
    withdrawalCredentialsType := 0
    pubkeys := TopupRouterContinuation.keys i.pubkeys
    keyIndices := TopupRouterContinuation.values i.keyIndices
    operatorIds := TopupRouterContinuation.values i.operatorIds
    topUpLimits := TopupRouterContinuation.values i.limits
    moduleReturndata := [] }

def payload (i : Input) : Bytes :=
  TopupBeaconEffects.serialize (allocateCalldata (typedCall i))

def call (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (i : Input) : Exec Bytes := fun w =>
  CallData.invoke callee ctx (moduleAddress hash ctx.self i.moduleId w) (payload i) (word 0) w

/- CallData.invoke has an early code-size check. The inspected 0.8.25 typed
CALL instead rejects a no-code target's empty return in its decoder. Failure
agrees, but no-code attempt traces are NOT identified. Successful transports
below derive the positive-code domain from the Live CALL. -/

/-- A successful call is traced back to the external interpreter on the actual
request and provisionally transferred World. No successful-result field is
supplied by Input. Both traced and untraced replies are retained. -/
theorem call_success_origin (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (i : Input) (before after : World) (raw : Bytes) (trace : List Attempt)
    (h : call hash callee ctx i before = ⟨.ok raw,after,trace⟩) :
    let target := moduleAddress hash ctx.self i.moduleId before
    let req : Request := ⟨ctx.self,target,word 0,payload i⟩
    (before.core.codeSize target.val).val ≠ 0 ∧
    ((callee req (transfer before ctx.self target 0) = .success raw after ∧
       trace = [⟨req,true,raw,[]⟩]) ∨
     ∃ nested, callee req (transfer before ctx.self target 0) = .successWithTrace raw after nested ∧
       trace = [⟨req,true,raw,nested⟩]) := by
  unfold call CallData.invoke at h
  dsimp only at h ⊢
  split at h
  · simp at h
  · rename_i hc
    split at h
    · simp at h
    · split at h
      · simp at h
      · rename_i data w hr
        cases h
        exact ⟨hc,Or.inl ⟨hr,rfl⟩⟩
      · rename_i data w nested hr
        cases h
        exact ⟨hc,Or.inr ⟨nested,hr,rfl⟩⟩
      · simp at h

def encodeWords (xs : List Word) : Bytes := xs.flatMap (fun x => encode 32 x.val)
def encodeReturn (xs : List Word) : Bytes :=
  encode 32 32 ++ encode 32 xs.length ++ encodeWords xs

def readWords : Nat → Bytes → List Word
  | 0, _ => []
  | n+1, bytes => word (decode (bytes.take 32)) :: readWords n (bytes.drop 32)

def decodeReturn (bytes : Bytes) : Except Fault (List Word) :=
  if bytes.length < 32 then .error .empty else
  let offset := decode (bytes.take 32)
  if offset ≥ 2^64 then .error .empty else
  if offset + 32 > bytes.length then .error .empty else
  let count := decode ((bytes.drop offset).take 32)
  if count ≥ 2^64 then .error (.reason "Panic(0x41)") else
  if offset + 32 + 32*count > bytes.length then .error .empty else
  .ok (readWords count (bytes.drop (offset+32)))

theorem encodeWords_length (xs : List Word) : (encodeWords xs).length = 32*xs.length := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    change (encode 32 x.val ++ encodeWords xs).length = 32*(xs.length+1)
    rw [List.length_append, ABI.encode_length, ih]
    omega

theorem readWords_encoded (xs : List Word) (tail : Bytes) :
    readWords xs.length (encodeWords xs ++ tail) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    have ht : (encode 32 x.val ++ (encodeWords xs ++ tail)).take 32 = encode 32 x.val := by
      simpa [ABI.encode_length] using (List.take_left (l₁ := encode 32 x.val) (l₂ := encodeWords xs ++ tail))
    have hd : (encode 32 x.val ++ (encodeWords xs ++ tail)).drop 32 = encodeWords xs ++ tail := by
      simpa [ABI.encode_length] using (List.drop_left (l₁ := encode 32 x.val) (l₂ := encodeWords xs ++ tail))
    change word (decode ((encode 32 x.val ++ encodeWords xs ++ tail).take 32)) ::
      readWords xs.length ((encode 32 x.val ++ encodeWords xs ++ tail).drop 32) = x :: xs
    rw [List.append_assoc, ht, hd, TopupBeaconEffects.decode_serialized_word, ih]
    congr 1
    exact Verity.Core.Uint256.ext (Nat.mod_eq_of_lt x.isLt)

theorem decodeReturn_encoded (xs : List Word) (tail : Bytes) (hn : xs.length < 2^64) :
    decodeReturn (encodeReturn xs ++ tail) = .ok xs := by
  have hword : xs.length < 256^32 := by omega
  have take32 (n : Nat) (bs : Bytes) : (encode 32 n ++ bs).take 32 = encode 32 n := by
    simpa [ABI.encode_length] using (List.take_left (l₁ := encode 32 n) (l₂ := bs))
  have drop32 (n : Nat) (bs : Bytes) : (encode 32 n ++ bs).drop 32 = bs := by
    simpa [ABI.encode_length] using (List.drop_left (l₁ := encode 32 n) (l₂ := bs))
  have he : encodeReturn xs ++ tail = encode 32 32 ++ (encode 32 xs.length ++ (encodeWords xs ++ tail)) := by
    simp [encodeReturn, List.append_assoc]
  have hl : (encodeReturn xs ++ tail).length = 64 + 32*xs.length + tail.length := by
    simp [encodeReturn, List.length_append, ABI.encode_length, encodeWords_length]; omega
  have hd64 : (encodeReturn xs ++ tail).drop 64 = encodeWords xs ++ tail := by
    rw [he, show 64 = 32+32 from rfl, ← List.drop_drop, drop32, drop32]
  unfold decodeReturn
  rw [if_neg (by omega), he, take32, ABI.decode_encode_bounded 32 32 (by decide)]
  rw [if_neg (by decide)]
  rw [← he, if_neg (by omega), he, drop32, take32, ABI.decode_encode_bounded 32 xs.length hword]
  rw [if_neg (by omega), ← he, if_neg (by omega)]
  simpa only [show 32+32=64 from rfl, hd64, readWords_encoded]

def continuationInput (i : Input) (allocations : List Word) : TopupRouterContinuation.Input :=
  ⟨i.moduleId, i.roundedTarget, i.pubkeys, i.limits, allocations⟩

/-- The withdrawal Context has Lido as self and router as sender; the module
CALL uses router as self. Callee effects survive into the continuation. -/
def program (hash : TopupRouterCredentials.Keccak) (moduleExternal withdrawalExternal : External)
    (withdrawalCtx : Context) (beacon : Address) (i : Input) : Exec Unit := do
  let raw ← call hash moduleExternal (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext withdrawalCtx) i
  match decodeReturn raw with
  | .error e => fail e
  | .ok allocations => TopupRouterContinuation.program hash withdrawalExternal withdrawalCtx beacon (continuationInput i allocations)

def execute (hash : TopupRouterCredentials.Keccak) (moduleExternal withdrawalExternal : External)
    (withdrawalCtx : Context) (beacon : Address) (i : Input) : Exec Unit :=
  Live.run (program hash moduleExternal withdrawalExternal withdrawalCtx beacon i)

theorem program_of_call (hash : TopupRouterCredentials.Keccak) (m e : External)
    (ctx : Context) (beacon : Address) (i : Input) (before after : World)
    (raw : Bytes) (trace : List Attempt)
    (hc : call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before = ⟨.ok raw,after,trace⟩) :
    program hash m e ctx beacon i before =
      match decodeReturn raw with
      | .error fault => ⟨.error fault,after,trace⟩
      | .ok allocations =>
        let r := TopupRouterContinuation.program hash e ctx beacon (continuationInput i allocations) after
        ⟨r.outcome,r.world,trace ++ r.attempts⟩ := by
  simp only [program, bind, bindExec, hc]
  cases decodeReturn raw <;> simp [fail]

/-- Canonical return bytes, including arbitrary trailing bytes, feed exactly
their decoded allocations to the continuation on the module's returned World. -/
theorem program_encoded (hash : TopupRouterCredentials.Keccak) (m e : External)
    (ctx : Context) (beacon : Address) (i : Input) (before after : World)
    (allocations : List Word) (tail : Bytes) (trace : List Attempt)
    (hn : allocations.length < 2^64)
    (hc : call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before =
      ⟨.ok (encodeReturn allocations ++ tail),after,trace⟩) :
    program hash m e ctx beacon i before =
      let r := TopupRouterContinuation.program hash e ctx beacon (continuationInput i allocations) after
      ⟨r.outcome,r.world,trace ++ r.attempts⟩ := by
  rw [program_of_call _ _ _ _ _ _ _ _ _ _ hc, decodeReturn_encoded _ _ hn]

/-- Every success has an actual raw module reply and a successful byte decode;
the same allocations and World enter the existing router continuation. -/
theorem program_success_origin (hash : TopupRouterCredentials.Keccak) (m e : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (h : (program hash m e ctx beacon i before).outcome = .ok ()) :
    ∃ raw after trace allocations,
      call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before = ⟨.ok raw,after,trace⟩ ∧
      decodeReturn raw = .ok allocations ∧
      let r := TopupRouterContinuation.program hash e ctx beacon (continuationInput i allocations) after
      r.outcome = .ok () ∧ (program hash m e ctx beacon i before).world = r.world ∧
        (program hash m e ctx beacon i before).attempts = trace ++ r.attempts := by
  cases hc : call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before with
  | mk outcome after trace =>
    cases outcome with
    | «error» fault => simp [program,bind,bindExec,hc] at h
    | ok raw =>
      have hp := program_of_call hash m e ctx beacon i before after raw trace hc
      cases hd : decodeReturn raw with
      | «error» fault => simp [hd] at hp; rw [hp] at h; contradiction
      | ok allocations =>
        simp only [hd] at hp
        refine ⟨raw,after,trace,allocations,rfl,hd,?_,?_,?_⟩
        · simpa only [hp] using h
        · rw [hp]
        · rw [hp]

theorem failure_restores (hash : TopupRouterCredentials.Keccak) (m e : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World) (fault : Fault)
    (h : (execute hash m e ctx beacon i before).outcome = .error fault) :
    (execute hash m e ctx beacon i before).world = before := by
  unfold execute Live.run at *
  dsimp only at *
  split <;> simp_all

end LidoSRv3.Audit.Source.TopupModuleCall
