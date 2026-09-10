import audit.trio.deposit.PhysicalMetadata
import LidoSRv3.Audit.Source.TopupModuleCall

/-! Additional DEPOSIT suffix at core@17005714, StakingRouter.sol:950–976.
`Input.selected` is the already computed allocation. Earlier getDepositableEther,
ALLOC, admission, credentials/config provenance and immutable deployment identity
remain boundaries. Address and uint64 cap are read from the entry physical world.

The inherited ordinary-no-code CALL arm excludes precompile dispatch.
The raw dual-bytes decoder follows pinned solc 0.8.25: head bound, first offset,
first bytes length/allocation/extent, then second offset/bytes. Aliased, unaligned,
reversed and unpadded tails are allowed. It executes the scalar uint256/uint64
allocator guards from an explicit phase cursor, including the initial raw-return
allocation. The cursor origin, memory-copy correctness and opcode gas remain
boundaries. No general compiler memory/gas equivalence is claimed. -/
namespace audit.trio.deposit.ModuleCall
set_option autoImplicit false
open LidoSRv3.Audit.Source
open TrioReserve1 Live
open TopupRouterCredentials (Keccak)

structure Input where
  moduleId : TrioAlloc1.Word
  selected : TrioAlloc1.Word
  maxEB : TrioAlloc1.Word
  depositCalldata : Live.Bytes
  /-- Actual free-memory pointer at the module CALL buffer, supplied by the
  earlier memory phase. Not a fixed initial-memory assumption. -/
  returnBuffer : Live.Word

/-- The uint64 third field of ModuleState.deposits at mapping slot + 1. -/
def packedCap (hash : Keccak) (router : Live.Address) (i : Input) (w : Live.World) : Nat :=
  (w.core.readContractSlot router.val (PhysicalMetadata.moduleDepositSlot hash i.moduleId)).val / 2^128 % 2^64

def moduleAddress (hash : Keccak) (router : Live.Address) (i : Input) (w : Live.World) : Live.Address :=
  TopupModuleCall.moduleAddress hash router (Live.word i.moduleId.val) w

def target (hash : Keccak) (router : Live.Address) (i : Input) (w : Live.World) : Nat :=
  min (packedCap hash router i w) (i.selected.val / i.maxEB.val)

/-- Selector of obtainDepositData(uint256,bytes), followed by a two-word head
and the length-prefixed, zero-padded calldata tail. -/
def payload (count : Nat) (data : Live.Bytes) : Live.Bytes :=
  Live.encode 4 0xbee41b58 ++ Live.encode 32 count ++ Live.encode 32 64 ++
    Live.encode 32 data.length ++ data ++ List.replicate ((32 - data.length % 32) % 32) 0

/-- `address` and `count` are captured by the caller before the CALL. -/
def call (callee : Live.External) (router address : Live.Address) (count : Nat)
    (data : Live.Bytes) : Live.Exec Live.Bytes :=
  audit.trio.consolidation.lowLevelCall callee ⟨router,router⟩ address (payload count data) (Live.word 0)

theorem call_success_origin (callee : Live.External) (router address : Live.Address)
    (count : Nat) (data : Live.Bytes) (before after : Live.World) (raw : Live.Bytes)
    (trace : List Live.Attempt)
    (h : call callee router address count data before = ⟨.ok raw,after,trace⟩) :
    let req : Live.Request := ⟨router,address,Live.word 0,payload count data⟩
    ((before.core.codeSize address.val).val = 0 ∧ raw = [] ∧
      after = Live.transfer before router address 0 ∧ trace = [⟨req,true,[],[]⟩]) ∨
    ((before.core.codeSize address.val).val ≠ 0 ∧
      ((callee req (Live.transfer before router address 0) = .success raw after ∧
        trace = [⟨req,true,raw,[]⟩]) ∨
       ∃ nested, callee req (Live.transfer before router address 0) = .successWithTrace raw after nested ∧
         trace = [⟨req,true,raw,nested⟩])) := by
  unfold call audit.trio.consolidation.lowLevelCall at h
  simp only [Live.word, Verity.Core.Uint256.val_ofNat, Nat.zero_mod, Nat.not_lt_zero, if_false] at h
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

