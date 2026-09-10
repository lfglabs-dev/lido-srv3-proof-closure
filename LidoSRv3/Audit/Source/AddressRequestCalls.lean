import LidoSRv3.Audit.Verity.AddressRecipientCallBridge

/-! One admitted stETH request, core@17005714, solc 0.8.9 legacy optimizer 200.
Uses the accepted live CALL and STATICCALL interfaces; no mutable quote world.
The experimental IR push has a different length guard: this source follows the
actual legacy assembly (wrapping length, length/value/index order). No full
pause/batch, raw ABI dispatcher, gas or arbitrary-slot final-read theorem. -/
namespace LidoSRv3.Audit.Source.AddressRequestCalls
open _root_.Verity (Uint256 ContractState zeroAddress)
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
  (StaticExternal callWithCalldata staticCallWithCalldata decodeAbiBool
   lastRequestIdPosition lastReportTimestampPosition stETHTransferFromCalldata stETHSharesCalldata)

@[simp] private theorem exec_bind {α β : Type} (x : Exec α) (f : α → Exec β) :
    (x >>= f) = bindExec x f := rfl
@[simp] private theorem exec_pure {α : Type} (x : α) : (pure x : Exec α) = pureExec x := rfl

/-- Assertion is checked; the pinned legacy array push itself wraps its length.
The index value is re-read after the array-cell write, preserving alias behavior. -/
def insertOwnerChecked (s : ContractState) (owner : _root_.Verity.Address) (id : Nat) :
    Except Fault ContractState :=
  if ownerRequestIndex s owner id ≠ 0 then .error (.reason "Panic(0x01)")
  else
    let n := ownerRequestValuesLength s owner
    let grown := s.writeSlot (ownerRequestValuesLengthSlot owner) (.ofNat (n + 1))
    let filled := grown.writeSlot (ownerRequestValueSlot owner n) (.ofNat id)
    .ok (filled.writeSlot (ownerRequestIndexSlot owner id)
      (filled.readSlot (ownerRequestValuesLengthSlot owner)))

def OwnerInsertion (s after : ContractState) (owner : _root_.Verity.Address) (id : Nat) : Prop :=
  ownerRequestIndex s owner id = 0 ∧
    let n := ownerRequestValuesLength s owner
    let grown := s.writeSlot (ownerRequestValuesLengthSlot owner) (.ofNat (n + 1))
    let filled := grown.writeSlot (ownerRequestValueSlot owner n) (.ofNat id)
    after = filled.writeSlot (ownerRequestIndexSlot owner id)
      (filled.readSlot (ownerRequestValuesLengthSlot owner))

theorem insert_success (s after : ContractState) (owner : _root_.Verity.Address) (id : Nat)
    (h : insertOwnerChecked s owner id = .ok after) : OwnerInsertion s after owner id := by
  unfold insertOwnerChecked at h
  split at h
  · contradiction
  · simp only [Except.ok.injEq] at h
    exact ⟨by simpa using ‹¬ownerRequestIndex s owner id ≠ 0›, h.symm⟩

/-- Metadata constructor updates its 248 occupied bits, preserving the high byte.
Its old word is read after the cumulative-amount word has been written. -/
def metadataWord (old : Uint256) (owner : _root_.Verity.Address) (timestamp report : Nat) : Uint256 :=
  .ofNat (old.val / 2 ^ 248 * 2 ^ 248 + owner.val +
    timestamp % 2 ^ 40 * 2 ^ 160 + report % 2 ^ 40 * 2 ^ 208)

def requestWrites (s : ContractState) (owner : _root_.Verity.Address)
    (id cumSt cumSh : Nat) (timestamp : Uint256) : ContractState :=
  let numbered := s.writeSlot lastRequestIdPosition (.ofNat id)
  let report := (numbered.readSlot lastReportTimestampPosition).val
  let amounts := numbered.writeSlot (queueAmountsPhysicalSlot id) (packAmounts cumSt cumSh)
  amounts.writeSlot (queueMetadataPhysicalSlot id)
    (metadataWord (amounts.readSlot (queueMetadataPhysicalSlot id)) owner timestamp.val report)

