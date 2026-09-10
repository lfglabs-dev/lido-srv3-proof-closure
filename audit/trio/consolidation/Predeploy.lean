import audit.trio.consolidation.LiveCall

/-!
# EIP-7251 consolidation-request predeploy body (frame from body)

The vault-hop theorems of `LiveCall.lean` quantify over an arbitrary callee
`External` and take the frame conditions `LogFrame` / `BalanceFrame` /
`Untraced` as explicit premises. This file is the concrete callee: an
executable body for the EIP-7251 consolidation-request predeploy
(`0x0000BBdDc7CE488642fb579F8B00f3a590007251`, the target of
`WithdrawalVaultEIP7685.sol:115`), and the frame conditions are *derived*
from that body instead of assumed.

Body (`ConsolidationRequestPredeploy`-shape, simplified):

* reject a request that is not exactly 96 octets
  (`sourcePubkey(48) ++ targetPubkey(48)`, the vault's line-114 payload);
* reject when `msg.value < currentFee` with the fee read from the fee slot
  of the credited world;
* otherwise append the request to the queue (three big-endian words per
  96-octet request), increment the accepted-request count, and return empty
  data. The predeploy commits no logs (the `ConsolidationRequestAdded` event
  is the vault's own line-120 emit) and moves no balances beyond the CALL's
  value transfer.

Residuals (stated, not claimed):

* The EIP-7251 fake-exponential per-block fee update is abstracted into the
  fee slot; the update rule itself remains OPEN.
* Excess/fee-on-excess accounting, the queue head/tail ring positions, and
  the source's exact revert data are not modeled; rejection is empty
  returndata.

Pin `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
P-CONSOLIDATION remains OPEN.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Current consolidation-request fee slot. The per-block fake-exponential
update is abstracted into this slot. -/
def predeployFeeSlot : Nat := 0

/-- Accepted-request count slot. -/
def predeployCountSlot : Nat := 1

/-- Queue base slot: request number `count` occupies the three consecutive
words `predeployQueueSlot + 3 * count, + 1, + 2`. -/
def predeployQueueSlot : Nat := 2

/-- Word `i` of a 96-octet request payload (big-endian 32-octet limbs). -/
def requestWord (payload : Bytes) (i : Nat) : Word :=
  word (decode ((payload.drop (32 * i)).take 32))

/-- Contract state after accepting request number `count`: the count write
and the three queue words retaining all 96 request octets. -/
def predeployAcceptCore (target : Nat) (payload : Bytes)
    (core : Verity.ContractState) : Verity.ContractState :=
  let count := (core.readContractSlot target predeployCountSlot).val
  let c1 := core.writeContractSlot target predeployCountSlot (word (count + 1))
  let c2 := c1.writeContractSlot target (predeployQueueSlot + 3 * count)
    (requestWord payload 0)
  let c3 := c2.writeContractSlot target (predeployQueueSlot + 3 * count + 1)
    (requestWord payload 1)
  c3.writeContractSlot target (predeployQueueSlot + 3 * count + 2)
    (requestWord payload 2)

/-- The concrete EIP-7251 callee body as a low-level-CALL `External`. The
incoming world is the CALL-credited world (the fee already moved). -/
def predeployBody : External := fun req w =>
  if req.payload.length ≠ 96 then .rejected []
  else if req.value.val < (w.core.readContractSlot req.target.val predeployFeeSlot).val then
    .rejected []
  else .success [] { w with core := predeployAcceptCore req.target.val req.payload w.core }

/-- Acceptance shape of the concrete body: on a 96-octet request funded at
the fee slot, the reply is empty data on the queue-extended world. -/
theorem predeployBody_accepted (req : Request) (w : World)
    (hlen : req.payload.length = 96)
    (hfee : (w.core.readContractSlot req.target.val predeployFeeSlot).val ≤ req.value.val) :
    predeployBody req w =
      .success [] { w with core := predeployAcceptCore req.target.val req.payload w.core } := by
  unfold predeployBody
  simp [hlen, Nat.not_lt.mpr hfee]

/-- Underpayment rejects before any queue or count write. -/
theorem predeployBody_underpaid (req : Request) (w : World)
    (hlen : req.payload.length = 96)
    (hfee : req.value.val < (w.core.readContractSlot req.target.val predeployFeeSlot).val) :
    predeployBody req w = .rejected [] := by
  unfold predeployBody
  simp [hlen, hfee]

/-- Malformed request width rejects. -/
theorem predeployBody_malformed (req : Request) (w : World)
    (hlen : req.payload.length ≠ 96) :
    predeployBody req w = .rejected [] := by
  unfold predeployBody
  simp [hlen]

/-- Accepted replies commit no logs: the body never touches `w.logs`.
Derived from the concrete body, not assumed. -/
theorem predeployBody_logFrame : LogFrame predeployBody := by
  intro req w data after h
  unfold predeployBody at h
  by_cases hlen : req.payload.length ≠ 96
  · rw [if_pos hlen] at h
    contradiction
  · by_cases hfee : req.value.val <
      (w.core.readContractSlot req.target.val predeployFeeSlot).val
    · rw [if_neg hlen, if_pos hfee] at h
      contradiction
    · rw [if_neg hlen, if_neg hfee] at h
      cases h
      rfl

/-- Accepted replies leave balances exactly as the CALL transfer credited
them: the body never touches `w.balances`. -/
theorem predeployBody_balanceFrame : BalanceFrame predeployBody := by
  intro req w data after h
  unfold predeployBody at h
  by_cases hlen : req.payload.length ≠ 96
  · rw [if_pos hlen] at h
    contradiction
  · by_cases hfee : req.value.val <
      (w.core.readContractSlot req.target.val predeployFeeSlot).val
    · rw [if_neg hlen, if_pos hfee] at h
      contradiction
    · rw [if_neg hlen, if_neg hfee] at h
      cases h
      rfl

/-- The concrete body is an untraced primitive: it never reports nested
calls. -/
theorem predeployBody_untraced : Untraced predeployBody := by
  intro req w data after nested h
  unfold predeployBody at h
  by_cases hlen : req.payload.length ≠ 96
  · rw [if_pos hlen] at h
    exact Reply.noConfusion h
  · by_cases hfee : req.value.val <
      (w.core.readContractSlot req.target.val predeployFeeSlot).val
    · rw [if_neg hlen, if_pos hfee] at h
      exact Reply.noConfusion h
    · rw [if_neg hlen, if_neg hfee] at h
      exact Reply.noConfusion h

/-- The concrete fee STATICCALL body: `staticcall("")` answers the 32-byte
big-endian encoding of the fee slot; any other payload reverts. -/
def predeployStaticBody : StaticCall.External := fun req w =>
  if req.payload = [] then
    .success (encode 32 (w.core.readContractSlot req.target.val predeployFeeSlot).val)
  else .rejected []

private theorem decode_fee_word (v : Word) :
    decode (encode 32 v.val) = v.val := by
  rw [ABI.decode_encode]
  have hpow : (256 : Nat) ^ 32 = Verity.Core.UINT256_MODULUS := by
    unfold Verity.Core.UINT256_MODULUS
    norm_num
  rw [hpow]
  exact Nat.mod_eq_of_lt v.isLt

/-- The vault's `_getFeeFromContract(CONSOLIDATION_REQUEST)`
(`WithdrawalVaultEIP7685.sol:79-95`) against the concrete predeploy body
returns the fee slot word: the line-84 `staticcall("")` succeeds with 32-byte
returndata, and the decode recovers the slot. -/
theorem predeploy_fee_read (ctx : Context) (inbox : Live.Address) (w : World)
    (hc : (w.core.codeSize inbox.val).val ≠ 0) :
    getConsolidationRequestFee predeployStaticBody ctx inbox w =
      ⟨.ok (w.core.readContractSlot inbox.val predeployFeeSlot), w, []⟩ := by
  have hcall : lowLevelStaticCall predeployStaticBody ctx.self inbox [] w =
      ⟨.ok (encode 32 (w.core.readContractSlot inbox.val predeployFeeSlot).val),
        [⟨⟨ctx.self, inbox, word 0, []⟩, true, true,
          encode 32 (w.core.readContractSlot inbox.val predeployFeeSlot).val, 1⟩]⟩ := by
    unfold lowLevelStaticCall predeployStaticBody
    simp [hc, Live.word, word]
  have hmain := feeRead_ok predeployStaticBody ctx inbox w
    (encode 32 (w.core.readContractSlot inbox.val predeployFeeSlot).val) _ hcall
    (ABI.encode_length 32 _)
  rw [decode_fee_word] at hmain
  have hw : Live.word (w.core.readContractSlot inbox.val predeployFeeSlot).val =
      w.core.readContractSlot inbox.val predeployFeeSlot := by
    apply Verity.Core.Uint256.ext
    simp [Live.word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus,
      Nat.mod_eq_of_lt (w.core.readContractSlot inbox.val predeployFeeSlot).isLt]
  rw [hw] at hmain
  exact hmain

/-- With the concrete predeploy on both hops, the vault entrypoint frame
needs no premises: the committed world logs are exactly the per-pair
`ConsolidationRequestAdded(source ++ target)` events in order, and the
ledger moved exactly `msg.value` from the vault to the predeploy. -/
theorem executeVault_success_frame_predeploy (ctx : Context)
    (gateway inbox : Live.Address) (msgValue : Live.Word)
    (sources targets : List Bytes) (before : World)
    (h : (executeVault predeployBody predeployStaticBody ctx gateway inbox msgValue sources
        targets before).outcome = .ok ()) :
    (executeVault predeployBody predeployStaticBody ctx gateway inbox msgValue sources
        targets before).world.logs =
        before.logs ++ (pairsOf sources targets).map
          (fun pair => requestAddedEvent ctx.self (vaultCallPayload pair)) ∧
      CallSpec.Balances before.balances
        (executeVault predeployBody predeployStaticBody ctx gateway inbox msgValue sources
          targets before).world.balances
        ctx.self inbox msgValue.val :=
  executeVault_success_frame predeployBody predeployStaticBody ctx gateway inbox msgValue
    sources targets before predeployBody_logFrame predeployBody_balanceFrame
    predeployBody_untraced h

end audit.trio.consolidation
