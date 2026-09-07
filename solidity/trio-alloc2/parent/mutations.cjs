// Test-only edits applied in memory after validating the original pinned sources.
const mutations = {
  'skip-total-scaling': {test:'normal', source:'sr',
    from:'totalAllocated *= initialDeposit;', to:'totalAllocated = totalAllocated;'},
  'alias-original-array': {test:'normal', source:'sr',
    from:'totalAllocated *= initialDeposit;', to:'allocated = newAllocations; totalAllocated *= initialDeposit;'},
  'skip-zero-conversion': {test:'zero-demand', source:'sr',
    from:'newAllocations[i] = allocated[i] * initialDeposit;', to:'newAllocations[i] = 0;'},
  'unchecked-zero-multiply': {test:'zero-demand-overflow', source:'sr',
    from:'newAllocations[i] = allocated[i] * initialDeposit;',
    to:'unchecked { newAllocations[i] = allocated[i] * initialDeposit; }'},
  'division-before-empty': {test:'empty-zero-divisor', source:'sr',
    from:'uint256 modulesCount = SRStorage.getModulesCount();\n        if (modulesCount == 0) {',
    to:'uint256 modulesCount = SRStorage.getModulesCount();\n        if (_allocateAmount / _cfg.maxEBType1 == type(uint256).max) { revert(); }\n        if (modulesCount == 0) {'},
  'swallow-parent-revert': {test:'late-second-row-overflow', source:'harness', frame:true,
    from:'require(sent);\n        return SRLib._getDepositAllocations(cfg, amount, topup);',
    to:'require(sent);\n        try this.parent(cfg, amount, topup) returns (uint256 total, uint256[] memory deltas, uint256[] memory next) {\n            return (total, deltas, next);\n        } catch { return (0, new uint256[](0), new uint256[](0)); }'}
};
function apply(source, mutation) {
  const occurrences = source.split(mutation.from).length - 1;
  if (occurrences !== 1) throw new Error('mutation anchor is not unique: '+occurrences);
  return source.replace(mutation.from, mutation.to);
}
module.exports = {mutations, apply};
