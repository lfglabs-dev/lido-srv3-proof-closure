import audit.trio.deposit.RouterDeposit

namespace audit.trio.deposit.Tests.Verity.RouterDeposit
open audit.trio.deposit
open audit.trio.deposit.RouterDeposit
open LidoSRv3.Audit.Source.TrioAlloc1

def addr (n : Nat) : Address := ⟨n % 2^160, Nat.mod_lt _ (by omega)⟩
def ctx : Context := ⟨addr 7, addr 7, true, some (word 99), 123, 456⟩
def before : World := ⟨5, 9, 1, 2, [], []⟩
def accepts : External := ⟨true, fun _ => true⟩
def twoKeys : Input := ⟨word 3, 2, DEPOSIT_SIZE, 96, 192⟩

def expectSuccess (result : Result) : IO Unit :=
  match result.outcome with
  | .error fault => throw (IO.userError s!"unexpected fault: {repr fault}")
  | .ok () =>
      unless result.world.routerBalance = before.routerBalance &&
          result.world.beaconBalance = before.beaconBalance + 2 * DEPOSIT_SIZE &&
          result.world.lastDepositAt = 123 && result.world.lastDepositBlock = 456 &&
          result.world.calls.map (fun call => call.value) = [DEPOSIT_SIZE, DEPOSIT_SIZE] do
        throw (IO.userError s!"wrong committed world: {repr result.world}")

#eval expectSuccess (execute accepts ctx twoKeys before)

/-- The state writer runs even when the module returned zero keys. -/
def zeroKeys : Input := ⟨word 3, 0, DEPOSIT_SIZE, 0, 0⟩
def expectZeroReturn (result : Result) : IO Unit :=
  match result.outcome with
  | .error fault => throw (IO.userError s!"unexpected zero-key fault: {repr fault}")
  | .ok () => unless result.world.lastDepositAt = 123 &&
      result.world.lastDepositBlock = 456 && result.world.routerBalance = before.routerBalance &&
      result.world.beaconBalance = before.beaconBalance && result.world.calls = [] &&
      result.world.depositedEvents = [(word 3, 0)] do
    throw (IO.userError s!"wrong zero-key world: {repr result.world}")

#eval expectZeroReturn (execute accepts ctx zeroKeys before)

def expectRollback (wanted : Fault) (result : Result) : IO Unit :=
  match result.outcome with
  | .ok () => throw (IO.userError "unexpected success")
  | .error actual => unless actual == wanted && result.world == before do
      throw (IO.userError s!"failure did not roll back: {repr result}")

#eval expectRollback .notAuthorized
  (execute accepts {ctx with caller := addr 8} twoKeys before)
#eval expectRollback .moduleNotActive
  (execute accepts {ctx with moduleActive := false} twoKeys before)
#eval expectRollback .unsupportedWithdrawalCredentials
  (execute accepts {ctx with withdrawalCredentials := none} twoKeys before)
#eval expectRollback .invalidPublicKeysBatchLength
  (execute accepts ctx {twoKeys with publicKeysBatchLength := 95} before)
#eval expectRollback .invalidSignaturesBatchLength
  (execute accepts ctx {twoKeys with signaturesBatchLength := 191} before)
#eval expectRollback .lidoCallFailed
  (execute {accepts with lidoAccepts := false} ctx twoKeys before)
#eval expectRollback .beaconCallFailed
  (execute {accepts with beaconAccepts := fun i => i = 0} ctx twoKeys before)

/- If the router immutable differs from the helper constant, all helper calls
still transfer 32 ether and the source assertion rejects the leftover balance. -/
#eval expectRollback .balanceAssertion
  (execute accepts ctx {twoKeys with maxEBType1 := 33 * 10^18} before)

end audit.trio.deposit.Tests.Verity.RouterDeposit
