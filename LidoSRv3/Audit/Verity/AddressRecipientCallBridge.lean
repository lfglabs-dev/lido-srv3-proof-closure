import LidoSRv3.Audit.Verity.AddressClaimBatchTx
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-!
# P-ADDRESS-1 recipient CALL bridge

`AddressClaimBatchTx.claimOne` is the storage-accurate, pinned
`claimWithdrawalsTo` iteration.  The storage transition fixes the actual
target and value, while this bridge supplies the callee-world step: the same
recipient and value are passed to the project-wide live CALL
interpreter, whose result contains both caller and callee effects.  A rejected
callee is not an input flag; `Live.run` restores the complete entry world.

The bridge intentionally starts with the smallest address-bearing call edge.
The other entrypoint work must use this boundary rather than add another
boolean success parameter or an observation-only recipient slot.
-/

namespace LidoSRv3.Audit.Verity.AddressRecipientCallBridge

open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Source.TrioReserve1.Live

abbrev World := LidoSRv3.Audit.Source.TrioReserve1.Live.World
abbrev Context := LidoSRv3.Audit.Source.TrioReserve1.Live.Context
abbrev External := LidoSRv3.Audit.Source.TrioReserve1.Live.External
abbrev Exec := LidoSRv3.Audit.Source.TrioReserve1.Live.Exec
abbrev Address := _root_.Verity.Address
abbrev Bytes := LidoSRv3.Audit.Source.TrioReserve1.Live.Bytes

/-- Executable lenses for the source's `requestsByOwner` EnumerableSet. -/
def ownerRequestIndexPosition : Nat :=
  0x7f973f1f0bd3b6a1d72f7b49927429710d68c91b5cf61dd64e2f5f40545ef4b6
def ownerRequestKey (owner : Address) (requestId : Nat) : Uint256 :=
  .ofNat (owner.toNat * 2 ^ 128 + requestId)

