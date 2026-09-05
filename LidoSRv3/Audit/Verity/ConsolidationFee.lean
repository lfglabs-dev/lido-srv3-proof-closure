import Compiler.CompilationModel
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteMemory

/-!
# WithdrawalVault consolidation requests

Source-shaped bounded scaffold for `WithdrawalVault.addConsolidationRequests` and
`WithdrawalVaultEIP7685._addConsolidationRequests` at Lido core pin
`17005714f151e5502c559932319a3f2f74ac2436`.  The gateway's grouped witness,
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

/-! ## WithdrawalVaultEIP7685 loop body (WithdrawalVaultEIP7685.sol:68-72) -/

/-- One iteration of `for (uint256 i = 0; i < requestsCount; ++i)`
(`WithdrawalVaultEIP7685.sol:68-72`), inlining `_validatePublicKey`
(97-101) twice and `_callAddConsolidationRequest` (113-121).

Added by the model: the `calldatacopy` scratch layout `[0,96)` standing for
`abi.encodePacked(sourcePubkey, targetPubkey)` (line 114) and the ABI event
data layout at `[128,288)`. -/
def consolidationRequestLoopBody : List Stmt :=
  [ .letVar "sourceOffset" (.arrayElementDynamicDataOffset "sourcePubkeys" (.localVar "i"))
  , .letVar "targetOffset" (.arrayElementDynamicDataOffset "targetPubkeys" (.localVar "i"))
  -- WithdrawalVaultEIP7685.sol:69  _validatePublicKey(sourcePubkeys[i]);  -> 98  if (pubkey.length != PUBLIC_KEY_LENGTH) revert InvalidPublicKeyLength(pubkey);
  , .require (.eq (elementLength "sourcePubkeys" (.localVar "i")) (.literal 48))
      "InvalidPublicKeyLength(sourcePubkey)"
  -- WithdrawalVaultEIP7685.sol:70  _validatePublicKey(targetPubkeys[i]);  -> 98  [_validatePublicKey]
  , .require (.eq (elementLength "targetPubkeys" (.localVar "i")) (.literal 48))
      "InvalidPublicKeyLength(targetPubkey)"
  -- WithdrawalVaultEIP7685.sol:114  bytes memory request = abi.encodePacked(sourcePubkey, targetPubkey);  [_callAddConsolidationRequest]
  , .calldatacopy (.literal 0) (.localVar "sourceOffset") (.literal 48)
  , .calldatacopy (.literal 48) (.localVar "targetOffset") (.literal 48)
  -- WithdrawalVaultEIP7685.sol:115  (bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);  [_callAddConsolidationRequest]
  , .letVar "request_ok"
      (.call (.literal Verity.Core.MAX_UINT256) (.immutable "CONSOLIDATION_REQUEST")
        (.localVar "fee") (.literal 0) (.literal 96) (.literal 0) (.literal 0))
  -- WithdrawalVaultEIP7685.sol:116-118  if (!success) { revert RequestAdditionFailed(request); }  [_callAddConsolidationRequest]
  , .require (.eq (.localVar "request_ok") (.literal 1)) "RequestAdditionFailed(request)"
  -- WithdrawalVaultEIP7685.sol:120  emit ConsolidationRequestAdded(request);  [_callAddConsolidationRequest]
  -- ABI event data for the single non-indexed `bytes request`: offset, length, payload.
  , .mstore (.literal 128) (.literal 32)
  , .mstore (.literal 160) (.literal 96)
  , .calldatacopy (.literal 192) (.localVar "sourceOffset") (.literal 48)
  , .calldatacopy (.literal 240) (.localVar "targetOffset") (.literal 48)
  , .rawLog [.literal consolidationRequestAddedTopic] (.literal 128) (.literal 160) ]

/-! ## WithdrawalVault.addConsolidationRequests (WithdrawalVault.sol:199-208) -/

/-- `WithdrawalVault.sol:199-208 addConsolidationRequests(bytes[] calldata sourcePubkeys, bytes[] calldata targetPubkeys)`,
`FunctionSpec` form, inlining the `preservesEthBalance` modifier
(`WithdrawalVault.sol:81-85`), `_addConsolidationRequests`
(`WithdrawalVaultEIP7685.sol:56-73`), `_getConsolidationRequestFee` /
`_getFeeFromContract` (79-95) and `_requireExactFee` (123-127); the loop
body is `consolidationRequestLoopBody`.

