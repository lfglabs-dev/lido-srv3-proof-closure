import audit.trio.consolidation.Composition

/-!
Source consumer for ConsolidationGateway.sol:220 and WithdrawalVault.sol:199–208
at core17005714. Uses the corrected bytes[] ABI, a high-level code check, the
credited CALL world, and an independently configured authorized gateway.
The result carries actual STATICCALL/CALL observations with their static flags
and nested depths. Error data uses the source custom-error ABI.

Public consumer: PConsolidation1.actual_gateway_vault_requests. This is the
vault-call portion of request integrity; gateway prefix/quota and refund
composition still require their public connection. No claim of full delivery.
-/
namespace audit.trio.consolidation.GatewayCall
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Selectors checked against the pinned signature with cast and solc. -/
def selector : Bytes := encode 4 0xa75ac640

def error0 (s : Nat) : Bytes := encode 4 s
def error2 (s a b : Nat) : Bytes := encode 4 s ++ encode 32 a ++ encode 32 b
def errorBytes (s : Nat) (b : Bytes) : Bytes :=
  encode 4 s ++ encode 32 32 ++ abiBytesElement b
def panic (code : Nat) : Bytes := encode 4 0x4e487b71 ++ encode 32 code

structure FrameResult where
  outcome : Except Bytes Unit
  world : World
  trace : List NestedAttempt

/-- Direct child calls have depth1. Descendants retain their relative order
and static flags and gain exactly one level at the caller frame. -/
def callTrace (attempts : List Attempt) : List NestedAttempt :=
  attempts.flatMap fun a =>
    ⟨a.request, false, a.accepted, a.returned, 1⟩ ::
      a.nested.map (fun n => {n with depth := n.depth + 1})

/-- Actual vault loop: validation precedes each CALL; a rejection carries the
request bytes in RequestAdditionFailed. Success emits on the callee world. -/
def loop (callee : External) (ctx : Context) (inbox : Address) (fee : Word) :
    List ProducedPair → World → FrameResult
  | [], w => ⟨.ok (), w, []⟩
  | p :: ps, w =>
      if p.source.length ≠ 48 then
        ⟨.error (errorBytes 0xeb0c68a7 p.source), w, []⟩
      else if p.target.length ≠ 48 then
        ⟨.error (errorBytes 0xeb0c68a7 p.target), w, []⟩
      else
        let r := lowLevelCall callee ctx inbox (vaultCallPayload p) fee w
        match r.outcome with
        | .error _ =>
            ⟨.error (errorBytes 0xef36228e (vaultCallPayload p)), r.world,
              callTrace r.attempts⟩
        | .ok _ =>
            let next := loop callee ctx inbox fee ps
              {r.world with logs := r.world.logs ++ [requestAddedEvent ctx.self (vaultCallPayload p)]}
            ⟨next.outcome, next.world, callTrace r.attempts ++ next.trace⟩

/-- Fee read is an actual static call on the same incoming world, before
checked multiplication, exact-fee validation and per-key accesses. -/
def vaultBody (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Word)
    (sources targets : List Bytes) (w : World) : FrameResult :=
  if w.balances ctx.self < value.val then ⟨.error (panic 0x11), w, []⟩
  else if ctx.sender ≠ gateway then ⟨.error (error0 0xb7d22932), w, []⟩
  else if sources.length = 0 then
    ⟨.error (errorBytes 0x56e42893 ("sourcePubkeys".toUTF8.toList)), w, []⟩
  else if sources.length ≠ targets.length then
    ⟨.error (error2 0x4c59bf28 sources.length targets.length), w, []⟩
  else
    let s := lowLevelStaticCall sexternal ctx.self inbox [] w
    match s.outcome with
    | .error _ => ⟨.error (error0 0x03045050), w, s.attempts⟩
    | .ok data =>
        if data.length ≠ 32 then ⟨.error (error0 0x8235fc55), w, s.attempts⟩
        else
          let fee := Live.word (decode data)
          let total := sources.length * fee.val
          if total ≥ Verity.Core.UINT256_MODULUS then
            ⟨.error (panic 0x11), w, s.attempts⟩
          else if total ≠ value.val then
            ⟨.error (error2 0xdcf6afcb total value.val), w, s.attempts⟩
          else
            let r := loop callee ctx inbox fee (pairsOf sources targets) w
            match r.outcome with
            | .error e => ⟨.error e, r.world, s.attempts ++ r.trace⟩
            | .ok _ =>
                if r.world.balances ctx.self ≠ w.balances ctx.self - value.val then
                  ⟨.error (panic 1), r.world, s.attempts ++ r.trace⟩
                else ⟨.ok (), r.world, s.attempts ++ r.trace⟩

