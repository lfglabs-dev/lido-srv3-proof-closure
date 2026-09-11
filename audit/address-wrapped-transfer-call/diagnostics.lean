import LidoSRv3.Tests.AddressWrappedTransferCalls
#eval LidoSRv3.Tests.AddressWrappedTransferCalls.diagnostics

-- Independently derived cast-keccak preimages; executable checks, not axioms.
#eval do
  unless LidoSRv3.Audit.Source.AddressWrappedTokenCalls.balanceSlot 1 == 0xada5013122d395ba3c54772283fb069b10426056ef8ca54750cb9bb552a59e7d do
    throw (IO.userError "balance mapping0 independent preimage mismatch")
  unless LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99 == 0xff67a398ecff03b66263bf0fe462d7e9454f0ea652ad311ddbbbff1dae964b28 do
    throw (IO.userError "owner/spender nested mapping1 independent preimage mismatch")
  IO.println "PASS 2 independent Keccak physical-slot checks"
