    /* "src/contracts/0.8.9/LidoLocator.sol":381:5256  contract LidoLocator is ILidoLocator {... */
  mstore(0x40, 0x0380)
    /* "src/contracts/0.8.9/LidoLocator.sol":2635:4279  constructor(Config memory _config) {... */
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
    /* "src/contracts/0.8.9/LidoLocator.sol":2714:2738  _config.accountingOracle */
  dup1
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":2699:2739  _assertNonZero(_config.accountingOracle) */
  tag_6
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":2699:2713  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":2699:2739  _assertNonZero(_config.accountingOracle) */
  div
  jump	// in
tag_6:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":2680:2739  accountingOracle = _assertNonZero(_config.accountingOracle) */
  and
  0x80
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":2788:2817  _config.depositSecurityModule */
  0x20
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":2773:2818  _assertNonZero(_config.depositSecurityModule) */
  tag_8
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":2773:2787  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":2773:2818  _assertNonZero(_config.depositSecurityModule) */
  div
  jump	// in
tag_8:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":2749:2818  depositSecurityModule = _assertNonZero(_config.depositSecurityModule) */
  and
  0xa0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":2860:2882  _config.elRewardsVault */
  0x40
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":2845:2883  _assertNonZero(_config.elRewardsVault) */
  tag_9
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":2845:2859  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":2845:2883  _assertNonZero(_config.elRewardsVault) */
  div
  jump	// in
tag_9:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":2828:2883  elRewardsVault = _assertNonZero(_config.elRewardsVault) */
  and
  0xc0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":2915:2927  _config.lido */
  0x60
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":2900:2928  _assertNonZero(_config.lido) */
  tag_10
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":2900:2914  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":2900:2928  _assertNonZero(_config.lido) */
  div
  jump	// in
tag_10:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":2893:2928  lido = _assertNonZero(_config.lido) */
  and
  0xe0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":2981:3014  _config.oracleReportSanityChecker */
  0x80
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":2966:3015  _assertNonZero(_config.oracleReportSanityChecker) */
  tag_11
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":2966:2980  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":2966:3015  _assertNonZero(_config.oracleReportSanityChecker) */
  div
  jump	// in
tag_11:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":2938:3015  oracleReportSanityChecker = _assertNonZero(_config.oracleReportSanityChecker) */
  swap1
  dup2
  and
  0x0100
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3051:3082  _config.postTokenRebaseReceiver */
  0xa0
  dup3
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3025:3082  postTokenRebaseReceiver = _config.postTokenRebaseReceiver */
  and
  0x0120
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3116:3130  _config.burner */
  0xc0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3101:3131  _assertNonZero(_config.burner) */
  tag_12
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3101:3115  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3101:3131  _assertNonZero(_config.burner) */
  div
  jump	// in
tag_12:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3092:3131  burner = _assertNonZero(_config.burner) */
  and
  0x0140
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3172:3193  _config.stakingRouter */
  0xe0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3157:3194  _assertNonZero(_config.stakingRouter) */
  tag_13
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3157:3171  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3157:3194  _assertNonZero(_config.stakingRouter) */
  div
  jump	// in
tag_13:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3141:3194  stakingRouter = _assertNonZero(_config.stakingRouter) */
  and
  0x0160
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3230:3246  _config.treasury */
  0x0100
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3215:3247  _assertNonZero(_config.treasury) */
  tag_14
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3215:3229  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3215:3247  _assertNonZero(_config.treasury) */
  div
  jump	// in
tag_14:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3204:3247  treasury = _assertNonZero(_config.treasury) */
  and
  0x0180
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3298:3329  _config.validatorsExitBusOracle */
  0x0120
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3283:3330  _assertNonZero(_config.validatorsExitBusOracle) */
  tag_15
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3283:3297  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3283:3330  _assertNonZero(_config.validatorsExitBusOracle) */
  div
  jump	// in
tag_15:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3257:3330  validatorsExitBusOracle = _assertNonZero(_config.validatorsExitBusOracle) */
  and
  0x01a0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3373:3396  _config.withdrawalQueue */
  0x0140
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3358:3397  _assertNonZero(_config.withdrawalQueue) */
  tag_16
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3358:3372  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3358:3397  _assertNonZero(_config.withdrawalQueue) */
  div
  jump	// in
tag_16:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3340:3397  withdrawalQueue = _assertNonZero(_config.withdrawalQueue) */
  and
  0x01c0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3440:3463  _config.withdrawalVault */
  0x0160
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3425:3464  _assertNonZero(_config.withdrawalVault) */
  tag_17
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3425:3439  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3425:3464  _assertNonZero(_config.withdrawalVault) */
  div
  jump	// in
tag_17:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3407:3464  withdrawalVault = _assertNonZero(_config.withdrawalVault) */
  and
  0x01e0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3510:3536  _config.oracleDaemonConfig */
  0x0180
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3495:3537  _assertNonZero(_config.oracleDaemonConfig) */
  tag_18
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3495:3509  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3495:3537  _assertNonZero(_config.oracleDaemonConfig) */
  div
  jump	// in
tag_18:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3474:3537  oracleDaemonConfig = _assertNonZero(_config.oracleDaemonConfig) */
  and
  0x0200
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3591:3625  _config.validatorExitDelayVerifier */
  0x01a0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3576:3626  _assertNonZero(_config.validatorExitDelayVerifier) */
  tag_19
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3576:3590  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3576:3626  _assertNonZero(_config.validatorExitDelayVerifier) */
  div
  jump	// in
