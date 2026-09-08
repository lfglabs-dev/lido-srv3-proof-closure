import LidoSRv3.Audit.Source.TopupCorrespondence
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import Contracts.Common

/-!
# Faithful executable P-TOPUP-1 transaction

An independent `Contract.run` program for the pinned `StakingRouter.topUp`
observable flow.  It does not call `SolidityTopup.run` or
`SolidityTopupParent.sourceExecute`.

Both value-moving hops run through Verity's own external-call frame
primitive, `Contracts.externalCallBindTo`: the frame checks the caller can
pay, debits `selfBalance`, and *itself* appends the journal entry recording
destination, wei value, and argument words.  Nothing here appends a
pre-built journal, so the call sequence in `ContractState.calls` is produced
by execution and the correspondence theorem below has to derive it.

Allocation amounts are materialized with `writeMapUint` and the running
aggregate with `writeSlot`.  Failure schedules revert after real intermediate
writes and real journalled frames, exposing transaction rollback.
Correspondence compares outcome observables, never full post-states.
-/

namespace LidoSRv3.Audit.Verity.TopupTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-- Observation slots, no Solidity storage counterpart: `allocations[i]`,
`amount` (`StakingRouter.sol:717-732`, memory and stack) and the pulled total
are persisted so the transaction boundary can be observed. -/
def allocationSlot : Nat := 7100
def allocationTotalSlot : Nat := 7101
def pulledTotalSlot : Nat := 7102

/-- Placeholder address for `LIDO` (`StakingRouter.sol:744`); a model pin, not
the deployed Lido address. -/
def lidoAddress : Address := (0xF00D : Address)
/-- `DEPOSIT_CONTRACT` (`StakingRouter.sol:750`), the canonical beacon deposit
contract address. This is a source pin only: constructor assignment / deployed
provenance remains deliberately OPEN (A-TOPUP-BEACON-ADDRESS). -/
def beaconAddress : Address := (0x00000000219ab540356cBB839Cbe05303d7705Fa : Address)

/-- The four arguments of the Beacon-chain deposit precompile call at
`BeaconChainDepositor.sol:106`.  They are deliberately a call-plane value,
rather than an index/amount projection: the journal must retain the exact
public key, withdrawal credentials, signature, and SSZ deposit-data root that
the source hands to `IDepositContract.deposit`.

The fields are word commitments in this Verity call plane; their byte-width,
SSZ construction, and root correspondence are discharged by P-SSZ-1. -/
structure BeaconDepositCall where
  pubkey : Nat
  withdrawalCredentials : Nat
  signature : Nat
  depositDataRoot : Nat
  deriving Repr, DecidableEq

inductive FailurePoint where
  | none
  | afterAllocationWrite
  | afterLidoPull
  | afterFirstBeaconPush
  deriving Repr, DecidableEq

/-! ## Source-shaped schedule

Read off the pinned source's `allocations` array alone.  `execute` below
never consults these definitions; they are the specification side of the
correspondence. -/

/-- The push schedule of the pinned source's loop: one entry per nonzero
allocation carrying its index and wei.  The `if amount = 0` skip is the
`continue` at `BeaconChainDepositor.sol` line 89; the retained pair is the
transfer at line 106. -/
def sourcePushes : List Nat → Nat → List (Nat × Nat)
  | [], _ => []
  | amount :: rest, index =>
      if amount = 0 then sourcePushes rest (index + 1)
      else (index, amount) :: sourcePushes rest (index + 1)

/-- Calldata and call values are 256-bit EVM words, so the schedule states
them reduced.  Only the loop index needs this: `A-TOPUP-NOWRAP` already
bounds every wei amount. -/
def evmWord (n : Nat) : Nat := n % Core.Uint256.modulus

/-! ## Executable transaction -/

/-- Source-shaped allocation loop (`StakingRouter.sol:722-734` without its
guards, which `guardLoop` below carries), expressed solely with Verity storage. -/
def allocationPass : List Nat → Nat → Nat → ContractState → ContractState
  | [], _, total, state => state.writeSlot allocationTotalSlot total
  -- StakingRouter.sol:732  amount += allocations[i];  (materialised per index and as a running slot)
  | amount :: rest, index, total, state =>
      allocationPass rest (index + 1) (total + amount)
        ((state.writeMapUint allocationSlot index amount).writeSlot
          allocationTotalSlot (total + amount))

/-- The allocation loop as a transaction step, with the pull slot zeroed. -/
def allocationStage (allocations : List Nat) : Contract Unit := fun state =>
  .success () ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0)

/-- Real external-call frame: the zero-value Lido pull at `StakingRouter.sol:744`.
`externalCallBindTo` journals the destination and argument word itself. -/
def lidoPull (total : Nat) : Contract Unit :=
  -- StakingRouter.sol:744  LIDO.withdrawDepositableEther(amount, 0);
  externalCallBindTo lidoAddress 0 [] "withdrawDepositableEther"
    ([(total : Uint256)] : List Uint256)

/-- The wei `withdrawDepositableEther` hands back.  `externalCallBindTo` is a
caller-side frame: it debits, journals, and binds, but callee-originated
inflow is outside its remit (callee state lives in `Verity.MultiContract`), so
the credit is an explicit step. -/
def creditPull (total : Nat) : Contract Unit := fun state =>
  -- Lido.sol:885  stakingRouter.receiveDepositableEther.value(_amount)();
  .success ()
    (({ state with selfBalance := state.selfBalance + (total : Uint256) }).writeSlot
      pulledTotalSlot (total : Uint256))

/-- Real external-call frame: one value-bearing beacon push.  The frame fails
closed when the router cannot pay, so a push is gated on funds actually held. -/
def scheduledBeaconPush (deposit : BeaconDepositCall) (amount : Nat) : Contract Unit :=
  -- BeaconChainDepositor.sol:106  _depositContract.deposit{value: amount}(pk, _withdrawalCredentials, dummySignature, depositDataRoot);
  externalCallBindTo beaconAddress (amount : Uint256) [] "deposit"
    ([(deposit.pubkey : Uint256), (deposit.withdrawalCredentials : Uint256),
      (deposit.signature : Uint256), (deposit.depositDataRoot : Uint256)] : List Uint256)

/-- Compatibility schedule used by the allocation-only executable slice.  It
is not a source of provenance or SSZ data.  The faithful call constructor is
`scheduledBeaconPush`, whose journal takes all four pinned deposit fields directly. -/
def scheduledDeposit (index amount : Nat) : BeaconDepositCall :=
  { pubkey := index, withdrawalCredentials := 0, signature := 0,
    depositDataRoot := amount }

/-! ### Why the legacy schedule cannot be promoted to a source derivation

`makeBeaconChainTopUp` receives byte strings, not validator indices.  The
source-shaped deposit-data-root model consequently gives us enough information
to build a call value directly from those bytes (and from the source root), but
the older `execute` slice has only an allocation list.  The following small
counterexample is deliberately executable evidence of that loss of information:
at allocation index zero the legacy schedule always emits public-key word zero,
whereas a valid pinned-source input can carry a nonzero first public-key byte.

This does not add a premise to the legacy theorem.  It records the obstruction
instead: `execute`/`executeGuarded` cannot be claimed to derive SSZ calldata
until their input surface is extended with the source byte inputs and the
withdrawal-credentials derivation. -/

/-- A word-level commitment to a Solidity `bytes` argument for the legacy
word-journal.  It is retained only for the diagnostic counterexample below;
the executable source-byte path uses `sourceBeaconCalldata` instead. -/
def sourceByteCommitment (bytes : List Nat) : Nat :=
  bytes.foldl (fun acc byte => acc * 256 + byte) 0

def sourceDerivedDeposit (input : SourceDepositDataRootInput) : BeaconDepositCall :=
  { pubkey := sourceByteCommitment input.publicKey
    withdrawalCredentials := sourceByteCommitment input.withdrawalCredentials
    signature := sourceByteCommitment input.signature
    depositDataRoot := sourceByteCommitment (computeDepositDataRootWithAmount input).bytes }

/-! ### Source-byte beacon call plane

The legacy `BeaconDepositCall` is a four-word observation and is intentionally
not used below.  Solidity passes three dynamic `bytes` arguments to
`IDepositContract.deposit`; the following encoding retains their bytes and the
root bytes derived by `_computeDepositDataRootWithAmount`.

`ExternalCall.calldata` is a word journal, so the selector occupies one
distinguished journal word and every subsequent word is a 32-byte ABI word.
This is an executable representation of the canonical ABI byte stream, not a
projection to validator indices or allocation amounts. -/

def abiWordOfBytes (bytes : List Nat) : Uint256 :=
  let chunk := bytes.take 32
  let padded : Nat := sourceByteCommitment chunk * 256 ^ (32 - chunk.length)
  (padded : Uint256)

def abiByteWords (bytes : List Nat) : List Uint256 :=
  (List.range ((bytes.length + 31) / 32)).map
    (fun index => abiWordOfBytes (bytes.drop (index * 32)))

def abiBytesTail (bytes : List Nat) : List Uint256 :=
  (bytes.length : Uint256) :: abiByteWords bytes

/-- Canonical tail of a `bytes[]`: an array length, element offsets relative
to the word after that length, then each length-and-padded-bytes element. -/
def abiBytesArrayOffsets : List (List Uint256) → Nat → List Uint256
  | [], _ => []
  | tail :: tails, offset => (offset : Uint256) ::
      abiBytesArrayOffsets tails (offset + tail.length * 32)

def abiBytesArrayTail (values : List (List Nat)) : List Uint256 :=
  let tails := values.map abiBytesTail
  (values.length : Uint256) ::
    abiBytesArrayOffsets tails (values.length * 32) ++ tails.flatten

/-- `deposit(bytes,bytes,bytes,bytes32)` (the precompile interface at the
pinned BeaconChainDepositor call site). -/
def beaconDepositSelector : Uint256 := (0x22895118 : Uint256)

/-- The value constructed by `new bytes(SIGNATURE_LENGTH)` at pinned
`BeaconChainDepositor.sol:76`.  Keeping this constructor separate from the
ABI encoder prevents a caller-selected signature from entering the top-up
call plane. -/
def dummySignature : List Nat := List.replicate 96 0

/-- Exact source widths checked by `_validateTopUpInputs` and
`makeBeaconChainTopUp`, plus the fixed dummy signature created by the latter.
This is intentionally stronger than the byte-range proofs carried by
`SourceDepositDataRootInput`. -/
def PinnedTopupFields (input : SourceDepositDataRootInput) : Prop :=
  input.withdrawalCredentials.length = 32 ∧
  input.publicKey.length = 48 ∧
  input.signature = dummySignature

/-- Canonical ABI words for the source call at `BeaconChainDepositor.sol:106`.
The three head offsets are byte offsets from the first head word; the final
head is the derived `bytes32` root. -/
def sourceBeaconCalldata (input : SourceDepositDataRootInput) : List Uint256 :=
  let pkTail := abiBytesTail input.publicKey
  let wcTail := abiBytesTail input.withdrawalCredentials
  let sigTail := abiBytesTail input.signature
  let headBytes := 4 * 32
  let pkOffset := headBytes
  let wcOffset := pkOffset + pkTail.length * 32
  let sigOffset := wcOffset + wcTail.length * 32
  [beaconDepositSelector, (pkOffset : Uint256), (wcOffset : Uint256),
    (sigOffset : Uint256),
    abiWordOfBytes (computeDepositDataRootWithAmount input).bytes] ++
    pkTail ++ wcTail ++ sigTail

