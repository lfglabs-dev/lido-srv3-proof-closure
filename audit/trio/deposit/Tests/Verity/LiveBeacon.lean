import audit.trio.deposit.LiveBeacon
import audit.trio.deposit.Tests.Verity.Deposit

/-! Executable regressions for the live-callee deposit suffix: one fixture world
with Lido, router, locator, queue, oracle, consensus and beacon accounts. -/
namespace audit.trio.deposit.Tests.Verity.LiveBeacon
open audit.trio.deposit audit.trio.deposit.LiveBeacon
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TopupBeaconCallee

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def addr (n : Nat) : Address := ⟨n % 2^160, Nat.mod_lt _ (by omega)⟩
def address (n : Nat) : Live.Address := Verity.Core.Address.ofNat n
def ether : Nat := 10^18

/-- Lido 1, router 2, locator 3, queue 4, oracle 5, consensus 6, DSM 7, beacon 8. -/
def ctx : RouterDeposit.Context := ⟨addr 7, addr 7, true, some (word 99), addr 8, 123, 456⟩
def liveContext : Live.Context := ⟨address 1, address 2⟩
def config : Pipeline.Config :=
  ⟨address 3, ⟨address 4, address 2, address 5⟩, ⟨Live.word 0, Live.word 1⟩, address 6,
    ⟨0, 1, 1, 7⟩, address 1⟩

def liveWorld (routerBalance beaconCount : Nat) : Live.World :=
  let core := {Verity.defaultState with codeSize := fun _ => Live.word 1, blockTimestamp := Live.word 1}
  let core := (core.writeContractSlot 1 Live.locatorSlot (Live.word 3)).writeContractSlot 5
    Oracle.consensusSlot (Live.word 6)
  let core := (core.writeContractSlot 1 Live.activeSlot (Live.word 1)).writeContractSlot 1
    Live.bufferSlot (Live.word (100 * ether))
  let core := core.writeContractSlot 4 Queue.bunkerSlot (Live.word (2^256 - 1))
  let core := (core.writeContractSlot 6 7 (Live.word (2^64))).writeContractSlot 1 Live.seedSlot (Live.word 9)
  let core := core.writeContractSlot 8 countSlot (Live.word beaconCount)
  ⟨core, fun a => if a = address 1 then 100 * ether else if a = address 2 then routerBalance
    else if a = address 8 then 11 else 0, []⟩

def liveBefore : Live.World := liveWorld 7 3
def reject : Live.External := fun _ _ => .rejected []
def rejectStatic : StaticCall.External := fun _ _ => .rejected []
def callee := Pipeline.external (fun _ => Live.word 0) config rejectStatic reject

def routerConfig : Config := ⟨word DEPOSIT_SIZE, word (2 * DEPOSIT_SIZE)⟩
/-- `storage` is a Verity DSL token once `LidoSRv3.Audit.Verity.*` is imported
(`Verity.Macro.Syntax`), so the legitimate `Inputs.storage` field is bound with
the escaped identifier; the field itself is unchanged. -/
def inputs : RouterDeposit.Inputs where
  layout := audit.trio.deposit.Tests.Verity.layout
  «storage» := audit.trio.deposit.Tests.Verity.storage
  oracle := audit.trio.deposit.Tests.Verity.oracle
  config := routerConfig
  requested := word (2 * DEPOSIT_SIZE + 1)
  moduleId := word 7
  limits := audit.trio.deposit.Tests.Verity.limits
  obtainDepositData := audit.trio.deposit.Tests.Verity.exactTargetModule
  liveContext := liveContext

def before : World := ⟨[], liveBefore, ⟨1, 2, []⟩⟩
def result := execute callee ctx inputs before

def acceptedBeaconCalls (attempts : List Live.Attempt) : List Live.Attempt :=
  attempts.filter fun a => a.accepted && a.request.target = address 8 &&
    a.request.caller = address 2 && a.request.value = Live.word DEPOSIT_SIZE

