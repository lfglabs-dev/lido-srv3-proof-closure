pragma solidity 0.8.9;
import "./WithdrawalQueueBase.sol";
contract ClaimHarness is WithdrawalQueueBase {
    using EnumerableSet for EnumerableSet.UintSet;
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    error ZeroRecipient();
    error ArraysLengthMismatch(uint256 a, uint256 b);
    function seed(address owner) external {
        _getQueue()[1] = WithdrawalRequest(30,30,owner,100,false,90);
        _getQueue()[2] = WithdrawalRequest(70,70,owner,101,false,90);
        _getRequestsByOwner()[owner].add(1);
        _getRequestsByOwner()[owner].add(2);
        _setLastFinalizedRequestId(2); _setLastCheckpointIndex(1);
        _getCheckpoints()[1] = Checkpoint(1,1e27); _setLockedEtherAmount(70);
    }
    // Exact WithdrawalQueue.claimWithdrawalsTo source loop/guards; the NFT
    // event wrapper is represented by its emitted Transfer event.
    function claimWithdrawalsTo(uint256[] calldata ids,uint256[] calldata hints,address recipient) external {
        if (recipient == address(0)) revert ZeroRecipient();
        if (ids.length != hints.length) revert ArraysLengthMismatch(ids.length,hints.length);
        for (uint256 i=0;i<ids.length;++i) { _claim(ids[i],hints[i],recipient); emit Transfer(msg.sender,address(0),ids[i]); }
    }
    function claimed(uint256 id) external view returns(bool) { return _getQueue()[id].claimed; }
    receive() external payable {}
}
