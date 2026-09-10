import LidoSRv3.Audit.Source.TopupGatewayWitnessBatch
import LidoSRv3.Audit.Source.SszActualLeafTree

/-! Additive typed witness loop for core17005714 TopUpGateway:204–228.
The inherited verifier executes with the gateway as BEACON_ROOTS caller.
The same typed proof list is consumed by slot and validator verification;
compiled calldata/memory and cryptographic SHA remain separate boundaries. -/
set_option maxRecDepth 4096
set_option maxHeartbeats 800000

namespace LidoSRv3.Audit.Source.TopupGatewayRootCalls
open SszValidatorLeaf SszVerifierEntry SszWrapperIndex SszActualLeafTree
open TopupGatewayWitnessBatch TrioReserve1

structure Environment where
  precompile : Precompile
  rootExternal : StaticCall.External
  scratch : Fin 32 → Byte
  gi : Configuration
  cfg : TopupWeiBounds.GatewayConfig
  beacon : BeaconData
  divisor : Index
  credentials : Digest
  gateway : Live.Address
  before : Live.World

def input (e : Environment) (r : Row) : SszRootCall.Input :=
  ⟨e.scratch,e.gi,e.beacon,r.witness,r.proof,r.index,e.credentials⟩

def verify (e : Environment) (r : Row) : SszRootCall.Result :=
  SszRootCall.run e.precompile e.rootExternal e.gateway (input e r) e.before

structure Result (α : Type) where
  outcome : Except GatewayFault α
  attempts : List Live.NestedAttempt

/-- Preserve every executed root attempt, including a failed root/leaf/proof
or a later headroom failure. Pubkey, ordering and activation precede the call. -/
def rowLimit (e : Environment) (previous : Option Index) (r : Row) : Result Nat :=
  if r.witness.pubkey.length ≠ 48 then ⟨.error .wrongPubkeyLength,[]⟩
  else if ordered previous r.index = false then ⟨.error .invalidSortOrder,[]⟩
  else match activated e.beacon.slot e.divisor r.witness with
  | .error fault => ⟨.error fault,[]⟩
  | .ok () =>
    let checked := verify e r
    match checked.outcome with
    | .error fault => ⟨.error (.verifier fault),checked.attempts⟩
    | .ok () =>
      match TopupWeiBounds.evaluate e.cfg (fields r) with
      | none => ⟨.error .pendingOverflow,checked.attempts⟩
      | some n => ⟨.ok n,checked.attempts⟩

def loop (e : Environment) : Option Index → Nat → List Row → Result Output
  | _, acc, [] => ⟨.ok ⟨[],[],acc⟩,[]⟩
  | previous, acc, r::rs =>
    let head := rowLimit e previous r
    match head.outcome with
    | .error fault => ⟨.error fault,head.attempts⟩
    | .ok n =>
      let wei := n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus
      let tail := loop e (some r.index) ((acc + wei) % TopupWeiBounds.wordModulus) rs
      ⟨tail.outcome.map (fun out => ⟨r.witness.pubkey::out.pubkeys,wei::out.limits,out.total⟩),
        head.attempts ++ tail.attempts⟩

/-- Per-row relation includes the exact evaluated fields, actual call bytes,
independent validator tree and single timestamp request with gateway caller. -/
def Authenticated (e : Environment) (r : Row) (n : Nat) : Prop :=
  TopupWeiBounds.evaluate e.cfg (fields r) = some n ∧
  (verify e r).outcome = .ok () ∧
  ∃ data gi,
    (SszRootCall.call e.rootExternal e.gateway e.beacon.childBlockTimestamp e.before).outcome = .ok data ∧
    32 ≤ data.length ∧
    sourceWrapper e.gi e.beacon.slot.toFin r.index = .ok gi ∧
    r.proof ≠ [] ∧
    SszProofFold.Branch (fun a b => some (pair (outputSha e.precompile) a b)) gi.index.val
      (treeDigest (pair (outputSha e.precompile))
        (validatorTree (outputSha e.precompile) r.witness e.credentials))
      r.proof (firstWord (SszRootCall.fromBytes data)) ∧
    (verify e r).attempts =
      [⟨SszRootCall.request e.gateway e.beacon.childBlockTimestamp,true,true,data,1⟩] ∧
    (verify e r).world = e.before

