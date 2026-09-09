import LidoSRv3.Audit.Source.SszPerfectTree

/-!
Canonical validator-list/container spine for consensus-specs v1.6.0 at
f96d3e7acf35125295d234da4b0c67591fdef49c. This external schema snapshot is
not inferred to be a Lido dependency or deployed-fork identity. Other named
BeaconState fields are opaque SSZ roots; their internal encodings are not proved.
Lido consumer pin remains 17005714f151e5502c559932319a3f2f74ac2436.
-/
namespace LidoSRv3.Audit.Source.SszStatePlacement
open SszWrapperIndex SszValidatorLeaf SszLittleEndianCorrespondence
open SszProofFold SszPerfectTree SszVerifierEntry

inductive Schema where
  | electra | fulu
  deriving DecidableEq, Repr

/-- Named field order follows the two immutable consensus BeaconState schemas.
The validators field is computed below; an opaque input at this name is ignored. -/
inductive StateField where
  | genesisTime | genesisValidatorsRoot | slot | fork | latestBlockHeader
  | blockRoots | stateRoots | historicalRoots | eth1Data | eth1DataVotes
  | eth1DepositIndex | validators | balances | randaoMixes | slashings
  | previousEpochParticipation | currentEpochParticipation | justificationBits
  | previousJustifiedCheckpoint | currentJustifiedCheckpoint | finalizedCheckpoint
  | inactivityScores | currentSyncCommittee | nextSyncCommittee
  | latestExecutionPayloadHeader | nextWithdrawalIndex | nextWithdrawalValidatorIndex
  | historicalSummaries | depositRequestsStartIndex | depositBalanceToConsume
  | exitBalanceToConsume | earliestExitEpoch | consolidationBalanceToConsume
  | earliestConsolidationEpoch | pendingDeposits | pendingPartialWithdrawals
  | pendingConsolidations | proposerLookahead
  deriving DecidableEq, Repr

/-- The complete ordered Electra field enumeration, not a supplied field index. -/
def electraFields : List StateField := [
  .genesisTime, .genesisValidatorsRoot, .slot, .fork, .latestBlockHeader,
  .blockRoots, .stateRoots, .historicalRoots, .eth1Data, .eth1DataVotes,
  .eth1DepositIndex, .validators, .balances, .randaoMixes, .slashings,
  .previousEpochParticipation, .currentEpochParticipation, .justificationBits,
  .previousJustifiedCheckpoint, .currentJustifiedCheckpoint, .finalizedCheckpoint,
  .inactivityScores, .currentSyncCommittee, .nextSyncCommittee,
  .latestExecutionPayloadHeader, .nextWithdrawalIndex, .nextWithdrawalValidatorIndex,
  .historicalSummaries, .depositRequestsStartIndex, .depositBalanceToConsume,
  .exitBalanceToConsume, .earliestExitEpoch, .consolidationBalanceToConsume,
  .earliestConsolidationEpoch, .pendingDeposits, .pendingPartialWithdrawals,
  .pendingConsolidations]

def fields : Schema → List StateField
  | .electra => electraFields
  | .fulu => electraFields ++ [.proposerLookahead]

theorem schema_field_count (schema : Schema) :
    (fields schema).length = (match schema with | .electra => 37 | .fulu => 38) := by
  cases schema <;> decide

theorem schema_container_width (schema : Schema) :
    2 ^ 5 < (fields schema).length ∧ (fields schema).length ≤ 2 ^ 6 := by
  cases schema <;> decide

theorem validators_field_position (schema : Schema) :
    (fields schema)[11]? = some .validators := by cases schema <;> decide

/-- Actual semantic Validator value, including its own credentials. The length
is the Bytes48 SSZ domain, not a supplied calculated-leaf equality. -/
structure ValidatorValue where
  witness : Witness
  withdrawalCredentials : Digest
  pubkeyLength : witness.pubkey.length = 48

def capacity : Nat := 2 ^ 40

/-- Little-endian uint256 length mix-in, independently serialized as 32 octets. -/
def lengthChunk (length : Nat) : Digest :=
  littleEndianOctets (BitVec.ofNat 256 length)

def validatorElement (sha : Sha) (values : List ValidatorValue) (i : Nat) : Tree Digest :=
  match values[i]? with
  | some value => validatorTree sha value.witness value.withdrawalCredentials
  | none => .leaf 0

