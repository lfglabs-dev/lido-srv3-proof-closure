    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":503:3515  contract OssifiableProxy is ERC1967Proxy {... */
  mstore(0x40, 0x80)
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":898:1075  constructor(... */
  callvalue
  dup1
  iszero
  tag_1
  jumpi
  0x00
  dup1
  revert
tag_1:
  pop
  mload(0x40)
  sub(codesize, bytecodeSize)
  dup1
  bytecodeSize
  dup4
  codecopy
  dup2
  add
  0x40
  dup2
  swap1
  mstore
  tag_2
  swap2
  tag_3
  jump	// in
tag_2:
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1014:1029  implementation_ */
  dup3
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1031:1036  data_ */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1050:1104  uint256(keccak256("eip1967.proxy.implementation")) - 1 */
  tag_7
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1103:1104  1 */
  0x01
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1058:1099  keccak256("eip1967.proxy.implementation") */
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbd
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1050:1104  uint256(keccak256("eip1967.proxy.implementation")) - 1 */
  tag_8
  jump	// in
tag_7:
  0x00
  dup1
  mload
  0x20
  data_75b20eef8615de99c108b05f0dbda081c91897128caa336d75dffb97c4132b4d
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1018:1105  _IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1) */
  eq
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1011:1106  assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)) */
  tag_10
  jumpi
  tag_10
  tag_11
  jump	// in
tag_10:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1116:1155  _upgradeToAndCall(_logic, _data, false) */
  tag_12
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1134:1140  _logic */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1142:1147  _data */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1149:1154  false */
  0x00
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1116:1133  _upgradeToAndCall */
  0x0100000000
  tag_13
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1116:1155  _upgradeToAndCall(_logic, _data, false) */
  div
  jump	// in
tag_12:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":945:1162  constructor(address _logic, bytes memory _data) payable {... */
  pop
  pop
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1048:1068  _changeAdmin(admin_) */
  tag_15
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1061:1067  admin_ */
  dup3
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1048:1060  _changeAdmin */
  mul(0x0100000000, tag_16)
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1048:1068  _changeAdmin(admin_) */
  0x0100000000
  swap1
  div
  jump	// in
