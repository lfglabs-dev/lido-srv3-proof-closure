// Save the complete import-resolved compiler input, bytecode and settings for replay.
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto');
const hash = x => crypto.createHash('sha256').update(x).digest('hex');
let compileIndex = 0;
module.exports = compiler => ({
  version: () => compiler.version(),
  compile: (inputText, callbacks) => {
    const input = JSON.parse(inputText);
    for (const contracts of Object.values(input.settings.outputSelection))
      for (const fields of Object.values(contracts))
        if (!fields.includes('evm.deployedBytecode')) fields.push('evm.deployedBytecode');
    const result = compiler.compile(JSON.stringify(input), {import: name => {
      const value = callbacks.import(name);
      if (value.contents !== undefined) input.sources[name] = {content: value.contents};
      return value;
    }});
    const directory = process.argv[2];
    fs.mkdirSync(directory, {recursive: true});
    const prefix = path.join(directory, 'complete-compiler-' + (++compileIndex));
    const fullInput = JSON.stringify(input, null, 2);
    fs.writeFileSync(prefix + '-input.json', fullInput);
    fs.writeFileSync(prefix + '-output.json', result);
    const output = JSON.parse(result);
    const bytecodes = Object.fromEntries(Object.entries(output.contracts || {}).flatMap(([file, contracts]) =>
      Object.entries(contracts).map(([name, c]) => [file + ':' + name, {
        runtimeBytes: (c.evm?.deployedBytecode?.object || '').length / 2,
        runtimeSha256: hash(c.evm?.deployedBytecode?.object || ''),
        creationBytes: (c.evm?.bytecode?.object || '').length / 2,
        creationSha256: hash(c.evm?.bytecode?.object || ''),
      }])));
    fs.writeFileSync(prefix + '-receipt.json', JSON.stringify({compiler: compiler.version(),
      bytecodeHashEncoding: 'UTF-8 compiler hexadecimal object including any link placeholders',
      target: process.env.ALLOC1_EVM || 'shanghai', inputSha256: hash(fullInput),
      outputSha256: hash(result), settings: input.settings, bytecodes,
      sources: Object.fromEntries(Object.entries(input.sources).map(([name, s]) => [name, hash(s.content)])),
      hardhat: process.env.ALLOC1_EVM === 'cancun' ? require('hardhat/package.json').version : null,
      allowUnlimitedContractSize: process.env.ALLOC1_EVM === 'cancun' ? false : 'see runner options',
    }, null, 2));
    return result;
  },
});
