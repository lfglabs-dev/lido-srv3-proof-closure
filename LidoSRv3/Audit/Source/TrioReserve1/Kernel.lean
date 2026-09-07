import LidoSRv3.Audit.Source.TrioReserve1.Aragon
import LidoSRv3.Audit.Source.TrioReserve1.Queue

namespace LidoSRv3.Audit.Source.TrioReserve1.Kernel
open Live

def appNamespace : Nat := 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb
def aclAppId : Nat := 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a

/-- KernelStorage.apps is the first structured storage field. The two mapping
hashes are separate applications of the explicit EVM keccak primitive. -/
def aclSlot (k : Queue.Keccak) : Nat :=
  (k (encode 32 aclAppId ++ encode 32 (k (encode 32 appNamespace ++ encode 32 0)).val)).val

def acl (k : Queue.Keccak) (self : Address) (w : World) : Address :=
  Verity.Core.Address.ofNat (w.core.readContractSlot self.val (aclSlot k)).val

def attempted (request : Request) (accepted : Bool) (data : Bytes)
    (children : List NestedAttempt := []) : List NestedAttempt :=
  ⟨request, false, accepted, data, 1⟩ :: children.map fun n => {n with depth := n.depth + 1}

def decodedReply (request : Request) (data : Bytes) (w : World)
    (children : List NestedAttempt := []) : Reply :=
  let trace := attempted request true data children
  if data.length < 32 then .rejectedWithTrace [] trace
  else .successWithTrace (encode 32 (if (word (decode (data.take 32))).val ≠ 0 then 1 else 0)) w trace

/-- Pinned Kernel.hasPermission for the empty-parameter role query used by
Lido._auth. Zero default ACL short-circuits; an installed ACL is called with
the original who/where/role, while msg.sender at the ACL is the kernel.
ACL code remains an explicit interpreter, including its own callback effects. -/
def hasPermission (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role : Word) (w : World) : Reply :=
  let target := acl k self w
  let request : Request := ⟨self, target, word 0, Aragon.permissionPayload ctx role⟩
  if target.val = 0 then .success (encode 32 0) w
  else if (w.core.codeSize target.val).val = 0 then .rejected []
  else match external request w with
    | .rejected data => .rejectedWithTrace data (attempted request false data)
    | .success data after => decodedReply request data after
    | .rejectedWithTrace data children => .rejectedWithTrace data (attempted request false data children)
    | .successWithTrace data after children => decodedReply request data after children

/-- Own exactly the argument-complete Lido role query; other selectors and
argument tuples are delegated. This is a specialization, not an ABI catch-all. -/
def dispatch (k : Queue.Keccak) (self : Address) (ctx : Context) (role : Word)
    (aclExternal other : External) : External := fun request w =>
  if request.target = self ∧ request.payload = Aragon.permissionPayload ctx role then
    if request.value.val ≠ 0 then .rejected []
    else hasPermission k aclExternal self ctx role w
  else other request w

theorem no_acl (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role : Word) (w : World) (h : (acl k self w).val = 0) :
    hasPermission k external self ctx role w = .success (encode 32 0) w := by
  simp [hasPermission, h]

theorem no_acl_code (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role : Word) (w : World)
    (h : (acl k self w).val ≠ 0) (hc : (w.core.codeSize (acl k self w).val).val = 0) :
    hasPermission k external self ctx role w = .rejected [] := by
  simp [hasPermission, h, hc]

theorem acl_rejection (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role : Word) (w : World) (data : Bytes)
    (h : (acl k self w).val ≠ 0) (hc : (w.core.codeSize (acl k self w).val).val ≠ 0)
    (hr : external ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ w = .rejected data) :
    hasPermission k external self ctx role w =
      .rejectedWithTrace data (attempted ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ false data) := by
  simp [hasPermission, h, hc, hr]

theorem decoded_word (request : Request) (value : Word) (suffix : Bytes) (w : World)
    (children : List NestedAttempt) :
    decodedReply request (encode 32 value.val ++ suffix) w children =
      .successWithTrace (encode 32 (if value.val ≠ 0 then 1 else 0)) w
        (attempted request true (encode 32 value.val ++ suffix) children) := by
  have hv : value.val < 256^32 := value.isLt
  simp [decodedReply, ABI.encode_length, ABI.decode_encode_bounded _ _ hv,
    Writers.word_val]

theorem acl_reply (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role value : Word) (w after : World) (suffix : Bytes)
    (h : (acl k self w).val ≠ 0) (hc : (w.core.codeSize (acl k self w).val).val ≠ 0)
    (hr : external ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ w =
      .success (encode 32 value.val ++ suffix) after) :
    hasPermission k external self ctx role w =
      .successWithTrace (encode 32 (if value.val ≠ 0 then 1 else 0)) after
        (attempted ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ true
          (encode 32 value.val ++ suffix)) := by
  simp only [hasPermission, h, hc, ite_false, hr, decoded_word]

