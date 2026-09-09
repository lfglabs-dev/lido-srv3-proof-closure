import audit.trio.deposit.RouterDeposit
import audit.trio.deposit.Tests.Verity.Deposit

namespace audit.trio.deposit.Tests.Verity.RouterDeposit
open audit.trio.deposit
open audit.trio.deposit.RouterDeposit
open LidoSRv3.Audit.Source.TrioAlloc1

def addr (n : Nat) : Address := ⟨n % 2^160, Nat.mod_lt _ (by omega)⟩
def ctx : Context := ⟨addr 7, addr 7, true, some (word 99), addr 42, 123, 456⟩
def before : World := ⟨5, 9, 1, 2, [], []⟩
def accepts : External := ⟨fun _ => true⟩

def routerConfig : Config := ⟨word DEPOSIT_SIZE, word (2 * DEPOSIT_SIZE)⟩
def routerWithdrawal : WithdrawDepositableEther := fun amount seeds =>
  if amount = word (2 * DEPOSIT_SIZE) ∧ seeds = word 2 then .ok () else .error .exceptionalCall
def execution : DepositExecution :=
  ⟨word 7, word DEPOSIT_SIZE, audit.trio.deposit.Tests.Verity.twoKeyData,
    ⟨2 * DEPOSIT_SIZE, 2, 2 * DEPOSIT_SIZE, 32, 64⟩,
    some ⟨word (2 * DEPOSIT_SIZE), word 2⟩⟩

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
  depositSize := 32
  withdraw := routerWithdrawal
  execution := execution
  executed := by native_decide

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