/-- Faithful beacon frame: all deposit arguments are read from one pinned
source deposit input, and the root is computed from that same input. -/
def beaconPush (input : SourceDepositDataRootInput) (amount : Nat) : Contract Unit :=
  externalCallBindTo beaconAddress (amount : Uint256) [] "deposit"
    (sourceBeaconCalldata input)

/-- `BeaconChainDepositor.sol:79-107` with its source-byte inputs retained.
An allocation can reach `deposit` only when it has a corresponding source
input; the registered constructor below sets its `amountGwei` to the
allocation divided by the pinned `1 gwei` unit. Extra or missing keys fail closed, matching the
source's array-length boundary rather than inventing a scheduled deposit. -/
def sourcePushLoop : List SourceDepositDataRootInput → List Nat → Contract Unit
  | [], [] => Verity.pure ()
  | [], _ :: _ => require false "SourceDepositLengthMismatch"
  | _ :: _, [] => require false "SourceDepositLengthMismatch"
  | input :: inputs, amount :: amounts => do
      if amount = 0 then sourcePushLoop inputs amounts
      else do
        beaconPush input amount
        sourcePushLoop inputs amounts

/-- Source-derived executable value tail. This is deliberately separate from
the allocation-only legacy `execute`: its deposit frames consume the source
bytes and source-computed root, never `scheduledDeposit`. -/
def executeSourceDerived (deposits : List SourceDepositDataRootInput)
    (allocations : List Nat) (failure : FailurePoint) : Contract Unit := do
  allocationStage allocations
  require (decide (failure ≠ .afterAllocationWrite)) "FAIL_AFTER_ALLOCATION_WRITE"
  let total := allocSumUnchecked allocations
  if total = 0 then Verity.pure ()
  else do
    lidoPull total
    creditPull total
    require (decide (failure ≠ .afterLidoPull)) "FAIL_AFTER_LIDO_PULL"
    sourcePushLoop deposits allocations

private def nonzeroPubkeySourceInput : SourceDepositDataRootInput :=
  { withdrawalCredentials := List.replicate 32 0
    publicKey := 1 :: List.replicate 47 0
    signature := List.replicate 96 0
    amountGwei := 0
    withdrawalCredentialsBounded := by simp
    publicKeyBounded := by
      intro byte h
      simp only [List.mem_cons, List.mem_replicate] at h
      rcases h with h | h
      · subst byte; decide
      · simpa [h.2]
    signatureBounded := by simp
    amountGweiBounded := by decide }

set_option maxRecDepth 100000 in
/-- Concrete source-derived counterexample to replacing the legacy placeholder
with a derivation without changing the transaction input. -/
theorem scheduledDeposit_not_sourceDerived :
    (scheduledDeposit 0 0).pubkey ≠
      (sourceDerivedDeposit nonzeroPubkeySourceInput).pubkey := by
  have fold_zeros_positive : ∀ n acc : Nat, 0 < acc →
      0 < List.foldl (fun acc byte => acc * 256 + byte) acc (List.replicate n 0) := by
    intro n acc hacc
    induction n generalizing acc with
    | zero => simpa
    | succ n ih =>
        simp only [List.replicate_succ, List.foldl_cons]
        exact ih (acc * 256) (Nat.mul_pos hacc (by decide))
  have hpositive : 0 <
      List.foldl (fun acc byte => acc * 256 + byte) 1 (List.replicate 47 0) :=
    fold_zeros_positive 47 1 (by decide)
  change 0 ≠ List.foldl (fun acc byte => acc * 256 + byte) 1 (List.replicate 47 0)
  exact Nat.ne_of_lt hpositive

/-- The *value/journal* push loop of `BeaconChainDepositor.sol:79-107` (reached
from `StakingRouter.sol:750`): one real `externalCallBindTo` frame per nonzero
amount. Zero allocations are skipped exactly as `BeaconChainDepositor.sol:89`
does. `stopAfterFirst` injects a failure once the first frame has really
debited and journalled.

Not to be confused with `SolidityTopup.pushLoop` (same name, different
namespace), which is the *guard* loop of the same Solidity lines (pubkey length,
`MIN_DEPOSIT`, `uint64` bound) and moves no value; the executable guard side
lives in `guardLoop` and `executeGuarded` below.

