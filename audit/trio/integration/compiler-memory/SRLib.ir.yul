/// @use-src 6:"contracts/0.8.25/sr/SRLib.sol"
object "SRLib_2650" {
    code {
        {
            /// @src 6:955:47234  "library SRLib {..."
            let _1 := memoryguard(0x80)
            mstore(64, _1)
            if callvalue() { revert(0, 0) }
            let _2 := datasize("SRLib_2650_deployed")
            codecopy(_1, dataoffset("SRLib_2650_deployed"), _2)
            setimmutable(_1, "library_deploy_address", address())
            return(_1, _2)
        }
    }
    /// @use-src 0:"@openzeppelin/contracts-v5.2/utils/Panic.sol", 1:"@openzeppelin/contracts-v5.2/utils/StorageSlot.sol", 2:"@openzeppelin/contracts-v5.2/utils/math/Math.sol", 3:"@openzeppelin/contracts-v5.2/utils/math/SafeCast.sol", 4:"@openzeppelin/contracts-v5.2/utils/structs/EnumerableSet.sol", 6:"contracts/0.8.25/sr/SRLib.sol", 7:"contracts/0.8.25/sr/SRStorage.sol", 9:"contracts/0.8.25/sr/SRUtils.sol", 14:"contracts/common/lib/WithdrawalCredentials.sol"
    object "SRLib_2650_deployed" {
        code {
            {
                /// @src 6:955:47234  "library SRLib {..."
                mstore(64, memoryguard(0x80))
                let _1 := eq(loadimmutable("library_deploy_address"), address())
                if iszero(lt(calldatasize(), 4))
                {
                    let _2 := 0
                    switch shr(224, calldataload(0))
                    case 0x16cfb08d {
                        if _1 { revert(0, 0) }
                        if slt(add(calldatasize(), not(3)), 160) { revert(0, 0) }
                        let value := calldataload(4)
                        let offset := calldataload(100)
                        if gt(offset, 0xffffffffffffffff) { revert(0, 0) }
                        let value3, value4 := abi_decode_bytes_calldata(add(4, offset), calldatasize())
                        /// @src 6:27663:27679  "_stakingModuleId"
                        fun_requireModuleIdExists(value)
                        /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                        let _3 := constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(0, value)
                        mstore(32, _3)
                        let cleaned := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(0, 64)), sub(shl(160, 1), 1))
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        if iszero(extcodesize(cleaned))
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            revert(0, 0)
                        }
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        let _4 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        mstore(_4, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x57f9c341))
                        mstore(/** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ add(_4, /** @src 6:955:47234  "library SRLib {..." */ 4), calldataload(36))
                        mstore(add(/** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ _4, /** @src 6:955:47234  "library SRLib {..." */ 36), calldataload(68))
                        mstore(add(/** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ _4, /** @src 6:955:47234  "library SRLib {..." */ 68), 128)
                        let tail := abi_encode_bytes_calldata(value3, value4, add(/** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ _4, /** @src 6:955:47234  "library SRLib {..." */ 132))
                        mstore(add(/** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ _4, /** @src 6:955:47234  "library SRLib {..." */ 100), calldataload(132))
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        let _5 := call(gas(), cleaned, /** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..." */ _4, sub(tail, _4), _4, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        if iszero(_5)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 6:27690:27836  "_stakingModuleId.getIStakingModule()..."
                        if _5
                        {
                            finalize_allocation_31410(_4)
                            /// @src 6:955:47234  "library SRLib {..."
                            _2 := 0
                        }
                        return(_2, _2)
                    }
                    case 0x2dedadea {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 288) { revert(_2, _2) }
                        let value_1 := calldataload(4)
                        let _6 := sub(shl(160, 1), 1)
                        let _7 := and(value_1, _6)
                        if iszero(eq(value_1, _7)) { revert(_2, _2) }
                        let offset_1 := calldataload(36)
                        let _8 := 0xffffffffffffffff
                        if gt(offset_1, _8) { revert(_2, _2) }
                        let value1, value2 := abi_decode_bytes_calldata(add(4, offset_1), calldatasize())
                        if slt(add(calldatasize(), not(67)), 224) { revert(_2, _2) }
                        /// @src 9:1163:1219  "if (_address == address(0)) revert ISRBase.ZeroAddress()"
                        if /** @src 9:1167:1189  "_address == address(0)" */ iszero(/** @src 6:955:47234  "library SRLib {..." */ _7)
                        /// @src 9:1163:1219  "if (_address == address(0)) revert ISRBase.ZeroAddress()"
                        {
                            /// @src 9:1198:1219  "ISRBase.ZeroAddress()"
                            let _9 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 9:1198:1219  "ISRBase.ZeroAddress()"
                            mstore(_9, shl(224, 0xd92e233d))
                            revert(_9, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:7963:8063  "bytes(_moduleName).length == 0 || bytes(_moduleName).length > SRUtils.MAX_STAKING_MODULE_NAME_LENGTH"
                        let expr := /** @src 6:7963:7993  "bytes(_moduleName).length == 0" */ iszero(value2)
                        /// @src 6:7963:8063  "bytes(_moduleName).length == 0 || bytes(_moduleName).length > SRUtils.MAX_STAKING_MODULE_NAME_LENGTH"
                        if iszero(expr)
                        {
                            expr := /** @src 6:7997:8063  "bytes(_moduleName).length > SRUtils.MAX_STAKING_MODULE_NAME_LENGTH" */ gt(value2, /** @src 9:704:706  "31" */ 0x1f)
                        }
                        /// @src 6:7959:8129  "if (bytes(_moduleName).length == 0 || bytes(_moduleName).length > SRUtils.MAX_STAKING_MODULE_NAME_LENGTH) {..."
                        if expr
                        {
                            /// @src 6:8086:8118  "ISRBase.StakingModuleWrongName()"
                            let _10 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:8086:8118  "ISRBase.StakingModuleWrongName()"
                            mstore(_10, shl(224, 0xac187169))
                            revert(_10, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 7:1957:1983  "getRouterState().moduleIds"
                        let _11 := 1
                        /// @src 6:955:47234  "library SRLib {..."
                        let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11))
                        /// @src 6:955:47234  "library SRLib {..."
                        let _12 := 32
                        /// @src 6:8198:8322  "if (modulesCount >= SRUtils.MAX_STAKING_MODULES_COUNT) {..."
                        if /** @src 6:8202:8251  "modulesCount >= SRUtils.MAX_STAKING_MODULES_COUNT" */ iszero(lt(length, /** @src 6:955:47234  "library SRLib {..." */ _12))
                        /// @src 6:8198:8322  "if (modulesCount >= SRUtils.MAX_STAKING_MODULES_COUNT) {..."
                        {
                            /// @src 6:8274:8311  "ISRBase.StakingModulesLimitExceeded()"
                            let _13 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:8274:8311  "ISRBase.StakingModulesLimitExceeded()"
                            mstore(_13, shl(224, 0x309eed99))
                            revert(_13, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 9:560:562  "32"
                        let value_2 := calldataload(/** @src 6:8360:8399  "_moduleConfig.withdrawalCredentialsType" */ 260)
                        /// @src 14:1225:1259  "isType1(wcType) || isType2(wcType)"
                        let expr_1 := /** @src 14:1567:1587  "wcType == WC_TYPE_01" */ eq(value_2, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11)
                        /// @src 14:1225:1259  "isType1(wcType) || isType2(wcType)"
                        if iszero(expr_1)
                        {
                            expr_1 := /** @src 14:1679:1699  "wcType == WC_TYPE_02" */ eq(value_2, /** @src 14:523:527  "0x02" */ 0x02)
                        }
                        /// @src 9:1302:1398  "if (!WithdrawalCredentials.isTypeValid(_wcType)) revert ISRBase.WrongWithdrawalCredentialsType()"
                        if /** @src 9:1306:1349  "!WithdrawalCredentials.isTypeValid(_wcType)" */ iszero(/** @src 9:1307:1349  "WithdrawalCredentials.isTypeValid(_wcType)" */ expr_1)
                        /// @src 9:1302:1398  "if (!WithdrawalCredentials.isTypeValid(_wcType)) revert ISRBase.WrongWithdrawalCredentialsType()"
                        {
                            /// @src 9:1358:1398  "ISRBase.WrongWithdrawalCredentialsType()"
                            let _14 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 9:1358:1398  "ISRBase.WrongWithdrawalCredentialsType()"
                            mstore(_14, shl(226, 0x0b972523))
                            revert(_14, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:8549:8558  "uint256 i"
                        let var_i := _2
                        var_i := _2
                        /// @src 6:8544:8812  "for (uint256 i; i < modulesCount; ++i) {..."
                        for { }
                        /** @src 6:8560:8576  "i < modulesCount" */ lt(var_i, length)
                        /// @src 6:8549:8558  "uint256 i"
                        {
                            /// @src 6:8578:8581  "++i"
                            var_i := /** @src 9:560:562  "32" */ add(/** @src 6:8578:8581  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11)
                        }
                        /// @src 6:8578:8581  "++i"
                        {
                            /// @src 4:5016:5034  "set._values[index]"
                            let _15, _16 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11), /** @src 4:5016:5034  "set._values[index]" */ var_i)
                            /// @src 6:955:47234  "library SRLib {..."
                            let _17 := sload(/** @src 4:5016:5034  "set._values[index]" */ _15)
                            /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                            let _18 := constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(3, _16), _17))
                            mstore(_12, _18)
                            /// @src 6:8656:8802  "if (_moduleAddress == moduleId.getModuleState().config.moduleAddress) {..."
                            if /** @src 6:8660:8724  "_moduleAddress == moduleId.getModuleState().config.moduleAddress" */ eq(/** @src 6:955:47234  "library SRLib {..." */ _7, and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64)), _6))
                            /// @src 6:8656:8802  "if (_moduleAddress == moduleId.getModuleState().config.moduleAddress) {..."
                            {
                                /// @src 6:8751:8787  "ISRBase.StakingModuleAddressExists()"
                                let _19 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:8751:8787  "ISRBase.StakingModuleAddressExists()"
                                mstore(_19, shl(228, 0x050f969d))
                                revert(_19, /** @src 6:955:47234  "library SRLib {..." */ 4)
                            }
                        }
                        /// @src 9:560:562  "32"
                        let _20 := 0xffffff
                        let sum := add(and(sload(/** @src 6:8836:8875  "SRStorage.getRouterState().lastModuleId" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:8836:8875  "SRStorage.getRouterState().lastModuleId" */ 5)), /** @src 9:560:562  "32" */ _20), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11)
                        /// @src 9:560:562  "32"
                        if gt(sum, _20)
                        {
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x11)
                            revert(/** @src 6:955:47234  "library SRLib {..." */ _2, 36)
                        }
                        /// @src 9:560:562  "32"
                        let cleaned_1 := and(sum, _20)
                        /// @src 4:10840:10872  "_add(set._inner, bytes32(value))"
                        pop(fun_add(/** @src 7:2791:2817  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11), /** @src 4:10857:10871  "bytes32(value)" */ cleaned_1))
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var_slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, cleaned_1)
                        mstore(_12, var_slot)
                        let dataSlot := keccak256(_2, 64)
                        /// @src 9:560:562  "32"
                        sstore(dataSlot, or(and(sload(dataSlot), shl(160, 0xffffff00ffffffffffffffff)), _7))
                        /// @src 6:9176:9269  "moduleState.config.withdrawalCredentialsType = uint8(_moduleConfig.withdrawalCredentialsType)"
                        update_storage_value_offsett_uint8_to_uint8(dataSlot, /** @src 9:560:562  "32" */ and(value_2, 0xff))
                        /// @src 6:9279:9295  "moduleState.name"
                        let _21 := add(dataSlot, /** @src 6:955:47234  "library SRLib {..." */ 3)
                        /// @src 9:560:562  "32"
                        if gt(value2, /** @src 6:955:47234  "library SRLib {..." */ _8)
                        /// @src 9:560:562  "32"
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(4, 0x41)
                            revert(_2, 36)
                        }
                        /// @src 9:560:562  "32"
                        clean_up_bytearray_end_slots_string_storage(_21, extract_byte_array_length(sload(_21)), value2)
                        let srcOffset := _2
                        switch gt(value2, 31)
                        case 1 {
                            let loopEnd := and(value2, not(31))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ _21)
                            let dstPtr := keccak256(/** @src 6:955:47234  "library SRLib {..." */ _2, _12)
                            /// @src 9:560:562  "32"
                            let i := _2
                            for { }
                            lt(i, loopEnd)
                            {
                                i := add(i, /** @src 6:955:47234  "library SRLib {..." */ _12)
                            }
                            /// @src 9:560:562  "32"
                            {
                                sstore(dstPtr, calldataload(add(value1, srcOffset)))
                                dstPtr := add(dstPtr, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11)
                                /// @src 9:560:562  "32"
                                srcOffset := add(srcOffset, /** @src 6:955:47234  "library SRLib {..." */ _12)
                            }
                            /// @src 9:560:562  "32"
                            if lt(loopEnd, value2)
                            {
                                sstore(dstPtr, and(calldataload(add(value1, srcOffset)), not(shr(and(shl(/** @src 6:955:47234  "library SRLib {..." */ 3, /** @src 9:560:562  "32" */ value2), 248), not(0)))))
                            }
                            sstore(_21, add(shl(/** @src 7:1957:1983  "getRouterState().moduleIds" */ _11, /** @src 9:560:562  "32" */ value2), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _11))
                        }
                        default /// @src 9:560:562  "32"
                        {
                            let value_3 := _2
                            if value2
                            {
                                value_3 := calldataload(add(value1, srcOffset))
                            }
                            sstore(_21, extract_used_part_and_set_length_of_short_byte_array(value_3, value2))
                        }
                        /// @src 6:9325:9405  "ISRBase.StakingModuleAdded(newModuleId, _moduleAddress, _moduleName, msg.sender)"
                        let _22 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 9:560:562  "32"
                        mstore(_22, /** @src 6:955:47234  "library SRLib {..." */ _7)
                        /// @src 9:560:562  "32"
                        mstore(add(_22, /** @src 6:955:47234  "library SRLib {..." */ _12), /** @src 9:560:562  "32" */ 96)
                        let tail_1 := abi_encode_bytes_calldata(value1, value2, add(_22, 96))
                        mstore(add(_22, /** @src 6:955:47234  "library SRLib {..." */ 64), /** @src 6:9394:9404  "msg.sender" */ caller())
                        /// @src 6:9325:9405  "ISRBase.StakingModuleAdded(newModuleId, _moduleAddress, _moduleName, msg.sender)"
                        log2(_22, sub(tail_1, _22), 0x43b5213f0e1666cd0b8692a73686164c94deb955a59c65e10dee8bb958e7ce3e, cleaned_1)
                        /// @src 6:9701:9738  "_moduleConfig.minDepositBlockDistance"
                        fun_updateModuleParams(cleaned_1, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 68), /** @src 9:560:562  "32" */ calldataload(/** @src 6:9517:9557  "_moduleConfig.priorityExitShareThreshold" */ 100), /** @src 9:560:562  "32" */ calldataload(/** @src 6:9571:9601  "_moduleConfig.stakingModuleFee" */ 132), /** @src 9:560:562  "32" */ calldataload(/** @src 6:9615:9640  "_moduleConfig.treasuryFee" */ 164), /** @src 9:560:562  "32" */ calldataload(/** @src 6:9654:9687  "_moduleConfig.maxDepositsPerBlock" */ 196), /** @src 9:560:562  "32" */ calldataload(/** @src 6:9701:9738  "_moduleConfig.minDepositBlockDistance" */ 228))
                        /// @src 6:9790:9829  "SRStorage.getRouterState().lastModuleId"
                        let _23 := add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:8836:8875  "SRStorage.getRouterState().lastModuleId" */ 5)
                        /// @src 9:560:562  "32"
                        sstore(_23, or(and(sload(_23), not(16777215)), cleaned_1))
                        /// @src 6:955:47234  "library SRLib {..."
                        let memPos := mload(64)
                        mstore(memPos, cleaned_1)
                        return(memPos, _12)
                    }
                    case 0x3ba5b397 {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 96) { revert(_2, _2) }
                        let offset_2 := calldataload(4)
                        if gt(offset_2, 0xffffffffffffffff) { revert(_2, _2) }
                        let value0, value1_1 := abi_decode_array_struct_ValidatorExitData_calldata_dyn_calldata(add(4, offset_2), calldatasize())
                        /// @src 6:28957:28970  "uint256 i = 0"
                        let var_i_1 := _2
                        /// @src 6:28952:30106  "for (uint256 i = 0; i < validatorExitData.length; ++i) {..."
                        for { }
                        /** @src 6:28972:29000  "i < validatorExitData.length" */ lt(var_i_1, /** @src 6:28976:29000  "validatorExitData.length" */ value1_1)
                        /// @src 6:28957:28970  "uint256 i = 0"
                        {
                            /// @src 6:29002:29005  "++i"
                            var_i_1 := /** @src 9:560:562  "32" */ add(/** @src 6:29002:29005  "++i" */ var_i_1, /** @src 6:955:47234  "library SRLib {..." */ 1)
                        }
                        /// @src 6:29002:29005  "++i"
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let rel_offset_of_tail := calldataload(add(value0, shl(5, var_i_1)))
                            if iszero(slt(rel_offset_of_tail, add(sub(calldatasize(), value0), not(94)))) { revert(_2, _2) }
                            /// @src 6:29093:29113  "data.stakingModuleId"
                            fun_requireModuleIdExists(/** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail)))
                            let _24 := and(/** @src 6:29132:29172  "data.stakingModuleId.getIStakingModule()" */ fun_getIStakingModule(/** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail))), sub(shl(160, 1), 1))
                            /// @src 6:29236:29247  "data.pubkey"
                            let expr_offset, expr_length := access_calldata_tail_bytes_calldata(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), /** @src 6:29236:29247  "data.pubkey" */ add(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), 64))
                            /// @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..."
                            if iszero(extcodesize(_24))
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                revert(_2, _2)
                            }
                            /// @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..."
                            let _25 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..."
                            mstore(_25, /** @src 6:955:47234  "library SRLib {..." */ shl(233, 3448419))
                            mstore(/** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ add(_25, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 9:560:562  "32" */ calldataload(/** @src 6:29215:29234  "data.nodeOperatorId" */ add(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), 32)))
                            mstore(add(/** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ _25, /** @src 6:955:47234  "library SRLib {..." */ 36), 128)
                            let tail_2 := abi_encode_bytes_calldata(expr_offset, expr_length, add(/** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ _25, /** @src 6:955:47234  "library SRLib {..." */ 132))
                            mstore(add(/** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ _25, /** @src 6:955:47234  "library SRLib {..." */ 68), calldataload(36))
                            mstore(add(/** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ _25, /** @src 6:955:47234  "library SRLib {..." */ 100), calldataload(68))
                            /// @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..."
                            let trySuccessCondition := call(gas(), _24, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..." */ _25, sub(tail_2, _25), _25, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 6:29132:29286  "data.stakingModuleId.getIStakingModule()..."
                            if trySuccessCondition
                            {
                                finalize_allocation_31410(_25)
                                /// @src 6:955:47234  "library SRLib {..."
                                if _2 { revert(_2, _2) }
                            }
                            /// @src 6:29128:30096  "try data.stakingModuleId.getIStakingModule()..."
                            switch iszero(trySuccessCondition)
                            case 0 { }
                            default {
                                /// @src 6:29882:29959  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                if /** @src 6:29886:29916  "lowLevelRevertData.length == 0" */ iszero(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:29302:30096  "catch (bytes memory lowLevelRevertData) {..." */ extract_returndata()))
                                /// @src 6:29882:29959  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                {
                                    /// @src 6:29925:29959  "ISRBase.UnrecoverableModuleError()"
                                    let _26 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                    /// @src 6:29925:29959  "ISRBase.UnrecoverableModuleError()"
                                    mstore(_26, shl(224, 0x8fd297d9))
                                    revert(_26, /** @src 6:955:47234  "library SRLib {..." */ 4)
                                }
                                /// @src 6:30069:30080  "data.pubkey"
                                let expr_offset_1, expr_length_1 := access_calldata_tail_bytes_calldata(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), /** @src 6:29236:29247  "data.pubkey" */ add(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), 64))
                                /// @src 6:29982:30081  "ISRBase.StakingModuleExitNotificationFailed(data.stakingModuleId, data.nodeOperatorId, data.pubkey)"
                                let _27 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                mstore(_27, 32)
                                /// @src 6:29982:30081  "ISRBase.StakingModuleExitNotificationFailed(data.stakingModuleId, data.nodeOperatorId, data.pubkey)"
                                log3(_27, sub(/** @src 6:955:47234  "library SRLib {..." */ abi_encode_bytes_calldata(expr_offset_1, expr_length_1, add(_27, 32)), /** @src 6:29982:30081  "ISRBase.StakingModuleExitNotificationFailed(data.stakingModuleId, data.nodeOperatorId, data.pubkey)" */ _27), 0xb639213d4cc5d7a615491fb0505dd448dee5074f322660125b7171993bf9bb1d, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:29215:29234  "data.nodeOperatorId" */ add(/** @src 6:955:47234  "library SRLib {..." */ add(value0, rel_offset_of_tail), 32)))
                            }
                        }
                        return(_2, _2)
                    }
                    case 0x43be2ccd {
                        let _28 := add(calldatasize(), not(3))
                        if slt(_28, 128) { revert(_2, _2) }
                        if slt(_28, 64) { revert(_2, _2) }
                        let value_4 := calldataload(100)
                        if iszero(eq(value_4, iszero(iszero(value_4)))) { revert(0, 0) }
                        let ret, ret_1, ret_2 := fun_getDepositAllocations_31414(calldataload(68), value_4)
                        let memPos_1 := mload(64)
                        mstore(memPos_1, ret)
                        mstore(add(memPos_1, 32), 96)
                        let tail_3 := abi_encode_array_uint256_dyn(ret_1, add(memPos_1, 96))
                        mstore(add(memPos_1, 64), sub(tail_3, memPos_1))
                        return(memPos_1, sub(abi_encode_array_uint256_dyn(ret_2, tail_3), memPos_1))
                    }
                    case 0x4bdf1645 {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_2, _2) }
                        /// @src 7:1957:1983  "getRouterState().moduleIds"
                        let _29 := 1
                        /// @src 6:955:47234  "library SRLib {..."
                        let length_1 := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                        /// @src 6:32380:32389  "uint256 i"
                        let var_i_2 := _2
                        var_i_2 := _2
                        /// @src 6:32375:33771  "for (uint256 i; i < modulesCount; ++i) {..."
                        for { }
                        /** @src 6:32391:32407  "i < modulesCount" */ lt(var_i_2, length_1)
                        /// @src 6:32380:32389  "uint256 i"
                        {
                            /// @src 6:32409:32412  "++i"
                            var_i_2 := /** @src 9:560:562  "32" */ add(/** @src 6:32409:32412  "++i" */ var_i_2, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _29)
                        }
                        /// @src 6:32409:32412  "++i"
                        {
                            /// @src 4:5016:5034  "set._values[index]"
                            let _30, _31 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _29), /** @src 4:5016:5034  "set._values[index]" */ var_i_2)
                            /// @src 6:955:47234  "library SRLib {..."
                            let value_5 := /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(3, _31), sload(/** @src 4:5016:5034  "set._values[index]" */ _30))
                            /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                            let var_slot_1 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, value_5)
                            mstore(0x20, var_slot_1)
                            let dataSlot_1 := keccak256(_2, 64)
                            let cleaned_2 := and(/** @src 9:560:562  "32" */ sload(dataSlot_1), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                            /// @src 6:32661:32700  "_getStakingModuleSummary(stakingModule)"
                            let expr_component, expr_component_1, expr_component_2 := fun_getStakingModuleSummary(cleaned_2)
                            /// @src 6:32714:32791  "if (exitedValidatorsCount != state.accounting.exitedValidatorsCount) continue"
                            if /** @src 6:32718:32781  "exitedValidatorsCount != state.accounting.exitedValidatorsCount" */ iszero(eq(expr_component, /** @src 6:955:47234  "library SRLib {..." */ and(shr(64, sload(/** @src 6:32743:32759  "state.accounting" */ add(dataSlot_1, 2))), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)))
                            /// @src 6:32714:32791  "if (exitedValidatorsCount != state.accounting.exitedValidatorsCount) continue"
                            {
                                /// @src 6:32783:32791  "continue"
                                continue
                            }
                            /// @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            if iszero(extcodesize(cleaned_2))
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                revert(_2, _2)
                            }
                            /// @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            let _32 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            mstore(_32, /** @src 6:955:47234  "library SRLib {..." */ shl(225, 0x743214cf))
                            /// @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            let trySuccessCondition_1 := call(gas(), cleaned_2, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()" */ _32, /** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()" */ _32, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 6:32885:32940  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            if trySuccessCondition_1
                            {
                                finalize_allocation_31410(_32)
                                /// @src 6:955:47234  "library SRLib {..."
                                if _2 { revert(_2, _2) }
                            }
                            /// @src 6:32881:33761  "try stakingModule.onExitedAndStuckValidatorsCountsUpdated() {}..."
                            switch iszero(trySuccessCondition_1)
                            case 0 { }
                            default {
                                /// @src 6:32956:33761  "catch (bytes memory lowLevelRevertData) {..."
                                let var_lowLevelRevertData_mpos := extract_returndata()
                                /// @src 6:33566:33643  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                if /** @src 6:33570:33600  "lowLevelRevertData.length == 0" */ iszero(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:33570:33595  "lowLevelRevertData.length" */ var_lowLevelRevertData_mpos))
                                /// @src 6:33566:33643  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                {
                                    /// @src 6:33609:33643  "ISRBase.UnrecoverableModuleError()"
                                    let _33 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                    /// @src 6:33609:33643  "ISRBase.UnrecoverableModuleError()"
                                    mstore(_33, /** @src 6:29925:29959  "ISRBase.UnrecoverableModuleError()" */ shl(224, 0x8fd297d9))
                                    /// @src 6:33609:33643  "ISRBase.UnrecoverableModuleError()"
                                    revert(_33, /** @src 6:955:47234  "library SRLib {..." */ 4)
                                }
                                /// @src 6:33666:33746  "ISRBase.ExitedAndStuckValidatorsCountsUpdateFailed(moduleId, lowLevelRevertData)"
                                let _34 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:33666:33746  "ISRBase.ExitedAndStuckValidatorsCountsUpdateFailed(moduleId, lowLevelRevertData)"
                                log2(_34, sub(abi_encode_bytes(_34, var_lowLevelRevertData_mpos), _34), 0xe74bf895f0c3a2d6c74c40cbb362fdd9640035fc4226c72e3843809ad2a9d2b5, value_5)
                            }
                        }
                        /// @src 6:955:47234  "library SRLib {..."
                        return(_2, _2)
                    }
                    case 0x66d97dbb {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_2, _2) }
                        /// @src 7:1957:1983  "getRouterState().moduleIds"
                        let _35 := 1
                        /// @src 6:955:47234  "library SRLib {..."
                        let length_2 := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                        /// @src 6:46128:46137  "uint256 i"
                        let var_i_3 := _2
                        var_i_3 := _2
                        /// @src 6:46123:46767  "for (uint256 i; i < modulesCount; ++i) {..."
                        for { }
                        /** @src 6:46139:46155  "i < modulesCount" */ lt(var_i_3, length_2)
                        /// @src 6:46128:46137  "uint256 i"
                        {
                            /// @src 6:46157:46160  "++i"
                            var_i_3 := /** @src 9:560:562  "32" */ add(/** @src 6:46157:46160  "++i" */ var_i_3, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _35)
                        }
                        /// @src 6:46157:46160  "++i"
                        {
                            /// @src 4:5016:5034  "set._values[index]"
                            let _36, _37 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _35), /** @src 4:5016:5034  "set._values[index]" */ var_i_3)
                            /// @src 6:955:47234  "library SRLib {..."
                            let _38 := sload(/** @src 4:5016:5034  "set._values[index]" */ _36)
                            /// @src 6:955:47234  "library SRLib {..."
                            let _39 := 3
                            let value_6 := /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_39, _37), _38)
                            /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                            let _40 := constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, value_6)
                            let _41 := 0x20
                            mstore(_41, _40)
                            let cleaned_3 := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64)), sub(shl(160, 1), 1))
                            /// @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()"
                            if iszero(extcodesize(cleaned_3))
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                revert(_2, _2)
                            }
                            /// @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()"
                            let _42 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()"
                            mstore(_42, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x90c09bdb))
                            /// @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()"
                            let trySuccessCondition_2 := call(gas(), cleaned_3, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()" */ _42, /** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()" */ _42, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 6:46240:46301  "moduleId.getIStakingModule().onWithdrawalCredentialsChanged()"
                            if trySuccessCondition_2
                            {
                                finalize_allocation_31410(_42)
                                /// @src 6:955:47234  "library SRLib {..."
                                if _2 { revert(_2, _2) }
                            }
                            /// @src 6:46236:46757  "try moduleId.getIStakingModule().onWithdrawalCredentialsChanged() {}..."
                            switch iszero(trySuccessCondition_2)
                            case 0 { }
                            default {
                                /// @src 6:46317:46757  "catch (bytes memory lowLevelRevertData) {..."
                                let var_lowLevelRevertData_mpos_1 := extract_returndata()
                                /// @src 6:46375:46452  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                if /** @src 6:46379:46409  "lowLevelRevertData.length == 0" */ iszero(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:46379:46404  "lowLevelRevertData.length" */ var_lowLevelRevertData_mpos_1))
                                /// @src 6:46375:46452  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                {
                                    /// @src 6:46418:46452  "ISRBase.UnrecoverableModuleError()"
                                    let _43 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                    /// @src 6:46418:46452  "ISRBase.UnrecoverableModuleError()"
                                    mstore(_43, /** @src 6:29925:29959  "ISRBase.UnrecoverableModuleError()" */ shl(224, 0x8fd297d9))
                                    /// @src 6:46418:46452  "ISRBase.UnrecoverableModuleError()"
                                    revert(_43, /** @src 6:955:47234  "library SRLib {..." */ 4)
                                }
                                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                                let var_slot_2 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                                /// @src 6:955:47234  "library SRLib {..."
                                mstore(_2, value_6)
                                mstore(_41, var_slot_2)
                                /// @src 9:560:562  "32"
                                let _44 := 0xff
                                /// @src 6:955:47234  "library SRLib {..."
                                let value_7 := /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(224, sload(keccak256(_2, 64))), /** @src 9:560:562  "32" */ _44)
                                if iszero(lt(value_7, /** @src 6:955:47234  "library SRLib {..." */ _39))
                                /// @src 9:560:562  "32"
                                {
                                    mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                    mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                                    revert(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ 0x24)
                                }
                                /// @src 6:46470:46648  "if (moduleId.getModuleState().config.status == StakingModuleStatus.Active) {..."
                                if /** @src 6:46474:46543  "moduleId.getModuleState().config.status == StakingModuleStatus.Active" */ iszero(value_7)
                                /// @src 6:46470:46648  "if (moduleId.getModuleState().config.status == StakingModuleStatus.Active) {..."
                                {
                                    /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                                    let var_slot_3 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                                    /// @src 6:955:47234  "library SRLib {..."
                                    mstore(0, value_6)
                                    mstore(_41, var_slot_3)
                                    let dataSlot_2 := keccak256(0, 64)
                                    let _45 := sload(/** @src 6:16258:16276  "stateConfig.status" */ dataSlot_2)
                                    /// @src 6:955:47234  "library SRLib {..."
                                    let value_8 := /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(224, _45), /** @src 9:560:562  "32" */ _44)
                                    if iszero(lt(value_8, /** @src 6:955:47234  "library SRLib {..." */ _39))
                                    /// @src 9:560:562  "32"
                                    {
                                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                                        revert(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ 0x24)
                                    }
                                    /// @src 6:16254:16357  "if (stateConfig.status == _status) {..."
                                    if /** @src 6:16258:16287  "stateConfig.status == _status" */ eq(value_8, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _35)
                                    /// @src 6:16254:16357  "if (stateConfig.status == _status) {..."
                                    {
                                        /// @src 6:16310:16346  "ISRBase.StakingModuleStatusTheSame()"
                                        let _46 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                        /// @src 6:16310:16346  "ISRBase.StakingModuleStatusTheSame()"
                                        mstore(_46, shl(225, 0x5ca16fa7))
                                        revert(_46, /** @src 6:955:47234  "library SRLib {..." */ 4)
                                    }
                                    /// @src 9:560:562  "32"
                                    sstore(dataSlot_2, or(and(_45, not(shl(224, 255))), /** @src 6:955:47234  "library SRLib {..." */ shl(224, 1)))
                                    /// @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)"
                                    let _47 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                    mstore(_47, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _35)
                                    /// @src 9:560:562  "32"
                                    mstore(/** @src 6:955:47234  "library SRLib {..." */ add(_47, _41), /** @src 6:16460:16470  "msg.sender" */ caller())
                                    /// @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)"
                                    log2(_47, /** @src 6:955:47234  "library SRLib {..." */ 64, /** @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)" */ 0xfd6f15fb2b48a21a60fe3d44d3c3a0433ca01e121b5124a63ec45c30ad925a17, value_6)
                                }
                                /// @src 6:46670:46742  "ISRBase.WithdrawalsCredentialsChangeFailed(moduleId, lowLevelRevertData)"
                                let _48 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:46670:46742  "ISRBase.WithdrawalsCredentialsChangeFailed(moduleId, lowLevelRevertData)"
                                log2(_48, sub(abi_encode_bytes(_48, var_lowLevelRevertData_mpos_1), _48), 0x0d64b11929aa111ca874dd00b5b0cc2d82b741be924ec9e3691e67c71552f623, value_6)
                            }
                        }
                        /// @src 6:955:47234  "library SRLib {..."
                        return(_2, _2)
                    }
                    case 0x758dbbf5 {
                        if _1 { revert(_2, _2) }
                        let param, param_1, param_2, param_3, param_4 := abi_decode_uint256t_bytes_calldatat_bytes_calldata(calldatasize())
                        /// @src 6:35455:35471  "_stakingModuleId"
                        fun_requireModuleIdExists(param)
                        /// @src 6:46887:46907  "_ids.length % 8 != 0"
                        let _49 := iszero(/** @src 6:955:47234  "library SRLib {..." */ and(param_2, 7))
                        /// @src 6:46887:46935  "_ids.length % 8 != 0 || _values.length % 16 != 0"
                        let expr_2 := /** @src 6:46887:46907  "_ids.length % 8 != 0" */ iszero(_49)
                        /// @src 6:46887:46935  "_ids.length % 8 != 0 || _values.length % 16 != 0"
                        if _49
                        {
                            expr_2 := /** @src 6:46911:46935  "_values.length % 16 != 0" */ iszero(iszero(/** @src 6:955:47234  "library SRLib {..." */ and(param_4, 15)))
                        }
                        /// @src 6:46883:46997  "if (_ids.length % 8 != 0 || _values.length % 16 != 0) {..."
                        if expr_2
                        {
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            let _50 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            mstore(_50, shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ add(_50, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:46984:46985  "3" */ 0x03)
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            revert(_50, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        let r := shr(3, param_2)
                        /// @src 6:47047:47141  "if (_values.length / 16 != count) {..."
                        if /** @src 6:47051:47079  "_values.length / 16 != count" */ iszero(eq(/** @src 6:955:47234  "library SRLib {..." */ shr(4, param_4), /** @src 6:47051:47079  "_values.length / 16 != count" */ r))
                        /// @src 6:47047:47141  "if (_values.length / 16 != count) {..."
                        {
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            let _51 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            mstore(_51, /** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:47102:47130  "ISRBase.InvalidReportData(2)" */ add(_51, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:47128:47129  "2" */ 0x02)
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            revert(_51, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        /// @src 6:47150:47226  "if (count == 0) {..."
                        if /** @src 6:47154:47164  "count == 0" */ iszero(r)
                        /// @src 6:47150:47226  "if (count == 0) {..."
                        {
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            let _52 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            mstore(_52, /** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:47187:47215  "ISRBase.InvalidReportData(1)" */ add(_52, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:47213:47214  "1" */ 0x01)
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            revert(_52, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                        let _53 := constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, param)
                        mstore(0x20, _53)
                        let cleaned_4 := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64)), sub(shl(160, 1), 1))
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        if iszero(extcodesize(cleaned_4))
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            revert(_2, _2)
                        }
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        let _54 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        mstore(_54, /** @src 6:955:47234  "library SRLib {..." */ shl(225, 0x4d8060a3))
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        let _55 := call(gas(), cleaned_4, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)" */ _54, sub(abi_encode_bytes_calldata_bytes_calldata(add(_54, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)" */ param_1, param_2, param_3, param_4), _54), _54, /** @src 6:955:47234  "library SRLib {..." */ _2)
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        if iszero(_55)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos_1 := mload(64)
                            returndatacopy(pos_1, _2, returndatasize())
                            revert(pos_1, returndatasize())
                        }
                        /// @src 6:35560:35667  "_stakingModuleId.getIStakingModule().updateExitedValidatorsCount(_nodeOperatorIds, _exitedValidatorsCounts)"
                        if _55
                        {
                            finalize_allocation_31410(_54)
                            /// @src 6:955:47234  "library SRLib {..."
                            if _2 { revert(_2, _2) }
                        }
                        return(_2, _2)
                    }
                    case 0x803300ac {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 224) { revert(_2, _2) }
                        fun_updateModuleParams(calldataload(4), calldataload(36), calldataload(68), calldataload(100), calldataload(132), calldataload(164), calldataload(196))
                        return(_2, _2)
                    }
                    case 0x888de12d {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_2, _2) }
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var_slot_4 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, calldataload(4))
                        mstore(32, var_slot_4)
                        /// @src 6:45808:45843  "_moduleId.getModuleState().deposits"
                        let _56 := add(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64), 1)
                        let _57 := 0xffffffffffffffff
                        /// @src 9:497:502  "10000"
                        sstore(_56, or(and(sload(_56), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), and(/** @src 6:45891:45906  "block.timestamp" */ timestamp(), /** @src 6:955:47234  "library SRLib {..." */ _57)))
                        /// @src 6:45917:45970  "stateDeposits.lastDepositBlock = uint64(block.number)"
                        update_storage_value_offsett_uint64_to_uint64(_56, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:45957:45969  "block.number" */ number(), /** @src 6:955:47234  "library SRLib {..." */ _57))
                        return(_2, _2)
                    }
                    case 0x8e78da5a {
                        if _1 { revert(_2, _2) }
                        let param_5, param_6, param_7, param_8 := abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(calldatasize())
                        /// @src 6:44863:44885  "_validatorBalancesGwei"
                        fun_validateReportValidatorBalancesByStakingModule(param_5, param_6, param_7, param_8)
                        /// @src 6:44943:44976  "uint64 totalValidatorsBalanceGwei"
                        let var_totalValidatorsBalanceGwei := _2
                        var_totalValidatorsBalanceGwei := _2
                        /// @src 6:44991:45004  "uint256 i = 0"
                        let var_i_4 := _2
                        /// @src 6:44986:45388  "for (uint256 i = 0; i < n; ++i) {..."
                        for { }
                        /** @src 6:45006:45011  "i < n" */ lt(var_i_4, param_6)
                        /// @src 6:44991:45004  "uint256 i = 0"
                        {
                            /// @src 6:45013:45016  "++i"
                            var_i_4 := /** @src 9:560:562  "32" */ add(/** @src 6:45013:45016  "++i" */ var_i_4, /** @src 9:560:562  "32" */ 1)
                        }
                        /// @src 6:45013:45016  "++i"
                        {
                            /// @src 9:560:562  "32"
                            let value_9 := calldataload(/** @src 6:45051:45071  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_5, param_6, var_i_4))
                            /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                            let _58 := constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, value_9)
                            mstore(0x20, _58)
                            /// @src 6:45127:45163  "moduleId.getModuleState().accounting"
                            let _59 := add(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64), /** @src 6:45127:45163  "moduleId.getModuleState().accounting" */ 2)
                            /// @src 6:955:47234  "library SRLib {..."
                            let cleaned_5 := and(/** @src 9:560:562  "32" */ calldataload(/** @src 6:45215:45240  "_validatorBalancesGwei[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_7, param_8, var_i_4)), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                            /// @src 9:497:502  "10000"
                            sstore(_59, or(and(sload(_59), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), cleaned_5))
                            /// @src 6:45326:45377  "totalValidatorsBalanceGwei += validatorsBalanceGwei"
                            var_totalValidatorsBalanceGwei := checked_add_uint64(var_totalValidatorsBalanceGwei, cleaned_5)
                        }
                        /// @src 6:45439:45476  "SRStorage.getRouterState().accounting"
                        let _60 := add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:45439:45476  "SRStorage.getRouterState().accounting" */ 3)
                        /// @src 9:497:502  "10000"
                        sstore(_60, or(and(sload(_60), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), and(/** @src 9:497:502  "10000" */ var_totalValidatorsBalanceGwei, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)))
                        return(_2, _2)
                    }
                    case 0xa4c341ee {
                        if _1 { revert(_2, _2) }
                        let param_9, param_10, param_11, param_12 := abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(calldatasize())
                        /// @src 6:30588:30655  "if (_totalShares.length != n) revert ISRBase.ArraysLengthMismatch()"
                        if /** @src 6:30592:30616  "_totalShares.length != n" */ iszero(eq(param_12, param_10))
                        /// @src 6:30588:30655  "if (_totalShares.length != n) revert ISRBase.ArraysLengthMismatch()"
                        {
                            /// @src 6:30625:30655  "ISRBase.ArraysLengthMismatch()"
                            let _61 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:30625:30655  "ISRBase.ArraysLengthMismatch()"
                            mstore(_61, shl(229, 0x07e11acb))
                            revert(_61, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:30671:30684  "uint256 i = 0"
                        let var_i_5 := _2
                        /// @src 6:30666:31657  "for (uint256 i = 0; i < n; ++i) {..."
                        for { }
                        /** @src 6:30686:30691  "i < n" */ lt(var_i_5, param_10)
                        /// @src 6:30671:30684  "uint256 i = 0"
                        {
                            /// @src 6:30693:30696  "++i"
                            var_i_5 := /** @src 9:560:562  "32" */ add(/** @src 6:30693:30696  "++i" */ var_i_5, /** @src 9:560:562  "32" */ 1)
                        }
                        /// @src 6:30693:30696  "++i"
                        {
                            /// @src 6:30712:30746  "if (_totalShares[i] == 0) continue"
                            if /** @src 6:30716:30736  "_totalShares[i] == 0" */ iszero(/** @src 9:560:562  "32" */ calldataload(/** @src 6:30716:30731  "_totalShares[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_11, param_12, var_i_5)))
                            /// @src 6:30712:30746  "if (_totalShares[i] == 0) continue"
                            {
                                /// @src 6:30738:30746  "continue"
                                continue
                            }
                            /// @src 6:30791:30811  "_stakingModuleIds[i]"
                            fun_requireModuleIdExists(/** @src 9:560:562  "32" */ calldataload(/** @src 6:30791:30811  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_9, param_10, var_i_5)))
                            /// @src 6:955:47234  "library SRLib {..."
                            let _62 := and(/** @src 6:30831:30871  "_stakingModuleIds[i].getIStakingModule()" */ fun_getIStakingModule(/** @src 9:560:562  "32" */ calldataload(/** @src 6:30831:30851  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_9, param_10, var_i_5))), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                            /// @src 9:560:562  "32"
                            let value_10 := calldataload(/** @src 6:30888:30903  "_totalShares[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_11, param_12, var_i_5))
                            /// @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])"
                            if iszero(extcodesize(_62))
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                revert(_2, _2)
                            }
                            /// @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])"
                            let _63 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])"
                            mstore(_63, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x8d7e4017))
                            mstore(/** @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])" */ add(_63, /** @src 6:955:47234  "library SRLib {..." */ 4), value_10)
                            /// @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])"
                            let trySuccessCondition_3 := call(gas(), _62, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])" */ _63, /** @src 6:955:47234  "library SRLib {..." */ 36, /** @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])" */ _63, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 6:30831:30904  "_stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i])"
                            if trySuccessCondition_3
                            {
                                finalize_allocation_31410(_63)
                                /// @src 6:955:47234  "library SRLib {..."
                                if _2 { revert(_2, _2) }
                            }
                            /// @src 6:30827:31647  "try _stakingModuleIds[i].getIStakingModule().onRewardsMinted(_totalShares[i]) {}..."
                            switch iszero(trySuccessCondition_3)
                            case 0 { }
                            default {
                                /// @src 6:30920:31647  "catch (bytes memory lowLevelRevertData) {..."
                                let var_lowLevelRevertData_mpos_2 := extract_returndata()
                                /// @src 6:31457:31534  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                if /** @src 6:31461:31491  "lowLevelRevertData.length == 0" */ iszero(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:31461:31486  "lowLevelRevertData.length" */ var_lowLevelRevertData_mpos_2))
                                /// @src 6:31457:31534  "if (lowLevelRevertData.length == 0) revert ISRBase.UnrecoverableModuleError()"
                                {
                                    /// @src 6:31500:31534  "ISRBase.UnrecoverableModuleError()"
                                    let _64 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                    /// @src 6:31500:31534  "ISRBase.UnrecoverableModuleError()"
                                    mstore(_64, /** @src 6:29925:29959  "ISRBase.UnrecoverableModuleError()" */ shl(224, 0x8fd297d9))
                                    /// @src 6:31500:31534  "ISRBase.UnrecoverableModuleError()"
                                    revert(_64, /** @src 6:955:47234  "library SRLib {..." */ 4)
                                }
                                /// @src 9:560:562  "32"
                                let value_11 := calldataload(/** @src 6:31591:31611  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_9, param_10, var_i_5))
                                /// @src 6:31557:31632  "ISRBase.RewardsMintedReportFailed(_stakingModuleIds[i], lowLevelRevertData)"
                                let _65 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:31557:31632  "ISRBase.RewardsMintedReportFailed(_stakingModuleIds[i], lowLevelRevertData)"
                                log2(_65, sub(abi_encode_bytes(_65, var_lowLevelRevertData_mpos_2), _65), 0xf74208fedac7280fd11f8de0be14e00423dc5076da8e8ec8ca90e09257fff1b3, value_11)
                            }
                        }
                        /// @src 6:955:47234  "library SRLib {..."
                        return(_2, _2)
                    }
                    case 0xafb7e738 {
                        if _1 { revert(_2, _2) }
                        let param_13, param_14, param_15, param_16 := abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(calldatasize())
                        /// @src 6:38764:38842  "if (_exitedValidatorsCounts.length != n) revert ISRBase.ArraysLengthMismatch()"
                        if /** @src 6:38768:38803  "_exitedValidatorsCounts.length != n" */ iszero(eq(param_16, param_14))
                        /// @src 6:38764:38842  "if (_exitedValidatorsCounts.length != n) revert ISRBase.ArraysLengthMismatch()"
                        {
                            /// @src 6:38812:38842  "ISRBase.ArraysLengthMismatch()"
                            let _66 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:38812:38842  "ISRBase.ArraysLengthMismatch()"
                            mstore(_66, /** @src 6:30625:30655  "ISRBase.ArraysLengthMismatch()" */ shl(229, 0x07e11acb))
                            /// @src 6:38812:38842  "ISRBase.ArraysLengthMismatch()"
                            revert(_66, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:38853:38887  "uint256 newlyExitedValidatorsCount"
                        let var_newlyExitedValidatorsCount := _2
                        var_newlyExitedValidatorsCount := _2
                        /// @src 6:38903:38916  "uint256 i = 0"
                        let var_i_6 := _2
                        /// @src 6:38898:40611  "for (uint256 i = 0; i < n; ++i) {..."
                        for { }
                        /** @src 6:38918:38923  "i < n" */ lt(var_i_6, param_14)
                        /// @src 6:38903:38916  "uint256 i = 0"
                        {
                            /// @src 6:38925:38928  "++i"
                            var_i_6 := /** @src 9:560:562  "32" */ add(/** @src 6:38925:38928  "++i" */ var_i_6, /** @src 9:560:562  "32" */ 1)
                        }
                        /// @src 6:38925:38928  "++i"
                        {
                            /// @src 9:560:562  "32"
                            let value_12 := calldataload(/** @src 6:38963:38983  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_13, param_14, var_i_6))
                            /// @src 6:39028:39036  "moduleId"
                            fun_requireModuleIdExists(value_12)
                            /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                            let var_slot_5 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, value_12)
                            mstore(0x20, var_slot_5)
                            let dataSlot_3 := keccak256(_2, 64)
                            let value_13 := and(shr(64, sload(/** @src 6:39160:39176  "state.accounting" */ add(dataSlot_3, 2))), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                            /// @src 6:39321:39366  "SafeCast.toUint64(_exitedValidatorsCounts[i])"
                            let expr_3 := fun_toUint64(/** @src 9:560:562  "32" */ calldataload(/** @src 6:39339:39365  "_exitedValidatorsCounts[i]" */ calldata_array_index_access_uint256_dyn_calldata(param_15, param_16, var_i_6)))
                            /// @src 6:39381:39540  "if (newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount) {..."
                            if /** @src 6:39385:39453  "newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount" */ lt(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:39385:39453  "newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount" */ expr_3, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff), value_13)
                            /// @src 6:39381:39540  "if (newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount) {..."
                            {
                                /// @src 6:39480:39525  "ISRBase.ExitedValidatorsCountCannotDecrease()"
                                let _67 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:39480:39525  "ISRBase.ExitedValidatorsCountCannotDecrease()"
                                mstore(_67, shl(226, 0x2f789f49))
                                revert(_67, /** @src 6:955:47234  "library SRLib {..." */ 4)
                            }
                            /// @src 6:39639:39690  "_getStakingModuleSummary(state.getIStakingModule())"
                            let expr_component_3, expr_component_4, expr_component_5 := fun_getStakingModuleSummary(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ sload(dataSlot_3), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1)))
                            /// @src 6:39705:39955  "if (newReportedExitedValidatorsCount > totalDepositedValidators) {..."
                            if /** @src 6:39709:39768  "newReportedExitedValidatorsCount > totalDepositedValidators" */ gt(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:39385:39453  "newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount" */ expr_3, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff), /** @src 6:39709:39768  "newReportedExitedValidatorsCount > totalDepositedValidators" */ expr_component_4)
                            /// @src 6:39705:39955  "if (newReportedExitedValidatorsCount > totalDepositedValidators) {..."
                            {
                                /// @src 6:39795:39940  "ISRBase.ReportedExitedValidatorsExceedDeposited(..."
                                let _68 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:39795:39940  "ISRBase.ReportedExitedValidatorsExceedDeposited(..."
                                mstore(_68, shl(226, 0x0b72c59d))
                                revert(_68, sub(abi_encode_uint64_uint256(add(_68, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:39795:39940  "ISRBase.ReportedExitedValidatorsExceedDeposited(..." */ expr_3, expr_component_4), _68))
                            }
                            /// @src 6:955:47234  "library SRLib {..."
                            let diff := sub(and(/** @src 6:39385:39453  "newReportedExitedValidatorsCount < prevReportedExitedValidatorsCount" */ expr_3, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff), value_13)
                            if gt(diff, 0xffffffffffffffff)
                            {
                                /// @src 9:560:562  "32"
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x11)
                                revert(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ 0x24)
                            }
                            /// @src 6:39969:40067  "newlyExitedValidatorsCount += newReportedExitedValidatorsCount - prevReportedExitedValidatorsCount"
                            var_newlyExitedValidatorsCount := checked_add_uint256(var_newlyExitedValidatorsCount, /** @src 6:955:47234  "library SRLib {..." */ and(diff, 0xffffffffffffffff))
                            /// @src 6:40082:40490  "if (totalExitedValidators < prevReportedExitedValidatorsCount) {..."
                            if /** @src 6:40086:40143  "totalExitedValidators < prevReportedExitedValidatorsCount" */ lt(expr_component_3, value_13)
                            /// @src 6:40082:40490  "if (totalExitedValidators < prevReportedExitedValidatorsCount) {..."
                            {
                                /// @src 6:40286:40457  "ISRBase.StakingModuleExitedValidatorsIncompleteReporting(..."
                                let _69 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                mstore(_69, sub(/** @src 6:40378:40435  "prevReportedExitedValidatorsCount - totalExitedValidators" */ value_13, expr_component_3))
                                /// @src 6:40286:40457  "ISRBase.StakingModuleExitedValidatorsIncompleteReporting(..."
                                log2(_69, /** @src 6:955:47234  "library SRLib {..." */ 0x20, /** @src 6:40286:40457  "ISRBase.StakingModuleExitedValidatorsIncompleteReporting(..." */ 0xdd2523ca96a639ba7e17420698937f71eddd8af012ccb36ff5c8fe96141acae9, value_12)
                            }
                            /// @src 6:40534:40600  "moduleAcc.exitedValidatorsCount = newReportedExitedValidatorsCount"
                            update_storage_value_offsett_uint64_to_uint64(/** @src 6:39160:39176  "state.accounting" */ add(dataSlot_3, 2), /** @src 6:40534:40600  "moduleAcc.exitedValidatorsCount = newReportedExitedValidatorsCount" */ expr_3)
                        }
                        /// @src 6:955:47234  "library SRLib {..."
                        let memPos_2 := mload(64)
                        mstore(memPos_2, var_newlyExitedValidatorsCount)
                        return(memPos_2, 0x20)
                    }
                    case 0xb336438f {
                        let param_17, param_18, param_19, param_20 := abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(calldatasize())
                        fun_validateReportValidatorBalancesByStakingModule(param_17, param_18, param_19, param_20)
                        return(_2, _2)
                    }
                    case 0xc580154f {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 224) { revert(_2, _2) }
                        let value_14 := calldataload(4)
                        let value_15 := calldataload(36)
                        let value_16 := calldataload(68)
                        if iszero(eq(value_16, iszero(iszero(value_16)))) { revert(0, 0) }
                        if slt(add(calldatasize(), not(99)), 128) { revert(_2, _2) }
                        /// @src 6:41939:41955  "_stakingModuleId"
                        fun_requireModuleIdExists(value_14)
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var_slot_6 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, value_14)
                        mstore(32, var_slot_6)
                        let dataSlot_4 := keccak256(_2, 64)
                        /// @src 6:42037:42095  "ModuleStateAccounting storage moduleAcc = state.accounting"
                        let var_moduleAcc_slot := /** @src 6:42079:42095  "state.accounting" */ add(dataSlot_4, 2)
                        /// @src 6:955:47234  "library SRLib {..."
                        let value_17 := and(shr(64, sload(/** @src 6:42148:42179  "moduleAcc.exitedValidatorsCount" */ var_moduleAcc_slot)), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                        let cleaned_6 := and(/** @src 9:560:562  "32" */ sload(dataSlot_4), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                        /// @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)"
                        let _70 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)"
                        mstore(_70, /** @src 6:955:47234  "library SRLib {..." */ shl(226, 0x2cc1db0f))
                        mstore(/** @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)" */ add(_70, /** @src 6:955:47234  "library SRLib {..." */ 4), value_15)
                        /// @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)"
                        let _71 := 256
                        let _72 := staticcall(gas(), cleaned_6, _70, /** @src 6:955:47234  "library SRLib {..." */ 36, /** @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)" */ _70, _71)
                        if iszero(_72)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos_2 := mload(64)
                            returndatacopy(pos_2, _2, returndatasize())
                            revert(pos_2, returndatasize())
                        }
                        let expr_component_6 := _2
                        /// @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)"
                        if _72
                        {
                            let _73 := _71
                            if gt(_71, returndatasize()) { _73 := returndatasize() }
                            finalize_allocation(_70, _73)
                            /// @src 6:955:47234  "library SRLib {..."
                            if slt(sub(/** @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)" */ add(_70, _73), /** @src 6:955:47234  "library SRLib {..." */ _70), /** @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)" */ _71)
                            /// @src 6:955:47234  "library SRLib {..."
                            { revert(_2, _2) }
                            /// @src 6:42298:42351  "stakingModule.getNodeOperatorSummary(_nodeOperatorId)"
                            expr_component_6 := /** @src 6:955:47234  "library SRLib {..." */ mload(add(_70, 160))
                        }
                        /// @src 6:42379:42462  "_correction.currentModuleExitedValidatorsCount != prevReportedExitedValidatorsCount"
                        let _74 := eq(/** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 100), value_17)
                        /// @src 6:42379:42559  "_correction.currentModuleExitedValidatorsCount != prevReportedExitedValidatorsCount..."
                        let expr_4 := /** @src 6:42379:42462  "_correction.currentModuleExitedValidatorsCount != prevReportedExitedValidatorsCount" */ iszero(_74)
                        /// @src 6:42379:42559  "_correction.currentModuleExitedValidatorsCount != prevReportedExitedValidatorsCount..."
                        if _74
                        {
                            expr_4 := /** @src 6:42482:42559  "_correction.currentNodeOperatorExitedValidatorsCount != totalExitedValidators" */ iszero(eq(/** @src 9:560:562  "32" */ calldataload(/** @src 6:42482:42534  "_correction.currentNodeOperatorExitedValidatorsCount" */ 132), /** @src 6:42482:42559  "_correction.currentNodeOperatorExitedValidatorsCount != totalExitedValidators" */ expr_component_6))
                        }
                        /// @src 6:42362:42700  "if (..."
                        if expr_4
                        {
                            /// @src 6:42591:42689  "ISRBase.UnexpectedCurrentValidatorsCount(prevReportedExitedValidatorsCount, totalExitedValidators)"
                            let _75 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:42591:42689  "ISRBase.UnexpectedCurrentValidatorsCount(prevReportedExitedValidatorsCount, totalExitedValidators)"
                            mstore(_75, shl(224, 0xc7c450d5))
                            revert(_75, sub(abi_encode_uint64_uint256(add(_75, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:42591:42689  "ISRBase.UnexpectedCurrentValidatorsCount(prevReportedExitedValidatorsCount, totalExitedValidators)" */ value_17, expr_component_6), _75))
                        }
                        /// @src 9:560:562  "32"
                        let value_18 := calldataload(/** @src 6:42762:42804  "_correction.newModuleExitedValidatorsCount" */ 164)
                        /// @src 6:42710:42805  "moduleAcc.exitedValidatorsCount = SafeCast.toUint64(_correction.newModuleExitedValidatorsCount)"
                        update_storage_value_offsett_uint64_to_uint64(var_moduleAcc_slot, /** @src 6:42744:42805  "SafeCast.toUint64(_correction.newModuleExitedValidatorsCount)" */ fun_toUint64(/** @src 6:42762:42804  "_correction.newModuleExitedValidatorsCount" */ value_18))
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        if iszero(extcodesize(cleaned_6))
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            revert(_2, _2)
                        }
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        let _76 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        mstore(_76, /** @src 6:955:47234  "library SRLib {..." */ shl(227, 0x1282406d))
                        mstore(/** @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)" */ add(_76, /** @src 6:955:47234  "library SRLib {..." */ 4), value_15)
                        mstore(add(/** @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)" */ _76, /** @src 6:955:47234  "library SRLib {..." */ 36), /** @src 9:560:562  "32" */ calldataload(/** @src 6:42875:42923  "_correction.newNodeOperatorExitedValidatorsCount" */ 196))
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        let _77 := call(gas(), cleaned_6, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)" */ _76, /** @src 6:955:47234  "library SRLib {..." */ 68, /** @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)" */ _76, /** @src 6:955:47234  "library SRLib {..." */ _2)
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        if iszero(_77)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos_3 := mload(64)
                            returndatacopy(pos_3, _2, returndatasize())
                            revert(pos_3, returndatasize())
                        }
                        /// @src 6:42816:42924  "stakingModule.unsafeUpdateValidatorsCount(_nodeOperatorId, _correction.newNodeOperatorExitedValidatorsCount)"
                        if _77
                        {
                            finalize_allocation_31410(_76)
                            /// @src 6:955:47234  "library SRLib {..."
                            if _2 { revert(_2, _2) }
                        }
                        /// @src 6:43028:43067  "_getStakingModuleSummary(stakingModule)"
                        let expr_component_7, expr_component_8, expr_component_9 := fun_getStakingModuleSummary(cleaned_6)
                        /// @src 6:43078:43344  "if (_correction.newModuleExitedValidatorsCount > moduleTotalDepositedValidators) {..."
                        if /** @src 6:43082:43157  "_correction.newModuleExitedValidatorsCount > moduleTotalDepositedValidators" */ gt(value_18, expr_component_8)
                        /// @src 6:43078:43344  "if (_correction.newModuleExitedValidatorsCount > moduleTotalDepositedValidators) {..."
                        {
                            /// @src 6:43180:43333  "ISRBase.ReportedExitedValidatorsExceedDeposited(..."
                            let _78 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:43180:43333  "ISRBase.ReportedExitedValidatorsExceedDeposited(..."
                            mstore(_78, /** @src 6:39795:39940  "ISRBase.ReportedExitedValidatorsExceedDeposited(..." */ shl(226, 0x0b72c59d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:43180:43333  "ISRBase.ReportedExitedValidatorsExceedDeposited(..." */ add(_78, /** @src 6:955:47234  "library SRLib {..." */ 4), value_18)
                            mstore(add(/** @src 6:43180:43333  "ISRBase.ReportedExitedValidatorsExceedDeposited(..." */ _78, /** @src 6:955:47234  "library SRLib {..." */ 36), expr_component_8)
                            /// @src 6:43180:43333  "ISRBase.ReportedExitedValidatorsExceedDeposited(..."
                            revert(_78, /** @src 6:955:47234  "library SRLib {..." */ 68)
                        }
                        /// @src 6:43354:43748  "if (_triggerUpdateFinish) {..."
                        if value_16
                        {
                            /// @src 6:43394:43668  "if (moduleTotalExitedValidators != _correction.newModuleExitedValidatorsCount) {..."
                            if /** @src 6:43398:43471  "moduleTotalExitedValidators != _correction.newModuleExitedValidatorsCount" */ iszero(eq(expr_component_7, value_18))
                            /// @src 6:43394:43668  "if (moduleTotalExitedValidators != _correction.newModuleExitedValidatorsCount) {..."
                            {
                                /// @src 6:43498:43653  "ISRBase.UnexpectedFinalExitedValidatorsCount(..."
                                let _79 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                                /// @src 6:43498:43653  "ISRBase.UnexpectedFinalExitedValidatorsCount(..."
                                mstore(_79, shl(224, 0xdcab2a89))
                                /// @src 6:955:47234  "library SRLib {..."
                                mstore(/** @src 6:43498:43653  "ISRBase.UnexpectedFinalExitedValidatorsCount(..." */ add(_79, /** @src 6:955:47234  "library SRLib {..." */ 4), expr_component_7)
                                mstore(add(/** @src 6:43498:43653  "ISRBase.UnexpectedFinalExitedValidatorsCount(..." */ _79, /** @src 6:955:47234  "library SRLib {..." */ 36), value_18)
                                /// @src 6:43498:43653  "ISRBase.UnexpectedFinalExitedValidatorsCount(..."
                                revert(_79, /** @src 6:955:47234  "library SRLib {..." */ 68)
                            }
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            if iszero(extcodesize(cleaned_6))
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                revert(_2, _2)
                            }
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            let _80 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            mstore(_80, /** @src 6:955:47234  "library SRLib {..." */ shl(225, 0x743214cf))
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            let _81 := call(gas(), cleaned_6, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()" */ _80, /** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()" */ _80, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            if iszero(_81)
                            {
                                /// @src 6:955:47234  "library SRLib {..."
                                let pos_4 := mload(64)
                                returndatacopy(pos_4, _2, returndatasize())
                                revert(pos_4, returndatasize())
                            }
                            /// @src 6:43682:43737  "stakingModule.onExitedAndStuckValidatorsCountsUpdated()"
                            if _81
                            {
                                finalize_allocation_31410(_80)
                                /// @src 6:955:47234  "library SRLib {..."
                                if _2 { revert(_2, _2) }
                            }
                        }
                        return(_2, _2)
                    }
                    case 0xd05e2bce {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 64) { revert(_2, _2) }
                        let value_19 := calldataload(4)
                        let value_20 := calldataload(36)
                        if iszero(lt(value_20, 3)) { revert(_2, _2) }
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var__slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(0, value_19)
                        mstore(0x20, var__slot)
                        let dataSlot_5 := keccak256(0, 64)
                        let value_21 := /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(224, sload(/** @src 6:16258:16276  "stateConfig.status" */ dataSlot_5)), /** @src 9:560:562  "32" */ 0xff)
                        if iszero(lt(value_21, /** @src 6:955:47234  "library SRLib {..." */ 3))
                        /// @src 9:560:562  "32"
                        {
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                            revert(/** @src 6:955:47234  "library SRLib {..." */ 0, 36)
                        }
                        /// @src 6:16254:16357  "if (stateConfig.status == _status) {..."
                        if /** @src 6:16258:16287  "stateConfig.status == _status" */ eq(value_21, value_20)
                        /// @src 6:16254:16357  "if (stateConfig.status == _status) {..."
                        {
                            /// @src 6:16310:16346  "ISRBase.StakingModuleStatusTheSame()"
                            let _82 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:16310:16346  "ISRBase.StakingModuleStatusTheSame()"
                            mstore(_82, shl(225, 0x5ca16fa7))
                            revert(_82, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:16366:16394  "stateConfig.status = _status"
                        update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(dataSlot_5, value_20)
                        /// @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)"
                        let _83 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        mstore(_83, /** @src 9:560:562  "32" */ value_20)
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ add(_83, 0x20), /** @src 6:16460:16470  "msg.sender" */ caller())
                        /// @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)"
                        log2(_83, /** @src 6:955:47234  "library SRLib {..." */ 64, /** @src 6:16409:16471  "ISRBase.StakingModuleStatusSet(_moduleId, _status, msg.sender)" */ 0xfd6f15fb2b48a21a60fe3d44d3c3a0433ca01e121b5124a63ec45c30ad925a17, value_19)
                        /// @src 6:955:47234  "library SRLib {..."
                        return(_2, _2)
                    }
                    case 0xd3ecac04 {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 64) { revert(_2, _2) }
                        let value_22 := calldataload(36)
                        /// @src 6:1918:2012  "if (SRStorage.getModulesCount() > 0) {..."
                        if /** @src 6:1922:1953  "SRStorage.getModulesCount() > 0" */ iszero(iszero(/** @src 6:955:47234  "library SRLib {..." */ sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:955:47234  "library SRLib {..." */ 1))))
                        /// @src 6:1918:2012  "if (SRStorage.getModulesCount() > 0) {..."
                        {
                            /// @src 6:1976:2001  "ISRBase.AlreadyMigrated()"
                            let _84 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:1976:2001  "ISRBase.AlreadyMigrated()"
                            mstore(_84, shl(226, 0x32870f2f))
                            revert(_84, /** @src 6:955:47234  "library SRLib {..." */ 4)
                        }
                        /// @src 6:2492:2535  "keccak256(\"lido.Versioned.contractVersion\")"
                        let _85 := 0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
                        /// @src 6:955:47234  "library SRLib {..."
                        let _86 := sload(/** @src 6:2492:2535  "keccak256(\"lido.Versioned.contractVersion\")" */ _85)
                        /// @src 6:2824:2959  "if (actualVersion != expectedVersion) {..."
                        if /** @src 6:2828:2860  "actualVersion != expectedVersion" */ iszero(eq(_86, value_22))
                        /// @src 6:2824:2959  "if (actualVersion != expectedVersion) {..."
                        {
                            /// @src 6:2883:2948  "ISRBase.UnexpectedContractVersion(expectedVersion, actualVersion)"
                            let _87 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:2883:2948  "ISRBase.UnexpectedContractVersion(expectedVersion, actualVersion)"
                            mstore(_87, shl(226, 0x03abe783))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:2883:2948  "ISRBase.UnexpectedContractVersion(expectedVersion, actualVersion)" */ add(_87, /** @src 6:955:47234  "library SRLib {..." */ 4), value_22)
                            mstore(add(/** @src 6:2883:2948  "ISRBase.UnexpectedContractVersion(expectedVersion, actualVersion)" */ _87, /** @src 6:955:47234  "library SRLib {..." */ 36), _86)
                            /// @src 6:2883:2948  "ISRBase.UnexpectedContractVersion(expectedVersion, actualVersion)"
                            revert(_87, /** @src 6:955:47234  "library SRLib {..." */ 68)
                        }
                        /// @src 9:560:562  "32"
                        sstore(/** @src 6:2120:2156  "keccak256(\"lido.StakingRouter.lido\")" */ 0x706b9ed9846c161ad535be9b6345c3a7b2cb929e8d4a7254dee9ba6e6f8e5531, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 9:560:562  "32"
                        sstore(/** @src 6:2492:2535  "keccak256(\"lido.Versioned.contractVersion\")" */ _85, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 6:2400:2451  "keccak256(\"lido.StakingRouter.lastStakingModuleId\")"
                        let _88 := 0xf9a85ae945d8134f58bd2ee028636634dcb9e812798acb5c806bf1951232a225
                        /// @src 9:560:562  "32"
                        let _89 := and(/** @src 6:955:47234  "library SRLib {..." */ sload(/** @src 6:2400:2451  "keccak256(\"lido.StakingRouter.lastStakingModuleId\")" */ _88), /** @src 9:560:562  "32" */ 0xffffff)
                        /// @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId"
                        let _90 := add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId" */ 5)
                        /// @src 9:560:562  "32"
                        sstore(_90, or(and(sload(_90), not(16777215)), _89))
                        sstore(/** @src 6:2400:2451  "keccak256(\"lido.StakingRouter.lastStakingModuleId\")" */ _88, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 6:2203:2256  "keccak256(\"lido.StakingRouter.withdrawalCredentials\")"
                        let _91 := 0xabeb05279af36da5d476d7f950157cd2ea98a4166fa68a6bc97ce3a22fbb93c0
                        /// @src 6:955:47234  "library SRLib {..."
                        sstore(/** @src 6:3355:3403  "SRStorage.getRouterState().withdrawalCredentials" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:955:47234  "library SRLib {..." */ 4), sload(/** @src 6:2203:2256  "keccak256(\"lido.StakingRouter.withdrawalCredentials\")" */ _91))
                        /// @src 9:560:562  "32"
                        sstore(/** @src 6:2203:2256  "keccak256(\"lido.StakingRouter.withdrawalCredentials\")" */ _91, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 6:2302:2353  "keccak256(\"lido.StakingRouter.stakingModulesCount\")"
                        let _92 := 0x1b3ef9db2d6f0727a31622833b45264c21051726d23ddb6f73b3b65628cafcc3
                        /// @src 6:955:47234  "library SRLib {..."
                        let _93 := sload(/** @src 6:2302:2353  "keccak256(\"lido.StakingRouter.stakingModulesCount\")" */ _92)
                        /// @src 9:560:562  "32"
                        sstore(/** @src 6:2302:2353  "keccak256(\"lido.StakingRouter.stakingModulesCount\")" */ _92, /** @src 6:955:47234  "library SRLib {..." */ 0)
                        /// @src 6:4097:4130  "uint64 totalValidatorsBalanceGwei"
                        let var_totalValidatorsBalanceGwei_1 := _2
                        var_totalValidatorsBalanceGwei_1 := _2
                        /// @src 6:955:47234  "library SRLib {..."
                        let memPtr := mload(64)
                        finalize_allocation_31433(memPtr)
                        mstore(memPtr, _2)
                        mstore(add(memPtr, 32), _2)
                        mstore(add(memPtr, 64), _2)
                        mstore(add(memPtr, 96), _2)
                        mstore(add(memPtr, 128), _2)
                        mstore(add(memPtr, 160), _2)
                        mstore(add(memPtr, 192), 96)
                        mstore(add(memPtr, 224), _2)
                        mstore(add(memPtr, 256), _2)
                        mstore(add(memPtr, 288), _2)
                        mstore(add(memPtr, 320), _2)
                        mstore(add(memPtr, 352), _2)
                        mstore(add(memPtr, 384), _2)
                        mstore(add(memPtr, 416), _2)
                        mstore(add(memPtr, 448), _2)
                        /// @src 6:4182:4191  "uint256 i"
                        let var_i_7 := _2
                        var_i_7 := _2
                        /// @src 6:4177:6566  "for (uint256 i; i < modulesCount; ++i) {..."
                        for { }
                        /** @src 6:4193:4209  "i < modulesCount" */ lt(var_i_7, _93)
                        /// @src 6:4182:4191  "uint256 i"
                        {
                            /// @src 6:4211:4214  "++i"
                            var_i_7 := /** @src 9:560:562  "32" */ add(/** @src 6:4211:4214  "++i" */ var_i_7, /** @src 6:955:47234  "library SRLib {..." */ 1)
                        }
                        /// @src 6:4211:4214  "++i"
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, var_i_7)
                            mstore(32, /** @src 6:2583:2629  "keccak256(\"lido.StakingRouter.stakingModules\")" */ 0x1d2f69fc9b5fe89d7414bf039e8d897c4c487c7603d80de6bcdd2868466f9476)
                            /// @src 6:955:47234  "library SRLib {..."
                            let dataSlot_6 := keccak256(_2, 64)
                            let memPtr_1 := mload(64)
                            finalize_allocation_31433(memPtr_1)
                            /// @src 9:560:562  "32"
                            let _94 := sload(/** @src 6:955:47234  "library SRLib {..." */ dataSlot_6)
                            mstore(memPtr_1, /** @src 9:560:562  "32" */ and(_94, 0xffffff))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 32), and(shr(24, _94), sub(shl(160, 1), 1)))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 64), /** @src 9:497:502  "10000" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(184, _94), /** @src 9:497:502  "10000" */ 0xffff))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 96), /** @src 9:497:502  "10000" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(200, _94), /** @src 9:497:502  "10000" */ 0xffff))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 128), /** @src 9:497:502  "10000" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(216, _94), /** @src 9:497:502  "10000" */ 0xffff))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 160), /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ shr(232, _94), /** @src 9:560:562  "32" */ 0xff))
                            /// @src 6:955:47234  "library SRLib {..."
                            let memPtr_2 := mload(64)
                            let ret_3 := _2
                            let slotValue := sload(add(dataSlot_6, 1))
                            let length_3 := extract_byte_array_length(slotValue)
                            mstore(memPtr_2, length_3)
                            switch and(slotValue, 1)
                            case 0 {
                                mstore(add(memPtr_2, 32), and(slotValue, not(/** @src 9:560:562  "32" */ 255)))
                                /// @src 6:955:47234  "library SRLib {..."
                                ret_3 := add(add(memPtr_2, shl(/** @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId" */ 5, /** @src 6:955:47234  "library SRLib {..." */ iszero(iszero(length_3)))), 32)
                            }
                            case 1 {
                                /// @src 9:560:562  "32"
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, add(dataSlot_6, 1))
                                let dataPos := /** @src 9:560:562  "32" */ keccak256(/** @src 6:955:47234  "library SRLib {..." */ _2, 32)
                                let i_1 := _2
                                for { } lt(i_1, length_3) { i_1 := add(i_1, 32) }
                                {
                                    mstore(add(add(memPtr_2, i_1), 32), sload(dataPos))
                                    dataPos := add(dataPos, 1)
                                }
                                ret_3 := add(add(memPtr_2, i_1), 32)
                            }
                            finalize_allocation(memPtr_2, sub(ret_3, memPtr_2))
                            mstore(add(memPtr_1, 192), memPtr_2)
                            let cleaned_7 := and(/** @src 9:497:502  "10000" */ sload(/** @src 6:955:47234  "library SRLib {..." */ add(dataSlot_6, 2)), 0xffffffffffffffff)
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 224), cleaned_7)
                            let _95 := sload(add(dataSlot_6, 3))
                            mstore(add(memPtr_1, 256), _95)
                            let _96 := sload(add(dataSlot_6, 4))
                            mstore(add(memPtr_1, 288), _96)
                            let _97 := sload(add(dataSlot_6, /** @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId" */ 5))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 320), /** @src 9:497:502  "10000" */ and(_97, 0xffff))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 352), and(shr(16, _97), 0xffffffffffffffff))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 384), and(shr(80, _97), 0xffffffffffffffff))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 416), /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(144, _97), /** @src 9:560:562  "32" */ 0xff))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 448), and(shr(152, _97), 0xffffffffffffffff))
                            /// @src 9:560:562  "32"
                            let cleaned_8 := and(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:4293:4301  "smOld.id" */ memPtr_1), /** @src 9:560:562  "32" */ 0xffffff)
                            /// @src 4:10840:10872  "_add(set._inner, bytes32(value))"
                            pop(fun_add(/** @src 7:2791:2817  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:955:47234  "library SRLib {..." */ 1), /** @src 4:10857:10871  "bytes32(value)" */ cleaned_8))
                            /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                            let var_slot_7 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, cleaned_8)
                            mstore(32, var_slot_7)
                            let dataSlot_7 := keccak256(_2, 64)
                            /// @src 6:4527:4537  "smOld.name"
                            let _98 := mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 192))
                            let newLen := mload(_98)
                            if gt(newLen, 0xffffffffffffffff)
                            {
                                mstore(_2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                /// @src 6:955:47234  "library SRLib {..."
                                mstore(4, 0x41)
                                revert(_2, 36)
                            }
                            clean_up_bytearray_end_slots_string_storage(/** @src 6:4508:4524  "moduleState.name" */ add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 3), extract_byte_array_length(sload(/** @src 6:4508:4524  "moduleState.name" */ add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 3))), newLen)
                            let srcOffset_1 := _2
                            srcOffset_1 := 32
                            switch gt(newLen, 31)
                            case 1 {
                                /// @src 9:560:562  "32"
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:4508:4524  "moduleState.name" */ add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 3))
                                let dstPtr_1 := /** @src 9:560:562  "32" */ keccak256(/** @src 6:955:47234  "library SRLib {..." */ _2, 32)
                                let i_2 := _2
                                for { }
                                lt(i_2, and(newLen, /** @src 9:560:562  "32" */ not(31)))
                                /// @src 6:955:47234  "library SRLib {..."
                                { i_2 := add(i_2, 32) }
                                {
                                    sstore(dstPtr_1, mload(add(_98, srcOffset_1)))
                                    dstPtr_1 := add(dstPtr_1, 1)
                                    srcOffset_1 := add(srcOffset_1, 32)
                                }
                                if lt(and(newLen, /** @src 9:560:562  "32" */ not(31)), /** @src 6:955:47234  "library SRLib {..." */ newLen)
                                {
                                    let lastValue := mload(add(_98, srcOffset_1))
                                    sstore(dstPtr_1, /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ lastValue, /** @src 9:560:562  "32" */ not(shr(and(shl(/** @src 6:955:47234  "library SRLib {..." */ 3, newLen), /** @src 9:560:562  "32" */ 248), not(0)))))
                                }
                                /// @src 6:955:47234  "library SRLib {..."
                                sstore(/** @src 6:4508:4524  "moduleState.name" */ add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 3), add(shl(1, newLen), 1))
                            }
                            default {
                                let value_23 := _2
                                if newLen
                                {
                                    value_23 := mload(add(_98, srcOffset_1))
                                }
                                sstore(/** @src 6:4508:4524  "moduleState.name" */ add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 3), extract_used_part_and_set_length_of_short_byte_array(value_23, newLen))
                            }
                            let cleaned_9 := and(/** @src 9:497:502  "10000" */ mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 32)), sub(shl(160, 1), 1))
                            /// @src 9:497:502  "10000"
                            let cleaned_10 := and(mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 64)), /** @src 9:497:502  "10000" */ 0xffff)
                            let cleaned_11 := and(mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 96)), /** @src 9:497:502  "10000" */ 0xffff)
                            let cleaned_12 := and(mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 128)), /** @src 9:497:502  "10000" */ 0xffff)
                            let cleaned_13 := and(mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 320)), /** @src 9:497:502  "10000" */ 0xffff)
                            /// @src 9:560:562  "32"
                            let cleaned_14 := and(/** @src 9:497:502  "10000" */ mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 160)), /** @src 9:560:562  "32" */ 0xff)
                            if iszero(lt(cleaned_14, /** @src 6:955:47234  "library SRLib {..." */ 3))
                            /// @src 9:560:562  "32"
                            {
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                                revert(/** @src 6:955:47234  "library SRLib {..." */ _2, 36)
                            }
                            let memPtr_3 := mload(64)
                            finalize_allocation_31435(memPtr_3)
                            /// @src 9:497:502  "10000"
                            mstore(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ cleaned_9)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            let _99 := add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 32)
                            /// @src 9:497:502  "10000"
                            mstore(_99, cleaned_10)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            let _100 := add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 64)
                            /// @src 9:497:502  "10000"
                            mstore(_100, cleaned_11)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            let _101 := add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 96)
                            /// @src 9:497:502  "10000"
                            mstore(_101, cleaned_12)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            let _102 := add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 128)
                            /// @src 9:497:502  "10000"
                            mstore(_102, cleaned_13)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            let _103 := add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 160)
                            /// @src 6:4597:5058  "ModuleStateConfig({..."
                            write_to_memory_enum_StakingModuleStatus(_103, cleaned_14)
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:4597:5058  "ModuleStateConfig({..." */ add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 192), 1)
                            let _104 := and(/** @src 9:497:502  "10000" */ mload(memPtr_3), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                            /// @src 9:560:562  "32"
                            let _105 := sload(dataSlot_7)
                            /// @src 9:497:502  "10000"
                            let toInsert := and(shl(/** @src 6:955:47234  "library SRLib {..." */ 160, /** @src 9:497:502  "10000" */ mload(_99)), shl(160, 65535))
                            let toInsert_1 := and(shl(176, mload(_100)), shl(176, 65535))
                            let toInsert_2 := and(shl(/** @src 6:955:47234  "library SRLib {..." */ 192, /** @src 9:497:502  "10000" */ mload(_101)), shl(192, 65535))
                            sstore(dataSlot_7, or(or(toInsert_2, or(toInsert_1, or(toInsert, or(and(/** @src 9:560:562  "32" */ _105, /** @src 9:497:502  "10000" */ shl(224, 0xffffffff)), _104)))), and(shl(208, mload(_102)), shl(208, 65535))))
                            let _106 := mload(_103)
                            /// @src 9:560:562  "32"
                            if iszero(lt(_106, /** @src 6:955:47234  "library SRLib {..." */ 3))
                            /// @src 9:560:562  "32"
                            {
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                                revert(/** @src 6:955:47234  "library SRLib {..." */ _2, 36)
                            }
                            /// @src 9:497:502  "10000"
                            update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(dataSlot_7, _106)
                            update_storage_value_offsett_uint8_to_uint8(dataSlot_7, /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:4597:5058  "ModuleStateConfig({..." */ add(memPtr_3, /** @src 6:955:47234  "library SRLib {..." */ 192)), /** @src 9:560:562  "32" */ 0xff))
                            /// @src 6:955:47234  "library SRLib {..."
                            let cleaned_15 := and(/** @src 9:497:502  "10000" */ mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 224)), 0xffffffffffffffff)
                            /// @src 6:5228:5269  "SafeCast.toUint64(smOld.lastDepositBlock)"
                            let expr_5 := fun_toUint64(/** @src 6:955:47234  "library SRLib {..." */ mload(add(memPtr_1, 256)))
                            /// @src 9:497:502  "10000"
                            let _107 := mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 352))
                            /// @src 9:497:502  "10000"
                            let _108 := mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 384))
                            let memPtr_4 := mload(64)
                            finalize_allocation_31436(memPtr_4)
                            /// @src 9:497:502  "10000"
                            mstore(memPtr_4, /** @src 6:955:47234  "library SRLib {..." */ cleaned_15)
                            let _109 := and(/** @src 9:497:502  "10000" */ expr_5, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:5120:5420  "ModuleStateDeposits({..." */ add(memPtr_4, /** @src 6:955:47234  "library SRLib {..." */ 32), _109)
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:5120:5420  "ModuleStateDeposits({..." */ add(memPtr_4, /** @src 6:955:47234  "library SRLib {..." */ 64), and(_107, 0xffffffffffffffff))
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:5120:5420  "ModuleStateDeposits({..." */ add(memPtr_4, /** @src 6:955:47234  "library SRLib {..." */ 96), and(_108, 0xffffffffffffffff))
                            /// @src 6:5097:5117  "moduleState.deposits"
                            let _110 := add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 1)
                            /// @src 9:497:502  "10000"
                            sstore(_110, or(and(sload(_110), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), cleaned_15))
                            /// @src 9:497:502  "10000"
                            update_storage_value_offsett_uint64_to_uint64(_110, _109)
                            let _111 := sload(_110)
                            sstore(_110, or(or(and(_111, 0xffffffffffffffffffffffffffffffff), and(shl(/** @src 6:955:47234  "library SRLib {..." */ 128, _107), /** @src 9:497:502  "10000" */ shl(128, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff))), /** @src 9:497:502  "10000" */ and(shl(/** @src 6:955:47234  "library SRLib {..." */ 192, _108), /** @src 9:497:502  "10000" */ shl(192, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff))))
                            /// @src 6:5600:5668  "_getStakingModuleSummary(IStakingModule(smOld.stakingModuleAddress))"
                            let expr_component_10, expr_component_11, expr_component_12 := fun_getStakingModuleSummary(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:955:47234  "library SRLib {..." */ add(memPtr_1, 32)), sub(shl(160, 1), 1)))
                            let _112 := mload(add(memPtr_1, 288))
                            /// @src 9:3248:3289  "return _ensureAmountGwei(amount / 1 gwei)"
                            let var := /** @src 9:3255:3289  "_ensureAmountGwei(amount / 1 gwei)" */ fun_ensureAmountGwei(/** @src 6:955:47234  "library SRLib {..." */ div(/** @src 6:6058:6082  "activeCount * maxEBType1" */ checked_mul_uint256(/** @src 6:5910:5997  "depositedValidatorsCount - Math.max(smOld.exitedValidatorsCount, exitedValidatorsCount)" */ checked_sub_uint256(expr_component_11, /** @src 2:3060:3102  "b ^ ((a ^ b) * SafeCast.toUint(condition))" */ xor(expr_component_10, /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:3066:3071  "a ^ b" */ xor(_112, expr_component_10), /** @src 2:3281:3286  "a > b" */ gt(_112, expr_component_10)))), /** @src 6:955:47234  "library SRLib {..." */ calldataload(4)), /** @src 9:3282:3288  "1 gwei" */ 0x3b9aca00))
                            /// @src 6:6272:6318  "SafeCast.toUint64(smOld.exitedValidatorsCount)"
                            let expr_6 := fun_toUint64(/** @src 6:955:47234  "library SRLib {..." */ mload(add(memPtr_1, 288)))
                            let memPtr_5 := mload(64)
                            if or(gt(add(memPtr_5, 64), 0xffffffffffffffff), lt(add(memPtr_5, 64), memPtr_5))
                            {
                                mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                                /// @src 6:955:47234  "library SRLib {..."
                                mstore(4, 0x41)
                                revert(0, 36)
                            }
                            mstore(64, add(memPtr_5, 64))
                            let _113 := and(/** @src 9:497:502  "10000" */ var, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                            /// @src 9:497:502  "10000"
                            mstore(memPtr_5, /** @src 6:955:47234  "library SRLib {..." */ _113)
                            let _114 := and(/** @src 9:497:502  "10000" */ expr_6, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                            /// @src 9:497:502  "10000"
                            mstore(/** @src 6:6147:6333  "ModuleStateAccounting({..." */ add(memPtr_5, /** @src 6:955:47234  "library SRLib {..." */ 32), _114)
                            /// @src 6:6122:6144  "moduleState.accounting"
                            let _115 := add(dataSlot_7, /** @src 6:955:47234  "library SRLib {..." */ 2)
                            /// @src 9:497:502  "10000"
                            sstore(_115, or(and(sload(_115), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), _113))
                            /// @src 14:478:482  "0x01"
                            update_storage_value_offsett_uint64_to_uint64(_115, /** @src 9:497:502  "10000" */ _114)
                            /// @src 6:6348:6399  "totalValidatorsBalanceGwei += validatorsBalanceGwei"
                            var_totalValidatorsBalanceGwei_1 := checked_add_uint64(var_totalValidatorsBalanceGwei_1, var)
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(_2, var_i_7)
                            mstore(32, /** @src 6:2583:2629  "keccak256(\"lido.StakingRouter.stakingModules\")" */ 0x1d2f69fc9b5fe89d7414bf039e8d897c4c487c7603d80de6bcdd2868466f9476)
                            /// @src 6:955:47234  "library SRLib {..."
                            let dataSlot_8 := keccak256(_2, 64)
                            /// @src 14:478:482  "0x01"
                            sstore(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ _2)
                            /// @src 14:478:482  "0x01"
                            let oldLen := extract_byte_array_length(sload(add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 1)))
                            /// @src 14:478:482  "0x01"
                            if iszero(iszero(oldLen))
                            {
                                switch gt(oldLen, /** @src 6:955:47234  "library SRLib {..." */ 31)
                                case /** @src 14:478:482  "0x01" */ 1 {
                                    /// @src 9:560:562  "32"
                                    mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 14:478:482  "0x01" */ add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 1))
                                    /// @src 9:560:562  "32"
                                    let data := keccak256(/** @src 6:955:47234  "library SRLib {..." */ _2, 32)
                                    /// @src 14:478:482  "0x01"
                                    clear_storage_range_bytes1(add(data, /** @src 6:955:47234  "library SRLib {..." */ 1), /** @src 14:478:482  "0x01" */ add(data, /** @src 9:560:562  "32" */ shr(/** @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId" */ 5, /** @src 9:560:562  "32" */ add(/** @src 14:478:482  "0x01" */ oldLen, /** @src 6:955:47234  "library SRLib {..." */ 31))))
                                    /// @src 14:478:482  "0x01"
                                    sstore(add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 1), 0)
                                    /// @src 14:478:482  "0x01"
                                    sstore(data, /** @src 6:955:47234  "library SRLib {..." */ _2)
                                }
                                default /// @src 14:478:482  "0x01"
                                {
                                    sstore(add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 1), 0)
                                }
                            }
                            /// @src 14:478:482  "0x01"
                            sstore(add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 2), _2)
                            /// @src 9:560:562  "32"
                            sstore(/** @src 14:478:482  "0x01" */ add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 3), 0)
                            /// @src 9:560:562  "32"
                            sstore(/** @src 14:478:482  "0x01" */ add(dataSlot_8, /** @src 6:955:47234  "library SRLib {..." */ 4), 0)
                            /// @src 14:478:482  "0x01"
                            sstore(add(dataSlot_8, /** @src 6:3157:3196  "SRStorage.getRouterState().lastModuleId" */ 5), /** @src 6:955:47234  "library SRLib {..." */ _2)
                            mstore(_2, cleaned_8)
                            mstore(32, /** @src 6:2676:2736  "keccak256(\"lido.StakingRouter.stakingModuleIndicesOneBased\")" */ 0x9b48f5b32acb95b982effe269feac267eead113c4b5af14ffeb9aadac18a6e9c)
                            /// @src 9:560:562  "32"
                            sstore(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64), 0)
                        }
                        let memPtr_6 := mload(64)
                        let newFreePtr := add(memPtr_6, 32)
                        let _116 := 0xffffffffffffffff
                        if or(gt(newFreePtr, _116), lt(newFreePtr, memPtr_6))
                        {
                            mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(4, 0x41)
                            revert(0, 36)
                        }
                        mstore(64, newFreePtr)
                        /// @src 9:497:502  "10000"
                        mstore(memPtr_6, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:497:502  "10000" */ var_totalValidatorsBalanceGwei_1, /** @src 6:955:47234  "library SRLib {..." */ _116))
                        /// @src 6:6704:6741  "SRStorage.getRouterState().accounting"
                        let _117 := add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 6:955:47234  "library SRLib {..." */ 3)
                        /// @src 9:497:502  "10000"
                        sstore(_117, or(and(sload(_117), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), and(/** @src 9:497:502  "10000" */ mload(/** @src 14:478:482  "0x01" */ memPtr_6), /** @src 6:955:47234  "library SRLib {..." */ _116)))
                        return(_2, _2)
                    }
                    case 0xe2081ac8 {
                        let _118 := add(calldatasize(), not(3))
                        if slt(_118, 160) { revert(_2, _2) }
                        if slt(_118, 64) { revert(_2, _2) }
                        let value_24 := calldataload(132)
                        if iszero(eq(value_24, iszero(iszero(value_24)))) { revert(0, 0) }
                        /// @src 6:20027:20082  "_getDepositAllocations(_cfg, _allocateAmount, _isTopUp)"
                        let expr_component_13, expr_component_mpos, expr_component_mpos_1 := fun_getDepositAllocations(/** @src 6:955:47234  "library SRLib {..." */ calldataload(100), value_24)
                        /// @src 7:2655:2699  "getRouterState().moduleIds._inner._positions"
                        let _119 := add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:2655:2699  "getRouterState().moduleIds._inner._positions" */ 2)
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, calldataload(68))
                        mstore(0x20, _119)
                        let _120 := sload(keccak256(_2, 64))
                        let diff_1 := add(_120, /** @src 9:560:562  "32" */ not(0))
                        /// @src 6:955:47234  "library SRLib {..."
                        if gt(diff_1, _120)
                        {
                            /// @src 9:560:562  "32"
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x11)
                            revert(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ 0x24)
                        }
                        /// @src 6:955:47234  "library SRLib {..."
                        let _121 := mload(/** @src 6:20173:20193  "allocated[moduleIdx]" */ memory_array_index_access_uint256_dyn(expr_component_mpos, /** @src 6:20112:20150  "SRUtils._getModuleIndexById(_moduleId)" */ diff_1))
                        /// @src 6:955:47234  "library SRLib {..."
                        let memPos_3 := mload(64)
                        mstore(memPos_3, _121)
                        return(memPos_3, 0x20)
                    }
                    case 0xf478e2b0 {
                        if _1 { revert(_2, _2) }
                        let param_21, param_22, param_23, param_24, param_25 := abi_decode_uint256t_bytes_calldatat_bytes_calldata(calldatasize())
                        /// @src 6:34489:34505  "_stakingModuleId"
                        fun_requireModuleIdExists(param_21)
                        /// @src 6:46887:46907  "_ids.length % 8 != 0"
                        let _122 := iszero(/** @src 6:955:47234  "library SRLib {..." */ and(param_23, 7))
                        /// @src 6:46887:46935  "_ids.length % 8 != 0 || _values.length % 16 != 0"
                        let expr_7 := /** @src 6:46887:46907  "_ids.length % 8 != 0" */ iszero(_122)
                        /// @src 6:46887:46935  "_ids.length % 8 != 0 || _values.length % 16 != 0"
                        if _122
                        {
                            expr_7 := /** @src 6:46911:46935  "_values.length % 16 != 0" */ iszero(iszero(/** @src 6:955:47234  "library SRLib {..." */ and(param_25, 15)))
                        }
                        /// @src 6:46883:46997  "if (_ids.length % 8 != 0 || _values.length % 16 != 0) {..."
                        if expr_7
                        {
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            let _123 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            mstore(_123, shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ add(_123, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:46984:46985  "3" */ 0x03)
                            /// @src 6:46958:46986  "ISRBase.InvalidReportData(3)"
                            revert(_123, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        let r_1 := shr(3, param_23)
                        /// @src 6:47047:47141  "if (_values.length / 16 != count) {..."
                        if /** @src 6:47051:47079  "_values.length / 16 != count" */ iszero(eq(/** @src 6:955:47234  "library SRLib {..." */ shr(4, param_25), /** @src 6:47051:47079  "_values.length / 16 != count" */ r_1))
                        /// @src 6:47047:47141  "if (_values.length / 16 != count) {..."
                        {
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            let _124 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            mstore(_124, /** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:47102:47130  "ISRBase.InvalidReportData(2)" */ add(_124, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:47128:47129  "2" */ 0x02)
                            /// @src 6:47102:47130  "ISRBase.InvalidReportData(2)"
                            revert(_124, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        /// @src 6:47150:47226  "if (count == 0) {..."
                        if /** @src 6:47154:47164  "count == 0" */ iszero(r_1)
                        /// @src 6:47150:47226  "if (count == 0) {..."
                        {
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            let _125 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            mstore(_125, /** @src 6:46958:46986  "ISRBase.InvalidReportData(3)" */ shl(225, 0x63209a7d))
                            /// @src 6:955:47234  "library SRLib {..."
                            mstore(/** @src 6:47187:47215  "ISRBase.InvalidReportData(1)" */ add(_125, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:47213:47214  "1" */ 0x01)
                            /// @src 6:47187:47215  "ISRBase.InvalidReportData(1)"
                            revert(_125, /** @src 6:955:47234  "library SRLib {..." */ 36)
                        }
                        /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                        let _126 := constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, param_21)
                        mstore(0x20, _126)
                        let cleaned_16 := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64)), sub(shl(160, 1), 1))
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        if iszero(extcodesize(cleaned_16))
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            revert(_2, _2)
                        }
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        let _127 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        mstore(_127, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0xb643189b))
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        let _128 := call(gas(), cleaned_16, /** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)" */ _127, sub(abi_encode_bytes_calldata_bytes_calldata(add(_127, /** @src 6:955:47234  "library SRLib {..." */ 4), /** @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)" */ param_22, param_23, param_24, param_25), _127), _127, /** @src 6:955:47234  "library SRLib {..." */ _2)
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        if iszero(_128)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos_5 := mload(64)
                            returndatacopy(pos_5, _2, returndatasize())
                            revert(pos_5, returndatasize())
                        }
                        /// @src 6:34595:34706  "_stakingModuleId.getIStakingModule().decreaseVettedSigningKeysCount(_nodeOperatorIds, _vettedSigningKeysCounts)"
                        if _128
                        {
                            finalize_allocation_31410(_127)
                            /// @src 6:955:47234  "library SRLib {..."
                            if _2 { revert(_2, _2) }
                        }
                        return(_2, _2)
                    }
                    case 0xf5733015 {
                        if _1 { revert(_2, _2) }
                        if slt(add(calldatasize(), not(3)), 96) { revert(_2, _2) }
                        let value_25 := calldataload(4)
                        let value_26 := calldataload(36)
                        let value_27 := calldataload(68)
                        /// @src 6:15447:15474  "_priorityExitShareThreshold"
                        fun_validateShareParams(value_26, value_27)
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var_slot_8 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, value_25)
                        mstore(32, var_slot_8)
                        /// @src 9:497:502  "10000"
                        let converted := read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:955:47234  "library SRLib {..." */ keccak256(_2, 64))
                        /// @src 9:497:502  "10000"
                        let _129 := 0xffff
                        /// @src 6:15642:15669  "stateConfig.stakeShareLimit"
                        let _130 := add(converted, /** @src 6:955:47234  "library SRLib {..." */ 96)
                        /// @src 9:497:502  "10000"
                        mstore(_130, and(/** @src 6:15672:15696  "uint16(_stakeShareLimit)" */ value_26, /** @src 9:497:502  "10000" */ _129))
                        /// @src 6:15706:15744  "stateConfig.priorityExitShareThreshold"
                        let _131 := add(converted, 128)
                        /// @src 9:497:502  "10000"
                        mstore(_131, and(/** @src 6:15747:15782  "uint16(_priorityExitShareThreshold)" */ value_27, /** @src 9:497:502  "10000" */ _129))
                        /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                        let var_slot_9 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(_2, value_25)
                        mstore(32, var_slot_9)
                        let dataSlot_9 := keccak256(_2, 64)
                        let _132 := and(/** @src 9:497:502  "10000" */ mload(converted), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                        /// @src 9:560:562  "32"
                        let _133 := sload(dataSlot_9)
                        /// @src 9:497:502  "10000"
                        let _134 := mload(add(converted, /** @src 6:955:47234  "library SRLib {..." */ 32))
                        /// @src 9:497:502  "10000"
                        let toInsert_3 := and(shl(176, mload(add(converted, /** @src 6:955:47234  "library SRLib {..." */ 64))), /** @src 9:497:502  "10000" */ shl(176, 65535))
                        let _135 := mload(_130)
                        sstore(dataSlot_9, or(or(and(shl(192, _135), shl(192, 65535)), or(toInsert_3, or(and(shl(160, _134), shl(160, 65535)), or(and(/** @src 9:560:562  "32" */ _133, /** @src 9:497:502  "10000" */ shl(224, 0xffffffff)), _132)))), and(shl(208, mload(_131)), shl(208, 65535))))
                        let _136 := mload(add(converted, 160))
                        /// @src 9:560:562  "32"
                        if iszero(lt(_136, 3))
                        {
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ _2, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                            revert(/** @src 6:955:47234  "library SRLib {..." */ _2, 36)
                        }
                        /// @src 9:497:502  "10000"
                        update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(dataSlot_9, _136)
                        update_storage_value_offsett_uint8_to_uint8(dataSlot_9, /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(add(converted, 192)), /** @src 9:560:562  "32" */ 0xff))
                        /// @src 6:15928:16032  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, msg.sender)"
                        let _137 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:15928:16032  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, msg.sender)"
                        log2(_137, sub(abi_encode_uint256_uint256_address(_137, value_26, value_27, /** @src 6:16021:16031  "msg.sender" */ caller()), /** @src 6:15928:16032  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, msg.sender)" */ _137), 0x1730859048adcce16559e75a58fd609e9dbf7d34f39bcb7a45ad388dfbba0e4e, value_25)
                        /// @src 6:955:47234  "library SRLib {..."
                        return(_2, _2)
                    }
                    case 0xff05c287 {
                        if _1 { revert(_2, _2) }
                        let param_26, param_27, param_28, param_29 := abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(calldatasize())
                        fun_updateAllModuleFees(param_26, param_27, param_28, param_29)
                        return(_2, _2)
                    }
                }
                revert(0, 0)
            }
            function abi_decode_bytes_calldata(offset, end) -> arrayPos, length
            {
                if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
                length := calldataload(offset)
                if gt(length, 0xffffffffffffffff) { revert(0, 0) }
                arrayPos := add(offset, 0x20)
                if gt(add(add(offset, length), 0x20), end) { revert(0, 0) }
            }
            function abi_decode_array_struct_ValidatorExitData_calldata_dyn_calldata(offset, end) -> arrayPos, length
            {
                if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
                length := calldataload(offset)
                if gt(length, 0xffffffffffffffff) { revert(0, 0) }
                arrayPos := add(offset, 0x20)
                if gt(add(add(offset, shl(5, length)), 0x20), end) { revert(0, 0) }
            }
            function abi_encode_array_uint256_dyn(value, pos) -> end
            {
                let length := mload(value)
                mstore(pos, length)
                let _1 := 0x20
                pos := add(pos, 0x20)
                let srcPtr := add(value, 0x20)
                let i := /** @src -1:-1:-1 */ 0
                /// @src 6:955:47234  "library SRLib {..."
                for { } lt(i, length) { i := add(i, 1) }
                {
                    mstore(pos, mload(srcPtr))
                    pos := add(pos, _1)
                    srcPtr := add(srcPtr, _1)
                }
                end := pos
            }
            function abi_decode_uint256t_bytes_calldatat_bytes_calldata(dataEnd) -> value0, value1, value2, value3, value4
            {
                if slt(add(dataEnd, not(3)), 96) { revert(0, 0) }
                value0 := calldataload(4)
                let offset := calldataload(36)
                let _1 := 0xffffffffffffffff
                if gt(offset, _1)
                {
                    revert(/** @src -1:-1:-1 */ 0, 0)
                }
                /// @src 6:955:47234  "library SRLib {..."
                let value1_1, value2_1 := abi_decode_bytes_calldata(add(4, offset), dataEnd)
                value1 := value1_1
                value2 := value2_1
                let offset_1 := calldataload(68)
                if gt(offset_1, _1)
                {
                    revert(/** @src -1:-1:-1 */ 0, 0)
                }
                /// @src 6:955:47234  "library SRLib {..."
                let value3_1, value4_1 := abi_decode_bytes_calldata(add(4, offset_1), dataEnd)
                value3 := value3_1
                value4 := value4_1
            }
            function abi_decode_array_uint256_dyn_calldatat_array_uint256_dyn_calldata(dataEnd) -> value0, value1, value2, value3
            {
                if slt(add(dataEnd, not(3)), 64) { revert(0, 0) }
                let offset := calldataload(4)
                let _1 := 0xffffffffffffffff
                if gt(offset, _1) { revert(0, 0) }
                let value0_1, value1_1 := abi_decode_array_struct_ValidatorExitData_calldata_dyn_calldata(add(4, offset), dataEnd)
                value0 := value0_1
                value1 := value1_1
                let offset_1 := calldataload(36)
                if gt(offset_1, _1) { revert(0, 0) }
                let value2_1, value3_1 := abi_decode_array_struct_ValidatorExitData_calldata_dyn_calldata(add(4, offset_1), dataEnd)
                value2 := value2_1
                value3 := value3_1
            }
            function finalize_allocation_31410(memPtr)
            {
                if gt(memPtr, 0xffffffffffffffff)
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, memPtr)
            }
            function finalize_allocation_31433(memPtr)
            {
                let newFreePtr := add(memPtr, 480)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation_31435(memPtr)
            {
                let newFreePtr := add(memPtr, 224)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation_31436(memPtr)
            {
                let newFreePtr := add(memPtr, 128)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation_31499(memPtr)
            {
                let newFreePtr := add(memPtr, 160)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation_47073(memPtr)
            {
                let newFreePtr := add(memPtr, 0x20)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation_47078(memPtr)
            {
                let newFreePtr := add(memPtr, 64)
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function finalize_allocation(memPtr, size)
            {
                let newFreePtr := add(memPtr, and(add(size, 31), /** @src 9:560:562  "32" */ not(31)))
                /// @src 6:955:47234  "library SRLib {..."
                if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                mstore(64, newFreePtr)
            }
            function abi_encode_bytes_calldata(start, length, pos) -> end
            {
                mstore(pos, length)
                calldatacopy(add(pos, 0x20), start, length)
                mstore(add(add(pos, length), 0x20), /** @src -1:-1:-1 */ 0)
                /// @src 6:955:47234  "library SRLib {..."
                end := add(add(pos, and(add(length, 31), /** @src 9:560:562  "32" */ not(31))), /** @src 6:955:47234  "library SRLib {..." */ 0x20)
            }
            /// @src 9:560:562  "32"
            function update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(slot, value)
            {
                if iszero(lt(value, 3))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    mstore(4, 0x21)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x24)
                }
                let _1 := sload(slot)
                sstore(slot, or(and(_1, not(shl(224, 255))), and(/** @src 6:955:47234  "library SRLib {..." */ shl(224, /** @src 9:560:562  "32" */ value), shl(224, 255))))
            }
            function update_storage_value_offsett_uint8_to_uint8(slot, value)
            {
                let _1 := sload(slot)
                sstore(slot, or(and(_1, not(shl(232, 255))), and(shl(232, value), shl(232, 255))))
            }
            function extract_byte_array_length(data) -> length
            {
                length := shr(1, data)
                let outOfPlaceEncoding := and(data, 1)
                if iszero(outOfPlaceEncoding) { length := and(length, 0x7f) }
                if eq(outOfPlaceEncoding, lt(length, 32))
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x22)
                    revert(0, 0x24)
                }
            }
            function clear_storage_range_bytes1(start, end)
            {
                for { } lt(start, end) { start := add(start, 1) }
                {
                    sstore(start, /** @src -1:-1:-1 */ 0)
                }
            }
            /// @src 9:560:562  "32"
            function clean_up_bytearray_end_slots_string_storage(array, len, startIndex)
            {
                if gt(len, 31)
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ array)
                    let data := keccak256(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x20)
                    let deleteStart := add(data, shr(5, add(startIndex, 31)))
                    if lt(startIndex, 0x20) { deleteStart := data }
                    clear_storage_range_bytes1(deleteStart, add(data, shr(5, add(len, 31))))
                }
            }
            function extract_used_part_and_set_length_of_short_byte_array(data, len) -> used
            {
                used := or(and(data, not(shr(shl(3, len), not(0)))), shl(1, len))
            }
            /// @src 6:955:47234  "library SRLib {..."
            function access_calldata_tail_bytes_calldata(base_ref, ptr_to_tail) -> addr, length
            {
                let rel_offset_of_tail := calldataload(ptr_to_tail)
                if iszero(slt(rel_offset_of_tail, add(sub(calldatasize(), base_ref), not(30)))) { revert(0, 0) }
                let addr_1 := add(base_ref, rel_offset_of_tail)
                length := calldataload(addr_1)
                if gt(length, 0xffffffffffffffff) { revert(0, 0) }
                addr := add(addr_1, 0x20)
                if sgt(addr, sub(calldatasize(), length)) { revert(0, 0) }
            }
            function extract_returndata() -> data
            {
                switch returndatasize()
                case 0 { data := 96 }
                default {
                    let _1 := returndatasize()
                    if gt(_1, 0xffffffffffffffff)
                    {
                        mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(4, 0x41)
                        revert(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x24)
                    }
                    let memPtr := mload(64)
                    finalize_allocation(memPtr, add(and(add(_1, 31), /** @src 9:560:562  "32" */ not(31)), /** @src 6:955:47234  "library SRLib {..." */ 0x20))
                    mstore(memPtr, _1)
                    data := memPtr
                    returndatacopy(add(memPtr, 0x20), /** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ returndatasize())
                }
            }
            function array_allocation_size_array_uint256_dyn(length) -> size
            {
                if gt(length, 0xffffffffffffffff)
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x41)
                    revert(0, 0x24)
                }
                size := add(shl(5, length), 0x20)
            }
            function allocate_and_zero_memory_array_array_uint256_dyn(length) -> memPtr
            {
                let _1 := array_allocation_size_array_uint256_dyn(length)
                let memPtr_1 := mload(64)
                finalize_allocation(memPtr_1, _1)
                mstore(memPtr_1, length)
                memPtr := memPtr_1
                calldatacopy(add(memPtr_1, 32), calldatasize(), add(array_allocation_size_array_uint256_dyn(length), /** @src 9:560:562  "32" */ not(31)))
            }
            /// @src 6:955:47234  "library SRLib {..."
            function checked_div_uint256(x, y) -> r
            {
                if iszero(y)
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x12)
                    revert(0, 0x24)
                }
                r := div(x, y)
            }
            function memory_array_index_access_uint256_dyn(baseRef, index) -> addr
            {
                if iszero(lt(index, mload(baseRef)))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                addr := add(add(baseRef, shl(5, index)), 32)
            }
            function checked_mul_uint256(x, y) -> product
            {
                product := mul(x, y)
                if iszero(or(iszero(x), eq(y, div(product, x))))
                {
                    /// @src 9:560:562  "32"
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @src 6:955:47234  "library SRLib {..."
            function checked_sub_uint256(x, y) -> diff
            {
                diff := sub(x, y)
                if gt(diff, x)
                {
                    /// @src 9:560:562  "32"
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @ast-id 1371 @src 6:17690:19718  "function _getDepositAllocations(Config calldata _cfg, uint256 _allocateAmount, bool _isTopUp)..."
            function fun_getDepositAllocations_31414(var__allocateAmount, var_isTopUp) -> var_totalAllocated, var_allocated_mpos, var_newAllocations_mpos
            {
                /// @src 6:17829:17851  "uint256 totalAllocated"
                var_totalAllocated := /** @src 6:955:47234  "library SRLib {..." */ 0
                let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:17988:18082  "if (modulesCount == 0) {..."
                if /** @src 6:17992:18009  "modulesCount == 0" */ iszero(length)
                /// @src 6:17988:18082  "if (modulesCount == 0) {..."
                {
                    /// @src 6:955:47234  "library SRLib {..."
                    let memPtr := mload(64)
                    finalize_allocation_47073(memPtr)
                    mstore(memPtr, 0)
                    let memPtr_1 := mload(64)
                    finalize_allocation_47073(memPtr_1)
                    mstore(memPtr_1, 0)
                    calldatacopy(0, calldatasize(), 0)
                    /// @src 6:18025:18071  "return (0, new uint256[](0), new uint256[](0))"
                    var_totalAllocated := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:18025:18071  "return (0, new uint256[](0), new uint256[](0))"
                    var_allocated_mpos := memPtr
                    var_newAllocations_mpos := memPtr_1
                    leave
                }
                /// @src 6:18252:18284  "_allocateAmount / initialDeposit"
                let expr := checked_div_uint256(var__allocateAmount, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                let length_1 := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:23169:23211  "_allocations = new uint256[](modulesCount)"
                let var_allocations_mpos := /** @src 6:23184:23211  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length_1)
                /// @src 6:955:47234  "library SRLib {..."
                let _1 := array_allocation_size_array_uint256_dyn(length_1)
                let memPtr_2 := mload(64)
                finalize_allocation(memPtr_2, _1)
                mstore(memPtr_2, length_1)
                let _2 := add(array_allocation_size_array_uint256_dyn(length_1), /** @src 9:560:562  "32" */ not(31))
                /// @src 6:955:47234  "library SRLib {..."
                let i := 0
                for { } lt(i, _2) { i := add(i, 32) }
                {
                    let memPtr_3 := mload(64)
                    finalize_allocation_31499(memPtr_3)
                    mstore(memPtr_3, 0)
                    let _3 := 32
                    mstore(add(memPtr_3, _3), 0)
                    mstore(add(memPtr_3, 64), 0)
                    mstore(add(memPtr_3, 96), 0)
                    mstore(add(memPtr_3, 128), 0)
                    mstore(add(add(memPtr_2, i), _3), memPtr_3)
                }
                let memPtr_4 := mload(64)
                finalize_allocation_31435(memPtr_4)
                mstore(memPtr_4, 0)
                mstore(add(memPtr_4, 32), 0)
                mstore(add(memPtr_4, 64), 0)
                mstore(add(memPtr_4, 96), 0)
                mstore(add(memPtr_4, 128), 0)
                mstore(add(memPtr_4, 160), 0)
                mstore(add(memPtr_4, 192), 0)
                /// @src 6:23447:23491  "uint256 totalValidators = depositsToAllocate"
                let var_totalValidators := expr
                /// @src 6:23552:23565  "uint256 i = 0"
                let var_i := /** @src 6:955:47234  "library SRLib {..." */ 0
                /// @src 6:23547:24929  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:23567:23583  "i < modulesCount" */ lt(var_i, length_1)
                /// @src 6:23552:23565  "uint256 i = 0"
                {
                    /// @src 6:23585:23588  "++i"
                    var_i := /** @src 9:560:562  "32" */ add(/** @src 6:23585:23588  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                }
                /// @src 6:23585:23588  "++i"
                {
                    /// @src 4:5016:5034  "set._values[index]"
                    let _4, _5 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1), /** @src 4:5016:5034  "set._values[index]" */ var_i)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _6 := sload(/** @src 4:5016:5034  "set._values[index]" */ _4)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _7 := 3
                    /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                    let _8 := constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                    mstore(32, _8)
                    let dataSlot := keccak256(0, 64)
                    /// @src 6:23716:23748  "stateConfig = moduleState.config"
                    let var_stateConfig_mpos := /** @src 9:497:502  "10000" */ read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:23716:23748  "stateConfig = moduleState.config" */ dataSlot)
                    /// @src 9:497:502  "10000"
                    mstore(/** @src 6:23792:23811  "cache[i].shareLimit" */ add(/** @src 6:23792:23800  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 64), /** @src 9:497:502  "10000" */ and(mload(/** @src 6:23814:23841  "stateConfig.stakeShareLimit" */ add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 96)), /** @src 9:497:502  "10000" */ 0xffff))
                    let _9 := mload(/** @src 6:23873:23891  "stateConfig.status" */ add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 160))
                    /// @src 9:560:562  "32"
                    if iszero(lt(_9, /** @src 6:955:47234  "library SRLib {..." */ _7))
                    /// @src 9:560:562  "32"
                    {
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                        revert(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ 0x24)
                    }
                    /// @src 6:23855:23891  "cache[i].status = stateConfig.status"
                    write_to_memory_enum_StakingModuleStatus(/** @src 6:23855:23870  "cache[i].status" */ add(/** @src 6:23855:23863  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 96), /** @src 9:497:502  "10000" */ _9)
                    /// @src 6:23923:23960  "stateConfig.withdrawalCredentialsType"
                    let _10 := add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 192)
                    /// @src 9:560:562  "32"
                    let _11 := 0xff
                    /// @src 9:497:502  "10000"
                    mstore(/** @src 6:23905:23920  "cache[i].wcType" */ add(/** @src 6:23905:23913  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 128), /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:23923:23960  "stateConfig.withdrawalCredentialsType" */ _10), /** @src 9:560:562  "32" */ _11))
                    /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                    let var_slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                    mstore(32, var_slot)
                    let _12 := sub(shl(160, 1), 1)
                    /// @src 6:24094:24148  "_getStakingModuleSummary(moduleId.getIStakingModule())"
                    let expr_component, expr_component_1, expr_component_2 := fun_getStakingModuleSummary(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(0, 64)), _12))
                    mstore(/** @src 6:24162:24170  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ expr_component_2)
                    /// @src 6:24375:24397  "moduleState.accounting"
                    let _13 := 2
                    /// @src 6:955:47234  "library SRLib {..."
                    let value := and(shr(64, sload(/** @src 6:24375:24397  "moduleState.accounting" */ add(dataSlot, _13))), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                    /// @src 6:24274:24420  "uint256 validatorsCount = depositedValidatorsCount..."
                    let var_validatorsCount := /** @src 6:24300:24420  "depositedValidatorsCount..." */ checked_sub_uint256(expr_component_1, /** @src 2:3060:3102  "b ^ ((a ^ b) * SafeCast.toUint(condition))" */ xor(value, /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:3066:3071  "a ^ b" */ xor(expr_component, value), /** @src 2:3281:3286  "a > b" */ gt(expr_component, value))))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:24464:24484  "cache[i].activeCount" */ add(/** @src 6:24464:24472  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 32), var_validatorsCount)
                    /// @src 6:24517:24824  "if (WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)) {..."
                    if /** @src 14:1679:1699  "wcType == WC_TYPE_02" */ eq(/** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:24551:24588  "stateConfig.withdrawalCredentialsType" */ _10), /** @src 9:560:562  "32" */ _11), /** @src 6:24375:24397  "moduleState.accounting" */ _13)
                    /// @src 6:24517:24824  "if (WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)) {..."
                    {
                        /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                        let _14 := constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                        mstore(32, _14)
                        let cleaned := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(0, 64)), _12)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let _15 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        mstore(_15, /** @src 6:955:47234  "library SRLib {..." */ shl(226, 0x03214bd7))
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let _16 := staticcall(gas(), cleaned, _15, /** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ _15, /** @src 6:955:47234  "library SRLib {..." */ 32)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        if iszero(_16)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let expr_1 := /** @src 6:955:47234  "library SRLib {..." */ 0
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        if _16
                        {
                            let _17 := /** @src 6:955:47234  "library SRLib {..." */ 32
                            /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                            if gt(/** @src 6:955:47234  "library SRLib {..." */ 32, /** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ returndatasize()) { _17 := returndatasize() }
                            finalize_allocation(_15, _17)
                            /// @src 6:955:47234  "library SRLib {..."
                            if slt(sub(/** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ add(_15, _17), /** @src 6:955:47234  "library SRLib {..." */ _15), 32) { revert(0, 0) }
                            /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                            expr_1 := /** @src 6:955:47234  "library SRLib {..." */ mload(_15)
                        }
                        /// @src 2:4050:4200  "if (b == 0) {..."
                        if /** @src 2:4054:4060  "b == 0" */ iszero(/** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                        /// @src 2:4050:4200  "if (b == 0) {..."
                        {
                            /// @src 0:1829:1964  "assembly (\"memory-safe\") {..."
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 0:1829:1964  "assembly (\"memory-safe\") {..." */ 0x4e487b71)
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 32, /** @src 0:1035:1039  "0x12" */ 0x12)
                            /// @src 0:1829:1964  "assembly (\"memory-safe\") {..."
                            revert(0x1c, 0x24)
                        }
                        /// @src 6:24713:24809  "validatorsCount = Math.ceilDiv(moduleId.getIStakingModuleV2().getTotalModuleStake(), maxEBType1)"
                        var_validatorsCount := /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:4630:4635  "a > 0" */ iszero(iszero(expr_1)), /** @src 0:1035:1039  "0x12" */ add(/** @src 2:4640:4651  "(a - 1) / b" */ checked_div_uint256(/** @src 6:955:47234  "library SRLib {..." */ add(/** @src 2:4641:4646  "a - 1" */ expr_1, /** @src 9:560:562  "32" */ not(0)), calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                    }
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:24837:24870  "_allocations[i] = validatorsCount" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i), /** @src 6:955:47234  "library SRLib {..." */ var_validatorsCount)
                    /// @src 6:24884:24918  "totalValidators += validatorsCount"
                    var_totalValidators := checked_add_uint256(var_totalValidators, var_validatorsCount)
                }
                /// @src 6:24938:24979  "_capacities = new uint256[](modulesCount)"
                let var_capacities_mpos := /** @src 6:24952:24979  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length_1)
                /// @src 6:25086:25099  "uint256 i = 0"
                let var_i_1 := /** @src 6:955:47234  "library SRLib {..." */ 0
                /// @src 6:25081:26318  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:25101:25117  "i < modulesCount" */ lt(var_i_1, length_1)
                /// @src 6:25086:25099  "uint256 i = 0"
                {
                    /// @src 6:25119:25122  "++i"
                    var_i_1 := /** @src 9:560:562  "32" */ add(/** @src 6:25119:25122  "++i" */ var_i_1, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                }
                /// @src 6:25119:25122  "++i"
                {
                    /// @src 6:25198:25242  "uint256 validatorsCapacity = _allocations[i]"
                    let var_validatorsCapacity := /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25227:25242  "_allocations[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_1))
                    /// @src 9:497:502  "10000"
                    let _18 := mload(/** @src 6:25260:25275  "cache[i].status" */ add(/** @src 6:25260:25268  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 96))
                    /// @src 9:560:562  "32"
                    if iszero(lt(_18, /** @src 6:955:47234  "library SRLib {..." */ 3))
                    /// @src 9:560:562  "32"
                    {
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                        revert(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 6:25055:25070  "_cfg.maxEBType2" */ 36)
                    }
                    /// @src 6:25256:26258  "if (cache[i].status == StakingModuleStatus.Active) {..."
                    if /** @src 6:25260:25305  "cache[i].status == StakingModuleStatus.Active" */ iszero(_18)
                    /// @src 6:25256:26258  "if (cache[i].status == StakingModuleStatus.Active) {..."
                    {
                        /// @src 6:25329:25387  "_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)"
                        let expr_2 := var_isTopUp
                        if var_isTopUp
                        {
                            expr_2 := /** @src 14:1679:1699  "wcType == WC_TYPE_02" */ eq(/** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:25371:25386  "cache[i].wcType" */ add(/** @src 6:25371:25379  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 128)), /** @src 9:560:562  "32" */ 0xff), /** @src 6:24375:24397  "moduleState.accounting" */ 2)
                        }
                        /// @src 6:25325:25772  "if (_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)) {..."
                        switch expr_2
                        case 0 {
                            /// @src 6:955:47234  "library SRLib {..."
                            let _19 := mload(/** @src 6:25710:25725  "_allocations[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_1))
                            /// @src 6:25689:25753  "validatorsCapacity = _allocations[i] + cache[i].depositableCount"
                            var_validatorsCapacity := /** @src 6:25710:25753  "_allocations[i] + cache[i].depositableCount" */ checked_add_uint256(_19, /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25728:25736  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1))))
                        }
                        default /// @src 6:25325:25772  "if (_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)) {..."
                        {
                            /// @src 6:25575:25642  "validatorsCapacity = cache[i].activeCount * maxEBType2 / maxEBType1"
                            var_validatorsCapacity := /** @src 6:25596:25642  "cache[i].activeCount * maxEBType2 / maxEBType1" */ checked_div_uint256(/** @src 6:25596:25629  "cache[i].activeCount * maxEBType2" */ checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25596:25616  "cache[i].activeCount" */ add(/** @src 6:25596:25604  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 32)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:25055:25070  "_cfg.maxEBType2" */ 36)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                        }
                        let r := div(/** @src 6:26004:26041  "cache[i].shareLimit * totalValidators" */ checked_mul_uint256(/** @src 9:497:502  "10000" */ and(mload(/** @src 6:26004:26023  "cache[i].shareLimit" */ add(/** @src 6:26004:26012  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 64)), /** @src 9:497:502  "10000" */ 0xffff), /** @src 6:26004:26041  "cache[i].shareLimit * totalValidators" */ var_totalValidators), /** @src 9:497:502  "10000" */ 0x2710)
                        /// @src 6:26176:26243  "validatorsCapacity = Math.min(targetValidators, validatorsCapacity)"
                        var_validatorsCapacity := /** @src 2:3060:3102  "b ^ ((a ^ b) * SafeCast.toUint(condition))" */ xor(var_validatorsCapacity, /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:3066:3071  "a ^ b" */ xor(r, var_validatorsCapacity), /** @src 2:3463:3468  "a < b" */ lt(r, var_validatorsCapacity)))
                    }
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:26272:26307  "_capacities[i] = validatorsCapacity" */ memory_array_index_access_uint256_dyn(var_capacities_mpos, var_i_1), /** @src 6:955:47234  "library SRLib {..." */ var_validatorsCapacity)
                }
                /// @src 6:18490:18584  "(allocated, capacities) = _getModulesAllocationAndCapacity(_cfg, depositsToAllocate, _isTopUp)"
                var_allocated_mpos := var_allocations_mpos
                /// @src 6:18655:19712  "if (depositsToAllocate > 0) {..."
                switch /** @src 6:18659:18681  "depositsToAllocate > 0" */ iszero(iszero(expr))
                case /** @src 6:18655:19712  "if (depositsToAllocate > 0) {..." */ 0 {
                    /// @src 6:19417:19461  "newAllocations = new uint256[](modulesCount)"
                    var_newAllocations_mpos := /** @src 6:19434:19461  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length)
                    /// @src 6:19548:19561  "uint256 i = 0"
                    let var_i_2 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:19543:19702  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                    for { }
                    /** @src 6:19563:19579  "i < modulesCount" */ lt(var_i_2, length)
                    /// @src 6:19548:19561  "uint256 i = 0"
                    {
                        /// @src 6:19581:19584  "++i"
                        var_i_2 := /** @src 9:560:562  "32" */ add(/** @src 6:19581:19584  "++i" */ var_i_2, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                    }
                    /// @src 6:19581:19584  "++i"
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(/** @src 6:19604:19653  "newAllocations[i] = allocated[i] * initialDeposit" */ memory_array_index_access_uint256_dyn(var_newAllocations_mpos, var_i_2), /** @src 6:19624:19653  "allocated[i] * initialDeposit" */ checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19624:19636  "allocated[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_2)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                        mstore(/** @src 6:19671:19687  "allocated[i] = 0" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_2), /** @src 6:955:47234  "library SRLib {..." */ 0)
                    }
                }
                default /// @src 6:18655:19712  "if (depositsToAllocate > 0) {..."
                {
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let _20 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    mstore(_20, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x2529fbc9))
                    mstore(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ add(_20, /** @src 6:955:47234  "library SRLib {..." */ 4), 96)
                    let tail := abi_encode_array_uint256_dyn(var_allocations_mpos, add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:955:47234  "library SRLib {..." */ 100))
                    mstore(add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:25055:25070  "_cfg.maxEBType2" */ 36), /** @src 6:955:47234  "library SRLib {..." */ add(sub(tail, /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20), /** @src 6:955:47234  "library SRLib {..." */ not(3)))
                    let tail_1 := abi_encode_array_uint256_dyn(var_capacities_mpos, tail)
                    mstore(add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:955:47234  "library SRLib {..." */ 68), expr)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let _21 := delegatecall(gas(), /** @src 6:18901:18927  "MinFirstAllocationStrategy" */ linkersymbol("contracts/common/lib/MinFirstAllocationStrategy.sol:MinFirstAllocationStrategy"), /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, sub(tail_1, _20), _20, /** @src 6:955:47234  "library SRLib {..." */ 0)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    if iszero(_21)
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        let pos_1 := mload(64)
                        returndatacopy(pos_1, 0, returndatasize())
                        revert(pos_1, returndatasize())
                    }
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let expr_component_3 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    let expr_component_mpos := 0
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    if _21
                    {
                        let _22 := returndatasize()
                        returndatacopy(_20, /** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _22)
                        finalize_allocation(_20, _22)
                        let _23 := add(_20, _22)
                        /// @src 6:955:47234  "library SRLib {..."
                        if slt(sub(_23, _20), 64) { revert(0, 0) }
                        let value_1 := mload(_20)
                        let offset := mload(add(_20, 32))
                        if gt(offset, 0xffffffffffffffff) { revert(0, 0) }
                        let _24 := add(_20, offset)
                        if iszero(slt(add(_24, 0x1f), _23)) { revert(0, 0) }
                        let _25 := mload(_24)
                        let _26 := array_allocation_size_array_uint256_dyn(_25)
                        let memPtr_5 := mload(64)
                        finalize_allocation(memPtr_5, _26)
                        let dst := memPtr_5
                        mstore(memPtr_5, _25)
                        dst := add(memPtr_5, 32)
                        let srcEnd := add(add(_24, shl(5, _25)), 32)
                        if gt(srcEnd, _23) { revert(0, 0) }
                        let src := add(_24, 32)
                        for { } lt(src, srcEnd) { src := add(src, 32) }
                        {
                            mstore(dst, mload(src))
                            dst := add(dst, 32)
                        }
                        /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                        expr_component_3 := value_1
                        expr_component_mpos := memPtr_5
                    }
                    /// @src 6:18850:18979  "(totalAllocated, newAllocations) =..."
                    var_newAllocations_mpos := expr_component_mpos
                    /// @src 6:19086:19118  "totalAllocated *= initialDeposit"
                    var_totalAllocated := checked_mul_uint256(expr_component_3, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                    /// @src 6:19137:19150  "uint256 i = 0"
                    let var_i_3 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:19132:19387  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                    for { }
                    /** @src 6:19152:19168  "i < modulesCount" */ lt(var_i_3, length)
                    /// @src 6:19137:19150  "uint256 i = 0"
                    {
                        /// @src 6:19170:19173  "++i"
                        var_i_3 := /** @src 9:560:562  "32" */ add(/** @src 6:19170:19173  "++i" */ var_i_3, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                    }
                    /// @src 6:19170:19173  "++i"
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        let _27 := mload(/** @src 6:19269:19286  "newAllocations[i]" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3))
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(/** @src 6:19253:19319  "allocated[i] = (newAllocations[i] - allocated[i]) * initialDeposit" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_3), /** @src 6:19268:19319  "(newAllocations[i] - allocated[i]) * initialDeposit" */ checked_mul_uint256(/** @src 6:19269:19301  "newAllocations[i] - allocated[i]" */ checked_sub_uint256(_27, /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19289:19301  "allocated[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_3))), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                        mstore(/** @src 6:19337:19372  "newAllocations[i] *= initialDeposit" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3), checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19337:19372  "newAllocations[i] *= initialDeposit" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                    }
                }
            }
            /// @ast-id 1371 @src 6:17690:19718  "function _getDepositAllocations(Config calldata _cfg, uint256 _allocateAmount, bool _isTopUp)..."
            function fun_getDepositAllocations(var_allocateAmount, var_isTopUp) -> var_totalAllocated, var_allocated_mpos, var_newAllocations_mpos
            {
                /// @src 6:17829:17851  "uint256 totalAllocated"
                var_totalAllocated := /** @src 6:955:47234  "library SRLib {..." */ 0
                let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:17988:18082  "if (modulesCount == 0) {..."
                if /** @src 6:17992:18009  "modulesCount == 0" */ iszero(length)
                /// @src 6:17988:18082  "if (modulesCount == 0) {..."
                {
                    /// @src 6:955:47234  "library SRLib {..."
                    let memPtr := mload(64)
                    finalize_allocation_47073(memPtr)
                    mstore(memPtr, 0)
                    let memPtr_1 := mload(64)
                    finalize_allocation_47073(memPtr_1)
                    mstore(memPtr_1, 0)
                    calldatacopy(0, calldatasize(), 0)
                    /// @src 6:18025:18071  "return (0, new uint256[](0), new uint256[](0))"
                    var_totalAllocated := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:18025:18071  "return (0, new uint256[](0), new uint256[](0))"
                    var_allocated_mpos := memPtr
                    var_newAllocations_mpos := memPtr_1
                    leave
                }
                /// @src 6:18252:18284  "_allocateAmount / initialDeposit"
                let expr := checked_div_uint256(var_allocateAmount, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                let length_1 := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:23169:23211  "_allocations = new uint256[](modulesCount)"
                let var_allocations_mpos := /** @src 6:23184:23211  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length_1)
                /// @src 6:955:47234  "library SRLib {..."
                let _1 := array_allocation_size_array_uint256_dyn(length_1)
                let memPtr_2 := mload(64)
                finalize_allocation(memPtr_2, _1)
                mstore(memPtr_2, length_1)
                let _2 := add(array_allocation_size_array_uint256_dyn(length_1), /** @src 9:560:562  "32" */ not(31))
                /// @src 6:955:47234  "library SRLib {..."
                let i := 0
                for { } lt(i, _2) { i := add(i, 32) }
                {
                    let memPtr_3 := mload(64)
                    finalize_allocation_31499(memPtr_3)
                    mstore(memPtr_3, 0)
                    let _3 := 32
                    mstore(add(memPtr_3, _3), 0)
                    mstore(add(memPtr_3, 64), 0)
                    mstore(add(memPtr_3, 96), 0)
                    mstore(add(memPtr_3, 128), 0)
                    mstore(add(add(memPtr_2, i), _3), memPtr_3)
                }
                let memPtr_4 := mload(64)
                finalize_allocation_31435(memPtr_4)
                mstore(memPtr_4, 0)
                mstore(add(memPtr_4, 32), 0)
                mstore(add(memPtr_4, 64), 0)
                mstore(add(memPtr_4, 96), 0)
                mstore(add(memPtr_4, 128), 0)
                mstore(add(memPtr_4, 160), 0)
                mstore(add(memPtr_4, 192), 0)
                /// @src 6:23447:23491  "uint256 totalValidators = depositsToAllocate"
                let var_totalValidators := expr
                /// @src 6:23552:23565  "uint256 i = 0"
                let var_i := /** @src 6:955:47234  "library SRLib {..." */ 0
                /// @src 6:23547:24929  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:23567:23583  "i < modulesCount" */ lt(var_i, length_1)
                /// @src 6:23552:23565  "uint256 i = 0"
                {
                    /// @src 6:23585:23588  "++i"
                    var_i := /** @src 9:560:562  "32" */ add(/** @src 6:23585:23588  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                }
                /// @src 6:23585:23588  "++i"
                {
                    /// @src 4:5016:5034  "set._values[index]"
                    let _4, _5 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1), /** @src 4:5016:5034  "set._values[index]" */ var_i)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _6 := sload(/** @src 4:5016:5034  "set._values[index]" */ _4)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _7 := 3
                    /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                    let _8 := constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                    mstore(32, _8)
                    let dataSlot := keccak256(0, 64)
                    /// @src 6:23716:23748  "stateConfig = moduleState.config"
                    let var_stateConfig_mpos := /** @src 9:497:502  "10000" */ read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:23716:23748  "stateConfig = moduleState.config" */ dataSlot)
                    /// @src 9:497:502  "10000"
                    mstore(/** @src 6:23792:23811  "cache[i].shareLimit" */ add(/** @src 6:23792:23800  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 64), /** @src 9:497:502  "10000" */ and(mload(/** @src 6:23814:23841  "stateConfig.stakeShareLimit" */ add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 96)), /** @src 9:497:502  "10000" */ 0xffff))
                    let _9 := mload(/** @src 6:23873:23891  "stateConfig.status" */ add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 160))
                    /// @src 9:560:562  "32"
                    if iszero(lt(_9, /** @src 6:955:47234  "library SRLib {..." */ _7))
                    /// @src 9:560:562  "32"
                    {
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                        revert(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ 0x24)
                    }
                    /// @src 6:23855:23891  "cache[i].status = stateConfig.status"
                    write_to_memory_enum_StakingModuleStatus(/** @src 6:23855:23870  "cache[i].status" */ add(/** @src 6:23855:23863  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 96), /** @src 9:497:502  "10000" */ _9)
                    /// @src 6:23923:23960  "stateConfig.withdrawalCredentialsType"
                    let _10 := add(var_stateConfig_mpos, /** @src 6:955:47234  "library SRLib {..." */ 192)
                    /// @src 9:560:562  "32"
                    let _11 := 0xff
                    /// @src 9:497:502  "10000"
                    mstore(/** @src 6:23905:23920  "cache[i].wcType" */ add(/** @src 6:23905:23913  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 128), /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:23923:23960  "stateConfig.withdrawalCredentialsType" */ _10), /** @src 9:560:562  "32" */ _11))
                    /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                    let var__slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                    mstore(32, var__slot)
                    let _12 := sub(shl(160, 1), 1)
                    /// @src 6:24094:24148  "_getStakingModuleSummary(moduleId.getIStakingModule())"
                    let expr_component, expr_component_1, expr_component_2 := fun_getStakingModuleSummary(/** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(0, 64)), _12))
                    mstore(/** @src 6:24162:24170  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ expr_component_2)
                    /// @src 6:24375:24397  "moduleState.accounting"
                    let _13 := 2
                    /// @src 6:955:47234  "library SRLib {..."
                    let value := and(shr(64, sload(/** @src 6:24375:24397  "moduleState.accounting" */ add(dataSlot, _13))), /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                    /// @src 6:24274:24420  "uint256 validatorsCount = depositedValidatorsCount..."
                    let var_validatorsCount := /** @src 6:24300:24420  "depositedValidatorsCount..." */ checked_sub_uint256(expr_component_1, /** @src 2:3060:3102  "b ^ ((a ^ b) * SafeCast.toUint(condition))" */ xor(value, /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:3066:3071  "a ^ b" */ xor(expr_component, value), /** @src 2:3281:3286  "a > b" */ gt(expr_component, value))))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:24464:24484  "cache[i].activeCount" */ add(/** @src 6:24464:24472  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i)), /** @src 6:955:47234  "library SRLib {..." */ 32), var_validatorsCount)
                    /// @src 6:24517:24824  "if (WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)) {..."
                    if /** @src 14:1679:1699  "wcType == WC_TYPE_02" */ eq(/** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:24551:24588  "stateConfig.withdrawalCredentialsType" */ _10), /** @src 9:560:562  "32" */ _11), /** @src 6:24375:24397  "moduleState.accounting" */ _13)
                    /// @src 6:24517:24824  "if (WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)) {..."
                    {
                        /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                        let _14 := constant_ROUTER_STORAGE_POSITION()
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(0, /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_7, _5), _6))
                        mstore(32, _14)
                        let cleaned := and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(0, 64)), _12)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let _15 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        mstore(_15, /** @src 6:955:47234  "library SRLib {..." */ shl(226, 0x03214bd7))
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let _16 := staticcall(gas(), cleaned, _15, /** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ _15, /** @src 6:955:47234  "library SRLib {..." */ 32)
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        if iszero(_16)
                        {
                            /// @src 6:955:47234  "library SRLib {..."
                            let pos := mload(64)
                            returndatacopy(pos, 0, returndatasize())
                            revert(pos, returndatasize())
                        }
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        let expr_1 := /** @src 6:955:47234  "library SRLib {..." */ 0
                        /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                        if _16
                        {
                            let _17 := /** @src 6:955:47234  "library SRLib {..." */ 32
                            /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                            if gt(/** @src 6:955:47234  "library SRLib {..." */ 32, /** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ returndatasize()) { _17 := returndatasize() }
                            finalize_allocation(_15, _17)
                            /// @src 6:955:47234  "library SRLib {..."
                            if slt(sub(/** @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()" */ add(_15, _17), /** @src 6:955:47234  "library SRLib {..." */ _15), 32) { revert(0, 0) }
                            /// @src 6:24744:24796  "moduleId.getIStakingModuleV2().getTotalModuleStake()"
                            expr_1 := /** @src 6:955:47234  "library SRLib {..." */ mload(_15)
                        }
                        /// @src 2:4050:4200  "if (b == 0) {..."
                        if /** @src 2:4054:4060  "b == 0" */ iszero(/** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                        /// @src 2:4050:4200  "if (b == 0) {..."
                        {
                            /// @src 0:1829:1964  "assembly (\"memory-safe\") {..."
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 0:1829:1964  "assembly (\"memory-safe\") {..." */ 0x4e487b71)
                            mstore(/** @src 6:955:47234  "library SRLib {..." */ 32, /** @src 0:1035:1039  "0x12" */ 0x12)
                            /// @src 0:1829:1964  "assembly (\"memory-safe\") {..."
                            revert(0x1c, 0x24)
                        }
                        /// @src 6:24713:24809  "validatorsCount = Math.ceilDiv(moduleId.getIStakingModuleV2().getTotalModuleStake(), maxEBType1)"
                        var_validatorsCount := /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:4630:4635  "a > 0" */ iszero(iszero(expr_1)), /** @src 0:1035:1039  "0x12" */ add(/** @src 2:4640:4651  "(a - 1) / b" */ checked_div_uint256(/** @src 6:955:47234  "library SRLib {..." */ add(/** @src 2:4641:4646  "a - 1" */ expr_1, /** @src 9:560:562  "32" */ not(0)), calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                    }
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:24837:24870  "_allocations[i] = validatorsCount" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i), /** @src 6:955:47234  "library SRLib {..." */ var_validatorsCount)
                    /// @src 6:24884:24918  "totalValidators += validatorsCount"
                    var_totalValidators := checked_add_uint256(var_totalValidators, var_validatorsCount)
                }
                /// @src 6:24938:24979  "_capacities = new uint256[](modulesCount)"
                let var_capacities_mpos := /** @src 6:24952:24979  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length_1)
                /// @src 6:25086:25099  "uint256 i = 0"
                let var_i_1 := /** @src 6:955:47234  "library SRLib {..." */ 0
                /// @src 6:25081:26318  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:25101:25117  "i < modulesCount" */ lt(var_i_1, length_1)
                /// @src 6:25086:25099  "uint256 i = 0"
                {
                    /// @src 6:25119:25122  "++i"
                    var_i_1 := /** @src 9:560:562  "32" */ add(/** @src 6:25119:25122  "++i" */ var_i_1, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                }
                /// @src 6:25119:25122  "++i"
                {
                    /// @src 6:25198:25242  "uint256 validatorsCapacity = _allocations[i]"
                    let var_validatorsCapacity := /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25227:25242  "_allocations[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_1))
                    /// @src 9:497:502  "10000"
                    let _18 := mload(/** @src 6:25260:25275  "cache[i].status" */ add(/** @src 6:25260:25268  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 96))
                    /// @src 9:560:562  "32"
                    if iszero(lt(_18, /** @src 6:955:47234  "library SRLib {..." */ 3))
                    /// @src 9:560:562  "32"
                    {
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        mstore(/** @src 6:955:47234  "library SRLib {..." */ 4, /** @src 9:560:562  "32" */ 0x21)
                        revert(/** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 6:25055:25070  "_cfg.maxEBType2" */ 36)
                    }
                    /// @src 6:25256:26258  "if (cache[i].status == StakingModuleStatus.Active) {..."
                    if /** @src 6:25260:25305  "cache[i].status == StakingModuleStatus.Active" */ iszero(_18)
                    /// @src 6:25256:26258  "if (cache[i].status == StakingModuleStatus.Active) {..."
                    {
                        /// @src 6:25329:25387  "_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)"
                        let expr_2 := var_isTopUp
                        if var_isTopUp
                        {
                            expr_2 := /** @src 14:1679:1699  "wcType == WC_TYPE_02" */ eq(/** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(/** @src 6:25371:25386  "cache[i].wcType" */ add(/** @src 6:25371:25379  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 128)), /** @src 9:560:562  "32" */ 0xff), /** @src 6:24375:24397  "moduleState.accounting" */ 2)
                        }
                        /// @src 6:25325:25772  "if (_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)) {..."
                        switch expr_2
                        case 0 {
                            /// @src 6:955:47234  "library SRLib {..."
                            let _19 := mload(/** @src 6:25710:25725  "_allocations[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_1))
                            /// @src 6:25689:25753  "validatorsCapacity = _allocations[i] + cache[i].depositableCount"
                            var_validatorsCapacity := /** @src 6:25710:25753  "_allocations[i] + cache[i].depositableCount" */ checked_add_uint256(_19, /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25728:25736  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1))))
                        }
                        default /// @src 6:25325:25772  "if (_isTopUp && WithdrawalCredentials.isType2(cache[i].wcType)) {..."
                        {
                            /// @src 6:25575:25642  "validatorsCapacity = cache[i].activeCount * maxEBType2 / maxEBType1"
                            var_validatorsCapacity := /** @src 6:25596:25642  "cache[i].activeCount * maxEBType2 / maxEBType1" */ checked_div_uint256(/** @src 6:25596:25629  "cache[i].activeCount * maxEBType2" */ checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:25596:25616  "cache[i].activeCount" */ add(/** @src 6:25596:25604  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 32)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:25055:25070  "_cfg.maxEBType2" */ 36)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                        }
                        let r := div(/** @src 6:26004:26041  "cache[i].shareLimit * totalValidators" */ checked_mul_uint256(/** @src 9:497:502  "10000" */ and(mload(/** @src 6:26004:26023  "cache[i].shareLimit" */ add(/** @src 6:26004:26012  "cache[i]" */ mload(memory_array_index_access_uint256_dyn(memPtr_2, var_i_1)), /** @src 6:955:47234  "library SRLib {..." */ 64)), /** @src 9:497:502  "10000" */ 0xffff), /** @src 6:26004:26041  "cache[i].shareLimit * totalValidators" */ var_totalValidators), /** @src 9:497:502  "10000" */ 0x2710)
                        /// @src 6:26176:26243  "validatorsCapacity = Math.min(targetValidators, validatorsCapacity)"
                        var_validatorsCapacity := /** @src 2:3060:3102  "b ^ ((a ^ b) * SafeCast.toUint(condition))" */ xor(var_validatorsCapacity, /** @src 0:1035:1039  "0x12" */ mul(/** @src 2:3066:3071  "a ^ b" */ xor(r, var_validatorsCapacity), /** @src 2:3463:3468  "a < b" */ lt(r, var_validatorsCapacity)))
                    }
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 6:26272:26307  "_capacities[i] = validatorsCapacity" */ memory_array_index_access_uint256_dyn(var_capacities_mpos, var_i_1), /** @src 6:955:47234  "library SRLib {..." */ var_validatorsCapacity)
                }
                /// @src 6:18490:18584  "(allocated, capacities) = _getModulesAllocationAndCapacity(_cfg, depositsToAllocate, _isTopUp)"
                var_allocated_mpos := var_allocations_mpos
                /// @src 6:18655:19712  "if (depositsToAllocate > 0) {..."
                switch /** @src 6:18659:18681  "depositsToAllocate > 0" */ iszero(iszero(expr))
                case /** @src 6:18655:19712  "if (depositsToAllocate > 0) {..." */ 0 {
                    /// @src 6:19417:19461  "newAllocations = new uint256[](modulesCount)"
                    var_newAllocations_mpos := /** @src 6:19434:19461  "new uint256[](modulesCount)" */ allocate_and_zero_memory_array_array_uint256_dyn(length)
                    /// @src 6:19548:19561  "uint256 i = 0"
                    let var_i_2 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:19543:19702  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                    for { }
                    /** @src 6:19563:19579  "i < modulesCount" */ lt(var_i_2, length)
                    /// @src 6:19548:19561  "uint256 i = 0"
                    {
                        /// @src 6:19581:19584  "++i"
                        var_i_2 := /** @src 9:560:562  "32" */ add(/** @src 6:19581:19584  "++i" */ var_i_2, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                    }
                    /// @src 6:19581:19584  "++i"
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(/** @src 6:19604:19653  "newAllocations[i] = allocated[i] * initialDeposit" */ memory_array_index_access_uint256_dyn(var_newAllocations_mpos, var_i_2), /** @src 6:19624:19653  "allocated[i] * initialDeposit" */ checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19624:19636  "allocated[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_2)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                        mstore(/** @src 6:19671:19687  "allocated[i] = 0" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_2), /** @src 6:955:47234  "library SRLib {..." */ 0)
                    }
                }
                default /// @src 6:18655:19712  "if (depositsToAllocate > 0) {..."
                {
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let _20 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    mstore(_20, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x2529fbc9))
                    mstore(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ add(_20, /** @src 6:955:47234  "library SRLib {..." */ 4), 96)
                    let tail := abi_encode_array_uint256_dyn(var_allocations_mpos, add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:955:47234  "library SRLib {..." */ 100))
                    mstore(add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:25055:25070  "_cfg.maxEBType2" */ 36), /** @src 6:955:47234  "library SRLib {..." */ add(sub(tail, /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20), /** @src 6:955:47234  "library SRLib {..." */ not(3)))
                    let tail_1 := abi_encode_array_uint256_dyn(var_capacities_mpos, tail)
                    mstore(add(/** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, /** @src 6:955:47234  "library SRLib {..." */ 68), expr)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let _21 := delegatecall(gas(), /** @src 6:18901:18927  "MinFirstAllocationStrategy" */ linkersymbol("contracts/common/lib/MinFirstAllocationStrategy.sol:MinFirstAllocationStrategy"), /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _20, sub(tail_1, _20), _20, /** @src 6:955:47234  "library SRLib {..." */ 0)
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    if iszero(_21)
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        let pos_1 := mload(64)
                        returndatacopy(pos_1, 0, returndatasize())
                        revert(pos_1, returndatasize())
                    }
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    let expr_component_3 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    let expr_component_mpos := 0
                    /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                    if _21
                    {
                        let _22 := returndatasize()
                        returndatacopy(_20, /** @src 6:955:47234  "library SRLib {..." */ 0, /** @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)" */ _22)
                        finalize_allocation(_20, _22)
                        let _23 := add(_20, _22)
                        /// @src 6:955:47234  "library SRLib {..."
                        if slt(sub(_23, _20), 64) { revert(0, 0) }
                        let value_1 := mload(_20)
                        let offset := mload(add(_20, 32))
                        if gt(offset, 0xffffffffffffffff) { revert(0, 0) }
                        let _24 := add(_20, offset)
                        if iszero(slt(add(_24, 0x1f), _23)) { revert(0, 0) }
                        let _25 := mload(_24)
                        let _26 := array_allocation_size_array_uint256_dyn(_25)
                        let memPtr_5 := mload(64)
                        finalize_allocation(memPtr_5, _26)
                        let dst := memPtr_5
                        mstore(memPtr_5, _25)
                        dst := add(memPtr_5, 32)
                        let srcEnd := add(add(_24, shl(5, _25)), 32)
                        if gt(srcEnd, _23) { revert(0, 0) }
                        let src := add(_24, 32)
                        for { } lt(src, srcEnd) { src := add(src, 32) }
                        {
                            mstore(dst, mload(src))
                            dst := add(dst, 32)
                        }
                        /// @src 6:18901:18979  "MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)"
                        expr_component_3 := value_1
                        expr_component_mpos := memPtr_5
                    }
                    /// @src 6:18850:18979  "(totalAllocated, newAllocations) =..."
                    var_newAllocations_mpos := expr_component_mpos
                    /// @src 6:19086:19118  "totalAllocated *= initialDeposit"
                    var_totalAllocated := checked_mul_uint256(expr_component_3, /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4))
                    /// @src 6:19137:19150  "uint256 i = 0"
                    let var_i_3 := /** @src 6:955:47234  "library SRLib {..." */ 0
                    /// @src 6:19132:19387  "for (uint256 i = 0; i < modulesCount; ++i) {..."
                    for { }
                    /** @src 6:19152:19168  "i < modulesCount" */ lt(var_i_3, length)
                    /// @src 6:19137:19150  "uint256 i = 0"
                    {
                        /// @src 6:19170:19173  "++i"
                        var_i_3 := /** @src 9:560:562  "32" */ add(/** @src 6:19170:19173  "++i" */ var_i_3, /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                    }
                    /// @src 6:19170:19173  "++i"
                    {
                        /// @src 6:955:47234  "library SRLib {..."
                        let _27 := mload(/** @src 6:19269:19286  "newAllocations[i]" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3))
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(/** @src 6:19253:19319  "allocated[i] = (newAllocations[i] - allocated[i]) * initialDeposit" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_3), /** @src 6:19268:19319  "(newAllocations[i] - allocated[i]) * initialDeposit" */ checked_mul_uint256(/** @src 6:19269:19301  "newAllocations[i] - allocated[i]" */ checked_sub_uint256(_27, /** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19289:19301  "allocated[i]" */ memory_array_index_access_uint256_dyn(var_allocations_mpos, var_i_3))), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                        mstore(/** @src 6:19337:19372  "newAllocations[i] *= initialDeposit" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3), checked_mul_uint256(/** @src 6:955:47234  "library SRLib {..." */ mload(/** @src 6:19337:19372  "newAllocations[i] *= initialDeposit" */ memory_array_index_access_uint256_dyn(expr_component_mpos, var_i_3)), /** @src 9:560:562  "32" */ calldataload(/** @src 6:955:47234  "library SRLib {..." */ 4)))
                    }
                }
            }
            function abi_encode_bytes(headStart, value0) -> tail
            {
                let _1 := 32
                mstore(headStart, 32)
                let length := mload(value0)
                mstore(add(headStart, 32), length)
                let i := 0
                for { } lt(i, length) { i := add(i, _1) }
                {
                    mstore(add(add(headStart, i), 64), mload(add(add(value0, i), _1)))
                }
                mstore(add(add(headStart, length), 64), 0)
                tail := add(add(headStart, and(add(length, 31), /** @src 9:560:562  "32" */ not(31))), /** @src 6:955:47234  "library SRLib {..." */ 64)
            }
            function abi_encode_bytes_calldata_bytes_calldata(headStart, value0, value1, value2, value3) -> tail
            {
                mstore(headStart, 64)
                let tail_1 := abi_encode_bytes_calldata(value0, value1, add(headStart, 64))
                mstore(add(headStart, 32), sub(tail_1, headStart))
                tail := abi_encode_bytes_calldata(value2, value3, tail_1)
            }
            function checked_add_uint256(x, y) -> sum
            {
                sum := add(x, y)
                if gt(x, sum)
                {
                    /// @src 9:560:562  "32"
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @src 9:497:502  "10000"
            function write_to_memory_enum_StakingModuleStatus(memPtr, value)
            {
                /// @src 9:560:562  "32"
                if iszero(lt(value, 3))
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    mstore(4, 0x21)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x24)
                }
                /// @src 9:497:502  "10000"
                mstore(memPtr, value)
            }
            function read_from_storage_reference_type_struct_ModuleStateConfig(slot) -> value
            {
                /// @src 6:955:47234  "library SRLib {..."
                let memPtr := mload(64)
                finalize_allocation_31435(memPtr)
                /// @src 9:497:502  "10000"
                value := memPtr
                /// @src 9:560:562  "32"
                let _1 := sload(/** @src 9:497:502  "10000" */ slot)
                mstore(memPtr, /** @src 6:955:47234  "library SRLib {..." */ and(_1, sub(shl(160, 1), 1)))
                /// @src 9:497:502  "10000"
                let _2 := 0xffff
                mstore(add(memPtr, 32), and(shr(160, _1), _2))
                mstore(add(memPtr, /** @src 6:955:47234  "library SRLib {..." */ 64), /** @src 9:497:502  "10000" */ and(shr(176, _1), _2))
                mstore(add(memPtr, 96), and(shr(192, _1), _2))
                mstore(add(memPtr, 128), and(shr(208, _1), _2))
                write_to_memory_enum_StakingModuleStatus(add(memPtr, 160), /** @src 9:560:562  "32" */ and(/** @src 6:955:47234  "library SRLib {..." */ shr(/** @src 9:497:502  "10000" */ 224, /** @src 6:955:47234  "library SRLib {..." */ _1), /** @src 9:560:562  "32" */ 0xff))
                /// @src 9:497:502  "10000"
                mstore(add(memPtr, 192), /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ shr(232, _1), /** @src 9:560:562  "32" */ 0xff))
            }
            /// @src 9:497:502  "10000"
            function update_storage_value_offsett_uint64_to_uint64(slot, value)
            {
                let _1 := sload(slot)
                sstore(slot, or(and(_1, not(0xffffffffffffffff0000000000000000)), and(shl(64, value), 0xffffffffffffffff0000000000000000)))
            }
            function abi_encode_uint256_uint256_address(headStart, value0, value1, value2) -> tail
            {
                tail := add(headStart, 96)
                /// @src 6:955:47234  "library SRLib {..."
                mstore(headStart, value0)
                mstore(/** @src 9:497:502  "10000" */ add(headStart, 32), /** @src 6:955:47234  "library SRLib {..." */ value1)
                /// @src 9:560:562  "32"
                mstore(/** @src 9:497:502  "10000" */ add(headStart, 64), /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ value2, /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1)))
            }
            /// @src 9:497:502  "10000"
            function abi_encode_uint256_address(headStart, value0, value1) -> tail
            {
                tail := add(headStart, 64)
                /// @src 6:955:47234  "library SRLib {..."
                mstore(headStart, value0)
                /// @src 9:560:562  "32"
                mstore(/** @src 9:497:502  "10000" */ add(headStart, 32), /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ value1, /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1)))
            }
            /// @ast-id 842 @src 6:10630:12841  "function _updateModuleParams(..."
            function fun_updateModuleParams(var_moduleId, var__stakeShareLimit, var__priorityExitShareThreshold, var_moduleFee, var_treasuryFee, var_maxDepositsPerBlock, var_minDepositBlockDistance)
            {
                /// @src 6:10965:10992  "_priorityExitShareThreshold"
                fun_validateShareParams(var__stakeShareLimit, var__priorityExitShareThreshold)
                /// @src 6:11003:11093  "if (_moduleFee + _treasuryFee > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                if /** @src 6:11007:11061  "_moduleFee + _treasuryFee > SRUtils.TOTAL_BASIS_POINTS" */ gt(/** @src 6:11007:11032  "_moduleFee + _treasuryFee" */ checked_add_uint256(var_moduleFee, var_treasuryFee), /** @src 9:497:502  "10000" */ 0x2710)
                /// @src 6:11003:11093  "if (_moduleFee + _treasuryFee > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                {
                    /// @src 6:11070:11093  "ISRBase.InvalidFeeSum()"
                    let _1 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:11070:11093  "ISRBase.InvalidFeeSum()"
                    mstore(_1, shl(224, 0xb65e4c59))
                    revert(_1, 4)
                }
                /// @src 6:12983:13008  "_moduleFee + _treasuryFee"
                let expr := checked_add_uint256(var_moduleFee, var_treasuryFee)
                /// @src 7:1957:1983  "getRouterState().moduleIds"
                let _2 := 1
                /// @src 6:955:47234  "library SRLib {..."
                let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:13084:13093  "uint256 i"
                let var_i := /** @src -1:-1:-1 */ 0
                /// @src 6:13079:13485  "for (uint256 i; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:13095:13111  "i < modulesCount" */ lt(var_i, length)
                /// @src 6:13084:13093  "uint256 i"
                {
                    /// @src 6:13113:13116  "++i"
                    var_i := /** @src 9:560:562  "32" */ add(/** @src 6:13113:13116  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _2)
                }
                /// @src 6:13113:13116  "++i"
                {
                    /// @src 4:5016:5034  "set._values[index]"
                    let _3, _4 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _2), /** @src 4:5016:5034  "set._values[index]" */ var_i)
                    /// @src 6:955:47234  "library SRLib {..."
                    let value := /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(3, _4), sload(/** @src 4:5016:5034  "set._values[index]" */ _3))
                    /// @src 6:13191:13226  "if (moduleId == _moduleId) continue"
                    if /** @src 6:13195:13216  "moduleId == _moduleId" */ eq(value, var_moduleId)
                    /// @src 6:13191:13226  "if (moduleId == _moduleId) continue"
                    {
                        /// @src 6:13218:13226  "continue"
                        continue
                    }
                    /// @src 7:874:897  "ROUTER_STORAGE_POSITION"
                    let _5 := constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ value)
                    let _6 := 0x20
                    mstore(_6, _5)
                    let _7 := 0x40
                    /// @src 9:497:502  "10000"
                    let converted := read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _7))
                    /// @src 9:497:502  "10000"
                    let _8 := 0xffff
                    let cleaned := and(mload(/** @src 6:13338:13359  "stateConfig.moduleFee" */ add(converted, /** @src 6:955:47234  "library SRLib {..." */ _6)), /** @src 9:497:502  "10000" */ _8)
                    /// @src 6:13326:13475  "if (uint256(stateConfig.moduleFee) + uint256(stateConfig.treasuryFee) != feeSum) {..."
                    if /** @src 6:13330:13405  "uint256(stateConfig.moduleFee) + uint256(stateConfig.treasuryFee) != feeSum" */ iszero(eq(/** @src 6:13330:13395  "uint256(stateConfig.moduleFee) + uint256(stateConfig.treasuryFee)" */ checked_add_uint256(cleaned, /** @src 9:497:502  "10000" */ and(mload(/** @src 6:13371:13394  "stateConfig.treasuryFee" */ add(converted, /** @src 6:955:47234  "library SRLib {..." */ _7)), /** @src 9:497:502  "10000" */ _8)), /** @src 6:13330:13405  "uint256(stateConfig.moduleFee) + uint256(stateConfig.treasuryFee) != feeSum" */ expr))
                    /// @src 6:13326:13475  "if (uint256(stateConfig.moduleFee) + uint256(stateConfig.treasuryFee) != feeSum) {..."
                    {
                        /// @src 6:13432:13460  "ISRBase.InconsistentFeeSum()"
                        let _9 := /** @src 6:955:47234  "library SRLib {..." */ mload(_7)
                        /// @src 6:13432:13460  "ISRBase.InconsistentFeeSum()"
                        mstore(_9, shl(224, 0xf15cd7e5))
                        revert(_9, 4)
                    }
                }
                /// @src 6:11178:11254  "_minDepositBlockDistance == 0 || _minDepositBlockDistance > type(uint64).max"
                let expr_1 := /** @src 6:11178:11207  "_minDepositBlockDistance == 0" */ iszero(var_minDepositBlockDistance)
                /// @src 6:11178:11254  "_minDepositBlockDistance == 0 || _minDepositBlockDistance > type(uint64).max"
                if iszero(expr_1)
                {
                    expr_1 := /** @src 6:11211:11254  "_minDepositBlockDistance > type(uint64).max" */ gt(var_minDepositBlockDistance, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                }
                /// @src 6:11174:11328  "if (_minDepositBlockDistance == 0 || _minDepositBlockDistance > type(uint64).max) {..."
                if expr_1
                {
                    /// @src 6:11277:11317  "ISRBase.InvalidMinDepositBlockDistance()"
                    let _10 := /** @src 6:955:47234  "library SRLib {..." */ mload(0x40)
                    /// @src 6:11277:11317  "ISRBase.InvalidMinDepositBlockDistance()"
                    mstore(_10, shl(227, 0x09e77275))
                    revert(_10, 4)
                }
                /// @src 6:11341:11409  "_maxDepositsPerBlock == 0 || _maxDepositsPerBlock > type(uint64).max"
                let expr_2 := /** @src 6:11341:11366  "_maxDepositsPerBlock == 0" */ iszero(var_maxDepositsPerBlock)
                /// @src 6:11341:11409  "_maxDepositsPerBlock == 0 || _maxDepositsPerBlock > type(uint64).max"
                if iszero(expr_2)
                {
                    expr_2 := /** @src 6:11370:11409  "_maxDepositsPerBlock > type(uint64).max" */ gt(var_maxDepositsPerBlock, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
                }
                /// @src 6:11337:11483  "if (_maxDepositsPerBlock == 0 || _maxDepositsPerBlock > type(uint64).max) {..."
                if expr_2
                {
                    /// @src 6:11432:11472  "ISRBase.InvalidMaxDepositPerBlockValue()"
                    let _11 := /** @src 6:955:47234  "library SRLib {..." */ mload(0x40)
                    /// @src 6:11432:11472  "ISRBase.InvalidMaxDepositPerBlockValue()"
                    mstore(_11, shl(224, 0xe747a27f))
                    revert(_11, 4)
                }
                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                let var_slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_moduleId)
                let _12 := 0x20
                mstore(_12, var_slot)
                let _13 := 0x40
                /// @src 9:497:502  "10000"
                let converted_1 := read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _13))
                /// @src 9:497:502  "10000"
                let _14 := 0xffff
                /// @src 6:11648:11669  "stateConfig.moduleFee"
                let _15 := add(converted_1, /** @src 6:955:47234  "library SRLib {..." */ _12)
                /// @src 9:497:502  "10000"
                mstore(_15, and(/** @src 6:11672:11690  "uint16(_moduleFee)" */ var_moduleFee, /** @src 9:497:502  "10000" */ _14))
                /// @src 6:11700:11723  "stateConfig.treasuryFee"
                let _16 := add(converted_1, /** @src 6:955:47234  "library SRLib {..." */ _13)
                /// @src 9:497:502  "10000"
                mstore(_16, and(/** @src 6:11726:11746  "uint16(_treasuryFee)" */ var_treasuryFee, /** @src 9:497:502  "10000" */ _14))
                /// @src 6:11756:11783  "stateConfig.stakeShareLimit"
                let _17 := add(converted_1, 96)
                /// @src 9:497:502  "10000"
                mstore(_17, and(/** @src 6:11786:11810  "uint16(_stakeShareLimit)" */ var__stakeShareLimit, /** @src 9:497:502  "10000" */ _14))
                /// @src 6:11820:11858  "stateConfig.priorityExitShareThreshold"
                let _18 := add(converted_1, 128)
                /// @src 9:497:502  "10000"
                mstore(_18, and(/** @src 6:11861:11896  "uint16(_priorityExitShareThreshold)" */ var__priorityExitShareThreshold, /** @src 9:497:502  "10000" */ _14))
                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                let var_slot_1 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_moduleId)
                mstore(_12, var_slot_1)
                let dataSlot := keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _13)
                let _19 := and(/** @src 9:497:502  "10000" */ mload(converted_1), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                /// @src 9:560:562  "32"
                let _20 := sload(dataSlot)
                /// @src 9:497:502  "10000"
                let _21 := mload(_15)
                let toInsert := and(shl(176, mload(_16)), shl(176, 65535))
                let _22 := mload(_17)
                sstore(dataSlot, or(or(and(shl(192, _22), shl(192, 65535)), or(toInsert, or(and(shl(160, _21), shl(160, 65535)), or(and(/** @src 9:560:562  "32" */ _20, /** @src 9:497:502  "10000" */ shl(224, 0xffffffff)), _19)))), and(shl(208, mload(_18)), shl(208, 65535))))
                let _23 := mload(add(converted_1, 160))
                /// @src 9:560:562  "32"
                if iszero(lt(_23, /** @src 6:955:47234  "library SRLib {..." */ 3))
                /// @src 9:560:562  "32"
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    mstore(4, 0x21)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x24)
                }
                /// @src 9:497:502  "10000"
                update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(dataSlot, _23)
                update_storage_value_offsett_uint8_to_uint8(dataSlot, /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(add(converted_1, 192)), /** @src 9:560:562  "32" */ 0xff))
                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                let var_slot_2 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_moduleId)
                mstore(_12, var_slot_2)
                /// @src 6:12046:12081  "_moduleId.getModuleState().deposits"
                let _24 := add(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _13), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                /// @src 6:955:47234  "library SRLib {..."
                let memPtr := mload(_13)
                finalize_allocation_31436(memPtr)
                /// @src 9:497:502  "10000"
                let _25 := sload(_24)
                /// @src 6:955:47234  "library SRLib {..."
                let _26 := 0xffffffffffffffff
                /// @src 9:497:502  "10000"
                mstore(memPtr, /** @src 6:955:47234  "library SRLib {..." */ and(_25, _26))
                /// @src 9:497:502  "10000"
                let _27 := add(memPtr, /** @src 6:955:47234  "library SRLib {..." */ _12)
                /// @src 9:497:502  "10000"
                mstore(_27, /** @src 6:955:47234  "library SRLib {..." */ and(shr(_13, _25), _26))
                /// @src 9:497:502  "10000"
                let _28 := add(memPtr, /** @src 6:955:47234  "library SRLib {..." */ _13)
                /// @src 9:497:502  "10000"
                mstore(_28, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:497:502  "10000" */ shr(/** @src 6:11820:11858  "stateConfig.priorityExitShareThreshold" */ 128, /** @src 9:497:502  "10000" */ _25), /** @src 6:955:47234  "library SRLib {..." */ _26))
                /// @src 9:497:502  "10000"
                let _29 := add(memPtr, /** @src 6:11756:11783  "stateConfig.stakeShareLimit" */ 96)
                /// @src 9:497:502  "10000"
                mstore(_29, shr(192, _25))
                mstore(_28, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:12127:12166  "SafeCast.toUint64(_maxDepositsPerBlock)" */ fun_toUint64(var_maxDepositsPerBlock), /** @src 6:955:47234  "library SRLib {..." */ _26))
                /// @src 9:497:502  "10000"
                mstore(_29, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:12216:12259  "SafeCast.toUint64(_minDepositBlockDistance)" */ fun_toUint64(var_minDepositBlockDistance), /** @src 6:955:47234  "library SRLib {..." */ _26))
                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                let var__slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_moduleId)
                mstore(_12, var__slot)
                /// @src 6:12341:12376  "_moduleId.getModuleState().deposits"
                let _30 := add(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _13), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1)
                /// @src 9:497:502  "10000"
                sstore(_30, or(and(sload(_30), not(/** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)), and(/** @src 9:497:502  "10000" */ mload(memPtr), /** @src 6:955:47234  "library SRLib {..." */ _26)))
                /// @src 9:497:502  "10000"
                update_storage_value_offsett_uint64_to_uint64(_30, /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:497:502  "10000" */ mload(_27), /** @src 6:955:47234  "library SRLib {..." */ _26))
                /// @src 9:497:502  "10000"
                let _31 := mload(_28)
                let _32 := sload(_30)
                sstore(_30, or(or(and(_32, 0xffffffffffffffffffffffffffffffff), and(shl(/** @src 6:11820:11858  "stateConfig.priorityExitShareThreshold" */ 128, /** @src 6:955:47234  "library SRLib {..." */ _31), /** @src 9:497:502  "10000" */ shl(128, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff))), /** @src 9:497:502  "10000" */ and(shl(192, mload(_29)), shl(192, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff))))
                /// @src 6:12444:12543  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, setBy)"
                let _33 := /** @src 6:955:47234  "library SRLib {..." */ mload(_13)
                /// @src 6:12444:12543  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, setBy)"
                log2(_33, sub(abi_encode_uint256_uint256_address(_33, var__stakeShareLimit, var__priorityExitShareThreshold, /** @src 6:12419:12429  "msg.sender" */ caller()), /** @src 6:12444:12543  "ISRBase.StakingModuleShareLimitSet(_moduleId, _stakeShareLimit, _priorityExitShareThreshold, setBy)" */ _33), 0x1730859048adcce16559e75a58fd609e9dbf7d34f39bcb7a45ad388dfbba0e4e, var_moduleId)
                /// @src 6:12558:12630  "ISRBase.StakingModuleFeesSet(_moduleId, _moduleFee, _treasuryFee, setBy)"
                let _34 := /** @src 6:955:47234  "library SRLib {..." */ mload(_13)
                /// @src 6:12558:12630  "ISRBase.StakingModuleFeesSet(_moduleId, _moduleFee, _treasuryFee, setBy)"
                log2(_34, sub(abi_encode_uint256_uint256_address(_34, var_moduleFee, var_treasuryFee, /** @src 6:12419:12429  "msg.sender" */ caller()), /** @src 6:12558:12630  "ISRBase.StakingModuleFeesSet(_moduleId, _moduleFee, _treasuryFee, setBy)" */ _34), 0x303c8ac43d1b1f9b898ddd2915a294efa01e9b07c322d7deeb7db332b66f0410, var_moduleId)
                /// @src 6:12645:12728  "ISRBase.StakingModuleMaxDepositsPerBlockSet(_moduleId, _maxDepositsPerBlock, setBy)"
                let _35 := /** @src 6:955:47234  "library SRLib {..." */ mload(_13)
                /// @src 6:12645:12728  "ISRBase.StakingModuleMaxDepositsPerBlockSet(_moduleId, _maxDepositsPerBlock, setBy)"
                log2(_35, sub(abi_encode_uint256_address(_35, var_maxDepositsPerBlock, /** @src 6:12419:12429  "msg.sender" */ caller()), /** @src 6:12645:12728  "ISRBase.StakingModuleMaxDepositsPerBlockSet(_moduleId, _maxDepositsPerBlock, setBy)" */ _35), 0x72766c50f14fe492bd1281ceef0a57ad49a02b7e1042fb58723647bf38040f83, var_moduleId)
                /// @src 6:12743:12834  "ISRBase.StakingModuleMinDepositBlockDistanceSet(_moduleId, _minDepositBlockDistance, setBy)"
                let _36 := /** @src 6:955:47234  "library SRLib {..." */ mload(_13)
                /// @src 6:12743:12834  "ISRBase.StakingModuleMinDepositBlockDistanceSet(_moduleId, _minDepositBlockDistance, setBy)"
                log2(_36, sub(abi_encode_uint256_address(_36, var_minDepositBlockDistance, /** @src 6:12419:12429  "msg.sender" */ caller()), /** @src 6:12743:12834  "ISRBase.StakingModuleMinDepositBlockDistanceSet(_moduleId, _minDepositBlockDistance, setBy)" */ _36), 0x4d106b4a7aff347abccca2dd6855d8d59d6cf792f1fdbb272c9858433d94b328, var_moduleId)
            }
            /// @src 6:955:47234  "library SRLib {..."
            function calldata_array_index_access_uint256_dyn_calldata(base_ref, length, index) -> addr
            {
                if iszero(lt(index, length))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                addr := add(base_ref, shl(5, index))
            }
            function checked_add_uint64(x, y) -> sum
            {
                let _1 := 0xffffffffffffffff
                sum := add(and(x, _1), and(y, _1))
                if gt(sum, _1)
                {
                    /// @src 9:560:562  "32"
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @src 6:955:47234  "library SRLib {..."
            function abi_encode_uint64_uint256(headStart, value0, value1) -> tail
            {
                tail := add(headStart, 64)
                mstore(headStart, and(value0, 0xffffffffffffffff))
                mstore(add(headStart, 32), value1)
            }
            /// @ast-id 2396 @src 6:43856:44525  "function _validateReportValidatorBalancesByStakingModule(..."
            function fun_validateReportValidatorBalancesByStakingModule(var_stakingModuleIds_offset, var_stakingModuleIds_length, var_validatorBalancesGwei_offset, var_validatorBalancesGwei_length)
            {
                /// @src 7:1957:1983  "getRouterState().moduleIds"
                let _1 := 1
                /// @src 6:955:47234  "library SRLib {..."
                let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:44092:44121  "_stakingModuleIds.length != n"
                let _2 := eq(var_stakingModuleIds_length, length)
                /// @src 6:44092:44159  "_stakingModuleIds.length != n || _validatorBalancesGwei.length != n"
                let expr := /** @src 6:44092:44121  "_stakingModuleIds.length != n" */ iszero(_2)
                /// @src 6:44092:44159  "_stakingModuleIds.length != n || _validatorBalancesGwei.length != n"
                if _2
                {
                    expr := /** @src 6:44125:44159  "_validatorBalancesGwei.length != n" */ iszero(eq(/** @src 6:44125:44154  "_validatorBalancesGwei.length" */ var_validatorBalancesGwei_length, /** @src 6:44125:44159  "_validatorBalancesGwei.length != n" */ length))
                }
                /// @src 6:44088:44223  "if (_stakingModuleIds.length != n || _validatorBalancesGwei.length != n) {..."
                if expr
                {
                    /// @src 6:44182:44212  "ISRBase.ArraysLengthMismatch()"
                    let _3 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:44182:44212  "ISRBase.ArraysLengthMismatch()"
                    mstore(_3, /** @src 6:30625:30655  "ISRBase.ArraysLengthMismatch()" */ shl(229, 0x07e11acb))
                    /// @src 6:44182:44212  "ISRBase.ArraysLengthMismatch()"
                    revert(_3, 4)
                }
                /// @src 6:44238:44251  "uint256 i = 0"
                let var_i := /** @src -1:-1:-1 */ 0
                /// @src 6:44233:44519  "for (uint256 i = 0; i < n; ++i) {..."
                for { }
                /** @src 6:44253:44258  "i < n" */ lt(var_i, length)
                /// @src 6:44238:44251  "uint256 i = 0"
                {
                    /// @src 6:44260:44263  "++i"
                    var_i := /** @src 9:560:562  "32" */ add(/** @src 6:44260:44263  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _1)
                }
                /// @src 6:44260:44263  "++i"
                {
                    /// @src 4:5016:5034  "set._values[index]"
                    let _4, _5 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _1), /** @src 4:5016:5034  "set._values[index]" */ var_i)
                    /// @src 6:955:47234  "library SRLib {..."
                    let value := /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(3, _5), sload(/** @src 4:5016:5034  "set._values[index]" */ _4))
                    /// @src 6:44338:44441  "if (moduleId != _stakingModuleIds[i]) revert ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])"
                    if /** @src 6:44342:44374  "moduleId != _stakingModuleIds[i]" */ iszero(eq(value, /** @src 9:560:562  "32" */ calldataload(/** @src 6:44354:44374  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_stakingModuleIds_offset, var_stakingModuleIds_length, var_i))))
                    /// @src 6:44338:44441  "if (moduleId != _stakingModuleIds[i]) revert ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])"
                    {
                        /// @src 9:560:562  "32"
                        let value_1 := calldataload(/** @src 6:44420:44440  "_stakingModuleIds[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_stakingModuleIds_offset, var_stakingModuleIds_length, var_i))
                        /// @src 6:44383:44441  "ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])"
                        let _6 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:44383:44441  "ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])"
                        mstore(_6, shl(226, 0x1d8b79ed))
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(/** @src 6:44383:44441  "ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])" */ add(_6, 4), /** @src 6:955:47234  "library SRLib {..." */ value)
                        mstore(add(/** @src 6:44383:44441  "ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])" */ _6, /** @src 6:955:47234  "library SRLib {..." */ 36), value_1)
                        /// @src 6:44383:44441  "ISRBase.UnexpectedModuleId(moduleId, _stakingModuleIds[i])"
                        revert(_6, /** @src 6:955:47234  "library SRLib {..." */ 68)
                    }
                    /// @src 6:44456:44508  "SRUtils._ensureAmountGwei(_validatorBalancesGwei[i])"
                    pop(fun_ensureAmountGwei(/** @src 9:560:562  "32" */ calldataload(/** @src 6:44482:44507  "_validatorBalancesGwei[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_validatorBalancesGwei_offset, var_validatorBalancesGwei_length, var_i))))
                }
            }
            /// @ast-id 1088 @src 6:13497:14967  "function _updateAllModuleFees(uint256[] calldata _moduleFees, uint256[] calldata _treasuryFees) public {..."
            function fun_updateAllModuleFees(var_moduleFees_offset, var_moduleFees_length, var_treasuryFees_offset, var_treasuryFees_length)
            {
                /// @src 7:1957:1983  "getRouterState().moduleIds"
                let _1 := 1
                /// @src 6:955:47234  "library SRLib {..."
                let length := sload(/** @src 7:1957:1983  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1))
                /// @src 6:13674:13708  "_moduleFees.length != modulesCount"
                let _2 := eq(var_moduleFees_length, length)
                /// @src 6:13674:13748  "_moduleFees.length != modulesCount || _treasuryFees.length != modulesCount"
                let expr := /** @src 6:13674:13708  "_moduleFees.length != modulesCount" */ iszero(_2)
                /// @src 6:13674:13748  "_moduleFees.length != modulesCount || _treasuryFees.length != modulesCount"
                if _2
                {
                    expr := /** @src 6:13712:13748  "_treasuryFees.length != modulesCount" */ iszero(eq(/** @src 6:13712:13732  "_treasuryFees.length" */ var_treasuryFees_length, /** @src 6:13712:13748  "_treasuryFees.length != modulesCount" */ length))
                }
                /// @src 6:13670:13812  "if (_moduleFees.length != modulesCount || _treasuryFees.length != modulesCount) {..."
                if expr
                {
                    /// @src 6:13771:13801  "ISRBase.ArraysLengthMismatch()"
                    let _3 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:13771:13801  "ISRBase.ArraysLengthMismatch()"
                    mstore(_3, /** @src 6:30625:30655  "ISRBase.ArraysLengthMismatch()" */ shl(229, 0x07e11acb))
                    /// @src 6:13771:13801  "ISRBase.ArraysLengthMismatch()"
                    revert(_3, 4)
                }
                /// @src 6:13821:13875  "if (modulesCount == 0) {..."
                if /** @src 6:13825:13842  "modulesCount == 0" */ iszero(length)
                /// @src 6:13821:13875  "if (modulesCount == 0) {..."
                {
                    /// @src 6:13858:13865  "return;"
                    leave
                }
                /// @src 6:955:47234  "library SRLib {..."
                if iszero(var_moduleFees_length)
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x32)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x24)
                }
                if iszero(var_treasuryFees_length)
                {
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x32)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x24)
                }
                /// @src 6:13910:13943  "_moduleFees[0] + _treasuryFees[0]"
                let expr_1 := checked_add_uint256(/** @src 9:560:562  "32" */ calldataload(var_moduleFees_offset), calldataload(var_treasuryFees_offset))
                /// @src 9:497:502  "10000"
                let _4 := 0x2710
                /// @src 6:13953:14032  "if (expectedFeeSum > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                if /** @src 6:13957:14000  "expectedFeeSum > SRUtils.TOTAL_BASIS_POINTS" */ gt(expr_1, /** @src 9:497:502  "10000" */ _4)
                /// @src 6:13953:14032  "if (expectedFeeSum > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                {
                    /// @src 6:14009:14032  "ISRBase.InvalidFeeSum()"
                    let _5 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:14009:14032  "ISRBase.InvalidFeeSum()"
                    mstore(_5, /** @src 6:11070:11093  "ISRBase.InvalidFeeSum()" */ shl(224, 0xb65e4c59))
                    /// @src 6:14009:14032  "ISRBase.InvalidFeeSum()"
                    revert(_5, 4)
                }
                /// @src 6:14048:14061  "uint256 i = 1"
                let var_i := /** @src 7:1957:1983  "getRouterState().moduleIds" */ 1
                /// @src 6:14043:14325  "for (uint256 i = 1; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:14063:14079  "i < modulesCount" */ lt(var_i, length)
                /// @src 6:14048:14061  "uint256 i = 1"
                {
                    /// @src 6:14081:14084  "++i"
                    var_i := /** @src 9:560:562  "32" */ add(/** @src 6:14081:14084  "++i" */ var_i, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _1)
                }
                /// @src 6:14081:14084  "++i"
                {
                    /// @src 9:560:562  "32"
                    let value := calldataload(/** @src 6:14117:14131  "_moduleFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_moduleFees_offset, var_moduleFees_length, var_i))
                    /// @src 6:14117:14150  "_moduleFees[i] + _treasuryFees[i]"
                    let _6 := checked_add_uint256(value, /** @src 9:560:562  "32" */ calldataload(/** @src 6:14134:14150  "_treasuryFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_treasuryFees_offset, var_treasuryFees_length, var_i)))
                    /// @src 6:14164:14235  "if (feeSum > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                    if /** @src 6:14168:14203  "feeSum > SRUtils.TOTAL_BASIS_POINTS" */ gt(_6, /** @src 9:497:502  "10000" */ _4)
                    /// @src 6:14164:14235  "if (feeSum > SRUtils.TOTAL_BASIS_POINTS) revert ISRBase.InvalidFeeSum()"
                    {
                        /// @src 6:14212:14235  "ISRBase.InvalidFeeSum()"
                        let _7 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:14212:14235  "ISRBase.InvalidFeeSum()"
                        mstore(_7, /** @src 6:11070:11093  "ISRBase.InvalidFeeSum()" */ shl(224, 0xb65e4c59))
                        /// @src 6:14212:14235  "ISRBase.InvalidFeeSum()"
                        revert(_7, 4)
                    }
                    /// @src 6:14249:14314  "if (feeSum != expectedFeeSum) revert ISRBase.InconsistentFeeSum()"
                    if /** @src 6:14253:14277  "feeSum != expectedFeeSum" */ iszero(eq(_6, expr_1))
                    /// @src 6:14249:14314  "if (feeSum != expectedFeeSum) revert ISRBase.InconsistentFeeSum()"
                    {
                        /// @src 6:14286:14314  "ISRBase.InconsistentFeeSum()"
                        let _8 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                        /// @src 6:14286:14314  "ISRBase.InconsistentFeeSum()"
                        mstore(_8, /** @src 6:13432:13460  "ISRBase.InconsistentFeeSum()" */ shl(224, 0xf15cd7e5))
                        /// @src 6:14286:14314  "ISRBase.InconsistentFeeSum()"
                        revert(_8, 4)
                    }
                }
                /// @src 6:14376:14385  "uint256 i"
                let var_i_1 := /** @src -1:-1:-1 */ 0
                /// @src 6:14371:14961  "for (uint256 i; i < modulesCount; ++i) {..."
                for { }
                /** @src 6:14387:14403  "i < modulesCount" */ lt(var_i_1, length)
                /// @src 6:14376:14385  "uint256 i"
                {
                    /// @src 6:14405:14408  "++i"
                    var_i_1 := /** @src 9:560:562  "32" */ add(/** @src 6:14405:14408  "++i" */ var_i_1, /** @src 7:1957:1983  "getRouterState().moduleIds" */ _1)
                }
                /// @src 6:14405:14408  "++i"
                {
                    /// @src 4:5016:5034  "set._values[index]"
                    let _9, _10 := storage_array_index_access_bytes32_dyn(/** @src 7:2221:2247  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:1957:1983  "getRouterState().moduleIds" */ _1), /** @src 4:5016:5034  "set._values[index]" */ var_i_1)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _11 := sload(/** @src 4:5016:5034  "set._values[index]" */ _9)
                    /// @src 6:955:47234  "library SRLib {..."
                    let _12 := 3
                    let value_1 := /** @src 9:560:562  "32" */ shr(/** @src 6:955:47234  "library SRLib {..." */ shl(_12, _10), _11)
                    /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                    let var_slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ value_1)
                    let _13 := 0x20
                    mstore(_13, var_slot)
                    let _14 := 0x40
                    /// @src 9:497:502  "10000"
                    let converted := read_from_storage_reference_type_struct_ModuleStateConfig(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _14))
                    /// @src 9:497:502  "10000"
                    let _15 := 0xffff
                    let cleaned := and(/** @src 9:560:562  "32" */ calldataload(/** @src 6:14657:14671  "_moduleFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_moduleFees_offset, var_moduleFees_length, var_i_1)), /** @src 9:497:502  "10000" */ _15)
                    /// @src 6:14626:14647  "stateConfig.moduleFee"
                    let _16 := add(converted, /** @src 6:955:47234  "library SRLib {..." */ _13)
                    /// @src 9:497:502  "10000"
                    mstore(_16, cleaned)
                    let cleaned_1 := and(/** @src 9:560:562  "32" */ calldataload(/** @src 6:14719:14735  "_treasuryFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_treasuryFees_offset, var_treasuryFees_length, var_i_1)), /** @src 9:497:502  "10000" */ _15)
                    /// @src 6:14686:14709  "stateConfig.treasuryFee"
                    let _17 := add(converted, /** @src 6:955:47234  "library SRLib {..." */ _14)
                    /// @src 9:497:502  "10000"
                    mstore(_17, cleaned_1)
                    /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                    let var_slot_1 := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ value_1)
                    mstore(_13, var_slot_1)
                    let dataSlot := keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ _14)
                    let _18 := and(/** @src 9:497:502  "10000" */ mload(converted), /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1))
                    /// @src 9:560:562  "32"
                    let _19 := sload(dataSlot)
                    /// @src 9:497:502  "10000"
                    let _20 := mload(_16)
                    let _21 := 160
                    let toInsert := and(shl(176, mload(_17)), shl(176, 65535))
                    let _22 := mload(add(converted, 96))
                    let _23 := 192
                    sstore(dataSlot, or(or(and(shl(_23, _22), shl(192, 65535)), or(toInsert, or(and(shl(_21, _20), shl(160, 65535)), or(and(/** @src 9:560:562  "32" */ _19, /** @src 9:497:502  "10000" */ shl(224, 0xffffffff)), _18)))), and(shl(208, mload(add(converted, 128))), shl(208, 65535))))
                    let _24 := mload(add(converted, _21))
                    /// @src 9:560:562  "32"
                    if iszero(lt(_24, /** @src 6:955:47234  "library SRLib {..." */ _12))
                    /// @src 9:560:562  "32"
                    {
                        mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        mstore(4, 0x21)
                        revert(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x24)
                    }
                    /// @src 9:497:502  "10000"
                    update_storage_value_offsett_enum_StakingModuleStatus_to_enum_StakingModuleStatus(dataSlot, _24)
                    update_storage_value_offsett_uint8_to_uint8(dataSlot, /** @src 9:560:562  "32" */ and(/** @src 9:497:502  "10000" */ mload(add(converted, _23)), /** @src 9:560:562  "32" */ 0xff))
                    let value_2 := calldataload(/** @src 6:14910:14924  "_moduleFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_moduleFees_offset, var_moduleFees_length, var_i_1))
                    /// @src 9:560:562  "32"
                    let value_3 := calldataload(/** @src 6:14926:14942  "_treasuryFees[i]" */ calldata_array_index_access_uint256_dyn_calldata(var_treasuryFees_offset, var_treasuryFees_length, var_i_1))
                    /// @src 6:14871:14950  "ISRBase.StakingModuleFeesSet(moduleId, _moduleFees[i], _treasuryFees[i], setBy)"
                    let _25 := /** @src 6:955:47234  "library SRLib {..." */ mload(_14)
                    /// @src 6:14871:14950  "ISRBase.StakingModuleFeesSet(moduleId, _moduleFees[i], _treasuryFees[i], setBy)"
                    log2(_25, sub(abi_encode_uint256_uint256_address(_25, value_2, value_3, /** @src 6:14351:14361  "msg.sender" */ caller()), /** @src 6:14871:14950  "ISRBase.StakingModuleFeesSet(moduleId, _moduleFees[i], _treasuryFees[i], setBy)" */ _25), 0x303c8ac43d1b1f9b898ddd2915a294efa01e9b07c322d7deeb7db332b66f0410, value_1)
                }
            }
            /// @ast-id 5241 @src 9:1582:1748  "function _requireModuleIdExists(uint256 _moduleId) internal view {..."
            function fun_requireModuleIdExists(var_moduleId)
            {
                /// @src 9:1657:1741  "if (!SRStorage.isModuleExists(_moduleId)) revert ISRBase.StakingModuleUnregistered()"
                if /** @src 9:1661:1697  "!SRStorage.isModuleExists(_moduleId)" */ iszero(/** @src 4:11363:11400  "_contains(set._inner, bytes32(value))" */ fun_contains(/** @src 7:2358:2384  "getRouterState().moduleIds" */ add(/** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION(), /** @src 7:2358:2384  "getRouterState().moduleIds" */ 1), /** @src 4:11385:11399  "bytes32(value)" */ var_moduleId))
                /// @src 9:1657:1741  "if (!SRStorage.isModuleExists(_moduleId)) revert ISRBase.StakingModuleUnregistered()"
                {
                    /// @src 9:1706:1741  "ISRBase.StakingModuleUnregistered()"
                    let _1 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 9:1706:1741  "ISRBase.StakingModuleUnregistered()"
                    mstore(_1, shl(225, 0x6a0eb141))
                    revert(_1, 4)
                }
            }
            /// @ast-id 4722 @src 7:1509:1663  "function getIStakingModule(uint256 _moduleId) internal view returns (IStakingModule) {..."
            function fun_getIStakingModule(var_moduleId) -> var_address
            {
                /// @src 7:907:975  "assembly (\"memory-safe\") {..."
                let var_slot := /** @src 7:874:897  "ROUTER_STORAGE_POSITION" */ constant_ROUTER_STORAGE_POSITION()
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_moduleId)
                mstore(0x20, var_slot)
                /// @src 7:1604:1656  "return getModuleState(_moduleId).getIStakingModule()"
                var_address := /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:560:562  "32" */ sload(/** @src 6:955:47234  "library SRLib {..." */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x40)), sub(shl(160, 1), 1))
            }
            /// @src 7:527:718  "bytes32 internal constant ROUTER_STORAGE_POSITION = keccak256(..."
            function constant_ROUTER_STORAGE_POSITION() -> ret
            {
                /// @src 7:627:679  "abi.encodePacked(\"lido.StakingRouter.routerStorage\")"
                let expr_mpos := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                /// @src 7:627:679  "abi.encodePacked(\"lido.StakingRouter.routerStorage\")"
                let _1 := add(expr_mpos, 0x20)
                /// @src 6:955:47234  "library SRLib {..."
                mstore(_1, "lido.StakingRouter.routerStorage")
                /// @src 7:627:679  "abi.encodePacked(\"lido.StakingRouter.routerStorage\")"
                mstore(expr_mpos, 0x20)
                finalize_allocation_47078(expr_mpos)
                /// @src 7:617:680  "keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))"
                let _2 := keccak256(/** @src 6:955:47234  "library SRLib {..." */ _1, mload(/** @src 7:617:680  "keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))" */ expr_mpos))
                /// @src 6:955:47234  "library SRLib {..."
                let diff := add(_2, /** @src 9:560:562  "32" */ not(0))
                /// @src 6:955:47234  "library SRLib {..."
                if gt(diff, _2)
                {
                    /// @src 9:560:562  "32"
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x24)
                }
                /// @src 7:598:686  "abi.encode(uint256(keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))) - 1)"
                let expr_4635_mpos := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                /// @src 7:598:686  "abi.encode(uint256(keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))) - 1)"
                let _3 := add(expr_4635_mpos, /** @src 7:627:679  "abi.encodePacked(\"lido.StakingRouter.routerStorage\")" */ 0x20)
                /// @src 6:955:47234  "library SRLib {..."
                mstore(_3, diff)
                /// @src 7:598:686  "abi.encode(uint256(keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))) - 1)"
                mstore(expr_4635_mpos, /** @src 7:627:679  "abi.encodePacked(\"lido.StakingRouter.routerStorage\")" */ 0x20)
                /// @src 7:598:686  "abi.encode(uint256(keccak256(abi.encodePacked(\"lido.StakingRouter.routerStorage\"))) - 1)"
                finalize_allocation_47078(expr_4635_mpos)
                /// @src 7:579:718  "keccak256(..."
                ret := and(/** @src 7:579:692  "keccak256(..." */ keccak256(/** @src 6:955:47234  "library SRLib {..." */ _3, mload(/** @src 7:579:692  "keccak256(..." */ expr_4635_mpos)), /** @src 6:955:47234  "library SRLib {..." */ not(/** @src 9:560:562  "32" */ 255))
            }
            /// @ast-id 1210 @src 6:16598:16848  "function _getStakingModuleSummary(IStakingModule module)..."
            function fun_getStakingModuleSummary(var_module_address) -> var_exitedValidators, var_depositedValidators, var_depositableValidators
            {
                /// @src 6:16809:16841  "module.getStakingModuleSummary()"
                let _1 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                /// @src 6:16809:16841  "module.getStakingModuleSummary()"
                mstore(_1, /** @src 6:955:47234  "library SRLib {..." */ shl(224, 0x9abddf09))
                /// @src 6:16809:16841  "module.getStakingModuleSummary()"
                let _2 := staticcall(gas(), /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 6:16809:16839  "module.getStakingModuleSummary" */ var_module_address, /** @src 6:955:47234  "library SRLib {..." */ sub(shl(160, 1), 1)), /** @src 6:16809:16841  "module.getStakingModuleSummary()" */ _1, 4, _1, 96)
                if iszero(_2)
                {
                    /// @src 6:955:47234  "library SRLib {..."
                    let pos := mload(64)
                    returndatacopy(pos, /** @src 6:16809:16841  "module.getStakingModuleSummary()" */ 0, /** @src 6:955:47234  "library SRLib {..." */ returndatasize())
                    revert(pos, returndatasize())
                }
                /// @src 6:16809:16841  "module.getStakingModuleSummary()"
                let expr_component := 0
                let expr_component_1 := 0
                let expr_component_2 := 0
                if _2
                {
                    let _3 := 96
                    if gt(96, returndatasize()) { _3 := returndatasize() }
                    finalize_allocation(_1, _3)
                    /// @src 6:955:47234  "library SRLib {..."
                    if slt(sub(/** @src 6:16809:16841  "module.getStakingModuleSummary()" */ add(_1, _3), /** @src 6:955:47234  "library SRLib {..." */ _1), /** @src 6:16809:16841  "module.getStakingModuleSummary()" */ 96)
                    /// @src 6:955:47234  "library SRLib {..."
                    {
                        revert(/** @src 6:16809:16841  "module.getStakingModuleSummary()" */ 0, 0)
                    }
                    /// @src 6:955:47234  "library SRLib {..."
                    let value := mload(_1)
                    let value_1 := mload(add(_1, 32))
                    let value_2 := mload(add(_1, 64))
                    /// @src 6:16809:16841  "module.getStakingModuleSummary()"
                    expr_component := value
                    expr_component_1 := value_1
                    expr_component_2 := value_2
                }
                /// @src 6:16802:16841  "return module.getStakingModuleSummary()"
                var_exitedValidators := expr_component
                var_depositedValidators := expr_component_1
                var_depositableValidators := expr_component_2
            }
            /// @ast-id 640 @src 6:10129:10624  "function _validateShareParams(uint256 _stakeShareLimit, uint256 _priorityExitShareThreshold) private pure {..."
            function fun_validateShareParams(var_stakeShareLimit, var_priorityExitShareThreshold)
            {
                /// @src 9:497:502  "10000"
                let _1 := 0x2710
                /// @src 6:10245:10360  "if (_stakeShareLimit > SRUtils.TOTAL_BASIS_POINTS) {..."
                if /** @src 6:10249:10294  "_stakeShareLimit > SRUtils.TOTAL_BASIS_POINTS" */ gt(var_stakeShareLimit, /** @src 9:497:502  "10000" */ _1)
                /// @src 6:10245:10360  "if (_stakeShareLimit > SRUtils.TOTAL_BASIS_POINTS) {..."
                {
                    /// @src 6:10317:10349  "ISRBase.InvalidStakeShareLimit()"
                    let _2 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:10317:10349  "ISRBase.InvalidStakeShareLimit()"
                    mstore(_2, shl(225, 0x6f004ebd))
                    revert(_2, 4)
                }
                /// @src 6:10369:10506  "if (_priorityExitShareThreshold > SRUtils.TOTAL_BASIS_POINTS) {..."
                if /** @src 6:10373:10429  "_priorityExitShareThreshold > SRUtils.TOTAL_BASIS_POINTS" */ gt(var_priorityExitShareThreshold, /** @src 9:497:502  "10000" */ _1)
                /// @src 6:10369:10506  "if (_priorityExitShareThreshold > SRUtils.TOTAL_BASIS_POINTS) {..."
                {
                    /// @src 6:10452:10495  "ISRBase.InvalidPriorityExitShareThreshold()"
                    let _3 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:10452:10495  "ISRBase.InvalidPriorityExitShareThreshold()"
                    mstore(_3, shl(227, 0x0285aacf))
                    revert(_3, 4)
                }
                /// @src 6:10515:10617  "if (_stakeShareLimit > _priorityExitShareThreshold) revert ISRBase.InvalidPriorityExitShareThreshold()"
                if /** @src 6:10519:10565  "_stakeShareLimit > _priorityExitShareThreshold" */ gt(var_stakeShareLimit, var_priorityExitShareThreshold)
                /// @src 6:10515:10617  "if (_stakeShareLimit > _priorityExitShareThreshold) revert ISRBase.InvalidPriorityExitShareThreshold()"
                {
                    /// @src 6:10574:10617  "ISRBase.InvalidPriorityExitShareThreshold()"
                    let _4 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 6:10574:10617  "ISRBase.InvalidPriorityExitShareThreshold()"
                    mstore(_4, /** @src 6:10452:10495  "ISRBase.InvalidPriorityExitShareThreshold()" */ shl(227, 0x0285aacf))
                    /// @src 6:10574:10617  "ISRBase.InvalidPriorityExitShareThreshold()"
                    revert(_4, 4)
                }
            }
            /// @ast-id 6686 @src 3:13296:13509  "function toUint64(uint256 value) internal pure returns (uint64) {..."
            function fun_toUint64(var_value) -> var
            {
                /// @src 6:955:47234  "library SRLib {..."
                let _1 := 0xffffffffffffffff
                /// @src 3:13370:13473  "if (value > type(uint64).max) {..."
                if /** @src 3:13374:13398  "value > type(uint64).max" */ gt(var_value, /** @src 6:955:47234  "library SRLib {..." */ _1)
                /// @src 3:13370:13473  "if (value > type(uint64).max) {..."
                {
                    /// @src 3:13421:13462  "SafeCastOverflowedUintDowncast(64, value)"
                    let _2 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 3:13421:13462  "SafeCastOverflowedUintDowncast(64, value)"
                    mstore(_2, shl(228, 0x06dfcc65))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src 3:13421:13462  "SafeCastOverflowedUintDowncast(64, value)" */ add(_2, 4), /** @src 6:955:47234  "library SRLib {..." */ 64)
                    mstore(add(/** @src 3:13421:13462  "SafeCastOverflowedUintDowncast(64, value)" */ _2, /** @src 6:955:47234  "library SRLib {..." */ 36), var_value)
                    /// @src 3:13421:13462  "SafeCastOverflowedUintDowncast(64, value)"
                    revert(_2, /** @src 6:955:47234  "library SRLib {..." */ 68)
                }
                /// @src 3:13482:13502  "return uint64(value)"
                var := /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 3:13489:13502  "uint64(value)" */ var_value, /** @src 6:955:47234  "library SRLib {..." */ _1)
            }
            /// @ast-id 5313 @src 9:2901:3122  "function _ensureAmountGwei(uint256 amountGwei) internal pure returns (uint64) {..."
            function fun_ensureAmountGwei(var_amountGwei) -> var
            {
                /// @src 9:2989:3081  "if (amountGwei > MAX_VALUE_GWEI) {..."
                if /** @src 9:2993:3020  "amountGwei > MAX_VALUE_GWEI" */ gt(var_amountGwei, /** @src 9:887:915  "1_000_000_000 ether / 1 gwei" */ 0x0de0b6b3a7640000)
                /// @src 9:2989:3081  "if (amountGwei > MAX_VALUE_GWEI) {..."
                {
                    /// @src 9:3043:3070  "ISRBase.InvalidAmountGwei()"
                    let _1 := /** @src 6:955:47234  "library SRLib {..." */ mload(64)
                    /// @src 9:3043:3070  "ISRBase.InvalidAmountGwei()"
                    mstore(_1, shl(225, 0x1b55234b))
                    revert(_1, 4)
                }
                /// @src 9:3090:3115  "return uint64(amountGwei)"
                var := /** @src 6:955:47234  "library SRLib {..." */ and(/** @src 9:3097:3115  "uint64(amountGwei)" */ var_amountGwei, /** @src 6:955:47234  "library SRLib {..." */ 0xffffffffffffffff)
            }
            function storage_array_index_access_bytes32_dyn(array, index) -> slot, offset
            {
                if iszero(lt(index, sload(array)))
                {
                    mstore(0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(4, 0x32)
                    revert(0, 0x24)
                }
                /// @src 9:560:562  "32"
                mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ array)
                /// @src 6:955:47234  "library SRLib {..."
                slot := add(/** @src 9:560:562  "32" */ keccak256(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ 0x20), /** @src 6:955:47234  "library SRLib {..." */ index)
                offset := /** @src -1:-1:-1 */ 0
            }
            /// @ast-id 7805 @src 4:2241:2647  "function _add(Set storage set, bytes32 value) private returns (bool) {..."
            function fun_add(var_set_slot, var_value) -> var
            {
                /// @src 4:2320:2641  "if (!_contains(set, value)) {..."
                switch /** @src 4:2324:2346  "!_contains(set, value)" */ iszero(/** @src 4:2325:2346  "_contains(set, value)" */ fun_contains(var_set_slot, var_value))
                case /** @src 4:2320:2641  "if (!_contains(set, value)) {..." */ 0 {
                    /// @src 4:2618:2630  "return false"
                    var := /** @src -1:-1:-1 */ 0
                    /// @src 4:2618:2630  "return false"
                    leave
                }
                default /// @src 4:2320:2641  "if (!_contains(set, value)) {..."
                {
                    /// @src 6:955:47234  "library SRLib {..."
                    let oldLen := sload(var_set_slot)
                    if iszero(lt(oldLen, 18446744073709551616))
                    {
                        mstore(/** @src -1:-1:-1 */ 0, /** @src 9:560:562  "32" */ shl(224, 0x4e487b71))
                        /// @src 6:955:47234  "library SRLib {..."
                        mstore(4, 0x41)
                        revert(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x24)
                    }
                    sstore(var_set_slot, add(oldLen, 1))
                    let slot, offset := storage_array_index_access_bytes32_dyn(var_set_slot, oldLen)
                    /// @src 9:560:562  "32"
                    let _1 := sload(slot)
                    let shiftBits := shl(3, offset)
                    sstore(slot, or(and(_1, not(shl(shiftBits, not(0)))), shl(shiftBits, var_value)))
                    /// @src 6:955:47234  "library SRLib {..."
                    let _2 := sload(/** @src 4:2544:2562  "set._values.length" */ var_set_slot)
                    /// @src 6:955:47234  "library SRLib {..."
                    mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_value)
                    mstore(0x20, /** @src 4:2520:2534  "set._positions" */ add(var_set_slot, /** @src 6:955:47234  "library SRLib {..." */ 1))
                    sstore(keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x40), _2)
                    /// @src 4:2576:2587  "return true"
                    var := /** @src 6:955:47234  "library SRLib {..." */ 1
                    /// @src 4:2576:2587  "return true"
                    leave
                }
            }
            /// @ast-id 7908 @src 4:4264:4393  "function _contains(Set storage set, bytes32 value) private view returns (bool) {..."
            function fun_contains(var_set_7893_slot, var_value) -> var
            {
                /// @src 6:955:47234  "library SRLib {..."
                mstore(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ var_value)
                mstore(0x20, /** @src 4:4360:4374  "set._positions" */ add(var_set_7893_slot, 1))
                /// @src 4:4353:4386  "return set._positions[value] != 0"
                var := /** @src 4:4360:4386  "set._positions[value] != 0" */ iszero(iszero(/** @src 6:955:47234  "library SRLib {..." */ sload(keccak256(/** @src -1:-1:-1 */ 0, /** @src 6:955:47234  "library SRLib {..." */ 0x40))))
            }
        }
        data ".metadata" hex"a26469706673582212208ec602a9b9ff648a5facb7e00115fc9c5c1aae5aadc3d79239891b28d8954bea64736f6c63430008190033"
    }
}
