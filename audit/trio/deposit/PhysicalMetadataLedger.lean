import audit.trio.deposit.PhysicalMetadata
import audit.trio.deposit.WithdrawalLedgerMinimal

/-! Same-world physical metadata → Lido withdrawal → beacon ledger. The existing
Lido/router inequality transports the physical locator read through the actual
two packed writes; oracle/queue aliases and code-presence assumptions are not
required. The prepared allocation/module prefix retains its existing scope. -/
namespace audit.trio.deposit.PhysicalMetadataLedger
open LidoSRv3.Audit.Source
open TrioReserve1
open audit.trio.deposit
open audit.trio.deposit.LiveBeacon (beaconAddress routerContext)
open TopupRouterCredentials (Keccak)

theorem update_other_slot (hash : Keccak) (ctx : RouterDeposit.Context) (router account : Live.Address)
    (prepared : PreparedDeposit) (before : Live.World) (key : Nat) (h : account ≠ router) :
    (PhysicalMetadata.update hash ctx router prepared before).core.readContractSlot account.val key =
      before.core.readContractSlot account.val key := by
  have hv : account.val ≠ router.val := fun he => h (Verity.Core.Address.ext he)
  by_cases ha : account.val = 0 <;> by_cases hr : router.val = 0 <;>
    simp [PhysicalMetadata.update, Verity.ContractState.readContractSlot,
      Verity.ContractState.writeContractSlot, Verity.ContractState.readSlot,
      Verity.ContractState.writeSlot, Verity.ContractState.storage,
      Verity.ContractState.contractStorage, ha, hr, hv]
  exact False.elim (hv (ha.trans hr.symm))

theorem updated_locator (hash : Keccak) (ctx : RouterDeposit.Context)
    (inputs : RouterDeposit.Inputs) (prepared : PreparedDeposit) (before : Live.World)
    (config : Pipeline.Config)
    (b : WithdrawalLedgerMinimal.LocatorBound config inputs.liveContext before)
    (h : inputs.liveContext.self ≠ inputs.liveContext.sender) :
    WithdrawalLedgerMinimal.LocatorBound config inputs.liveContext
      (PhysicalMetadata.update hash ctx inputs.liveContext.sender prepared before) := by
  unfold WithdrawalLedgerMinimal.LocatorBound
  rw [update_other_slot hash ctx inputs.liveContext.sender inputs.liveContext.self prepared before _ h]
  exact b


