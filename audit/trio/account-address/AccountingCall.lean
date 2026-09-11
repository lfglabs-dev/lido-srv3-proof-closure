import LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause
import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! Pinned Lido.sol894,1422–1427,1557–1559, solc0.4.24: physical low160
locator, typed EXTCODESIZE + zero-value CALL, unsigned minimum return size,
then low160 cleanup at _auth. This is specialized to the actual LidoLocator
immutable getter body. Effective deployment/code identity (including proxy
implementation resolution) remains context, not a proved proxy interpreter.
No arbitrary mutable callback is represented as readonly. -/
namespace AccountAddress.AccountingCall
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
abbrev World := ReportFeeMint.World

def locatorPosition : Nat :=
  0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223

def locator (w : World) : Live.Address :=
  Verity.Core.Address.ofNat (w.steth.storage.read locatorPosition).val

/-- The effective pinned implementation's immutable, not a supplied CALL
reply or an independent mint authorization value. `none` represents no code.
Matching target/proxy/implementation to deployed code remains explicit. -/
structure Getter where
  accounting : Live.Address

structure Environment where
  code : Live.Address → Option Getter

def request (w : World) : Live.Request :=
  ⟨Verity.Core.Address.ofNat w.steth.selfAddress,locator w,Live.word 0,Live.encode 4 0x9624e83e⟩

inductive Reply where
  | success (post : World) (raw : Live.Bytes)
  | rejected (raw : Live.Bytes)

/-- The actual no-argument nonpayable immutable getter branch, with its
selector/value dispatch. Preservation follows from this body, not a frame
premise. Resource exhaustion and full memory/bytecode refinement are outside. -/
def getter (g : Getter) (req : Live.Request) (w : World) : Reply :=
  if req.value.val = 0 ∧ req.payload.take 4 = Live.encode 4 0x9624e83e then
    .success w (Live.encode 32 g.accounting.val)
  else .rejected []

/-- Legacy return-size LT is unsigned, with no canonical-address rejection.
The compiler loads the first word and _auth masks its high96 bits. Trailing
bytes are ignored. Memory/output-copy provenance retains its existing boundary. -/
def decodeAddress (raw : Live.Bytes) : Except Live.Fault Nat :=
  if (Live.word raw.length).val < 32 then .error .empty
  else .ok (Live.decode (raw.take 32) % 2^160)

structure Result where
  outcome : Except Live.Fault (World × Nat)
  attempts : List Live.NestedAttempt

def call (e : Environment) (w : World) : Result :=
  let req := request w
  match e.code req.target with
  | none => ⟨.error .empty,[]⟩
  | some g => match getter g req w with
    | .rejected raw => ⟨.error (.bubbled raw),[⟨req,false,false,raw,1⟩]⟩
    | .success post raw =>
      ⟨(decodeAddress raw).map (fun a => (post,a)),[⟨req,false,true,raw,1⟩]⟩

theorem getter_request (g : Getter) (w : World) :
    getter g (request w) w = .success w (Live.encode 32 g.accounting.val) := by
  have ht : (Live.encode 4 0x9624e83e).take 4 = Live.encode 4 0x9624e83e := by decide +kernel
  simp [getter,request,Live.word,ht]

theorem decode_getter (g : Getter) :
    decodeAddress (Live.encode 32 g.accounting.val) = .ok g.accounting.val := by
  have hb : g.accounting.val < 2^160 := g.accounting.isLt
  have hb32 : g.accounting.val < 256^32 := Nat.lt_trans hb (by decide)
  have ht : (Live.encode 32 g.accounting.val).take 32 = Live.encode 32 g.accounting.val := by
    exact List.take_of_length_le (by simp [ABI.encode_length])
  simp [decodeAddress,ABI.encode_length,Live.word,ht,ABI.decode_encode_bounded 32 _ hb32,
    Nat.mod_eq_of_lt hb,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS]

theorem call_success (e : Environment) (before after : World) (resolved : Nat)
    (h : (call e before).outcome = .ok (after,resolved)) :
    after = before ∧ resolved < 2^160 ∧ ∃ g,
      e.code (locator before) = some g ∧
      getter g (request before) before = .success before (Live.encode 32 g.accounting.val) ∧
      decodeAddress (Live.encode 32 g.accounting.val) = .ok resolved ∧ resolved = g.accounting.val ∧
      (call e before).attempts = [⟨request before,false,true,Live.encode 32 g.accounting.val,1⟩] := by
  unfold call at h ⊢
  cases hc : e.code (request before).target with
  | none => simp only [hc] at h; cases h
  | some g =>
    simp only [hc,getter_request] at h ⊢
    cases hd : decodeAddress (Live.encode 32 g.accounting.val) with
    | error f => simp [hd,Except.map] at h
    | ok a =>
      simp only [hd,Except.map] at h
      cases h
      refine ⟨rfl,?_,g,hc,True.intro,hd,?_,rfl⟩
      · unfold decodeAddress at hd
        split at hd
        · cases hd
        · cases hd; exact Nat.mod_lt _ (by decide)
      · rw [decode_getter] at hd
        cases hd
        rfl


theorem call_getter (e : Environment) (w : World) (g : Getter)
    (h : e.code (locator w) = some g) :
    (call e w).outcome = .ok (w,g.accounting.val) ∧
    (call e w).attempts = [⟨request w,false,true,Live.encode 32 g.accounting.val,1⟩] := by
  simp [call,show (request w).target = locator w from rfl,h,getter_request,decode_getter,Except.map]

end AccountAddress.AccountingCall
