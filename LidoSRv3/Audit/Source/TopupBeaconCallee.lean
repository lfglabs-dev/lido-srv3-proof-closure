import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Source.TrioReserve1.CallData
import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! Source-shaped callee for the TOPUP deposit frame, core pin
17005714f151e5502c559932319a3f2f74ac2436, contracts/0.6.11/deposit_contract.sol:101–159.
SHA is explicit and instantiated with the existing opaque source SHA. This is
not a proof of SHA, generated ABI decoder, EVM execution or deployed identity.
The body has actual count/branch writes and event fields; no acceptance oracle.
-/
namespace LidoSRv3.Audit.Source.TopupBeaconCallee
open TrioReserve1 Live

abbrev Hash := List Nat → DepositDataRootCorrespondence.Sha256Digest

def selector : Nat := 0x22895118
def countSlot : Nat := 32
def maxCount : Nat := 2^32 - 1

structure Fields where
  pubkey : Bytes
  credentials : Bytes
  signature : Bytes
  suppliedRoot : Word
  deriving DecidableEq, Repr

/-- Bounds-check the dynamic offset/length before taking any payload bytes.
Offsets are relative to the argument head (after the four-byte selector).
Canonical source encodings are covered; full solc0.6.11 malformed-input
acceptance equivalence is not asserted. -/
def dynamicField (payload : Bytes) (headOffset : Nat) : Option Bytes := do
  if payload.length < 4 + headOffset + 32 then none else do
    let offset := decode ((payload.drop (4 + headOffset)).take 32)
    if payload.length < 4 + offset + 32 then none else do
      let size := decode ((payload.drop (4 + offset)).take 32)
      if payload.length < 4 + offset + 32 + size then none
      else some ((payload.drop (4 + offset + 32)).take size)

def decodePayload (payload : Bytes) : Option Fields := do
  if payload.length < 132 then none else do
    if decode (payload.take 4) ≠ selector then none else do
      let pk ← dynamicField payload 0
      let wc ← dynamicField payload 32
      let sig ← dynamicField payload 64
      pure ⟨pk, wc, sig, word (decode ((payload.drop 100).take 32))⟩

def little (n : Nat) : Bytes :=
  (List.range 8).map fun i => UInt8.ofNat (n / 256^i % 256)

/-- Independently transcribed callee hash chain: amount comes from msg.value,
not from a caller-selected gwei field. -/
def reconstructed (hash : Hash) (f : Fields) (value : Word) : Word :=
  let pk := hash (f.pubkey.map UInt8.toNat ++ List.replicate 16 0)
  let sig := hash ((hash ((f.signature.take 64).map UInt8.toNat)).bytes ++
    (hash ((f.signature.drop 64).map UInt8.toNat ++ List.replicate 32 0)).bytes)
  LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes (hash ((hash (pk.bytes ++ f.credentials.map UInt8.toNat)).bytes ++
    (hash ((little (value.val / 10^9)).map UInt8.toNat ++ List.replicate 24 0 ++ sig.bytes)).bytes)).bytes

/-- Event semantic fields, retaining EVERY byte. The five fixed widths on
accepted deposits are 48,32,8,96,8; this lossless word-per-octet representation
is not an assertion about LOG topics or dynamic ABI event-data encoding. -/
def depositEvent (target : Address) (f : Fields) (value : Word) (index : Nat) : Log :=
  ⟨target, "DepositEvent",
    (f.pubkey ++ f.credentials ++ little (value.val / 10^9) ++
      f.signature ++ little index).map (fun b => word b.toNat)⟩

/-- Binary-carry insertion performs the source loop, including its final
unreachable assertion branch. Fixed-array element height is physical slot
height; Solidity's count follows its 32 words. -/
def insert (hash : Hash) (target : Address) : Nat → Nat → Nat → Word → World → Option World
  | 0, _, _, _, _ => none
  | fuel+1, height, size, node, w =>
    if size % 2 = 1 then
      some {w with core := w.core.writeContractSlot target.val height node}
    else
      let previous := w.core.readContractSlot target.val height
      let next := LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes (hash ((encode 32 previous.val ++ encode 32 node.val).map UInt8.toNat)).bytes
      insert hash target fuel (height+1) (size/2) next w

/-- Error bytes are semantic reason identifiers (UTF8), not claimed solc
Error(string) returndata ABI. Revert outcome and state restoration are exact
in this source model. Event is emitted before root/tree-full checks. -/
def rejected (reason : String) : Reply := .rejected reason.toUTF8.toList

