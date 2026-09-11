    /* "src/RequestHarness.sol":60:1076  contract RequestHarness is WithdrawalQueue {... */
  mstore(0x40, 0xc0)
    /* "src/RequestHarness.sol":189:245  constructor(IWstETH wrapper) WithdrawalQueue(wrapper) {} */
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
    /* "src/RequestHarness.sol":234:241  wrapper */
  dup1
    /* "src/core/utils/Versioned.sol":1144:1211  CONTRACT_VERSION_POSITION.setStorageUint256(PETRIFIED_VERSION_MARK) */
  tag_8
  not(0x00)
    /* "src/core/utils/Versioned.sol":913:956  keccak256("lido.Versioned.contractVersion") */
  0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
    /* "src/core/utils/Versioned.sol":1144:1187  CONTRACT_VERSION_POSITION.setStorageUint256 */
  or(tag_0_266, shl(0x20, tag_9))
  swap1
    /* "src/core/utils/Versioned.sol":1144:1211  CONTRACT_VERSION_POSITION.setStorageUint256(PETRIFIED_VERSION_MARK) */
  swap2
  swap1
  0x20
  shr
  jump	// in
tag_8:
  sub(shl(0xa0, 0x01), 0x01)
    /* "src/core/WithdrawalQueue.sol":3564:3580  WSTETH = _wstETH */
  dup2
  and
  0xa0
  dup2
  swap1
  mstore
    /* "src/core/WithdrawalQueue.sol":3598:3612  WSTETH.stETH() */
  0x40
  dup1
  mload
  shl(0xe3, 0x183fc7c9)
  dup2
  mstore
  swap1
  mload
    /* "src/core/WithdrawalQueue.sol":3598:3610  WSTETH.stETH */
  0xc1fe3e48
  swap2
    /* "src/core/WithdrawalQueue.sol":3598:3612  WSTETH.stETH() */
  0x04
  dup1
  dup3
  add
  swap3
  0x20
  swap3
  swap1
  swap2
  swap1
  dup3
  swap1
  sub
  add
  dup2
    /* "src/core/WithdrawalQueue.sol":3564:3580  WSTETH = _wstETH */
  dup7
    /* "src/core/WithdrawalQueue.sol":3598:3612  WSTETH.stETH() */
  dup1
  extcodesize
  iszero
  dup1
  iszero
  tag_11
  jumpi
  0x00
  dup1
  revert
tag_11:
  pop
  gas
  staticcall
  iszero
  dup1
  iszero
  tag_13
  jumpi
  returndatasize
  0x00
  dup1
  returndatacopy
  revert(0x00, returndatasize)
tag_13:
  pop
  pop
  pop
  pop
  mload(0x40)
  returndatasize
  not(0x1f)
  0x1f
  dup3
  add
  and
  dup3
  add
  dup1
  0x40
  mstore
  pop
  dup2
  add
  swap1
  tag_14
  swap2
  swap1
  tag_3
  jump	// in
tag_14:
  sub(shl(0xa0, 0x01), 0x01)
    /* "src/core/WithdrawalQueue.sol":3590:3612  STETH = WSTETH.stETH() */
  and
  0x80
  mstore
  pop
    /* "src/RequestHarness.sol":60:1076  contract RequestHarness is WithdrawalQueue {... */
  tag_20
  swap1
  pop
  jump
    /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
tag_9:
    /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
  swap1
  sstore
    /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
  jump	// out
    /* "#utility.yul":14:154   */
tag_19:
  sub(shl(0xa0, 0x01), 0x01)
    /* "#utility.yul":98:129   */
  dup2
  and
    /* "#utility.yul":88:130   */
  dup2
  eq
    /* "#utility.yul":78:148   */
  tag_22
  jumpi
    /* "#utility.yul":144:145   */
  0x00
    /* "#utility.yul":141:142   */
  dup1
    /* "#utility.yul":134:146   */
  revert
    /* "#utility.yul":78:148   */
tag_22:
    /* "#utility.yul":14:154   */
  pop
  jump	// out
    /* "#utility.yul":159:435   */
tag_3:
    /* "#utility.yul":245:251   */
  0x00
    /* "#utility.yul":298:300   */
  0x20
    /* "#utility.yul":286:295   */
  dup3
    /* "#utility.yul":277:284   */
  dup5
    /* "#utility.yul":273:296   */
  sub
    /* "#utility.yul":269:301   */
  slt
    /* "#utility.yul":266:318   */
  iszero
  tag_24
  jumpi
    /* "#utility.yul":314:315   */
  0x00
    /* "#utility.yul":311:312   */
  dup1
    /* "#utility.yul":304:316   */
  revert
    /* "#utility.yul":266:318   */
tag_24:
    /* "#utility.yul":346:355   */
  dup2
    /* "#utility.yul":340:356   */
  mload
    /* "#utility.yul":365:405   */
  tag_25
    /* "#utility.yul":399:404   */
  dup2
    /* "#utility.yul":365:405   */
  tag_19
  jump	// in
tag_25:
    /* "#utility.yul":424:429   */
  swap4
    /* "#utility.yul":159:435   */
  swap3
  pop
  pop
  pop
  jump	// out
    /* "#utility.yul":440:715   */
tag_20:
    /* "src/RequestHarness.sol":60:1076  contract RequestHarness is WithdrawalQueue {... */
  mload(0x80)
  mload(0xa0)
  codecopy(0x00, dataOffset(sub_0), dataSize(sub_0))
  0x00
  assignImmutable("0x6e20e28aa948d9b4a4e4fad29a41b0e2debd981d9d74148d1704f33eeae821e8")
  0x00
  assignImmutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
  return(0x00, dataSize(sub_0))
stop

sub_0: assembly {
        /* "src/RequestHarness.sol":60:1076  contract RequestHarness is WithdrawalQueue {... */
      mstore(0x40, 0x80)
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
      jumpi(tag_2, lt(calldatasize, 0x04))
      shr(0xe0, calldataload(0x00))
      dup1
      0xa217fddf
      gt
      tag_55
      jumpi
      dup1
      0xd547741f
      gt
      tag_56
      jumpi
      dup1
      0xe3afe0a3
      gt
      tag_57
      jumpi
      dup1
      0xf3f449c7
      gt
      tag_58
      jumpi
      dup1
      0xf3f449c7
      eq
      tag_51
      jumpi
      dup1
      0xf6fa8a47
      eq
      tag_52
      jumpi
      dup1
      0xf8444436
      eq
      tag_53
      jumpi
      dup1
      0xfa42f209
      eq
      tag_54
      jumpi
      0x00
      dup1
      revert
    tag_58:
      dup1
      0xe3afe0a3
      eq
      tag_48
      jumpi
      dup1
      0xe7c0835d
      eq
      tag_30
      jumpi
      dup1
      0xeed53bf5
      eq
      tag_50
      jumpi
      0x00
      dup1
      revert
    tag_57:
      dup1
      0xd547741f
      eq
      tag_42
      jumpi
      dup1
      0xd6681042
      eq
      tag_43
      jumpi
      dup1
      0xd9fb643a
      eq
      tag_44
      jumpi
      dup1
      0xdb2296cd
      eq
      tag_45
      jumpi
      dup1
      0xe00bfe50
      eq
      tag_46
      jumpi
      dup1
      0xe3684e39
      eq
      tag_47
      jumpi
      0x00
      dup1
      revert
    tag_56:
      dup1
      0xb8c4b85a
      gt
      tag_59
      jumpi
      dup1
      0xc97912d8
      gt
      tag_60
      jumpi
      dup1
      0xc97912d8
      eq
      tag_38
      jumpi
      dup1
      0xca15c873
      eq
      tag_39
      jumpi
      dup1
      0xcb6557bf
      eq
      tag_40
      jumpi
      dup1
      0xd0fb84e8
      eq
      tag_41
      jumpi
      0x00
      dup1
      revert
    tag_60:
      dup1
      0xb8c4b85a
      eq
      tag_35
      jumpi
      dup1
      0xc2fc7aff
      eq
      tag_36
      jumpi
      dup1
      0xc4d66de8
      eq
      tag_37
      jumpi
      0x00
      dup1
      revert
    tag_59:
      dup1
      0xa217fddf
      eq
      tag_29
      jumpi
      dup1
      0xa302ee38
      eq
      tag_30
      jumpi
      dup1
      0xa52e9c9f
      eq
      tag_31
      jumpi
      dup1
      0xabe9cfc8
      eq
      tag_32
      jumpi
      dup1
      0xacf41e4d
      eq
      tag_33
      jumpi
      dup1
      0xb187bd26
      eq
      tag_34
      jumpi
      0x00
      dup1
      revert
    tag_55:
      dup1
      0x389ed267
      gt
      tag_61
      jumpi
      dup1
      0x7951b76f
      gt
      tag_62
      jumpi
      dup1
      0x9010d07c
      gt
      tag_63
      jumpi
      dup1
      0x9010d07c
      eq
      tag_25
      jumpi
      dup1
      0x91d14854
      eq
      tag_26
      jumpi
      dup1
      0x96992fed
      eq
      tag_27
      jumpi
      dup1
      0x9b36be58
      eq
      tag_28
      jumpi
      0x00
      dup1
      revert
    tag_63:
      dup1
      0x7951b76f
      eq
      tag_22
      jumpi
      dup1
      0x7d031b65
      eq
      tag_23
      jumpi
      dup1
      0x8aa10435
      eq
      tag_24
      jumpi
      0x00
      dup1
      revert
    tag_62:
      dup1
      0x389ed267
      eq
      tag_16
      jumpi
      dup1
      0x4f069a13
      eq
      tag_17
      jumpi
      dup1
      0x526eae3e
      eq
      tag_18
      jumpi
      dup1
      0x589ff76c
      eq
      tag_19
      jumpi
      dup1
      0x5e7eead9
      eq
      tag_20
      jumpi
      dup1
      0x62abe3fa
      eq
      tag_21
      jumpi
      0x00
      dup1
      revert
    tag_61:
      dup1
      0x220ca2f4
      gt
      tag_64
      jumpi
      dup1
      0x2b95b781
      gt
      tag_65
      jumpi
      dup1
      0x2b95b781
      eq
      tag_12
      jumpi
      dup1
      0x2de03aa1
      eq
      tag_13
      jumpi
      dup1
      0x2f2ff15d
      eq
      tag_14
      jumpi
      dup1
      0x36568abe
      eq
      tag_15
      jumpi
      0x00
      dup1
      revert
    tag_65:
      dup1
      0x220ca2f4
      eq
      tag_9
      jumpi
      dup1
      0x248a9ca3
      eq
      tag_10
      jumpi
      dup1
      0x29fd065d
      eq
      tag_11
      jumpi
      0x00
      dup1
      revert
    tag_64:
      dup1
      0x01ffc9a7
      eq
      tag_3
      jumpi
      dup1
      0x046f7da2
      eq
      tag_4
      jumpi
      dup1
      0x07e2cea5
      eq
      tag_5
      jumpi
      dup1
      0x0d25a957
      eq
      tag_6
      jumpi
      dup1
      0x19aa6257
      eq
      tag_7
      jumpi
      dup1
      0x19c2b4c3
      eq
      tag_8
      jumpi
    tag_2:
      0x00
      dup1
      revert
        /* "src/core/utils/access/AccessControlEnumerable.sol":1277:1489  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
    tag_3:
      tag_66
      tag_67
      calldatasize
      0x04
      tag_68
      jump	// in
    tag_67:
      tag_69
      jump	// in
    tag_66:
      mload(0x40)
        /* "#utility.yul":470:484   */
      swap1
      iszero
        /* "#utility.yul":463:485   */
      iszero
        /* "#utility.yul":445:486   */
      dup2
      mstore
        /* "#utility.yul":433:435   */
      0x20
        /* "#utility.yul":418:436   */
      add
        /* "src/core/utils/access/AccessControlEnumerable.sol":1277:1489  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
    tag_70:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/core/WithdrawalQueue.sol":4258:4356  function resume() external {... */
    tag_4:
      tag_72
      tag_73
      jump	// in
    tag_72:
      stop
        /* "src/core/WithdrawalQueue.sol":2292:2354  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE") */
    tag_5:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2330:2354  keccak256("ORACLE_ROLE") */
      0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1
        /* "src/core/WithdrawalQueue.sol":2292:2354  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE") */
      dup2
      jump
    tag_74:
      mload(0x40)
        /* "#utility.yul":643:668   */
      swap1
      dup2
      mstore
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
        /* "src/core/WithdrawalQueue.sol":2292:2354  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE") */
      tag_70
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueue.sol":2430:2487  uint256 public constant MIN_STETH_WITHDRAWAL_AMOUNT = 100 */
    tag_6:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2484:2487  100 */
      0x64
        /* "src/core/WithdrawalQueue.sol":2430:2487  uint256 public constant MIN_STETH_WITHDRAWAL_AMOUNT = 100 */
      dup2
      jump
        /* "src/core/WithdrawalQueue.sol":6793:7218  function requestWithdrawalsWstETH(uint256[] calldata _amounts, address _owner)... */
    tag_7:
      tag_82
      tag_83
      calldatasize
      0x04
      tag_84
      jump	// in
    tag_83:
      tag_85
      jump	// in
    tag_82:
      mload(0x40)
      tag_70
      swap2
      swap1
      tag_87
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":5410:5536  function getLastRequestId() public view returns (uint256) {... */
    tag_8:
      tag_74
      tag_89
      jump	// in
        /* "src/core/WithdrawalQueue.sol":2220:2286  bytes32 public constant FINALIZE_ROLE = keccak256("FINALIZE_ROLE") */
    tag_9:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2260:2286  keccak256("FINALIZE_ROLE") */
      0x485191a2ef18512555bd4426d18a716ce8e98c80ec2de16394dcf86d7d91bc80
        /* "src/core/WithdrawalQueue.sol":2220:2286  bytes32 public constant FINALIZE_ROLE = keccak256("FINALIZE_ROLE") */
      dup2
      jump
        /* "src/core/utils/access/AccessControl.sol":4607:4737  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {... */
    tag_10:
      tag_74
      tag_95
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_95:
      tag_97
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":805:852  uint256 public constant MAX_BATCHES_LENGTH = 36 */
    tag_11:
      tag_74
        /* "src/core/WithdrawalQueueBase.sol":850:852  36 */
      0x24
        /* "src/core/WithdrawalQueueBase.sol":805:852  uint256 public constant MAX_BATCHES_LENGTH = 36 */
      dup2
      jump
        /* "src/core/WithdrawalQueue.sol":16848:16988  function isBunkerModeActive() public view returns (bool) {... */
    tag_12:
      tag_66
      tag_103
      jump	// in
        /* "src/core/WithdrawalQueue.sol":2152:2214  bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE") */
    tag_13:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2190:2214  keccak256("RESUME_ROLE") */
      0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7
        /* "src/core/WithdrawalQueue.sol":2152:2214  bytes32 public constant RESUME_ROLE = keccak256("RESUME_ROLE") */
      dup2
      jump
        /* "src/core/utils/access/AccessControl.sol":4987:5132  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {... */
    tag_14:
      tag_72
      tag_109
      calldatasize
      0x04
      tag_110
      jump	// in
    tag_109:
      tag_111
      jump	// in
        /* "src/core/utils/access/AccessControl.sol":6004:6218  function renounceRole(bytes32 role, address account) public virtual override {... */
    tag_15:
      tag_72
      tag_113
      calldatasize
      0x04
      tag_110
      jump	// in
    tag_113:
      tag_114
      jump	// in
        /* "src/core/WithdrawalQueue.sol":2086:2146  bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE") */
    tag_16:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2123:2146  keccak256("PAUSE_ROLE") */
      0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
        /* "src/core/WithdrawalQueue.sol":2086:2146  bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE") */
      dup2
      jump
        /* "src/core/WithdrawalQueueBase.sol":5696:5841  function getLastFinalizedRequestId() public view returns (uint256) {... */
    tag_17:
      tag_74
      tag_119
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":6265:6403  function getLastCheckpointIndex() public view returns (uint256) {... */
    tag_18:
      tag_74
      tag_122
      jump	// in
        /* "src/core/utils/PausableUntil.sol":1717:1859  function getResumeSinceTimestamp() external view returns (uint256) {... */
    tag_19:
      tag_74
      tag_125
      jump	// in
        /* "src/core/WithdrawalQueue.sol":11880:12410  function claimWithdrawalsTo(uint256[] calldata _requestIds, uint256[] calldata _hints, address _recipient)... */
    tag_20:
      tag_72
      tag_128
      calldatasize
      0x04
      tag_129
      jump	// in
    tag_128:
      tag_130
      jump	// in
        /* "src/core/WithdrawalQueue.sol":14796:15386  function findCheckpointHints(uint256[] calldata _requestIds, uint256 _firstIndex, uint256 _lastIndex)... */
    tag_21:
      tag_82
      tag_132
      calldatasize
      0x04
      tag_133
      jump	// in
    tag_132:
      tag_134
      jump	// in
        /* "src/core/WithdrawalQueue.sol":8815:9193  function requestWithdrawalsWstETHWithPermit(... */
    tag_22:
      tag_82
      tag_137
      calldatasize
      0x04
      tag_138
      jump	// in
    tag_137:
      tag_139
      jump	// in
        /* "src/core/WithdrawalQueue.sol":9761:9923  function getWithdrawalRequests(address _owner) external view returns (uint256[] memory requestsIds) {... */
    tag_23:
      tag_82
      tag_142
      calldatasize
      0x04
      tag_143
      jump	// in
    tag_142:
      tag_144
      jump	// in
        /* "src/core/utils/Versioned.sol":1278:1407  function getContractVersion() public view returns (uint256) {... */
    tag_24:
      tag_74
      tag_147
      jump	// in
        /* "src/core/utils/access/AccessControlEnumerable.sol":2074:2226  function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {... */
    tag_25:
      tag_149
      tag_150
      calldatasize
      0x04
      tag_151
      jump	// in
    tag_150:
      tag_152
      jump	// in
    tag_149:
      mload(0x40)
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":5724:5756   */
      swap1
      swap2
      and
        /* "#utility.yul":5706:5757   */
      dup2
      mstore
        /* "#utility.yul":5694:5696   */
      0x20
        /* "#utility.yul":5679:5697   */
      add
        /* "src/core/utils/access/AccessControlEnumerable.sol":2074:2226  function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {... */
      tag_70
        /* "#utility.yul":5560:5763   */
      jump
        /* "src/core/utils/access/AccessControl.sol":3515:3661  function hasRole(bytes32 role, address account) public view override returns (bool) {... */
    tag_26:
      tag_66
      tag_156
      calldatasize
      0x04
      tag_110
      jump	// in
    tag_156:
      tag_157
      jump	// in
        /* "src/core/WithdrawalQueue.sol":15745:16795  function onOracleReport(bool _isBunkerModeNow, uint256 _bunkerStartTimestamp, uint256 _currentReportTimestamp)... */
    tag_27:
      tag_72
      tag_160
      calldatasize
      0x04
      tag_161
      jump	// in
    tag_160:
      tag_162
      jump	// in
        /* "src/core/WithdrawalQueue.sol":17158:17304  function bunkerModeSinceTimestamp() public view returns (uint256) {... */
    tag_28:
      tag_74
      tag_164
      jump	// in
        /* "src/core/utils/access/AccessControl.sol":2633:2682  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00 */
    tag_29:
      tag_74
        /* "src/core/utils/access/AccessControl.sol":2678:2682  0x00 */
      0x00
        /* "src/core/utils/access/AccessControl.sol":2633:2682  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00 */
      dup2
      jump
        /* "src/core/utils/PausableUntil.sol":442:502  uint256 public constant PAUSE_INFINITELY = type(uint256).max */
    tag_30:
      tag_74
      not(0x00)
      dup2
      jump
        /* "src/core/WithdrawalQueueBase.sol":15105:16633  function prefinalize(uint256[] calldata _batches, uint256 _maxShareRate)... */
    tag_31:
      tag_172
      tag_173
      calldatasize
      0x04
      tag_174
      jump	// in
    tag_173:
      tag_175
      jump	// in
    tag_172:
      0x40
      dup1
      mload
        /* "#utility.yul":6957:6982   */
      swap3
      dup4
      mstore
        /* "#utility.yul":7013:7015   */
      0x20
        /* "#utility.yul":6998:7016   */
      dup4
      add
        /* "#utility.yul":6991:7025   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":6930:6948   */
      add
        /* "src/core/WithdrawalQueueBase.sol":15105:16633  function prefinalize(uint256[] calldata _batches, uint256 _maxShareRate)... */
      tag_70
        /* "#utility.yul":6783:7031   */
      jump
        /* "src/core/WithdrawalQueue.sol":5195:5325  function pauseUntil(uint256 _pauseUntilInclusive) external onlyRole(PAUSE_ROLE) {... */
    tag_32:
      tag_72
      tag_179
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_179:
      tag_181
      jump	// in
        /* "src/core/WithdrawalQueue.sol":7906:8261  function requestWithdrawalsWithPermit(uint256[] calldata _amounts, address _owner, PermitInput calldata _permit)... */
    tag_33:
      tag_82
      tag_183
      calldatasize
      0x04
      tag_138
      jump	// in
    tag_183:
      tag_184
      jump	// in
        /* "src/core/utils/PausableUntil.sol":1348:1488  function isPaused() public view returns (bool) {... */
    tag_34:
      tag_66
      tag_187
      jump	// in
        /* "src/core/WithdrawalQueue.sol":10050:10405  function getWithdrawalStatus(uint256[] calldata _requestIds)... */
    tag_35:
      tag_189
      tag_190
      calldatasize
      0x04
      tag_191
      jump	// in
    tag_190:
      tag_192
      jump	// in
    tag_189:
      mload(0x40)
      tag_70
      swap2
      swap1
      tag_194
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":6480:6620  function unfinalizedRequestNumber() external view returns (uint256) {... */
    tag_36:
      tag_74
      tag_196
      jump	// in
        /* "src/core/WithdrawalQueue.sol":3960:4103  function initialize(address _admin) external {... */
    tag_37:
      tag_72
      tag_199
      calldatasize
      0x04
      tag_143
      jump	// in
    tag_199:
      tag_200
      jump	// in
        /* "src/core/WithdrawalQueue.sol":10826:11223  function getClaimableEther(uint256[] calldata _requestIds, uint256[] calldata _hints)... */
    tag_38:
      tag_82
      tag_202
      calldatasize
      0x04
      tag_203
      jump	// in
    tag_202:
      tag_204
      jump	// in
        /* "src/core/utils/access/AccessControlEnumerable.sol":2394:2535  function getRoleMemberCount(bytes32 role) public view override returns (uint256) {... */
    tag_39:
      tag_74
      tag_207
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_207:
      tag_208
      jump	// in
        /* "src/RequestHarness.sol":742:964  function seed(uint256 id,uint128 st,uint128 sh,uint256 report) external {... */
    tag_40:
      tag_72
      tag_211
      calldatasize
      0x04
      tag_212
      jump	// in
    tag_211:
      tag_213
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":6703:6905  function unfinalizedStETH() external view returns (uint256) {... */
    tag_41:
      tag_74
      tag_215
      jump	// in
        /* "src/core/utils/access/AccessControl.sol":5366:5513  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {... */
    tag_42:
      tag_72
      tag_218
      calldatasize
      0x04
      tag_110
      jump	// in
    tag_218:
      tag_219
      jump	// in
        /* "src/core/WithdrawalQueue.sol":5822:6291  function requestWithdrawals(uint256[] calldata _amounts, address _owner)... */
    tag_43:
      tag_82
      tag_221
      calldatasize
      0x04
      tag_84
      jump	// in
    tag_221:
      tag_222
      jump	// in
        /* "src/core/WithdrawalQueue.sol":2954:2985  IWstETH public immutable WSTETH */
    tag_44:
      tag_149
      immutable("0x6e20e28aa948d9b4a4e4fad29a41b0e2debd981d9d74148d1704f33eeae821e8")
      dup2
      jump
        /* "src/core/WithdrawalQueue.sol":2764:2829  uint256 public constant MAX_STETH_WITHDRAWAL_AMOUNT = 1000 * 1e18 */
    tag_45:
      tag_74
        /* "src/core/WithdrawalQueue.sol":2818:2829  1000 * 1e18 */
      0x3635c9adc5dea00000
        /* "src/core/WithdrawalQueue.sol":2764:2829  uint256 public constant MAX_STETH_WITHDRAWAL_AMOUNT = 1000 * 1e18 */
      dup2
      jump
        /* "src/core/WithdrawalQueue.sol":2877:2906  IStETH public immutable STETH */
    tag_46:
      tag_149
      immutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
      dup2
      jump
        /* "src/RequestHarness.sol":969:1074  function metadata(uint256 id) external view returns(WithdrawalRequest memory) { return _getQueue()[id]; } */
    tag_47:
      tag_235
      tag_236
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_236:
      tag_237
      jump	// in
    tag_235:
      mload(0x40)
      tag_70
      swap2
      swap1
        /* "#utility.yul":10953:10966   */
      dup2
      mload
      sub(shl(0x80, 0x01), 0x01)
        /* "#utility.yul":10949:10971   */
      swap1
      dup2
      and
        /* "#utility.yul":10931:10972   */
      dup3
      mstore
        /* "#utility.yul":11032:11036   */
      0x20
        /* "#utility.yul":11020:11037   */
      dup1
      dup5
      add
        /* "#utility.yul":11014:11038   */
      mload
        /* "#utility.yul":11010:11043   */
      swap1
      swap2
      and
        /* "#utility.yul":10988:11008   */
      swap1
      dup3
      add
        /* "#utility.yul":10981:11044   */
      mstore
        /* "#utility.yul":11104:11108   */
      0x40
        /* "#utility.yul":11092:11109   */
      dup1
      dup4
      add
        /* "#utility.yul":11086:11110   */
      mload
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":11082:11132   */
      and
        /* "#utility.yul":11060:11080   */
      swap1
      dup3
      add
        /* "#utility.yul":11053:11133   */
      mstore
        /* "#utility.yul":11180:11184   */
      0x60
        /* "#utility.yul":11168:11185   */
      dup1
      dup4
      add
        /* "#utility.yul":11162:11186   */
      mload
        /* "#utility.yul":11205:11217   */
      0xffffffffff
        /* "#utility.yul":11255:11276   */
      swap1
      dup2
      and
        /* "#utility.yul":11233:11253   */
      swap2
      dup4
      add
        /* "#utility.yul":11226:11277   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":11347:11351   */
      0x80
        /* "#utility.yul":11335:11352   */
      dup1
      dup5
      add
        /* "#utility.yul":11329:11353   */
      mload
        /* "#utility.yul":11322:11354   */
      iszero
        /* "#utility.yul":11315:11355   */
      iszero
        /* "#utility.yul":11293:11313   */
      swap1
      dup4
      add
        /* "#utility.yul":11286:11356   */
      mstore
        /* "#utility.yul":11120:11123   */
      0xa0
        /* "#utility.yul":11404:11421   */
      swap3
      dup4
      add
        /* "#utility.yul":11398:11422   */
      mload
        /* "#utility.yul":11394:11427   */
      and
        /* "#utility.yul":11372:11392   */
      swap2
      dup2
      add
        /* "#utility.yul":11365:11428   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":10865:10868   */
      0xc0
        /* "#utility.yul":10850:10869   */
      add
      swap1
        /* "#utility.yul":10661:11434   */
      jump
        /* "src/core/WithdrawalQueue.sol":12954:13388  function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external {... */
    tag_48:
      tag_72
      tag_241
      calldatasize
      0x04
      tag_203
      jump	// in
    tag_241:
      tag_242
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":11431:14606  function calculateFinalizationBatches(... */
    tag_50:
      tag_246
      tag_247
      calldatasize
      0x04
      tag_248
      jump	// in
    tag_247:
      tag_249
      jump	// in
    tag_246:
      mload(0x40)
      tag_70
      swap2
      swap1
      tag_251
      jump	// in
        /* "src/core/WithdrawalQueue.sol":4731:4835  function pauseFor(uint256 _duration) external onlyRole(PAUSE_ROLE) {... */
    tag_51:
      tag_72
      tag_253
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_253:
      tag_254
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":5955:6089  function getLockedEtherAmount() public view returns (uint256) {... */
    tag_52:
      tag_74
      tag_256
      jump	// in
        /* "src/core/WithdrawalQueue.sol":13792:14014  function claimWithdrawal(uint256 _requestId) external {... */
    tag_53:
      tag_72
      tag_259
      calldatasize
      0x04
      tag_96
      jump	// in
    tag_259:
      tag_260
      jump	// in
        /* "src/RequestHarness.sol":438:658  function one(uint256 amount,address owner) external returns(uint256) {... */
    tag_54:
      tag_74
      tag_262
      calldatasize
      0x04
      tag_110
      jump	// in
    tag_262:
      tag_264
      jump	// in
        /* "src/core/utils/access/AccessControlEnumerable.sol":1277:1489  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
    tag_69:
        /* "src/core/utils/access/AccessControlEnumerable.sol":1362:1366  bool */
      0x00
      not(sub(shl(0xe0, 0x01), 0x01))
        /* "src/core/utils/access/AccessControlEnumerable.sol":1385:1442  interfaceId == type(IAccessControlEnumerable).interfaceId */
      dup3
      and
      shl(0xe0, 0x5a05180f)
      eq
      dup1
        /* "src/core/utils/access/AccessControlEnumerable.sol":1385:1482  interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId) */
      tag_269
      jumpi
      pop
        /* "src/core/utils/access/AccessControlEnumerable.sol":1446:1482  super.supportsInterface(interfaceId) */
      tag_269
        /* "src/core/utils/access/AccessControlEnumerable.sol":1470:1481  interfaceId */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":1446:1469  super.supportsInterface */
      tag_270
        /* "src/core/utils/access/AccessControlEnumerable.sol":1446:1482  super.supportsInterface(interfaceId) */
      jump	// in
    tag_269:
        /* "src/core/utils/access/AccessControlEnumerable.sol":1378:1482  return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId) */
      swap3
        /* "src/core/utils/access/AccessControlEnumerable.sol":1277:1489  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":4258:4356  function resume() external {... */
    tag_73:
        /* "src/core/WithdrawalQueue.sol":4295:4330  _checkRole(RESUME_ROLE, msg.sender) */
      tag_272
        /* "src/core/WithdrawalQueue.sol":2190:2214  keccak256("RESUME_ROLE") */
      0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7
        /* "src/core/WithdrawalQueue.sol":4319:4329  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":4295:4305  _checkRole */
      tag_273
        /* "src/core/WithdrawalQueue.sol":4295:4330  _checkRole(RESUME_ROLE, msg.sender) */
      jump	// in
    tag_272:
        /* "src/core/WithdrawalQueue.sol":4340:4349  _resume() */
      tag_274
        /* "src/core/WithdrawalQueue.sol":4340:4347  _resume */
      tag_275
        /* "src/core/WithdrawalQueue.sol":4340:4349  _resume() */
      jump	// in
    tag_274:
        /* "src/core/WithdrawalQueue.sol":4258:4356  function resume() external {... */
      jump	// out
        /* "src/core/WithdrawalQueue.sol":6793:7218  function requestWithdrawalsWstETH(uint256[] calldata _amounts, address _owner)... */
    tag_85:
        /* "src/core/WithdrawalQueue.sol":6904:6931  uint256[] memory requestIds */
      0x60
        /* "src/core/WithdrawalQueue.sol":6947:6962  _checkResumed() */
      tag_277
        /* "src/core/WithdrawalQueue.sol":6947:6960  _checkResumed */
      tag_278
        /* "src/core/WithdrawalQueue.sol":6947:6962  _checkResumed() */
      jump	// in
    tag_277:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":6976:6996  _owner == address(0) */
      dup3
      and
        /* "src/core/WithdrawalQueue.sol":6972:7017  if (_owner == address(0)) _owner = msg.sender */
      tag_279
      jumpi
        /* "src/core/WithdrawalQueue.sol":7007:7017  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":6998:7017  _owner = msg.sender */
      swap2
      pop
        /* "src/core/WithdrawalQueue.sol":6972:7017  if (_owner == address(0)) _owner = msg.sender */
    tag_279:
        /* "src/core/WithdrawalQueue.sol":7054:7062  _amounts */
      dup3
      sub(shl(0x40, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":7040:7070  new uint256[](_amounts.length) */
      dup2
      gt
      iszero
      tag_281
      jumpi
      tag_281
      tag_282
      jump	// in
    tag_281:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x20
      mul
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_283
      jumpi
      dup2
      0x20
      add
      0x20
      dup3
      mul
      dup1
      calldatasize
      dup4
      calldatacopy
      add
      swap1
      pop
    tag_283:
      pop
        /* "src/core/WithdrawalQueue.sol":7027:7070  requestIds = new uint256[](_amounts.length) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":7085:7094  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":7080:7212  for (uint256 i = 0; i < _amounts.length; ++i) {... */
    tag_284:
        /* "src/core/WithdrawalQueue.sol":7100:7119  i < _amounts.length */
      dup4
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":7080:7212  for (uint256 i = 0; i < _amounts.length; ++i) {... */
      iszero
      tag_285
      jumpi
        /* "src/core/WithdrawalQueue.sol":7156:7201  _requestWithdrawalWstETH(_amounts[i], _owner) */
      tag_287
        /* "src/core/WithdrawalQueue.sol":7181:7189  _amounts */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":7190:7191  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":7181:7192  _amounts[i] */
      dup2
      dup2
      lt
      tag_289
      jumpi
      tag_289
      tag_290
      jump	// in
    tag_289:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":7194:7200  _owner */
      dup5
        /* "src/core/WithdrawalQueue.sol":7156:7180  _requestWithdrawalWstETH */
      tag_291
        /* "src/core/WithdrawalQueue.sol":7156:7201  _requestWithdrawalWstETH(_amounts[i], _owner) */
      jump	// in
    tag_287:
        /* "src/core/WithdrawalQueue.sol":7140:7150  requestIds */
      dup3
        /* "src/core/WithdrawalQueue.sol":7151:7152  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":7140:7153  requestIds[i] */
      dup2
      mload
      dup2
      lt
      tag_293
      jumpi
      tag_293
      tag_290
      jump	// in
    tag_293:
      0x20
      swap1
      dup2
      mul
      swap2
      swap1
      swap2
      add
      add
        /* "src/core/WithdrawalQueue.sol":7140:7201  requestIds[i] = _requestWithdrawalWstETH(_amounts[i], _owner) */
      mstore
        /* "src/core/WithdrawalQueue.sol":7121:7124  ++i */
      tag_294
      dup2
      tag_295
      jump	// in
    tag_294:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":7080:7212  for (uint256 i = 0; i < _amounts.length; ++i) {... */
      jump(tag_284)
    tag_285:
      pop
        /* "src/core/WithdrawalQueue.sol":6793:7218  function requestWithdrawalsWstETH(uint256[] calldata _amounts, address _owner)... */
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":5410:5536  function getLastRequestId() public view returns (uint256) {... */
    tag_89:
        /* "src/core/WithdrawalQueueBase.sol":5459:5466  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":5485:5529  LAST_REQUEST_ID_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/WithdrawalQueueBase.sol":1340:1387  keccak256("lido.WithdrawalQueue.lastRequestId") */
      0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":5485:5529  LAST_REQUEST_ID_POSITION.getStorageUint256() */
    tag_297:
        /* "src/core/WithdrawalQueueBase.sol":5478:5529  return LAST_REQUEST_ID_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":5410:5536  function getLastRequestId() public view returns (uint256) {... */
      swap1
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":4607:4737  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {... */
    tag_97:
        /* "src/core/utils/access/AccessControl.sol":4673:4680  bytes32 */
      0x00
        /* "src/core/utils/access/AccessControl.sol":4699:4720  _storageRoles()[role] */
      swap1
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_91113e80635bccc2f93908fdf2a5cbd6a74badad069abcad4f85e45f73ab3f4c
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/utils/access/AccessControl.sol":4699:4730  _storageRoles()[role].adminRole */
      0x01
      add
      sload
      swap1
        /* "src/core/utils/access/AccessControl.sol":4607:4737  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {... */
      jump	// out
        /* "src/core/WithdrawalQueue.sol":16848:16988  function isBunkerModeActive() public view returns (bool) {... */
    tag_103:
        /* "src/core/WithdrawalQueue.sol":16899:16903  bool */
      0x00
      not(0x00)
        /* "src/core/WithdrawalQueue.sol":16922:16948  bunkerModeSinceTimestamp() */
      tag_303
        /* "src/core/WithdrawalQueue.sol":16922:16946  bunkerModeSinceTimestamp */
      tag_164
        /* "src/core/WithdrawalQueue.sol":16922:16948  bunkerModeSinceTimestamp() */
      jump	// in
    tag_303:
        /* "src/core/WithdrawalQueue.sol":16922:16981  bunkerModeSinceTimestamp() < BUNKER_MODE_DISABLED_TIMESTAMP */
      lt
        /* "src/core/WithdrawalQueue.sol":16915:16981  return bunkerModeSinceTimestamp() < BUNKER_MODE_DISABLED_TIMESTAMP */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":16848:16988  function isBunkerModeActive() public view returns (bool) {... */
      swap1
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":4987:5132  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {... */
    tag_111:
        /* "src/core/utils/access/AccessControl.sol":5070:5088  getRoleAdmin(role) */
      tag_304
        /* "src/core/utils/access/AccessControl.sol":5083:5087  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":5070:5082  getRoleAdmin */
      tag_97
        /* "src/core/utils/access/AccessControl.sol":5070:5088  getRoleAdmin(role) */
      jump	// in
    tag_304:
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      tag_306
        /* "src/core/utils/access/AccessControl.sol":3122:3126  role */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
        /* "src/core/utils/access/AccessControl.sol":3111:3121  _checkRole */
      tag_273
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      jump	// in
    tag_306:
        /* "src/core/utils/access/AccessControl.sol":5100:5125  _grantRole(role, account) */
      tag_310
        /* "src/core/utils/access/AccessControl.sol":5111:5115  role */
      dup4
        /* "src/core/utils/access/AccessControl.sol":5117:5124  account */
      dup4
        /* "src/core/utils/access/AccessControl.sol":5100:5110  _grantRole */
      tag_311
        /* "src/core/utils/access/AccessControl.sol":5100:5125  _grantRole(role, account) */
      jump	// in
    tag_310:
        /* "src/core/utils/access/AccessControl.sol":4987:5132  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {... */
      pop
      pop
      pop
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":6004:6218  function renounceRole(bytes32 role, address account) public virtual override {... */
    tag_114:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/utils/access/AccessControl.sol":6099:6122  account == _msgSender() */
      dup2
      and
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
        /* "src/core/utils/access/AccessControl.sol":6099:6122  account == _msgSender() */
      eq
        /* "src/core/utils/access/AccessControl.sol":6091:6174  require(account == _msgSender(), "AccessControl: can only renounce roles for self") */
      tag_314
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
        /* "#utility.yul":14971:14973   */
      0x20
        /* "src/core/utils/access/AccessControl.sol":6091:6174  require(account == _msgSender(), "AccessControl: can only renounce roles for self") */
      0x04
      dup3
      add
        /* "#utility.yul":14953:14974   */
      mstore
        /* "#utility.yul":15010:15012   */
      0x2f
        /* "#utility.yul":14990:15008   */
      0x24
      dup3
      add
        /* "#utility.yul":14983:15013   */
      mstore
        /* "#utility.yul":15049:15083   */
      0x416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e6365
        /* "#utility.yul":15029:15047   */
      0x44
      dup3
      add
        /* "#utility.yul":15022:15084   */
      mstore
      shl(0x89, 0x103937b632b9903337b91039b2b633)
        /* "#utility.yul":15100:15118   */
      0x64
      dup3
      add
        /* "#utility.yul":15093:15138   */
      mstore
        /* "#utility.yul":15155:15174   */
      0x84
      add
        /* "src/core/utils/access/AccessControl.sol":6091:6174  require(account == _msgSender(), "AccessControl: can only renounce roles for self") */
    tag_315:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_314:
        /* "src/core/utils/access/AccessControl.sol":6185:6211  _revokeRole(role, account) */
      tag_317
        /* "src/core/utils/access/AccessControl.sol":6197:6201  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":6203:6210  account */
      dup3
        /* "src/core/utils/access/AccessControl.sol":6185:6196  _revokeRole */
      tag_318
        /* "src/core/utils/access/AccessControl.sol":6185:6211  _revokeRole(role, account) */
      jump	// in
    tag_317:
        /* "src/core/utils/access/AccessControl.sol":6004:6218  function renounceRole(bytes32 role, address account) public virtual override {... */
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":5696:5841  function getLastFinalizedRequestId() public view returns (uint256) {... */
    tag_119:
        /* "src/core/WithdrawalQueueBase.sol":5754:5761  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":5780:5834  LAST_FINALIZED_REQUEST_ID_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/WithdrawalQueueBase.sol":1522:1578  keccak256("lido.WithdrawalQueue.lastFinalizedRequestId") */
      0x992f2e0c24ce59a21f2dab8bba13b25c2f872129df7f4d45372155e717db0c48
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":6265:6403  function getLastCheckpointIndex() public view returns (uint256) {... */
    tag_122:
        /* "src/core/WithdrawalQueueBase.sol":6320:6327  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6346:6396  LAST_CHECKPOINT_INDEX_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/WithdrawalQueueBase.sol":1849:1902  keccak256("lido.WithdrawalQueue.lastCheckpointIndex") */
      0x9d8be19d6a54e40bd767aa61b0f462241f5562ef6967d7045485bccac825b240
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/utils/PausableUntil.sol":1717:1859  function getResumeSinceTimestamp() external view returns (uint256) {... */
    tag_125:
        /* "src/core/utils/PausableUntil.sol":1775:1782  uint256 */
      0x00
        /* "src/core/utils/PausableUntil.sol":1801:1852  RESUME_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
      tag_297
      0x00
      dup1
      mload
      0x20
      data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/WithdrawalQueue.sol":11880:12410  function claimWithdrawalsTo(uint256[] calldata _requestIds, uint256[] calldata _hints, address _recipient)... */
    tag_130:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":12022:12046  _recipient == address(0) */
      dup2
      and
        /* "src/core/WithdrawalQueue.sol":12018:12070  if (_recipient == address(0)) revert ZeroRecipient() */
      tag_326
      jumpi
        /* "src/core/WithdrawalQueue.sol":12055:12070  ZeroRecipient() */
      mload(0x40)
      shl(0xe0, 0xd27b4443)
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
        /* "src/core/WithdrawalQueue.sol":12018:12070  if (_recipient == address(0)) revert ZeroRecipient() */
    tag_326:
        /* "src/core/WithdrawalQueue.sol":12084:12119  _requestIds.length != _hints.length */
      dup4
      dup3
      eq
        /* "src/core/WithdrawalQueue.sol":12080:12208  if (_requestIds.length != _hints.length) {... */
      tag_327
      jumpi
        /* "src/core/WithdrawalQueue.sol":12142:12197  ArraysLengthMismatch(_requestIds.length, _hints.length) */
      mload(0x40)
      shl(0xe3, 0x098b37e5)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":6957:6982   */
      dup6
      swap1
      mstore
        /* "#utility.yul":6998:7016   */
      0x24
      dup2
      add
        /* "#utility.yul":6991:7025   */
      dup4
      swap1
      mstore
        /* "#utility.yul":6930:6948   */
      0x44
      add
        /* "src/core/WithdrawalQueue.sol":12142:12197  ArraysLengthMismatch(_requestIds.length, _hints.length) */
      tag_315
        /* "#utility.yul":6783:7031   */
      jump
        /* "src/core/WithdrawalQueue.sol":12080:12208  if (_requestIds.length != _hints.length) {... */
    tag_327:
        /* "src/core/WithdrawalQueue.sol":12223:12232  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":12218:12404  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
    tag_329:
        /* "src/core/WithdrawalQueue.sol":12238:12260  i < _requestIds.length */
      dup5
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":12218:12404  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      iszero
      tag_330
      jumpi
        /* "src/core/WithdrawalQueue.sol":12281:12326  _claim(_requestIds[i], _hints[i], _recipient) */
      tag_332
        /* "src/core/WithdrawalQueue.sol":12288:12299  _requestIds */
      dup7
      dup7
        /* "src/core/WithdrawalQueue.sol":12300:12301  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":12288:12302  _requestIds[i] */
      dup2
      dup2
      lt
      tag_334
      jumpi
      tag_334
      tag_290
      jump	// in
    tag_334:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":12304:12310  _hints */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":12311:12312  i */
      dup5
        /* "src/core/WithdrawalQueue.sol":12304:12313  _hints[i] */
      dup2
      dup2
      lt
      tag_336
      jumpi
      tag_336
      tag_290
      jump	// in
    tag_336:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":12315:12325  _recipient */
      dup5
        /* "src/core/WithdrawalQueue.sol":12281:12287  _claim */
      tag_337
        /* "src/core/WithdrawalQueue.sol":12281:12326  _claim(_requestIds[i], _hints[i], _recipient) */
      jump	// in
    tag_332:
        /* "src/core/WithdrawalQueue.sol":12340:12393  _emitTransfer(msg.sender, address(0), _requestIds[i]) */
      tag_338
        /* "src/core/WithdrawalQueue.sol":12354:12364  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":12374:12375  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":12378:12389  _requestIds */
      dup9
      dup9
        /* "src/core/WithdrawalQueue.sol":12390:12391  i */
      dup6
        /* "src/core/WithdrawalQueue.sol":12378:12392  _requestIds[i] */
      dup2
      dup2
      lt
      tag_340
      jumpi
      tag_340
      tag_290
      jump	// in
    tag_340:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":12340:12353  _emitTransfer */
      tag_341
        /* "src/core/WithdrawalQueue.sol":12340:12393  _emitTransfer(msg.sender, address(0), _requestIds[i]) */
      jump	// in
    tag_338:
        /* "src/core/WithdrawalQueue.sol":12262:12265  ++i */
      tag_342
      dup2
      tag_295
      jump	// in
    tag_342:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":12218:12404  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      jump(tag_329)
    tag_330:
      pop
        /* "src/core/WithdrawalQueue.sol":11880:12410  function claimWithdrawalsTo(uint256[] calldata _requestIds, uint256[] calldata _hints, address _recipient)... */
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":14796:15386  function findCheckpointHints(uint256[] calldata _requestIds, uint256 _firstIndex, uint256 _lastIndex)... */
    tag_134:
        /* "src/core/WithdrawalQueue.sol":14945:14969  uint256[] memory hintIds */
      0x60
        /* "src/core/WithdrawalQueue.sol":15009:15020  _requestIds */
      dup4
      sub(shl(0x40, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":14995:15028  new uint256[](_requestIds.length) */
      dup2
      gt
      iszero
      tag_345
      jumpi
      tag_345
      tag_282
      jump	// in
    tag_345:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x20
      mul
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_346
      jumpi
      dup2
      0x20
      add
      0x20
      dup3
      mul
      dup1
      calldatasize
      dup4
      calldatacopy
      add
      swap1
      pop
    tag_346:
      pop
        /* "src/core/WithdrawalQueue.sol":14985:15028  hintIds = new uint256[](_requestIds.length) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":15038:15059  uint256 prevRequestId */
      0x00
        /* "src/core/WithdrawalQueue.sol":15078:15087  uint256 i */
      dup1
        /* "src/core/WithdrawalQueue.sol":15073:15380  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
    tag_347:
        /* "src/core/WithdrawalQueue.sol":15093:15115  i < _requestIds.length */
      dup6
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":15073:15380  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      iszero
      tag_348
      jumpi
        /* "src/core/WithdrawalQueue.sol":15157:15170  prevRequestId */
      dup2
        /* "src/core/WithdrawalQueue.sol":15140:15151  _requestIds */
      dup8
      dup8
        /* "src/core/WithdrawalQueue.sol":15152:15153  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":15140:15154  _requestIds[i] */
      dup2
      dup2
      lt
      tag_351
      jumpi
      tag_351
      tag_290
      jump	// in
    tag_351:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":15140:15170  _requestIds[i] < prevRequestId */
      lt
        /* "src/core/WithdrawalQueue.sol":15136:15200  if (_requestIds[i] < prevRequestId) revert RequestIdsNotSorted() */
      iszero
      tag_352
      jumpi
        /* "src/core/WithdrawalQueue.sol":15179:15200  RequestIdsNotSorted() */
      mload(0x40)
      shl(0xe0, 0x374e8bd1)
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
        /* "src/core/WithdrawalQueue.sol":15136:15200  if (_requestIds[i] < prevRequestId) revert RequestIdsNotSorted() */
    tag_352:
        /* "src/core/WithdrawalQueue.sol":15227:15287  _findCheckpointHint(_requestIds[i], _firstIndex, _lastIndex) */
      tag_353
        /* "src/core/WithdrawalQueue.sol":15247:15258  _requestIds */
      dup8
      dup8
        /* "src/core/WithdrawalQueue.sol":15259:15260  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":15247:15261  _requestIds[i] */
      dup2
      dup2
      lt
      tag_355
      jumpi
      tag_355
      tag_290
      jump	// in
    tag_355:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":15263:15274  _firstIndex */
      dup7
        /* "src/core/WithdrawalQueue.sol":15276:15286  _lastIndex */
      dup7
        /* "src/core/WithdrawalQueue.sol":15227:15246  _findCheckpointHint */
      tag_356
        /* "src/core/WithdrawalQueue.sol":15227:15287  _findCheckpointHint(_requestIds[i], _firstIndex, _lastIndex) */
      jump	// in
    tag_353:
        /* "src/core/WithdrawalQueue.sol":15214:15221  hintIds */
      dup4
        /* "src/core/WithdrawalQueue.sol":15222:15223  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":15214:15224  hintIds[i] */
      dup2
      mload
      dup2
      lt
      tag_358
      jumpi
      tag_358
      tag_290
      jump	// in
    tag_358:
      0x20
      mul
      0x20
      add
      add
        /* "src/core/WithdrawalQueue.sol":15214:15287  hintIds[i] = _findCheckpointHint(_requestIds[i], _firstIndex, _lastIndex) */
      dup2
      dup2
      mstore
      pop
      pop
        /* "src/core/WithdrawalQueue.sol":15315:15322  hintIds */
      dup3
        /* "src/core/WithdrawalQueue.sol":15323:15324  i */
      dup2
        /* "src/core/WithdrawalQueue.sol":15315:15325  hintIds[i] */
      dup2
      mload
      dup2
      lt
      tag_360
      jumpi
      tag_360
      tag_290
      jump	// in
    tag_360:
      0x20
      mul
      0x20
      add
      add
      mload
        /* "src/core/WithdrawalQueue.sol":15301:15325  _firstIndex = hintIds[i] */
      swap5
      pop
        /* "src/core/WithdrawalQueue.sol":15355:15366  _requestIds */
      dup7
      dup7
        /* "src/core/WithdrawalQueue.sol":15367:15368  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":15355:15369  _requestIds[i] */
      dup2
      dup2
      lt
      tag_362
      jumpi
      tag_362
      tag_290
      jump	// in
    tag_362:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":15339:15369  prevRequestId = _requestIds[i] */
      swap2
      pop
        /* "src/core/WithdrawalQueue.sol":15117:15120  ++i */
      dup1
      tag_363
      swap1
      tag_295
      jump	// in
    tag_363:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":15073:15380  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      jump(tag_347)
    tag_348:
      pop
        /* "src/core/WithdrawalQueue.sol":14975:15386  {... */
      pop
        /* "src/core/WithdrawalQueue.sol":14796:15386  function findCheckpointHints(uint256[] calldata _requestIds, uint256 _firstIndex, uint256 _lastIndex)... */
      swap5
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":8815:9193  function requestWithdrawalsWstETHWithPermit(... */
    tag_139:
        /* "src/core/WithdrawalQueue.sol":8982:9009  uint256[] memory requestIds */
      0x60
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":9021:9027  WSTETH */
      immutable("0x6e20e28aa948d9b4a4e4fad29a41b0e2debd981d9d74148d1704f33eeae821e8")
        /* "src/core/WithdrawalQueue.sol":9021:9034  WSTETH.permit */
      and
      0xd505accf
        /* "src/core/WithdrawalQueue.sol":9035:9045  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":9055:9059  this */
      address
        /* "src/core/WithdrawalQueue.sol":9062:9075  _permit.value */
      dup6
      calldataload
        /* "src/core/WithdrawalQueue.sol":9077:9093  _permit.deadline */
      0x20
      dup8
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":9095:9104  _permit.v */
      tag_365
      dup9
      dup9
      add
      0x40
      dup11
      add
      tag_366
      jump	// in
    tag_365:
        /* "src/core/WithdrawalQueue.sol":9106:9113  _permit */
      dup9
        /* "src/core/WithdrawalQueue.sol":9106:9115  _permit.r */
      0x60
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":9117:9124  _permit */
      dup10
        /* "src/core/WithdrawalQueue.sol":9117:9126  _permit.s */
      0x80
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":9021:9127  WSTETH.permit(msg.sender, address(this), _permit.value, _permit.deadline, _permit.v, _permit.r, _permit.s) */
      mload(0x40)
      dup9
      0xffffffff
      and
      0xe0
      shl
      dup2
      mstore
      0x04
      add
      tag_367
      swap8
      swap7
      swap6
      swap5
      swap4
      swap3
      swap2
      swap1
      tag_368
      jump	// in
    tag_367:
      0x00
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x00
      dup8
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_369
      jumpi
      0x00
      dup1
      revert
    tag_369:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_371
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_371:
      pop
      pop
      pop
      pop
        /* "src/core/WithdrawalQueue.sol":9144:9186  requestWithdrawalsWstETH(_amounts, _owner) */
      tag_372
        /* "src/core/WithdrawalQueue.sol":9169:9177  _amounts */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":9179:9185  _owner */
      dup6
        /* "src/core/WithdrawalQueue.sol":9144:9168  requestWithdrawalsWstETH */
      tag_85
        /* "src/core/WithdrawalQueue.sol":9144:9186  requestWithdrawalsWstETH(_amounts, _owner) */
      jump	// in
    tag_372:
        /* "src/core/WithdrawalQueue.sol":9137:9186  return requestWithdrawalsWstETH(_amounts, _owner) */
      swap6
        /* "src/core/WithdrawalQueue.sol":8815:9193  function requestWithdrawalsWstETHWithPermit(... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":9761:9923  function getWithdrawalRequests(address _owner) external view returns (uint256[] memory requestsIds) {... */
    tag_144:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":9878:9907  _getRequestsByOwner()[_owner] */
      dup2
      and
      0x00
      swap1
      dup2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":2197:2246  keccak256("lido.WithdrawalQueue.requestsByOwner") */
      0x4b9bfe0774f05ab288bd50bd23f74ae80a797f1d0c82d419d43ebda4fdc2fe1f
        /* "src/core/WithdrawalQueue.sol":9878:9907  _getRequestsByOwner()[_owner] */
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueue.sol":9831:9859  uint256[] memory requestsIds */
      0x60
      swap1
        /* "src/core/WithdrawalQueue.sol":9878:9916  _getRequestsByOwner()[_owner].values() */
      tag_269
      swap1
        /* "src/core/WithdrawalQueue.sol":9878:9914  _getRequestsByOwner()[_owner].values */
      tag_377
        /* "src/core/WithdrawalQueue.sol":9878:9916  _getRequestsByOwner()[_owner].values() */
      jump	// in
        /* "src/core/utils/Versioned.sol":1278:1407  function getContractVersion() public view returns (uint256) {... */
    tag_147:
        /* "src/core/utils/Versioned.sol":1329:1336  uint256 */
      0x00
        /* "src/core/utils/Versioned.sol":1355:1400  CONTRACT_VERSION_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/utils/Versioned.sol":913:956  keccak256("lido.Versioned.contractVersion") */
      0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/utils/access/AccessControlEnumerable.sol":2074:2226  function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {... */
    tag_152:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2156:2163  address */
      0x00
        /* "src/core/utils/access/AccessControlEnumerable.sol":2182:2209  _storageRoleMembers()[role] */
      dup3
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_8c85144e36a363d47a080fe4c41afdc57727e34b590650d5b653cdd378d93afe
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      dup2
      keccak256
        /* "src/core/utils/access/AccessControlEnumerable.sol":2182:2219  _storageRoleMembers()[role].at(index) */
      tag_381
      swap1
        /* "src/core/utils/access/AccessControlEnumerable.sol":2213:2218  index */
      dup4
        /* "src/core/utils/access/AccessControlEnumerable.sol":2182:2212  _storageRoleMembers()[role].at */
      tag_384
        /* "src/core/utils/access/AccessControlEnumerable.sol":2182:2219  _storageRoleMembers()[role].at(index) */
      jump	// in
    tag_381:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2175:2219  return _storageRoleMembers()[role].at(index) */
      swap4
        /* "src/core/utils/access/AccessControlEnumerable.sol":2074:2226  function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":3515:3661  function hasRole(bytes32 role, address account) public view override returns (bool) {... */
    tag_157:
        /* "src/core/utils/access/AccessControl.sol":3593:3597  bool */
      0x00
        /* "src/core/utils/access/AccessControl.sol":3616:3637  _storageRoles()[role] */
      swap2
      dup3
      mstore
      0x00
      dup1
      mload
      0x20
      data_91113e80635bccc2f93908fdf2a5cbd6a74badad069abcad4f85e45f73ab3f4c
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup5
      keccak256
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/utils/access/AccessControl.sol":3616:3654  _storageRoles()[role].members[account] */
      swap4
      swap1
      swap4
      and
      dup5
      mstore
      swap2
      swap1
      mstore
      swap1
      keccak256
      sload
      0xff
      and
      swap1
        /* "src/core/utils/access/AccessControl.sol":3515:3661  function hasRole(bytes32 role, address account) public view override returns (bool) {... */
      jump	// out
        /* "src/core/WithdrawalQueue.sol":15745:16795  function onOracleReport(bool _isBunkerModeNow, uint256 _bunkerStartTimestamp, uint256 _currentReportTimestamp)... */
    tag_162:
        /* "src/core/WithdrawalQueue.sol":15887:15922  _checkRole(ORACLE_ROLE, msg.sender) */
      tag_388
        /* "src/core/WithdrawalQueue.sol":2330:2354  keccak256("ORACLE_ROLE") */
      0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1
        /* "src/core/WithdrawalQueue.sol":15911:15921  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":15887:15897  _checkRole */
      tag_273
        /* "src/core/WithdrawalQueue.sol":15887:15922  _checkRole(ORACLE_ROLE, msg.sender) */
      jump	// in
    tag_388:
        /* "src/core/WithdrawalQueue.sol":15961:15976  block.timestamp */
      timestamp
        /* "src/core/WithdrawalQueue.sol":15936:15957  _bunkerStartTimestamp */
      dup3
        /* "src/core/WithdrawalQueue.sol":15936:15976  _bunkerStartTimestamp >= block.timestamp */
      lt
        /* "src/core/WithdrawalQueue.sol":15932:16009  if (_bunkerStartTimestamp >= block.timestamp) revert InvalidReportTimestamp() */
      tag_389
      jumpi
        /* "src/core/WithdrawalQueue.sol":15985:16009  InvalidReportTimestamp() */
      mload(0x40)
      shl(0xe0, 0x34819c03)
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
        /* "src/core/WithdrawalQueue.sol":15932:16009  if (_bunkerStartTimestamp >= block.timestamp) revert InvalidReportTimestamp() */
    tag_389:
        /* "src/core/WithdrawalQueue.sol":16050:16065  block.timestamp */
      timestamp
        /* "src/core/WithdrawalQueue.sol":16023:16046  _currentReportTimestamp */
      dup2
        /* "src/core/WithdrawalQueue.sol":16023:16065  _currentReportTimestamp >= block.timestamp */
      lt
        /* "src/core/WithdrawalQueue.sol":16019:16098  if (_currentReportTimestamp >= block.timestamp) revert InvalidReportTimestamp() */
      tag_390
      jumpi
        /* "src/core/WithdrawalQueue.sol":16074:16098  InvalidReportTimestamp() */
      mload(0x40)
      shl(0xe0, 0x34819c03)
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
        /* "src/core/WithdrawalQueue.sol":16019:16098  if (_currentReportTimestamp >= block.timestamp) revert InvalidReportTimestamp() */
    tag_390:
        /* "src/core/WithdrawalQueue.sol":16109:16157  _setLastReportTimestamp(_currentReportTimestamp) */
      tag_391
        /* "src/core/WithdrawalQueue.sol":16133:16156  _currentReportTimestamp */
      dup2
        /* "src/core/WithdrawalQueue.sol":16109:16132  _setLastReportTimestamp */
      tag_392
        /* "src/core/WithdrawalQueue.sol":16109:16157  _setLastReportTimestamp(_currentReportTimestamp) */
      jump	// in
    tag_391:
        /* "src/core/WithdrawalQueue.sol":16168:16197  bool isBunkerModeWasSetBefore */
      0x00
        /* "src/core/WithdrawalQueue.sol":16200:16220  isBunkerModeActive() */
      tag_393
        /* "src/core/WithdrawalQueue.sol":16200:16218  isBunkerModeActive */
      tag_103
        /* "src/core/WithdrawalQueue.sol":16200:16220  isBunkerModeActive() */
      jump	// in
    tag_393:
        /* "src/core/WithdrawalQueue.sol":16168:16220  bool isBunkerModeWasSetBefore = isBunkerModeActive() */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":16294:16318  isBunkerModeWasSetBefore */
      dup1
        /* "src/core/WithdrawalQueue.sol":16274:16318  _isBunkerModeNow != isBunkerModeWasSetBefore */
      iszero
      iszero
        /* "src/core/WithdrawalQueue.sol":16274:16290  _isBunkerModeNow */
      dup5
        /* "src/core/WithdrawalQueue.sol":16274:16318  _isBunkerModeNow != isBunkerModeWasSetBefore */
      iszero
      iszero
      eq
        /* "src/core/WithdrawalQueue.sol":16270:16789  if (_isBunkerModeNow != isBunkerModeWasSetBefore) {... */
      tag_398
      jumpi
        /* "src/core/WithdrawalQueue.sol":16418:16434  _isBunkerModeNow */
      dup4
        /* "src/core/WithdrawalQueue.sol":16414:16779  if (_isBunkerModeNow) {... */
      iszero
      tag_395
      jumpi
        /* "src/core/WithdrawalQueue.sol":16454:16531  BUNKER_MODE_SINCE_TIMESTAMP_POSITION.setStorageUint256(_bunkerStartTimestamp) */
      tag_396
      0x00
      dup1
      mload
      0x20
      data_b589db986128d3258a700f5bc8482afbd859dc508593ec30968f79002edbed47
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/WithdrawalQueue.sol":16509:16530  _bunkerStartTimestamp */
      dup5
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/WithdrawalQueue.sol":16454:16531  BUNKER_MODE_SINCE_TIMESTAMP_POSITION.setStorageUint256(_bunkerStartTimestamp) */
    tag_396:
        /* "src/core/WithdrawalQueue.sol":16555:16595  BunkerModeEnabled(_bunkerStartTimestamp) */
      mload(0x40)
        /* "#utility.yul":643:668   */
      dup4
      dup2
      mstore
        /* "src/core/WithdrawalQueue.sol":16555:16595  BunkerModeEnabled(_bunkerStartTimestamp) */
      0x47f03b07e5b5377f871539bb2942f5ecb72733be9fc9d55a17b6d6a05d418345
      swap1
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
        /* "src/core/WithdrawalQueue.sol":16555:16595  BunkerModeEnabled(_bunkerStartTimestamp) */
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log1
        /* "src/core/WithdrawalQueue.sol":16414:16779  if (_isBunkerModeNow) {... */
      jump(tag_398)
    tag_395:
      not(0x00)
      0x00
      dup1
      mload
      0x20
      data_b589db986128d3258a700f5bc8482afbd859dc508593ec30968f79002edbed47
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      sstore
        /* "src/core/WithdrawalQueue.sol":16744:16764  BunkerModeDisabled() */
      mload(0x40)
      0xd1f8a2998c0caf73e09434aa93d273a599060d789407c6f70ccd4c9c9f32c8f4
      swap1
      0x00
      swap1
      log1
        /* "src/core/WithdrawalQueue.sol":16414:16779  if (_isBunkerModeNow) {... */
    tag_398:
        /* "src/core/WithdrawalQueue.sol":15877:16795  {... */
      pop
        /* "src/core/WithdrawalQueue.sol":15745:16795  function onOracleReport(bool _isBunkerModeNow, uint256 _bunkerStartTimestamp, uint256 _currentReportTimestamp)... */
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":17158:17304  function bunkerModeSinceTimestamp() public view returns (uint256) {... */
    tag_164:
        /* "src/core/WithdrawalQueue.sol":17215:17222  uint256 */
      0x00
        /* "src/core/WithdrawalQueue.sol":17241:17297  BUNKER_MODE_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
      tag_297
      0x00
      dup1
      mload
      0x20
      data_b589db986128d3258a700f5bc8482afbd859dc508593ec30968f79002edbed47
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":15105:16633  function prefinalize(uint256[] calldata _batches, uint256 _maxShareRate)... */
    tag_175:
        /* "src/core/WithdrawalQueueBase.sol":15225:15242  uint256 ethToLock */
      0x00
      dup1
        /* "src/core/WithdrawalQueueBase.sol":15284:15302  _maxShareRate == 0 */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":15280:15326  if (_maxShareRate == 0) revert ZeroShareRate() */
      tag_403
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15311:15326  ZeroShareRate() */
      mload(0x40)
      shl(0xe0, 0xe4e97357)
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
        /* "src/core/WithdrawalQueueBase.sol":15280:15326  if (_maxShareRate == 0) revert ZeroShareRate() */
    tag_403:
        /* "src/core/WithdrawalQueueBase.sol":15340:15360  _batches.length == 0 */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":15336:15383  if (_batches.length == 0) revert EmptyBatches() */
      tag_404
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15369:15383  EmptyBatches() */
      mload(0x40)
      shl(0xe0, 0x12de1df3)
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
        /* "src/core/WithdrawalQueueBase.sol":15336:15383  if (_batches.length == 0) revert EmptyBatches() */
    tag_404:
        /* "src/core/WithdrawalQueueBase.sol":15413:15440  getLastFinalizedRequestId() */
      tag_405
        /* "src/core/WithdrawalQueueBase.sol":15413:15438  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":15413:15440  getLastFinalizedRequestId() */
      jump	// in
    tag_405:
        /* "src/core/WithdrawalQueueBase.sol":15398:15406  _batches */
      dup6
      dup6
        /* "src/core/WithdrawalQueueBase.sol":15407:15408  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":15398:15409  _batches[0] */
      dup2
      dup2
      lt
      tag_407
      jumpi
      tag_407
      tag_290
      jump	// in
    tag_407:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueueBase.sol":15398:15440  _batches[0] <= getLastFinalizedRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":15394:15478  if (_batches[0] <= getLastFinalizedRequestId()) revert InvalidRequestId(_batches[0]) */
      tag_408
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15466:15474  _batches */
      dup5
      dup5
        /* "src/core/WithdrawalQueueBase.sol":15475:15476  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":15466:15477  _batches[0] */
      dup2
      dup2
      lt
      tag_410
      jumpi
      tag_410
      tag_290
      jump	// in
    tag_410:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueueBase.sol":15449:15478  InvalidRequestId(_batches[0]) */
      mload(0x40)
      shl(0xe1, 0x64b4f079)
      dup2
      mstore
      0x04
      add
      tag_315
      swap2
        /* "#utility.yul":643:668   */
      dup2
      mstore
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
      swap1
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":15394:15478  if (_batches[0] <= getLastFinalizedRequestId()) revert InvalidRequestId(_batches[0]) */
    tag_408:
        /* "src/core/WithdrawalQueueBase.sol":15524:15542  getLastRequestId() */
      tag_412
        /* "src/core/WithdrawalQueueBase.sol":15524:15540  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":15524:15542  getLastRequestId() */
      jump	// in
    tag_412:
        /* "src/core/WithdrawalQueueBase.sol":15492:15500  _batches */
      dup6
      dup6
        /* "src/core/WithdrawalQueueBase.sol":15501:15520  _batches.length - 1 */
      tag_413
        /* "src/core/WithdrawalQueueBase.sol":15519:15520  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":15492:15500  _batches */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":15501:15520  _batches.length - 1 */
      tag_414
      jump	// in
    tag_413:
        /* "src/core/WithdrawalQueueBase.sol":15492:15521  _batches[_batches.length - 1] */
      dup2
      dup2
      lt
      tag_416
      jumpi
      tag_416
      tag_290
      jump	// in
    tag_416:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueueBase.sol":15492:15542  _batches[_batches.length - 1] > getLastRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":15488:15598  if (_batches[_batches.length - 1] > getLastRequestId()) revert InvalidRequestId(_batches[_batches.length - 1]) */
      iszero
      tag_417
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15568:15576  _batches */
      dup5
      dup5
        /* "src/core/WithdrawalQueueBase.sol":15577:15596  _batches.length - 1 */
      tag_418
        /* "src/core/WithdrawalQueueBase.sol":15595:15596  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":15568:15576  _batches */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":15577:15596  _batches.length - 1 */
      tag_414
      jump	// in
    tag_418:
        /* "src/core/WithdrawalQueueBase.sol":15568:15597  _batches[_batches.length - 1] */
      dup2
      dup2
      lt
      tag_410
      jumpi
      tag_410
      tag_290
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":15488:15598  if (_batches[_batches.length - 1] > getLastRequestId()) revert InvalidRequestId(_batches[_batches.length - 1]) */
    tag_417:
        /* "src/core/WithdrawalQueueBase.sol":15609:15634  uint256 currentBatchIndex */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":15644:15673  uint256 prevBatchEndRequestId */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":15676:15703  getLastFinalizedRequestId() */
      tag_422
        /* "src/core/WithdrawalQueueBase.sol":15676:15701  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":15676:15703  getLastFinalizedRequestId() */
      jump	// in
    tag_422:
        /* "src/core/WithdrawalQueueBase.sol":15644:15703  uint256 prevBatchEndRequestId = getLastFinalizedRequestId() */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":15713:15750  WithdrawalRequest memory prevBatchEnd */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":15753:15764  _getQueue() */
      tag_423
        /* "src/core/WithdrawalQueueBase.sol":15753:15762  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":15753:15764  _getQueue() */
      jump	// in
    tag_423:
        /* "src/core/WithdrawalQueueBase.sol":15753:15787  _getQueue()[prevBatchEndRequestId] */
      0x00
      dup4
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      swap1
      dup2
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":15713:15787  WithdrawalRequest memory prevBatchEnd = _getQueue()[prevBatchEndRequestId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap4
      dup2
      add
      swap4
      swap1
      swap4
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup5
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup3
      add
      mstore
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":15797:16627  while (currentBatchIndex < _batches.length) {... */
    tag_425:
        /* "src/core/WithdrawalQueueBase.sol":15804:15839  currentBatchIndex < _batches.length */
      dup7
      dup4
      lt
        /* "src/core/WithdrawalQueueBase.sol":15797:16627  while (currentBatchIndex < _batches.length) {... */
      iszero
      tag_426
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15855:15880  uint256 batchEndRequestId */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":15883:15891  _batches */
      dup9
      dup9
        /* "src/core/WithdrawalQueueBase.sol":15892:15909  currentBatchIndex */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":15883:15910  _batches[currentBatchIndex] */
      dup2
      dup2
      lt
      tag_428
      jumpi
      tag_428
      tag_290
      jump	// in
    tag_428:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueueBase.sol":15855:15910  uint256 batchEndRequestId = _batches[currentBatchIndex] */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":15949:15970  prevBatchEndRequestId */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":15928:15945  batchEndRequestId */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":15928:15970  batchEndRequestId <= prevBatchEndRequestId */
      gt
        /* "src/core/WithdrawalQueueBase.sol":15924:16000  if (batchEndRequestId <= prevBatchEndRequestId) revert BatchesAreNotSorted() */
      tag_429
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":15979:16000  BatchesAreNotSorted() */
      mload(0x40)
      shl(0xe2, 0x337c4a71)
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
        /* "src/core/WithdrawalQueueBase.sol":15924:16000  if (batchEndRequestId <= prevBatchEndRequestId) revert BatchesAreNotSorted() */
    tag_429:
        /* "src/core/WithdrawalQueueBase.sol":16015:16048  WithdrawalRequest memory batchEnd */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":16051:16062  _getQueue() */
      tag_430
        /* "src/core/WithdrawalQueueBase.sol":16051:16060  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":16051:16062  _getQueue() */
      jump	// in
    tag_430:
        /* "src/core/WithdrawalQueueBase.sol":16051:16081  _getQueue()[batchEndRequestId] */
      0x00
      dup4
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":16015:16081  WithdrawalRequest memory batchEnd = _getQueue()[batchEndRequestId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap5
      dup2
      add
      swap5
      swap1
      swap5
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup5
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup6
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup6
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup4
      add
      mstore
      swap1
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":16051:16081  _getQueue()[batchEndRequestId] */
      dup1
      dup1
        /* "src/core/WithdrawalQueueBase.sol":16154:16188  _calcBatch(prevBatchEnd, batchEnd) */
      tag_431
        /* "src/core/WithdrawalQueueBase.sol":16165:16177  prevBatchEnd */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":16015:16081  WithdrawalRequest memory batchEnd = _getQueue()[batchEndRequestId] */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":16154:16164  _calcBatch */
      tag_432
        /* "src/core/WithdrawalQueueBase.sol":16154:16188  _calcBatch(prevBatchEnd, batchEnd) */
      jump	// in
    tag_431:
        /* "src/core/WithdrawalQueueBase.sol":16096:16188  (uint256 batchShareRate, uint256 stETH, uint256 shares) = _calcBatch(prevBatchEnd, batchEnd) */
      swap3
      pop
      swap3
      pop
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":16224:16237  _maxShareRate */
      dup11
        /* "src/core/WithdrawalQueueBase.sol":16207:16221  batchShareRate */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":16207:16237  batchShareRate > _maxShareRate */
      gt
        /* "src/core/WithdrawalQueueBase.sol":16203:16442  if (batchShareRate > _maxShareRate) {... */
      iszero
      tag_433
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":952:956  1e27 */
      0x033b2e3c9fd0803ce8000000
        /* "src/core/WithdrawalQueueBase.sol":16300:16322  shares * _maxShareRate */
      tag_434
        /* "src/core/WithdrawalQueueBase.sol":16309:16322  _maxShareRate */
      dup13
        /* "src/core/WithdrawalQueueBase.sol":16300:16306  shares */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":16300:16322  shares * _maxShareRate */
      tag_435
      jump	// in
    tag_434:
        /* "src/core/WithdrawalQueueBase.sol":16300:16343  shares * _maxShareRate / E27_PRECISION_BASE */
      tag_436
      swap2
      swap1
      tag_437
      jump	// in
    tag_436:
        /* "src/core/WithdrawalQueueBase.sol":16287:16343  ethToLock += shares * _maxShareRate / E27_PRECISION_BASE */
      tag_438
      swap1
      dup12
      tag_439
      jump	// in
    tag_438:
      swap10
      pop
        /* "src/core/WithdrawalQueueBase.sol":16203:16442  if (batchShareRate > _maxShareRate) {... */
      jump(tag_440)
    tag_433:
        /* "src/core/WithdrawalQueueBase.sol":16409:16427  ethToLock += stETH */
      tag_441
        /* "src/core/WithdrawalQueueBase.sol":16422:16427  stETH */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":16409:16427  ethToLock += stETH */
      dup12
      tag_439
      jump	// in
    tag_441:
      swap10
      pop
        /* "src/core/WithdrawalQueueBase.sol":16203:16442  if (batchShareRate > _maxShareRate) {... */
    tag_440:
        /* "src/core/WithdrawalQueueBase.sol":16455:16477  sharesToBurn += shares */
      tag_442
        /* "src/core/WithdrawalQueueBase.sol":16471:16477  shares */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":16455:16477  sharesToBurn += shares */
      dup11
      tag_439
      jump	// in
    tag_442:
      swap9
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":16595:16614  ++currentBatchIndex */
      0x01
      swap1
      swap7
      add
      swap6
      pop
        /* "src/core/WithdrawalQueueBase.sol":16516:16533  batchEndRequestId */
      swap2
      swap4
      pop
        /* "src/core/WithdrawalQueueBase.sol":16562:16570  batchEnd */
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":15797:16627  while (currentBatchIndex < _batches.length) {... */
      tag_425
      swap1
      pop
      jump
    tag_426:
        /* "src/core/WithdrawalQueueBase.sol":15270:16633  {... */
      pop
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":15105:16633  function prefinalize(uint256[] calldata _batches, uint256 _maxShareRate)... */
      swap4
      pop
      swap4
      swap2
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":5195:5325  function pauseUntil(uint256 _pauseUntilInclusive) external onlyRole(PAUSE_ROLE) {... */
    tag_181:
        /* "src/core/WithdrawalQueue.sol":2123:2146  keccak256("PAUSE_ROLE") */
      0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      tag_444
        /* "src/core/WithdrawalQueue.sol":2123:2146  keccak256("PAUSE_ROLE") */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
        /* "src/core/utils/access/AccessControl.sol":3111:3121  _checkRole */
      tag_273
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      jump	// in
    tag_444:
        /* "src/core/WithdrawalQueue.sol":5285:5318  _pauseUntil(_pauseUntilInclusive) */
      tag_317
        /* "src/core/WithdrawalQueue.sol":5297:5317  _pauseUntilInclusive */
      dup3
        /* "src/core/WithdrawalQueue.sol":5285:5296  _pauseUntil */
      tag_448
        /* "src/core/WithdrawalQueue.sol":5285:5318  _pauseUntil(_pauseUntilInclusive) */
      jump	// in
        /* "src/core/WithdrawalQueue.sol":7906:8261  function requestWithdrawalsWithPermit(uint256[] calldata _amounts, address _owner, PermitInput calldata _permit)... */
    tag_184:
        /* "src/core/WithdrawalQueue.sol":8053:8080  uint256[] memory requestIds */
      0x60
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":8096:8101  STETH */
      immutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
        /* "src/core/WithdrawalQueue.sol":8096:8108  STETH.permit */
      and
      0xd505accf
        /* "src/core/WithdrawalQueue.sol":8109:8119  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":8129:8133  this */
      address
        /* "src/core/WithdrawalQueue.sol":8136:8149  _permit.value */
      dup6
      calldataload
        /* "src/core/WithdrawalQueue.sol":8151:8167  _permit.deadline */
      0x20
      dup8
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":8169:8178  _permit.v */
      tag_450
      dup9
      dup9
      add
      0x40
      dup11
      add
      tag_366
      jump	// in
    tag_450:
        /* "src/core/WithdrawalQueue.sol":8180:8187  _permit */
      dup9
        /* "src/core/WithdrawalQueue.sol":8180:8189  _permit.r */
      0x60
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":8191:8198  _permit */
      dup10
        /* "src/core/WithdrawalQueue.sol":8191:8200  _permit.s */
      0x80
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":8096:8201  STETH.permit(msg.sender, address(this), _permit.value, _permit.deadline, _permit.v, _permit.r, _permit.s) */
      mload(0x40)
      dup9
      0xffffffff
      and
      0xe0
      shl
      dup2
      mstore
      0x04
      add
      tag_451
      swap8
      swap7
      swap6
      swap5
      swap4
      swap3
      swap2
      swap1
      tag_368
      jump	// in
    tag_451:
      0x00
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x00
      dup8
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_452
      jumpi
      0x00
      dup1
      revert
    tag_452:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_454
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_454:
      pop
      pop
      pop
      pop
        /* "src/core/WithdrawalQueue.sol":8218:8254  requestWithdrawals(_amounts, _owner) */
      tag_372
        /* "src/core/WithdrawalQueue.sol":8237:8245  _amounts */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":8247:8253  _owner */
      dup6
        /* "src/core/WithdrawalQueue.sol":8218:8236  requestWithdrawals */
      tag_222
        /* "src/core/WithdrawalQueue.sol":8218:8254  requestWithdrawals(_amounts, _owner) */
      jump	// in
        /* "src/core/utils/PausableUntil.sol":1348:1488  function isPaused() public view returns (bool) {... */
    tag_187:
        /* "src/core/utils/PausableUntil.sol":1389:1393  bool */
      0x00
        /* "src/core/utils/PausableUntil.sol":1430:1481  RESUME_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
      tag_457
      0x00
      dup1
      mload
      0x20
      data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/utils/PausableUntil.sol":1430:1481  RESUME_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
    tag_457:
        /* "src/core/utils/PausableUntil.sol":1412:1427  block.timestamp */
      timestamp
        /* "src/core/utils/PausableUntil.sol":1412:1481  block.timestamp < RESUME_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
      lt
        /* "src/core/utils/PausableUntil.sol":1405:1481  return block.timestamp < RESUME_SINCE_TIMESTAMP_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/core/utils/PausableUntil.sol":1348:1488  function isPaused() public view returns (bool) {... */
      swap1
      jump	// out
        /* "src/core/WithdrawalQueue.sol":10050:10405  function getWithdrawalStatus(uint256[] calldata _requestIds)... */
    tag_192:
        /* "src/core/WithdrawalQueue.sol":10158:10199  WithdrawalRequestStatus[] memory statuses */
      0x60
        /* "src/core/WithdrawalQueue.sol":10256:10267  _requestIds */
      dup2
      sub(shl(0x40, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":10226:10275  new WithdrawalRequestStatus[](_requestIds.length) */
      dup2
      gt
      iszero
      tag_460
      jumpi
      tag_460
      tag_282
      jump	// in
    tag_460:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x20
      mul
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_461
      jumpi
      dup2
      0x20
      add
    tag_462:
      tag_463
      tag_464
      jump	// in
    tag_463:
      dup2
      mstore
      0x20
      add
      swap1
      0x01
      swap1
      sub
      swap1
      dup2
      tag_462
      jumpi
      swap1
      pop
    tag_461:
      pop
        /* "src/core/WithdrawalQueue.sol":10215:10275  statuses = new WithdrawalRequestStatus[](_requestIds.length) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":10290:10299  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":10285:10399  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
    tag_465:
        /* "src/core/WithdrawalQueue.sol":10305:10327  i < _requestIds.length */
      dup3
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":10285:10399  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      iszero
      tag_466
      jumpi
        /* "src/core/WithdrawalQueue.sol":10362:10388  _getStatus(_requestIds[i]) */
      tag_468
        /* "src/core/WithdrawalQueue.sol":10373:10384  _requestIds */
      dup5
      dup5
        /* "src/core/WithdrawalQueue.sol":10385:10386  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":10373:10387  _requestIds[i] */
      dup2
      dup2
      lt
      tag_470
      jumpi
      tag_470
      tag_290
      jump	// in
    tag_470:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":10362:10372  _getStatus */
      tag_471
        /* "src/core/WithdrawalQueue.sol":10362:10388  _getStatus(_requestIds[i]) */
      jump	// in
    tag_468:
        /* "src/core/WithdrawalQueue.sol":10348:10356  statuses */
      dup3
        /* "src/core/WithdrawalQueue.sol":10357:10358  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":10348:10359  statuses[i] */
      dup2
      mload
      dup2
      lt
      tag_473
      jumpi
      tag_473
      tag_290
      jump	// in
    tag_473:
      0x20
      mul
      0x20
      add
      add
        /* "src/core/WithdrawalQueue.sol":10348:10388  statuses[i] = _getStatus(_requestIds[i]) */
      dup2
      swap1
      mstore
      pop
        /* "src/core/WithdrawalQueue.sol":10329:10332  ++i */
      dup1
      tag_474
      swap1
      tag_295
      jump	// in
    tag_474:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":10285:10399  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      jump(tag_465)
    tag_466:
      pop
        /* "src/core/WithdrawalQueue.sol":10050:10405  function getWithdrawalStatus(uint256[] calldata _requestIds)... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":6480:6620  function unfinalizedRequestNumber() external view returns (uint256) {... */
    tag_196:
        /* "src/core/WithdrawalQueueBase.sol":6539:6546  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6586:6613  getLastFinalizedRequestId() */
      tag_476
        /* "src/core/WithdrawalQueueBase.sol":6586:6611  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":6586:6613  getLastFinalizedRequestId() */
      jump	// in
    tag_476:
        /* "src/core/WithdrawalQueueBase.sol":6565:6583  getLastRequestId() */
      tag_477
        /* "src/core/WithdrawalQueueBase.sol":6565:6581  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":6565:6583  getLastRequestId() */
      jump	// in
    tag_477:
        /* "src/core/WithdrawalQueueBase.sol":6565:6613  getLastRequestId() - getLastFinalizedRequestId() */
      tag_297
      swap2
      swap1
      tag_414
      jump	// in
        /* "src/core/WithdrawalQueue.sol":3960:4103  function initialize(address _admin) external {... */
    tag_200:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":4019:4039  _admin == address(0) */
      dup2
      and
        /* "src/core/WithdrawalQueue.sol":4015:4066  if (_admin == address(0)) revert AdminZeroAddress() */
      tag_480
      jumpi
        /* "src/core/WithdrawalQueue.sol":4048:4066  AdminZeroAddress() */
      mload(0x40)
      shl(0xe1, 0x016b8ae1)
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
        /* "src/core/WithdrawalQueue.sol":4015:4066  if (_admin == address(0)) revert AdminZeroAddress() */
    tag_480:
        /* "src/core/WithdrawalQueue.sol":4077:4096  _initialize(_admin) */
      tag_481
        /* "src/core/WithdrawalQueue.sol":4089:4095  _admin */
      dup2
        /* "src/core/WithdrawalQueue.sol":4077:4088  _initialize */
      tag_482
        /* "src/core/WithdrawalQueue.sol":4077:4096  _initialize(_admin) */
      jump	// in
    tag_481:
        /* "src/core/WithdrawalQueue.sol":3960:4103  function initialize(address _admin) external {... */
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":10826:11223  function getClaimableEther(uint256[] calldata _requestIds, uint256[] calldata _hints)... */
    tag_204:
        /* "src/core/WithdrawalQueue.sol":10959:10994  uint256[] memory claimableEthValues */
      0x60
        /* "src/core/WithdrawalQueue.sol":11045:11056  _requestIds */
      dup4
      sub(shl(0x40, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":11031:11064  new uint256[](_requestIds.length) */
      dup2
      gt
      iszero
      tag_485
      jumpi
      tag_485
      tag_282
      jump	// in
    tag_485:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x20
      mul
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_486
      jumpi
      dup2
      0x20
      add
      0x20
      dup3
      mul
      dup1
      calldatasize
      dup4
      calldatacopy
      add
      swap1
      pop
    tag_486:
      pop
        /* "src/core/WithdrawalQueue.sol":11010:11064  claimableEthValues = new uint256[](_requestIds.length) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":11079:11088  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":11074:11217  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
    tag_487:
        /* "src/core/WithdrawalQueue.sol":11094:11116  i < _requestIds.length */
      dup5
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":11074:11217  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      iszero
      tag_488
      jumpi
        /* "src/core/WithdrawalQueue.sol":11161:11206  _getClaimableEther(_requestIds[i], _hints[i]) */
      tag_490
        /* "src/core/WithdrawalQueue.sol":11180:11191  _requestIds */
      dup7
      dup7
        /* "src/core/WithdrawalQueue.sol":11192:11193  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":11180:11194  _requestIds[i] */
      dup2
      dup2
      lt
      tag_492
      jumpi
      tag_492
      tag_290
      jump	// in
    tag_492:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":11196:11202  _hints */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":11203:11204  i */
      dup5
        /* "src/core/WithdrawalQueue.sol":11196:11205  _hints[i] */
      dup2
      dup2
      lt
      tag_494
      jumpi
      tag_494
      tag_290
      jump	// in
    tag_494:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":11161:11179  _getClaimableEther */
      tag_495
        /* "src/core/WithdrawalQueue.sol":11161:11206  _getClaimableEther(_requestIds[i], _hints[i]) */
      jump	// in
    tag_490:
        /* "src/core/WithdrawalQueue.sol":11137:11155  claimableEthValues */
      dup3
        /* "src/core/WithdrawalQueue.sol":11156:11157  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":11137:11158  claimableEthValues[i] */
      dup2
      mload
      dup2
      lt
      tag_497
      jumpi
      tag_497
      tag_290
      jump	// in
    tag_497:
      0x20
      swap1
      dup2
      mul
      swap2
      swap1
      swap2
      add
      add
        /* "src/core/WithdrawalQueue.sol":11137:11206  claimableEthValues[i] = _getClaimableEther(_requestIds[i], _hints[i]) */
      mstore
        /* "src/core/WithdrawalQueue.sol":11118:11121  ++i */
      tag_498
      dup2
      tag_295
      jump	// in
    tag_498:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":11074:11217  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      jump(tag_487)
    tag_488:
      pop
        /* "src/core/WithdrawalQueue.sol":10826:11223  function getClaimableEther(uint256[] calldata _requestIds, uint256[] calldata _hints)... */
      swap5
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/utils/access/AccessControlEnumerable.sol":2394:2535  function getRoleMemberCount(bytes32 role) public view override returns (uint256) {... */
    tag_208:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2466:2473  uint256 */
      0x00
        /* "src/core/utils/access/AccessControlEnumerable.sol":2492:2519  _storageRoleMembers()[role] */
      dup2
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_8c85144e36a363d47a080fe4c41afdc57727e34b590650d5b653cdd378d93afe
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      dup2
      keccak256
        /* "src/core/utils/access/AccessControlEnumerable.sol":2492:2528  _storageRoleMembers()[role].length() */
      tag_269
      swap1
        /* "src/core/utils/access/AccessControlEnumerable.sol":2492:2526  _storageRoleMembers()[role].length */
      tag_502
        /* "src/core/utils/access/AccessControlEnumerable.sol":2492:2528  _storageRoleMembers()[role].length() */
      jump	// in
        /* "src/RequestHarness.sol":742:964  function seed(uint256 id,uint128 st,uint128 sh,uint256 report) external {... */
    tag_213:
        /* "src/RequestHarness.sol":824:845  _setLastRequestId(id) */
      tag_504
        /* "src/RequestHarness.sol":842:844  id */
      dup5
        /* "src/RequestHarness.sol":824:841  _setLastRequestId */
      tag_505
        /* "src/RequestHarness.sol":824:845  _setLastRequestId(id) */
      jump	// in
    tag_504:
        /* "src/RequestHarness.sol":871:916  WithdrawalRequest(st,sh,address(0),0,false,0) */
      0x40
      dup1
      mload
      0xc0
      dup2
      add
      dup3
      mstore
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup7
      and
      dup3
      mstore
      dup5
      and
      0x20
      dup3
      add
      mstore
      0x00
      swap2
      dup2
      add
      dup3
      swap1
      mstore
      0x60
      dup2
      add
      dup3
      swap1
      mstore
      0x80
      dup2
      add
      dup3
      swap1
      mstore
      0xa0
      dup2
      add
      swap2
      swap1
      swap2
      mstore
        /* "src/RequestHarness.sol":855:866  _getQueue() */
      tag_506
        /* "src/RequestHarness.sol":855:864  _getQueue */
      tag_424
        /* "src/RequestHarness.sol":855:866  _getQueue() */
      jump	// in
    tag_506:
        /* "src/RequestHarness.sol":855:870  _getQueue()[id] */
      0x00
      dup7
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      swap1
      dup2
      swap1
      keccak256
        /* "src/RequestHarness.sol":855:916  _getQueue()[id]=WithdrawalRequest(st,sh,address(0),0,false,0) */
      dup4
      mload
      swap3
      dup5
      add
      mload
      sub(shl(0x80, 0x01), 0x01)
      swap4
      dup5
      and
      shl(0x80, 0x01)
      swap5
      swap1
      swap2
      and
      swap4
      swap1
      swap4
      mul
      swap3
      swap1
      swap3
      or
      dup3
      sstore
      dup3
      add
      mload
      0x01
      swap1
      swap2
      add
      dup1
      sload
      0x60
      dup5
      add
      mload
      0x80
      dup6
      add
      mload
      0xa0
      swap1
      swap6
      add
      mload
      sub(shl(0xa0, 0x01), 0x01)
      swap1
      swap5
      and
      not(sub(shl(0xc8, 0x01), 0x01))
      swap1
      swap3
      and
      swap2
      swap1
      swap2
      or
      shl(0xa0, 0x01)
      0xffffffffff
      swap3
      dup4
      and
      mul
      or
      not(shl(0xc8, 0xffffffffffff))
      and
      shl(0xc8, 0x01)
      swap5
      iszero
      iszero
      swap5
      swap1
      swap5
      mul
      not(shl(0xd0, 0xffffffffff))
      and
      swap4
      swap1
      swap4
      or
      shl(0xd0, 0x01)
      swap4
      swap1
      swap3
      and
      swap3
      swap1
      swap3
      mul
      or
      swap1
      sstore
        /* "src/RequestHarness.sol":926:957  _setLastReportTimestamp(report) */
      tag_398
        /* "src/RequestHarness.sol":950:956  report */
      dup2
        /* "src/RequestHarness.sol":926:949  _setLastReportTimestamp */
      tag_392
        /* "src/RequestHarness.sol":926:957  _setLastReportTimestamp(report) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":6703:6905  function unfinalizedStETH() external view returns (uint256) {... */
    tag_215:
        /* "src/core/WithdrawalQueueBase.sol":6754:6761  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6842:6853  _getQueue() */
      tag_509
        /* "src/core/WithdrawalQueueBase.sol":6842:6851  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":6842:6853  _getQueue() */
      jump	// in
    tag_509:
        /* "src/core/WithdrawalQueueBase.sol":6842:6882  _getQueue()[getLastFinalizedRequestId()] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6854:6881  getLastFinalizedRequestId() */
      tag_510
        /* "src/core/WithdrawalQueueBase.sol":6854:6879  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":6854:6881  getLastFinalizedRequestId() */
      jump	// in
    tag_510:
        /* "src/core/WithdrawalQueueBase.sol":6842:6882  _getQueue()[getLastFinalizedRequestId()] */
      dup2
      mstore
      0x20
      dup2
      add
      swap2
      swap1
      swap2
      mstore
      0x40
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":6842:6898  _getQueue()[getLastFinalizedRequestId()].cumulativeStETH */
      sload
      sub(shl(0x80, 0x01), 0x01)
      and
        /* "src/core/WithdrawalQueueBase.sol":6792:6803  _getQueue() */
      tag_511
        /* "src/core/WithdrawalQueueBase.sol":6792:6801  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":6792:6803  _getQueue() */
      jump	// in
    tag_511:
        /* "src/core/WithdrawalQueueBase.sol":6792:6823  _getQueue()[getLastRequestId()] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6804:6822  getLastRequestId() */
      tag_512
        /* "src/core/WithdrawalQueueBase.sol":6804:6820  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":6804:6822  getLastRequestId() */
      jump	// in
    tag_512:
        /* "src/core/WithdrawalQueueBase.sol":6792:6823  _getQueue()[getLastRequestId()] */
      dup2
      mstore
      0x20
      dup2
      add
      swap2
      swap1
      swap2
      mstore
      0x40
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":6792:6839  _getQueue()[getLastRequestId()].cumulativeStETH */
      sload
        /* "src/core/WithdrawalQueueBase.sol":6792:6898  _getQueue()[getLastRequestId()].cumulativeStETH - _getQueue()[getLastFinalizedRequestId()].cumulativeStETH */
      tag_513
      swap2
      swap1
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":6792:6839  _getQueue()[getLastRequestId()].cumulativeStETH */
      and
        /* "src/core/WithdrawalQueueBase.sol":6792:6898  _getQueue()[getLastRequestId()].cumulativeStETH - _getQueue()[getLastFinalizedRequestId()].cumulativeStETH */
      tag_514
      jump	// in
    tag_513:
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":6773:6898  return... */
      and
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":6703:6905  function unfinalizedStETH() external view returns (uint256) {... */
      swap1
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":5366:5513  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {... */
    tag_219:
        /* "src/core/utils/access/AccessControl.sol":5450:5468  getRoleAdmin(role) */
      tag_515
        /* "src/core/utils/access/AccessControl.sol":5463:5467  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":5450:5462  getRoleAdmin */
      tag_97
        /* "src/core/utils/access/AccessControl.sol":5450:5468  getRoleAdmin(role) */
      jump	// in
    tag_515:
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      tag_517
        /* "src/core/utils/access/AccessControl.sol":3122:3126  role */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
        /* "src/core/utils/access/AccessControl.sol":3111:3121  _checkRole */
      tag_273
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      jump	// in
    tag_517:
        /* "src/core/utils/access/AccessControl.sol":5480:5506  _revokeRole(role, account) */
      tag_310
        /* "src/core/utils/access/AccessControl.sol":5492:5496  role */
      dup4
        /* "src/core/utils/access/AccessControl.sol":5498:5505  account */
      dup4
        /* "src/core/utils/access/AccessControl.sol":5480:5491  _revokeRole */
      tag_318
        /* "src/core/utils/access/AccessControl.sol":5480:5506  _revokeRole(role, account) */
      jump	// in
        /* "src/core/WithdrawalQueue.sol":5822:6291  function requestWithdrawals(uint256[] calldata _amounts, address _owner)... */
    tag_222:
        /* "src/core/WithdrawalQueue.sol":5927:5954  uint256[] memory requestIds */
      0x60
        /* "src/core/WithdrawalQueue.sol":5970:5985  _checkResumed() */
      tag_522
        /* "src/core/WithdrawalQueue.sol":5970:5983  _checkResumed */
      tag_278
        /* "src/core/WithdrawalQueue.sol":5970:5985  _checkResumed() */
      jump	// in
    tag_522:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":5999:6019  _owner == address(0) */
      dup3
      and
        /* "src/core/WithdrawalQueue.sol":5995:6040  if (_owner == address(0)) _owner = msg.sender */
      tag_523
      jumpi
        /* "src/core/WithdrawalQueue.sol":6030:6040  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":6021:6040  _owner = msg.sender */
      swap2
      pop
        /* "src/core/WithdrawalQueue.sol":5995:6040  if (_owner == address(0)) _owner = msg.sender */
    tag_523:
        /* "src/core/WithdrawalQueue.sol":6077:6085  _amounts */
      dup3
      sub(shl(0x40, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":6063:6093  new uint256[](_amounts.length) */
      dup2
      gt
      iszero
      tag_525
      jumpi
      tag_525
      tag_282
      jump	// in
    tag_525:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x20
      mul
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_526
      jumpi
      dup2
      0x20
      add
      0x20
      dup3
      mul
      dup1
      calldatasize
      dup4
      calldatacopy
      add
      swap1
      pop
    tag_526:
      pop
        /* "src/core/WithdrawalQueue.sol":6050:6093  requestIds = new uint256[](_amounts.length) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":6108:6117  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":6103:6285  for (uint256 i = 0; i < _amounts.length; ++i) {... */
    tag_527:
        /* "src/core/WithdrawalQueue.sol":6123:6142  i < _amounts.length */
      dup4
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":6103:6285  for (uint256 i = 0; i < _amounts.length; ++i) {... */
      iszero
      tag_285
      jumpi
        /* "src/core/WithdrawalQueue.sol":6163:6205  _checkWithdrawalRequestAmount(_amounts[i]) */
      tag_530
        /* "src/core/WithdrawalQueue.sol":6193:6201  _amounts */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":6202:6203  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":6193:6204  _amounts[i] */
      dup2
      dup2
      lt
      tag_532
      jumpi
      tag_532
      tag_290
      jump	// in
    tag_532:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":6163:6192  _checkWithdrawalRequestAmount */
      tag_533
        /* "src/core/WithdrawalQueue.sol":6163:6205  _checkWithdrawalRequestAmount(_amounts[i]) */
      jump	// in
    tag_530:
        /* "src/core/WithdrawalQueue.sol":6235:6274  _requestWithdrawal(_amounts[i], _owner) */
      tag_534
        /* "src/core/WithdrawalQueue.sol":6254:6262  _amounts */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":6263:6264  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":6254:6265  _amounts[i] */
      dup2
      dup2
      lt
      tag_536
      jumpi
      tag_536
      tag_290
      jump	// in
    tag_536:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":6267:6273  _owner */
      dup5
        /* "src/core/WithdrawalQueue.sol":6235:6253  _requestWithdrawal */
      tag_537
        /* "src/core/WithdrawalQueue.sol":6235:6274  _requestWithdrawal(_amounts[i], _owner) */
      jump	// in
    tag_534:
        /* "src/core/WithdrawalQueue.sol":6219:6229  requestIds */
      dup3
        /* "src/core/WithdrawalQueue.sol":6230:6231  i */
      dup3
        /* "src/core/WithdrawalQueue.sol":6219:6232  requestIds[i] */
      dup2
      mload
      dup2
      lt
      tag_539
      jumpi
      tag_539
      tag_290
      jump	// in
    tag_539:
      0x20
      swap1
      dup2
      mul
      swap2
      swap1
      swap2
      add
      add
        /* "src/core/WithdrawalQueue.sol":6219:6274  requestIds[i] = _requestWithdrawal(_amounts[i], _owner) */
      mstore
        /* "src/core/WithdrawalQueue.sol":6144:6147  ++i */
      tag_540
      dup2
      tag_295
      jump	// in
    tag_540:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":6103:6285  for (uint256 i = 0; i < _amounts.length; ++i) {... */
      jump(tag_527)
        /* "src/RequestHarness.sol":969:1074  function metadata(uint256 id) external view returns(WithdrawalRequest memory) { return _getQueue()[id]; } */
    tag_237:
      0x40
      dup1
      mload
      0xc0
      dup2
      add
      dup3
      mstore
      0x00
      dup1
      dup3
      mstore
      0x20
      dup3
      add
      dup2
      swap1
      mstore
      swap2
      dup2
      add
      dup3
      swap1
      mstore
      0x60
      dup2
      add
      dup3
      swap1
      mstore
      0x80
      dup2
      add
      dup3
      swap1
      mstore
      0xa0
      dup2
      add
      swap2
      swap1
      swap2
      mstore
        /* "src/RequestHarness.sol":1056:1067  _getQueue() */
      tag_544
        /* "src/RequestHarness.sol":1056:1065  _getQueue */
      tag_424
        /* "src/RequestHarness.sol":1056:1067  _getQueue() */
      jump	// in
    tag_544:
        /* "src/RequestHarness.sol":1056:1071  _getQueue()[id] */
      0x00
      swap3
      dup4
      mstore
      0x20
      swap1
      dup2
      mstore
      0x40
      swap3
      dup4
      swap1
      keccak256
        /* "src/RequestHarness.sol":1049:1071  return _getQueue()[id] */
      dup4
      mload
      0xc0
      dup2
      add
      dup6
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap3
      dup2
      add
      swap3
      swap1
      swap3
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap4
      dup3
      add
      swap4
      swap1
      swap4
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup5
      div
      dup2
      and
      0x60
      dup4
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup6
      div
      and
      iszero
      iszero
      0x80
      dup4
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap4
      div
      swap1
      swap3
      and
      0xa0
      dup4
      add
      mstore
      pop
      swap1
        /* "src/RequestHarness.sol":969:1074  function metadata(uint256 id) external view returns(WithdrawalRequest memory) { return _getQueue()[id]; } */
      jump	// out
        /* "src/core/WithdrawalQueue.sol":12954:13388  function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external {... */
    tag_242:
        /* "src/core/WithdrawalQueue.sol":13062:13097  _requestIds.length != _hints.length */
      dup3
      dup2
      eq
        /* "src/core/WithdrawalQueue.sol":13058:13186  if (_requestIds.length != _hints.length) {... */
      tag_546
      jumpi
        /* "src/core/WithdrawalQueue.sol":13120:13175  ArraysLengthMismatch(_requestIds.length, _hints.length) */
      mload(0x40)
      shl(0xe3, 0x098b37e5)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":6957:6982   */
      dup5
      swap1
      mstore
        /* "#utility.yul":6998:7016   */
      0x24
      dup2
      add
        /* "#utility.yul":6991:7025   */
      dup3
      swap1
      mstore
        /* "#utility.yul":6930:6948   */
      0x44
      add
        /* "src/core/WithdrawalQueue.sol":13120:13175  ArraysLengthMismatch(_requestIds.length, _hints.length) */
      tag_315
        /* "#utility.yul":6783:7031   */
      jump
        /* "src/core/WithdrawalQueue.sol":13058:13186  if (_requestIds.length != _hints.length) {... */
    tag_546:
        /* "src/core/WithdrawalQueue.sol":13201:13210  uint256 i */
      0x00
        /* "src/core/WithdrawalQueue.sol":13196:13382  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
    tag_548:
        /* "src/core/WithdrawalQueue.sol":13216:13238  i < _requestIds.length */
      dup4
      dup2
      lt
        /* "src/core/WithdrawalQueue.sol":13196:13382  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      iszero
      tag_549
      jumpi
        /* "src/core/WithdrawalQueue.sol":13259:13304  _claim(_requestIds[i], _hints[i], msg.sender) */
      tag_551
        /* "src/core/WithdrawalQueue.sol":13266:13277  _requestIds */
      dup6
      dup6
        /* "src/core/WithdrawalQueue.sol":13278:13279  i */
      dup4
        /* "src/core/WithdrawalQueue.sol":13266:13280  _requestIds[i] */
      dup2
      dup2
      lt
      tag_553
      jumpi
      tag_553
      tag_290
      jump	// in
    tag_553:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":13282:13288  _hints */
      dup5
      dup5
        /* "src/core/WithdrawalQueue.sol":13289:13290  i */
      dup5
        /* "src/core/WithdrawalQueue.sol":13282:13291  _hints[i] */
      dup2
      dup2
      lt
      tag_555
      jumpi
      tag_555
      tag_290
      jump	// in
    tag_555:
      swap1
      pop
      0x20
      mul
      add
      calldataload
        /* "src/core/WithdrawalQueue.sol":13293:13303  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":13259:13265  _claim */
      tag_337
        /* "src/core/WithdrawalQueue.sol":13259:13304  _claim(_requestIds[i], _hints[i], msg.sender) */
      jump	// in
    tag_551:
        /* "src/core/WithdrawalQueue.sol":13318:13371  _emitTransfer(msg.sender, address(0), _requestIds[i]) */
      tag_556
        /* "src/core/WithdrawalQueue.sol":13332:13342  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":13352:13353  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":13356:13367  _requestIds */
      dup8
      dup8
        /* "src/core/WithdrawalQueue.sol":13368:13369  i */
      dup6
        /* "src/core/WithdrawalQueue.sol":13356:13370  _requestIds[i] */
      dup2
      dup2
      lt
      tag_340
      jumpi
      tag_340
      tag_290
      jump	// in
        /* "src/core/WithdrawalQueue.sol":13318:13371  _emitTransfer(msg.sender, address(0), _requestIds[i]) */
    tag_556:
        /* "src/core/WithdrawalQueue.sol":13240:13243  ++i */
      tag_559
      dup2
      tag_295
      jump	// in
    tag_559:
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":13196:13382  for (uint256 i = 0; i < _requestIds.length; ++i) {... */
      jump(tag_548)
    tag_549:
      pop
        /* "src/core/WithdrawalQueue.sol":12954:13388  function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external {... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":11431:14606  function calculateFinalizationBatches(... */
    tag_249:
        /* "src/core/WithdrawalQueueBase.sol":11644:11674  BatchesCalculationState memory */
      tag_560
      tag_561
      jump	// in
    tag_560:
        /* "src/core/WithdrawalQueueBase.sol":11690:11696  _state */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":11690:11705  _state.finished */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":11690:11739  _state.finished || _state.remainingEthBudget == 0 */
      dup1
      tag_563
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":11709:11734  _state.remainingEthBudget */
      dup2
      mload
        /* "src/core/WithdrawalQueueBase.sol":11709:11739  _state.remainingEthBudget == 0 */
      iszero
        /* "src/core/WithdrawalQueueBase.sol":11690:11739  _state.finished || _state.remainingEthBudget == 0 */
    tag_563:
        /* "src/core/WithdrawalQueueBase.sol":11686:11762  if (_state.finished || _state.remainingEthBudget == 0) revert InvalidState() */
      iszero
      tag_564
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":11748:11762  InvalidState() */
      mload(0x40)
      shl(0xe0, 0xbaf3f0f7)
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
        /* "src/core/WithdrawalQueueBase.sol":11686:11762  if (_state.finished || _state.remainingEthBudget == 0) revert InvalidState() */
    tag_564:
      0x40
      dup1
      mload
      0xc0
      dup2
      add
      dup3
      mstore
        /* "src/core/WithdrawalQueueBase.sol":11773:11790  uint256 currentId */
      0x00
      dup1
      dup3
      mstore
      0x20
      dup3
      add
      dup2
      swap1
      mstore
      swap2
      dup2
      add
      dup3
      swap1
      mstore
      0x60
      dup2
      add
      dup3
      swap1
      mstore
      0x80
      dup2
      add
      dup3
      swap1
      mstore
      0xa0
      dup2
      add
      dup3
      swap1
      mstore
        /* "src/core/WithdrawalQueueBase.sol":11846:11874  uint256 prevRequestShareRate */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":11889:11895  _state */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":11889:11909  _state.batchesLength */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":11913:11914  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":11889:11914  _state.batchesLength == 0 */
      eq
        /* "src/core/WithdrawalQueueBase.sol":11885:12356  if (_state.batchesLength == 0) {... */
      iszero
      tag_566
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":11942:11969  getLastFinalizedRequestId() */
      tag_567
        /* "src/core/WithdrawalQueueBase.sol":11942:11967  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":11942:11969  getLastFinalizedRequestId() */
      jump	// in
    tag_567:
        /* "src/core/WithdrawalQueueBase.sol":11942:11973  getLastFinalizedRequestId() + 1 */
      tag_568
      swap1
        /* "src/core/WithdrawalQueueBase.sol":11972:11973  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":11942:11973  getLastFinalizedRequestId() + 1 */
      tag_439
      jump	// in
    tag_568:
        /* "src/core/WithdrawalQueueBase.sol":11930:11973  currentId = getLastFinalizedRequestId() + 1 */
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":12002:12013  _getQueue() */
      tag_569
        /* "src/core/WithdrawalQueueBase.sol":12002:12011  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":12002:12013  _getQueue() */
      jump	// in
    tag_569:
        /* "src/core/WithdrawalQueueBase.sol":12002:12028  _getQueue()[currentId - 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12014:12027  currentId - 1 */
      tag_570
        /* "src/core/WithdrawalQueueBase.sol":12026:12027  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":12014:12023  currentId */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":12014:12027  currentId - 1 */
      tag_414
      jump	// in
    tag_570:
        /* "src/core/WithdrawalQueueBase.sol":12002:12028  _getQueue()[currentId - 1] */
      dup2
      mstore
      0x20
      dup1
      dup3
      add
      swap3
      swap1
      swap3
      mstore
      0x40
      swap1
      dup2
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":11988:12028  prevRequest = _getQueue()[currentId - 1] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap4
      dup2
      add
      swap4
      swap1
      swap4
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup5
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup3
      add
      mstore
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":11885:12356  if (_state.batchesLength == 0) {... */
      jump(tag_571)
    tag_566:
        /* "src/core/WithdrawalQueueBase.sol":12059:12087  uint256 lastHandledRequestId */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12090:12096  _state */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12090:12104  _state.batches */
      0x40
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":12128:12129  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":12105:12111  _state */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":12105:12125  _state.batchesLength */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":12105:12129  _state.batchesLength - 1 */
      tag_572
      swap2
      swap1
      tag_414
      jump	// in
    tag_572:
        /* "src/core/WithdrawalQueueBase.sol":12090:12130  _state.batches[_state.batchesLength - 1] */
      0x24
      dup2
      lt
      tag_574
      jumpi
      tag_574
      tag_290
      jump	// in
    tag_574:
      0x20
      mul
      add
      mload
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":12156:12180  lastHandledRequestId + 1 */
      tag_575
        /* "src/core/WithdrawalQueueBase.sol":12090:12130  _state.batches[_state.batchesLength - 1] */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":12179:12180  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":12156:12180  lastHandledRequestId + 1 */
      tag_439
      jump	// in
    tag_575:
        /* "src/core/WithdrawalQueueBase.sol":12144:12180  currentId = lastHandledRequestId + 1 */
      swap4
      pop
        /* "src/core/WithdrawalQueueBase.sol":12209:12220  _getQueue() */
      tag_576
        /* "src/core/WithdrawalQueueBase.sol":12209:12218  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":12209:12220  _getQueue() */
      jump	// in
    tag_576:
        /* "src/core/WithdrawalQueueBase.sol":12209:12242  _getQueue()[lastHandledRequestId] */
      0x00
      dup3
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      swap1
      dup2
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":12195:12242  prevRequest = _getQueue()[lastHandledRequestId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap4
      dup2
      add
      swap4
      swap1
      swap4
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup5
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup3
      add
      mstore
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":12283:12345  _calcBatch(_getQueue()[lastHandledRequestId - 1], prevRequest) */
      tag_577
        /* "src/core/WithdrawalQueueBase.sol":12294:12305  _getQueue() */
      tag_578
        /* "src/core/WithdrawalQueueBase.sol":12294:12303  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":12294:12305  _getQueue() */
      jump	// in
    tag_578:
        /* "src/core/WithdrawalQueueBase.sol":12294:12331  _getQueue()[lastHandledRequestId - 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12306:12330  lastHandledRequestId - 1 */
      tag_579
        /* "src/core/WithdrawalQueueBase.sol":12329:12330  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":12306:12326  lastHandledRequestId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12306:12330  lastHandledRequestId - 1 */
      tag_414
      jump	// in
    tag_579:
        /* "src/core/WithdrawalQueueBase.sol":12294:12331  _getQueue()[lastHandledRequestId - 1] */
      dup2
      mstore
      0x20
      dup1
      dup3
      add
      swap3
      swap1
      swap3
      mstore
      0x40
      swap1
      dup2
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":12283:12345  _calcBatch(_getQueue()[lastHandledRequestId - 1], prevRequest) */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap4
      dup2
      add
      swap4
      swap1
      swap4
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup5
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup3
      add
      mstore
        /* "src/core/WithdrawalQueueBase.sol":12333:12344  prevRequest */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":12283:12293  _calcBatch */
      tag_432
        /* "src/core/WithdrawalQueueBase.sol":12283:12345  _calcBatch(_getQueue()[lastHandledRequestId - 1], prevRequest) */
      jump	// in
    tag_577:
      pop
        /* "src/core/WithdrawalQueueBase.sol":12256:12345  (prevRequestShareRate,,) = _calcBatch(_getQueue()[lastHandledRequestId - 1], prevRequest) */
      swap1
      swap3
      pop
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":11885:12356  if (_state.batchesLength == 0) {... */
    tag_571:
        /* "src/core/WithdrawalQueueBase.sol":12366:12391  uint256 nextCallRequestId */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12394:12425  currentId + _maxRequestsPerCall */
      tag_580
        /* "src/core/WithdrawalQueueBase.sol":12406:12425  _maxRequestsPerCall */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":12394:12403  currentId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12394:12425  currentId + _maxRequestsPerCall */
      tag_439
      jump	// in
    tag_580:
        /* "src/core/WithdrawalQueueBase.sol":12366:12425  uint256 nextCallRequestId = currentId + _maxRequestsPerCall */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":12435:12454  uint256 queueLength */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12457:12475  getLastRequestId() */
      tag_581
        /* "src/core/WithdrawalQueueBase.sol":12457:12473  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":12457:12475  getLastRequestId() */
      jump	// in
    tag_581:
        /* "src/core/WithdrawalQueueBase.sol":12457:12479  getLastRequestId() + 1 */
      tag_582
      swap1
        /* "src/core/WithdrawalQueueBase.sol":12478:12479  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":12457:12479  getLastRequestId() + 1 */
      tag_439
      jump	// in
    tag_582:
        /* "src/core/WithdrawalQueueBase.sol":12435:12479  uint256 queueLength = getLastRequestId() + 1 */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":12490:14490  while (currentId < queueLength && currentId < nextCallRequestId) {... */
    tag_583:
        /* "src/core/WithdrawalQueueBase.sol":12509:12520  queueLength */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":12497:12506  currentId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12497:12520  currentId < queueLength */
      lt
        /* "src/core/WithdrawalQueueBase.sol":12497:12553  currentId < queueLength && currentId < nextCallRequestId */
      dup1
      iszero
      tag_585
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":12536:12553  nextCallRequestId */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":12524:12533  currentId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12524:12553  currentId < nextCallRequestId */
      lt
        /* "src/core/WithdrawalQueueBase.sol":12497:12553  currentId < queueLength && currentId < nextCallRequestId */
    tag_585:
        /* "src/core/WithdrawalQueueBase.sol":12490:14490  while (currentId < queueLength && currentId < nextCallRequestId) {... */
      iszero
      tag_584
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":12569:12601  WithdrawalRequest memory request */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12604:12615  _getQueue() */
      tag_586
        /* "src/core/WithdrawalQueueBase.sol":12604:12613  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":12604:12615  _getQueue() */
      jump	// in
    tag_586:
        /* "src/core/WithdrawalQueueBase.sol":12604:12626  _getQueue()[currentId] */
      0x00
      dup8
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      swap1
      dup2
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":12569:12626  WithdrawalRequest memory request = _getQueue()[currentId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap4
      dup2
      add
      swap4
      swap1
      swap4
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      dup2
      swap1
      mstore
      0xff
      shl(0xc8, 0x01)
      dup5
      div
      and
      iszero
      iszero
      0x80
      dup6
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap3
      div
      and
      0xa0
      dup4
      add
      mstore
      swap1
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":12645:12678  request.timestamp > _maxTimestamp */
      dup11
      lt
        /* "src/core/WithdrawalQueueBase.sol":12641:12685  if (request.timestamp > _maxTimestamp) break */
      iszero
      tag_587
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":12680:12685  break */
      pop
      jump(tag_584)
        /* "src/core/WithdrawalQueueBase.sol":12641:12685  if (request.timestamp > _maxTimestamp) break */
    tag_587:
        /* "src/core/WithdrawalQueueBase.sol":12724:12748  uint256 requestShareRate */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12750:12771  uint256 ethToFinalize */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":12773:12787  uint256 shares */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":12791:12823  _calcBatch(prevRequest, request) */
      tag_588
        /* "src/core/WithdrawalQueueBase.sol":12802:12813  prevRequest */
      dup9
        /* "src/core/WithdrawalQueueBase.sol":12815:12822  request */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":12791:12801  _calcBatch */
      tag_432
        /* "src/core/WithdrawalQueueBase.sol":12791:12823  _calcBatch(prevRequest, request) */
      jump	// in
    tag_588:
        /* "src/core/WithdrawalQueueBase.sol":12723:12823  (uint256 requestShareRate, uint256 ethToFinalize, uint256 shares) = _calcBatch(prevRequest, request) */
      swap3
      pop
      swap3
      pop
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":12861:12874  _maxShareRate */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":12842:12858  requestShareRate */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":12842:12874  requestShareRate > _maxShareRate */
      gt
        /* "src/core/WithdrawalQueueBase.sol":12838:13000  if (requestShareRate > _maxShareRate) {... */
      iszero
      tag_589
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":952:956  1e27 */
      0x033b2e3c9fd0803ce8000000
        /* "src/core/WithdrawalQueueBase.sol":12941:12963  shares * _maxShareRate */
      tag_590
        /* "src/core/WithdrawalQueueBase.sol":12950:12963  _maxShareRate */
      dup16
        /* "src/core/WithdrawalQueueBase.sol":12941:12947  shares */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":12941:12963  shares * _maxShareRate */
      tag_435
      jump	// in
    tag_590:
        /* "src/core/WithdrawalQueueBase.sol":12940:12985  (shares * _maxShareRate) / E27_PRECISION_BASE */
      tag_591
      swap2
      swap1
      tag_437
      jump	// in
    tag_591:
        /* "src/core/WithdrawalQueueBase.sol":12924:12985  ethToFinalize = (shares * _maxShareRate) / E27_PRECISION_BASE */
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":12838:13000  if (requestShareRate > _maxShareRate) {... */
    tag_589:
        /* "src/core/WithdrawalQueueBase.sol":13034:13059  _state.remainingEthBudget */
      dup11
      mload
        /* "src/core/WithdrawalQueueBase.sol":13018:13059  ethToFinalize > _state.remainingEthBudget */
      dup3
      gt
        /* "src/core/WithdrawalQueueBase.sol":13014:13066  if (ethToFinalize > _state.remainingEthBudget) break */
      iszero
      tag_592
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":13061:13066  break */
      pop
      pop
      pop
      pop
      jump(tag_584)
        /* "src/core/WithdrawalQueueBase.sol":13014:13066  if (ethToFinalize > _state.remainingEthBudget) break */
    tag_592:
        /* "src/core/WithdrawalQueueBase.sol":13125:13138  ethToFinalize */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":13096:13102  _state */
      dup12
        /* "src/core/WithdrawalQueueBase.sol":13096:13121  _state.remainingEthBudget */
      0x00
      add
        /* "src/core/WithdrawalQueueBase.sol":13096:13138  _state.remainingEthBudget -= ethToFinalize */
      dup2
      dup2
      mload
      tag_593
      swap2
      swap1
      tag_414
      jump	// in
    tag_593:
      swap1
      mstore
      pop
        /* "src/core/WithdrawalQueueBase.sol":13157:13177  _state.batchesLength */
      0x60
      dup12
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":13157:13182  _state.batchesLength != 0 */
      iszero
      dup1
      iszero
      swap1
        /* "src/core/WithdrawalQueueBase.sol":13157:13911  _state.batchesLength != 0 && (... */
      tag_598
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":13584:13591  request */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":13584:13607  request.reportTimestamp */
      0xa0
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":13553:13607  prevRequest.reportTimestamp == request.reportTimestamp */
      0xffffffffff
      and
        /* "src/core/WithdrawalQueueBase.sol":13553:13564  prevRequest */
      dup9
        /* "src/core/WithdrawalQueueBase.sol":13553:13580  prevRequest.reportTimestamp */
      0xa0
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":13553:13607  prevRequest.reportTimestamp == request.reportTimestamp */
      0xffffffffff
      and
      eq
        /* "src/core/WithdrawalQueueBase.sol":13553:13753  prevRequest.reportTimestamp == request.reportTimestamp ||... */
      dup1
      tag_596
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":13703:13716  _maxShareRate */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":13679:13699  prevRequestShareRate */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":13679:13716  prevRequestShareRate <= _maxShareRate */
      gt
      iszero
        /* "src/core/WithdrawalQueueBase.sol":13679:13753  prevRequestShareRate <= _maxShareRate && requestShareRate <= _maxShareRate */
      dup1
      iszero
      tag_596
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":13740:13753  _maxShareRate */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":13720:13736  requestShareRate */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":13720:13753  requestShareRate <= _maxShareRate */
      gt
      iszero
        /* "src/core/WithdrawalQueueBase.sol":13679:13753  prevRequestShareRate <= _maxShareRate && requestShareRate <= _maxShareRate */
    tag_596:
        /* "src/core/WithdrawalQueueBase.sol":13553:13897  prevRequest.reportTimestamp == request.reportTimestamp ||... */
      dup1
      tag_598
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":13848:13861  _maxShareRate */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":13825:13845  prevRequestShareRate */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":13825:13861  prevRequestShareRate > _maxShareRate */
      gt
        /* "src/core/WithdrawalQueueBase.sol":13825:13897  prevRequestShareRate > _maxShareRate && requestShareRate > _maxShareRate */
      dup1
      iszero
      tag_598
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":13884:13897  _maxShareRate */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":13865:13881  requestShareRate */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":13865:13897  requestShareRate > _maxShareRate */
      gt
        /* "src/core/WithdrawalQueueBase.sol":13825:13897  prevRequestShareRate > _maxShareRate && requestShareRate > _maxShareRate */
    tag_598:
        /* "src/core/WithdrawalQueueBase.sol":13153:14353  if (_state.batchesLength != 0 && (... */
      iszero
      tag_599
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":13974:13983  currentId */
      dup9
        /* "src/core/WithdrawalQueueBase.sol":13931:13937  _state */
      dup12
        /* "src/core/WithdrawalQueueBase.sol":13931:13945  _state.batches */
      0x40
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":13969:13970  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":13946:13952  _state */
      dup14
        /* "src/core/WithdrawalQueueBase.sol":13946:13966  _state.batchesLength */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":13946:13970  _state.batchesLength - 1 */
      tag_600
      swap2
      swap1
      tag_414
      jump	// in
    tag_600:
        /* "src/core/WithdrawalQueueBase.sol":13931:13971  _state.batches[_state.batchesLength - 1] */
      0x24
      dup2
      lt
      tag_602
      jumpi
      tag_602
      tag_290
      jump	// in
    tag_602:
      0x20
      mul
      add
        /* "src/core/WithdrawalQueueBase.sol":13931:13983  _state.batches[_state.batchesLength - 1] = currentId */
      mstore
        /* "src/core/WithdrawalQueueBase.sol":13153:14353  if (_state.batchesLength != 0 && (... */
      jump(tag_603)
    tag_599:
        /* "src/core/WithdrawalQueueBase.sol":850:852  36 */
      0x24
        /* "src/core/WithdrawalQueueBase.sol":14144:14150  _state */
      dup12
        /* "src/core/WithdrawalQueueBase.sol":14144:14164  _state.batchesLength */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":14144:14186  _state.batchesLength == MAX_BATCHES_LENGTH */
      eq
        /* "src/core/WithdrawalQueueBase.sol":14140:14193  if (_state.batchesLength == MAX_BATCHES_LENGTH) break */
      iszero
      tag_604
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":14188:14193  break */
      pop
      pop
      pop
      pop
      jump(tag_584)
        /* "src/core/WithdrawalQueueBase.sol":14140:14193  if (_state.batchesLength == MAX_BATCHES_LENGTH) break */
    tag_604:
        /* "src/core/WithdrawalQueueBase.sol":14289:14298  currentId */
      dup9
        /* "src/core/WithdrawalQueueBase.sol":14250:14256  _state */
      dup12
        /* "src/core/WithdrawalQueueBase.sol":14250:14264  _state.batches */
      0x40
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":14265:14271  _state */
      dup13
        /* "src/core/WithdrawalQueueBase.sol":14265:14285  _state.batchesLength */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":14250:14286  _state.batches[_state.batchesLength] */
      0x24
      dup2
      lt
      tag_606
      jumpi
      tag_606
      tag_290
      jump	// in
    tag_606:
      0x20
      mul
      add
        /* "src/core/WithdrawalQueueBase.sol":14250:14298  _state.batches[_state.batchesLength] = currentId */
      mstore
        /* "src/core/WithdrawalQueueBase.sol":14318:14338  _state.batchesLength */
      0x60
      dup12
      add
        /* "src/core/WithdrawalQueueBase.sol":14316:14338  ++_state.batchesLength */
      dup1
      mload
      tag_607
      swap1
      tag_295
      jump	// in
    tag_607:
      swap1
      mstore
        /* "src/core/WithdrawalQueueBase.sol":13153:14353  if (_state.batchesLength != 0 && (... */
    tag_603:
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":14466:14477  ++currentId */
      0x01
      swap1
      swap7
      add
      swap6
        /* "src/core/WithdrawalQueueBase.sol":14434:14441  request */
      swap1
      swap5
      pop
        /* "src/core/WithdrawalQueueBase.sol":14390:14406  requestShareRate */
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":12490:14490  while (currentId < queueLength && currentId < nextCallRequestId) {... */
      jump(tag_583)
    tag_584:
        /* "src/core/WithdrawalQueueBase.sol":14531:14542  queueLength */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":14518:14527  currentId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":14518:14542  currentId == queueLength */
      eq
        /* "src/core/WithdrawalQueueBase.sol":14518:14575  currentId == queueLength || currentId < nextCallRequestId */
      dup1
      tag_608
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":14558:14575  nextCallRequestId */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":14546:14555  currentId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":14546:14575  currentId < nextCallRequestId */
      lt
        /* "src/core/WithdrawalQueueBase.sol":14518:14575  currentId == queueLength || currentId < nextCallRequestId */
    tag_608:
        /* "src/core/WithdrawalQueueBase.sol":14500:14575  _state.finished = currentId == queueLength || currentId < nextCallRequestId */
      iszero
      iszero
        /* "src/core/WithdrawalQueueBase.sol":14500:14515  _state.finished */
      0x20
      dup9
      add
        /* "src/core/WithdrawalQueueBase.sol":14500:14575  _state.finished = currentId == queueLength || currentId < nextCallRequestId */
      mstore
      pop
        /* "src/core/WithdrawalQueueBase.sol":14500:14515  _state.finished */
      swap5
      swap9
        /* "src/core/WithdrawalQueueBase.sol":11431:14606  function calculateFinalizationBatches(... */
      swap8
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":4731:4835  function pauseFor(uint256 _duration) external onlyRole(PAUSE_ROLE) {... */
    tag_254:
        /* "src/core/WithdrawalQueue.sol":2123:2146  keccak256("PAUSE_ROLE") */
      0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      tag_610
        /* "src/core/WithdrawalQueue.sol":2123:2146  keccak256("PAUSE_ROLE") */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
        /* "src/core/utils/access/AccessControl.sol":3111:3121  _checkRole */
      tag_273
        /* "src/core/utils/access/AccessControl.sol":3111:3141  _checkRole(role, _msgSender()) */
      jump	// in
    tag_610:
        /* "src/core/WithdrawalQueue.sol":4808:4828  _pauseFor(_duration) */
      tag_317
        /* "src/core/WithdrawalQueue.sol":4818:4827  _duration */
      dup3
        /* "src/core/WithdrawalQueue.sol":4808:4817  _pauseFor */
      tag_614
        /* "src/core/WithdrawalQueue.sol":4808:4828  _pauseFor(_duration) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":5955:6089  function getLockedEtherAmount() public view returns (uint256) {... */
    tag_256:
        /* "src/core/WithdrawalQueueBase.sol":6008:6015  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":6034:6082  LOCKED_ETHER_AMOUNT_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/WithdrawalQueueBase.sol":2032:2083  keccak256("lido.WithdrawalQueue.lockedEtherAmount") */
      0x0e27eaa2e71c8572ab988fef0b54cd45bbd1740de1e22343fb6cda7536edc12f
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/core/WithdrawalQueue.sol":13792:14014  function claimWithdrawal(uint256 _requestId) external {... */
    tag_260:
        /* "src/core/WithdrawalQueue.sol":13856:13948  _claim(_requestId, _findCheckpointHint(_requestId, 1, getLastCheckpointIndex()), msg.sender) */
      tag_618
        /* "src/core/WithdrawalQueue.sol":13863:13873  _requestId */
      dup2
        /* "src/core/WithdrawalQueue.sol":13875:13935  _findCheckpointHint(_requestId, 1, getLastCheckpointIndex()) */
      tag_619
        /* "src/core/WithdrawalQueue.sol":13895:13905  _requestId */
      dup4
        /* "src/core/WithdrawalQueue.sol":13907:13908  1 */
      0x01
        /* "src/core/WithdrawalQueue.sol":13910:13934  getLastCheckpointIndex() */
      tag_620
        /* "src/core/WithdrawalQueue.sol":13910:13932  getLastCheckpointIndex */
      tag_122
        /* "src/core/WithdrawalQueue.sol":13910:13934  getLastCheckpointIndex() */
      jump	// in
    tag_620:
        /* "src/core/WithdrawalQueue.sol":13875:13894  _findCheckpointHint */
      tag_356
        /* "src/core/WithdrawalQueue.sol":13875:13935  _findCheckpointHint(_requestId, 1, getLastCheckpointIndex()) */
      jump	// in
    tag_619:
        /* "src/core/WithdrawalQueue.sol":13937:13947  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":13856:13862  _claim */
      tag_337
        /* "src/core/WithdrawalQueue.sol":13856:13948  _claim(_requestId, _findCheckpointHint(_requestId, 1, getLastCheckpointIndex()), msg.sender) */
      jump	// in
    tag_618:
        /* "src/core/WithdrawalQueue.sol":13958:14007  _emitTransfer(msg.sender, address(0), _requestId) */
      tag_481
        /* "src/core/WithdrawalQueue.sol":13972:13982  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":13992:13993  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":13996:14006  _requestId */
      dup4
        /* "src/core/WithdrawalQueue.sol":13958:13971  _emitTransfer */
      tag_341
        /* "src/core/WithdrawalQueue.sol":13958:14007  _emitTransfer(msg.sender, address(0), _requestId) */
      jump	// in
        /* "src/RequestHarness.sol":438:658  function one(uint256 amount,address owner) external returns(uint256) {... */
    tag_264:
        /* "src/RequestHarness.sol":498:505  uint256 */
      0x00
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/RequestHarness.sol":520:537  owner==address(0) */
      dup3
      and
        /* "src/RequestHarness.sol":517:555  if(owner==address(0)) owner=msg.sender */
      tag_623
      jumpi
        /* "src/RequestHarness.sol":545:555  msg.sender */
      caller
        /* "src/RequestHarness.sol":539:555  owner=msg.sender */
      swap2
      pop
        /* "src/RequestHarness.sol":517:555  if(owner==address(0)) owner=msg.sender */
    tag_623:
        /* "src/RequestHarness.sol":565:602  _checkWithdrawalRequestAmount(amount) */
      tag_624
        /* "src/RequestHarness.sol":595:601  amount */
      dup4
        /* "src/RequestHarness.sol":565:594  _checkWithdrawalRequestAmount */
      tag_533
        /* "src/RequestHarness.sol":565:602  _checkWithdrawalRequestAmount(amount) */
      jump	// in
    tag_624:
        /* "src/RequestHarness.sol":619:651  _requestWithdrawal(amount,owner) */
      tag_381
        /* "src/RequestHarness.sol":638:644  amount */
      dup4
        /* "src/RequestHarness.sol":645:650  owner */
      dup4
        /* "src/RequestHarness.sol":619:637  _requestWithdrawal */
      tag_537
        /* "src/RequestHarness.sol":619:651  _requestWithdrawal(amount,owner) */
      jump	// in
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
    tag_266:
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":3226:3428  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
    tag_270:
        /* "src/core/utils/access/AccessControl.sol":3311:3315  bool */
      0x00
      not(sub(shl(0xe0, 0x01), 0x01))
        /* "src/core/utils/access/AccessControl.sol":3334:3381  interfaceId == type(IAccessControl).interfaceId */
      dup3
      and
      shl(0xe0, 0x7965db0b)
      eq
      dup1
        /* "src/core/utils/access/AccessControl.sol":3334:3421  interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId) */
      tag_269
      jumpi
      pop
      shl(0xe0, 0x01ffc9a7)
      not(sub(shl(0xe0, 0x01), 0x01))
        /* "src/@openzeppelin/contracts-v4.4/utils/introspection/ERC165.sol":937:977  interfaceId == type(IERC165).interfaceId */
      dup4
      and
      eq
        /* "src/core/utils/access/AccessControl.sol":3385:3421  super.supportsInterface(interfaceId) */
      tag_269
        /* "src/@openzeppelin/contracts-v4.4/utils/introspection/ERC165.sol":829:984  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {... */
      jump
        /* "src/core/utils/access/AccessControl.sol":3942:4426  function _checkRole(bytes32 role, address account) internal view {... */
    tag_273:
        /* "src/core/utils/access/AccessControl.sol":4022:4044  hasRole(role, account) */
      tag_632
        /* "src/core/utils/access/AccessControl.sol":4030:4034  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":4036:4043  account */
      dup3
        /* "src/core/utils/access/AccessControl.sol":4022:4029  hasRole */
      tag_157
        /* "src/core/utils/access/AccessControl.sol":4022:4044  hasRole(role, account) */
      jump	// in
    tag_632:
        /* "src/core/utils/access/AccessControl.sol":4017:4420  if (!hasRole(role, account)) {... */
      tag_317
      jumpi
        /* "src/core/utils/access/AccessControl.sol":4205:4246  Strings.toHexString(uint160(account), 20) */
      tag_634
        /* "src/core/utils/access/AccessControl.sol":4233:4240  account */
      dup2
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/utils/access/AccessControl.sol":4205:4246  Strings.toHexString(uint160(account), 20) */
      and
        /* "src/core/utils/access/AccessControl.sol":4243:4245  20 */
      0x14
        /* "src/core/utils/access/AccessControl.sol":4205:4224  Strings.toHexString */
      tag_635
        /* "src/core/utils/access/AccessControl.sol":4205:4246  Strings.toHexString(uint160(account), 20) */
      jump	// in
    tag_634:
        /* "src/core/utils/access/AccessControl.sol":4317:4355  Strings.toHexString(uint256(role), 32) */
      tag_636
        /* "src/core/utils/access/AccessControl.sol":4345:4349  role */
      dup4
        /* "src/core/utils/access/AccessControl.sol":4352:4354  32 */
      0x20
        /* "src/core/utils/access/AccessControl.sol":4317:4336  Strings.toHexString */
      tag_635
        /* "src/core/utils/access/AccessControl.sol":4317:4355  Strings.toHexString(uint256(role), 32) */
      jump	// in
    tag_636:
        /* "src/core/utils/access/AccessControl.sol":4112:4377  abi.encodePacked(... */
      add(0x20, mload(0x40))
      tag_637
      swap3
      swap2
      swap1
      tag_638
      jump	// in
    tag_637:
      0x40
      dup1
      mload
      not(0x1f)
      dup2
      dup5
      sub
      add
      dup2
      mstore
      swap1
      dup3
      swap1
      mstore
      shl(0xe5, 0x461bcd)
        /* "src/core/utils/access/AccessControl.sol":4060:4409  revert(... */
      dup3
      mstore
      tag_315
      swap2
      0x04
      add
      tag_640
      jump	// in
        /* "src/core/utils/PausableUntil.sol":1865:2024  function _resume() internal {... */
    tag_275:
        /* "src/core/utils/PausableUntil.sol":1903:1917  _checkPaused() */
      tag_642
        /* "src/core/utils/PausableUntil.sol":1903:1915  _checkPaused */
      tag_643
        /* "src/core/utils/PausableUntil.sol":1903:1917  _checkPaused() */
      jump	// in
    tag_642:
        /* "src/core/utils/PausableUntil.sol":1977:1992  block.timestamp */
      timestamp
      0x00
      dup1
      mload
      0x20
      data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      sstore
        /* "src/core/utils/PausableUntil.sol":2008:2017  Resumed() */
      mload(0x40)
      0x62451d457bc659158be6e6247f56ec1df424a5c7597f71c20c2bc44e0965c8f9
      swap1
      0x00
      swap1
      log1
        /* "src/core/utils/PausableUntil.sol":1865:2024  function _resume() internal {... */
      jump	// out
        /* "src/core/utils/PausableUntil.sol":1167:1287  function _checkResumed() internal view {... */
    tag_278:
        /* "src/core/utils/PausableUntil.sol":1220:1230  isPaused() */
      tag_646
        /* "src/core/utils/PausableUntil.sol":1220:1228  isPaused */
      tag_187
        /* "src/core/utils/PausableUntil.sol":1220:1230  isPaused() */
      jump	// in
    tag_646:
        /* "src/core/utils/PausableUntil.sol":1216:1281  if (isPaused()) {... */
      iszero
      tag_274
      jumpi
        /* "src/core/utils/PausableUntil.sol":1253:1270  ResumedExpected() */
      mload(0x40)
      shl(0xe3, 0x0286f073)
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
        /* "src/core/WithdrawalQueue.sol":18331:18861  function _requestWithdrawalWstETH(uint256 _amountOfWstETH, address _owner) internal returns (uint256 requestId) {... */
    tag_291:
        /* "src/core/WithdrawalQueue.sol":18453:18516  WSTETH.transferFrom(msg.sender, address(this), _amountOfWstETH) */
      mload(0x40)
      shl(0xe0, 0x23b872dd)
      dup2
      mstore
        /* "src/core/WithdrawalQueue.sol":18473:18483  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":18453:18516  WSTETH.transferFrom(msg.sender, address(this), _amountOfWstETH) */
      0x04
      dup3
      add
        /* "#utility.yul":18725:18759   */
      mstore
        /* "src/core/WithdrawalQueue.sol":18493:18497  this */
      address
        /* "#utility.yul":18775:18793   */
      0x24
      dup3
      add
        /* "#utility.yul":18768:18811   */
      mstore
        /* "#utility.yul":18827:18845   */
      0x44
      dup2
      add
        /* "#utility.yul":18820:18854   */
      dup4
      swap1
      mstore
        /* "src/core/WithdrawalQueue.sol":18424:18441  uint256 requestId */
      0x00
      swap1
        /* "src/core/WithdrawalQueue.sol":18453:18459  WSTETH */
      immutable("0x6e20e28aa948d9b4a4e4fad29a41b0e2debd981d9d74148d1704f33eeae821e8")
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":18453:18472  WSTETH.transferFrom */
      and
      swap1
      0x23b872dd
      swap1
        /* "#utility.yul":18660:18678   */
      0x64
      add
        /* "src/core/WithdrawalQueue.sol":18453:18516  WSTETH.transferFrom(msg.sender, address(this), _amountOfWstETH) */
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x00
      dup8
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_651
      jumpi
      0x00
      dup1
      revert
    tag_651:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_653
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_653:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      not(0x1f)
      0x1f
      dup3
      add
      and
      dup3
      add
      dup1
      0x40
      mstore
      pop
      dup2
      add
      swap1
      tag_654
      swap2
      swap1
      tag_655
      jump	// in
    tag_654:
      pop
        /* "src/core/WithdrawalQueue.sol":18550:18580  WSTETH.unwrap(_amountOfWstETH) */
      mload(0x40)
      shl(0xe1, 0x6f074d1f)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "src/core/WithdrawalQueue.sol":18526:18547  uint256 amountOfStETH */
      0x00
      swap1
        /* "src/core/WithdrawalQueue.sol":18550:18556  WSTETH */
      immutable("0x6e20e28aa948d9b4a4e4fad29a41b0e2debd981d9d74148d1704f33eeae821e8")
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":18550:18563  WSTETH.unwrap */
      and
      swap1
      0xde0e9a3e
      swap1
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":18550:18580  WSTETH.unwrap(_amountOfWstETH) */
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x00
      dup8
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_657
      jumpi
      0x00
      dup1
      revert
    tag_657:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_659
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_659:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      not(0x1f)
      0x1f
      dup3
      add
      and
      dup3
      add
      dup1
      0x40
      mstore
      pop
      dup2
      add
      swap1
      tag_660
      swap2
      swap1
      tag_661
      jump	// in
    tag_660:
        /* "src/core/WithdrawalQueue.sol":18526:18580  uint256 amountOfStETH = WSTETH.unwrap(_amountOfWstETH) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":18590:18634  _checkWithdrawalRequestAmount(amountOfStETH) */
      tag_662
        /* "src/core/WithdrawalQueue.sol":18620:18633  amountOfStETH */
      dup2
        /* "src/core/WithdrawalQueue.sol":18590:18619  _checkWithdrawalRequestAmount */
      tag_533
        /* "src/core/WithdrawalQueue.sol":18590:18634  _checkWithdrawalRequestAmount(amountOfStETH) */
      jump	// in
    tag_662:
        /* "src/core/WithdrawalQueue.sol":18670:18711  STETH.getSharesByPooledEth(amountOfStETH) */
      mload(0x40)
      shl(0xe0, 0x19208451)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup3
      swap1
      mstore
        /* "src/core/WithdrawalQueue.sol":18645:18667  uint256 amountOfShares */
      0x00
      swap1
        /* "src/core/WithdrawalQueue.sol":18670:18675  STETH */
      immutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":18670:18696  STETH.getSharesByPooledEth */
      and
      swap1
      0x19208451
      swap1
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":18670:18711  STETH.getSharesByPooledEth(amountOfStETH) */
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup7
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_664
      jumpi
      0x00
      dup1
      revert
    tag_664:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_666
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_666:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      not(0x1f)
      0x1f
      dup3
      add
      and
      dup3
      add
      dup1
      0x40
      mstore
      pop
      dup2
      add
      swap1
      tag_667
      swap2
      swap1
      tag_661
      jump	// in
    tag_667:
        /* "src/core/WithdrawalQueue.sol":18645:18711  uint256 amountOfShares = STETH.getSharesByPooledEth(amountOfStETH) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":18734:18799  _enqueue(uint128(amountOfStETH), uint128(amountOfShares), _owner) */
      tag_668
        /* "src/core/WithdrawalQueue.sol":18751:18764  amountOfStETH */
      dup3
        /* "src/core/WithdrawalQueue.sol":18775:18789  amountOfShares */
      dup3
        /* "src/core/WithdrawalQueue.sol":18792:18798  _owner */
      dup7
        /* "src/core/WithdrawalQueue.sol":18734:18742  _enqueue */
      tag_669
        /* "src/core/WithdrawalQueue.sol":18734:18799  _enqueue(uint128(amountOfStETH), uint128(amountOfShares), _owner) */
      jump	// in
    tag_668:
        /* "src/core/WithdrawalQueue.sol":18722:18799  requestId = _enqueue(uint128(amountOfStETH), uint128(amountOfShares), _owner) */
      swap3
      pop
        /* "src/core/WithdrawalQueue.sol":18810:18854  _emitTransfer(address(0), _owner, requestId) */
      tag_670
        /* "src/core/WithdrawalQueue.sol":18832:18833  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":18836:18842  _owner */
      dup6
        /* "src/core/WithdrawalQueue.sol":18844:18853  requestId */
      dup6
        /* "src/core/WithdrawalQueue.sol":18810:18823  _emitTransfer */
      tag_341
        /* "src/core/WithdrawalQueue.sol":18810:18854  _emitTransfer(address(0), _owner, requestId) */
      jump	// in
    tag_670:
        /* "src/core/WithdrawalQueue.sol":18443:18861  {... */
      pop
      pop
        /* "src/core/WithdrawalQueue.sol":18331:18861  function _requestWithdrawalWstETH(uint256 _amountOfWstETH, address _owner) internal returns (uint256 requestId) {... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/core/utils/access/AccessControlEnumerable.sol":2623:2798  function _grantRole(bytes32 role, address account) internal virtual override {... */
    tag_311:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2710:2741  super._grantRole(role, account) */
      tag_675
        /* "src/core/utils/access/AccessControlEnumerable.sol":2727:2731  role */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":2733:2740  account */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":2710:2726  super._grantRole */
      tag_676
        /* "src/core/utils/access/AccessControlEnumerable.sol":2710:2741  super._grantRole(role, account) */
      jump	// in
    tag_675:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2751:2778  _storageRoleMembers()[role] */
      0x00
      dup3
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_8c85144e36a363d47a080fe4c41afdc57727e34b590650d5b653cdd378d93afe
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/utils/access/AccessControlEnumerable.sol":2751:2791  _storageRoleMembers()[role].add(account) */
      tag_310
      swap1
        /* "src/core/utils/access/AccessControlEnumerable.sol":2783:2790  account */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":2751:2782  _storageRoleMembers()[role].add */
      tag_679
        /* "src/core/utils/access/AccessControlEnumerable.sol":2751:2791  _storageRoleMembers()[role].add(account) */
      jump	// in
        /* "src/core/utils/access/AccessControlEnumerable.sol":2887:3067  function _revokeRole(bytes32 role, address account) internal virtual override {... */
    tag_318:
        /* "src/core/utils/access/AccessControlEnumerable.sol":2975:3007  super._revokeRole(role, account) */
      tag_681
        /* "src/core/utils/access/AccessControlEnumerable.sol":2993:2997  role */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":2999:3006  account */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":2975:2992  super._revokeRole */
      tag_682
        /* "src/core/utils/access/AccessControlEnumerable.sol":2975:3007  super._revokeRole(role, account) */
      jump	// in
    tag_681:
        /* "src/core/utils/access/AccessControlEnumerable.sol":3017:3044  _storageRoleMembers()[role] */
      0x00
      dup3
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_8c85144e36a363d47a080fe4c41afdc57727e34b590650d5b653cdd378d93afe
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/utils/access/AccessControlEnumerable.sol":3017:3060  _storageRoleMembers()[role].remove(account) */
      tag_310
      swap1
        /* "src/core/utils/access/AccessControlEnumerable.sol":3052:3059  account */
      dup3
        /* "src/core/utils/access/AccessControlEnumerable.sol":3017:3051  _storageRoleMembers()[role].remove */
      tag_685
        /* "src/core/utils/access/AccessControlEnumerable.sol":3017:3060  _storageRoleMembers()[role].remove(account) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":22501:23584  function _claim(uint256 _requestId, uint256 _hint, address _recipient) internal {... */
    tag_337:
        /* "src/core/WithdrawalQueueBase.sol":22595:22610  _requestId == 0 */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":22591:22647  if (_requestId == 0) revert InvalidRequestId(_requestId) */
      tag_687
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":22619:22647  InvalidRequestId(_requestId) */
      mload(0x40)
      shl(0xe1, 0x64b4f079)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":22619:22647  InvalidRequestId(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":22591:22647  if (_requestId == 0) revert InvalidRequestId(_requestId) */
    tag_687:
        /* "src/core/WithdrawalQueueBase.sol":22674:22701  getLastFinalizedRequestId() */
      tag_689
        /* "src/core/WithdrawalQueueBase.sol":22674:22699  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":22674:22701  getLastFinalizedRequestId() */
      jump	// in
    tag_689:
        /* "src/core/WithdrawalQueueBase.sol":22661:22671  _requestId */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":22661:22701  _requestId > getLastFinalizedRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":22657:22751  if (_requestId > getLastFinalizedRequestId()) revert RequestNotFoundOrNotFinalized(_requestId) */
      iszero
      tag_690
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":22710:22751  RequestNotFoundOrNotFinalized(_requestId) */
      mload(0x40)
      shl(0xe3, 0x095ca045)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":22710:22751  RequestNotFoundOrNotFinalized(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":22657:22751  if (_requestId > getLastFinalizedRequestId()) revert RequestNotFoundOrNotFinalized(_requestId) */
    tag_690:
        /* "src/core/WithdrawalQueueBase.sol":22762:22795  WithdrawalRequest storage request */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":22798:22809  _getQueue() */
      tag_692
        /* "src/core/WithdrawalQueueBase.sol":22798:22807  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":22798:22809  _getQueue() */
      jump	// in
    tag_692:
        /* "src/core/WithdrawalQueueBase.sol":22798:22821  _getQueue()[_requestId] */
      0x00
      dup6
      dup2
      mstore
      0x20
      swap2
      swap1
      swap2
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":22836:22851  request.claimed */
      0x01
      dup2
      add
      sload
        /* "src/core/WithdrawalQueueBase.sol":22798:22821  _getQueue()[_requestId] */
      swap1
      swap2
      pop
      shl(0xc8, 0x01)
        /* "src/core/WithdrawalQueueBase.sol":22836:22851  request.claimed */
      swap1
      div
      0xff
      and
        /* "src/core/WithdrawalQueueBase.sol":22832:22893  if (request.claimed) revert RequestAlreadyClaimed(_requestId) */
      iszero
      tag_693
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":22860:22893  RequestAlreadyClaimed(_requestId) */
      mload(0x40)
      shl(0xe0, 0xf0e0cc2d)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup6
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":22860:22893  RequestAlreadyClaimed(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":22832:22893  if (request.claimed) revert RequestAlreadyClaimed(_requestId) */
    tag_693:
        /* "src/core/WithdrawalQueueBase.sol":22907:22920  request.owner */
      0x01
      dup2
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      and
        /* "src/core/WithdrawalQueueBase.sol":22924:22934  msg.sender */
      caller
        /* "src/core/WithdrawalQueueBase.sol":22907:22934  request.owner != msg.sender */
      eq
        /* "src/core/WithdrawalQueueBase.sol":22903:22978  if (request.owner != msg.sender) revert NotOwner(msg.sender, request.owner) */
      tag_695
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":22964:22977  request.owner */
      0x01
      dup2
      add
      sload
        /* "src/core/WithdrawalQueueBase.sol":22943:22978  NotOwner(msg.sender, request.owner) */
      mload(0x40)
      shl(0xe1, 0x1194af87)
      dup2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":22952:22962  msg.sender */
      caller
        /* "src/core/WithdrawalQueueBase.sol":22943:22978  NotOwner(msg.sender, request.owner) */
      0x04
      dup3
      add
        /* "#utility.yul":19516:19550   */
      mstore
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":22964:22977  request.owner */
      swap1
      swap2
      and
        /* "#utility.yul":19566:19584   */
      0x24
      dup3
      add
        /* "#utility.yul":19559:19602   */
      mstore
        /* "#utility.yul":19451:19469   */
      0x44
      add
        /* "src/core/WithdrawalQueueBase.sol":22943:22978  NotOwner(msg.sender, request.owner) */
      tag_315
        /* "#utility.yul":19304:19608   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":22903:22978  if (request.owner != msg.sender) revert NotOwner(msg.sender, request.owner) */
    tag_695:
        /* "src/core/WithdrawalQueueBase.sol":23007:23011  true */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":22989:23004  request.claimed */
      dup2
      add
        /* "src/core/WithdrawalQueueBase.sol":22989:23011  request.claimed = true */
      dup1
      sload
      not(shl(0xc8, 0xff))
      and
      shl(0xc8, 0x01)
      or
      swap1
      sstore
        /* "src/core/WithdrawalQueueBase.sol":23028:23083  _getRequestsByOwner()[request.owner].remove(_requestId) */
      tag_698
        /* "src/core/WithdrawalQueueBase.sol":23072:23082  _requestId */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":23028:23049  _getRequestsByOwner() */
      tag_699
        /* "src/core/WithdrawalQueueBase.sol":2197:2246  keccak256("lido.WithdrawalQueue.requestsByOwner") */
      0x4b9bfe0774f05ab288bd50bd23f74ae80a797f1d0c82d419d43ebda4fdc2fe1f
      swap1
        /* "src/core/WithdrawalQueueBase.sol":26906:27190  function _getRequestsByOwner()... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":23028:23049  _getRequestsByOwner() */
    tag_699:
        /* "src/core/WithdrawalQueueBase.sol":23050:23063  request.owner */
      0x01
      dup5
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      and
        /* "src/core/WithdrawalQueueBase.sol":23028:23064  _getRequestsByOwner()[request.owner] */
      0x00
      swap1
      dup2
      mstore
      0x20
      swap2
      swap1
      swap2
      mstore
      0x40
      swap1
      keccak256
      swap1
        /* "src/core/WithdrawalQueueBase.sol":23028:23071  _getRequestsByOwner()[request.owner].remove */
      tag_700
        /* "src/core/WithdrawalQueueBase.sol":23028:23083  _getRequestsByOwner()[request.owner].remove(_requestId) */
      jump	// in
    tag_698:
        /* "src/core/WithdrawalQueueBase.sol":23021:23084  assert(_getRequestsByOwner()[request.owner].remove(_requestId)) */
      tag_702
      jumpi
      tag_702
      tag_703
      jump	// in
    tag_702:
        /* "src/core/WithdrawalQueueBase.sol":23095:23118  uint256 ethWithDiscount */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":23121:23173  _calculateClaimableEther(request, _requestId, _hint) */
      tag_704
        /* "src/core/WithdrawalQueueBase.sol":23146:23153  request */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":23155:23165  _requestId */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":23167:23172  _hint */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":23121:23145  _calculateClaimableEther */
      tag_705
        /* "src/core/WithdrawalQueueBase.sol":23121:23173  _calculateClaimableEther(request, _requestId, _hint) */
      jump	// in
    tag_704:
        /* "src/core/WithdrawalQueueBase.sol":23095:23173  uint256 ethWithDiscount = _calculateClaimableEther(request, _requestId, _hint) */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":23379:23442  _setLockedEtherAmount(getLockedEtherAmount() - ethWithDiscount) */
      tag_706
        /* "src/core/WithdrawalQueueBase.sol":23426:23441  ethWithDiscount */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":23401:23423  getLockedEtherAmount() */
      tag_707
        /* "src/core/WithdrawalQueueBase.sol":23401:23421  getLockedEtherAmount */
      tag_256
        /* "src/core/WithdrawalQueueBase.sol":23401:23423  getLockedEtherAmount() */
      jump	// in
    tag_707:
        /* "src/core/WithdrawalQueueBase.sol":23401:23441  getLockedEtherAmount() - ethWithDiscount */
      tag_708
      swap2
      swap1
      tag_414
      jump	// in
    tag_708:
        /* "src/core/WithdrawalQueueBase.sol":23379:23400  _setLockedEtherAmount */
      tag_709
        /* "src/core/WithdrawalQueueBase.sol":23379:23442  _setLockedEtherAmount(getLockedEtherAmount() - ethWithDiscount) */
      jump	// in
    tag_706:
        /* "src/core/WithdrawalQueueBase.sol":23452:23491  _sendValue(_recipient, ethWithDiscount) */
      tag_710
        /* "src/core/WithdrawalQueueBase.sol":23463:23473  _recipient */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":23475:23490  ethWithDiscount */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":23452:23462  _sendValue */
      tag_711
        /* "src/core/WithdrawalQueueBase.sol":23452:23491  _sendValue(_recipient, ethWithDiscount) */
      jump	// in
    tag_710:
        /* "src/core/WithdrawalQueueBase.sol":23549:23559  _recipient */
      dup3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":23507:23577  WithdrawalClaimed(_requestId, msg.sender, _recipient, ethWithDiscount) */
      and
        /* "src/core/WithdrawalQueueBase.sol":23537:23547  msg.sender */
      caller
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":23507:23577  WithdrawalClaimed(_requestId, msg.sender, _recipient, ethWithDiscount) */
      and
        /* "src/core/WithdrawalQueueBase.sol":23525:23535  _requestId */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":23507:23577  WithdrawalClaimed(_requestId, msg.sender, _recipient, ethWithDiscount) */
      0x6ad26c5e238e7d002799f9a5db07e81ef14e37386ae03496d7a7ef04713e145b
        /* "src/core/WithdrawalQueueBase.sol":23561:23576  ethWithDiscount */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":23507:23577  WithdrawalClaimed(_requestId, msg.sender, _recipient, ethWithDiscount) */
      mload(0x40)
      tag_712
      swap2
        /* "#utility.yul":643:668   */
      dup2
      mstore
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
      swap1
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":23507:23577  WithdrawalClaimed(_requestId, msg.sender, _recipient, ethWithDiscount) */
    tag_712:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log4
        /* "src/core/WithdrawalQueueBase.sol":22581:23584  {... */
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":22501:23584  function _claim(uint256 _requestId, uint256 _hint, address _recipient) internal {... */
      pop
      pop
      pop
      jump	// out
        /* "src/RequestHarness.sol":250:357  function _emitTransfer(address from,address to,uint256 id) internal override { emit Transfer(from,to,id); } */
    tag_341:
        /* "src/RequestHarness.sol":351:353  id */
      dup1
        /* "src/RequestHarness.sol":348:350  to */
      dup3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/RequestHarness.sol":334:354  Transfer(from,to,id) */
      and
        /* "src/RequestHarness.sol":343:347  from */
      dup5
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/RequestHarness.sol":334:354  Transfer(from,to,id) */
      and
      0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
      mload(0x40)
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log4
        /* "src/RequestHarness.sol":250:357  function _emitTransfer(address from,address to,uint256 id) internal override { emit Transfer(from,to,id); } */
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":20799:22179  function _findCheckpointHint(uint256 _requestId, uint256 _start, uint256 _end) internal view returns (uint256) {... */
    tag_356:
        /* "src/core/WithdrawalQueueBase.sol":20901:20908  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":20924:20939  _requestId == 0 */
      dup4
      iszero
      dup1
        /* "src/core/WithdrawalQueueBase.sol":20924:20974  _requestId == 0 || _requestId > getLastRequestId() */
      tag_715
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":20956:20974  getLastRequestId() */
      tag_716
        /* "src/core/WithdrawalQueueBase.sol":20956:20972  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":20956:20974  getLastRequestId() */
      jump	// in
    tag_716:
        /* "src/core/WithdrawalQueueBase.sol":20943:20953  _requestId */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":20943:20974  _requestId > getLastRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":20924:20974  _requestId == 0 || _requestId > getLastRequestId() */
    tag_715:
        /* "src/core/WithdrawalQueueBase.sol":20920:21011  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
      iszero
      tag_717
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":20983:21011  InvalidRequestId(_requestId) */
      mload(0x40)
      shl(0xe1, 0x64b4f079)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup6
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":20983:21011  InvalidRequestId(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":20920:21011  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
    tag_717:
        /* "src/core/WithdrawalQueueBase.sol":21022:21049  uint256 lastCheckpointIndex */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21052:21076  getLastCheckpointIndex() */
      tag_719
        /* "src/core/WithdrawalQueueBase.sol":21052:21074  getLastCheckpointIndex */
      tag_122
        /* "src/core/WithdrawalQueueBase.sol":21052:21076  getLastCheckpointIndex() */
      jump	// in
    tag_719:
        /* "src/core/WithdrawalQueueBase.sol":21022:21076  uint256 lastCheckpointIndex = getLastCheckpointIndex() */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":21090:21101  _start == 0 */
      dup4
      iszero
      dup1
        /* "src/core/WithdrawalQueueBase.sol":21090:21131  _start == 0 || _end > lastCheckpointIndex */
      tag_720
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":21112:21131  lastCheckpointIndex */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":21105:21109  _end */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":21105:21131  _end > lastCheckpointIndex */
      gt
        /* "src/core/WithdrawalQueueBase.sol":21090:21131  _start == 0 || _end > lastCheckpointIndex */
    tag_720:
        /* "src/core/WithdrawalQueueBase.sol":21086:21175  if (_start == 0 || _end > lastCheckpointIndex) revert InvalidRequestIdRange(_start, _end) */
      iszero
      tag_721
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":21140:21175  InvalidRequestIdRange(_start, _end) */
      mload(0x40)
      shl(0xe0, 0x71894257)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":6957:6982   */
      dup6
      swap1
      mstore
        /* "#utility.yul":6998:7016   */
      0x24
      dup2
      add
        /* "#utility.yul":6991:7025   */
      dup5
      swap1
      mstore
        /* "#utility.yul":6930:6948   */
      0x44
      add
        /* "src/core/WithdrawalQueueBase.sol":21140:21175  InvalidRequestIdRange(_start, _end) */
      tag_315
        /* "#utility.yul":6783:7031   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":21086:21175  if (_start == 0 || _end > lastCheckpointIndex) revert InvalidRequestIdRange(_start, _end) */
    tag_721:
        /* "src/core/WithdrawalQueueBase.sol":21190:21214  lastCheckpointIndex == 0 */
      dup1
      iszero
      dup1
        /* "src/core/WithdrawalQueueBase.sol":21190:21258  lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() */
      tag_723
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":21231:21258  getLastFinalizedRequestId() */
      tag_724
        /* "src/core/WithdrawalQueueBase.sol":21231:21256  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":21231:21258  getLastFinalizedRequestId() */
      jump	// in
    tag_724:
        /* "src/core/WithdrawalQueueBase.sol":21218:21228  _requestId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":21218:21258  _requestId > getLastFinalizedRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":21190:21258  lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() */
    tag_723:
        /* "src/core/WithdrawalQueueBase.sol":21190:21275  lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() || _start > _end */
      dup1
      tag_725
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":21271:21275  _end */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":21262:21268  _start */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":21262:21275  _start > _end */
      gt
        /* "src/core/WithdrawalQueueBase.sol":21190:21275  lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() || _start > _end */
    tag_725:
        /* "src/core/WithdrawalQueueBase.sol":21186:21293  if (lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() || _start > _end) return NOT_FOUND */
      iszero
      tag_726
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":1073:1074  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21277:21293  return NOT_FOUND */
      swap2
      pop
      pop
      jump(tag_381)
        /* "src/core/WithdrawalQueueBase.sol":21186:21293  if (lastCheckpointIndex == 0 || _requestId > getLastFinalizedRequestId() || _start > _end) return NOT_FOUND */
    tag_726:
        /* "src/core/WithdrawalQueueBase.sol":21348:21371  _getCheckpoints()[_end] */
      0x00
      dup4
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":21348:21385  _getCheckpoints()[_end].fromRequestId */
      sload
        /* "src/core/WithdrawalQueueBase.sol":21334:21385  _requestId >= _getCheckpoints()[_end].fromRequestId */
      dup6
      lt
        /* "src/core/WithdrawalQueueBase.sol":21330:21683  if (_requestId >= _getCheckpoints()[_end].fromRequestId) {... */
      tag_729
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":21468:21487  lastCheckpointIndex */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":21460:21464  _end */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":21460:21487  _end == lastCheckpointIndex */
      eq
        /* "src/core/WithdrawalQueueBase.sol":21456:21500  if (_end == lastCheckpointIndex) return _end */
      iszero
      tag_730
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":21496:21500  _end */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":21489:21500  return _end */
      swap2
      pop
      pop
      jump(tag_381)
        /* "src/core/WithdrawalQueueBase.sol":21456:21500  if (_end == lastCheckpointIndex) return _end */
    tag_730:
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":21587:21614  _getCheckpoints()[_end + 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21605:21613  _end + 1 */
      tag_732
        /* "src/core/WithdrawalQueueBase.sol":21605:21609  _end */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":21612:21613  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":21605:21613  _end + 1 */
      tag_439
      jump	// in
    tag_732:
        /* "src/core/WithdrawalQueueBase.sol":21587:21614  _getCheckpoints()[_end + 1] */
      dup2
      mstore
      0x20
      add
      swap1
      dup2
      mstore
      0x20
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":21587:21628  _getCheckpoints()[_end + 1].fromRequestId */
      0x00
      add
      sload
        /* "src/core/WithdrawalQueueBase.sol":21574:21584  _requestId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":21574:21628  _requestId < _getCheckpoints()[_end + 1].fromRequestId */
      lt
        /* "src/core/WithdrawalQueueBase.sol":21570:21641  if (_requestId < _getCheckpoints()[_end + 1].fromRequestId) return _end */
      iszero
      tag_733
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":21637:21641  _end */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":21630:21641  return _end */
      swap2
      pop
      pop
      jump(tag_381)
        /* "src/core/WithdrawalQueueBase.sol":21570:21641  if (_requestId < _getCheckpoints()[_end + 1].fromRequestId) return _end */
    tag_733:
        /* "src/core/WithdrawalQueueBase.sol":1073:1074  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21656:21672  return NOT_FOUND */
      swap2
      pop
      pop
      jump(tag_381)
        /* "src/core/WithdrawalQueueBase.sol":21330:21683  if (_requestId >= _getCheckpoints()[_end].fromRequestId) {... */
    tag_729:
        /* "src/core/WithdrawalQueueBase.sol":21734:21759  _getCheckpoints()[_start] */
      0x00
      dup5
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":21734:21773  _getCheckpoints()[_start].fromRequestId */
      sload
        /* "src/core/WithdrawalQueueBase.sol":21721:21773  _requestId < _getCheckpoints()[_start].fromRequestId */
      dup6
      lt
        /* "src/core/WithdrawalQueueBase.sol":21717:21816  if (_requestId < _getCheckpoints()[_start].fromRequestId) {... */
      iszero
      tag_735
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":1073:1074  0 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21789:21805  return NOT_FOUND */
      swap2
      pop
      pop
      jump(tag_381)
        /* "src/core/WithdrawalQueueBase.sol":21717:21816  if (_requestId < _getCheckpoints()[_start].fromRequestId) {... */
    tag_735:
        /* "src/core/WithdrawalQueueBase.sol":21865:21871  _start */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":21851:21862  uint256 min */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21895:21903  _end - 1 */
      tag_736
        /* "src/core/WithdrawalQueueBase.sol":21902:21903  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":21895:21899  _end */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":21895:21903  _end - 1 */
      tag_414
      jump	// in
    tag_736:
        /* "src/core/WithdrawalQueueBase.sol":21881:21903  uint256 max = _end - 1 */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":21914:22153  while (max > min) {... */
    tag_737:
        /* "src/core/WithdrawalQueueBase.sol":21927:21930  min */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":21921:21924  max */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":21921:21930  max > min */
      gt
        /* "src/core/WithdrawalQueueBase.sol":21914:22153  while (max > min) {... */
      iszero
      tag_738
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":21946:21957  uint256 mid */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":21978:21979  2 */
      0x02
        /* "src/core/WithdrawalQueueBase.sol":21961:21970  max + min */
      tag_739
        /* "src/core/WithdrawalQueueBase.sol":21967:21970  min */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":21961:21964  max */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":21961:21970  max + min */
      tag_439
      jump	// in
    tag_739:
        /* "src/core/WithdrawalQueueBase.sol":21961:21974  max + min + 1 */
      tag_740
      swap1
        /* "src/core/WithdrawalQueueBase.sol":21973:21974  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":21961:21974  max + min + 1 */
      tag_439
      jump	// in
    tag_740:
        /* "src/core/WithdrawalQueueBase.sol":21960:21979  (max + min + 1) / 2 */
      tag_741
      swap2
      swap1
      tag_437
      jump	// in
    tag_741:
        /* "src/core/WithdrawalQueueBase.sol":21997:22019  _getCheckpoints()[mid] */
      0x00
      dup2
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":21997:22033  _getCheckpoints()[mid].fromRequestId */
      sload
        /* "src/core/WithdrawalQueueBase.sol":21946:21979  uint256 mid = (max + min + 1) / 2 */
      swap1
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":21997:22047  _getCheckpoints()[mid].fromRequestId <= _requestId */
      dup9
      lt
        /* "src/core/WithdrawalQueueBase.sol":21993:22143  if (_getCheckpoints()[mid].fromRequestId <= _requestId) {... */
      tag_743
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":22073:22076  mid */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":22067:22076  min = mid */
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":21993:22143  if (_getCheckpoints()[mid].fromRequestId <= _requestId) {... */
      jump(tag_744)
    tag_743:
        /* "src/core/WithdrawalQueueBase.sol":22121:22128  mid - 1 */
      tag_745
        /* "src/core/WithdrawalQueueBase.sol":22127:22128  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":22121:22124  mid */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":22121:22128  mid - 1 */
      tag_414
      jump	// in
    tag_745:
        /* "src/core/WithdrawalQueueBase.sol":22115:22128  max = mid - 1 */
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":21993:22143  if (_getCheckpoints()[mid].fromRequestId <= _requestId) {... */
    tag_744:
        /* "src/core/WithdrawalQueueBase.sol":21932:22153  {... */
      pop
        /* "src/core/WithdrawalQueueBase.sol":21914:22153  while (max > min) {... */
      jump(tag_737)
    tag_738:
      pop
        /* "src/core/WithdrawalQueueBase.sol":22169:22172  min */
      swap6
        /* "src/core/WithdrawalQueueBase.sol":20799:22179  function _findCheckpointHint(uint256 _requestId, uint256 _start, uint256 _end) internal view returns (uint256) {... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":11924:12178  function values(UintSet storage set) internal view returns (uint256[] memory) {... */
    tag_377:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":11984:12000  uint256[] memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":12012:12034  bytes32[] memory store */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":12037:12056  _values(set._inner) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":12045:12048  set */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":12037:12044  _values */
      tag_749
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":12037:12056  _values(set._inner) */
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8870:9026  function at(AddressSet storage set, uint256 index) internal view returns (address) {... */
    tag_384:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8944:8951  address */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8994:9016  _at(set._inner, index) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8998:9001  set */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":9010:9015  index */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8994:8997  _at */
      tag_753
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8994:9016  _at(set._inner, index) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":27984:28143  function _setLastReportTimestamp(uint256 _lastReportTimestamp) internal {... */
    tag_392:
        /* "src/core/WithdrawalQueueBase.sol":28066:28136  LAST_REPORT_TIMESTAMP_POSITION.setStorageUint256(_lastReportTimestamp) */
      tag_481
        /* "src/core/WithdrawalQueueBase.sol":2360:2413  keccak256("lido.WithdrawalQueue.lastReportTimestamp") */
      0x6825d6bead7081b4d1ac062bbb771f0e4ade13182688453e79955a721d58c4dd
        /* "src/core/WithdrawalQueueBase.sol":28115:28135  _lastReportTimestamp */
      dup3
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":26455:26666  function _getQueue() internal pure returns (mapping(uint256 => WithdrawalRequest) storage queue) {... */
    tag_424:
        /* "src/core/WithdrawalQueueBase.sol":1201:1240  keccak256("lido.WithdrawalQueue.queue") */
      0xe21b95c4eb1b99fd548b219e3b5c175a8efb31f910cb76456b20e14eba8cfe43
      swap1
        /* "src/core/WithdrawalQueueBase.sol":26455:26666  function _getQueue() internal pure returns (mapping(uint256 => WithdrawalRequest) storage queue) {... */
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":25944:26374  function _calcBatch(WithdrawalRequest memory _preStartRequest, WithdrawalRequest memory _endRequest)... */
    tag_432:
        /* "src/core/WithdrawalQueueBase.sol":26194:26226  _preStartRequest.cumulativeStETH */
      dup2
      mload
        /* "src/core/WithdrawalQueueBase.sol":26164:26191  _endRequest.cumulativeStETH */
      dup2
      mload
        /* "src/core/WithdrawalQueueBase.sol":26092:26109  uint256 shareRate */
      0x00
      swap2
      dup3
      swap2
      dup3
      swap2
        /* "src/core/WithdrawalQueueBase.sol":26164:26226  _endRequest.cumulativeStETH - _preStartRequest.cumulativeStETH */
      tag_758
      swap2
      tag_514
      jump	// in
    tag_758:
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":26156:26226  stETH = _endRequest.cumulativeStETH - _preStartRequest.cumulativeStETH */
      and
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":26276:26292  _preStartRequest */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":26276:26309  _preStartRequest.cumulativeShares */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":26245:26256  _endRequest */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":26245:26273  _endRequest.cumulativeShares */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":26245:26309  _endRequest.cumulativeShares - _preStartRequest.cumulativeShares */
      tag_759
      swap2
      swap1
      tag_514
      jump	// in
    tag_759:
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":26236:26309  shares = _endRequest.cumulativeShares - _preStartRequest.cumulativeShares */
      and
      swap1
      pop
      dup1
        /* "src/core/WithdrawalQueueBase.sol":26332:26358  stETH * E27_PRECISION_BASE */
      tag_760
        /* "src/core/WithdrawalQueueBase.sol":952:956  1e27 */
      0x033b2e3c9fd0803ce8000000
        /* "src/core/WithdrawalQueueBase.sol":26332:26337  stETH */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":26332:26358  stETH * E27_PRECISION_BASE */
      tag_435
      jump	// in
    tag_760:
        /* "src/core/WithdrawalQueueBase.sol":26332:26367  stETH * E27_PRECISION_BASE / shares */
      tag_761
      swap2
      swap1
      tag_437
      jump	// in
    tag_761:
        /* "src/core/WithdrawalQueueBase.sol":26320:26367  shareRate = stETH * E27_PRECISION_BASE / shares */
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":25944:26374  function _calcBatch(WithdrawalRequest memory _preStartRequest, WithdrawalRequest memory _endRequest)... */
      swap3
      pop
      swap3
      pop
      swap3
      jump	// out
        /* "src/core/utils/PausableUntil.sol":2410:2836  function _pauseUntil(uint256 _pauseUntilInclusive) internal {... */
    tag_448:
        /* "src/core/utils/PausableUntil.sol":2480:2495  _checkResumed() */
      tag_763
        /* "src/core/utils/PausableUntil.sol":2480:2493  _checkResumed */
      tag_278
        /* "src/core/utils/PausableUntil.sol":2480:2495  _checkResumed() */
      jump	// in
    tag_763:
        /* "src/core/utils/PausableUntil.sol":2532:2547  block.timestamp */
      timestamp
        /* "src/core/utils/PausableUntil.sol":2509:2529  _pauseUntilInclusive */
      dup2
        /* "src/core/utils/PausableUntil.sol":2509:2547  _pauseUntilInclusive < block.timestamp */
      lt
        /* "src/core/utils/PausableUntil.sol":2505:2582  if (_pauseUntilInclusive < block.timestamp) revert PauseUntilMustBeInFuture() */
      iszero
      tag_764
      jumpi
        /* "src/core/utils/PausableUntil.sol":2556:2582  PauseUntilMustBeInFuture() */
      mload(0x40)
      shl(0xe1, 0x39e2ec53)
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
        /* "src/core/utils/PausableUntil.sol":2505:2582  if (_pauseUntilInclusive < block.timestamp) revert PauseUntilMustBeInFuture() */
    tag_764:
        /* "src/core/utils/PausableUntil.sol":2593:2612  uint256 resumeSince */
      0x00
      not(0x00)
        /* "src/core/utils/PausableUntil.sol":2626:2646  _pauseUntilInclusive */
      dup3
        /* "src/core/utils/PausableUntil.sol":2626:2666  _pauseUntilInclusive != PAUSE_INFINITELY */
      eq
        /* "src/core/utils/PausableUntil.sol":2622:2792  if (_pauseUntilInclusive != PAUSE_INFINITELY) {... */
      tag_765
      jumpi
        /* "src/core/utils/PausableUntil.sol":2696:2720  _pauseUntilInclusive + 1 */
      tag_766
        /* "src/core/utils/PausableUntil.sol":2696:2716  _pauseUntilInclusive */
      dup3
        /* "src/core/utils/PausableUntil.sol":2719:2720  1 */
      0x01
        /* "src/core/utils/PausableUntil.sol":2696:2720  _pauseUntilInclusive + 1 */
      tag_439
      jump	// in
    tag_766:
        /* "src/core/utils/PausableUntil.sol":2682:2720  resumeSince = _pauseUntilInclusive + 1 */
      swap1
      pop
        /* "src/core/utils/PausableUntil.sol":2622:2792  if (_pauseUntilInclusive != PAUSE_INFINITELY) {... */
      jump(tag_767)
    tag_765:
      pop
      not(0x00)
    tag_767:
        /* "src/core/utils/PausableUntil.sol":2801:2829  _setPausedState(resumeSince) */
      tag_317
        /* "src/core/utils/PausableUntil.sol":2817:2828  resumeSince */
      dup2
        /* "src/core/utils/PausableUntil.sol":2801:2816  _setPausedState */
      tag_769
        /* "src/core/utils/PausableUntil.sol":2801:2829  _setPausedState(resumeSince) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":19506:20204  function _getStatus(uint256 _requestId) internal view returns (WithdrawalRequestStatus memory status) {... */
    tag_471:
        /* "src/core/WithdrawalQueueBase.sol":19569:19606  WithdrawalRequestStatus memory status */
      tag_770
      tag_464
      jump	// in
    tag_770:
        /* "src/core/WithdrawalQueueBase.sol":19622:19637  _requestId == 0 */
      dup2
      iszero
      dup1
        /* "src/core/WithdrawalQueueBase.sol":19622:19672  _requestId == 0 || _requestId > getLastRequestId() */
      tag_772
      jumpi
      pop
        /* "src/core/WithdrawalQueueBase.sol":19654:19672  getLastRequestId() */
      tag_773
        /* "src/core/WithdrawalQueueBase.sol":19654:19670  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":19654:19672  getLastRequestId() */
      jump	// in
    tag_773:
        /* "src/core/WithdrawalQueueBase.sol":19641:19651  _requestId */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":19641:19672  _requestId > getLastRequestId() */
      gt
        /* "src/core/WithdrawalQueueBase.sol":19622:19672  _requestId == 0 || _requestId > getLastRequestId() */
    tag_772:
        /* "src/core/WithdrawalQueueBase.sol":19618:19709  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
      iszero
      tag_774
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":19681:19709  InvalidRequestId(_requestId) */
      mload(0x40)
      shl(0xe1, 0x64b4f079)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup4
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":19681:19709  InvalidRequestId(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":19618:19709  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
    tag_774:
        /* "src/core/WithdrawalQueueBase.sol":19720:19752  WithdrawalRequest memory request */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":19755:19766  _getQueue() */
      tag_776
        /* "src/core/WithdrawalQueueBase.sol":19755:19764  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":19755:19766  _getQueue() */
      jump	// in
    tag_776:
        /* "src/core/WithdrawalQueueBase.sol":19755:19778  _getQueue()[_requestId] */
      0x00
      dup5
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":19720:19778  WithdrawalRequest memory request = _getQueue()[_requestId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap5
      dup2
      add
      swap5
      swap1
      swap5
      mstore
      0x01
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap2
      dup5
      add
      swap2
      swap1
      swap2
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup6
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup6
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup4
      add
      mstore
      swap1
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":19831:19842  _getQueue() */
      tag_777
        /* "src/core/WithdrawalQueueBase.sol":19831:19840  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":19831:19842  _getQueue() */
      jump	// in
    tag_777:
        /* "src/core/WithdrawalQueueBase.sol":19831:19858  _getQueue()[_requestId - 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":19843:19857  _requestId - 1 */
      tag_778
        /* "src/core/WithdrawalQueueBase.sol":19856:19857  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":19843:19853  _requestId */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":19843:19857  _requestId - 1 */
      tag_414
      jump	// in
    tag_778:
        /* "src/core/WithdrawalQueueBase.sol":19831:19858  _getQueue()[_requestId - 1] */
      dup2
      mstore
      0x20
      dup1
      dup3
      add
      swap3
      swap1
      swap3
      mstore
      0x40
      swap1
      dup2
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":19788:19858  WithdrawalRequest memory previousRequest = _getQueue()[_requestId - 1] */
      dup2
      mload
      0xc0
      dup1
      dup3
      add
      dup5
      mstore
      dup3
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup5
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap5
      dup3
      add
      swap5
      swap1
      swap5
      mstore
      0x01
      swap1
      swap2
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      dup3
      dup5
      add
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup3
      div
      dup2
      and
      0x60
      dup5
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup4
      div
      and
      iszero
      iszero
      0x80
      dup5
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap2
      div
      and
      0xa0
      dup3
      add
      mstore
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      dup2
      mload
      swap3
      dup4
      add
      swap1
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":19941:19972  previousRequest.cumulativeStETH */
      dup1
      mload
        /* "src/core/WithdrawalQueueBase.sol":19915:19938  request.cumulativeStETH */
      dup5
      mload
        /* "src/core/WithdrawalQueueBase.sol":19788:19858  WithdrawalRequest memory previousRequest = _getQueue()[_requestId - 1] */
      swap2
      swap4
      pop
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      dup3
      swap2
        /* "src/core/WithdrawalQueueBase.sol":19915:19972  request.cumulativeStETH - previousRequest.cumulativeStETH */
      tag_779
      swap2
        /* "src/core/WithdrawalQueueBase.sol":19941:19972  previousRequest.cumulativeStETH */
      swap1
        /* "src/core/WithdrawalQueueBase.sol":19915:19972  request.cumulativeStETH - previousRequest.cumulativeStETH */
      tag_514
      jump	// in
    tag_779:
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":20013:20028  previousRequest */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":20013:20045  previousRequest.cumulativeShares */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":19986:19993  request */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":19986:20010  request.cumulativeShares */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":19986:20045  request.cumulativeShares - previousRequest.cumulativeShares */
      tag_780
      swap2
      swap1
      tag_514
      jump	// in
    tag_780:
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":20059:20066  request */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":20059:20072  request.owner */
      0x40
      add
      mload
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":20086:20093  request */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":20086:20103  request.timestamp */
      0x60
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      0xffffffffff
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":20131:20158  getLastFinalizedRequestId() */
      tag_781
        /* "src/core/WithdrawalQueueBase.sol":20131:20156  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueueBase.sol":20131:20158  getLastFinalizedRequestId() */
      jump	// in
    tag_781:
        /* "src/core/WithdrawalQueueBase.sol":20117:20127  _requestId */
      dup7
        /* "src/core/WithdrawalQueueBase.sol":20117:20158  _requestId <= getLastFinalizedRequestId() */
      gt
      iszero
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      iszero
      iszero
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":20172:20179  request */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":20172:20187  request.claimed */
      0x80
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":19878:20197  WithdrawalRequestStatus(... */
      iszero
      iszero
      dup2
      mstore
      pop
        /* "src/core/WithdrawalQueueBase.sol":19869:20197  status = WithdrawalRequestStatus(... */
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":19608:20204  {... */
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":19506:20204  function _getStatus(uint256 _requestId) internal view returns (WithdrawalRequestStatus memory status) {... */
      swap2
      swap1
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":17571:17914  function _initialize(address _admin) internal {... */
    tag_482:
        /* "src/core/WithdrawalQueue.sol":17627:17645  _initializeQueue() */
      tag_783
        /* "src/core/WithdrawalQueue.sol":17627:17643  _initializeQueue */
      tag_784
        /* "src/core/WithdrawalQueue.sol":17627:17645  _initializeQueue() */
      jump	// in
    tag_783:
        /* "src/core/WithdrawalQueue.sol":17655:17682  _pauseFor(PAUSE_INFINITELY) */
      tag_785
      not(0x00)
        /* "src/core/WithdrawalQueue.sol":17655:17664  _pauseFor */
      tag_614
        /* "src/core/WithdrawalQueue.sol":17655:17682  _pauseFor(PAUSE_INFINITELY) */
      jump	// in
    tag_785:
        /* "src/core/WithdrawalQueue.sol":17693:17724  _initializeContractVersionTo(1) */
      tag_786
        /* "src/core/WithdrawalQueue.sol":17722:17723  1 */
      0x01
        /* "src/core/WithdrawalQueue.sol":17693:17721  _initializeContractVersionTo */
      tag_787
        /* "src/core/WithdrawalQueue.sol":17693:17724  _initializeContractVersionTo(1) */
      jump	// in
    tag_786:
        /* "src/core/WithdrawalQueue.sol":17735:17773  _grantRole(DEFAULT_ADMIN_ROLE, _admin) */
      tag_788
        /* "src/core/utils/access/AccessControl.sol":2678:2682  0x00 */
      0x00
        /* "src/core/WithdrawalQueue.sol":17766:17772  _admin */
      dup3
        /* "src/core/WithdrawalQueue.sol":17735:17745  _grantRole */
      tag_311
        /* "src/core/WithdrawalQueue.sol":17735:17773  _grantRole(DEFAULT_ADMIN_ROLE, _admin) */
      jump	// in
    tag_788:
      not(0x00)
      0x00
      dup1
      mload
      0x20
      data_b589db986128d3258a700f5bc8482afbd859dc508593ec30968f79002edbed47
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      sstore
        /* "src/core/WithdrawalQueue.sol":17886:17907  InitializedV1(_admin) */
      mload(0x40)
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":5724:5756   */
      dup3
      and
        /* "#utility.yul":5706:5757   */
      dup2
      mstore
        /* "src/core/WithdrawalQueue.sol":17886:17907  InitializedV1(_admin) */
      0x20b34d2aaaf6acb4fbbc9c4846858bb824053ab11ff44a59dfba1e22ceb8a509
      swap1
        /* "#utility.yul":5694:5696   */
      0x20
        /* "#utility.yul":5679:5697   */
      add
        /* "src/core/WithdrawalQueue.sol":17886:17907  InitializedV1(_admin) */
    tag_790:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log1
        /* "src/core/WithdrawalQueue.sol":17571:17914  function _initialize(address _admin) internal {... */
      pop
      jump	// out
        /* "src/core/WithdrawalQueue.sol":19321:19768  function _getClaimableEther(uint256 _requestId, uint256 _hint) internal view returns (uint256) {... */
    tag_495:
        /* "src/core/WithdrawalQueue.sol":19407:19414  uint256 */
      0x00
        /* "src/core/WithdrawalQueue.sol":19430:19445  _requestId == 0 */
      dup3
      iszero
      dup1
        /* "src/core/WithdrawalQueue.sol":19430:19480  _requestId == 0 || _requestId > getLastRequestId() */
      tag_792
      jumpi
      pop
        /* "src/core/WithdrawalQueue.sol":19462:19480  getLastRequestId() */
      tag_793
        /* "src/core/WithdrawalQueue.sol":19462:19478  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueue.sol":19462:19480  getLastRequestId() */
      jump	// in
    tag_793:
        /* "src/core/WithdrawalQueue.sol":19449:19459  _requestId */
      dup4
        /* "src/core/WithdrawalQueue.sol":19449:19480  _requestId > getLastRequestId() */
      gt
        /* "src/core/WithdrawalQueue.sol":19430:19480  _requestId == 0 || _requestId > getLastRequestId() */
    tag_792:
        /* "src/core/WithdrawalQueue.sol":19426:19517  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
      iszero
      tag_794
      jumpi
        /* "src/core/WithdrawalQueue.sol":19489:19517  InvalidRequestId(_requestId) */
      mload(0x40)
      shl(0xe1, 0x64b4f079)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":19489:19517  InvalidRequestId(_requestId) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueue.sol":19426:19517  if (_requestId == 0 || _requestId > getLastRequestId()) revert InvalidRequestId(_requestId) */
    tag_794:
        /* "src/core/WithdrawalQueue.sol":19545:19572  getLastFinalizedRequestId() */
      tag_796
        /* "src/core/WithdrawalQueue.sol":19545:19570  getLastFinalizedRequestId */
      tag_119
        /* "src/core/WithdrawalQueue.sol":19545:19572  getLastFinalizedRequestId() */
      jump	// in
    tag_796:
        /* "src/core/WithdrawalQueue.sol":19532:19542  _requestId */
      dup4
        /* "src/core/WithdrawalQueue.sol":19532:19572  _requestId > getLastFinalizedRequestId() */
      gt
        /* "src/core/WithdrawalQueue.sol":19528:19582  if (_requestId > getLastFinalizedRequestId()) return 0 */
      iszero
      tag_797
      jumpi
      pop
        /* "src/core/WithdrawalQueue.sol":19581:19582  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":19574:19582  return 0 */
      jump(tag_269)
        /* "src/core/WithdrawalQueue.sol":19528:19582  if (_requestId > getLastFinalizedRequestId()) return 0 */
    tag_797:
        /* "src/core/WithdrawalQueue.sol":19593:19626  WithdrawalRequest storage request */
      0x00
        /* "src/core/WithdrawalQueue.sol":19629:19640  _getQueue() */
      tag_798
        /* "src/core/WithdrawalQueue.sol":19629:19638  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueue.sol":19629:19640  _getQueue() */
      jump	// in
    tag_798:
        /* "src/core/WithdrawalQueue.sol":19629:19652  _getQueue()[_requestId] */
      0x00
      dup6
      dup2
      mstore
      0x20
      swap2
      swap1
      swap2
      mstore
      0x40
      swap1
      keccak256
        /* "src/core/WithdrawalQueue.sol":19666:19681  request.claimed */
      0x01
      dup2
      add
      sload
        /* "src/core/WithdrawalQueue.sol":19629:19652  _getQueue()[_requestId] */
      swap1
      swap2
      pop
      shl(0xc8, 0x01)
        /* "src/core/WithdrawalQueue.sol":19666:19681  request.claimed */
      swap1
      div
      0xff
      and
        /* "src/core/WithdrawalQueue.sol":19662:19691  if (request.claimed) return 0 */
      iszero
      tag_799
      jumpi
        /* "src/core/WithdrawalQueue.sol":19690:19691  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":19683:19691  return 0 */
      swap2
      pop
      pop
      jump(tag_269)
        /* "src/core/WithdrawalQueue.sol":19662:19691  if (request.claimed) return 0 */
    tag_799:
        /* "src/core/WithdrawalQueue.sol":19709:19761  _calculateClaimableEther(request, _requestId, _hint) */
      tag_800
        /* "src/core/WithdrawalQueue.sol":19734:19741  request */
      dup2
        /* "src/core/WithdrawalQueue.sol":19743:19753  _requestId */
      dup6
        /* "src/core/WithdrawalQueue.sol":19755:19760  _hint */
      dup6
        /* "src/core/WithdrawalQueue.sol":19709:19733  _calculateClaimableEther */
      tag_705
        /* "src/core/WithdrawalQueue.sol":19709:19761  _calculateClaimableEther(request, _requestId, _hint) */
      jump	// in
    tag_800:
        /* "src/core/WithdrawalQueue.sol":19702:19761  return _calculateClaimableEther(request, _requestId, _hint) */
      swap5
        /* "src/core/WithdrawalQueue.sol":19321:19768  function _getClaimableEther(uint256 _requestId, uint256 _hint) internal view returns (uint256) {... */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8413:8528  function length(AddressSet storage set) internal view returns (uint256) {... */
    tag_502:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8476:8483  uint256 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8502:8521  _length(set._inner) */
      tag_269
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8510:8513  set */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4028:4046  set._values.length */
      sload
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3946:4053  function _length(Set storage set) private view returns (uint256) {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":27343:27478  function _setLastRequestId(uint256 _lastRequestId) internal {... */
    tag_505:
        /* "src/core/WithdrawalQueueBase.sol":27413:27471  LAST_REQUEST_ID_POSITION.setStorageUint256(_lastRequestId) */
      tag_481
        /* "src/core/WithdrawalQueueBase.sol":1340:1387  keccak256("lido.WithdrawalQueue.lastRequestId") */
      0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041
        /* "src/core/WithdrawalQueueBase.sol":27456:27470  _lastRequestId */
      dup3
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/WithdrawalQueue.sol":18867:19207  function _checkWithdrawalRequestAmount(uint256 _amountOfStETH) internal pure {... */
    tag_533:
        /* "src/core/WithdrawalQueue.sol":2484:2487  100 */
      0x64
        /* "src/core/WithdrawalQueue.sol":18958:18972  _amountOfStETH */
      dup2
        /* "src/core/WithdrawalQueue.sol":18958:19002  _amountOfStETH < MIN_STETH_WITHDRAWAL_AMOUNT */
      lt
        /* "src/core/WithdrawalQueue.sol":18954:19073  if (_amountOfStETH < MIN_STETH_WITHDRAWAL_AMOUNT) {... */
      iszero
      tag_807
      jumpi
        /* "src/core/WithdrawalQueue.sol":19025:19062  RequestAmountTooSmall(_amountOfStETH) */
      mload(0x40)
      shl(0xe3, 0x171370f9)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup3
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":19025:19062  RequestAmountTooSmall(_amountOfStETH) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueue.sol":18954:19073  if (_amountOfStETH < MIN_STETH_WITHDRAWAL_AMOUNT) {... */
    tag_807:
        /* "src/core/WithdrawalQueue.sol":2818:2829  1000 * 1e18 */
      0x3635c9adc5dea00000
        /* "src/core/WithdrawalQueue.sol":19086:19100  _amountOfStETH */
      dup2
        /* "src/core/WithdrawalQueue.sol":19086:19130  _amountOfStETH > MAX_STETH_WITHDRAWAL_AMOUNT */
      gt
        /* "src/core/WithdrawalQueue.sol":19082:19201  if (_amountOfStETH > MAX_STETH_WITHDRAWAL_AMOUNT) {... */
      iszero
      tag_481
      jumpi
        /* "src/core/WithdrawalQueue.sol":19153:19190  RequestAmountTooLarge(_amountOfStETH) */
      mload(0x40)
      shl(0xe0, 0x8ebfb78d)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup3
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":19153:19190  RequestAmountTooLarge(_amountOfStETH) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueue.sol":17920:18325  function _requestWithdrawal(uint256 _amountOfStETH, address _owner) internal returns (uint256 requestId) {... */
    tag_537:
        /* "src/core/WithdrawalQueue.sol":18035:18096  STETH.transferFrom(msg.sender, address(this), _amountOfStETH) */
      mload(0x40)
      shl(0xe0, 0x23b872dd)
      dup2
      mstore
        /* "src/core/WithdrawalQueue.sol":18054:18064  msg.sender */
      caller
        /* "src/core/WithdrawalQueue.sol":18035:18096  STETH.transferFrom(msg.sender, address(this), _amountOfStETH) */
      0x04
      dup3
      add
        /* "#utility.yul":18725:18759   */
      mstore
        /* "src/core/WithdrawalQueue.sol":18074:18078  this */
      address
        /* "#utility.yul":18775:18793   */
      0x24
      dup3
      add
        /* "#utility.yul":18768:18811   */
      mstore
        /* "#utility.yul":18827:18845   */
      0x44
      dup2
      add
        /* "#utility.yul":18820:18854   */
      dup4
      swap1
      mstore
        /* "src/core/WithdrawalQueue.sol":18006:18023  uint256 requestId */
      0x00
      swap1
        /* "src/core/WithdrawalQueue.sol":18035:18040  STETH */
      immutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":18035:18053  STETH.transferFrom */
      and
      swap1
      0x23b872dd
      swap1
        /* "#utility.yul":18660:18678   */
      0x64
      add
        /* "src/core/WithdrawalQueue.sol":18035:18096  STETH.transferFrom(msg.sender, address(this), _amountOfStETH) */
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x00
      dup8
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_813
      jumpi
      0x00
      dup1
      revert
    tag_813:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_815
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_815:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      not(0x1f)
      0x1f
      dup3
      add
      and
      dup3
      add
      dup1
      0x40
      mstore
      pop
      dup2
      add
      swap1
      tag_816
      swap2
      swap1
      tag_655
      jump	// in
    tag_816:
      pop
        /* "src/core/WithdrawalQueue.sol":18132:18174  STETH.getSharesByPooledEth(_amountOfStETH) */
      mload(0x40)
      shl(0xe0, 0x19208451)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "src/core/WithdrawalQueue.sol":18107:18129  uint256 amountOfShares */
      0x00
      swap1
        /* "src/core/WithdrawalQueue.sol":18132:18137  STETH */
      immutable("0xa570d8e206167497b077d8e037f9b3c67068f1e3da0834fee823fee7a1c2031f")
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueue.sol":18132:18158  STETH.getSharesByPooledEth */
      and
      swap1
      0x19208451
      swap1
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueue.sol":18132:18174  STETH.getSharesByPooledEth(_amountOfStETH) */
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup7
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_818
      jumpi
      0x00
      dup1
      revert
    tag_818:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_820
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_820:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      not(0x1f)
      0x1f
      dup3
      add
      and
      dup3
      add
      dup1
      0x40
      mstore
      pop
      dup2
      add
      swap1
      tag_821
      swap2
      swap1
      tag_661
      jump	// in
    tag_821:
        /* "src/core/WithdrawalQueue.sol":18107:18174  uint256 amountOfShares = STETH.getSharesByPooledEth(_amountOfStETH) */
      swap1
      pop
        /* "src/core/WithdrawalQueue.sol":18197:18263  _enqueue(uint128(_amountOfStETH), uint128(amountOfShares), _owner) */
      tag_822
        /* "src/core/WithdrawalQueue.sol":18214:18228  _amountOfStETH */
      dup5
        /* "src/core/WithdrawalQueue.sol":18239:18253  amountOfShares */
      dup3
        /* "src/core/WithdrawalQueue.sol":18256:18262  _owner */
      dup6
        /* "src/core/WithdrawalQueue.sol":18197:18205  _enqueue */
      tag_669
        /* "src/core/WithdrawalQueue.sol":18197:18263  _enqueue(uint128(_amountOfStETH), uint128(amountOfShares), _owner) */
      jump	// in
    tag_822:
        /* "src/core/WithdrawalQueue.sol":18185:18263  requestId = _enqueue(uint128(_amountOfStETH), uint128(amountOfShares), _owner) */
      swap2
      pop
        /* "src/core/WithdrawalQueue.sol":18274:18318  _emitTransfer(address(0), _owner, requestId) */
      tag_466
        /* "src/core/WithdrawalQueue.sol":18296:18297  0 */
      0x00
        /* "src/core/WithdrawalQueue.sol":18300:18306  _owner */
      dup5
        /* "src/core/WithdrawalQueue.sol":18308:18317  requestId */
      dup5
        /* "src/core/WithdrawalQueue.sol":18274:18287  _emitTransfer */
      tag_341
        /* "src/core/WithdrawalQueue.sol":18274:18318  _emitTransfer(address(0), _owner, requestId) */
      jump	// in
        /* "src/core/utils/PausableUntil.sol":2030:2404  function _pauseFor(uint256 _duration) internal {... */
    tag_614:
        /* "src/core/utils/PausableUntil.sol":2087:2102  _checkResumed() */
      tag_825
        /* "src/core/utils/PausableUntil.sol":2087:2100  _checkResumed */
      tag_278
        /* "src/core/utils/PausableUntil.sol":2087:2102  _checkResumed() */
      jump	// in
    tag_825:
        /* "src/core/utils/PausableUntil.sol":2116:2130  _duration == 0 */
      dup1
        /* "src/core/utils/PausableUntil.sol":2112:2158  if (_duration == 0) revert ZeroPauseDuration() */
      tag_826
      jumpi
        /* "src/core/utils/PausableUntil.sol":2139:2158  ZeroPauseDuration() */
      mload(0x40)
      shl(0xe0, 0xad58bfc7)
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
        /* "src/core/utils/PausableUntil.sol":2112:2158  if (_duration == 0) revert ZeroPauseDuration() */
    tag_826:
        /* "src/core/utils/PausableUntil.sol":2169:2188  uint256 resumeSince */
      0x00
      not(0x00)
        /* "src/core/utils/PausableUntil.sol":2202:2211  _duration */
      dup3
        /* "src/core/utils/PausableUntil.sol":2202:2231  _duration == PAUSE_INFINITELY */
      eq
        /* "src/core/utils/PausableUntil.sol":2198:2360  if (_duration == PAUSE_INFINITELY) {... */
      iszero
      tag_827
      jumpi
      pop
      not(0x00)
      jump(tag_767)
    tag_827:
        /* "src/core/utils/PausableUntil.sol":2322:2349  block.timestamp + _duration */
      tag_829
        /* "src/core/utils/PausableUntil.sol":2340:2349  _duration */
      dup3
        /* "src/core/utils/PausableUntil.sol":2322:2337  block.timestamp */
      timestamp
        /* "src/core/utils/PausableUntil.sol":2322:2349  block.timestamp + _duration */
      tag_439
      jump	// in
    tag_829:
        /* "src/core/utils/PausableUntil.sol":2308:2349  resumeSince = block.timestamp + _duration */
      swap1
      pop
        /* "src/core/utils/PausableUntil.sol":2369:2397  _setPausedState(resumeSince) */
      tag_317
        /* "src/core/utils/PausableUntil.sol":2385:2396  resumeSince */
      dup2
        /* "src/core/utils/PausableUntil.sol":2369:2384  _setPausedState */
      tag_769
        /* "src/core/utils/PausableUntil.sol":2369:2397  _setPausedState(resumeSince) */
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1588:2029  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {... */
    tag_635:
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1663:1676  string memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1688:1707  bytes memory buffer */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1720:1730  2 * length */
      tag_833
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1724:1730  length */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1720:1721  2 */
      0x02
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1720:1730  2 * length */
      tag_435
      jump	// in
    tag_833:
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1720:1734  2 * length + 2 */
      tag_834
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1733:1734  2 */
      0x02
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1720:1734  2 * length + 2 */
      tag_439
      jump	// in
    tag_834:
      sub(shl(0x40, 0x01), 0x01)
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1710:1735  new bytes(2 * length + 2) */
      dup2
      gt
      iszero
      tag_836
      jumpi
      tag_836
      tag_282
      jump	// in
    tag_836:
      mload(0x40)
      swap1
      dup1
      dup3
      mstore
      dup1
      0x1f
      add
      not(0x1f)
      and
      0x20
      add
      dup3
      add
      0x40
      mstore
      dup1
      iszero
      tag_837
      jumpi
      0x20
      dup3
      add
      dup2
      dup1
      calldatasize
      dup4
      calldatacopy
      add
      swap1
      pop
    tag_837:
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1688:1735  bytes memory buffer = new bytes(2 * length + 2) */
      swap1
      pop
      shl(0xfc, 0x03)
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1745:1751  buffer */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1752:1753  0 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1745:1754  buffer[0] */
      dup2
      mload
      dup2
      lt
      tag_839
      jumpi
      tag_839
      tag_290
      jump	// in
    tag_839:
      0x20
      add
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1745:1760  buffer[0] = "0" */
      swap1
      not(sub(shl(0xf8, 0x01), 0x01))
      and
      swap1
      dup2
      0x00
      byte
      swap1
      mstore8
      pop
      shl(0xfb, 0x0f)
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1770:1776  buffer */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1777:1778  1 */
      0x01
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1770:1779  buffer[1] */
      dup2
      mload
      dup2
      lt
      tag_841
      jumpi
      tag_841
      tag_290
      jump	// in
    tag_841:
      0x20
      add
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1770:1785  buffer[1] = "x" */
      swap1
      not(sub(shl(0xf8, 0x01), 0x01))
      and
      swap1
      dup2
      0x00
      byte
      swap1
      mstore8
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1800:1809  uint256 i */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1812:1822  2 * length */
      tag_845
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1816:1822  length */
      dup5
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1812:1813  2 */
      0x02
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1812:1822  2 * length */
      tag_435
      jump	// in
    tag_845:
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1812:1826  2 * length + 1 */
      tag_846
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1825:1826  1 */
      0x01
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1812:1826  2 * length + 1 */
      tag_439
      jump	// in
    tag_846:
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1800:1826  uint256 i = 2 * length + 1 */
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1795:1927  for (uint256 i = 2 * length + 1; i > 1; --i) {... */
    tag_842:
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1832:1833  1 */
      0x01
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1828:1829  i */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1828:1833  i > 1 */
      gt
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1795:1927  for (uint256 i = 2 * length + 1; i > 1; --i) {... */
      iszero
      tag_843
      jumpi
      shl(0x81, 0x181899199a1a9b1b9c1cb0b131b232b3)
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1879:1884  value */
      dup6
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1887:1890  0xf */
      0x0f
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1879:1890  value & 0xf */
      and
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1866:1891  _HEX_SYMBOLS[value & 0xf] */
      0x10
      dup2
      lt
      tag_848
      jumpi
      tag_848
      tag_290
      jump	// in
    tag_848:
      byte
      0xf8
      shl
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1854:1860  buffer */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1861:1862  i */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1854:1863  buffer[i] */
      dup2
      mload
      dup2
      lt
      tag_850
      jumpi
      tag_850
      tag_290
      jump	// in
    tag_850:
      0x20
      add
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1854:1891  buffer[i] = _HEX_SYMBOLS[value & 0xf] */
      swap1
      not(sub(shl(0xf8, 0x01), 0x01))
      and
      swap1
      dup2
      0x00
      byte
      swap1
      mstore8
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1915:1916  4 */
      0x04
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1905:1916  value >>= 4 */
      swap5
      swap1
      swap5
      shr
      swap4
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1835:1838  --i */
      tag_851
      dup2
      tag_852
      jump	// in
    tag_851:
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1795:1927  for (uint256 i = 2 * length + 1; i > 1; --i) {... */
      jump(tag_842)
    tag_843:
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1944:1954  value == 0 */
      dup4
      iszero
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1936:1991  require(value == 0, "Strings: hex length insufficient") */
      tag_381
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
        /* "#utility.yul":20088:20090   */
      0x20
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1936:1991  require(value == 0, "Strings: hex length insufficient") */
      0x04
      dup3
      add
        /* "#utility.yul":20070:20091   */
      dup2
      swap1
      mstore
        /* "#utility.yul":20107:20125   */
      0x24
      dup3
      add
        /* "#utility.yul":20100:20130   */
      mstore
        /* "#utility.yul":20166:20200   */
      0x537472696e67733a20686578206c656e67746820696e73756666696369656e74
        /* "#utility.yul":20146:20164   */
      0x44
      dup3
      add
        /* "#utility.yul":20139:20201   */
      mstore
        /* "#utility.yul":20218:20236   */
      0x64
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/Strings.sol":1936:1991  require(value == 0, "Strings: hex length insufficient") */
      tag_315
        /* "#utility.yul":19886:20242   */
      jump
        /* "src/core/utils/PausableUntil.sol":1042:1161  function _checkPaused() internal view {... */
    tag_643:
        /* "src/core/utils/PausableUntil.sol":1095:1105  isPaused() */
      tag_857
        /* "src/core/utils/PausableUntil.sol":1095:1103  isPaused */
      tag_187
        /* "src/core/utils/PausableUntil.sol":1095:1105  isPaused() */
      jump	// in
    tag_857:
        /* "src/core/utils/PausableUntil.sol":1090:1155  if (!isPaused()) {... */
      tag_274
      jumpi
        /* "src/core/utils/PausableUntil.sol":1128:1144  PausedExpected() */
      mload(0x40)
      shl(0xe0, 0xb047186b)
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
        /* "src/core/WithdrawalQueueBase.sol":18439:19421  function _enqueue(uint128 _amountOfStETH, uint128 _amountOfShares, address _owner)... */
    tag_669:
        /* "src/core/WithdrawalQueueBase.sol":18556:18573  uint256 requestId */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":18589:18610  uint256 lastRequestId */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":18613:18631  getLastRequestId() */
      tag_860
        /* "src/core/WithdrawalQueueBase.sol":18613:18629  getLastRequestId */
      tag_89
        /* "src/core/WithdrawalQueueBase.sol":18613:18631  getLastRequestId() */
      jump	// in
    tag_860:
        /* "src/core/WithdrawalQueueBase.sol":18589:18631  uint256 lastRequestId = getLastRequestId() */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":18641:18677  WithdrawalRequest memory lastRequest */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":18680:18691  _getQueue() */
      tag_861
        /* "src/core/WithdrawalQueueBase.sol":18680:18689  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":18680:18691  _getQueue() */
      jump	// in
    tag_861:
        /* "src/core/WithdrawalQueueBase.sol":18680:18706  _getQueue()[lastRequestId] */
      0x00
      dup4
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":18641:18706  WithdrawalRequest memory lastRequest = _getQueue()[lastRequestId] */
      dup2
      mload
      0xc0
      dup2
      add
      dup4
      mstore
      dup2
      sload
      sub(shl(0x80, 0x01), 0x01)
      dup1
      dup3
      and
      dup4
      mstore
      shl(0x80, 0x01)
      swap1
      swap2
      div
      and
      swap5
      dup2
      add
      dup6
      swap1
      mstore
      0x01
      swap1
      swap2
      add
      sload
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      and
      swap3
      dup3
      add
      swap3
      swap1
      swap3
      mstore
      0xffffffffff
      shl(0xa0, 0x01)
      dup4
      div
      dup2
      and
      0x60
      dup4
      add
      mstore
      0xff
      shl(0xc8, 0x01)
      dup5
      div
      and
      iszero
      iszero
      0x80
      dup4
      add
      mstore
      shl(0xd0, 0x01)
      swap1
      swap3
      div
      swap1
      swap2
      and
      0xa0
      dup3
      add
      mstore
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":18680:18706  _getQueue()[lastRequestId] */
      swap1
        /* "src/core/WithdrawalQueueBase.sol":18744:18790  lastRequest.cumulativeShares + _amountOfShares */
      tag_862
      swap1
        /* "src/core/WithdrawalQueueBase.sol":18775:18790  _amountOfShares */
      dup8
      swap1
        /* "src/core/WithdrawalQueueBase.sol":18744:18790  lastRequest.cumulativeShares + _amountOfShares */
      tag_863
      jump	// in
    tag_862:
        /* "src/core/WithdrawalQueueBase.sol":18717:18790  uint128 cumulativeShares = lastRequest.cumulativeShares + _amountOfShares */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":18800:18823  uint128 cumulativeStETH */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":18856:18870  _amountOfStETH */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":18826:18837  lastRequest */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":18826:18853  lastRequest.cumulativeStETH */
      0x00
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":18826:18870  lastRequest.cumulativeStETH + _amountOfStETH */
      tag_864
      swap2
      swap1
      tag_863
      jump	// in
    tag_864:
        /* "src/core/WithdrawalQueueBase.sol":18800:18870  uint128 cumulativeStETH = lastRequest.cumulativeStETH + _amountOfStETH */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":18893:18910  lastRequestId + 1 */
      tag_865
        /* "src/core/WithdrawalQueueBase.sol":18893:18906  lastRequestId */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":18909:18910  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":18893:18910  lastRequestId + 1 */
      tag_439
      jump	// in
    tag_865:
        /* "src/core/WithdrawalQueueBase.sol":18881:18910  requestId = lastRequestId + 1 */
      swap5
      pop
        /* "src/core/WithdrawalQueueBase.sol":18921:18949  _setLastRequestId(requestId) */
      tag_866
        /* "src/core/WithdrawalQueueBase.sol":18939:18948  requestId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":18921:18938  _setLastRequestId */
      tag_505
        /* "src/core/WithdrawalQueueBase.sol":18921:18949  _setLastRequestId(requestId) */
      jump	// in
    tag_866:
        /* "src/core/WithdrawalQueueBase.sol":18960:18995  WithdrawalRequest memory newRequest */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      mload(0x40)
      dup1
      0xc0
      add
      0x40
      mstore
      dup1
        /* "src/core/WithdrawalQueueBase.sol":19030:19045  cumulativeStETH */
      dup4
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":19059:19075  cumulativeShares */
      dup5
      sub(shl(0x80, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":19089:19095  _owner */
      dup9
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":19116:19131  block.timestamp */
      timestamp
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      0xffffffffff
      and
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":19146:19151  false */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      iszero
      iszero
      dup2
      mstore
      0x20
      add
        /* "src/core/WithdrawalQueueBase.sol":19172:19197  _getLastReportTimestamp() */
      tag_867
        /* "src/core/WithdrawalQueueBase.sol":19172:19195  _getLastReportTimestamp */
      tag_868
        /* "src/core/WithdrawalQueueBase.sol":19172:19197  _getLastReportTimestamp() */
      jump	// in
    tag_867:
        /* "src/core/WithdrawalQueueBase.sol":18999:19208  WithdrawalRequest(... */
      0xffffffffff
      and
      swap1
      mstore
        /* "src/core/WithdrawalQueueBase.sol":18960:19208  WithdrawalRequest memory newRequest =  WithdrawalRequest(... */
      swap1
      pop
      dup1
        /* "src/core/WithdrawalQueueBase.sol":19218:19229  _getQueue() */
      tag_869
        /* "src/core/WithdrawalQueueBase.sol":19218:19227  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":19218:19229  _getQueue() */
      jump	// in
    tag_869:
        /* "src/core/WithdrawalQueueBase.sol":19218:19240  _getQueue()[requestId] */
      0x00
      dup9
      dup2
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":19218:19253  _getQueue()[requestId] = newRequest */
      dup5
      mload
      dup6
      dup6
      add
      mload
      sub(shl(0x80, 0x01), 0x01)
      swap1
      dup2
      and
      shl(0x80, 0x01)
      mul
      swap2
      and
      or
      dup2
      sstore
      dup5
      dup3
      add
      mload
      0x01
      swap1
      swap2
      add
      dup1
      sload
      0x60
      dup8
      add
      mload
      0x80
      dup9
      add
      mload
      0xa0
      swap1
      swap9
      add
      mload
      0xffffffffff
      swap1
      dup2
      and
      shl(0xd0, 0x01)
      mul
      not(shl(0xd0, 0xffffffffff))
      swap10
      iszero
      iszero
      shl(0xc8, 0x01)
      mul
      swap10
      swap1
      swap10
      and
      not(shl(0xc8, 0xffffffffffff))
      swap2
      swap1
      swap3
      and
      shl(0xa0, 0x01)
      mul
      not(sub(shl(0xc8, 0x01), 0x01))
      swap1
      swap4
      and
      sub(shl(0xa0, 0x01), 0x01)
      swap6
      dup7
      and
      or
      swap3
      swap1
      swap3
      or
      swap2
      swap1
      swap2
      and
      or
      swap6
      swap1
      swap6
      or
      swap1
      swap5
      sstore
        /* "src/core/WithdrawalQueueBase.sol":19270:19299  _getRequestsByOwner()[_owner] */
      swap3
      dup11
      and
      dup2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":2197:2246  keccak256("lido.WithdrawalQueue.requestsByOwner") */
      0x4b9bfe0774f05ab288bd50bd23f74ae80a797f1d0c82d419d43ebda4fdc2fe1f
        /* "src/core/WithdrawalQueueBase.sol":19270:19299  _getRequestsByOwner()[_owner] */
      swap1
      swap2
      mstore
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":19270:19314  _getRequestsByOwner()[_owner].add(requestId) */
      tag_870
      swap1
        /* "src/core/WithdrawalQueueBase.sol":19218:19240  _getQueue()[requestId] */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":19270:19303  _getRequestsByOwner()[_owner].add */
      tag_872
        /* "src/core/WithdrawalQueueBase.sol":19270:19314  _getRequestsByOwner()[_owner].add(requestId) */
      jump	// in
    tag_870:
        /* "src/core/WithdrawalQueueBase.sol":19263:19315  assert(_getRequestsByOwner()[_owner].add(requestId)) */
      tag_874
      jumpi
      tag_874
      tag_703
      jump	// in
    tag_874:
        /* "src/core/WithdrawalQueueBase.sol":19331:19414  WithdrawalRequested(requestId, msg.sender, _owner, _amountOfStETH, _amountOfShares) */
      0x40
      dup1
      mload
      sub(shl(0x80, 0x01), 0x01)
        /* "#utility.yul":20750:20765   */
      dup1
      dup13
      and
        /* "#utility.yul":20732:20766   */
      dup3
      mstore
        /* "#utility.yul":20802:20817   */
      dup11
      and
        /* "#utility.yul":20797:20799   */
      0x20
        /* "#utility.yul":20782:20800   */
      dup3
      add
        /* "#utility.yul":20775:20818   */
      mstore
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":19331:19414  WithdrawalRequested(requestId, msg.sender, _owner, _amountOfStETH, _amountOfShares) */
      dup10
      and
      swap2
        /* "src/core/WithdrawalQueueBase.sol":19362:19372  msg.sender */
      caller
      swap2
        /* "src/core/WithdrawalQueueBase.sol":19351:19360  requestId */
      dup10
      swap2
        /* "src/core/WithdrawalQueueBase.sol":19331:19414  WithdrawalRequested(requestId, msg.sender, _owner, _amountOfStETH, _amountOfShares) */
      0xf0cb471f23fb74ea44b8252eb1881a2dca546288d9f6e90d1a0e82fe0ed342ab
      swap2
        /* "#utility.yul":20652:20670   */
      add
        /* "src/core/WithdrawalQueueBase.sol":19331:19414  WithdrawalRequested(requestId, msg.sender, _owner, _amountOfStETH, _amountOfShares) */
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log4
        /* "src/core/WithdrawalQueueBase.sol":18579:19421  {... */
      pop
      pop
      pop
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":18439:19421  function _enqueue(uint128 _amountOfStETH, uint128 _amountOfShares, address _owner)... */
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/core/utils/access/AccessControl.sol":7470:7712  function _grantRole(bytes32 role, address account) internal virtual {... */
    tag_676:
        /* "src/core/utils/access/AccessControl.sol":7553:7575  hasRole(role, account) */
      tag_878
        /* "src/core/utils/access/AccessControl.sol":7561:7565  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":7567:7574  account */
      dup3
        /* "src/core/utils/access/AccessControl.sol":7553:7560  hasRole */
      tag_157
        /* "src/core/utils/access/AccessControl.sol":7553:7575  hasRole(role, account) */
      jump	// in
    tag_878:
        /* "src/core/utils/access/AccessControl.sol":7548:7706  if (!hasRole(role, account)) {... */
      tag_317
      jumpi
        /* "src/core/utils/access/AccessControl.sol":7591:7612  _storageRoles()[role] */
      0x00
      dup3
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_91113e80635bccc2f93908fdf2a5cbd6a74badad069abcad4f85e45f73ab3f4c
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/utils/access/AccessControl.sol":7591:7629  _storageRoles()[role].members[account] */
      dup6
      and
      dup1
      dup6
      mstore
      swap3
      mstore
      dup1
      dup4
      keccak256
        /* "src/core/utils/access/AccessControl.sol":7591:7636  _storageRoles()[role].members[account] = true */
      dup1
      sload
      not(0xff)
      and
        /* "src/core/utils/access/AccessControl.sol":7632:7636  true */
      0x01
        /* "src/core/utils/access/AccessControl.sol":7591:7636  _storageRoles()[role].members[account] = true */
      or
      swap1
      sstore
        /* "src/core/utils/access/AccessControl.sol":7655:7695  RoleGranted(role, account, _msgSender()) */
      mload
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
      swap3
        /* "src/core/utils/access/AccessControl.sol":7591:7612  _storageRoles()[role] */
      dup6
      swap2
        /* "src/core/utils/access/AccessControl.sol":7655:7695  RoleGranted(role, account, _msgSender()) */
      0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d
      swap2
        /* "src/core/utils/access/AccessControl.sol":7591:7612  _storageRoles()[role] */
      swap1
        /* "src/core/utils/access/AccessControl.sol":7655:7695  RoleGranted(role, account, _msgSender()) */
      log4
        /* "src/core/utils/access/AccessControl.sol":7470:7712  function _grantRole(bytes32 role, address account) internal virtual {... */
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7612:7762  function add(AddressSet storage set, address value) internal returns (bool) {... */
    tag_679:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7682:7686  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7705:7755  _add(set._inner, bytes32(uint256(uint160(value)))) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7710:7713  set */
      dup4
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7730:7753  uint256(uint160(value)) */
      dup5
      and
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7705:7709  _add */
      tag_884
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7705:7755  _add(set._inner, bytes32(uint256(uint160(value)))) */
      jump	// in
        /* "src/core/utils/access/AccessControl.sol":7837:8080  function _revokeRole(bytes32 role, address account) internal virtual {... */
    tag_682:
        /* "src/core/utils/access/AccessControl.sol":7920:7942  hasRole(role, account) */
      tag_886
        /* "src/core/utils/access/AccessControl.sol":7928:7932  role */
      dup3
        /* "src/core/utils/access/AccessControl.sol":7934:7941  account */
      dup3
        /* "src/core/utils/access/AccessControl.sol":7920:7927  hasRole */
      tag_157
        /* "src/core/utils/access/AccessControl.sol":7920:7942  hasRole(role, account) */
      jump	// in
    tag_886:
        /* "src/core/utils/access/AccessControl.sol":7916:8074  if (hasRole(role, account)) {... */
      iszero
      tag_317
      jumpi
        /* "src/core/utils/access/AccessControl.sol":7999:8004  false */
      0x00
        /* "src/core/utils/access/AccessControl.sol":7958:7979  _storageRoles()[role] */
      dup3
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_91113e80635bccc2f93908fdf2a5cbd6a74badad069abcad4f85e45f73ab3f4c
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/utils/access/AccessControl.sol":7958:7996  _storageRoles()[role].members[account] */
      dup6
      and
      dup1
      dup6
      mstore
      swap3
      mstore
      dup1
      dup4
      keccak256
        /* "src/core/utils/access/AccessControl.sol":7958:8004  _storageRoles()[role].members[account] = false */
      dup1
      sload
      not(0xff)
      and
      swap1
      sstore
        /* "src/core/utils/access/AccessControl.sol":8023:8063  RoleRevoked(role, account, _msgSender()) */
      mload
        /* "src/@openzeppelin/contracts-v4.4/utils/Context.sol":719:729  msg.sender */
      caller
      swap3
        /* "src/core/utils/access/AccessControl.sol":7958:7979  _storageRoles()[role] */
      dup6
      swap2
        /* "src/core/utils/access/AccessControl.sol":8023:8063  RoleRevoked(role, account, _msgSender()) */
      0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b
      swap2
        /* "src/core/utils/access/AccessControl.sol":7999:8004  false */
      swap1
        /* "src/core/utils/access/AccessControl.sol":8023:8063  RoleRevoked(role, account, _msgSender()) */
      log4
        /* "src/core/utils/access/AccessControl.sol":7837:8080  function _revokeRole(bytes32 role, address account) internal virtual {... */
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":7930:8086  function remove(AddressSet storage set, address value) internal returns (bool) {... */
    tag_685:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8003:8007  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8026:8079  _remove(set._inner, bytes32(uint256(uint160(value)))) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8034:8037  set */
      dup4
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8054:8077  uint256(uint160(value)) */
      dup5
      and
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8026:8033  _remove */
      tag_892
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":8026:8079  _remove(set._inner, bytes32(uint256(uint160(value)))) */
      jump	// in
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10354:10489  function remove(UintSet storage set, uint256 value) internal returns (bool) {... */
    tag_700:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10424:10428  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10447:10482  _remove(set._inner, bytes32(value)) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10455:10458  set */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10475:10480  value */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10447:10454  _remove */
      tag_892
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10447:10482  _remove(set._inner, bytes32(value)) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":23754:25037  function _calculateClaimableEther(WithdrawalRequest storage _request, uint256 _requestId, uint256 _hint)... */
    tag_705:
        /* "src/core/WithdrawalQueueBase.sol":23906:23928  uint256 claimableEther */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":23948:23958  _hint == 0 */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":23944:23985  if (_hint == 0) revert InvalidHint(_hint) */
      tag_896
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":23967:23985  InvalidHint(_hint) */
      mload(0x40)
      shl(0xe1, 0x6773bc71)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup4
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":23967:23985  InvalidHint(_hint) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":23944:23985  if (_hint == 0) revert InvalidHint(_hint) */
    tag_896:
        /* "src/core/WithdrawalQueueBase.sol":23996:24023  uint256 lastCheckpointIndex */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24026:24050  getLastCheckpointIndex() */
      tag_898
        /* "src/core/WithdrawalQueueBase.sol":24026:24048  getLastCheckpointIndex */
      tag_122
        /* "src/core/WithdrawalQueueBase.sol":24026:24050  getLastCheckpointIndex() */
      jump	// in
    tag_898:
        /* "src/core/WithdrawalQueueBase.sol":23996:24050  uint256 lastCheckpointIndex = getLastCheckpointIndex() */
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":24072:24091  lastCheckpointIndex */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":24064:24069  _hint */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":24064:24091  _hint > lastCheckpointIndex */
      gt
        /* "src/core/WithdrawalQueueBase.sol":24060:24118  if (_hint > lastCheckpointIndex) revert InvalidHint(_hint) */
      iszero
      tag_899
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":24100:24118  InvalidHint(_hint) */
      mload(0x40)
      shl(0xe1, 0x6773bc71)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup5
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":24100:24118  InvalidHint(_hint) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":24060:24118  if (_hint > lastCheckpointIndex) revert InvalidHint(_hint) */
    tag_899:
        /* "src/core/WithdrawalQueueBase.sol":24129:24157  Checkpoint memory checkpoint */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24160:24184  _getCheckpoints()[_hint] */
      dup4
      dup2
      mstore
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      0x20
      swap1
      dup2
      mstore
      0x40
      swap2
      dup3
      swap1
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":24129:24184  Checkpoint memory checkpoint = _getCheckpoints()[_hint] */
      dup3
      mload
      dup1
      dup5
      add
      swap1
      swap4
      mstore
      dup1
      sload
      dup1
      dup5
      mstore
      0x01
      swap1
      swap2
      add
      sload
      swap2
      dup4
      add
      swap2
      swap1
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":24333:24370  _requestId < checkpoint.fromRequestId */
      dup6
      lt
        /* "src/core/WithdrawalQueueBase.sol":24329:24397  if (_requestId < checkpoint.fromRequestId) revert InvalidHint(_hint) */
      iszero
      tag_902
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":24379:24397  InvalidHint(_hint) */
      mload(0x40)
      shl(0xe1, 0x6773bc71)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup6
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":24379:24397  InvalidHint(_hint) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":24329:24397  if (_requestId < checkpoint.fromRequestId) revert InvalidHint(_hint) */
    tag_902:
        /* "src/core/WithdrawalQueueBase.sol":24419:24438  lastCheckpointIndex */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":24411:24416  _hint */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":24411:24438  _hint < lastCheckpointIndex */
      lt
        /* "src/core/WithdrawalQueueBase.sol":24407:24694  if (_hint < lastCheckpointIndex) {... */
      iszero
      tag_904
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":24533:24565  Checkpoint memory nextCheckpoint */
      0x00
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":24568:24596  _getCheckpoints()[_hint + 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24586:24595  _hint + 1 */
      tag_906
        /* "src/core/WithdrawalQueueBase.sol":24586:24591  _hint */
      dup8
        /* "src/core/WithdrawalQueueBase.sol":24594:24595  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":24586:24595  _hint + 1 */
      tag_439
      jump	// in
    tag_906:
        /* "src/core/WithdrawalQueueBase.sol":24568:24596  _getCheckpoints()[_hint + 1] */
      dup2
      mstore
      0x20
      add
      swap1
      dup2
      mstore
      0x20
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":24533:24596  Checkpoint memory nextCheckpoint = _getCheckpoints()[_hint + 1] */
      mload(0x40)
      dup1
      0x40
      add
      0x40
      mstore
      swap1
      dup2
      0x00
      dup3
      add
      sload
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      sload
      dup2
      mstore
      pop
      pop
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":24646:24656  _requestId */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":24614:24628  nextCheckpoint */
      dup2
        /* "src/core/WithdrawalQueueBase.sol":24614:24642  nextCheckpoint.fromRequestId */
      0x00
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":24614:24656  nextCheckpoint.fromRequestId <= _requestId */
      gt
        /* "src/core/WithdrawalQueueBase.sol":24610:24683  if (nextCheckpoint.fromRequestId <= _requestId) revert InvalidHint(_hint) */
      tag_907
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":24665:24683  InvalidHint(_hint) */
      mload(0x40)
      shl(0xe1, 0x6773bc71)
      dup2
      mstore
      0x04
      dup2
      add
        /* "#utility.yul":643:668   */
      dup7
      swap1
      mstore
        /* "#utility.yul":616:634   */
      0x24
      add
        /* "src/core/WithdrawalQueueBase.sol":24665:24683  InvalidHint(_hint) */
      tag_315
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":24610:24683  if (nextCheckpoint.fromRequestId <= _requestId) revert InvalidHint(_hint) */
    tag_907:
        /* "src/core/WithdrawalQueueBase.sol":24440:24694  {... */
      pop
        /* "src/core/WithdrawalQueueBase.sol":24407:24694  if (_hint < lastCheckpointIndex) {... */
    tag_904:
        /* "src/core/WithdrawalQueueBase.sol":24704:24740  WithdrawalRequest memory prevRequest */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24743:24754  _getQueue() */
      tag_909
        /* "src/core/WithdrawalQueueBase.sol":24743:24752  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":24743:24754  _getQueue() */
      jump	// in
    tag_909:
        /* "src/core/WithdrawalQueueBase.sol":24743:24770  _getQueue()[_requestId - 1] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24755:24769  _requestId - 1 */
      tag_910
        /* "src/core/WithdrawalQueueBase.sol":24768:24769  1 */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":24755:24765  _requestId */
      dup10
        /* "src/core/WithdrawalQueueBase.sol":24755:24769  _requestId - 1 */
      tag_414
      jump	// in
    tag_910:
        /* "src/core/WithdrawalQueueBase.sol":24743:24770  _getQueue()[_requestId - 1] */
      dup2
      mstore
      0x20
      add
      swap1
      dup2
      mstore
      0x20
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":24704:24770  WithdrawalRequest memory prevRequest = _getQueue()[_requestId - 1] */
      mload(0x40)
      dup1
      0xc0
      add
      0x40
      mstore
      swap1
      dup2
      0x00
      dup3
      add
      0x00
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x00
      dup3
      add
      0x10
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x00
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0xa0, 0x01), 0x01)
      and
      sub(shl(0xa0, 0x01), 0x01)
      and
      sub(shl(0xa0, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x14
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xffffffffff
      and
      0xffffffffff
      and
      0xffffffffff
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x19
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xff
      and
      iszero
      iszero
      iszero
      iszero
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x1a
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xffffffffff
      and
      0xffffffffff
      and
      0xffffffffff
      and
      dup2
      mstore
      pop
      pop
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":24781:24803  uint256 batchShareRate */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24805:24816  uint256 eth */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":24818:24832  uint256 shares */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":24836:24869  _calcBatch(prevRequest, _request) */
      tag_911
        /* "src/core/WithdrawalQueueBase.sol":24847:24858  prevRequest */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":24860:24868  _request */
      dup12
        /* "src/core/WithdrawalQueueBase.sol":24836:24869  _calcBatch(prevRequest, _request) */
      mload(0x40)
      dup1
      0xc0
      add
      0x40
      mstore
      swap1
      dup2
      0x00
      dup3
      add
      0x00
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x00
      dup3
      add
      0x10
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      sub(shl(0x80, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x00
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      sub(shl(0xa0, 0x01), 0x01)
      and
      sub(shl(0xa0, 0x01), 0x01)
      and
      sub(shl(0xa0, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x14
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xffffffffff
      and
      0xffffffffff
      and
      0xffffffffff
      and
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x19
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xff
      and
      iszero
      iszero
      iszero
      iszero
      dup2
      mstore
      0x20
      add
      0x01
      dup3
      add
      0x1a
      swap1
      sload
      swap1
      0x0100
      exp
      swap1
      div
      0xffffffffff
      and
      0xffffffffff
      and
      0xffffffffff
      and
      dup2
      mstore
      pop
      pop
        /* "src/core/WithdrawalQueueBase.sol":24836:24846  _calcBatch */
      tag_432
        /* "src/core/WithdrawalQueueBase.sol":24836:24869  _calcBatch(prevRequest, _request) */
      jump	// in
    tag_911:
        /* "src/core/WithdrawalQueueBase.sol":24780:24869  (uint256 batchShareRate, uint256 eth, uint256 shares) = _calcBatch(prevRequest, _request) */
      swap3
      pop
      swap3
      pop
      swap3
      pop
        /* "src/core/WithdrawalQueueBase.sol":24901:24911  checkpoint */
      dup5
        /* "src/core/WithdrawalQueueBase.sol":24901:24924  checkpoint.maxShareRate */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":24884:24898  batchShareRate */
      dup4
        /* "src/core/WithdrawalQueueBase.sol":24884:24924  batchShareRate > checkpoint.maxShareRate */
      gt
        /* "src/core/WithdrawalQueueBase.sol":24880:25010  if (batchShareRate > checkpoint.maxShareRate) {... */
      iszero
      tag_912
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":952:956  1e27 */
      0x033b2e3c9fd0803ce8000000
        /* "src/core/WithdrawalQueueBase.sol":24955:24965  checkpoint */
      dup6
        /* "src/core/WithdrawalQueueBase.sol":24955:24978  checkpoint.maxShareRate */
      0x20
      add
      mload
        /* "src/core/WithdrawalQueueBase.sol":24946:24952  shares */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":24946:24978  shares * checkpoint.maxShareRate */
      tag_913
      swap2
      swap1
      tag_435
      jump	// in
    tag_913:
        /* "src/core/WithdrawalQueueBase.sol":24946:24999  shares * checkpoint.maxShareRate / E27_PRECISION_BASE */
      tag_914
      swap2
      swap1
      tag_437
      jump	// in
    tag_914:
        /* "src/core/WithdrawalQueueBase.sol":24940:24999  eth = shares * checkpoint.maxShareRate / E27_PRECISION_BASE */
      swap2
      pop
        /* "src/core/WithdrawalQueueBase.sol":24880:25010  if (batchShareRate > checkpoint.maxShareRate) {... */
    tag_912:
      pop
        /* "src/core/WithdrawalQueueBase.sol":25027:25030  eth */
      swap9
        /* "src/core/WithdrawalQueueBase.sol":23754:25037  function _calculateClaimableEther(WithdrawalRequest storage _request, uint256 _requestId, uint256 _hint)... */
      swap8
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/core/WithdrawalQueueBase.sol":27827:27978  function _setLockedEtherAmount(uint256 _lockedEtherAmount) internal {... */
    tag_709:
        /* "src/core/WithdrawalQueueBase.sol":27905:27971  LOCKED_ETHER_AMOUNT_POSITION.setStorageUint256(_lockedEtherAmount) */
      tag_481
        /* "src/core/WithdrawalQueueBase.sol":2032:2083  keccak256("lido.WithdrawalQueue.lockedEtherAmount") */
      0x0e27eaa2e71c8572ab988fef0b54cd45bbd1740de1e22343fb6cda7536edc12f
        /* "src/core/WithdrawalQueueBase.sol":27952:27970  _lockedEtherAmount */
      dup3
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/WithdrawalQueueBase.sol":25508:25822  function _sendValue(address _recipient, uint256 _amount) internal {... */
    tag_711:
        /* "src/core/WithdrawalQueueBase.sol":25612:25619  _amount */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":25588:25609  address(this).balance */
      selfbalance
        /* "src/core/WithdrawalQueueBase.sol":25588:25619  address(this).balance < _amount */
      lt
        /* "src/core/WithdrawalQueueBase.sol":25584:25644  if (address(this).balance < _amount) revert NotEnoughEther() */
      iszero
      tag_918
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":25628:25644  NotEnoughEther() */
      mload(0x40)
      shl(0xe0, 0x8a0d3779)
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
        /* "src/core/WithdrawalQueueBase.sol":25584:25644  if (address(this).balance < _amount) revert NotEnoughEther() */
    tag_918:
        /* "src/core/WithdrawalQueueBase.sol":25693:25705  bool success */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":25710:25720  _recipient */
      dup3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WithdrawalQueueBase.sol":25710:25725  _recipient.call */
      and
        /* "src/core/WithdrawalQueueBase.sol":25733:25740  _amount */
      dup3
        /* "src/core/WithdrawalQueueBase.sol":25710:25745  _recipient.call{value: _amount}("") */
      mload(0x40)
      0x00
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup6
      dup8
      gas
      call
      swap3
      pop
      pop
      pop
      returndatasize
      dup1
      0x00
      dup2
      eq
      tag_923
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
      jump(tag_922)
    tag_923:
      0x60
      swap2
      pop
    tag_922:
      pop
        /* "src/core/WithdrawalQueueBase.sol":25692:25745  (bool success,) = _recipient.call{value: _amount}("") */
      pop
      swap1
      pop
        /* "src/core/WithdrawalQueueBase.sol":25760:25767  success */
      dup1
        /* "src/core/WithdrawalQueueBase.sol":25755:25815  if (!success) revert CantSendValueRecipientMayHaveReverted() */
      tag_310
      jumpi
        /* "src/core/WithdrawalQueueBase.sol":25776:25815  CantSendValueRecipientMayHaveReverted() */
      mload(0x40)
      shl(0xe0, 0x0f0b498d)
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
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5053:5162  function _values(Set storage set) private view returns (bytes32[] memory) {... */
    tag_749:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5109:5125  bytes32[] memory */
      0x60
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5144:5147  set */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5144:5155  set._values */
      0x00
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5137:5155  return set._values */
      dup1
      sload
      dup1
      0x20
      mul
      0x20
      add
      mload(0x40)
      swap1
      dup2
      add
      0x40
      mstore
      dup1
      swap3
      swap2
      swap1
      dup2
      dup2
      mstore
      0x20
      add
      dup3
      dup1
      sload
      dup1
      iszero
      tag_927
      jumpi
      0x20
      mul
      dup3
      add
      swap2
      swap1
      0x00
      mstore
      keccak256(0x00, 0x20)
      swap1
    tag_928:
      dup2
      sload
      dup2
      mstore
      0x20
      add
      swap1
      0x01
      add
      swap1
      dup1
      dup4
      gt
      tag_928
      jumpi
    tag_927:
      pop
      pop
      pop
      pop
      pop
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":5053:5162  function _values(Set storage set) private view returns (bytes32[] memory) {... */
      swap2
      swap1
      pop
      jump	// out
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4395:4513  function _at(Set storage set, uint256 index) private view returns (bytes32) {... */
    tag_753:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4462:4469  bytes32 */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4488:4491  set */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4488:4499  set._values */
      0x00
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4500:4505  index */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4488:4506  set._values[index] */
      dup2
      sload
      dup2
      lt
      tag_931
      jumpi
      tag_931
      tag_290
      jump	// in
    tag_931:
      swap1
      0x00
      mstore
      keccak256(0x00, 0x20)
      add
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4481:4506  return set._values[index] */
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":4395:4513  function _at(Set storage set, uint256 index) private view returns (bytes32) {... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/core/utils/PausableUntil.sol":2842:3153  function _setPausedState(uint256 _resumeSince) internal {... */
    tag_769:
        /* "src/core/utils/PausableUntil.sol":2908:2971  RESUME_SINCE_TIMESTAMP_POSITION.setStorageUint256(_resumeSince) */
      tag_934
      0x00
      dup1
      mload
      0x20
      data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/utils/PausableUntil.sol":2958:2970  _resumeSince */
      dup3
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/utils/PausableUntil.sol":2908:2971  RESUME_SINCE_TIMESTAMP_POSITION.setStorageUint256(_resumeSince) */
    tag_934:
      not(0x00)
        /* "src/core/utils/PausableUntil.sol":2985:2997  _resumeSince */
      dup2
        /* "src/core/utils/PausableUntil.sol":2985:3017  _resumeSince == PAUSE_INFINITELY */
      eq
        /* "src/core/utils/PausableUntil.sol":2981:3147  if (_resumeSince == PAUSE_INFINITELY) {... */
      iszero
      tag_935
      jumpi
        /* "src/core/utils/PausableUntil.sol":3038:3062  Paused(PAUSE_INFINITELY) */
      mload(0x40)
      not(0x00)
        /* "#utility.yul":643:668   */
      dup2
      mstore
        /* "src/core/utils/PausableUntil.sol":3038:3062  Paused(PAUSE_INFINITELY) */
      0x32fb7c9891bc4f963c7de9f1186d2a7755c7d6e9f4604dabe1d8bb3027c2f49e
      swap1
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
        /* "src/core/utils/PausableUntil.sol":3038:3062  Paused(PAUSE_INFINITELY) */
      tag_790
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/utils/PausableUntil.sol":2981:3147  if (_resumeSince == PAUSE_INFINITELY) {... */
    tag_935:
        /* "src/core/utils/PausableUntil.sol":3098:3136  Paused(_resumeSince - block.timestamp) */
      0x32fb7c9891bc4f963c7de9f1186d2a7755c7d6e9f4604dabe1d8bb3027c2f49e
        /* "src/core/utils/PausableUntil.sol":3105:3135  _resumeSince - block.timestamp */
      tag_938
        /* "src/core/utils/PausableUntil.sol":3120:3135  block.timestamp */
      timestamp
        /* "src/core/utils/PausableUntil.sol":3105:3117  _resumeSince */
      dup4
        /* "src/core/utils/PausableUntil.sol":3105:3135  _resumeSince - block.timestamp */
      tag_414
      jump	// in
    tag_938:
        /* "src/core/utils/PausableUntil.sol":3098:3136  Paused(_resumeSince - block.timestamp) */
      mload(0x40)
        /* "#utility.yul":643:668   */
      swap1
      dup2
      mstore
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
        /* "src/core/utils/PausableUntil.sol":3098:3136  Paused(_resumeSince - block.timestamp) */
      tag_790
        /* "#utility.yul":497:674   */
      jump
        /* "src/core/WithdrawalQueueBase.sol":25074:25502  function _initializeQueue() internal {... */
    tag_784:
        /* "src/core/WithdrawalQueueBase.sol":25354:25423  WithdrawalRequest(0, 0, address(0), uint40(block.timestamp), true, 0) */
      0x40
      dup1
      mload
      0xc0
      dup2
      add
      dup3
      mstore
      0x00
      dup1
      dup3
      mstore
      0x20
      dup3
      add
      dup2
      swap1
      mstore
      swap2
      dup2
      add
      dup3
      swap1
      mstore
      0xffffffffff
        /* "src/core/WithdrawalQueueBase.sol":25397:25412  block.timestamp */
      timestamp
        /* "src/core/WithdrawalQueueBase.sol":25354:25423  WithdrawalRequest(0, 0, address(0), uint40(block.timestamp), true, 0) */
      and
      0x60
      dup3
      add
      mstore
        /* "src/core/WithdrawalQueueBase.sol":25415:25419  true */
      0x01
        /* "src/core/WithdrawalQueueBase.sol":25354:25423  WithdrawalRequest(0, 0, address(0), uint40(block.timestamp), true, 0) */
      0x80
      dup3
      add
      mstore
      0xa0
      dup2
      add
      swap2
      swap1
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":25337:25348  _getQueue() */
      tag_941
        /* "src/core/WithdrawalQueueBase.sol":25337:25346  _getQueue */
      tag_424
        /* "src/core/WithdrawalQueueBase.sol":25337:25348  _getQueue() */
      jump	// in
    tag_941:
        /* "src/core/WithdrawalQueueBase.sol":25337:25351  _getQueue()[0] */
      0x00
      dup1
      dup1
      mstore
      0x20
      swap2
      dup3
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":25337:25423  _getQueue()[0] = WithdrawalRequest(0, 0, address(0), uint40(block.timestamp), true, 0) */
      dup5
      mload
      dup6
      dup6
      add
      mload
      sub(shl(0x80, 0x01), 0x01)
      swap2
      dup3
      and
      shl(0x80, 0x01)
      swap3
      swap1
      swap2
      and
      swap2
      swap1
      swap2
      mul
      or
      dup2
      sstore
      dup5
      dup3
      add
      mload
      0x01
      swap1
      swap2
      add
      dup1
      sload
      0x60
      dup8
      add
      mload
      0x80
      dup9
      add
      mload
      0xa0
      swap1
      swap9
      add
      mload
      sub(shl(0xa0, 0x01), 0x01)
      swap1
      swap5
      and
      not(sub(shl(0xc8, 0x01), 0x01))
      swap1
      swap3
      and
      swap2
      swap1
      swap2
      or
      shl(0xa0, 0x01)
      0xffffffffff
      swap3
      dup4
      and
      mul
      or
      not(shl(0xc8, 0xffffffffffff))
      and
      shl(0xc8, 0x01)
      swap8
      iszero
      iszero
      swap8
      swap1
      swap8
      mul
      not(shl(0xd0, 0xffffffffff))
      and
      swap7
      swap1
      swap7
      or
      shl(0xd0, 0x01)
      swap7
      swap1
      swap3
      and
      swap6
      swap1
      swap6
      mul
      or
      swap1
      swap4
      sstore
        /* "src/core/WithdrawalQueueBase.sol":25479:25495  Checkpoint(0, 0) */
      dup3
      mload
      dup1
      dup5
      add
      swap1
      swap4
      mstore
      dup1
      dup4
      mstore
      swap1
      dup3
      add
      mstore
      0x00
      dup1
      mload
      0x20
      data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/core/WithdrawalQueueBase.sol":25433:25476  _getCheckpoints()[getLastCheckpointIndex()] */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":25451:25475  getLastCheckpointIndex() */
      tag_943
        /* "src/core/WithdrawalQueueBase.sol":25451:25473  getLastCheckpointIndex */
      tag_122
        /* "src/core/WithdrawalQueueBase.sol":25451:25475  getLastCheckpointIndex() */
      jump	// in
    tag_943:
        /* "src/core/WithdrawalQueueBase.sol":25433:25476  _getCheckpoints()[getLastCheckpointIndex()] */
      dup2
      mstore
      0x20
      dup1
      dup3
      add
      swap3
      swap1
      swap3
      mstore
      0x40
      add
      0x00
      keccak256
        /* "src/core/WithdrawalQueueBase.sol":25433:25495  _getCheckpoints()[getLastCheckpointIndex()] = Checkpoint(0, 0) */
      dup3
      mload
      dup2
      sstore
      swap2
      add
      mload
      0x01
      swap1
      swap2
      add
      sstore
        /* "src/core/WithdrawalQueueBase.sol":25074:25502  function _initializeQueue() internal {... */
      jump	// out
        /* "src/core/utils/Versioned.sol":1762:1949  function _initializeContractVersionTo(uint256 version) internal {... */
    tag_787:
        /* "src/core/utils/Versioned.sol":1840:1860  getContractVersion() */
      tag_945
        /* "src/core/utils/Versioned.sol":1840:1858  getContractVersion */
      tag_147
        /* "src/core/utils/Versioned.sol":1840:1860  getContractVersion() */
      jump	// in
    tag_945:
        /* "src/core/utils/Versioned.sol":1840:1865  getContractVersion() != 0 */
      iszero
        /* "src/core/utils/Versioned.sol":1836:1904  if (getContractVersion() != 0) revert NonZeroContractVersionOnInit() */
      tag_946
      jumpi
        /* "src/core/utils/Versioned.sol":1874:1904  NonZeroContractVersionOnInit() */
      mload(0x40)
      shl(0xe2, 0x184e52a1)
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
        /* "src/core/utils/Versioned.sol":1836:1904  if (getContractVersion() != 0) revert NonZeroContractVersionOnInit() */
    tag_946:
        /* "src/core/utils/Versioned.sol":1914:1942  _setContractVersion(version) */
      tag_481
        /* "src/core/utils/Versioned.sol":1934:1941  version */
      dup2
        /* "src/core/utils/Versioned.sol":1914:1933  _setContractVersion */
      tag_948
        /* "src/core/utils/Versioned.sol":1914:1942  _setContractVersion(version) */
      jump	// in
        /* "src/core/WithdrawalQueueBase.sol":27196:27337  function _getLastReportTimestamp() internal view returns (uint256) {... */
    tag_868:
        /* "src/core/WithdrawalQueueBase.sol":27254:27261  uint256 */
      0x00
        /* "src/core/WithdrawalQueueBase.sol":27280:27330  LAST_REPORT_TIMESTAMP_POSITION.getStorageUint256() */
      tag_297
        /* "src/core/WithdrawalQueueBase.sol":2360:2413  keccak256("lido.WithdrawalQueue.lastReportTimestamp") */
      0x6825d6bead7081b4d1ac062bbb771f0e4ade13182688453e79955a721d58c4dd
        /* "src/core/lib/UnstructuredStorage.sol":679:694  sload(position) */
      sload
      swap1
        /* "src/core/lib/UnstructuredStorage.sol":568:702  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
      jump
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10057:10186  function add(UintSet storage set, uint256 value) internal returns (bool) {... */
    tag_872:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10124:10128  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10147:10179  _add(set._inner, bytes32(value)) */
      tag_381
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10152:10155  set */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":10172:10177  value */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1697:2101  function _add(Set storage set, bytes32 value) private returns (bool) {... */
    tag_884:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1760:1764  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3834:3853  set._indexes[value] */
      dup2
      dup2
      mstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3834:3846  set._indexes */
      0x01
      dup4
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3834:3853  set._indexes[value] */
      0x20
      mstore
      0x40
      dup2
      keccak256
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1776:2095  if (!_contains(set, value)) {... */
      tag_957
      jumpi
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1818:1841  set._values.push(value) */
      dup2
      sload
      0x01
      dup2
      dup2
      add
      dup5
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1818:1829  set._values */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1818:1841  set._values.push(value) */
      dup5
      dup2
      mstore
      0x20
      dup1
      dup3
      keccak256
      swap1
      swap4
      add
      dup5
      swap1
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1998:2016  set._values.length */
      dup5
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1976:1995  set._indexes[value] */
      dup5
      dup3
      mstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1976:1988  set._indexes */
      dup3
      dup7
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1976:1995  set._indexes[value] */
      swap1
      swap4
      mstore
      0x40
      swap1
      keccak256
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1976:2016  set._indexes[value] = set._values.length */
      swap2
      swap1
      swap2
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2030:2041  return true */
      jump(tag_269)
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":1776:2095  if (!_contains(set, value)) {... */
    tag_957:
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2079:2084  false */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2072:2084  return false */
      jump(tag_269)
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2269:3657  function _remove(Set storage set, bytes32 value) private returns (bool) {... */
    tag_892:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2335:2339  bool */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2472:2491  set._indexes[value] */
      dup2
      dup2
      mstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2472:2484  set._indexes */
      0x01
      dup4
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2472:2491  set._indexes[value] */
      0x20
      mstore
      0x40
      dup2
      keccak256
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2506:2521  valueIndex != 0 */
      dup1
      iszero
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2502:3651  if (valueIndex != 0) {... */
      tag_961
      jumpi
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2875:2896  uint256 toDeleteIndex */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2899:2913  valueIndex - 1 */
      tag_962
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2912:2913  1 */
      0x01
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2899:2909  valueIndex */
      dup4
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2899:2913  valueIndex - 1 */
      tag_414
      jump	// in
    tag_962:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2947:2965  set._values.length */
      dup6
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2875:2913  uint256 toDeleteIndex = valueIndex - 1 */
      swap1
      swap2
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2927:2944  uint256 lastIndex */
      0x00
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2947:2969  set._values.length - 1 */
      tag_963
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2968:2969  1 */
      0x01
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2947:2969  set._values.length - 1 */
      tag_414
      jump	// in
    tag_963:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2927:2969  uint256 lastIndex = set._values.length - 1 */
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3001:3014  toDeleteIndex */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2988:2997  lastIndex */
      dup2
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2988:3014  lastIndex != toDeleteIndex */
      eq
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2984:3382  if (lastIndex != toDeleteIndex) {... */
      tag_964
      jumpi
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3034:3051  bytes32 lastvalue */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3054:3057  set */
      dup7
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3054:3065  set._values */
      0x00
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3066:3075  lastIndex */
      dup3
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3054:3076  set._values[lastIndex] */
      dup2
      sload
      dup2
      lt
      tag_966
      jumpi
      tag_966
      tag_290
      jump	// in
    tag_966:
      swap1
      0x00
      mstore
      keccak256(0x00, 0x20)
      add
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3034:3076  bytes32 lastvalue = set._values[lastIndex] */
      swap1
      pop
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3205:3214  lastvalue */
      dup1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3176:3179  set */
      dup8
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3176:3187  set._values */
      0x00
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3188:3201  toDeleteIndex */
      dup5
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3176:3202  set._values[toDeleteIndex] */
      dup2
      sload
      dup2
      lt
      tag_969
      jumpi
      tag_969
      tag_290
      jump	// in
    tag_969:
      0x00
      swap2
      dup3
      mstore
      0x20
      dup1
      dup4
      keccak256
      swap1
      swap2
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3176:3214  set._values[toDeleteIndex] = lastvalue */
      swap3
      swap1
      swap3
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3288:3311  set._indexes[lastvalue] */
      swap2
      dup3
      mstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3288:3300  set._indexes */
      0x01
      dup9
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3288:3311  set._indexes[lastvalue] */
      swap1
      mstore
      0x40
      swap1
      keccak256
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3288:3324  set._indexes[lastvalue] = valueIndex */
      dup4
      swap1
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2984:3382  if (lastIndex != toDeleteIndex) {... */
    tag_964:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3460:3477  set._values.pop() */
      dup6
      sload
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3460:3463  set */
      dup7
      swap1
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3460:3477  set._values.pop() */
      dup1
      tag_972
      jumpi
      tag_972
      tag_973
      jump	// in
    tag_972:
      0x01
      swap1
      sub
      dup2
      dup2
      swap1
      0x00
      mstore
      keccak256(0x00, 0x20)
      add
      0x00
      swap1
      sstore
      swap1
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3552:3555  set */
      dup6
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3552:3564  set._indexes */
      0x01
      add
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3552:3571  set._indexes[value] */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3565:3570  value */
      dup7
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3552:3571  set._indexes[value] */
      dup2
      mstore
      0x20
      add
      swap1
      dup2
      mstore
      0x20
      add
      0x00
      keccak256
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3545:3571  delete set._indexes[value] */
      0x00
      swap1
      sstore
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3593:3597  true */
      0x01
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3586:3597  return true */
      swap4
      pop
      pop
      pop
      pop
      jump(tag_269)
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":2502:3651  if (valueIndex != 0) {... */
    tag_961:
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3635:3640  false */
      0x00
        /* "src/@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol":3628:3640  return false */
      swap2
      pop
      pop
      jump(tag_269)
        /* "src/core/utils/Versioned.sol":2262:2427  function _setContractVersion(uint256 version) private {... */
    tag_948:
        /* "src/core/utils/Versioned.sol":2326:2378  CONTRACT_VERSION_POSITION.setStorageUint256(version) */
      tag_977
        /* "src/core/utils/Versioned.sol":913:956  keccak256("lido.Versioned.contractVersion") */
      0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
        /* "src/core/utils/Versioned.sol":2370:2377  version */
      dup3
        /* "src/core/lib/UnstructuredStorage.sol":1166:1188  sstore(position, data) */
      swap1
      sstore
        /* "src/core/lib/UnstructuredStorage.sol":1077:1196  function setStorageUint256(bytes32 position, uint256 data) internal {... */
      jump
        /* "src/core/utils/Versioned.sol":2326:2378  CONTRACT_VERSION_POSITION.setStorageUint256(version) */
    tag_977:
        /* "src/core/utils/Versioned.sol":2393:2420  ContractVersionSet(version) */
      mload(0x40)
        /* "#utility.yul":643:668   */
      dup2
      dup2
      mstore
        /* "src/core/utils/Versioned.sol":2393:2420  ContractVersionSet(version) */
      0xfddcded6b4f4730c226821172046b48372d3cd963c159701ae1b7c3bcac541bb
      swap1
        /* "#utility.yul":631:633   */
      0x20
        /* "#utility.yul":616:634   */
      add
        /* "src/core/utils/Versioned.sol":2393:2420  ContractVersionSet(version) */
      tag_790
        /* "#utility.yul":497:674   */
      jump
    tag_464:
      mload(0x40)
      dup1
      0xc0
      add
      0x40
      mstore
      dup1
      0x00
      dup2
      mstore
      0x20
      add
      0x00
      dup2
      mstore
      0x20
      add
      and(sub(shl(0xa0, 0x01), 0x01), 0x00)
      dup2
      mstore
      0x20
      add
      0x00
      dup2
      mstore
      0x20
      add
      iszero(iszero(0x00))
      dup2
      mstore
      0x20
      add
      iszero(iszero(0x00))
      dup2
      mstore
      pop
      swap1
      jump	// out
    tag_561:
      0x40
      dup1
      mload
      0x80
      dup2
      add
      dup3
      mstore
      0x00
      dup1
      dup3
      mstore
      0x20
      dup3
      add
      mstore
      swap1
      dup2
      add
      tag_980
      tag_981
      jump	// in
    tag_980:
      dup2
      mstore
      0x20
      add
      0x00
      dup2
      mstore
      pop
      swap1
      jump	// out
    tag_981:
      mload(0x40)
      dup1
      0x0480
      add
      0x40
      mstore
      dup1
      0x24
      swap1
      0x20
      dup3
      mul
      dup1
      calldatasize
      dup4
      calldatacopy
      pop
      swap2
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "#utility.yul":14:300   */
    tag_68:
        /* "#utility.yul":72:78   */
      0x00
        /* "#utility.yul":125:127   */
      0x20
        /* "#utility.yul":113:122   */
      dup3
        /* "#utility.yul":104:111   */
      dup5
        /* "#utility.yul":100:123   */
      sub
        /* "#utility.yul":96:128   */
      slt
        /* "#utility.yul":93:145   */
      iszero
      tag_992
      jumpi
        /* "#utility.yul":141:142   */
      0x00
        /* "#utility.yul":138:139   */
      dup1
        /* "#utility.yul":131:143   */
      revert
        /* "#utility.yul":93:145   */
    tag_992:
        /* "#utility.yul":167:190   */
      dup2
      calldataload
      not(sub(shl(0xe0, 0x01), 0x01))
        /* "#utility.yul":219:251   */
      dup2
      and
        /* "#utility.yul":209:252   */
      dup2
      eq
        /* "#utility.yul":199:270   */
      tag_381
      jumpi
        /* "#utility.yul":266:267   */
      0x00
        /* "#utility.yul":263:264   */
      dup1
        /* "#utility.yul":256:268   */
      revert
        /* "#utility.yul":861:1228   */
    tag_982:
        /* "#utility.yul":924:932   */
      0x00
        /* "#utility.yul":934:940   */
      dup1
        /* "#utility.yul":988:991   */
      dup4
        /* "#utility.yul":981:985   */
      0x1f
        /* "#utility.yul":973:979   */
      dup5
        /* "#utility.yul":969:986   */
      add
        /* "#utility.yul":965:992   */
      slt
        /* "#utility.yul":955:1010   */
      tag_998
      jumpi
        /* "#utility.yul":1006:1007   */
      0x00
        /* "#utility.yul":1003:1004   */
      dup1
        /* "#utility.yul":996:1008   */
      revert
        /* "#utility.yul":955:1010   */
    tag_998:
      pop
        /* "#utility.yul":1029:1049   */
      dup2
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":1061:1091   */
      dup2
      gt
        /* "#utility.yul":1058:1108   */
      iszero
      tag_999
      jumpi
        /* "#utility.yul":1104:1105   */
      0x00
        /* "#utility.yul":1101:1102   */
      dup1
        /* "#utility.yul":1094:1106   */
      revert
        /* "#utility.yul":1058:1108   */
    tag_999:
        /* "#utility.yul":1141:1145   */
      0x20
        /* "#utility.yul":1133:1139   */
      dup4
        /* "#utility.yul":1129:1146   */
      add
        /* "#utility.yul":1117:1146   */
      swap2
      pop
        /* "#utility.yul":1201:1204   */
      dup4
        /* "#utility.yul":1194:1198   */
      0x20
        /* "#utility.yul":1184:1190   */
      dup3
        /* "#utility.yul":1181:1182   */
      0x05
        /* "#utility.yul":1177:1191   */
      shl
        /* "#utility.yul":1169:1175   */
      dup6
        /* "#utility.yul":1165:1192   */
      add
        /* "#utility.yul":1161:1199   */
      add
        /* "#utility.yul":1158:1205   */
      gt
        /* "#utility.yul":1155:1222   */
      iszero
      tag_1000
      jumpi
        /* "#utility.yul":1218:1219   */
      0x00
        /* "#utility.yul":1215:1216   */
      dup1
        /* "#utility.yul":1208:1220   */
      revert
        /* "#utility.yul":1155:1222   */
    tag_1000:
        /* "#utility.yul":861:1228   */
      swap3
      pop
      swap3
      swap1
      pop
      jump	// out
        /* "#utility.yul":1233:1406   */
    tag_983:
        /* "#utility.yul":1301:1321   */
      dup1
      calldataload
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":1350:1381   */
      dup2
      and
        /* "#utility.yul":1340:1382   */
      dup2
      eq
        /* "#utility.yul":1330:1400   */
      tag_1002
      jumpi
        /* "#utility.yul":1396:1397   */
      0x00
        /* "#utility.yul":1393:1394   */
      dup1
        /* "#utility.yul":1386:1398   */
      revert
        /* "#utility.yul":1330:1400   */
    tag_1002:
        /* "#utility.yul":1233:1406   */
      swap2
      swap1
      pop
      jump	// out
        /* "#utility.yul":1411:1922   */
    tag_84:
        /* "#utility.yul":1506:1512   */
      0x00
        /* "#utility.yul":1514:1520   */
      dup1
        /* "#utility.yul":1522:1528   */
      0x00
        /* "#utility.yul":1575:1577   */
      0x40
        /* "#utility.yul":1563:1572   */
      dup5
        /* "#utility.yul":1554:1561   */
      dup7
        /* "#utility.yul":1550:1573   */
      sub
        /* "#utility.yul":1546:1578   */
      slt
        /* "#utility.yul":1543:1595   */
      iszero
      tag_1004
      jumpi
        /* "#utility.yul":1591:1592   */
      0x00
        /* "#utility.yul":1588:1589   */
      dup1
        /* "#utility.yul":1581:1593   */
      revert
        /* "#utility.yul":1543:1595   */
    tag_1004:
        /* "#utility.yul":1631:1640   */
      dup4
        /* "#utility.yul":1618:1641   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":1656:1662   */
      dup2
        /* "#utility.yul":1653:1683   */
      gt
        /* "#utility.yul":1650:1700   */
      iszero
      tag_1005
      jumpi
        /* "#utility.yul":1696:1697   */
      0x00
        /* "#utility.yul":1693:1694   */
      dup1
        /* "#utility.yul":1686:1698   */
      revert
        /* "#utility.yul":1650:1700   */
    tag_1005:
        /* "#utility.yul":1735:1805   */
      tag_1006
        /* "#utility.yul":1797:1804   */
      dup7
        /* "#utility.yul":1788:1794   */
      dup3
        /* "#utility.yul":1777:1786   */
      dup8
        /* "#utility.yul":1773:1795   */
      add
        /* "#utility.yul":1735:1805   */
      tag_982
      jump	// in
    tag_1006:
        /* "#utility.yul":1824:1832   */
      swap1
      swap5
      pop
        /* "#utility.yul":1709:1805   */
      swap3
      pop
        /* "#utility.yul":1878:1916   */
      tag_1007
      swap1
      pop
        /* "#utility.yul":1912:1914   */
      0x20
        /* "#utility.yul":1897:1915   */
      dup6
      add
        /* "#utility.yul":1878:1916   */
      tag_983
      jump	// in
    tag_1007:
        /* "#utility.yul":1868:1916   */
      swap1
      pop
        /* "#utility.yul":1411:1922   */
      swap3
      pop
      swap3
      pop
      swap3
      jump	// out
        /* "#utility.yul":1927:2559   */
    tag_87:
        /* "#utility.yul":2098:2100   */
      0x20
        /* "#utility.yul":2150:2171   */
      dup1
      dup3
      mstore
        /* "#utility.yul":2220:2233   */
      dup3
      mload
        /* "#utility.yul":2123:2141   */
      dup3
      dup3
      add
        /* "#utility.yul":2242:2264   */
      dup2
      swap1
      mstore
        /* "#utility.yul":2069:2073   */
      0x00
      swap2
        /* "#utility.yul":2098:2100   */
      swap1
        /* "#utility.yul":2321:2336   */
      dup5
      dup3
      add
      swap1
        /* "#utility.yul":2295:2297   */
      0x40
        /* "#utility.yul":2280:2298   */
      dup6
      add
      swap1
        /* "#utility.yul":2069:2073   */
      dup5
        /* "#utility.yul":2364:2533   */
    tag_1009:
        /* "#utility.yul":2378:2384   */
      dup2
        /* "#utility.yul":2375:2376   */
      dup2
        /* "#utility.yul":2372:2385   */
      lt
        /* "#utility.yul":2364:2533   */
      iszero
      tag_1011
      jumpi
        /* "#utility.yul":2439:2452   */
      dup4
      mload
        /* "#utility.yul":2427:2453   */
      dup4
      mstore
        /* "#utility.yul":2508:2523   */
      swap3
      dup5
      add
      swap3
        /* "#utility.yul":2473:2485   */
      swap2
      dup5
      add
      swap2
        /* "#utility.yul":2400:2401   */
      0x01
        /* "#utility.yul":2393:2402   */
      add
        /* "#utility.yul":2364:2533   */
      jump(tag_1009)
    tag_1011:
      pop
        /* "#utility.yul":2550:2553   */
      swap1
      swap7
        /* "#utility.yul":1927:2559   */
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":2564:2744   */
    tag_96:
        /* "#utility.yul":2623:2629   */
      0x00
        /* "#utility.yul":2676:2678   */
      0x20
        /* "#utility.yul":2664:2673   */
      dup3
        /* "#utility.yul":2655:2662   */
      dup5
        /* "#utility.yul":2651:2674   */
      sub
        /* "#utility.yul":2647:2679   */
      slt
        /* "#utility.yul":2644:2696   */
      iszero
      tag_1013
      jumpi
        /* "#utility.yul":2692:2693   */
      0x00
        /* "#utility.yul":2689:2690   */
      dup1
        /* "#utility.yul":2682:2694   */
      revert
        /* "#utility.yul":2644:2696   */
    tag_1013:
      pop
        /* "#utility.yul":2715:2738   */
      calldataload
      swap2
        /* "#utility.yul":2564:2744   */
      swap1
      pop
      jump	// out
        /* "#utility.yul":2749:3003   */
    tag_110:
        /* "#utility.yul":2817:2823   */
      0x00
        /* "#utility.yul":2825:2831   */
      dup1
        /* "#utility.yul":2878:2880   */
      0x40
        /* "#utility.yul":2866:2875   */
      dup4
        /* "#utility.yul":2857:2864   */
      dup6
        /* "#utility.yul":2853:2876   */
      sub
        /* "#utility.yul":2849:2881   */
      slt
        /* "#utility.yul":2846:2898   */
      iszero
      tag_1015
      jumpi
        /* "#utility.yul":2894:2895   */
      0x00
        /* "#utility.yul":2891:2892   */
      dup1
        /* "#utility.yul":2884:2896   */
      revert
        /* "#utility.yul":2846:2898   */
    tag_1015:
        /* "#utility.yul":2930:2939   */
      dup3
        /* "#utility.yul":2917:2940   */
      calldataload
        /* "#utility.yul":2907:2940   */
      swap2
      pop
        /* "#utility.yul":2959:2997   */
      tag_1016
        /* "#utility.yul":2993:2995   */
      0x20
        /* "#utility.yul":2982:2991   */
      dup5
        /* "#utility.yul":2978:2996   */
      add
        /* "#utility.yul":2959:2997   */
      tag_983
      jump	// in
    tag_1016:
        /* "#utility.yul":2949:2997   */
      swap1
      pop
        /* "#utility.yul":2749:3003   */
      swap3
      pop
      swap3
      swap1
      pop
      jump	// out
        /* "#utility.yul":3008:3855   */
    tag_129:
        /* "#utility.yul":3139:3145   */
      0x00
        /* "#utility.yul":3147:3153   */
      dup1
        /* "#utility.yul":3155:3161   */
      0x00
        /* "#utility.yul":3163:3169   */
      dup1
        /* "#utility.yul":3171:3177   */
      0x00
        /* "#utility.yul":3224:3226   */
      0x60
        /* "#utility.yul":3212:3221   */
      dup7
        /* "#utility.yul":3203:3210   */
      dup9
        /* "#utility.yul":3199:3222   */
      sub
        /* "#utility.yul":3195:3227   */
      slt
        /* "#utility.yul":3192:3244   */
      iszero
      tag_1018
      jumpi
        /* "#utility.yul":3240:3241   */
      0x00
        /* "#utility.yul":3237:3238   */
      dup1
        /* "#utility.yul":3230:3242   */
      revert
        /* "#utility.yul":3192:3244   */
    tag_1018:
        /* "#utility.yul":3280:3289   */
      dup6
        /* "#utility.yul":3267:3290   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":3350:3352   */
      dup1
        /* "#utility.yul":3342:3348   */
      dup3
        /* "#utility.yul":3339:3353   */
      gt
        /* "#utility.yul":3336:3370   */
      iszero
      tag_1019
      jumpi
        /* "#utility.yul":3366:3367   */
      0x00
        /* "#utility.yul":3363:3364   */
      dup1
        /* "#utility.yul":3356:3368   */
      revert
        /* "#utility.yul":3336:3370   */
    tag_1019:
        /* "#utility.yul":3405:3475   */
      tag_1020
        /* "#utility.yul":3467:3474   */
      dup10
        /* "#utility.yul":3458:3464   */
      dup4
        /* "#utility.yul":3447:3456   */
      dup11
        /* "#utility.yul":3443:3465   */
      add
        /* "#utility.yul":3405:3475   */
      tag_982
      jump	// in
    tag_1020:
        /* "#utility.yul":3494:3502   */
      swap1
      swap8
      pop
        /* "#utility.yul":3379:3475   */
      swap6
      pop
        /* "#utility.yul":3582:3584   */
      0x20
        /* "#utility.yul":3567:3585   */
      dup9
      add
        /* "#utility.yul":3554:3586   */
      calldataload
      swap2
      pop
        /* "#utility.yul":3598:3614   */
      dup1
      dup3
      gt
        /* "#utility.yul":3595:3631   */
      iszero
      tag_1021
      jumpi
        /* "#utility.yul":3627:3628   */
      0x00
        /* "#utility.yul":3624:3625   */
      dup1
        /* "#utility.yul":3617:3629   */
      revert
        /* "#utility.yul":3595:3631   */
    tag_1021:
      pop
        /* "#utility.yul":3666:3738   */
      tag_1022
        /* "#utility.yul":3730:3737   */
      dup9
        /* "#utility.yul":3719:3727   */
      dup3
        /* "#utility.yul":3708:3717   */
      dup10
        /* "#utility.yul":3704:3728   */
      add
        /* "#utility.yul":3666:3738   */
      tag_982
      jump	// in
    tag_1022:
        /* "#utility.yul":3757:3765   */
      swap1
      swap5
      pop
        /* "#utility.yul":3640:3738   */
      swap3
      pop
        /* "#utility.yul":3811:3849   */
      tag_1023
      swap1
      pop
        /* "#utility.yul":3845:3847   */
      0x40
        /* "#utility.yul":3830:3848   */
      dup8
      add
        /* "#utility.yul":3811:3849   */
      tag_983
      jump	// in
    tag_1023:
        /* "#utility.yul":3801:3849   */
      swap1
      pop
        /* "#utility.yul":3008:3855   */
      swap3
      swap6
      pop
      swap3
      swap6
      swap1
      swap4
      pop
      jump	// out
        /* "#utility.yul":3860:4433   */
    tag_133:
        /* "#utility.yul":3964:3970   */
      0x00
        /* "#utility.yul":3972:3978   */
      dup1
        /* "#utility.yul":3980:3986   */
      0x00
        /* "#utility.yul":3988:3994   */
      dup1
        /* "#utility.yul":4041:4043   */
      0x60
        /* "#utility.yul":4029:4038   */
      dup6
        /* "#utility.yul":4020:4027   */
      dup8
        /* "#utility.yul":4016:4039   */
      sub
        /* "#utility.yul":4012:4044   */
      slt
        /* "#utility.yul":4009:4061   */
      iszero
      tag_1025
      jumpi
        /* "#utility.yul":4057:4058   */
      0x00
        /* "#utility.yul":4054:4055   */
      dup1
        /* "#utility.yul":4047:4059   */
      revert
        /* "#utility.yul":4009:4061   */
    tag_1025:
        /* "#utility.yul":4097:4106   */
      dup5
        /* "#utility.yul":4084:4107   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":4122:4128   */
      dup2
        /* "#utility.yul":4119:4149   */
      gt
        /* "#utility.yul":4116:4166   */
      iszero
      tag_1026
      jumpi
        /* "#utility.yul":4162:4163   */
      0x00
        /* "#utility.yul":4159:4160   */
      dup1
        /* "#utility.yul":4152:4164   */
      revert
        /* "#utility.yul":4116:4166   */
    tag_1026:
        /* "#utility.yul":4201:4271   */
      tag_1027
        /* "#utility.yul":4263:4270   */
      dup8
        /* "#utility.yul":4254:4260   */
      dup3
        /* "#utility.yul":4243:4252   */
      dup9
        /* "#utility.yul":4239:4261   */
      add
        /* "#utility.yul":4201:4271   */
      tag_982
      jump	// in
    tag_1027:
        /* "#utility.yul":4290:4298   */
      swap1
      swap9
        /* "#utility.yul":4175:4271   */
      swap1
      swap8
      pop
        /* "#utility.yul":4372:4374   */
      0x20
        /* "#utility.yul":4357:4375   */
      dup8
      add
        /* "#utility.yul":4344:4376   */
      calldataload
      swap7
        /* "#utility.yul":4423:4425   */
      0x40
        /* "#utility.yul":4408:4426   */
      add
        /* "#utility.yul":4395:4427   */
      calldataload
      swap6
      pop
        /* "#utility.yul":3860:4433   */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":4438:5111   */
    tag_138:
        /* "#utility.yul":4573:4579   */
      0x00
        /* "#utility.yul":4581:4587   */
      dup1
        /* "#utility.yul":4589:4595   */
      0x00
        /* "#utility.yul":4597:4603   */
      dup1
        /* "#utility.yul":4641:4650   */
      dup5
        /* "#utility.yul":4632:4639   */
      dup7
        /* "#utility.yul":4628:4651   */
      sub
        /* "#utility.yul":4671:4674   */
      0xe0
        /* "#utility.yul":4667:4669   */
      dup2
        /* "#utility.yul":4663:4675   */
      slt
        /* "#utility.yul":4660:4692   */
      iszero
      tag_1029
      jumpi
        /* "#utility.yul":4688:4689   */
      0x00
        /* "#utility.yul":4685:4686   */
      dup1
        /* "#utility.yul":4678:4690   */
      revert
        /* "#utility.yul":4660:4692   */
    tag_1029:
        /* "#utility.yul":4728:4737   */
      dup6
        /* "#utility.yul":4715:4738   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":4753:4759   */
      dup2
        /* "#utility.yul":4750:4780   */
      gt
        /* "#utility.yul":4747:4797   */
      iszero
      tag_1030
      jumpi
        /* "#utility.yul":4793:4794   */
      0x00
        /* "#utility.yul":4790:4791   */
      dup1
        /* "#utility.yul":4783:4795   */
      revert
        /* "#utility.yul":4747:4797   */
    tag_1030:
        /* "#utility.yul":4832:4902   */
      tag_1031
        /* "#utility.yul":4894:4901   */
      dup9
        /* "#utility.yul":4885:4891   */
      dup3
        /* "#utility.yul":4874:4883   */
      dup10
        /* "#utility.yul":4870:4892   */
      add
        /* "#utility.yul":4832:4902   */
      tag_982
      jump	// in
    tag_1031:
        /* "#utility.yul":4921:4929   */
      swap1
      swap7
      pop
        /* "#utility.yul":4806:4902   */
      swap5
      pop
        /* "#utility.yul":4975:5013   */
      tag_1032
      swap1
      pop
        /* "#utility.yul":5009:5011   */
      0x20
        /* "#utility.yul":4994:5012   */
      dup8
      add
        /* "#utility.yul":4975:5013   */
      tag_983
      jump	// in
    tag_1032:
        /* "#utility.yul":4965:5013   */
      swap3
      pop
        /* "#utility.yul":5047:5050   */
      0xa0
      not(0x3f)
        /* "#utility.yul":5029:5045   */
      dup3
      add
        /* "#utility.yul":5025:5051   */
      slt
        /* "#utility.yul":5022:5068   */
      iszero
      tag_1033
      jumpi
        /* "#utility.yul":5064:5065   */
      0x00
        /* "#utility.yul":5061:5062   */
      dup1
        /* "#utility.yul":5054:5066   */
      revert
        /* "#utility.yul":5022:5068   */
    tag_1033:
      pop
        /* "#utility.yul":4438:5111   */
      swap3
      swap6
      swap2
      swap5
      pop
      swap3
        /* "#utility.yul":5102:5104   */
      0x40
        /* "#utility.yul":5087:5105   */
      add
      swap2
      pop
        /* "#utility.yul":4438:5111   */
      jump	// out
        /* "#utility.yul":5116:5302   */
    tag_143:
        /* "#utility.yul":5175:5181   */
      0x00
        /* "#utility.yul":5228:5230   */
      0x20
        /* "#utility.yul":5216:5225   */
      dup3
        /* "#utility.yul":5207:5214   */
      dup5
        /* "#utility.yul":5203:5226   */
      sub
        /* "#utility.yul":5199:5231   */
      slt
        /* "#utility.yul":5196:5248   */
      iszero
      tag_1035
      jumpi
        /* "#utility.yul":5244:5245   */
      0x00
        /* "#utility.yul":5241:5242   */
      dup1
        /* "#utility.yul":5234:5246   */
      revert
        /* "#utility.yul":5196:5248   */
    tag_1035:
        /* "#utility.yul":5267:5296   */
      tag_381
        /* "#utility.yul":5286:5295   */
      dup3
        /* "#utility.yul":5267:5296   */
      tag_983
      jump	// in
        /* "#utility.yul":5307:5555   */
    tag_151:
        /* "#utility.yul":5375:5381   */
      0x00
        /* "#utility.yul":5383:5389   */
      dup1
        /* "#utility.yul":5436:5438   */
      0x40
        /* "#utility.yul":5424:5433   */
      dup4
        /* "#utility.yul":5415:5422   */
      dup6
        /* "#utility.yul":5411:5434   */
      sub
        /* "#utility.yul":5407:5439   */
      slt
        /* "#utility.yul":5404:5456   */
      iszero
      tag_1038
      jumpi
        /* "#utility.yul":5452:5453   */
      0x00
        /* "#utility.yul":5449:5450   */
      dup1
        /* "#utility.yul":5442:5454   */
      revert
        /* "#utility.yul":5404:5456   */
    tag_1038:
      pop
      pop
        /* "#utility.yul":5475:5498   */
      dup1
      calldataload
      swap3
        /* "#utility.yul":5545:5547   */
      0x20
        /* "#utility.yul":5530:5548   */
      swap1
      swap2
      add
        /* "#utility.yul":5517:5549   */
      calldataload
      swap2
      pop
        /* "#utility.yul":5307:5555   */
      jump	// out
        /* "#utility.yul":5768:5886   */
    tag_984:
        /* "#utility.yul":5854:5859   */
      dup1
        /* "#utility.yul":5847:5860   */
      iszero
        /* "#utility.yul":5840:5861   */
      iszero
        /* "#utility.yul":5833:5838   */
      dup2
        /* "#utility.yul":5830:5862   */
      eq
        /* "#utility.yul":5820:5880   */
      tag_481
      jumpi
        /* "#utility.yul":5876:5877   */
      0x00
        /* "#utility.yul":5873:5874   */
      dup1
        /* "#utility.yul":5866:5878   */
      revert
        /* "#utility.yul":5891:6268   */
    tag_161:
        /* "#utility.yul":5965:5971   */
      0x00
        /* "#utility.yul":5973:5979   */
      dup1
        /* "#utility.yul":5981:5987   */
      0x00
        /* "#utility.yul":6034:6036   */
      0x60
        /* "#utility.yul":6022:6031   */
      dup5
        /* "#utility.yul":6013:6020   */
      dup7
        /* "#utility.yul":6009:6032   */
      sub
        /* "#utility.yul":6005:6037   */
      slt
        /* "#utility.yul":6002:6054   */
      iszero
      tag_1043
      jumpi
        /* "#utility.yul":6050:6051   */
      0x00
        /* "#utility.yul":6047:6048   */
      dup1
        /* "#utility.yul":6040:6052   */
      revert
        /* "#utility.yul":6002:6054   */
    tag_1043:
        /* "#utility.yul":6089:6098   */
      dup4
        /* "#utility.yul":6076:6099   */
      calldataload
        /* "#utility.yul":6108:6136   */
      tag_1044
        /* "#utility.yul":6130:6135   */
      dup2
        /* "#utility.yul":6108:6136   */
      tag_984
      jump	// in
    tag_1044:
        /* "#utility.yul":6155:6160   */
      swap6
        /* "#utility.yul":6207:6209   */
      0x20
        /* "#utility.yul":6192:6210   */
      dup6
      add
        /* "#utility.yul":6179:6211   */
      calldataload
      swap6
      pop
        /* "#utility.yul":6258:6260   */
      0x40
        /* "#utility.yul":6243:6261   */
      swap1
      swap5
      add
        /* "#utility.yul":6230:6262   */
      calldataload
      swap4
        /* "#utility.yul":5891:6268   */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":6273:6778   */
    tag_174:
        /* "#utility.yul":6368:6374   */
      0x00
        /* "#utility.yul":6376:6382   */
      dup1
        /* "#utility.yul":6384:6390   */
      0x00
        /* "#utility.yul":6437:6439   */
      0x40
        /* "#utility.yul":6425:6434   */
      dup5
        /* "#utility.yul":6416:6423   */
      dup7
        /* "#utility.yul":6412:6435   */
      sub
        /* "#utility.yul":6408:6440   */
      slt
        /* "#utility.yul":6405:6457   */
      iszero
      tag_1046
      jumpi
        /* "#utility.yul":6453:6454   */
      0x00
        /* "#utility.yul":6450:6451   */
      dup1
        /* "#utility.yul":6443:6455   */
      revert
        /* "#utility.yul":6405:6457   */
    tag_1046:
        /* "#utility.yul":6493:6502   */
      dup4
        /* "#utility.yul":6480:6503   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":6518:6524   */
      dup2
        /* "#utility.yul":6515:6545   */
      gt
        /* "#utility.yul":6512:6562   */
      iszero
      tag_1047
      jumpi
        /* "#utility.yul":6558:6559   */
      0x00
        /* "#utility.yul":6555:6556   */
      dup1
        /* "#utility.yul":6548:6560   */
      revert
        /* "#utility.yul":6512:6562   */
    tag_1047:
        /* "#utility.yul":6597:6667   */
      tag_1048
        /* "#utility.yul":6659:6666   */
      dup7
        /* "#utility.yul":6650:6656   */
      dup3
        /* "#utility.yul":6639:6648   */
      dup8
        /* "#utility.yul":6635:6657   */
      add
        /* "#utility.yul":6597:6667   */
      tag_982
      jump	// in
    tag_1048:
        /* "#utility.yul":6686:6694   */
      swap1
      swap8
        /* "#utility.yul":6571:6667   */
      swap1
      swap7
      pop
        /* "#utility.yul":6768:6770   */
      0x20
        /* "#utility.yul":6753:6771   */
      swap6
      swap1
      swap6
      add
        /* "#utility.yul":6740:6772   */
      calldataload
      swap5
        /* "#utility.yul":6273:6778   */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":7221:7658   */
    tag_191:
        /* "#utility.yul":7307:7313   */
      0x00
        /* "#utility.yul":7315:7321   */
      dup1
        /* "#utility.yul":7368:7370   */
      0x20
        /* "#utility.yul":7356:7365   */
      dup4
        /* "#utility.yul":7347:7354   */
      dup6
        /* "#utility.yul":7343:7366   */
      sub
        /* "#utility.yul":7339:7371   */
      slt
        /* "#utility.yul":7336:7388   */
      iszero
      tag_1053
      jumpi
        /* "#utility.yul":7384:7385   */
      0x00
        /* "#utility.yul":7381:7382   */
      dup1
        /* "#utility.yul":7374:7386   */
      revert
        /* "#utility.yul":7336:7388   */
    tag_1053:
        /* "#utility.yul":7424:7433   */
      dup3
        /* "#utility.yul":7411:7434   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":7449:7455   */
      dup2
        /* "#utility.yul":7446:7476   */
      gt
        /* "#utility.yul":7443:7493   */
      iszero
      tag_1054
      jumpi
        /* "#utility.yul":7489:7490   */
      0x00
        /* "#utility.yul":7486:7487   */
      dup1
        /* "#utility.yul":7479:7491   */
      revert
        /* "#utility.yul":7443:7493   */
    tag_1054:
        /* "#utility.yul":7528:7598   */
      tag_1055
        /* "#utility.yul":7590:7597   */
      dup6
        /* "#utility.yul":7581:7587   */
      dup3
        /* "#utility.yul":7570:7579   */
      dup7
        /* "#utility.yul":7566:7588   */
      add
        /* "#utility.yul":7528:7598   */
      tag_982
      jump	// in
    tag_1055:
        /* "#utility.yul":7617:7625   */
      swap1
      swap7
        /* "#utility.yul":7502:7598   */
      swap1
      swap6
      pop
        /* "#utility.yul":7221:7658   */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":7663:8836   */
    tag_194:
        /* "#utility.yul":7916:7918   */
      0x20
        /* "#utility.yul":7968:7989   */
      dup1
      dup3
      mstore
        /* "#utility.yul":8038:8051   */
      dup3
      mload
        /* "#utility.yul":7941:7959   */
      dup3
      dup3
      add
        /* "#utility.yul":8060:8082   */
      dup2
      swap1
      mstore
        /* "#utility.yul":7887:7891   */
      0x00
      swap2
        /* "#utility.yul":7916:7918   */
      swap1
        /* "#utility.yul":8101:8103   */
      0x40
      swap1
        /* "#utility.yul":8119:8137   */
      dup2
      dup6
      add
      swap1
        /* "#utility.yul":8160:8175   */
      dup7
      dup5
      add
        /* "#utility.yul":7887:7891   */
      dup6
        /* "#utility.yul":8203:8810   */
    tag_1057:
        /* "#utility.yul":8217:8223   */
      dup3
        /* "#utility.yul":8214:8215   */
      dup2
        /* "#utility.yul":8211:8224   */
      lt
        /* "#utility.yul":8203:8810   */
      iszero
      tag_1059
      jumpi
        /* "#utility.yul":8276:8289   */
      dup2
      mload
        /* "#utility.yul":8314:8323   */
      dup1
      mload
        /* "#utility.yul":8302:8324   */
      dup6
      mstore
        /* "#utility.yul":8364:8375   */
      dup7
      dup2
      add
        /* "#utility.yul":8358:8376   */
      mload
        /* "#utility.yul":8344:8356   */
      dup8
      dup7
      add
        /* "#utility.yul":8337:8377   */
      mstore
        /* "#utility.yul":8421:8432   */
      dup6
      dup2
      add
        /* "#utility.yul":8415:8433   */
      mload
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":8411:8455   */
      and
        /* "#utility.yul":8397:8409   */
      dup7
      dup7
      add
        /* "#utility.yul":8390:8456   */
      mstore
        /* "#utility.yul":8479:8483   */
      0x60
        /* "#utility.yul":8523:8534   */
      dup1
      dup3
      add
        /* "#utility.yul":8517:8535   */
      mload
        /* "#utility.yul":8503:8515   */
      swap1
      dup7
      add
        /* "#utility.yul":8496:8536   */
      mstore
        /* "#utility.yul":8559:8563   */
      0x80
        /* "#utility.yul":8617:8628   */
      dup1
      dup3
      add
        /* "#utility.yul":8611:8629   */
      mload
        /* "#utility.yul":8604:8630   */
      iszero
        /* "#utility.yul":8597:8631   */
      iszero
        /* "#utility.yul":8583:8595   */
      swap1
      dup7
      add
        /* "#utility.yul":8576:8632   */
      mstore
        /* "#utility.yul":8443:8446   */
      0xa0
        /* "#utility.yul":8713:8724   */
      swap1
      dup2
      add
        /* "#utility.yul":8707:8725   */
      mload
        /* "#utility.yul":8700:8726   */
      iszero
        /* "#utility.yul":8693:8727   */
      iszero
        /* "#utility.yul":8679:8691   */
      swap1
      dup6
      add
        /* "#utility.yul":8672:8728   */
      mstore
        /* "#utility.yul":8757:8761   */
      0xc0
        /* "#utility.yul":8748:8762   */
      swap1
      swap4
      add
      swap3
        /* "#utility.yul":8785:8800   */
      swap1
      dup6
      add
      swap1
        /* "#utility.yul":8452:8453   */
      0x01
        /* "#utility.yul":8232:8241   */
      add
        /* "#utility.yul":8203:8810   */
      jump(tag_1057)
    tag_1059:
      pop
        /* "#utility.yul":8827:8830   */
      swap2
      swap8
        /* "#utility.yul":7663:8836   */
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":8841:9614   */
    tag_203:
        /* "#utility.yul":8963:8969   */
      0x00
        /* "#utility.yul":8971:8977   */
      dup1
        /* "#utility.yul":8979:8985   */
      0x00
        /* "#utility.yul":8987:8993   */
      dup1
        /* "#utility.yul":9040:9042   */
      0x40
        /* "#utility.yul":9028:9037   */
      dup6
        /* "#utility.yul":9019:9026   */
      dup8
        /* "#utility.yul":9015:9038   */
      sub
        /* "#utility.yul":9011:9043   */
      slt
        /* "#utility.yul":9008:9060   */
      iszero
      tag_1061
      jumpi
        /* "#utility.yul":9056:9057   */
      0x00
        /* "#utility.yul":9053:9054   */
      dup1
        /* "#utility.yul":9046:9058   */
      revert
        /* "#utility.yul":9008:9060   */
    tag_1061:
        /* "#utility.yul":9096:9105   */
      dup5
        /* "#utility.yul":9083:9106   */
      calldataload
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":9166:9168   */
      dup1
        /* "#utility.yul":9158:9164   */
      dup3
        /* "#utility.yul":9155:9169   */
      gt
        /* "#utility.yul":9152:9186   */
      iszero
      tag_1062
      jumpi
        /* "#utility.yul":9182:9183   */
      0x00
        /* "#utility.yul":9179:9180   */
      dup1
        /* "#utility.yul":9172:9184   */
      revert
        /* "#utility.yul":9152:9186   */
    tag_1062:
        /* "#utility.yul":9221:9291   */
      tag_1063
        /* "#utility.yul":9283:9290   */
      dup9
        /* "#utility.yul":9274:9280   */
      dup4
        /* "#utility.yul":9263:9272   */
      dup10
        /* "#utility.yul":9259:9281   */
      add
        /* "#utility.yul":9221:9291   */
      tag_982
      jump	// in
    tag_1063:
        /* "#utility.yul":9310:9318   */
      swap1
      swap7
      pop
        /* "#utility.yul":9195:9291   */
      swap5
      pop
        /* "#utility.yul":9398:9400   */
      0x20
        /* "#utility.yul":9383:9401   */
      dup8
      add
        /* "#utility.yul":9370:9402   */
      calldataload
      swap2
      pop
        /* "#utility.yul":9414:9430   */
      dup1
      dup3
      gt
        /* "#utility.yul":9411:9447   */
      iszero
      tag_1064
      jumpi
        /* "#utility.yul":9443:9444   */
      0x00
        /* "#utility.yul":9440:9441   */
      dup1
        /* "#utility.yul":9433:9445   */
      revert
        /* "#utility.yul":9411:9447   */
    tag_1064:
      pop
        /* "#utility.yul":9482:9554   */
      tag_1065
        /* "#utility.yul":9546:9553   */
      dup8
        /* "#utility.yul":9535:9543   */
      dup3
        /* "#utility.yul":9524:9533   */
      dup9
        /* "#utility.yul":9520:9544   */
      add
        /* "#utility.yul":9482:9554   */
      tag_982
      jump	// in
    tag_1065:
        /* "#utility.yul":8841:9614   */
      swap6
      swap9
      swap5
      swap8
      pop
        /* "#utility.yul":9573:9581   */
      swap6
      pop
      pop
      pop
      pop
        /* "#utility.yul":8841:9614   */
      jump	// out
        /* "#utility.yul":9619:9807   */
    tag_985:
        /* "#utility.yul":9687:9707   */
      dup1
      calldataload
      sub(shl(0x80, 0x01), 0x01)
        /* "#utility.yul":9736:9782   */
      dup2
      and
        /* "#utility.yul":9726:9783   */
      dup2
      eq
        /* "#utility.yul":9716:9801   */
      tag_1002
      jumpi
        /* "#utility.yul":9797:9798   */
      0x00
        /* "#utility.yul":9794:9795   */
      dup1
        /* "#utility.yul":9787:9799   */
      revert
        /* "#utility.yul":9812:10209   */
    tag_212:
        /* "#utility.yul":9898:9904   */
      0x00
        /* "#utility.yul":9906:9912   */
      dup1
        /* "#utility.yul":9914:9920   */
      0x00
        /* "#utility.yul":9922:9928   */
      dup1
        /* "#utility.yul":9975:9978   */
      0x80
        /* "#utility.yul":9963:9972   */
      dup6
        /* "#utility.yul":9954:9961   */
      dup8
        /* "#utility.yul":9950:9973   */
      sub
        /* "#utility.yul":9946:9979   */
      slt
        /* "#utility.yul":9943:9996   */
      iszero
      tag_1069
      jumpi
        /* "#utility.yul":9992:9993   */
      0x00
        /* "#utility.yul":9989:9990   */
      dup1
        /* "#utility.yul":9982:9994   */
      revert
        /* "#utility.yul":9943:9996   */
    tag_1069:
        /* "#utility.yul":10028:10037   */
      dup5
        /* "#utility.yul":10015:10038   */
      calldataload
        /* "#utility.yul":10005:10038   */
      swap4
      pop
        /* "#utility.yul":10057:10095   */
      tag_1070
        /* "#utility.yul":10091:10093   */
      0x20
        /* "#utility.yul":10080:10089   */
      dup7
        /* "#utility.yul":10076:10094   */
      add
        /* "#utility.yul":10057:10095   */
      tag_985
      jump	// in
    tag_1070:
        /* "#utility.yul":10047:10095   */
      swap3
      pop
        /* "#utility.yul":10114:10152   */
      tag_1071
        /* "#utility.yul":10148:10150   */
      0x40
        /* "#utility.yul":10137:10146   */
      dup7
        /* "#utility.yul":10133:10151   */
      add
        /* "#utility.yul":10114:10152   */
      tag_985
      jump	// in
    tag_1071:
        /* "#utility.yul":9812:10209   */
      swap4
      swap7
      swap3
      swap6
      pop
        /* "#utility.yul":10104:10152   */
      swap3
      swap4
        /* "#utility.yul":10199:10201   */
      0x60
        /* "#utility.yul":10184:10202   */
      add
        /* "#utility.yul":10171:10203   */
      calldataload
      swap3
      pop
      pop
        /* "#utility.yul":9812:10209   */
      jump	// out
        /* "#utility.yul":11439:11566   */
    tag_282:
        /* "#utility.yul":11500:11510   */
      0x4e487b71
        /* "#utility.yul":11495:11498   */
      0xe0
        /* "#utility.yul":11491:11511   */
      shl
        /* "#utility.yul":11488:11489   */
      0x00
        /* "#utility.yul":11481:11512   */
      mstore
        /* "#utility.yul":11531:11535   */
      0x41
        /* "#utility.yul":11528:11529   */
      0x04
        /* "#utility.yul":11521:11536   */
      mstore
        /* "#utility.yul":11555:11559   */
      0x24
        /* "#utility.yul":11552:11553   */
      0x00
        /* "#utility.yul":11545:11560   */
      revert
        /* "#utility.yul":11571:11824   */
    tag_986:
        /* "#utility.yul":11643:11645   */
      0x40
        /* "#utility.yul":11637:11646   */
      mload
        /* "#utility.yul":11685:11689   */
      0x80
        /* "#utility.yul":11673:11690   */
      dup2
      add
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":11705:11739   */
      dup2
      gt
        /* "#utility.yul":11741:11763   */
      dup3
      dup3
      lt
        /* "#utility.yul":11702:11764   */
      or
        /* "#utility.yul":11699:11787   */
      iszero
      tag_1078
      jumpi
        /* "#utility.yul":11767:11785   */
      tag_1078
      tag_282
      jump	// in
    tag_1078:
        /* "#utility.yul":11803:11805   */
      0x40
        /* "#utility.yul":11796:11818   */
      mstore
        /* "#utility.yul":11571:11824   */
      swap1
      jump	// out
        /* "#utility.yul":11829:12077   */
    tag_987:
        /* "#utility.yul":11896:11898   */
      0x40
        /* "#utility.yul":11890:11899   */
      mload
        /* "#utility.yul":11938:11942   */
      0x0480
        /* "#utility.yul":11926:11943   */
      dup2
      add
      sub(shl(0x40, 0x01), 0x01)
        /* "#utility.yul":11958:11992   */
      dup2
      gt
        /* "#utility.yul":11994:12016   */
      dup3
      dup3
      lt
        /* "#utility.yul":11955:12017   */
      or
        /* "#utility.yul":11952:12040   */
      iszero
      tag_1078
      jumpi
        /* "#utility.yul":12020:12038   */
      tag_1078
      tag_282
      jump	// in
        /* "#utility.yul":12082:13323   */
    tag_248:
        /* "#utility.yul":12209:12215   */
      0x00
        /* "#utility.yul":12217:12223   */
      dup1
        /* "#utility.yul":12225:12231   */
      0x00
        /* "#utility.yul":12233:12239   */
      dup1
        /* "#utility.yul":12277:12286   */
      dup5
        /* "#utility.yul":12268:12275   */
      dup7
        /* "#utility.yul":12264:12287   */
      sub
        /* "#utility.yul":12307:12311   */
      0x0540
        /* "#utility.yul":12303:12305   */
      dup2
        /* "#utility.yul":12299:12312   */
      slt
        /* "#utility.yul":12296:12329   */
      iszero
      tag_1083
      jumpi
        /* "#utility.yul":12325:12326   */
      0x00
        /* "#utility.yul":12322:12323   */
      dup1
        /* "#utility.yul":12315:12327   */
      revert
        /* "#utility.yul":12296:12329   */
    tag_1083:
        /* "#utility.yul":12348:12371   */
      dup6
      calldataload
      swap5
      pop
        /* "#utility.yul":12390:12392   */
      0x20
        /* "#utility.yul":12424:12442   */
      dup1
      dup8
      add
        /* "#utility.yul":12411:12443   */
      calldataload
      swap5
      pop
        /* "#utility.yul":12490:12492   */
      0x40
        /* "#utility.yul":12475:12493   */
      dup8
      add
        /* "#utility.yul":12462:12494   */
      calldataload
      swap4
      pop
        /* "#utility.yul":12528:12534   */
      0x04e0
      not(0x5f)
        /* "#utility.yul":12510:12526   */
      dup4
      add
        /* "#utility.yul":12506:12535   */
      slt
        /* "#utility.yul":12503:12552   */
      iszero
      tag_1084
      jumpi
        /* "#utility.yul":12548:12549   */
      0x00
        /* "#utility.yul":12545:12546   */
      dup1
        /* "#utility.yul":12538:12550   */
      revert
        /* "#utility.yul":12503:12552   */
    tag_1084:
        /* "#utility.yul":12574:12596   */
      tag_1085
      tag_986
      jump	// in
    tag_1085:
        /* "#utility.yul":12561:12596   */
      swap2
      pop
        /* "#utility.yul":12647:12649   */
      0x60
        /* "#utility.yul":12636:12645   */
      dup8
        /* "#utility.yul":12632:12650   */
      add
        /* "#utility.yul":12619:12651   */
      calldataload
        /* "#utility.yul":12612:12617   */
      dup3
        /* "#utility.yul":12605:12652   */
      mstore
        /* "#utility.yul":12704:12708   */
      0x80
        /* "#utility.yul":12693:12702   */
      dup8
        /* "#utility.yul":12689:12709   */
      add
        /* "#utility.yul":12676:12710   */
      calldataload
        /* "#utility.yul":12719:12749   */
      tag_1086
        /* "#utility.yul":12741:12748   */
      dup2
        /* "#utility.yul":12719:12749   */
      tag_984
      jump	// in
    tag_1086:
        /* "#utility.yul":12765:12779   */
      dup3
      dup3
      add
        /* "#utility.yul":12758:12789   */
      mstore
        /* "#utility.yul":12827:12830   */
      0xbf
        /* "#utility.yul":12812:12831   */
      dup8
      add
        /* "#utility.yul":12808:12841   */
      dup9
      sgt
        /* "#utility.yul":12798:12859   */
      tag_1087
      jumpi
        /* "#utility.yul":12855:12856   */
      0x00
        /* "#utility.yul":12852:12853   */
      dup1
        /* "#utility.yul":12845:12857   */
      revert
        /* "#utility.yul":12798:12859   */
    tag_1087:
        /* "#utility.yul":12879:12896   */
      tag_1088
      tag_987
      jump	// in
    tag_1088:
        /* "#utility.yul":12918:12921   */
      dup1
        /* "#utility.yul":12959:12963   */
      0x0520
        /* "#utility.yul":12948:12957   */
      dup10
        /* "#utility.yul":12944:12964   */
      add
        /* "#utility.yul":12987:12994   */
      dup11
        /* "#utility.yul":12979:12985   */
      dup2
        /* "#utility.yul":12976:12995   */
      gt
        /* "#utility.yul":12973:13012   */
      iszero
      tag_1089
      jumpi
        /* "#utility.yul":13008:13009   */
      0x00
        /* "#utility.yul":13005:13006   */
      dup1
        /* "#utility.yul":12998:13010   */
      revert
        /* "#utility.yul":12973:13012   */
    tag_1089:
        /* "#utility.yul":13047:13050   */
      0xa0
        /* "#utility.yul":13036:13045   */
      dup11
        /* "#utility.yul":13032:13051   */
      add
        /* "#utility.yul":13060:13202   */
    tag_1090:
        /* "#utility.yul":13076:13082   */
      dup2
        /* "#utility.yul":13071:13074   */
      dup2
        /* "#utility.yul":13068:13083   */
      lt
        /* "#utility.yul":13060:13202   */
      iszero
      tag_1092
      jumpi
        /* "#utility.yul":13142:13159   */
      dup1
      calldataload
        /* "#utility.yul":13130:13160   */
      dup5
      mstore
        /* "#utility.yul":13180:13192   */
      swap3
      dup5
      add
      swap3
        /* "#utility.yul":13093:13105   */
      dup5
      add
        /* "#utility.yul":13060:13202   */
      jump(tag_1090)
    tag_1092:
      pop
        /* "#utility.yul":13229:13231   */
      0x40
        /* "#utility.yul":13218:13232   */
      dup6
      add
        /* "#utility.yul":13211:13240   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":13272:13292   */
      calldataload
        /* "#utility.yul":13267:13269   */
      0x60
        /* "#utility.yul":13256:13270   */
      dup5
      add
        /* "#utility.yul":13249:13293   */
      mstore
      pop
        /* "#utility.yul":12082:13323   */
      swap5
      swap8
      swap4
      swap7
      pop
      swap2
      swap5
      pop
        /* "#utility.yul":13222:13227   */
      swap1
      swap3
      pop
      pop
        /* "#utility.yul":12082:13323   */
      jump	// out
        /* "#utility.yul":13328:14101   */
    tag_251:
        /* "#utility.yul":13576:13589   */
      dup2
      mload
        /* "#utility.yul":13558:13590   */
      dup2
      mstore
        /* "#utility.yul":13609:13613   */
      0x20
        /* "#utility.yul":13669:13684   */
      dup1
      dup4
      add
        /* "#utility.yul":13663:13685   */
      mload
        /* "#utility.yul":13656:13686   */
      iszero
        /* "#utility.yul":13649:13687   */
      iszero
        /* "#utility.yul":13629:13647   */
      dup2
      dup4
      add
        /* "#utility.yul":13622:13688   */
      mstore
        /* "#utility.yul":13735:13739   */
      0x40
        /* "#utility.yul":13723:13740   */
      dup1
      dup5
      add
        /* "#utility.yul":13717:13741   */
      mload
        /* "#utility.yul":13544:13548   */
      0x04e0
        /* "#utility.yul":13529:13549   */
      dup5
      add
      swap3
        /* "#utility.yul":13609:13613   */
      swap2
        /* "#utility.yul":13761:13781   */
      dup5
      add
        /* "#utility.yul":13502:13506   */
      0x00
        /* "#utility.yul":13863:14030   */
    tag_1094:
        /* "#utility.yul":13877:13881   */
      0x24
        /* "#utility.yul":13874:13875   */
      dup2
        /* "#utility.yul":13871:13882   */
      lt
        /* "#utility.yul":13863:14030   */
      iszero
      tag_1096
      jumpi
        /* "#utility.yul":13936:13949   */
      dup3
      mload
        /* "#utility.yul":13924:13950   */
      dup3
      mstore
        /* "#utility.yul":14005:14020   */
      swap2
      dup4
      add
      swap2
        /* "#utility.yul":13970:13982   */
      swap1
      dup4
      add
      swap1
        /* "#utility.yul":13897:13898   */
      0x01
        /* "#utility.yul":13890:13899   */
      add
        /* "#utility.yul":13863:14030   */
      jump(tag_1094)
    tag_1096:
        /* "#utility.yul":13867:13870   */
      pop
      pop
      pop
      pop
        /* "#utility.yul":14088:14092   */
      0x60
        /* "#utility.yul":14080:14086   */
      dup4
        /* "#utility.yul":14076:14093   */
      add
        /* "#utility.yul":14070:14094   */
      mload
        /* "#utility.yul":14061:14067   */
      0x04c0
        /* "#utility.yul":14050:14059   */
      dup4
        /* "#utility.yul":14046:14068   */
      add
        /* "#utility.yul":14039:14095   */
      mstore
        /* "#utility.yul":13328:14101   */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "#utility.yul":14365:14492   */
    tag_290:
        /* "#utility.yul":14426:14436   */
      0x4e487b71
        /* "#utility.yul":14421:14424   */
      0xe0
        /* "#utility.yul":14417:14437   */
      shl
        /* "#utility.yul":14414:14415   */
      0x00
        /* "#utility.yul":14407:14438   */
      mstore
        /* "#utility.yul":14457:14461   */
      0x32
        /* "#utility.yul":14454:14455   */
      0x04
        /* "#utility.yul":14447:14462   */
      mstore
        /* "#utility.yul":14481:14485   */
      0x24
        /* "#utility.yul":14478:14479   */
      0x00
        /* "#utility.yul":14471:14486   */
      revert
        /* "#utility.yul":14497:14624   */
    tag_988:
        /* "#utility.yul":14558:14568   */
      0x4e487b71
        /* "#utility.yul":14553:14556   */
      0xe0
        /* "#utility.yul":14549:14569   */
      shl
        /* "#utility.yul":14546:14547   */
      0x00
        /* "#utility.yul":14539:14570   */
      mstore
        /* "#utility.yul":14589:14593   */
      0x11
        /* "#utility.yul":14586:14587   */
      0x04
        /* "#utility.yul":14579:14594   */
      mstore
        /* "#utility.yul":14613:14617   */
      0x24
        /* "#utility.yul":14610:14611   */
      0x00
        /* "#utility.yul":14603:14618   */
      revert
        /* "#utility.yul":14629:14764   */
    tag_295:
        /* "#utility.yul":14668:14671   */
      0x00
      not(0x00)
        /* "#utility.yul":14689:14706   */
      dup3
      eq
        /* "#utility.yul":14686:14729   */
      iszero
      tag_1104
      jumpi
        /* "#utility.yul":14709:14727   */
      tag_1104
      tag_988
      jump	// in
    tag_1104:
      pop
        /* "#utility.yul":14756:14757   */
      0x01
        /* "#utility.yul":14745:14758   */
      add
      swap1
        /* "#utility.yul":14629:14764   */
      jump	// out
        /* "#utility.yul":15185:15454   */
    tag_366:
        /* "#utility.yul":15242:15248   */
      0x00
        /* "#utility.yul":15295:15297   */
      0x20
        /* "#utility.yul":15283:15292   */
      dup3
        /* "#utility.yul":15274:15281   */
      dup5
        /* "#utility.yul":15270:15293   */
      sub
        /* "#utility.yul":15266:15298   */
      slt
        /* "#utility.yul":15263:15315   */
      iszero
      tag_1107
      jumpi
        /* "#utility.yul":15311:15312   */
      0x00
        /* "#utility.yul":15308:15309   */
      dup1
        /* "#utility.yul":15301:15313   */
      revert
        /* "#utility.yul":15263:15315   */
    tag_1107:
        /* "#utility.yul":15350:15359   */
      dup2
        /* "#utility.yul":15337:15360   */
      calldataload
        /* "#utility.yul":15400:15404   */
      0xff
        /* "#utility.yul":15393:15398   */
      dup2
        /* "#utility.yul":15389:15405   */
      and
        /* "#utility.yul":15382:15387   */
      dup2
        /* "#utility.yul":15379:15406   */
      eq
        /* "#utility.yul":15369:15424   */
      tag_381
      jumpi
        /* "#utility.yul":15420:15421   */
      0x00
        /* "#utility.yul":15417:15418   */
      dup1
        /* "#utility.yul":15410:15422   */
      revert
        /* "#utility.yul":15459:16129   */
    tag_368:
      sub(shl(0xa0, 0x01), 0x01)
        /* "#utility.yul":15826:15841   */
      swap8
      dup9
      and
        /* "#utility.yul":15808:15842   */
      dup2
      mstore
        /* "#utility.yul":15878:15893   */
      swap6
      swap1
      swap7
      and
        /* "#utility.yul":15873:15875   */
      0x20
        /* "#utility.yul":15858:15876   */
      dup7
      add
        /* "#utility.yul":15851:15894   */
      mstore
        /* "#utility.yul":15925:15927   */
      0x40
        /* "#utility.yul":15910:15928   */
      dup6
      add
        /* "#utility.yul":15903:15937   */
      swap4
      swap1
      swap4
      mstore
        /* "#utility.yul":15968:15970   */
      0x60
        /* "#utility.yul":15953:15971   */
      dup5
      add
        /* "#utility.yul":15946:15980   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":16029:16033   */
      0xff
        /* "#utility.yul":16017:16034   */
      and
        /* "#utility.yul":16011:16014   */
      0x80
        /* "#utility.yul":15996:16015   */
      dup4
      add
        /* "#utility.yul":15989:16035   */
      mstore
        /* "#utility.yul":15788:15791   */
      0xa0
        /* "#utility.yul":16051:16070   */
      dup3
      add
        /* "#utility.yul":16044:16079   */
      mstore
        /* "#utility.yul":16110:16113   */
      0xc0
        /* "#utility.yul":16095:16114   */
      dup2
      add
        /* "#utility.yul":16088:16123   */
      swap2
      swap1
      swap2
      mstore
        /* "#utility.yul":15757:15760   */
      0xe0
        /* "#utility.yul":15742:15761   */
      add
      swap1
        /* "#utility.yul":15459:16129   */
      jump	// out
        /* "#utility.yul":16134:16259   */
    tag_414:
        /* "#utility.yul":16174:16178   */
      0x00
        /* "#utility.yul":16202:16203   */
      dup3
        /* "#utility.yul":16199:16200   */
      dup3
        /* "#utility.yul":16196:16204   */
      lt
        /* "#utility.yul":16193:16227   */
      iszero
      tag_1112
      jumpi
        /* "#utility.yul":16207:16225   */
      tag_1112
      tag_988
      jump	// in
    tag_1112:
      pop
        /* "#utility.yul":16244:16253   */
      sub
      swap1
        /* "#utility.yul":16134:16259   */
      jump	// out
        /* "#utility.yul":16264:16432   */
    tag_435:
        /* "#utility.yul":16304:16311   */
      0x00
        /* "#utility.yul":16370:16371   */
      dup2
        /* "#utility.yul":16366:16367   */
      0x00
        /* "#utility.yul":16362:16368   */
      not
        /* "#utility.yul":16358:16372   */
      div
        /* "#utility.yul":16355:16356   */
      dup4
        /* "#utility.yul":16352:16373   */
      gt
        /* "#utility.yul":16347:16348   */
      dup3
        /* "#utility.yul":16340:16349   */
      iszero
        /* "#utility.yul":16333:16350   */
      iszero
        /* "#utility.yul":16329:16374   */
      and
        /* "#utility.yul":16326:16397   */
      iszero
      tag_1115
      jumpi
        /* "#utility.yul":16377:16395   */
      tag_1115
      tag_988
      jump	// in
    tag_1115:
      pop
        /* "#utility.yul":16417:16426   */
      mul
      swap1
        /* "#utility.yul":16264:16432   */
      jump	// out
        /* "#utility.yul":16437:16654   */
    tag_437:
        /* "#utility.yul":16477:16478   */
      0x00
        /* "#utility.yul":16503:16504   */
      dup3
        /* "#utility.yul":16493:16625   */
      tag_1117
      jumpi
        /* "#utility.yul":16547:16557   */
      0x4e487b71
        /* "#utility.yul":16542:16545   */
      0xe0
        /* "#utility.yul":16538:16558   */
      shl
        /* "#utility.yul":16535:16536   */
      0x00
        /* "#utility.yul":16528:16559   */
      mstore
        /* "#utility.yul":16582:16586   */
      0x12
        /* "#utility.yul":16579:16580   */
      0x04
        /* "#utility.yul":16572:16587   */
      mstore
        /* "#utility.yul":16610:16614   */
      0x24
        /* "#utility.yul":16607:16608   */
      0x00
        /* "#utility.yul":16600:16615   */
      revert
        /* "#utility.yul":16493:16625   */
    tag_1117:
      pop
        /* "#utility.yul":16639:16648   */
      div
      swap1
        /* "#utility.yul":16437:16654   */
      jump	// out
        /* "#utility.yul":16659:16787   */
    tag_439:
        /* "#utility.yul":16699:16702   */
      0x00
        /* "#utility.yul":16730:16731   */
      dup3
        /* "#utility.yul":16726:16732   */
      not
        /* "#utility.yul":16723:16724   */
      dup3
        /* "#utility.yul":16720:16733   */
      gt
        /* "#utility.yul":16717:16756   */
      iszero
      tag_1120
      jumpi
        /* "#utility.yul":16736:16754   */
      tag_1120
      tag_988
      jump	// in
    tag_1120:
      pop
        /* "#utility.yul":16772:16781   */
      add
      swap1
        /* "#utility.yul":16659:16787   */
      jump	// out
        /* "#utility.yul":16792:17038   */
    tag_514:
        /* "#utility.yul":16832:16836   */
      0x00
      sub(shl(0x80, 0x01), 0x01)
        /* "#utility.yul":16945:16955   */
      dup4
      dup2
      and
      swap1
        /* "#utility.yul":16915:16925   */
      dup4
      and
        /* "#utility.yul":16967:16979   */
      dup2
      dup2
      lt
        /* "#utility.yul":16964:17002   */
      iszero
      tag_1123
      jumpi
        /* "#utility.yul":16982:17000   */
      tag_1123
      tag_988
      jump	// in
    tag_1123:
        /* "#utility.yul":17019:17032   */
      sub
      swap4
        /* "#utility.yul":16792:17038   */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":17043:17301   */
    tag_989:
        /* "#utility.yul":17115:17116   */
      0x00
        /* "#utility.yul":17125:17238   */
    tag_1125:
        /* "#utility.yul":17139:17145   */
      dup4
        /* "#utility.yul":17136:17137   */
      dup2
        /* "#utility.yul":17133:17146   */
      lt
        /* "#utility.yul":17125:17238   */
      iszero
      tag_1127
      jumpi
        /* "#utility.yul":17215:17226   */
      dup2
      dup2
      add
        /* "#utility.yul":17209:17227   */
      mload
        /* "#utility.yul":17196:17207   */
      dup4
      dup3
      add
        /* "#utility.yul":17189:17228   */
      mstore
        /* "#utility.yul":17161:17163   */
      0x20
        /* "#utility.yul":17154:17164   */
      add
        /* "#utility.yul":17125:17238   */
      jump(tag_1125)
    tag_1127:
        /* "#utility.yul":17256:17262   */
      dup4
        /* "#utility.yul":17253:17254   */
      dup2
        /* "#utility.yul":17250:17263   */
      gt
        /* "#utility.yul":17247:17295   */
      iszero
      tag_398
      jumpi
      pop
      pop
        /* "#utility.yul":17291:17292   */
      0x00
        /* "#utility.yul":17273:17289   */
      swap2
      add
        /* "#utility.yul":17266:17293   */
      mstore
        /* "#utility.yul":17043:17301   */
      jump	// out
        /* "#utility.yul":17306:18092   */
    tag_638:
        /* "#utility.yul":17717:17742   */
      0x416363657373436f6e74726f6c3a206163636f756e7420000000000000000000
        /* "#utility.yul":17712:17715   */
      dup2
        /* "#utility.yul":17705:17743   */
      mstore
        /* "#utility.yul":17687:17690   */
      0x00
        /* "#utility.yul":17772:17778   */
      dup4
        /* "#utility.yul":17766:17779   */
      mload
        /* "#utility.yul":17788:17850   */
      tag_1130
        /* "#utility.yul":17843:17849   */
      dup2
        /* "#utility.yul":17838:17840   */
      0x17
        /* "#utility.yul":17833:17836   */
      dup6
        /* "#utility.yul":17829:17841   */
      add
        /* "#utility.yul":17822:17826   */
      0x20
        /* "#utility.yul":17814:17820   */
      dup9
        /* "#utility.yul":17810:17827   */
      add
        /* "#utility.yul":17788:17850   */
      tag_989
      jump	// in
    tag_1130:
      shl(0x7d, 0x01034b99036b4b9b9b4b733903937b6329)
        /* "#utility.yul":17909:17911   */
      0x17
        /* "#utility.yul":17869:17885   */
      swap2
      dup5
      add
        /* "#utility.yul":17901:17912   */
      swap2
      dup3
      add
        /* "#utility.yul":17894:17934   */
      mstore
        /* "#utility.yul":17959:17972   */
      dup4
      mload
        /* "#utility.yul":17981:18044   */
      tag_1131
        /* "#utility.yul":17959:17972   */
      dup2
        /* "#utility.yul":18030:18032   */
      0x28
        /* "#utility.yul":18022:18033   */
      dup5
      add
        /* "#utility.yul":18015:18019   */
      0x20
        /* "#utility.yul":18003:18020   */
      dup9
      add
        /* "#utility.yul":17981:18044   */
      tag_989
      jump	// in
    tag_1131:
        /* "#utility.yul":18064:18081   */
      add
        /* "#utility.yul":18083:18085   */
      0x28
        /* "#utility.yul":18060:18086   */
      add
      swap5
        /* "#utility.yul":17306:18092   */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":18097:18480   */
    tag_640:
        /* "#utility.yul":18246:18248   */
      0x20
        /* "#utility.yul":18235:18244   */
      dup2
        /* "#utility.yul":18228:18249   */
      mstore
        /* "#utility.yul":18209:18213   */
      0x00
        /* "#utility.yul":18278:18284   */
      dup3
        /* "#utility.yul":18272:18285   */
      mload
        /* "#utility.yul":18321:18327   */
      dup1
        /* "#utility.yul":18316:18318   */
      0x20
        /* "#utility.yul":18305:18314   */
      dup5
        /* "#utility.yul":18301:18319   */
      add
        /* "#utility.yul":18294:18328   */
      mstore
        /* "#utility.yul":18337:18403   */
      tag_1133
        /* "#utility.yul":18396:18402   */
      dup2
        /* "#utility.yul":18391:18393   */
      0x40
        /* "#utility.yul":18380:18389   */
      dup6
        /* "#utility.yul":18376:18394   */
      add
        /* "#utility.yul":18371:18373   */
      0x20
        /* "#utility.yul":18363:18369   */
      dup8
        /* "#utility.yul":18359:18374   */
      add
        /* "#utility.yul":18337:18403   */
      tag_989
      jump	// in
    tag_1133:
        /* "#utility.yul":18464:18466   */
      0x1f
        /* "#utility.yul":18443:18458   */
      add
      not(0x1f)
        /* "#utility.yul":18439:18468   */
      and
        /* "#utility.yul":18424:18469   */
      swap2
      swap1
      swap2
      add
        /* "#utility.yul":18471:18473   */
      0x40
        /* "#utility.yul":18420:18474   */
      add
      swap3
        /* "#utility.yul":18097:18480   */
      swap2
      pop
      pop
      jump	// out
        /* "#utility.yul":18865:19110   */
    tag_655:
        /* "#utility.yul":18932:18938   */
      0x00
        /* "#utility.yul":18985:18987   */
      0x20
        /* "#utility.yul":18973:18982   */
      dup3
        /* "#utility.yul":18964:18971   */
      dup5
        /* "#utility.yul":18960:18983   */
      sub
        /* "#utility.yul":18956:18988   */
      slt
        /* "#utility.yul":18953:19005   */
      iszero
      tag_1136
      jumpi
        /* "#utility.yul":19001:19002   */
      0x00
        /* "#utility.yul":18998:18999   */
      dup1
        /* "#utility.yul":18991:19003   */
      revert
        /* "#utility.yul":18953:19005   */
    tag_1136:
        /* "#utility.yul":19033:19042   */
      dup2
        /* "#utility.yul":19027:19043   */
      mload
        /* "#utility.yul":19052:19080   */
      tag_381
        /* "#utility.yul":19074:19079   */
      dup2
        /* "#utility.yul":19052:19080   */
      tag_984
      jump	// in
        /* "#utility.yul":19115:19299   */
    tag_661:
        /* "#utility.yul":19185:19191   */
      0x00
        /* "#utility.yul":19238:19240   */
      0x20
        /* "#utility.yul":19226:19235   */
      dup3
        /* "#utility.yul":19217:19224   */
      dup5
        /* "#utility.yul":19213:19236   */
      sub
        /* "#utility.yul":19209:19241   */
      slt
        /* "#utility.yul":19206:19258   */
      iszero
      tag_1139
      jumpi
        /* "#utility.yul":19254:19255   */
      0x00
        /* "#utility.yul":19251:19252   */
      dup1
        /* "#utility.yul":19244:19256   */
      revert
        /* "#utility.yul":19206:19258   */
    tag_1139:
      pop
        /* "#utility.yul":19277:19293   */
      mload
      swap2
        /* "#utility.yul":19115:19299   */
      swap1
      pop
      jump	// out
        /* "#utility.yul":19613:19740   */
    tag_703:
        /* "#utility.yul":19674:19684   */
      0x4e487b71
        /* "#utility.yul":19669:19672   */
      0xe0
        /* "#utility.yul":19665:19685   */
      shl
        /* "#utility.yul":19662:19663   */
      0x00
        /* "#utility.yul":19655:19686   */
      mstore
        /* "#utility.yul":19705:19709   */
      0x01
        /* "#utility.yul":19702:19703   */
      0x04
        /* "#utility.yul":19695:19710   */
      mstore
        /* "#utility.yul":19729:19733   */
      0x24
        /* "#utility.yul":19726:19727   */
      0x00
        /* "#utility.yul":19719:19734   */
      revert
        /* "#utility.yul":19745:19881   */
    tag_852:
        /* "#utility.yul":19784:19787   */
      0x00
        /* "#utility.yul":19812:19817   */
      dup2
        /* "#utility.yul":19802:19841   */
      tag_1144
      jumpi
        /* "#utility.yul":19821:19839   */
      tag_1144
      tag_988
      jump	// in
    tag_1144:
      pop
      not(0x00)
        /* "#utility.yul":19857:19875   */
      add
      swap1
        /* "#utility.yul":19745:19881   */
      jump	// out
        /* "#utility.yul":20247:20500   */
    tag_863:
        /* "#utility.yul":20287:20290   */
      0x00
      sub(shl(0x80, 0x01), 0x01)
        /* "#utility.yul":20376:20378   */
      dup1
        /* "#utility.yul":20373:20374   */
      dup4
        /* "#utility.yul":20369:20379   */
      and
        /* "#utility.yul":20406:20408   */
      dup2
        /* "#utility.yul":20403:20404   */
      dup6
        /* "#utility.yul":20399:20409   */
      and
        /* "#utility.yul":20437:20440   */
      dup1
        /* "#utility.yul":20433:20435   */
      dup4
        /* "#utility.yul":20429:20441   */
      sub
        /* "#utility.yul":20424:20427   */
      dup3
        /* "#utility.yul":20421:20442   */
      gt
        /* "#utility.yul":20418:20465   */
      iszero
      tag_1148
      jumpi
        /* "#utility.yul":20445:20463   */
      tag_1148
      tag_988
      jump	// in
    tag_1148:
        /* "#utility.yul":20481:20494   */
      add
      swap5
        /* "#utility.yul":20247:20500   */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":21039:21166   */
    tag_973:
        /* "#utility.yul":21100:21110   */
      0x4e487b71
        /* "#utility.yul":21095:21098   */
      0xe0
        /* "#utility.yul":21091:21111   */
      shl
        /* "#utility.yul":21088:21089   */
      0x00
        /* "#utility.yul":21081:21112   */
      mstore
        /* "#utility.yul":21131:21135   */
      0x31
        /* "#utility.yul":21128:21129   */
      0x04
        /* "#utility.yul":21121:21136   */
      mstore
        /* "#utility.yul":21155:21159   */
      0x24
        /* "#utility.yul":21152:21153   */
      0x00
        /* "#utility.yul":21145:21160   */
      revert
    stop
    data_8c85144e36a363d47a080fe4c41afdc57727e34b590650d5b653cdd378d93afe 8f8c450dae5029cd48cd91dd9db65da48fb742893edfc7941250f6721d93cbbe
    data_91113e80635bccc2f93908fdf2a5cbd6a74badad069abcad4f85e45f73ab3f4c 9a627a5d4aa7c17f87ff26e3fe9a42c2b6c559e8b41a42282d0ecebb17c0e4d3
    data_b589db986128d3258a700f5bc8482afbd859dc508593ec30968f79002edbed47 1450eb8d0693284079f6627b2c1c6bb2e076066e44df1b18ba6ea7cc507e9bcb
    data_ba930d38d363826ce600a5728c59ce313a9b3e31d7a4a14f9fe10008fda6890b e8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02
    data_eb0cc6fe41e07c5bfb34b66efcadef6cbff2b9d3283bcf9ef5027bf303177a95 445f3cbbc114a35d080f2a1953516d74e74d5106860bc2317840ba265f03b51a

    auxdata: 0xa2646970667358221220e453fddab5347c11f2539946157dab219fe01c675b5876a485328fea2222463564736f6c63430008090033
}

