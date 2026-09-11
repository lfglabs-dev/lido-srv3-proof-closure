import LidoSRv3.Audit.Guarantees.PSsz1CompiledClEntry
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszCompiledClEntry SszWrapperIndex TrioReserve1

-- IO evaluation through existing SHA FFI; these checks are NOT kernel theorems.
def diagnostics : IO Unit := do
  let calldata ← IO.FS.readBinFile "audit/ssz-compiled-cl-entry/validation/valid-calldata.bin"
  let reply ← IO.FS.readBinFile "audit/ssz-compiled-cl-entry/validation/valid-root.bin"
  let context : EVM.State := { (default : EVM.State) with
    gasAvailable := UInt256.ofNat 10000000
    memory := ⟨#[1,2,3]⟩
    executionEnv := { (default : EVM.State).executionEnv with calldata := calldata, codeOwner := ⟨99, by decide⟩ } }
  let world : Live.World := ⟨{Verity.defaultState with codeSize := fun _ => Live.word 1},fun _ => 0,[]⟩
  let cfg := pinnedConfiguration ⟨0, by decide⟩
  let external : StaticCall.External := fun req _ =>
    if req = SszRootCall.request (Verity.Core.Address.ofNat 99) (BitVec.ofNat 64 123)
    then .success reply.data.toList else .rejected []
  let result := SszCompiledClEntry.run 100 cfg external world context
  match result.outcome with
  | .ok _ => pure ()
  | .error (.abi _) => throw (IO.userError "valid ABI rejected")
  | .error (.bls _) => throw (IO.userError "valid BLS rejected")
  | .error (.proof _) => throw (IO.userError "valid proof rejected")
  | .error (.reply _) => throw (IO.userError "valid reply rejected")
  | .error (.gindex _) => throw (IO.userError "valid index rejected")
  | .error _ => throw (IO.userError "valid entry rejected")
  unless result.attempts.length == 1 do throw (IO.userError "root attempt missing")
  let changedRoot : StaticCall.External := fun _ _ => .success (reply.set! 0 (reply.get! 0 ^^^ 1)).data.toList
  let badRoot := SszCompiledClEntry.run 100 cfg changedRoot world context
  match badRoot.outcome with
  | .error (.proof _) => pure ()
  | _ => throw (IO.userError "corrupted root accepted or wrong failure")
  let badBytes := calldata.set! 484 1
  let badProof := SszCompiledClEntry.run 100 cfg external world
    {context with executionEnv := {context.executionEnv with calldata := badBytes}}
  match badProof.outcome with
  | .error (.proof _) => pure ()
  | _ => throw (IO.userError "corrupted proof byte accepted or wrong failure")
  let badTimestamp := calldata.set! 35 124
  let badTime := SszCompiledClEntry.run 100 cfg external world
    {context with executionEnv := {context.executionEnv with calldata := badTimestamp}}
  match badTime.outcome with
  | .error (.reply _) => pure ()
  | _ => throw (IO.userError "timestamp not consumed by actual request")
  IO.println "PASS 4 whole-entry FFI diagnostics: independent root/proof success, corrupted root, corrupted proof byte, exact timestamp request"
#eval diagnostics
