import LidoSRv3.Model

namespace LidoSRv3

/-!
  P0 proof targets. These are Lean-checked theorems over the SRv3 Verity model,
  conditional on the source-correspondence and environment assumptions listed in
  `verity/targets/trust-boundary.json`.
-/

private theorem report_sum_matches_zipWith
    (modules : List Module) (r : List (ModuleId × Gwei))
    (hLen : r.length = modules.length) :
    (reportBalances r).sum =
      moduleBalanceSum (applyReportToModules modules r) := by
  induction modules generalizing r with
  | nil =>
      cases r with
      | nil => simp [reportBalances, moduleBalanceSum, applyReportToModules]
      | cons row rs => simp at hLen
  | cons m ms ih =>
      cases r with
      | nil => simp at hLen
      | cons row rs =>
          have hTail : rs.length = ms.length := Nat.succ.inj hLen
          simp [reportBalances, moduleBalanceSum, applyReportToModules]
          exact ih rs hTail

private theorem report_balances_match_zipWith
    (modules : List Module) (r : List (ModuleId × Gwei))
    (hLen : r.length = modules.length) :
    reportBalances r =
      (applyReportToModules modules r).map Module.validatorsBalanceGwei := by
  induction modules generalizing r with
  | nil =>
      cases r with
      | nil => simp [reportBalances, applyReportToModules]
      | cons row rs => simp at hLen
  | cons m ms ih =>
      cases r with
      | nil => simp at hLen
      | cons row rs =>
          have hTail : rs.length = ms.length := Nat.succ.inj hLen
          simp [reportBalances, applyReportToModules]
          exact ih rs hTail

private theorem find_recordModuleLastDeposit_records_value
    (modules : List Module) (moduleId : ModuleId) (depositsValue : Wei)
    (m : Module)
    (hFind : modules.find? (fun m => m.id = moduleId) = some m) :
    ∃ m',
      (recordModuleLastDeposit moduleId depositsValue modules).find?
          (fun m => m.id = moduleId) = some m' ∧
        m'.lastDepositWei = depositsValue := by
  induction modules with
  | nil =>
      simp at hFind
  | cons head tail ih =>
      by_cases hHead : head.id = moduleId
      · simp [recordModuleLastDeposit, updateModuleById, hHead]
      · simp [recordModuleLastDeposit, updateModuleById, hHead] at hFind ⊢
        exact ih hFind

private theorem updateModuleById_length
    (moduleId : ModuleId) (f : Module → Module) (modules : List Module) :
    (updateModuleById moduleId f modules).length = modules.length := by
  induction modules with
  | nil =>
      simp [updateModuleById]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [updateModuleById, hId, ih]
      · simp [updateModuleById, hId, ih]

private theorem record_last_deposit_preserves_balances
    (modules : List Module) (moduleId : ModuleId) (depositsValue : Wei) :
    (recordModuleLastDeposit moduleId depositsValue modules).map
        Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules with
  | nil =>
      simp [recordModuleLastDeposit, updateModuleById]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [recordModuleLastDeposit, updateModuleById, hId]
        simpa [recordModuleLastDeposit] using ih
      · simp [recordModuleLastDeposit, updateModuleById, hId]
        simpa [recordModuleLastDeposit] using ih

private theorem roundDownToGwei_le (amount : Wei) :
    roundDownToGwei amount ≤ amount := by
  unfold roundDownToGwei
  exact Nat.sub_le amount (amount % oneGweiWei)

/--
  Reserve separation. The depositable bucket and the effective
  withdrawal-reserved bucket partition the buffer exactly: their sum is the
  whole buffer, so depositable ether never includes any withdrawal liquidity.
  This is derived from the reserve definitions (not assumed), which is why the
  two Nat subtractions in `unreservedEther` do not truncate.
-/
theorem P1_reserve_separation (s : State) :
    depositableEther s + withdrawalReserveUsed s = s.bufferedEther := by
  have hDep : depositReserveUsed s ≤ s.bufferedEther := Nat.min_le_left _ _
  have hWit : withdrawalReserveUsed s ≤ s.bufferedEther - depositReserveUsed s :=
    Nat.min_le_left _ _
  unfold depositableEther unreservedEther
  rw [Nat.add_assoc, Nat.sub_add_cancel hWit, Nat.add_sub_cancel' hDep]

/--
  Corollary: depositable ether excludes the withdrawal-reserved liquidity, so a
  deposit spend bounded by `depositableEther` cannot draw on saved withdrawal
  funds.
-/
theorem P1_depositable_excludes_withdrawal_reserve (s : State) :
    depositableEther s ≤ s.bufferedEther - withdrawalReserveUsed s := by
  have h := P1_reserve_separation s
  have heq : s.bufferedEther - withdrawalReserveUsed s = depositableEther s := by
    rw [← h, Nat.add_sub_cancel]
  exact Nat.le_of_eq heq.symm

theorem P2_deposit_exact_pull (actualDeposits : Nat) :
    depositPullWei actualDeposits = validatorDepositWei * actualDeposits := by
  rfl

theorem P2_deposit_transition_router_eth_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.routerEthBalanceWei = s.routerEthBalanceWei := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            simpa using congrArg State.routerEthBalanceWei h.symm
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              simpa using congrArg State.routerEthBalanceWei h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_beacon_sink_exact
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (hNonzero : actualDeposits ≠ 0)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.beaconDepositSinkWei = s.beaconDepositSinkWei + depositPullWei actualDeposits := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · contradiction
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              exact congrArg State.beaconDepositSinkWei h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_buffered_exact
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (hNonzero : actualDeposits ≠ 0)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.bufferedEther = s.bufferedEther - depositPullWei actualDeposits := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · contradiction
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              exact congrArg State.bufferedEther h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_positive_requires_depositable
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (hNonzero : actualDeposits ≠ 0)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    depositPullWei actualDeposits ≤ depositableEther s := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · contradiction
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · exact hAllowed
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_zero_external_value_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (hZero : actualDeposits = 0)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          simp [hZero] at h
          constructor
          · simpa using congrArg State.bufferedEther h.symm
          · simpa using congrArg State.beaconDepositSinkWei h.symm
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_withdrawal_reserve_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.withdrawalReserve = s.withdrawalReserve := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            simpa using congrArg State.withdrawalReserve h.symm
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              simpa using congrArg State.withdrawalReserve h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_deposit_reserve_spent
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (hNonzero : actualDeposits ≠ 0)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.depositReserve = s.depositReserve - depositPullWei actualDeposits := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · contradiction
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              exact congrArg State.depositReserve h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_requires_active_module_and_capacity
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    ∃ m,
      s.modules.find? (fun m => m.id = stakingModuleId) = some m ∧
        m.status = ModuleStatus.active ∧
          depositMaxCount m moduleAllocationWei ≠ 0 ∧
            actualDeposits ≤ depositMaxCount m moduleAllocationWei := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · exact ⟨m, hFind, hActive, hMax, hLe⟩
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_modules_exact
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.modules =
      recordModuleLastDeposit stakingModuleId
        (depositPullWei actualDeposits) s.modules := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            simpa [hZero] using congrArg State.modules h.symm
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              simpa using congrArg State.modules h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_records_last_deposit
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    ∃ m,
      s'.modules.find? (fun m => m.id = stakingModuleId) = some m ∧
        m.lastDepositWei = depositPullWei actualDeposits := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          have hRecord :
              ∃ m',
                (recordModuleLastDeposit stakingModuleId
                    (depositPullWei actualDeposits) s.modules).find?
                    (fun m => m.id = stakingModuleId) = some m' ∧
                  m'.lastDepositWei = depositPullWei actualDeposits := by
            simpa using
              find_recordModuleLastDeposit_records_value
                s.modules stakingModuleId (depositPullWei actualDeposits) m hFind
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            simpa [h.symm, hZero] using hRecord
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              simpa [h.symm] using hRecord
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_preserves_module_length
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.modules.length = s.modules.length := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            rw [← h]
            simpa [recordModuleLastDeposit, hZero] using
              updateModuleById_length stakingModuleId
                (fun m => { m with lastDepositWei := depositPullWei actualDeposits })
                s.modules
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              rw [← h]
              simpa [recordModuleLastDeposit] using
                updateModuleById_length stakingModuleId
                  (fun m => { m with lastDepositWei := depositPullWei actualDeposits })
                  s.modules
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_preserves_module_balance_sum
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            rw [← h]
            unfold moduleBalanceSum
            rw [record_last_deposit_preserves_balances s.modules stakingModuleId
              (depositPullWei 0)]
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              rw [← h]
              unfold moduleBalanceSum
              rw [record_last_deposit_preserves_balances s.modules stakingModuleId
                (depositPullWei actualDeposits)]
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

theorem P2_deposit_transition_preserves_report_state
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (actualDeposits : Nat)
    (h : depositTransition s stakingModuleId moduleAllocationWei actualDeposits = some s') :
    s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  unfold depositTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hMax : depositMaxCount m moduleAllocationWei = 0
      · simp [hMax] at h
      · simp [hMax] at h
        by_cases hLe : actualDeposits ≤ depositMaxCount m moduleAllocationWei
        · simp [hLe] at h
          by_cases hZero : actualDeposits = 0
          · simp [hZero] at h
            constructor
            · simpa using congrArg State.routerBalanceGwei h.symm
            · simpa using congrArg State.lastAcceptedReport h.symm
          · simp [hZero] at h
            by_cases hAllowed : depositPullWei actualDeposits ≤ depositableEther s
            · simp [hAllowed] at h
              constructor
              · simpa using congrArg State.routerBalanceGwei h.symm
              · simpa using congrArg State.lastAcceptedReport h.symm
            · simp [hAllowed] at h
        · simp [hLe] at h
    · simp [hActive] at h

/--
  Deposit-allocation conservation. For a well-formed per-module allocation
  (only active modules carry a positive count), the total allocated equals the
  sum of the per-module allocated amounts. The router deposit budget is split
  across modules; the module deltas sum to the total instead of every active
  module receiving the full count.
-/
theorem P2_total_allocated_deposits
    (rows : List (Module × Nat)) :
    depositAllocationWellFormed rows →
      totalAllocatedDeposits rows = (rows.map Prod.snd).sum := by
  induction rows with
  | nil => intro _; rfl
  | cons r rs ih =>
      intro h
      have hrow : allocatedDeposits r.fst r.snd = r.snd := by
        unfold allocatedDeposits
        by_cases hActive : r.fst.status = ModuleStatus.active
        · simp [hActive]
        · have hzero : r.snd = 0 := h r (List.mem_cons_self) hActive
          simp [hActive, hzero]
      have hrest : depositAllocationWellFormed rs :=
        fun row hmem => h row (List.mem_cons_of_mem r hmem)
      have hcons : totalAllocatedDeposits (r :: rs) =
          allocatedDeposits r.fst r.snd + totalAllocatedDeposits rs := by
        simp [totalAllocatedDeposits]
      rw [hcons, hrow, ih hrest]
      simp

theorem P9_allocation_capacity_rows_aligned
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) (row : AllocationCapacityRow)
    (h : row ∈ modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp) :
    ∃ m ∈ modules,
      row = allocationCapacityRow cfg modules depositsToAllocate isTopUp m := by
  simp [modulesAllocationAndCapacity] at h
  rcases h with ⟨m, hm, hrow⟩
  exact ⟨m, hm, hrow.symm⟩

theorem P9_allocation_capacity_length
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) :
    (modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp).length =
      modules.length := by
  simp [modulesAllocationAndCapacity]