tag_19:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3547:3626  validatorExitDelayVerifier = _assertNonZero(_config.validatorExitDelayVerifier) */
  and
  0x0220
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3683:3720  _config.triggerableWithdrawalsGateway */
  0x01c0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3668:3721  _assertNonZero(_config.triggerableWithdrawalsGateway) */
  tag_20
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3668:3682  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3668:3721  _assertNonZero(_config.triggerableWithdrawalsGateway) */
  div
  jump	// in
tag_20:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3636:3721  triggerableWithdrawalsGateway = _assertNonZero(_config.triggerableWithdrawalsGateway) */
  and
  0x0240
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3769:3797  _config.consolidationGateway */
  0x01e0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3754:3798  _assertNonZero(_config.consolidationGateway) */
  tag_21
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3754:3768  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3754:3798  _assertNonZero(_config.consolidationGateway) */
  div
  jump	// in
tag_21:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3731:3798  consolidationGateway = _assertNonZero(_config.consolidationGateway) */
  and
  0x0260
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3836:3854  _config.accounting */
  0x0200
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3821:3855  _assertNonZero(_config.accounting) */
  tag_22
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3821:3835  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3821:3855  _assertNonZero(_config.accounting) */
  div
  jump	// in
tag_22:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3808:3855  accounting = _assertNonZero(_config.accounting) */
  and
  0x0280
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3902:3929  _config.predepositGuarantee */
  0x0220
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3887:3930  _assertNonZero(_config.predepositGuarantee) */
  tag_23
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3887:3901  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3887:3930  _assertNonZero(_config.predepositGuarantee) */
  div
  jump	// in
tag_23:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3865:3930  predepositGuarantee = _assertNonZero(_config.predepositGuarantee) */
  and
  0x02a0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":3964:3978  _config.wstETH */
  0x0240
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":3949:3979  _assertNonZero(_config.wstETH) */
  tag_24
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":3949:3963  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":3949:3979  _assertNonZero(_config.wstETH) */
  div
  jump	// in
tag_24:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3940:3979  wstETH = _assertNonZero(_config.wstETH) */
  and
  0x02c0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":4015:4031  _config.vaultHub */
  0x0260
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":4000:4032  _assertNonZero(_config.vaultHub) */
  tag_25
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":4000:4014  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":4000:4032  _assertNonZero(_config.vaultHub) */
  div
  jump	// in
tag_25:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":3989:4032  vaultHub = _assertNonZero(_config.vaultHub) */
  and
  0x02e0
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":4072:4092  _config.vaultFactory */
  0x0280
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":4057:4093  _assertNonZero(_config.vaultFactory) */
  tag_26
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":4057:4071  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":4057:4093  _assertNonZero(_config.vaultFactory) */
  div
  jump	// in
tag_26:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":4042:4093  vaultFactory = _assertNonZero(_config.vaultFactory) */
  and
  0x0300
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":4131:4149  _config.lazyOracle */
  0x02a0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":4116:4150  _assertNonZero(_config.lazyOracle) */
  tag_27
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":4116:4130  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":4116:4150  _assertNonZero(_config.lazyOracle) */
  div
  jump	// in
tag_27:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":4103:4150  lazyOracle = _assertNonZero(_config.lazyOracle) */
  and
  0x0320
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":4190:4210  _config.operatorGrid */
  0x02c0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":4175:4211  _assertNonZero(_config.operatorGrid) */
  tag_28
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":4175:4189  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":4175:4211  _assertNonZero(_config.operatorGrid) */
  div
  jump	// in
tag_28:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":4160:4211  operatorGrid = _assertNonZero(_config.operatorGrid) */
  and
  0x0340
  mstore
    /* "src/contracts/0.8.9/LidoLocator.sol":4251:4271  _config.topUpGateway */
  0x02e0
  dup2
  add
  mload
    /* "src/contracts/0.8.9/LidoLocator.sol":4236:4272  _assertNonZero(_config.topUpGateway) */
  tag_29
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":4236:4250  _assertNonZero */
  0x0100000000
  tag_7
  dup2
  mul
    /* "src/contracts/0.8.9/LidoLocator.sol":4236:4272  _assertNonZero(_config.topUpGateway) */
  div
  jump	// in
tag_29:
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":4221:4272  topUpGateway = _assertNonZero(_config.topUpGateway) */
  and
  0x0360
  mstore
  pop
    /* "src/contracts/0.8.9/LidoLocator.sol":381:5256  contract LidoLocator is ILidoLocator {... */
  jump(tag_35)
    /* "src/contracts/0.8.9/LidoLocator.sol":5090:5254  function _assertNonZero(address _address) internal pure returns (address) {... */
tag_7:
    /* "src/contracts/0.8.9/LidoLocator.sol":5155:5162  address */
  0x00
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/contracts/0.8.9/LidoLocator.sol":5178:5200  _address == address(0) */
  dup3
  and
    /* "src/contracts/0.8.9/LidoLocator.sol":5174:5222  if (_address == address(0)) revert ZeroAddress() */
  tag_32
  jumpi
    /* "src/contracts/0.8.9/LidoLocator.sol":5209:5222  ZeroAddress() */
  mload(0x40)
  0xd92e233d00000000000000000000000000000000000000000000000000000000
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
    /* "src/contracts/0.8.9/LidoLocator.sol":5174:5222  if (_address == address(0)) revert ZeroAddress() */
tag_32:
  pop
    /* "src/contracts/0.8.9/LidoLocator.sol":5239:5247  _address */
  swap1
    /* "src/contracts/0.8.9/LidoLocator.sol":5090:5254  function _assertNonZero(address _address) internal pure returns (address) {... */
  jump	// out
    /* "#utility.yul":14:415   */
