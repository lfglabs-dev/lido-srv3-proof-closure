import audit.trio.deposit.ModuleCall

/-! Actual module CALL → raw dual bytes → physical metadata → actual
withdrawal/beacon suffix. This is an additional public consumer of the accepted
suffix. It starts with the already computed allocation and a phase memory cursor;
it is not a full deposit entrypoint/ALLOC/deployment correspondence claim.
The external module may change any Live.World component. Its returned world is
consumed verbatim by PhysicalMetadata.update and then LiveBeacon.suffix.
-/
namespace audit.trio.deposit.ModulePhysicalMetadata
set_option autoImplicit false
open LidoSRv3.Audit.Source
open TrioReserve1
open TopupRouterCredentials (Keccak)
open ModuleCall

/-- The closure receives the actual module-returned world, not the entry world.
The return allocator cursor is executed even though the later accepted suffix
retains its existing memory abstraction. -/
def continuation (hash : Keccak) (withdrawalExternal : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (credentials : TrioAlloc1.Word)
    (i : Input) (count : Nat) (raw : Live.Bytes) : Live.Exec Unit := fun moduleWorld =>
  match decodeReturn i.returnBuffer raw with
  | .error e => Live.fail e moduleWorld
  | .ok (data,_) =>
    match prepare i count data with
    | .error e => Live.fail e moduleWorld
    | .ok prepared =>
      LiveBeacon.suffix withdrawalExternal ctx liveCtx credentials prepared
        (PhysicalMetadata.update hash ctx liveCtx.sender prepared moduleWorld)

def program (hash : Keccak) (moduleExternal withdrawalExternal : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input) : Live.Exec Unit := fun before =>
  if ctx.caller != ctx.depositSecurityModule then Live.fail (.reason "NotAuthorized") before
  else if !ctx.moduleActive then Live.fail (.reason "StakingModuleNotActive") before
  else match ctx.withdrawalCredentials with
  | none => Live.fail (.reason "UnsupportedWithdrawalCredentials") before
  | some credentials =>
    if i.maxEB.val = 0 then Live.fail (.reason "Panic(0x12)") before else
    let count := target hash liveCtx.sender i before
    if count = 0 then Live.fail (.reason "ZeroDeposits") before else
    let address := moduleAddress hash liveCtx.sender i before
    Live.bindExec (call moduleExternal liveCtx.sender address count i.depositCalldata)
      (continuation hash withdrawalExternal ctx liveCtx credentials i count) before

/-- Exact transport equation for the call that the prefix actually issues. -/
theorem program_of_call (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before moduleWorld : Live.World) (credentials : TrioAlloc1.Word)
    (raw : Live.Bytes) (trace : List Live.Attempt)
    (ha : ctx.caller = ctx.depositSecurityModule) (hm : ctx.moduleActive = true)
    (hc : ctx.withdrawalCredentials = some credentials) (hd : i.maxEB.val ≠ 0)
    (ht : target hash liveCtx.sender i before ≠ 0)
    (hcall : call m liveCtx.sender (moduleAddress hash liveCtx.sender i before)
      (target hash liveCtx.sender i before) i.depositCalldata before = ⟨.ok raw,moduleWorld,trace⟩) :
    program hash m w ctx liveCtx i before =
      let r := continuation hash w ctx liveCtx credentials i (target hash liveCtx.sender i before) raw moduleWorld
      ⟨r.outcome,r.world,trace ++ r.attempts⟩ := by
  simp only [program,ha,bne_self_eq_false,Bool.false_eq_true,if_false,
    hm,Bool.not_true,hc,hd,ht,hcall,Live.bindExec]

/-- Root rollback includes all module changes, physical writes, logs and callee
ledger state. Attempts retain the whole observed module + suffix journal. -/
def execute (hash : Keccak) (moduleExternal withdrawalExternal : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input) : Live.Exec Unit :=
  Live.run (program hash moduleExternal withdrawalExternal ctx liveCtx i)

theorem failure_restores (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (fault : Live.Fault) (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.error fault,after,attempts⟩) :
    after = before := by
  unfold execute Live.run at h
  dsimp only at h
  split at h
  · have he := congrArg Live.Result.outcome h
    simp_all
  · exact (Live.Result.mk.inj h).2.1.symm

/-- Exact equations for the actual successful subexecutions, obtained by
inverting a single root result. No callee receipt or frame premise is supplied. -/
structure Commitment (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (attempts : List Live.Attempt) where
  credentials : TrioAlloc1.Word
  raw : Live.Bytes
  data : Data
  nextCursor : Live.Word
  prepared : PreparedDeposit
  moduleWorld : Live.World
  moduleTrace : List Live.Attempt
  suffixTrace : List Live.Attempt
  authorized : ctx.caller = ctx.depositSecurityModule
  active : ctx.moduleActive = true
  credentials_captured : ctx.withdrawalCredentials = some credentials
  divisor_nonzero : i.maxEB.val ≠ 0
  target_nonzero : target hash liveCtx.sender i before ≠ 0
  call_ok : call m liveCtx.sender (moduleAddress hash liveCtx.sender i before)
    (target hash liveCtx.sender i before) i.depositCalldata before = ⟨.ok raw,moduleWorld,moduleTrace⟩
  decode_ok : decodeReturn i.returnBuffer raw = .ok (data,nextCursor)
  prepare_ok : prepare i (target hash liveCtx.sender i before) data = .ok prepared
  suffix_ok : LiveBeacon.suffix w ctx liveCtx credentials prepared
    (PhysicalMetadata.update hash ctx liveCtx.sender prepared moduleWorld) = ⟨.ok (),after,suffixTrace⟩
  journal : attempts = moduleTrace ++ suffixTrace

theorem success_commitment (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    Nonempty (Commitment hash m w ctx liveCtx i before after attempts) := by
  have hp : program hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩ := by
    unfold execute Live.run at h
    dsimp only at h
    split at h
    · exact h
    · cases h
  unfold program at hp
  split at hp
  · cases hp
  · rename_i ha
    split at hp
    · cases hp
    · rename_i hm
      cases hc : ctx.withdrawalCredentials with
      | none => simp [hc,Live.fail] at hp
      | some credentials =>
        simp only [hc] at hp
        split at hp
        · cases hp
        · rename_i hd
          split at hp
          · cases hp
          · rename_i ht
            cases hcall : call m liveCtx.sender (moduleAddress hash liveCtx.sender i before)
                (target hash liveCtx.sender i before) i.depositCalldata before with
            | mk outcome moduleWorld moduleTrace =>
              cases outcome with
              | «error» e => simp [Live.bindExec,hcall] at hp
              | ok raw =>
                simp only [Live.bindExec,hcall] at hp
                cases hdecode : decodeReturn i.returnBuffer raw with
                | «error» e => simp [continuation,hdecode,Live.fail] at hp
                | ok decoded =>
                  rcases decoded with ⟨data,nextCursor⟩
                  cases hprep : prepare i (target hash liveCtx.sender i before) data with
                  | «error» e => simp [continuation,hdecode,hprep,Live.fail] at hp
                  | ok prepared =>
                    simp only [continuation,hdecode,hprep] at hp
                    cases hsuffix : LiveBeacon.suffix w ctx liveCtx credentials prepared
                        (PhysicalMetadata.update hash ctx liveCtx.sender prepared moduleWorld) with
                    | mk outcome suffixWorld suffixTrace =>
                      cases outcome with
                      | «error» e => simp [hsuffix] at hp
                      | ok u =>
                        cases u
                        simp only [hsuffix,Live.Result.mk.injEq,true_and] at hp
                        obtain ⟨hw,htrace⟩ := hp
                        subst suffixWorld
                        refine ⟨⟨credentials,raw,data,nextCursor,prepared,moduleWorld,moduleTrace,suffixTrace,
                          ?_,?_,hc,hd,ht,hcall,hdecode,hprep,hsuffix,htrace.symm⟩⟩
                        · simpa using ha
                        · simpa using hm

/-- Every success exposes the exact module request/reply/returned world, byte
decode, source count/value guards, metadata update and actual suffix. Zero
keys retain the module world plus metadata/event and make no suffix calls;
positive keys expose the existing necessary-success SuffixCommitment. -/
theorem success_effects (hash : Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : Input)
    (before after : Live.World) (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    ∃ c : Commitment hash m w ctx liveCtx i before after attempts,
      let address := moduleAddress hash liveCtx.sender i before
      let count := target hash liveCtx.sender i before
      let req : Live.Request := ⟨liveCtx.sender,address,Live.word 0,payload count i.depositCalldata⟩
      (before.core.codeSize address.val).val ≠ 0 ∧
      ((m req (Live.transfer before liveCtx.sender address 0) = .success c.raw c.moduleWorld ∧
         c.moduleTrace = [⟨req,true,c.raw,[]⟩]) ∨
       ∃ nested, m req (Live.transfer before liveCtx.sender address 0) = .successWithTrace c.raw c.moduleWorld nested ∧
         c.moduleTrace = [⟨req,true,c.raw,nested⟩]) ∧
      64 ≤ (Live.word c.raw.length).val ∧
      i.returnBuffer.val + (Live.word c.raw.length).val < 2^64 ∧
      c.data.publicKeys.length % 48 = 0 ∧
      c.prepared.values.actualKeys = c.data.publicKeys.length / 48 ∧
      c.prepared.values.actualKeys ≤ count ∧
      c.prepared.values.lidoPullWei = c.prepared.values.actualKeys*i.maxEB.val ∧
      c.prepared.values.lidoPullWei < 2^256 ∧
      let updated := PhysicalMetadata.update hash ctx liveCtx.sender c.prepared c.moduleWorld
      let key := PhysicalMetadata.moduleDepositSlot hash i.moduleId
      let packed := (updated.core.readContractSlot liveCtx.sender.val key).val
      (packed % 2^64 = c.moduleWorld.core.blockTimestamp.val % 2^64 ∧
       packed / 2^64 % 2^64 = c.moduleWorld.core.blockNumber.val % 2^64 ∧
       packed / 2^128 = (c.moduleWorld.core.readContractSlot liveCtx.sender.val key).val / 2^128) ∧
      updated.balances = c.moduleWorld.balances ∧
      updated.logs = c.moduleWorld.logs ++ [PhysicalMetadata.routerEvent liveCtx.sender c.prepared] ∧
      ((c.prepared.values.actualKeys = 0 ∧ after = updated ∧ c.suffixTrace = [] ∧ attempts = c.moduleTrace) ∨
       (c.prepared.values.actualKeys ≠ 0 ∧ Nonempty
         (LiveBeaconCommitted.SuffixCommitment w ctx liveCtx c.credentials c.prepared updated after c.suffixTrace))) := by
  obtain ⟨c⟩ := success_commitment hash m w ctx liveCtx i before after attempts h
  have ho := decoded_call_origin m liveCtx.sender (moduleAddress hash liveCtx.sender i before)
    (target hash liveCtx.sender i before) i.depositCalldata before c.moduleWorld c.raw c.moduleTrace
    c.data i.returnBuffer c.nextCursor c.call_ok c.decode_ok
  have hb := decodeReturn_size_bounds i.returnBuffer c.nextCursor c.raw c.data c.decode_ok
  have hv := prepare_values i (target hash liveCtx.sender i before) c.data c.prepared c.prepare_ok
  refine ⟨c,ho.1,ho.2,hb.1,hb.2,hv.1,hv.2.2.2.2.2.1,hv.2.2.2.2.2.2.1,
    hv.2.2.2.2.2.2.2.1,hv.2.2.2.2.2.2.2.2.1,?_,rfl,rfl,?_⟩
  · have hf := PhysicalMetadata.update_fields hash ctx liveCtx.sender c.prepared c.moduleWorld
    simpa only [hv.2.1] using hf
  · by_cases hz : c.prepared.values.actualKeys = 0
    · left
      have hs := c.suffix_ok
      rw [LiveBeacon.zero_keys_no_calls w ctx liveCtx c.credentials c.prepared _ hz] at hs
      have he := (Live.Result.mk.inj hs).2
      exact ⟨hz,he.1.symm,he.2.symm,by simpa [← he.2] using c.journal⟩
    · exact Or.inr ⟨hz,LiveBeaconCommitted.suffix_ok_commitment w ctx liveCtx
        c.credentials c.prepared _ after c.suffixTrace hz c.suffix_ok⟩

#print axioms failure_restores
#print axioms success_commitment
#print axioms success_effects
end audit.trio.deposit.ModulePhysicalMetadata
