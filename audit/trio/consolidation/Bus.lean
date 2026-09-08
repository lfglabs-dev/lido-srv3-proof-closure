import audit.trio.consolidation.Spec

/-!
# ConsolidationBus stateful source specification

Independent executable semantics for the stateful portions of
`ConsolidationBus.addConsolidationRequests` and `executeConsolidation` at the
pinned source revision. Hashing and the downstream gateway are explicit
oracles. This exposes, rather than assumes away, the correspondence condition
that the witness groups reconstruct the publisher's batch hash.
-/

namespace audit.trio.consolidation

abbrev Address := Nat
abbrev BatchHash := Nat

structure BatchInfo where
  publisher : Address
  addedAt : Nat
  deriving DecidableEq, Repr

structure BusState where
  pending : BatchHash → Option BatchInfo

def emptyBusState : BusState := ⟨fun _ => none⟩

def BusState.writePending (state : BusState) (hash : BatchHash)
    (info : BatchInfo) : BusState :=
  ⟨fun key => if key = hash then some info else state.pending key⟩

def BusState.deletePending (state : BusState) (hash : BatchHash) : BusState :=
  ⟨fun key => if key = hash then none else state.pending key⟩

structure HashOracle where
  hash : List PublisherGroup → BatchHash

def publisherGroups (groups : List WitnessGroup) : List PublisherGroup :=
  groups.map fun group => ⟨group.sources, group.target⟩

inductive AddError where
  | accessDenied
  | validation (error : BusAddError)
  | batchAlreadyPending (hash : BatchHash)
  deriving DecidableEq, Repr

structure RequestsAdded where
  publisher : Address
  groups : List PublisherGroup
  hash : BatchHash
  deriving DecidableEq, Repr

inductive AddOutcome where
  | reverted (error : AddError) (state : BusState)
  | committed (state : BusState) (event : RequestsAdded)

/-- `ConsolidationBus.addConsolidationRequests`, including `onlyRole`, all
pure guards, hash derivation, duplicate lookup, pending write, and event. -/
def addConsolidationRequests (oracle : HashOracle) (hasPublishRole : Bool)
    (publisher now batchSize maxGroups : Nat) (groups : List PublisherGroup)
    (state : BusState) : AddOutcome :=
  if !hasPublishRole then .reverted .accessDenied state
  else match validateBusAdd batchSize maxGroups groups with
    | .error error => .reverted (.validation error) state
    | .ok _ =>
        let hash := oracle.hash groups
        match state.pending hash with
        | some _ => .reverted (.batchAlreadyPending hash) state
        | none =>
            let info := { publisher := publisher, addedAt := now }
            .committed (state.writePending hash info)
              { publisher := publisher, groups := groups, hash := hash }

inductive ExecuteError where
  | batchNotFound (hash : BatchHash)
  | timestampOverflow
  | executionDelayNotPassed (current executeAfter : Nat)
  | gatewayReverted
  deriving DecidableEq, Repr

structure GatewayCall where
  groups : List WitnessGroup
  refundRecipient : Address
  value : Word
  deriving DecidableEq, Repr

structure RequestsExecuted where
  hash : BatchHash
  feePaid : Word
  deriving DecidableEq, Repr

inductive ExecuteOutcome where
  | reverted (error : ExecuteError) (state : BusState)
  | committed (state : BusState) (call : GatewayCall) (event : RequestsExecuted)

private def checkedTimestampAdd (addedAt delay : Nat) : Option Nat :=
  if addedAt + delay < 2 ^ 256 then some (addedAt + delay) else none

/-- `ConsolidationBus.executeConsolidation`. A false `gatewayAccepts` models
a reverting downstream call. Although Solidity deletes the pending entry
before that call, EVM transaction rollback restores the entry, represented by
the original `state` in the revert arm. -/
def executeConsolidation (oracle : HashOracle) (gatewayAccepts : Bool)
    (caller now delay : Nat) (msgValue : Word) (groups : List WitnessGroup)
    (state : BusState) : ExecuteOutcome :=
  let publisherBatch := publisherGroups groups
  let hash := oracle.hash publisherBatch
  match state.pending hash with
  | none => .reverted (.batchNotFound hash) state
  | some batch =>
      match checkedTimestampAdd batch.addedAt delay with
      | none => .reverted .timestampOverflow state
      | some executeAfter =>
          if now < executeAfter then
            .reverted (.executionDelayNotPassed now executeAfter) state
          else if !gatewayAccepts then
            .reverted .gatewayReverted state
          else
            .committed (state.deletePending hash)
              { groups := groups, refundRecipient := caller, value := msgValue }
              { hash := hash, feePaid := msgValue }

theorem add_revert_restores (oracle : HashOracle) (role : Bool)
    (publisher now batchSize maxGroups : Nat) (groups : List PublisherGroup)
    (state rollback : BusState) (error : AddError)
    (h : addConsolidationRequests oracle role publisher now batchSize maxGroups
      groups state = .reverted error rollback) :
    rollback = state := by
  cases role <;> simp [addConsolidationRequests] at h
  · exact h.2.symm
  · cases hv : validateBusAdd batchSize maxGroups groups with
    | error validationError =>
        simp [hv] at h
        exact h.2.symm
    | ok total =>
        cases hp : state.pending (oracle.hash groups) with
        | none => simp [hv, hp] at h
        | some info =>
            simp [hv, hp] at h
            exact h.2.symm

theorem execute_revert_restores (oracle : HashOracle) (gatewayAccepts : Bool)
    (caller now delay : Nat) (msgValue : Word) (groups : List WitnessGroup)
    (state rollback : BusState) (error : ExecuteError)
    (h : executeConsolidation oracle gatewayAccepts caller now delay msgValue
      groups state = .reverted error rollback) :
    rollback = state := by
  cases hp : state.pending (oracle.hash (publisherGroups groups)) with
  | none =>
      simp [executeConsolidation, hp] at h
      exact h.2.symm
  | some batch =>
      cases ht : checkedTimestampAdd batch.addedAt delay with
      | none =>
          simp [executeConsolidation, hp, ht] at h
          exact h.2.symm
      | some executeAfter =>
          by_cases hearly : now < executeAfter
          · simp [executeConsolidation, hp, ht, hearly] at h
            exact h.2.symm
          · cases gatewayAccepts <;>
            simp [executeConsolidation, hp, ht, hearly] at h
            · exact h.2.symm

theorem execute_committed_deletes (oracle : HashOracle)
    (gatewayAccepts : Bool) (caller now delay : Nat) (msgValue : Word)
    (groups : List WitnessGroup) (before after : BusState)
    (call : GatewayCall) (event : RequestsExecuted)
    (h : executeConsolidation oracle gatewayAccepts caller now delay msgValue
      groups before = .committed after call event) :
    after.pending (oracle.hash (publisherGroups groups)) = none := by
  cases hp : before.pending (oracle.hash (publisherGroups groups)) with
  | none => simp [executeConsolidation, hp] at h
  | some batch =>
      cases ht : checkedTimestampAdd batch.addedAt delay with
      | none => simp [executeConsolidation, hp, ht] at h
      | some executeAfter =>
          by_cases hearly : now < executeAfter
          · simp [executeConsolidation, hp, ht, hearly] at h
          · cases gatewayAccepts
            · simp [executeConsolidation, hp, ht, hearly] at h
            · simp [executeConsolidation, hp, ht, hearly] at h
              rw [← h.1]
              simp [BusState.deletePending]

end audit.trio.consolidation
