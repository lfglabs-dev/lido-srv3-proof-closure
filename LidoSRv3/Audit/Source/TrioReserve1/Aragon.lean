import LidoSRv3.Audit.Source.TrioReserve1.AragonSpec
import LidoSRv3.Audit.Source.TrioReserve1.ABI
import LidoSRv3.Audit.Source.TrioReserve1.Writers

namespace LidoSRv3.Audit.Source.TrioReserve1.Aragon
open Live

def initializationSlot : Nat := 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e
def kernelSlot : Nat := 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b
def bufferReserveManagerRole : Word :=
  word 0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921

def initialized (ctx : Context) (w : World) : Bool :=
  let n := (w.core.readContractSlot ctx.self.val initializationSlot).val
  n ≠ 0 && n ≤ w.core.blockNumber.val

def kernel (ctx : Context) (w : World) : Address :=
  Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val kernelSlot).val

/-- ABI for hasPermission(sender, self, role, empty bytes). Aragon casts the
empty uint256 array used by Lido._auth to empty bytes, so offset=128 and length=0. -/
def permissionPayload (ctx : Context) (role : Word) : Bytes :=
  encode 4 0xfdef9106 ++ encode 32 ctx.sender.val ++ encode 32 ctx.self.val ++
    encode 32 role.val ++ encode 32 128 ++ encode 32 0

