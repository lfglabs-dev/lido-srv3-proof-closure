// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import {ConsolidationGateway,IWithdrawalVault} from "contracts/0.8.25/consolidation/ConsolidationGateway.sol";
import {pack} from "contracts/common/lib/GIndex.sol";
// Actual inherited rate library, storage, timestamp, fee/refund and pair producer.
// Only this explicit suffix entry bypasses the omitted stateful gateway prefix.
contract PhysicalQuotaHarness is ConsolidationGateway {
 constructor() ConsolidationGateway(address(this),address(1),10,1,10,pack(1,0),pack(1,0),0) {}
 function consume(uint256 count) external { _consumeConsolidationRequestLimit(count); }
 function rawQuota() external view returns(uint256 value) { bytes32 p=CONSOLIDATION_LIMIT_POSITION; assembly {value:=sload(p)} }
 function setRaw(uint256 value) external { bytes32 p=CONSOLIDATION_LIMIT_POSITION; assembly {sstore(p,value)} }
    function settle(IWithdrawalVault withdrawalVault, ConsolidationWitnessGroup[] calldata groups, address refundRecipient) external payable preservesEthBalance {
        if (msg.value == 0) revert ZeroArgument("msg.value");
        uint256 groupsCount = groups.length;
        if (groupsCount == 0) revert ZeroArgument("groups");

        // Count total individual requests across all groups
        uint256 requestsCount = 0;
        for (uint256 i = 0; i < groupsCount; ++i) {
            uint256 groupSize = groups[i].sourcePubkeys.length;
            if (groupSize == 0) revert EmptyGroup(i);
            requestsCount += groupSize;
        }


        // Typed suffix: omitted role/pause/DSM/locator/witness prefix.
        _consumeConsolidationRequestLimit(requestsCount);
        uint256 fee = withdrawalVault.getConsolidationRequestFee();
        uint256 totalFee = requestsCount * fee;
        uint256 refund = _checkFee(totalFee);

        // Expand grouped requests into flat pairs for WithdrawalVault
        (bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys) = _prepareConsolidationPairs(
            groups,
            requestsCount
        );
        withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys);

        _refundFee(refund, refundRecipient);
    }
}