/-- Dispatcher consumes actual calldata. Eager element decoding remains a
known malformed-input ordering gap; canonical gateway calldata is connected
by the round-trip proof, not supplied decoded arrays. -/
def vaultExternal (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) : External := fun request credited =>
  if request.payload.take 4 ≠ selector then .rejected []
  else match decodeVaultArgs (request.payload.drop 4) with
    | none => .rejected []
    | some (sources, targets) =>
        let r := vaultBody callee sexternal ⟨request.target, request.caller⟩
          gateway inbox request.value sources targets credited
        match r.outcome with
        | .error data => .rejectedWithTrace data r.trace
        | .ok _ => .successWithTrace [] r.world r.trace

/-- High-level void interface CALL (code check before CALL), concrete selector
and actual ABI arrays. The calleeBody receives the transferred world. -/
def invoke (calleeBody : External) (ctx : Context) (vault : Address) (value : Word)
    (sources targets : List Bytes) : Exec Bytes := fun w =>
  let req : Request := ⟨ctx.self, vault, value, gatewayVaultCalldata selector sources targets⟩
  if (w.core.codeSize vault.val).val = 0 then ⟨.error .empty, w, []⟩
  else if w.balances ctx.self < value.val then
    ⟨.error (.bubbled []), w, [⟨req, false, [], []⟩]⟩
  else match calleeBody req (transfer w ctx.self vault value.val) with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨req, false, data, []⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.bubbled data), w, [⟨req, false, data, nested⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨req, true, data, []⟩]⟩
    | .successWithTrace data after nested =>
        ⟨.ok data, after, [⟨req, true, data, nested⟩]⟩

/-- Actual byte arrays flattened from the gateway's grouped calldata. -/
def sourceArray (groups : List WitnessGroupBytes) : List Bytes :=
  (preparePairBytes groups).map (·.source)
def targetArray (groups : List WitnessGroupBytes) : List Bytes :=
  (preparePairBytes groups).map (·.target)

