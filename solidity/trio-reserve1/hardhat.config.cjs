// In-process local EVM only; no RPC endpoint, account secret, or public network.
module.exports = {
  solidity: '0.8.25',
  networks: {hardhat: {hardfork:'cancun',allowUnlimitedContractSize:true,
    throwOnTransactionFailures:false,throwOnCallFailures:false}},
};
