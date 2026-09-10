/// @use-src 0:"FeeCallSite.sol"
object "FeeCallSite_21" {
    code {
        {
            /// @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }"
            let _1 := memoryguard(0x80)
            mstore(64, _1)
            if callvalue() { revert(0, 0) }
            let _2 := datasize("FeeCallSite_21_deployed")
            codecopy(_1, dataoffset("FeeCallSite_21_deployed"), _2)
            return(_1, _2)
        }
    }
    /// @use-src 0:"FeeCallSite.sol"
    object "FeeCallSite_21_deployed" {
        code {
            {
                /// @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }"
                let _1 := memoryguard(0x80)
                mstore(64, _1)
                if iszero(lt(calldatasize(), 4))
                {
                    if eq(0x0b39ed47, shr(224, calldataload(0)))
                    {
                        if callvalue() { revert(0, 0) }
                        let _2 := 32
                        if slt(add(calldatasize(), not(3)), _2) { revert(0, 0) }
                        let value := calldataload(4)
                        let _3 := and(value, sub(shl(160, 1), 1))
                        if iszero(eq(value, _3)) { revert(0, 0) }
                        /// @src 0:203:233  "v.getConsolidationRequestFee()"
                        mstore(_1, /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ shl(224, 0x1e515533))
                        /// @src 0:203:233  "v.getConsolidationRequestFee()"
                        let _4 := staticcall(gas(), _3, _1, /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ 4, /** @src 0:203:233  "v.getConsolidationRequestFee()" */ _1, /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ _2)
                        /// @src 0:203:233  "v.getConsolidationRequestFee()"
                        if iszero(_4)
                        {
                            /// @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }"
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 0:203:233  "v.getConsolidationRequestFee()"
                        let expr := /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ 0
                        /// @src 0:203:233  "v.getConsolidationRequestFee()"
                        if _4
                        {
                            let _5 := /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ _2
                            /// @src 0:203:233  "v.getConsolidationRequestFee()"
                            if gt(/** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ _2, /** @src 0:203:233  "v.getConsolidationRequestFee()" */ returndatasize()) { _5 := returndatasize() }
                            /// @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }"
                            let newFreePtr := add(_1, and(add(_5, 31), not(31)))
                            if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, _1))
                            {
                                mstore(0, shl(224, 0x4e487b71))
                                mstore(4, 0x41)
                                revert(0, 0x24)
                            }
                            mstore(64, newFreePtr)
                            if slt(sub(/** @src 0:203:233  "v.getConsolidationRequestFee()" */ add(_1, _5), /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ _1), _2) { revert(0, 0) }
                            /// @src 0:203:233  "v.getConsolidationRequestFee()"
                            expr := /** @src 0:115:238  "contract FeeCallSite { function quote(IVault v) external view returns(uint256) { return v.getConsolidationRequestFee(); } }" */ mload(_1)
                        }
                        let memPos := mload(64)
                        mstore(memPos, expr)
                        return(memPos, _2)
                    }
                }
                revert(0, 0)
            }
        }
        data ".metadata" hex"a2646970667358221220efce411dab433eca48bf78a6103796950ed731f802534566ce82211c7b652e0a64736f6c63430008190033"
    }
}
