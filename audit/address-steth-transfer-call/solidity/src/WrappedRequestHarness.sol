pragma solidity 0.8.9;
import "./core/WithdrawalQueue.sol";
contract WrappedRequestHarness is WithdrawalQueue {
    event Transfer(address indexed from,address indexed to,uint256 indexed id);
    constructor(IWstETH wrapper) WithdrawalQueue(wrapper) {}
    function _emitTransfer(address from,address to,uint256 id) internal override { emit Transfer(from,to,id); }
    // One-item caller boundary. No pause/array allocation/batch or permit claims.
    function one(uint256 amount,address owner) external returns(uint256) {
        if(owner==address(0)) owner=msg.sender;
        return _requestWithdrawalWstETH(amount,owner);
    }
    function seed(uint256 id,uint128 st,uint128 sh,uint256 report) external {
        _setLastRequestId(id);
        _getQueue()[id]=WithdrawalRequest(st,sh,address(0),0,false,0);
        _setLastReportTimestamp(report);
    }
    function metadata(uint256 id) external view returns(WithdrawalRequest memory) {return _getQueue()[id];}
}