def registryData (sha : Sha) (values : List ValidatorValue) : Tree Digest :=
  perfectTree 40 (validatorElement sha values)

/-- Composite-list root: ordered data to capacity, then actual length on right. -/
def registryTree (sha : Sha) (values : List ValidatorValue) : Tree Digest :=
  .node (registryData sha values) (.leaf (lengthChunk values.length))

/-- Independent root specification uses ordered chunks and list reduction.
It does not take a final registry digest as an argument. -/
def registryRoot (sha : Sha) (values : List ValidatorValue) : Digest :=
  pair sha (orderedMerkle (pair sha) 0 40 (chunks 40 (fun i =>
    match values[i]? with
    | some v => treeDigest (pair sha) (validatorTree sha v.witness v.withdrawalCredentials)
    | none => 0))) (lengthChunk values.length)

/-- Ordered semantic element roots followed by the exact SSZ capacity padding. -/
theorem registry_chunks (sha : Sha) (values : List ValidatorValue)
    (hcap : values.length ≤ capacity) :
    chunks 40 (fun i => match values[i]? with
      | some v => treeDigest (pair sha) (validatorTree sha v.witness v.withdrawalCredentials)
      | none => 0) =
    values.map (fun v => treeDigest (pair sha) (validatorTree sha v.witness v.withdrawalCredentials)) ++
      List.replicate (capacity - values.length) 0 := by
  let roots := values.map (fun v => treeDigest (pair sha) (validatorTree sha v.witness v.withdrawalCredentials))
  have hf : (fun i : Nat => match values[i]? with
      | some v => treeDigest (pair sha) (validatorTree sha v.witness v.withdrawalCredentials)
      | none => 0) = fun i : Nat => roots[i]?.getD 0 := by
    funext i
    simp only [roots, List.getElem?_map]
    cases values[i]? <;> rfl
  rw [hf]
  simpa only [roots, List.length_map, capacity] using
    chunks_padding 40 roots 0 (by simpa only [roots, List.length_map, capacity] using hcap)

theorem registry_digest (sha : Sha) (values : List ValidatorValue) :
    treeDigest (pair sha) (registryTree sha values) = registryRoot sha values := by
  unfold registryTree registryRoot registryData
  rw [treeDigest, perfect_digest_ordered (zero := 0)]
  congr 3
  funext i
  unfold validatorElement
  cases values[i]? <;> rfl

theorem length_encoding_no_wrap (values : List ValidatorValue) (hcap : values.length ≤ capacity) :
    (BitVec.ofNat 256 values.length).toNat = values.length ∧
    sourceUint256 (BitVec.ofNat 256 values.length) = lengthChunk values.length := by
  constructor
  · simp only [BitVec.toNat_ofNat]
    apply Nat.mod_eq_of_lt
    unfold capacity at hcap
    omega
  · exact source_uint256_eq_octets _

/-- These are roots of other named SSZ fields, not an arbitrary state root or
supplied validator placement. Their internal semantics remain a boundary. -/
abbrev OtherFieldRoots := StateField → Digest

def stateElement (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) (i : Nat) : Tree Digest :=
  match (fields schema)[i]? with
  | none => .leaf 0
  | some .validators => registryTree sha values
  | some field => .leaf (other field)

def stateTree (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) : Tree Digest := perfectTree 6 (stateElement sha schema values other)

/-- Independent ordered container-root specification, with unknown nonvalidator
field roots kept explicit. Named field order controls position and padding. -/
def stateRoot (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) : Digest :=
  orderedMerkle (pair sha) 0 6 (chunks 6 (fun i =>
    match (fields schema)[i]? with
    | none => 0
    | some .validators => registryRoot sha values
    | some field => other field))

def canonicalFieldRoots (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) : List Digest :=
  (fields schema).map fun field => match field with
    | .validators => registryRoot sha values
    | field => other field

