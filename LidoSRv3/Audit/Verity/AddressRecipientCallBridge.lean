import LidoSRv3.Audit.Verity.AddressClaimBatchTx
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-!
# P-ADDRESS-1 recipient CALL bridge

`AddressClaimBatchTx.claimOne` is the storage-accurate, pinned
`claimWithdrawalsTo` iteration.  Its `externalCallBindTo` frame fixes the
actual target and value in the executable Verity receipt, but that primitive
has only a caller state.  This bridge supplies the missing callee-world step:
the same recipient and value are passed to the project-wide live CALL
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

/-- Execute a first-class CALL with the supplied ABI bytes.  The live helper
only accepts a selector, while the token entrypoints below have real argument
words.  As with `Live.call`, the callee sees the value-transferred world and a
rejection restores that transfer before the top-level rollback is applied. -/
def callWithCalldata (external : External) (ctx : Context) (target : Address)
    (payload : Bytes) (value : Uint256 := 0) : Exec Bytes := fun world =>
  let request : Request := ⟨ctx.self, target, value, payload⟩
  if (world.core.codeSize target.val).val = 0 then ⟨.error .empty, world, []⟩
  else if world.balances ctx.self < value.val then
    ⟨.error (.bubbled []), world, [⟨request, false, [], []⟩]⟩
  else
    match external request (transfer world ctx.self target value.val) with
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
  let request := readRequest before requestId hint
  match claimableEther request with
  | none => ⟨.error (.reason "ZeroShares"), world, []⟩
  | some payout =>
      match claimOne requestId hint recipient before with
      | .success _ after => ⟨.ok payout, { world with core := after }, []⟩
      | .revert reason _ => ⟨.error (.reason reason), world, []⟩