/-- Zero-value high-level CALL with complete argument bytes. Retains callee
world effects and rejection bytes; transaction rollback belongs to Live.run. -/
def permissionCall (external : External) (ctx : Context) (target : Address) (role : Word) : Exec Bytes := fun w =>
  let req : Request := ⟨ctx.self, target, word 0, permissionPayload ctx role⟩
  if (w.core.codeSize target.val).val = 0 then ⟨.error .empty, w, []⟩
  else match external req w with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨req, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨req, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok data, after, [⟨req, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested => ⟨.error (.bubbled data), w, [⟨req, false, data, nested⟩]⟩

/-- Pinned AragonApp.canPerform, specialized to Lido._auth's empty parameters.
No supplied authorization boolean replaces the physical prefix or kernel call. -/
def canPerform (external : External) (ctx : Context) (role : Word) : Exec Bool := fun w =>
  if !initialized ctx w then ⟨.ok false, w, []⟩
  else if (kernel ctx w).val = 0 then ⟨.ok false, w, []⟩
  else (do
    let data ← permissionCall external ctx (kernel ctx w) role
    let value ← decodeWord data
    pure (decide (value.val ≠ 0))) w

/-- External Lido writer: the role check precedes every target/reserve write. -/
def setTarget (external : External) (ctx : Context) (requested : Word) : Exec Unit := do
  let allowed ← canPerform external ctx bufferReserveManagerRole
  require allowed (.reason "APP_AUTH_FAILED")
  setDepositsReserveTarget ctx requested

def admissionPrefix (ctx : Context) (w : World) : AragonSpec.Prefix :=
  if !initialized ctx w || (kernel ctx w).val = 0 then .deny else .query

theorem prefix_corresponds (ctx : Context) (w : World) :
    AragonSpec.Describes (w.core.readContractSlot ctx.self.val initializationSlot).val
      w.core.blockNumber.val (kernel ctx w).val (admissionPrefix ctx w) := by
  unfold admissionPrefix initialized
  split <;> simp_all [AragonSpec.Describes] <;> omega

theorem uninitialized (external : External) (ctx : Context) (role : Word) (w : World)
    (h : initialized ctx w = false) : canPerform external ctx role w = ⟨.ok false, w, []⟩ := by
  simp [canPerform, h]

theorem absent_kernel (external : External) (ctx : Context) (role : Word) (w : World)
    (h : (kernel ctx w).val = 0) : canPerform external ctx role w = ⟨.ok false, w, []⟩ := by
  unfold canPerform
  split
  · rfl
  · simp_all

/-- Actual kernel reply bytes are decoded after the physical admission prefix.
The post-call world is retained, including arbitrary callback effects. -/
theorem kernel_reply (external : External) (ctx : Context) (role value : Word)
    (w after : World) (suffix : Bytes)
    (hi : initialized ctx w = true) (hk : (kernel ctx w).val ≠ 0)
    (hc : (w.core.codeSize (kernel ctx w).val).val ≠ 0)
    (hr : external ⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩ w =
      .success (encode 32 value.val ++ suffix) after) :
    canPerform external ctx role w =
      ⟨.ok (decide (value.val ≠ 0)), after,
        [⟨⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩,
          true, encode 32 value.val ++ suffix, []⟩]⟩ := by
  have hd := ABI.decode_word value.val suffix after
  simp only [Writers.word_val] at hd
  simp [canPerform, hi, hk, permissionCall, hc, hr, bind, bindExec, hd, pure, pureExec]

theorem kernel_rejection (external : External) (ctx : Context) (role : Word)
    (w : World) (data : Bytes)
    (hi : initialized ctx w = true) (hk : (kernel ctx w).val ≠ 0)
    (hc : (w.core.codeSize (kernel ctx w).val).val ≠ 0)
    (hr : external ⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩ w = .rejected data) :
    canPerform external ctx role w =
      ⟨.error (.bubbled data), w,
        [⟨⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩, false, data, []⟩]⟩ := by
  simp [canPerform, hi, hk, permissionCall, hc, hr, bind, bindExec]

theorem kernel_no_code (external : External) (ctx : Context) (role : Word) (w : World)
    (hi : initialized ctx w = true) (hk : (kernel ctx w).val ≠ 0)
    (hc : (w.core.codeSize (kernel ctx w).val).val = 0) :
    canPerform external ctx role w = ⟨.error .empty, w, []⟩ := by
  simp [canPerform, hi, hk, permissionCall, hc, bind, bindExec]

theorem kernel_short_reply (external : External) (ctx : Context) (role : Word)
    (w after : World) (data : Bytes) (hlen : data.length < 32)
    (hi : initialized ctx w = true) (hk : (kernel ctx w).val ≠ 0)
    (hc : (w.core.codeSize (kernel ctx w).val).val ≠ 0)
    (hr : external ⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩ w = .success data after) :
    canPerform external ctx role w =
      ⟨.error .empty, after,
        [⟨⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx role⟩, true, data, []⟩]⟩ := by
  simp [canPerform, hi, hk, permissionCall, hc, hr, bind, bindExec, decodeWord,
    require, Nat.not_le.mpr hlen, fail]

theorem denied (external : External) (ctx : Context) (requested : Word) (w after : World)
    (trace : List Attempt)
    (h : canPerform external ctx bufferReserveManagerRole w = ⟨.ok false, after, trace⟩) :
    run (setTarget external ctx requested) w = ⟨.error (.reason "APP_AUTH_FAILED"), w, trace⟩ := by
  simp [setTarget, run, bind, bindExec, h, require, fail]

theorem permission_failure (external : External) (ctx : Context) (requested : Word)
    (w : World) (fault : Fault)
    (h : (canPerform external ctx bufferReserveManagerRole w).outcome = .error fault) :
    run (setTarget external ctx requested) w =
      ⟨.error fault, w, (canPerform external ctx bufferReserveManagerRole w).attempts⟩ := by
  simp [setTarget, run, bind, bindExec, h]

/-- Successful permission evaluation retains its actual callee world. The
writer specification is based on that world, not stale pre-CALL storage. -/
theorem allowed (external : External) (ctx : Context) (requested : Word) (w after : World)
    (trace : List Attempt)
    (h : canPerform external ctx bufferReserveManagerRole w = ⟨.ok true, after, trace⟩) :
    WriterSpec.Target (Writers.project ctx after) requested.val
      (Writers.project ctx (run (setTarget external ctx requested) w).world) := by
  have hs := Writers.target_observations ctx after requested
  have ht := Writers.target_corresponds ctx after requested
  have ho : (setDepositsReserveTarget ctx requested after).outcome = .ok () := by
    cases he : (setDepositsReserveTarget ctx requested after).outcome with
    | error e => simp [run, he] at hs
    | ok value => cases value; rfl
  simpa [run, setTarget, bind, bindExec, h, require, pure, pureExec, ho] using ht

theorem target_from_kernel_reply (external : External) (ctx : Context) (requested value : Word)
    (w after : World) (suffix : Bytes)
    (hi : initialized ctx w = true) (hk : (kernel ctx w).val ≠ 0)
    (hc : (w.core.codeSize (kernel ctx w).val).val ≠ 0) (hv : value.val ≠ 0)
    (hr : external ⟨ctx.self, kernel ctx w, word 0, permissionPayload ctx bufferReserveManagerRole⟩ w =
      .success (encode 32 value.val ++ suffix) after) :
    WriterSpec.Target (Writers.project ctx after) requested.val
      (Writers.project ctx (run (setTarget external ctx requested) w).world) := by
  apply allowed external ctx requested w after
  simpa [hv] using kernel_reply external ctx bufferReserveManagerRole value w after suffix hi hk hc hr


end LidoSRv3.Audit.Source.TrioReserve1.Aragon
