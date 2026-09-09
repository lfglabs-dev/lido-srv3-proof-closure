import audit.trio.deposit.RouterDeposit
import audit.trio.deposit.Tests.Verity.Deposit

namespace audit.trio.deposit.Tests.Verity.RouterDeposit
open audit.trio.deposit
open audit.trio.deposit.RouterDeposit
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1

def addr (n : Nat) : Address := ⟨n % 2^160, Nat.mod_lt _ (by omega)⟩
def ctx : Context := ⟨addr 7, addr 7, true, some (word 99), addr 42, 123, 456⟩

def routerConfig : Config := ⟨word DEPOSIT_SIZE, word (2 * DEPOSIT_SIZE)⟩

def liveAddr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n
def liveLido := liveAddr 1
def liveLocator := liveAddr 2
def liveQueue := liveAddr 3
def liveOracle := liveAddr 4
def liveRouter := liveAddr 7
def liveContext : Live.Context := ⟨liveLido, liveRouter⟩
def liveCore : Verity.ContractState :=
  let core := Verity.defaultState
  let core := core.writeContractSlot liveLido.val Live.locatorSlot (Live.word liveLocator.val)
  let core := core.writeContractSlot liveLido.val Live.activeSlot (Live.word 1)
  let core := core.writeContractSlot liveLido.val Live.bufferSlot (Live.word (2 * DEPOSIT_SIZE))
  { core with codeSize := fun _ => Live.word 1 }
def liveBefore : Live.World :=
  ⟨liveCore, fun a => if a = liveLido then 2 * DEPOSIT_SIZE else if a = liveRouter then 5 else 0, []⟩
def liveExternal : Live.External := fun req w =>
  if req.target = liveLocator then
    if req.payload = Live.encode 4 0x37d5fe99 then .success (Live.encode 32 liveQueue.val) w
    else if req.payload = Live.encode 4 0xef6c064c then .success (Live.encode 32 liveRouter.val) w
    else if req.payload = Live.encode 4 0x5a2031f9 then .success (Live.encode 32 liveOracle.val) w
    else .rejected []
  else if req.target = liveQueue then
    if req.payload = Live.encode 4 0x2b95b781 ∨ req.payload = Live.encode 4 0xd0fb84e8 then
      .success (Live.encode 32 0) w
    else .rejected []
  else if req.target = liveOracle ∧ req.payload = Live.encode 4 0x72f79b13 then
    .success (Live.encode 64 0) w
  else if req.target = liveRouter ∧ req.payload = Live.encode 4 0x13ae8460 then .success [] w
  else .rejected []

def inputs : Inputs where
  layout := audit.trio.deposit.Tests.Verity.layout
  storage := audit.trio.deposit.Tests.Verity.storage
  oracle := audit.trio.deposit.Tests.Verity.oracle
  config := routerConfig
  requested := word (2 * DEPOSIT_SIZE + 1)
  moduleId := word 7
  limits := audit.trio.deposit.Tests.Verity.limits
  obtainDepositData := audit.trio.deposit.Tests.Verity.exactTargetModule
  liveContext := liveContext

def before : World :=
  ⟨[], liveBefore, ⟨5, 9, 1, 2, [], []⟩⟩
def accepts : External := ⟨liveExternal, fun _ => true⟩

def successfulResult := execute accepts ctx inputs before

example : successfulResult.world.allocationTranscript =
    audit.trio.deposit.Tests.Verity.successfulAfter := by native_decide
example : (successfulResult.lidoAttempts.filter (fun attempt =>
    attempt.accepted && attempt.request.target = liveRouter &&
      attempt.request.value = Live.word (2 * DEPOSIT_SIZE) &&
      attempt.request.payload = Live.encode 4 0x13ae8460)).length = 1 := by native_decide

def expectSuccess (result : Result) : IO Unit :=
  match result.outcome with
  | .error fault => throw (IO.userError s!"unexpected fault: {repr fault}")
  | .ok () =>
      unless result.world.router.routerBalance = before.router.routerBalance &&
          result.world.live.balances liveRouter = before.live.balances liveRouter &&
          result.world.router.beaconBalance = before.router.beaconBalance + 2 * DEPOSIT_SIZE &&
          result.world.router.lastDepositAt = 123 && result.world.router.lastDepositBlock = 456 &&
          result.world.router.calls.map (fun call => call.value) = [DEPOSIT_SIZE, DEPOSIT_SIZE] &&
          result.world.router.calls.map (fun call => call.publicKey.length) = [48, 48] &&
          result.world.router.calls.map (fun call => call.signature.length) = [96, 96] &&
          result.world.router.calls.map (fun call => call.depositContract) = [addr 42, addr 42] &&
          result.world.router.calls.map (fun call => call.depositDataRoot.length) = [32, 32] do
        throw (IO.userError "wrong committed world")

#eval expectSuccess successfulResult

def expectRollback (wanted : Fault) (result : Result) : IO Unit :=
  match result.outcome with
  | .ok () => throw (IO.userError "unexpected success")
  | .error actual => unless actual == wanted &&
        result.world.allocationTranscript == before.allocationTranscript &&
        result.world.router == before.router &&
        result.world.live.balances liveRouter = before.live.balances liveRouter &&
        result.world.live.balances liveLido = before.live.balances liveLido do
      throw (IO.userError "failure did not roll back")

#eval expectRollback .notAuthorized
  (execute accepts {ctx with caller := addr 8} inputs before)
#eval expectRollback .moduleNotActive
  (execute accepts {ctx with moduleActive := false} inputs before)
#eval expectRollback .unsupportedWithdrawalCredentials
  (execute accepts {ctx with withdrawalCredentials := none} inputs before)
#eval expectRollback .beaconCallFailed
  (execute ⟨liveExternal, fun call => call.index = 0⟩ ctx inputs before)

def expectRawBeaconPrefix (result : Result) : IO Unit :=
  match result.outcome with
  | .ok () => throw (IO.userError "unexpected success")
  | .error actual =>
      unless actual == .beaconCallFailed &&
          result.world.router.calls.length = 1 &&
          result.world.router.calls.map (fun call => call.index) = [0] &&
          result.world.router.routerBalance = before.router.routerBalance + DEPOSIT_SIZE &&
          result.world.router.beaconBalance = before.router.beaconBalance + DEPOSIT_SIZE do
        throw (IO.userError "raw failure lost successful beacon prefix")

#eval expectRawBeaconPrefix
  (executeRaw ⟨liveExternal, fun call => call.index = 0⟩ ctx inputs before)

/-- These are the three Solidity 0.8 multiplication sites. -/
example : checkedMulNat (2^255) 32 = none := by native_decide
example : checkedProduct 48 (2^255) = .error .arithmeticOverflow := by native_decide
example : checkedProduct 96 (2^255) = .error .arithmeticOverflow := by native_decide

end audit.trio.deposit.Tests.Verity.RouterDeposit
