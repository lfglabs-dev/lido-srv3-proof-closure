/// @use-src 0:"audit/ssz-bls-composition/solidity/SszBlsComposition.t.sol", 1:"lido-core/contracts/0.8.25/CLValidatorVerifier.sol", 5:"lido-core/contracts/common/lib/GIndex.sol"
object "BlsCompositionHarness_87" {
    code {
        {
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            let _1 := memoryguard(0x0100)
            mstore(64, _1)
            if callvalue() { revert(0, 0) }
            /// @src 1:745:814  "pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH)"
            mstore(128, /** @src 5:877:890  "(gI << 8) | p" */ 2819)
            let _2 := 0x96000000000028
            /// @src 1:1462:1509  "GI_FIRST_VALIDATOR_PREV = _gIFirstValidatorPrev"
            mstore(160, /** @src 5:877:890  "(gI << 8) | p" */ _2)
            /// @src 1:1519:1566  "GI_FIRST_VALIDATOR_CURR = _gIFirstValidatorCurr"
            mstore(192, /** @src 5:877:890  "(gI << 8) | p" */ _2)
            /// @src 1:1576:1599  "PIVOT_SLOT = _pivotSlot"
            mstore(224, /** @src 0:892:893  "0" */ 0x00)
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            let _3 := datasize("BlsCompositionHarness_87_deployed")
            codecopy(_1, dataoffset("BlsCompositionHarness_87_deployed"), _3)
            setimmutable(_1, "1241", mload(/** @src 1:745:814  "pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH)" */ 128))
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            setimmutable(_1, "1250", mload(/** @src 1:1462:1509  "GI_FIRST_VALIDATOR_PREV = _gIFirstValidatorPrev" */ 160))
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            setimmutable(_1, "1253", mload(/** @src 1:1519:1566  "GI_FIRST_VALIDATOR_CURR = _gIFirstValidatorCurr" */ 192))
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            setimmutable(_1, "1255", mload(/** @src 1:1576:1599  "PIVOT_SLOT = _pivotSlot" */ 224))
            /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
            return(_1, _3)
        }
    }
    /// @use-src 0:"audit/ssz-bls-composition/solidity/SszBlsComposition.t.sol", 1:"lido-core/contracts/0.8.25/CLValidatorVerifier.sol", 3:"lido-core/contracts/common/lib/BLS.sol", 5:"lido-core/contracts/common/lib/GIndex.sol", 6:"lido-core/contracts/common/lib/SSZ.sol"
    object "BlsCompositionHarness_87_deployed" {
        code {
            {
                /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                let _1 := memoryguard(0x80)
                let _2 := 64
                mstore(_2, _1)
                let _3 := 4
                if iszero(lt(calldatasize(), _3))
                {
                    switch shr(224, calldataload(0))
                    case 0x2f8d5149 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        mstore(_1, /** @src 1:705:814  "GIndex public immutable GI_STATE_ROOT = pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH)" */ loadimmutable("1241"))
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        return(_1, 32)
                    }
                    case 0x3a5e31fe {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos := mload(_2)
                        mstore(memPos, /** @src 1:1215:1262  "GIndex public immutable GI_FIRST_VALIDATOR_CURR" */ loadimmutable("1253"))
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        return(memPos, 32)
                    }
                    case 0x3bd227c1 {
                        if callvalue() { revert(0, 0) }
                        let _4 := not(3)
                        if slt(add(calldatasize(), _4), 128) { revert(0, 0) }
                        let offset := calldataload(_3)
                        let _5 := 0xffffffffffffffff
                        if gt(offset, _5) { revert(0, 0) }
                        let _6 := sub(calldatasize(), offset)
                        let _7 := 256
                        if slt(add(_6, _4), _7) { revert(0, 0) }
                        let _8 := 36
                        let memPtr := mload(_2)
                        let newFreePtr := add(memPtr, _7)
                        if or(gt(newFreePtr, _5), lt(newFreePtr, memPtr))
                        {
                            mstore(0, shl(224, 0x4e487b71))
                            mstore(_3, 0x41)
                            revert(0, _8)
                        }
                        mstore(_2, newFreePtr)
                        calldatacopy(memPtr, calldatasize(), _7)
                        let rel_offset_of_tail := calldataload(/** @src 1:2750:2759  "_w.pubkey" */ add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, _8))
                        let _9 := add(_6, not(34))
                        if iszero(slt(rel_offset_of_tail, _9)) { revert(0, 0) }
                        let _10 := add(offset, rel_offset_of_tail)
                        let length := calldataload(add(_10, _3))
                        if gt(length, _5) { revert(0, 0) }
                        let addr := add(_10, _8)
                        if sgt(addr, sub(calldatasize(), length)) { revert(0, 0) }
                        /// @src 3:24956:25009  "if (pubkey.length != 48) revert InvalidPubkeyLength()"
                        if /** @src 3:24960:24979  "pubkey.length != 48" */ iszero(eq(length, /** @src 3:24977:24979  "48" */ 0x30))
                        /// @src 3:24956:25009  "if (pubkey.length != 48) revert InvalidPubkeyLength()"
                        {
                            /// @src 3:24988:25009  "InvalidPubkeyLength()"
                            let _11 := /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(_2)
                            /// @src 3:24988:25009  "InvalidPubkeyLength()"
                            mstore(_11, shl(224, 0x9ca717ed))
                            revert(_11, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                        }
                        let _12 := 32
                        /// @src 3:25063:25762  "assembly {..."
                        mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _12, 0)
                        /// @src 3:25063:25762  "assembly {..."
                        calldatacopy(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 3:25063:25762  "assembly {..." */ addr, /** @src 3:24977:24979  "48" */ 0x30)
                        /// @src 3:25063:25762  "assembly {..."
                        let usr$success := staticcall(gas(), 0x02, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, _2, 0, _12)
                        /// @src 3:25063:25762  "assembly {..."
                        if iszero(and(usr$success, eq(returndatasize(), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _12)))
                        /// @src 3:25063:25762  "assembly {..."
                        {
                            mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 3:25063:25762  "assembly {..." */ 0xdd5cab3e)
                            revert(0x1c, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                        }
                        mstore(memPtr, /** @src 3:25063:25762  "assembly {..." */ mload(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0))
                        let addr_1 := add(memPtr, _12)
                        mstore(addr_1, calldataload(_8))
                        /// @src 1:2834:2873  "SSZ.toLittleEndian(_w.effectiveBalance)"
                        let expr := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:2853:2872  "_w.effectiveBalance" */ read_from_calldatat_uint64(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, 68)), _5))
                        let addr_2 := add(memPtr, _2)
                        mstore(addr_2, expr)
                        let value := calldataload(/** @src 1:2914:2924  "_w.slashed" */ add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, /** @src 1:2914:2924  "_w.slashed" */ 228))
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        if iszero(eq(value, iszero(iszero(value)))) { revert(0, 0) }
                        /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        let expr_1 := /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0
                        /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        switch value
                        case 0 {
                            expr_1 := /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0
                        }
                        default /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        {
                            expr_1 := /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 1
                        }
                        /// @src 1:2895:2941  "SSZ.toLittleEndian(_w.slashed ? uint64(1) : 0)"
                        let expr_2 := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:2895:2941  "SSZ.toLittleEndian(_w.slashed ? uint64(1) : 0)" */ expr_1, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _5))
                        let addr_3 := add(memPtr, 96)
                        mstore(addr_3, expr_2)
                        /// @src 1:2963:3012  "SSZ.toLittleEndian(_w.activationEligibilityEpoch)"
                        let expr_3 := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:2982:3011  "_w.activationEligibilityEpoch" */ read_from_calldatat_uint64(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, 100)), _5))
                        let addr_4 := add(memPtr, 128)
                        mstore(addr_4, expr_3)
                        /// @src 1:3034:3072  "SSZ.toLittleEndian(_w.activationEpoch)"
                        let expr_4 := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:3053:3071  "_w.activationEpoch" */ read_from_calldatat_uint64(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, /** @src 1:3053:3071  "_w.activationEpoch" */ 132)), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _5))
                        let addr_5 := add(memPtr, 160)
                        mstore(addr_5, expr_4)
                        /// @src 1:3094:3126  "SSZ.toLittleEndian(_w.exitEpoch)"
                        let expr_5 := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:3113:3125  "_w.exitEpoch" */ read_from_calldatat_uint64(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, /** @src 1:3113:3125  "_w.exitEpoch" */ 164)), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _5))
                        let addr_6 := add(memPtr, 192)
                        mstore(addr_6, expr_5)
                        /// @src 1:3148:3188  "SSZ.toLittleEndian(_w.withdrawableEpoch)"
                        let expr_6 := fun_toLittleEndian(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(/** @src 1:3167:3187  "_w.withdrawableEpoch" */ read_from_calldatat_uint64(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ offset, /** @src 1:3167:3187  "_w.withdrawableEpoch" */ 196)), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _5))
                        let addr_7 := add(memPtr, 224)
                        mstore(addr_7, expr_6)
                        let memPtr_1 := mload(_2)
                        let newFreePtr_1 := add(memPtr_1, 128)
                        if or(gt(newFreePtr_1, _5), lt(newFreePtr_1, memPtr_1))
                        {
                            mstore(0, shl(224, 0x4e487b71))
                            mstore(_3, 0x41)
                            revert(0, _8)
                        }
                        mstore(_2, newFreePtr_1)
                        calldatacopy(memPtr_1, calldatasize(), 128)
                        let _13 := mload(memPtr)
                        mstore(memPtr_1, /** @src 1:3237:3279  "BLS12_381.sha256Pair(leaves[0], leaves[1])" */ fun_sha256Pair(_13, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_1)))
                        let _14 := mload(addr_2)
                        /// @src 1:3297:3339  "BLS12_381.sha256Pair(leaves[2], leaves[3])"
                        let _15 := fun_sha256Pair(_14, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_3))
                        let addr_8 := add(memPtr_1, _12)
                        mstore(addr_8, _15)
                        let _16 := mload(addr_4)
                        /// @src 1:3357:3399  "BLS12_381.sha256Pair(leaves[4], leaves[5])"
                        let _17 := fun_sha256Pair(_16, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_5))
                        let addr_9 := add(memPtr_1, _2)
                        mstore(addr_9, _17)
                        let _18 := mload(addr_6)
                        /// @src 1:3417:3459  "BLS12_381.sha256Pair(leaves[6], leaves[7])"
                        let _19 := fun_sha256Pair(_18, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_7))
                        let addr_10 := add(memPtr_1, 96)
                        mstore(addr_10, _19)
                        let memPtr_2 := mload(_2)
                        let newFreePtr_2 := add(memPtr_2, _2)
                        if or(gt(newFreePtr_2, _5), lt(newFreePtr_2, memPtr_2))
                        {
                            mstore(0, shl(224, 0x4e487b71))
                            mstore(_3, 0x41)
                            revert(0, _8)
                        }
                        mstore(_2, newFreePtr_2)
                        calldatacopy(memPtr_2, calldatasize(), _2)
                        let _20 := mload(memPtr_1)
                        mstore(memPtr_2, /** @src 1:3508:3542  "BLS12_381.sha256Pair(l1[0], l1[1])" */ fun_sha256Pair(_20, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_8)))
                        let _21 := mload(addr_9)
                        /// @src 1:3560:3594  "BLS12_381.sha256Pair(l1[2], l1[3])"
                        let _22 := fun_sha256Pair(_21, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(addr_10))
                        mstore(add(memPtr_2, _12), _22)
                        /// @src 1:3605:3646  "return BLS12_381.sha256Pair(l2[0], l2[1])"
                        let var := /** @src 1:3612:3646  "BLS12_381.sha256Pair(l2[0], l2[1])" */ fun_sha256Pair(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ mload(memPtr_2), /** @src 1:3640:3645  "l2[1]" */ _22)
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        let rel_offset_of_tail_1 := calldataload(add(_3, offset))
                        if iszero(slt(rel_offset_of_tail_1, _9)) { revert(0, 0) }
                        let _23 := add(offset, rel_offset_of_tail_1)
                        let length_1 := calldataload(add(_23, _3))
                        if gt(length_1, _5) { revert(0, 0) }
                        let addr_11 := add(_23, _8)
                        let _24 := 5
                        let _25 := shl(5, length_1)
                        if sgt(addr_11, sub(calldatasize(), _25)) { revert(0, 0) }
                        /// @src 0:1104:1106  "gi"
                        let var_leaf := var
                        /// @src 6:5868:5894  "uint256 index = gI.index()"
                        let var_index := /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ shr(8, calldataload(100))
                        /// @src 6:5948:8617  "assembly {..."
                        if iszero(length_1)
                        {
                            mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x09bde339)
                            revert(0x1c, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                        }
                        /// @src 6:5948:8617  "assembly {..."
                        let usr$end := add(add(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _23, /** @src 6:5948:8617  "assembly {..." */ _25), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _8)
                        /// @src 6:5948:8617  "assembly {..."
                        let usr$offset := addr_11
                        for { }
                        /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 1
                        /// @src 6:5948:8617  "assembly {..."
                        { }
                        {
                            let usr$scratch := and(shl(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _24, /** @src 6:5948:8617  "assembly {..." */ var_index), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _12)
                            /// @src 6:5948:8617  "assembly {..."
                            var_index := shr(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 1, /** @src 6:5948:8617  "assembly {..." */ var_index)
                            if iszero(var_index)
                            {
                                mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x5849603f)
                                revert(0x1c, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                            }
                            /// @src 6:5948:8617  "assembly {..."
                            mstore(usr$scratch, var_leaf)
                            mstore(xor(usr$scratch, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _12), /** @src 6:5948:8617  "assembly {..." */ calldataload(usr$offset))
                            if iszero(staticcall(gas(), /** @src 3:25063:25762  "assembly {..." */ 0x02, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, _2, 0, _12))
                            /// @src 6:5948:8617  "assembly {..."
                            {
                                revert(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, 0)
                            }
                            /// @src 6:5948:8617  "assembly {..."
                            var_leaf := mload(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0)
                            /// @src 6:5948:8617  "assembly {..."
                            usr$offset := add(usr$offset, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _12)
                            /// @src 6:5948:8617  "assembly {..."
                            if iszero(lt(usr$offset, usr$end)) { break }
                        }
                        if iszero(eq(var_index, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 1))
                        /// @src 6:5948:8617  "assembly {..."
                        {
                            mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x1b6661c3)
                            revert(0x1c, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                        }
                        /// @src 6:5948:8617  "assembly {..."
                        if iszero(eq(var_leaf, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ calldataload(68)))
                        /// @src 6:5948:8617  "assembly {..."
                        {
                            mstore(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x09bde339)
                            revert(0x1c, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ _3)
                        }
                        return(0, 0)
                    }
                    case 0x562d7d67 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_1 := mload(_2)
                        mstore(memPos_1, /** @src 1:1162:1209  "GIndex public immutable GI_FIRST_VALIDATOR_PREV" */ loadimmutable("1250"))
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        return(memPos_1, 32)
                    }
                    case 0x56d7e8fd {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_2 := mload(_2)
                        mstore(memPos_2, /** @src 1:1053:1095  "0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02" */ 0x0f3df6d732807ef1319fb7b8bb8522d0beac02)
                        /// @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..."
                        return(memPos_2, 32)
                    }
                    case 0x8f60eab9 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_3 := mload(_2)
                        mstore(memPos_3, and(/** @src 1:1268:1302  "uint64 public immutable PIVOT_SLOT" */ loadimmutable("1255"), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0xffffffffffffffff))
                        return(memPos_3, 32)
                    }
                }
                revert(0, 0)
            }
            function read_from_calldatat_uint64(ptr) -> returnValue
            {
                let value := calldataload(ptr)
                if iszero(eq(value, and(value, 0xffffffffffffffff))) { revert(0, 0) }
                returnValue := value
            }
            /// @ast-id 2927 @src 6:8747:9687  "function toLittleEndian(uint256 v) internal pure returns (bytes32) {..."
            function fun_toLittleEndian(var_v) -> var
            {
                /// @src 6:8840:9013  "((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |..."
                let expr := or(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:8917:8918  "8" */ 0x08, /** @src 6:8842:8912  "v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00" */ var_v), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff), and(shl(/** @src 6:8917:8918  "8" */ 0x08, /** @src 6:8936:9006  "v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF" */ var_v), /** @src 6:8846:8912  "0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00" */ 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00))
                /// @src 6:9039:9214  "((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |..."
                let expr_1 := or(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9116:9118  "16" */ 0x10, /** @src 6:9041:9111  "v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000" */ expr), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff), and(shl(/** @src 6:9116:9118  "16" */ 0x10, /** @src 6:9136:9206  "v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF" */ expr), /** @src 6:9045:9111  "0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000" */ 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000))
                /// @src 6:9240:9415  "((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |..."
                let expr_2 := or(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9317:9319  "32" */ 0x20, /** @src 6:9242:9312  "v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000" */ expr_1), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff), and(shl(/** @src 6:9317:9319  "32" */ 0x20, /** @src 6:9337:9407  "v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF" */ expr_1), /** @src 6:9246:9312  "0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000" */ 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000))
                /// @src 6:9441:9616  "((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |..."
                let expr_3 := or(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9518:9520  "64" */ 0x40, /** @src 6:9443:9513  "v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000" */ expr_2), /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ 0xffffffffffffffff0000000000000000ffffffffffffffff), and(shl(/** @src 6:9518:9520  "64" */ 0x40, /** @src 6:9538:9608  "v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF" */ expr_2), /** @src 6:9447:9513  "0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000" */ not(0xffffffffffffffff0000000000000000ffffffffffffffff)))
                /// @src 6:9663:9680  "return bytes32(v)"
                var := /** @src 6:9630:9653  "(v >> 128) | (v << 128)" */ or(/** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ shr(/** @src 6:9636:9639  "128" */ 0x80, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ expr_3), shl(/** @src 6:9636:9639  "128" */ 0x80, /** @src 0:760:1116  "contract BlsCompositionHarness is CLValidatorVerifier {..." */ expr_3))
            }
            /// @ast-id 2272 @src 3:23923:24692  "function sha256Pair(bytes32 left, bytes32 right) internal view returns (bytes32 result) {..."
            function fun_sha256Pair(var_left, var_right) -> var_result
            {
                /// @src 3:24064:24686  "assembly {..."
                mstore(0x00, var_left)
                mstore(0x20, var_right)
                let usr$success := staticcall(gas(), 0x02, 0x00, 0x40, 0x00, 0x20)
                if iszero(and(usr$success, eq(returndatasize(), 0x20)))
                {
                    mstore(0x00, 0xdd5cab3e)
                    revert(0x1c, 0x04)
                }
                var_result := mload(0x00)
            }
        }
        data ".metadata" hex"a26469706673582212206077d847b80043685a58dd664dd48fe699db5a785359438ab827b181325a4e5d64736f6c63430008190033"
    }
}

