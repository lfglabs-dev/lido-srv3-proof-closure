import LidoSRv3.Audit.Guarantees.PDeposit1ModuleCalls

/-! Additive physical admission adapter for StakingRouter.deposit, core@17005714.
DSM locator resolution and selected allocation are existing explicit boundaries.
The adapter reads the real registry membership, config status/type and raw WC,
then consumes the unchanged actual module/metadata/withdrawal/beacon program. -/
namespace LidoSRv3.Audit.Source.DepositPhysicalAdmission
set_option autoImplicit false
open LidoSRv3.Audit.Source
open TrioReserve1
open _root_.LidoSRv3.Audit.Source.TopupRouterCredentials (routerRoot)
abbrev Keccak := _root_.LidoSRv3.Audit.Source.TopupRouterCredentials.Keccak
open audit.trio.deposit

/-- OZ 5.2 UintSet is at routerRoot+1; its _positions mapping is its second word. -/
def membershipSlot (hash : Keccak) (id : TrioAlloc1.Word) : Nat :=
  (hash (Live.encode 32 id.val ++ Live.encode 32 (routerRoot + 2))).val

def membership (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) : Nat := (w.core.readContractSlot router.val (membershipSlot hash id)).val

def config (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) : Live.Word :=
  w.core.readContractSlot router.val (TopupRouterCredentials.moduleSlot hash (Live.word id.val))

def status (packed : Live.Word) : Nat := packed.val / 2^224 % 256

/-- Source setType: preserve low 248 bits and overwrite the entire high byte.
All uint8 type values are accepted here; no 1/2 validation is added. -/
def selected (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) : TrioAlloc1.Word :=
  TrioAlloc1.word ((TopupRouterCredentials.raw router w).val % 2^248 +
    TopupRouterCredentials.typeOf (config hash router id w) * 2^248)

def derivedContext (hash : Keccak) (ctx : RouterDeposit.Context) (router : Live.Address)
    (id : TrioAlloc1.Word) (w : Live.World) : RouterDeposit.Context :=
  { ctx with moduleActive := true, withdrawalCredentials := some (selected hash router id w) }

theorem selected_fields (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) :
    (selected hash router id w).val / 2^248 = TopupRouterCredentials.typeOf (config hash router id w) ∧
    (selected hash router id w).val % 2^248 = (TopupRouterCredentials.raw router w).val % 2^248 := by
  have ht := TopupRouterCredentials.typeOf_bound (config hash router id w)
  have hr := Nat.mod_lt (TopupRouterCredentials.raw router w).val (show 0 < 2^248 by decide)
  unfold selected TrioAlloc1.word
  dsimp only
  omega

/-- The status byte is separate from both address/fees and the WC-type byte. -/
theorem status_packed (packed : Live.Word) (low state high : Nat)
    (hl : low < 2^224) (hs : state < 256)
    (h : packed.val = low + state * 2^224 + high * 2^232) : status packed = state := by
  unfold status
  rw [h]
  omega

/-- Encoding consumed by the old suffix, with explicit origin from selected WC. -/
def selectedOctets (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) : List Nat :=
  (TrioAlloc1.encodeWord (selected hash router id w)).map Fin.val

theorem selectedOctets_length (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) : (selectedOctets hash router id w).length = 32 := by
  simp [selectedOctets,TrioAlloc1.encodeWord_length]

private theorem encodeBE_head (width n : Nat) :
    (TrioAlloc1.encodeBE (width+1) n).head? = some (TrioAlloc1.byte (n / 256^width)) := by
  induction width generalizing n with
  | zero => simp [TrioAlloc1.encodeBE]
  | succ width ih =>
    rw [TrioAlloc1.encodeBE, List.head?_append, ih]
    simp [Nat.div_div_eq_div_mul,Nat.pow_succ,Nat.mul_comm]

theorem selectedOctets_head (hash : Keccak) (router : Live.Address) (id : TrioAlloc1.Word)
    (w : Live.World) :
    (selectedOctets hash router id w).head? =
      some (TopupRouterCredentials.typeOf (config hash router id w)) := by
  have hf := (selected_fields hash router id w).1
  have ht := TopupRouterCredentials.typeOf_bound (config hash router id w)
  unfold selectedOctets TrioAlloc1.encodeWord
  rw [List.head?_map,encodeBE_head]
  have hp : 256^31 = 2^248 := by decide
  change some ((selected hash router id w).val / 256^31 % 256) = _
  rw [hp,hf,Nat.mod_eq_of_lt ht]