Not transcribed: the constructor nonzero-address guards beyond `spec`'s
two `ZeroAddress` requires; ABI-level `bytes[]` decoding (local obligation
`bytes_array_offsets_and_lengths`); whole-transaction rollback of earlier
successful CALLs (local obligation
`whole_transaction_rollback_after_prior_success`).

Added by the model: the explicit underflow guard on
`address(this).balance - msg.value` (a Solidity 0.8 checked subtraction),
the `requiredFee / requestsCount == fee` division check expressing checked
multiplication, and the `fee_read_ok` / `returndatasize` decomposition of
`_getFeeFromContract`.

Exact vault signature `addConsolidationRequests(bytes[],bytes[])`.
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
         proofStatus := .unchecked },
       { name := "whole_transaction_rollback_after_prior_success"
         obligation := "EVM transaction rollback removes successful earlier request calls and logs when any later request fails."
         proofStatus := .unchecked }]
    body :=
      -- WithdrawalVault.sol:82  uint256 balanceBeforeCall = address(this).balance - msg.value;  [preservesEthBalance]
      [ .letVar "balanceBeforeCall" (.sub .selfBalance .msgValue)
      -- (same line, checked subtraction: Panic 0x11 on underflow)
      , .require (.ge .selfBalance .msgValue)
          "Panic(0x11): preservesEthBalance pre-call subtraction underflow"
      -- WithdrawalVault.sol:203-204  if (msg.sender != CONSOLIDATION_GATEWAY) { revert NotConsolidationGateway(); }
      , .require (.eq .caller (.immutable "CONSOLIDATION_GATEWAY"))
          "NotConsolidationGateway"
      -- WithdrawalVaultEIP7685.sol:60  uint256 requestsCount = sourcePubkeys.length;  [_addConsolidationRequests]
      , .letVar "requestsCount" (.arrayLength "sourcePubkeys")
      -- WithdrawalVaultEIP7685.sol:61  if (requestsCount == 0) revert ZeroArgument("sourcePubkeys");  [_addConsolidationRequests]
      , .require (.gt (.localVar "requestsCount") (.literal 0)) "ZeroArgument(sourcePubkeys)"
      -- WithdrawalVaultEIP7685.sol:62-63  if (requestsCount != targetPubkeys.length) revert ArraysLengthMismatch(...)  [_addConsolidationRequests]
      , .require (.eq (.localVar "requestsCount") (.arrayLength "targetPubkeys"))
          "ArraysLengthMismatch"
      -- WithdrawalVaultEIP7685.sol:65  uint256 fee = _getConsolidationRequestFee();  -> 84  (bool success, bytes memory feeData) = contractAddress.staticcall("");  [_getFeeFromContract]
      , .letVar "fee_read_ok"
          (.staticcall (.literal Verity.Core.MAX_UINT256)
            (.immutable "CONSOLIDATION_REQUEST") (.literal 0) (.literal 0)
            (.literal 96) (.literal 32))
      -- WithdrawalVaultEIP7685.sol:86-88  if (!success) { revert FeeReadFailed(); }  [_getFeeFromContract]
      , .require (.eq (.localVar "fee_read_ok") (.literal 1)) "FeeReadFailed"
      -- WithdrawalVaultEIP7685.sol:90-92  if (feeData.length != 32) { revert FeeInvalidData(); }  [_getFeeFromContract]
      , .require (.eq .returndataSize (.literal 32)) "FeeInvalidData"
      -- WithdrawalVaultEIP7685.sol:94  return abi.decode(feeData, (uint256));  [_getFeeFromContract]
      , .letVar "fee" (.mload (.literal 96))
      -- WithdrawalVaultEIP7685.sol:66  _requireExactFee(requestsCount * fee);  (checked multiply)
      , .letVar "requiredFee" (.mul (.localVar "requestsCount") (.localVar "fee"))
      , .require
          (.eq (.div (.localVar "requiredFee") (.localVar "requestsCount")) (.localVar "fee"))
          "Panic(0x11): checked multiplication overflow"
      -- WithdrawalVaultEIP7685.sol:124-125  if (requiredFee != msg.value) { revert IncorrectFee(requiredFee, msg.value); }  [_requireExactFee]
      , .require (.eq .msgValue (.localVar "requiredFee")) "IncorrectFee"
      -- WithdrawalVaultEIP7685.sol:68  for (uint256 i = 0; i < requestsCount; ++i) {  [_addConsolidationRequests]
      , .forEach "i" (.localVar "requestsCount") consolidationRequestLoopBody
      -- WithdrawalVault.sol:84  assert(address(this).balance == balanceBeforeCall);  [preservesEthBalance]
      -- Solidity `assert` is Panic(0x01), not a recoverable custom-error guard.
      , .ite (.eq .selfBalance (.localVar "balanceBeforeCall")) []
          [.panicCode (.literal 0x01)]
      , .stop ] }

