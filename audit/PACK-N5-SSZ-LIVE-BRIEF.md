# Pack N5 brief — SSZ live chain

One node, one PR. No new guarantee IDs. Keeps `A-SHA256-FFI`: `combine`
stays abstract and no SHA functional correctness is claimed. Does not set
any Prop to `False` and does not rewrite `ProductionGindexBinding`
(deployed-GI equality stays open). The `Nat`-tree traversal is not a
finish. The age check alone was already done (W2-4788); this node makes
the opaque parent-root lookup **consumed** by verify, not an unused
symbol.

## Frozen interfaces used

- `Ssz.verifyProof`, `Ssz.pivot`, `Ssz.branchPath`,
  `Ssz.HasGeneralizedIndex` from `Audit/Ssz.lean`.
- `Eip4788AnchorChild.ageCheck` and the opaque
  `Eip4788AnchorChild.eip4788ParentRoot` (cited, not discharged).
- `ProductionGindexChild.cl_validator_index_is_toy` (cited; the toy
  slots 2/3/4 stay the leftover record).

## Work

1. Inhabited `ProductionGindex` (`Spec/SszLiveCorrespondence.lean`):
   `giFirstValidatorCurr` with `index = 150 * 2 ^ 40`, `pow = 40`,
   `packed = 0x…0096000000000028`, pinned from the
   lidofinance/core@af095e48 vector (labeled mainnet values in
   `test/0.8.25/validatorExitDelayVerifier.test.ts`; pack layout
   `(index << 8) | pow` per `contracts/common/lib/GIndex.sol`,
   `giFirstValidatorCurr_packed_decodes`). A model constant from the
   pinned test vector, not a discharge of a deployment assumption, and
   not a new A-* closed by the pin.
2. `verifyAtParent combine leaf gi parentRoot path branch` is
   `Ssz.verifyProof combine leaf gi (pivot gi) path branch parentRoot`.
   Depth facts at the production index: pivot `2 ^ 47`, branch depth 47
   (`production_pivot_depth`), rejection of every wrong-depth path
   (`verifyAtParent_production_wrong_depth`), and the construction leg
   (`verifyAtParent_production_construction`).
3. `verifyAtLookup`: the parent root used by verify is
   `eip4788ParentRoot ts` when `some`; when the lookup is `none`, verify
   is false (`verifyAtLookup_none`, `verifyAtLookup_eq_true_iff`). The
   lookup stays opaque.
4. Gateway consume (`Guarantees/PSszLive1.lean`):
   `admitTopupOrConsolidation wcProof` is `ageCheck ∧ verifyAtLookup`.
   Parent theorem `production_witness_admission_correspondence`: one `∀`
   whose conclusion is the correspondence — the witness age-checks and
   verifies at the production GI against the looked-up parent root iff
   the gateway admits. Unpacked soundness `gateway_admission_sound`;
   fail-closed `admission_false_of_lookup_none`; conditional non-vacuity
   `admitted_construction_under_lookup`.

## Kill-lines

- `admitSkipLookup` (age check only, parent-root lookup skipped):
  `skip_lookup_kill_line_refutes_parent` refutes the mutant-substituted
  parent, premises retained, at a fresh-anchor depth-0 witness the
  production verify rejects against every root.
- Toy slot 2 instead of `150 * 2 ^ 40`:
  `toy_slot_kill_line_refutes_verify_parent` refutes the
  mutant-substituted verify-soundness surface at a depth-1 witness the
  toy slot accepts (`toy_slot_accepts_shallow_witness_production_rejects`);
  `toy_slot_gateway_kill_line_under_lookup` shows the gateway-level
  divergence under a hypothesized `some` lookup.

## Out of scope

Discharging `eip4788ParentRoot` (no precompile, no `block.parent` read),
deployed-GI equality (`ProductionGindexBinding` stays as the child
records it), SHA-256 functional correctness (`A-SHA256-FFI`), Yul, EVM
execution, a live Solidity gateway, a bus.
