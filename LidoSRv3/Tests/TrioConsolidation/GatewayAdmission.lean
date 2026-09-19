import LidoSRv3.Audit.Guarantees.PConsolidation1WitnessAdmission
import LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement

/-! Kernel regressions for the gateway's DSM/locator prefix and the pure parts
of the witness check. The SHA-bearing stages (slot pair, leaf, fold) execute
the opaque engine FFI and are covered by the theorems, not by kernel
evaluation, as for the compiled CL entry. -/
namespace LidoSRv3.Tests.TrioConsolidation.GatewayAdmission
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
open audit.trio.consolidation.GatewayPreconditions
open ConsolidationSettlementRegression
open LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement (uniform)
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000

/-- Admitted role/balance/pause storage with code everywhere except 999. -/
def admitted : World :=
  {uniform 2 2 6 with core := {(uniform 2 2 6).core with
    codeSize := fun a => if a = 999 then Live.word 0 else Live.word 1}}
def locator : Address := addr 500
def dsm : Address := addr 600
def lido : Address := addr 700

/-- A locator answering the three getters; DSM/Lido flags are parameters. -/
def locatorReplies (paused canDeposit : Nat) : StaticCall.External := fun r _ =>
  if r.target = locator ∧ r.payload = encode 4 depositSecurityModuleSelector then .success (encode 32 600)
  else if r.target = locator ∧ r.payload = encode 4 lidoSelector then .success (encode 32 700)
  else if r.target = locator ∧ r.payload = encode 4 withdrawalVaultSelector then .success (encode 32 200)
  else if r.target = dsm ∧ r.payload = encode 4 isDepositsPausedSelector then .success (encode 32 paused)
  else if r.target = lido ∧ r.payload = encode 4 canDepositSelector then .success (encode 32 canDeposit)
  else .rejected [0xfa]

def prefixOf (s : StaticCall.External) :=
  GatewayAdmission.entryPrefix s ctx locator (Live.word 6) groups admitted

theorem prefix_admits_vault :
    ((prefixOf (locatorReplies 0 1)).outcome,(prefixOf (locatorReplies 0 1)).attempts.length) =
      (.ok (addr 200),5) := by decide +kernel
theorem dsm_paused_after_two_reads :
    ((prefixOf (locatorReplies 1 1)).outcome,(prefixOf (locatorReplies 1 1)).attempts.length) =
      (.error dsmPaused,2) := by decide +kernel
theorem lido_paused_after_four_reads :
    ((prefixOf (locatorReplies 0 0)).outcome,(prefixOf (locatorReplies 0 0)).attempts.length) =
      (.error lidoPaused,4) := by decide +kernel
theorem non_boolean_flag_rejected :
    (prefixOf (locatorReplies 2 1)).outcome = .error .empty := by decide +kernel
theorem short_locator_reply_rejected :
    (prefixOf (fun _ _ => .success (encode 31 600))).outcome = .error .empty := by decide +kernel
theorem non_canonical_address_rejected :
    (prefixOf (fun _ _ => .success (encode 32 (2^160 + 600)))).outcome = .error .empty := by
  decide +kernel
theorem rejected_locator_forwards_bytes :
    (prefixOf (fun _ _ => .rejected [0xab,0xcd])).outcome = .error (.bubbled [0xab,0xcd]) := by
  decide +kernel
/-- A code-less locator answers empty bytes; the 32-byte guard rejects them. -/
theorem code_less_locator_typed_decode_failure :
    (GatewayAdmission.entryPrefix (locatorReplies 0 1) ctx (addr 999) (Live.word 6) groups admitted).outcome =
      .error .empty := by decide +kernel
/-- The pure guards precede the DSM read: no group means no locator call. -/
theorem empty_groups_before_dsm :
    ((GatewayAdmission.entryPrefix (locatorReplies 1 1) ctx locator (Live.word 6) [] admitted).outcome,
      (GatewayAdmission.entryPrefix (locatorReplies 1 1) ctx locator (Live.word 6) [] admitted).attempts) =
      (.error (.bubbled (GatewayCall.errorBytes 0x56e42893 "groups".toUTF8.toList)),[]) := by
  decide +kernel
theorem role_before_dsm :
    (GatewayAdmission.entryPrefix (locatorReplies 1 1) ctx locator (Live.word 6) groups (uniform 0 0 6)).outcome =
      .error (.bubbled (PhysicalEntrySettlement.unauthorized ctx.sender)) := by decide +kernel

/-- A DSM pause restores the entry world before any witness or quota work. -/
def witnessGroups : List WitnessProof.WitnessGroup :=
  [⟨[List.replicate 48 1],⟨[],List.replicate 48 2,EvmYul.UInt256.ofNat 0,0,0,0⟩⟩]
theorem witness_executor_dsm_pause_restores :
    let r := GatewayWitnessAdmission.execute (dispatch refundAccept) (locatorReplies 1 1) ctx locator
      (addr 100) (addr 300) (addr 400) (Audit.Source.SszWrapperIndex.pinnedConfiguration ⟨0,by decide⟩)
      (Live.word 6) witnessGroups admitted
    (r.outcome,r.trace.length,r.vault,r.suffix.isNone,
      decide (r.world.core.readContractSlot 100 PhysicalQuotaSettlement.position =
        admitted.core.readContractSlot 100 PhysicalQuotaSettlement.position),
      r.world.balances (addr 100)) =
      ((Except.error dsmPaused : Except Fault Unit),2,(none : Option Address),true,true,6) := by
  decide +kernel

theorem credentials_is_compounding_prefix_or_vault :
    WitnessProof.credentialsWord (addr 0xabc) = EvmYul.UInt256.ofNat (2^249 + 0xabc) := by decide +kernel

/-- The gateway index of validator 1234 at slot 100 on the pinned configuration:
the P-SSZ-1 state-root/validator index (1430 * 2^40 + 1234) descended below
the pubkey/credentials parent (4 at depth 2), depth 2. -/
def witness1234 : WitnessProof.ValidatorWitness :=
  ⟨[],List.replicate 48 2,EvmYul.UInt256.ofNat 1234,0,100,0⟩
theorem gateway_index_pinned :
    WitnessProof.gatewayIndex (Audit.Source.SszWrapperIndex.pinnedConfiguration ⟨0,by decide⟩) witness1234 =
      .ok ⟨⟨(1430 * 2^40 + 1234) * 4,by decide⟩,⟨2,by decide⟩⟩ := by decide +kernel
theorem gateway_index_out_of_range :
    WitnessProof.gatewayIndex (Audit.Source.SszWrapperIndex.pinnedConfiguration ⟨0,by decide⟩)
      {witness1234 with validatorIndex := EvmYul.UInt256.ofNat (2^40)} = .error WitnessProof.indexOutOfRange := by
  decide +kernel

theorem root_decoder :
    WitnessProof.decodeRoot (.error [0x01]) = .error WitnessProof.rootNotFound ∧
    WitnessProof.decodeRoot (.ok []) = .error WitnessProof.rootNotFound ∧
    WitnessProof.decodeRoot (.ok (List.replicate 31 7)) = .error .empty ∧
    WitnessProof.decodeRoot (.ok (encode 32 5 ++ [9])) = .ok (EvmYul.UInt256.ofNat 5) := by decide +kernel

theorem pubkey_length_guard :
    WitnessProof.pubkeyRoot (List.replicate 47 1) = .error WitnessProof.invalidPubkeyLength := by
  decide +kernel

end LidoSRv3.Tests.TrioConsolidation.GatewayAdmission
