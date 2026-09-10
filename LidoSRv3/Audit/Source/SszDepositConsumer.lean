import LidoSRv3.Audit.Source.TopupBeaconEffects

/-! The deposit ABI consumer of SSZ-1. Source pin 17005714f151e5502c559932319a3f2f74ac2436,
BeaconChainDepositor.sol:110–153 and deposit_contract.sol:101–159.
The input below is reconstructed from the fields the concrete callee decoded
and its actual CALL value. It is never a separately supplied root-helper input.
The existing decoder's malformed-input boundary is unchanged. -/
namespace LidoSRv3.Audit.Source.SszDepositConsumer
open TrioReserve1 Live TopupBeaconCallee
open DepositDataRootCorrespondence (SourceDepositDataRootInput)

/-- A byte-valued decoded frame determines all four helper arguments. -/
def consumedInput (f : Fields) (value : Word) : SourceDepositDataRootInput where
  withdrawalCredentials := f.credentials.map UInt8.toNat
  publicKey := f.pubkey.map UInt8.toNat
  signature := f.signature.map UInt8.toNat
  amountGwei := value.val / 10^9
  withdrawalCredentialsBounded := by
    intro b hb; obtain ⟨x, _, rfl⟩ := List.mem_map.mp hb; exact x.toNat_lt
  publicKeyBounded := by
    intro b hb; obtain ⟨x, _, rfl⟩ := List.mem_map.mp hb; exact x.toNat_lt
  signatureBounded := by
    intro b hb; obtain ⟨x, _, rfl⟩ := List.mem_map.mp hb; exact x.toNat_lt
  amountGweiBounded := lt_of_le_of_lt (Nat.div_le_self _ _) value.isLt

/-- Independent caller-helper and callee preimage chains agree forward on
the consumed fields. No hash injectivity or root-match premise is used. -/
theorem reconstructed_consumed (f : Fields) (value : Word)
    (hsig : f.signature.length = 96) :
    reconstructed DepositDataRootCorrespondence.sha256 f value =
      LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
        (DepositDataRootCorrespondence.computeDepositDataRootWithAmount
          (consumedInput f value)).bytes := by
  have ht : ((f.signature.map UInt8.toNat).drop 64).take 32 =
      (f.signature.map UInt8.toNat).drop 64 := by
    apply List.take_of_length_le
    simp [hsig]
  have hl : (little (value.val / 10^9)).map UInt8.toNat =
      DepositDataRootCorrespondence.toLittleEndian64 (value.val / 10^9) := by
    simp [little, DepositDataRootCorrespondence.toLittleEndian64,
      DepositDataRootCorrespondence.sourceByteAt, List.map_map]
  simp only [reconstructed, DepositDataRootCorrespondence.computeDepositDataRootWithAmount,
    consumedInput, DepositDataRootCorrespondence.concatDigests,
    DepositDataRootCorrespondence.signatureRoot,
    DepositDataRootCorrespondence.computeSignatureRoot, List.map_take, List.map_drop, ht, hl]

/-- Necessary success derives the actual widths, uint64 amount and supplied
root from the source guard sequence and hash comparison. -/
theorem deposit_success_consumed (f : Fields) (req : Request)
    (before after : World) (data : Live.Bytes)
    (h : deposit DepositDataRootCorrespondence.sha256 f req before = .success data after) :
    f.pubkey.length = 48 ∧ f.credentials.length = 32 ∧ f.signature.length = 96 ∧
    (consumedInput f req.value).amountGwei < 2^64 ∧ req.value.val % 10^9 = 0 ∧
    f.suppliedRoot = LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
      (DepositDataRootCorrespondence.computeDepositDataRootWithAmount
        (consumedInput f req.value)).bytes := by
  unfold deposit at h
  split at h <;> try { simp [rejected] at h }
  rename_i hpk
  split at h <;> try { simp [rejected] at h }
  rename_i hwc
  split at h <;> try { simp [rejected] at h }
  rename_i hsig
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  rename_i hmod
  split at h <;> try { simp [rejected] at h }
  rename_i hamount
  dsimp only at h
  split at h <;> try { simp [rejected] at h }
  rename_i hroot
  refine ⟨by omega, by omega, by omega, ?_, by omega, ?_⟩
  · change req.value.val / 10^9 < 2^64
    omega
  · rw [← reconstructed_consumed f req.value (by omega)]
    exact (not_ne_iff.mp hroot).symm

/-- The dispatcher consumes this exact payload's decoded bytes and CALL value.
This is an ABI-facing necessary result, not an unused serialization adapter. -/
theorem dispatch_success_consumed (target : Address) (req : Request)
    (before after : World) (data : Live.Bytes)
    (h : dispatch DepositDataRootCorrespondence.sha256 target req before = .success data after) :
    req.target = target ∧ ∃ f,
      decodePayload req.payload = some f ∧
      f.pubkey.length = 48 ∧ f.credentials.length = 32 ∧ f.signature.length = 96 ∧
      (consumedInput f req.value).amountGwei < 2^64 ∧ req.value.val % 10^9 = 0 ∧
      f.suppliedRoot = LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
        (DepositDataRootCorrespondence.computeDepositDataRootWithAmount
          (consumedInput f req.value)).bytes := by
  unfold dispatch at h
  split at h
  · simp [rejected] at h
  · rename_i ht
    split at h
    · simp [rejected] at h
    · rename_i f hf
      exact ⟨not_ne_iff.mp ht, f, hf, deposit_success_consumed _ _ _ _ _ h⟩

/-- The real CALL wrapper consumes the dispatcher result after its provisional
value transfer. No caller-selected input or root equality is a premise. -/
theorem push_success_consumed (ctx : Context) (target : Address)
    (payload : Live.Bytes) (amount : Word) (before after : World) (data : Live.Bytes)
    (trace : List Attempt)
    (h : TopupBeaconEffects.push DepositDataRootCorrespondence.sha256
      ctx target payload amount before = ⟨.ok data, after, trace⟩) :
    ∃ f, decodePayload payload = some f ∧
      f.pubkey.length = 48 ∧ f.credentials.length = 32 ∧ f.signature.length = 96 ∧
      (consumedInput f amount).amountGwei < 2^64 ∧ amount.val % 10^9 = 0 ∧
      f.suppliedRoot = LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
        (DepositDataRootCorrespondence.computeDepositDataRootWithAmount
          (consumedInput f amount)).bytes := by
  unfold TopupBeaconEffects.push CallData.invoke at h
  dsimp only at h
  split at h
  · simp at h
  · split at h
    · simp at h
    · split at h
      · simp at h
      · rename_i data' w' hr
        exact (dispatch_success_consumed _ _ _ _ _ hr).2
      · rename_i data' w' nested hr
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

#print axioms reconstructed_consumed
#print axioms deposit_success_consumed
#print axioms dispatch_success_consumed
#print axioms push_success_consumed
end LidoSRv3.Audit.Source.SszDepositConsumer
