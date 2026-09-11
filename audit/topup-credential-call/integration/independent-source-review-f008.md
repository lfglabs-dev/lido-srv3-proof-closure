# Independent exact-source review: TOPUP credentials call

**CLEAN for the bounded additive slice** at `f00863276fbe279c566328ed4ae90f5bf223a38e`.
Tree `7d0d867f1e3788896ce49ae336274199b4955f64`; parent
`f193ebf96beef3f5e1e1568fc9f2b906c0192299`.
No blocking correctness, correspondence, composition or receipt finding found.
This is not certification of full TOPUP delivery or whole compiled gateway execution.

I did not author this increment or its TOPUP substrate. Review was read-only in
`/tmp/lido-topup-credential-call`; its exact clean tree and all 27 receipt hashes
were checked before/after. No source, dossier, Git state or build output was changed.
No Lean build, solc invocation, Forge run or native-library build was repeated.

## Exact consumer and source assessment

| Obligation | Assessment and inspected location |
|---|---|
| Generated request is actually executed | `Source/TopupCredentialCall.lean:15–19,80–89,142–152`: the call uses gateway `e.gateway`, router role `ctx.sender`, zero value, exact module Word and selector `f85c6ceb`. The public theorem derives the actual external reply from that lookup. No assumed calldata or supplied stage-success hypothesis. |
| Source failure order | `TopupCredentialCall.lean:20–72,135–157`: typed length/config checks precede lookup; failed STATICCALL bubbles before successful-return allocation; allocation precedes short-return decoder; prefix02 precedes any root attempt. The inherited repeated length check is pure on unchanged rows/config/World. |
| Actual scalar decoder | IR `GatewayWitnessHarness.ir:512–538,1685–1695` executes output capacity32, `min(32,returndatasize)`, wrapping allocation guard, signed end-minus-base test and first-word load. `copied_signed_guard` proves the bounded signed/natural comparison; `decode_fields` derives next=cursor+32 and next<2^64. No cursor/width assumption is smuggled into the theorem. Empty/short and trailing cases are tested. |
| No artificial EXTCODESIZE rejection | Getter IR517 directly STATICCALLs; `lookup` uses inherited `lowLevelStaticCall`, whose ordinary no-code arm succeeds empty and subsequently fails allocation/decoding. The derived nonzero-code conclusion on success is an observation of that typed model, not an extra entry premise. Its inherited precompile restriction remains explicit. |
| Exact credential type and value | Core `WithdrawalCredentials.getType/isType2` checks the high byte only; IR541–548 agrees with division by2^248. No additional zero-middle/address condition is added. `resolved` at source115–116 overwrites only credentials with the actual first-word Digest. |
| Same value reaches same witness/root proof | `TopupGatewayRootCalls.input/verify/Authenticated` and `TopupBatchRootCalls.environment` retain that replacement. Core `CLValidatorVerifier:60–85` inserts expected credentials in validator leaf1; IR829 stores the same getter result `expr_8`, then uses the complete SHA/proof loop. The new source executes the old memory runner once on this resolved environment. |
| Whole previous conclusion retained | `Guarantees/PTopupCredentialCalls.lean:12–43` reproduces the entire old `PTopupMemoryCalls.actual_root_module_memory_effects` conjunction on the same result: Success, physical Effects, actual module call/raw reply, return decoding and both allocation cursors. Source `ofBatch` preserves its world and both journals; the exact result equation connects them to the new result and preceding credential attempt. The proof at lines44–49 actually applies the old public theorem to the derived downstream success. |
| Rollback | Source `failure_restores:188–215` and public failure theorem preserve the entire input World for lengths/lookup/prefix/batch failures. Downstream failure delegates to the actual existing rollback wrapper, including successful module effects preceding a later memory error. Attempt records remain observations, not committed logs. |

I read all three new Lean files, both public statements, their proofs and tests,
the full new README/receipt/validator/compiler/vector/diagnostic sources, and the
consumed memory/root/Success/Effects definitions. I followed the complete relevant
optimized topUp path through lengths, timing/locator, getter, allocations, witness
verification, module-call construction and final history writes, plus the scalar
allocator. The preserved raw IR includes both covered and excluded operations.

