import LidoSRv3.Audit.Source.TopupKeccakOracle

/-! Concrete witnesses and kill-lines for the P-TOPUP-2 keccak oracle
boundary. Decoder-only: no always-success stub, no renamed TOPUP premise,
no claim that keccak correspondence is closed. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupKeccakOracleMutants

open LidoSRv3.Audit.Source.TopupKeccakOracle
open LidoSRv3.Audit.Verity.Topup2DistributionTx

end LidoSRv3.Tests.TopupKeccakOracleMutants
