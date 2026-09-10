// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
interface IWithdrawalVault {
 function addConsolidationRequests(bytes[] calldata,bytes[] calldata) external payable;
 function getConsolidationRequestFee() external view returns(uint256);
}
// Only the source count and fee/vault/refund suffix are copied. Prefix admission
// and full witness layout are intentionally omitted from this fragment harness.
contract SettlementHarness {
 struct TargetWitness { bytes pubkey; }
 struct ConsolidationWitnessGroup { bytes[] sourcePubkeys; TargetWitness targetWitness; }
 error ZeroArgument(string name);
 error EmptyGroup(uint256 groupIndex);
 error InsufficientFee(uint256 feeRequired,uint256 passedValue);
 error FeeRefundFailed();
    modifier preservesEthBalance() {
        uint256 balanceBeforeCall = address(this).balance - msg.value;
        _;
        assert(address(this).balance == balanceBeforeCall);
    }
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


        // Role/pause/DSM/locator/witness/quota admission is outside this harness.
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

    function _checkFee(uint256 fee) internal view returns (uint256 refund) {
        if (msg.value < fee) {
            revert InsufficientFee(fee, msg.value);
        }
        unchecked {
            refund = msg.value - fee;
        }
    }

    function _refundFee(uint256 refund, address recipient) internal {
        if (refund > 0) {
            // If the refund recipient is not set, use the sender as the refund recipient
            if (recipient == address(0)) {
                recipient = msg.sender;
            }

            (bool success, ) = recipient.call{value: refund}("");
            if (!success) {
                revert FeeRefundFailed();
            }
        }
    }

    function _prepareConsolidationPairs(
        ConsolidationWitnessGroup[] calldata groups,
        uint256 totalCount
    ) internal pure returns (bytes[] memory sourcePubkeys, bytes[] memory targetPubkeys) {
        sourcePubkeys = new bytes[](totalCount);
        targetPubkeys = new bytes[](totalCount);

        uint256 idx = 0;
        for (uint256 i = 0; i < groups.length; ++i) {
            bytes[] calldata group = groups[i].sourcePubkeys;
            bytes calldata target = groups[i].targetWitness.pubkey;
            for (uint256 j = 0; j < group.length; ++j) {
                sourcePubkeys[idx] = group[j];
                targetPubkeys[idx] = target;
                ++idx;
            }
        }
    }
}
