import Compiler.CompilationModel
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteMemory

/-!
# WithdrawalVault consolidation requests

Faithful bounded model of `WithdrawalVault.addConsolidationRequests` and
`WithdrawalVaultEIP7685._addConsolidationRequests` at Lido core pin
`af095e48bbc1c3841c2c9936219c8461af01056b`.  The gateway's grouped witness,
quota, and refund path is deliberately outside this vault-entrypoint model.

There is no mutable source storage on this path.  In particular, this file does
not introduce a prepaid balance, a validator mapping, or a stored fee.  Both
callee addresses are constructor immutables.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationFee

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory

def addConsolidationRequestsSelector : Nat := 0xa75ac640
def consolidationRequestAddedTopic : Nat :=
  0x67fce43957b4e9e86198cf87c600a0a6c3de7d0f56b0571062d93a853e4e9f73

/-! The `FunctionSpec` uses Verity's dynamic ABI loaders.  For an element of a
`bytes[]`, `arrayElementDynamicDataOffset` follows the element-offset word and
returns the first data byte; the preceding word is its byte length. -/

def elementLength (array : String) (index : Expr) : Expr :=
  .calldataload (.sub (.arrayElementDynamicDataOffset array index) (.literal 32))

def consolidationLoopBody : List Stmt :=
  [ .letVar "sourceOffset" (.arrayElementDynamicDataOffset "sourcePubkeys" (.localVar "i"))
  , .letVar "targetOffset" (.arrayElementDynamicDataOffset "targetPubkeys" (.localVar "i"))
  , .require (.eq (elementLength "sourcePubkeys" (.localVar "i")) (.literal 48))
      "InvalidPublicKeyLength(sourcePubkey)"
  , .require (.eq (elementLength "targetPubkeys" (.localVar "i")) (.literal 48))
      "InvalidPublicKeyLength(targetPubkey)"
  , .calldatacopy (.literal 0) (.localVar "sourceOffset") (.literal 48)
  , .calldatacopy (.literal 48) (.localVar "targetOffset") (.literal 48)
  , .letVar "request_ok"
      (.call (.literal Verity.Core.MAX_UINT256) (.immutable "CONSOLIDATION_REQUEST")
        (.localVar "fee") (.literal 0) (.literal 96) (.literal 0) (.literal 0))
  , .require (.eq (.localVar "request_ok") (.literal 1)) "RequestAdditionFailed(request)"
  -- ABI event data for the single non-indexed `bytes request`: offset, length, payload.
  , .mstore (.literal 128) (.literal 32)
  , .mstore (.literal 160) (.literal 96)
  , .calldatacopy (.literal 192) (.localVar "sourceOffset") (.literal 48)
  , .calldatacopy (.literal 240) (.localVar "targetOffset") (.literal 48)
  , .rawLog [.literal consolidationRequestAddedTopic] (.literal 128) (.literal 160) ]

/-- Exact vault signature `addConsolidationRequests(bytes[],bytes[])`.
The multiplication guard expresses Solidity 0.8 checked-multiplication:
for nonzero `requestsCount`, a wrapped product cannot divide back to `fee`.
The fee is obtained by empty-calldata STATICCALL to the immutable target and
accepted only after success and an exactly-32-byte return. -/
def addConsolidationRequests : FunctionSpec :=
  { name := "addConsolidationRequests"
    params :=
      [{ name := "sourcePubkeys", ty := .array .bytes },
       { name := "targetPubkeys", ty := .array .bytes }]
    returnType := none
    isPayable := true
    reentrancyTrusted := true
    localObligations :=
      [{ name := "bytes_array_offsets_and_lengths"
         obligation := "Verity dynamic ABI loaders follow each bytes[] element offset and length."
         proofStatus := .proved },
       { name := "whole_transaction_rollback_after_prior_success"
         obligation := "EVM transaction rollback removes successful earlier request calls and logs when any later request fails."
         proofStatus := .unchecked }]
    body :=
      [ .require (.eq .caller (.immutable "CONSOLIDATION_GATEWAY"))
          "NotConsolidationGateway"
      , .letVar "requestsCount" (.arrayLength "sourcePubkeys")
      , .require (.gt (.localVar "requestsCount") (.literal 0)) "ZeroArgument(sourcePubkeys)"
      , .require (.eq (.localVar "requestsCount") (.arrayLength "targetPubkeys"))
          "ArraysLengthMismatch"
      , .letVar "fee_read_ok"
          (.staticcall (.literal Verity.Core.MAX_UINT256)
            (.immutable "CONSOLIDATION_REQUEST") (.literal 0) (.literal 0)
            (.literal 96) (.literal 32))
      , .require (.eq (.localVar "fee_read_ok") (.literal 1)) "FeeReadFailed"
      , .require (.eq .returndataSize (.literal 32)) "FeeInvalidData"
      , .letVar "fee" (.mload (.literal 96))
      , .letVar "requiredFee" (.mul (.localVar "requestsCount") (.localVar "fee"))
      , .require
          (.eq (.div (.localVar "requiredFee") (.localVar "requestsCount")) (.localVar "fee"))
          "Panic(0x11): checked multiplication overflow"
      , .require (.eq .msgValue (.localVar "requiredFee")) "IncorrectFee"
      , .forEach "i" (.localVar "requestsCount") consolidationLoopBody
      , .stop ] }

