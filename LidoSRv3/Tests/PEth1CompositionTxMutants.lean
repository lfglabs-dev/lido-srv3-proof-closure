import LidoSRv3.Audit.Verity.PEth1CompositionTx

/-! Discriminating mutants for the composed P-ETH-1 MultiContract slice. -/

namespace LidoSRv3.Tests.PEth1CompositionTxMutants

open _root_.Verity
open Compiler.CompilationModel.DenoteExternalCalls
open _root_.Verity.MultiContract
open LidoSRv3.Audit.Verity.PEth1CompositionTx

def wrongRefundAddr : Address := (7 : Address)

def runDoubleRefund : TxResult :=
  let before := initial 10
  advance before .busToGateway
    (executeHop before busAddr gatewayAddr 10 1 true) fun w1 =>
  advance before .gatewayToVault
    (executeHop w1 gatewayAddr vaultAddr 3 2 true) fun w2 =>
  advance before .gatewayToRefund
    (executeHop w2 gatewayAddr refundAddr 14 3 true) fun w3 =>
  advance before .vaultToRequest
    (executeHop w3 vaultAddr requestAddr 3 4 true) fun w4 =>
  .committed w4

def runWrongRecipient : TxResult :=
  let before := initial 10
  advance before .busToGateway
    (executeHop before busAddr gatewayAddr 10 1 true) fun w1 =>
  advance before .gatewayToVault
    (executeHop w1 gatewayAddr vaultAddr 3 2 true) fun w2 =>
  advance before .gatewayToRefund
    (executeHop w2 gatewayAddr wrongRefundAddr 7 3 true) fun w3 =>
  advance before .vaultToRequest
    (executeHop w3 vaultAddr requestAddr 3 4 true) fun w4 =>
  .committed w4

/-- Bug: returns the world after the first three committed hops when the final
request call fails, instead of the transaction-entry snapshot. -/
def runPreservedPrefix : TxResult :=
  let before := initial 10
  advance before .busToGateway
    (executeHop before busAddr gatewayAddr 10 1 true) fun w1 =>
  advance before .gatewayToVault
    (executeHop w1 gatewayAddr vaultAddr 3 2 true) fun w2 =>
  advance before .gatewayToRefund
    (executeHop w2 gatewayAddr refundAddr 7 3 true) fun w3 =>
  match executeHop w3 vaultAddr requestAddr 3 4 false with
  | some _ => .reverted .vaultToRequest w3
  | none => .reverted .vaultToRequest w3

/-- Bug: restores the Bus balance after an otherwise committing run. -/
def runValueNotDebited : TxResult :=
  match run (initial 10) 10 3 true true true true with
  | .reverted hop w => .reverted hop w
  | .committed w =>
      .committed (upsert w busAddr (accountAt busAddr 10).state)

theorem rejects_double_refund :
    observe runDoubleRefund ≠
      observe (run (initial 10) 10 3 true true true true) := by decide

theorem rejects_wrong_recipient :
    observe runWrongRecipient ≠
      observe (run (initial 10) 10 3 true true true true) := by decide

theorem rejects_preserved_prefix_after_failed_hop :
    observe runPreservedPrefix ≠
      observe (run (initial 10) 10 3 true true true false) := by decide

theorem rejects_value_not_debited :
    observe runValueNotDebited ≠
      observe (run (initial 10) 10 3 true true true true) := by decide

end LidoSRv3.Tests.PEth1CompositionTxMutants
