pragma solidity 0.8.9;
import "./WrappedRequestHarness.sol";
contract BatchHarness is WrappedRequestHarness {
 constructor(IWstETH w) WrappedRequestHarness(w) {}
 // Explicit fixture hook: callback writes the real pause slot. No role theorem.
 function setResume(uint256 resumeAt) external {
  bytes32 slot=keccak256("lido.PausableUntil.resumeSinceTimestamp");
  assembly {sstore(slot,resumeAt)}
 }
}