def deposit (hash : Hash) (f : Fields) (req : Request) (w : World) : Reply :=
  if f.pubkey.length ≠ 48 then rejected "invalid pubkey length"
  else if f.credentials.length ≠ 32 then rejected "invalid withdrawal_credentials length"
  else if f.signature.length ≠ 96 then rejected "invalid signature length"
  else if req.value.val < 10^18 then rejected "deposit value too low"
  else if req.value.val % 10^9 ≠ 0 then rejected "deposit value not multiple of gwei"
  else if 2^64 - 1 < req.value.val / 10^9 then rejected "deposit value too high"
  else
    let count := (w.core.readContractSlot req.target.val countSlot).val
    let emitted := {w with logs := w.logs ++ [depositEvent req.target f req.value count]}
    let node := reconstructed hash f req.value
    if node ≠ f.suppliedRoot then rejected "reconstructed root mismatch"
    else if maxCount ≤ count then rejected "merkle tree full"
    else
      let counted := {emitted with core := emitted.core.writeContractSlot req.target.val countSlot (word (count+1))}
      match insert hash req.target 32 0 (count+1) node counted with
      | none => rejected "unreachable tree assertion"
      | some after => .success [] after

/-- Unsupported target/selector/malformed payload is rejected, never delegated
to a name-based success stub. -/
def dispatch (hash : Hash) (target : Address) : External := fun req w =>
  if req.target ≠ target then rejected "unsupported target"
  else match decodePayload req.payload with
    | none => rejected "malformed deposit ABI"
    | some f => deposit hash f req w

/-- Read-only source callee proof: every actual branch write preserves account
balances and previously emitted logs. No frame premise on a callee reply. -/
theorem insert_frame (hash : Hash) (target : Address) (fuel height size : Nat)
    (node : Word) (w after : World)
    (h : insert hash target fuel height size node w = some after) :
    after.balances = w.balances ∧ after.logs = w.logs := by
  induction fuel generalizing height size node with
  | zero => simp [insert] at h
  | succ fuel ih =>
    simp only [insert] at h
    split at h
    · cases h; exact ⟨rfl, rfl⟩
    · exact ih _ _ _ h

/-- Source tree capacity ensures loop termination without assuming a
successful insertion or a post-count equation. -/
theorem insert_exists (hash : Hash) (target : Address) (fuel height size : Nat)
    (node : Word) (w : World) (hpos : 0 < size) (hbound : size < 2^fuel) :
    ∃ after, insert hash target fuel height size node w = some after := by
  induction fuel generalizing height size node with
  | zero => simp at hbound; omega
  | succ fuel ih =>
    unfold insert
    split
    · exact ⟨_, rfl⟩
    · rename_i heven
      have hp : 0 < size / 2 := by omega
      have hb : size / 2 < 2^fuel := by
        rw [Nat.pow_succ] at hbound
        omega
      exact ih _ _ _ hp hb

/-- Branch-loop footprint independently excludes the count slot. -/
theorem insert_count (hash : Hash) (target : Address) (fuel height size : Nat)
    (node : Word) (w after : World) (hheight : height + fuel ≤ 32)
    (h : insert hash target fuel height size node w = some after) :
    after.core.readContractSlot target.val countSlot = w.core.readContractSlot target.val countSlot := by
  induction fuel generalizing height size node with
  | zero => simp [insert] at h
  | succ fuel ih =>
    simp only [insert] at h
    split at h
    · cases h
      have hn : height ≠ countSlot := by unfold countSlot; omega
      by_cases ht : target.val = 0 <;> simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot, Verity.ContractState.writeSlot, Verity.ContractState.readSlot, Verity.ContractState.storage, Verity.ContractState.contractStorage, ht, Ne.symm hn]
    · exact ih _ _ _ (by omega) h

/-- The concrete deposit body has no balance writer on any successful path. -/
theorem deposit_balances (hash : Hash) (f : Fields) (req : Request)
    (w after : World) (data : Bytes) (h : deposit hash f req w = .success data after) :
    after.balances = w.balances := by
  unfold deposit at h
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  dsimp only at h
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  rename_i after' hi
  cases h
  exact (insert_frame _ _ _ _ _ _ _ _ hi).1

/-- Balance preservation is derived for this dispatcher, not supplied by its consumer. -/
theorem dispatch_balances (hash : Hash) (target : Address) (req : Request)
    (w after : World) (data : Bytes) (h : dispatch hash target req w = .success data after) :
    after.balances = w.balances := by
  unfold dispatch at h
  split at h
  · simp [rejected] at h
  · split at h
    · simp [rejected] at h
    · exact deposit_balances _ _ _ _ _ _ h

/-- Source fields retain the existing helper's computed root, independently
of the callee recomputation. -/
def sourceFields (input : DepositDataRootCorrespondence.SourceDepositDataRootInput) : Fields :=
  ⟨input.publicKey.map UInt8.ofNat, input.withdrawalCredentials.map UInt8.ofNat,
    input.signature.map UInt8.ofNat,
    LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
      (DepositDataRootCorrespondence.computeDepositDataRootWithAmount input).bytes⟩