The actual router getter at pinned core `sr/StakingRouter.sol:639–642` gets module
state/config then applies `_getWithdrawalCredentialsWithType` (`1046–1049`) to
physical raw credentials. This body is **not executed by the new arbitrary getter
interface**. The README explicitly says so; the reviewed new claim is actual caller
request/return consumption, not proof of router storage provenance or membership.
The later physical continuation may reread credentials after arbitrary module
changes; this increment does not establish equality with those later physical
credentials, nor does its public theorem claim it.

## Independent validation and receipt identity

- Exact diff: 28 additions only (three Lean files plus the new audit directory).
  All 27 SHA256 receipt entries match exact Git objects and working bytes.
  Parent/tree identities match the stated candidate. No shared source/wiring/pin
  change. Nonraw `git diff --check` passes; the sole unrestricted exception is
  the retained IR blank EOF, exactly raw `irOptimized` plus its appended newline.
- Ran reviewed `validation/validate.py` in its default comparison-only mode,
  redirecting output outside the candidate. PASS: **1343 sources, 11 pins,
  25 ordinary foundation-only scopes, 22 exact compiler inputs, 3 normal modules**.
  It checks actual registered import source/selected local olean identities,
  unchanged local bodies against the accepted parent, package Git pins, normal
  setup/traces and fresh named environment axiom closures. No skipKernelTC,
  synthetic trace, new axiom/sorry/native_decide/unsafe declaration is admitted.
- Reused exact normal build evidence: **1360 jobs PASS**; new source Built1.7s,
  public Built1.4s, tests Built5.8s (build.log802–821). These are actual active
  builds of the three new modules, with warm dependencies; no global All/Trust
  gate is claimed. Seventeen named kernel regressions and a concrete full public
  success instance supplement the universal success/rollback theorems.
- Compiler input/body and metadata checks pass for all22 original fixture sources
  (17 core, four OZ5.2, one unchanged harness), using solc0.8.25 viaIR optimizer200
  Cancun. Complete actual output and optimized IR agree byte-for-byte. This is
  the inspected fixture profile, not production bytecode identity.
- Read the five FFI diagnostics and archived successful execution. The positive
  case runs actual root verification over three Python-built leaves/proofs and
  the existing [1ETH,0,2ETH] physical continuation. Credential, root and proof
  corruptions reject with invalidProof; the late module-memory case rejects
  after its module attempt. Independently recomputed all three validator leaves
  and 50-word branch roots in Python from the committed binaries; also checked
  all three changed-credential variants fail the stored root. No dossier writes.
  This independent replay does not reclassify the native Lean executions as
  kernel theorem instances or as full consensus/EVM tests.
- No fresh Forge execution is claimed. The inherited seven actual Solidity tests
  and three1024-run fuzz properties remain historical evidence at their exact
  original input identities and original scope.

Independent machine-readable evidence is at
`/tmp/lido-topup-credential-f008-independent-evidence.json`; fresh read-only
validator output at `/tmp/lido-topup-credential-f008-review-validation.log`.

## Publication and integration boundaries

The following are necessary qualifications, not newly discharged obligations:
role/pause/timing/root-age/locator admission; supplied gateway/router address roles;
actual gateway→router topUp CALL/role binding and final history writes; actual
storage-backed getter body; ordinary no-code versus precompile dispatch; earlier
memory and both cursor provenance/relationship; actual memory copy/alias/opcode gas;
full outer ABI and error-byte refinement; typed SHA/root and physical hash trust;
arbitrary later module/callback behavior. These are explicitly retained in the
README and do not conceal an assumption required for the stated narrower result.

In particular, the useful proven delta is **actual getter reply → exact bytes32
and prefix → same witness/root/module/physical memory consumer**, with no added
frame, successful-stage, fit, sum, funding or alignment hypothesis. It must not be
published as a complete deployed TopUpGateway call or as authenticated router
storage credentials. Integration wiring/global gates remain root's later scope.

Reviewer STOP. No further candidate mutation or execution is pending.