Not transcribed: `BeaconChainDepositor.sol:82-84, 92-94, 97-99` guards (see
`SolidityTopup.pushLoop`), `:103-104` (SSZ root, P-SSZ-1). -/
def pushLoop (stopAfterFirst : Bool) : List Nat → Nat → Contract Unit
  -- BeaconChainDepositor.sol:79  for (uint256 i; i < len; ++i) {  (loop exit)
  | [], _ => Verity.pure ()
  | amount :: rest, index =>
      -- BeaconChainDepositor.sol:89  if (amount == 0) continue;
      if amount = 0 then pushLoop stopAfterFirst rest (index + 1)
      else do
        -- BeaconChainDepositor.sol:106  _depositContract.deposit{value: amount}(...)
        scheduledBeaconPush (scheduledDeposit index amount) amount
        -- Added by the model: failure hook after the first real frame.
        require (!stopAfterFirst) "FAIL_AFTER_FIRST_BEACON_PUSH"
        pushLoop stopAfterFirst rest (index + 1)

/-- `StakingRouter.sol:742-756`: pull the aggregate from Lido, then forward
every non-zero allocation to the deposit contract.  Both legs go through real
`externalCallBindTo` frames, so the journal is produced by execution rather
than asserted.

Not transcribed (Lido guards not modelled here): `Lido.sol:870`
(`require(canDeposit(), "CAN_NOT_DEPOSIT")`), `:872` (`_auth`), `:873`
(`require(_amount != 0, "ZERO_AMOUNT")`), `:842`
(`require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER")`) and the
buffer accounting `:846-858`; the frame's own success is the only Lido-side
failure (`lidoStub`). Also not transcribed: `StakingRouter.sol:742/752/755`
(balance snapshots and the assert; `execute_ends_with_zero_balance` is the
executable reading), `:746-747` (withdrawal credentials).

Added by the model: `creditPull` (callee inflow made explicit) and the
`require (failure ≠ .afterLidoPull)` hook, a rollback probe placed after the
journalled pull. -/
def pushStage (allocations : List Nat) (total : Nat) (failure : FailurePoint) :
    Contract Unit := do
  -- StakingRouter.sol:744  LIDO.withdrawDepositableEther(amount, 0);
  lidoPull total
  -- Lido.sol:885  stakingRouter.receiveDepositableEther.value(_amount)();
  creditPull total
  -- Added by the model: failure hook after the pull.
  require (decide (failure ≠ .afterLidoPull)) "FAIL_AFTER_LIDO_PULL"
  -- StakingRouter.sol:750  BeaconChainDepositor.makeBeaconChainTopUp(DEPOSIT_CONTRACT, wcBytes, _pubkeys, allocations);
  pushLoop (failure = .afterFirstBeaconPush) allocations 0

/-- `StakingRouter.sol:722-756` (the suffix of `topUp` from the accumulator
loop on) as an executable Verity transaction over a free `allocations` list.
Every failure point sits *after* real storage writes and, past the first, after
real journalled call frames; `Contract.run` supplies the transaction boundary
that restores the snapshot.

Not transcribed: `StakingRouter.sol:686-718` (authentication, input validation,
module guards and the module call; `executeGuarded` below adds the call and the
`:724/728/737` guards), `:758` (event).

Added by the model: `allocationStage` slots and the `failure` schedule. -/
def execute (allocations : List Nat) (failure : FailurePoint) : Contract Unit := do
  -- StakingRouter.sol:722-734  unchecked { for (...) { amount += allocations[i]; } }  (guards elsewhere)
  allocationStage allocations
  -- Added by the model: failure hook after the allocation writes.
  require (decide (failure ≠ .afterAllocationWrite)) "FAIL_AFTER_ALLOCATION_WRITE"
  -- StakingRouter.sol:732  amount  (wrapped reading, see the TopupCorrespondence name table)
  let total := allocSumUnchecked allocations
  -- StakingRouter.sol:741  if (amount > 0) {
  if total = 0 then Verity.pure ()
  else pushStage allocations total failure

/-! ## Observables -/

/-- Everything a caller can observe at the transaction boundary: the
per-allocation mapping words, the aggregate slots, and the external-call
journal projected onto destination, wei value, argument words, and order. -/
@[ext] structure OutcomeObservables where
  committed : Bool
  allocationCells : List Nat
  allocationTotal : Nat
  pulled : Nat
  pushed : Nat
  callNames : List String
  callTargets : List Nat
  callValues : List Nat
  callArgs : List (List Nat)
  deriving Repr, DecidableEq

def callValueOf (name : String) : List ExternalCall → Nat
  | [] => 0
  | call :: rest => (if call.name == name then call.value else 0) + callValueOf name rest

/-- The per-allocation mapping words, index-ordered. -/
def cellsOf (state : ContractState) (index count : Nat) : List Nat :=
  (List.range count).map
    (fun i => (state.readMapUint allocationSlot ((index + i : Nat) : Uint256)).val)

def observe (before : ContractState) (allocationCount : Nat) :
    ContractResult Unit → OutcomeObservables
  | .revert _ _ => ⟨false, [], 0, 0, 0, [], [], [], []⟩
  | .success _ after =>
      let fresh := after.calls.drop before.calls.length
      ⟨true, cellsOf after 0 allocationCount,
        (after.readSlot allocationTotalSlot).val,
        (after.readSlot pulledTotalSlot).val,
        callValueOf "deposit" fresh,
        fresh.map (·.name), fresh.map (·.target),
        fresh.map (·.value), fresh.map (·.calldata)⟩

/-- Independent source-shaped observable specification.

Totals are the on-chain wrapped reading `allocSumUnchecked` (`wrappedTotal =
exactTotal % 2^256`).  A wrap-to-zero batch is an empty success: no pull and
no pushes.  Under `NoUncheckedWrap` this coincides with the exact `Nat` sum. -/
def sourceObservables (allocations : List Nat) : OutcomeObservables :=
  let wrapped := allocSumUnchecked allocations
  let pushes := sourcePushes allocations 0
  ⟨true, allocations, wrapped, wrapped, wrapped,
    if wrapped = 0 then [] else
      "withdrawDepositableEther" :: pushes.map (fun _ => "deposit"),
    if wrapped = 0 then [] else
      lidoAddress.toNat :: pushes.map (fun _ => beaconAddress.toNat),
    if wrapped = 0 then [] else 0 :: pushes.map (fun p => evmWord p.2),
    if wrapped = 0 then [] else
      [evmWord wrapped] :: pushes.map (fun p => [evmWord p.1, 0, 0, evmWord p.2])⟩

/-! ## The journal execution has to produce

`pushEntry` and `expectedCalls` are stated from the source-shaped schedule.
`execute` does not mention them: the theorems below derive them from the
`externalCallBindTo` frames the transaction actually runs. -/

def pushEntry (p : Nat × Nat) : ExternalCall :=
  let deposit := scheduledDeposit p.1 p.2
  linkedCallEntryTo "deposit" beaconAddress (p.2 : Uint256)
    [(deposit.pubkey : Uint256), (deposit.withdrawalCredentials : Uint256),
      (deposit.signature : Uint256), (deposit.depositDataRoot : Uint256)]

def beaconJournal (allocations : List Nat) (index : Nat) : List ExternalCall :=
  (sourcePushes allocations index).map pushEntry

def pullEntry (total : Nat) : ExternalCall :=
  linkedCallEntryTo "withdrawDepositableEther" lidoAddress 0 [(total : Uint256)]

def expectedCalls (allocations : List Nat) : List ExternalCall :=
  if allocSumUnchecked allocations = 0 then []
  else pullEntry (allocSumUnchecked allocations) :: beaconJournal allocations 0

/-! ## Word and storage laws

Verity ships `readMapUint_writeMapUint_same` but no disjoint-key companion, so
the three lens laws the allocation loop needs are proved here. -/

theorem word_val {n : Nat} (h : n < uint256Modulus) : ((n : Uint256)).val = n :=
  Nat.mod_eq_of_lt h

theorem word_ne {a b : Nat} (ha : a < uint256Modulus) (hb : b < uint256Modulus)
    (hne : a ≠ b) : ((a : Uint256)) ≠ ((b : Uint256)) := fun h =>
  hne (by rw [← word_val ha, ← word_val hb, h])

theorem ofNat_val (x : Uint256) : ((x.val : Nat) : Uint256) = x :=
  Verity.Core.Uint256.ext (Nat.mod_eq_of_lt x.isLt)

theorem getD_eq (l : List Nat) {i : Nat} (hi : i < l.length) : l.getD i 0 = l[i] := by
  simp [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem hi]

theorem readMapUint_writeMapUint_other (state : ContractState) (mapSlot : Nat)
    {key key' : Uint256} (h : key' ≠ key) (value : Uint256) :
    (state.writeMapUint mapSlot key value).readMapUint mapSlot key' =
      state.readMapUint mapSlot key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, h]

theorem readMapUint_writeSlot (state : ContractState) (mapSlot wordSlot : Nat)
    (key value : Uint256) :
    (state.writeSlot wordSlot value).readMapUint mapSlot key =
      state.readMapUint mapSlot key := by
  simp [ContractState.readMapUint, ContractState.storageMapUint, ContractState.writeSlot]

theorem readSlot_writeMapUint (state : ContractState) (mapSlot wordSlot : Nat)
    (key value : Uint256) :
    (state.writeMapUint mapSlot key value).readSlot wordSlot = state.readSlot wordSlot := by
  simp [ContractState.readSlot, ContractState.storage, ContractState.writeMapUint]

/-! ## What the allocation loop does to storage -/

theorem allocationPass_calls : ∀ (l : List Nat) (index total : Nat) (state : ContractState),
    (allocationPass l index total state).calls = state.calls
  | [], _, _, _ => rfl
  | a :: rest, index, total, state => by
      rw [allocationPass]
      exact allocationPass_calls rest (index + 1) (total + a) _

theorem allocationPass_selfBalance :
    ∀ (l : List Nat) (index total : Nat) (state : ContractState),
      (allocationPass l index total state).selfBalance = state.selfBalance
  | [], _, _, _ => rfl
  | a :: rest, index, total, state => by
      rw [allocationPass]
      exact allocationPass_selfBalance rest (index + 1) (total + a) _

theorem allocationPass_total :
    ∀ (l : List Nat) (index total : Nat) (state : ContractState),
      (allocationPass l index total state).readSlot allocationTotalSlot
        = ((total + allocSum l : Nat) : Uint256)
  | [], _, total, state => by
      simp [allocationPass, allocSum, ContractState.readSlot_writeSlot_same]
  | a :: rest, index, total, state => by
      rw [allocationPass, allocationPass_total rest (index + 1) (total + a)]
      have : total + a + allocSum rest = total + allocSum (a :: rest) := by
        simp [allocSum]; omega
      rw [this]

/-- Writes made at indices at or above `index` leave a strictly smaller key
alone.  This is where the `Uint256` key encoding has to be injective, hence the
`index + l.length ≤ uint256Modulus` side condition. -/
theorem allocationPass_cell_untouched (l : List Nat) :
    ∀ (index total : Nat) (state : ContractState) (k : Nat),
      k < index → index + l.length ≤ uint256Modulus →
      (allocationPass l index total state).readMapUint allocationSlot ((k : Nat) : Uint256)
        = state.readMapUint allocationSlot ((k : Nat) : Uint256) := by
  induction l with
  | nil =>
      intro index total state k _ _
      simpa [allocationPass] using readMapUint_writeSlot state allocationSlot
        allocationTotalSlot ((k : Nat) : Uint256) ((total : Nat) : Uint256)
  | cons a rest ih =>
      intro index total state k hk hLen
      have hIndex : index < uint256Modulus := by simp [List.length_cons] at hLen; omega
      have hk' : k < uint256Modulus := Nat.lt_trans hk hIndex
      rw [allocationPass]
      rw [ih (index + 1) (total + a) _ k (Nat.lt_succ_of_lt hk)
        (by simp [List.length_cons] at hLen; omega)]
      rw [readMapUint_writeSlot, readMapUint_writeMapUint_other _ _
        (word_ne hk' hIndex (Nat.ne_of_lt hk))]

theorem allocationPass_cell (l : List Nat) :
    ∀ (index total : Nat) (state : ContractState) (i : Nat),
      i < l.length → index + l.length ≤ uint256Modulus →
      (allocationPass l index total state).readMapUint allocationSlot
          ((index + i : Nat) : Uint256)
        = ((l.getD i 0 : Nat) : Uint256) := by
  induction l with
  | nil => intro index total state i hi _; simp at hi
  | cons a rest ih =>
      intro index total state i hi hLen
      match i with
      | 0 =>
          rw [Nat.add_zero, allocationPass]
          rw [allocationPass_cell_untouched rest (index + 1) (total + a) _ index
            (Nat.lt_succ_self _) (by simp [List.length_cons] at hLen; omega)]
          rw [readMapUint_writeSlot, ContractState.readMapUint_writeMapUint_same]
          simp
      | j + 1 =>
          have hj : j < rest.length := by simp [List.length_cons] at hi; omega
          have hstep : index + (j + 1) = (index + 1) + j := by omega
          rw [hstep, allocationPass]
          rw [ih (index + 1) (total + a) _ j hj
            (by simp [List.length_cons] at hLen; omega)]
          simp

theorem cellsOf_allocationPass (l : List Nat) (total : Nat) (state : ContractState)
    (hLen : l.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ l, a < uint256Modulus) :
    cellsOf (allocationPass l 0 total state) 0 l.length = l := by
  apply List.ext_getElem
  · simp [cellsOf]
  · intro i h1 h2
    have hi : i < l.length := h2
    have hmem : l.getD i 0 ∈ l := by
      rw [getD_eq l hi]
      exact List.getElem_mem hi
    simp only [cellsOf, List.getElem_map, List.getElem_range]
    rw [allocationPass_cell l 0 total state i hi (by simpa using hLen)]
    rw [word_val (hAmt _ hmem), getD_eq l hi]

/-! ## What the external-call frames do

Nothing below assumes a journal.  `externalCallBindTo` is the only thing that
touches `ContractState.calls`, and these lemmas read the entries back off it. -/

theorem val_lt (x : Uint256) : x.val < uint256Modulus := x.isLt

theorem le_allocSum : ∀ {l : List Nat} {a : Nat}, a ∈ l → a ≤ allocSum l := by
  intro l
  induction l with
  | nil => intro a h; cases h
  | cons b rest ih =>
      intro a h
      rcases List.mem_cons.mp h with rfl | h'
      · simp [allocSum]
      · have := ih h'
        simp [allocSum]
        omega

theorem beaconStub : externalCallStubSuccess "deposit" = true := by decide

theorem lidoStub : externalCallStubSuccess "withdrawDepositableEther" = true := by decide

/-- One value-bearing frame: the balance check passes, `selfBalance` is debited
by exactly the allocation, and the frame appends exactly `pushEntry`. -/
theorem beaconPush_run (deposit : BeaconDepositCall) (amount : Nat) (state : ContractState)
    (hle : ((amount : Uint256)) ≤ state.selfBalance) :
    scheduledBeaconPush deposit amount state =
      ContractResult.success () { state with
        selfBalance := state.selfBalance - (amount : Uint256),
        calls := state.calls ++ [linkedCallEntryTo "deposit" beaconAddress (amount : Uint256)
          [(deposit.pubkey : Uint256), (deposit.withdrawalCredentials : Uint256),
            (deposit.signature : Uint256), (deposit.depositDataRoot : Uint256)]] } := by
  simp [scheduledBeaconPush, externalCallBindTo, hle, beaconStub, linkedCallEntryTo,
    linkedCallEntry, ExternalArg.toWords]

/-- The zero-value pull frame always passes the balance check and appends
exactly `pullEntry`. -/
theorem lidoPull_run (total : Nat) (state : ContractState) :
    lidoPull total state =
      ContractResult.success () { state with
        selfBalance := state.selfBalance - (0 : Uint256),
        calls := state.calls ++ [pullEntry total] } := by
  have hle : ((0 : Uint256)) ≤ state.selfBalance := by
    show (0 : Uint256).val ≤ state.selfBalance.val
    simp
  simp [lidoPull, externalCallBindTo, hle, lidoStub, pullEntry, linkedCallEntryTo,
    linkedCallEntry, ExternalArg.toWords]

/-- The push loop's journal is *derived*: each iteration's entry comes out of
`externalCallBindTo`, and the aggregate is exactly `beaconJournal`.  The only
hypothesis is that the router really holds the wei it is about to send, which is
what `creditPull` establishes. -/
theorem pushLoop_run (l : List Nat) :
    ∀ (index : Nat) (state : ContractState),
      allocSum l ≤ state.selfBalance.val →
      pushLoop false l index state =
        ContractResult.success () { state with
          selfBalance := ((state.selfBalance.val - allocSum l : Nat) : Uint256),
          calls := state.calls ++ beaconJournal l index } := by
  induction l with
  | nil =>
      intro index state _
      simp [pushLoop, beaconJournal, sourcePushes, allocSum, _root_.Verity.pure, ofNat_val]
  | cons a rest ih =>
      intro index state hbal
      have hsplit : allocSum (a :: rest) = a + allocSum rest := rfl
      by_cases ha : a = 0
      · subst ha
        rw [pushLoop, if_pos rfl, ih (index + 1) state (by omega)]
        simp [beaconJournal, sourcePushes, allocSum]
      · have haLe : a ≤ state.selfBalance.val := by omega
        have haLt : a < uint256Modulus :=
          Nat.lt_of_le_of_lt haLe (val_lt state.selfBalance)
        have hval : ((a : Uint256)).val = a := word_val haLt
        have hle : ((a : Uint256)) ≤ state.selfBalance := by
          show ((a : Uint256)).val ≤ state.selfBalance.val
          omega
        have hnext : (state.selfBalance - (a : Uint256)).val = state.selfBalance.val - a := by
          rw [Verity.Core.Uint256.sub_eq_of_le (by omega), hval]
        rw [pushLoop, if_neg ha]
        simp only [Bind.bind, _root_.Verity.bind,
          beaconPush_run (scheduledDeposit index a) a state hle]
        simp only [Bool.not_false, _root_.Verity.require, if_pos]
        rw [ih (index + 1) _ (by simp only [hnext]; omega)]
        have hbal2 : (state.selfBalance - (a : Uint256)).val - allocSum rest
            = state.selfBalance.val - allocSum (a :: rest) := by
          rw [hnext, hsplit]; omega
        have hjournal : beaconJournal (a :: rest) index
            = pushEntry (index, a) :: beaconJournal rest (index + 1) := by
          simp [beaconJournal, sourcePushes, ha]
        simp [hbal2, hjournal, pushEntry, scheduledDeposit]

/-- If every allocation is a uint256 word but their exact sum exceeds the
router's balance, the first unfundable nonzero allocation makes the real
external-call frame revert. -/
theorem pushLoop_reverts_of_insufficient (l : List Nat) :
    ∀ (index : Nat) (state : ContractState),
      (∀ a ∈ l, a < uint256Modulus) →
      state.selfBalance.val < allocSum l →
      ∃ reason dirty,
        pushLoop false l index state = ContractResult.revert reason dirty := by
  induction l with
  | nil =>
      intro index state _ hlt
      simp [allocSum] at hlt
  | cons a rest ih =>
      intro index state hAmt hlt
      by_cases ha : a = 0
      · subst a
        rw [pushLoop, if_pos rfl]
        apply ih (index + 1) state
        · intro x hx
          exact hAmt x (List.mem_cons_of_mem 0 hx)
        · simpa [allocSum] using hlt
      · have haLt : a < uint256Modulus := hAmt a List.mem_cons_self
        have hval : ((a : Uint256)).val = a := word_val haLt
        by_cases hleNat : a ≤ state.selfBalance.val
        · have hle : ((a : Uint256)) ≤ state.selfBalance := by
            show ((a : Uint256)).val ≤ state.selfBalance.val
            rw [hval]
            exact hleNat
          have hnext :
              (state.selfBalance - (a : Uint256)).val = state.selfBalance.val - a := by
            have hleVal : (Core.Uint256.ofNat a).val ≤ state.selfBalance.val := by
              rw [hval]
              exact hleNat
            rw [Verity.Core.Uint256.sub_eq_of_le hleVal, hval]
          have hrestLt :
              (state.selfBalance - (a : Uint256)).val < allocSum rest := by
            rw [hnext]
            simp only [allocSum] at hlt
            omega
          rcases ih (index + 1)
              { state with
                selfBalance := state.selfBalance - (a : Uint256)
                calls := state.calls ++ [pushEntry (index, a)] }
              (fun x hx => hAmt x (List.mem_cons_of_mem a hx)) hrestLt with
            ⟨reason, dirty, hrest⟩
          refine ⟨reason, dirty, ?_⟩
          rw [pushLoop, if_neg ha]
          simp only [Bind.bind, _root_.Verity.bind,
            beaconPush_run (scheduledDeposit index a) a state hle]
          simp only [Bool.not_false, _root_.Verity.require, if_pos]
          exact hrest
        · have hle : ¬ ((a : Uint256)) ≤ state.selfBalance := by
            intro h
            exact hleNat (by
              show a ≤ state.selfBalance.val
              rw [← hval]
              exact h)
          refine ⟨"insufficient balance", state, ?_⟩
          rw [pushLoop, if_neg ha]
          have hpush :
              scheduledBeaconPush (scheduledDeposit index a) a state =
                ContractResult.revert "insufficient balance" state := by
            simp [scheduledBeaconPush, Contracts.externalCallBindTo, hle]
          simp only [Bind.bind, _root_.Verity.bind, hpush]

/-- Pulling a word-sized wrapped total cannot fund allocations whose exact sum
is larger. The pull frame and credit execute, then the push loop reverts. -/
theorem pushStage_reverts_of_wrapped_underfunding (l : List Nat) (total : Nat)
    (st : ContractState)
    (hbal : st.selfBalance = 0)
    (hTotal : total < uint256Modulus)
    (hInsufficient : total < allocSum l)
    (hAmt : ∀ a ∈ l, a < uint256Modulus) :
    ∃ reason dirty,
      pushStage l total .none st = ContractResult.revert reason dirty := by
  let funded : ContractState :=
    (({ st with
          selfBalance := st.selfBalance - (0 : Uint256) + (total : Uint256)
          calls := st.calls ++ [pullEntry total] }).writeSlot
      pulledTotalSlot (total : Uint256))
  have hFunded : funded.selfBalance.val = total := by
    have hmod : Core.Uint256.modulus = uint256Modulus := by decide
    simp [funded, hbal, Core.Uint256.val_ofNat, hmod, Nat.mod_eq_of_lt hTotal]
  rcases pushLoop_reverts_of_insufficient l 0 funded hAmt (by
      rw [hFunded]
      exact hInsufficient) with ⟨reason, dirty, hLoop⟩
  refine ⟨reason, dirty, ?_⟩
  simp only [pushStage, Bind.bind, _root_.Verity.bind, lidoPull_run, creditPull,
    _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true, if_true,
    decide_false]
  exact hLoop

/-! ## Running the transaction -/

theorem cellsOf_writeSlot (state : ContractState) (wordSlot : Nat) (value : Uint256)
    (index count : Nat) :
    cellsOf (state.writeSlot wordSlot value) index count = cellsOf state index count := by
  simp [cellsOf, readMapUint_writeSlot]

theorem cellsOf_frame (state : ContractState) (balance : Uint256)
    (journal : List ExternalCall) (index count : Nat) :
    cellsOf { state with selfBalance := balance, calls := journal } index count
      = cellsOf state index count := rfl

theorem execute_run_zero (allocations : List Nat) (state : ContractState)
    (hZero : allocSumUnchecked allocations = 0) :
    (execute allocations .none).run state = ContractResult.success ()
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0) := by
  simp [execute, Contract.run, allocationStage, Bind.bind, _root_.Verity.bind,
    _root_.Verity.pure, _root_.Verity.require, hZero]

/-- The push loop spends exactly the balance the Lido pull credited, so the
contract ends the batch holding nothing.  This is the executable counterpart
of the `assert(address(this).balance == 0)` at the end of the Solidity
top-up. -/
theorem pushLoop_run_exact (l : List Nat) (index : Nat) (st : ContractState)
    (h : st.selfBalance.val = allocSum l) :
    pushLoop false l index st = ContractResult.success ()
      { st with selfBalance := 0, calls := st.calls ++ beaconJournal l index } := by
  rw [pushLoop_run l index st (Nat.le_of_eq h.symm), h, Nat.sub_self]
  rfl

theorem pushStage_run (l : List Nat) (st : ContractState)
    (hbal : st.selfBalance = 0) (hNoWrap : allocSum l < uint256Modulus) :
    pushStage l (allocSum l) .none st = ContractResult.success ()
      { st.writeSlot pulledTotalSlot ((allocSum l : Nat) : Uint256) with
        selfBalance := 0
        calls := st.calls ++ (pullEntry (allocSum l) :: beaconJournal l 0) } := by
  have hcredited :
      ((st.selfBalance - (0 : Uint256)) + ((allocSum l : Nat) : Uint256)).val = allocSum l := by
    rw [hbal, Verity.Core.Uint256.sub_zero, Verity.Core.Uint256.zero_add]
    exact word_val hNoWrap
  simp only [pushStage, Bind.bind, _root_.Verity.bind, lidoPull_run, creditPull,
    _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true, if_true,
    decide_false]
  rw [pushLoop_run_exact l 0 _ hcredited]
  show ContractResult.success ()
      { st.writeSlot pulledTotalSlot ((allocSum l : Nat) : Uint256) with
        selfBalance := 0
        calls := (st.calls ++ [pullEntry (allocSum l)]) ++ beaconJournal l 0 } = _
  rw [List.append_assoc]
  rfl

theorem execute_run_nonzero (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hNz : allocSum allocations ≠ 0) :
    (execute allocations .none).run state = ContractResult.success ()
      { ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).writeSlot
            pulledTotalSlot ((allocSum allocations : Nat) : Uint256) with
        selfBalance := 0
        calls := state.calls ++ expectedCalls allocations } := by
  have hEq : allocSumUnchecked allocations = allocSum allocations :=
    allocSumUnchecked_eq_allocSum hNoWrap
  have hNzW : allocSumUnchecked allocations ≠ 0 := by rw [hEq]; exact hNz
  have hstagedBal :
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).selfBalance = 0 := by
    show (allocationPass allocations 0 0 state).selfBalance = 0
    rw [allocationPass_selfBalance, hBalance]
  have hstagedCalls :
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls = state.calls :=
    allocationPass_calls _ _ _ _
  simp only [execute, Contract.run, allocationStage, Bind.bind, _root_.Verity.bind,
    _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true,
    if_true, hNzW, if_false]
  rw [hEq, pushStage_run allocations _ hstagedBal hNoWrap]
  rw [hstagedCalls, expectedCalls, hEq, if_neg hNz]

