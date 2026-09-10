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

The recipient CALL remains an empty-calldata EVM CALL, including the EOA
success path; its actual success certificate is proved below. Full caller-renaming
correspondence remains separate from this necessary execution result.
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

local instance : DecidableEq Log := by
  intro a b
  by_cases h : a.emitter = b.emitter ∧ a.name = b.name ∧ a.values = b.values
  · exact isTrue (by cases a; cases b; simp_all)
  · exact isFalse (by
      intro hab
      apply h
      cases a
      cases b
      cases hab
      exact ⟨rfl, rfl, rfl⟩)

/-- `STATICCALL` has a distinct callee interface: it can return bytes but has
no post-world channel through which a state write could commit. -/
abbrev StaticExternal := Request → World → Except Fault Bytes

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
  | .success payout after => ⟨.ok payout, { world with core := after }, []⟩
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
  else if (world.core.codeSize recipient.val).val = 0 then
    -- EVM CALL to an EOA succeeds after value transfer; no callee is invoked.
    ⟨.ok (), transfer world ctx.self recipient value.val, [⟨request, true, [], []⟩]⟩
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
  let payout ← claimStorage ctx requestId hint recipient
  payoutCall callee ctx recipient payout
  -- WithdrawalQueueBase emits this before ERC-721's transfer/burn event.
  emit ctx "WithdrawalClaimed" [(.ofNat requestId), (.ofNat ctx.sender.toNat),
    (.ofNat recipient.toNat), (.ofNat payout)]
  emit ctx "Transfer" [(.ofNat ctx.sender.toNat), 0, (.ofNat requestId)]

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

/-- Deliberately rejecting code: the EOA receipt below proves it is never
consulted when the recipient has no code. -/
def rejectingCallee : External := fun _ _ => .rejected [0xff]

def claimBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

def eoaPayoutWorld : World :=
  { core := defaultState
    balances := fun address => if address = claimBridgeContext.self then 30 else 0 }

theorem eoa_empty_value_call_receipt :
    let result := emptyValueCall rejectingCallee claimBridgeContext (2 : Address) 30 eoaPayoutWorld
    result.outcome = .ok () ∧
      result.world.balances claimBridgeContext.self = 0 ∧
      result.world.balances (2 : Address) = 30 ∧
      result.attempts = [⟨⟨claimBridgeContext.self, (2 : Address), 30, []⟩, true, [], []⟩] := by
  decide +kernel

/-- The `twoClaimState` storage witness with a code-bearing recipient and a
separate account-balance world for the actual CALL. -/
def claimBridgeWorld : World :=
  { core := { twoClaimState with
      codeSize := fun address => if address = (2 : Address).toNat then 1 else 0 }
    balances := fun address => if address = claimBridgeContext.self then 70 else 0 }

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

/-- `isApprovedForAll[owner][operator]` is a Solidity nested mapping. -/
def operatorApprovalsPosition : Nat :=
  0xe6a0e71d546599dab4b90490502c456cf7c806a5710690dde406c1a77d7f25e7
def operatorApprovalSlot (owner operator : Address) : Nat :=
  Compiler.Proofs.nestedMappingSlotLocation operatorApprovalsPosition owner.toNat operator.toNat 0


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
      (before.readSlot (operatorApprovalSlot fromAddr ctx.sender)).val = 0 then
    ⟨.error (.reason "NotOwnerOrApproved"), world, []⟩
  else
    -- `_transfer` is owner-operated on this registered path. Approval and
    -- operator branches remain modeled guards, but are not evidence here.
    match removeOwnerRequest before fromAddr requestId with
    | none => ⟨.error (.reason "Panic(0x01)"), world, []⟩
    | some removed => match insertOwnerRequest removed recipient requestId with
      | none => ⟨.error (.reason "Panic(0x01)"), world, []⟩
      | some moved =>
        let core := (moved.writeMapUint tokenApprovalsPosition (.ofNat requestId) 0).writeSlot
          (queueMetadataPhysicalSlot requestId) (withRequestOwner metadata recipient)
        let after : World :=
          { core := core
            balances := world.balances
            logs := world.logs ++ [⟨ctx.self, "Transfer",
              [(.ofNat fromAddr.toNat), (.ofNat recipient.toNat), (.ofNat requestId)]⟩] }
        ⟨.ok (), after, []⟩

