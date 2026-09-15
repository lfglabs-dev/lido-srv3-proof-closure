# I-TRUST-COMPILER-KERNEL — OPEN

The authorized axiom set is exactly `propext`, `Quot.sound`, `Classical.choice`.
The three names in `trust-native-decide-allowlist.txt` remain emitted dependencies,
not approved exceptions. They belong to these unchanged compilation witnesses:

- `AllocCapacityPhase3.consumed_summary_function_spec_compiles`
- `SszAbstractDigest.deposit_data_root_compiles`
- `ConsolidationAbstractFlowModel.forward_compiles`

All three still assert success of the actual pinned `CompilationModel.compile`.
No compilation claim, registered row, or Trust print has been removed. The stricter
trust gate rejects these dependencies even after authentic recomputation and native
Boolean reevaluation. This repairs policy enforcement; it does not eliminate them.

At Verity `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`,
`Compiler/CompilationModel/ScopeValidation.lean:55,64` calls
`staticParamBindingNames`. `Compiler/CompilationModel/InternalArgs.lean:6,30`
defines that helper and `internalParamYulNamesForType` using `partial def`.
The pinned source exposes no kernel reduction equations for those helpers in the
paths inspected. A prior direct kernel-decision attempt at `b164f2e72796aae7c7da1411b0cf6be2401cf9c8`
failed in registered job `b33c8f90-856b-43fb-9148-bd853185bf18`; its original proofs
were restored, not relabeled foundational. Repeating it unchanged is not a repair.

Remaining work is a kernel-checkable proof of the same compiler result, including
the opaque validation helpers it consumes. A total/equational compiler change
requires separately declared linked-dependency PR ownership and validation; this
writer has not edited the pinned dependency or claimed that ownership. There is
no premise assuming the desired compilation result. Runtime/deployment and
supported-module reachability obligations are separate and remain open.
