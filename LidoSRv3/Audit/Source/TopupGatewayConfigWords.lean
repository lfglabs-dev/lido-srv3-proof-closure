import LidoSRv3.Audit.Source.TopupWeiBounds
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! Literal physical word reads for TopUpGateway.Storage at core17005714.
This models Solidity's declared packed fields, without claiming a compiler or
runtime refinement. Time fields and setter reachability are not assumed. -/
namespace LidoSRv3.Audit.Source.TopupGatewayConfigWords
open TrioReserve1.Live

def gatewayRoot : Nat := 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200

def decode (first second : Word) : TopupWeiBounds.GatewayConfig :=
  { maxValidators := ⟨first.val % (2^64), Nat.mod_lt _ (by decide)⟩
    target := ⟨first.val / (2^160) % (2^64), Nat.mod_lt _ (by decide)⟩
    minTopUp := ⟨second.val % (2^64), Nat.mod_lt _ (by decide)⟩ }

def readConfig (gateway : Address) (w : World) : TopupWeiBounds.GatewayConfig :=
  decode (w.core.readContractSlot gateway.val gatewayRoot)
    (w.core.readContractSlot gateway.val (gatewayRoot+1))

/-- The two selected uint64 fields of the first word are independent of the
intervening timestamp/block/distance/age bits and upper unused bits. -/
theorem decode_packed (first second : Word) (count middle target upper minimum rest : Nat)
    (hc : count < 2^64) (hm : middle < 2^96) (ht : target < 2^64) (hmin : minimum < 2^64)
    (hfirst : first.val = count + 2^64 * middle + 2^160 * target + 2^224 * upper)
    (hsecond : second.val = minimum + 2^64 * rest) :
    (decode first second).maxValidators.val = count ∧
    (decode first second).target.val = target ∧ (decode first second).minTopUp.val = minimum := by
  have hlow : count + 2^64 * middle < 2^160 := by omega
  have he : first.val = (count + 2^64 * middle) + 2^160 * (target + 2^64 * upper) := by rw [hfirst,Nat.mul_add]; omega
  constructor
  · simp only [decode,hfirst]
    omega
  constructor
  · simp only [decode,he]
    omega
  · simp only [decode,hsecond]
    omega

end LidoSRv3.Audit.Source.TopupGatewayConfigWords
