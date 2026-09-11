/// @use-src 0:"audit/ssz-root-call-composition/solidity/SszRootCall.t.sol", 1:"lido-core/contracts/0.8.25/CLValidatorVerifier.sol", 5:"lido-core/contracts/common/lib/GIndex.sol"
object "SszRootCallHarness_73" {
    code {
        {
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
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
            mstore(224, /** @src 0:760:761  "0" */ 0x00)
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
            let _3 := datasize("SszRootCallHarness_73_deployed")
            codecopy(_1, dataoffset("SszRootCallHarness_73_deployed"), _3)
            setimmutable(_1, "982", mload(/** @src 1:745:814  "pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH)" */ 128))
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
            setimmutable(_1, "991", mload(/** @src 1:1462:1509  "GI_FIRST_VALIDATOR_PREV = _gIFirstValidatorPrev" */ 160))
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
            setimmutable(_1, "994", mload(/** @src 1:1519:1566  "GI_FIRST_VALIDATOR_CURR = _gIFirstValidatorCurr" */ 192))
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
            setimmutable(_1, "996", mload(/** @src 1:1576:1599  "PIVOT_SLOT = _pivotSlot" */ 224))
            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
            return(_1, _3)
        }
    }
    /// @use-src 0:"audit/ssz-root-call-composition/solidity/SszRootCall.t.sol", 1:"lido-core/contracts/0.8.25/CLValidatorVerifier.sol", 3:"lido-core/contracts/common/lib/BLS.sol", 5:"lido-core/contracts/common/lib/GIndex.sol", 6:"lido-core/contracts/common/lib/SSZ.sol"
    object "SszRootCallHarness_73_deployed" {
        code {
            {
                /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                let _1 := 64
                mstore(_1, memoryguard(0x80))
                let _2 := 4
                if iszero(lt(calldatasize(), _2))
                {
                    switch shr(224, calldataload(0))
                    case 0x2e77b4ba {
                        if callvalue() { revert(0, 0) }
                        let _3 := not(3)
                        let _4 := add(calldatasize(), _3)
                        if slt(_4, 192) { revert(0, 0) }
                        if slt(_4, 96) { revert(0, 0) }
                        let offset := calldataload(100)
                        let _5 := 0xffffffffffffffff
                        if gt(offset, _5) { revert(0, 0) }
                        let _6 := add(_2, offset)
                        let _7 := sub(calldatasize(), offset)
                        let _8 := 256
                        if slt(add(_7, _3), _8) { revert(0, 0) }
                        let value := calldataload(132)
                        /// @src 1:1935:1953  "_vw.proofValidator"
                        let expr_offset, expr_length := access_calldata_tail_array_bytes32_dyn_calldata(_6, _6)
                        /// @src 1:1955:1975  "_beaconRootData.slot"
                        let expr := read_from_calldatat_uint64_10616()
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let value_1 := calldataload(/** @src 1:1977:2006  "_beaconRootData.proposerIndex" */ 68)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let _9 := and(value_1, _5)
                        if iszero(eq(value_1, _9)) { revert(0, 0) }
                        /// @src 1:3920:3945  "SSZ.toLittleEndian(_slot)"
                        let expr_1 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:3920:3945  "SSZ.toLittleEndian(_slot)" */ expr, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5))
                        /// @src 1:3899:3982  "BLS12_381.sha256Pair(SSZ.toLittleEndian(_slot), SSZ.toLittleEndian(_proposerIndex))"
                        let expr_2 := fun_sha256Pair(expr_1, /** @src 1:3947:3981  "SSZ.toLittleEndian(_proposerIndex)" */ fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _9))
                        /// @src 1:975:976  "2"
                        let diff := add(expr_length, not(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 1))
                        /// @src 1:975:976  "2"
                        if gt(diff, expr_length)
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2, /** @src 1:975:976  "2" */ 0x11)
                            revert(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        }
                        /// @src 1:975:976  "2"
                        if iszero(lt(diff, expr_length))
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2, /** @src 1:975:976  "2" */ 0x32)
                            revert(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        }
                        /// @src 1:975:976  "2"
                        let _10 := 5
                        /// @src 1:3992:4122  "if (_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer) {..."
                        if /** @src 1:3996:4075  "_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer" */ iszero(eq(/** @src 1:975:976  "2" */ calldataload(add(expr_offset, shl(5, diff))), /** @src 1:3996:4075  "_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer" */ expr_2))
                        /// @src 1:3992:4122  "if (_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer) {..."
                        {
                            /// @src 1:4098:4111  "InvalidSlot()"
                            let _11 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                            /// @src 1:4098:4111  "InvalidSlot()"
                            mstore(_11, shl(224, 0x1258e443))
                            revert(_11, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        let value_2 := calldataload(_2)
                        let _12 := and(value_2, _5)
                        if iszero(eq(value_2, _12)) { revert(0, 0) }
                        /// @src 1:4664:4696  "abi.encode(_childBlockTimestamp)"
                        let expr_mpos := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                        /// @src 1:1955:1975  "_beaconRootData.slot"
                        let _13 := 32
                        /// @src 1:4664:4696  "abi.encode(_childBlockTimestamp)"
                        let _14 := add(expr_mpos, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        mstore(_14, _12)
                        /// @src 1:4664:4696  "abi.encode(_childBlockTimestamp)"
                        mstore(expr_mpos, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 1:4664:4696  "abi.encode(_childBlockTimestamp)"
                        finalize_allocation(expr_mpos)
                        /// @src 1:4640:4697  "BEACON_ROOTS.staticcall(abi.encode(_childBlockTimestamp))"
                        let expr_component := staticcall(gas(), /** @src 1:1053:1095  "0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02" */ 0x0f3df6d732807ef1319fb7b8bb8522d0beac02, /** @src 1:4640:4697  "BEACON_ROOTS.staticcall(abi.encode(_childBlockTimestamp))" */ _14, mload(expr_mpos), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, 0)
                        /// @src 1:4640:4697  "BEACON_ROOTS.staticcall(abi.encode(_childBlockTimestamp))"
                        let data := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0
                        switch returndatasize()
                        case 0 { data := 96 }
                        default {
                            let _15 := returndatasize()
                            if gt(_15, _5)
                            {
                                mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                                /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                                mstore(_2, 0x41)
                                revert(0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                            }
                            /// @src 1:4664:4696  "abi.encode(_childBlockTimestamp)"
                            let _16 := not(31)
                            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                            let memPtr := mload(_1)
                            let newFreePtr := add(memPtr, and(add(and(add(_15, 31), /** @src 1:4664:4696  "abi.encode(_childBlockTimestamp)" */ _16), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 63), /** @src 1:4664:4696  "abi.encode(_childBlockTimestamp)" */ _16))
                            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                            if or(gt(newFreePtr, _5), lt(newFreePtr, memPtr))
                            {
                                mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                                /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                                mstore(_2, 0x41)
                                revert(0, 0x24)
                            }
                            mstore(_1, newFreePtr)
                            mstore(memPtr, _15)
                            data := memPtr
                            returndatacopy(add(memPtr, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, returndatasize())
                        }
                        /// @src 1:4711:4739  "!success || data.length == 0"
                        let expr_3 := /** @src 1:4711:4719  "!success" */ iszero(expr_component)
                        /// @src 1:4711:4739  "!success || data.length == 0"
                        if /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ iszero(/** @src 1:4711:4719  "!success" */ expr_3)
                        /// @src 1:4711:4739  "!success || data.length == 0"
                        {
                            expr_3 := /** @src 1:4723:4739  "data.length == 0" */ iszero(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(/** @src 1:4723:4734  "data.length" */ data))
                        }
                        /// @src 1:4707:4762  "if (!success || data.length == 0) revert RootNotFound()"
                        if expr_3
                        {
                            /// @src 1:4748:4762  "RootNotFound()"
                            let _17 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                            /// @src 1:4748:4762  "RootNotFound()"
                            mstore(_17, shl(224, 0x3033b0ff))
                            revert(_17, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        if slt(sub(/** @src 1:4779:4806  "abi.decode(data, (bytes32))" */ add(data, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(/** @src 1:4779:4806  "abi.decode(data, (bytes32))" */ data)), data), /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        { revert(0, 0) }
                        let value_3 := mload(/** @src 1:4779:4806  "abi.decode(data, (bytes32))" */ add(data, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13))
                        /// @src 1:2191:2211  "_beaconRootData.slot"
                        let _18 := read_from_calldatat_uint64_10616()
                        /// @src 1:4311:4387  "_provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR"
                        let expr_4 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0
                        /// @src 1:4311:4387  "_provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR"
                        switch /** @src 1:4311:4335  "_provenSlot < PIVOT_SLOT" */ lt(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:4311:4335  "_provenSlot < PIVOT_SLOT" */ _18, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5), and(/** @src 1:4325:4335  "PIVOT_SLOT" */ loadimmutable("996"), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5))
                        case /** @src 1:4311:4387  "_provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR" */ 0 {
                            expr_4 := /** @src 1:4364:4387  "GI_FIRST_VALIDATOR_CURR" */ loadimmutable("994")
                        }
                        default /// @src 1:4311:4387  "_provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR"
                        {
                            expr_4 := /** @src 1:4338:4361  "GI_FIRST_VALIDATOR_PREV" */ loadimmutable("991")
                        }
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let result := shr(/** @src 5:1158:1159  "8" */ 0x08, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ expr_4)
                        let converted := and(expr_4, 0xff)
                        let _19 := 1
                        let result_1 := shl(converted, _19)
                        if iszero(result_1)
                        {
                            mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                            mstore(_2, 0x12)
                            revert(0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        }
                        /// @src 5:1540:1603  "if ((i % w) + n >= w) {..."
                        if /** @src 5:1544:1560  "(i % w) + n >= w" */ iszero(lt(/** @src 5:1544:1555  "(i % w) + n" */ checked_add_uint256(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mod(result, result_1), /** @src 5:1544:1555  "(i % w) + n" */ value), /** @src 5:1544:1560  "(i % w) + n >= w" */ result_1))
                        /// @src 5:1540:1603  "if ((i % w) + n >= w) {..."
                        {
                            /// @src 5:1579:1596  "IndexOutOfRange()"
                            let _20 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                            /// @src 5:1579:1596  "IndexOutOfRange()"
                            mstore(_20, shl(224, 0x1390f2a1))
                            revert(_20, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        /// @src 5:1609:1638  "return pack(i + n, pow(self))"
                        let var := /** @src 5:1616:1638  "pack(i + n, pow(self))" */ fun_pack(/** @src 5:1621:1626  "i + n" */ checked_add_uint256(result, value), /** @src 5:1307:1335  "uint8(uint256(unwrap(self)))" */ converted)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let result_2 := shr(/** @src 5:1158:1159  "8" */ 0x08, /** @src 1:2143:2156  "GI_STATE_ROOT" */ loadimmutable("982"))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let result_3 := shr(/** @src 5:1158:1159  "8" */ 0x08, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ var)
                        /// @src 5:2217:2228  "fls(lindex)"
                        let expr_5 := fun_fls(result_2)
                        /// @src 5:2256:2267  "fls(rindex)"
                        let expr_6 := fun_fls(result_3)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        let sum := add(expr_5, _19)
                        if gt(expr_5, sum)
                        {
                            /// @src 1:975:976  "2"
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2, /** @src 1:975:976  "2" */ 0x11)
                            revert(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        }
                        /// @src 5:2274:2356  "if (lhsMSbIndex + 1 + rhsMSbIndex > 248) {..."
                        if /** @src 5:2278:2313  "lhsMSbIndex + 1 + rhsMSbIndex > 248" */ gt(/** @src 5:2278:2307  "lhsMSbIndex + 1 + rhsMSbIndex" */ checked_add_uint256(/** @src 5:2278:2293  "lhsMSbIndex + 1" */ sum, /** @src 5:2278:2307  "lhsMSbIndex + 1 + rhsMSbIndex" */ expr_6), /** @src 5:2310:2313  "248" */ 0xf8)
                        /// @src 5:2274:2356  "if (lhsMSbIndex + 1 + rhsMSbIndex > 248) {..."
                        {
                            /// @src 5:2332:2349  "IndexOutOfRange()"
                            let _21 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                            /// @src 5:2332:2349  "IndexOutOfRange()"
                            mstore(_21, /** @src 5:1579:1596  "IndexOutOfRange()" */ shl(224, 0x1390f2a1))
                            /// @src 5:2332:2349  "IndexOutOfRange()"
                            revert(_21, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        /// @src 5:2362:2448  "return..."
                        let var_1 := /** @src 5:2377:2448  "pack((lindex << rhsMSbIndex) | (rindex ^ (1 << rhsMSbIndex)), pow(rhs))" */ fun_pack(/** @src 5:2382:2437  "(lindex << rhsMSbIndex) | (rindex ^ (1 << rhsMSbIndex))" */ or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ shl(expr_6, result_2), /** @src 5:2409:2436  "rindex ^ (1 << rhsMSbIndex)" */ xor(result_3, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ shl(expr_6, _19))), and(var, 0xff))
                        let memPtr_1 := mload(_1)
                        let newFreePtr_1 := add(memPtr_1, _8)
                        if or(gt(newFreePtr_1, _5), lt(newFreePtr_1, memPtr_1))
                        {
                            mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                            mstore(_2, 0x41)
                            revert(0, 0x24)
                        }
                        mstore(_1, newFreePtr_1)
                        calldatacopy(memPtr_1, calldatasize(), _8)
                        let rel_offset_of_tail := calldataload(/** @src 1:2750:2759  "_w.pubkey" */ add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        if iszero(slt(rel_offset_of_tail, add(_7, not(34)))) { revert(0, 0) }
                        let _22 := add(offset, rel_offset_of_tail)
                        let length := calldataload(add(_22, _2))
                        if gt(length, _5) { revert(0, 0) }
                        let addr := add(_22, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        if sgt(addr, sub(calldatasize(), length)) { revert(0, 0) }
                        /// @src 3:24956:25009  "if (pubkey.length != 48) revert InvalidPubkeyLength()"
                        if /** @src 3:24960:24979  "pubkey.length != 48" */ iszero(eq(length, /** @src 3:24977:24979  "48" */ 0x30))
                        /// @src 3:24956:25009  "if (pubkey.length != 48) revert InvalidPubkeyLength()"
                        {
                            /// @src 3:24988:25009  "InvalidPubkeyLength()"
                            let _23 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(_1)
                            /// @src 3:24988:25009  "InvalidPubkeyLength()"
                            mstore(_23, shl(224, 0x9ca717ed))
                            revert(_23, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        /// @src 3:25063:25762  "assembly {..."
                        mstore(/** @src 1:1955:1975  "_beaconRootData.slot" */ _13, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0)
                        /// @src 3:25063:25762  "assembly {..."
                        calldatacopy(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 3:25063:25762  "assembly {..." */ addr, /** @src 3:24977:24979  "48" */ 0x30)
                        /// @src 1:975:976  "2"
                        let _24 := 0x02
                        /// @src 3:25063:25762  "assembly {..."
                        let usr$success := staticcall(gas(), /** @src 1:975:976  "2" */ 0x02, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, _1, 0, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 3:25063:25762  "assembly {..."
                        if iszero(and(usr$success, eq(returndatasize(), /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)))
                        /// @src 3:25063:25762  "assembly {..."
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 3:25063:25762  "assembly {..." */ 0xdd5cab3e)
                            revert(0x1c, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        mstore(memPtr_1, /** @src 3:25063:25762  "assembly {..." */ mload(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0))
                        let addr_1 := add(memPtr_1, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        mstore(addr_1, calldataload(164))
                        /// @src 1:2834:2873  "SSZ.toLittleEndian(_w.effectiveBalance)"
                        let expr_7 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:2853:2872  "_w.effectiveBalance" */ read_from_calldatat_uint64(add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, /** @src 1:1977:2006  "_beaconRootData.proposerIndex" */ 68)), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5))
                        let addr_2 := add(memPtr_1, _1)
                        mstore(addr_2, expr_7)
                        let value_4 := calldataload(/** @src 1:2914:2924  "_w.slashed" */ add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, /** @src 1:2914:2924  "_w.slashed" */ 228))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        if iszero(eq(value_4, iszero(iszero(value_4)))) { revert(0, 0) }
                        /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        let expr_8 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0
                        /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        switch value_4
                        case 0 {
                            expr_8 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0
                        }
                        default /// @src 1:2914:2940  "_w.slashed ? uint64(1) : 0"
                        {
                            expr_8 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _19
                        }
                        /// @src 1:2895:2941  "SSZ.toLittleEndian(_w.slashed ? uint64(1) : 0)"
                        let expr_9 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:2895:2941  "SSZ.toLittleEndian(_w.slashed ? uint64(1) : 0)" */ expr_8, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5))
                        let addr_3 := add(memPtr_1, 96)
                        mstore(addr_3, expr_9)
                        /// @src 1:2963:3012  "SSZ.toLittleEndian(_w.activationEligibilityEpoch)"
                        let expr_10 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:2982:3011  "_w.activationEligibilityEpoch" */ read_from_calldatat_uint64(add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, 100)), _5))
                        let addr_4 := add(memPtr_1, 128)
                        mstore(addr_4, expr_10)
                        /// @src 1:3034:3072  "SSZ.toLittleEndian(_w.activationEpoch)"
                        let expr_11 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:3053:3071  "_w.activationEpoch" */ read_from_calldatat_uint64(add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, 132)), _5))
                        let addr_5 := add(memPtr_1, 160)
                        mstore(addr_5, expr_11)
                        /// @src 1:3094:3126  "SSZ.toLittleEndian(_w.exitEpoch)"
                        let expr_12 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:3113:3125  "_w.exitEpoch" */ read_from_calldatat_uint64(add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, 164)), _5))
                        let addr_6 := add(memPtr_1, 192)
                        mstore(addr_6, expr_12)
                        /// @src 1:3148:3188  "SSZ.toLittleEndian(_w.withdrawableEpoch)"
                        let expr_13 := fun_toLittleEndian(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(/** @src 1:3167:3187  "_w.withdrawableEpoch" */ read_from_calldatat_uint64(add(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ offset, /** @src 1:3167:3187  "_w.withdrawableEpoch" */ 196)), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _5))
                        let addr_7 := add(memPtr_1, 224)
                        mstore(addr_7, expr_13)
                        let memPtr_2 := mload(_1)
                        let newFreePtr_2 := add(memPtr_2, 128)
                        if or(gt(newFreePtr_2, _5), lt(newFreePtr_2, memPtr_2))
                        {
                            mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                            /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                            mstore(_2, 0x41)
                            revert(0, /** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                        }
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        mstore(_1, newFreePtr_2)
                        calldatacopy(memPtr_2, calldatasize(), 128)
                        let _25 := mload(memPtr_1)
                        mstore(memPtr_2, /** @src 1:3237:3279  "BLS12_381.sha256Pair(leaves[0], leaves[1])" */ fun_sha256Pair(_25, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_1)))
                        let _26 := mload(addr_2)
                        /// @src 1:3297:3339  "BLS12_381.sha256Pair(leaves[2], leaves[3])"
                        let _27 := fun_sha256Pair(_26, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_3))
                        let addr_8 := add(memPtr_2, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        mstore(addr_8, _27)
                        let _28 := mload(addr_4)
                        /// @src 1:3357:3399  "BLS12_381.sha256Pair(leaves[4], leaves[5])"
                        let _29 := fun_sha256Pair(_28, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_5))
                        let addr_9 := add(memPtr_2, _1)
                        mstore(addr_9, _29)
                        let _30 := mload(addr_6)
                        /// @src 1:3417:3459  "BLS12_381.sha256Pair(leaves[6], leaves[7])"
                        let _31 := fun_sha256Pair(_30, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_7))
                        let addr_10 := add(memPtr_2, 96)
                        mstore(addr_10, _31)
                        let memPtr_3 := mload(_1)
                        finalize_allocation(memPtr_3)
                        calldatacopy(memPtr_3, calldatasize(), _1)
                        let _32 := mload(memPtr_2)
                        mstore(memPtr_3, /** @src 1:3508:3542  "BLS12_381.sha256Pair(l1[0], l1[1])" */ fun_sha256Pair(_32, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_8)))
                        let _33 := mload(addr_9)
                        /// @src 1:3560:3594  "BLS12_381.sha256Pair(l1[2], l1[3])"
                        let _34 := fun_sha256Pair(_33, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(addr_10))
                        mstore(add(memPtr_3, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _34)
                        /// @src 1:3605:3646  "return BLS12_381.sha256Pair(l2[0], l2[1])"
                        let var_2 := /** @src 1:3612:3646  "BLS12_381.sha256Pair(l2[0], l2[1])" */ fun_sha256Pair(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(memPtr_3), /** @src 1:3640:3645  "l2[1]" */ _34)
                        /// @src 1:2340:2358  "_vw.proofValidator"
                        let expr_offset_1, expr_length_1 := access_calldata_tail_array_bytes32_dyn_calldata(_6, _6)
                        /// @src 1:2408:2423  "gIndexValidator"
                        let var_leaf := var_2
                        /// @src 6:5868:5894  "uint256 index = gI.index()"
                        let var_index := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ shr(/** @src 5:1158:1159  "8" */ 0x08, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ var_1)
                        /// @src 6:5948:8617  "assembly {..."
                        if iszero(expr_length_1)
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x09bde339)
                            revert(0x1c, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        /// @src 6:5948:8617  "assembly {..."
                        let usr$end := add(expr_offset_1, shl(/** @src 1:975:976  "2" */ 5, /** @src 6:5948:8617  "assembly {..." */ expr_length_1))
                        let usr$offset := expr_offset_1
                        for { }
                        /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _19
                        /// @src 6:5948:8617  "assembly {..."
                        { }
                        {
                            let usr$scratch := and(shl(/** @src 1:975:976  "2" */ _10, /** @src 6:5948:8617  "assembly {..." */ var_index), /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                            /// @src 6:5948:8617  "assembly {..."
                            var_index := shr(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _19, /** @src 6:5948:8617  "assembly {..." */ var_index)
                            if iszero(var_index)
                            {
                                mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x5849603f)
                                revert(0x1c, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                            }
                            /// @src 6:5948:8617  "assembly {..."
                            mstore(usr$scratch, var_leaf)
                            mstore(xor(usr$scratch, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13), /** @src 6:5948:8617  "assembly {..." */ calldataload(usr$offset))
                            if iszero(staticcall(gas(), /** @src 1:975:976  "2" */ _24, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, _1, 0, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13))
                            /// @src 6:5948:8617  "assembly {..."
                            {
                                revert(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, 0)
                            }
                            /// @src 6:5948:8617  "assembly {..."
                            var_leaf := mload(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0)
                            /// @src 6:5948:8617  "assembly {..."
                            usr$offset := add(usr$offset, /** @src 1:1955:1975  "_beaconRootData.slot" */ _13)
                            /// @src 6:5948:8617  "assembly {..."
                            if iszero(lt(usr$offset, usr$end)) { break }
                        }
                        if iszero(eq(var_index, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _19))
                        /// @src 6:5948:8617  "assembly {..."
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x1b6661c3)
                            revert(0x1c, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        /// @src 6:5948:8617  "assembly {..."
                        if iszero(eq(var_leaf, value_3))
                        {
                            mstore(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0, /** @src 6:5948:8617  "assembly {..." */ 0x09bde339)
                            revert(0x1c, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ _2)
                        }
                        return(0, 0)
                    }
                    case 0x2f8d5149 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos := mload(_1)
                        mstore(memPos, /** @src 1:705:814  "GIndex public immutable GI_STATE_ROOT = pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH)" */ loadimmutable("982"))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        return(memPos, 32)
                    }
                    case 0x3a5e31fe {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_1 := mload(_1)
                        mstore(memPos_1, /** @src 1:1215:1262  "GIndex public immutable GI_FIRST_VALIDATOR_CURR" */ loadimmutable("994"))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        return(memPos_1, 32)
                    }
                    case 0x562d7d67 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_2 := mload(_1)
                        mstore(memPos_2, /** @src 1:1162:1209  "GIndex public immutable GI_FIRST_VALIDATOR_PREV" */ loadimmutable("991"))
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        return(memPos_2, 32)
                    }
                    case 0x56d7e8fd {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_3 := mload(_1)
                        mstore(memPos_3, /** @src 1:1053:1095  "0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02" */ 0x0f3df6d732807ef1319fb7b8bb8522d0beac02)
                        /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                        return(memPos_3, 32)
                    }
                    case 0x8f60eab9 {
                        if callvalue() { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 0) { revert(0, 0) }
                        let memPos_4 := mload(_1)
                        mstore(memPos_4, and(/** @src 1:1268:1302  "uint64 public immutable PIVOT_SLOT" */ loadimmutable("996"), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xffffffffffffffff))
                        return(memPos_4, 32)
                    }
                }
                revert(0, 0)
            }
            function access_calldata_tail_array_bytes32_dyn_calldata(base_ref, ptr_to_tail) -> addr, length
            {
                let rel_offset_of_tail := calldataload(ptr_to_tail)
                if iszero(slt(rel_offset_of_tail, add(sub(calldatasize(), base_ref), not(30)))) { revert(0, 0) }
                let addr_1 := add(base_ref, rel_offset_of_tail)
                length := calldataload(addr_1)
                if gt(length, 0xffffffffffffffff) { revert(0, 0) }
                addr := add(addr_1, 0x20)
                if sgt(addr, sub(calldatasize(), shl(5, length))) { revert(0, 0) }
            }
            function read_from_calldatat_uint64_10616() -> returnValue
            {
                let value := calldataload(/** @src 1:1955:1975  "_beaconRootData.slot" */ 36)
                /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                if iszero(eq(value, and(value, 0xffffffffffffffff))) { revert(0, 0) }
                returnValue := value
            }
            function read_from_calldatat_uint64(ptr) -> returnValue
            {
                let value := calldataload(ptr)
                if iszero(eq(value, and(value, 0xffffffffffffffff))) { revert(0, 0) }
                returnValue := value
            }
            function finalize_allocation(memPtr)
            {
                let newFreePtr := add(memPtr, 64)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 1:975:976  "2" */ shl(224, 0x4e487b71))
                    /// @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function checked_add_uint256(x, y) -> sum
            {
                sum := add(x, y)
                if gt(x, sum)
                {
                    /// @src 1:975:976  "2"
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @ast-id 2668 @src 6:8747:9687  "function toLittleEndian(uint256 v) internal pure returns (bytes32) {..."
            function fun_toLittleEndian(var_v) -> var
            {
                /// @src 6:8840:9013  "((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |..."
                let expr := or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:8917:8918  "8" */ 0x08, /** @src 6:8842:8912  "v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00" */ var_v), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff), and(shl(/** @src 6:8917:8918  "8" */ 0x08, /** @src 6:8936:9006  "v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF" */ var_v), /** @src 6:8846:8912  "0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00" */ 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00))
                /// @src 6:9039:9214  "((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |..."
                let expr_1 := or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9116:9118  "16" */ 0x10, /** @src 6:9041:9111  "v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000" */ expr), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff), and(shl(/** @src 6:9116:9118  "16" */ 0x10, /** @src 6:9136:9206  "v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF" */ expr), /** @src 6:9045:9111  "0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000" */ 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000))
                /// @src 6:9240:9415  "((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |..."
                let expr_2 := or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9317:9319  "32" */ 0x20, /** @src 6:9242:9312  "v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000" */ expr_1), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff), and(shl(/** @src 6:9317:9319  "32" */ 0x20, /** @src 6:9337:9407  "v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF" */ expr_1), /** @src 6:9246:9312  "0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000" */ 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000))
                /// @src 6:9441:9616  "((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |..."
                let expr_3 := or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ and(shr(/** @src 6:9518:9520  "64" */ 0x40, /** @src 6:9443:9513  "v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000" */ expr_2), /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xffffffffffffffff0000000000000000ffffffffffffffff), and(shl(/** @src 6:9518:9520  "64" */ 0x40, /** @src 6:9538:9608  "v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF" */ expr_2), /** @src 6:9447:9513  "0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000" */ not(0xffffffffffffffff0000000000000000ffffffffffffffff)))
                /// @src 6:9663:9680  "return bytes32(v)"
                var := /** @src 6:9630:9653  "(v >> 128) | (v << 128)" */ or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ shr(/** @src 6:9636:9639  "128" */ 0x80, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ expr_3), shl(/** @src 6:9636:9639  "128" */ 0x80, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ expr_3))
            }
            /// @ast-id 2013 @src 3:23923:24692  "function sha256Pair(bytes32 left, bytes32 right) internal view returns (bytes32 result) {..."
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
            /// @ast-id 2443 @src 5:2724:3362  "function fls(uint256 x) pure returns (uint256 r) {..."
            function fun_fls(var_x) -> var_r
            {
                /// @src 5:2818:3360  "assembly {..."
                let var_r_1 := or(shl(8, iszero(var_x)), shl(7, lt(0xffffffffffffffffffffffffffffffff, var_x)))
                let var_r_2 := or(var_r_1, shl(6, lt(0xffffffffffffffff, shr(var_r_1, var_x))))
                let var_r_3 := or(var_r_2, shl(5, lt(0xffffffff, shr(var_r_2, var_x))))
                let var_r_4 := or(var_r_3, shl(4, lt(0xffff, shr(var_r_3, var_x))))
                let var_r_5 := or(var_r_4, shl(3, lt(0xff, shr(var_r_4, var_x))))
                var_r := or(var_r_5, byte(and(0x1f, shr(shr(var_r_5, var_x), 0x8421084210842108cc6318c6db6d54be)), 0x0706060506020504060203020504030106050205030304010505030400000000))
            }
            /// @ast-id 2194 @src 5:635:895  "function pack(uint256 gI, uint8 p) pure returns (GIndex) {..."
            function fun_pack(var_gI, var_p) -> var
            {
                /// @src 5:698:767  "if (gI > type(uint248).max) {..."
                if /** @src 5:702:724  "gI > type(uint248).max" */ gt(var_gI, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ sub(shl(248, 1), 1))
                /// @src 5:698:767  "if (gI > type(uint248).max) {..."
                {
                    /// @src 5:743:760  "IndexOutOfRange()"
                    let _1 := /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ mload(64)
                    /// @src 5:743:760  "IndexOutOfRange()"
                    mstore(_1, /** @src 5:1579:1596  "IndexOutOfRange()" */ shl(224, 0x1390f2a1))
                    /// @src 5:743:760  "IndexOutOfRange()"
                    revert(_1, 4)
                }
                /// @src 5:850:892  "return GIndex.wrap(bytes32((gI << 8) | p))"
                var := /** @src 5:877:890  "(gI << 8) | p" */ or(/** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ shl(/** @src 5:884:885  "8" */ 0x08, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ var_gI), and(/** @src 5:877:890  "(gI << 8) | p" */ var_p, /** @src 0:635:929  "contract SszRootCallHarness is CLValidatorVerifier {..." */ 0xff))
            }
        }
        data ".metadata" hex"a264697066735822122061763b63c609ef8b7748dd9e105e78bcafadf871701596b63b080df59b137c3664736f6c63430008190033"
    }
}