tag_33:
    /* "#utility.yul":81:83   */
  0x40
    /* "#utility.yul":75:84   */
  mload
    /* "#utility.yul":123:126   */
  0x0300
    /* "#utility.yul":111:127   */
  dup2
  add
    /* "#utility.yul":157:175   */
  0xffffffffffffffff
    /* "#utility.yul":142:176   */
  dup2
  gt
    /* "#utility.yul":178:200   */
  dup3
  dup3
  lt
    /* "#utility.yul":139:201   */
  or
    /* "#utility.yul":136:378   */
  iszero
  tag_37
  jumpi
    /* "#utility.yul":234:311   */
  0x4e487b7100000000000000000000000000000000000000000000000000000000
    /* "#utility.yul":231:232   */
  0x00
    /* "#utility.yul":224:312   */
  mstore
    /* "#utility.yul":335:339   */
  0x41
    /* "#utility.yul":332:333   */
  0x04
    /* "#utility.yul":325:340   */
  mstore
    /* "#utility.yul":363:367   */
  0x24
    /* "#utility.yul":360:361   */
  0x00
    /* "#utility.yul":353:368   */
  revert
    /* "#utility.yul":136:378   */
tag_37:
    /* "#utility.yul":394:396   */
  0x40
    /* "#utility.yul":387:409   */
  mstore
    /* "#utility.yul":14:415   */
  swap1
  jump	// out
    /* "#utility.yul":420:597   */
tag_34:
    /* "#utility.yul":499:512   */
  dup1
  mload
  sub(exp(0x02, 0xa0), 0x01)
    /* "#utility.yul":541:572   */
  dup2
  and
    /* "#utility.yul":531:573   */
  dup2
  eq
    /* "#utility.yul":521:591   */
  tag_39
  jumpi
    /* "#utility.yul":587:588   */
  0x00
    /* "#utility.yul":584:585   */
  dup1
    /* "#utility.yul":577:589   */
  revert
    /* "#utility.yul":521:591   */
tag_39:
    /* "#utility.yul":420:597   */
  swap2
  swap1
  pop
  jump	// out
    /* "#utility.yul":602:3170   */
tag_3:
    /* "#utility.yul":696:702   */
  0x00
    /* "#utility.yul":749:752   */
  0x0300
    /* "#utility.yul":737:746   */
  dup3
    /* "#utility.yul":728:735   */
  dup5
    /* "#utility.yul":724:747   */
  sub
    /* "#utility.yul":720:753   */
  slt
    /* "#utility.yul":717:770   */
  iszero
  tag_41
  jumpi
    /* "#utility.yul":766:767   */
  0x00
    /* "#utility.yul":763:764   */
  dup1
    /* "#utility.yul":756:768   */
  revert
    /* "#utility.yul":717:770   */
tag_41:
    /* "#utility.yul":792:809   */
  tag_42
  tag_33
  jump	// in
tag_42:
    /* "#utility.yul":832:872   */
  tag_43
    /* "#utility.yul":862:871   */
  dup4
    /* "#utility.yul":832:872   */
  tag_34
  jump	// in
tag_43:
    /* "#utility.yul":825:830   */
  dup2
    /* "#utility.yul":818:873   */
  mstore
    /* "#utility.yul":905:954   */
  tag_44
    /* "#utility.yul":950:952   */
  0x20
    /* "#utility.yul":939:948   */
  dup5
    /* "#utility.yul":935:953   */
  add
    /* "#utility.yul":905:954   */
  tag_34
  jump	// in
tag_44:
    /* "#utility.yul":900:902   */
  0x20
    /* "#utility.yul":893:898   */
  dup3
    /* "#utility.yul":889:903   */
  add
    /* "#utility.yul":882:955   */
  mstore
    /* "#utility.yul":987:1036   */
  tag_45
    /* "#utility.yul":1032:1034   */
  0x40
    /* "#utility.yul":1021:1030   */
  dup5
    /* "#utility.yul":1017:1035   */
  add
    /* "#utility.yul":987:1036   */
  tag_34
  jump	// in
tag_45:
    /* "#utility.yul":982:984   */
  0x40
    /* "#utility.yul":975:980   */
  dup3
    /* "#utility.yul":971:985   */
  add
    /* "#utility.yul":964:1037   */
  mstore
    /* "#utility.yul":1069:1118   */
  tag_46
    /* "#utility.yul":1114:1116   */
  0x60
    /* "#utility.yul":1103:1112   */
  dup5
    /* "#utility.yul":1099:1117   */
  add
    /* "#utility.yul":1069:1118   */
  tag_34
  jump	// in
tag_46:
    /* "#utility.yul":1064:1066   */
  0x60
    /* "#utility.yul":1057:1062   */
  dup3
    /* "#utility.yul":1053:1067   */
  add
    /* "#utility.yul":1046:1119   */
  mstore
    /* "#utility.yul":1152:1202   */
  tag_47
    /* "#utility.yul":1197:1200   */
  0x80
    /* "#utility.yul":1186:1195   */
  dup5
    /* "#utility.yul":1182:1201   */
  add
    /* "#utility.yul":1152:1202   */
  tag_34
  jump	// in
tag_47:
    /* "#utility.yul":1146:1149   */
  0x80
    /* "#utility.yul":1139:1144   */
  dup3
    /* "#utility.yul":1135:1150   */
  add
    /* "#utility.yul":1128:1203   */
  mstore
    /* "#utility.yul":1236:1286   */
  tag_48
    /* "#utility.yul":1281:1284   */
  0xa0
    /* "#utility.yul":1270:1279   */
  dup5
    /* "#utility.yul":1266:1285   */
  add
    /* "#utility.yul":1236:1286   */
  tag_34
  jump	// in
