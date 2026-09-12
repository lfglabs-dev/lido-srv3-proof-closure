import LidoSRv3.Audit.Source.TopupRouterContinuation
import audit.trio.consolidation.LowLevel

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
  audit.trio.consolidation.lowLevelCall callee ctx (moduleAddress hash ctx.self i.moduleId w) (payload i) (word 0) w

/- The pinned solc 0.8.25 typed allocateDeposits call has no code-size
precheck: ordinary no-code targets return empty bytes and the caller decoder
rejects them. Precompile dispatch is outside this inherited no-code model arm. -/

/-- Actual successful CALL origin, including ordinary no-code empty acceptance.
A decoded successful module execution will derive the positive-code domain. -/
theorem call_success_origin (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (i : Input) (before after : World) (raw : Bytes) (trace : List Attempt)
    (h : call hash callee ctx i before = ⟨.ok raw,after,trace⟩) :
    let target := moduleAddress hash ctx.self i.moduleId before
    let req : Request := ⟨ctx.self,target,word 0,payload i⟩
    ((before.core.codeSize target.val).val = 0 ∧ raw = [] ∧
      after = transfer before ctx.self target 0 ∧ trace = [⟨req,true,[],[]⟩]) ∨
    ((before.core.codeSize target.val).val ≠ 0 ∧
      ((callee req (transfer before ctx.self target 0) = .success raw after ∧
        trace = [⟨req,true,raw,[]⟩]) ∨
       ∃ nested, callee req (transfer before ctx.self target 0) = .successWithTrace raw after nested ∧
         trace = [⟨req,true,raw,nested⟩])) := by
  unfold call audit.trio.consolidation.lowLevelCall at h
  simp only [word, Verity.Core.Uint256.val_ofNat, Nat.zero_mod, Nat.not_lt_zero, if_false] at h
  dsimp only
  split at h
  · rename_i hc
    cases h
    exact Or.inl ⟨hc,rfl,rfl,rfl⟩
  · rename_i hc
    right
    refine ⟨hc,?_⟩
    split at h
    · cases h
    · rename_i data w hr
      cases h
      exact Or.inl ⟨hr,rfl⟩
    · rename_i data w nested hr
      cases h
      exact Or.inr ⟨nested,hr,rfl⟩
    · cases h

/-- The actual zero-value CALL to an ordinary no-code target succeeds empty
and records the exact attempted request. No external interpreter is invoked. -/
theorem call_no_code (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (i : Input) (before : World)
    (hc : (before.core.codeSize (moduleAddress hash ctx.self i.moduleId before).val).val = 0) :
    call hash callee ctx i before =
      ⟨.ok [], transfer before ctx.self (moduleAddress hash ctx.self i.moduleId before) 0,
       [⟨⟨ctx.self,moduleAddress hash ctx.self i.moduleId before,word 0,payload i⟩,true,[],[]⟩]⟩ := by
  simp [call,audit.trio.consolidation.lowLevelCall,hc,word]

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

/-- Nonempty ABI success excludes the no-code empty reply by execution. -/
theorem decoded_call_has_code (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (i : Input) (before after : World) (raw : Bytes) (trace : List Attempt)
    (allocations : List Word)
    (h : call hash callee ctx i before = ⟨.ok raw,after,trace⟩)
    (hd : decodeReturn raw = .ok allocations) :
    (before.core.codeSize (moduleAddress hash ctx.self i.moduleId before).val).val ≠ 0 := by
  rcases call_success_origin hash callee ctx i before after raw trace h with he | he
  · rcases he with ⟨_,rfl,_,_⟩
    simp [decodeReturn] at hd
  · exact he.1

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

/-- Ordinary no-code acceptance is consumed by the ABI decoder, whose empty
failure restores the complete entry world and retains the successful CALL. -/
theorem execute_no_code (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (hc : (before.core.codeSize (moduleAddress hash ctx.sender i.moduleId before).val).val = 0) :
    execute hash m x ctx beacon i before =
      ⟨.error .empty,before,
       [⟨⟨ctx.sender,moduleAddress hash ctx.sender i.moduleId before,word 0,payload i⟩,true,[],[]⟩]⟩ := by
  have hcall := call_no_code hash m
    (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx) i before hc
  have hp := program_of_call hash m x ctx beacon i before _ [] _ hcall
  simp only [decodeReturn, List.length_nil, Nat.zero_lt_succ, if_true] at hp
  simpa [execute,Live.run,hp,fail,LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext]

/-- Full decoded success derives code presence; callers need no new premise. -/
theorem execute_success_has_code (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (h : (execute hash m x ctx beacon i before).outcome = .ok ()) :
    (before.core.codeSize (moduleAddress hash ctx.sender i.moduleId before).val).val ≠ 0 := by
  intro hc
  rw [execute_no_code hash m x ctx beacon i before hc] at h
  cases h

#print axioms execute_success_has_code

#print axioms call_success_origin
#print axioms decoded_call_has_code
#print axioms execute_no_code

end LidoSRv3.Audit.Source.TopupModuleCall