def expectSuccess (r : Result) : IO Unit :=
  match r.outcome with
  | .error fault => throw (IO.userError s!"unexpected fault: {repr fault}")
  | .ok () =>
    unless r.world.live.balances (address 2) = 7 &&
        r.world.live.balances (address 1) + 2 * DEPOSIT_SIZE = 100 * ether &&
        r.world.live.balances (address 8) = 11 + 2 * DEPOSIT_SIZE &&
        r.world.live.balances (address 9) = 0 &&
        (r.world.live.core.readContractSlot 8 countSlot).val = 5 &&
        r.world.metadata = ⟨123, 456, [(word 7, 2 * DEPOSIT_SIZE)]⟩ &&
        (acceptedBeaconCalls r.attempts).length = 2 &&
        (r.attempts.filter fun a => a.accepted && a.request.caller = address 1 &&
          a.request.target = address 2 && a.request.value = Live.word (2 * DEPOSIT_SIZE) &&
          a.request.payload = Live.encode 4 0x13ae8460).length = 1 &&
        (r.world.live.logs.filter fun l => l.name = "DepositEvent").length = 2 &&
        (r.world.live.logs.filter fun l => l.name = "DepositedValidatorsChanged").length = 1 do
      throw (IO.userError "wrong committed live world")

#eval expectSuccess result

/-- Late failure: the beacon tree has room for one more deposit. The first CALL
is accepted by the real callee; the second is rejected by its tree-full guard. -/
def fullTree : World := ⟨[], liveWorld 7 (maxCount - 1), ⟨1, 2, []⟩⟩
def lateRaw := executeRaw callee ctx inputs fullTree
def late := execute callee ctx inputs fullTree

def expectLate : IO Unit := do
  match late.outcome with
  | .error (.live (.bubbled data)) =>
    unless data = "merkle tree full".toUTF8.toList do
      throw (IO.userError "late failure has the wrong callee reason")
  | _ => throw (IO.userError "late failure did not surface the callee rejection")
  unless late.world.live.balances (address 2) = 7 &&
      late.world.live.balances (address 1) = 100 * ether &&
      late.world.live.balances (address 8) = 11 &&
      (late.world.live.core.readContractSlot 8 countSlot).val = maxCount - 1 &&
      late.world.live.logs.length = 0 &&
      late.world.metadata = fullTree.metadata &&
      late.world.allocationTranscript = fullTree.allocationTranscript do
    throw (IO.userError "late failure did not roll back the whole world")
  unless lateRaw.world.live.balances (address 8) = 11 + DEPOSIT_SIZE &&
      lateRaw.world.live.balances (address 2) = 7 + DEPOSIT_SIZE &&
      (lateRaw.world.live.core.readContractSlot 8 countSlot).val = maxCount &&
      (acceptedBeaconCalls lateRaw.attempts).length = 1 &&
      (lateRaw.attempts.reverse.take 2).reverse.map (fun a => (a.request.target == address 8, a.accepted))
        = [(true, true), (true, false)] do
    throw (IO.userError "raw late failure lost the accepted first deposit")

#eval expectLate

/-- Deployment-identity mismatch: a per-key `maxEBType1` below `DEPOSIT_SIZE`
pulls less than the loop sends. With enough spare router balance every beacon
CALL succeeds and the source line 996 assertion fails, rolling back. -/
def mismatch : RouterDeposit.Inputs :=
  { inputs with config := ⟨word (DEPOSIT_SIZE - 10^9), word (2 * DEPOSIT_SIZE)⟩ }
def richRouter : World := ⟨[], liveWorld (7 + 10^10) 3, ⟨1, 2, []⟩⟩
def mismatchRaw := executeRaw callee ctx mismatch richRouter
def mismatchRun := execute callee ctx mismatch richRouter

