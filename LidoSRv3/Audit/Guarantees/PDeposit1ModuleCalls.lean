import audit.trio.deposit.ModulePhysicalMetadata

namespace LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Source
open TrioReserve1
open TopupRouterCredentials (Keccak)
open audit.trio.deposit audit.trio.deposit.ModuleCall audit.trio.deposit.ModulePhysicalMetadata
set_option autoImplicit false

/-- Additional DEPOSIT consumer from an already computed typed allocation and
explicit CALL-buffer memory cursor. The actual zero-value module CALL supplies
raw bytes and its world; physical metadata updates that world, which the real
withdrawal/beacon suffix then consumes. Earlier allocation/admission, credential
provenance, cursor origin, memory copies/gas and immutable deployment identity
remain boundaries. This is not a full source-entrypoint claim. -/
theorem actual_module_call_metadata_suffix (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    ∃ c : Commitment hash m w ctx liveCtx i before after attempts,
      let address := moduleAddress hash liveCtx.sender i before
      let count := target hash liveCtx.sender i before
      let req : Live.Request := ⟨liveCtx.sender,address,Live.word 0,payload count i.depositCalldata⟩
      (before.core.codeSize address.val).val ≠ 0 ∧
      ((m req (Live.transfer before liveCtx.sender address 0) = .success c.raw c.moduleWorld ∧
         c.moduleTrace = [⟨req,true,c.raw,[]⟩]) ∨
       ∃ nested, m req (Live.transfer before liveCtx.sender address 0) = .successWithTrace c.raw c.moduleWorld nested ∧
         c.moduleTrace = [⟨req,true,c.raw,nested⟩]) ∧
      64 ≤ (Live.word c.raw.length).val ∧
      i.returnBuffer.val + (Live.word c.raw.length).val < 2^64 ∧
      c.data.publicKeys.length % 48 = 0 ∧
      c.prepared.values.actualKeys = c.data.publicKeys.length / 48 ∧
      c.prepared.values.actualKeys ≤ count ∧
      c.prepared.values.lidoPullWei = c.prepared.values.actualKeys*i.maxEB.val ∧
      c.prepared.values.lidoPullWei < 2^256 ∧
      let updated := PhysicalMetadata.update hash ctx liveCtx.sender c.prepared c.moduleWorld
      let key := PhysicalMetadata.moduleDepositSlot hash i.moduleId
      let packed := (updated.core.readContractSlot liveCtx.sender.val key).val
      (packed % 2^64 = c.moduleWorld.core.blockTimestamp.val % 2^64 ∧
       packed / 2^64 % 2^64 = c.moduleWorld.core.blockNumber.val % 2^64 ∧
       packed / 2^128 = (c.moduleWorld.core.readContractSlot liveCtx.sender.val key).val / 2^128) ∧
      updated.balances = c.moduleWorld.balances ∧
      updated.logs = c.moduleWorld.logs ++ [PhysicalMetadata.routerEvent liveCtx.sender c.prepared] ∧
      ((c.prepared.values.actualKeys = 0 ∧ after = updated ∧ c.suffixTrace = [] ∧ attempts = c.moduleTrace) ∨
       (c.prepared.values.actualKeys ≠ 0 ∧ Nonempty
         (LiveBeaconCommitted.SuffixCommitment w ctx liveCtx c.credentials c.prepared updated after c.suffixTrace))) :=
  ModulePhysicalMetadata.success_effects hash m w ctx liveCtx i before after attempts h

/-- Any failure, including allocator/ABI failure or a late actual beacon
failure, restores the entry world while retaining attempted-call observations. -/
theorem actual_module_call_failure_restores (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (fault : Live.Fault) (attempts : List Live.Attempt)
    (h : ModulePhysicalMetadata.execute hash m w ctx liveCtx i before = ⟨.error fault,after,attempts⟩) :
    after = before :=
  ModulePhysicalMetadata.failure_restores hash m w ctx liveCtx i before after fault attempts h

#print axioms actual_module_call_metadata_suffix
#print axioms actual_module_call_failure_restores
end LidoSRv3.Audit.Guarantees.PDeposit1
