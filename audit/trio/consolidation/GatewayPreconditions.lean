import audit.trio.consolidation.PhysicalEntrySettlement

/-! Typed static prefix of ConsolidationGateway.sol:201-203 at core17005714:
`_checkConsolidationPreconditions` (269-283) and `_getWithdrawalVaultData`
(368-379). The immutable `LOCATOR` is an input address. Each typed 0.8.25
view call is a return-valued STATICCALL without target-code precheck; the
caller's 32-byte returndata guard and the canonical address/bool validators
decide. A rejected callee forwards its bytes, a short or non-canonical reply
reverts empty. No world is written; the four static observations are kept.
Memory allocation extents of the reply copies are not modeled. -/
set_option autoImplicit false
namespace audit.trio.consolidation.GatewayPreconditions
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live

def depositSecurityModuleSelector : Nat := 0x472c1776
def lidoSelector : Nat := 0x23509a2d
def withdrawalVaultSelector : Nat := 0x69d42148
def isDepositsPausedSelector : Nat := 0x27042b84
def canDepositSelector : Nat := 0xe78a5875
/-- `DSMDepositsPaused()` (line 275). -/
def dsmPaused : Fault := .bubbled (encode 4 0xa37afd3f)
/-- `LidoDepositsPaused()` (line 281). -/
def lidoPaused : Fault := .bubbled (encode 4 0x5609c247)

/-- abi_decode address: the first returned word with canonical high bits;
trailing return data is ignored, fewer than 32 bytes revert empty. -/
def decodeAddress (raw : Bytes) : Except Fault Address :=
  if raw.length < 32 then .error .empty else
  let n := decode (raw.take 32)
  if h : n < Verity.Core.ADDRESS_MODULUS then .ok ⟨n,h⟩ else .error .empty

/-- abi_decode bool: the first returned word must be exactly 0 or 1. -/
def decodeBool (raw : Bytes) : Except Fault Bool :=
  if raw.length < 32 then .error .empty else
  let n := decode (raw.take 32)
  if n = 0 then .ok false else if n = 1 then .ok true else .error .empty

/-- A read-only stage: typed outcome and its static observations, no world. -/
structure Observed (α : Type) where
  outcome : Except Fault α
  attempts : List NestedAttempt

def request (caller target : Address) (selector : Nat) : Request :=
  ⟨caller,target,word 0,encode 4 selector⟩

/-- Return-valued typed STATICCALL: no code precheck (a code-less target
answers empty bytes and fails the decoder), callee bytes forwarded on failure. -/
def query {α : Type} (decoder : Bytes → Except Fault α) (sexternal : StaticCall.External)
    (caller target : Address) (selector : Nat) (w : World) : Observed α :=
  let r := lowLevelStaticCall sexternal caller target (encode 4 selector) w
  match r.outcome with
  | .error data => ⟨.error (.bubbled data),r.attempts⟩
  | .ok raw => ⟨decoder raw,r.attempts⟩

theorem query_success {α : Type} (decoder : Bytes → Except Fault α)
    (sexternal : StaticCall.External) (caller target : Address) (selector : Nat)
    (w : World) (a : α)
    (h : (query decoder sexternal caller target selector w).outcome = .ok a) :
    ∃ raw, lowLevelStaticCall sexternal caller target (encode 4 selector) w =
        ⟨.ok raw,[⟨request caller target selector,true,true,raw,1⟩]⟩ ∧
      decoder raw = .ok a ∧
      query decoder sexternal caller target selector w =
        ⟨.ok a,[⟨request caller target selector,true,true,raw,1⟩]⟩ := by
  rcases lowLevelStaticCall_shape sexternal caller target (encode 4 selector) w with
    ⟨_,he⟩ | ⟨_,⟨raw,_,he⟩ | ⟨data,_,he⟩ | ⟨_,he⟩⟩
  · have hd : decoder [] = .ok a := by simpa [query,he] using h
    exact ⟨[],he,hd,by simp [query,he,hd,request]⟩
  · have hd : decoder raw = .ok a := by simpa [query,he] using h
    exact ⟨raw,he,hd,by simp [query,he,hd,request]⟩
  · simp [query,he] at h
  · simp [query,he] at h