/-- The container specification is exactly the named ordered field roots,
followed by zero chunks up to the schema-derived 64-position width. -/
theorem state_root_ordered_fields (sha : Sha) (schema : Schema)
    (values : List ValidatorValue) (other : OtherFieldRoots) :
    stateRoot sha schema values other = orderedMerkle (pair sha) 0 6
      (canonicalFieldRoots sha schema values other ++
        List.replicate (64 - (fields schema).length) 0) := by
  have hf : (fun i : Nat => match (fields schema)[i]? with
      | none => (0 : Digest)
      | some .validators => registryRoot sha values
      | some field => other field) =
      fun i : Nat => (canonicalFieldRoots sha schema values other)[i]?.getD 0 := by
    funext i
    simp only [canonicalFieldRoots, List.getElem?_map]
    cases (fields schema)[i]? with
    | none => rfl
    | some field => cases field <;> rfl
  unfold stateRoot
  rw [hf, chunks_padding]
  · simp only [canonicalFieldRoots, List.length_map, show (2 : Nat) ^ 6 = 64 by decide]
  · simpa only [canonicalFieldRoots, List.length_map] using (schema_container_width schema).2

theorem state_digest (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) :
    treeDigest (pair sha) (stateTree sha schema values other) = stateRoot sha schema values other := by
  unfold stateTree stateRoot
  rw [perfect_digest_ordered (zero := 0)]
  congr 2
  funext i
  unfold stateElement
  cases (fields schema)[i]? with
  | none => rfl
  | some field => cases field <;> simp only [registry_digest, treeDigest]

/-- Field 11's six-bit address, then the composite list's left data edge. -/
def statePath (i : Nat) : List Bool := addressPath 6 11 ++ false :: addressPath 40 i

theorem state_path_index (i : Nat) (hi : i < capacity) :
    treeIndex (statePath i) = 150 * 2 ^ 40 + i := by
  have hn := address_length 40 i
  have hv := address_index 40 i hi
  change treeIndex ([false, false, true, false, true, true, false] ++ addressPath 40 i) = _
  simp only [List.cons_append, List.nil_append, treeIndex, List.length_cons, hn, Nat.pow_succ]
  omega

theorem registry_member_subtree (sha : Sha) (values : List ValidatorValue)
    (hcap : values.length ≤ capacity) (i : Fin values.length) :
    subtreeAt (registryTree sha values) (false :: addressPath 40 i.val) =
      some (validatorTree sha values[i].witness values[i].withdrawalCredentials) := by
  have hi : i.val < 2 ^ 40 := lt_of_lt_of_le i.isLt hcap
  simp only [registryTree, subtreeAt, registryData]
  rw [perfect_subtree 40 i.val _ hi]
  simp only [validatorElement, List.getElem?_eq_getElem i.isLt, Fin.getElem_fin]

/-- The actual length is the sibling immediately above the 40 data edges.
It is computed from this list, not supplied independently in the proof. -/
theorem registry_length_sibling (sha : Sha) (values : List ValidatorValue)
    (hcap : values.length ≤ capacity) (i : Fin values.length) :
    ∃ dataProof,
      treeBranch (pair sha) (registryData sha values) (addressPath 40 i.val) = some dataProof ∧
      dataProof.length = 40 ∧
      treeBranch (pair sha) (registryTree sha values) (false :: addressPath 40 i.val) =
        some (dataProof ++ [lengthChunk values.length]) := by
  have hi : i.val < 2 ^ 40 := lt_of_lt_of_le i.isLt hcap
  obtain ⟨proof, hp⟩ := subtree_branch_exists (pair sha) _ _ _
    (perfect_subtree 40 i.val (validatorElement sha values) hi)
  refine ⟨proof, hp, ?_, ?_⟩
  · simpa only [address_length] using tree_branch_length (pair sha) _ _ proof hp
  · simp only [registryTree, treeBranch, registryData, hp, Option.map_some, treeDigest]

/-- Padding is structural and does not imply any universal digest inequality. -/
theorem registry_padding_subtree (sha : Sha) (values : List ValidatorValue)
    (i : Nat) (hpad : values.length ≤ i) (hi : i < capacity) :
    subtreeAt (registryTree sha values) (false :: addressPath 40 i) = some (.leaf 0) := by
  simp only [registryTree, subtreeAt, registryData]
  rw [perfect_subtree 40 i _ hi]
  simp only [validatorElement, List.getElem?_eq_none hpad]

/-- Actual membership supplies the source's offset guard, not conversely. -/
theorem member_capacity (values : List ValidatorValue) (hcap : values.length ≤ capacity)
    (i : Fin values.length) : i.val < capacity := lt_of_lt_of_le i.isLt hcap

