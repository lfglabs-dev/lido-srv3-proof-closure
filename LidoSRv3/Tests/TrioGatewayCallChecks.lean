import audit.trio.consolidation.GatewayCall
import audit.trio.consolidation.Predeploy

namespace LidoSRv3.Tests.TrioGatewayCallChecks

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

private def addr (n : Nat) : Address := Verity.Core.Address.ofNat n
private def gateway : Address := addr 0xB2
private def vault : Address := addr 0xA1
private def inbox : Address := addr 0xC3
private def sender : Address := addr 0xD4
private def recipient : Address := addr 0xE5
private def gatewayCtx : Context := ⟨gateway, sender⟩
private def vaultCtx : Context := ⟨vault, gateway⟩
private def selector : Bytes := [1, 2, 3, 4]
private def key (n : Nat) : Pubkey := ⟨n, 48⟩
private def groups : List WitnessGroup := [⟨[key 11, key 12], key 21⟩]

private def core : Verity.ContractState :=
  ({ Verity.defaultState with
      codeSize := fun a => if a = vault.val || a = inbox.val then Live.word 1 else Live.word 0 } :
    Verity.ContractState).writeContractSlot inbox.val predeployFeeSlot (Live.word 7)

/-- Gateway starts with the supplied payable value; the vault begins empty. -/
private def before : World := ⟨core, fun a => if a = gateway then 14 else 0, []⟩

private def accepting : External := fun _ w => .success [] w
private def feeStatic : StaticCall.External := fun _ _ => .success (encode 32 7)

/-- Positive fee: the real line-220 low-level CALL debits the gateway and
credits the vault before the vault consumes the same ABI calldata.  The vault
then pays both request fees to the inbox, leaving the gateway debited by 14. -/
example : (executeGatewayCall accepting feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).outcome =
    .ok (.committed
      { pairs := preparePairs groups, value := Live.word 14,
        payloads := (packedPayloads (preparePairs groups)).getD [] } none) := by
  native_decide

example : (executeGatewayCall accepting feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).world.balances gateway = 0 := by
  native_decide

example : (executeGatewayCall accepting feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).world.balances inbox = 14 := by
  native_decide

/-- The second request rejects.  The vault had already accepted the first
request, but the rejection bubbles through the gateway CALL and the root
transaction restores the original gateway world: neither gateway debit nor
vault/inbox credit survives. -/
private def rejectSecond : External := fun request w =>
  if request.payload = (hopSources (preparePairs groups)).getD 1 [] ++
      (hopTargets (preparePairs groups)).getD 1 [] then .rejected [0xEE]
  else .success [] w

example : (executeGatewayCall rejectSecond feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).outcome = .error (.bubbled []) := by
  native_decide

example : (executeGatewayCall rejectSecond feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).world = before := by
  exact executeGatewayCall_failure_restores rejectSecond feeStatic gatewayCtx vaultCtx vault inbox
    recipient selector (Live.word 14) (Live.word 7) groups before (.bubbled []) (by native_decide)

example : (executeGatewayCall rejectSecond feeStatic gatewayCtx vaultCtx vault inbox recipient selector
    (Live.word 14) (Live.word 7) groups before).world.balances vault = 0 ∧
    (executeGatewayCall rejectSecond feeStatic gatewayCtx vaultCtx vault inbox recipient selector
      (Live.word 14) (Live.word 7) groups before).world.balances inbox = 0 := by
  have hrestore := executeGatewayCall_failure_restores rejectSecond feeStatic gatewayCtx vaultCtx
    vault inbox recipient selector (Live.word 14) (Live.word 7) groups before (.bubbled [])
    (by native_decide)
  rw [hrestore]
  native_decide

end LidoSRv3.Tests.TrioGatewayCallChecks
