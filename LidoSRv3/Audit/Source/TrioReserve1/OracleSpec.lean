/-! Independent specification of AccountingOracle's checked timestamp, after
the returned consensus reference slot has been decoded from its actual reply.
No executor or Verity import. Both overflow operations have panic code 0x11.+-/
namespace LidoSRv3.Audit.Source.TrioReserve1.OracleSpec

inductive Timestamp where
  | value (timestamp : Nat)
  | overflow
  deriving DecidableEq, Repr

def Describes (genesis seconds slot : Nat) : Timestamp → Prop
  | .value timestamp => timestamp = genesis + slot * seconds ∧
      slot * seconds < 2^256 ∧ timestamp < 2^256
  | .overflow => 2^256 ≤ slot * seconds ∨ 2^256 ≤ genesis + slot * seconds

end LidoSRv3.Audit.Source.TrioReserve1.OracleSpec
