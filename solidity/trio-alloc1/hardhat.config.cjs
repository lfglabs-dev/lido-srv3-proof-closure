// Local in-process EVM; enforce normal contract-size limits.
module.exports = {
  solidity: '0.8.25',
  networks: {hardhat: {hardfork: 'cancun', allowUnlimitedContractSize: false,
    throwOnTransactionFailures: false, throwOnCallFailures: true}},
};
