# SSZ wrapper index and slot sibling

Candidate increment; commit-exact independent review and integration acceptance
are separate. Source pin:
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

## Useful result

`wrapper_success` applies to arbitrary decoded constructor configurations,
slots and uint256 offsets. It derives the accepted offset range from the
source neighbor guard and identifies the header-relative index by an
independent arithmetic append specification. `concat_of_depth` derives both
uint256 shift safety and uint248 pack safety from the source depth guard;
neither is supplied as a no-wrap/result-fit premise.

The independent specification is
`appendIndex a b = a * 2^(log2 b) + (b - 2^(log2 b))`.
`xor_pivot_eq_sub` proves that the source XOR removes exactly the leading bit,
and the OR theorem proves the disjoint shifted fields compose as this sum.
This is not a duplicated shift/XOR/OR specification or a proof by rfl.

For the configuration artifact with validator base `150 * 2^40`, power 40,
`pinned_wrapper_accepts_iff` proves admission exactly when `offset < 2^40`.
`pinned_wrapper_success` then gives **`1430 * 2^40 + offset`**, depth **50**,
with power metadata 40. The state-relative validator index has depth 47;
it is not the full index consumed against the parent block root. This is a
missing bridge in earlier models, not a demonstrated deployed contract bug.

`slot_sibling_of_header_branch` independently constructs a branch from a
binary BeaconBlockHeader tree and proves that `proof[length-2]` is its
slot/proposer subtree. It allows any state subtree and valid path inside it.
`encoded_slot_accepts_header_branch` then consumes the existing universal
uint64 endian theorem: the reference header uses independent octet chunks,
while the source-shaped slot check computes the literal source mask/shift
encodings. No expected digest or root-match Boolean is supplied independently.
The pair function is universally quantified; no hash injectivity is assumed.

## Source correspondence

| Source location | Definition/theorem | Scope |
|---|---|---|
| GIndex.sol:23-30,41-54 | `PackedIndex` | Decoded actual uint248 index and uint8 power. Raw bytes32 decoding/packing execution remains a representation boundary. |
| CLValidatorVerifier.sol:97-99 | `selected`, `sourceNeighbor`, `wrapper_success` | Strict slot < pivot selects actual previous/current parameters; offset range comes from checked guards. |
| GIndex.sol:57-64 | `sourceNeighbor`, `neighbor_success` | Checked remainder-plus-offset and index-plus-offset, width rejection and pack rejection; arithmetic panic distinguished from IndexOutOfRange. |
| GIndex.sol:76-89 | `sourceConcat`, `concat_of_depth`, `concat_success` | Depth guard, actual word truncation for shifts, XOR/OR and pack; successful result equals independent arithmetic path append. |
| CLValidatorVerifier.sol:19-22,54 | `stateRootIndex`, `sourceWrapper` | Prefix actual header state_root index 11 before final verification. |
| Source mainnet config:66-67,88-89 | `pinnedConfiguration`, `pinned_wrapper_accepts_iff` | Both source configuration words happen to be pack(150*2^40,40). This is not the generic configuration definition or deployed identity evidence. |
| CLValidatorVerifier.sol:89-93 | `sourceSlotSibling` | The indexing fragment after pair hashing; lengths 0/1 trigger checked subtraction panic. |
| Same span; SSZ.sol:251-265 | `sourceVerifySlotArithmetic`, `encoded_slot_accepts_header_branch` | Computes expected pair from source encodings of uint64 slot/proposer and compares the extracted sibling. Pair-call failure is not modeled. |
| SSZ.sol:199-200 | `pinned_header_steps` | Arithmetic parent indices at steps 47/48/49 are 11/5/2, whose parities are 1/1/0. Step 48's sibling is header node 4, the slot/proposer subtree. |

The exact source files and mainnet configuration artifact are compared against
immutable git objects by `check_source.py`, with explicit relevant textual
anchors. These checks establish file identity and support manual source review;
they are not semantic equivalence proofs.

