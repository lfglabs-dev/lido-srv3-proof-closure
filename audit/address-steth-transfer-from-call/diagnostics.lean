import LidoSRv3.Tests.AddressStETHTransferFromCalls

-- Executable Keccak diagnostics, not native proof axioms.
#eval do
  unless LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot (.ofNat 0) (.ofNat 0) == 0xe5d06582d467054dda5404b9e1ec93f72b608a4970ba970773776c69ca5664f7 do
    throw (IO.userError "nested mapping vector 0/0")
  unless LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot (.ofNat 1) (.ofNat 99) == 0xff67a398ecff03b66263bf0fe462d7e9454f0ea652ad311ddbbbff1dae964b28 do
    throw (IO.userError "nested mapping vector 1/99")
  unless LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot (.ofNat 99) (.ofNat 1) == 0xbf647baa02000d1d21bc4135452d25e88d2282f2eaedc90a1056a043102b09bc do
    throw (IO.userError "nested mapping vector 99/1")
  unless LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot (.ofNat 1461501637330902918203684832716283019655932542975) (.ofNat 1461501637330902918203684832716283019655932542975) == 0x4233c29e78663f7ecc2ce2bfaada6ca8a0d1dac6601afb2e1235b6fe26bb589e do
    throw (IO.userError "nested mapping vector 1461501637330902918203684832716283019655932542975/1461501637330902918203684832716283019655932542975")
  IO.println "PASS 4 actual nested Keccak vectors; both exact 64-byte preimages"

#eval LidoSRv3.Tests.AddressStETHTransferFromCalls.diagnostics