/-- Exact `WithdrawalQueueBase._sendValue` call frame (lines 475--480): it is
an EVM `CALL` to the recipient with value and **empty** calldata.  The generic
`Live.call` helper encodes a four-byte selector, so using it here would silently
change the real call target's input.  Rejection restores the value transfer;
success returns the callee's entire resulting world. -/
def emptyValueCall (external : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit := fun world =>
  let value : Uint256 := .ofNat payout
  let request : Request := ⟨ctx.self, recipient, value, []⟩
  if (world.core.codeSize recipient.val).val = 0 then
    ⟨.error .empty, world, []⟩
  else if world.balances ctx.self < value.val then
    ⟨.error (.bubbled []), world, [⟨request, false, [], []⟩]⟩
  else
    match external request (transfer world ctx.self recipient value.val) with
    | .rejected data => ⟨.error (.bubbled data), world, [⟨request, false, data, []⟩]⟩
    | .success data after => ⟨.ok (), after, [⟨request, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok (), after, [⟨request, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.bubbled data), world, [⟨request, false, data, nested⟩]⟩

/-- The recipient is the CALL target, not a post-hoc observation. -/
def payoutCall (external : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit :=
  emptyValueCall external ctx recipient payout

/-- One physical `_claim` followed by its value-bearing recipient CALL.  The
two layers have distinct jobs: `claimOne` fixes Solidity storage and its
`externalCallBindTo` receipt; `payoutCall` executes that same frame against a
callee that may accept, reject, or change its own world. -/
def claimTo (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) : Exec Unit := do
  let payout ← claimStorage ctx requestId hint recipient
  payoutCall external ctx recipient payout

def runClaimTo (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) :=
  run (claimTo external ctx requestId hint recipient) before

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

/-- `WithdrawalQueueERC721.transferFrom` through `_transfer`, restricted to
the literal `msg.sender == _from` branch.  Every guard is evaluated from the
caller and physical request word; the successful writes are the approval
deletion at `TOKEN_APPROVALS_POSITION` and the owner word at
`keccak256(abi.encode(requestId, QUEUE_POSITION)) + 1`. -/
def transferFrom (ctx : Context) (from recipient : Address) (requestId : Nat) :
    Exec Unit := fun world =>
  let before := { world.core with sender := ctx.sender }
  let metadata := requestMetadataWord before requestId
  if recipient = zeroAddress then ⟨.error (.reason "TransferToZeroAddress"), world, []⟩
  else if recipient = from then ⟨.error (.reason "TransferToThemselves"), world, []⟩
  else if requestId = 0 then ⟨.error (.reason "InvalidRequestId"), world, []⟩
  else if requestClaimed metadata then ⟨.error (.reason "RequestAlreadyClaimed"), world, []⟩
  else if requestOwner metadata != from then
    ⟨.error (.reason "TransferFromIncorrectOwner"), world, []⟩
  else if ctx.sender != from then ⟨.error (.reason "NotOwnerOrApproved"), world, []⟩
  else
    ⟨.ok (), { world with core :=
      (before.writeMapUint tokenApprovalsPosition (.ofNat requestId) 0).writeMapUint
        (queuePosition + 1) (.ofNat requestId) (withRequestOwner metadata recipient) }, []⟩

def runTransferFrom (ctx : Context) (from recipient : Address) (requestId : Nat)
    (before : World) :=
  run (transferFrom ctx from recipient requestId) before

/-- The direct ownership handoff is a top-level transaction too: every failed
guard returns the entry world, including every unrelated account's state. -/
theorem transfer_revert_restores_world
    (ctx : Context) (from recipient : Address) (requestId : Nat) (before : World)
    (fault : Fault)
    (h : (runTransferFrom ctx from recipient requestId before).outcome = .error fault) :
    (runTransferFrom ctx from recipient requestId before).world = before := by
  unfold runTransferFrom LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : transferFrom ctx from recipient requestId before <;> simp [hrun] at h ⊢

/-! ## `requestWithdrawals` one-item physical path -/

/-- `keccak256("lido.WithdrawalQueue.lastRequestId")`. -/
def lastRequestIdPosition : Nat :=
  0x8ee26abbbdf5335e3953ccf2204a79e845eecb5ab51f8398526746e4ea068041

/-- `keccak256("lido.WithdrawalQueue.lastReportTimestamp")`. -/
def lastReportTimestampPosition : Nat :=
  0x6825d6bead788134d1ac062bbb7f1f0e4a9e13182688453e79955a721d58c45d

def transferFromSelector : Nat := 0x23b872dd
def getSharesByPooledEthSelector : Nat := 0x19208451

def abiWord (n : Nat) : Bytes := encode 32 n
def abiAddress (a : Address) : Bytes := abiWord a.toNat

def stETHTransferFromCalldata (from queue : Address) (amount : Nat) : Bytes :=
  encode 4 transferFromSelector ++ abiAddress from ++ abiAddress queue ++ abiWord amount

def stETHSharesCalldata (amount : Nat) : Bytes :=
  encode 4 getSharesByPooledEthSelector ++ abiWord amount

/-- Solidity's packed `WithdrawalRequest` constructor, including the uint128
and uint40 narrowing performed by the source types. -/
def packEnqueuedAmounts (stETH shares : Nat) : Uint256 :=
  packAmounts (stETH % 2 ^ 128) (shares % 2 ^ 128)

def packEnqueuedMetadata (owner : Address) (timestamp reportTimestamp : Nat) : Uint256 :=
  .ofNat (owner.toNat + (timestamp % 2 ^ 40) * 2 ^ 160 +
    (reportTimestamp % 2 ^ 40) * 2 ^ 208)

/-- Physical `_enqueue` suffix.  Its request id, cumulative pair, report
timestamp, and owner all come from the current post-call storage world. -/
def enqueueRequest (ctx : Context) (owner : Address) (amount shares : Nat) : Exec Nat := fun world =>
  let state := world.core
  let lastId := (state.readSlot lastRequestIdPosition).val
  if lastId + 1 ≥ 2 ^ 256 then ⟨.error (.reason "RequestIdOverflow"), world, []⟩
  else
    let requestId := lastId + 1
    let previous := requestAmountsWord state lastId
    let cumulativeStETH := cumulativeStETH previous + amount
    let cumulativeShares := cumulativeShares previous + shares
    let reportTimestamp := (state.readSlot lastReportTimestampPosition).val
    let after :=
      ((state.writeSlot lastRequestIdPosition (.ofNat requestId)).writeMapUint
        queuePosition (.ofNat requestId) (packEnqueuedAmounts cumulativeStETH cumulativeShares)).writeMapUint
          (queuePosition + 1) (.ofNat requestId)
            (packEnqueuedMetadata owner state.blockTimestamp.val reportTimestamp)
    ⟨.ok requestId, { world with core := after }, []⟩

/-- One item of `WithdrawalQueue.requestWithdrawals`.  The queue calls the
configured stETH target twice: first `transferFrom(msg.sender, address(this),
amount)`, then `getSharesByPooledEth(amount)`.  Both replies are execution
results from `external`; there is no supplied success, balance, or allowance
bit.  Only after both calls return does the physical queue record commit. -/
def requestWithdrawals (external : External) (ctx : Context) (stETH : Address)
    (amount : Nat) (suppliedOwner : Address) : Exec Nat := do
  require (decide (100 ≤ amount) && decide (amount ≤ 1000 * 10 ^ 18))
    (.reason "RequestAmountOutOfRange")
  let owner := if suppliedOwner = zeroAddress then ctx.sender else suppliedOwner
  let _ ← callWithCalldata external ctx stETH (stETHTransferFromCalldata ctx.sender ctx.self amount)
  let sharesBytes ← callWithCalldata external ctx stETH (stETHSharesCalldata amount)
  let shares ← decodeWord sharesBytes
  enqueueRequest ctx owner amount shares.val

def runRequestWithdrawals (external : External) (ctx : Context) (stETH : Address)
    (amount : Nat) (suppliedOwner : Address) (before : World) :=
  run (requestWithdrawals external ctx stETH amount suppliedOwner) before

theorem request_revert_restores_caller_and_callee_world
    (external : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (suppliedOwner : Address) (before : World) (fault : Fault)
    (h : (runRequestWithdrawals external ctx stETH amount suppliedOwner before).outcome =
      .error fault) :
    (runRequestWithdrawals external ctx stETH amount suppliedOwner before).world = before := by
  unfold runRequestWithdrawals LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : requestWithdrawals external ctx stETH amount suppliedOwner before <;>
    simp [hrun] at h ⊢

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
      (state.writeMap wstETHBalancesSlot ctx.sender (.ofNat (balance.val - amount))).writeSlot
        wstETHTotalSupplySlot (.ofNat (supply.val - amount)) }, []⟩

/-- `WstETH.unwrap` (0.6.12, lines 69--75).  The stETH amount is decoded from
the configured stETH callee's `getPooledEthByShares` reply; then the bridge
burns the caller's actual wstETH slots and calls the same stETH target's
`transfer(msg.sender, amount)`.  Thus the recipient is the execution-derived
`ctx.sender`, and any callee rejection rolls back caller and callee worlds. -/
def unwrap (external : External) (ctx : Context) (stETH : Address) (amount : Nat) :
    Exec Nat := do
  require (decide (amount ≠ 0)) (.reason "wstETH: zero amount unwrap not allowed")
  let amountBytes ← callWithCalldata external ctx stETH (pooledEthBySharesCalldata amount)
  let stETHAmount ← decodeWord amountBytes
  burnWstETH ctx amount
  let _ ← callWithCalldata external ctx stETH (erc20TransferCalldata ctx.sender stETHAmount.val)
  pure stETHAmount.val

def runUnwrap (external : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) :=
  run (unwrap external ctx stETH amount) before

theorem unwrap_revert_restores_caller_and_callee_world
    (external : External) (ctx : Context) (stETH : Address) (amount : Nat)
    (before : World) (fault : Fault)
    (h : (runUnwrap external ctx stETH amount before).outcome = .error fault) :
    (runUnwrap external ctx stETH amount before).world = before := by
  unfold runUnwrap LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : unwrap external ctx stETH amount before <;> simp [hrun] at h ⊢

/-- Top-level failure restores the exact caller/callee world.  Failed calls
remain in `attempts`, but no queue slot, balance, or callee effect commits. -/
theorem revert_restores_caller_and_callee_world
    (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) (fault : Fault)
  (h : (runClaimTo external ctx requestId hint recipient before).outcome = .error fault) :
    (runClaimTo external ctx requestId hint recipient before).world = before := by
  unfold runClaimTo LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : claimTo external ctx requestId hint recipient before <;>
    simp [hrun] at h ⊢

end LidoSRv3.Audit.Verity.AddressRecipientCallBridge
