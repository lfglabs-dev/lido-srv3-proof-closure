import LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault
namespace LidoSRv3.Tests.ConsolidationGatewayCallRegression
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def addr (n : Nat) : Address := Verity.Core.Address.ofNat n
def ctx : Context := ⟨addr 100, addr 999⟩
def groups : List WitnessGroupBytes :=
  [⟨[List.replicate 48 1, List.replicate 48 3], List.replicate 48 2⟩]
def before : World :=
  ⟨{Verity.defaultState with codeSize := fun _ => Live.word 1},
   fun a => if a = addr 100 then 100 else if a = addr 200 then 7 else 0, []⟩
def fees : StaticCall.External := fun r _ =>
  if r.caller = addr 200 ∧ r.target = addr 300 ∧ r.payload = [] ∧ r.value.val = 0 then
    .success (encode 32 2)
  else .rejected [0xff]
def inbox : External := fun r w =>
  if r.caller = addr 200 ∧ r.target = addr 300 ∧ r.value.val = 2 ∧
      (r.payload = List.replicate 48 1 ++ List.replicate 48 2 ∨
       r.payload = List.replicate 48 3 ++ List.replicate 48 2) then .success [] w
  else .rejected [0xee]
def run (gateway : Nat) (value : Nat) :=
  GatewayCall.execute inbox fees ctx (addr 200) (addr gateway) (addr 300)
    (Live.word value) groups before

theorem consumes_two_real_payloads :
    ((run 100 4).outcome, (run 100 4).world.balances (addr 100),
      (run 100 4).world.balances (addr 200), (run 100 4).world.balances (addr 300)) =
    (.ok [],96,7,4) := by decide +kernel

theorem preserves_static_flag_and_call_order :
    ((run 100 4).world.logs.map (·.name),
      ((run 100 4).attempts.flatMap (·.nested)).map (fun a => (a.isStatic,a.depth,a.request.payload.length))) =
    (["ConsolidationRequestAdded","ConsolidationRequestAdded"],
      [(true,1,0),(false,1,96),(false,1,96)]) := by decide +kernel

/-- The expected gateway is configured separately; caller equality cannot
make an unauthorized request pass its own authorization test. -/
theorem unauthorized_gateway_rejected :
    ((run 101 4).outcome, (run 101 4).world.balances (addr 100),
      ((run 101 4).attempts.flatMap (·.nested)).length) =
    (.error (.bubbled [0xb7,0xd2,0x29,0x32]),100,0) := by decide +kernel

theorem incorrect_fee_after_staticcall :
    ((run 100 3).outcome,
      ((run 100 3).attempts.flatMap (·.nested)).map (·.isStatic)) =
    (.error (.bubbled ([0xdc,0xf6,0xaf,0xcb] ++ encode 32 4 ++ encode 32 3)),[true]) := by decide +kernel

#print axioms consumes_two_real_payloads
#print axioms preserves_static_flag_and_call_order
#print axioms unauthorized_gateway_rejected
#print axioms incorrect_fee_after_staticcall
end LidoSRv3.Tests.ConsolidationGatewayCallRegression
