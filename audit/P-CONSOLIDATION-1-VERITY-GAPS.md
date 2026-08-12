# P-CONSOLIDATION-1 Verity framework gaps

PR #46 is a source-shaped bounded `FunctionSpec` scaffold, not a faithful
source/transaction proof.  At Verity pin `f485b2ca7502793ce227ede0076b7d070a0697b7`,
the following connections required for certification are unavailable:

1. `CallProgram` has external-call observations but no event/log instruction or
   observation, so event-after-success and log rollback cannot be stated over
   the same execution trace.
2. There is no semantics-preservation theorem connecting a compiled
   `FunctionSpec` containing dynamic `bytes[]` ABI loaders, calldata copy,
   low-level calls, and logs to `CallProgram`, `CallsIn`, or `ObservedCalls`.
3. `DenoteMemory` is a separate byte-memory model.  It has no theorem linking
   `arrayElementDynamicDataOffset`/`calldataload`/`calldatacopy` in the actual
   `FunctionSpec` to `MemoryRequest`, `validRequest`, `requestMemory`, or
   `requestSite` in this scaffold.
4. `CallProgramRollback` has no transaction-frame operator.  Consequently it
   cannot undo earlier successful mutable calls or logs after a later failure.
5. The source `preservesEthBalance` assertion is representable syntactically in
   `FunctionSpec`, but the external-call `CallState` theorem surface has no
   connection to that function's `selfBalance` assertion or its rollback.
6. Local-obligation statuses are metadata and do not accept a theorem witness.
   The dynamic ABI loader obligation therefore remains `unchecked` until a
   connecting theorem exists.

The negative mutants requested for call target/value/payload/memory and ABI
length/value guards cannot certify source adequacy until items 1--3 exist.
Testing a second handwritten `CallProgram` against the first would only compare
two models and would not reject a corresponding mutation in the registered
`FunctionSpec`.
