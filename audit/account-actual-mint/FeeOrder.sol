pragma solidity 0.8.9;
contract FeeOrder { function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } }
