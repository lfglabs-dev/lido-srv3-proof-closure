import Verity.Core

/-!
# Consolidation source specification

An independent, executable specification of the pure parts of the pinned
consolidation path at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `ConsolidationBus.addConsolidationRequests` (lines 325--370),
* `ConsolidationGateway._prepareConsolidationPairs` (lines 348--365), and
* `WithdrawalVaultEIP7685._addConsolidationRequests` (lines 56--73).

This file deliberately does not import an existing consolidation model.  Keys
carry their byte length and an opaque content identity; `keccak256` equality is
represented by equality of that identity.  Stateful role, pending-batch,
proof, quota, external-call, and rollback behavior belongs to later layers.
-/

namespace audit.trio.consolidation

abbrev Word := Verity.Core.Uint256

def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

def pubkeyLength : Nat := 48

/-- A calldata `bytes` public key. `identity` abstracts its byte content/hash. -/
structure Pubkey where
  identity : Nat
  length : Nat
  deriving DecidableEq, Repr

/-- Publisher input to `ConsolidationBus.addConsolidationRequests`. -/
structure PublisherGroup where
  sources : List Pubkey
  target : Pubkey
  deriving DecidableEq, Repr

/-- Gateway input. The proof fields of `ValidatorWitness` are intentionally
opaque here; the target pubkey is the field used by pair preparation. -/
structure WitnessGroup where
  sources : List Pubkey
  target : Pubkey
  deriving DecidableEq, Repr

inductive BusAddError where
  | emptyBatch
  | tooManyGroups (actual limit : Nat)
  | emptyGroup (groupIndex : Nat)
  | countOverflow
  | batchTooLarge (actual limit : Nat)
  | invalidTargetLength (groupIndex actual : Nat)
  | invalidSourceLength (groupIndex sourceIndex actual : Nat)
  | sourceEqualsTarget (groupIndex sourceIndex : Nat)
  deriving DecidableEq, Repr

private def checkedAdd (a b : Nat) : Option Nat :=
  if a + b < 2 ^ 256 then some (a + b) else none

/-- First loop of the bus entrypoint: reject an empty source group and compute
`totalCount` with Solidity's checked `uint256` addition. -/
def countSources : List PublisherGroup → Except BusAddError Nat :=
  go 0 0
where
  go (groupIndex total : Nat) : List PublisherGroup → Except BusAddError Nat
    | [] => .ok total
    | group :: rest =>
        if group.sources.isEmpty then .error (.emptyGroup groupIndex)
        else match checkedAdd total group.sources.length with
          | none => .error .countOverflow
          | some next => go (groupIndex + 1) next rest

private def validateSources (groupIndex : Nat) (target : Pubkey) :
    Nat → List Pubkey → Except BusAddError Unit
  | _, [] => .ok ()
  | sourceIndex, source :: rest =>
      if source.length != pubkeyLength then
        .error (.invalidSourceLength groupIndex sourceIndex source.length)
      else if source.identity == target.identity then
        .error (.sourceEqualsTarget groupIndex sourceIndex)
      else validateSources groupIndex target (sourceIndex + 1) rest

/-- Second loop of the bus entrypoint, preserving target-before-source and
length-before-equality error precedence. -/
def validatePubkeys : Nat → List PublisherGroup → Except BusAddError Unit
  | _, [] => .ok ()
  | groupIndex, group :: rest =>
      if group.target.length != pubkeyLength then
        .error (.invalidTargetLength groupIndex group.target.length)
      else match validateSources groupIndex group.target 0 group.sources with
        | .error err => .error err
        | .ok () => validatePubkeys (groupIndex + 1) rest

/-- Pure validation prefix of `ConsolidationBus.addConsolidationRequests`.
The pending-batch lookup/write follows this result in the stateful layer. -/
def validateBusAdd (batchSize maxGroups : Nat)
    (groups : List PublisherGroup) : Except BusAddError Nat := do
  if groups.isEmpty then throw .emptyBatch
  if groups.length > maxGroups then throw (.tooManyGroups groups.length maxGroups)
  let totalCount ← countSources groups
  if totalCount > batchSize then throw (.batchTooLarge totalCount batchSize)
  validatePubkeys 0 groups
  pure totalCount