def spec : CompilationModel :=
  { name := "WithdrawalVaultConsolidationRequests"
    fields := []
    immutables :=
      [{ name := "CONSOLIDATION_GATEWAY", ty := .address, init := .constructorArg 0 },
       { name := "CONSOLIDATION_REQUEST", ty := .address, init := .constructorArg 1 }]
    constructor := some
      { params :=
          [{ name := "consolidationGateway", ty := .address },
           { name := "consolidationRequest", ty := .address }]
        body :=
          [.setImmutable "CONSOLIDATION_GATEWAY" (.param "consolidationGateway"),
           .setImmutable "CONSOLIDATION_REQUEST" (.param "consolidationRequest")] }
    functions := [addConsolidationRequests] }

theorem function_is_actual_entrypoint :
    spec.functions = [addConsolidationRequests] := rfl

theorem function_spec_compiles :
    (CompilationModel.compile spec [addConsolidationRequestsSelector]).isOk = true := by
  native_decide

/-! ## Byte-precise memory/call model -/

abbrev Pubkey := List Byte

structure Request where
  source : Pubkey
  target : Pubkey

def ValidRequest (request : Request) : Prop :=
  request.source.length = 48 ∧ request.target.length = 48

def validRequest (request : Request) : Bool :=
  request.source.length == 48 && request.target.length == 48

def payloadBytes (request : Request) : List Byte := request.source ++ request.target

def payload (request : Request) : List Nat := (payloadBytes request).map (·.val)

/-- 1H byte memory corresponding to the two `calldatacopy` operations in the
typed loop: source at `[0,48)` and target at `[48,96)`. -/
def requestMemory (request : Request) : Memory :=
  (Memory.empty.copyFrom (listByte request.source) 0 0 48).copyFrom
    (listByte request.target) 48 0 48

theorem payload_length (request : Request) (h : ValidRequest request) :
    (payload request).length = 96 := by
  simp [payload, payloadBytes, h.1, h.2]

theorem requestMemory_target_byte (request : Request) (index : Fin 48) :
    (requestMemory request).bytes (48 + index) = listByte request.target index := by
  simpa [requestMemory] using
    Memory.copyFrom_at
      (Memory.empty.copyFrom (listByte request.source) 0 0 48)
      (listByte request.target) 48 0 48 index

def feeSite (consolidationRequest : Nat) : CallSite :=
  { siteId := 0, kind := .staticcall, target := consolidationRequest,
    value := 0, calldata := [], gas := Verity.Core.MAX_UINT256 }

def requestSite (consolidationRequest fee index : Nat) (request : Request) : CallSite :=
  { siteId := index + 1, kind := .call, target := consolidationRequest,
    value := fee, calldata := payload request, gas := Verity.Core.MAX_UINT256 }

def decodeWord (bytes : List Nat) : Nat :=
  bytes.foldl (fun value byte => value * 256 + byte) 0

inductive BatchStatus where | reverted | succeeded
  deriving DecidableEq

/-- The actual fee-staticcall followed by the request-call batch.  No request
call is constructed unless the fee call succeeds with exactly 32 return bytes,
authorization/ABI validation succeeds, checked multiplication does not wrap,
and `msg.value` is exactly the product. -/
def batchCalls (caller gateway consolidationRequest msgValue : Nat)
    (sources targets : List Pubkey) : CallProgram BatchStatus :=
  .bind (feeSite consolidationRequest) fun feeObservation =>
    match feeObservation.result with
    | .success data =>
        if data.length = 32 then
          let fee := decodeWord data
          let count := sources.length
          if caller = gateway ∧ count > 0 ∧ count = targets.length ∧
              count * fee ≤ Verity.Core.MAX_UINT256 ∧ msgValue = count * fee then
            let requests := List.zipWith (fun source target => ({ source, target } : Request)) sources targets
            let rec loop (index : Nat) : List Request → CallProgram BatchStatus
              | [] => .pure .succeeded
              | request :: rest =>
                  if validRequest request then
                    .bind (requestSite consolidationRequest fee index request) fun observation =>
                      if observation.result.succeeded then loop (index + 1) rest
                      else .pure .reverted
                  else .pure .reverted
            loop 0 requests
          else .pure .reverted
        else .pure .reverted
    | .failure _ | .revert _ => .pure .reverted

/-- A.1 is connected to the dynamically observed calls of the same vault
batch program.  It proves the exact available Verity guarantee: if every
observed site is static/fails/reverts, the complete batch preserves the initial
external world. -/
theorem batch_all_observed_calls_rollback
    (caller gateway consolidationRequest msgValue : Nat)
    (sources targets : List Pubkey) (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls
      (batchCalls caller gateway consolidationRequest msgValue sources targets)
      adversary state, RollsBack adversary entry) :
    (denote (batchCalls caller gateway consolidationRequest msgValue sources targets)
      adversary state).2.world = state.world := by
  exact denoteCallProgram_all_revert_preserves_world _ adversary state h

/-! OPEN: `CallProgramRollback` does not expose a transaction-frame operator
that can undo earlier *successful* mutable calls when a later call fails.
Accordingly this model does not claim that its `denote` world proves that EVM
case. Solidity/EVM supplies that rollback, but a faithful Verity proof requires
such an operator/theorem upstream; inventing a compensating state transition
here would be unsound. -/

end LidoSRv3.Audit.Verity.ConsolidationFee
