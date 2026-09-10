// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import "./WithdrawalVaultEIP7685.sol";
contract SettlementVaultHarness is WithdrawalVaultEIP7685 {
 address public immutable CONSOLIDATION_GATEWAY;
 error NotConsolidationGateway();
 constructor(address gateway,address target) WithdrawalVaultEIP7685(target,target) { CONSOLIDATION_GATEWAY=gateway; }
    modifier preservesEthBalance() {
        uint256 balanceBeforeCall = address(this).balance - msg.value;
        _;
        assert(address(this).balance == balanceBeforeCall);
    }
    function addConsolidationRequests(
        bytes[] calldata sourcePubkeys,
        bytes[] calldata targetPubkeys
    ) external payable preservesEthBalance {
        if (msg.sender != CONSOLIDATION_GATEWAY) {
            revert NotConsolidationGateway();
        }

        _addConsolidationRequests(sourcePubkeys, targetPubkeys);
    }
    function getConsolidationRequestFee() external view returns (uint256) {
        return _getConsolidationRequestFee();
    }
}