/-- Physical metadata and its event precede the exact withdrawal/beacon ledger.
No supplied successful stage or preservation assumption joins the executions. -/
theorem execute_success_conservation (hash : Keccak) (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : Live.External)
    (ctx : RouterDeposit.Context) (inputs : RouterDeposit.Inputs)
    (before after : PhysicalMetadata.World) (attempts : List Live.Attempt)
    (bound : WithdrawalLedgerMinimal.LocatorBound config inputs.liveContext before.live)
    (lido_ne_router : inputs.liveContext.self ≠ inputs.liveContext.sender)
    (router_ne_beacon : inputs.liveContext.sender ≠ beaconAddress ctx)
    (h : PhysicalMetadata.execute hash (Pipeline.external k config staticOther other) ctx inputs before =
      ⟨.ok (), after, attempts⟩) :
    ∃ prepared transcript,
      prepareDepositABI inputs.layout inputs.storage inputs.oracle inputs.config
        inputs.requested before.allocationTranscript inputs.moduleId inputs.limits
        inputs.obtainDepositData DEPOSIT_SIZE = (.ok prepared, transcript) ∧
      CallSpec.Balances before.live.balances after.live.balances
        inputs.liveContext.self (beaconAddress ctx) (prepared.values.actualKeys * DEPOSIT_SIZE) ∧
      after.live.balances inputs.liveContext.sender = before.live.balances inputs.liveContext.sender ∧
      (prepared.values.actualKeys = 0 ∨ inputs.config.maxEBType1.val = DEPOSIT_SIZE) := by
  obtain ⟨credentials, prepared, transcript, hprep, htranscript, hsuffix⟩ :=
    PhysicalMetadata.success_suffix hash (Pipeline.external k config staticOther other)
      ctx inputs before after attempts h
  let updated := PhysicalMetadata.update hash ctx inputs.liveContext.sender prepared before.live
  have hb := updated_locator hash ctx inputs prepared before.live config bound lido_ne_router
  refine ⟨prepared, transcript, hprep, ?_⟩
  by_cases hz : prepared.values.actualKeys = 0
  · rw [audit.trio.deposit.LiveBeacon.zero_keys_no_calls _ ctx inputs.liveContext credentials prepared _ hz] at hsuffix
    have hw := (Live.Result.mk.inj hsuffix).2.1.symm
    rw [hw]
    exact ⟨by simp [CallSpec.Balances, PhysicalMetadata.update, hz], rfl, Or.inl hz⟩
  · obtain ⟨committed, hbeacon, hcount, hcapacity⟩ :=
      LiveBeaconCommitted.suffix_ok_actual_beacon_effects (Pipeline.external k config staticOther other)
        ctx inputs.liveContext credentials prepared updated after.live attempts hz hsuffix
    have values := prepareDepositABI_composes_beacon_values inputs.layout inputs.storage inputs.oracle
      inputs.config inputs.requested before.allocationTranscript transcript inputs.moduleId inputs.limits
      inputs.obtainDepositData DEPOSIT_SIZE prepared hprep
    have hword : (Live.word prepared.values.lidoPullWei).val = prepared.values.lidoPullWei :=
      Nat.mod_eq_of_lt values.2.2.2.2.1
    have hw := WithdrawalLedgerMinimal.pipeline_withdrawal_success_ledger k config staticOther other
      inputs.liveContext (Live.word prepared.values.lidoPullWei) (Live.word prepared.values.actualKeys)
      updated committed.withdrawn committed.withdrawalTrace hb committed.withdrawal_ok
    rw [hword] at hw
    obtain ⟨hfunds, hledger⟩ := hw
    have hwithdraw := CallFlow.transfer_balances updated inputs.liveContext.self
      inputs.liveContext.sender prepared.values.lidoPullWei hfunds
    rw [← hledger] at hwithdraw
    have hwr := hwithdraw inputs.liveContext.sender
    have hbr := hbeacon inputs.liveContext.sender
    simp only [routerContext] at hbr
    simp only [Ne.symm lido_ne_router, if_false, ite_true, Nat.add_zero] at hwr
    simp only [router_ne_beacon, if_false, ite_true, Nat.add_zero] at hbr
    have restored := committed.router_restored
    have hamount : prepared.values.lidoPullWei = prepared.values.actualKeys * DEPOSIT_SIZE := by omega
    have hmax : inputs.config.maxEBType1.val = DEPOSIT_SIZE := by
      have hp := values.2.2.2.1.symm.trans hamount
      exact Nat.eq_of_mul_eq_mul_left (Nat.pos_of_ne_zero hz) hp
    refine ⟨?_, restored, Or.inr hmax⟩
    intro account
    have hw := hwithdraw account
    have hb := hbeacon account
    simp only [routerContext] at hb
    rw [hamount] at hw
    change after.live.balances account +
      (if account = inputs.liveContext.self then prepared.values.actualKeys * DEPOSIT_SIZE else 0) =
      updated.balances account + (if account = beaconAddress ctx then prepared.values.actualKeys * DEPOSIT_SIZE else 0)
    by_cases hl : account = inputs.liveContext.self <;>
      by_cases hr : account = inputs.liveContext.sender <;>
      by_cases hbcn : account = beaconAddress ctx <;>
      simp only [hl, hr, hbcn, if_pos] at hw hb ⊢ <;> omega

#print axioms execute_success_conservation

end audit.trio.deposit.PhysicalMetadataLedger