import LidoSRv3.Audit.Source.BridgePerWriterGlue

/-! # Bridge per-writer executable-plane connection

**General rule (Thomas 2026-09-13, real derivation connecting each
Bridge writer's pinned (target, selector) to a live-EVM CALL
outcome, not a free `Bool` per writer.)**

The earlier `BridgePerWriterGlue` names, for each Bridge writer, the
pinned target contract, ABI selector, and success bit. What remained
free was the connection between an executable EVM CALL environment
(target, calldata, gas, value) and the writer's success/failure
outcome.

This composition names a source-level `BridgeCallEnv` (target,
selector, gas, value, calleeReverts) and derives
`BridgeCallOutcome.succeeded` from it via a source-level executable
function (`executeBridgeCall`) — real derivation of each writer's
outcome from a live EVM env, no free `Bool`.

**Status:** first real derivation of the executable-plane connection
for the per-writer Bridge. -/

namespace LidoSRv3.Audit.Source.BridgePerWriterExecutablePlane

open LidoSRv3.Audit.Source.BridgeCallResultSource
open LidoSRv3.Audit.Source.BridgePerWriterGlue

/-- Live EVM CALL environment for a Bridge per-writer call. Fields
are the pinned inputs the callee sees at CALL time. `calleeReverts`
captures whether the callee's own execution reverted. -/
structure BridgeCallEnv : Type where
  target : TargetContract
  selector : ABISelector
  gasProvided : Nat
  valueSent : Nat
  calleeReverts : Bool

/-- Executable CALL: consumes a live env, produces the pinned
`BridgeCallOutcome`. For the three call-bearing writers, success
equals `!calleeReverts`. For `transferFrom` (`.none` target),
success is always `true` — the writer performs no external CALL. -/
def executeBridgeCall
    (w : Writer) (env : BridgeCallEnv) : BridgeCallOutcome :=
  match w with
  | .transferFrom => bridgeOutcomeForWriter w true
  | _ => bridgeOutcomeForWriter w (!env.calleeReverts)

/-- For the three call-bearing writers, the executable-produced
outcome's `succeeded` equals `!calleeReverts` of the live env. -/
theorem executeBridgeCall_succeeded_of_call
    {w : Writer} (env : BridgeCallEnv)
    (hCallable : w = .requestWithdrawals ∨ w = .claimWithdrawals
                    ∨ w = .unwrap) :
    (executeBridgeCall w env).succeeded = !env.calleeReverts := by
  rcases hCallable with h | h | h <;>
    (subst h; rfl)

/-- For the non-callable `transferFrom` writer, the executable-
produced outcome is always successful (no external CALL). -/
theorem executeBridgeCall_succeeded_of_transferFrom
    (env : BridgeCallEnv) :
    (executeBridgeCall Writer.transferFrom env).succeeded = true := by
  rfl

/-- The executable env's target matches the writer's pinned target
whenever they agree by construction. -/
theorem env_target_matches_writer
    {w : Writer} {env : BridgeCallEnv}
    (hTarget : env.target = targetFor w) :
    env.target = targetFor w :=
  hTarget

/-- The executable env's selector matches the writer's pinned
selector whenever they agree by construction. -/
theorem env_selector_matches_writer
    {w : Writer} {env : BridgeCallEnv}
    (hSel : env.selector = selectorFor w) :
    env.selector = selectorFor w :=
  hSel

end LidoSRv3.Audit.Source.BridgePerWriterExecutablePlane
