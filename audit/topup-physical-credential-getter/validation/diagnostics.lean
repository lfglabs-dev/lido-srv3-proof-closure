import LidoSRv3.Tests.TopupPhysicalCredentialGetter
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
  let go := fun rootEnv => TopupPhysicalCredentialGetter.run (word 128) (word 128)
    LidoSRv3.Tests.TopupPhysicalCredentialGetter.hash
    (TopupRootCallEffectsRegression.module [word (10^18),word 0,word (2*10^18)])
    TopupRouterContinuationMutants.callee rootEnv ctx (address 8) (word 7)
    [word 1,word 2,word 3] [word 4,word 5,word 6] rows (word (2^256-1))
  let good := go e
  unless good.outcome == .ok () && good.credentialAttempts.length == 1 && good.rootAttempts.length == 3 && good.moduleAttempts.length > 1 do
    throw (IO.userError s!"physical getter positive {repr good.outcome}")
  let absent := go {e with before := configured 0 (1*2^248+12345)}
  unless absent.outcome == .error (.lookup (.bubbled TopupPhysicalCredentialGetter.unregistered)) && absent.rootAttempts.length == 0 do
    throw (IO.userError "unregistered did not reject before roots")
  let bad := go {e with before := configured 1 (1*2^248+12346)}
  unless bad.outcome == .error (.batch (.gateway (.verifier (.proof .invalidProof)))) do
    throw (IO.userError "changed physical WC not consumed")
  let type1 := go {e with before := {e.before with core := e.before.core.writeContractSlot 2 90 (word (40+1*2^232))}}
  unless type1.outcome == .error .wrongWithdrawalCredentials && type1.rootAttempts.length == 0 do
    throw (IO.userError "gateway prefix guard")
  IO.println "PASS 4 fresh FFI diagnostics: physical getter + independent three-row root + positive physical effects; missing membership; changed physical WC invalidProof; physical type1 rejected by gateway"
#eval diagnostics
