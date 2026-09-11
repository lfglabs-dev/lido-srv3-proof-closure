import LidoSRv3.Tests.TopupCredentialCall
import LidoSRv3.Audit.Source.SszTypedFfiBridge
open LidoSRv3.Audit.Source LidoSRv3.Tests
open TrioReserve1 Live SszValidatorLeaf
open TopupBatchConsumerRegression

def bytesWord (b : ByteArray) : Digest := BitVec.ofNat 256 (decode b.data.toList)
def proofWords (b : ByteArray) : List Digest :=
  (List.range 50).map (fun i => bytesWord (b.extract (32*i) (32*(i+1))))

def diagnostics : IO Unit := do
  let base := "audit/topup-credential-call/validation/"
  let rawRoot ← IO.FS.readBinFile (base++"root.bin")
  let p0 ← IO.FS.readBinFile (base++"proof-0.bin")
  let p1 ← IO.FS.readBinFile (base++"proof-1.bin")
  let p2 ← IO.FS.readBinFile (base++"proof-2.bin")
  let rows := (TopupRootCallEffectsRegression.rows.zip [proofWords p0,proofWords p1,proofWords p2]).map
    (fun (r,p) => {r with proof := p})
  let roots : StaticCall.External := fun req _ =>
    if req = SszRootCall.request (address 3) beacon.childBlockTimestamp then .success rawRoot.data.toList else .rejected [0xba]
  let e := {TopupRootCallEffectsRegression.environment with
    precompile := SszValidatorLeaf.standardSha SszTypedFfiBridge.ffiSha
    rootExternal := roots
    credentials := 999}
  let go := fun get rs rootEnv buffer => TopupCredentialCall.run get (word 128) buffer mapHash
    (TopupRootCallEffectsRegression.module [word (10^18),word 0,word (2*10^18)])
    TopupRouterContinuationMutants.callee rootEnv ctx (address 8) (word 7)
    [word 1,word 2,word 3] [word 4,word 5,word 6] rs (word (2^256-1))
  let good := go LidoSRv3.Tests.TopupCredentialCall.getter rows e (word 128)
  unless good.outcome == .ok () do throw (IO.userError s!"positive failed {repr good.outcome}")
  unless good.credentialAttempts.length == 1 && good.rootAttempts.length == 3 && good.moduleAttempts.length > 1 do
    throw (IO.userError "missing actual phase attempts")
  let wrongCred : StaticCall.External := fun _ _ => .success (encode 32 (2*2^248+12346))
  unless (go wrongCred rows e (word 128)).outcome == .error (.batch (.gateway (.verifier (.proof .invalidProof)))) do throw (IO.userError "wrong credentials accepted")
  let wrongRoot := {e with rootExternal := fun _ _ => .success (List.replicate 32 0)}
  unless (go LidoSRv3.Tests.TopupCredentialCall.getter rows wrongRoot (word 128)).outcome == .error (.batch (.gateway (.verifier (.proof .invalidProof)))) do throw (IO.userError "wrong root accepted")
  let badRows := rows.map (fun r => {r with proof := 1 :: r.proof.drop 1})
  unless (go LidoSRv3.Tests.TopupCredentialCall.getter badRows e (word 128)).outcome == .error (.batch (.gateway (.verifier (.proof .invalidProof)))) do throw (IO.userError "wrong proof accepted")
  let late := go LidoSRv3.Tests.TopupCredentialCall.getter rows e (word (2^64-192))
  unless late.outcome == .error (.batch (.module (.reason "Panic(0x41)"))) && late.moduleAttempts.length == 1 do
    throw (IO.userError s!"late allocation failure {repr late.outcome}")
  IO.println "PASS 5 whole-entry FFI diagnostics: actual credentials + independent three-row root + positive physical continuation; different prefix02 credential, root and proof reject; late memory failure"
#eval diagnostics