def memberOffset (values : List ValidatorValue) (hcap : values.length ≤ capacity)
    (i : Fin values.length) : Fin wordModulus :=
  ⟨i.val, by have hi := member_capacity values hcap i; unfold capacity wordModulus at *; omega⟩

theorem member_wrapper_accepts (values : List ValidatorValue) (hcap : values.length ≤ capacity)
    (i : Fin values.length) (pivot slot : Fin (2 ^ 64)) :
    ∃ out, sourceWrapper (pinnedConfiguration pivot) slot (memberOffset values hcap i) = .ok out := by
  apply (pinned_wrapper_accepts_iff _ _ _).mpr
  exact member_capacity values hcap i

/-- Placement is derived from the named container schema and actual list element;
there is no externally supplied subtree or index/path equality premise. -/
theorem state_member_subtree (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) (hcap : values.length ≤ capacity) (i : Fin values.length) :
    subtreeAt (stateTree sha schema values other) (statePath i.val) =
      some (validatorTree sha values[i].witness values[i].withdrawalCredentials) := by
  have hfield : subtreeAt (stateTree sha schema values other) (addressPath 6 11) =
      some (registryTree sha values) := by
    unfold stateTree
    rw [perfect_subtree 6 11 _ (by decide)]
    simp only [stateElement, validators_field_position]
  rw [statePath, subtree_append _ _ _ _ hfield]
  exact registry_member_subtree sha values hcap i

theorem state_member_branch (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) (hcap : values.length ≤ capacity) (i : Fin values.length) :
    ∃ proof, treeBranch (pair sha) (stateTree sha schema values other) (statePath i.val) = some proof ∧
      proof.length = 47 := by
  obtain ⟨proof, hp⟩ := subtree_branch_exists (pair sha) _ _ _
    (state_member_subtree sha schema values other hcap i)
  refine ⟨proof, hp, ?_⟩
  have hn := tree_branch_length (pair sha) _ _ proof hp
  simpa only [statePath, List.length_append, List.length_cons, address_length] using hn

/-- Complete typed entry consumer with canonical registry/container placement.
The root response remains explicitly trusted; the other fields remain opaque.
No hi/hp/hplace, supplied leaf digest or root-match Boolean is a premise. -/
theorem canonical_validator_entry
    (sha : Sha) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (schema : Schema) (values : List ValidatorValue) (other : OtherFieldRoots)
    (hcap : values.length ≤ capacity) (i : Fin values.length)
    (pivot : Fin (2 ^ 64)) (beacon : BeaconData) (parentRoot bodyRoot : Digest) (suffix : List Byte)
    (hresponse : oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp) =
      ⟨true, digestBytes (treeDigest (pair sha)
        (headerTree (uint64Chunk beacon.slot) (uint64Chunk beacon.proposerIndex)
          parentRoot bodyRoot 0 (stateTree sha schema values other))) ++ suffix⟩) :
    ∃ proof,
      treeBranch (pair sha)
        (headerTree (uint64Chunk beacon.slot) (uint64Chunk beacon.proposerIndex)
          parentRoot bodyRoot 0 (stateTree sha schema values other))
        ([false, true, true] ++ statePath i.val) = some proof ∧
      proof.length = 50 ∧
      sourceEntry (standardSha sha) oracle scratch (pinnedConfiguration pivot)
        beacon values[i].witness proof (memberOffset values hcap i) values[i].withdrawalCredentials = .ok () := by
  obtain ⟨out, hw⟩ := member_wrapper_accepts values hcap i pivot ⟨beacon.slot.toNat, beacon.slot.isLt⟩
  obtain ⟨stateProof, hp, _⟩ := state_member_branch sha schema values other hcap i
  exact validator_entry_consumer sha oracle scratch values[i].witness values[i].withdrawalCredentials
    values[i].pubkeyLength pivot beacon (memberOffset values hcap i) out parentRoot bodyRoot
    (stateTree sha schema values other) (statePath i.val) stateProof suffix hw
    (state_path_index i.val (member_capacity values hcap i)) hp
    (state_member_subtree sha schema values other hcap i) hresponse

end LidoSRv3.Audit.Source.SszStatePlacement
