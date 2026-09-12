import LidoSRv3.Tests.TopupEntryAdmission
import LidoSRv3.Audit.Source.SszTypedFfiBridge
open LidoSRv3.Audit.Source LidoSRv3.Tests
open TrioReserve1 Live SszValidatorLeaf
open TopupBatchConsumerRegression

def proofWords (b : ByteArray) : List Digest :=
  (List.range 50).map (fun i => BitVec.ofNat 256 (decode (b.extract (32*i) (32*(i+1))).data.toList))

def diagnostics : IO Unit := do
  let base := "audit/topup-credential-call/validation/"
  let root ← IO.FS.readBinFile (base++"root.bin")
  let p0 ← IO.FS.readBinFile (base++"proof-0.bin")
  let p1 ← IO.FS.readBinFile (base++"proof-1.bin")
  let p2 ← IO.FS.readBinFile (base++"proof-2.bin")
  let rows := (TopupRootCallEffectsRegression.rows.zip [proofWords p0,proofWords p1,proofWords p2]).map
    (fun (r,p) => {r with proof := p})
  let original := TopupRootCallEffectsRegression.environment
  let configured := fun position raw =>
    let core := original.before.core.writeContractSlot 2 1007 (word position)
    let core := core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+4) (word raw)
    {original.before with core}
  let unguarded := {original with
    before := configured 1 (1*2^248+12345)
    precompile := SszValidatorLeaf.standardSha SszTypedFfiBridge.ffiSha
    rootExternal := fun req _ =>
      if req = SszRootCall.request (address 3) beacon.childBlockTimestamp then .success root.data.toList else .rejected [0xba]
    credentials := 999}
  let caller := address 11
  let roleKey := LidoSRv3.Audit.Source.TopupEntryAdmission.roleSlot caller
  let granted := unguarded.before.core.writeContractSlot 3 roleKey (word (2^255+2))
  let granted := granted.writeContractSlot 3 LidoSRv3.Audit.Source.TopupEntryAdmission.resumeSlot unguarded.before.core.blockTimestamp
  let e := {unguarded with before := {unguarded.before with core := granted}}
  let go := fun rootEnv amounts => LidoSRv3.Audit.Source.TopupEntryAdmission.run caller LidoSRv3.Tests.TopupRouterLocatorCall.good
    (address 9) (word 128) (word 128) LidoSRv3.Tests.TopupPhysicalCredentialGetter.hash
    (TopupRootCallEffectsRegression.module amounts) TopupRouterContinuationMutants.callee rootEnv
    LidoSRv3.Tests.TopupRouterLocatorCall.supplied (address 8) (word 7)
    [word 1,word 2,word 3] [word 4,word 5,word 6] rows (word (2^256-1))
  let result := go e [word (10^18),word 0,word (2*10^18)]
  unless result.outcome == .ok () do throw (IO.userError s!"admitted actual complete path: {repr result.outcome}")
  let some lookup := result.suffix | throw (IO.userError "no actual locator phase")
  let some history := lookup.suffix | throw (IO.userError "no actual history phase")
  unless lookup.locatorAttempts.length == 1 && history.credentialAttempts.length == 1 &&
      history.rootAttempts.length == 3 && history.moduleAttempts.length > 1 &&
      result.world.logs.getLast?.map (·.name) == some "LastTopUpChanged" do
    throw (IO.userError "complete locator/root/module/history not retained")
  let coreWithoutRole := e.before.core.writeContractSlot 3 roleKey (word (2^255))
  let denied := go {e with before := {e.before with core := coreWithoutRole}} [word 0,word 0,word 0]
  unless denied.outcome == .error (.admission (.bubbled (LidoSRv3.Audit.Source.TopupEntryAdmission.unauthorized caller))) && denied.suffix.isNone do
    throw (IO.userError "high bits must not grant role or enter locator")
  let corePaused := e.before.core.writeContractSlot 3 LidoSRv3.Audit.Source.TopupEntryAdmission.resumeSlot (word (e.before.core.blockTimestamp.val+1))
  let paused := go {e with before := {e.before with core := corePaused}} [word 0,word 0,word 0]
  unless paused.outcome == .error (.admission (.bubbled (encode 4 0x14378398))) && paused.suffix.isNone do
    throw (IO.userError "physical timestamp must gate before locator")
  let late := go e [word (2*10^18),word (2*10^18),word 0]
  unless late.outcome == .error (.phase (.phase (.phase (.batch (.module (.reason "ModuleReturnExceedTarget")))))) &&
      late.world.logs.map (fun l => (l.emitter,l.name,l.values)) == e.before.logs.map (fun l => (l.emitter,l.name,l.values)) &&
      late.world.core.readContractSlot 3 roleKey == e.before.core.readContractSlot 3 roleKey &&
      TopupTimingHistory.stored (address 3) late.world == TopupTimingHistory.stored (address 3) e.before do
    throw (IO.userError "late error after physical admission must restore entry")
  let json ← IO.FS.readFile "audit/topup-entry-admission/validation/mapping-vectors.tsv"
  for line in json.splitOn "\n" do
    if line.isEmpty then continue
    let fields := line.splitOn "\t"
    let some a := fields[0]!.toNat? | throw (IO.userError "bad caller")
    let some expectedSlot := fields[1]!.toNat? | throw (IO.userError "bad expected slot")
    unless LidoSRv3.Audit.Source.TopupEntryAdmission.roleSlot (address a) == expectedSlot do throw (IO.userError "nested role hash bytes")
  IO.println "PASS 4 native execution groups: complete actual SHA/locator/root/module/history success; high-byte-only denied; physical resume denied; late full entry rollback. PASS 4 independent nested mapping vectors."
#eval diagnostics