/-! ## Journal projections

The four projections below are what a caller sees of each recorded frame.
Everything is `rfl` against `linkedCallEntryTo`, so a misrouted destination, a
corrupted wei value, or a dropped argument word changes the observable. -/

theorem pushEntry_name (p : Nat × Nat) : (pushEntry p).name = "deposit" := rfl
theorem pushEntry_target (p : Nat × Nat) : (pushEntry p).target = beaconAddress.toNat := rfl
theorem pushEntry_value (p : Nat × Nat) : (pushEntry p).value = evmWord p.2 := rfl
theorem pushEntry_calldata (p : Nat × Nat) :
    (pushEntry p).calldata = [evmWord p.1, 0, 0, evmWord p.2] := by
  simp [pushEntry, scheduledDeposit, linkedCallEntryTo, linkedCallEntry,
    evmWord, uint256Modulus]

theorem pullEntry_name (total : Nat) :
    (pullEntry total).name = "withdrawDepositableEther" := rfl
theorem pullEntry_target (total : Nat) : (pullEntry total).target = lidoAddress.toNat := rfl
theorem pullEntry_value (total : Nat) : (pullEntry total).value = 0 := rfl
theorem pullEntry_calldata (total : Nat) : (pullEntry total).calldata = [evmWord total] := rfl

theorem callValueOf_beaconJournal :
    ∀ (l : List Nat) (index : Nat), (∀ a ∈ l, a < uint256Modulus) →
      callValueOf "deposit" (beaconJournal l index) = allocSum l
  | [], _, _ => rfl
  | a :: rest, index, hmem => by
      have hrest := callValueOf_beaconJournal rest (index + 1)
        (fun x hx => hmem x (List.mem_cons_of_mem _ hx))
      by_cases ha : a = 0
      · subst ha
        rw [beaconJournal, sourcePushes, if_pos rfl, ← beaconJournal, hrest, allocSum,
          Nat.zero_add]
      · have haLt : a < uint256Modulus := hmem a List.mem_cons_self
        have haCore : a < Core.Uint256.modulus := by
          norm_num [Core.Uint256.modulus]
          exact haLt
        rw [beaconJournal, sourcePushes, if_neg ha, List.map_cons, ← beaconJournal,
          callValueOf, hrest, pushEntry_name, pushEntry_value, allocSum]
        simp [evmWord, Nat.mod_eq_of_lt haCore]