/-- Execute a first-class CALL with the supplied ABI bytes.  The live helper
only accepts a selector, while the token entrypoints below have real argument
words.  As with `Live.call`, the callee sees the value-transferred world and a
rejection restores that transfer before the top-level rollback is applied. -/
def callWithCalldata (callee : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Uint256 := 0) : Exec Bytes := fun world =>
  let request : Request := ⟨ctx.self, target, value, payload⟩
  if (world.core.codeSize target.val).val = 0 then ⟨.error .empty, world, []⟩
  else if world.balances ctx.self < value.val then
    ⟨.error (.bubbled []), world, [⟨request, false, [], []⟩]⟩
  else
    match callee request (transfer world ctx.self target value.val) with
    | .rejected data => ⟨.error (.bubbled data), world, [⟨request, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨request, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok data, after, [⟨request, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.bubbled data), world, [⟨request, false, data, nested⟩]⟩

/-- Lift the pinned storage transition into the whole-world interpreter.  The
state supplied to `claimOne` receives the live transaction sender; every
queue/checkpoint read and the claimed/locked write therefore remains on the
physical channels used by `AddressClaimBatchTx`. -/
def claimStorage (ctx : Context) (requestId hint : Nat) (recipient : Address) :
    Exec Nat := fun world =>
  let before := { world.core with sender := ctx.sender }
  -- `_claim` owns every validation (and hence error ordering).  In particular
  -- do not calculate a prospective payout before it has checked finalization,
  -- ownership, and hints.
  match claimOne requestId hint recipient before with
  | .success payout after =>
      let owner := requestOwner (requestMetadataWord before requestId)
      if (before.readMapUint ownerRequestIndexPosition
        (ownerRequestKey owner requestId)).val = 0 then
        ⟨.error (.reason "OwnerRequestSetInvariant"), world, []⟩
      else
        ⟨.ok payout, { world with core := after.writeMapUint ownerRequestIndexPosition
          (ownerRequestKey owner requestId) 0 }, []⟩
  | .revert reason _ => ⟨.error (.reason reason), world, []⟩

/-- Exact `WithdrawalQueueBase._sendValue` call frame (lines 475--480): it is
an EVM `CALL` to the recipient with value and **empty** calldata.  The generic
`Live.call` helper encodes a four-byte selector, so using it here would silently
change the real call target's input.  Rejection restores the value transfer;
success returns the callee's entire resulting world. -/
def emptyValueCall (callee : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit := fun world =>
  let value : Uint256 := .ofNat payout
  let request : Request := ⟨ctx.self, recipient, value, []⟩
  if world.balances ctx.self < value.val then
    ⟨.error (.reason "NotEnoughEther"), world, [⟨request, false, [], []⟩]⟩
  else
    match callee request (transfer world ctx.self recipient value.val) with
    | .rejected data =>
        ⟨.error (.reason "CantSendValueRecipientMayHaveReverted"), world,
          [⟨request, false, data, []⟩]⟩
    | .success data after => ⟨.ok (), after, [⟨request, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok (), after, [⟨request, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.reason "CantSendValueRecipientMayHaveReverted"), world,
          [⟨request, false, data, nested⟩]⟩

/-- The recipient is the CALL target, not a post-hoc observation. -/
def payoutCall (callee : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit :=
  emptyValueCall callee ctx recipient payout

/-- One physical `_claim` followed by its value-bearing recipient CALL.  The
two layers have distinct jobs: `claimOne` fixes Solidity storage; `payoutCall`
executes the sole frame against a callee that may accept, reject, or change
its own world. -/
def claimTo (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) : Exec Unit := do
  let owner : Address ← fun world =>
    ⟨.ok (requestOwner (requestMetadataWord world.core requestId)), world, []⟩
  let payout ← claimStorage ctx requestId hint recipient
  payoutCall callee ctx recipient payout
  -- WithdrawalQueueBase emits this before ERC-721's transfer/burn event.
  emit ctx "WithdrawalClaimed" [(.ofNat requestId), (.ofNat ctx.sender.toNat),
    (.ofNat recipient.toNat), (.ofNat payout)]
  emit ctx "Transfer" [(.ofNat owner.toNat), 0, (.ofNat requestId)]

def runClaimTo (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) :=
  run (claimTo callee ctx requestId hint recipient) before

/-- The public `claimWithdrawalsTo` loop, lifted over the same callee-world
boundary as `claimTo`.  This deliberately reuses `claimOne`: each iteration
therefore keeps its physical request/checkpoint reads, packed claimed write,
and locked-ETH decrement.  The immediately following `payoutCall` executes
the sole recipient/value/empty-calldata frame and adopts the callee world. -/
def claimWithdrawalsLoop (callee : External) (ctx : Context) :
    List Nat → List Nat → Address → Exec Unit
  | [], [], _ => pure ()
  | requestId :: requestIds, hint :: hints, recipient => do
      claimTo callee ctx requestId hint recipient
      claimWithdrawalsLoop callee ctx requestIds hints recipient
  | _, _, _ => fun world => ⟨.error (.reason "ArraysLengthMismatch"), world, []⟩

/-- `WithdrawalQueue.claimWithdrawalsTo`: the recipient and matching arrays
are checked at the external boundary, then every item uses the same real CALL
bridge.  A failure in a later iteration is still top-level failure, so `run`
restores the complete entry caller/callee world. -/
def claimWithdrawalsTo (callee : External) (ctx : Context) (requestIds hints : List Nat)
    (recipient : Address) : Exec Unit := do
  require (decide (recipient != zeroAddress)) (.reason "ZeroRecipient")
  require (decide (requestIds.length = hints.length)) (.reason "ArraysLengthMismatch")
  claimWithdrawalsLoop callee ctx requestIds hints recipient

def runClaimWithdrawalsTo (callee : External) (ctx : Context) (requestIds hints : List Nat)
    (recipient : Address) (before : World) :=
  run (claimWithdrawalsTo callee ctx requestIds hints recipient) before

/-- A callee that accepts a value frame without changing the post-transfer
world.  It is a concrete executable callee, not a Boolean success input. -/
def acceptingCallee : External := fun _ world => .success [] world

def claimBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

/-- The `twoClaimState` storage witness with a code-bearing recipient and a
separate account-balance world for the actual CALL. -/
def claimBridgeWorld : World :=
  { core := { twoClaimState with
      codeSize := fun address => if address = (2 : Address).toNat then 1 else 0 } |>.writeMapUint
        ownerRequestIndexPosition (ownerRequestKey (1 : Address) 1) 1 |>.writeMapUint
          ownerRequestIndexPosition (ownerRequestKey (1 : Address) 2) 1
    balances := fun address => if address = claimBridgeContext.self then 70 else 0 }

/-- End-to-end receipt for the smallest recipient bridge.  The storage claim,
the exact empty-calldata CALL, and the callee-returned world agree on both the
30 wei value and address 2. -/
theorem claim_bridge_receipt :
    let result := runClaimTo acceptingCallee claimBridgeContext 1 1 (2 : Address)
      claimBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readMapUint (queuePosition + 1) 1 =
        markClaimed (requestMetadataWord twoClaimState 1) ∧
      result.world.core.selfBalance = 70 ∧
      result.world.balances claimBridgeContext.self = 40 ∧
      result.world.balances (2 : Address) = 30 ∧
      result.world.logs =
        [⟨claimBridgeContext.self, "WithdrawalClaimed", [1, 1, 2, 30]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 1]⟩] ∧
      result.attempts = [⟨⟨claimBridgeContext.self, (2 : Address), 30, []⟩,
        true, [], []⟩] := by
  decide +kernel

/-- The public two-item entrypoint retains both physical claimed writes and
executes two recipient CALLs in source loop order.  The callee's returned
world is the committed result, rather than a Boolean call-success premise. -/
theorem claim_withdrawals_to_bridge_receipt :
    let result := runClaimWithdrawalsTo acceptingCallee claimBridgeContext [1, 2] [1, 1]
      (2 : Address) claimBridgeWorld
    result.outcome = .ok () ∧
      requestClaimed (requestMetadataWord result.world.core 1) = true ∧
      requestClaimed (requestMetadataWord result.world.core 2) = true ∧
      result.world.core.readSlot lockedEtherAmountPosition = 0 ∧
      result.world.balances claimBridgeContext.self = 0 ∧
      result.world.balances (2 : Address) = 70 ∧
      result.world.logs =
        [⟨claimBridgeContext.self, "WithdrawalClaimed", [1, 1, 2, 30]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 1]⟩,
         ⟨claimBridgeContext.self, "WithdrawalClaimed", [2, 1, 2, 40]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 2]⟩] ∧
      result.attempts =
        [⟨⟨claimBridgeContext.self, (2 : Address), 30, []⟩, true, [], []⟩,
         ⟨⟨claimBridgeContext.self, (2 : Address), 40, []⟩, true, [], []⟩] := by
  decide +kernel

theorem claim_withdrawals_to_revert_restores_caller_and_callee_world
    (callee : External) (ctx : Context) (requestIds hints : List Nat)
    (recipient : Address) (before : World) (fault : Fault)
    (h : (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).outcome =
      .error fault) :
    (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).world = before := by
  unfold runClaimWithdrawalsTo LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : claimWithdrawalsTo callee ctx requestIds hints recipient before = result at h ⊢
  cases result with
  | mk outcome after attempts => cases outcome <;> simp_all

/-! ## `transferFrom` owner-operated physical branch

The live Solidity function also admits the two approval branches.  This bridge
contains the owner-operated branch, which is the branch shared with the
existing `AddressTransferTx` source slice: authorization is read from
`ctx.sender`, never injected as an approval Boolean.  It updates precisely the
low 160-bit `owner` field of the same `QUEUE_POSITION` metadata word used by
`claimOne`; timestamp, claimed byte, and report timestamp are retained. -/

/-- Replace only `WithdrawalRequest.owner`, packed into bits 0--159 of the
second request word. -/
def withRequestOwner (word : Uint256) (owner : Address) : Uint256 :=
  .ofNat ((word.val / 2 ^ 160) * 2 ^ 160 + owner.toNat)

/-- `keccak256("lido.WithdrawalQueueERC721.tokenApprovals")`, the actual
unstructured mapping base deleted by `_transfer` at source line 247. -/
def tokenApprovalsPosition : Nat :=
  0x528f2b9d452f4b604589d1a9e64c321ee1035a867d38a1359d022af391cf7df5

def lastRequestIdPosition : Nat :=
  0x8ee26abbbdf5335e3953ccf2204a79e845eecb5ab51f8398526746e4ea068041

def lastReportTimestampPosition : Nat :=
  0x6825d6bead788134d1ac062bbb7f1f0e4a9e13182688453e79955a721d58c45d

/-- `isApprovedForAll[owner][operator]` is a nested mapping.  The key below
is its ABI-pair projection in this executable storage lens. -/
def operatorApprovalsPosition : Nat :=
  0x2e6c8bafb6f9028b48d2d99e6559efba8c57eecbdb9b8b40b2ee6163e6c9e8da
def approvalPairKey (owner operator : Address) : Uint256 :=
  .ofNat (owner.toNat * 2 ^ 160 + operator.toNat)


/-- `WithdrawalQueueERC721.transferFrom` through `_transfer`, restricted to
the literal `msg.sender == _from` branch.  Every guard is evaluated from the
caller and physical request word; the successful writes are the approval
deletion at `TOKEN_APPROVALS_POSITION` and the owner word at
`keccak256(abi.encode(requestId, QUEUE_POSITION)) + 1`. -/
def transferFrom (ctx : Context) (fromAddr recipient : Address) (requestId : Nat) :
    Exec Unit := fun world =>
  let before := { world.core with sender := ctx.sender }
  let metadata := requestMetadataWord before requestId
  if recipient = zeroAddress then ⟨.error (.reason "TransferToZeroAddress"), world, []⟩
  else if recipient = fromAddr then ⟨.error (.reason "TransferToThemselves"), world, []⟩
  else if requestId = 0 || requestId > (before.readSlot lastRequestIdPosition).val then
    ⟨.error (.reason "InvalidRequestId"), world, []⟩
  else if requestClaimed metadata then ⟨.error (.reason "RequestAlreadyClaimed"), world, []⟩
  else if requestOwner metadata != fromAddr then
    ⟨.error (.reason "TransferFromIncorrectOwner"), world, []⟩
  else if ctx.sender != fromAddr &&
      (before.readMapUint tokenApprovalsPosition (.ofNat requestId)).val != ctx.sender.toNat &&
      (before.readMapUint operatorApprovalsPosition
        (approvalPairKey fromAddr ctx.sender)).val = 0 then
    ⟨.error (.reason "NotOwnerOrApproved"), world, []⟩
  else if (before.readMapUint ownerRequestIndexPosition (ownerRequestKey fromAddr requestId)).val = 0 then
    ⟨.error (.reason "OwnerRequestSetInvariant"), world, []⟩
  else
    ⟨.ok (), { world with core :=
      (((before.writeMapUint tokenApprovalsPosition (.ofNat requestId) 0).writeMapUint
        ownerRequestIndexPosition (ownerRequestKey fromAddr requestId) 0).writeMapUint
          ownerRequestIndexPosition (ownerRequestKey recipient requestId) 1).writeMapUint
        (queuePosition + 1) (.ofNat requestId) (withRequestOwner metadata recipient),
      logs := world.logs ++ [⟨ctx.self, "Transfer",
        [(.ofNat fromAddr.toNat), (.ofNat recipient.toNat), (.ofNat requestId)]⟩] }, []⟩

def runTransferFrom (ctx : Context) (fromAddr recipient : Address) (requestId : Nat)
    (before : World) :=
  run (transferFrom ctx fromAddr recipient requestId) before

def transferBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

def transferBridgeWorld : World :=
  { core := (defaultState.writeMapUint (queuePosition + 1) 1
      (packMetadata (1 : Address) 5 false 9)).writeMapUint
        tokenApprovalsPosition 1 7 |>.writeMapUint ownerRequestIndexPosition
          (ownerRequestKey (1 : Address) 1) 1 |>.writeSlot lastRequestIdPosition 1
    balances := fun _ => 0 }

/-- Owner-operated `transferFrom` receipt: no approval flag is supplied. The
caller is the request owner, so the physical token-approval word is deleted
and only the owner field of the packed request metadata becomes address 2. -/
theorem transfer_bridge_receipt :
    let result := runTransferFrom transferBridgeContext (1 : Address) (2 : Address) 1
      transferBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readMapUint tokenApprovalsPosition 1 = 0 ∧
      requestOwner (requestMetadataWord result.world.core 1) = (2 : Address) ∧
      result.world.core.readMapUint (queuePosition + 1) 1 =
        withRequestOwner (requestMetadataWord transferBridgeWorld.core 1) (2 : Address) ∧
      result.world.logs = [⟨transferBridgeContext.self, "Transfer", [1, 2, 1]⟩] ∧
      result.attempts = [] := by
  decide +kernel

/-- The direct ownership handoff is a top-level transaction too: every failed
guard returns the entry world, including every unrelated account's state. -/
theorem transfer_revert_restores_world
    (ctx : Context) (fromAddr recipient : Address) (requestId : Nat) (before : World)
    (fault : Fault)
    (h : (runTransferFrom ctx fromAddr recipient requestId before).outcome = .error fault) :
    (runTransferFrom ctx fromAddr recipient requestId before).world = before := by
  unfold runTransferFrom LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : transferFrom ctx fromAddr recipient requestId before = result at h ⊢
  cases result with
  | mk outcome after attempts => cases outcome <;> simp_all

/-! ## `requestWithdrawals` one-item physical path -/

def transferFromSelector : Nat := 0x23b872dd
def getSharesByPooledEthSelector : Nat := 0x19208451

def abiWord (n : Nat) : Bytes := encode 32 n
def abiAddress (a : Address) : Bytes := abiWord a.toNat

def stETHTransferFromCalldata (fromAddr queue : Address) (amount : Nat) : Bytes :=
  encode 4 transferFromSelector ++ abiAddress fromAddr ++ abiAddress queue ++ abiWord amount

def stETHSharesCalldata (amount : Nat) : Bytes :=
  encode 4 getSharesByPooledEthSelector ++ abiWord amount

/-- Solidity's packed `WithdrawalRequest` constructor.  Its callers have
already performed the uint128 conversions and checked additions; this encoder
must never hide an overflow with a final modulo operation. -/
def packEnqueuedAmounts (stETH shares : Nat) : Uint256 :=
  packAmounts stETH shares

def packEnqueuedMetadata (owner : Address) (timestamp reportTimestamp : Nat) : Uint256 :=
  .ofNat (owner.toNat + (timestamp % 2 ^ 40) * 2 ^ 160 +
    (reportTimestamp % 2 ^ 40) * 2 ^ 208)

/-- Physical `_enqueue` suffix.  Its request id, cumulative pair, report
timestamp, and owner all come from the current post-call storage world. -/
def enqueueRequest (_ctx : Context) (owner : Address) (amount shares : Nat) : Exec Nat := fun world =>
  let state := world.core
  let lastId := (state.readSlot lastRequestIdPosition).val
  let previous := requestAmountsWord state lastId
  -- Source order: shares addition first, then stETH, and only then id ++.
  let cumulativeShares := cumulativeShares previous + shares
  if cumulativeShares ≥ 2 ^ 128 then ⟨.error (.reason "Panic(0x11)"), world, []⟩
  else
    let cumulativeStETH := cumulativeStETH previous + amount
    if cumulativeStETH ≥ 2 ^ 128 then ⟨.error (.reason "Panic(0x11)"), world, []⟩
    else if lastId + 1 ≥ 2 ^ 256 then ⟨.error (.reason "Panic(0x11)"), world, []⟩
    else if (state.readMapUint ownerRequestIndexPosition
      (ownerRequestKey owner (lastId + 1))).val != 0 then
      ⟨.error (.reason "OwnerRequestSetInvariant"), world, []⟩
    else
      let requestId := lastId + 1
      let reportTimestamp := (state.readSlot lastReportTimestampPosition).val
      let after :=
        ((((state.writeSlot lastRequestIdPosition (.ofNat requestId)).writeMapUint
          queuePosition (.ofNat requestId) (packEnqueuedAmounts cumulativeStETH cumulativeShares)).writeMapUint
            (queuePosition + 1) (.ofNat requestId)
              (packEnqueuedMetadata owner state.blockTimestamp.val reportTimestamp)).writeMapUint
                ownerRequestIndexPosition (ownerRequestKey owner requestId) 1)
      ⟨.ok requestId, { world with core := after,
        logs := world.logs ++ [⟨_ctx.self, "WithdrawalRequested",
          [(.ofNat requestId), (.ofNat _ctx.sender.toNat), (.ofNat owner.toNat),
            (.ofNat amount), (.ofNat shares)]⟩,
          ⟨_ctx.self, "Transfer", [0, (.ofNat owner.toNat), (.ofNat requestId)]⟩] }, []⟩

/-- One item of `WithdrawalQueue.requestWithdrawals`.  The queue calls the
configured stETH target twice: first `transferFrom(msg.sender, address(this),
amount)`, then `getSharesByPooledEth(amount)`.  Both replies are execution
results from `external`; there is no supplied success, balance, or allowance
bit.  Only after both calls return does the physical queue record commit. -/
def requestWithdrawals (callee : External) (ctx : Context) (stETH : Address)
    (amount : Nat) (suppliedOwner : Address) : Exec Nat := do
  require (decide (100 ≤ amount) && decide (amount ≤ 1000 * 10 ^ 18))
    (.reason "RequestAmountOutOfRange")
  let owner := if suppliedOwner = zeroAddress then ctx.sender else suppliedOwner
  let amount128 := amount % 2 ^ 128
  let transferReply ← callWithCalldata callee ctx stETH
    (stETHTransferFromCalldata ctx.sender ctx.self amount128)
  let _ ← decodeWord transferReply
  let sharesBytes ← callWithCalldata callee ctx stETH (stETHSharesCalldata amount128)
  let shares ← decodeWord sharesBytes
  let shares128 := shares.val % 2 ^ 128
  enqueueRequest ctx owner amount128 shares128

def runRequestWithdrawals (callee : External) (ctx : Context) (stETH : Address)
    (amount : Nat) (suppliedOwner : Address) (before : World) :=
  run (requestWithdrawals callee ctx stETH amount suppliedOwner) before

def requestBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

/-- The share conversion call returns ten shares.  Solidity ABI-decodes the
ERC20 bool return (but does not branch on its value), so the first reply is a
full ABI word as well. -/
def requestCallee : External := fun request world =>
  if request.payload = stETHSharesCalldata 100 then .success (abiWord 10) world
  else .success (abiWord 1) world

def requestBridgeWorld : World :=
  { core := ({ defaultState with
      codeSize := fun address => if address = (2 : Address).toNat then 1 else 0,
      blockTimestamp := 5 }).writeSlot lastReportTimestampPosition 9
    balances := fun _ => 0 }

/-- One-item `requestWithdrawals` receipt. The owner fallback is caller 1,
and the successful post-call enqueue writes request id 1 with cumulative
amount/shares `(100, 10)` and the packed owner/timestamp/report word. -/
theorem request_bridge_receipt :
    let result := runRequestWithdrawals requestCallee requestBridgeContext (2 : Address)
      100 zeroAddress requestBridgeWorld
    result.outcome = .ok 1 ∧
      result.world.core.readSlot lastRequestIdPosition = 1 ∧
      requestAmountsWord result.world.core 1 = packEnqueuedAmounts 100 10 ∧
      requestMetadataWord result.world.core 1 = packEnqueuedMetadata (1 : Address) 5 9 ∧
      result.world.logs =
        [⟨requestBridgeContext.self, "WithdrawalRequested", [1, 1, 1, 100, 10]⟩,
         ⟨requestBridgeContext.self, "Transfer", [0, 1, 1]⟩] ∧
      result.attempts =
        [⟨⟨requestBridgeContext.self, (2 : Address), 0,
            stETHTransferFromCalldata requestBridgeContext.sender requestBridgeContext.self 100⟩,
            true, abiWord 1, []⟩,
         ⟨⟨requestBridgeContext.self, (2 : Address), 0, stETHSharesCalldata 100⟩,
            true, abiWord 10, []⟩] := by
  decide +kernel

theorem request_revert_restores_caller_and_callee_world
    (callee : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (suppliedOwner : Address) (before : World) (fault : Fault)
    (h : (runRequestWithdrawals callee ctx stETH amount suppliedOwner before).outcome =
      .error fault) :
    (runRequestWithdrawals callee ctx stETH amount suppliedOwner before).world = before := by
  unfold runRequestWithdrawals LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : requestWithdrawals callee ctx stETH amount suppliedOwner before = result at h ⊢
  cases result with
  | mk outcome after attempts => cases outcome <;> simp_all

/-! ## `WstETH.unwrap` physical path -/

/-- OpenZeppelin ERC20's inherited physical layout in the pinned WstETH
contract: `_balances` is mapping slot 0 and `_totalSupply` is scalar slot 2.
`unwrap` changes both via `_burn(msg.sender, amount)`. -/
def wstETHBalancesSlot : Nat := 0
def wstETHTotalSupplySlot : Nat := 2

def getPooledEthBySharesSelector : Nat := 0x7a28fb88
def erc20TransferSelector : Nat := 0xa9059cbb

def pooledEthBySharesCalldata (shares : Nat) : Bytes :=
  encode 4 getPooledEthBySharesSelector ++ abiWord shares

def erc20TransferCalldata (recipient : Address) (amount : Nat) : Bytes :=
  encode 4 erc20TransferSelector ++ abiAddress recipient ++ abiWord amount

/-- Source-ordered ERC20 `_burn`: both inherited physical slots change before
the subsequent stETH transfer.  No balance fact is supplied by the caller. -/
def burnWstETH (ctx : Context) (amount : Nat) : Exec Unit := fun world =>
  let state := world.core
  let balance := state.readMap wstETHBalancesSlot ctx.sender
  let supply := state.readSlot wstETHTotalSupplySlot
  if amount > balance.val then ⟨.error (.reason "ERC20: burn amount exceeds balance"), world, []⟩
  else if amount > supply.val then ⟨.error (.reason "ERC20: burn exceeds total supply"), world, []⟩
  else
    ⟨.ok (), { world with core :=
      ((state.writeMap wstETHBalancesSlot ctx.sender (.ofNat (balance.val - amount))).writeSlot
        wstETHTotalSupplySlot (.ofNat (supply.val - amount))),
      logs := world.logs ++ [⟨ctx.self, "Transfer", [(.ofNat ctx.sender.toNat), 0, (.ofNat amount)]⟩] }, []⟩

/-- `staticcall` form of the `getPooledEthByShares` view.  It shares CALL's
ABI framing but names the source-level static boundary explicitly; no value is
ever carried across this getter. -/
def staticCallWithCalldata (callee : External) (ctx : Context) (target : Address)
    (payload : Bytes) : Exec Bytes :=
  callWithCalldata callee ctx target payload 0

/-- `WstETH.unwrap` (0.6.12, lines 69--75).  The stETH amount is decoded from
the configured stETH callee's `getPooledEthByShares` reply; then the bridge
burns the caller's actual wstETH slots and calls the same stETH target's
`transfer(msg.sender, amount)`.  Thus the recipient is the execution-derived
`ctx.sender`, and any callee rejection rolls back caller and callee worlds. -/
def unwrap (callee : External) (ctx : Context) (stETH : Address) (amount : Nat) :
    Exec Nat := do
  require (decide (amount ≠ 0)) (.reason "wstETH: zero amount unwrap not allowed")
  let amountBytes ← staticCallWithCalldata callee ctx stETH (pooledEthBySharesCalldata amount)
  let stETHAmount ← decodeWord amountBytes
  burnWstETH ctx amount
  let transferReply ← callWithCalldata callee ctx stETH
    (erc20TransferCalldata ctx.sender stETHAmount.val)
  let _ ← decodeWord transferReply
  pure stETHAmount.val

def runUnwrap (callee : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) :=
  run (unwrap callee ctx stETH amount) before

def unwrapBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

/-- A concrete stETH callee for the unwrap receipt: its conversion reply is
the ABI word 15, and its later ERC20 transfer reply succeeds. -/
def unwrapCallee : External := fun request world =>
  if request.payload = pooledEthBySharesCalldata 10 then
    .success (abiWord 15) world
  else
    .success (abiWord 1) world

def unwrapBridgeWorld : World :=
  { core := ({ defaultState with
      codeSize := fun address => if address = (2 : Address).toNat then 1 else 0 }).writeMap
        wstETHBalancesSlot unwrapBridgeContext.sender 10 |>.writeSlot wstETHTotalSupplySlot 10
    balances := fun _ => 0 }

/-- Executable `unwrap` receipt: conversion result 15 drives the transfer
calldata, while the caller's inherited balance and total-supply slots are both
burned by 10. -/
theorem unwrap_bridge_receipt :
    let result := runUnwrap unwrapCallee unwrapBridgeContext (2 : Address) 10 unwrapBridgeWorld
    result.outcome = .ok 15 ∧
      result.world.core.readMap wstETHBalancesSlot unwrapBridgeContext.sender = 0 ∧
      result.world.core.readSlot wstETHTotalSupplySlot = 0 ∧
      result.world.logs =
        [⟨unwrapBridgeContext.self, "Transfer", [1, 0, 10]⟩] ∧
      result.attempts =
        [⟨⟨unwrapBridgeContext.self, (2 : Address), 0, pooledEthBySharesCalldata 10⟩,
            true, abiWord 15, []⟩,
         ⟨⟨unwrapBridgeContext.self, (2 : Address), 0,
            erc20TransferCalldata unwrapBridgeContext.sender 15⟩, true, abiWord 1, []⟩] := by
  decide +kernel

theorem unwrap_revert_restores_caller_and_callee_world
    (callee : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) (fault : Fault)
    (h : (runUnwrap callee ctx stETH amount before).outcome = .error fault) :
    (runUnwrap callee ctx stETH amount before).world = before := by
  unfold runUnwrap LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : unwrap callee ctx stETH amount before = result at h ⊢
  cases result with
  | mk outcome after attempts => cases outcome <;> simp_all

/-- Top-level failure restores the exact caller/callee world.  Failed calls
remain in `attempts`, but no queue slot, balance, or callee effect commits. -/
theorem revert_restores_caller_and_callee_world
    (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) (fault : Fault)
  (h : (runClaimTo callee ctx requestId hint recipient before).outcome = .error fault) :
    (runClaimTo callee ctx requestId hint recipient before).world = before := by
  unfold runClaimTo LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : claimTo callee ctx requestId hint recipient before = result at h ⊢
  cases result with
  | mk outcome after attempts => cases outcome <;> simp_all

end LidoSRv3.Audit.Verity.AddressRecipientCallBridge