tag_48:
    /* "#utility.yul":1230:1233   */
  0xa0
    /* "#utility.yul":1223:1228   */
  dup3
    /* "#utility.yul":1219:1234   */
  add
    /* "#utility.yul":1212:1287   */
  mstore
    /* "#utility.yul":1320:1370   */
  tag_49
    /* "#utility.yul":1365:1368   */
  0xc0
    /* "#utility.yul":1354:1363   */
  dup5
    /* "#utility.yul":1350:1369   */
  add
    /* "#utility.yul":1320:1370   */
  tag_34
  jump	// in
tag_49:
    /* "#utility.yul":1314:1317   */
  0xc0
    /* "#utility.yul":1307:1312   */
  dup3
    /* "#utility.yul":1303:1318   */
  add
    /* "#utility.yul":1296:1371   */
  mstore
    /* "#utility.yul":1404:1454   */
  tag_50
    /* "#utility.yul":1449:1452   */
  0xe0
    /* "#utility.yul":1438:1447   */
  dup5
    /* "#utility.yul":1434:1453   */
  add
    /* "#utility.yul":1404:1454   */
  tag_34
  jump	// in
tag_50:
    /* "#utility.yul":1398:1401   */
  0xe0
    /* "#utility.yul":1391:1396   */
  dup3
    /* "#utility.yul":1387:1402   */
  add
    /* "#utility.yul":1380:1455   */
  mstore
    /* "#utility.yul":1474:1477   */
  0x0100
    /* "#utility.yul":1509:1558   */
  tag_51
    /* "#utility.yul":1554:1556   */
  dup2
    /* "#utility.yul":1543:1552   */
  dup6
    /* "#utility.yul":1539:1557   */
  add
    /* "#utility.yul":1509:1558   */
  tag_34
  jump	// in
tag_51:
    /* "#utility.yul":1493:1507   */
  swap1
  dup3
  add
    /* "#utility.yul":1486:1559   */
  mstore
    /* "#utility.yul":1578:1581   */
  0x0120
    /* "#utility.yul":1613:1662   */
  tag_52
    /* "#utility.yul":1643:1661   */
  dup5
  dup3
  add
    /* "#utility.yul":1613:1662   */
  tag_34
  jump	// in
tag_52:
    /* "#utility.yul":1597:1611   */
  swap1
  dup3
  add
    /* "#utility.yul":1590:1663   */
  mstore
    /* "#utility.yul":1682:1685   */
  0x0140
    /* "#utility.yul":1717:1766   */
  tag_53
    /* "#utility.yul":1747:1765   */
  dup5
  dup3
  add
    /* "#utility.yul":1717:1766   */
  tag_34
  jump	// in
tag_53:
    /* "#utility.yul":1701:1715   */
  swap1
  dup3
  add
    /* "#utility.yul":1694:1767   */
  mstore
    /* "#utility.yul":1786:1789   */
  0x0160
    /* "#utility.yul":1821:1870   */
  tag_54
    /* "#utility.yul":1851:1869   */
  dup5
  dup3
  add
    /* "#utility.yul":1821:1870   */
  tag_34
  jump	// in
tag_54:
    /* "#utility.yul":1805:1819   */
  swap1
  dup3
  add
    /* "#utility.yul":1798:1871   */
  mstore
    /* "#utility.yul":1890:1893   */
  0x0180
    /* "#utility.yul":1925:1974   */
  tag_55
    /* "#utility.yul":1955:1973   */
  dup5
  dup3
  add
    /* "#utility.yul":1925:1974   */
  tag_34
  jump	// in
tag_55:
    /* "#utility.yul":1909:1923   */
  swap1
  dup3
  add
    /* "#utility.yul":1902:1975   */
  mstore
    /* "#utility.yul":1994:1997   */
  0x01a0
    /* "#utility.yul":2029:2078   */
  tag_56
    /* "#utility.yul":2059:2077   */
  dup5
  dup3
  add
    /* "#utility.yul":2029:2078   */
  tag_34
  jump	// in
tag_56:
    /* "#utility.yul":2013:2027   */
  swap1
  dup3
  add
    /* "#utility.yul":2006:2079   */
  mstore
    /* "#utility.yul":2098:2101   */
  0x01c0
    /* "#utility.yul":2133:2182   */
  tag_57
    /* "#utility.yul":2163:2181   */
  dup5
  dup3
  add
    /* "#utility.yul":2133:2182   */
  tag_34
  jump	// in
tag_57:
    /* "#utility.yul":2117:2131   */
  swap1
  dup3
  add
    /* "#utility.yul":2110:2183   */
  mstore
    /* "#utility.yul":2202:2205   */
  0x01e0
    /* "#utility.yul":2237:2286   */
  tag_58
    /* "#utility.yul":2267:2285   */
  dup5
  dup3
  add
    /* "#utility.yul":2237:2286   */
  tag_34
  jump	// in
tag_58:
    /* "#utility.yul":2221:2235   */
  swap1
  dup3
  add
    /* "#utility.yul":2214:2287   */
  mstore
    /* "#utility.yul":2306:2309   */
  0x0200
    /* "#utility.yul":2341:2390   */
  tag_59
    /* "#utility.yul":2371:2389   */
  dup5
  dup3
  add
    /* "#utility.yul":2341:2390   */
  tag_34
  jump	// in
tag_59:
    /* "#utility.yul":2325:2339   */
  swap1
  dup3
  add
    /* "#utility.yul":2318:2391   */
  mstore
    /* "#utility.yul":2411:2414   */
  0x0220
    /* "#utility.yul":2447:2497   */
  tag_60
    /* "#utility.yul":2477:2496   */
  dup5
  dup3
  add
    /* "#utility.yul":2447:2497   */
  tag_34
  jump	// in