/-- Lines 269-283 in source order: DSM address from the locator, its pause
flag, the Lido address from the locator, its `canDeposit`. -/
def preconditions (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (w : World) : Observed Unit :=
  let d := query decodeAddress sexternal ctx.self locator depositSecurityModuleSelector w
  match d.outcome with
  | .error f => ⟨.error f,d.attempts⟩
  | .ok dsm =>
    let p := query decodeBool sexternal ctx.self dsm isDepositsPausedSelector w
    match p.outcome with
    | .error f => ⟨.error f,d.attempts ++ p.attempts⟩
    | .ok true => ⟨.error dsmPaused,d.attempts ++ p.attempts⟩
    | .ok false =>
      let l := query decodeAddress sexternal ctx.self locator lidoSelector w
      match l.outcome with
      | .error f => ⟨.error f,d.attempts ++ p.attempts ++ l.attempts⟩
      | .ok lido =>
        let c := query decodeBool sexternal ctx.self lido canDepositSelector w
        match c.outcome with
        | .error f => ⟨.error f,d.attempts ++ p.attempts ++ l.attempts ++ c.attempts⟩
        | .ok false => ⟨.error lidoPaused,d.attempts ++ p.attempts ++ l.attempts ++ c.attempts⟩
        | .ok true => ⟨.ok (),d.attempts ++ p.attempts ++ l.attempts ++ c.attempts⟩

/-- Admission derives four successful static observations: the decoded DSM
answered `isDepositsPaused() = false` and the decoded Lido answered
`canDeposit() = true`, each on the entry world. -/
theorem preconditions_success (sexternal : StaticCall.External) (ctx : Context)
    (locator : Address) (w : World)
    (h : (preconditions sexternal ctx locator w).outcome = .ok ()) :
    ∃ dsm lido rawDsm rawPaused rawLido rawCan,
      lowLevelStaticCall sexternal ctx.self locator (encode 4 depositSecurityModuleSelector) w =
        ⟨.ok rawDsm,[⟨request ctx.self locator depositSecurityModuleSelector,true,true,rawDsm,1⟩]⟩ ∧
      decodeAddress rawDsm = .ok dsm ∧
      lowLevelStaticCall sexternal ctx.self dsm (encode 4 isDepositsPausedSelector) w =
        ⟨.ok rawPaused,[⟨request ctx.self dsm isDepositsPausedSelector,true,true,rawPaused,1⟩]⟩ ∧
      decodeBool rawPaused = .ok false ∧
      lowLevelStaticCall sexternal ctx.self locator (encode 4 lidoSelector) w =
        ⟨.ok rawLido,[⟨request ctx.self locator lidoSelector,true,true,rawLido,1⟩]⟩ ∧
      decodeAddress rawLido = .ok lido ∧
      lowLevelStaticCall sexternal ctx.self lido (encode 4 canDepositSelector) w =
        ⟨.ok rawCan,[⟨request ctx.self lido canDepositSelector,true,true,rawCan,1⟩]⟩ ∧
      decodeBool rawCan = .ok true ∧
      (preconditions sexternal ctx locator w).attempts =
        [⟨request ctx.self locator depositSecurityModuleSelector,true,true,rawDsm,1⟩,
         ⟨request ctx.self dsm isDepositsPausedSelector,true,true,rawPaused,1⟩,
         ⟨request ctx.self locator lidoSelector,true,true,rawLido,1⟩,
         ⟨request ctx.self lido canDepositSelector,true,true,rawCan,1⟩] := by
  unfold preconditions at h ⊢
  try dsimp only at h ⊢
  cases hd : (query decodeAddress sexternal ctx.self locator depositSecurityModuleSelector w).outcome with
  | «error» f => simp [hd] at h
  | ok dsm =>
    obtain ⟨rawDsm,hc1,hd1,hq1⟩ := query_success _ _ _ _ _ _ _ hd
    simp only [hq1] at h ⊢
    cases hp : (query decodeBool sexternal ctx.self dsm isDepositsPausedSelector w).outcome with
    | «error» f => simp [hp] at h
    | ok paused =>
      obtain ⟨rawPaused,hc2,hd2,hq2⟩ := query_success _ _ _ _ _ _ _ hp
      simp only [hq2] at h ⊢
      cases paused with
      | true => simp at h
      | false =>
        try dsimp only at h ⊢
        cases hl : (query decodeAddress sexternal ctx.self locator lidoSelector w).outcome with
        | «error» f => simp [hl] at h
        | ok lido =>
          obtain ⟨rawLido,hc3,hd3,hq3⟩ := query_success _ _ _ _ _ _ _ hl
          simp only [hq3] at h ⊢
          cases hcan : (query decodeBool sexternal ctx.self lido canDepositSelector w).outcome with
          | «error» f => simp [hcan] at h
          | ok can =>
            obtain ⟨rawCan,hc4,hd4,hq4⟩ := query_success _ _ _ _ _ _ _ hcan
            simp only [hq4] at h ⊢
            cases can with
            | false => simp at h
            | true =>
              try dsimp only at h ⊢
              exact ⟨dsm,lido,rawDsm,rawPaused,rawLido,rawCan,hc1,hd1,hc2,hd2,hc3,hd3,hc4,hd4,rfl⟩

/-- `COMPOUNDING_PREFIX = uint256(0x02) << 248` (line 105). -/
def compoundingPrefix : Nat := 0x02 <<< 248

/-- Line 378: `bytes32(COMPOUNDING_PREFIX | uint160(vaultAddress))`. -/
def credentials (vault : Address) : Word := word (compoundingPrefix ||| vault.val)

/-- Lines 368-379: the configured vault read from the locator. Its 0x02
credentials are `credentials vault`. -/
def vaultData (sexternal : StaticCall.External) (ctx : Context) (locator : Address)
    (w : World) : Observed Address :=
  query decodeAddress sexternal ctx.self locator withdrawalVaultSelector w

theorem vaultData_success (sexternal : StaticCall.External) (ctx : Context)
    (locator : Address) (w : World) (vault : Address)
    (h : (vaultData sexternal ctx locator w).outcome = .ok vault) :
    ∃ raw, lowLevelStaticCall sexternal ctx.self locator (encode 4 withdrawalVaultSelector) w =
        ⟨.ok raw,[⟨request ctx.self locator withdrawalVaultSelector,true,true,raw,1⟩]⟩ ∧
      decodeAddress raw = .ok vault ∧ 32 ≤ raw.length ∧ vault.val = decode (raw.take 32) ∧
      (vaultData sexternal ctx locator w).attempts =
        [⟨request ctx.self locator withdrawalVaultSelector,true,true,raw,1⟩] := by
  obtain ⟨raw,hc,hd,hq⟩ := query_success _ _ _ _ _ _ _ h
  refine ⟨raw,hc,hd,?_,?_,by simp [vaultData,hq]⟩
  · unfold decodeAddress at hd
    split at hd
    · contradiction
    · omega
  · unfold decodeAddress at hd
    split at hd
    · contradiction
    · try dsimp only at hd
      split at hd
      · cases hd; rfl
      · contradiction

#print axioms query_success
#print axioms preconditions_success
#print axioms vaultData_success
end audit.trio.consolidation.GatewayPreconditions
