# P-DEREF-1 closure-v2 receipt

Writer: `LidoSRv3/Audit/Guarantees/PDeref1.lean` (one writer for this guarantee).

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The guarantee states that a successfully membership-guarded staking-module ID
dereferences to its exact registered, nonzero module address, and that this
binding is stable under every address-relevant source interleaving. The source
has one registry writer, `SRLib._addModule`; it admits no removal or address
replacement. External calls in the digest/summary read paths are `view` and
therefore execute under `STATICCALL`, so callback subtrees cannot mutate router
storage.

## Exact source surface

- `SRStorage.getModuleState`, `getIStakingModule`, `getIStakingModuleV2`:
  `contracts/0.8.25/sr/SRStorage.sol:30-47`.
- module-set reads and sole add writer: `SRStorage.sol:54-77`.
- membership/index guards: `SRUtils.sol:45-58`.
- registration, duplicate/nonzero/count guards, address write and packed
  `lastModuleId`: `SRLib.sol:183-232`.
- direct guarded views: `StakingRouter.getStakingModule` at 415-417 and
  `getNodeOperatorSummary` at 461-467.
- multi-call read interleavings: `getStakingModuleDigests` and
  `getNodeOperatorDigests` at 483-553.
- guarded storage projection and summary dereference: `StakingRouter.sol:
  1099-1143`.

## Hybrid evidence and bounds

- MODEL/SOURCE: `PDeref1.closure` proves exact address resolution after an
  arbitrary list of source-permitted interleavings.
- VERITY_TX: `DereferenceTx.observe` is an executable inherited
  `verity_contract` transaction with a first-class existence modifier and
  packed `Uint24` ID representation.
- YUL interface: `DereferenceYulBridge` binds Verity's active Solidity mapping
  slot location to EVMYulLean's typed `SLOAD` AST at pin
  `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`; no EVM equivalence is claimed.
- Bound: source cap 32 implies exact `uint24` roundtrip. Concrete out-of-bound
  witness: `2^24 % 2^24 = 0`, so the bound cannot be dropped.
- Negative mutants: removal of the membership guard aliases an absent ID to
  zero; adding an address-replacement writer changes ID 1 from `0xBEEF` to
  `0xCAFE` and violates stability.

## Verity feature-pin verification

Chosen pin: `c41757164e9e8230536d7af29d81a2961b30e482`.

- #2249 packed storage lowering: merge `1f9e2380…` is an ancestor.
- #2247 modifiers/inheritance: merge `23f53568…` is an ancestor.
- #2248 uint8 enum support: the chosen pin is merge `c4175716…` itself.
- #2245 external-call bodies: GitHub's merge commit `d48472c8…` lives on the
  feature branch rather than main; the chosen tree was verified directly to
  contain `Verity/Macro/ExternalCalls.lean`, external-call body translation,
  and its feature tests. This records tree evidence rather than asserting a
  false merge-commit ancestry.