theorem call_no_code (callee : Live.External) (router address : Live.Address)
    (count : Nat) (data : Live.Bytes) (before : Live.World)
    (hc : (before.core.codeSize address.val).val = 0) :
    call callee router address count data before =
      ⟨.ok [], Live.transfer before router address 0,
        [⟨⟨router,address,Live.word 0,payload count data⟩,true,[],[]⟩]⟩ := by
  simp [call,audit.trio.consolidation.lowLevelCall,hc,Live.word]

/-- Yul round_up_to_mul_of_32: wrapping ADD before the low-bit mask. -/
def round32 (size : Nat) : Nat := ((size + 31) % 2^256) / 32 * 32

/-- The exact scalar guards of solc finalize_allocation, including uint256
addition wrap and the pointer-dependent uint64 ceiling. No bound is assumed. -/
def finalizeAllocation (cursor : Live.Word) (size : Nat) : Except Live.Fault Live.Word :=
  let next := Live.word (cursor.val + round32 size)
  if next.val ≥ 2^64 ∨ next.val < cursor.val then .error (.reason "Panic(0x41)")
  else .ok next

/-- EVM signed comparison of 256-bit words. -/
def signed (w : Live.Word) : Int :=
  if w.val < 2^255 then Int.ofNat w.val else Int.ofNat w.val - 2^256

def signedLt (a b : Live.Word) : Bool := signed a < signed b

theorem finalizeAllocation_ok (cursor next : Live.Word) (size : Nat)
    (h : finalizeAllocation cursor size = .ok next) :
    next.val < 2^64 ∧ cursor.val ≤ next.val ∧
      next = Live.word (cursor.val + round32 size) := by
  unfold finalizeAllocation at h
  dsimp only at h
  split at h
  · cases h
  · rename_i hg
    cases h
    exact ⟨by omega,by omega,rfl⟩

/-- The signed head guard rules out the high-bit/near-2^256 size cases that
an allocator check alone cannot rule out. Together they derive the small,
nonwrapping copied range, rather than assuming an extra size bound. -/
theorem return_size_bounds (cursor size next : Live.Word)
    (ha : finalizeAllocation cursor size.val = .ok next)
    (hh : signedLt size (Live.word 64) = false) :
    64 ≤ size.val ∧ cursor.val + size.val ≤ next.val ∧ next.val < 2^64 := by
  obtain ⟨hn,hc,he⟩ := finalizeAllocation_ok cursor next size.val ha
  have hsize : 64 ≤ size.val ∧ size.val < 2^255 := by
    have hh : (64 : Int) ≤ signed size := by
      have hn := of_decide_eq_false hh
      change ¬ signed size < 64 at hn
      omega
    by_cases hs : size.val < 2^255
    · simp only [signed,hs,if_true,Int.ofNat_eq_natCast] at hh
      exact ⟨by omega,hs⟩
    · simp only [signed,hs,if_false,Int.ofNat_eq_natCast] at hh
      have hb := size.isLt
      change size.val < 2^256 at hb
      omega
  have hr : size.val + 31 < 2^256 := by omega
  have hsum : cursor.val + (size.val + 31) / 32 * 32 < 2^256 := by omega
  have hv : next.val = cursor.val + (size.val + 31) / 32 * 32 := by
    rw [he]
    simp only [Live.word,Verity.Core.Uint256.val_ofNat,round32,
      Nat.mod_eq_of_lt hr]
    exact Nat.mod_eq_of_lt hsum
  exact ⟨hsize.1,by omega,hn⟩

/-- Execute the compiler's absolute-pointer signed length-word bound and
unsigned payload bound. `raw` backs the copied returndata beginning at `base`;
all pointer arithmetic is uint256, including `end` and the head subtraction. -/
def decodeBytes (raw : Live.Bytes) (base dataEnd : Live.Word)
    (offset : Nat) (cursor : Live.Word) : Except Live.Fault (Live.Bytes × Live.Word) := do
  if offset ≥ 2^64 then .error .empty else
  let location := Live.word (base.val + offset)
  if !signedLt (Live.word (location.val + 31)) dataEnd then .error .empty else
  let length := Live.decode ((raw.drop offset).take 32)
  if length ≥ 2^64 then .error (.reason "Panic(0x41)") else
  let next ← finalizeAllocation cursor (32 + round32 length)
  if (Live.word (location.val + 32 + length)).val > dataEnd.val then .error .empty else
  .ok (((raw.drop (offset+32)).take length),next)

