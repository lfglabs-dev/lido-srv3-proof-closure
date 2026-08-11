// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

/// Executable reference/equivalent-model harness for pinned TopUpGateway
/// `_evaluateTopUpLimit` and its ERC-7201 namespaced packed Storage struct.
contract PTopup2Differential {
    bytes32 internal constant GATEWAY_STORAGE_POSITION =
        0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200;
    uint64 internal constant FAR_FUTURE_EPOCH = type(uint64).max;

    struct Storage {
        uint64 maxValidatorsPerTopUp;
        uint32 lastTopUpTimestamp;
        uint32 lastTopUpBlock;
        uint16 minBlockDistance;
        uint16 maxRootAge;
        uint64 targetBalanceGwei;
        uint64 minTopUpGwei;
    }

    function _gatewayStorage() internal pure returns (Storage storage s) {
        bytes32 position = GATEWAY_STORAGE_POSITION;
        assembly ("memory-safe") { s.slot := position }
    }

    function seedWords(bytes32 word0, bytes32 word1) external {
        bytes32 p = GATEWAY_STORAGE_POSITION;
        assembly ("memory-safe") { sstore(p, word0) sstore(add(p, 1), word1) }
    }

    function words() external view returns (bytes32 word0, bytes32 word1) {
        bytes32 p = GATEWAY_STORAGE_POSITION;
        assembly ("memory-safe") { word0 := sload(p) word1 := sload(add(p, 1)) }
    }

    function setTarget(uint64 value) external { _gatewayStorage().targetBalanceGwei = value; }
    function setMinimum(uint64 value) external { _gatewayStorage().minTopUpGwei = value; }
    function getTarget() external view returns (uint64) { return _gatewayStorage().targetBalanceGwei; }
    function getMinimum() external view returns (uint64) { return _gatewayStorage().minTopUpGwei; }

    function referenceEvaluate(
        uint64 effectiveBalance, uint64 exitEpoch, bool slashed, uint256 pendingBalanceGwei
    ) external view returns (uint256) {
        if (exitEpoch != FAR_FUTURE_EPOCH || slashed) return 0;
        Storage storage s = _gatewayStorage();
        uint256 currentTotal = effectiveBalance + pendingBalanceGwei;
        if (currentTotal >= s.targetBalanceGwei) return 0;
        uint256 topUpLimit = s.targetBalanceGwei - currentTotal;
        if (topUpLimit < s.minTopUpGwei) return 0;
        return topUpLimit;
    }

    function equivalentModel(
        uint64 effectiveBalance, uint64 exitEpoch, bool slashed, uint256 pendingBalanceGwei
    ) external view returns (uint256) {
        if (exitEpoch != type(uint64).max || slashed) return 0;
        uint256 currentTotal = uint256(effectiveBalance) + pendingBalanceGwei;
        uint256 target = _gatewayStorage().targetBalanceGwei;
        if (currentTotal >= target) return 0;
        uint256 gap = target - currentTotal;
        return gap < _gatewayStorage().minTopUpGwei ? 0 : gap;
    }
}