def requestEvents (ctx : Context) (owner : _root_.Verity.Address)
    (id amount shares : Nat) (w : World) : World :=
  { w with logs := w.logs ++
    [⟨ctx.self, "WithdrawalRequested", [.ofNat id, .ofNat ctx.sender.val,
      .ofNat owner.val, .ofNat amount, .ofNat shares]⟩,
     ⟨ctx.self, "Transfer", [0, .ofNat owner.val, .ofNat id]⟩] }

/-- Source-order checked additions and ID, then physical writes and OZ insertion.
Inputs are the explicit uint128 casts performed by the consumer below. -/
def enqueue (ctx : Context) (owner : _root_.Verity.Address) (amount shares : Nat) (timestamp : Uint256) : Exec Nat := fun w =>
  let last := (w.core.readSlot lastRequestIdPosition).val
  let prev := requestAmountsWord w.core last
  let sh := cumulativeShares prev + shares
  if sh ≥ 2 ^ 128 then ⟨.error (.reason "Panic(0x11)"), w, []⟩ else
  let st := cumulativeStETH prev + amount
  if st ≥ 2 ^ 128 then ⟨.error (.reason "Panic(0x11)"), w, []⟩ else
  if last + 1 ≥ 2 ^ 256 then ⟨.error (.reason "Panic(0x11)"), w, []⟩ else
  let dirty := requestWrites w.core owner (last + 1) st sh timestamp
  match insertOwnerChecked dirty owner (last + 1) with
  | .error e => ⟨.error e, w, []⟩
  | .ok after => ⟨.ok (last + 1), requestEvents ctx owner (last + 1) amount shares
      { w with core := after }, []⟩

def EnqueueEffect (ctx : Context) (owner : _root_.Verity.Address)
    (amount shares id : Nat) (timestamp : Uint256) (before after : World) : Prop :=
  let last := (before.core.readSlot lastRequestIdPosition).val
  let prev := requestAmountsWord before.core last
  let sh := cumulativeShares prev + shares
  let st := cumulativeStETH prev + amount
  sh < 2 ^ 128 ∧ st < 2 ^ 128 ∧ id = last + 1 ∧ last < id ∧ id < 2 ^ 256 ∧
    ∃ stored,
      OwnerInsertion (requestWrites before.core owner id st sh timestamp) stored owner id ∧
      after = requestEvents ctx owner id amount shares { before with core := stored }

theorem enqueue_success (ctx : Context) (owner : _root_.Verity.Address)
    (amount shares id : Nat) (timestamp : Uint256) (w : World) (h : (enqueue ctx owner amount shares timestamp w).outcome = .ok id) :
    EnqueueEffect ctx owner amount shares id timestamp w (enqueue ctx owner amount shares timestamp w).world ∧
      (enqueue ctx owner amount shares timestamp w).attempts = [] := by
  by_cases hs : cumulativeShares (requestAmountsWord w.core
      (w.core.readSlot lastRequestIdPosition).val) + shares ≥ 2 ^ 128
  · simp only [enqueue, if_pos hs] at h
    contradiction
  by_cases ht : cumulativeStETH (requestAmountsWord w.core
      (w.core.readSlot lastRequestIdPosition).val) + amount ≥ 2 ^ 128
  · simp only [enqueue, if_neg hs, if_pos ht] at h
    contradiction
  by_cases hi : (w.core.readSlot lastRequestIdPosition).val + 1 ≥ 2 ^ 256
  · simp only [enqueue, if_neg hs, if_neg ht, if_pos hi] at h
    contradiction
  cases he : insertOwnerChecked
      (requestWrites w.core owner ((w.core.readSlot lastRequestIdPosition).val + 1)
        (cumulativeStETH (requestAmountsWord w.core (w.core.readSlot lastRequestIdPosition).val) + amount)
        (cumulativeShares (requestAmountsWord w.core (w.core.readSlot lastRequestIdPosition).val) + shares) timestamp)
      owner ((w.core.readSlot lastRequestIdPosition).val + 1) with
  | «error» e => simp only [enqueue, if_neg hs, if_neg ht, if_neg hi, he] at h; contradiction
  | ok stored =>
    simp only [enqueue, hs, ht, hi, if_false, he, Except.ok.injEq] at h
    subst id
    simp only [enqueue, hs, ht, hi, if_false, he]
    exact ⟨⟨Nat.lt_of_not_ge hs, Nat.lt_of_not_ge ht, rfl, Nat.lt_succ_self _,
      Nat.lt_of_not_ge hi, stored, insert_success _ _ _ _ he, rfl⟩, trivial⟩

