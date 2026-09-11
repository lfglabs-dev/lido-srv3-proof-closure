import LidoSRv3.Tests.TopupTimingHistory
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
  let e := {original with
    before := configured 1 (1*2^248+12345)
    precompile := SszValidatorLeaf.standardSha SszTypedFfiBridge.ffiSha
    rootExternal := fun req _ =>
      if req = SszRootCall.request (address 3) beacon.childBlockTimestamp then .success root.data.toList else .rejected [0xba]
    credentials := 999}
  let go := fun rootEnv amounts => TopupTimingHistory.run (word 128) (word 128)
    LidoSRv3.Tests.TopupPhysicalCredentialGetter.hash
    (TopupRootCallEffectsRegression.module amounts)
    TopupRouterContinuationMutants.callee rootEnv ctx (address 8) (word 7)
    [word 1,word 2,word 3] [word 4,word 5,word 6] rows (word (2^256-1))
  let good := go e [word (10^18),word 0,word (2*10^18)]
  unless good.outcome == .ok () && good.credentialAttempts.length == 1 && good.rootAttempts.length == 3 && good.moduleAttempts.length > 1 do
    throw (IO.userError s!"physical timing/getter positive {repr good.outcome}")
  let some stage := good.stage | throw (IO.userError "missing actual stage")
  let some (_,output) := stage.produced | throw (IO.userError "missing actual loop output")
  unless output.total > 0 && TopupTimingHistory.lastTimestamp (address 3) good.world == stage.intermediate.world.core.blockTimestamp.val % 2^32 &&
      TopupTimingHistory.lastBlock (address 3) good.world == stage.intermediate.world.core.blockNumber.val % 2^32 &&
      good.world.logs.getLast?.map (·.values) == some [stage.intermediate.world.core.blockTimestamp] do
    throw (IO.userError "actual post-world history fields/event")
  let zeros := go e [word 0,word 0,word 0]
  unless zeros.outcome == .ok () && zeros.rootAttempts.length == 3 && zeros.moduleAttempts.length == 1 &&
      zeros.world.logs.getLast?.map (·.name) == some "LastTopUpChanged" do
    throw (IO.userError "real authenticated positive limits / zero allocations must write history")
  let bad := go {e with before := configured 1 (1*2^248+12346)} [word 0,word 0,word 0]
  unless bad.outcome == .error (.phase (.batch (.gateway (.verifier (.proof .invalidProof))))) do
    throw (IO.userError "changed physical WC not consumed")
  let wrongRoot := go {e with rootExternal := fun _ _ => .success (List.replicate 32 0)} [word 0,word 0,word 0]
  unless wrongRoot.outcome == .error (.phase (.batch (.gateway (.verifier (.proof .invalidProof))))) do
    throw (IO.userError "changed actual root not consumed")
  let blockedCore := (configured 0 (1*2^248+12345)).core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot
    (word ((TopupTimingHistory.stored (address 3) e.before).val+9*2^96))
  let blocked := go {e with before := {e.before with core := blockedCore}} [word 0,word 0,word 0]
  unless blocked.outcome == .error (.timing .arithmetic) && blocked.credentialAttempts.length == 0 && blocked.rootAttempts.length == 0 do
    throw (IO.userError "distance subtraction must precede absent getter registration")
  let late := go e [word (2*10^18),word (2*10^18),word 0]
  unless late.outcome == .error (.phase (.batch (.module (.reason "ModuleReturnExceedTarget")))) &&
      late.rootAttempts.length == 3 && late.moduleAttempts.length == 1 && late.world.logs.map (fun l => (l.emitter,l.name,l.values)) == e.before.logs.map (fun l => (l.emitter,l.name,l.values)) &&
      TopupTimingHistory.stored (address 3) late.world == TopupTimingHistory.stored (address 3) e.before do
    throw (IO.userError s!"late failure root rollback: {repr late.outcome}, attempts {late.rootAttempts.length}/{late.moduleAttempts.length}")
  let oldWord := TopupTimingHistory.stored (address 3) e.before
  let overflowCore := e.before.core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot (word (oldWord.val+2^144))
  let overflowEnv := {e with before := {e.before with core := overflowCore}, beacon := {e.beacon with childBlockTimestamp := BitVec.ofNat 64 (2^64-1)}}
  let overflow := go overflowEnv [word 0,word 0,word 0]
  unless overflow.outcome == .error (.timing .arithmetic) && overflow.credentialAttempts.length == 0 do
    throw (IO.userError "uint64 root age overflow")
  IO.println "PASS 7 fresh FFI diagnostics: actual-root positive physical suffix/history; actual-root zero allocations/history; altered WC; altered root; temporal guard before missing registration; late failure rollback; uint64 age overflow"
#eval diagnostics
