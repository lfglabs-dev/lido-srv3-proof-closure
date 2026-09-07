import LidoSRv3.Audit.Source.TrioReserve1.OracleCalls
import LidoSRv3.Audit.Source.TrioReserve1.Consensus

namespace LidoSRv3.Audit.Source.TrioReserve1.ConsensusCalls
open Live

def consensusAddress (oracle : Address) (w : World) : Address :=
  Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val Oracle.consensusSlot).val

def attempt (oracle consensus : Address) (accepted : Bool) (data : Bytes) : NestedAttempt :=
  ⟨⟨oracle, consensus, word 0, encode 4 0x72f79b13⟩, true, accepted, data, 1⟩

theorem compute_bounds (c : Consensus.Config) (time packed reference deadline : Nat)
    (h : Consensus.compute c time packed = .ok (reference, deadline)) :
    reference < 2^64 ∧ deadline < 2^64 := by
  obtain ⟨s, e, i, _, _, _, _, _, _, _, _, hr, hd⟩ := Consensus.compute_success c time packed reference deadline h
  constructor
  · rw [hr]
    exact Nat.mod_lt _ (by decide)
  · rw [hd]
    exact Nat.mod_lt _ (by decide)

theorem static_success (consensus oracle : Address) (c : Consensus.Config)
    (other : StaticCall.External) (w : World) (reference deadline : Nat)
    (hc : (w.core.codeSize consensus.val).val ≠ 0)
    (h : Consensus.compute c w.core.blockTimestamp.val
      (w.core.readContractSlot consensus.val c.frameSlot).val = .ok (reference, deadline)) :
    StaticCall.call (Consensus.dispatch consensus c other) oracle consensus 0x72f79b13 w =
      ⟨.ok (encode 32 reference ++ encode 32 deadline),
        [attempt oracle consensus true (encode 32 reference ++ encode 32 deadline)]⟩ := by
  simp [StaticCall.call, Consensus.dispatch, hc, h, attempt]

theorem static_rejection (consensus oracle : Address) (c : Consensus.Config)
    (other : StaticCall.External) (w : World) (data : Bytes)
    (hc : (w.core.codeSize consensus.val).val ≠ 0)
    (h : Consensus.compute c w.core.blockTimestamp.val
      (w.core.readContractSlot consensus.val c.frameSlot).val = .error data) :
    StaticCall.call (Consensus.dispatch consensus c other) oracle consensus 0x72f79b13 w =
      ⟨.error data, [attempt oracle consensus false data]⟩ := by
  simp [StaticCall.call, Consensus.dispatch, hc, h, attempt]

theorem decode_reference (reference deadline : Nat) (hr : reference < 2^64) :
    (word (decode ((encode 32 reference ++ encode 32 deadline).take 32))).val = reference := by
  have ht : (encode 32 reference ++ encode 32 deadline).take 32 = encode 32 reference := by
    simpa only [ABI.encode_length] using
      (List.take_left (l₁ := encode 32 reference) (l₂ := encode 32 deadline))
  have hb : reference < 256^32 := by omega
  rw [ht, ABI.decode_encode_bounded 32 reference hb]
  exact Nat.mod_eq_of_lt (by change reference < 2^256; omega)

/-- Bind BaseOracle's physical pointer to the actual consensus getter. The
tuple comes from checked frame computation, not arbitrary static-return bytes. -/
theorem oracle_frame (oracle : Address) (oc : Oracle.Config) (cc : Consensus.Config)
    (other : StaticCall.External) (w : World) (reference deadline time : Nat)
    (hc : (w.core.codeSize (consensusAddress oracle w).val).val ≠ 0)
    (h : Consensus.compute cc w.core.blockTimestamp.val
      (w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp oc.genesis.val oc.secondsPerSlot.val reference = .value time) :
    Oracle.frame (Consensus.dispatch (consensusAddress oracle w) cc other) oracle oc w =
      .successWithTrace (encode 32 reference ++ encode 32 time) w
        [attempt oracle (consensusAddress oracle w) true (encode 32 reference ++ encode 32 deadline)] := by
  have hr := (compute_bounds cc _ _ reference deadline h).1
  have hs := static_success (consensusAddress oracle w) oracle cc other w reference deadline hc h
  change StaticCall.call _ oracle
    (Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val Oracle.consensusSlot).val) _ w = _ at hs
  simp only [Oracle.frame, hs, decode_reference reference deadline hr, ht]
  simp [ABI.encode_length]

theorem oracle_rejection (oracle : Address) (oc : Oracle.Config) (cc : Consensus.Config)
    (other : StaticCall.External) (w : World) (data : Bytes)
    (hc : (w.core.codeSize (consensusAddress oracle w).val).val ≠ 0)
    (h : Consensus.compute cc w.core.blockTimestamp.val
      (w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val = .error data) :
    Oracle.frame (Consensus.dispatch (consensusAddress oracle w) cc other) oracle oc w =
      .rejectedWithTrace data [attempt oracle (consensusAddress oracle w) false data] := by
  have hs := static_rejection (consensusAddress oracle w) oracle cc other w data hc h
  change StaticCall.call _ oracle
    (Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val Oracle.consensusSlot).val) _ w = _ at hs
  simp only [Oracle.frame, hs]

