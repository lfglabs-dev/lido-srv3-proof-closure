import LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall

/-!
# P-TOPUP-2 validator pre-checks before the module reply

The registered admission chain `TopupRouterAdmissionCall.run` (displayed on
P-TOPUP-2 as `actual_topup_admission_calls_wei_and_revert`) reaches the module
CALL only through the seam `Ready`. This module proves that the seam is
reachable only with a `0x02` withdrawal credential returned by the physical
credential getter (`TopUpGateway.sol:200-203`, `wc[0] == 0x02`) and with
48-byte pubkeys in every witness row (`CLValidatorVerifier.sol` /
`TopUpGateway.sol:212`, `_verifyValidator`), and that any other shape is
rejected at that stage: the outcome is the stage's error, the returned world
is the entry world and no module reply is executed (`ready = none`).

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The block-distance and root-recency gates precede these checks
(`TopupTimingHistory.gates`); they are premises of the same-block bound in
`PTopup2SameBlock` and are not restated here.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PTopup2ValidatorChecks
open Source Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch
open Source.TopupRouterAdmissionCall (Input Ready)

private theorem map_ok {ε α β : Type} {f : α → β} {x : Except ε α} {y : β}
    (h : Except.map f x = .ok y) : ∃ a, x = .ok a := by
  cases x with
  | «error» e => simp [Except.map] at h
  | ok a => exact ⟨a, rfl⟩

/-- A successful root loop consumed 48-byte pubkeys only: `rowLimit` refuses
any other length before the ordering, activation and verifier steps. -/
theorem loop_success_pubkeys (e : TopupGatewayRootCalls.Environment) :
    ∀ (rows : List Row) (previous : Option Index) (acc : Nat) (out : Output),
      (TopupGatewayRootCalls.loop e previous acc rows).outcome = .ok out →
      ∀ r ∈ rows, r.witness.pubkey.length = 48
  | [], _, _, _, _, r, hr => by simp at hr
  | r :: rs, previous, acc, out, h, r', hr' => by
    by_cases hk : r.witness.pubkey.length ≠ 48
    · have hhead : (TopupGatewayRootCalls.rowLimit e previous r).outcome = .error .wrongPubkeyLength := by
        simp [TopupGatewayRootCalls.rowLimit, hk]
      simp [TopupGatewayRootCalls.loop, hhead] at h
    · have hk' : r.witness.pubkey.length = 48 := by simpa using hk
      rcases List.mem_cons.mp hr' with hrr | hmem
      · rw [hrr]
        exact hk'
      · unfold TopupGatewayRootCalls.loop at h
        cases hh : (TopupGatewayRootCalls.rowLimit e previous r).outcome with
        | «error» f => simp [hh] at h
        | ok n =>
          simp only [hh] at h
          obtain ⟨out', htail⟩ := map_ok h
          exact loop_success_pubkeys e rs (some r.index) _ out' htail r' hmem

/-- The module-reply seam is reached only with a `0x02` credential word and a
successful root loop over the rows. -/
theorem seam_shapes (g : TopupRouterAdmissionCallGates.Environment) (i : Input) (p : Ready)
    (h : (TopupRouterAdmissionCall.run g i).ready = some p) :
    p.wc.val / 2^248 = 2 ∧
    (TopupGatewayRootCalls.loop
      (TopupBatchRootCalls.environment (TopupCredentialCall.resolved i.gateway p.wc))
      none 0 i.rows).outcome = .ok p.output := by
  unfold TopupRouterAdmissionCall.run TopupRouterAdmissionCall.walk at h
  cases hg : TopupEntryAdmission.gates i.gateway.gateway i.caller i.gateway.before with
  | «error» f => simp [hg] at h
  | ok u =>
    cases u
    simp only [hg] at h
    cases hl : checkLengths (TopupBatchRootCalls.environment i.gateway).cfg i.rows.length
        i.keys.length i.operators.length i.rows.length i.rows.length with
    | «error» f => simp [hl] at h
    | ok u =>
      cases u
      simp only [hl] at h
      cases ht : TopupTimingHistory.gates i.gateway with
      | «error» f => simp [ht] at h
      | ok u =>
        cases u
        simp only [ht] at h
        cases hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator
            i.cursor i.gateway.before).outcome with
        | «error» f => simp [hq] at h
        | ok pair =>
          rcases pair with ⟨router, next⟩
          simp only [hq] at h
          cases hc : (TopupCredentialCall.lookup (TopupPhysicalCredentialGetter.dispatch i.hash)
              i.gateway.gateway router i.moduleId next i.gateway.before).outcome with
          | «error» f => simp [hc] at h
          | ok pair =>
            rcases pair with ⟨wc, x⟩
            simp only [hc] at h
            by_cases hwc : wc.val / 2^248 ≠ 2
            · split at h
              · simp at h
              · rename_i hnot
                exact absurd hwc hnot
            · simp only [if_neg hwc] at h
              cases ho : (TopupGatewayRootCalls.loop
                  (TopupBatchRootCalls.environment (TopupCredentialCall.resolved i.gateway wc))
                  none 0 i.rows).outcome with
              | «error» f => simp [ho] at h
              | ok out =>
                simp only [ho] at h
                unfold TopupRouterAdmissionCall.consume at h
                dsimp only at h
                split at h <;> (try dsimp only at h) <;> cases h <;>
                  exact ⟨by simpa using hwc, ho⟩