/-- Authorization precedes membership, then enum conversion/status, then WC.
No writes or calls occur in this new prefix. -/
def program (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) : Live.Exec Unit := fun before =>
  if ctx.caller != ctx.depositSecurityModule then Live.fail (.reason "NotAuthorized") before
  else if membership hash liveCtx.sender i.moduleId before = 0 then
    Live.fail (.reason "StakingModuleUnregistered") before
  else if status (config hash liveCtx.sender i.moduleId before) ≥ 3 then
    Live.fail (.reason "Panic(0x21)") before
  else if status (config hash liveCtx.sender i.moduleId before) ≠ 0 then
    Live.fail (.reason "StakingModuleNotActive") before
  else ModulePhysicalMetadata.program hash m w
    (derivedContext hash ctx liveCtx.sender i.moduleId before) liveCtx i before

def execute (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) : Live.Exec Unit :=
  Live.run (program hash m w ctx liveCtx i)

/-- Inversion derives every new guard and the actual old consumer success.
It requires no hcfg, stage-success or storage-separation assumption. -/
theorem success_admission (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    ctx.caller = ctx.depositSecurityModule ∧
    membership hash liveCtx.sender i.moduleId before ≠ 0 ∧
    status (config hash liveCtx.sender i.moduleId before) = 0 ∧
    ModulePhysicalMetadata.execute hash m w
      (derivedContext hash ctx liveCtx.sender i.moduleId before) liveCtx i before =
      ⟨.ok (),after,attempts⟩ := by
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
      split at hp
      · cases hp
      · split at hp
        · cases hp
        · rename_i hs
          refine ⟨by simpa using ha,hm,by simpa using hs,?_⟩
          unfold ModulePhysicalMetadata.execute Live.run
          rw [hp]

theorem failure_restores (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (fault : Live.Fault)
    (h : execute hash m w ctx liveCtx i before = ⟨.error fault,after,attempts⟩) :
    after = before := by
  unfold execute Live.run at h
  dsimp only at h
  split at h
  · have he := congrArg Live.Result.outcome h
    simp_all
  · exact (Live.Result.mk.inj h).2.1.symm

open ModuleCall ModulePhysicalMetadata

/-- Full previous public consequence, plus physical membership/active guards
and the selected WC word/octet origin on that very same commitment. -/
def Effects (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) : Prop :=
    ctx.caller = ctx.depositSecurityModule ∧
    membership hash liveCtx.sender i.moduleId before ≠ 0 ∧
    status (config hash liveCtx.sender i.moduleId before) = 0 ∧
    let derived := derivedContext hash ctx liveCtx.sender i.moduleId before
    ∃ c : Commitment hash m w derived liveCtx i before after attempts,
      c.credentials = selected hash liveCtx.sender i.moduleId before ∧
      (c.credentials.val / 2^248 = TopupRouterCredentials.typeOf (config hash liveCtx.sender i.moduleId before) ∧
       c.credentials.val % 2^248 = (TopupRouterCredentials.raw liveCtx.sender before).val % 2^248) ∧
      (TrioAlloc1.encodeWord c.credentials).map Fin.val = selectedOctets hash liveCtx.sender i.moduleId before ∧
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
      let updated := PhysicalMetadata.update hash derived liveCtx.sender c.prepared c.moduleWorld
      let key := PhysicalMetadata.moduleDepositSlot hash i.moduleId
      let packed := (updated.core.readContractSlot liveCtx.sender.val key).val
      (packed % 2^64 = c.moduleWorld.core.blockTimestamp.val % 2^64 ∧
       packed / 2^64 % 2^64 = c.moduleWorld.core.blockNumber.val % 2^64 ∧
       packed / 2^128 = (c.moduleWorld.core.readContractSlot liveCtx.sender.val key).val / 2^128) ∧
      updated.balances = c.moduleWorld.balances ∧
      updated.logs = c.moduleWorld.logs ++ [PhysicalMetadata.routerEvent liveCtx.sender c.prepared] ∧
      ((c.prepared.values.actualKeys = 0 ∧ after = updated ∧ c.suffixTrace = [] ∧ attempts = c.moduleTrace) ∨
       (c.prepared.values.actualKeys ≠ 0 ∧ Nonempty
         (LiveBeaconCommitted.SuffixCommitment w derived liveCtx c.credentials c.prepared updated after c.suffixTrace)))

theorem success_effects (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt)
    (h : execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    Effects hash m w ctx liveCtx i before after attempts := by
  obtain ⟨ha,hm,hs,hold⟩ := success_admission hash m w ctx liveCtx i before after attempts h
  obtain ⟨c,hrest⟩ := LidoSRv3.Audit.Guarantees.PDeposit1.actual_module_call_metadata_suffix
    hash m w (derivedContext hash ctx liveCtx.sender i.moduleId before) liveCtx i before after attempts hold
  have hc : c.credentials = selected hash liveCtx.sender i.moduleId before := by
    have captured := c.credentials_captured
    simp only [derivedContext] at captured
    exact (Option.some.inj captured).symm
  refine ⟨ha,hm,hs,c,hc,?_,?_,hrest⟩
  · rw [hc]
    exact selected_fields hash liveCtx.sender i.moduleId before
  · rw [hc]
    rfl

end LidoSRv3.Audit.Source.DepositPhysicalAdmission
