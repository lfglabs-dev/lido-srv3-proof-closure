import audit.trio.consolidation.Composition

/-!
# Root ConsolidationGateway → WithdrawalVault call

This is the missing transaction boundary for `ConsolidationGateway.sol:220` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

```
withdrawalVault.addConsolidationRequests{value: totalFee}(
    sourcePubkeys, targetPubkeys
);
```

`gatewayProgram` deliberately uses `lowLevelCall`, rather than passing a
precomputed `VaultHop` into the vault.  Consequently the gateway is debited
and the vault is credited by the CALL rule *before* `executeVaultCalldata`
consumes the very same ABI arguments.  The whole program is put under
`Live.run`; a rejected vault call (including a late rejection by the vault)
therefore bubbles as the low-level CALL failure and restores the original
gateway world.  `World` contains all modeled state (core, balances, logs), so
this also restores any modeled gateway state.

The selector is intentionally a parameter: keccak of the Solidity signature
is not modeled by this audit lane.  P-CONSOLIDATION remains OPEN.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- A failed source-level vault entrypoint becomes the failed return of the
gateway's low-level CALL.  The low-level rule preserves this returndata as a
`Fault.bubbled`; this bounded component uses empty revert data because the
vault model's faults are names, not ABI-encoded revert bytes. -/
def vaultCalldataExternal (callee : External) (sexternal : StaticCall.External)
    (vaultCtx : Context) (gateway inbox : Address) (fee : Word) (selector calldata : Bytes) :
    External := fun _ credited =>
  let r := executeVaultCalldata callee sexternal vaultCtx gateway inbox fee selector calldata credited
  match r.outcome with
  | .ok _ => .success [] r.world
  | .error _ => .rejected []

/-- The actual line-220 request, including its ABI payload. -/
def gatewayVaultRequest (gatewayCtx : Context) (vault : Address) (fee : Word)
    (selector calldata : Bytes) : Request :=
  ⟨gatewayCtx.self, vault, fee, calldata⟩

/-- Execute the physical gateway program after the pure Solidity guards and
fee calculation have selected a `GatewayOutcome`.  A successful vault CALL is
followed by `_refundFee`; any failure stays in the same root transaction. -/
def gatewayProgram (callee : External) (sexternal : StaticCall.External)
    (gatewayCtx vaultCtx : Context) (vault inbox recipient : Address) (selector : Bytes)
    (msgValue fee : Word) (groups : List WitnessGroup) : Exec GatewayOutcome := fun before =>
  match gatewayAddConsolidationRequests msgValue groups fee recipient.val gatewayCtx.sender.val true true with
  | .reverted _ => ⟨.error (.reason "GatewayRejected"), before, []⟩
  | .committed hop refund =>
      let calldata := gatewayVaultCalldata selector (hopSources hop.pairs) (hopTargets hop.pairs)
      let vaultExternal := vaultCalldataExternal callee sexternal vaultCtx gatewayCtx.self inbox
        hop.value selector calldata
      let callResult := lowLevelCall vaultExternal gatewayCtx vault calldata hop.value before
      match callResult.outcome with
      | .error fault => ⟨.error fault, callResult.world, callResult.attempts⟩
      | .ok _ =>
          let refundResult :=
            match refund with
            | none => (⟨.ok (), callResult.world, []⟩ : Result Unit)
            | some r => refundFee callee gatewayCtx r.value recipient callResult.world
          match refundResult.outcome with
          | .error fault => ⟨.error fault, refundResult.world,
              callResult.attempts ++ refundResult.attempts⟩
          | .ok _ => ⟨.ok (.committed hop refund), refundResult.world,
              callResult.attempts ++ refundResult.attempts⟩

/-- Root transaction of `ConsolidationGateway.addConsolidationRequests`'s
line-220 vault CALL plus `_refundFee`.  `before` is the gateway entry world,
after its payable frame has supplied `msgValue` to `gatewayCtx.self`. -/
def executeGatewayCall (callee : External) (sexternal : StaticCall.External)
    (gatewayCtx vaultCtx : Context) (vault inbox recipient : Address) (selector : Bytes)
    (msgValue fee : Word) (groups : List WitnessGroup) (before : World) : Result GatewayOutcome :=
  Live.run (gatewayProgram callee sexternal gatewayCtx vaultCtx vault inbox recipient selector
    msgValue fee groups) before

/-- Any failed root execution restores the complete gateway entry world,
including balances, logs, core storage and any state represented there. -/
theorem executeGatewayCall_failure_restores (callee : External) (sexternal : StaticCall.External)
    (gatewayCtx vaultCtx : Context) (vault inbox recipient : Address) (selector : Bytes)
    (msgValue fee : Word) (groups : List WitnessGroup) (before : World) (fault : Fault)
    (h : (executeGatewayCall callee sexternal gatewayCtx vaultCtx vault inbox recipient selector
      msgValue fee groups before).outcome = .error fault) :
    (executeGatewayCall callee sexternal gatewayCtx vaultCtx vault inbox recipient selector
      msgValue fee groups before).world = before := by
  unfold executeGatewayCall Live.run at h ⊢
  dsimp only at h ⊢
  cases hr : gatewayProgram callee sexternal gatewayCtx vaultCtx vault inbox recipient selector
    msgValue fee groups before with
  | mk outcome world attempts =>
      cases outcome <;> simp_all

end audit.trio.consolidation