def runTransferFrom (ctx : Context) (fromAddr recipient : Address) (requestId : Nat)
    (before : World) :=
  run (transferFrom ctx fromAddr recipient requestId) before

def transferBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

def transferBridgeWorld : World :=
  let core := (defaultState.writeSlot (queueMetadataPhysicalSlot 1)
      (packMetadata (1 : Address) 5 false 9)).writeMapUint
        tokenApprovalsPosition 1 7 |>.writeSlot lastRequestIdPosition 1
  let core := match insertOwnerRequest core (1 : Address) 1 with
    | some after => after | none => core
  { core := core
    balances := fun _ => 0 }

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

/-- Solidity ABI `bool` decoding accepts only canonical zero and one words;
a 32-byte word alone is not a boolean proof. -/
def decodeAbiBool (data : Bytes) : Exec Bool := do
  let value ← decodeWord data
  if value.val = 0 then pure false
  else if value.val = 1 then pure true
  else fail .empty

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
    else
      let requestId := lastId + 1
      let reportTimestamp := (state.readSlot lastReportTimestampPosition).val
      let initial :=
        ((((state.writeSlot lastRequestIdPosition (.ofNat requestId)).writeSlot
          (queueAmountsPhysicalSlot requestId)
            (packEnqueuedAmounts cumulativeStETH cumulativeShares)).writeSlot
              (queueMetadataPhysicalSlot requestId)
                (packEnqueuedMetadata owner state.blockTimestamp.val reportTimestamp)))
      match insertOwnerRequest initial owner requestId with
      | none => ⟨.error (.reason "Panic(0x01)"), world, []⟩
      | some after =>
        let afterWorld : World :=
          { core := after
            balances := world.balances
            logs := world.logs ++ [⟨_ctx.self, "WithdrawalRequested",
              [(.ofNat requestId), (.ofNat _ctx.sender.toNat), (.ofNat owner.toNat),
                (.ofNat amount), (.ofNat shares)]⟩,
              ⟨_ctx.self, "Transfer", [0, (.ofNat owner.toNat), (.ofNat requestId)]⟩] }
        ⟨.ok requestId, afterWorld, []⟩

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
  let transferred ← decodeAbiBool transferReply
  require (decide transferred) (.reason "STETHTransferFailed")
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
    let core := (state.writeMap wstETHBalancesSlot ctx.sender (.ofNat (balance.val - amount))).writeSlot
      wstETHTotalSupplySlot (.ofNat (supply.val - amount))
    let after : World :=
      { core := core
        balances := world.balances
        logs := world.logs ++ [⟨ctx.self, "Transfer", [(.ofNat ctx.sender.toNat), 0, (.ofNat amount)]⟩] }
    ⟨.ok (), after, []⟩

/-- `STATICCALL` has no post-world channel, so state writes by its callee are
unrepresentable. It is deliberately not an alias of mutable CALL. -/
def staticCallWithCalldata (callee : StaticExternal) (ctx : Context) (target : Address)
    (payload : Bytes) : Exec Bytes := fun world =>
  let request : Request := ⟨ctx.self, target, 0, payload⟩
  if (world.core.codeSize target.val).val = 0 then ⟨.error .empty, world, []⟩
  else match callee request world with
    | .error fault => ⟨.error fault, world, [⟨request, false, [], []⟩]⟩
    | .ok data => ⟨.ok data, world, [⟨request, true, data, []⟩]⟩