/-- Bool false is accepted; noncanonical or short returns fail in the ABI decoder. -/
def transferStage (callee : External) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) : Exec Unit := do
  let bytes ← callWithCalldata callee ctx stETH (stETHTransferFromCalldata ctx.sender ctx.self amount)
  let _ ← decodeAbiBool bytes
  pure ()

def quoteStage (callee : StaticExternal) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) : Exec Uint256 := do
  let bytes ← staticCallWithCalldata callee ctx stETH (stETHSharesCalldata amount)
  decodeWord bytes

def resolvedOwner (ctx : Context) (owner : _root_.Verity.Address) : _root_.Verity.Address :=
  if owner = zeroAddress then ctx.sender else owner

/-- External wrapper owner resolution and one amount admission, then the actual
internal request. No pause, array-allocation or batch-loop execution is claimed. -/
def request (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address) : Exec Nat := fun before => (do
  require (decide (100 ≤ amount)) (.reason "RequestAmountTooSmall")
  require (decide (amount ≤ 1000 * 10 ^ 18)) (.reason "RequestAmountTooLarge")
  transferStage callee ctx stETH amount
  let shares ← quoteStage quote ctx stETH amount
  enqueue ctx (resolvedOwner ctx owner) (amount % 2 ^ 128) (shares.val % 2 ^ 128) before.core.blockTimestamp) before

def runRequest (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address) (w : World) :=
  run (request callee quote ctx stETH amount owner) w

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

/-- Actual CALL reply and postworld; the bool decoder admits exactly 0 or 1.
This relation exposes the external interpreter, not an assumed stage success. -/
def TransferEffect (callee : External) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  let req : Request := ⟨ctx.self, stETH, 0, stETHTransferFromCalldata ctx.sender ctx.self amount⟩
  (before.core.codeSize stETH.val).val ≠ 0 ∧
    ∃ data nested,
      32 ≤ data.length ∧
      ((word (decode (data.take 32))).val = 0 ∨ (word (decode (data.take 32))).val = 1) ∧
      ((callee req (transfer before ctx.self stETH 0) = .success data after ∧ nested = []) ∨
        callee req (transfer before ctx.self stETH 0) = .successWithTrace data after nested) ∧
      attempts = [⟨req, true, data, nested⟩]

def QuoteEffect (callee : StaticExternal) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) (before : World) (shares : Uint256) (attempts : List Attempt) : Prop :=
  let req : Request := ⟨ctx.self, stETH, 0, stETHSharesCalldata amount⟩
  (before.core.codeSize stETH.val).val ≠ 0 ∧ ∃ data,
    callee req before = .ok data ∧ 32 ≤ data.length ∧
    shares = word (decode (data.take 32)) ∧ attempts = [⟨req, true, data, []⟩]

private theorem decode_success (data : Bytes) (w : World) (v : Uint256)
    (h : (decodeWord data 0 w).outcome = .ok v) :
    32 ≤ data.length ∧ v = word (decode (data.take 32)) ∧
      (decodeWord data 0 w).world = w ∧ (decodeWord data 0 w).attempts = [] := by
  by_cases hl : 32 ≤ data.length
  · simp [decodeWord, require, hl, bindExec, pureExec] at h ⊢
    exact h.symm
  · simp [decodeWord, require, hl, bindExec, fail] at h