theorem authenticated (e : Environment) (r : Row) (n : Nat)
    (he : TopupWeiBounds.evaluate e.cfg (fields r) = some n)
    (hv : (verify e r).outcome = .ok ()) : Authenticated e r n := by
  obtain ⟨_,data,gi,leaf,hcall,_,_,hlen,hgi,hleaf,hproof,hbranch,hattempts,hworld⟩ :=
    SszRootCall.run_success e.precompile e.rootExternal e.gateway (input e r) e.before hv
  obtain ⟨_,htree⟩ := leaf_success_tree e.precompile e.scratch r.witness e.credentials leaf hleaf
  refine ⟨he,hv,data,gi,hcall,hlen,hgi,hproof,?_,hattempts,hworld⟩
  rw [htree]
  exact branch_output_tree e.precompile gi.index.val leaf _ r.proof hbranch

theorem row_success (e : Environment) (previous : Option Index) (r : Row) (n : Nat)
    (h : (rowLimit e previous r).outcome = .ok n) :
    Authenticated e r n ∧ ordered previous r.index = true ∧
    (rowLimit e previous r).attempts = (verify e r).attempts := by
  unfold rowLimit at h ⊢
  split at *
  · cases h
  · split at *
    · cases h
    · rename_i hk ho
      cases ha : activated e.beacon.slot e.divisor r.witness with
      | «error» fault => simp [ha] at h
      | ok u =>
        cases u
        simp only [ha] at h ⊢
        cases hv : (verify e r).outcome with
        | «error» fault => simp [hv] at h
        | ok u =>
          cases u
          simp only [hv] at h ⊢
          cases he : TopupWeiBounds.evaluate e.cfg (fields r) with
          | none => simp [he] at h
          | some m =>
            simp only [he,Except.ok.injEq] at h
            subst m
            exact ⟨authenticated e r n he hv, by cases hb : ordered previous r.index <;> simp_all, by simp [hk,ho]⟩

/-- Ordered evidence and produced arrays arise from the same successful loop.
The accumulator and limit facts reuse the unchanged arithmetic definitions. -/
theorem loop_success (e : Environment) (rows : List Row) :
    ∀ previous acc out, (loop e previous acc rows).outcome = .ok out →
      ∃ ns, TopupWeiBounds.limits e.cfg (rows.map fields) = some ns ∧
        out.pubkeys = rows.map (fun r => r.witness.pubkey) ∧
        out.limits = TopupWeiBounds.weiLimits ns ∧
        out.total = TopupWeiBounds.uncheckedSum acc out.limits ∧
        List.Forall₂ (Authenticated e) rows ns ∧ Increasing previous rows ∧
        (loop e previous acc rows).attempts = rows.flatMap (fun r => (verify e r).attempts) := by
  induction rows with
  | nil =>
    intro previous acc out h
    simp only [loop,Except.ok.injEq] at h
    subst out
    exact ⟨[],rfl,rfl,rfl,rfl,.nil,trivial,rfl⟩
  | cons r rs ih =>
    intro previous acc out h
    cases he : (rowLimit e previous r).outcome with
    | «error» fault => simp [loop,he] at h
    | ok n =>
      obtain ⟨ha,ho,ht⟩ := row_success e previous r n he
      cases hl : (loop e (some r.index)
          ((acc + n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus) % TopupWeiBounds.wordModulus) rs).outcome with
      | «error» fault => simp only [loop,he,hl,Except.map] at h; cases h
      | ok tail =>
        simp only [loop,he,hl,Except.map,Except.ok.injEq] at h
        subst out
        obtain ⟨ns,hn,hk,hw,hsum,hauth,hinc,htrace⟩ := ih _ _ tail hl
        refine ⟨n::ns,?_,?_,?_,hsum,.cons ha hauth,⟨ho,hinc⟩,?_⟩
        · simp [TopupWeiBounds.limits,ha.1,hn]
        · simp [hk]
        · simp [TopupWeiBounds.weiLimits,hw]
        · simp only [loop,he,List.flatMap_cons,ht,htrace]

#print axioms authenticated
#print axioms row_success
#print axioms loop_success
end LidoSRv3.Audit.Source.TopupGatewayRootCalls
