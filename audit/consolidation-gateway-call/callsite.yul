/// @use-src 0:"CallSite.sol"
object "CallSite_36" {
    code {
        {
            /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
            let _1 := memoryguard(0x80)
            mstore(64, _1)
            if callvalue() { revert(0, 0) }
            let _2 := datasize("CallSite_36_deployed")
            codecopy(_1, dataoffset("CallSite_36_deployed"), _2)
            return(_1, _2)
        }
    }
    /// @use-src 0:"CallSite.sol"
    object "CallSite_36_deployed" {
        code {
            {
                /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                mstore(64, memoryguard(0x80))
                let _1 := 4
                if iszero(lt(calldatasize(), _1))
                {
                    let _2 := 0
                    if eq(0x8f2a6f45, shr(224, calldataload(0)))
                    {
                        if callvalue() { revert(0, 0) }
                        let _3 := not(3)
                        if slt(add(calldatasize(), _3), 128) { revert(0, 0) }
                        let value := calldataload(_1)
                        let _4 := and(value, sub(shl(160, 1), 1))
                        if iszero(eq(value, _4)) { revert(0, 0) }
                        let offset := calldataload(36)
                        let _5 := 0xffffffffffffffff
                        if gt(offset, _5) { revert(0, 0) }
                        let value1 := abi_decode_array_bytes_dyn(add(_1, offset), calldatasize())
                        let offset_1 := calldataload(68)
                        if gt(offset_1, _5) { revert(0, 0) }
                        let value2 := abi_decode_array_bytes_dyn(add(_1, offset_1), calldatasize())
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        if iszero(extcodesize(_4))
                        {
                            /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                            revert(0, 0)
                        }
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        let _6 := /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ mload(64)
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        mstore(_6, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ shl(230, 0x029d6b19))
                        mstore(/** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ add(_6, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ _1), 64)
                        let tail := abi_encode_array_bytes_dyn(value1, add(/** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ _6, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ 68))
                        mstore(add(/** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ _6, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ 36), add(sub(tail, /** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ _6), /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ _3))
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        let _7 := call(gas(), _4, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ calldataload(100), /** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ _6, sub(/** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ abi_encode_array_bytes_dyn(value2, tail), /** @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)" */ _6), _6, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ 0)
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        if iszero(_7)
                        {
                            /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 0:331:418  "withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)"
                        if _7
                        {
                            /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                            if gt(_6, _5)
                            {
                                mstore(0, shl(224, 0x4e487b71))
                                mstore(_1, 0x41)
                                revert(0, 36)
                            }
                            mstore(64, _6)
                            _2 := 0
                        }
                        return(_2, _2)
                    }
                }
                revert(0, 0)
            }
            function finalize_allocation(memPtr, size)
            {
                let newFreePtr := add(memPtr, and(add(size, 31), not(31)))
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function abi_decode_array_bytes_dyn(offset, end) -> array
            {
                let _1 := 0x1f
                if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
                let _2 := calldataload(offset)
                let _3 := 0x20
                let _4 := 0xffffffffffffffff
                if gt(_2, _4)
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ shl(224, 0x4e487b71))
                    mstore(4, 0x41)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ 0x24)
                }
                let _5 := shl(5, _2)
                let _6 := 64
                let memPtr := mload(64)
                finalize_allocation(memPtr, add(_5, _3))
                let dst := memPtr
                mstore(memPtr, _2)
                dst := add(memPtr, _3)
                let srcEnd := add(add(offset, _5), _3)
                if gt(srcEnd, end)
                {
                    revert(/** @src -1:-1:-1 */ 0, 0)
                }
                /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                let src := add(offset, _3)
                for { } lt(src, srcEnd) { src := add(src, _3) }
                {
                    let innerOffset := calldataload(src)
                    if gt(innerOffset, _4)
                    {
                        revert(/** @src -1:-1:-1 */ 0, 0)
                    }
                    /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                    let _7 := add(offset, innerOffset)
                    if iszero(slt(add(_7, 63), end))
                    {
                        revert(/** @src -1:-1:-1 */ 0, 0)
                    }
                    /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                    let _8 := calldataload(add(_7, _3))
                    if gt(_8, _4)
                    {
                        mstore(/** @src -1:-1:-1 */ 0, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ shl(224, 0x4e487b71))
                        mstore(4, 0x41)
                        revert(/** @src -1:-1:-1 */ 0, /** @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }" */ 0x24)
                    }
                    let memPtr_1 := mload(_6)
                    finalize_allocation(memPtr_1, add(and(add(_8, _1), not(31)), _3))
                    mstore(memPtr_1, _8)
                    if gt(add(add(_7, _8), _6), end)
                    {
                        revert(/** @src -1:-1:-1 */ 0, 0)
                    }
                    /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                    calldatacopy(add(memPtr_1, _3), add(_7, _6), _8)
                    mstore(add(add(memPtr_1, _8), _3), /** @src -1:-1:-1 */ 0)
                    /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                    mstore(dst, memPtr_1)
                    dst := add(dst, _3)
                }
                array := memPtr
            }
            function abi_encode_array_bytes_dyn(value, pos) -> end
            {
                let pos_1 := pos
                let length := mload(value)
                mstore(pos, length)
                let _1 := 0x20
                pos := add(pos, _1)
                let tail := add(add(pos_1, shl(5, length)), _1)
                let srcPtr := add(value, _1)
                let i := /** @src -1:-1:-1 */ 0
                /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                for { } lt(i, length) { i := add(i, 1) }
                {
                    let _2 := not(31)
                    mstore(pos, add(sub(tail, pos_1), _2))
                    let _3 := mload(srcPtr)
                    let length_1 := mload(_3)
                    mstore(tail, length_1)
                    mcopy(add(tail, _1), add(_3, _1), length_1)
                    mstore(add(add(tail, length_1), _1), /** @src -1:-1:-1 */ 0)
                    /// @src 0:171:423  "contract CallSite { function execute(IWithdrawalVault withdrawalVault, bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys, uint256 totalFee) external { withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys); } }"
                    tail := add(add(tail, and(add(length_1, 31), _2)), _1)
                    srcPtr := add(srcPtr, _1)
                    pos := add(pos, _1)
                }
                end := tail
            }
        }
        data ".metadata" hex"a26469706673582212200dbc71f5d104924f7ab63672ad528ddde6e3b619c7082929475d061458ffb86564736f6c63430008190033"
    }
}