/-- Contract shell: the two immutables (`WithdrawalVault.sol` constructor
`CONSOLIDATION_GATEWAY`, `WithdrawalVaultEIP7685.sol` `CONSOLIDATION_REQUEST`)
with their nonzero-address guards (`_onlyNonZeroAddress`, `ZeroAddress`).
No mutable storage on this path. -/
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
          [.require (.gt (.param "consolidationGateway") (.literal 0)) "ZeroAddress",
           .require (.gt (.param "consolidationRequest") (.literal 0)) "ZeroAddress",
           .setImmutable "CONSOLIDATION_GATEWAY" (.param "consolidationGateway"),
           .setImmutable "CONSOLIDATION_REQUEST" (.param "consolidationRequest")] }
    functions := [addConsolidationRequests] }

theorem function_scaffold_entrypoint :
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

def abiWord (value : Nat) : Word :=
  fun index => ⟨(value / 256 ^ (31 - index.val)) % 256, Nat.mod_lt _ (by decide)⟩

def decodeWordBytes (bytes : List Byte) : Nat :=
  bytes.foldl (fun value byte => value * 256 + byte.val) 0

def decodeMemoryWord (memory : Memory) (offset : Nat) : Nat :=
  decodeWordBytes (List.ofFn (fun index : Fin 32 => memory.bytes (offset + index)))

/-- Exact ABI tail of one dynamic `bytes[]` element: the 32-byte big-endian
length followed by its bytes at the offset returned by the dynamic loader. -/
def encodeDynamicElement (bytes : Pubkey) : Memory :=
  (Memory.empty.writeWord 0 (abiWord bytes.length)).copyFrom
    (listByte bytes) 32 0 bytes.length

def decodeDynamicElement (memory : Memory) : Pubkey :=
  memory.slice 32 (decodeMemoryWord memory 0)

structure MemoryRequest where
  sourceElement : Memory
  targetElement : Memory

def encodeRequest (request : Request) : MemoryRequest :=
  { sourceElement := encodeDynamicElement request.source
    targetElement := encodeDynamicElement request.target }

def decodeRequest (encoded : MemoryRequest) : Request :=
  { source := decodeDynamicElement encoded.sourceElement
    target := decodeDynamicElement encoded.targetElement }

/-- Validation consumes only lengths decoded from byte memory. -/
def validRequest (encoded : MemoryRequest) : Bool :=
  (decodeDynamicElement encoded.sourceElement).length == 48 &&
    (decodeDynamicElement encoded.targetElement).length == 48

/-- Execution memory for the two typed `calldatacopy` operations.  Both copy
sources are decoded ABI element memories, not the original request lists. -/
def requestMemory (encoded : MemoryRequest) : Memory :=
  let request := decodeRequest encoded
  (Memory.empty.copyFrom (listByte request.source) 0 0 48).copyFrom
    (listByte request.target) 48 0 48

/-- The external request call reads its exact `[0,96)` calldata from memory. -/
def payloadBytes (encoded : MemoryRequest) : List Byte :=
  (requestMemory encoded).slice 0 96

def payload (encoded : MemoryRequest) : List Nat :=
  (payloadBytes encoded).map (·.val)

theorem abiWord_48_decodes :
    decodeWordBytes (List.ofFn (abiWord 48)) = 48 := by native_decide

theorem encodeDynamicElement_length_48 (bytes : Pubkey) (h : bytes.length = 48) :
    decodeMemoryWord (encodeDynamicElement bytes) 0 = 48 := by
  unfold decodeMemoryWord
  rw [show List.ofFn (fun index : Fin 32 =>
      (encodeDynamicElement bytes).bytes (0 + index)) = List.ofFn (abiWord 48) by
    congr 1
    funext index
    simp only [encodeDynamicElement, h, Memory.copyFrom]
    split
    · omega
    · simp [Memory.readByte, Memory.writeWord, Memory.expand, Memory.empty,
        expandedLength] <;> omega]
  exact abiWord_48_decodes