theorem oracle_overflow (oracle : Address) (oc : Oracle.Config) (cc : Consensus.Config)
    (other : StaticCall.External) (w : World) (reference deadline : Nat)
    (hc : (w.core.codeSize (consensusAddress oracle w).val).val ≠ 0)
    (h : Consensus.compute cc w.core.blockTimestamp.val
      (w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp oc.genesis.val oc.secondsPerSlot.val reference = .overflow) :
    Oracle.frame (Consensus.dispatch (consensusAddress oracle w) cc other) oracle oc w =
      .rejectedWithTrace Oracle.panic
        [attempt oracle (consensusAddress oracle w) true (encode 32 reference ++ encode 32 deadline)] := by
  have hr := (compute_bounds cc _ _ reference deadline h).1
  have hs := static_success (consensusAddress oracle w) oracle cc other w reference deadline hc h
  change StaticCall.call _ oracle
    (Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val Oracle.consensusSlot).val) _ w = _ at hs
  simp only [Oracle.frame, hs, decode_reference reference deadline hr, ht]
  simp [ABI.encode_length]

theorem oracle_no_code (oracle : Address) (oc : Oracle.Config) (cc : Consensus.Config)
    (other : StaticCall.External) (w : World)
    (hc : (w.core.codeSize (consensusAddress oracle w).val).val = 0) :
    Oracle.frame (Consensus.dispatch (consensusAddress oracle w) cc other) oracle oc w =
      .rejectedWithTrace [] [] := by
  change (w.core.codeSize
    (Verity.Core.Address.ofNat (w.core.readContractSlot oracle.val Oracle.consensusSlot).val).val).val = 0 at hc
  simp only [Oracle.frame, StaticCall.call, hc, ite_true]

/-- Both independent arithmetic relations use the actual timestamp, physical
frame word and immutable inputs of this execution. -/
theorem independent_rules (oracle : Address) (oc : Oracle.Config) (cc : Consensus.Config)
    (w : World) (reference deadline time : Nat)
    (h : Consensus.compute cc w.core.blockTimestamp.val
      (w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp oc.genesis.val oc.secondsPerSlot.val reference = .value time) :
    FrameSpec.Describes w.core.blockTimestamp.val cc.genesis cc.secondsPerSlot cc.slotsPerEpoch
      ((w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val % 2^64)
      ((w.core.readContractSlot (consensusAddress oracle w).val cc.frameSlot).val / 2^64 % 2^64)
      reference deadline ∧
    OracleSpec.Describes oc.genesis.val oc.secondsPerSlot.val reference (.value time) := by
  refine ⟨Consensus.compute_success cc _ _ reference deadline h, ?_⟩
  have hs := Oracle.timestamp_corresponds oc.genesis.val oc.secondsPerSlot.val reference
  simpa only [ht] using hs

/-- Complete getter path: Lido's physical locator, immutable oracle lookup,
AccountingOracle/BaseOracle pointer, actual HashConsensus getter and both ABI
decoders. The result uses exact Nat values justified by source-derived bounds. -/
theorem lido_frame (keccak : Queue.Keccak) (c : Locator.Config)
    (oc : Oracle.Config) (cc : Consensus.Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (reference deadline time : Nat)
    (hd : c.oracle ≠ Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val)
    (hq : c.oracle ≠ c.queue)
    (hl : (w.core.codeSize
      (Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val).val).val ≠ 0)
    (ho : (w.core.codeSize c.oracle.val).val ≠ 0)
    (hc : (w.core.codeSize (consensusAddress c.oracle w).val).val ≠ 0)
    (h : Consensus.compute cc w.core.blockTimestamp.val
      (w.core.readContractSlot (consensusAddress c.oracle w).val cc.frameSlot).val = .ok (reference, deadline))
    (ht : Oracle.timestamp oc.genesis.val oc.secondsPerSlot.val reference = .value time) :
    let locator := Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val
    let consensus := consensusAddress c.oracle w
    getCurrentFrame
      (OracleCalls.external keccak locator c oc (Consensus.dispatch consensus cc staticOther) other) ctx w =
      ⟨.ok (reference, time), w,
        [⟨⟨ctx.self, locator, word 0, encode 4 0x5a2031f9⟩, true, encode 32 c.oracle.val, []⟩,
          ⟨⟨ctx.self, c.oracle, word 0, encode 4 0x72f79b13⟩, true, encode 32 reference ++ encode 32 time,
            [attempt c.oracle consensus true (encode 32 reference ++ encode 32 deadline)]⟩]⟩ := by
  have hf := oracle_frame c.oracle oc cc staticOther w reference deadline time hc h ht
  have hg := OracleCalls.current_frame keccak c oc
    (Consensus.dispatch (consensusAddress c.oracle w) cc staticOther) other ctx w reference time _ hd hq hl ho hf
  have hr := (compute_bounds cc _ _ reference deadline h).1
  have hr256 : reference < Verity.Core.UINT256_MODULUS := by
    unfold Verity.Core.UINT256_MODULUS
    omega
  have ht256 := (independent_rules c.oracle oc cc w reference deadline time h ht).2.2.2
  change time < Verity.Core.UINT256_MODULUS at ht256
  simpa [word, Verity.Core.Uint256.ofNat, Verity.Core.Uint256.modulus,
    Nat.mod_eq_of_lt hr256, Nat.mod_eq_of_lt ht256] using hg

end LidoSRv3.Audit.Source.TrioReserve1.ConsensusCalls
