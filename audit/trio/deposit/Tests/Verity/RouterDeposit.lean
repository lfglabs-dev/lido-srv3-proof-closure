import audit.trio.deposit.RouterDeposit
import audit.trio.deposit.Tests.Verity.Deposit

namespace audit.trio.deposit.Tests.Verity.RouterDeposit
open audit.trio.deposit
open audit.trio.deposit.RouterDeposit
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1

def addr (n : Nat) : Address := ⟨n % 2^160, Nat.mod_lt _ (by omega)⟩
def ctx : Context := ⟨addr 7, addr 7, true, some (word 99), addr 42, 123, 456⟩
def before : World := ⟨5, 9, 1, 2, [], []⟩
def accepts : External := ⟨fun _ => true⟩

def routerConfig : Config := ⟨word DEPOSIT_SIZE, word (2 * DEPOSIT_SIZE)⟩
def routerWithdrawal : WithdrawDepositableEther := fun amount seeds =>
  if amount = word (2 * DEPOSIT_SIZE) ∧ seeds = word 2 then .ok () else .error .exceptionalCall
def execution : DepositExecution :=
  ⟨word 7, word DEPOSIT_SIZE, audit.trio.deposit.Tests.Verity.twoKeyData,
    ⟨2 * DEPOSIT_SIZE, 2, 2 * DEPOSIT_SIZE, DEPOSIT_SIZE, 2 * DEPOSIT_SIZE⟩,
    some ⟨word (2 * DEPOSIT_SIZE), word 2⟩⟩

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
def liveResult := Live.run (Live.withdrawDepositableEther liveExternal liveContext
  (Live.word (2 * DEPOSIT_SIZE)) (Live.word 2)) liveBefore
def liveReceipt : LiveWithdrawalExecution execution where
  external := liveExternal
  context := liveContext
  before := liveBefore
  after := liveResult.world
  attempts := liveResult.attempts
  executed := by rfl
  callbackCredit := by native_decide
  callbackObserved := by native_decide

def linked : SuccessfulDepositExecution where
  layout := audit.trio.deposit.Tests.Verity.layout
  storage := audit.trio.deposit.Tests.Verity.storage
  oracle := audit.trio.deposit.Tests.Verity.oracle
  config := routerConfig
  requested := word (2 * DEPOSIT_SIZE + 1)
  before := []
  after := audit.trio.deposit.Tests.Verity.successfulAfter
  moduleId := word 7
  limits := audit.trio.deposit.Tests.Verity.limits
  obtainDepositData := audit.trio.deposit.Tests.Verity.exactTargetModule
  depositSize := DEPOSIT_SIZE
  withdraw := routerWithdrawal
  execution := execution
  executed := by native_decide
  liveWithdrawal := some liveReceipt
  liveWithdrawalIffNonzero := by native_decide

def expectSuccess (result : Result) : IO Unit :=
  match result.outcome with
  | .error fault => throw (IO.userError s!"unexpected fault: {repr fault}")
  | .ok () =>
      unless result.world.routerBalance = before.routerBalance &&
          result.world.beaconBalance = before.beaconBalance + 2 * DEPOSIT_SIZE &&
          result.world.lastDepositAt = 123 && result.world.lastDepositBlock = 456 &&
          result.world.calls.map (fun call => call.value) = [DEPOSIT_SIZE, DEPOSIT_SIZE] &&
          result.world.calls.map (fun call => call.publicKey.length) = [48, 48] &&
          result.world.calls.map (fun call => call.signature.length) = [96, 96] &&
          result.world.calls.map (fun call => call.depositContract) = [addr 42, addr 42] &&
          result.world.calls.map (fun call => call.depositDataRoot.length) = [32, 32] do
        throw (IO.userError s!"wrong committed world: {repr result.world}")

#eval expectSuccess (execute accepts ctx linked before)

def expectRollback (wanted : Fault) (result : Result) : IO Unit :=
  match result.outcome with
  | .ok () => throw (IO.userError "unexpected success")
  | .error actual => unless actual == wanted && result.world == before do
      throw (IO.userError s!"failure did not roll back: {repr result}")

#eval expectRollback .notAuthorized
  (execute accepts {ctx with caller := addr 8} linked before)
#eval expectRollback .moduleNotActive
  (execute accepts {ctx with moduleActive := false} linked before)
#eval expectRollback .unsupportedWithdrawalCredentials
  (execute accepts {ctx with withdrawalCredentials := none} linked before)
#eval expectRollback .beaconCallFailed
  (execute ⟨fun call => call.index = 0⟩ ctx linked before)

/-- These are the three Solidity 0.8 multiplication sites. -/
example : checkedMulNat (2^255) 32 = none := by native_decide
example : checkedProduct 48 (2^255) = .error .arithmeticOverflow := by native_decide
example : checkedProduct 96 (2^255) = .error .arithmeticOverflow := by native_decide

end audit.trio.deposit.Tests.Verity.RouterDeposit