theorem encode_decode_dynamic_48 (bytes : Pubkey) (h : bytes.length = 48) :
    decodeDynamicElement (encodeDynamicElement bytes) = bytes := by
  rw [decodeDynamicElement, encodeDynamicElement_length_48 bytes h]
  apply List.ext_get
  · simpa [Memory.slice] using h.symm
  · intro index hleft hright
    have hi : index < 48 := by omega
    have hi80 : 32 + index < 80 := by omega
    have hi96 : 32 + index < 96 := by omega
    simp [Memory.slice, encodeDynamicElement, h, Memory.readByte, Memory.copyFrom,
      Memory.writeWord, Memory.expand, Memory.empty, expandedLength, listByte,
      List.getD_eq_getElem?_getD, hi, hi80, hi96]

theorem encode_decode_request (request : Request) (h : ValidRequest request) :
    decodeRequest (encodeRequest request) = request := by
  cases request
  simp only [decodeRequest, encodeRequest, ValidRequest] at h ⊢
  simp [encode_decode_dynamic_48 _ h.1, encode_decode_dynamic_48 _ h.2]

theorem payload_length (encoded : MemoryRequest) :
    (payload encoded).length = 96 := by
  simp [payload, payloadBytes, Memory.slice]

theorem requestMemory_source_byte (encoded : MemoryRequest) (index : Fin 48) :
    (requestMemory encoded).bytes index =
      listByte (decodeRequest encoded).source index := by
  simp only [requestMemory, Memory.copyFrom]
  split
  · omega
  · simp [Memory.readByte, Memory.expand, expandedLength, Memory.empty] <;> omega

theorem requestMemory_target_byte (encoded : MemoryRequest) (index : Fin 48) :
    (requestMemory encoded).bytes (48 + index) =
      listByte (decodeRequest encoded).target index := by
  simpa [requestMemory] using
    Memory.copyFrom_at
      (Memory.empty.copyFrom (listByte (decodeRequest encoded).source) 0 0 48)
      (listByte (decodeRequest encoded).target) 48 0 48 index

theorem validRequest_encode_of_valid (request : Request) (h : ValidRequest request) :
    validRequest (encodeRequest request) = true := by
  change ((decodeRequest (encodeRequest request)).source.length == 48 &&
    (decodeRequest (encodeRequest request)).target.length == 48) = true
  rw [encode_decode_request request h]
  simp [h.1, h.2]

/-- For every valid request, the 96-byte request payload retains the source
key in bytes `[0,48)` and the target key in bytes `[48,96)`. -/
theorem valid_request_payload_preserves_source_order (request : Request)
    (h : ValidRequest request) :
    (∀ index : Fin 48,
      (requestMemory (encodeRequest request)).bytes index = listByte request.source index) ∧
    (∀ index : Fin 48,
      (requestMemory (encodeRequest request)).bytes (48 + index) =
        listByte request.target index) := by
  constructor
  · intro index
    simpa [encode_decode_request request h] using
      requestMemory_source_byte (encodeRequest request) index
  · intro index
    simpa [encode_decode_request request h] using
      requestMemory_target_byte (encodeRequest request) index

def feeSite (consolidationRequest : Nat) : CallSite :=
  { siteId := 0, kind := .staticcall, target := consolidationRequest,
    value := 0, calldata := [], gas := Verity.Core.MAX_UINT256 }

def requestSite (consolidationRequest fee index : Nat) (encoded : MemoryRequest) : CallSite :=
  { siteId := index + 1, kind := .call, target := consolidationRequest,
    value := fee, calldata := payload encoded, gas := Verity.Core.MAX_UINT256 }

def decodeWord (bytes : List Nat) : Nat :=
  bytes.foldl (fun value byte => value * 256 + byte) 0

inductive BatchStatus where | reverted | succeeded
  deriving DecidableEq

/-- `WithdrawalVault.sol:199-208 addConsolidationRequests` as a `CallProgram`:
a handwritten guarded fee-staticcall followed by a request-call batch.
Authorization and both array-shape guards precede the fee site.  After a valid
fee result and exact `msg.value` check, each request is decoded and length-
checked immediately before its request call, in the pinned source order.

