import LidoSRv3.Audit.Source.AddressRequestCalls

/-! One-item WithdrawalQueue → WSTETH transfer/unwrap → STETH quote → physical
queue request, core@17005714. The WSTETH implementation is an external callee,
not an asserted burn/allowance theorem. Full pause/batch/dispatcher are outside
this phase. Existing enqueue and source-order writes are reused unchanged. -/
namespace LidoSRv3.Audit.Source.AddressWrappedRequestCalls
open _root_.Verity (Uint256 zeroAddress)
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestCalls
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
  (StaticExternal callWithCalldata)
set_option autoImplicit false

@[simp] private theorem exec_bind {α β : Type} (x : Exec α) (f : α → Exec β) :
    (x >>= f) = bindExec x f := rfl
@[simp] private theorem exec_pure {α : Type} (x : α) : (pure x : Exec α) = pureExec x := rfl

def unwrapCalldata (amount : Uint256) : Bytes := encode 4 0xde0e9a3e ++ encode 32 amount.val

/-- The caller's actual uint256 ABI decoder accepts trailing returndata. -/
def unwrapStage (callee : External) (ctx : Context) (wstETH : _root_.Verity.Address)
    (amount : Uint256) : Exec Uint256 := do
  let data ← callWithCalldata callee ctx wstETH (unwrapCalldata amount)
  decodeWord data

/-- No extra stETH transferFrom: the decoded unwrap amount is quoted/enqueued. -/
def request (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address) : Exec Nat := fun before => (do
  transferStage callee ctx wstETH amount.val
  let received ← unwrapStage callee ctx wstETH amount
  require (decide (100 ≤ received.val)) (.reason "RequestAmountTooSmall")
  require (decide (received.val ≤ 1000 * 10 ^ 18)) (.reason "RequestAmountTooLarge")
  let shares ← quoteStage quote ctx stETH received.val
  enqueue ctx (resolvedOwner ctx owner) (received.val % 2 ^ 128) (shares.val % 2 ^ 128)
    before.core.blockTimestamp) before

def runRequest (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address) (w : World) :=
  run (request callee quote ctx wstETH stETH amount owner) w

/-- Actual raw CALL return and world, consumed by the uint256 decoder. -/
def UnwrapEffect (callee : External) (ctx : Context) (wstETH : _root_.Verity.Address)
    (amount received : Uint256) (before after : World) (attempts : List Attempt) : Prop :=
  let req : Request := ⟨ctx.self, wstETH, 0, unwrapCalldata amount⟩
  (before.core.codeSize wstETH.val).val ≠ 0 ∧
    ∃ data nested, 32 ≤ data.length ∧ received = word (decode (data.take 32)) ∧
      ((callee req (transfer before ctx.self wstETH 0) = .success data after ∧ nested = []) ∨
       callee req (transfer before ctx.self wstETH 0) = .successWithTrace data after nested) ∧
      attempts = [⟨req, true, data, nested⟩]

private theorem bind_success {α β : Type} (first : Exec α) (next : α → Exec β)
    (before : World) (value : β) (h : (bindExec first next before).outcome = .ok value) :
    ∃ a, (first before).outcome = .ok a ∧
      (next a (first before).world).outcome = .ok value ∧
      (bindExec first next before).world = (next a (first before).world).world ∧
      (bindExec first next before).attempts =
        (first before).attempts ++ (next a (first before).world).attempts := by
  cases hx : (first before).outcome with
  | «error» fault => simp [bindExec, hx] at h
  | ok a => exact ⟨a, rfl, by simpa [bindExec, hx] using h,
      by simp [bindExec, hx], by simp [bindExec, hx]⟩

private theorem decode_success (data : Bytes) (w : World) (v : Uint256)
    (h : (decodeWord data 0 w).outcome = .ok v) :
    32 ≤ data.length ∧ v = word (decode (data.take 32)) ∧
      (decodeWord data 0 w).world = w ∧ (decodeWord data 0 w).attempts = [] := by
  by_cases hl : 32 ≤ data.length
  · simp [decodeWord, require, hl, bindExec, pureExec] at h ⊢
    exact h.symm
  · simp [decodeWord, require, hl, bindExec, fail] at h