theorem P9_allocation_capacity_values_length
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) :
    (allocatedCapacityValues
        (modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp)).length =
      modules.length := by
  simp [allocatedCapacityValues, modulesAllocationAndCapacity]

theorem P9_allocation_capacity_module_ids_preserved
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) :
    (modulesAllocationAndCapacity cfg modules depositsToAllocate isTopUp).map
        AllocationCapacityRow.moduleId =
      modules.map Module.id := by
  simp [modulesAllocationAndCapacity, allocationCapacityRow]

theorem P9_active_allocation_capacity_target_bound
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) (m : Module)
    (hActive : m.status = ModuleStatus.active) :
    (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).capacity ≤
      (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).targetValidators := by
  simpa [allocationCapacityRow, hActive] using
    Nat.min_le_left
      (moduleTargetValidators cfg modules depositsToAllocate m)
      (moduleAvailableCapacityEquivalent cfg isTopUp m)

theorem P9_active_allocation_capacity_available_bound
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) (m : Module)
    (hActive : m.status = ModuleStatus.active) :
    (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).capacity ≤
      moduleAvailableCapacityEquivalent cfg isTopUp m := by
  simpa [allocationCapacityRow, hActive] using
    Nat.min_le_right
      (moduleTargetValidators cfg modules depositsToAllocate m)
      (moduleAvailableCapacityEquivalent cfg isTopUp m)

theorem P9_inactive_allocation_capacity_current
    (cfg : AllocationConfig) (modules : List Module) (depositsToAllocate : Nat)
    (isTopUp : Bool) (m : Module)
    (hInactive : m.status ≠ ModuleStatus.active) :
    (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).capacity =
      (allocationCapacityRow cfg modules depositsToAllocate isTopUp m).currentAllocation := by
  simp [allocationCapacityRow, hInactive]

private theorem update_all_module_fees_length
    (modules : List Module) (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length) :
    (updateAllModuleFeesInModules modules moduleFees treasuryFees).length =
      modules.length := by
  induction modules generalizing moduleFees treasuryFees with
  | nil =>
      simp [updateAllModuleFeesInModules]
  | cons m ms ih =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              have hModuleTail : moduleFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hModuleLen
              have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hTreasuryLen
              simp [updateAllModuleFeesInModules,
                ih moduleFeesTail treasuryFeesTail hModuleTail hTreasuryTail]

private theorem update_all_module_fees_preserves_balances
    (modules : List Module) (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length) :
    (updateAllModuleFeesInModules modules moduleFees treasuryFees).map
        Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules generalizing moduleFees treasuryFees with
  | nil =>
      simp [updateAllModuleFeesInModules]
  | cons m ms ih =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              have hModuleTail : moduleFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hModuleLen
              have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hTreasuryLen
              simp [updateAllModuleFeesInModules,
                ih moduleFeesTail treasuryFeesTail hModuleTail hTreasuryTail]

private theorem update_all_module_fees_module_fee_projection
    (modules : List Module) (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length) :
    (updateAllModuleFeesInModules modules moduleFees treasuryFees).map
        Module.moduleFeeBps =
      moduleFees := by
  induction modules generalizing moduleFees treasuryFees with
  | nil =>
      cases moduleFees with
      | nil => simp [updateAllModuleFeesInModules]
      | cons moduleFee moduleFeesTail => simp at hModuleLen
  | cons m ms ih =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              have hModuleTail : moduleFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hModuleLen
              have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hTreasuryLen
              simp [updateAllModuleFeesInModules,
                ih moduleFeesTail treasuryFeesTail hModuleTail hTreasuryTail]

private theorem update_all_module_fees_treasury_fee_projection
    (modules : List Module) (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length) :
    (updateAllModuleFeesInModules modules moduleFees treasuryFees).map
        Module.treasuryFeeBps =
      treasuryFees := by
  induction modules generalizing moduleFees treasuryFees with
  | nil =>
      cases treasuryFees with
      | nil => simp [updateAllModuleFeesInModules]
      | cons treasuryFee treasuryFeesTail => simp at hTreasuryLen
  | cons m ms ih =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              have hModuleTail : moduleFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hModuleLen
              have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                simpa using Nat.succ.inj hTreasuryLen
              simp [updateAllModuleFeesInModules,
                ih moduleFeesTail treasuryFeesTail hModuleTail hTreasuryTail]

private theorem update_all_module_fees_bounded_from_expected
    (expectedFeeSum : Nat) (modules : List Module)
    (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length)
    (hValid :
      feeRowsValidFromExpected expectedFeeSum moduleFees treasuryFees = true) :
    moduleFeeSumsWithinBps
      (updateAllModuleFeesInModules modules moduleFees treasuryFees) = true := by
  induction modules generalizing moduleFees treasuryFees with
  | nil =>
      simp [updateAllModuleFeesInModules, moduleFeeSumsWithinBps]
  | cons m ms ih =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              unfold feeRowsValidFromExpected at hValid
              by_cases hBound : moduleFee + treasuryFee ≤ bpsDenominator
              · simp [hBound] at hValid
                rcases hValid with ⟨_hConsistent, hTailValid⟩
                have hModuleTail : moduleFeesTail.length = ms.length := by
                  simpa using Nat.succ.inj hModuleLen
                have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                  simpa using Nat.succ.inj hTreasuryLen
                simp [updateAllModuleFeesInModules, moduleFeeSumsWithinBps,
                  hBound,
                  ih moduleFeesTail treasuryFeesTail hModuleTail hTreasuryTail
                    hTailValid]
              · simp [hBound] at hValid

private theorem update_all_module_fees_bounded
    (modules : List Module) (moduleFees treasuryFees : List Bps)
    (hModuleLen : moduleFees.length = modules.length)
    (hTreasuryLen : treasuryFees.length = modules.length)
    (hValid : allModuleFeesConsistent moduleFees treasuryFees = true) :
    moduleFeeSumsWithinBps
      (updateAllModuleFeesInModules modules moduleFees treasuryFees) = true := by
  cases modules with
  | nil =>
      simp [updateAllModuleFeesInModules, moduleFeeSumsWithinBps]
  | cons m ms =>
      cases moduleFees with
      | nil => simp at hModuleLen
      | cons moduleFee moduleFeesTail =>
          cases treasuryFees with
          | nil => simp at hTreasuryLen
          | cons treasuryFee treasuryFeesTail =>
              unfold allModuleFeesConsistent at hValid
              by_cases hBound : moduleFee + treasuryFee ≤ bpsDenominator
              · simp [hBound] at hValid
                have hModuleTail : moduleFeesTail.length = ms.length := by
                  simpa using Nat.succ.inj hModuleLen
                have hTreasuryTail : treasuryFeesTail.length = ms.length := by
                  simpa using Nat.succ.inj hTreasuryLen
                simp [updateAllModuleFeesInModules, moduleFeeSumsWithinBps,
                  hBound,
                  update_all_module_fees_bounded_from_expected
                    (moduleFee + treasuryFee) ms moduleFeesTail treasuryFeesTail
                    hModuleTail hTreasuryTail hValid]
              · simp [hBound] at hValid

theorem P11_update_all_module_fees_requires_lengths
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    moduleFees.length = s.modules.length ∧
      treasuryFees.length = s.modules.length := by
  unfold updateAllModuleFeesTransition at h
  split at h
  · assumption
  · cases h

theorem P11_update_all_module_fees_requires_consistent_rows
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    allModuleFeesConsistent moduleFees treasuryFees = true := by
  unfold updateAllModuleFeesTransition at h
  split at h
  · by_cases hValid : allModuleFeesConsistent moduleFees treasuryFees = true
    · simp [hValid] at h
      exact hValid
    · simp [hValid] at h
  · cases h