theorem beaconJournal_names (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.name)
      = (sourcePushes l index).map (fun _ => "deposit") := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_name]

theorem beaconJournal_targets (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.target)
      = (sourcePushes l index).map (fun _ => beaconAddress.toNat) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_target]

theorem beaconJournal_values (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.value)
      = (sourcePushes l index).map (fun p => evmWord p.2) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_value]

theorem beaconJournal_calldata (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.calldata)
      = (sourcePushes l index).map (fun p => [evmWord p.1, 0, 0, evmWord p.2]) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_calldata]

/-! ## Composed correspondence -/

theorem readSlot_frame (state : ContractState) (balance : Uint256)
    (journal : List ExternalCall) (wordSlot : Nat) :
    ({ state with selfBalance := balance, calls := journal } : ContractState).readSlot wordSlot
      = state.readSlot wordSlot := rfl

/-- The executable Verity transaction, run through `Contract.run`, produces
exactly the observables the pinned Solidity top-up prescribes: the
per-allocation mapping words, both aggregate slots, and the external-call
journal down to destination address, wei value, argument words, and order. -/
theorem execute_observes_source (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hLen : allocations.length ≤ uint256Modulus) :
    observe state allocations.length ((execute allocations .none).run state)
      = sourceObservables allocations := by
  have hAmt : ∀ a ∈ allocations, a < uint256Modulus := fun a ha =>
    Nat.lt_of_le_of_lt (le_allocSum ha) hNoWrap
  have hOther : allocationTotalSlot ≠ pulledTotalSlot := by decide
  have hcells : cellsOf (allocationPass allocations 0 0 state) 0 allocations.length = allocations :=
    cellsOf_allocationPass allocations 0 state hLen hAmt
  have htotal : ((allocationPass allocations 0 0 state).readSlot allocationTotalSlot).val
      = allocSum allocations := by
    rw [allocationPass_total, Nat.zero_add]
    exact word_val hNoWrap
  have hEq : allocSumUnchecked allocations = allocSum allocations :=
    allocSumUnchecked_eq_allocSum hNoWrap
  have hcalls : ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls
      = state.calls := allocationPass_calls _ _ _ _
  by_cases hZero : allocSum allocations = 0
  · have hZeroW : allocSumUnchecked allocations = 0 := by rw [hEq]; exact hZero
    rw [execute_run_zero allocations state hZeroW]
    simp only [observe, sourceObservables, cellsOf_writeSlot, hcells,
      ContractState.readSlot_writeSlot_other _ hOther, htotal, hcalls, hEq, hZero,
      ContractState.readSlot_writeSlot_same, Verity.Core.Uint256.val_zero,
      List.drop_length, callValueOf, if_true, List.map_nil]
  · have hNzW : allocSumUnchecked allocations ≠ 0 := by rw [hEq]; exact hZero
    rw [execute_run_nonzero allocations state hBalance hNoWrap hZero]
    simp only [observe, sourceObservables, cellsOf_frame, cellsOf_writeSlot, hcells,
      readSlot_frame, ContractState.readSlot_writeSlot_same,
      ContractState.readSlot_writeSlot_other _ hOther,
      htotal, word_val hNoWrap, List.drop_left, expectedCalls, hEq, if_neg hZero,
      List.map_cons, pullEntry_name, pullEntry_target, pullEntry_value, pullEntry_calldata,
      beaconJournal_names, beaconJournal_targets, beaconJournal_values, beaconJournal_calldata,
      callValueOf, callValueOf_beaconJournal allocations 0 hAmt]
    simp [evmWord, Nat.mod_eq_of_lt hNoWrap]

/-- Entry frame for the composed guarantee: the router owns no ether of its
own when the batch starts, so `etherBalanceBeforeTopUp` at source line 743 is
zero and every wei the pushes move must come from the Lido pull. -/
def entryFrame (state : ContractState) : ContractState := { state with selfBalance := 0 }

theorem execute_observes_source_from_entry (allocations : List Nat) (state : ContractState)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hLen : allocations.length ≤ uint256Modulus) :
    observe (entryFrame state) allocations.length
        ((execute allocations .none).run (entryFrame state))
      = sourceObservables allocations :=
  execute_observes_source allocations (entryFrame state) rfl hNoWrap hLen

/-- Wrap-to-zero (and the ordinary zero batch) is an empty success: the
executable transaction writes the allocation cells, stores a wrapped total of
zero, and skips the pull/push. -/
theorem execute_observes_source_wrapped_zero (allocations : List Nat)
    (state : ContractState) (_hBalance : state.selfBalance = 0)
    (hZero : allocSumUnchecked allocations = 0)
    (hLen : allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    observe state allocations.length ((execute allocations .none).run state)
      = sourceObservables allocations := by
  have hOther : allocationTotalSlot ≠ pulledTotalSlot := by decide
  have hcells : cellsOf (allocationPass allocations 0 0 state) 0 allocations.length = allocations :=
    cellsOf_allocationPass allocations 0 state hLen hAmt
  have htotal : ((allocationPass allocations 0 0 state).readSlot allocationTotalSlot).val
      = allocSumUnchecked allocations := by
    rw [allocationPass_total, Nat.zero_add, allocSumUnchecked_eq_mod]
    have hmod : Core.Uint256.modulus = uint256Modulus := by decide
    simp [hmod, Core.Uint256.val_ofNat]
  have hcalls : ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls
      = state.calls := allocationPass_calls _ _ _ _
  rw [execute_run_zero allocations state hZero]
  simp only [observe, sourceObservables, cellsOf_writeSlot, hcells,
    ContractState.readSlot_writeSlot_other _ hOther, htotal, hcalls, hZero,
    ContractState.readSlot_writeSlot_same, Verity.Core.Uint256.val_zero,
    List.drop_length, callValueOf, if_true, List.map_nil]

theorem execute_observes_source_wrapped_zero_from_entry (allocations : List Nat)
    (state : ContractState) (hZero : allocSumUnchecked allocations = 0)
    (hLen : allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    observe (entryFrame state) allocations.length
        ((execute allocations .none).run (entryFrame state))
      = sourceObservables allocations :=
  execute_observes_source_wrapped_zero allocations (entryFrame state) rfl hZero hLen hAmt

/-- Every nonzero unchecked wrap fails closed, not only the concrete regression
witness below.  The wrapped pull credits strictly less ether than the exact
sum of the word-sized pushes, so one real external-call frame must revert;
`Contract.run` then restores the exact transaction-entry snapshot. -/
theorem execute_nonzero_wrap_reverts (allocations : List Nat) (state : ContractState)
    (hWrap : uint256Modulus ≤ allocSum allocations)
    (hNz : allocSumUnchecked allocations ≠ 0)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    ∃ reason,
      (execute allocations .none).run (entryFrame state) =
          ContractResult.revert reason (entryFrame state) ∧
        (observe (entryFrame state) allocations.length
          ((execute allocations .none).run (entryFrame state))).committed = false := by
  have hMod :
      allocSumUnchecked allocations = allocSum allocations % uint256Modulus :=
    allocSumUnchecked_eq_mod allocations
  have hModPos : 0 < uint256Modulus := by decide
  have hInsufficient :
      allocSumUnchecked allocations < allocSum allocations := by
    rw [hMod]
    exact Nat.lt_of_lt_of_le (Nat.mod_lt _ hModPos) hWrap
  let staged :=
    (allocationPass allocations 0 0 (entryFrame state)).writeSlot pulledTotalSlot 0
  have hStagedBalance : staged.selfBalance = 0 := by
    simp [staged, allocationPass_selfBalance, entryFrame]
  have hWrappedLt : allocSumUnchecked allocations < uint256Modulus := by
    rw [hMod]
    exact Nat.mod_lt _ hModPos
  rcases pushStage_reverts_of_wrapped_underfunding allocations
      (allocSumUnchecked allocations) staged hStagedBalance hWrappedLt
      hInsufficient hAmt with ⟨reason, dirty, hPush⟩
  have hExecute :
      execute allocations .none (entryFrame state) =
        ContractResult.revert reason dirty := by
    simp only [execute, allocationStage, Bind.bind, _root_.Verity.bind,
      _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true,
      if_true, hNz, if_false]
    simp only [staged] at hPush ⊢
    exact hPush
  refine ⟨reason, ?_, ?_⟩
  · simp [Contract.run, hExecute]
  · rw [show (execute allocations .none).run (entryFrame state) =
      ContractResult.revert reason (entryFrame state) by simp [Contract.run, hExecute]]
    rfl

/-- Concrete nonzero-wrap execution witness. The unchecked sum of
`[2^256 - 1, 2]` is one, so the pull credits one wei; the first beacon push
then attempts `2^256 - 1` wei and the real external-call frame fails closed.
`Contract.run` restores the exact entry snapshot. -/
theorem execute_nonzero_wrap_witness_reverts (state : ContractState) :
    ∃ reason rollback,
      (execute [uint256Modulus - 1, 2] .none).run (entryFrame state) =
          ContractResult.revert reason rollback ∧
        rollback = entryFrame state := by
  have hmod : Core.Uint256.modulus = uint256Modulus := by decide
  simp [execute, Contract.run, allocationStage, allocSumUnchecked,
    pushStage, Bind.bind, _root_.Verity.bind, _root_.Verity.require,
    lidoPull_run, creditPull, pushLoop, scheduledBeaconPush, externalCallBindTo,
    allocationPass_selfBalance, entryFrame, hmod, uint256Modulus]

/-- The witness is observably a non-commit as well as a state rollback. -/
theorem execute_nonzero_wrap_witness_observes_noncommit (state : ContractState) :
    (observe (entryFrame state) 2
      ((execute [uint256Modulus - 1, 2] .none).run (entryFrame state))).committed = false := by
  rcases execute_nonzero_wrap_witness_reverts state with ⟨reason, rollback, h, _⟩
  rw [h]
  rfl

/-- The batch spends every wei it pulled: the executable counterpart of the
final `assert(address(this).balance == 0)`. -/
theorem execute_ends_with_zero_balance (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus) :
    ∀ after, (execute allocations .none).run state = ContractResult.success () after →
      after.selfBalance = 0 := by
  intro after h
  by_cases hZero : allocSum allocations = 0
  · have hZeroW : allocSumUnchecked allocations = 0 :=
      (allocSumUnchecked_eq_allocSum hNoWrap).trans hZero
    rw [execute_run_zero allocations state hZeroW] at h
    injection h with _ hstate
    rw [← hstate]
    show (allocationPass allocations 0 0 state).selfBalance = 0
    rw [allocationPass_selfBalance, hBalance]
  · rw [execute_run_nonzero allocations state hBalance hNoWrap hZero] at h
    injection h with _ hstate
    rw [← hstate]

/-! ## Rollback after real prefix effects

The three injection points are not no-ops: each fires on a state the
transaction has already mutated -- storage words for the first, a journalled
and balance-debited call frame for the other two.  `Contract.run` then
normalizes every one of them back to the entry snapshot. -/

/-- `afterAllocationWrite` fires with every allocation word and the aggregate
already written. -/
theorem revert_after_allocation_write (allocations : List Nat) (state : ContractState) :
    execute allocations .afterAllocationWrite state =
      ContractResult.revert "FAIL_AFTER_ALLOCATION_WRITE"
        ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0) := by
  simp [execute, allocationStage, Bind.bind, _root_.Verity.bind, _root_.Verity.require]

theorem allocation_write_prefix_is_dirty (allocations : List Nat) (state : ContractState)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hNz : allocSum allocations ≠ 0)
    (hFresh : state.readSlot allocationTotalSlot = 0) :
    ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).readSlot
        allocationTotalSlot ≠ state.readSlot allocationTotalSlot := by
  rw [ContractState.readSlot_writeSlot_other _ (by decide), allocationPass_total, Nat.zero_add,
    hFresh]
  exact fun h => hNz (by rw [← word_val hNoWrap, h]; rfl)