structure Data where
  publicKeys : Live.Bytes
  signatures : Live.Bytes
  deriving DecidableEq, Repr

/-- The compiler's uint256 ADD followed by SUB recovers returndatasize even
when ADD wrapped. No raw-length admission premise is used. -/
theorem end_sub_base (base size : Live.Word) :
    Live.word ((Live.word (base.val + size.val)).val + 2^256 - base.val) = size := by
  have hb := base.isLt
  have hs := size.isLt
  apply Verity.Core.Uint256.ext
  simp only [Live.word,Verity.Core.Uint256.val_ofNat]
  change ((base.val + size.val) % 2^256 + 2^256 - base.val) % 2^256 = size.val
  change base.val < 2^256 at hb
  change size.val < 2^256 at hs
  omega

/-- `cursor` is the actual phase input at the CALL buffer. Successful return
first reserves the raw return buffer, then allocates the first and second
bytes sequentially. This models the allocator's scalar guards, not memory
copy correctness, opcode gas, or the earlier derivation of the phase cursor. -/
def decodeReturn (cursor : Live.Word) (raw : Live.Bytes) : Except Live.Fault (Data × Live.Word) :=
  let rawSize := Live.word raw.length
  match finalizeAllocation cursor rawSize.val with
  | .error fault => .error fault
  | .ok rawCursor =>
    let dataEnd := Live.word (cursor.val + rawSize.val)
    let size := Live.word (dataEnd.val + 2^256 - cursor.val)
    if signedLt size (Live.word 64) then .error .empty else
    match decodeBytes raw cursor dataEnd (Live.decode (raw.take 32)) rawCursor with
    | .error fault => .error fault
    | .ok (publicKeys,keyCursor) =>
      match decodeBytes raw cursor dataEnd (Live.decode ((raw.drop 32).take 32)) keyCursor with
      | .error fault => .error fault
      | .ok (signatures,next) => .ok (⟨publicKeys,signatures⟩,next)

theorem decode_empty (cursor : Live.Word) :
    ∃ fault, decodeReturn cursor [] = .error fault := by
  cases h : finalizeAllocation cursor 0 with
  | «error» e =>
    refine ⟨e,?_⟩
    unfold decodeReturn
    dsimp only
    rw [show (Live.word ([] : Live.Bytes).length).val = 0 from rfl,h]
  | ok next =>
    refine ⟨.empty,?_⟩
    unfold decodeReturn
    dsimp only
    rw [show (Live.word ([] : Live.Bytes).length).val = 0 from rfl,h]
    have hs := end_sub_base cursor (Live.word 0)
    simp only [show (Live.word 0).val = 0 from rfl] at hs
    rw [hs]
    rfl

/-- Successful full decoding derives a bounded copied returndata range from
executed allocator + signed guards. The EVM size is the uint256 projection of
the host byte-list length; oversized host lists get no invented admission rule. -/
theorem decodeReturn_size_bounds (cursor next : Live.Word) (raw : Live.Bytes) (data : Data)
    (h : decodeReturn cursor raw = .ok (data,next)) :
    64 ≤ (Live.word raw.length).val ∧
    cursor.val + (Live.word raw.length).val < 2^64 := by
  cases ha : finalizeAllocation cursor (Live.word raw.length).val with
  | «error» e => simp only [decodeReturn,ha] at h; cases h
  | ok rawCursor =>
    have hh : signedLt (Live.word raw.length) (Live.word 64) = false := by
      cases hs : signedLt (Live.word raw.length) (Live.word 64) with
      | false => rfl
      | true =>
        simp only [decodeReturn,ha,end_sub_base,hs,ite_true] at h
        cases h
    obtain ⟨hs,hle,hn⟩ := return_size_bounds cursor (Live.word raw.length) rawCursor ha hh
    exact ⟨hs,by omega⟩

