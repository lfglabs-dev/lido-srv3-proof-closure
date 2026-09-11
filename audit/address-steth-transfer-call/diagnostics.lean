import LidoSRv3.Tests.AddressStETHTransferCalls

-- Runtime cross-checks against the four independently cast-keccak vectors.
-- These are diagnostic evaluation, not declarations with native proof axioms.
#eval do
  unless LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot (.ofNat 0) == 0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5 do
    throw (IO.userError "mapping vector owner 0")
  unless LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot (.ofNat 3) == 0x101e368776582e57ab3d116ffe2517c0a585cd5b23174b01e275c2d8329c3d83 do
    throw (IO.userError "mapping vector owner 3")
  unless LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot (.ofNat 99) == 0x01c4951e729acbc05299798279cd10e5be143681a3d883a027edec470c12b1a9 do
    throw (IO.userError "mapping vector owner 99")
  unless LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot (.ofNat 1461501637330902918203684832716283019655932542975) == 0x50c7a3d1a23c7ff4a61d37c3f2c4aeb36cf60b43ee893723db201d3eb941cbad do
    throw (IO.userError "mapping vector owner 1461501637330902918203684832716283019655932542975")
  IO.println "PASS 4 actual Keccak mapping vectors, exact clean160 word plus zero base word"

#eval LidoSRv3.Tests.AddressStETHTransferCalls.diagnostics