/-- `afterLidoPull` fires with the pull frame already journalled and the
pulled ether already on the balance. -/
theorem revert_after_lido_pull (l : List Nat) (st : ContractState) :
    pushStage l (allocSum l) .afterLidoPull st =
      ContractResult.revert "FAIL_AFTER_LIDO_PULL"
        (({ st with
              selfBalance := st.selfBalance - (0 : Uint256) + ((allocSum l : Nat) : Uint256),
              calls := st.calls ++ [pullEntry (allocSum l)] }).writeSlot
          pulledTotalSlot ((allocSum l : Nat) : Uint256)) := by
  simp [pushStage, Bind.bind, _root_.Verity.bind, lidoPull_run, creditPull,
    _root_.Verity.require]

/-- `afterFirstBeaconPush` fires once the first deposit frame has really
debited the balance and appended its journal entry. -/
theorem revert_after_first_beacon_push (a : Nat) (rest : List Nat) (index : Nat)
    (st : ContractState) (ha : a ≠ 0) (hle : ((a : Uint256)) ≤ st.selfBalance) :
    pushLoop true (a :: rest) index st =
      ContractResult.revert "FAIL_AFTER_FIRST_BEACON_PUSH"
        { st with
          selfBalance := st.selfBalance - (a : Uint256)
          calls := st.calls ++ [pushEntry (index, a)] } := by
  rw [pushLoop, if_neg ha]
  simp only [Bind.bind, _root_.Verity.bind,
    beaconPush_run (scheduledDeposit index a) a st hle]
  simp [_root_.Verity.require,
    pushEntry, scheduledDeposit]