/-- Only a fixture/serialization utility; execution never invents a reply. -/
def encodeReturn (keys signatures : Live.Bytes) : Live.Bytes :=
  let pad (bytes : Live.Bytes) := bytes ++ List.replicate ((32 - bytes.length % 32) % 32) 0
  Live.encode 32 64 ++ Live.encode 32 (96 + (pad keys).length) ++
    Live.encode 32 keys.length ++ pad keys ++ Live.encode 32 signatures.length ++ pad signatures

/-- A decoded CALL necessarily ran the arbitrary coded callee, rather than
succeeding through the ordinary-no-code empty-return rule. -/
theorem decoded_call_origin (callee : Live.External) (router address : Live.Address)
    (count : Nat) (data : Live.Bytes) (before after : Live.World) (raw : Live.Bytes)
    (trace : List Live.Attempt) (decoded : Data) (cursor next : Live.Word)
    (hc : call callee router address count data before = ⟨.ok raw,after,trace⟩)
    (hd : decodeReturn cursor raw = .ok (decoded,next)) :
    (before.core.codeSize address.val).val ≠ 0 ∧
    let req : Live.Request := ⟨router,address,Live.word 0,payload count data⟩
    ((callee req (Live.transfer before router address 0) = .success raw after ∧
      trace = [⟨req,true,raw,[]⟩]) ∨
     ∃ nested, callee req (Live.transfer before router address 0) = .successWithTrace raw after nested ∧
       trace = [⟨req,true,raw,nested⟩]) := by
  rcases call_success_origin callee router address count data before after raw trace hc with h | h
  · obtain ⟨_,rfl,_,_⟩ := h
    obtain ⟨fault,hf⟩ := decode_empty cursor
    rw [hf] at hd
    cases hd
  · exact h

def sourceBytes (bytes : Live.Bytes) : TrioAlloc1.Bytes :=
  bytes.map (fun b => ⟨b.toNat, b.toNat_lt⟩)

def prepare (i : Input) (count : Nat) (data : Data) : Except Live.Fault PreparedDeposit :=
  if data.publicKeys.length % 48 ≠ 0 then .error (.reason "WrongPubkeyLength") else
  let actual := data.publicKeys.length / 48
  if actual > count then .error (.reason "ModuleReturnExceedTarget") else
  if actual * i.maxEB.val ≥ 2^256 then .error (.reason "Panic(0x11)") else
  .ok ⟨i.moduleId,i.maxEB,⟨sourceBytes data.publicKeys,sourceBytes data.signatures⟩,
    ⟨i.selected.val,actual,actual*i.maxEB.val,DEPOSIT_SIZE,actual*DEPOSIT_SIZE⟩⟩

theorem prepare_values (i : Input) (count : Nat) (data : Data) (prepared : PreparedDeposit)
    (h : prepare i count data = .ok prepared) :
    data.publicKeys.length % 48 = 0 ∧
    prepared.moduleId = i.moduleId ∧ prepared.maxEBType1 = i.maxEB ∧
    prepared.moduleData = ⟨sourceBytes data.publicKeys,sourceBytes data.signatures⟩ ∧
    prepared.values.selectedAllocationWei = i.selected.val ∧
    prepared.values.actualKeys = data.publicKeys.length / 48 ∧
    prepared.values.actualKeys ≤ count ∧
    prepared.values.lidoPullWei = prepared.values.actualKeys*i.maxEB.val ∧
    prepared.values.lidoPullWei < 2^256 ∧
    prepared.values.beaconPerKeyWei = DEPOSIT_SIZE ∧
    prepared.values.beaconTotalWei = prepared.values.actualKeys*DEPOSIT_SIZE := by
  unfold prepare at h
  split at h
  · cases h
  · rename_i halign
    dsimp only at h
    split at h
    · cases h
    · rename_i hcount
      split at h
      · cases h
      · rename_i hvalue
        cases h
        dsimp only
        exact ⟨by omega,rfl,rfl,rfl,rfl,rfl,by omega,rfl,by omega,rfl,rfl⟩

#print axioms call_success_origin
#print axioms decoded_call_origin
#print axioms prepare_values
#print axioms return_size_bounds
#print axioms decodeReturn_size_bounds
end audit.trio.deposit.ModuleCall
