// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import {PhysicalQuotaHarness} from "./PhysicalQuotaHarness.sol";
import {IWithdrawalVault} from "contracts/0.8.25/consolidation/ConsolidationGateway.sol";
interface BalanceInstrumentation { function deal(address,uint256) external; }
// Exact inherited modifiers; only this typed suffix omits DSM/locator/witness checks.
contract PhysicalEntryHarness is PhysicalQuotaHarness {
 constructor() { _grantRole(ADD_CONSOLIDATION_REQUEST_ROLE,msg.sender); }
 function seedRole(address caller,uint256 value) external {
  bytes32 inner=keccak256(abi.encode(ADD_CONSOLIDATION_REQUEST_ROLE,uint256(0)));
  bytes32 key=keccak256(abi.encode(caller,inner));assembly {sstore(key,value)}
 }
 function setResume(uint256 value) external {
  bytes32 p=0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02;
  assembly {sstore(p,value)}
 }
 // Test-only balance damage; not a naturally reachable credited CALL state.
 function charged() external payable {
  BalanceInstrumentation(address(uint160(uint256(keccak256("hevm cheat code"))))).deal(address(this),0);
  _charged();
 }
 function _charged() internal onlyRole(ADD_CONSOLIDATION_REQUEST_ROLE) preservesEthBalance whenResumed {}
    function entry(IWithdrawalVault withdrawalVault, ConsolidationWitnessGroup[] calldata groups, address refundRecipient) external payable onlyRole(ADD_CONSOLIDATION_REQUEST_ROLE) preservesEthBalance whenResumed {
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


        // Typed suffix: omitted DSM/locator/witness prefix.
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