tag_60:
    /* "#utility.yul":2430:2445   */
  swap1
  dup3
  add
    /* "#utility.yul":2423:2498   */
  mstore
    /* "#utility.yul":2518:2521   */
  0x0240
    /* "#utility.yul":2554:2604   */
  tag_61
    /* "#utility.yul":2584:2603   */
  dup5
  dup3
  add
    /* "#utility.yul":2554:2604   */
  tag_34
  jump	// in
tag_61:
    /* "#utility.yul":2537:2552   */
  swap1
  dup3
  add
    /* "#utility.yul":2530:2605   */
  mstore
    /* "#utility.yul":2625:2628   */
  0x0260
    /* "#utility.yul":2661:2711   */
  tag_62
    /* "#utility.yul":2691:2710   */
  dup5
  dup3
  add
    /* "#utility.yul":2661:2711   */
  tag_34
  jump	// in
tag_62:
    /* "#utility.yul":2644:2659   */
  swap1
  dup3
  add
    /* "#utility.yul":2637:2712   */
  mstore
    /* "#utility.yul":2732:2735   */
  0x0280
    /* "#utility.yul":2768:2818   */
  tag_63
    /* "#utility.yul":2798:2817   */
  dup5
  dup3
  add
    /* "#utility.yul":2768:2818   */
  tag_34
  jump	// in
tag_63:
    /* "#utility.yul":2751:2766   */
  swap1
  dup3
  add
    /* "#utility.yul":2744:2819   */
  mstore
    /* "#utility.yul":2839:2842   */
  0x02a0
    /* "#utility.yul":2875:2925   */
  tag_64
    /* "#utility.yul":2905:2924   */
  dup5
  dup3
  add
    /* "#utility.yul":2875:2925   */
  tag_34
  jump	// in
tag_64:
    /* "#utility.yul":2858:2873   */
  swap1
  dup3
  add
    /* "#utility.yul":2851:2926   */
  mstore
    /* "#utility.yul":2946:2949   */
  0x02c0
    /* "#utility.yul":2982:3032   */
  tag_65
    /* "#utility.yul":3012:3031   */
  dup5
  dup3
  add
    /* "#utility.yul":2982:3032   */
  tag_34
  jump	// in
tag_65:
    /* "#utility.yul":2965:2980   */
  swap1
  dup3
  add
    /* "#utility.yul":2958:3033   */
  mstore
    /* "#utility.yul":3053:3056   */
  0x02e0
    /* "#utility.yul":3089:3139   */
  tag_66
    /* "#utility.yul":3119:3138   */
  dup5
  dup3
  add
    /* "#utility.yul":3089:3139   */
  tag_34
  jump	// in
tag_66:
    /* "#utility.yul":3072:3087   */
  swap1
  dup3
  add
    /* "#utility.yul":3065:3140   */
  mstore
    /* "#utility.yul":3076:3081   */
  swap4
    /* "#utility.yul":602:3170   */
  swap3
  pop
  pop
  pop
  jump	// out
tag_35:
    /* "src/contracts/0.8.9/LidoLocator.sol":381:5256  contract LidoLocator is ILidoLocator {... */
  mload(0x80)
  mload(0xa0)
  mload(0xc0)
  mload(0xe0)
  mload(0x0100)
  mload(0x0120)
  mload(0x0140)
  mload(0x0160)
  mload(0x0180)
  mload(0x01a0)
  mload(0x01c0)
  mload(0x01e0)
  mload(0x0200)
  mload(0x0220)
  mload(0x0240)
  mload(0x0260)
  mload(0x0280)
  mload(0x02a0)
  mload(0x02c0)
  mload(0x02e0)
  mload(0x0300)
  mload(0x0320)
  mload(0x0340)
  mload(0x0360)
  codecopy(0x00, dataOffset(sub_0), dataSize(sub_0))
  0x00
  assignImmutable("0xea1c3a463a334d4502a6bc7c1ce6676ab071cb26e08d8d603278a360d97dc14c")
  0x00
  assignImmutable("0x33e238d35c5878a00c0b41bb14bf170dc8975fbccc23fdcd4d6def8a35f2b4ff")
  0x00
  assignImmutable("0xce808bee4cccd89eae538588eb77bc380f9da5c9759321360894904078b60e9d")
  0x00
  assignImmutable("0xafca43aa599376c7b90696247a35115c63b93138e61f08f3178d2a5ed7be3bf5")
  0x00
  assignImmutable("0x753005bd0bd6e20e7acd0dd8275cf856a18a272384014dc1cce463f3c48513ee")
  0x00
  assignImmutable("0x554c46e96817775b8989ddc254d554940ba2015f43972fccfc1ecb50653ca381")
  0x00
  assignImmutable("0x97824bbe6e40d0dd7dc4dfbd8453ad754b387f6ecc496038a29ae6c08908bf4f")
  0x00
  assignImmutable("0x2421bf267a9cf09c6324c6235fd3f297d10d1bc3146ea5ce2cc1eb602bb8cd41")
  0x00
  assignImmutable("0x3531cc3dc5bb231b65d260771886cc583d8fe8fb29b457554cb1930a722a747d")
  0x00
  assignImmutable("0xc53e81d5df64592d8da771bc0a3ae4c598dca5ecd02622d7a28774b6b78c4b19")
  0x00
  assignImmutable("0x29f8d1998cd4186678d0085cd54072aeefd05bc476ef1844361510d857ac074b")
  0x00
  assignImmutable("0xc9c56ece8ab1aa87565be4409fb2c8fe3d8ffec3fdab003090c209216657ff72")
  0x00
  assignImmutable("0x6ec03fc6a2303ff0283996b05577f38ea45b37619214a3bde5dbe5d42345eefa")
  0x00
  assignImmutable("0x294a915770f1abdd270970c5c5e0116f353ee0443c415452cffb70311418f069")
  0x00
  assignImmutable("0xe9e0475224745f570c2fa5a2212581dbb763b0b604cf1588d130cda3bdffbf52")
  0x00
  assignImmutable("0x341878494918d8151b9a5c06b89111716a13db8d7307871a34b92267fdbacd54")
  0x00
  assignImmutable("0x51cced3aa4cce2bc1795a51d0cf6e1d1377f88f6d8c4fec45da052f87ea02752")
  0x00
  assignImmutable("0x94b72f6d5810c90c68ea7d7f52a48aba033cd0249ea1144a4588f2256d6f57ff")
  0x00
  assignImmutable("0xcc1cf32daa775edd624f71ddb0d100d39c31c65becb67e6d2e7789fa58c10fe0")
  0x00
  assignImmutable("0xdbe57501b1c7526a01d30f9df6b0318f6c7e7a325dfdb4249dda8958c2bb53bc")
  0x00
  assignImmutable("0xd42f94ef3d2e62346988d2d58c999f56371dc7993a3ad4f92e0d3796c93f6830")
  0x00
  assignImmutable("0x7accbde6ceb84317f73cf616046161b2827a9ee871490b0c927c2024ef305ecf")
  0x00
  assignImmutable("0xd4fdba55a337451fb821a44ca705320b9065ad6ec4ab5b29c1056e12ca3c3cb3")
  0x00
  assignImmutable("0x4304fe5d7fe4375eefe3ebf4aaab653abea6a5daf0294f9dcca579ad0ebe9a53")
  return(0x00, dataSize(sub_0))
