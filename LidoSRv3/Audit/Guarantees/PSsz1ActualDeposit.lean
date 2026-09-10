import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Source.SszDepositConsumer

/-! Public SSZ-1 deposit-call byte binding. Validator proof calls are a separate
path; no relation to an arbitrary CL witness or synthetic Nat.pair root is assumed. -/
namespace LidoSRv3.Audit.Guarantees.PSsz1
open Source Source.TrioReserve1 Source.TrioReserve1.Live Source.TopupBeaconCallee
open Source.SszDepositConsumer

/-- A successful actual deposit CALL determines its helper input from decoded
payload fields and msg.value. The root matches the ordered SHA preimage chain
for precisely that input, with widths and uint64 gwei range derived from guards. -/
theorem actual_deposit_call_binds_root (ctx : Context) (target : Address)
    (payload : Live.Bytes) (amount : Word) (before after : World) (data : Live.Bytes)
    (trace : List Attempt)
    (h : TopupBeaconEffects.push DepositDataRootCorrespondence.sha256
      ctx target payload amount before = ⟨.ok data, after, trace⟩) :
    ∃ f, decodePayload payload = some f ∧
      f.pubkey.length = 48 ∧ f.credentials.length = 32 ∧ f.signature.length = 96 ∧
      (consumedInput f amount).amountGwei < 2^64 ∧ amount.val % 10^9 = 0 ∧
      f.suppliedRoot = LidoSRv3.Audit.Verity.TopupTx.abiWordOfBytes
        (DepositDataRootCorrespondence.computeDepositDataRootWithAmount
          (consumedInput f amount)).bytes :=
  SszDepositConsumer.push_success_consumed ctx target payload amount before after data trace h

#print axioms actual_deposit_call_binds_root
end LidoSRv3.Audit.Guarantees.PSsz1