def expectMismatch : IO Unit := do
  match mismatchRun.outcome with
  | .error (.live (.reason "Panic(0x01)")) => pure ()
  | _ => throw (IO.userError "mismatch did not reach the balance assertion")
  unless mismatchRun.world.live.balances (address 2) = 7 + 10^10 &&
      mismatchRun.world.live.balances (address 8) = 11 &&
      (mismatchRun.world.live.core.readContractSlot 8 countSlot).val = 3 do
    throw (IO.userError "mismatch failure did not roll back")
  unless mismatchRaw.world.live.balances (address 2) = 7 + 10^10 - 2 * 10^9 &&
      mismatchRaw.world.live.balances (address 8) = 11 + 2 * DEPOSIT_SIZE &&
      (acceptedBeaconCalls mismatchRaw.attempts).length = 2 do
    throw (IO.userError "mismatch raw execution did not send both deposits")

#eval expectMismatch

/-- Guards before any CALL. -/
def expectRollback (wanted : Fault) (r : Result) : IO Unit :=
  match r.outcome with
  | .ok () => throw (IO.userError "unexpected success")
  | .error actual => unless actual == wanted && r.attempts = [] &&
        r.world.live.balances (address 2) = 7 && r.world.metadata = before.metadata do
      throw (IO.userError "guard failure did not roll back")

#eval expectRollback .notAuthorized (execute callee {ctx with caller := addr 8} inputs before)
#eval expectRollback .moduleNotActive (execute callee {ctx with moduleActive := false} inputs before)
#eval expectRollback .unsupportedWithdrawalCredentials
  (execute callee {ctx with withdrawalCredentials := none} inputs before)

/-- Instantiate the universal theorem on the fixture. SHA stays opaque; the
prefix equation is checked by evaluation, the live premises by decision. -/
def preparedResult := prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
  inputs.requested [] inputs.moduleId inputs.limits inputs.obtainDepositData DEPOSIT_SIZE
def prepared : PreparedDeposit :=
  ⟨word 7, word DEPOSIT_SIZE, audit.trio.deposit.Tests.Verity.twoKeyData,
    ⟨2 * DEPOSIT_SIZE, 2, 2 * DEPOSIT_SIZE, DEPOSIT_SIZE, 2 * DEPOSIT_SIZE⟩⟩
def transcript : Transcript := preparedResult.2
theorem prepared_eq : preparedResult = (.ok prepared, transcript) := by native_decide

def positiveFacts := positive_success (fun _ => Live.word 0) config rejectStatic reject ctx inputs
  before (word 99) prepared transcript 0 0 1 0 rfl rfl rfl prepared_eq (by decide) (by decide)
  (by decide) (by constructor <;> decide) (by decide) (by decide) rfl (by rfl) (by decide)
  (by rfl) (by rfl) (by decide) (by decide) rfl (by decide) (by decide) (by decide) (by decide)
  (by decide) (by decide)

theorem fixture_ok : result.outcome = .ok () := positiveFacts.1
theorem fixture_router : result.world.live.balances (address 2) = 7 := positiveFacts.2.router
theorem fixture_beacon : result.world.live.balances (address 8) = 11 + 2 * DEPOSIT_SIZE :=
  positiveFacts.2.beacon
theorem fixture_count : (result.world.live.core.readContractSlot 8 countSlot).val = 5 :=
  positiveFacts.2.count
theorem fixture_other : result.world.live.balances (address 9) = 0 :=
  positiveFacts.2.others (address 9) (by decide) (by decide) (by decide)

/- `prepared_eq` is checked by `native_decide`, so every fixture theorem below
it carries `Lean.ofReduceBool`; the universal `positive_success` itself does not. -/
#print axioms prepared_eq
#print axioms fixture_ok
#print axioms fixture_router
#print axioms fixture_beacon
#print axioms fixture_count
#print axioms fixture_other

end audit.trio.deposit.Tests.Verity.LiveBeacon