Not transcribed: `preservesEthBalance` (81-85), the `abi.decode` of the fee
(`decodeWord` stands in), the event (line 120). Added by the model:
`BatchStatus`, `encodeRequest` memory encoding. -/
def batchCalls (caller gateway consolidationRequest msgValue : Nat)
    (sources targets : List Pubkey) : CallProgram BatchStatus :=
  -- WithdrawalVaultEIP7685.sol:60  uint256 requestsCount = sourcePubkeys.length;
  let count := sources.length
  let requests := List.zipWith
    (fun source target => encodeRequest ({ source, target } : Request)) sources targets
  -- WithdrawalVault.sol:203  if (msg.sender != CONSOLIDATION_GATEWAY)  +  EIP7685 61  requestsCount == 0  +  62  requestsCount != targetPubkeys.length
  if caller = gateway ∧ count > 0 ∧ count = targets.length then
    -- WithdrawalVaultEIP7685.sol:84  (bool success, bytes memory feeData) = contractAddress.staticcall("");  [_getFeeFromContract]
    .bind (feeSite consolidationRequest) fun feeObservation =>
      match feeObservation.result with
      | .success data =>
          -- WithdrawalVaultEIP7685.sol:90  if (feeData.length != 32) {  [_getFeeFromContract]
          if data.length = 32 then
            -- WithdrawalVaultEIP7685.sol:94  return abi.decode(feeData, (uint256));
            let fee := decodeWord data
            -- WithdrawalVaultEIP7685.sol:66  _requireExactFee(requestsCount * fee);  -> 124  if (requiredFee != msg.value)
            if count * fee ≤ Verity.Core.MAX_UINT256 ∧ msgValue = count * fee then
              -- WithdrawalVaultEIP7685.sol:68-72  for (uint256 i = 0; i < requestsCount; ++i) { ... }
              let rec loop (index : Nat) : List MemoryRequest → CallProgram BatchStatus
                | [] => .pure .succeeded
                | request :: rest =>
                    -- WithdrawalVaultEIP7685.sol:69-70  _validatePublicKey(sourcePubkeys[i]); _validatePublicKey(targetPubkeys[i]);
                    if validRequest request then
                      -- WithdrawalVaultEIP7685.sol:115  CONSOLIDATION_REQUEST.call{value: fee}(request);  [_callAddConsolidationRequest]
                      .bind (requestSite consolidationRequest fee index request) fun observation =>
                        -- WithdrawalVaultEIP7685.sol:116  if (!success) { revert RequestAdditionFailed(request); }
                        if observation.result.succeeded then loop (index + 1) rest
                        else .pure .reverted
                    else .pure .reverted
              loop 0 requests
            else .pure .reverted
          else .pure .reverted
      -- WithdrawalVaultEIP7685.sol:86  if (!success) { revert FeeReadFailed(); }  [_getFeeFromContract]
      | .failure _ | .revert _ => .pure .reverted
  else .pure .reverted

theorem caller_guard_precedes_all_external_calls
    (caller gateway consolidationRequest msgValue : Nat)
    (sources targets : List Pubkey) (adversary : AdversaryModel) (state : CallState)
    (hcaller : caller ≠ gateway) :
    ObservedCalls
      (batchCalls caller gateway consolidationRequest msgValue sources targets)
      adversary state = [] := by
  simp [batchCalls, hcaller]
  rfl

theorem array_shape_guards_precede_all_external_calls
    (gateway consolidationRequest msgValue : Nat)
    (sources targets : List Pubkey) (adversary : AdversaryModel) (state : CallState)
    (hshape : sources = [] ∨ sources.length ≠ targets.length) :
    ObservedCalls
      (batchCalls gateway gateway consolidationRequest msgValue sources targets)
      adversary state = [] := by
  rcases hshape with rfl | hlength
  · simp [batchCalls]
    rfl
  · simp [batchCalls, hlength]
    rfl

theorem fee_failure_trace_contains_only_staticcall
    (gateway consolidationRequest msgValue : Nat)
    (source : Pubkey) (sources targets : List Pubkey)
    (adversary : AdversaryModel) (state : CallState) (data : List Nat)
    (hlength : (source :: sources).length = targets.length)
    (hfee : adversary.result (feeSite consolidationRequest) state.world = .failure data) :
    ObservedCalls
      (batchCalls gateway gateway consolidationRequest msgValue (source :: sources) targets)
      adversary state =
        [{ site := feeSite consolidationRequest, preWorld := state.world }] := by
  have hpositive : 0 < targets.length := by
    cases targets with
    | nil => simp at hlength
    | cons => simp
  simp [batchCalls, hlength, hpositive, ObservedCalls, denoteCall, hfee]

theorem invalid_fee_data_trace_contains_only_staticcall
    (gateway consolidationRequest msgValue : Nat)
    (source : Pubkey) (sources targets : List Pubkey) (feeData : List Nat)
    (adversary : AdversaryModel) (state : CallState)
    (hlength : (source :: sources).length = targets.length)
    (hfee : adversary.result (feeSite consolidationRequest) state.world =
      .success feeData)
    (hsize : feeData.length ≠ 32) :
    ObservedCalls
      (batchCalls gateway gateway consolidationRequest msgValue (source :: sources) targets)
      adversary state =
        [{ site := feeSite consolidationRequest, preWorld := state.world }] := by
  have hpositive : 0 < targets.length := by
    cases targets with
    | nil => simp at hlength
    | cons => simp
  simp [batchCalls, hlength, hpositive, ObservedCalls, denoteCall, hfee, hsize]

/-- If the first decoded pair has an invalid key length, a successful fee read
is still observable, but no request CALL is made for that invalid pair. -/
theorem first_key_length_failure_trace_contains_only_fee_staticcall
    (gateway consolidationRequest fee : Nat) (feeData : List Nat)
    (source target : Pubkey) (adversary : AdversaryModel) (state : CallState)
    (hfee : adversary.result (feeSite consolidationRequest) state.world =
      .success feeData)
    (hsize : feeData.length = 32) (hdecode : decodeWord feeData = fee)
    (hvalue : fee ≤ Verity.Core.MAX_UINT256)
    (hkey : validRequest (encodeRequest ({ source, target } : Request)) = false) :
    ObservedCalls
      (batchCalls gateway gateway consolidationRequest fee [source] [target]) adversary state =
        [{ site := feeSite consolidationRequest, preWorld := state.world }] := by
  simp [batchCalls, batchCalls.loop, ObservedCalls, denoteCall, hfee, hsize, hdecode,
    hvalue, hkey]

/-- A later invalid pair yields a partial trace: the fee STATICCALL and the
preceding valid request CALL are present, while the invalid request is absent. -/
theorem second_key_length_failure_trace_is_partial
    (gateway consolidationRequest fee : Nat) (feeData requestData : List Nat)
    (source₀ source₁ target₀ target₁ : Pubkey)
    (adversary : AdversaryModel) (state : CallState)
    (hfee : adversary.result (feeSite consolidationRequest) state.world = .success feeData)
    (hsize : feeData.length = 32) (hdecode : decodeWord feeData = fee)
    (hbound : 2 * fee ≤ Verity.Core.MAX_UINT256)
    (hvalid₀ : validRequest (encodeRequest ({ source := source₀, target := target₀ } : Request)) = true)
    (hinvalid₁ : validRequest (encodeRequest ({ source := source₁, target := target₁ } : Request)) = false)
    (hrequest : adversary.result
      (requestSite consolidationRequest fee 0
        (encodeRequest ({ source := source₀, target := target₀ } : Request))) state.world =
      .success requestData) :
    (ObservedCalls
      (batchCalls gateway gateway consolidationRequest (2 * fee)
        [source₀, source₁] [target₀, target₁]) adversary state).map (·.site) =
      [feeSite consolidationRequest,
       requestSite consolidationRequest fee 0
         (encodeRequest ({ source := source₀, target := target₀ } : Request))] := by
  simp [batchCalls, batchCalls.loop, ObservedCalls, denoteCall, hfee, hsize, hdecode,
    hbound, hvalid₀, hinvalid₁, hrequest]

/-- This theorem applies only to the separate handwritten `CallProgram`; there
is currently no Verity theorem connecting it to the `FunctionSpec` above.  If
every observed site is static/fails/reverts, this program preserves its initial
external world.  It is intentionally not registered as A.1 evidence. -/
theorem handwritten_batch_all_observed_calls_rollback
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