private theorem bool_success (data : Bytes) (w : World) (b : Bool)
    (h : (decodeAbiBool data w).outcome = .ok b) :
    32 ≤ data.length ∧
    ((word (decode (data.take 32))).val = 0 ∨ (word (decode (data.take 32))).val = 1) ∧
    (decodeAbiBool data w).world = w ∧ (decodeAbiBool data w).attempts = [] := by
  obtain ⟨v, hd, hb, hw, ha⟩ := bind_success _ _ _ _ h
  obtain ⟨hl, hv, hdw, hda⟩ := decode_success data w v hd
  by_cases hz : v.val = 0
  · refine ⟨hl, Or.inl (by simpa [← hv] using hz), ?_, ?_⟩ <;>
      simp [decodeAbiBool, bindExec, hd, hdw, hda, hz, pureExec]
  by_cases ho : v.val = 1
  · refine ⟨hl, Or.inr (by simpa [← hv] using ho), ?_, ?_⟩ <;>
      simp only [decodeAbiBool, exec_bind, bindExec, hd, hdw, hda, if_neg hz, if_pos ho, exec_pure, pureExec, List.nil_append]
  · simp [hz, ho, fail] at hb

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

theorem transfer_success (callee : External) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) (w : World) (h : (transferStage callee ctx stETH amount w).outcome = .ok ()) :
    TransferEffect callee ctx stETH amount w (transferStage callee ctx stETH amount w).world
      (transferStage callee ctx stETH amount w).attempts := by
  obtain ⟨data, hc, ht, hw, ha⟩ := bind_success _ _ _ _ h
  obtain ⟨b, hb, _, hbw, hba⟩ := bind_success _ _ _ _ ht
  obtain ⟨hl, hv, hbdw, hbda⟩ := bool_success _ _ _ hb
  obtain ⟨hcode, nested, hr, hat⟩ := call_success _ _ _ _ _ _ hc
  have finalw : (transferStage callee ctx stETH amount w).world =
      (callWithCalldata callee ctx stETH (stETHTransferFromCalldata ctx.sender ctx.self amount) 0 w).world := by
    exact hw.trans (hbw.trans (by simpa [pureExec] using hbdw))
  have finala : (transferStage callee ctx stETH amount w).attempts =
      (callWithCalldata callee ctx stETH (stETHTransferFromCalldata ctx.sender ctx.self amount) 0 w).attempts := by
    simp only [exec_bind, exec_pure] at ha hba
    simpa only [transferStage, exec_bind, exec_pure, hba, hbda, pureExec, List.append_nil] using ha
  exact ⟨hcode, data, nested, hl, hv, by simpa only [finalw] using hr,
    finala.trans hat⟩

theorem quote_success (quote : StaticExternal) (ctx : Context) (stETH : _root_.Verity.Address)
    (amount : Nat) (w : World) (shares : Uint256)
    (h : (quoteStage quote ctx stETH amount w).outcome = .ok shares) :
    QuoteEffect quote ctx stETH amount w shares (quoteStage quote ctx stETH amount w).attempts ∧
      (quoteStage quote ctx stETH amount w).world = w := by
  obtain ⟨data, hc, hd, hw, ha⟩ := bind_success _ _ _ _ h
  have hc0 : (w.core.codeSize stETH.val).val ≠ 0 := by
    intro hz
    simp [staticCallWithCalldata, hz] at hc
  cases hr : quote ⟨ctx.self, stETH, 0, stETHSharesCalldata amount⟩ w with
  | «error» e => simp [staticCallWithCalldata, hc0, hr] at hc
  | ok bytes =>
    simp only [staticCallWithCalldata, if_neg hc0, hr, Except.ok.injEq] at hc
    subst data
    simp only [staticCallWithCalldata, if_neg hc0, hr] at hd hw ha
    obtain ⟨hl, hv, hdw, hda⟩ := decode_success _ _ _ hd
    exact ⟨⟨hc0, bytes, hr, hl, hv, by simpa only [quoteStage, exec_bind, hda, List.append_nil] using ha⟩, hw.trans hdw⟩

