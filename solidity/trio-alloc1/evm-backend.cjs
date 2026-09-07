const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const assert = require('node:assert/strict');
module.exports.provider = options => {
  const target = process.env.ALLOC1_EVM || 'shanghai';
  assert(['shanghai', 'cancun'].includes(target), 'unsupported EVM target');
  if (target === 'shanghai') return require('ganache').provider(options);
  process.env.HARDHAT_CONFIG = require.resolve('./hardhat.config.cjs');
  const hre = require('hardhat');
  assert.equal(hre.network.config.hardfork, 'cancun');
  assert.equal(hre.network.config.allowUnlimitedContractSize, false);
  const deployments = new Map();
  return {request: async args => {
    const result = await hre.network.provider.request(args);
    if (args.method === 'eth_getTransactionReceipt' && result?.contractAddress &&
        !deployments.has(result.transactionHash)) {
      const code = await hre.network.provider.request({method: 'eth_getCode',
        params: [result.contractAddress, 'latest']});
      const transaction = await hre.network.provider.request({method: 'eth_getTransactionByHash',
        params: [result.transactionHash]});
      const bytes = Buffer.from(code.slice(2), 'hex');
      assert(bytes.length <= 24576, 'EIP-170 runtime code limit');
      deployments.set(result.transactionHash, {receipt: result, transaction, runtimeCode: code,
        runtimeBytes: bytes.length, runtimeSha256: crypto.createHash('sha256').update(bytes).digest('hex')});
      fs.writeFileSync(path.join(process.argv[2], 'deployments.json'),
        JSON.stringify([...deployments.values()], null, 2));
    }
    return result;
  }, disconnect: async () => {}};
};