/-- `WstETH.unwrap` (0.6.12, lines 69--75).  The stETH amount is decoded from
the configured stETH callee's `getPooledEthByShares` reply; then the bridge
burns the caller's actual wstETH slots and calls the same stETH target's
`transfer(msg.sender, amount)`.  Thus the recipient is the execution-derived
`ctx.sender`, and any callee rejection rolls back caller and callee worlds. -/
def unwrap (staticCallee : StaticExternal) (callee : External) (ctx : Context) (stETH : Address) (amount : Nat) :
    Exec Nat := do
  require (decide (amount ≠ 0)) (.reason "wstETH: zero amount unwrap not allowed")
  let amountBytes ← staticCallWithCalldata staticCallee ctx stETH (pooledEthBySharesCalldata amount)
  let stETHAmount ← decodeWord amountBytes
  burnWstETH ctx amount
  let transferReply ← callWithCalldata callee ctx stETH
    (erc20TransferCalldata ctx.sender stETHAmount.val)
  let _ ← decodeWord transferReply
  pure stETHAmount.val

def runUnwrap (staticCallee : StaticExternal) (callee : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) :=
  run (unwrap staticCallee callee ctx stETH amount) before

def unwrapBridgeContext : Context := ⟨(99 : Address), (1 : Address)⟩

/-- A concrete stETH callee for the unwrap receipt: its conversion reply is
the ABI word 15, and its later ERC20 transfer reply succeeds. -/
def unwrapCallee : External := fun request world =>
  if request.payload = pooledEthBySharesCalldata 10 then
    .success (abiWord 15) world
  else
    .success (abiWord 1) world

def unwrapStaticCallee : StaticExternal := fun request _ =>
  if request.payload = pooledEthBySharesCalldata 10 then .ok (abiWord 15)
  else .ok (abiWord 0)

def unwrapBridgeWorld : World :=
  { core := ({ defaultState with
      codeSize := fun address => if address = (2 : Address).toNat then 1 else 0 }).writeMap
        wstETHBalancesSlot unwrapBridgeContext.sender 10 |>.writeSlot wstETHTotalSupplySlot 10
    balances := fun _ => 0 }

/-- Executable `unwrap` receipt: conversion result 15 drives the transfer
calldata, while the caller's inherited balance and total-supply slots are both
burned by 10. -/
theorem unwrap_bridge_receipt :
    let result := runUnwrap unwrapStaticCallee unwrapCallee unwrapBridgeContext (2 : Address) 10 unwrapBridgeWorld
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
    (staticCallee : StaticExternal) (callee : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) (fault : Fault)
    (h : (runUnwrap staticCallee callee ctx stETH amount before).outcome = .error fault) :
    (runUnwrap staticCallee callee ctx stETH amount before).world = before := by
  unfold runUnwrap LidoSRv3.Audit.Source.TrioReserve1.Live.run at h ⊢
  generalize hresult : unwrap staticCallee callee ctx stETH amount before = result at h ⊢
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

/-! ## Actual successful execution certificates

These theorems invert the executable itself. They neither rely on finite
receipt axioms nor ask the caller to supply successful intermediate stages.
-/

private theorem bind_success {α β : Type} (first : Exec α) (next : α → Exec β)
    (before : World) (value : β)
    (h : (bindExec first next before).outcome = .ok value) :
    ∃ a, (first before).outcome = .ok a ∧
      (next a (first before).world).outcome = .ok value ∧
      (bindExec first next before).world = (next a (first before).world).world ∧
      (bindExec first next before).attempts =
        (first before).attempts ++ (next a (first before).world).attempts := by
  cases hx : (first before).outcome with
  | «error» fault => simp [bindExec, hx] at h
  | ok a => exact ⟨a, rfl, by simpa [bindExec, hx] using h,
      by simp [bindExec, hx], by simp [bindExec, hx]⟩