theorem octets_roundtrip (xs : List Nat) (hb : ∀ b ∈ xs, b < 256) :
    (xs.map UInt8.ofNat).map UInt8.toNat = xs := by
  rw [List.map_map]
  conv_rhs => rw [← List.map_id xs]
  apply List.map_congr_left
  intro x hx
  simp [Nat.mod_eq_of_lt (hb x hx)]

/-- Independent callee hash chain equals the caller helper on the actual
same fields and msg.value. No supplied root-match parameter. -/
theorem reconstructed_source (input : DepositDataRootCorrespondence.SourceDepositDataRootInput)
    (value : Word) (hsig : input.signature.length = 96)
    (hamount : value.val / 10^9 = input.amountGwei) :
    reconstructed DepositDataRootCorrespondence.sha256 (sourceFields input) value =
      (sourceFields input).suppliedRoot := by
  have hp := octets_roundtrip input.publicKey input.publicKeyBounded
  have hw := octets_roundtrip input.withdrawalCredentials input.withdrawalCredentialsBounded
  have hs := octets_roundtrip input.signature input.signatureBounded
  have ht : (input.signature.drop 64).take 32 = input.signature.drop 64 := by
    apply List.take_of_length_le
    simp [hsig]
  have hl : (little (value.val / 10^9)).map UInt8.toNat =
      DepositDataRootCorrespondence.toLittleEndian64 input.amountGwei := by
    rw [hamount]
    simp [little, DepositDataRootCorrespondence.toLittleEndian64,
      DepositDataRootCorrespondence.sourceByteAt, List.map_map]
  unfold reconstructed sourceFields
  dsimp only
  rw [hp, hw, List.map_take, hs, List.map_drop, hs, hl]
  simp only [DepositDataRootCorrespondence.computeDepositDataRootWithAmount,
    DepositDataRootCorrespondence.concatDigests,
    DepositDataRootCorrespondence.signatureRoot,
    DepositDataRootCorrespondence.computeSignatureRoot, ht]

/-- A separately specified fold of OLD branch nodes below the changed slot. -/
def carryDigest (hash : Hash) (target : Address) (w : World)
    (height count : Nat) (node : Word) : Word :=
  (List.range' height count).foldl (fun acc position =>
    LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes (hash
      ((encode 32 (w.core.readContractSlot target.val position).val ++ encode 32 acc.val).map UInt8.toNat)).bytes) node

