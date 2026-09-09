import LidoSRv3.Audit.Source.TopupBeaconCallee
import LidoSRv3.Audit.Source.TrioReserve1.CallFlow

namespace LidoSRv3.Audit.Source.TopupBeaconEffects
open TrioReserve1 Live TopupBeaconCallee
open LidoSRv3.Audit.Verity.TopupTx

/-- The journal's distinguished selector occupies FOUR bytes. Every argument
word occupies 32 bytes. No validator IDs or synthetic amounts replace bytes. -/
def serialize : List Word → Bytes
  | [] => []
  | selectorWord :: args => encode 4 selectorWord.val ++ args.flatMap (fun w => encode 32 w.val)

def sourcePayload (input : DepositDataRootCorrespondence.SourceDepositDataRootInput) : Bytes :=
  serialize (sourceBeaconCalldata input)

/-- Executable deposit CALL in the same physical World, using the complete
serialized source byte payload and the concrete source callee dispatcher. -/
def push (hash : Hash) (ctx : Context) (target : Address) (payload : Bytes)
    (amount : Word) : Exec Bytes :=
  CallData.invoke (dispatch hash target) ctx target payload amount

/-- Root rollback around a list of actual payload/value calls; a later failure
restores earlier callee storage, events and transferred balances together. -/
def loop (hash : Hash) (ctx : Context) (target : Address) : List (Bytes × Word) → Exec Unit
  | [] => pure ()
  | (payload,amount) :: rest => do
    let _ ← push hash ctx target payload amount
    loop hash ctx target rest

def execute (hash : Hash) (ctx : Context) (target : Address)
    (calls : List (Bytes × Word)) (before : World) : Result Unit :=
  Live.run (loop hash ctx target calls) before

/-- The independent ledger relation covers all accounts, including sender =
recipient. Every callee successful path preserves the provisional balances
by proof of its body, so no balance/frame premise is supplied here. -/
theorem success_balances (hash : Hash) (ctx : Context) (target : Address)
    (payload : Bytes) (amount : Word) (before after : World) (data : Bytes)
    (attempts : List Attempt)
    (h : push hash ctx target payload amount before = ⟨.ok data, after, attempts⟩) :
    CallSpec.Balances before.balances after.balances ctx.self target amount.val := by
  unfold push CallData.invoke at h
  dsimp only at h
  split at h
  · simp at h
  · split at h
    · simp at h
    · rename_i hc hf
      have hfunds : amount.val ≤ before.balances ctx.self := by omega
      split at h
      · simp at h
      · rename_i data' w' hr
        cases h
        rw [dispatch_balances _ _ _ _ _ _ hr]
        exact CallFlow.transfer_balances _ _ _ _ hfunds
      · rename_i data' w' nested hr
        -- This concrete dispatcher never returns a traced success.
        unfold dispatch at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        unfold deposit at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        dsimp only at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }

      · simp at h

/-- Root error restores the entire World, not only its ledger projection. -/
theorem failure_restores (hash : Hash) (ctx : Context) (target : Address)
    (calls : List (Bytes × Word)) (before : World) (fault : Fault)
    (h : (execute hash ctx target calls before).outcome = .error fault) :
    (execute hash ctx target calls before).world = before := by
  unfold execute Live.run at *
  dsimp only at *
  split <;> simp_all

/-- Reverse byte encoding is derived for arbitrary byte values. -/
theorem encode_decode_bytes (bytes : Bytes) : encode bytes.length (decode bytes) = bytes := by
  induction bytes using List.reverseRecOn with
  | nil => rfl
  | append_singleton bytes b ih =>
    rw [List.length_append, List.length_singleton, ABI.decode_append_byte, ABI.encode_succ]
    have hb : b.toNat < 256 := b.toNat_lt
    have hd : (decode bytes * 256 + b.toNat) / 256 = decode bytes := by omega
    have hm : (decode bytes * 256 + b.toNat) % 256 = b.toNat := by omega
    rw [hd, hm, ih]
    simp

theorem encode_mod (size n : Nat) : encode size (n % 256^size) = encode size n := by
  have h := encode_decode_bytes (encode size n)
  simpa only [ABI.encode_length, ABI.decode_encode] using h