/-- The accepted recipient CALL: actual bytes, provisional transfer and either
EOA execution or the precise returned callee world. No recipient net-credit
claim is made for arbitrary successful callbacks. -/
def PayoutEffect (callee : External) (ctx : Context) (recipient : Address)
    (payout : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  let request : Request := ⟨ctx.self, recipient, .ofNat payout, []⟩
  let credited := transfer before ctx.self recipient (Verity.Core.Uint256.ofNat payout).val
  before.balances ctx.self ≥ (Verity.Core.Uint256.ofNat payout).val ∧
    ∃ returned nested,
      attempts = [⟨request, true, returned, nested⟩] ∧
      (((before.core.codeSize recipient.val).val = 0 ∧
          after = credited ∧ returned = [] ∧ nested = []) ∨
       ((before.core.codeSize recipient.val).val ≠ 0 ∧
         ((callee request credited = .success returned after ∧ nested = []) ∨
           callee request credited = .successWithTrace returned after nested)))

theorem emptyValueCall_success (callee : External) (ctx : Context)
    (recipient : Address) (payout : Nat) (before : World)
    (h : (emptyValueCall callee ctx recipient payout before).outcome = .ok ()) :
    PayoutEffect callee ctx recipient payout before
      (emptyValueCall callee ctx recipient payout before).world
      (emptyValueCall callee ctx recipient payout before).attempts := by
  by_cases hf : before.balances ctx.self < (Verity.Core.Uint256.ofNat payout).val
  · simp only [emptyValueCall, if_pos hf] at h
    contradiction
  · by_cases he : (before.core.codeSize recipient.val).val = 0
    · simpa only [emptyValueCall, if_neg hf, if_pos he] using
        (show PayoutEffect callee ctx recipient payout before
          (transfer before ctx.self recipient (Verity.Core.Uint256.ofNat payout).val)
          [⟨⟨ctx.self, recipient, .ofNat payout, []⟩, true, [], []⟩] from
          ⟨Nat.le_of_not_gt hf, [], [], rfl, Or.inl ⟨he, rfl, rfl, rfl⟩⟩)
    · cases hc : callee ⟨ctx.self, recipient, .ofNat payout, []⟩
          (transfer before ctx.self recipient (Verity.Core.Uint256.ofNat payout).val) with
      | rejected data => simp only [emptyValueCall, if_neg hf, if_neg he, hc] at h; contradiction
      | rejectedWithTrace data nested => simp only [emptyValueCall, if_neg hf, if_neg he, hc] at h; contradiction
      | success data after =>
        simp only [emptyValueCall, if_neg hf, if_neg he, hc]
        exact ⟨Nat.le_of_not_gt hf, data, [], rfl, Or.inr ⟨he, Or.inl ⟨hc, rfl⟩⟩⟩
      | successWithTrace data after nested =>
        simp only [emptyValueCall, if_neg hf, if_neg he, hc]
        exact ⟨Nat.le_of_not_gt hf, data, nested, rfl, Or.inr ⟨he, Or.inr hc⟩⟩

/-- The two events are appended only after the recipient callback returns,
using the source msg.sender rather than re-reading callback-modified storage. -/
def claimEvents (ctx : Context) (requestId : Nat) (recipient : Address)
    (payout : Nat) (world : World) : World :=
  { world with logs := world.logs ++
      [⟨ctx.self, "WithdrawalClaimed", [.ofNat requestId, .ofNat ctx.sender.toNat,
        .ofNat recipient.toNat, .ofNat payout]⟩,
       ⟨ctx.self, "Transfer", [.ofNat ctx.sender.toNat, 0, .ofNat requestId]⟩] }

/-- One actual claim: checked physical storage computes the payout consumed
by its sole CALL, then that CALL's returned world receives the source events. -/
def ClaimEffect (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before after : World) (attempts : List Attempt) : Prop :=
  ∃ payout dirty called,
    claimOne requestId hint recipient {before.core with sender := ctx.sender} =
      .success payout dirty ∧
    requestId ≠ 0 ∧
    requestId ≤ (before.core.readSlot lastFinalizedRequestIdPosition).val ∧
    requestClaimed (requestMetadataWord before.core requestId) = false ∧
    requestOwner (requestMetadataWord before.core requestId) = ctx.sender ∧
    payout < 2 ^ 256 ∧
    (∃ removed, prepareClaim requestId hint recipient {before.core with sender := ctx.sender} =
      .success payout removed ∧ payout ≤ (removed.readSlot lockedEtherAmountPosition).val ∧
      dirty = removed.writeSlot lockedEtherAmountPosition
        (.ofNat ((removed.readSlot lockedEtherAmountPosition).val - payout))) ∧
    PayoutEffect callee ctx recipient payout {before with core := dirty} called attempts ∧
    after = claimEvents ctx requestId recipient payout called

/-- A chain records every actual intermediate world, including the callback
world used by the next request. It is not a list of independently supplied
successful-stage premises. -/
inductive ClaimChain (callee : External) (ctx : Context) (recipient : Address) :
    List Nat → List Nat → World → World → List Attempt → Prop
  | nil (world : World) : ClaimChain callee ctx recipient [] [] world world []
  | cons {requestId hint requestIds hints before middle after first rest} :
      ClaimEffect callee ctx requestId hint recipient before middle first →
      ClaimChain callee ctx recipient requestIds hints middle after rest →
      ClaimChain callee ctx recipient (requestId :: requestIds) (hint :: hints)
        before after (first ++ rest)


private theorem claimStorage_success (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) (payout : Nat)
    (h : (claimStorage ctx requestId hint recipient before).outcome = .ok payout) :
    ∃ dirty, claimOne requestId hint recipient {before.core with sender := ctx.sender} =
      .success payout dirty ∧
      (claimStorage ctx requestId hint recipient before).world = {before with core := dirty} ∧
      (claimStorage ctx requestId hint recipient before).attempts = [] := by
  cases hc : claimOne requestId hint recipient {before.core with sender := ctx.sender} with
  | success amount dirty =>
    simp only [claimStorage, hc] at h ⊢
    cases h
    exact ⟨dirty, rfl, rfl, trivial⟩
  | «revert» reason rollback => simp [claimStorage, hc] at h

theorem claimTo_success (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World)
    (h : (claimTo callee ctx requestId hint recipient before).outcome = .ok ()) :
    ClaimEffect callee ctx requestId hint recipient before
      (claimTo callee ctx requestId hint recipient before).world
      (claimTo callee ctx requestId hint recipient before).attempts := by
  obtain ⟨payout, hs, ht, hw, ha⟩ := bind_success _ _ before () h
  obtain ⟨dirty, hd, hsw, hsa⟩ := claimStorage_success ctx requestId hint recipient before payout hs
  obtain ⟨u, hc, he, hcw, hca⟩ := bind_success _ _ _ () ht
  cases u
  have hp := emptyValueCall_success callee ctx recipient payout
    (claimStorage ctx requestId hint recipient before).world hc
  have hg := claimOne_success_guards requestId hint recipient _ dirty payout hd
  obtain ⟨removed, hprep, hlocked, hfit, hdirty⟩ :=
    claimOne_success_storage requestId hint recipient _ dirty payout hd
  refine ⟨payout, dirty, (payoutCall callee ctx recipient payout (claimStorage ctx requestId hint recipient before).world).world, hd, hg.1, hg.2.1, hg.2.2.1, hg.2.2.2, hfit, ⟨removed, hprep, hlocked, hdirty⟩, ?_, ?_⟩
  · have hat : (claimTo callee ctx requestId hint recipient before).attempts =
        (payoutCall callee ctx recipient payout
          (claimStorage ctx requestId hint recipient before).world).attempts := by
        simp [claimTo, Bind.bind, bindExec, hs, hc,
          LidoSRv3.Audit.Source.TrioReserve1.Live.emit, pureExec, hsa]
    rw [hat, ← hsw]
    exact hp
  · simp [claimTo, Bind.bind, bindExec, hs, hc, LidoSRv3.Audit.Source.TrioReserve1.Live.emit, pureExec, claimEvents, List.append_assoc]

/-- One-claim wrapper derives its certificate from root success as well. -/
theorem runClaimTo_success (callee : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World)
    (h : (runClaimTo callee ctx requestId hint recipient before).outcome = .ok ()) :
    ClaimEffect callee ctx requestId hint recipient before
      (runClaimTo callee ctx requestId hint recipient before).world
      (runClaimTo callee ctx requestId hint recipient before).attempts := by
  have hs : (claimTo callee ctx requestId hint recipient before).outcome = .ok () := by
    cases ho : (claimTo callee ctx requestId hint recipient before).outcome with
    | ok u => cases u; rfl
    | «error» fault => simp [runClaimTo, run, ho] at h
  simpa only [runClaimTo, run, hs] using claimTo_success callee ctx requestId hint recipient before hs

theorem claimWithdrawalsLoop_success (callee : External) (ctx : Context)
    (recipient : Address) (requestIds hints : List Nat) (before : World)
    (h : (claimWithdrawalsLoop callee ctx requestIds hints recipient before).outcome = .ok ()) :
    ClaimChain callee ctx recipient requestIds hints before
      (claimWithdrawalsLoop callee ctx requestIds hints recipient before).world
      (claimWithdrawalsLoop callee ctx requestIds hints recipient before).attempts := by
  induction requestIds generalizing hints before with
  | nil =>
    cases hints with
    | nil => exact ClaimChain.nil before
    | cons hint hints => simp [claimWithdrawalsLoop] at h
  | cons requestId requestIds ih =>
    cases hints with
    | nil => simp [claimWithdrawalsLoop] at h
    | cons hint hints =>
      obtain ⟨u, hc, ht, hw, ha⟩ := bind_success _ _ before () h
      cases u
      have first := claimTo_success callee ctx requestId hint recipient before hc
      have rest := ih hints _ ht
      simpa only [claimWithdrawalsLoop, Bind.bind, bindExec, hc] using ClaimChain.cons first rest

/-- Necessary same-world certificate from actual root success. The recipient
and length guards and every physical claim/CALL/event step are derived. -/
theorem runClaimWithdrawalsTo_success (callee : External) (ctx : Context)
    (requestIds hints : List Nat) (recipient : Address) (before : World)
    (h : (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).outcome = .ok ()) :
    recipient ≠ zeroAddress ∧ requestIds.length = hints.length ∧
      ClaimChain callee ctx recipient requestIds hints before
        (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).world
        (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).attempts := by
  have hs : (claimWithdrawalsTo callee ctx requestIds hints recipient before).outcome = .ok () := by
    cases ho : (claimWithdrawalsTo callee ctx requestIds hints recipient before).outcome with
    | ok u => cases u; rfl
    | «error» fault => simp [runClaimWithdrawalsTo, run, ho] at h
  have hr : runClaimWithdrawalsTo callee ctx requestIds hints recipient before =
      claimWithdrawalsTo callee ctx requestIds hints recipient before := by
    simp [runClaimWithdrawalsTo, run, hs]
  have hn : recipient ≠ zeroAddress := by
    by_contra hn
    simp [claimWithdrawalsTo, hn, LidoSRv3.Audit.Source.TrioReserve1.Live.require, Bind.bind, bindExec, fail] at hs
  have hn0 : recipient ≠ 0 := hn
  have hl : requestIds.length = hints.length := by
    by_contra hl
    simp [claimWithdrawalsTo, hn, hn0, hl, zeroAddress, Pure.pure, LidoSRv3.Audit.Source.TrioReserve1.Live.require, Bind.bind, bindExec, fail, pureExec] at hs
  have he : claimWithdrawalsTo callee ctx requestIds hints recipient before =
      claimWithdrawalsLoop callee ctx requestIds hints recipient before := by
    simp [claimWithdrawalsTo, hn, hn0, hl, zeroAddress, Pure.pure, LidoSRv3.Audit.Source.TrioReserve1.Live.require, Bind.bind, bindExec, pureExec]
  rw [hr, he]
  exact ⟨hn, hl, claimWithdrawalsLoop_success callee ctx recipient requestIds hints before (by rwa [he] at hs)⟩

#print axioms claimTo_success
#print axioms runClaimWithdrawalsTo_success
end LidoSRv3.Audit.Verity.AddressRecipientCallBridge