theorem P11_update_all_module_fees_preserves_module_length
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    s'.modules.length = s.modules.length := by
  rcases P11_update_all_module_fees_requires_lengths
      s s' moduleFees treasuryFees h with ⟨hModuleLen, hTreasuryLen⟩
  unfold updateAllModuleFeesTransition at h
  simp [hModuleLen, hTreasuryLen] at h
  by_cases hValid : allModuleFeesConsistent moduleFees treasuryFees = true
  · simp [hValid] at h
    cases h
    exact update_all_module_fees_length s.modules moduleFees treasuryFees
      hModuleLen hTreasuryLen
  · simp [hValid] at h

theorem P11_update_all_module_fees_exact_fee_projections
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    s'.modules.map Module.moduleFeeBps = moduleFees ∧
      s'.modules.map Module.treasuryFeeBps = treasuryFees := by
  rcases P11_update_all_module_fees_requires_lengths
      s s' moduleFees treasuryFees h with ⟨hModuleLen, hTreasuryLen⟩
  have hValid :=
    P11_update_all_module_fees_requires_consistent_rows
      s s' moduleFees treasuryFees h
  unfold updateAllModuleFeesTransition at h
  simp [hModuleLen, hTreasuryLen, hValid] at h
  cases h
  constructor
  · exact update_all_module_fees_module_fee_projection s.modules moduleFees
      treasuryFees hModuleLen hTreasuryLen
  · exact update_all_module_fees_treasury_fee_projection s.modules moduleFees
      treasuryFees hModuleLen hTreasuryLen

theorem P11_update_all_module_fees_bounded_after_success
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    moduleFeeSumsWithinBps s'.modules = true := by
  rcases P11_update_all_module_fees_requires_lengths
      s s' moduleFees treasuryFees h with ⟨hModuleLen, hTreasuryLen⟩
  have hValid :=
    P11_update_all_module_fees_requires_consistent_rows
      s s' moduleFees treasuryFees h
  unfold updateAllModuleFeesTransition at h
  simp [hModuleLen, hTreasuryLen, hValid] at h
  cases h
  exact update_all_module_fees_bounded s.modules moduleFees treasuryFees
    hModuleLen hTreasuryLen hValid

theorem P11_update_all_module_fees_preserves_module_balance_sum
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  rcases P11_update_all_module_fees_requires_lengths
      s s' moduleFees treasuryFees h with ⟨hModuleLen, hTreasuryLen⟩
  have hValid :=
    P11_update_all_module_fees_requires_consistent_rows
      s s' moduleFees treasuryFees h
  unfold updateAllModuleFeesTransition at h
  simp [hModuleLen, hTreasuryLen, hValid] at h
  cases h
  unfold moduleBalanceSum
  rw [update_all_module_fees_preserves_balances
    s.modules moduleFees treasuryFees hModuleLen hTreasuryLen]

