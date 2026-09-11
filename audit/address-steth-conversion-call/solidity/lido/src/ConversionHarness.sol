pragma solidity 0.4.24;
import "./contracts/0.4.24/Lido.sol";
contract Callback { function moved(address sender,address to,uint256 amount) external; }
// Only mutable transfer boundary is replaced. Both conversion/quote bodies and
// all rate/storage helpers remain the actual inherited full pinned Lido code.
contract ConversionHarness is Lido {
 address public controller;
 function configure(address c) external {controller=c;}
 function transfer(address to,uint256 amount) external returns(bool) {
  Callback(controller).moved(msg.sender,to,amount);return true;
 }
}