## Domain and remaining work

- **Decoded packed inputs.** Every index input is uint248 and every power is
  uint8, matching the source representation. Source arithmetic checks remain
  executable, not assumptions. The model's `fls` uses Nat.log2 and the zero=256
  sentinel. Universal equivalence to the Solady assembly implementation is
  not proved. Imported Solidity differential tests exercise it extensively,
  but remain finite evidence.
- **Configuration.** Generic `wrapper_success` retains arbitrary previous and
  current packed words. Only the explicitly named pinned consumer assumes the
  repository configuration artifact. It proves admission for all uint256
  offsets, deriving the subtree bound. Constructor immutables and deployed
  chain identity remain unproved. Distinct synthetic fork configurations are
  tested because the pinned equal values cannot detect a reversed fork switch.
- **Slot construction, not authentication.** `treeBranch` derives the siblings
  from an independent tree and path; its success premise is mathematical branch
  construction, not an assumed slot-sibling conclusion. There is not yet a
  formal composition from decoded generalized-index bits to this tree traversal
  and the actual SSZ.verifyProof loop. No theorem here says that every arbitrary
  accepted hash branch comes from this tree, or proves cryptographic binding.
- **SHA and failure order.** The arithmetic slot check uses a total deterministic
  pair function. The real `_verifySlot` hashes before indexing; BLS.sha256Pair
  may reject failed calls or non-32-byte returndata before a short-proof panic.
  This increment does not model those failures or the full wrapper error order.
- **Full validator verification.** Witness field selection, expected withdrawal
  credentials, 48-byte pubkey-plus-padding preimage, the digest-carrying proof
  loop, EIP-4788 call/ABI decoding, memory, compiler/EVM execution, gas and
  deployed provenance remain to compose. The eight helper hashes and structural
  validator field inventory do not discharge these obligations.

No existing registered SSZ-1 parent, source pin, metadata index or website claim
is modified by these files. The universal helper result and this wrapper slice
are increments, not full SSZ-1 acceptance.

## Validation

Targeted Lean source/tests, including six principal axiom queries, are recorded
in `validation.log` and `receipt.json`. The four queried numeric/index theorems use only
propext and Quot.sound; the two queried tree-branch/encoding-consumer theorems
also use Classical.choice. These exact dependencies are printed in the log. There is no
sorry, native_decide, bv_decide, custom axiom or assumed source equivalence.
The new dependency justifies a targeted rebuild, not a full repository build.

The root integrator's final `SszWrapperIndex.t.sol` inherits the actual pinned
CLValidatorVerifier and calls its `_getValidatorGI` and `_verifySlot`, plus the
real GIndex concat/fls functions. Final Solidity log: **8 passing tests**, five
fuzz properties with **1024 runs each**, all 256 one-hot fls inputs, zero/depth
boundaries, offset errors and short-proof panic. The independent reference
uses bit-length by repeated division, arithmetic path append, and byte-wise
slot/proposer chunks. The harness does not execute the complete
`_verifyValidator` flow. No finite test is called a universal proof.

Lean regressions cover omitted/wrong header prefix, wrong offset, strict pivot
selection with distinct synthetic layouts, zero/depth-248/pack/overflow
boundaries, wrong slot-sibling neighbors, source slot/proposer encoding and
big-endian field mistakes. The consumer computes and compares encoded values;
canonical proof construction is not confused with arbitrary-root authentication.

## Next verifiable result

Connect the actual complete index's path bits to a digest-carrying
SSZ.verifyProof interpreter, deriving exact branch length and sibling order from
successful execution while computing the accumulator. Do not retain supplied
`finalRootMatches` or computed root inputs. Separately connect actual validator
field writes and BLS public-key padding to the leaf consumed by that same run.
Estimated 1–3 working days for the loop/path bridge once byte/memory/precompile
interfaces are fixed, lower confidence until that interface is settled. Full
compiler/EVM and deployment linkage are additional work.