tag_15:
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":898:1075  constructor(... */
  pop
  pop
  pop
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":503:3515  contract OssifiableProxy is ERC1967Proxy {... */
  jump(tag_77)
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2122:2417  function _upgradeToAndCall(... */
tag_13:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2289  _upgradeTo(newImplementation) */
  tag_19
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2271:2288  newImplementation */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2270  _upgradeTo */
  0x0100000000
  tag_20
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2289  _upgradeTo(newImplementation) */
  div
  jump	// in
tag_19:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2317:2318  0 */
  0x00
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2307  data */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2314  data.length */
  mload
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2318  data.length > 0 */
  gt
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2331  data.length > 0 || forceCall */
  dup1
  tag_21
  jumpi
  pop
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2322:2331  forceCall */
  dup1
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2331  data.length > 0 || forceCall */
tag_21:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2299:2411  if (data.length > 0 || forceCall) {... */
  iszero
  tag_22
  jumpi
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2400  Address.functionDelegateCall(newImplementation, data) */
  tag_23
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2376:2393  newImplementation */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2395:2399  data */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2375  Address.functionDelegateCall */
  0x0100000000
  tag_0_49
  tag_24
  dup3
  mul
  or
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2400  Address.functionDelegateCall(newImplementation, data) */
  div
  jump	// in
tag_23:
  pop
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2299:2411  if (data.length > 0 || forceCall) {... */
tag_22:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2122:2417  function _upgradeToAndCall(... */
  pop
  pop
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4843:4978  function _changeAdmin(address newAdmin) internal {... */
tag_16:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
  0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4931  _getAdmin() */
  tag_26
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4929  _getAdmin */
  0x0100000000
  tag_27
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4931  _getAdmin() */
  div
  jump	// in
tag_26:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
  0x40
  dup1
  mload
  sub(exp(0x02, 0xa0), 0x01)
    /* "#utility.yul":2409:2424   */
  swap3
  dup4
  and
    /* "#utility.yul":2391:2425   */
  dup2
  mstore
    /* "#utility.yul":2461:2476   */
  swap2
  dup5
  and
    /* "#utility.yul":2456:2458   */
  0x20
    /* "#utility.yul":2441:2459   */
  dup4
  add
    /* "#utility.yul":2434:2477   */
  mstore
    /* "#utility.yul":2326:2344   */
  add
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
  mload(0x40)
  dup1
  swap2
  sub
  swap1
  log1
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4971  _setAdmin(newAdmin) */
  tag_30
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4962:4970  newAdmin */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4961  _setAdmin */
  0x0100000000
  tag_31
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4971  _setAdmin(newAdmin) */
  div
  jump	// in
tag_30:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4843:4978  function _changeAdmin(address newAdmin) internal {... */
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1836:1988  function _upgradeTo(address newImplementation) internal {... */
tag_20:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1939  _setImplementation(newImplementation) */
  tag_33
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1921:1938  newImplementation */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1920  _setImplementation */
  0x0100000000
  tag_34
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1939  _setImplementation(newImplementation) */
  div
  jump	// in
tag_33:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1954:1981  Upgraded(newImplementation) */
  mload(0x40)
  sub(exp(0x02, 0xa0), 0x01)
  dup3
  and
  swap1
  0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b
  swap1
  0x00
  swap1
  log2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1836:1988  function _upgradeTo(address newImplementation) internal {... */
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6223:6421  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {... */
tag_24:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6306:6318  bytes memory */
  0x60
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
  tag_36
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6358:6364  target */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6366:6370  data */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
  mload(0x40)
  dup1
  0x60
  add
  0x40
  mstore
  dup1
  0x27
  dup2
  mstore
  0x20
  add
  data_9fdcd12e4b726339b32a442b0a448365d5d85c96b2d2cff917b4f66c63110398
  0x27
  swap2
  codecopy
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6357  functionDelegateCall */
  0x0100000000
  tag_37
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
  div
  jump	// in
tag_36:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6330:6414  return functionDelegateCall(target, data, "Address: low-level delegate call failed") */
  swap4
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6223:6421  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {... */
  swap3
  pop
  pop
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4327:4449  function _getAdmin() internal view returns (address) {... */
tag_27:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4371:4378  address */
  0x00
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4436  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
  tag_39
  0x00
  dup1
  mload
  0x20
  data_52df0bdf5a5f92d8037cf11e50f13d8017aefc99d20a73c826416df79570d481
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4423  StorageSlot.getAddressSlot */
  0x0100000000
  tag_0_50
  tag_40
  dup3
  mul
  or
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4436  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
  div
  jump	// in
tag_39:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4442  StorageSlot.getAddressSlot(_ADMIN_SLOT).value */
  sload
  sub(exp(0x02, 0xa0), 0x01)
  and
  swap2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4327:4449  function _getAdmin() internal view returns (address) {... */
  swap1
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4531:4732  function _setAdmin(address newAdmin) private {... */
tag_31:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4594:4616  newAdmin != address(0) */
  dup2
  and
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
  tag_42
  jumpi
  mload(0x40)
  0x08c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
    /* "#utility.yul":2690:2692   */
  0x20
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
  0x04
  dup3
  add
    /* "#utility.yul":2672:2693   */
  mstore
    /* "#utility.yul":2729:2731   */
  0x26
    /* "#utility.yul":2709:2727   */
  0x24
  dup3
  add
    /* "#utility.yul":2702:2732   */
  mstore
    /* "#utility.yul":2768:2802   */
  0x455243313936373a206e65772061646d696e20697320746865207a65726f2061
    /* "#utility.yul":2748:2766   */
  0x44
  dup3
  add
    /* "#utility.yul":2741:2803   */
  mstore
    /* "#utility.yul":2839:2847   */
  0x6464726573730000000000000000000000000000000000000000000000000000
    /* "#utility.yul":2819:2837   */
  0x64
  dup3
  add
    /* "#utility.yul":2812:2848   */
  mstore
    /* "#utility.yul":2865:2884   */
  0x84
  add
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
tag_43:
  mload(0x40)
  dup1
  swap2
  sub
  swap1
  revert
tag_42:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4717:4725  newAdmin */
  dup1
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4669:4708  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
  tag_45
  0x00
  dup1
  mload
  0x20
  data_52df0bdf5a5f92d8037cf11e50f13d8017aefc99d20a73c826416df79570d481
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4669:4695  StorageSlot.getAddressSlot */
  0x0100000000
  tag_0_50
  tag_40
  dup3
  mul
  or
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4669:4708  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
  div
  jump	// in
tag_45:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4669:4725  StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin */
  dup1
  sload
  not(sub(exp(0x02, 0xa0), 0x01))
  and
  sub(exp(0x02, 0xa0), 0x01)
  swap3
  swap1
  swap3
  and
  swap2
  swap1
  swap2
  or
  swap1
  sstore
  pop
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4531:4732  function _setAdmin(address newAdmin) private {... */
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1471:1730  function _setImplementation(address newImplementation) private {... */
tag_34:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1552:1589  Address.isContract(newImplementation) */
  tag_47
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1571:1588  newImplementation */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1552:1570  Address.isContract */
  0x0100000000
  tag_0_51
  tag_48
  dup3
  mul
  or
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1552:1589  Address.isContract(newImplementation) */
  div
  jump	// in
tag_47:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
  tag_49
  jumpi
  mload(0x40)
  0x08c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
    /* "#utility.yul":3097:3099   */
  0x20
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
  0x04
  dup3
  add
    /* "#utility.yul":3079:3100   */
  mstore
    /* "#utility.yul":3136:3138   */
  0x2d
    /* "#utility.yul":3116:3134   */
  0x24
  dup3
  add
    /* "#utility.yul":3109:3139   */
  mstore
    /* "#utility.yul":3175:3209   */
  0x455243313936373a206e657720696d706c656d656e746174696f6e206973206e
    /* "#utility.yul":3155:3173   */
  0x44
  dup3
  add
    /* "#utility.yul":3148:3210   */
  mstore
    /* "#utility.yul":3246:3261   */
  0x6f74206120636f6e747261637400000000000000000000000000000000000000
    /* "#utility.yul":3226:3244   */
  0x64
  dup3
  add
    /* "#utility.yul":3219:3262   */
  mstore
    /* "#utility.yul":3279:3298   */
  0x84
  add
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
  tag_43
    /* "#utility.yul":2895:3304   */
  jump
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
tag_49:
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1706:1723  newImplementation */
  dup1
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1649:1697  StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT) */
  tag_45
  0x00
  dup1
  mload
  0x20
  data_75b20eef8615de99c108b05f0dbda081c91897128caa336d75dffb97c4132b4d
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1649:1675  StorageSlot.getAddressSlot */
  0x0100000000
  tag_0_50
  tag_40
  dup3
  mul
  or
    /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1649:1697  StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT) */
  div
  jump	// in
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6607:6994  function functionDelegateCall(... */
tag_37:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6748:6760  bytes memory */
  0x60
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6780:6798  isContract(target) */
  tag_54
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6791:6797  target */
  dup5
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6780:6790  isContract */
  0x0100000000
  tag_48
  dup2
  mul
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6780:6798  isContract(target) */
  div
  jump	// in
tag_54:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
  tag_55
  jumpi
  mload(0x40)
  0x08c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
    /* "#utility.yul":3511:3513   */
  0x20
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
  0x04
  dup3
  add
    /* "#utility.yul":3493:3514   */
  mstore
    /* "#utility.yul":3550:3552   */
  0x26
    /* "#utility.yul":3530:3548   */
  0x24
  dup3
  add
    /* "#utility.yul":3523:3553   */
  mstore
    /* "#utility.yul":3589:3623   */
  0x416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f
    /* "#utility.yul":3569:3587   */
  0x44
  dup3
  add
    /* "#utility.yul":3562:3624   */
  mstore
    /* "#utility.yul":3660:3668   */
  0x6e74726163740000000000000000000000000000000000000000000000000000
    /* "#utility.yul":3640:3658   */
  0x64
  dup3
  add
    /* "#utility.yul":3633:3669   */
  mstore
    /* "#utility.yul":3686:3705   */
  0x84
  add
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
  tag_43
    /* "#utility.yul":3309:3711   */
  jump
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
tag_55:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6853:6865  bool success */
  0x00
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6867:6890  bytes memory returndata */
  dup1
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6900  target */
  dup6
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6913  target.delegatecall */
  and
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6914:6918  data */
  dup6
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6919  target.delegatecall(data) */
  mload(0x40)
  tag_58
  swap2
  swap1
  tag_59
  jump	// in
tag_58:
  0x00
  mload(0x40)
  dup1
  dup4
  sub
  dup2
  dup6
  gas
  delegatecall
  swap2
  pop
  pop
  returndatasize
  dup1
  0x00
  dup2
  eq
  tag_62
  jumpi
  mload(0x40)
  swap2
  pop
  and(add(returndatasize, 0x3f), not(0x1f))
  dup3
  add
  0x40
  mstore
  returndatasize
  dup3
  mstore
  returndatasize
  0x00
  0x20
  dup5
  add
  returndatacopy
  jump(tag_61)
tag_62:
  0x60
  swap2
  pop
tag_61:
  pop
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6852:6919  (bool success, bytes memory returndata) = target.delegatecall(data) */
  swap2
  pop
  swap2
  pop
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6987  verifyCallResult(success, returndata, errorMessage) */
  tag_63
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6953:6960  success */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6962:6972  returndata */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6974:6986  errorMessage */
  dup7
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6952  verifyCallResult */
  mul(0x0100000000, tag_64)
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6987  verifyCallResult(success, returndata, errorMessage) */
  0x0100000000
  swap1
  div
  jump	// in
tag_63:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6929:6987  return verifyCallResult(success, returndata, errorMessage) */
  swap7
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6607:6994  function functionDelegateCall(... */
  swap6
  pop
  pop
  pop
  pop
  pop
  pop
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
tag_40:
    /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1726:1730  slot */
  swap1
    /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":771:1148  function isContract(address account) internal view returns (bool) {... */
tag_48:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1087:1107  extcodesize(account) */
  extcodesize
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1133:1141  size > 0 */
  iszero
  iszero
  swap1
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":771:1148  function isContract(address account) internal view returns (bool) {... */
  jump	// out
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7214:7906  function verifyCallResult(... */
tag_64:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7360:7372  bytes memory */
  0x60
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7388:7395  success */
  dup4
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7384:7900  if (success) {... */
  iszero
  tag_68
  jumpi
  pop
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7418:7428  returndata */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7411:7428  return returndata */
  jump(tag_36)
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7384:7900  if (success) {... */
tag_68:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7529:7546  returndata.length */
  dup3
  mload
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7529:7550  returndata.length > 0 */
  iszero
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7525:7890  if (returndata.length > 0) {... */
  tag_70
  jumpi
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7723:7733  returndata */
  dup3
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7717:7734  mload(returndata) */
  mload
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7783:7798  returndata_size */
  dup1
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7770:7780  returndata */
  dup5
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7766:7768  32 */
  0x20
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7762:7781  add(32, returndata) */
  add
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7755:7799  revert(add(32, returndata), returndata_size) */
  revert
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7525:7890  if (returndata.length > 0) {... */
tag_70:
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7862:7874  errorMessage */
  dup2
    /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7855:7875  revert(errorMessage) */
  mload(0x40)
  0x08c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
  0x04
  add
  tag_43
  swap2
  swap1
  tag_73
  jump	// in
    /* "#utility.yul":14:191   */
tag_74:
    /* "#utility.yul":93:106   */
  dup1
  mload
  sub(exp(0x02, 0xa0), 0x01)
    /* "#utility.yul":135:166   */
  dup2
  and
    /* "#utility.yul":125:167   */
  dup2
  eq
    /* "#utility.yul":115:185   */
  tag_79
  jumpi
    /* "#utility.yul":181:182   */
  0x00
    /* "#utility.yul":178:179   */
  dup1
    /* "#utility.yul":171:183   */
  revert
    /* "#utility.yul":115:185   */
tag_79:
    /* "#utility.yul":14:191   */
  swap2
  swap1
  pop
  jump	// out
    /* "#utility.yul":196:380   */
tag_75:
    /* "#utility.yul":248:325   */
  0x4e487b7100000000000000000000000000000000000000000000000000000000
    /* "#utility.yul":245:246   */
  0x00
    /* "#utility.yul":238:326   */
  mstore
    /* "#utility.yul":345:349   */
  0x41
    /* "#utility.yul":342:343   */
  0x04
    /* "#utility.yul":335:350   */
  mstore
    /* "#utility.yul":369:373   */
  0x24
    /* "#utility.yul":366:367   */
  0x00
    /* "#utility.yul":359:374   */
  revert
    /* "#utility.yul":385:643   */
tag_76:
    /* "#utility.yul":457:458   */
  0x00
    /* "#utility.yul":467:580   */
tag_82:
    /* "#utility.yul":481:487   */
  dup4
    /* "#utility.yul":478:479   */
  dup2
    /* "#utility.yul":475:488   */
  lt
    /* "#utility.yul":467:580   */
  iszero
  tag_84
  jumpi
    /* "#utility.yul":557:568   */
  dup2
  dup2
  add
    /* "#utility.yul":551:569   */
  mload
    /* "#utility.yul":538:549   */
  dup4
  dup3
  add
    /* "#utility.yul":531:570   */
  mstore
    /* "#utility.yul":503:505   */
  0x20
    /* "#utility.yul":496:506   */
  add
    /* "#utility.yul":467:580   */
  jump(tag_82)
tag_84:
    /* "#utility.yul":598:604   */
  dup4
    /* "#utility.yul":595:596   */
  dup2
    /* "#utility.yul":592:605   */
  gt
    /* "#utility.yul":589:637   */
  iszero
  tag_23
  jumpi
  pop
  pop
    /* "#utility.yul":633:634   */
  0x00
    /* "#utility.yul":615:631   */
  swap2
  add
    /* "#utility.yul":608:635   */
  mstore
    /* "#utility.yul":385:643   */
  jump	// out
    /* "#utility.yul":648:1701   */
tag_3:
    /* "#utility.yul":745:751   */
  0x00
    /* "#utility.yul":753:759   */
  dup1
    /* "#utility.yul":761:767   */
  0x00
    /* "#utility.yul":814:816   */
  0x60
    /* "#utility.yul":802:811   */
  dup5
    /* "#utility.yul":793:800   */
  dup7
    /* "#utility.yul":789:812   */
  sub
    /* "#utility.yul":785:817   */
  slt
    /* "#utility.yul":782:834   */
  iszero
  tag_87
  jumpi
    /* "#utility.yul":830:831   */
  0x00
    /* "#utility.yul":827:828   */
  dup1
    /* "#utility.yul":820:832   */
  revert
    /* "#utility.yul":782:834   */
tag_87:
    /* "#utility.yul":853:893   */
  tag_88
    /* "#utility.yul":883:892   */
  dup5
    /* "#utility.yul":853:893   */
  tag_74
  jump	// in
tag_88:
    /* "#utility.yul":843:893   */
  swap3
  pop
    /* "#utility.yul":912:961   */
  tag_89
    /* "#utility.yul":957:959   */
  0x20
    /* "#utility.yul":946:955   */
  dup6
    /* "#utility.yul":942:960   */
  add
    /* "#utility.yul":912:961   */
  tag_74
  jump	// in
tag_89:
    /* "#utility.yul":902:961   */
  swap2
  pop
    /* "#utility.yul":1005:1007   */
  0x40
    /* "#utility.yul":994:1003   */
  dup5
    /* "#utility.yul":990:1008   */
  add
    /* "#utility.yul":984:1009   */
  mload
    /* "#utility.yul":1028:1046   */
  0xffffffffffffffff
    /* "#utility.yul":1069:1071   */
  dup1
    /* "#utility.yul":1061:1067   */
  dup3
    /* "#utility.yul":1058:1072   */
  gt
    /* "#utility.yul":1055:1089   */
  iszero
  tag_90
  jumpi
    /* "#utility.yul":1085:1086   */
  0x00
    /* "#utility.yul":1082:1083   */
  dup1
    /* "#utility.yul":1075:1087   */
  revert
    /* "#utility.yul":1055:1089   */
tag_90:
    /* "#utility.yul":1123:1129   */
  dup2
    /* "#utility.yul":1112:1121   */
  dup7
    /* "#utility.yul":1108:1130   */
  add
    /* "#utility.yul":1098:1130   */
  swap2
  pop
    /* "#utility.yul":1168:1175   */
  dup7
    /* "#utility.yul":1161:1165   */
  0x1f
    /* "#utility.yul":1157:1159   */
  dup4
    /* "#utility.yul":1153:1166   */
  add
    /* "#utility.yul":1149:1176   */
  slt
    /* "#utility.yul":1139:1194   */
  tag_91
  jumpi
    /* "#utility.yul":1190:1191   */
  0x00
    /* "#utility.yul":1187:1188   */
  dup1
    /* "#utility.yul":1180:1192   */
  revert
    /* "#utility.yul":1139:1194   */
tag_91:
    /* "#utility.yul":1219:1221   */
  dup2
    /* "#utility.yul":1213:1222   */
  mload
    /* "#utility.yul":1241:1243   */
  dup2
    /* "#utility.yul":1237:1239   */
  dup2
    /* "#utility.yul":1234:1244   */
  gt
    /* "#utility.yul":1231:1267   */
  iszero
  tag_93
  jumpi
    /* "#utility.yul":1247:1265   */
  tag_93
  tag_75
  jump	// in
tag_93:
    /* "#utility.yul":1322:1324   */
  0x40
    /* "#utility.yul":1316:1325   */
  mload
    /* "#utility.yul":1290:1292   */
  0x1f
    /* "#utility.yul":1376:1389   */
  dup3
  add
  not(0x1f)
    /* "#utility.yul":1372:1394   */
  swap1
  dup2
  and
    /* "#utility.yul":1396:1398   */
  0x3f
    /* "#utility.yul":1368:1399   */
  add
    /* "#utility.yul":1364:1404   */
  and
    /* "#utility.yul":1352:1405   */
  dup2
  add
  swap1
    /* "#utility.yul":1420:1438   */
  dup4
  dup3
  gt
    /* "#utility.yul":1440:1462   */
  dup2
  dup4
  lt
    /* "#utility.yul":1417:1463   */
  or
    /* "#utility.yul":1414:1486   */
  iszero
  tag_95
  jumpi
    /* "#utility.yul":1466:1484   */
  tag_95
  tag_75
  jump	// in
tag_95:
    /* "#utility.yul":1506:1516   */
  dup2
    /* "#utility.yul":1502:1504   */
  0x40
    /* "#utility.yul":1495:1517   */
  mstore
    /* "#utility.yul":1541:1543   */
  dup3
    /* "#utility.yul":1533:1539   */
  dup2
    /* "#utility.yul":1526:1544   */
  mstore
    /* "#utility.yul":1581:1588   */
  dup10
    /* "#utility.yul":1576:1578   */
  0x20
    /* "#utility.yul":1571:1573   */
  dup5
    /* "#utility.yul":1567:1569   */
  dup8
    /* "#utility.yul":1563:1574   */
  add
    /* "#utility.yul":1559:1579   */
  add
    /* "#utility.yul":1556:1589   */
  gt
    /* "#utility.yul":1553:1606   */
  iszero
  tag_96
  jumpi
    /* "#utility.yul":1602:1603   */
  0x00
    /* "#utility.yul":1599:1600   */
  dup1
    /* "#utility.yul":1592:1604   */
  revert
    /* "#utility.yul":1553:1606   */
tag_96:
    /* "#utility.yul":1615:1670   */
  tag_97
    /* "#utility.yul":1667:1669   */
  dup4
    /* "#utility.yul":1662:1664   */
  0x20
    /* "#utility.yul":1654:1660   */
  dup4
    /* "#utility.yul":1650:1665   */
  add
    /* "#utility.yul":1645:1647   */
  0x20
    /* "#utility.yul":1641:1643   */
  dup9
    /* "#utility.yul":1637:1648   */
  add
    /* "#utility.yul":1615:1670   */
  tag_76
  jump	// in
tag_97:
    /* "#utility.yul":1689:1695   */
  dup1
    /* "#utility.yul":1679:1695   */
  swap6
  pop
  pop
  pop
  pop
  pop
  pop
    /* "#utility.yul":648:1701   */
  swap3
  pop
  swap3
  pop
  swap3
  jump	// out
    /* "#utility.yul":1706:1985   */
tag_8:
    /* "#utility.yul":1746:1750   */
  0x00
    /* "#utility.yul":1774:1775   */
  dup3
    /* "#utility.yul":1771:1772   */
  dup3
    /* "#utility.yul":1768:1776   */
  lt
    /* "#utility.yul":1765:1953   */
  iszero
  tag_99
  jumpi
    /* "#utility.yul":1809:1886   */
  0x4e487b7100000000000000000000000000000000000000000000000000000000
    /* "#utility.yul":1806:1807   */
  0x00
    /* "#utility.yul":1799:1887   */
  mstore
    /* "#utility.yul":1910:1914   */
  0x11
    /* "#utility.yul":1907:1908   */
  0x04
    /* "#utility.yul":1900:1915   */
  mstore
    /* "#utility.yul":1938:1942   */
  0x24
    /* "#utility.yul":1935:1936   */
  0x00
    /* "#utility.yul":1928:1943   */
  revert
    /* "#utility.yul":1765:1953   */
tag_99:
  pop
    /* "#utility.yul":1970:1979   */
  sub
  swap1
    /* "#utility.yul":1706:1985   */
  jump	// out
    /* "#utility.yul":1990:2174   */
tag_11:
    /* "#utility.yul":2042:2119   */
  0x4e487b7100000000000000000000000000000000000000000000000000000000
    /* "#utility.yul":2039:2040   */
  0x00
    /* "#utility.yul":2032:2120   */
  mstore
    /* "#utility.yul":2139:2143   */
  0x01
    /* "#utility.yul":2136:2137   */
  0x04
    /* "#utility.yul":2129:2144   */
  mstore
    /* "#utility.yul":2163:2167   */
  0x24
    /* "#utility.yul":2160:2161   */
  0x00
    /* "#utility.yul":2153:2168   */
  revert
    /* "#utility.yul":3716:3990   */
tag_59:
    /* "#utility.yul":3845:3848   */
  0x00
    /* "#utility.yul":3883:3889   */
  dup3
    /* "#utility.yul":3877:3890   */
  mload
    /* "#utility.yul":3899:3952   */
  tag_106
    /* "#utility.yul":3945:3951   */
  dup2
    /* "#utility.yul":3940:3943   */
  dup5
    /* "#utility.yul":3933:3937   */
  0x20
    /* "#utility.yul":3925:3931   */
  dup8
    /* "#utility.yul":3921:3938   */
  add
    /* "#utility.yul":3899:3952   */
  tag_76
  jump	// in
tag_106:
    /* "#utility.yul":3968:3984   */
  swap2
  swap1
  swap2
  add
  swap3
    /* "#utility.yul":3716:3990   */
  swap2
  pop
  pop
  jump	// out
    /* "#utility.yul":3995:4378   */
tag_73:
    /* "#utility.yul":4144:4146   */
  0x20
    /* "#utility.yul":4133:4142   */
  dup2
    /* "#utility.yul":4126:4147   */
  mstore
    /* "#utility.yul":4107:4111   */
  0x00
    /* "#utility.yul":4176:4182   */
  dup3
    /* "#utility.yul":4170:4183   */
  mload
    /* "#utility.yul":4219:4225   */
  dup1
    /* "#utility.yul":4214:4216   */
  0x20
    /* "#utility.yul":4203:4212   */
  dup5
    /* "#utility.yul":4199:4217   */
  add
    /* "#utility.yul":4192:4226   */
  mstore
    /* "#utility.yul":4235:4301   */
  tag_108
    /* "#utility.yul":4294:4300   */
  dup2
    /* "#utility.yul":4289:4291   */
  0x40
    /* "#utility.yul":4278:4287   */
  dup6
    /* "#utility.yul":4274:4292   */
  add
    /* "#utility.yul":4269:4271   */
  0x20
    /* "#utility.yul":4261:4267   */
  dup8
    /* "#utility.yul":4257:4272   */
  add
    /* "#utility.yul":4235:4301   */
  tag_76
  jump	// in
tag_108:
    /* "#utility.yul":4362:4364   */
  0x1f
    /* "#utility.yul":4341:4356   */
  add
  not(0x1f)
    /* "#utility.yul":4337:4366   */
  and
    /* "#utility.yul":4322:4367   */
  swap2
  swap1
  swap2
  add
    /* "#utility.yul":4369:4371   */
  0x40
    /* "#utility.yul":4318:4372   */
  add
  swap3
    /* "#utility.yul":3995:4378   */
  swap2
  pop
  pop
  jump	// out
tag_77:
    /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":503:3515  contract OssifiableProxy is ERC1967Proxy {... */
  dataSize(sub_0)
  dup1
  dataOffset(sub_0)
  0x00
  codecopy
  0x00
  return
stop
data_52df0bdf5a5f92d8037cf11e50f13d8017aefc99d20a73c826416df79570d481 b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
data_75b20eef8615de99c108b05f0dbda081c91897128caa336d75dffb97c4132b4d 360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
data_9fdcd12e4b726339b32a442b0a448365d5d85c96b2d2cff917b4f66c63110398 416464726573733a206c6f772d6c6576656c2064656c65676174652063616c6c206661696c6564

sub_0: assembly {
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":503:3515  contract OssifiableProxy is ERC1967Proxy {... */
      mstore(0x40, 0x80)
      jumpi(tag_1, lt(calldatasize, 0x04))
      calldataload(0x00)
      0x0100000000000000000000000000000000000000000000000000000000
      swap1
      div
      dup1
      0x916f1fd7
      gt
      tag_10
      jumpi
      dup1
      0x916f1fd7
      eq
      tag_6
      jumpi
      dup1
      0xad729a71
      eq
      tag_7
      jumpi
      dup1
      0xadcbc237
      eq
      tag_8
      jumpi
      dup1
      0xd2f6ed4d
      eq
      tag_9
      jumpi
      jump(tag_2)
    tag_10:
      dup1
      0x13351258
      eq
      tag_3
      jumpi
      dup1
      0x3ebdd0eb
      eq
      tag_4
      jumpi
      dup1
      0x773f5be8
      eq
      tag_5
      jumpi
      jump(tag_2)
    tag_1:
      jumpi(tag_2, calldatasize)
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2884:2895  _fallback() */
      tag_13
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2884:2893  _fallback */
      tag_14
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2884:2895  _fallback() */
      jump	// in
    tag_13:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":503:3515  contract OssifiableProxy is ERC1967Proxy {... */
      stop
    tag_2:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2661:2672  _fallback() */
      tag_13
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2661:2670  _fallback */
      tag_14
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2661:2672  _fallback() */
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1479:1589  function proxy__getIsOssified() external view returns (bool) {... */
    tag_3:
      callvalue
      dup1
      iszero
      tag_18
      jumpi
      0x00
      dup1
      revert
    tag_18:
      pop
      tag_19
      tag_20
      jump	// in
    tag_19:
      mload(0x40)
        /* "#utility.yul":179:193   */
      swap1
      iszero
        /* "#utility.yul":172:194   */
      iszero
        /* "#utility.yul":154:195   */
      dup2
      mstore
        /* "#utility.yul":142:144   */
      0x20
        /* "#utility.yul":127:145   */
      add
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1479:1589  function proxy__getIsOssified() external view returns (bool) {... */
    tag_21:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2292:2412  function proxy__upgradeTo(address newImplementation_) external onlyAdmin {... */
    tag_4:
      callvalue
      dup1
      iszero
      tag_23
      jumpi
      0x00
      dup1
      revert
    tag_23:
      pop
      tag_13
      tag_25
      calldatasize
      0x04
      tag_26
      jump	// in
    tag_25:
      tag_27
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2055:2161  function proxy__changeAdmin(address newAdmin_) external onlyAdmin {... */
    tag_5:
      callvalue
      dup1
      iszero
      tag_28
      jumpi
      0x00
      dup1
      revert
    tag_28:
      pop
      tag_13
      tag_30
      calldatasize
      0x04
      tag_26
      jump	// in
    tag_30:
      tag_31
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1136:1230  function proxy__getAdmin() external view returns (address) {... */
    tag_6:
      callvalue
      dup1
      iszero
      tag_32
      jumpi
      0x00
      dup1
      revert
    tag_32:
      pop
      tag_33
      tag_34
      jump	// in
    tag_33:
      mload(0x40)
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":762:817   */
      swap1
      swap2
      and
        /* "#utility.yul":744:818   */
      dup2
      mstore
        /* "#utility.yul":732:734   */
      0x20
        /* "#utility.yul":717:735   */
      add
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1136:1230  function proxy__getAdmin() external view returns (address) {... */
      tag_21
        /* "#utility.yul":598:824   */
      jump
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1295:1404  function proxy__getImplementation() external view returns (address) {... */
    tag_7:
      callvalue
      dup1
      iszero
      tag_37
      jumpi
      0x00
      dup1
      revert
    tag_37:
      pop
      tag_33
      tag_39
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1712:1952  function proxy__ossify() external onlyAdmin {... */
    tag_8:
      callvalue
      dup1
      iszero
      tag_41
      jumpi
      0x00
      dup1
      revert
    tag_41:
      pop
      tag_13
      tag_43
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2840:3078  function proxy__upgradeToAndCall(... */
    tag_9:
      callvalue
      dup1
      iszero
      tag_44
      jumpi
      0x00
      dup1
      revert
    tag_44:
      pop
      tag_13
      tag_46
      calldatasize
      0x04
      tag_47
      jump	// in
    tag_46:
      tag_48
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2308:2418  function _fallback() internal virtual {... */
    tag_14:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2383:2411  _delegate(_implementation()) */
      tag_55
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2393:2410  _implementation() */
      tag_56
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2393:2408  _implementation */
      tag_57
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2393:2410  _implementation() */
      jump	// in
    tag_56:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2383:2392  _delegate */
      tag_58
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2383:2411  _delegate(_implementation()) */
      jump	// in
    tag_55:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":2308:2418  function _fallback() internal virtual {... */
      jump	// out
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1479:1589  function proxy__getIsOssified() external view returns (bool) {... */
    tag_20:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1534:1538  bool */
      0x00
      dup1
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1557:1568  _getAdmin() */
      tag_60
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1557:1566  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1557:1568  _getAdmin() */
      jump	// in
    tag_60:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1557:1582  _getAdmin() == address(0) */
      and
      eq
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1550:1582  return _getAdmin() == address(0) */
      swap1
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1479:1589  function proxy__getIsOssified() external view returns (bool) {... */
      swap1
      jump	// out
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2292:2412  function proxy__upgradeTo(address newImplementation_) external onlyAdmin {... */
    tag_27:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3242  address admin */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      tag_63
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3254  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      jump	// in
    tag_63:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3256  address admin = _getAdmin() */
      swap1
      pop
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3270:3289  admin == address(0) */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
      tag_64
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3312:3329  ProxyIsOssified() */
      mload(0x40)
      mul(0xb83646a9, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
    tag_64:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3362:3372  msg.sender */
      caller
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      eq
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
      tag_65
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3395:3405  NotAdmin() */
      mload(0x40)
      mul(0x7bfa4b9f, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
    tag_65:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2375:2405  _upgradeTo(newImplementation_) */
      tag_67
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2386:2404  newImplementation_ */
      dup3
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2375:2385  _upgradeTo */
      tag_68
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2375:2405  _upgradeTo(newImplementation_) */
      jump	// in
    tag_67:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3219:3433  {... */
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2292:2412  function proxy__upgradeTo(address newImplementation_) external onlyAdmin {... */
      pop
      jump	// out
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2055:2161  function proxy__changeAdmin(address newAdmin_) external onlyAdmin {... */
    tag_31:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3242  address admin */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      tag_70
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3254  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      jump	// in
    tag_70:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3256  address admin = _getAdmin() */
      swap1
      pop
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3270:3289  admin == address(0) */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
      tag_71
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3312:3329  ProxyIsOssified() */
      mload(0x40)
      mul(0xb83646a9, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
    tag_71:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3362:3372  msg.sender */
      caller
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      eq
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
      tag_72
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3395:3405  NotAdmin() */
      mload(0x40)
      mul(0x7bfa4b9f, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
    tag_72:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2131:2154  _changeAdmin(newAdmin_) */
      tag_67
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2144:2153  newAdmin_ */
      dup3
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2131:2143  _changeAdmin */
      tag_75
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2131:2154  _changeAdmin(newAdmin_) */
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1136:1230  function proxy__getAdmin() external view returns (address) {... */
    tag_34:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1186:1193  address */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1212:1223  _getAdmin() */
      tag_77
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1212:1221  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1212:1223  _getAdmin() */
      jump	// in
    tag_77:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1205:1223  return _getAdmin() */
      swap1
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1136:1230  function proxy__getAdmin() external view returns (address) {... */
      swap1
      jump	// out
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1295:1404  function proxy__getImplementation() external view returns (address) {... */
    tag_39:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1354:1361  address */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1380:1397  _implementation() */
      tag_77
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1380:1395  _implementation */
      tag_57
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1380:1397  _implementation() */
      jump	// in
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1712:1952  function proxy__ossify() external onlyAdmin {... */
    tag_43:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3242  address admin */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      tag_81
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3254  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      jump	// in
    tag_81:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3256  address admin = _getAdmin() */
      swap1
      pop
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3270:3289  admin == address(0) */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
      tag_82
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3312:3329  ProxyIsOssified() */
      mload(0x40)
      mul(0xb83646a9, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
    tag_82:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3362:3372  msg.sender */
      caller
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      eq
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
      tag_83
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3395:3405  NotAdmin() */
      mload(0x40)
      mul(0x7bfa4b9f, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
    tag_83:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1766:1783  address prevAdmin */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1786:1797  _getAdmin() */
      tag_85
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1786:1795  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1786:1797  _getAdmin() */
      jump	// in
    tag_85:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4061:4127  0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 */
      0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1807:1865  StorageSlot.getAddressSlot(_ADMIN_SLOT).value = address(0) */
      dup1
      sload
      not(0xffffffffffffffffffffffffffffffffffffffff)
      and
      swap1
      sstore
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1880:1915  AdminChanged(prevAdmin, address(0)) */
      0x40
      dup1
      mload
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":2504:2519   */
      dup4
      and
        /* "#utility.yul":2486:2520   */
      dup2
      mstore
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1863:1864  0 */
      0x00
        /* "#utility.yul":2551:2553   */
      0x20
        /* "#utility.yul":2536:2554   */
      dup3
      add
        /* "#utility.yul":2529:2572   */
      mstore
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1880:1915  AdminChanged(prevAdmin, address(0)) */
      dup2
      mload
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1766:1797  address prevAdmin = _getAdmin() */
      swap3
      swap4
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1880:1915  AdminChanged(prevAdmin, address(0)) */
      0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f
      swap3
      swap1
      dup2
      swap1
      sub
      swap1
      swap2
      add
      swap1
      log1
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1930:1945  ProxyOssified() */
      mload(0x40)
      0x158b204828f9326d9bb3c2be9336986c14911b4a72b93d1801f207aac3c68b9f
      swap1
      0x00
      swap1
      log1
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1756:1952  {... */
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3219:3433  {... */
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":1712:1952  function proxy__ossify() external onlyAdmin {... */
      jump	// out
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2840:3078  function proxy__upgradeToAndCall(... */
    tag_48:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3242  address admin */
      0x00
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      tag_90
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3254  _getAdmin */
      tag_61
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3245:3256  _getAdmin() */
      jump	// in
    tag_90:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3229:3256  address admin = _getAdmin() */
      swap1
      pop
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3270:3289  admin == address(0) */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
      tag_91
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3312:3329  ProxyIsOssified() */
      mload(0x40)
      mul(0xb83646a9, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3266:3340  if (admin == address(0)) {... */
    tag_91:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      dup2
      and
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3362:3372  msg.sender */
      caller
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3353:3372  admin != msg.sender */
      eq
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
      tag_92
      jumpi
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3395:3405  NotAdmin() */
      mload(0x40)
      mul(0x7bfa4b9f, exp(0x02, 0xe0))
      dup2
      mstore
      0x04
      add
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3349:3416  if (admin != msg.sender) {... */
    tag_92:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3006:3071  _upgradeToAndCall(newImplementation_, setupCalldata_, forceCall_) */
      tag_94
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3024:3042  newImplementation_ */
      dup5
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3044:3058  setupCalldata_ */
      dup5
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3060:3070  forceCall_ */
      dup5
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3006:3023  _upgradeToAndCall */
      tag_95
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3006:3071  _upgradeToAndCall(newImplementation_, setupCalldata_, forceCall_) */
      jump	// in
    tag_94:
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":3219:3433  {... */
      pop
        /* "src/contracts/0.8.9/proxy/OssifiableProxy.sol":2840:3078  function proxy__upgradeToAndCall(... */
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6223:6421  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {... */
    tag_49:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6306:6318  bytes memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
      tag_97
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6358:6364  target */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6366:6370  data */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
      0x27
      dup2
      mstore
      0x20
      add
      data_9fdcd12e4b726339b32a442b0a448365d5d85c96b2d2cff917b4f66c63110398
      0x27
      swap2
      codecopy
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6357  functionDelegateCall */
      tag_98
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6337:6414  functionDelegateCall(target, data, "Address: low-level delegate call failed") */
      jump	// in
    tag_97:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6330:6414  return functionDelegateCall(target, data, "Address: low-level delegate call failed") */
      swap4
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6223:6421  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
    tag_50:
        /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1726:1730  slot */
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":771:1148  function isContract(address account) internal view returns (bool) {... */
    tag_51:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1087:1107  extcodesize(account) */
      extcodesize
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1133:1141  size > 0 */
      iszero
      iszero
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":771:1148  function isContract(address account) internal view returns (bool) {... */
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1240:1380  function _implementation() internal view virtual override returns (address impl) {... */
    tag_57:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1307:1319  address impl */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1338:1373  ERC1967Upgrade._getImplementation() */
      tag_77
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1338:1371  ERC1967Upgrade._getImplementation */
      tag_104
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Proxy.sol":1338:1373  ERC1967Upgrade._getImplementation() */
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":934:1829  function _delegate(address implementation) internal virtual {... */
    tag_58:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1272:1286  calldatasize() */
      calldatasize
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1269:1270  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1266:1267  0 */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1253:1287  calldatacopy(0, 0, calldatasize()) */
      calldatacopy
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1486:1487  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1483:1484  0 */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1467:1481  calldatasize() */
      calldatasize
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1464:1465  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1448:1462  implementation */
      dup5
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1441:1446  gas() */
      gas
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1428:1488  delegatecall(gas(), implementation, 0, calldatasize(), 0, 0) */
      delegatecall
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1562:1578  returndatasize() */
      returndatasize
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1559:1560  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1556:1557  0 */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1541:1579  returndatacopy(0, 0, returndatasize()) */
      returndatacopy
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1600:1606  result */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1667:1733  case 0 {... */
      dup1
      iszero
      tag_107
      jumpi
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1782:1798  returndatasize() */
      returndatasize
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1779:1780  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1772:1799  return(0, returndatasize()) */
      return
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1667:1733  case 0 {... */
    tag_107:
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1702:1718  returndatasize() */
      returndatasize
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1699:1700  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1692:1719  revert(0, returndatasize()) */
      revert
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":1593:1813  switch result... */
    tag_106:
      pop
      pop
        /* "src/@openzeppelin/contracts-v4.4/proxy/Proxy.sol":934:1829  function _delegate(address implementation) internal virtual {... */
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4327:4449  function _getAdmin() internal view returns (address) {... */
    tag_61:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4371:4378  address */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4061:4127  0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 */
      0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4436  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
    tag_109:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4397:4442  StorageSlot.getAddressSlot(_ADMIN_SLOT).value */
      sload
      sub(exp(0x02, 0xa0), 0x01)
      and
      swap2
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4327:4449  function _getAdmin() internal view returns (address) {... */
      swap1
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1836:1988  function _upgradeTo(address newImplementation) internal {... */
    tag_68:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1939  _setImplementation(newImplementation) */
      tag_111
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1921:1938  newImplementation */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1920  _setImplementation */
      tag_112
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1902:1939  _setImplementation(newImplementation) */
      jump	// in
    tag_111:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1954:1981  Upgraded(newImplementation) */
      mload(0x40)
      sub(exp(0x02, 0xa0), 0x01)
      dup3
      and
      swap1
      0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b
      swap1
      0x00
      swap1
      log2
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1836:1988  function _upgradeTo(address newImplementation) internal {... */
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4843:4978  function _changeAdmin(address newAdmin) internal {... */
    tag_75:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
      0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4931  _getAdmin() */
      tag_114
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4929  _getAdmin */
      tag_61
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4920:4931  _getAdmin() */
      jump	// in
    tag_114:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
      0x40
      dup1
      mload
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":2504:2519   */
      swap3
      dup4
      and
        /* "#utility.yul":2486:2520   */
      dup2
      mstore
        /* "#utility.yul":2556:2571   */
      swap2
      dup5
      and
        /* "#utility.yul":2551:2553   */
      0x20
        /* "#utility.yul":2536:2554   */
      dup4
      add
        /* "#utility.yul":2529:2572   */
      mstore
        /* "#utility.yul":2398:2416   */
      add
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4907:4942  AdminChanged(_getAdmin(), newAdmin) */
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log1
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4971  _setAdmin(newAdmin) */
      tag_116
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4962:4970  newAdmin */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4961  _setAdmin */
      tag_117
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4952:4971  _setAdmin(newAdmin) */
      jump	// in
    tag_116:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4843:4978  function _changeAdmin(address newAdmin) internal {... */
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2122:2417  function _upgradeToAndCall(... */
    tag_95:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2289  _upgradeTo(newImplementation) */
      tag_119
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2271:2288  newImplementation */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2270  _upgradeTo */
      tag_68
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2260:2289  _upgradeTo(newImplementation) */
      jump	// in
    tag_119:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2317:2318  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2307  data */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2314  data.length */
      mload
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2318  data.length > 0 */
      gt
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2331  data.length > 0 || forceCall */
      dup1
      tag_120
      jumpi
      pop
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2322:2331  forceCall */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2303:2331  data.length > 0 || forceCall */
    tag_120:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2299:2411  if (data.length > 0 || forceCall) {... */
      iszero
      tag_106
      jumpi
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2400  Address.functionDelegateCall(newImplementation, data) */
      tag_94
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2376:2393  newImplementation */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2395:2399  data */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2375  Address.functionDelegateCall */
      tag_49
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":2347:2400  Address.functionDelegateCall(newImplementation, data) */
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6607:6994  function functionDelegateCall(... */
    tag_98:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6748:6760  bytes memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1087:1107  extcodesize(account) */
      dup4
      extcodesize
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
      tag_125
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x02, 0xe5))
      dup2
      mstore
        /* "#utility.yul":2785:2787   */
      0x20
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
      0x04
      dup3
      add
        /* "#utility.yul":2767:2788   */
      mstore
        /* "#utility.yul":2824:2826   */
      0x26
        /* "#utility.yul":2804:2822   */
      0x24
      dup3
      add
        /* "#utility.yul":2797:2827   */
      mstore
        /* "#utility.yul":2863:2897   */
      0x416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f
        /* "#utility.yul":2843:2861   */
      0x44
      dup3
      add
        /* "#utility.yul":2836:2898   */
      mstore
        /* "#utility.yul":2934:2942   */
      0x6e74726163740000000000000000000000000000000000000000000000000000
        /* "#utility.yul":2914:2932   */
      0x64
      dup3
      add
        /* "#utility.yul":2907:2943   */
      mstore
        /* "#utility.yul":2960:2979   */
      0x84
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6772:6841  require(isContract(target), "Address: delegate call to non-contract") */
    tag_126:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_125:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6853:6865  bool success */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6867:6890  bytes memory returndata */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6900  target */
      dup6
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6913  target.delegatecall */
      and
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6914:6918  data */
      dup6
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6894:6919  target.delegatecall(data) */
      mload(0x40)
      tag_128
      swap2
      swap1
      tag_129
      jump	// in
    tag_128:
      0x00
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup6
      gas
      delegatecall
      swap2
      pop
      pop
      returndatasize
      dup1
      0x00
      dup2
      eq
      tag_132
      jumpi
      mload(0x40)
      swap2
      pop
      and(add(returndatasize, 0x3f), not(0x1f))
      dup3
      add
      0x40
      mstore
      returndatasize
      dup3
      mstore
      returndatasize
      0x00
      0x20
      dup5
      add
      returndatacopy
      jump(tag_131)
    tag_132:
      0x60
      swap2
      pop
    tag_131:
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6852:6919  (bool success, bytes memory returndata) = target.delegatecall(data) */
      swap2
      pop
      swap2
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6987  verifyCallResult(success, returndata, errorMessage) */
      tag_133
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6953:6960  success */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6962:6972  returndata */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6974:6986  errorMessage */
      dup7
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6952  verifyCallResult */
      tag_134
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6936:6987  verifyCallResult(success, returndata, errorMessage) */
      jump	// in
    tag_133:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6929:6987  return verifyCallResult(success, returndata, errorMessage) */
      swap7
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":6607:6994  function functionDelegateCall(... */
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1240:1380  function _getImplementation() internal view returns (address) {... */
    tag_104:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1293:1300  address */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":969:1035  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc */
      0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1319:1367  StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT) */
      tag_109
        /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
      jump
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1471:1730  function _setImplementation(address newImplementation) private {... */
    tag_112:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":1087:1107  extcodesize(account) */
      dup1
      extcodesize
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
      tag_139
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x02, 0xe5))
      dup2
      mstore
        /* "#utility.yul":3734:3736   */
      0x20
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
      0x04
      dup3
      add
        /* "#utility.yul":3716:3737   */
      mstore
        /* "#utility.yul":3773:3775   */
      0x2d
        /* "#utility.yul":3753:3771   */
      0x24
      dup3
      add
        /* "#utility.yul":3746:3776   */
      mstore
        /* "#utility.yul":3812:3846   */
      0x455243313936373a206e657720696d706c656d656e746174696f6e206973206e
        /* "#utility.yul":3792:3810   */
      0x44
      dup3
      add
        /* "#utility.yul":3785:3847   */
      mstore
        /* "#utility.yul":3883:3898   */
      0x6f74206120636f6e747261637400000000000000000000000000000000000000
        /* "#utility.yul":3863:3881   */
      0x64
      dup3
      add
        /* "#utility.yul":3856:3899   */
      mstore
        /* "#utility.yul":3916:3935   */
      0x84
      add
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
      tag_126
        /* "#utility.yul":3532:3941   */
      jump
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1544:1639  require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract") */
    tag_139:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1706:1723  newImplementation */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":969:1035  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc */
      0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1649:1697  StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT) */
    tag_142:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1649:1723  StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation */
      dup1
      sload
      not(0xffffffffffffffffffffffffffffffffffffffff)
      and
      sub(exp(0x02, 0xa0), 0x01)
      swap3
      swap1
      swap3
      and
      swap2
      swap1
      swap2
      or
      swap1
      sstore
      pop
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":1471:1730  function _setImplementation(address newImplementation) private {... */
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4531:4732  function _setAdmin(address newAdmin) private {... */
    tag_117:
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4594:4616  newAdmin != address(0) */
      dup2
      and
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
      tag_144
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x02, 0xe5))
      dup2
      mstore
        /* "#utility.yul":4148:4150   */
      0x20
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
      0x04
      dup3
      add
        /* "#utility.yul":4130:4151   */
      mstore
        /* "#utility.yul":4187:4189   */
      0x26
        /* "#utility.yul":4167:4185   */
      0x24
      dup3
      add
        /* "#utility.yul":4160:4190   */
      mstore
        /* "#utility.yul":4226:4260   */
      0x455243313936373a206e65772061646d696e20697320746865207a65726f2061
        /* "#utility.yul":4206:4224   */
      0x44
      dup3
      add
        /* "#utility.yul":4199:4261   */
      mstore
        /* "#utility.yul":4297:4305   */
      0x6464726573730000000000000000000000000000000000000000000000000000
        /* "#utility.yul":4277:4295   */
      0x64
      dup3
      add
        /* "#utility.yul":4270:4306   */
      mstore
        /* "#utility.yul":4323:4342   */
      0x84
      add
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
      tag_126
        /* "#utility.yul":3946:4348   */
      jump
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4586:4659  require(newAdmin != address(0), "ERC1967: new admin is the zero address") */
    tag_144:
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4717:4725  newAdmin */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4061:4127  0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 */
      0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
        /* "src/@openzeppelin/contracts-v4.4/proxy/ERC1967/ERC1967Upgrade.sol":4669:4708  StorageSlot.getAddressSlot(_ADMIN_SLOT) */
      tag_142
        /* "src/@openzeppelin/contracts-v4.4/utils/StorageSlot.sol":1599:1746  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {... */
      jump
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7214:7906  function verifyCallResult(... */
    tag_134:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7360:7372  bytes memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7388:7395  success */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7384:7900  if (success) {... */
      iszero
      tag_149
      jumpi
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7418:7428  returndata */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7411:7428  return returndata */
      jump(tag_97)
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7384:7900  if (success) {... */
    tag_149:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7529:7546  returndata.length */
      dup3
      mload
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7529:7550  returndata.length > 0 */
      iszero
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7525:7890  if (returndata.length > 0) {... */
      tag_151
      jumpi
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7723:7733  returndata */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7717:7734  mload(returndata) */
      mload
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7783:7798  returndata_size */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7770:7780  returndata */
      dup5
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7766:7768  32 */
      0x20
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7762:7781  add(32, returndata) */
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7755:7799  revert(add(32, returndata), returndata_size) */
      revert
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7525:7890  if (returndata.length > 0) {... */
    tag_151:
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7862:7874  errorMessage */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Address.sol":7855:7875  revert(errorMessage) */
      mload(0x40)
      mul(0x461bcd, exp(0x02, 0xe5))
      dup2
      mstore
      0x04
      add
      tag_126
      swap2
      swap1
      tag_154
      jump	// in
        /* "#utility.yul":206:402   */
    tag_155:
        /* "#utility.yul":274:294   */
      dup1
      calldataload
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":323:377   */
      dup2
      and
        /* "#utility.yul":313:378   */
      dup2
      eq
        /* "#utility.yul":303:396   */
      tag_162
      jumpi
        /* "#utility.yul":392:393   */
      0x00
        /* "#utility.yul":389:390   */
      dup1
        /* "#utility.yul":382:394   */
      revert
        /* "#utility.yul":303:396   */
    tag_162:
        /* "#utility.yul":206:402   */
      swap2
      swap1
      pop
      jump	// out
        /* "#utility.yul":407:593   */
    tag_26:
        /* "#utility.yul":466:472   */
      0x00
        /* "#utility.yul":519:521   */
      0x20
        /* "#utility.yul":507:516   */
      dup3
        /* "#utility.yul":498:505   */
      dup5
        /* "#utility.yul":494:517   */
      sub
        /* "#utility.yul":490:522   */
      slt
        /* "#utility.yul":487:539   */
      iszero
      tag_164
      jumpi
        /* "#utility.yul":535:536   */
      0x00
        /* "#utility.yul":532:533   */
      dup1
        /* "#utility.yul":525:537   */
      revert
        /* "#utility.yul":487:539   */
    tag_164:
        /* "#utility.yul":558:587   */
      tag_97
        /* "#utility.yul":577:586   */
      dup3
        /* "#utility.yul":558:587   */
      tag_155
      jump	// in
        /* "#utility.yul":829:1013   */
    tag_156:
        /* "#utility.yul":881:958   */
      0x4e487b7100000000000000000000000000000000000000000000000000000000
        /* "#utility.yul":878:879   */
      0x00
        /* "#utility.yul":871:959   */
      mstore
        /* "#utility.yul":978:982   */
      0x41
        /* "#utility.yul":975:976   */
      0x04
        /* "#utility.yul":968:983   */
      mstore
        /* "#utility.yul":1002:1006   */
      0x24
        /* "#utility.yul":999:1000   */
      0x00
        /* "#utility.yul":992:1007   */
      revert
        /* "#utility.yul":1018:1178   */
    tag_157:
        /* "#utility.yul":1083:1103   */
      dup1
      calldataload
        /* "#utility.yul":1139:1152   */
      dup1
      iszero
        /* "#utility.yul":1132:1153   */
      iszero
        /* "#utility.yul":1122:1154   */
      dup2
      eq
        /* "#utility.yul":1112:1172   */
      tag_162
      jumpi
        /* "#utility.yul":1168:1169   */
      0x00
        /* "#utility.yul":1165:1166   */
      dup1
        /* "#utility.yul":1158:1170   */
      revert
        /* "#utility.yul":1183:2246   */
    tag_47:
        /* "#utility.yul":1266:1272   */
      0x00
        /* "#utility.yul":1274:1280   */
      dup1
        /* "#utility.yul":1282:1288   */
      0x00
        /* "#utility.yul":1335:1337   */
      0x60
        /* "#utility.yul":1323:1332   */
      dup5
        /* "#utility.yul":1314:1321   */
      dup7
        /* "#utility.yul":1310:1333   */
      sub
        /* "#utility.yul":1306:1338   */
      slt
        /* "#utility.yul":1303:1355   */
      iszero
      tag_171
      jumpi
        /* "#utility.yul":1351:1352   */
      0x00
        /* "#utility.yul":1348:1349   */
      dup1
        /* "#utility.yul":1341:1353   */
      revert
        /* "#utility.yul":1303:1355   */
    tag_171:
        /* "#utility.yul":1374:1403   */
      tag_172
        /* "#utility.yul":1393:1402   */
      dup5
        /* "#utility.yul":1374:1403   */
      tag_155
      jump	// in
    tag_172:
        /* "#utility.yul":1364:1403   */
      swap3
      pop
        /* "#utility.yul":1454:1456   */
      0x20
        /* "#utility.yul":1443:1452   */
      dup5
        /* "#utility.yul":1439:1457   */
      add
        /* "#utility.yul":1426:1458   */
      calldataload
        /* "#utility.yul":1477:1495   */
      0xffffffffffffffff
        /* "#utility.yul":1518:1520   */
      dup1
        /* "#utility.yul":1510:1516   */
      dup3
        /* "#utility.yul":1507:1521   */
      gt
        /* "#utility.yul":1504:1538   */
      iszero
      tag_173
      jumpi
        /* "#utility.yul":1534:1535   */
      0x00
        /* "#utility.yul":1531:1532   */
      dup1
        /* "#utility.yul":1524:1536   */
      revert
        /* "#utility.yul":1504:1538   */
    tag_173:
        /* "#utility.yul":1572:1578   */
      dup2
        /* "#utility.yul":1561:1570   */
      dup7
        /* "#utility.yul":1557:1579   */
      add
        /* "#utility.yul":1547:1579   */
      swap2
      pop
        /* "#utility.yul":1617:1624   */
      dup7
        /* "#utility.yul":1610:1614   */
      0x1f
        /* "#utility.yul":1606:1608   */
      dup4
        /* "#utility.yul":1602:1615   */
      add
        /* "#utility.yul":1598:1625   */
      slt
        /* "#utility.yul":1588:1643   */
      tag_174
      jumpi
        /* "#utility.yul":1639:1640   */
      0x00
        /* "#utility.yul":1636:1637   */
      dup1
        /* "#utility.yul":1629:1641   */
      revert
        /* "#utility.yul":1588:1643   */
    tag_174:
        /* "#utility.yul":1675:1677   */
      dup2
        /* "#utility.yul":1662:1678   */
      calldataload
        /* "#utility.yul":1697:1699   */
      dup2
        /* "#utility.yul":1693:1695   */
      dup2
        /* "#utility.yul":1690:1700   */
      gt
        /* "#utility.yul":1687:1723   */
      iszero
      tag_176
      jumpi
        /* "#utility.yul":1703:1721   */
      tag_176
      tag_156
      jump	// in
    tag_176:
        /* "#utility.yul":1778:1780   */
      0x40
        /* "#utility.yul":1772:1781   */
      mload
        /* "#utility.yul":1746:1748   */
      0x1f
        /* "#utility.yul":1832:1845   */
      dup3
      add
      not(0x1f)
        /* "#utility.yul":1828:1850   */
      swap1
      dup2
      and
        /* "#utility.yul":1852:1854   */
      0x3f
        /* "#utility.yul":1824:1855   */
      add
        /* "#utility.yul":1820:1860   */
      and
        /* "#utility.yul":1808:1861   */
      dup2
      add
      swap1
        /* "#utility.yul":1876:1894   */
      dup4
      dup3
      gt
        /* "#utility.yul":1896:1918   */
      dup2
      dup4
      lt
        /* "#utility.yul":1873:1919   */
      or
        /* "#utility.yul":1870:1942   */
      iszero
      tag_178
      jumpi
        /* "#utility.yul":1922:1940   */
      tag_178
      tag_156
      jump	// in
    tag_178:
        /* "#utility.yul":1962:1972   */
      dup2
        /* "#utility.yul":1958:1960   */
      0x40
        /* "#utility.yul":1951:1973   */
      mstore
        /* "#utility.yul":1997:1999   */
      dup3
        /* "#utility.yul":1989:1995   */
      dup2
        /* "#utility.yul":1982:2000   */
      mstore
        /* "#utility.yul":2037:2044   */
      dup10
        /* "#utility.yul":2032:2034   */
      0x20
        /* "#utility.yul":2027:2029   */
      dup5
        /* "#utility.yul":2023:2025   */
      dup8
        /* "#utility.yul":2019:2030   */
      add
        /* "#utility.yul":2015:2035   */
      add
        /* "#utility.yul":2012:2045   */
      gt
        /* "#utility.yul":2009:2062   */
      iszero
      tag_179
      jumpi
        /* "#utility.yul":2058:2059   */
      0x00
        /* "#utility.yul":2055:2056   */
      dup1
        /* "#utility.yul":2048:2060   */
      revert
        /* "#utility.yul":2009:2062   */
    tag_179:
        /* "#utility.yul":2114:2116   */
      dup3
        /* "#utility.yul":2109:2111   */
      0x20
        /* "#utility.yul":2105:2107   */
      dup7
        /* "#utility.yul":2101:2112   */
      add
        /* "#utility.yul":2096:2098   */
      0x20
        /* "#utility.yul":2088:2094   */
      dup4
        /* "#utility.yul":2084:2099   */
      add
        /* "#utility.yul":2071:2117   */
      calldatacopy
        /* "#utility.yul":2159:2160   */
      0x00
        /* "#utility.yul":2154:2156   */
      0x20
        /* "#utility.yul":2149:2151   */
      dup5
        /* "#utility.yul":2141:2147   */
      dup4
        /* "#utility.yul":2137:2152   */
      add
        /* "#utility.yul":2133:2157   */
      add
        /* "#utility.yul":2126:2161   */
      mstore
        /* "#utility.yul":2180:2186   */
      dup1
        /* "#utility.yul":2170:2186   */
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
        /* "#utility.yul":2205:2240   */
      tag_180
        /* "#utility.yul":2236:2238   */
      0x40
        /* "#utility.yul":2225:2234   */
      dup6
        /* "#utility.yul":2221:2239   */
      add
        /* "#utility.yul":2205:2240   */
      tag_157
      jump	// in
    tag_180:
        /* "#utility.yul":2195:2240   */
      swap1
      pop
        /* "#utility.yul":1183:2246   */
      swap3
      pop
      swap3
      pop
      swap3
      jump	// out
        /* "#utility.yul":2990:3248   */
    tag_158:
        /* "#utility.yul":3062:3063   */
      0x00
        /* "#utility.yul":3072:3185   */
    tag_184:
        /* "#utility.yul":3086:3092   */
      dup4
        /* "#utility.yul":3083:3084   */
      dup2
        /* "#utility.yul":3080:3093   */
      lt
        /* "#utility.yul":3072:3185   */
      iszero
      tag_186
      jumpi
        /* "#utility.yul":3162:3173   */
      dup2
      dup2
      add
        /* "#utility.yul":3156:3174   */
      mload
        /* "#utility.yul":3143:3154   */
      dup4
      dup3
      add
        /* "#utility.yul":3136:3175   */
      mstore
        /* "#utility.yul":3108:3110   */
      0x20
        /* "#utility.yul":3101:3111   */
      add
        /* "#utility.yul":3072:3185   */
      jump(tag_184)
    tag_186:
        /* "#utility.yul":3203:3209   */
      dup4
        /* "#utility.yul":3200:3201   */
      dup2
        /* "#utility.yul":3197:3210   */
      gt
        /* "#utility.yul":3194:3242   */
      iszero
      tag_94
      jumpi
      pop
      pop
        /* "#utility.yul":3238:3239   */
      0x00
        /* "#utility.yul":3220:3236   */
      swap2
      add
        /* "#utility.yul":3213:3240   */
      mstore
        /* "#utility.yul":2990:3248   */
      jump	// out
        /* "#utility.yul":3253:3527   */
    tag_129:
        /* "#utility.yul":3382:3385   */
      0x00
        /* "#utility.yul":3420:3426   */
      dup3
        /* "#utility.yul":3414:3427   */
      mload
        /* "#utility.yul":3436:3489   */
      tag_189
        /* "#utility.yul":3482:3488   */
      dup2
        /* "#utility.yul":3477:3480   */
      dup5
        /* "#utility.yul":3470:3474   */
      0x20
        /* "#utility.yul":3462:3468   */
      dup8
        /* "#utility.yul":3458:3475   */
      add
        /* "#utility.yul":3436:3489   */
      tag_158
      jump	// in
    tag_189:
        /* "#utility.yul":3505:3521   */
      swap2
      swap1
      swap2
      add
      swap3
        /* "#utility.yul":3253:3527   */
      swap2
      pop
      pop
      jump	// out
        /* "#utility.yul":4353:4736   */
    tag_154:
        /* "#utility.yul":4502:4504   */
      0x20
        /* "#utility.yul":4491:4500   */
      dup2
        /* "#utility.yul":4484:4505   */
      mstore
        /* "#utility.yul":4465:4469   */
      0x00
        /* "#utility.yul":4534:4540   */
      dup3
        /* "#utility.yul":4528:4541   */
      mload
        /* "#utility.yul":4577:4583   */
      dup1
        /* "#utility.yul":4572:4574   */
      0x20
        /* "#utility.yul":4561:4570   */
      dup5
        /* "#utility.yul":4557:4575   */
      add
        /* "#utility.yul":4550:4584   */
      mstore
        /* "#utility.yul":4593:4659   */
      tag_193
        /* "#utility.yul":4652:4658   */
      dup2
        /* "#utility.yul":4647:4649   */
      0x40
        /* "#utility.yul":4636:4645   */
      dup6
        /* "#utility.yul":4632:4650   */
      add
        /* "#utility.yul":4627:4629   */
      0x20
        /* "#utility.yul":4619:4625   */
      dup8
        /* "#utility.yul":4615:4630   */
      add
        /* "#utility.yul":4593:4659   */
      tag_158
      jump	// in
    tag_193:
        /* "#utility.yul":4720:4722   */
      0x1f
        /* "#utility.yul":4699:4714   */
      add
      not(0x1f)
        /* "#utility.yul":4695:4724   */
      and
        /* "#utility.yul":4680:4725   */
      swap2
      swap1
      swap2
      add
        /* "#utility.yul":4727:4729   */
      0x40
        /* "#utility.yul":4676:4730   */
      add
      swap3
        /* "#utility.yul":4353:4736   */
      swap2
      pop
      pop
      jump	// out
    stop
    data_9fdcd12e4b726339b32a442b0a448365d5d85c96b2d2cff917b4f66c63110398 416464726573733a206c6f772d6c6576656c2064656c65676174652063616c6c206661696c6564

    auxdata: 0xa264697066735822122000dd075126102350e5ac31db68efdcff525a0ee85ca862f9e6a3fadc7521aa8d64736f6c63430008090033
}