private theorem call_success (callee : External) (ctx : Context) (target : _root_.Verity.Address)
    (payload data : Bytes) (w : World)
    (h : (callWithCalldata callee ctx target payload 0 w).outcome = .ok data) :
    (w.core.codeSize target.val).val ≠ 0 ∧ ∃ nested,
      ((callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) =
          .success data (callWithCalldata callee ctx target payload 0 w).world ∧ nested = []) ∨
       callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) =
          .successWithTrace data (callWithCalldata callee ctx target payload 0 w).world nested) ∧
      (callWithCalldata callee ctx target payload 0 w).attempts =
        [⟨⟨ctx.self, target, 0, payload⟩, true, data, nested⟩] := by
  by_cases hc : (w.core.codeSize target.val).val = 0
  · simp [callWithCalldata, hc] at h
  cases hr : callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) with
  | rejected bytes => simp [callWithCalldata, hc, hr] at h
  | rejectedWithTrace bytes nested => simp [callWithCalldata, hc, hr] at h
  | success bytes after =>
    simp [callWithCalldata, hc, hr] at h
    subst data
    simp only [callWithCalldata, if_neg hc]
    simp only [Verity.Core.Uint256.val_zero, Nat.not_lt_zero, ↓reduceIte, hr]
    exact ⟨hc, [], Or.inl ⟨trivial, rfl⟩, rfl⟩
  | successWithTrace bytes after nested =>
    simp [callWithCalldata, hc, hr] at h
    subst data
    simp only [callWithCalldata, if_neg hc]
    simp only [Verity.Core.Uint256.val_zero, Nat.not_lt_zero, ↓reduceIte, hr]
    exact ⟨hc, nested, Or.inr rfl, rfl⟩

theorem unwrap_success (callee : External) (ctx : Context) (wstETH : _root_.Verity.Address)
    (amount received : Uint256) (w : World)
    (h : (unwrapStage callee ctx wstETH amount w).outcome = .ok received) :
    UnwrapEffect callee ctx wstETH amount received w
      (unwrapStage callee ctx wstETH amount w).world
      (unwrapStage callee ctx wstETH amount w).attempts := by
  obtain ⟨data,hc,hd,hw,ha⟩ := bind_success _ _ _ _ h
  obtain ⟨hl,hv,hdw,hda⟩ := decode_success _ _ _ hd
  obtain ⟨hcode,nested,hr,hat⟩ := call_success _ _ _ _ _ _ hc
  have finalw : (unwrapStage callee ctx wstETH amount w).world =
      (callWithCalldata callee ctx wstETH (unwrapCalldata amount) 0 w).world := hw.trans hdw
  exact ⟨hcode,data,nested,hl,hv,by simpa only [finalw] using hr,
    by simpa only [unwrapStage,exec_bind,hda,List.append_nil] using ha.trans (by simpa only [hda,List.append_nil] using hat)⟩