/-- A canonical argument word survives its exact-width byte serialization. -/
theorem decode_serialized_word (w : Word) : decode (encode 32 w.val) = w.val :=
  ABI.decode_encode_bounded 32 w.val (by change w.val < Verity.Core.UINT256_MODULUS; exact w.isLt)

theorem decode_zeros (bs : Bytes) (n : Nat) :
    decode (bs ++ List.replicate n (0 : UInt8)) = decode bs * 256^n := by
  induction n with
  | zero => simp [decode]
  | succ n ih =>
    rw [List.replicate_succ', ← List.append_assoc, ABI.decode_append_byte, ih]
    simp [Nat.pow_succ, Nat.mul_assoc]

/-- The helper's positional ABI word packs the actual bytes; exact octet
bounds discharge the ofNat conversion, and trailing padding is explicit. -/
theorem encode_abiWord (xs : List Nat) (hb : ∀ b ∈ xs, b < 256) :
    encode 32 (abiWordOfBytes xs).val =
      (xs.take 32).map UInt8.ofNat ++ List.replicate (32-(xs.take 32).length) 0 := by
  let bs := (xs.take 32).map UInt8.ofNat
  have he : decode bs = sourceByteCommitment (xs.take 32) := by
    have hr := octets_roundtrip (xs.take 32) (fun b h => hb b (List.mem_of_mem_take h))
    have hf : decode bs = sourceByteCommitment (bs.map UInt8.toNat) := by
      simp [decode, sourceByteCommitment, List.foldl_map]
    rw [hf, hr]
  have hl : (bs ++ List.replicate (32-(xs.take 32).length) 0).length = 32 := by
    simp only [List.length_append, List.length_map, List.length_replicate, bs]
    have := List.length_take_le 32 xs
    omega
  have hd := decode_zeros bs (32-(xs.take 32).length)
  have hre := encode_decode_bytes (bs ++ List.replicate (32-(xs.take 32).length) 0)
  rw [hl, hd, he] at hre
  unfold abiWordOfBytes
  change encode 32 ((sourceByteCommitment (xs.take 32) * 256^(32-(xs.take 32).length)) % (2^256)) = _
  rw [show 2^256 = 256^32 by decide, encode_mod]
  exact hre

/-- Canonical ABI constructed independently from the journal representation. -/
def canonicalPayload (f : Fields) : Bytes :=
  encode 4 selector ++ encode 32 128 ++ encode 32 224 ++ encode 32 288 ++
    encode 32 f.suppliedRoot.val ++ encode 32 48 ++ f.pubkey ++ List.replicate 16 0 ++
    encode 32 32 ++ f.credentials ++ encode 32 96 ++ f.signature

theorem tail32 (xs : List Nat) (hl : xs.length = 32) (hb : ∀ b ∈ xs, b < 256) :
    (abiBytesTail xs).flatMap (fun w => encode 32 w.val) =
      encode 32 32 ++ xs.map UInt8.ofNat := by
  simp only [abiBytesTail, abiByteWords, hl]
  change encode 32 32 ++ (encode 32 (abiWordOfBytes xs).val ++ []) = _
  rw [encode_abiWord xs hb]
  simp [List.take_of_length_le (by omega : xs.length ≤ 32), hl]

theorem tail48 (xs : List Nat) (hl : xs.length = 48) (hb : ∀ b ∈ xs, b < 256) :
    (abiBytesTail xs).flatMap (fun w => encode 32 w.val) =
      encode 32 48 ++ xs.map UInt8.ofNat ++ List.replicate 16 0 := by
  simp only [abiBytesTail, abiByteWords, hl]
  change encode 32 48 ++ (encode 32 (abiWordOfBytes xs).val ++
    (encode 32 (abiWordOfBytes (xs.drop 32)).val ++ [])) = _
  rw [encode_abiWord xs hb, encode_abiWord (xs.drop 32) (fun b h => hb b (List.mem_of_mem_drop h))]
  have ht : (xs.drop 32).take 32 = xs.drop 32 := List.take_of_length_le (by simp [hl])
  simp only [ht, List.length_take, List.length_drop, hl]
  norm_num only [Nat.min_eq_left (by omega : 32 ≤ 48), Nat.reduceSub,
    List.replicate_zero, List.append_nil]
  rw [List.append_assoc, ← List.append_assoc (xs.take 32 |>.map UInt8.ofNat),
    ← List.map_append, List.take_append_drop]

theorem tail96 (xs : List Nat) (hl : xs.length = 96) (hb : ∀ b ∈ xs, b < 256) :
    (abiBytesTail xs).flatMap (fun w => encode 32 w.val) =
      encode 32 96 ++ xs.map UInt8.ofNat := by
  simp only [abiBytesTail, abiByteWords, hl]
  change encode 32 96 ++ (encode 32 (abiWordOfBytes xs).val ++
    (encode 32 (abiWordOfBytes (xs.drop 32)).val ++
    (encode 32 (abiWordOfBytes (xs.drop 64)).val ++ []))) = _
  rw [encode_abiWord xs hb,
    encode_abiWord (xs.drop 32) (fun b h => hb b (List.mem_of_mem_drop h)),
    encode_abiWord (xs.drop 64) (fun b h => hb b (List.mem_of_mem_drop h))]
  have hlast : (xs.drop 64).take 32 = xs.drop 64 := List.take_of_length_le (by simp [hl])
  simp only [hlast, List.length_take, List.length_drop, hl]
  norm_num only [Nat.min_eq_left (by omega : 32 ≤ 96),
    Nat.min_eq_left (by omega : 32 ≤ 64), Nat.reduceSub,
    List.replicate_zero, List.append_nil]
  have hs : xs.drop 64 = (xs.drop 32).drop 32 := by rw [List.drop_drop]
  rw [hs, ← List.map_append, List.take_append_drop,
    ← List.map_append, List.take_append_drop]

/-- Universal actual-byte bridge for the existing source journal, including
all pubkey/signature bytes and the helper-computed bytes32 root. -/
theorem sourcePayload_eq (input : DepositDataRootCorrespondence.SourceDepositDataRootInput)
    (hpk : input.publicKey.length = 48) (hwc : input.withdrawalCredentials.length = 32)
    (hsig : input.signature.length = 96) :
    sourcePayload input = canonicalPayload (sourceFields input) := by
  have hp := tail48 input.publicKey hpk input.publicKeyBounded
  have hw := tail32 input.withdrawalCredentials hwc input.withdrawalCredentialsBounded
  have hs := tail96 input.signature hsig input.signatureBounded
  have hpl : (abiBytesTail input.publicKey).length = 3 := by simp [abiBytesTail, abiByteWords, hpk]
  have hwl : (abiBytesTail input.withdrawalCredentials).length = 2 := by simp [abiBytesTail, abiByteWords, hwc]
  simp only [sourcePayload, sourceBeaconCalldata, hpl, hwl, serialize,
    List.flatMap_append, List.flatMap_cons, List.cons_append, List.nil_append]
  change encode 4 selector ++
    (encode 32 128 ++ encode 32 224 ++ encode 32 288 ++
      encode 32 (sourceFields input).suppliedRoot.val ++
      (abiBytesTail input.publicKey).flatMap (fun w => encode 32 w.val) ++
      (abiBytesTail input.withdrawalCredentials).flatMap (fun w => encode 32 w.val) ++
      (abiBytesTail input.signature).flatMap (fun w => encode 32 w.val)) = _
  rw [hp, hw, hs]
  simp [canonicalPayload, sourceFields, List.append_assoc]

/-- Decoder consumes the independently encoded canonical call. All three
byte arrays are recovered, not merely their lengths or commitments. -/
theorem decode_canonical (f : Fields) (hpk : f.pubkey.length = 48)
    (hwc : f.credentials.length = 32) (hsig : f.signature.length = 96) :
    decodePayload (canonicalPayload f) = some f := by
  have hv : f.suppliedRoot.val < 2^256 := f.suppliedRoot.isLt
  norm_num only [Nat.reducePow] at hv
  simp [decodePayload, dynamicField, canonicalPayload, List.append_assoc,
    ABI.encode_length, List.length_append, hpk, hwc, hsig,
    List.drop_append, ABI.decode_encode, selector,
    List.take_of_length_le,
    word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus,
    Verity.Core.UINT256_MODULUS, Nat.mod_eq_of_lt hv, List.drop_eq_nil_of_le]

/-- Existing source journal bytes decode to the existing source fields/root. -/
theorem decode_sourcePayload (input : DepositDataRootCorrespondence.SourceDepositDataRootInput)
    (hpk : input.publicKey.length = 48) (hwc : input.withdrawalCredentials.length = 32)
    (hsig : input.signature.length = 96) :
    decodePayload (sourcePayload input) = some (sourceFields input) := by
  rw [sourcePayload_eq input hpk hwc hsig]
  exact decode_canonical _ (by simpa [sourceFields] using hpk)
    (by simpa [sourceFields] using hwc) (by simpa [sourceFields] using hsig)

set_option maxRecDepth 2048 in
/-- Concrete source deposit CALL succeeds from physical code/funds and actual
source fields, and proves both sides of the ETH transfer, count and event.
No successful callee response, balance frame or root-match premise. -/
theorem source_push_success
    (input : DepositDataRootCorrespondence.SourceDepositDataRootInput)
    (ctx : Context) (target : Address) (amount : Word) (before : World)
    (hpk : input.publicKey.length = 48) (hwc : input.withdrawalCredentials.length = 32)
    (hsig : input.signature.length = 96)
    (hmin : 10^18 ≤ amount.val) (halign : amount.val % 10^9 = 0)
    (hmax : amount.val / 10^9 ≤ 2^64-1)
    (hamount : amount.val / 10^9 = input.amountGwei)
    (hcount : (before.core.readContractSlot target.val countSlot).val < maxCount)
    (hcode : (before.core.codeSize target.val).val ≠ 0)
    (hfunds : amount.val ≤ before.balances ctx.self) :
    ∃ after, push DepositDataRootCorrespondence.sha256 ctx target (sourcePayload input) amount before =
        ⟨.ok [], after, [⟨⟨ctx.self, target, amount, sourcePayload input⟩, true, [], []⟩]⟩ ∧
      CallSpec.Balances before.balances after.balances ctx.self target amount.val ∧
      after.core.readContractSlot target.val countSlot =
        word ((before.core.readContractSlot target.val countSlot).val+1) ∧
      after.logs = before.logs ++ [depositEvent target (sourceFields input) amount
        (before.core.readContractSlot target.val countSlot).val] ∧
      BranchEffect DepositDataRootCorrespondence.sha256 target
        (reconstructed DepositDataRootCorrespondence.sha256 (sourceFields input) amount) before after := by
  let req : Request := ⟨ctx.self,target,amount,sourcePayload input⟩
  obtain ⟨after, hd, _hb, hc, hl, hbranch⟩ := source_deposit_success input req
    (transfer before ctx.self target amount.val) hpk hwc hsig hmin halign hmax hamount hcount
  have he : push DepositDataRootCorrespondence.sha256 ctx target (sourcePayload input) amount before =
      ⟨.ok [], after, [⟨req, true, [], []⟩]⟩ := by
    unfold push CallData.invoke
    simp only [hcode, if_false, Nat.not_lt.mpr hfunds]
    have hd' : dispatch DepositDataRootCorrespondence.sha256 target req
        (transfer before ctx.self target amount.val) = .success [] after := by
      unfold dispatch
      change (if target ≠ target then rejected "unsupported target"
        else match decodePayload (sourcePayload input) with
          | none => rejected "malformed deposit ABI"
          | some f => deposit DepositDataRootCorrespondence.sha256 f req
            (transfer before ctx.self target amount.val)) = .success [] after
      rw [if_neg (not_not_intro rfl), decode_sourcePayload input hpk hwc hsig]
      exact hd
    change (match dispatch DepositDataRootCorrespondence.sha256 target req
      (transfer before ctx.self target amount.val) with
      | .rejected data => _ | .success data after => _
      | .successWithTrace data after nested => _ | .rejectedWithTrace data nested => _) = _
    rw [hd']
  exact ⟨after, he, success_balances _ _ _ _ _ _ _ _ _ he, hc, hl, hbranch⟩

end LidoSRv3.Audit.Source.TopupBeaconEffects