theorem P11_update_all_module_fees_preserves_router_state
    (s s' : State) (moduleFees treasuryFees : List Bps)
    (h : updateAllModuleFeesTransition s moduleFees treasuryFees = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  rcases P11_update_all_module_fees_requires_lengths
      s s' moduleFees treasuryFees h with ⟨hModuleLen, hTreasuryLen⟩
  have hValid :=
    P11_update_all_module_fees_requires_consistent_rows
      s s' moduleFees treasuryFees h
  unfold updateAllModuleFeesTransition at h
  simp [hModuleLen, hTreasuryLen, hValid] at h
  cases h
  simp

private theorem update_all_module_shares_length
    (modules : List Module) (stakeShares priorityExitShares : List Bps)
    (hStakeLen : stakeShares.length = modules.length)
    (hPriorityLen : priorityExitShares.length = modules.length) :
    (updateAllModuleSharesInModules modules stakeShares priorityExitShares).length =
      modules.length := by
  induction modules generalizing stakeShares priorityExitShares with
  | nil =>
      simp [updateAllModuleSharesInModules]
  | cons m ms ih =>
      cases stakeShares with
      | nil => simp at hStakeLen
      | cons stakeShare stakeSharesTail =>
          cases priorityExitShares with
          | nil => simp at hPriorityLen
          | cons priorityExitShare priorityExitSharesTail =>
              have hStakeTail : stakeSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hStakeLen
              have hPriorityTail :
                  priorityExitSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hPriorityLen
              simp [updateAllModuleSharesInModules,
                ih stakeSharesTail priorityExitSharesTail hStakeTail
                  hPriorityTail]

private theorem update_all_module_shares_balances
    (modules : List Module) (stakeShares priorityExitShares : List Bps)
    (hStakeLen : stakeShares.length = modules.length)
    (hPriorityLen : priorityExitShares.length = modules.length) :
    (updateAllModuleSharesInModules modules stakeShares priorityExitShares).map
        Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules generalizing stakeShares priorityExitShares with
  | nil =>
      simp [updateAllModuleSharesInModules]
  | cons m ms ih =>
      cases stakeShares with
      | nil => simp at hStakeLen
      | cons stakeShare stakeSharesTail =>
          cases priorityExitShares with
          | nil => simp at hPriorityLen
          | cons priorityExitShare priorityExitSharesTail =>
              have hStakeTail : stakeSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hStakeLen
              have hPriorityTail :
                  priorityExitSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hPriorityLen
              simp [updateAllModuleSharesInModules,
                ih stakeSharesTail priorityExitSharesTail hStakeTail
                  hPriorityTail]

private theorem update_all_module_shares_stake_projection
    (modules : List Module) (stakeShares priorityExitShares : List Bps)
    (hStakeLen : stakeShares.length = modules.length)
    (hPriorityLen : priorityExitShares.length = modules.length) :
    (updateAllModuleSharesInModules modules stakeShares priorityExitShares).map
        Module.stakeShareLimitBps =
      stakeShares := by
  induction modules generalizing stakeShares priorityExitShares with
  | nil =>
      cases stakeShares with
      | nil => simp [updateAllModuleSharesInModules]
      | cons stakeShare stakeSharesTail => simp at hStakeLen
  | cons m ms ih =>
      cases stakeShares with
      | nil => simp at hStakeLen
      | cons stakeShare stakeSharesTail =>
          cases priorityExitShares with
          | nil => simp at hPriorityLen
          | cons priorityExitShare priorityExitSharesTail =>
              have hStakeTail : stakeSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hStakeLen
              have hPriorityTail :
                  priorityExitSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hPriorityLen
              simp [updateAllModuleSharesInModules,
                ih stakeSharesTail priorityExitSharesTail hStakeTail
                  hPriorityTail]

private theorem update_all_module_shares_priority_projection
    (modules : List Module) (stakeShares priorityExitShares : List Bps)
    (hStakeLen : stakeShares.length = modules.length)
    (hPriorityLen : priorityExitShares.length = modules.length) :
    (updateAllModuleSharesInModules modules stakeShares priorityExitShares).map
        Module.priorityExitShareThresholdBps =
      priorityExitShares := by
  induction modules generalizing stakeShares priorityExitShares with
  | nil =>
      cases priorityExitShares with
      | nil => simp [updateAllModuleSharesInModules]
      | cons priorityExitShare priorityExitSharesTail => simp at hPriorityLen
  | cons m ms ih =>
      cases stakeShares with
      | nil => simp at hStakeLen
      | cons stakeShare stakeSharesTail =>
          cases priorityExitShares with
          | nil => simp at hPriorityLen
          | cons priorityExitShare priorityExitSharesTail =>
              have hStakeTail : stakeSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hStakeLen
              have hPriorityTail :
                  priorityExitSharesTail.length = ms.length := by
                simpa using Nat.succ.inj hPriorityLen
              simp [updateAllModuleSharesInModules,
                ih stakeSharesTail priorityExitSharesTail hStakeTail
                  hPriorityTail]

theorem P15_update_all_module_shares_requires_lengths
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    stakeShares.length = s.modules.length ∧
      priorityExitShares.length = s.modules.length := by
  unfold updateAllModuleSharesTransition at h
  split at h
  · assumption
  · cases h

theorem P15_update_all_module_shares_requires_valid_rows
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    allModuleSharesValid stakeShares priorityExitShares = true := by
  unfold updateAllModuleSharesTransition at h
  split at h
  · by_cases hValid :
      allModuleSharesValid stakeShares priorityExitShares = true
    · simp [hValid] at h
      exact hValid
    · simp [hValid] at h
  · cases h

theorem P15_update_all_module_shares_preserves_module_length
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    s'.modules.length = s.modules.length := by
  rcases P15_update_all_module_shares_requires_lengths
      s s' stakeShares priorityExitShares h with ⟨hStakeLen, hPriorityLen⟩
  have hValid :=
    P15_update_all_module_shares_requires_valid_rows
      s s' stakeShares priorityExitShares h
  unfold updateAllModuleSharesTransition at h
  simp [hStakeLen, hPriorityLen, hValid] at h
  cases h
  exact update_all_module_shares_length s.modules stakeShares priorityExitShares
    hStakeLen hPriorityLen

theorem P15_update_all_module_shares_exact_share_projections
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    s'.modules.map Module.stakeShareLimitBps = stakeShares ∧
      s'.modules.map Module.priorityExitShareThresholdBps = priorityExitShares := by
  rcases P15_update_all_module_shares_requires_lengths
      s s' stakeShares priorityExitShares h with ⟨hStakeLen, hPriorityLen⟩
  have hValid :=
    P15_update_all_module_shares_requires_valid_rows
      s s' stakeShares priorityExitShares h
  unfold updateAllModuleSharesTransition at h
  simp [hStakeLen, hPriorityLen, hValid] at h
  cases h
  constructor
  · exact update_all_module_shares_stake_projection s.modules stakeShares
      priorityExitShares hStakeLen hPriorityLen
  · exact update_all_module_shares_priority_projection s.modules stakeShares
      priorityExitShares hStakeLen hPriorityLen

theorem P15_update_all_module_shares_preserves_module_balance_sum
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  rcases P15_update_all_module_shares_requires_lengths
      s s' stakeShares priorityExitShares h with ⟨hStakeLen, hPriorityLen⟩
  have hValid :=
    P15_update_all_module_shares_requires_valid_rows
      s s' stakeShares priorityExitShares h
  unfold updateAllModuleSharesTransition at h
  simp [hStakeLen, hPriorityLen, hValid] at h
  cases h
  unfold moduleBalanceSum
  rw [update_all_module_shares_balances s.modules stakeShares
    priorityExitShares hStakeLen hPriorityLen]

theorem P15_update_all_module_shares_preserves_router_state
    (s s' : State) (stakeShares priorityExitShares : List Bps)
    (h :
      updateAllModuleSharesTransition s stakeShares priorityExitShares =
        some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  rcases P15_update_all_module_shares_requires_lengths
      s s' stakeShares priorityExitShares h with ⟨hStakeLen, hPriorityLen⟩
  have hValid :=
    P15_update_all_module_shares_requires_valid_rows
      s s' stakeShares priorityExitShares h
  unfold updateAllModuleSharesTransition at h
  simp [hStakeLen, hPriorityLen, hValid] at h
  cases h
  simp

private theorem update_module_params_length
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat) :
    (updateModuleParamsInModules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance modules).length = modules.length := by
  induction modules with
  | nil =>
      simp [updateModuleParamsInModules]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [updateModuleParamsInModules, hId, ih]
      · simp [updateModuleParamsInModules, hId, ih]

private theorem update_module_params_balances
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat) :
    (updateModuleParamsInModules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance modules).map Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules with
  | nil =>
      simp [updateModuleParamsInModules]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [updateModuleParamsInModules, hId, ih]
      · simp [updateModuleParamsInModules, hId, ih]

private theorem update_module_params_bounded
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (hBound : moduleFee + treasuryFee ≤ bpsDenominator)
    (hConsistent :
      otherModulesFeeSumConsistent modules moduleId
        (moduleFee + treasuryFee) = true) :
    moduleFeeSumsWithinBps
      (updateModuleParamsInModules moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance modules) = true := by
  induction modules with
  | nil =>
      simp [updateModuleParamsInModules, moduleFeeSumsWithinBps]
  | cons m ms ih =>
      unfold otherModulesFeeSumConsistent at hConsistent
      by_cases hId : m.id = moduleId
      · simp [hId] at hConsistent
        simp [updateModuleParamsInModules, moduleFeeSumsWithinBps, hId, hBound,
          ih hConsistent]
      · simp [hId] at hConsistent
        rcases hConsistent with ⟨hHead, hTail⟩
        have hHeadBound : m.moduleFeeBps + m.treasuryFeeBps ≤ bpsDenominator := by
          have hModuleBound : moduleFeeSum m ≤ bpsDenominator := by
            rw [hHead]
            exact hBound
          simpa [moduleFeeSum] using hModuleBound
        simp [updateModuleParamsInModules, moduleFeeSumsWithinBps, hId,
          hHeadBound, ih hTail]

private theorem update_module_params_find_records
    (modules : List Module) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (m : Module)
    (hFind : modules.find? (fun candidate => candidate.id = moduleId) = some m) :
    ∃ m',
      (updateModuleParamsInModules moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance modules).find?
          (fun candidate => candidate.id = moduleId) = some m' ∧
        m'.stakeShareLimitBps = stakeShareLimit ∧
        m'.priorityExitShareThresholdBps = priorityExitShareThreshold ∧
        m'.moduleFeeBps = moduleFee ∧
        m'.treasuryFeeBps = treasuryFee ∧
        m'.maxDepositsPerBlock = maxDepositsPerBlock ∧
        m'.minDepositBlockDistance = minDepositBlockDistance := by
  induction modules with
  | nil =>
      simp at hFind
  | cons head tail ih =>
      by_cases hHead : head.id = moduleId
      · simp [updateModuleParamsInModules, hHead]
      · simp [updateModuleParamsInModules, hHead] at hFind ⊢
        exact ih hFind

theorem P12_update_module_params_requires_existing_module
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    ∃ m, s.modules.find? (fun candidate => candidate.id = moduleId) = some m := by
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · rename_i m hFind
    exact ⟨m, hFind⟩

theorem P12_update_module_params_requires_valid_config
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    singleModuleParamsValid s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance = true := by
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · by_cases hValid :
        singleModuleParamsValid s.modules moduleId stakeShareLimit
          priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
          minDepositBlockDistance = true
    · simp [hValid] at h
      exact hValid
    · simp [hValid] at h

/--
  New at `af095e48`: `_updateModuleParams` rejects a zero `maxDepositsPerBlock`
  (`InvalidMaxDepositPerBlockValue`), so a successful update implies a positive
  per-block deposit limit.
-/
theorem P12_update_module_params_requires_positive_max_deposits
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    maxDepositsPerBlock ≠ 0 := by
  have hValidParts :=
    P12_update_module_params_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance h
  unfold singleModuleParamsValid at hValidParts
  simp at hValidParts
  rcases hValidParts with ⟨hLeft, _hMaxBound⟩
  rcases hLeft with ⟨_hRest, hMaxNonzero⟩
  exact hMaxNonzero

theorem P12_update_module_params_preserves_module_length
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    s'.modules.length = s.modules.length := by
  have hValid :=
    P12_update_module_params_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance h
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · simp [hValid] at h
    cases h
    exact update_module_params_length s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance

theorem P12_update_module_params_records_requested_params
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    ∃ m',
      s'.modules.find? (fun candidate => candidate.id = moduleId) = some m' ∧
        m'.stakeShareLimitBps = stakeShareLimit ∧
        m'.priorityExitShareThresholdBps = priorityExitShareThreshold ∧
        m'.moduleFeeBps = moduleFee ∧
        m'.treasuryFeeBps = treasuryFee ∧
        m'.maxDepositsPerBlock = maxDepositsPerBlock ∧
        m'.minDepositBlockDistance = minDepositBlockDistance := by
  have hValid :=
    P12_update_module_params_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance h
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · rename_i m hFind
    simp [hValid] at h
    cases h
    exact update_module_params_find_records s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance m hFind

theorem P12_update_module_params_bounded_after_success
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    moduleFeeSumsWithinBps s'.modules = true := by
  have hValidBool :=
    P12_update_module_params_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance h
  have hValidParts := hValidBool
  unfold singleModuleParamsValid at hValidParts
  simp at hValidParts
  rcases hValidParts with ⟨hLeft, _hMaxBound⟩
  rcases hLeft with ⟨hLeft, _hMaxNonzero⟩
  rcases hLeft with ⟨hLeft, _hMinBound⟩
  rcases hLeft with ⟨hLeft, _hMinNonzero⟩
  rcases hLeft with ⟨hLeft, hConsistent⟩
  rcases hLeft with ⟨_hShare, hBound⟩
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · simp [hValidBool] at h
    cases h
    exact update_module_params_bounded s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance hBound hConsistent

theorem P12_update_module_params_preserves_module_balance_sum
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  have hValid :=
    P12_update_module_params_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance h
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · simp [hValid] at h
    cases h
    unfold moduleBalanceSum
    rw [update_module_params_balances s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance]

theorem P12_update_module_params_preserves_router_state
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (h :
      updateModuleParamsTransition s moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  have hValid :=
    P12_update_module_params_requires_valid_config s s' moduleId
      stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee
      maxDepositsPerBlock minDepositBlockDistance h
  unfold updateModuleParamsTransition at h
  split at h
  · cases h
  · simp [hValid] at h
    cases h
    simp

private theorem update_module_status_length
    (modules : List Module) (moduleId : ModuleId) (status : ModuleStatus) :
    (updateModuleStatusInModules moduleId status modules).length =
      modules.length := by
  induction modules with
  | nil =>
      simp [updateModuleStatusInModules]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [updateModuleStatusInModules, hId, ih]
      · simp [updateModuleStatusInModules, hId, ih]

private theorem update_module_status_balances
    (modules : List Module) (moduleId : ModuleId) (status : ModuleStatus) :
    (updateModuleStatusInModules moduleId status modules).map
        Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules with
  | nil =>
      simp [updateModuleStatusInModules]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [updateModuleStatusInModules, hId, ih]
      · simp [updateModuleStatusInModules, hId, ih]

private theorem update_module_status_find_records
    (modules : List Module) (moduleId : ModuleId) (status : ModuleStatus)
    (m : Module)
    (hFind : modules.find? (fun candidate => candidate.id = moduleId) = some m) :
    ∃ m',
      (updateModuleStatusInModules moduleId status modules).find?
          (fun candidate => candidate.id = moduleId) = some m' ∧
        m'.status = status := by
  induction modules with
  | nil =>
      simp at hFind
  | cons head tail ih =>
      by_cases hHead : head.id = moduleId
      · simp [updateModuleStatusInModules, hHead]
      · simp [updateModuleStatusInModules, hHead] at hFind ⊢
        exact ih hFind

theorem P13_update_module_status_requires_existing_module
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    ∃ m, s.modules.find? (fun candidate => candidate.id = moduleId) = some m := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m hFind
    exact ⟨m, hFind⟩

theorem P13_update_module_status_requires_status_change
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    ∃ m,
      s.modules.find? (fun candidate => candidate.id = moduleId) = some m ∧
        m.status ≠ status := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hSame : m.status = status
    · simp [hSame] at h
    · exact ⟨m, hFind, hSame⟩

theorem P13_update_module_status_records_requested_status
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    ∃ m',
      s'.modules.find? (fun candidate => candidate.id = moduleId) = some m' ∧
        m'.status = status := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hSame : m.status = status
    · simp [hSame] at h
    · simp [hSame] at h
      cases h
      exact update_module_status_find_records s.modules moduleId status m hFind

theorem P13_update_module_status_preserves_module_length
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    s'.modules.length = s.modules.length := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m _hFind
    by_cases hSame : m.status = status
    · simp [hSame] at h
    · simp [hSame] at h
      cases h
      exact update_module_status_length s.modules moduleId status

theorem P13_update_module_status_preserves_module_balance_sum
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m _hFind
    by_cases hSame : m.status = status
    · simp [hSame] at h
    · simp [hSame] at h
      cases h
      unfold moduleBalanceSum
      rw [update_module_status_balances s.modules moduleId status]

theorem P13_update_module_status_preserves_router_state
    (s s' : State) (moduleId : ModuleId) (status : ModuleStatus)
    (h : updateModuleStatusTransition s moduleId status = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  unfold updateModuleStatusTransition at h
  split at h
  · cases h
  · rename_i m _hFind
    by_cases hSame : m.status = status
    · simp [hSame] at h
    · simp [hSame] at h
      cases h
      simp

theorem P14_add_module_requires_valid_config
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    addModuleConfigValid s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance = true := by
  unfold addModuleTransition at h
  by_cases hValid :
      addModuleConfigValid s.modules moduleId stakeShareLimit
        priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
        minDepositBlockDistance = true
  · simp [hValid] at h
    exact hValid
  · simp [hValid] at h

theorem P14_add_module_requires_fresh_module_id
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    moduleExists s.modules moduleId = false := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleConfigValid at hValid
  simp at hValid
  exact hValid.left

theorem P14_add_module_preserves_config_guards
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    singleModuleParamsValid s.modules moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance = true := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleConfigValid at hValid
  simp at hValid
  exact hValid.right

theorem P14_add_module_increments_module_length
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    s'.modules.length = s.modules.length + 1 := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleTransition at h
  simp [hValid] at h
  cases h
  simp [newModuleFromConfig]

theorem P14_add_module_appends_new_module_from_config
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    s'.modules =
      s.modules ++
        [newModuleFromConfig moduleId stakeShareLimit priorityExitShareThreshold
          moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
          supportsTopUp rewardRecipient] := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleTransition at h
  simp [hValid] at h
  cases h
  rfl

theorem P14_add_module_new_module_zero_accounting
    (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address) :
    let m :=
      newModuleFromConfig moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient
    m.status = ModuleStatus.active ∧
      m.depositableValidators = 0 ∧
      m.lastDepositWei = 0 ∧
      m.depositedValidatorsCount = 0 ∧
      m.exitedValidatorsCount = 0 ∧
      m.validatorsBalanceGwei = 0 ∧
      m.totalModuleStakeWei = 0 := by
  simp [newModuleFromConfig]

private theorem sum_append_zero (xs : List Nat) :
    (xs ++ [0]).sum = xs.sum := by
  induction xs with
  | nil =>
      simp
  | cons x xs ih =>
      simp [ih]

theorem P14_add_module_preserves_module_balance_sum
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleTransition at h
  simp [hValid] at h
  cases h
  simpa [moduleBalanceSum, newModuleFromConfig] using
    sum_append_zero (s.modules.map (fun m => m.validatorsBalanceGwei))

theorem P14_add_module_preserves_router_state
    (s s' : State) (moduleId : ModuleId)
    (stakeShareLimit priorityExitShareThreshold moduleFee treasuryFee : Bps)
    (maxDepositsPerBlock minDepositBlockDistance : Nat)
    (supportsTopUp : Bool) (rewardRecipient : Address)
    (h :
      addModuleTransition s moduleId stakeShareLimit priorityExitShareThreshold
        moduleFee treasuryFee maxDepositsPerBlock minDepositBlockDistance
        supportsTopUp rewardRecipient = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  have hValid :=
    P14_add_module_requires_valid_config s s' moduleId stakeShareLimit
      priorityExitShareThreshold moduleFee treasuryFee maxDepositsPerBlock
      minDepositBlockDistance supportsTopUp rewardRecipient h
  unfold addModuleTransition at h
  simp [hValid] at h
  cases h
  simp

theorem P3_module_balance_conservation
    (s : State) (r : List (ModuleId × Gwei))
    (hLen : r.length = s.modules.length) :
    let s' := acceptReport s r
    s'.routerBalanceGwei = moduleBalanceSum s'.modules := by
  simp [acceptReport, report_sum_matches_zipWith s.modules r hLen]

theorem P3_report_transition_requires_well_formed
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    reportWellFormed s r := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · rename_i hLen
    split at h
    · rename_i hIds
      split at h
      · rename_i hRange
        exact ⟨hLen, hIds, hRange⟩
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_module_balance_conservation
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.routerBalanceGwei = moduleBalanceSum s'.modules := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · rename_i hLen
    split at h
    · split at h
      · cases h
        exact P3_module_balance_conservation s r hLen
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_module_balances_match_report
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.modules.map Module.validatorsBalanceGwei = reportBalances r := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · rename_i hLen
    split at h
    · split at h
      · cases h
        exact (report_balances_match_zipWith s.modules r hLen).symm
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_records_accepted_report
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.lastAcceptedReport = some r := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · split at h
    · split at h
      · cases h
        simp [acceptReport]
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_preserves_module_length
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.modules.length = s.modules.length := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · rename_i hLen
    split at h
    · split at h
      · cases h
        simp [acceptReport, applyReportToModules, hLen]
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_modules_exact
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.modules = applyReportToModules s.modules r := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · split at h
    · split at h
      · cases h
        rfl
      · cases h
    · cases h
  · cases h

theorem P3_report_transition_preserves_eth_state
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · split at h
    · split at h
      · cases h
        simp [acceptReport]
      · cases h
    · cases h
  · cases h

theorem P4_report_before_reward_consistency
    (s : State) (r : List (ModuleId × Gwei))
    (hLen : r.length = s.modules.length) :
    rewardsUseAcceptedReport (acceptReport s r) := by
  refine ⟨r, ?_, ?_⟩
  · simp [acceptReport]
  · simp [acceptReport, report_balances_match_zipWith s.modules r hLen]

theorem P4_report_transition_before_reward_consistency
    (s s' : State) (r : List (ModuleId × Gwei))
    (h : reportValidatorBalancesTransition s r = some s') :
    rewardsUseAcceptedReport s' := by
  unfold reportValidatorBalancesTransition at h
  split at h
  · rename_i hLen
    split at h
    · split at h
      · cases h
        exact P4_report_before_reward_consistency s r hLen
      · cases h
    · cases h
  · cases h

private theorem update_exited_count_rows_valid
    (modules finalModules : List Module)
    (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedCountInModules modules rows = some (finalModules, newlyExited)) :
    exitedCountUpdateRowsValid modules rows := by
  induction rows generalizing modules finalModules newlyExited with
  | nil =>
      simp [exitedCountUpdateRowsValid]
  | cons row rows ih =>
      cases row with
      | mk moduleId newExited =>
          unfold updateExitedCountInModules at h
          split at h
          · cases h
          · rename_i m hFind
            by_cases hMono : m.exitedValidatorsCount ≤ newExited
            · simp [hMono] at h
              by_cases hBound : newExited ≤ m.depositedValidatorsCount
              · simp [hBound] at h
                cases hLoop :
                    updateExitedCountInModules
                      (recordModuleExitedCount moduleId newExited modules) rows with
                | none =>
                    simp [hLoop] at h
                | some loopResult =>
                    rcases loopResult with ⟨laterModules, laterDelta⟩
                    simp [hLoop] at h
                    cases h
                    exact
                      ⟨m, hFind, hMono, hBound,
                        ih
                          (recordModuleExitedCount moduleId newExited modules)
                          laterModules laterDelta hLoop⟩
              · simp [hBound] at h
            · simp [hMono] at h

private theorem update_exited_count_length
    (modules finalModules : List Module)
    (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedCountInModules modules rows = some (finalModules, newlyExited)) :
    finalModules.length = modules.length := by
  induction rows generalizing modules finalModules newlyExited with
  | nil =>
      simp [updateExitedCountInModules] at h
      rcases h with ⟨hModules, _hDelta⟩
      cases hModules
      rfl
  | cons row rows ih =>
      cases row with
      | mk moduleId newExited =>
          unfold updateExitedCountInModules at h
          split at h
          · cases h
          · rename_i m hFind
            by_cases hMono : m.exitedValidatorsCount ≤ newExited
            · simp [hMono] at h
              by_cases hBound : newExited ≤ m.depositedValidatorsCount
              · simp [hBound] at h
                cases hLoop :
                    updateExitedCountInModules
                      (recordModuleExitedCount moduleId newExited modules) rows with
                | none =>
                    simp [hLoop] at h
                | some loopResult =>
                    rcases loopResult with ⟨laterModules, laterDelta⟩
                    simp [hLoop] at h
                    rcases h with ⟨hModules, _hDelta⟩
                    have hLaterLength :
                        laterModules.length =
                          (recordModuleExitedCount moduleId newExited modules).length :=
                      ih
                        (recordModuleExitedCount moduleId newExited modules)
                        laterModules laterDelta hLoop
                    cases hModules
                    rw [hLaterLength]
                    exact updateModuleById_length moduleId
                      (fun m => { m with exitedValidatorsCount := newExited })
                      modules
              · simp [hBound] at h
            · simp [hMono] at h

private theorem record_exited_count_preserves_balances
    (modules : List Module) (moduleId : ModuleId) (newExited : ValidatorsCount) :
    (recordModuleExitedCount moduleId newExited modules).map
        Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction modules with
  | nil =>
      simp [recordModuleExitedCount, updateModuleById]
  | cons m ms ih =>
      by_cases hId : m.id = moduleId
      · simp [recordModuleExitedCount, updateModuleById, hId]
        simpa [recordModuleExitedCount] using ih
      · simp [recordModuleExitedCount, updateModuleById, hId]
        simpa [recordModuleExitedCount] using ih

private theorem update_exited_count_preserves_balances
    (modules finalModules : List Module)
    (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedCountInModules modules rows = some (finalModules, newlyExited)) :
    finalModules.map Module.validatorsBalanceGwei =
      modules.map Module.validatorsBalanceGwei := by
  induction rows generalizing modules finalModules newlyExited with
  | nil =>
      simp [updateExitedCountInModules] at h
      rcases h with ⟨hModules, _hDelta⟩
      cases hModules
      rfl
  | cons row rows ih =>
      cases row with
      | mk moduleId newExited =>
          unfold updateExitedCountInModules at h
          split at h
          · cases h
          · rename_i m hFind
            by_cases hMono : m.exitedValidatorsCount ≤ newExited
            · simp [hMono] at h
              by_cases hBound : newExited ≤ m.depositedValidatorsCount
              · simp [hBound] at h
                cases hLoop :
                    updateExitedCountInModules
                      (recordModuleExitedCount moduleId newExited modules) rows with
                | none =>
                    simp [hLoop] at h
                | some loopResult =>
                    rcases loopResult with ⟨laterModules, laterDelta⟩
                    simp [hLoop] at h
                    rcases h with ⟨hModules, _hDelta⟩
                    have hLaterBalances :
                        laterModules.map Module.validatorsBalanceGwei =
                          (recordModuleExitedCount moduleId newExited modules).map
                            Module.validatorsBalanceGwei :=
                      ih
                        (recordModuleExitedCount moduleId newExited modules)
                        laterModules laterDelta hLoop
                    cases hModules
                    rw [hLaterBalances]
                    exact record_exited_count_preserves_balances modules moduleId
                      newExited
              · simp [hBound] at h
            · simp [hMono] at h

theorem P7_exited_count_update_requires_valid_rows
    (s s' : State) (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedValidatorsTransition s rows = some (s', newlyExited)) :
    exitedCountUpdateRowsValid s.modules rows := by
  unfold updateExitedValidatorsTransition at h
  cases hLoop : updateExitedCountInModules s.modules rows with
  | none =>
      simp [hLoop] at h
  | some loopResult =>
      rcases loopResult with ⟨finalModules, loopDelta⟩
      simp [hLoop] at h
      cases h
      exact update_exited_count_rows_valid s.modules finalModules rows loopDelta hLoop

theorem P7_exited_count_update_returns_loop_result
    (s s' : State) (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedValidatorsTransition s rows = some (s', newlyExited)) :
    updateExitedCountInModules s.modules rows =
      some (s'.modules, newlyExited) := by
  unfold updateExitedValidatorsTransition at h
  cases hLoop : updateExitedCountInModules s.modules rows with
  | none =>
      simp [hLoop] at h
  | some loopResult =>
      rcases loopResult with ⟨finalModules, loopDelta⟩
      simp [hLoop] at h
      rcases h with ⟨hState, hDelta⟩
      cases hState
      cases hDelta
      simp

theorem P7_exited_count_update_empty
    (s : State) :
    updateExitedValidatorsTransition s [] = some (s, 0) := by
  rfl

theorem P7_exited_count_update_preserves_module_length
    (s s' : State) (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedValidatorsTransition s rows = some (s', newlyExited)) :
    s'.modules.length = s.modules.length := by
  unfold updateExitedValidatorsTransition at h
  cases hLoop : updateExitedCountInModules s.modules rows with
  | none =>
      simp [hLoop] at h
  | some loopResult =>
      rcases loopResult with ⟨finalModules, loopDelta⟩
      simp [hLoop] at h
      rcases h with ⟨hState, _hDelta⟩
      cases hState
      exact update_exited_count_length s.modules finalModules rows loopDelta hLoop

theorem P7_exited_count_update_preserves_module_balance_sum
    (s s' : State) (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedValidatorsTransition s rows = some (s', newlyExited)) :
    moduleBalanceSum s'.modules = moduleBalanceSum s.modules := by
  unfold updateExitedValidatorsTransition at h
  cases hLoop : updateExitedCountInModules s.modules rows with
  | none =>
      simp [hLoop] at h
  | some loopResult =>
      rcases loopResult with ⟨finalModules, loopDelta⟩
      simp [hLoop] at h
      rcases h with ⟨hState, _hDelta⟩
      cases hState
      unfold moduleBalanceSum
      rw [update_exited_count_preserves_balances s.modules finalModules rows
        loopDelta hLoop]

theorem P7_exited_count_update_preserves_router_state
    (s s' : State) (rows : List (ModuleId × ValidatorsCount))
    (newlyExited : ValidatorsCount)
    (h : updateExitedValidatorsTransition s rows = some (s', newlyExited)) :
    s'.bufferedEther = s.bufferedEther ∧
      s'.depositReserve = s.depositReserve ∧
      s'.withdrawalReserve = s.withdrawalReserve ∧
      s'.routerEthBalanceWei = s.routerEthBalanceWei ∧
      s'.beaconDepositSinkWei = s.beaconDepositSinkWei ∧
      s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  unfold updateExitedValidatorsTransition at h
  cases hLoop : updateExitedCountInModules s.modules rows with
  | none =>
      simp [hLoop] at h
  | some loopResult =>
      rcases loopResult with ⟨finalModules, loopDelta⟩
      simp [hLoop] at h
      rcases h with ⟨hState, _hDelta⟩
      cases hState
      simp

theorem P8_topup_transition_requires_active_topup_module
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    ∃ m,
      s.modules.find? (fun candidate => candidate.id = stakingModuleId) = some m ∧
        m.status = ModuleStatus.active ∧
        m.supportsTopUp = true := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · exact ⟨m, hFind, hActive, hTopUp⟩
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_requires_input_shape
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    keyCount ≠ 0 ∧
      nodeOperatorCount = keyCount ∧
        topUpLimits.length = keyCount ∧
          pubkeyCount = keyCount := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · exact ⟨hKey, hOperators, hLimits, hPubkeys⟩
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_requires_well_formed_allocations
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    topUpAllocationsWellFormed allocations topUpLimits
      (topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei) := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · exact
                          ⟨hAllocations.trans hLimits.symm, hAligned, hWithin, hAmount⟩
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

private theorem topUpTargetWei_le_module_allocation
    (moduleAllocationWei : Wei) (maxTopUpPerBlockGwei : Gwei) :
    topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei ≤ moduleAllocationWei :=
  Nat.le_trans (roundDownToGwei_le _) (Nat.min_le_left _ _)

private theorem topUpTargetWei_le_per_block_cap
    (moduleAllocationWei : Wei) (maxTopUpPerBlockGwei : Gwei) :
    topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei ≤
      maxTopUpPerBlockWei maxTopUpPerBlockGwei :=
  Nat.le_trans (roundDownToGwei_le _) (Nat.min_le_right _ _)

theorem P8_topup_transition_allocation_sum_bounded_by_module_allocation
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    allocations.sum ≤ moduleAllocationWei := by
  have hWellFormed :=
    P8_topup_transition_requires_well_formed_allocations s s'
      stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei lidoCanDeposit
      keyCount nodeOperatorCount pubkeyCount topUpLimits allocations h
  rcases hWellFormed with ⟨_hLength, _hAligned, _hWithin, hTarget⟩
  exact Nat.le_trans hTarget
    (topUpTargetWei_le_module_allocation moduleAllocationWei maxTopUpPerBlockGwei)

/--
  New at `af095e48`: the allocation sum is additionally bounded by the
  router-global per-block top-up cap (`maxTopUpPerBlockGwei`, PR #1820).
-/
theorem P8_topup_transition_respects_per_block_cap
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    allocations.sum ≤ maxTopUpPerBlockWei maxTopUpPerBlockGwei := by
  have hWellFormed :=
    P8_topup_transition_requires_well_formed_allocations s s'
      stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei lidoCanDeposit
      keyCount nodeOperatorCount pubkeyCount topUpLimits allocations h
  rcases hWellFormed with ⟨_hLength, _hAligned, _hWithin, hTarget⟩
  exact Nat.le_trans hTarget
    (topUpTargetWei_le_per_block_cap moduleAllocationWei maxTopUpPerBlockGwei)

/--
  New at `af095e48`: a successful zero-target top-up (queue-advancement no-op)
  requires the Lido protocol deposit gate `LIDO.canDeposit()` to be open;
  otherwise the router reverts with `LidoDepositsPaused`.
-/
theorem P8_topup_transition_zero_target_requires_lido_can_deposit
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hZeroTarget : topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei = 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    lidoCanDeposit = true := by
  by_cases hCan : lidoCanDeposit = false
  · unfold topUpTransition at h
    split at h
    · cases h
    · rename_i m hFind
      by_cases hActive : m.status = ModuleStatus.active
      · simp [hActive] at h
        by_cases hTopUp : m.supportsTopUp = true
        · simp [hTopUp] at h
          by_cases hKey : keyCount = 0
          · simp [hKey] at h
          · simp [hKey] at h
            by_cases hOperators : nodeOperatorCount = keyCount
            · simp [hOperators] at h
              by_cases hLimits : topUpLimits.length = keyCount
              · simp [hLimits] at h
                by_cases hPubkeys : pubkeyCount = keyCount
                · simp [hPubkeys] at h
                  by_cases hAllocations : allocations.length = keyCount
                  · simp [hAllocations, hZeroTarget, hCan] at h
                  · simp [hAllocations] at h
                · simp [hPubkeys] at h
              · simp [hLimits] at h
            · simp [hOperators] at h
        · simp [hTopUp] at h
      · simp [hActive] at h
  · simpa using hCan

theorem P8_topup_transition_router_eth_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.routerEthBalanceWei = s.routerEthBalanceWei := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · simp [hZero] at h
                          simpa using congrArg State.routerEthBalanceWei h.symm
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            simpa using congrArg State.routerEthBalanceWei h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_modules_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.modules = s.modules := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · simp [hZero] at h
                          simpa using congrArg State.modules h.symm
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            simpa using congrArg State.modules h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_preserves_report_state
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.routerBalanceGwei = s.routerBalanceGwei ∧
      s'.lastAcceptedReport = s.lastAcceptedReport := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · simp [hZero] at h
                          constructor
                          · simpa using congrArg State.routerBalanceGwei h.symm
                          · simpa using congrArg State.lastAcceptedReport h.symm
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            constructor
                            · simpa using congrArg State.routerBalanceGwei h.symm
                            · simpa using congrArg State.lastAcceptedReport h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_beacon_sink_exact
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hNonzero : allocations.sum ≠ 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.beaconDepositSinkWei = s.beaconDepositSinkWei + allocations.sum := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · contradiction
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            exact congrArg State.beaconDepositSinkWei h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_buffered_exact
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hNonzero : allocations.sum ≠ 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.bufferedEther = s.bufferedEther - allocations.sum := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · contradiction
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            exact congrArg State.bufferedEther h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_positive_requires_depositable
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hNonzero : allocations.sum ≠ 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    allocations.sum ≤ depositableEther s := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · contradiction
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · exact hAllowed
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_zero_sum_noop
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hZeroSum : allocations.sum = 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s' = s := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hZeroSum] at h
                        exact h.symm
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_withdrawal_reserve_unchanged
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.withdrawalReserve = s.withdrawalReserve := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · simp [hZero] at h
                          simpa using congrArg State.withdrawalReserve h.symm
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            simpa using congrArg State.withdrawalReserve h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

theorem P8_topup_transition_deposit_reserve_spent
    (s s' : State) (stakingModuleId : ModuleId) (moduleAllocationWei : Wei)
    (maxTopUpPerBlockGwei : Gwei) (lidoCanDeposit : Bool)
    (keyCount nodeOperatorCount pubkeyCount : Nat)
    (topUpLimits allocations : List Wei)
    (hNonzero : allocations.sum ≠ 0)
    (h :
      topUpTransition s stakingModuleId moduleAllocationWei maxTopUpPerBlockGwei
        lidoCanDeposit keyCount nodeOperatorCount pubkeyCount topUpLimits
        allocations = some s') :
    s'.depositReserve = s.depositReserve - allocations.sum := by
  unfold topUpTransition at h
  split at h
  · cases h
  · rename_i m hFind
    by_cases hActive : m.status = ModuleStatus.active
    · simp [hActive] at h
      by_cases hTopUp : m.supportsTopUp = true
      · simp [hTopUp] at h
        by_cases hKey : keyCount = 0
        · simp [hKey] at h
        · simp [hKey] at h
          by_cases hOperators : nodeOperatorCount = keyCount
          · simp [hOperators] at h
            by_cases hLimits : topUpLimits.length = keyCount
            · simp [hLimits] at h
              by_cases hPubkeys : pubkeyCount = keyCount
              · simp [hPubkeys] at h
                by_cases hAllocations : allocations.length = keyCount
                · simp [hAllocations] at h
                  obtain ⟨_hGate, h⟩ := h
                  by_cases hAligned : allocationsGweiAligned allocations = true
                  · simp [hAligned] at h
                    by_cases hWithin : allocationsWithinLimits allocations topUpLimits = true
                    · simp [hWithin] at h
                      by_cases hAmount :
                          allocations.sum ≤ topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei
                      · simp [hAmount] at h
                        by_cases hZero : allocations.sum = 0
                        · contradiction
                        · simp [hZero] at h
                          by_cases hAllowed : allocations.sum ≤ depositableEther s
                          · simp [hAllowed] at h
                            exact congrArg State.depositReserve h.symm
                          · simp [hAllowed] at h
                      · simp [hAmount] at h
                    · simp [hWithin] at h
                  · simp [hAligned] at h
                · simp [hAllocations] at h
              · simp [hPubkeys] at h
            · simp [hLimits] at h
          · simp [hOperators] at h
      · simp [hTopUp] at h
    · simp [hActive] at h

private theorem reward_loop_rows_aligned
    (totalValidatorsBalanceGwei : Gwei) (modules : List Module)
    (row : RewardDistributionRow)
    (h : row ∈ rewardDistributionLoop totalValidatorsBalanceGwei modules) :
    ∃ m ∈ modules,
      m.validatorsBalanceGwei ≠ 0 ∧
        row = rewardDistributionRow totalValidatorsBalanceGwei m := by
  induction modules with
  | nil =>
      simp [rewardDistributionLoop] at h
  | cons m ms ih =>
      unfold rewardDistributionLoop at h
      by_cases hZero : m.validatorsBalanceGwei = 0
      · simp [hZero] at h
        rcases ih h with ⟨m', hm', hNonzero, hrow⟩
        exact ⟨m', by simp [hm'], hNonzero, hrow⟩
      · simp [hZero] at h
        rcases h with hrow | htail
        · exact ⟨m, by simp, hZero, hrow⟩
        · rcases ih htail with ⟨m', hm', hNonzero, hrow⟩
          exact ⟨m', by simp [hm'], hNonzero, hrow⟩

private theorem reward_distribution_row_paid_bound
    (totalValidatorsBalanceGwei : Gwei) (m : Module) :
    (rewardDistributionRow totalValidatorsBalanceGwei m).paidModuleFee ≤
      (rewardDistributionRow totalValidatorsBalanceGwei m).moduleFee := by
  unfold rewardDistributionRow
  by_cases hStopped : m.status = ModuleStatus.stopped
  · simp [hStopped]
  · simp [hStopped]

theorem P5_rewards_distribution_rows_aligned
    (modules : List Module) (row : RewardDistributionRow)
    (h : row ∈ stakingRewardsDistributionRows modules) :
    ∃ m ∈ modules,
      m.validatorsBalanceGwei ≠ 0 ∧
        row = rewardDistributionRow (moduleBalanceSum modules) m := by
  unfold stakingRewardsDistributionRows at h
  by_cases hTotal : moduleBalanceSum modules = 0
  · simp [hTotal] at h
  · simp [hTotal] at h
    exact reward_loop_rows_aligned (moduleBalanceSum modules) modules row h

theorem P5_rewards_distribution_zero_total_empty
    (modules : List Module)
    (hTotal : moduleBalanceSum modules = 0) :
    stakingRewardsDistributionRows modules = [] := by
  simp [stakingRewardsDistributionRows, hTotal]

theorem P5_rewards_distribution_zero_total_empty_module_ids
    (modules : List Module)
    (hTotal : moduleBalanceSum modules = 0) :
    (stakingRewardsDistributionRows modules).map RewardDistributionRow.moduleId = [] := by
  simp [stakingRewardsDistributionRows, hTotal]

theorem P5_rewards_distribution_row_nonzero_balance
    (modules : List Module) (row : RewardDistributionRow)
    (h : row ∈ stakingRewardsDistributionRows modules) :
    row.validatorsBalanceGwei ≠ 0 := by
  rcases P5_rewards_distribution_rows_aligned modules row h with
    ⟨m, _hm, hNonzero, hrow⟩
  cases hrow
  simpa [rewardDistributionRow] using hNonzero

theorem P5_rewards_distribution_paid_module_fee_bound
    (modules : List Module) (row : RewardDistributionRow)
    (h : row ∈ stakingRewardsDistributionRows modules) :
    row.paidModuleFee ≤ row.moduleFee := by
  rcases P5_rewards_distribution_rows_aligned modules row h with
    ⟨m, _hm, _hNonzero, hrow⟩
  cases hrow
  exact reward_distribution_row_paid_bound (moduleBalanceSum modules) m

theorem P5_rewards_distribution_stopped_module_zero
    (totalValidatorsBalanceGwei : Gwei) (m : Module)
    (h : m.status = ModuleStatus.stopped) :
    (rewardDistributionRow totalValidatorsBalanceGwei m).paidModuleFee = 0 := by
  simp [rewardDistributionRow, h]

theorem P5_rewards_distribution_total_fee_sum
    (rows : List RewardDistributionRow) :
    rewardDistributionTotalFee rows =
      (rows.map (fun row => row.moduleFee + row.treasuryFee)).sum := by
  rfl

private theorem module_exists_true_exists
    (modules : List Module) (moduleId : ModuleId)
    (h : moduleExists modules moduleId = true) :
    ∃ m, modules.find? (fun candidate => candidate.id = moduleId) = some m := by
  unfold moduleExists at h
  cases hFind : modules.find? (fun candidate => candidate.id = moduleId) with
  | none =>
      simp [hFind] at h
  | some m =>
      exact ⟨m, rfl⟩

private theorem reward_minted_valid_nonzero_module_exists_bool
    (modules : List Module) (rows : List RewardMintedReportRow)
    (row : RewardMintedReportRow)
    (hValid : rewardMintedRowsValid modules rows = true)
    (hMem : row ∈ rows)
    (hNonzero : row.totalShares ≠ 0) :
    moduleExists modules row.moduleId = true := by
  induction rows generalizing row with
  | nil =>
      simp at hMem
  | cons head tail ih =>
      unfold rewardMintedRowsValid at hValid
      by_cases hZero : head.totalShares = 0
      · simp [hZero] at hValid
        have hMem' : row = head ∨ row ∈ tail := by
          simpa using hMem
        rcases hMem' with hEq | hTail
        · cases hEq
          contradiction
        · exact ih row hValid hTail hNonzero
      · simp [hZero] at hValid
        rcases hValid with ⟨hHeadExists, hTailValid⟩
        have hMem' : row = head ∨ row ∈ tail := by
          simpa using hMem
        rcases hMem' with hEq | hTail
        · cases hEq
          exact hHeadExists
        · exact ih row hTailValid hTail hNonzero

private theorem reward_minted_valid_nonzero_module_exists
    (modules : List Module) (rows : List RewardMintedReportRow)
    (row : RewardMintedReportRow)
    (hValid : rewardMintedRowsValid modules rows = true)
    (hMem : row ∈ rows)
    (hNonzero : row.totalShares ≠ 0) :
    ∃ m, modules.find? (fun candidate => candidate.id = row.moduleId) = some m := by
  exact module_exists_true_exists modules row.moduleId
    (reward_minted_valid_nonzero_module_exists_bool
      modules rows row hValid hMem hNonzero)

private theorem reward_minted_rows_module_ids
    (stakingModuleIds totalShares : List Nat)
    (hLen : totalShares.length = stakingModuleIds.length) :
    (rewardMintedReportRows stakingModuleIds totalShares).map
        RewardMintedReportRow.moduleId =
      stakingModuleIds := by
  induction stakingModuleIds generalizing totalShares with
  | nil =>
      cases totalShares with
      | nil => simp [rewardMintedReportRows]
      | cons share shares => simp at hLen
  | cons moduleId moduleIds ih =>
      cases totalShares with
      | nil => simp at hLen
      | cons share shares =>
          have hTail : shares.length = moduleIds.length := by
            exact Nat.succ.inj hLen
          simp [rewardMintedReportRows]
          simpa [rewardMintedReportRows] using ih shares hTail

private theorem reward_minted_rows_total_shares
    (stakingModuleIds totalShares : List Nat)
    (hLen : totalShares.length = stakingModuleIds.length) :
    (rewardMintedReportRows stakingModuleIds totalShares).map
        RewardMintedReportRow.totalShares =
      totalShares := by
  induction stakingModuleIds generalizing totalShares with
  | nil =>
      cases totalShares with
      | nil => simp [rewardMintedReportRows]
      | cons share shares => simp at hLen
  | cons moduleId moduleIds ih =>
      cases totalShares with
      | nil => simp at hLen
      | cons share shares =>
          have hTail : shares.length = moduleIds.length := by
            exact Nat.succ.inj hLen
          simp [rewardMintedReportRows]
          simpa [rewardMintedReportRows] using ih shares hTail

theorem P10_report_rewards_minted_requires_equal_lengths
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    totalShares.length = stakingModuleIds.length := by
  unfold reportRewardsMintedTransition at h
  split at h
  · assumption
  · cases h

theorem P10_report_rewards_minted_requires_valid_rows
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    rewardMintedRowsValid s.modules rows = true := by
  unfold reportRewardsMintedTransition at h
  split at h
  · rename_i hLen
    let generatedRows := rewardMintedReportRows stakingModuleIds totalShares
    by_cases hValid : rewardMintedRowsValid s.modules generatedRows = true
    · simp [generatedRows, hValid] at h
      cases h
      exact hValid
    · simp [generatedRows, hValid] at h
  · cases h

theorem P10_report_rewards_minted_returns_generated_rows
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    rows = rewardMintedReportRows stakingModuleIds totalShares := by
  unfold reportRewardsMintedTransition at h
  split at h
  · let generatedRows := rewardMintedReportRows stakingModuleIds totalShares
    by_cases hValid : rewardMintedRowsValid s.modules generatedRows = true
    · simp [generatedRows, hValid] at h
      cases h
      rfl
    · simp [generatedRows, hValid] at h
  · cases h

theorem P10_report_rewards_minted_preserves_row_length
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    rows.length = stakingModuleIds.length := by
  have hRows :=
    P10_report_rewards_minted_returns_generated_rows
      s stakingModuleIds totalShares rows h
  have hLen :=
    P10_report_rewards_minted_requires_equal_lengths
      s stakingModuleIds totalShares rows h
  rw [hRows]
  simp [rewardMintedReportRows, hLen]

theorem P10_report_rewards_minted_preserves_module_ids
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    rows.map RewardMintedReportRow.moduleId = stakingModuleIds := by
  have hRows :=
    P10_report_rewards_minted_returns_generated_rows
      s stakingModuleIds totalShares rows h
  have hLen :=
    P10_report_rewards_minted_requires_equal_lengths
      s stakingModuleIds totalShares rows h
  rw [hRows]
  exact reward_minted_rows_module_ids stakingModuleIds totalShares hLen

theorem P10_report_rewards_minted_preserves_total_shares
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows) :
    rows.map RewardMintedReportRow.totalShares = totalShares := by
  have hRows :=
    P10_report_rewards_minted_returns_generated_rows
      s stakingModuleIds totalShares rows h
  have hLen :=
    P10_report_rewards_minted_requires_equal_lengths
      s stakingModuleIds totalShares rows h
  rw [hRows]
  exact reward_minted_rows_total_shares stakingModuleIds totalShares hLen

theorem P10_report_rewards_minted_nonzero_module_exists
    (s : State) (stakingModuleIds totalShares : List Nat)
    (rows : List RewardMintedReportRow) (row : RewardMintedReportRow)
    (h :
      reportRewardsMintedTransition s stakingModuleIds totalShares = some rows)
    (hMem : row ∈ rows)
    (hNonzero : row.totalShares ≠ 0) :
    ∃ m, s.modules.find? (fun candidate => candidate.id = row.moduleId) = some m := by
  exact reward_minted_valid_nonzero_module_exists s.modules rows row
    (P10_report_rewards_minted_requires_valid_rows s stakingModuleIds totalShares rows h)
    hMem hNonzero

theorem P10_report_rewards_minted_zero_rows_skip_module_check
    (modules : List Module) (moduleId : ModuleId) :
    rewardMintedRowsValid modules
      [{ moduleId := moduleId, totalShares := 0 }] = true := by
  simp [rewardMintedRowsValid]

private theorem module_balance_le_sum
    (modules : List Module) (m : Module) (h : m ∈ modules) :
    m.validatorsBalanceGwei ≤ moduleBalanceSum modules := by
  induction modules with
  | nil => cases h
  | cons x xs ih =>
      have hcons : moduleBalanceSum (x :: xs) =
          x.validatorsBalanceGwei + moduleBalanceSum xs := by
        simp [moduleBalanceSum]
      rw [hcons]
      rcases List.mem_cons.mp h with heq | hmem
      · subst heq; exact Nat.le_add_right _ _
      · exact Nat.le_trans (ih hmem) (Nat.le_add_left _ _)

private theorem reward_share_le_precision
    (modules : List Module) (m : Module) (h : m ∈ modules)
    (hTotal : moduleBalanceSum modules ≠ 0) :
    rewardShare (moduleBalanceSum modules) m ≤ feePrecisionPoints := by
  unfold rewardShare
  have hle : m.validatorsBalanceGwei ≤ moduleBalanceSum modules :=
    module_balance_le_sum modules m h
  have hpos : 0 < moduleBalanceSum modules := Nat.pos_of_ne_zero hTotal
  calc
    m.validatorsBalanceGwei * feePrecisionPoints / moduleBalanceSum modules
        ≤ moduleBalanceSum modules * feePrecisionPoints / moduleBalanceSum modules :=
          Nat.div_le_div_right (Nat.mul_le_mul hle (Nat.le_refl _))
    _ = feePrecisionPoints := Nat.mul_div_cancel_left feePrecisionPoints hpos

/--
  Reward fee bound (balance-proportional). Each module's computed fee is derived
  from its share of the total validator balance and is bounded by the
  precision-scaled module fee. Requires the module to be one of the rewarded
  modules with a nonzero router total, matching
  `getStakingRewardsDistribution`.
-/
theorem P5_reward_bound
    (modules : List Module) (m : Module)
    (hMem : m ∈ modules) (hTotal : moduleBalanceSum modules ≠ 0) :
    computedModuleFee (moduleBalanceSum modules) m ≤
      feePrecisionPoints * m.moduleFeeBps / bpsDenominator := by
  unfold computedModuleFee
  have hshare := reward_share_le_precision modules m hMem hTotal
  exact Nat.div_le_div_right (Nat.mul_le_mul hshare (Nat.le_refl _))

theorem P5_reward_recipient_alignment
    (modules : List Module) :
    rewardRecipientsAligned modules := by
  intro row hrow
  rcases P5_rewards_distribution_rows_aligned modules row hrow with
    ⟨m, hm, _hNonzero, hrowEq⟩
  refine ⟨m, hm, ?_⟩
  cases hrowEq
  simp [rewardDistributionRow]

theorem P6_deposit_status_gating
    (m : Module) (allocated : Nat)
    (h : m.status ≠ ModuleStatus.active) :
    allocatedDeposits m allocated = 0 := by
  simp [allocatedDeposits, h]

/--
  Stopped modules are paid zero module-side fee even though the balance-share
  computation still produces a `moduleFee` figure for the treasury accumulator.
-/
theorem P6_stopped_module_reward_zero
    (totalValidatorsBalanceGwei : Gwei) (m : Module)
    (h : m.status = ModuleStatus.stopped) :
    (rewardDistributionRow totalValidatorsBalanceGwei m).paidModuleFee = 0 := by
  simp [rewardDistributionRow, h]

end LidoSRv3