/-- The actual line220 program consumes the raw-byte producer, not freely
chosen Nat pubkey identities. -/
def execute (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox : Address) (value : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result Bytes :=
  invoke (vaultExternal callee sexternal gateway inbox) ctx vault value
    (sourceArray groups) (targetArray groups) before

 theorem no_code (calleeBody : External) (ctx : Context) (vault : Address)
    (value : Word) (sources targets : List Bytes) (w : World)
    (h : (w.core.codeSize vault.val).val = 0) :
    invoke calleeBody ctx vault value sources targets w = ⟨.error .empty, w, []⟩ := by
  simp [invoke, h]

/-- Every failed outer CALL restores the pre-transfer world, including vault
writes, balances and logs. The retained trace records reverted attempts. -/
theorem invoke_failure_restores (calleeBody : External) (ctx : Context) (vault : Address)
    (value : Word) (sources targets : List Bytes) (w : World) (fault : Fault)
    (h : (invoke calleeBody ctx vault value sources targets w).outcome = .error fault) :
    (invoke calleeBody ctx vault value sources targets w).world = w := by
  unfold invoke at h ⊢
  dsimp only at h ⊢
  split <;> try rfl
  split <;> try rfl
  split <;> simp_all

/-- Successful execution of the richer loop has the same actual calls and
world as the existing loop. Its nested trace preserves every descendant. -/
theorem loop_success_projection (callee : External) (ctx : Context) (inbox : Address)
    (fee : Word) (pairs : List ProducedPair) (w : World)
    (h : (loop callee ctx inbox fee pairs w).outcome = .ok ()) :
    (addConsolidationRequestsLoop callee ctx inbox fee pairs w).outcome = .ok () ∧
    (loop callee ctx inbox fee pairs w).world =
      (addConsolidationRequestsLoop callee ctx inbox fee pairs w).world ∧
    (loop callee ctx inbox fee pairs w).trace =
      callTrace (addConsolidationRequestsLoop callee ctx inbox fee pairs w).attempts := by
  induction pairs generalizing w with
  | nil => simp [loop, addConsolidationRequestsLoop, pure, pureExec, callTrace]
  | cons p ps ih =>
      unfold loop at h ⊢
      split at h
      · contradiction
      next hs =>
        split at h
        · contradiction
        next ht =>
          have hs' : p.source.length = 48 := by simpa using hs
          have ht' : p.target.length = 48 := by simpa using ht
          simp only [hs', ht', ne_eq, not_true_eq_false, if_false]
          cases hc : lowLevelCall callee ctx inbox (vaultCallPayload p) fee w with
          | mk out after ats =>
              cases out with
              | «error» e => simp [hc] at h
              | ok data =>
                  simp only [hc] at h ⊢
                  have hi := ih _ h
                  simp only [addConsolidationRequestsLoop, validatePublicKey, pubkeyLength,
                    hs', ht', decide_true, Live.require, bind, bindExec, pure, pureExec,
                    callAddConsolidationRequest, hc, List.nil_append]
                  rcases hi with ⟨hok, hw, ht⟩
                  simp [Live.pureExec, hc, hok, hw, ht, callTrace]

/-- Necessary evidence extracted from the executed vault body. The fee, loop
world and trace below are the values actually consumed by that execution. -/
structure VaultSuccess (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Word)
    (sources targets : List Bytes) (w : World) : Prop where
  funded : value.val ≤ w.balances ctx.self
  authorized : ctx.sender = gateway
  nonempty : sources.length ≠ 0
  sameLength : sources.length = targets.length
  effects : ∃ data sattempts,
    lowLevelStaticCall sexternal ctx.self inbox [] w = ⟨.ok data, sattempts⟩ ∧
    data.length = 32 ∧
    sources.length * (Live.word (decode data)).val = value.val ∧
    (loop callee ctx inbox (Live.word (decode data)) (pairsOf sources targets) w).outcome = .ok () ∧
    (vaultBody callee sexternal ctx gateway inbox value sources targets w).world =
      (loop callee ctx inbox (Live.word (decode data)) (pairsOf sources targets) w).world ∧
    (vaultBody callee sexternal ctx gateway inbox value sources targets w).trace =
      sattempts ++ (loop callee ctx inbox (Live.word (decode data)) (pairsOf sources targets) w).trace ∧
    (vaultBody callee sexternal ctx gateway inbox value sources targets w).world.balances ctx.self =
      w.balances ctx.self - value.val

theorem vault_success (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Word)
    (sources targets : List Bytes) (w : World)
    (h : (vaultBody callee sexternal ctx gateway inbox value sources targets w).outcome = .ok ()) :
    VaultSuccess callee sexternal ctx gateway inbox value sources targets w := by
  unfold vaultBody at h
  split at h
  · contradiction
  next hfund =>
    split at h
    · contradiction
    next hauth =>
      split at h
      · contradiction
      next hnonempty =>
        split at h
        · contradiction
        next hlength =>
          cases hs : lowLevelStaticCall sexternal ctx.self inbox [] w with
          | mk sout sats =>
            cases sout with
            | «error» e => simp [hs] at h
            | ok data =>
              simp only [hs] at h
              split at h
              · contradiction
              next hdata =>
                split at h
                · contradiction
                next hfit =>
                  split at h
                  · contradiction
                  next hfee =>
                    cases hl : (loop callee ctx inbox (Live.word (decode data))
                        (pairsOf sources targets) w).outcome with
                    | «error» e => simp [hl] at h
                    | ok u =>
                      cases u
                      simp only [hl] at h
                      split at h
                      · contradiction
                      next hbalance =>
                        refine ⟨by omega, by simpa using hauth, hnonempty,
                          by simpa using hlength, data, sats, hs, by simpa using hdata,
                          by simpa using hfee, hl, ?_, ?_, ?_⟩ <;>
                          simp [vaultBody, hfund, hauth, hnonempty, hlength, hs, hdata,
                            hfit, hfee, hl, hbalance] <;> simpa using hbalance

set_option maxRecDepth 2048 in
/-- The actual CALL is the consumer: its accepted outcome exposes the decoded
arrays, actual credited world, authorized vault body, and that body's complete
static/value-call trace. There is no separately supplied successful vault run. -/
theorem execute_success (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox : Address) (value : Word)
    (groups : List WitnessGroupBytes) (before : World) (returned : Bytes)
    (h : (execute callee sexternal ctx vault gateway inbox value groups before).outcome = .ok returned) :
    (before.core.codeSize vault.val).val ≠ 0 ∧ value.val ≤ before.balances ctx.self ∧
    ∃ sources targets,
      decodeVaultArgs (gatewayVaultArgs (sourceArray groups) (targetArray groups)) =
        some (sources, targets) ∧
      VaultSuccess callee sexternal ⟨vault, ctx.self⟩ gateway inbox value sources targets
        (transfer before ctx.self vault value.val) ∧
      (execute callee sexternal ctx vault gateway inbox value groups before).world =
        (vaultBody callee sexternal ⟨vault, ctx.self⟩ gateway inbox value sources targets
          (transfer before ctx.self vault value.val)).world ∧
      (execute callee sexternal ctx vault gateway inbox value groups before).attempts =
        [⟨⟨ctx.self, vault, value,
          gatewayVaultCalldata selector (sourceArray groups) (targetArray groups)⟩, true, [],
          (vaultBody callee sexternal ⟨vault, ctx.self⟩ gateway inbox value sources targets
            (transfer before ctx.self vault value.val)).trace⟩] := by
  have hsel : selector.length = 4 := ABI.encode_length _ _
  have takeSel : (gatewayVaultCalldata selector (sourceArray groups) (targetArray groups)).take 4 =
      selector := by
    exact List.take_left' hsel
  have dropSel : (gatewayVaultCalldata selector (sourceArray groups) (targetArray groups)).drop 4 =
      gatewayVaultArgs (sourceArray groups) (targetArray groups) := by
    exact List.drop_left' hsel
  unfold execute invoke at h
  dsimp only at h
  split at h
  · contradiction
  next hcode =>
    split at h
    · contradiction
    next hfund =>
      simp only [vaultExternal, takeSel, ne_eq, not_true_eq_false, if_false, dropSel] at h
      cases hd : decodeVaultArgs (gatewayVaultArgs (sourceArray groups) (targetArray groups)) with
      | none => simp [hd] at h
      | some arrays =>
        obtain ⟨sources, targets⟩ := arrays
        simp only [hd] at h
        cases hb : (vaultBody callee sexternal ⟨vault, ctx.self⟩ gateway inbox value sources targets
            (transfer before ctx.self vault value.val)).outcome with
        | «error» e => simp [hb] at h
        | ok u =>
          cases u
          refine ⟨hcode, by omega, sources, targets, rfl,
            vault_success callee sexternal _ gateway inbox value sources targets _ hb, ?_, ?_⟩ <;>
            simp [execute, invoke, hcode, hfund, vaultExternal, takeSel, dropSel, hd, hb]

/-- Successful vault execution consumes one source+target request per decoded
pair, after the fee STATICCALL. All descendant observations are retained. -/
theorem vault_success_requests (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Word)
    (sources targets : List Bytes) (w : World)
    (h : (vaultBody callee sexternal ctx gateway inbox value sources targets w).outcome = .ok ()) :
    ∃ data sattempts attempts,
      lowLevelStaticCall sexternal ctx.self inbox [] w = ⟨.ok data, sattempts⟩ ∧
      data.length = 32 ∧ sources.length * (Live.word (decode data)).val = value.val ∧
      (∀ p ∈ pairsOf sources targets, widthOk p) ∧
      attempts.map (·.request) = hopRequests ctx inbox (Live.word (decode data)) (pairsOf sources targets) ∧
      (vaultBody callee sexternal ctx gateway inbox value sources targets w).trace =
        sattempts ++ callTrace attempts := by
  obtain ⟨_, _, _, _, data, sats, hs, hlen, hfee, hl, _, ht, _⟩ :=
    vault_success callee sexternal ctx gateway inbox value sources targets w h
  obtain ⟨hold, _, htrace⟩ := loop_success_projection callee ctx inbox _ _ w hl
  obtain ⟨hw, hreq, _⟩ := loop_success callee ctx inbox _ _ w hold
  exact ⟨data, sats, (addConsolidationRequestsLoop callee ctx inbox (Live.word (decode data))
    (pairsOf sources targets) w).attempts, hs, hlen, hfee, hw, hreq, ht.trans (by rw [htrace])⟩

/-- End-to-end necessary request evidence for the gateway's actual vault CALL.
The committed world and trace are those of the decoded request consumer. -/
theorem execute_success_requests (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox : Address) (value : Word)
    (groups : List WitnessGroupBytes) (before : World) (returned : Bytes)
    (h : (execute callee sexternal ctx vault gateway inbox value groups before).outcome = .ok returned) :
    ctx.self = gateway ∧
    ∃ sources targets data sats attempts,
      decodeVaultArgs (gatewayVaultArgs (sourceArray groups) (targetArray groups)) = some (sources, targets) ∧
      sources.length ≠ 0 ∧ sources.length = targets.length ∧
      lowLevelStaticCall sexternal vault inbox [] (transfer before ctx.self vault value.val) =
        ⟨.ok data, sats⟩ ∧
      data.length = 32 ∧ sources.length * (Live.word (decode data)).val = value.val ∧
      (∀ p ∈ pairsOf sources targets, widthOk p) ∧
      attempts.map (·.request) = hopRequests ⟨vault, ctx.self⟩ inbox
        (Live.word (decode data)) (pairsOf sources targets) ∧
      (execute callee sexternal ctx vault gateway inbox value groups before).world =
        (addConsolidationRequestsLoop callee ⟨vault, ctx.self⟩ inbox (Live.word (decode data))
          (pairsOf sources targets) (transfer before ctx.self vault value.val)).world ∧
      (execute callee sexternal ctx vault gateway inbox value groups before).attempts =
        [⟨⟨ctx.self, vault, value,
          gatewayVaultCalldata selector (sourceArray groups) (targetArray groups)⟩,
          true, [], sats ++ callTrace attempts⟩] := by
  obtain ⟨_, _, sources, targets, hd, hv, hw, ha⟩ :=
    execute_success callee sexternal ctx vault gateway inbox value groups before returned h
  obtain ⟨data, sats, hs, hlen, hfee, hl, hworld, htrace, _⟩ := hv.effects
  obtain ⟨hold, hwold, htold⟩ := loop_success_projection callee ⟨vault, ctx.self⟩ inbox _ _ _ hl
  obtain ⟨hwidth, hrequests, _⟩ := loop_success callee ⟨vault, ctx.self⟩ inbox _ _ _ hold
  refine ⟨hv.authorized, sources, targets, data, sats, _, hd,
    hv.nonempty, hv.sameLength, hs, hlen, hfee, hwidth, hrequests,
    hw.trans (hworld.trans hwold), ?_⟩
  rw [ha, htrace, htold]

#print axioms execute_success_requests
#print axioms invoke_failure_restores

end audit.trio.consolidation.GatewayCall