/-- Whatever was mutated, `Contract.run` hands back the entry snapshot. -/
theorem revert_restores_snapshot (allocations : List Nat) (failure : FailurePoint)
    (state rollback : ContractState) (reason : String)
    (h : (execute allocations failure).run state = ContractResult.revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- A failed batch is observationally inert: no allocation words, no aggregate
slots, no external calls. -/
theorem revert_observes_nothing (allocations : List Nat) (failure : FailurePoint)
    (state rollback : ContractState) (reason : String)
    (h : (execute allocations failure).run state = ContractResult.revert reason rollback) :
    observe state allocations.length ((execute allocations failure).run state)
      = ⟨false, [], 0, 0, 0, [], [], [], []⟩ := by
  rw [h]; rfl

/-! ## The module call and its returndata guards

`execute` above takes the allocation list as a free argument.  Nothing in it
records that the array is the returndata of
`IStakingModuleV2.allocateDeposits` (source lines 717--718), and nothing
enforces the three guards the router applies to that returndata *before* any
wei moves:

* the gwei alignment test at source line 724;
* the per-index `_topUpLimits[i]` bound at source line 728, whose read panics
  when the module returns more entries than there are keys;
* the aggregate over-target comparison at source line 737, read on the
  `unchecked` accumulator of line 732.

That is the reviewed P-TOPUP-1 fidelity gap.  The definitions below close it on
the executable plane: the allocation array becomes the journalled module
frame's `returndata`, and the guards are conditioned on exactly that array.

The residual boundary is stated rather than hidden: Verity's single-contract
`Contract` surface has no callee, so the returned words are still chosen by
whoever instantiates the frame.  That is the correct modelling of an
*untrusted* module -- the theorems below quantify over every possible
returndata -- but it is not an executed callee, and no claim here says
otherwise. -/

/-- Model pin for the staking module the router calls at source line 717.  No
equality with any deployed module address is claimed. -/
def moduleAddress : Address := (0x5140 : Address)

/-- The exact five source arguments of
`IStakingModuleV2.allocateDeposits` at `StakingRouter.sol:717-718`.
`moduleReturndata` is intentionally separate: the module is untrusted and the
router must guard whatever it returns. -/
structure TopupCall where
  /-- `smDepositableEthAmountRounded`. -/
  roundedTarget : Nat
  /-- `getWithdrawalCredentials()`, the bytes32 router-state value read by
  `_getWithdrawalCredentialsWithType` at pinned StakingRouter.sol:1046-1049. -/
  routerWithdrawalCredentials : List Nat
  /-- `stateConfig.withdrawalCredentialsType`, passed to `wc.setType(...)`. -/
  withdrawalCredentialsType : Nat
  /-- `_pubkeys`, retained as source ABI bytes rather than key-length words. -/
  pubkeys : List (List Nat)
  /-- `_keyIndices`. -/
  keyIndices : List Nat
  /-- `_operatorIds`. -/
  operatorIds : List Nat
  /-- `_topUpLimits`. -/
  topUpLimits : List Nat
  moduleReturndata : List Nat
  deriving Repr, DecidableEq

/-- Pinned `bytes32 wc = getWithdrawalCredentials(); return wc.setType(type)`.
For a Solidity `bytes32`, the credential type is its first byte. -/
def routerWithdrawalCredentials (call : TopupCall) : List Nat :=
  call.withdrawalCredentialsType :: call.routerWithdrawalCredentials.drop 1

def bytesBounded (bytes : List Nat) : Bool := bytes.all (· < 256)

def pubkeysPinned (pubkeys : List (List Nat)) : Bool :=
  pubkeys.all (fun pk => pk.length == 48 && bytesBounded pk)

/-- The source inputs admitted to `makeBeaconChainTopUp`.  These conditions
are executable guards below, not informal side conditions: bytes32 WC,
48-byte keys, octet ranges, and a one-byte credential type. -/
def SourceTopupCallWellFormed (call : TopupCall) : Prop :=
  call.routerWithdrawalCredentials.length = 32 ∧
  call.withdrawalCredentialsType < 256 ∧
  bytesBounded call.routerWithdrawalCredentials = true ∧
  pubkeysPinned call.pubkeys = true ∧
  call.pubkeys.length = call.moduleReturndata.length ∧
  call.moduleReturndata.all (· < uint256Modulus) = true

instance sourceTopupCallWellFormedDecidable (call : TopupCall) :
    Decidable (SourceTopupCallWellFormed call) := by
  unfold SourceTopupCallWellFormed
  infer_instance

theorem bytesBounded_iff (bytes : List Nat) :
    bytesBounded bytes = true ↔ ∀ b ∈ bytes, b < 256 := by
  simp [bytesBounded]

theorem pubkeysPinned_iff (pubkeys : List (List Nat)) :
    pubkeysPinned pubkeys = true ↔
      ∀ pk ∈ pubkeys, pk.length = 48 ∧ ∀ b ∈ pk, b < 256 := by
  simp [pubkeysPinned, bytesBounded, Bool.and_eq_true]

theorem routerWithdrawalCredentials_length (call : TopupCall)
    (h : call.routerWithdrawalCredentials.length = 32) :
    (routerWithdrawalCredentials call).length = 32 := by
  simp [routerWithdrawalCredentials, h]

theorem routerWithdrawalCredentials_bounded (call : TopupCall)
    (ht : call.withdrawalCredentialsType < 256)
    (hwc : ∀ b ∈ call.routerWithdrawalCredentials, b < 256) :
    ∀ b ∈ routerWithdrawalCredentials call, b < 256 := by
  intro b hb
  simp only [routerWithdrawalCredentials, List.mem_cons] at hb
  rcases hb with rfl | hb
  · exact ht
  · exact hwc b (List.mem_of_mem_drop hb)

/-- One SSZ input exactly as the pinned loop constructs it: WC is router
state after `setType`, pubkey is the corresponding `_pubkeys[i]`, signature
is the local 96-byte zero allocation, and amount is the guarded wei value in
gwei. -/
def sourceDepositInput (call : TopupCall) (pk : List Nat) (amount : Nat)
    (hwcLen : call.routerWithdrawalCredentials.length = 32)
    (ht : call.withdrawalCredentialsType < 256)
    (hwc : ∀ b ∈ call.routerWithdrawalCredentials, b < 256)
    (hpk : ∀ b ∈ pk, b < 256)
    (hamount : amount < uint256Modulus) : SourceDepositDataRootInput :=
  { withdrawalCredentials := routerWithdrawalCredentials call
    publicKey := pk
    signature := dummySignature
    amountGwei := amount / 1000000000
    withdrawalCredentialsBounded := routerWithdrawalCredentials_bounded call ht hwc
    publicKeyBounded := hpk
    signatureBounded := by simp [dummySignature]
    amountGweiBounded := by
      have hle : amount / 1000000000 ≤ amount := Nat.div_le_self _ _
      exact lt_of_le_of_lt hle (by simpa [uint256Modulus] using hamount) }

/-- Independent transcription of the values selected by pinned
`StakingRouter.topUp` lines 746-750 and
`BeaconChainDepositor.makeBeaconChainTopUp` lines 76-106.  It deliberately
does not mention `sourceBeaconCalldata` or any ABI encoder. -/
def PinnedMakeBeaconChainTopUpFields (call : TopupCall) (pk : List Nat)
    (amount : Nat) (input : SourceDepositDataRootInput) : Prop :=
  input.withdrawalCredentials = routerWithdrawalCredentials call ∧
  input.publicKey = pk ∧
  input.signature = List.replicate 96 0 ∧
  input.amountGwei = amount / 1000000000 ∧
  (computeDepositDataRootWithAmount input).bytes.length = 32

/-- The input consumed by the executed beacon frame is exactly the pinned
Solidity field selection, including router-derived WC, the corresponding
`_pubkeys[i]`, and the locally allocated zero signature.  This theorem is
against `PinnedMakeBeaconChainTopUpFields`, not definitional equality to the
call encoder. -/
theorem beaconPush_binds_source_ssz_fields (call : TopupCall) (pk : List Nat)
    (amount : Nat)
    (hwcLen : call.routerWithdrawalCredentials.length = 32)
    (ht : call.withdrawalCredentialsType < 256)
    (hwc : ∀ b ∈ call.routerWithdrawalCredentials, b < 256)
    (hpkLen : pk.length = 48) (hpk : ∀ b ∈ pk, b < 256)
    (hamount : amount < uint256Modulus) :
    let input := sourceDepositInput call pk amount hwcLen ht hwc hpk hamount
    beaconPush input amount =
        externalCallBindTo beaconAddress (amount : Uint256) [] "deposit"
          (sourceBeaconCalldata input) ∧
      PinnedMakeBeaconChainTopUpFields call pk amount input ∧
      input.withdrawalCredentials.length = 32 ∧
      input.publicKey.length = 48 ∧ input.signature.length = 96 := by
  dsimp [PinnedMakeBeaconChainTopUpFields, sourceDepositInput]
  refine ⟨rfl, ⟨rfl, rfl, ?_, rfl, ?_⟩,
    routerWithdrawalCredentials_length call hwcLen, hpkLen, ?_⟩
  · simp [dummySignature]
  · exact (computeDepositDataRootWithAmount
      (sourceDepositInput call pk amount hwcLen ht hwc hpk hamount)).widthPinned
  · simp [dummySignature]

def sourceDepositsOf (call : TopupCall) :
    (pubkeys : List (List Nat)) → (amounts : List Nat) →
    (∀ pk ∈ pubkeys, pk.length = 48 ∧ ∀ b ∈ pk, b < 256) →
    (∀ amount ∈ amounts, amount < uint256Modulus) →
    call.routerWithdrawalCredentials.length = 32 →
    call.withdrawalCredentialsType < 256 →
    (∀ b ∈ call.routerWithdrawalCredentials, b < 256) →
    List SourceDepositDataRootInput
  | [], _, _, _, _, _, _ => []
  | _, [], _, _, _, _, _ => []
  | pk :: pks, amount :: amounts, hpks, hamounts, hwcLen, ht, hwc =>
      sourceDepositInput call pk amount hwcLen ht hwc
          (hpks pk (by simp)).2 (hamounts amount (by simp)) ::
        sourceDepositsOf call pks amounts
          (fun key hkey => hpks key (by simp [hkey]))
          (fun value hvalue => hamounts value (by simp [hvalue])) hwcLen ht hwc

def sourceDeposits (call : TopupCall) (h : SourceTopupCallWellFormed call) :
    List SourceDepositDataRootInput :=
  sourceDepositsOf call call.pubkeys call.moduleReturndata
    ((pubkeysPinned_iff call.pubkeys).mp h.2.2.2.1)
    (by simpa using h.2.2.2.2.2) h.1 h.2.1
    ((bytesBounded_iff call.routerWithdrawalCredentials).mp h.2.2.1)

theorem sourceDepositsOf_length (call : TopupCall) :
    ∀ (pubkeys : List (List Nat)) (amounts : List Nat)
      (hpks : ∀ pk ∈ pubkeys, pk.length = 48 ∧ ∀ b ∈ pk, b < 256)
      (hamounts : ∀ amount ∈ amounts, amount < uint256Modulus)
      (hwcLen : call.routerWithdrawalCredentials.length = 32)
      (ht : call.withdrawalCredentialsType < 256)
      (hwc : ∀ b ∈ call.routerWithdrawalCredentials, b < 256),
      pubkeys.length = amounts.length →
      (sourceDepositsOf call pubkeys amounts hpks hamounts hwcLen ht hwc).length =
        pubkeys.length := by
  intro pubkeys
  induction pubkeys with
  | nil => intro amounts hpks hamounts hwcLen ht hwc hlen; simp [sourceDepositsOf]
  | cons pk pks ih =>
      intro amounts hpks hamounts hwcLen ht hwc hlen
      cases amounts with
      | nil => simp at hlen
      | cons amount amounts =>
          have htail : pks.length = amounts.length := by simpa using hlen
          simp only [sourceDepositsOf, List.length_cons]
          simpa using ih amounts (fun key hkey => hpks key (by simp [hkey]))
            (fun value hvalue => hamounts value (by simp [hvalue])) hwcLen ht hwc htail

theorem sourceDeposits_length (call : TopupCall) (h : SourceTopupCallWellFormed call) :
    (sourceDeposits call h).length = call.moduleReturndata.length := by
  rw [← h.2.2.2.2.1]
  exact sourceDepositsOf_length call call.pubkeys call.moduleReturndata
    ((pubkeysPinned_iff call.pubkeys).mp h.2.2.2.1)
    (by simpa using h.2.2.2.2.2) h.1 h.2.1
    ((bytesBounded_iff call.routerWithdrawalCredentials).mp h.2.2.1)
    h.2.2.2.2.1

/-- Canonical tail of a dynamic `uint256[]`: its length followed by its ABI
words.  Unlike the former flattened abstraction, offsets are emitted by
`allocateCalldata` below. -/
def abiUintArrayTail (xs : List Nat) : List Uint256 :=
  (xs.length : Uint256) :: xs.map (fun x => (x : Uint256))

/-- The four-byte selector for
`allocateDeposits(uint256,bytes[],uint256[],uint256[],uint256[])`, derived
from that pinned interface signature. It is retained as a distinguished leading
journal word; the remaining list is the exact 32-byte-word ABI body. -/
def allocateDepositsSelector : Uint256 := (0x783b8a65 : Uint256)

/-- Canonical ABI encoding for all five source arguments at
`StakingRouter.sol:717-718`, including the selector, five-word head, dynamic
offsets, `bytes[]` element offsets/lengths/padding, and three `uint256[]`
tails. -/
def allocateCalldata (call : TopupCall) : List Uint256 :=
  let pubkeysTail := abiBytesArrayTail call.pubkeys
  let keysTail := abiUintArrayTail call.keyIndices
  let operatorsTail := abiUintArrayTail call.operatorIds
  let limitsTail := abiUintArrayTail call.topUpLimits
  let headBytes := 5 * 32
  let pubkeysOffset := headBytes
  let keysOffset := pubkeysOffset + pubkeysTail.length * 32
  let operatorsOffset := keysOffset + keysTail.length * 32
  let limitsOffset := operatorsOffset + operatorsTail.length * 32
  [allocateDepositsSelector, (call.roundedTarget : Uint256),
    (pubkeysOffset : Uint256), (keysOffset : Uint256),
    (operatorsOffset : Uint256), (limitsOffset : Uint256)] ++
    pubkeysTail ++ keysTail ++ operatorsTail ++ limitsTail

theorem abiUintArrayTail_calldata (xs : List Nat) :
    (abiUintArrayTail xs).map (·.val) =
      (xs.length : Uint256).val :: xs.map (fun x => (x : Uint256).val) := by
  simp [abiUintArrayTail]

 /-- The journalled five-argument `allocateDeposits` frame. -/
def allocateEntry (call : TopupCall) : ExternalCall :=
  linkedCallEntryTo "allocateDeposits" moduleAddress 0 (allocateCalldata call)
    .success call.moduleReturndata

theorem allocateEntry_name (call : TopupCall) :
    (allocateEntry call).name = "allocateDeposits" := rfl
theorem allocateEntry_target (call : TopupCall) :
    (allocateEntry call).target = moduleAddress.toNat := rfl
theorem allocateEntry_value (call : TopupCall) :
    (allocateEntry call).value = 0 := rfl
theorem allocateEntry_calldata (call : TopupCall) :
    (allocateEntry call).calldata =
      (linkedCallEntryTo "allocateDeposits" moduleAddress 0
        (allocateCalldata call)).calldata := rfl

/-- The fact the whole correction turns on: the words the guarded transaction
consumes *are* the journalled frame's returndata. -/
theorem allocateEntry_returndata (call : TopupCall) :
    (allocateEntry call).returndata = call.moduleReturndata := rfl

/-- The module call as a transaction step: it journals the frame and binds the
frame's returndata.  Callers of `executeGuarded` supply the module's return,
never the guarded array directly. -/
def allocateDeposits (call : TopupCall) : Contract (List Nat) :=
  fun state =>
    .success (allocateEntry call).returndata
      { state with calls := state.calls ++ [allocateEntry call] }

/-- The router's returndata guards, source lines 722--734, as a transaction
step.  Guard order is source order: the alignment test at line 724 precedes the
`_topUpLimits[i]` read at line 728, so an over-long returndata array trips
alignment for its extra entry first and the out-of-bounds panic second. -/
def guardLoop (cfg : SourceTopupConfig) : List Nat → List Nat → Contract Unit
  -- StakingRouter.sol:723  for (uint256 i; i < allocations.length; ++i) {  (loop exit)
  | [], _ => Verity.pure ()
  | a :: _, [] => do
      -- StakingRouter.sol:724-726  if (allocations[i] % 1 gwei != 0) { revert AmountNotAlignedToGwei(); }
      require (decide (a % cfg.gwei = 0)) "AmountNotAlignedToGwei"
      -- StakingRouter.sol:728  _topUpLimits[i]  (out-of-bounds read, Panic(0x32))
      require false "TopUpLimitIndexOutOfBounds"
  | a :: as, l :: ls => do
      -- StakingRouter.sol:724-726  if (allocations[i] % 1 gwei != 0) { revert AmountNotAlignedToGwei(); }
      require (decide (a % cfg.gwei = 0)) "AmountNotAlignedToGwei"
      -- StakingRouter.sol:728-730  if (allocations[i] > _topUpLimits[i]) { revert AllocationExceedsLimit(); }
      require (decide (a ≤ l)) "AllocationExceedsLimit"
      guardLoop cfg as ls

/-- The revert string each source guard outcome maps to.  Pairing the two
makes the executable guard and the source `Outcome` constructor the *same*
guard rather than two independently drifting ones. -/
def guardReason : Outcome → String
  | .revertAmountNotAlignedToGwei => "AmountNotAlignedToGwei"
  | .revertTopUpLimitIndexOutOfBounds => "TopUpLimitIndexOutOfBounds"
  | .revertAllocationExceedsLimit => "AllocationExceedsLimit"
  | _ => "NOT_AN_ALLOCATION_LOOP_GUARD"

theorem guardLoop_success (cfg : SourceTopupConfig) :
    ∀ (allocations limits : List Nat) (state : ContractState),
      allocationLoop cfg allocations limits = none →
        guardLoop cfg allocations limits state = ContractResult.success () state := by
  intro allocations
  induction allocations with
  | nil => intro limits state _; rfl
  | cons a as ih =>
      intro limits state h
      cases limits with
      | nil =>
          rw [allocationLoop] at h
          split at h <;> simp at h
      | cons l ls =>
          rw [allocationLoop] at h
          split at h
          · simp at h
          · rename_i hAlign
            split at h
            · simp at h
            · rename_i hLimit
              simp only [ne_eq, not_not] at hAlign
              simp only [Nat.not_lt] at hLimit
              rw [guardLoop]
              simp only [Bind.bind, _root_.Verity.bind, _root_.Verity.require,
                hAlign, decide_true, if_true, hLimit]
              exact ih ls state h

theorem guardLoop_revert (cfg : SourceTopupConfig) :
    ∀ (allocations limits : List Nat) (o : Outcome) (state : ContractState),
      allocationLoop cfg allocations limits = some o →
        guardLoop cfg allocations limits state
          = ContractResult.revert (guardReason o) state := by
  intro allocations
  induction allocations with
  | nil => intro limits o state h; rw [allocationLoop] at h; simp at h
  | cons a as ih =>
      intro limits o state h
      cases limits with
      | nil =>
          rw [allocationLoop] at h
          rw [guardLoop]
          split at h
          · rename_i hAlign
            cases h
            simp [Bind.bind, _root_.Verity.bind, _root_.Verity.require, guardReason, hAlign]
          · rename_i hAlign
            cases h
            simp only [ne_eq, not_not] at hAlign
            simp [Bind.bind, _root_.Verity.bind, _root_.Verity.require, guardReason, hAlign]
      | cons l ls =>
          rw [allocationLoop] at h
          rw [guardLoop]
          split at h
          · rename_i hAlign
            cases h
            simp [Bind.bind, _root_.Verity.bind, _root_.Verity.require, guardReason, hAlign]
          · rename_i hAlign
            simp only [ne_eq, not_not] at hAlign
            split at h
            · rename_i hLimit
              cases h
              simp [Bind.bind, _root_.Verity.bind, _root_.Verity.require, guardReason,
                hAlign, Nat.not_le.mpr hLimit]
            · rename_i hLimit
              simp only [Nat.not_lt] at hLimit
              simp only [Bind.bind, _root_.Verity.bind, _root_.Verity.require,
                hAlign, decide_true, if_true, hLimit]
              exact ih ls o state h

/-- Everything the router does *to* the module's returndata: guard it, then
spend it. -/
def guardedStage (cfg : SourceTopupConfig) (limits : List Nat) (roundedTarget : Nat)
    (returned : List Nat) (failure : FailurePoint) : Contract Unit := do
  -- StakingRouter.sol:722-734  per-index guards of the accumulator loop
  guardLoop cfg returned limits
  -- StakingRouter.sol:737-739  if (amount > smDepositableEthAmountRounded) { revert ModuleReturnExceedTarget(); }
  require (decide (allocSumUnchecked returned ≤ roundedTarget)) "ModuleReturnExceedTarget"
  -- StakingRouter.sol:722-756  accumulate, pull, push
  execute returned failure

/-- The live guarded value path.  After the module-return guards, it admits
only the exact router/source byte shape and invokes the source-derived
executor.  Thus no successful registered execution can reach
`scheduledDeposit` or `scheduledBeaconPush`. -/
def guardedSourceStage (cfg : SourceTopupConfig) (call : TopupCall)
    (returned : List Nat) (failure : FailurePoint) : Contract Unit := do
  guardLoop cfg returned call.topUpLimits
  require (decide (allocSumUnchecked returned ≤ call.roundedTarget))
    "ModuleReturnExceedTarget"
  require (decide (returned = call.moduleReturndata)) "ModuleReturnBindingMismatch"
  if h : SourceTopupCallWellFormed call then
    executeSourceDerived (sourceDeposits call h) returned failure
  else
    require false "InvalidSourceTopupFields"

/-- The corrected executable top-up: call the module, then guard and spend
exactly what it returned. -/
def executeGuarded (cfg : SourceTopupConfig) (call : TopupCall) (failure : FailurePoint) :
    Contract Unit := do
  -- StakingRouter.sol:717-718  uint256[] memory allocations = IStakingModuleV2(stateConfig.moduleAddress).allocateDeposits(...);
  let returned ← allocateDeposits call
  guardedSourceStage cfg call returned failure

/-- The binding statement.  `executeGuarded` journals the module frame and then
runs the guard-and-spend stage on *that frame's returndata*; the allocation
array is not a free argument of the guarded transaction. -/
theorem executeGuarded_binds_returndata (cfg : SourceTopupConfig) (call : TopupCall)
    (failure : FailurePoint) (state : ContractState) :
    executeGuarded cfg call failure state =
      guardedSourceStage cfg call (allocateEntry call).returndata failure
        { state with
          calls := state.calls ++ [allocateEntry call] } :=
  rfl

/-- Alignment, per-index limit, and out-of-bounds all fail closed with the
source guard's own name, and `Contract.run` restores the entry snapshot. -/
theorem executeGuarded_reverts_on_allocation_guard (cfg : SourceTopupConfig)
    (call : TopupCall) (o : Outcome) (failure : FailurePoint) (state : ContractState)
    (hLoop : allocationLoop cfg call.moduleReturndata call.topUpLimits = some o) :
    (executeGuarded cfg call failure).run state
      = ContractResult.revert (guardReason o) state := by
  have hStage : executeGuarded cfg call failure state
      = ContractResult.revert (guardReason o)
          { state with
            calls := state.calls ++ [allocateEntry call] } := by
    rw [executeGuarded_binds_returndata, allocateEntry_returndata]
    simp only [guardedSourceStage, Bind.bind, _root_.Verity.bind]
    rw [guardLoop_revert cfg call.moduleReturndata call.topUpLimits o _ hLoop]
  simp [Contract.run, hStage]

/-- The aggregate over-target guard at source line 737 fails closed on the
same accumulator the source reads (`allocSumUnchecked`, mod 2^256). -/
theorem executeGuarded_reverts_on_over_target (cfg : SourceTopupConfig)
    (call : TopupCall) (failure : FailurePoint) (state : ContractState)
    (hLoop : allocationLoop cfg call.moduleReturndata call.topUpLimits = none)
    (hOver : call.roundedTarget < allocSumUnchecked call.moduleReturndata) :
    (executeGuarded cfg call failure).run state
      = ContractResult.revert "ModuleReturnExceedTarget" state := by
  have hStage : executeGuarded cfg call failure state
      = ContractResult.revert "ModuleReturnExceedTarget"
          { state with
            calls := state.calls ++ [allocateEntry call] } := by
    rw [executeGuarded_binds_returndata, allocateEntry_returndata]
    simp only [guardedSourceStage, Bind.bind, _root_.Verity.bind]
    rw [guardLoop_success cfg call.moduleReturndata call.topUpLimits _ hLoop]
    simp [_root_.Verity.require, Nat.not_le.mpr hOver]
  simp [Contract.run, hStage]

/-- The exact 32-byte router WC, 48-byte per-validator public keys, octet
ranges, key/allocation cardinality and uint256 amount widths are executable
admission checks. Any violation restores the transaction snapshot. -/
theorem executeGuarded_reverts_on_invalid_source (cfg : SourceTopupConfig)
    (call : TopupCall) (failure : FailurePoint) (state : ContractState)
    (hLoop : allocationLoop cfg call.moduleReturndata call.topUpLimits = none)
    (hTarget : ¬ call.roundedTarget < allocSumUnchecked call.moduleReturndata)
    (hInvalid : ¬ SourceTopupCallWellFormed call) :
    (executeGuarded cfg call failure).run state =
      ContractResult.revert "InvalidSourceTopupFields" state := by
  have hStage : executeGuarded cfg call failure state =
      ContractResult.revert "InvalidSourceTopupFields"
        { state with calls := state.calls ++ [allocateEntry call] } := by
    rw [executeGuarded_binds_returndata, allocateEntry_returndata]
    simp only [guardedSourceStage, Bind.bind, _root_.Verity.bind]
    rw [guardLoop_success cfg call.moduleReturndata call.topUpLimits _ hLoop]
    simp [_root_.Verity.require, Nat.not_lt.mp hTarget, hInvalid]
  simp [Contract.run, hStage]

/-- With every returndata guard passed, the guarded transaction is exactly the
unguarded one run on the module's returndata from the post-frame state. -/
theorem executeGuarded_apply_of_guards_pass (cfg : SourceTopupConfig) (call : TopupCall)
    (failure : FailurePoint) (state : ContractState)
    (hLoop : allocationLoop cfg call.moduleReturndata call.topUpLimits = none)
    (hTarget : ¬ call.roundedTarget < allocSumUnchecked call.moduleReturndata)
    (hSource : SourceTopupCallWellFormed call) :
    executeGuarded cfg call failure state =
      executeSourceDerived (sourceDeposits call hSource) call.moduleReturndata failure
        { state with
          calls := state.calls ++ [allocateEntry call] } := by
  rw [executeGuarded_binds_returndata, allocateEntry_returndata]
  simp only [guardedSourceStage, Bind.bind, _root_.Verity.bind]
  rw [guardLoop_success cfg call.moduleReturndata call.topUpLimits _ hLoop]
  simp [_root_.Verity.require, Nat.not_lt.mp hTarget, hSource]

/-- Whatever the guarded transaction mutated, `Contract.run` hands back the
entry snapshot. -/
theorem executeGuarded_revert_restores_snapshot (cfg : SourceTopupConfig) (call : TopupCall)
    (failure : FailurePoint) (state rollback : ContractState) (reason : String)
    (h : (executeGuarded cfg call failure).run state
      = ContractResult.revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-! ## Observables of the guarded transaction -/

/-- The unguarded schedule with the module frame prepended. -/
def guardedObservables (call : TopupCall) : OutcomeObservables :=
  let base := sourceObservables call.moduleReturndata
  { base with
    callNames := "allocateDeposits" :: base.callNames
    callTargets := moduleAddress.toNat :: base.callTargets
    callValues := 0 :: base.callValues
    callArgs := (allocateEntry call).calldata :: base.callArgs }

/-- The unguarded run always ends with the journal it started from extended by
`expectedCalls`; both the zero and the nonzero branch. -/
theorem execute_run_calls (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus) :
    ∃ after, (execute allocations .none).run state = ContractResult.success () after ∧
      after.calls = state.calls ++ expectedCalls allocations := by
  have hEq : allocSumUnchecked allocations = allocSum allocations :=
    allocSumUnchecked_eq_allocSum hNoWrap
  by_cases hZero : allocSum allocations = 0
  · refine ⟨_, execute_run_zero allocations state (by rw [hEq]; exact hZero), ?_⟩
    have hcalls : ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls
        = state.calls := allocationPass_calls _ _ _ _
    show ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls = _
    rw [hcalls, expectedCalls, hEq, if_pos hZero, List.append_nil]
  · exact ⟨_, execute_run_nonzero allocations state hBalance hNoWrap hZero, rfl⟩

/-- Observing across one extra leading journal entry.  The entry shows up as
the head of every journal projection; every other observable is read off the
post-state and is untouched. -/
theorem observe_after_leading_entry (before after : ContractState) (entry : ExternalCall)
    (tail : List ExternalCall) (count : Nat)
    (hName : entry.name ≠ "deposit")
    (hCalls : after.calls = (before.calls ++ [entry]) ++ tail) :
    observe before count (ContractResult.success () after) =
      (let base := observe { before with calls := before.calls ++ [entry] } count
        (ContractResult.success () after)
       { base with
         callNames := entry.name :: base.callNames
         callTargets := entry.target :: base.callTargets
         callValues := entry.value :: base.callValues
         callArgs := entry.calldata :: base.callArgs }) := by
  have hOuter : after.calls.drop before.calls.length = entry :: tail := by
    rw [hCalls, List.append_assoc, List.drop_left]
    rfl
  have hInner : after.calls.drop (before.calls ++ [entry]).length = tail := by
    rw [hCalls, List.drop_left]
  simp only [observe, hOuter, hInner, callValueOf, beq_iff_eq, hName, if_false,
    Nat.zero_add, List.map_cons]

end LidoSRv3.Audit.Verity.TopupTx