/-- `ConsolidationGateway._prepareConsolidationPairs`: sources stay in nested
source order and each group's target is repeated once per source. -/
def preparePairs (groups : List WitnessGroup) : List (Pubkey × Pubkey) :=
  groups.flatMap fun group => group.sources.map fun source => (source, group.target)

/-- First array returned by `_prepareConsolidationPairs`. -/
def preparedSources (groups : List WitnessGroup) : List Pubkey :=
  groups.flatMap (·.sources)

/-- Second array returned by `_prepareConsolidationPairs`. -/
def preparedTargets (groups : List WitnessGroup) : List Pubkey :=
  groups.flatMap fun group => List.replicate group.sources.length group.target

inductive VaultError where
  | zeroSources
  | arraysLengthMismatch (sources targets : Nat)
  | feeOverflow
  | incorrectFee (required provided : Word)
  | invalidSourceLength (index actual : Nat)
  | invalidTargetLength (index actual : Nat)
  deriving DecidableEq, Repr

private def checkedMulWord (a : Nat) (b : Word) : Option Word :=
  if h : a * b.val < 2 ^ 256 then
    some ⟨a * b.val, h⟩
  else none

private def validateVaultPairs : Nat → List (Pubkey × Pubkey) →
    Except VaultError Unit
  | _, [] => .ok ()
  | index, pair :: rest =>
      if pair.1.length != pubkeyLength then
        .error (.invalidSourceLength index pair.1.length)
      else if pair.2.length != pubkeyLength then
        .error (.invalidTargetLength index pair.2.length)
      else validateVaultPairs (index + 1) rest

/-- Pure guards of `_addConsolidationRequests`, including checked fee
multiplication and the exact-fee check before per-pair key validation. -/
def validateVaultAdd (fee msgValue : Word) (sources targets : List Pubkey) :
    Except VaultError (List (Pubkey × Pubkey)) := do
  if sources.isEmpty then throw .zeroSources
  if sources.length != targets.length then
    throw (.arraysLengthMismatch sources.length targets.length)
  let required ← match checkedMulWord sources.length fee with
    | some required => pure required
    | none => throw .feeOverflow
  if required != msgValue then throw (.incorrectFee required msgValue)
  let pairs := sources.zip targets
  validateVaultPairs 0 pairs
  pure pairs

theorem preparePairs_length (groups : List WitnessGroup) :
    (preparePairs groups).length = (groups.map (·.sources.length)).sum := by
  simp [preparePairs]

theorem preparePairs_sources (groups : List WitnessGroup) :
    (preparePairs groups).map Prod.fst = preparedSources groups := by
  unfold preparedSources
  simp [preparePairs, List.map_flatMap, Function.comp_def]

private theorem map_pair_snd (sources : List Pubkey) (target : Pubkey) :
    (sources.map fun source => (source, target)).map Prod.snd =
      List.replicate sources.length target := by
  induction sources with
  | nil => rfl
  | cons source rest ih =>
      simp only [List.map_cons, List.length_cons]
      rw [ih, List.replicate_succ]

theorem preparePairs_targets (groups : List WitnessGroup) :
    (preparePairs groups).map Prod.snd = preparedTargets groups := by
  induction groups with
  | nil => rfl
  | cons group rest ih =>
      change
        ((group.sources.map fun source => (source, group.target)) ++
          preparePairs rest).map Prod.snd =
        List.replicate group.sources.length group.target ++ preparedTargets rest
      rw [List.map_append, map_pair_snd, ih]

/-- Universal gateway-to-vault array correspondence: flattening the groups
as pairs is exactly zipping the two arrays passed to the withdrawal vault. -/
theorem prepared_zip (groups : List WitnessGroup) :
    (preparedSources groups).zip (preparedTargets groups) = preparePairs groups := by
  rw [← preparePairs_sources, ← preparePairs_targets]
  simpa [List.unzip_eq_map] using List.zip_unzip (preparePairs groups)

end audit.trio.consolidation
