import ReportFeeDistribution
import LidoSRv3.Audit.Source.TrioReserve1.StaticCall

/-! Accounting.sol:486, pinned solc0.8.9 typed STATICCALL. ACCOUNT's actual
World is retained: no invented embedding into the separate Live.World.
Immutable locator and code metadata are explicit call-context inputs. -/
namespace AccountAddress.TreasuryCall
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
abbrev World := ReportFeeMint.World

structure Environment where
  locator : Live.Address
  codeSize : Live.Address → Live.Word
  external : Live.Request → World → StaticCall.Reply

def request (e : Environment) (caller : Nat) : Live.Request :=
  ⟨Verity.Core.Address.ofNat caller,e.locator,Live.word 0,Live.encode 4 0x61d027b3⟩

/-- Signed uint256 head-size check followed by canonical ABI address check.
Trailing bytes are permitted. Earlier memory/copy provenance is not asserted. -/
def decodeAddress (raw : Live.Bytes) : Except Live.Fault Nat :=
  let size := (Live.word raw.length).val
  if size < 32 ∨ 2^255 ≤ size then .error .empty else
  let value := Live.decode (raw.take 32)
  if 2^160 ≤ value then .error .empty else .ok value

structure Result where
  outcome : Except Live.Fault Nat
  attempts : List Live.NestedAttempt

def call (e : Environment) (caller : Nat) (world : World) : Result :=
  let req := request e caller
  if (e.codeSize e.locator).val = 0 then ⟨.error .empty,[]⟩
  else match e.external req world with
    | .success raw => ⟨decodeAddress raw,[⟨req,true,true,raw,1⟩]⟩
    | .rejected raw => ⟨.error (.bubbled raw),[⟨req,true,false,raw,1⟩]⟩
    | .forbiddenStateChange => ⟨.error .empty,[⟨req,true,false,[],1⟩]⟩

/-- Adapter is consumed by the actual distribution projection. Errors remain
fully represented in call; the old Nat-error resolver only observes a tag. -/
def read (e : Environment) (caller : Nat) (router : ReportWriteFee.Core) : FeeDistribution.TreasuryRead :=
  fun steth => (call e caller ⟨router,steth⟩).outcome.mapError (fun _ => 0)

theorem call_success (e : Environment) (caller : Nat) (world : World) (recipient : Nat)
    (h : (call e caller world).outcome = .ok recipient) :
    (e.codeSize e.locator).val ≠ 0 ∧ ∃ raw,
      e.external (request e caller) world = .success raw ∧
      decodeAddress raw = .ok recipient ∧ recipient < 2^160 ∧
      recipient = Live.decode (raw.take 32) ∧
      (call e caller world).attempts = [⟨request e caller,true,true,raw,1⟩] := by
  unfold call at h ⊢
  split at h
  · cases h
  · rename_i hc
    rw [if_neg hc]
    cases he : e.external (request e caller) world with
    | rejected raw => simp [he] at h
    | forbiddenStateChange => simp [he] at h
    | success raw =>
      simp only [he] at h ⊢
      refine ⟨hc,raw,rfl,h,?_,?_,rfl⟩
      all_goals
        unfold decodeAddress at h
        dsimp only at h
        split at h
        · cases h
        · split at h
          · cases h
          · rename_i hb
            cases h
            first | omega | rfl

#print axioms call_success
end AccountAddress.TreasuryCall