/-- Independent final-write statement: the loop updates exactly ONE branch
slot, and its value folds the corresponding original lower branch nodes.
No intermediate storage or balance conclusion is supplied. -/
theorem insert_footprint (hash : Hash) (target : Address) (fuel height size : Nat)
    (node : Word) (w after : World)
    (h : insert hash target fuel height size node w = some after) :
    ∃ skipped, skipped < fuel ∧
      after = {w with core := w.core.writeContractSlot target.val (height+skipped) (carryDigest hash target w height skipped node)} := by
  induction fuel generalizing height size node with
  | zero => simp [insert] at h
  | succ fuel ih =>
    simp only [insert] at h
    split at h
    · cases h
      exact ⟨0, by omega, by simp [carryDigest]⟩
    · obtain ⟨skipped, hs, ha⟩ := ih _ _ _ h
      refine ⟨skipped+1, by omega, ?_⟩
      simpa [carryDigest, List.range'_succ, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using ha

/-- The selected slot is the FIRST odd quotient of the incremented count.
This excludes a mutated implementation which writes the right digest to an
arbitrary branch slot. -/
theorem insert_selection (hash : Hash) (target : Address) (fuel height size : Nat)
    (node : Word) (w after : World)
    (h : insert hash target fuel height size node w = some after) :
    ∃ skipped, skipped < fuel ∧ size / 2^skipped % 2 = 1 ∧
      (∀ j < skipped, size / 2^j % 2 = 0) ∧
      after = {w with core := w.core.writeContractSlot target.val (height+skipped) (carryDigest hash target w height skipped node)} := by
  induction fuel generalizing height size node with
  | zero => simp [insert] at h
  | succ fuel ih =>
    simp only [insert] at h
    split at h
    · rename_i hodd
      cases h
      exact ⟨0, by omega, by simpa using hodd, by simp, by simp [carryDigest]⟩
    · rename_i heven
      obtain ⟨skipped, hs, hodd, hzero, ha⟩ := ih _ _ _ h
      have hdiv (j : Nat) : size / 2^(j+1) = size / 2 / 2^j := by
        rw [Nat.pow_succ, Nat.div_div_eq_div_mul, Nat.mul_comm (2^j) 2]
      refine ⟨skipped+1, by omega, ?_, ?_, ?_⟩
      · rw [hdiv]; exact hodd
      · intro j hj
        cases j with
        | zero => simp; omega
        | succ j => rw [hdiv]; exact hzero j (by omega)
      · simpa [carryDigest, List.range'_succ, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using ha

/-- Independent physical branch update after the count increment. -/
def BranchEffect (hash : Hash) (target : Address) (node : Word) (before after : World) : Prop :=
  let count := (before.core.readContractSlot target.val countSlot).val
  let counted := {before with core := before.core.writeContractSlot target.val countSlot (word (count+1))}
  ∃ skipped, skipped < 32 ∧ (count+1) / 2^skipped % 2 = 1 ∧
    (∀ j < skipped, (count+1) / 2^j % 2 = 0) ∧
    after.core = counted.core.writeContractSlot target.val skipped
      (carryDigest hash target counted 0 skipped node)

/-- Concrete source input is admitted by the full modeled body and produces
an incremented physical count and the exact source event, without assuming
execution success or callee balance preservation. -/
theorem source_deposit_success
    (input : DepositDataRootCorrespondence.SourceDepositDataRootInput)
    (req : Request) (w : World)
    (hpk : input.publicKey.length = 48)
    (hwc : input.withdrawalCredentials.length = 32)
    (hsig : input.signature.length = 96)
    (hmin : 10^18 ≤ req.value.val)
    (halign : req.value.val % 10^9 = 0)
    (hmax : req.value.val / 10^9 ≤ 2^64-1)
    (hamount : req.value.val / 10^9 = input.amountGwei)
    (hcount : (w.core.readContractSlot req.target.val countSlot).val < maxCount) :
    ∃ after, deposit DepositDataRootCorrespondence.sha256 (sourceFields input) req w =
        .success [] after ∧
      after.balances = w.balances ∧
      after.core.readContractSlot req.target.val countSlot =
        word ((w.core.readContractSlot req.target.val countSlot).val + 1) ∧
      after.logs = w.logs ++ [depositEvent req.target (sourceFields input) req.value
        (w.core.readContractSlot req.target.val countSlot).val] ∧
      BranchEffect DepositDataRootCorrespondence.sha256 req.target
        (reconstructed DepositDataRootCorrespondence.sha256 (sourceFields input) req.value) w after := by
  let count := (w.core.readContractSlot req.target.val countSlot).val
  let emitted := {w with logs := w.logs ++ [depositEvent req.target (sourceFields input) req.value count]}
  let counted := {emitted with core := emitted.core.writeContractSlot req.target.val countSlot (word (count+1))}
  have hb : count+1 < 2^32 := by unfold count maxCount at *; omega
  obtain ⟨after, hi⟩ := insert_exists DepositDataRootCorrespondence.sha256 req.target 32 0
    (count+1) (reconstructed DepositDataRootCorrespondence.sha256 (sourceFields input) req.value)
    counted (by omega) hb
  refine ⟨after, ?_, (insert_frame _ _ _ _ _ _ _ _ hi).1, ?_, (insert_frame _ _ _ _ _ _ _ _ hi).2, ?_⟩
  · have hpk' : (sourceFields input).pubkey.length = 48 := by simpa [sourceFields] using hpk
    have hwc' : (sourceFields input).credentials.length = 32 := by simpa [sourceFields] using hwc
    have hsig' : (sourceFields input).signature.length = 96 := by simpa [sourceFields] using hsig
    simp only [deposit, hpk', hwc', hsig', ne_eq, not_true_eq_false, if_false,
      Nat.not_lt.mpr hmin, halign, Nat.not_lt.mpr hmax]
    rw [if_neg (not_not_intro (reconstructed_source input req.value hsig hamount)),
      if_neg (Nat.not_le.mpr hcount)]
    change (match insert DepositDataRootCorrespondence.sha256 req.target 32 0 (count+1)
      (reconstructed DepositDataRootCorrespondence.sha256 (sourceFields input) req.value) counted with
      | none => rejected "unreachable tree assertion"
      | some after => .success [] after) = .success [] after
    rw [hi]
  · rw [insert_count _ _ _ _ _ _ _ _ (by decide) hi]
    exact Verity.ContractState.readContractSlot_writeContractSlot_same _ _ _ _
  · obtain ⟨skipped, hk, ho, hz, ha⟩ := insert_selection _ _ _ _ _ _ _ _ hi
    refine ⟨skipped, hk, ho, hz, ?_⟩
    simpa only [counted, emitted, count, carryDigest, Nat.zero_add] using congrArg World.core ha

end LidoSRv3.Audit.Source.TopupBeaconCallee