/-- Both mutable calls, then the static quote and enqueue, share the actual
returned worlds. The same decoded amount drives its bounds, quote and event. -/
def RequestEffect (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address)
    (id : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  ∃ transferred unwrapped received shares ta ua qa,
    TransferEffect callee ctx wstETH amount.val before transferred ta ∧
    UnwrapEffect callee ctx wstETH amount received transferred unwrapped ua ∧
    100 ≤ received.val ∧ received.val ≤ 1000 * 10 ^ 18 ∧ received.val < 2 ^ 128 ∧
    QuoteEffect quote ctx stETH received.val unwrapped shares qa ∧
    EnqueueEffect ctx (resolvedOwner ctx owner) received.val (shares.val % 2 ^ 128) id
      before.core.blockTimestamp unwrapped after ∧
    attempts = ta ++ ua ++ qa

private theorem require_success (condition : Bool) (fault : Fault) (w : World)
    (h : (require condition fault w).outcome = .ok ()) :
    condition = true ∧ (require condition fault w).world = w ∧
      (require condition fault w).attempts = [] := by
  cases condition <;> simp [require, pureExec, fail] at h ⊢

theorem request_success (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address)
    (id : Nat) (w : World)
    (h : (request callee quote ctx wstETH stETH amount owner w).outcome = .ok id) :
    RequestEffect callee quote ctx wstETH stETH amount owner id w
      (request callee quote ctx wstETH stETH amount owner w).world
      (request callee quote ctx wstETH stETH amount owner w).attempts := by
  obtain ⟨u,ht,h1,hw0,ha0⟩ := bind_success _ _ _ _ h
  cases u
  obtain ⟨received,hu,h2,hw1,ha1⟩ := bind_success _ _ _ _ h1
  obtain ⟨u,hlo,h3,hw2,ha2⟩ := bind_success _ _ _ _ h2
  cases u
  obtain ⟨hlo,hwl,hal⟩ := require_success _ _ _ hlo
  simp only [hwl] at h3 hw2 ha2
  obtain ⟨u,hhi,h4,hw3,ha3⟩ := bind_success _ _ _ _ h3
  cases u
  obtain ⟨hhi,hwh,hah⟩ := require_success _ _ _ hhi
  simp only [hwh] at h4 hw3 ha3
  obtain ⟨shares,hq,he,hw4,ha4⟩ := bind_success _ _ _ _ h4
  obtain ⟨hqe,hqw⟩ := quote_success _ _ _ _ _ _ hq
  simp only [hqw] at he hw4 ha4
  obtain ⟨hee,hea⟩ := enqueue_success _ _ _ _ _ _ _ he
  have hlow : 100 ≤ received.val := of_decide_eq_true hlo
  have hhigh : received.val ≤ 1000 * 10 ^ 18 := of_decide_eq_true hhi
  have hfit : received.val < 2 ^ 128 := by omega
  refine ⟨_,_,received,shares,_,_,_,transfer_success _ _ _ _ _ ht,
    unwrap_success _ _ _ _ _ _ hu,hlow,hhigh,hfit,hqe,?_,?_⟩
  · have finalw := hw0.trans (hw1.trans (hw2.trans (hw3.trans hw4)))
    change (request callee quote ctx wstETH stETH amount owner w).world = _ at finalw
    rw [finalw]
    simpa only [Nat.mod_eq_of_lt hfit] using hee
  · simp only [exec_bind] at ha0 ha1 ha2 ha3 ha4
    simpa only [request,exec_bind,ha1,ha2,ha3,ha4,hal,hah,hea,List.nil_append,List.append_nil,List.append_assoc] using ha0

theorem run_success (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address)
    (id : Nat) (w : World)
    (h : (runRequest callee quote ctx wstETH stETH amount owner w).outcome = .ok id) :
    RequestEffect callee quote ctx wstETH stETH amount owner id w
      (runRequest callee quote ctx wstETH stETH amount owner w).world
      (runRequest callee quote ctx wstETH stETH amount owner w).attempts := by
  unfold runRequest run at h ⊢
  cases he : (request callee quote ctx wstETH stETH amount owner w).outcome with
  | «error» e => simp [he] at h
  | ok n =>
    simp only [he] at h ⊢
    cases h
    exact request_success _ _ _ _ _ _ _ _ _ he

theorem run_failure_restores (callee : External) (quote : StaticExternal) (ctx : Context)
    (wstETH stETH : _root_.Verity.Address) (amount : Uint256) (owner : _root_.Verity.Address)
    (w : World) (fault : Fault)
    (h : (runRequest callee quote ctx wstETH stETH amount owner w).outcome = .error fault) :
    (runRequest callee quote ctx wstETH stETH amount owner w).world = w := by
  unfold runRequest run at h ⊢
  cases he : (request callee quote ctx wstETH stETH amount owner w).outcome <;> simp_all

end LidoSRv3.Audit.Source.AddressWrappedRequestCalls