/-- Complete necessary-success statement: both real call effects are connected
on one returned world, then the physical enqueue consumes that same world.
The only hypotheses of the public theorem are whole-program success. -/
def RequestEffect (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address)
    (id : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  100 ≤ amount ∧ amount ≤ 1000 * 10 ^ 18 ∧ amount < 2 ^ 128 ∧
    ∃ called shares transferAttempts quoteAttempts,
      TransferEffect callee ctx stETH amount before called transferAttempts ∧
      QuoteEffect quote ctx stETH amount called shares quoteAttempts ∧
      EnqueueEffect ctx (resolvedOwner ctx owner) amount (shares.val % 2 ^ 128) id before.core.blockTimestamp called after ∧
      attempts = transferAttempts ++ quoteAttempts

private theorem require_success (condition : Bool) (fault : Fault) (w : World)
    (h : (require condition fault w).outcome = .ok ()) :
    condition = true ∧ (require condition fault w).world = w ∧
      (require condition fault w).attempts = [] := by
  cases condition <;> simp [require, pureExec, fail] at h ⊢

theorem request_success (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address)
    (id : Nat) (w : World) (h : (request callee quote ctx stETH amount owner w).outcome = .ok id) :
    RequestEffect callee quote ctx stETH amount owner id w
      (request callee quote ctx stETH amount owner w).world
      (request callee quote ctx stETH amount owner w).attempts := by
  obtain ⟨u, hlo, h1, hw0, ha0⟩ := bind_success _ _ _ _ h
  cases u
  obtain ⟨hlo, hwl, hal⟩ := require_success _ _ _ hlo
  simp only [hwl] at h1 hw0 ha0
  obtain ⟨u, hhi, h2, hw1, ha1⟩ := bind_success _ _ _ _ h1
  cases u
  obtain ⟨hhi, hwh, hah⟩ := require_success _ _ _ hhi
  simp only [hwh] at h2 hw1 ha1
  obtain ⟨u, ht, h3, hw2, ha2⟩ := bind_success _ _ _ _ h2
  cases u
  obtain ⟨shares, hq, he, hw3, ha3⟩ := bind_success _ _ _ _ h3
  obtain ⟨hqe, hqw⟩ := quote_success _ _ _ _ _ _ hq
  simp only [hqw] at he hw3 ha3
  obtain ⟨hee, hea⟩ := enqueue_success _ _ _ _ _ _ _ he
  have hlow : 100 ≤ amount := of_decide_eq_true hlo
  have hhigh : amount ≤ 1000 * 10 ^ 18 := of_decide_eq_true hhi
  have hfit : amount < 2 ^ 128 := by omega
  refine ⟨hlow, hhigh, hfit, _, shares, _, _, transfer_success _ _ _ _ _ ht, hqe, ?_, ?_⟩
  · have finalw := hw0.trans (hw1.trans (hw2.trans hw3))
    change (request callee quote ctx stETH amount owner w).world = _ at finalw
    rw [finalw]
    simpa only [Nat.mod_eq_of_lt hfit] using hee
  · simp only [exec_bind] at ha0 ha1 ha2 ha3
    simpa only [request, exec_bind, ha1, ha2, ha3, hal, hah, hea, List.nil_append, List.append_nil] using ha0

theorem run_success (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address)
    (id : Nat) (w : World) (h : (runRequest callee quote ctx stETH amount owner w).outcome = .ok id) :
    RequestEffect callee quote ctx stETH amount owner id w
      (runRequest callee quote ctx stETH amount owner w).world
      (runRequest callee quote ctx stETH amount owner w).attempts := by
  unfold runRequest run at h ⊢
  cases he : (request callee quote ctx stETH amount owner w).outcome with
  | «error» e => simp [he] at h
  | ok n =>
    simp only [he] at h ⊢
    cases h
    exact request_success _ _ _ _ _ _ _ _ he

theorem run_failure_restores (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH : _root_.Verity.Address) (amount : Nat) (owner : _root_.Verity.Address)
    (w : World) (fault : Fault)
    (h : (runRequest callee quote ctx stETH amount owner w).outcome = .error fault) :
    (runRequest callee quote ctx stETH amount owner w).world = w := by
  unfold runRequest run at h ⊢
  cases he : (request callee quote ctx stETH amount owner w).outcome <;> simp_all

end LidoSRv3.Audit.Source.AddressRequestCalls