/-- Every witness row of a reached seam carries a 48-byte pubkey. -/
theorem seam_pubkeys (g : TopupRouterAdmissionCallGates.Environment) (i : Input) (p : Ready)
    (h : (TopupRouterAdmissionCall.run g i).ready = some p) :
    ∀ r ∈ i.rows, r.witness.pubkey.length = 48 :=
  loop_success_pubkeys _ i.rows none 0 p.output (seam_shapes g i p h).2

/-- A credential word whose first byte is not `0x02` is rejected at the
credential stage: the chain returns `wrongWithdrawalCredentials`, the entry
world, and never reaches the module-reply seam. -/
theorem wrong_credential_type_rejected (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (router : Address) (next wc x : Word)
    (hg : TopupEntryAdmission.gates i.gateway.gateway i.caller i.gateway.before = .ok ())
    (hl : checkLengths (TopupBatchRootCalls.environment i.gateway).cfg i.rows.length
      i.keys.length i.operators.length i.rows.length i.rows.length = .ok ())
    (ht : TopupTimingHistory.gates i.gateway = .ok ())
    (hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
      i.gateway.before).outcome = .ok (router, next))
    (hc : (TopupCredentialCall.lookup (TopupPhysicalCredentialGetter.dispatch i.hash)
      i.gateway.gateway router i.moduleId next i.gateway.before).outcome = .ok (wc, x))
    (hwc : wc.val / 2^248 ≠ 2) :
    (TopupRouterAdmissionCall.run g i).outcome =
      .error (.prior (.phase (.phase (.phase .wrongWithdrawalCredentials)))) ∧
    (TopupRouterAdmissionCall.run g i).world = i.gateway.before ∧
    (TopupRouterAdmissionCall.run g i).ready = none := by
  unfold TopupRouterAdmissionCall.run TopupRouterAdmissionCall.walk
  refine ⟨?_, ?_, ?_⟩ <;> simp only [hg, hl, ht, hq, hc, if_pos hwc]

/-- A witness row whose pubkey is not 48 bytes is rejected by the root loop:
the chain returns a gateway fault, the entry world, and never reaches the
module-reply seam. -/
theorem wrong_pubkey_length_rejected (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (router : Address) (next wc x : Word)
    (hg : TopupEntryAdmission.gates i.gateway.gateway i.caller i.gateway.before = .ok ())
    (hl : checkLengths (TopupBatchRootCalls.environment i.gateway).cfg i.rows.length
      i.keys.length i.operators.length i.rows.length i.rows.length = .ok ())
    (ht : TopupTimingHistory.gates i.gateway = .ok ())
    (hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
      i.gateway.before).outcome = .ok (router, next))
    (hc : (TopupCredentialCall.lookup (TopupPhysicalCredentialGetter.dispatch i.hash)
      i.gateway.gateway router i.moduleId next i.gateway.before).outcome = .ok (wc, x))
    (hwc : wc.val / 2^248 = 2)
    (hbad : ∃ r ∈ i.rows, r.witness.pubkey.length ≠ 48) :
    (∃ f, (TopupRouterAdmissionCall.run g i).outcome =
      .error (.prior (.phase (.phase (.phase (.batch (.gateway f))))))) ∧
    (TopupRouterAdmissionCall.run g i).world = i.gateway.before ∧
    (TopupRouterAdmissionCall.run g i).ready = none := by
  have hwc' : ¬ (wc.val / 2^248 ≠ 2) := fun hne => hne hwc
  cases ho : (TopupGatewayRootCalls.loop
      (TopupBatchRootCalls.environment (TopupCredentialCall.resolved i.gateway wc))
      none 0 i.rows).outcome with
  | ok out =>
    exfalso
    obtain ⟨r, hr, hk⟩ := hbad
    exact hk (loop_success_pubkeys _ i.rows none 0 out ho r hr)
  | «error» f =>
    unfold TopupRouterAdmissionCall.run TopupRouterAdmissionCall.walk
    refine ⟨⟨f, ?_⟩, ?_, ?_⟩ <;> simp only [hg, hl, ht, hq, hc, if_neg hwc', ho]

#print axioms loop_success_pubkeys
#print axioms seam_shapes
#print axioms seam_pubkeys
#print axioms wrong_credential_type_rejected
#print axioms wrong_pubkey_length_rejected

end LidoSRv3.Audit.Guarantees.PTopup2ValidatorChecks
