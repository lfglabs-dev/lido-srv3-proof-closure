# Source return guards and actual output-buffer checks

Four solc0.8.25 tests pass, including two properties with1024 fuzz runs each at seed0x20260909. The harness imports the unmodified BLS pubkey/pair helpers and SSZ.verifyProof. It does not alter their guards or output buffers.

One property mocks the exact64-byte call to address2 with successful return data of length0–64. BLS accepts exactly32 bytes and otherwise produces its actual four-byte Sha256PrecompileFailed selector. The actual SSZ one-sibling/index2 fold has only a success-flag guard: its computed first word consists of the returned prefix up to32 followed by the original left scratch bytes. It accepts that independently reconstructed residual word and rejects a one-bit-changed expected root. The pubkey helper receives the same length cases on its exact key48++zero16 input. Another test forces the actual call flag false: BLS returns its selector while SSZ returns empty revert bytes.

These address2 responses are **synthetic fault injection**, not the standard SHA precompile's possible outputs, an observed deployment defect, an exploit or proof of the opaque EvmYul FFI implementation. They establish finite behavior of the actual source guards and caller buffer under injected replies. Mocks are explicitly cleared between source call groups. An additional test executes both BLS helpers with the real SHA precompile and compares their overlapping-buffer results to builtin SHA on independently assembled inputs.

The second fuzz property uses the real identity precompile at address4 with input lengths0–64, independent dirty first/second words and a32-byte caller output buffer. It checks exact returned length, overwrite of min(length,32) bytes, preservation of the remaining first-word bytes and the entire second word. This separate generic CALL-shape fixture is not a BLS function or SHA model. It complements the formal EvmYul engine result without replacing it with a fake SHA callback.

The checks do not prove cryptographic correctness, universal FFI length, gas sufficiency, exact EvmYul-to-Foundry equivalence, arbitrary memory frames, activeWords reachability, whole verifier/ABI execution or deployment identity. In particular the formal activeWords multiplication boundary is not a Solidity memory-state test here.

Executed from the proof checkout with Forge1.5.0 and repository foundry.toml:

```sh
FOUNDRY_SRC=audit/ssz-sha-call-memory/solidity FOUNDRY_TEST=audit/ssz-sha-call-memory/solidity forge test --remappings contracts/=lido-core/contracts/ --match-contract SszShaCallMemoryTest --fuzz-runs 1024 --fuzz-seed 0x20260909 --out /tmp/lido-ssz-sha-call-solidity-out --cache-path /tmp/lido-ssz-sha-call-solidity-cache -vv
```

receipt.json records the exact command, compiler-consumed sources/configuration and three artifact hashes. validation.log is the actual exit0 run; no external package install was required.