theorem aragon_from_acl (k : Queue.Keccak) (aclExternal other : External) (ctx : Context)
    (role value : Word) (w after : World) (suffix : Bytes)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hr : aclExternal ⟨Aragon.kernel ctx w, acl k (Aragon.kernel ctx w) w, word 0,
      Aragon.permissionPayload ctx role⟩ w = .success (encode 32 value.val ++ suffix) after) :
    Aragon.canPerform (dispatch k (Aragon.kernel ctx w) ctx role aclExternal other) ctx role w =
      ⟨.ok (decide (value.val ≠ 0)), after,
        [⟨⟨ctx.self, Aragon.kernel ctx w, word 0, Aragon.permissionPayload ctx role⟩,
          true, encode 32 (if value.val ≠ 0 then 1 else 0),
          attempted ⟨Aragon.kernel ctx w, acl k (Aragon.kernel ctx w) w, word 0,
            Aragon.permissionPayload ctx role⟩ true (encode 32 value.val ++ suffix)⟩]⟩ := by
  have hr' := acl_reply k aclExternal (Aragon.kernel ctx w) ctx role value w after suffix ha hac hr
  have hd0 := ABI.decode_word 0 [] after
  have hd1 := ABI.decode_word 1 [] after
  have hz : (word 0).val = 0 := rfl
  have ho : (word 1).val = 1 := rfl
  simp only [List.append_nil] at hd0 hd1
  by_cases hv : value.val = 0 <;>
    simp [Aragon.canPerform, hi, hk, bind, bindExec, Aragon.permissionCall, hkc,
      dispatch, hr', hv, hd0, hd1, hz, ho, pure, pureExec]


theorem target_from_acl (k : Queue.Keccak) (aclExternal other : External) (ctx : Context)
    (requested value : Word) (w after : World) (suffix : Bytes)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hv : value.val ≠ 0)
    (hr : aclExternal ⟨Aragon.kernel ctx w, acl k (Aragon.kernel ctx w) w, word 0,
      Aragon.permissionPayload ctx Aragon.bufferReserveManagerRole⟩ w =
        .success (encode 32 value.val ++ suffix) after) :
    WriterSpec.Target (Writers.project ctx after) requested.val
      (Writers.project ctx (run (Aragon.setTarget
        (dispatch k (Aragon.kernel ctx w) ctx Aragon.bufferReserveManagerRole aclExternal other)
        ctx requested) w).world) := by
  apply Aragon.allowed _ ctx requested w after
  simpa [hv] using aragon_from_acl k aclExternal other ctx Aragon.bufferReserveManagerRole
    value w after suffix hi hk hkc ha hac hr

theorem acl_reply_traced (k : Queue.Keccak) (external : External) (self : Address)
    (ctx : Context) (role value : Word) (w after : World) (suffix : Bytes) (children : List NestedAttempt)
    (h : (acl k self w).val ≠ 0) (hc : (w.core.codeSize (acl k self w).val).val ≠ 0)
    (hr : external ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ w =
      .successWithTrace (encode 32 value.val ++ suffix) after children) :
    hasPermission k external self ctx role w =
      .successWithTrace (encode 32 (if value.val ≠ 0 then 1 else 0)) after
        (attempted ⟨self, acl k self w, word 0, Aragon.permissionPayload ctx role⟩ true
          (encode 32 value.val ++ suffix) children) := by
  simp only [hasPermission, h, hc, ite_false, hr, decoded_word]

theorem aragon_from_acl_traced (k : Queue.Keccak) (aclExternal other : External) (ctx : Context)
    (role value : Word) (w after : World) (suffix : Bytes) (children : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hr : aclExternal ⟨Aragon.kernel ctx w, acl k (Aragon.kernel ctx w) w, word 0,
      Aragon.permissionPayload ctx role⟩ w = .successWithTrace (encode 32 value.val ++ suffix) after children) :
    Aragon.canPerform (dispatch k (Aragon.kernel ctx w) ctx role aclExternal other) ctx role w =
      ⟨.ok (decide (value.val ≠ 0)), after,
        [⟨⟨ctx.self, Aragon.kernel ctx w, word 0, Aragon.permissionPayload ctx role⟩,
          true, encode 32 (if value.val ≠ 0 then 1 else 0),
          attempted ⟨Aragon.kernel ctx w, acl k (Aragon.kernel ctx w) w, word 0,
            Aragon.permissionPayload ctx role⟩ true (encode 32 value.val ++ suffix) children⟩]⟩ := by
  have hr' := acl_reply_traced k aclExternal (Aragon.kernel ctx w) ctx role value w after suffix children ha hac hr
  have hd0 := ABI.decode_word 0 [] after
  have hd1 := ABI.decode_word 1 [] after
  have hz : (word 0).val = 0 := rfl
  have ho : (word 1).val = 1 := rfl
  simp only [List.append_nil] at hd0 hd1
  by_cases hv : value.val = 0 <;>
    simp [Aragon.canPerform, hi, hk, bind, bindExec, Aragon.permissionCall, hkc,
      dispatch, hr', hv, hd0, hd1, hz, ho, pure, pureExec]


end LidoSRv3.Audit.Source.TrioReserve1.Kernel