stop

sub_0: assembly {
        /* "src/contracts/0.8.9/LidoLocator.sol":381:5256  contract LidoLocator is ILidoLocator {... */
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
      calldataload(0x00)
      0x0100000000000000000000000000000000000000000000000000000000
      swap1
      div
      dup1
      0x69d42148
      gt
      tag_29
      jumpi
      dup1
      0xd680a876
      gt
      tag_30
      jumpi
      dup1
      0xe441d25f
      gt
      tag_31
      jumpi
      dup1
      0xe441d25f
      eq
      tag_25
      jumpi
      dup1
      0xef6c064c
      eq
      tag_26
      jumpi
      dup1
      0xf4415af2
      eq
      tag_27
      jumpi
      dup1
      0xf5e6d50f
      eq
      tag_28
      jumpi
      0x00
      dup1
      revert
    tag_31:
      dup1
      0xd680a876
      eq
      tag_22
      jumpi
      dup1
      0xd6dff580
      eq
      tag_23
      jumpi
      dup1
      0xd8a06f73
      eq
      tag_24
      jumpi
      0x00
      dup1
      revert
    tag_30:
      dup1
      0x69d42148
      eq
      tag_16
      jumpi
      dup1
      0x6dd6e80b
      eq
      tag_17
      jumpi
      dup1
      0x8d4e6153
      eq
      tag_18
      jumpi
      dup1
      0x9624e83e
      eq
      tag_19
      jumpi
      dup1
      0xb2ad1104
      eq
      tag_20
      jumpi
      dup1
      0xb9a03828
      eq
      tag_21
      jumpi
      0x00
      dup1
      revert
    tag_29:
      dup1
      0x3fe7d554
      gt
      tag_32
      jumpi
      dup1
      0x53ce572d
      gt
      tag_33
      jumpi
      dup1
      0x53ce572d
      eq
      tag_12
      jumpi
      dup1
      0x5a2031f9
      eq
      tag_13
      jumpi
      dup1
      0x61d027b3
      eq
      tag_14
      jumpi
      dup1
      0x644862de
      eq
      tag_15
      jumpi
      0x00
      dup1
      revert
    tag_33:
      dup1
      0x3fe7d554
      eq
      tag_9
      jumpi
      dup1
      0x472c1776
      eq
      tag_10
      jumpi
      dup1
      0x4aa07e64
      eq
      tag_11
      jumpi
      0x00
      dup1
      revert
    tag_32:
      dup1
      0x12f8d4b9
      eq
      tag_3
      jumpi
      dup1
      0x23509a2d
      eq
      tag_4
      jumpi
      dup1
      0x27810b6e
      eq
      tag_5
      jumpi
      dup1
      0x2e39045c
      eq
      tag_6
      jumpi
      dup1
      0x35f4022e
      eq
      tag_7
      jumpi
      dup1
      0x37d5fe99
      eq
      tag_8
      jumpi
    tag_2:
      0x00
      dup1
      revert
        /* "src/contracts/0.8.9/LidoLocator.sol":1727:1775  address public immutable validatorsExitBusOracle */
    tag_3:
      tag_34
      immutable("0xe9e0475224745f570c2fa5a2212581dbb763b0b604cf1588d130cda3bdffbf52")
      dup2
      jump
    tag_34:
      mload(0x40)
        /* "#utility.yul":190:232   */
      0xffffffffffffffffffffffffffffffffffffffff
        /* "#utility.yul":178:233   */
      swap1
      swap2
      and
        /* "#utility.yul":160:234   */
      dup2
      mstore
        /* "#utility.yul":148:150   */
      0x20
        /* "#utility.yul":133:151   */
      add
        /* "src/contracts/0.8.9/LidoLocator.sol":1727:1775  address public immutable validatorsExitBusOracle */
    tag_36:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/contracts/0.8.9/LidoLocator.sol":1462:1491  address public immutable lido */
    tag_4:
      tag_34
      immutable("0xd42f94ef3d2e62346988d2d58c999f56371dc7993a3ad4f92e0d3796c93f6830")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1607:1638  address public immutable burner */
    tag_5:
      tag_34
      immutable("0x94b72f6d5810c90c68ea7d7f52a48aba033cd0249ea1144a4588f2256d6f57ff")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2300:2335  address public immutable lazyOracle */
    tag_6:
      tag_34
      immutable("0xce808bee4cccd89eae538588eb77bc380f9da5c9759321360894904078b60e9d")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":4285:4650  function coreComponents() external view returns (... */
    tag_7:
      0x40
      dup1
      mload
        /* "#utility.yul":542:584   */
      0xffffffffffffffffffffffffffffffffffffffff
        /* "src/contracts/0.8.9/LidoLocator.sol":4473:4487  elRewardsVault */
      immutable("0x7accbde6ceb84317f73cf616046161b2827a9ee871490b0c927c2024ef305ecf")
        /* "#utility.yul":611:626   */
      dup2
      and
        /* "#utility.yul":593:627   */
      dup3
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4501:4526  oracleReportSanityChecker */
      immutable("0xdbe57501b1c7526a01d30f9df6b0318f6c7e7a325dfdb4249dda8958c2bb53bc")
        /* "#utility.yul":663:678   */
      dup2
      and
        /* "#utility.yul":658:660   */
      0x20
        /* "#utility.yul":643:661   */
      dup4
      add
        /* "#utility.yul":636:679   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4540:4553  stakingRouter */
      immutable("0x51cced3aa4cce2bc1795a51d0cf6e1d1377f88f6d8c4fec45da052f87ea02752")
        /* "#utility.yul":715:730   */
      dup2
      and
        /* "#utility.yul":695:713   */
      swap3
      dup3
      add
        /* "#utility.yul":688:731   */
      swap3
      swap1
      swap3
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4567:4575  treasury */
      immutable("0x341878494918d8151b9a5c06b89111716a13db8d7307871a34b92267fdbacd54")
        /* "#utility.yul":767:782   */
      dup3
      and
        /* "#utility.yul":762:764   */
      0x60
        /* "#utility.yul":747:765   */
      dup3
      add
        /* "#utility.yul":740:783   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4589:4604  withdrawalQueue */
      immutable("0x294a915770f1abdd270970c5c5e0116f353ee0443c415452cffb70311418f069")
        /* "#utility.yul":820:835   */
      dup3
      and
        /* "#utility.yul":814:817   */
      0x80
        /* "#utility.yul":799:818   */
      dup3
      add
        /* "#utility.yul":792:836   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4618:4633  withdrawalVault */
      immutable("0x6ec03fc6a2303ff0283996b05577f38ea45b37619214a3bde5dbe5d42345eefa")
        /* "#utility.yul":873:888   */
      swap2
      swap1
      swap2
      and
        /* "#utility.yul":867:870   */
      0xa0
        /* "#utility.yul":852:871   */
      dup3
      add
        /* "#utility.yul":845:889   */
      mstore
        /* "#utility.yul":519:522   */
      0xc0
        /* "#utility.yul":504:523   */
      add
        /* "src/contracts/0.8.9/LidoLocator.sol":4285:4650  function coreComponents() external view returns (... */
      tag_36
        /* "#utility.yul":245:895   */
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1781:1821  address public immutable withdrawalQueue */
    tag_8:
      tag_34
      immutable("0x294a915770f1abdd270970c5c5e0116f353ee0443c415452cffb70311418f069")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1873:1916  address public immutable oracleDaemonConfig */
    tag_9:
      tag_34
      immutable("0xc9c56ece8ab1aa87565be4409fb2c8fe3d8ffec3fdab003090c209216657ff72")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1365:1411  address public immutable depositSecurityModule */
    tag_10:
      tag_34
      immutable("0xd4fdba55a337451fb821a44ca705320b9065ad6ec4ab5b29c1056e12ca3c3cb3")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2181:2212  address public immutable wstETH */
    tag_11:
      tag_34
      immutable("0x554c46e96817775b8989ddc254d554940ba2015f43972fccfc1ecb50653ca381")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1922:1973  address public immutable validatorExitDelayVerifier */
    tag_12:
      tag_34
      immutable("0x29f8d1998cd4186678d0085cd54072aeefd05bc476ef1844361510d857ac074b")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1318:1359  address public immutable accountingOracle */
    tag_13:
      tag_34
      immutable("0x4304fe5d7fe4375eefe3ebf4aaab653abea6a5daf0294f9dcca579ad0ebe9a53")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1688:1721  address public immutable treasury */
    tag_14:
      tag_34
      immutable("0x341878494918d8151b9a5c06b89111716a13db8d7307871a34b92267fdbacd54")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2384:2421  address public immutable topUpGateway */
    tag_15:
      tag_34
      immutable("0xea1c3a463a334d4502a6bc7c1ce6676ab071cb26e08d8d603278a360d97dc14c")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1827:1867  address public immutable withdrawalVault */
    tag_16:
      tag_34
      immutable("0x6ec03fc6a2303ff0283996b05577f38ea45b37619214a3bde5dbe5d42345eefa")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2218:2251  address public immutable vaultHub */
    tag_17:
      tag_34
      immutable("0x753005bd0bd6e20e7acd0dd8275cf856a18a272384014dc1cce463f3c48513ee")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2131:2175  address public immutable predepositGuarantee */
    tag_18:
      tag_34
      immutable("0x97824bbe6e40d0dd7dc4dfbd8453ad754b387f6ecc496038a29ae6c08908bf4f")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2090:2125  address public immutable accounting */
    tag_19:
      tag_34
      immutable("0x2421bf267a9cf09c6324c6235fd3f297d10d1bc3146ea5ce2cc1eb602bb8cd41")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":4656:5084  function oracleReportComponents() external view override returns(... */
    tag_20:
      0x40
      dup1
      mload
        /* "#utility.yul":1225:1267   */
      0xffffffffffffffffffffffffffffffffffffffff
        /* "src/contracts/0.8.9/LidoLocator.sol":4877:4893  accountingOracle */
      immutable("0x4304fe5d7fe4375eefe3ebf4aaab653abea6a5daf0294f9dcca579ad0ebe9a53")
        /* "#utility.yul":1294:1309   */
      dup2
      and
        /* "#utility.yul":1276:1310   */
      dup3
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4907:4932  oracleReportSanityChecker */
      immutable("0xdbe57501b1c7526a01d30f9df6b0318f6c7e7a325dfdb4249dda8958c2bb53bc")
        /* "#utility.yul":1346:1361   */
      dup2
      and
        /* "#utility.yul":1341:1343   */
      0x20
        /* "#utility.yul":1326:1344   */
      dup4
      add
        /* "#utility.yul":1319:1362   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4946:4952  burner */
      immutable("0x94b72f6d5810c90c68ea7d7f52a48aba033cd0249ea1144a4588f2256d6f57ff")
        /* "#utility.yul":1398:1413   */
      dup2
      and
        /* "#utility.yul":1378:1396   */
      swap3
      dup3
      add
        /* "#utility.yul":1371:1414   */
      swap3
      swap1
      swap3
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4966:4981  withdrawalQueue */
      immutable("0x294a915770f1abdd270970c5c5e0116f353ee0443c415452cffb70311418f069")
        /* "#utility.yul":1450:1465   */
      dup3
      and
        /* "#utility.yul":1445:1447   */
      0x60
        /* "#utility.yul":1430:1448   */
      dup3
      add
        /* "#utility.yul":1423:1466   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":4995:5018  postTokenRebaseReceiver */
      immutable("0xcc1cf32daa775edd624f71ddb0d100d39c31c65becb67e6d2e7789fa58c10fe0")
        /* "#utility.yul":1503:1518   */
      dup3
      and
        /* "#utility.yul":1497:1500   */
      0x80
        /* "#utility.yul":1482:1501   */
      dup3
      add
        /* "#utility.yul":1475:1519   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":5032:5045  stakingRouter */
      immutable("0x51cced3aa4cce2bc1795a51d0cf6e1d1377f88f6d8c4fec45da052f87ea02752")
        /* "#utility.yul":1556:1571   */
      dup3
      and
        /* "#utility.yul":1550:1553   */
      0xa0
        /* "#utility.yul":1535:1554   */
      dup3
      add
        /* "#utility.yul":1528:1572   */
      mstore
        /* "src/contracts/0.8.9/LidoLocator.sol":5059:5067  vaultHub */
      immutable("0x753005bd0bd6e20e7acd0dd8275cf856a18a272384014dc1cce463f3c48513ee")
        /* "#utility.yul":1609:1624   */
      swap2
      swap1
      swap2
      and
        /* "#utility.yul":1603:1606   */
      0xc0
        /* "#utility.yul":1588:1607   */
      dup3
      add
        /* "#utility.yul":1581:1625   */
      mstore
        /* "#utility.yul":1202:1205   */
      0xe0
        /* "#utility.yul":1187:1206   */
      add
        /* "src/contracts/0.8.9/LidoLocator.sol":4656:5084  function oracleReportComponents() external view override returns(... */
      tag_36
        /* "#utility.yul":900:1631   */
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2341:2378  address public immutable operatorGrid */
    tag_21:
      tag_34
      immutable("0x33e238d35c5878a00c0b41bb14bf170dc8975fbccc23fdcd4d6def8a35f2b4ff")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1553:1601  address public immutable postTokenRebaseReceiver */
    tag_22:
      tag_34
      immutable("0xcc1cf32daa775edd624f71ddb0d100d39c31c65becb67e6d2e7789fa58c10fe0")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1979:2033  address public immutable triggerableWithdrawalsGateway */
    tag_23:
      tag_34
      immutable("0xc53e81d5df64592d8da771bc0a3ae4c598dca5ecd02622d7a28774b6b78c4b19")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2257:2294  address public immutable vaultFactory */
    tag_24:
      tag_34
      immutable("0xafca43aa599376c7b90696247a35115c63b93138e61f08f3178d2a5ed7be3bf5")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1417:1456  address public immutable elRewardsVault */
    tag_25:
      tag_34
      immutable("0x7accbde6ceb84317f73cf616046161b2827a9ee871490b0c927c2024ef305ecf")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1644:1682  address public immutable stakingRouter */
    tag_26:
      tag_34
      immutable("0x51cced3aa4cce2bc1795a51d0cf6e1d1377f88f6d8c4fec45da052f87ea02752")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":2039:2084  address public immutable consolidationGateway */
    tag_27:
      tag_34
      immutable("0x3531cc3dc5bb231b65d260771886cc583d8fe8fb29b457554cb1930a722a747d")
      dup2
      jump
        /* "src/contracts/0.8.9/LidoLocator.sol":1497:1547  address public immutable oracleReportSanityChecker */
    tag_28:
      tag_34
      immutable("0xdbe57501b1c7526a01d30f9df6b0318f6c7e7a325dfdb4249dda8958c2bb53bc")
      dup2
      jump

    auxdata: 0xa26469706673582212204b3534bb30fb8a0f97f67b70c61981f41d11f04fd0eddb407495062e97ae06ac64736f6c63430008090033
}

