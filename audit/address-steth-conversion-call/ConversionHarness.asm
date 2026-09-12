    /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
  mstore(0x40, 0x80)
    /* "src/contracts/0.4.24/utils/Versioned.sol":1251:1318  CONTRACT_VERSION_POSITION.setStorageUint256(PETRIFIED_VERSION_MARK) */
  tag_4
    /* "src/contracts/0.4.24/utils/Versioned.sol":948:1014  0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6 */
  0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
  not(0x0)
    /* "src/contracts/0.4.24/utils/Versioned.sol":1251:1294  CONTRACT_VERSION_POSITION.setStorageUint256 */
  0x100000000
  tag_0_562
  tag_5
  dup3
  mul
  or
    /* "src/contracts/0.4.24/utils/Versioned.sol":1251:1318  CONTRACT_VERSION_POSITION.setStorageUint256(PETRIFIED_VERSION_MARK) */
  div
  jump	// in
tag_4:
    /* "src/@aragon/os/contracts/common/Autopetrified.sol":343:352  petrify() */
  tag_7
    /* "src/@aragon/os/contracts/common/Autopetrified.sol":343:350  petrify */
  0x100000000
  tag_8
  dup2
  mul
    /* "src/@aragon/os/contracts/common/Autopetrified.sol":343:352  petrify() */
  div
  jump	// in
tag_7:
    /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
  jump(tag_9)
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1027:1146  function setStorageUint256(bytes32 position, uint256 data) internal {... */
tag_5:
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1116:1138  sstore(position, data) */
  swap1
  sstore
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1114:1140  { sstore(position, data) } */
  jump	// out
    /* "src/@aragon/os/contracts/common/Petrifiable.sol":589:673  function petrify() internal onlyInit {... */
tag_8:
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
  tag_12
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:636  getInitializationBlock */
  0x100000000
  tag_13
  dup2
  mul
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
  div
  jump	// in
tag_12:
    /* "src/@aragon/os/contracts/common/Initializable.sol":645:670  ERROR_ALREADY_INITIALIZED */
  0x40
  dup1
  mload
  dup1
  dup3
  add
  swap1
  swap2
  mstore
  0x18
  dup2
  mstore
  0x494e49545f414c52454144595f494e495449414c495a45440000000000000000
  0x20
  dup3
  add
  mstore
  swap1
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:643  getInitializationBlock() == 0 */
  iszero
    /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
  tag_14
  jumpi
  mload(0x40)
  0x8c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
  0x4
  add
  dup1
  dup1
  0x20
  add
  dup3
  dup2
  sub
  dup3
  mstore
  dup4
  dup2
  dup2
  mload
  dup2
  mstore
  0x20
  add
  swap2
  pop
  dup1
  mload
  swap1
  0x20
  add
  swap1
  dup1
  dup4
  dup4
    /* "--CODEGEN--":23:24   */
  0x0
    /* "--CODEGEN--":8:108   */
tag_15:
    /* "--CODEGEN--":33:36   */
  dup4
    /* "--CODEGEN--":30:31   */
  dup2
    /* "--CODEGEN--":27:37   */
  lt
    /* "--CODEGEN--":8:108   */
  iszero
  tag_16
  jumpi
    /* "--CODEGEN--":90:101   */
  dup2
  dup2
  add
    /* "--CODEGEN--":84:102   */
  mload
    /* "--CODEGEN--":71:82   */
  dup4
  dup3
  add
    /* "--CODEGEN--":64:103   */
  mstore
    /* "--CODEGEN--":52:54   */
  0x20
    /* "--CODEGEN--":45:55   */
  add
    /* "--CODEGEN--":8:108   */
  jump(tag_15)
tag_16:
    /* "--CODEGEN--":12:26   */
  pop
    /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
  pop
  pop
  pop
  swap1
  pop
  swap1
  dup2
  add
  swap1
  0x1f
  and
  dup1
  iszero
  tag_18
  jumpi
  dup1
  dup3
  sub
  dup1
  mload
  0x1
  dup4
  0x20
  sub
  0x100
  exp
  sub
  not
  and
  dup2
  mstore
  0x20
  add
  swap2
  pop
tag_18:
  pop
  swap3
  pop
  pop
  pop
  mload(0x40)
  dup1
  swap2
  sub
  swap1
  revert
tag_14:
  pop
    /* "src/@aragon/os/contracts/common/Petrifiable.sol":636:666  initializedAt(PETRIFIED_BLOCK) */
  tag_20
  not(0x0)
    /* "src/@aragon/os/contracts/common/Petrifiable.sol":636:649  initializedAt */
  0x100000000
  tag_21
  dup2
  mul
    /* "src/@aragon/os/contracts/common/Petrifiable.sol":636:666  initializedAt(PETRIFIED_BLOCK) */
  div
  jump	// in
tag_20:
    /* "src/@aragon/os/contracts/common/Petrifiable.sol":589:673  function petrify() internal onlyInit {... */
  jump	// out
    /* "src/@aragon/os/contracts/common/Initializable.sol":880:1017  function getInitializationBlock() public view returns (uint256) {... */
tag_13:
    /* "src/@aragon/os/contracts/common/Initializable.sol":935:942  uint256 */
  0x0
    /* "src/@aragon/os/contracts/common/Initializable.sol":961:1010  INITIALIZATION_BLOCK_POSITION.getStorageUint256() */
  tag_23
  0x0
  dup1
  mload
  0x20
  data_1b40822006c6e6d8a2f11af38d236a7d577b9c3badb5a768a1bac85094deca19
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@aragon/os/contracts/common/Initializable.sol":961:1008  INITIALIZATION_BLOCK_POSITION.getStorageUint256 */
  0x100000000
  tag_0_438
  tag_24
  dup3
  mul
  or
    /* "src/@aragon/os/contracts/common/Initializable.sol":961:1010  INITIALIZATION_BLOCK_POSITION.getStorageUint256() */
  div
  jump	// in
tag_23:
    /* "src/@aragon/os/contracts/common/Initializable.sol":954:1010  return INITIALIZATION_BLOCK_POSITION.getStorageUint256() */
  swap1
  pop
    /* "src/@aragon/os/contracts/common/Initializable.sol":880:1017  function getInitializationBlock() public view returns (uint256) {... */
  swap1
  jump	// out
    /* "src/@aragon/os/contracts/common/Initializable.sol":1750:1891  function initializedAt(uint256 _blockNumber) internal onlyInit {... */
tag_21:
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
  tag_26
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:636  getInitializationBlock */
  0x100000000
  tag_13
  dup2
  mul
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
  div
  jump	// in
tag_26:
    /* "src/@aragon/os/contracts/common/Initializable.sol":645:670  ERROR_ALREADY_INITIALIZED */
  0x40
  dup1
  mload
  dup1
  dup3
  add
  swap1
  swap2
  mstore
  0x18
  dup2
  mstore
  0x494e49545f414c52454144595f494e495449414c495a45440000000000000000
  0x20
  dup3
  add
  mstore
  swap1
    /* "src/@aragon/os/contracts/common/Initializable.sol":614:643  getInitializationBlock() == 0 */
  iszero
    /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
  tag_27
  jumpi
  mload(0x40)
  0x8c379a000000000000000000000000000000000000000000000000000000000
  dup2
  mstore
  0x4
  add
  dup1
  dup1
  0x20
  add
  dup3
  dup2
  sub
  dup3
  mstore
  dup4
  dup2
  dup2
  mload
  dup2
  mstore
  0x20
  add
  swap2
  pop
  dup1
  mload
  swap1
  0x20
  add
  swap1
  dup1
  dup4
  dup4
    /* "--CODEGEN--":23:24   */
  0x0
    /* "--CODEGEN--":33:36   */
  dup4
    /* "--CODEGEN--":30:31   */
  dup2
    /* "--CODEGEN--":27:37   */
  lt
    /* "--CODEGEN--":8:108   */
  iszero
  tag_16
  jumpi
    /* "--CODEGEN--":90:101   */
  dup2
  dup2
  add
    /* "--CODEGEN--":84:102   */
  mload
    /* "--CODEGEN--":71:82   */
  dup4
  dup3
  add
    /* "--CODEGEN--":64:103   */
  mstore
    /* "--CODEGEN--":52:54   */
  0x20
    /* "--CODEGEN--":45:55   */
  add
    /* "--CODEGEN--":8:108   */
  jump(tag_15)
    /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
tag_27:
  pop
    /* "src/@aragon/os/contracts/common/Initializable.sol":1823:1884  INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber) */
  tag_33
  0x0
  dup1
  mload
  0x20
  data_1b40822006c6e6d8a2f11af38d236a7d577b9c3badb5a768a1bac85094deca19
  dup4
  codecopy
  dup2
  mload
  swap2
  mstore
    /* "src/@aragon/os/contracts/common/Initializable.sol":1871:1883  _blockNumber */
  dup3
    /* "src/@aragon/os/contracts/common/Initializable.sol":1823:1870  INITIALIZATION_BLOCK_POSITION.setStorageUint256 */
  0x100000000
  tag_0_562
  tag_5
  dup3
  mul
  or
    /* "src/@aragon/os/contracts/common/Initializable.sol":1823:1884  INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber) */
  div
  jump	// in
tag_33:
    /* "src/@aragon/os/contracts/common/Initializable.sol":1750:1891  function initializedAt(uint256 _blockNumber) internal onlyInit {... */
  pop
  jump	// out
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":518:652  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
tag_24:
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":629:644  sload(position) */
  sload
  swap1
    /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":619:646  { data := sload(position) } */
  jump	// out
    /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
tag_9:
  dataSize(sub_0)
  dup1
  dataOffset(sub_0)
  0x0
  codecopy
  0x0
  return
stop
data_1b40822006c6e6d8a2f11af38d236a7d577b9c3badb5a768a1bac85094deca19 ebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e

sub_0: assembly {
        /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
      mstore(0x40, 0x80)
      jumpi(tag_1, lt(calldatasize, 0x4))
      and(div(calldataload(0x0), exp(0x2, 0xe0)), 0xffffffff)
      0x103349c
      dup2
      eq
      tag_2
      jumpi
      dup1
      0x46f7da2
      eq
      tag_3
      jumpi
      dup1
      0x6f187a4
      eq
      tag_4
      jumpi
      dup1
      0x6fdde03
      eq
      tag_5
      jumpi
      dup1
      0x7da68f5
      eq
      tag_6
      jumpi
      dup1
      0x803fac0
      eq
      tag_7
      jumpi
      dup1
      0x8c37d55
      eq
      tag_8
      jumpi
      dup1
      0x95ea7b3
      eq
      tag_9
      jumpi
      dup1
      0x136dd43c
      eq
      tag_10
      jumpi
      dup1
      0x14457a32
      eq
      tag_11
      jumpi
      dup1
      0x1574d953
      eq
      tag_12
      jumpi
      dup1
      0x1794bb3c
      eq
      tag_13
      jumpi
      dup1
      0x18160ddd
      eq
      tag_14
      jumpi
      dup1
      0x19208451
      eq
      tag_15
      jumpi
      dup1
      0x1b250097
      eq
      tag_16
      jumpi
      dup1
      0x1ea7ca89
      eq
      tag_17
      jumpi
      dup1
      0x2087400e
      eq
      tag_18
      jumpi
      dup1
      0x23b872dd
      eq
      tag_19
      jumpi
      dup1
      0x2914b9bd
      eq
      tag_20
      jumpi
      dup1
      0x2cb5f784
      eq
      tag_21
      jumpi
      dup1
      0x2de03aa1
      eq
      tag_22
      jumpi
      dup1
      0x313ce567
      eq
      tag_23
      jumpi
      dup1
      0x32f0a3b5
      eq
      tag_24
      jumpi
      dup1
      0x3644e515
      eq
      tag_25
      jumpi
      dup1
      0x37cfdaca
      eq
      tag_14
      jumpi
      dup1
      0x389ed267
      eq
      tag_27
      jumpi
      dup1
      0x38ac3c55
      eq
      tag_28
      jumpi
      dup1
      0x39509351
      eq
      tag_29
      jumpi
      dup1
      0x3b19e84a
      eq
      tag_30
      jumpi
      dup1
      0x3f683b6a
      eq
      tag_31
      jumpi
      dup1
      0x47b714e0
      eq
      tag_32
      jumpi
      dup1
      0x4ad509b2
      eq
      tag_33
      jumpi
      dup1
      0x528c198a
      eq
      tag_34
      jumpi
      dup1
      0x56396715
      eq
      tag_35
      jumpi
      dup1
      0x574ff50d
      eq
      tag_36
      jumpi
      dup1
      0x609c4c6c
      eq
      tag_37
      jumpi
      dup1
      0x63021d8b
      eq
      tag_38
      jumpi
      dup1
      0x648c51e7
      eq
      tag_39
      jumpi
      dup1
      0x665b4b0b
      eq
      tag_40
      jumpi
      dup1
      0x6d780459
      eq
      tag_41
      jumpi
      dup1
      0x70a08231
      eq
      tag_42
      jumpi
      dup1
      0x72e62e56
      eq
      tag_43
      jumpi
      dup1
      0x7475f913
      eq
      tag_44
      jumpi
      dup1
      0x752f77f1
      eq
      tag_45
      jumpi
      dup1
      0x75cb2672
      eq
      tag_46
      jumpi
      dup1
      0x78ffcfe2
      eq
      tag_47
      jumpi
      dup1
      0x7a28fb88
      eq
      tag_48
      jumpi
      dup1
      0x7c8d9e38
      eq
      tag_49
      jumpi
      dup1
      0x7e7db6e1
      eq
      tag_50
      jumpi
      dup1
      0x7ecebe00
      eq
      tag_51
      jumpi
      dup1
      0x80afdea8
      eq
      tag_52
      jumpi
      dup1
      0x84b0196e
      eq
      tag_53
      jumpi
      dup1
      0x853c637d
      eq
      tag_54
      jumpi
      dup1
      0x8831f09e
      eq
      tag_55
      jumpi
      dup1
      0x8a5e5688
      eq
      tag_56
      jumpi
      dup1
      0x8aa10435
      eq
      tag_57
      jumpi
      dup1
      0x8b3dd749
      eq
      tag_58
      jumpi
      dup1
      0x8ee1c0a8
      eq
      tag_59
      jumpi
      dup1
      0x8fcb4e5b
      eq
      tag_60
      jumpi
      dup1
      0x9271e3e6
      eq
      tag_61
      jumpi
      dup1
      0x95d89b41
      eq
      tag_62
      jumpi
      dup1
      0x9861f8e5
      eq
      tag_63
      jumpi
      dup1
      0x9ca5a3d0
      eq
      tag_64
      jumpi
      dup1
      0x9d4941d8
      eq
      tag_65
      jumpi
      dup1
      0xa1658fad
      eq
      tag_66
      jumpi
      dup1
      0xa1903eab
      eq
      tag_67
      jumpi
      dup1
      0xa457c2d7
      eq
      tag_68
      jumpi
      dup1
      0xa479e508
      eq
      tag_69
      jumpi
      dup1
      0xa9059cbb
      eq
      tag_70
      jumpi
      dup1
      0xae2e3538
      eq
      tag_71
      jumpi
      dup1
      0xb3320d9a
      eq
      tag_72
      jumpi
      dup1
      0xced72f87
      eq
      tag_73
      jumpi
      dup1
      0xd4aae0c4
      eq
      tag_74
      jumpi
      dup1
      0xd5002f2e
      eq
      tag_75
      jumpi
      dup1
      0xd505accf
      eq
      tag_76
      jumpi
      dup1
      0xdd62ed3e
      eq
      tag_77
      jumpi
      dup1
      0xde4796ed
      eq
      tag_78
      jumpi
      dup1
      0xe16a9065
      eq
      tag_79
      jumpi
      dup1
      0xe654ff17
      eq
      tag_80
      jumpi
      dup1
      0xe78a5875
      eq
      tag_81
      jumpi
      dup1
      0xeb85262f
      eq
      tag_82
      jumpi
      dup1
      0xf0bfd7e8
      eq
      tag_83
      jumpi
      dup1
      0xf2cfa87d
      eq
      tag_84
      jumpi
      dup1
      0xf352e17e
      eq
      tag_85
      jumpi
      dup1
      0xf5eb42dc
      eq
      tag_86
      jumpi
      dup1
      0xf77c4791
      eq
      tag_87
      jumpi
      dup1
      0xf999c506
      eq
      tag_88
      jumpi
      dup1
      0xfa64ebac
      eq
      tag_89
      jumpi
    tag_1:
        /* "src/contracts/0.4.24/Lido.sol":22636:22644  msg.data */
      calldatasize
        /* "src/contracts/0.4.24/Lido.sol":22636:22656  msg.data.length == 0 */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":22628:22675  require(msg.data.length == 0, "NON_EMPTY_DATA") */
      tag_92
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xe
      0x24
      dup3
      add
      mstore
      0x4e4f4e5f454d5054595f44415441000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_92:
        /* "src/contracts/0.4.24/Lido.sol":22685:22695  _submit(0) */
      tag_93
        /* "src/contracts/0.4.24/Lido.sol":22693:22694  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":22685:22692  _submit */
      tag_94
        /* "src/contracts/0.4.24/Lido.sol":22685:22695  _submit(0) */
      jump	// in
    tag_93:
      pop
        /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
      stop
        /* "src/contracts/0.4.24/StETH.sol":13645:14023  function getPooledEthBySharesRoundUp(uint256 _sharesAmount) public view returns (uint256) {... */
    tag_2:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_95
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_95:
      pop
        /* "src/contracts/0.4.24/StETH.sol":13645:14023  function getPooledEthBySharesRoundUp(uint256 _sharesAmount) public view returns (uint256) {... */
      tag_96
      calldataload(0x4)
      jump(tag_97)
    tag_96:
      0x40
      dup1
      mload
      swap2
      dup3
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":24277:24385  function resume() external {... */
    tag_3:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_98
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_98:
        /* "src/contracts/0.4.24/Lido.sol":24277:24385  function resume() external {... */
      pop
      tag_99
      jump(tag_100)
    tag_99:
      stop
        /* "src/contracts/0.4.24/Lido.sol":42662:43306  function mintExternalShares(address _recipient, uint256 _amountOfShares) external {... */
    tag_4:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_101
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_101:
      pop
        /* "src/contracts/0.4.24/Lido.sol":42662:43306  function mintExternalShares(address _recipient, uint256 _amountOfShares) external {... */
      tag_99
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_103)
        /* "src/contracts/0.4.24/StETH.sol":5504:5600  function name() external pure returns (string) {... */
    tag_5:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_104
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_104:
        /* "src/contracts/0.4.24/StETH.sol":5504:5600  function name() external pure returns (string) {... */
      pop
      tag_105
      jump(tag_106)
    tag_105:
      0x40
      dup1
      mload
      0x20
      dup1
      dup3
      mstore
      dup4
      mload
      dup2
      dup4
      add
      mstore
      dup4
      mload
      swap2
      swap3
      dup4
      swap3
      swap1
      dup4
      add
      swap2
      dup6
      add
      swap1
      dup1
      dup4
      dup4
      0x0
        /* "--CODEGEN--":8:108   */
    tag_107:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_108
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_107)
    tag_108:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/contracts/0.4.24/StETH.sol":5504:5600  function name() external pure returns (string) {... */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_110
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_110:
      pop
      swap3
      pop
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":24019:24121  function stop() external {... */
    tag_6:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_111
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_111:
        /* "src/contracts/0.4.24/Lido.sol":24019:24121  function stop() external {... */
      pop
      tag_99
      jump(tag_113)
        /* "src/@aragon/os/contracts/common/Initializable.sol":1127:1335  function hasInitialized() public view returns (bool) {... */
    tag_7:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_114
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_114:
        /* "src/@aragon/os/contracts/common/Initializable.sol":1127:1335  function hasInitialized() public view returns (bool) {... */
      pop
      tag_115
      jump(tag_116)
    tag_115:
      0x40
      dup1
      mload
      swap2
      iszero
      iszero
      dup3
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":4437:4565  bytes32 public constant BUFFER_RESERVE_MANAGER_ROLE =... */
    tag_8:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_117
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_117:
        /* "src/contracts/0.4.24/Lido.sol":4437:4565  bytes32 public constant BUFFER_RESERVE_MANAGER_ROLE =... */
      pop
      tag_96
      jump(tag_119)
        /* "src/contracts/0.4.24/StETH.sol":8652:8805  function approve(address _spender, uint256 _amount) external returns (bool) {... */
    tag_9:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_120
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_120:
      pop
        /* "src/contracts/0.4.24/StETH.sol":8652:8805  function approve(address _spender, uint256 _amount) external returns (bool) {... */
      tag_115
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_122)
        /* "src/contracts/0.4.24/Lido.sol":4281:4394  bytes32 public constant STAKING_CONTROL_ROLE = 0xa42eee1333c0758ba72be38e728b6dadb32ea767de5b4ddbaea1dae85b1b051f */
    tag_10:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_123
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_123:
        /* "src/contracts/0.4.24/Lido.sol":4281:4394  bytes32 public constant STAKING_CONTROL_ROLE = 0xa42eee1333c0758ba72be38e728b6dadb32ea767de5b4ddbaea1dae85b1b051f */
      pop
      tag_96
      jump(tag_125)
        /* "src/contracts/0.4.24/Lido.sol":29350:29542  function setDepositsReserveTarget(uint256 _newDepositsReserveTarget) external {... */
    tag_11:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_126
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_126:
      pop
        /* "src/contracts/0.4.24/Lido.sol":29350:29542  function setDepositsReserveTarget(uint256 _newDepositsReserveTarget) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_128)
        /* "src/contracts/0.4.24/Lido.sol":29078:29220  function getDepositsReserveTarget() public view returns (uint256) {... */
    tag_12:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_129
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_129:
        /* "src/contracts/0.4.24/Lido.sol":29078:29220  function getDepositsReserveTarget() public view returns (uint256) {... */
      pop
      tag_96
      jump(tag_131)
        /* "src/contracts/0.4.24/Lido.sol":13059:13634  function initialize(address _lidoLocator, address _eip712StETH, uint256 _depositsReserveTarget) public payable onlyInit {... */
    tag_13:
      tag_99
      sub(exp(0x2, 0xa0), 0x1)
      calldataload(0x4)
      dup2
      and
      swap1
      calldataload(0x24)
      and
      calldataload(0x44)
      jump(tag_133)
        /* "src/contracts/0.4.24/StETH.sol":6201:6302  function totalSupply() external view returns (uint256) {... */
    tag_14:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_134
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_134:
        /* "src/contracts/0.4.24/StETH.sol":6201:6302  function totalSupply() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_136)
        /* "src/contracts/0.4.24/StETH.sol":12431:12734  function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {... */
    tag_15:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_137
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_137:
      pop
        /* "src/contracts/0.4.24/StETH.sol":12431:12734  function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {... */
      tag_96
      calldataload(0x4)
      jump(tag_139)
        /* "src/contracts/0.4.24/Lido.sol":52980:53726  function emitTokenRebase(... */
    tag_16:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_140
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_140:
      pop
        /* "src/contracts/0.4.24/Lido.sol":52980:53726  function emitTokenRebase(... */
      tag_99
      calldataload(0x4)
      calldataload(0x24)
      calldataload(0x44)
      calldataload(0x64)
      calldataload(0x84)
      calldataload(0xa4)
      calldataload(0xc4)
      calldataload(0xe4)
      calldataload(0x104)
      jump(tag_142)
        /* "src/contracts/0.4.24/Lido.sol":19222:19369  function isStakingPaused() public view returns (bool) {... */
    tag_17:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_143
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_143:
        /* "src/contracts/0.4.24/Lido.sol":19222:19369  function isStakingPaused() public view returns (bool) {... */
      pop
      tag_115
      jump(tag_145)
        /* "src/contracts/0.4.24/Lido.sol":40309:41111  function withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount) external {... */
    tag_18:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_146
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_146:
      pop
        /* "src/contracts/0.4.24/Lido.sol":40309:41111  function withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount) external {... */
      tag_99
      calldataload(0x4)
      calldataload(0x24)
      jump(tag_148)
        /* "src/contracts/0.4.24/StETH.sol":9671:9903  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {... */
    tag_19:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_149
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_149:
      pop
        /* "src/contracts/0.4.24/StETH.sol":9671:9903  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {... */
      tag_115
      sub(exp(0x2, 0xa0), 0x1)
      calldataload(0x4)
      dup2
      and
      swap1
      calldataload(0x24)
      and
      calldataload(0x44)
      jump(tag_151)
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":794:973  function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {... */
    tag_20:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_152
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_152:
      pop
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":794:973  function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {... */
      0x40
      dup1
      mload
      0x20
      0x4
      dup1
      calldataload
      dup1
      dup3
      add
      calldataload
      0x1f
      dup2
      add
      dup5
      swap1
      div
      dup5
      mul
      dup6
      add
      dup5
      add
      swap1
      swap6
      mstore
      dup5
      dup5
      mstore
      tag_153
      swap5
      calldatasize
      swap5
      swap3
      swap4
      0x24
      swap4
      swap3
      dup5
      add
      swap2
      swap1
      dup2
      swap1
      dup5
      add
      dup4
      dup3
      dup1
      dup3
      dup5
      calldatacopy
      pop
      swap5
      swap8
      pop
      tag_154
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump
    tag_153:
      0x40
      dup1
      mload
      sub(exp(0x2, 0xa0), 0x1)
      swap1
      swap3
      and
      dup3
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":18285:18794  function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external {... */
    tag_21:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_155
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_155:
      pop
        /* "src/contracts/0.4.24/Lido.sol":18285:18794  function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external {... */
      tag_99
      calldataload(0x4)
      calldataload(0x24)
      jump(tag_157)
        /* "src/contracts/0.4.24/Lido.sol":3990:4094  bytes32 public constant RESUME_ROLE = 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
    tag_22:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_158
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_158:
        /* "src/contracts/0.4.24/Lido.sol":3990:4094  bytes32 public constant RESUME_ROLE = 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
      pop
      tag_96
      jump(tag_160)
        /* "src/contracts/0.4.24/StETH.sol":5899:5975  function decimals() external pure returns (uint8) {... */
    tag_23:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_161
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_161:
        /* "src/contracts/0.4.24/StETH.sol":5899:5975  function decimals() external pure returns (uint8) {... */
      pop
      tag_162
      jump(tag_163)
    tag_162:
      0x40
      dup1
      mload
      0xff
      swap1
      swap3
      and
      dup3
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      return
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2252:2481  function getRecoveryVault() public view returns (address) {... */
    tag_24:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_164
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_164:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2252:2481  function getRecoveryVault() public view returns (address) {... */
      pop
      tag_153
      jump(tag_166)
        /* "src/contracts/0.4.24/StETHPermit.sol":4825:4972  function DOMAIN_SEPARATOR() external view returns (bytes32) {... */
    tag_25:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_167
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_167:
        /* "src/contracts/0.4.24/StETHPermit.sol":4825:4972  function DOMAIN_SEPARATOR() external view returns (bytes32) {... */
      pop
      tag_96
      jump(tag_169)
        /* "src/contracts/0.4.24/Lido.sol":3853:3956  bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
    tag_27:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_173
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_173:
        /* "src/contracts/0.4.24/Lido.sol":3853:3956  bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
      pop
      tag_96
      jump(tag_175)
        /* "src/contracts/0.4.24/Lido.sol":33764:34518  function getBalanceStats()... */
    tag_28:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_176
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_176:
        /* "src/contracts/0.4.24/Lido.sol":33764:34518  function getBalanceStats()... */
      pop
      tag_177
      jump(tag_178)
    tag_177:
      0x40
      dup1
      mload
      swap5
      dup6
      mstore
      0x20
      dup6
      add
      swap4
      swap1
      swap4
      mstore
      dup4
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0x60
      dup4
      add
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x80
      add
      swap1
      return
        /* "src/contracts/0.4.24/StETH.sol":10441:10650  function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {... */
    tag_29:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_179
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_179:
      pop
        /* "src/contracts/0.4.24/StETH.sol":10441:10650  function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {... */
      tag_115
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_181)
        /* "src/contracts/0.4.24/Lido.sol":54646:54753  function getTreasury() external view returns (address) {... */
    tag_30:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_182
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_182:
        /* "src/contracts/0.4.24/Lido.sol":54646:54753  function getTreasury() external view returns (address) {... */
      pop
      tag_153
      jump(tag_184)
        /* "src/contracts/0.4.24/utils/Pausable.sol":753:863  function isStopped() public view returns (bool) {... */
    tag_31:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_185
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_185:
        /* "src/contracts/0.4.24/utils/Pausable.sol":753:863  function isStopped() public view returns (bool) {... */
      pop
      tag_115
      jump(tag_187)
        /* "src/contracts/0.4.24/Lido.sol":24709:24812  function getBufferedEther() external view returns (uint256) {... */
    tag_32:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_188
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_188:
        /* "src/contracts/0.4.24/Lido.sol":24709:24812  function getBufferedEther() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_190)
        /* "src/contracts/0.4.24/Lido.sol":23321:23560  function receiveELRewards() external payable {... */
    tag_33:
      tag_99
      jump(tag_192)
        /* "src/contracts/0.4.24/Lido.sol":41315:41574  function mintShares(address _recipient, uint256 _amountOfShares) external {... */
    tag_34:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_193
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_193:
      pop
        /* "src/contracts/0.4.24/Lido.sol":41315:41574  function mintShares(address _recipient, uint256 _amountOfShares) external {... */
      tag_99
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_195)
        /* "src/contracts/0.4.24/Lido.sol":54382:54517  function getWithdrawalCredentials() external view returns (bytes32) {... */
    tag_35:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_196
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_196:
        /* "src/contracts/0.4.24/Lido.sol":54382:54517  function getWithdrawalCredentials() external view returns (bytes32) {... */
      pop
      tag_96
      jump(tag_198)
        /* "src/contracts/0.4.24/Lido.sol":46284:47390  function processClStateUpdate(uint256 _reportTimestamp, uint256 _clValidatorsBalance, uint256 _clPendingBalance)... */
    tag_36:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_199
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_199:
      pop
        /* "src/contracts/0.4.24/Lido.sol":46284:47390  function processClStateUpdate(uint256 _reportTimestamp, uint256 _clValidatorsBalance, uint256 _clPendingBalance)... */
      tag_99
      calldataload(0x4)
      calldataload(0x24)
      calldataload(0x44)
      jump(tag_201)
        /* "src/contracts/0.4.24/Lido.sol":19611:19773  function getCurrentStakeLimit() external view returns (uint256) {... */
    tag_37:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_202
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_202:
        /* "src/contracts/0.4.24/Lido.sol":19611:19773  function getCurrentStakeLimit() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_204)
        /* "src/contracts/0.4.24/Lido.sol":30990:31095  function getExternalShares() external view returns (uint256) {... */
    tag_38:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_205
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_205:
        /* "src/contracts/0.4.24/Lido.sol":30990:31095  function getExternalShares() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_207)
        /* "src/contracts/0.4.24/Lido.sol":47519:48375  function internalizeExternalBadDebt(uint256 _amountOfShares) external {... */
    tag_39:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_208
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_208:
      pop
        /* "src/contracts/0.4.24/Lido.sol":47519:48375  function internalizeExternalBadDebt(uint256 _amountOfShares) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_210)
        /* "src/contracts/0.4.24/Lido.sol":20482:21410  function getStakeLimitFullInfo()... */
    tag_40:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_211
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_211:
        /* "src/contracts/0.4.24/Lido.sol":20482:21410  function getStakeLimitFullInfo()... */
      pop
      tag_212
      jump(tag_213)
    tag_212:
      0x40
      dup1
      mload
      swap8
      iszero
      iszero
      dup9
      mstore
      swap6
      iszero
      iszero
      0x20
      dup9
      add
      mstore
      dup7
      dup7
      add
      swap5
      swap1
      swap5
      mstore
      0x60
      dup7
      add
      swap3
      swap1
      swap3
      mstore
      0x80
      dup6
      add
      mstore
      0xa0
      dup5
      add
      mstore
      0xc0
      dup4
      add
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0xe0
      add
      swap1
      return
        /* "src/contracts/0.4.24/StETH.sol":15578:16011  function transferSharesFrom(... */
    tag_41:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_214
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_214:
      pop
        /* "src/contracts/0.4.24/StETH.sol":15578:16011  function transferSharesFrom(... */
      tag_96
      sub(exp(0x2, 0xa0), 0x1)
      calldataload(0x4)
      dup2
      and
      swap1
      calldataload(0x24)
      and
      calldataload(0x44)
      jump(tag_216)
        /* "src/contracts/0.4.24/StETH.sol":6844:6978  function balanceOf(address _account) external view returns (uint256) {... */
    tag_42:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_217
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_217:
      pop
        /* "src/contracts/0.4.24/StETH.sol":6844:6978  function balanceOf(address _account) external view returns (uint256) {... */
      tag_96
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_219)
        /* "src/contracts/0.4.24/Lido.sol":43492:44451  function burnExternalShares(uint256 _amountOfShares) external {... */
    tag_43:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_220
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_220:
      pop
        /* "src/contracts/0.4.24/Lido.sol":43492:44451  function burnExternalShares(uint256 _amountOfShares) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_222)
        /* "src/contracts/0.4.24/Lido.sol":17044:17285  function resumeStaking() external {... */
    tag_44:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_223
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_223:
        /* "src/contracts/0.4.24/Lido.sol":17044:17285  function resumeStaking() external {... */
      pop
      tag_99
      jump(tag_225)
        /* "src/contracts/0.4.24/Lido.sol":56232:57033  function getFeeDistribution()... */
    tag_45:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_226
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_226:
        /* "src/contracts/0.4.24/Lido.sol":56232:57033  function getFeeDistribution()... */
      pop
      tag_227
      jump(tag_228)
    tag_227:
      0x40
      dup1
      mload
      0xffff
      swap5
      dup6
      and
      dup2
      mstore
      swap3
      dup5
      and
      0x20
      dup5
      add
      mstore
      swap3
      and
      dup2
      dup4
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x60
      add
      swap1
      return
        /* "src/ConversionHarness.sol":376:430  function configure(address c) external {controller=c;} */
    tag_46:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_229
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_229:
      pop
        /* "src/ConversionHarness.sol":376:430  function configure(address c) external {controller=c;} */
      tag_99
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_231)
        /* "src/contracts/0.4.24/Lido.sol":23818:23953  function receiveWithdrawals() external payable {... */
    tag_47:
      tag_99
      jump(tag_233)
        /* "src/contracts/0.4.24/StETH.sol":12982:13297  function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {... */
    tag_48:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_234
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_234:
      pop
        /* "src/contracts/0.4.24/StETH.sol":12982:13297  function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {... */
      tag_96
      calldataload(0x4)
      jump(tag_236)
        /* "src/contracts/0.4.24/Lido.sol":44813:45786  function rebalanceExternalEtherToInternal(uint256 _amountOfShares) external payable {... */
    tag_49:
      tag_99
      calldataload(0x4)
      jump(tag_238)
        /* "src/@aragon/os/contracts/common/VaultRecoverable.sol":1658:1757  function allowRecoverability(address token) public view returns (bool) {... */
    tag_50:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_239
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_239:
      pop
        /* "src/@aragon/os/contracts/common/VaultRecoverable.sol":1658:1757  function allowRecoverability(address token) public view returns (bool) {... */
      tag_115
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_241)
        /* "src/contracts/0.4.24/StETHPermit.sol":4524:4633  function nonces(address owner) external view returns (uint256) {... */
    tag_51:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_242
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_242:
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":4524:4633  function nonces(address owner) external view returns (uint256) {... */
      tag_96
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_244)
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":795:901  function appId() public view returns (bytes32) {... */
    tag_52:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_245
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_245:
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":795:901  function appId() public view returns (bytes32) {... */
      pop
      tag_96
      jump(tag_247)
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
    tag_53:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_248
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_248:
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
      pop
      tag_249
      jump(tag_250)
    tag_249:
      0x40
      dup1
      mload
      swap1
      dup2
      add
      dup4
      swap1
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      dup3
      and
      0x60
      dup3
      add
      mstore
      0x80
      dup1
      dup3
      mstore
      dup6
      mload
      swap1
      dup3
      add
      mstore
      dup5
      mload
      dup2
      swap1
      0x20
      dup1
      dup4
      add
      swap2
      0xa0
      dup5
      add
      swap2
      dup10
      add
      swap1
      dup1
      dup4
      dup4
      0x0
        /* "--CODEGEN--":8:108   */
    tag_251:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_252
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_251)
    tag_252:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_254
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_254:
      pop
      dup4
      dup2
      sub
      dup3
      mstore
      dup7
      mload
      dup2
      mstore
      dup7
      mload
      0x20
      swap2
      dup3
      add
      swap2
      dup9
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":8:108   */
    tag_255:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_256
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_255)
    tag_256:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_258
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_258:
      pop
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":41755:42353  function burnShares(uint256 _amountOfShares) external {... */
    tag_54:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_259
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_259:
      pop
        /* "src/contracts/0.4.24/Lido.sol":41755:42353  function burnShares(uint256 _amountOfShares) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_261)
        /* "src/contracts/0.4.24/Lido.sol":31228:31355  function getMaxMintableExternalShares() external view returns (uint256) {... */
    tag_55:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_262
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_262:
        /* "src/contracts/0.4.24/Lido.sol":31228:31355  function getMaxMintableExternalShares() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_264)
        /* "src/contracts/0.4.24/Lido.sol":28787:28924  function getWithdrawalsReserve() external view returns (uint256) {... */
    tag_56:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_265
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_265:
        /* "src/contracts/0.4.24/Lido.sol":28787:28924  function getWithdrawalsReserve() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_267)
        /* "src/contracts/0.4.24/utils/Versioned.sol":1385:1514  function getContractVersion() public view returns (uint256) {... */
    tag_57:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_268
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_268:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1385:1514  function getContractVersion() public view returns (uint256) {... */
      pop
      tag_96
      jump(tag_270)
        /* "src/@aragon/os/contracts/common/Initializable.sol":880:1017  function getInitializationBlock() public view returns (uint256) {... */
    tag_58:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_271
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_271:
        /* "src/@aragon/os/contracts/common/Initializable.sol":880:1017  function getInitializationBlock() public view returns (uint256) {... */
      pop
      tag_96
      jump(tag_273)
        /* "src/contracts/0.4.24/Lido.sol":13831:14489  function finalizeUpgrade_v4(uint256 _depositsReserveTarget) external {... */
    tag_59:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_274
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_274:
      pop
        /* "src/contracts/0.4.24/Lido.sol":13831:14489  function finalizeUpgrade_v4(uint256 _depositsReserveTarget) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_276)
        /* "src/contracts/0.4.24/StETH.sol":14578:14922  function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {... */
    tag_60:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_277
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_277:
      pop
        /* "src/contracts/0.4.24/StETH.sol":14578:14922  function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {... */
      tag_96
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_279)
        /* "src/contracts/0.4.24/Lido.sol":49291:51081  function collectRewardsAndProcessWithdrawals(... */
    tag_61:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_280
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_280:
      pop
        /* "src/contracts/0.4.24/Lido.sol":49291:51081  function collectRewardsAndProcessWithdrawals(... */
      tag_99
      calldataload(0x4)
      calldataload(0x24)
      calldataload(0x44)
      calldataload(0x64)
      calldataload(0x84)
      calldataload(0xa4)
      calldataload(0xc4)
      calldataload(0xe4)
      jump(tag_282)
        /* "src/contracts/0.4.24/StETH.sol":5708:5788  function symbol() external pure returns (string) {... */
    tag_62:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_283
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_283:
        /* "src/contracts/0.4.24/StETH.sol":5708:5788  function symbol() external pure returns (string) {... */
      pop
      tag_105
      jump(tag_285)
        /* "src/contracts/0.4.24/StETHPermit.sol":6337:6458  function getEIP712StETH() public view returns (address) {... */
    tag_63:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_290
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_290:
        /* "src/contracts/0.4.24/StETHPermit.sol":6337:6458  function getEIP712StETH() public view returns (address) {... */
      pop
      tag_153
      jump(tag_292)
        /* "src/contracts/0.4.24/Lido.sol":21531:21644  function getMaxExternalRatioBP() external view returns (uint256) {... */
    tag_64:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_293
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_293:
        /* "src/contracts/0.4.24/Lido.sol":21531:21644  function getMaxExternalRatioBP() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_295)
        /* "src/contracts/0.4.24/Lido.sol":53822:53944  function transferToVault(... */
    tag_65:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_296
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_296:
      pop
        /* "src/contracts/0.4.24/Lido.sol":53822:53944  function transferToVault(... */
      tag_99
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_298)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1640:2136  function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {... */
    tag_66:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_299
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_299:
      pop
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1640:2136  function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {... */
      0x40
      dup1
      mload
      0x20
      0x4
      calldataload(0x44)
      dup2
      dup2
      add
      calldataload
      dup4
      dup2
      mul
      dup1
      dup7
      add
      dup6
      add
      swap1
      swap7
      mstore
      dup1
      dup6
      mstore
      tag_115
      swap6
      dup4
      calldataload
      sub(exp(0x2, 0xa0), 0x1)
      and
      swap6
      0x24
      dup1
      calldataload
      swap7
      calldatasize
      swap7
      swap6
      0x64
      swap6
      swap4
      swap5
      swap3
      add
      swap3
      swap2
      dup3
      swap2
      dup6
      add
      swap1
      dup5
      swap1
      dup1
      dup3
      dup5
      calldatacopy
      pop
      swap5
      swap8
      pop
      tag_301
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump
        /* "src/contracts/0.4.24/Lido.sol":22940:23052  function submit(address _referral) external payable returns (uint256) {... */
    tag_67:
      tag_96
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_303)
        /* "src/contracts/0.4.24/StETH.sol":11280:11631  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {... */
    tag_68:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_304
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_304:
      pop
        /* "src/contracts/0.4.24/StETH.sol":11280:11631  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {... */
      tag_115
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_306)
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":979:1210  function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {... */
    tag_69:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_307
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_307:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":979:1210  function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {... */
      pop
      tag_153
      jump(tag_309)
        /* "src/ConversionHarness.sol":432:568  function transfer(address to,uint256 amount) external returns(bool) {... */
    tag_70:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_310
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_310:
      pop
        /* "src/ConversionHarness.sol":432:568  function transfer(address to,uint256 amount) external returns(bool) {... */
      tag_115
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      calldataload(0x24)
      jump(tag_312)
        /* "src/contracts/0.4.24/Lido.sol":32473:33248  function getBeaconStat()... */
    tag_71:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_313
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_313:
        /* "src/contracts/0.4.24/Lido.sol":32473:33248  function getBeaconStat()... */
      pop
      tag_314
      jump(tag_315)
    tag_314:
      0x40
      dup1
      mload
      swap4
      dup5
      mstore
      0x20
      dup5
      add
      swap3
      swap1
      swap3
      mstore
      dup3
      dup3
      add
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x60
      add
      swap1
      return
        /* "src/contracts/0.4.24/Lido.sol":18861:19137  function removeStakingLimit() external {... */
    tag_72:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_316
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_316:
        /* "src/contracts/0.4.24/Lido.sol":18861:19137  function removeStakingLimit() external {... */
      pop
      tag_99
      jump(tag_318)
        /* "src/contracts/0.4.24/Lido.sol":55187:55314  function getFee() external view returns (uint16 totalFee) {... */
    tag_73:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_319
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_319:
        /* "src/contracts/0.4.24/Lido.sol":55187:55314  function getFee() external view returns (uint16 totalFee) {... */
      pop
      tag_320
      jump(tag_321)
    tag_320:
      0x40
      dup1
      mload
      0xffff
      swap1
      swap3
      and
      dup3
      mstore
      mload
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      return
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":673:789  function kernel() public view returns (IKernel) {... */
    tag_74:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_322
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_322:
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":673:789  function kernel() public view returns (IKernel) {... */
      pop
      tag_153
      jump(tag_324)
        /* "src/contracts/0.4.24/StETH.sol":11886:11985  function getTotalShares() external view returns (uint256) {... */
    tag_75:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_325
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_325:
        /* "src/contracts/0.4.24/StETH.sol":11886:11985  function getTotalShares() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_327)
        /* "src/contracts/0.4.24/StETHPermit.sol":3614:4219  function permit(... */
    tag_76:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_328
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_328:
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":3614:4219  function permit(... */
      tag_99
      sub(exp(0x2, 0xa0), 0x1)
      calldataload(0x4)
      dup2
      and
      swap1
      calldataload(0x24)
      and
      calldataload(0x44)
      calldataload(0x64)
      and(calldataload(0x84), 0xff)
      calldataload(0xa4)
      calldataload(0xc4)
      jump(tag_330)
        /* "src/contracts/0.4.24/StETH.sol":7968:8103  function allowance(address _owner, address _spender) public view returns (uint256) {... */
    tag_77:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_331
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_331:
      pop
        /* "src/contracts/0.4.24/StETH.sol":7968:8103  function allowance(address _owner, address _spender) public view returns (uint256) {... */
      tag_96
      sub(exp(0x2, 0xa0), 0x1)
      calldataload(0x4)
      dup2
      and
      swap1
      calldataload(0x24)
      and
      jump(tag_333)
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":286:403  function isPetrified() public view returns (bool) {... */
    tag_78:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_334
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_334:
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":286:403  function isPetrified() public view returns (bool) {... */
      pop
      tag_115
      jump(tag_336)
        /* "src/contracts/0.4.24/Lido.sol":30771:30893  function getExternalEther() external view returns (uint256) {... */
    tag_79:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_337
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_337:
        /* "src/contracts/0.4.24/Lido.sol":30771:30893  function getExternalEther() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_339)
        /* "src/contracts/0.4.24/Lido.sol":31868:31972  function getLidoLocator() external view returns (ILidoLocator) {... */
    tag_80:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_340
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_340:
        /* "src/contracts/0.4.24/Lido.sol":31868:31972  function getLidoLocator() external view returns (ILidoLocator) {... */
      pop
      tag_153
      jump(tag_342)
        /* "src/contracts/0.4.24/Lido.sol":37595:37724  function canDeposit() public view returns (bool) {... */
    tag_81:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_343
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_343:
        /* "src/contracts/0.4.24/Lido.sol":37595:37724  function canDeposit() public view returns (bool) {... */
      pop
      tag_115
      jump(tag_345)
        /* "src/contracts/0.4.24/Lido.sol":4129:4240  bytes32 public constant STAKING_PAUSE_ROLE = 0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
    tag_82:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_346
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_346:
        /* "src/contracts/0.4.24/Lido.sol":4129:4240  bytes32 public constant STAKING_PAUSE_ROLE = 0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
      pop
      tag_96
      jump(tag_348)
        /* "src/contracts/0.4.24/Lido.sol":28109:28256  function getDepositsReserve() external view returns (uint256 depositsReserve) {... */
    tag_83:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_349
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_349:
        /* "src/contracts/0.4.24/Lido.sol":28109:28256  function getDepositsReserve() external view returns (uint256 depositsReserve) {... */
      pop
      tag_96
      jump(tag_351)
        /* "src/contracts/0.4.24/Lido.sol":37937:38075  function getDepositableEther() external view returns (uint256) {... */
    tag_84:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_352
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_352:
        /* "src/contracts/0.4.24/Lido.sol":37937:38075  function getDepositableEther() external view returns (uint256) {... */
      pop
      tag_96
      jump(tag_354)
        /* "src/contracts/0.4.24/Lido.sol":21837:22004  function setMaxExternalRatioBP(uint256 _maxExternalRatioBP) external {... */
    tag_85:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_355
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_355:
      pop
        /* "src/contracts/0.4.24/Lido.sol":21837:22004  function setMaxExternalRatioBP(uint256 _maxExternalRatioBP) external {... */
      tag_99
      calldataload(0x4)
      jump(tag_357)
        /* "src/contracts/0.4.24/StETH.sol":12064:12175  function sharesOf(address _account) external view returns (uint256) {... */
    tag_86:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_358
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_358:
      pop
        /* "src/contracts/0.4.24/StETH.sol":12064:12175  function sharesOf(address _account) external view returns (uint256) {... */
      tag_96
      and(calldataload(0x4), sub(exp(0x2, 0xa0), 0x1))
      jump(tag_360)
        /* "src/ConversionHarness.sol":348:373  address public controller */
    tag_87:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_361
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_361:
        /* "src/ConversionHarness.sol":348:373  address public controller */
      pop
      tag_153
      jump(tag_363)
        /* "src/contracts/0.4.24/Lido.sol":16535:16691  function pauseStaking() external {... */
    tag_88:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_364
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_364:
        /* "src/contracts/0.4.24/Lido.sol":16535:16691  function pauseStaking() external {... */
      pop
      tag_99
      jump(tag_366)
        /* "src/contracts/0.4.24/Lido.sol":31659:31806  function getTotalELRewardsCollected() public view returns (uint256) {... */
    tag_89:
      callvalue
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_367
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_367:
        /* "src/contracts/0.4.24/Lido.sol":31659:31806  function getTotalELRewardsCollected() public view returns (uint256) {... */
      pop
      tag_96
      jump(tag_369)
        /* "src/contracts/0.4.24/Lido.sol":57214:57705  function _submit(address _referral) internal returns (uint256) {... */
    tag_94:
        /* "src/contracts/0.4.24/Lido.sol":57268:57275  uint256 */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":57295:57304  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":57295:57309  msg.value != 0 */
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":57287:57326  require(msg.value != 0, "ZERO_DEPOSIT") */
      tag_371
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xc
      0x24
      dup3
      add
      mstore
      0x5a45524f5f4445504f5349540000000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_371:
        /* "src/contracts/0.4.24/Lido.sol":57337:57369  _decreaseStakingLimit(msg.value) */
      tag_372
        /* "src/contracts/0.4.24/Lido.sol":57359:57368  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":57337:57358  _decreaseStakingLimit */
      tag_373
        /* "src/contracts/0.4.24/Lido.sol":57337:57369  _decreaseStakingLimit(msg.value) */
      jump	// in
    tag_372:
        /* "src/contracts/0.4.24/Lido.sol":57403:57434  getSharesByPooledEth(msg.value) */
      tag_374
        /* "src/contracts/0.4.24/Lido.sol":57424:57433  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":57403:57423  getSharesByPooledEth */
      tag_139
        /* "src/contracts/0.4.24/Lido.sol":57403:57434  getSharesByPooledEth(msg.value) */
      jump	// in
    tag_374:
        /* "src/contracts/0.4.24/Lido.sol":57380:57434  uint256 sharesAmount = getSharesByPooledEth(msg.value) */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":57445:57482  _mintShares(msg.sender, sharesAmount) */
      tag_375
        /* "src/contracts/0.4.24/Lido.sol":57457:57467  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":57469:57481  sharesAmount */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":57445:57456  _mintShares */
      tag_376
        /* "src/contracts/0.4.24/Lido.sol":57445:57482  _mintShares(msg.sender, sharesAmount) */
      jump	// in
    tag_375:
      pop
        /* "src/contracts/0.4.24/Lido.sol":57493:57543  _setBufferedEther(_getBufferedEther() + msg.value) */
      tag_377
        /* "src/contracts/0.4.24/Lido.sol":57533:57542  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":57511:57530  _getBufferedEther() */
      tag_378
        /* "src/contracts/0.4.24/Lido.sol":57511:57528  _getBufferedEther */
      tag_379
        /* "src/contracts/0.4.24/Lido.sol":57511:57530  _getBufferedEther() */
      jump	// in
    tag_378:
        /* "src/contracts/0.4.24/Lido.sol":57511:57542  _getBufferedEther() + msg.value */
      add
        /* "src/contracts/0.4.24/Lido.sol":57493:57510  _setBufferedEther */
      tag_380
        /* "src/contracts/0.4.24/Lido.sol":57493:57543  _setBufferedEther(_getBufferedEther() + msg.value) */
      jump	// in
    tag_377:
        /* "src/contracts/0.4.24/Lido.sol":57558:57601  Submitted(msg.sender, msg.value, _referral) */
      0x40
      dup1
      mload
        /* "src/contracts/0.4.24/Lido.sol":57580:57589  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":57558:57601  Submitted(msg.sender, msg.value, _referral) */
      dup2
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      dup6
      and
      0x20
      dup3
      add
      mstore
      dup2
      mload
        /* "src/contracts/0.4.24/Lido.sol":57568:57578  msg.sender */
      caller
      swap3
        /* "src/contracts/0.4.24/Lido.sol":57558:57601  Submitted(msg.sender, msg.value, _referral) */
      0x96a25c8ce0baabc1fdefd93e9ed25d8e092a3332f3aa9a41722b5697231d1d1a
      swap3
      dup3
      swap1
      sub
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":57612:57669  _emitTransferAfterMintingShares(msg.sender, sharesAmount) */
      tag_381
        /* "src/contracts/0.4.24/Lido.sol":57644:57654  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":57656:57668  sharesAmount */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":57612:57643  _emitTransferAfterMintingShares */
      tag_382
        /* "src/contracts/0.4.24/Lido.sol":57612:57669  _emitTransferAfterMintingShares(msg.sender, sharesAmount) */
      jump	// in
    tag_381:
        /* "src/contracts/0.4.24/Lido.sol":57686:57698  sharesAmount */
      swap3
        /* "src/contracts/0.4.24/Lido.sol":57214:57705  function _submit(address _referral) internal returns (uint256) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":13645:14023  function getPooledEthBySharesRoundUp(uint256 _sharesAmount) public view returns (uint256) {... */
    tag_97:
        /* "src/contracts/0.4.24/StETH.sol":13726:13733  uint256 */
      0x0
      dup1
      dup1
        /* "src/contracts/0.4.24/StETH.sol":13769:13780  UINT128_MAX */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/StETH.sol":13753:13780  _sharesAmount < UINT128_MAX */
      dup5
      lt
        /* "src/contracts/0.4.24/StETH.sol":13745:13801  require(_sharesAmount < UINT128_MAX, "SHARES_TOO_LARGE") */
      tag_384
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x5348415245535f544f4f5f4c4152474500000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_384:
        /* "src/contracts/0.4.24/StETH.sol":13838:13862  _getShareRateNumerator() */
      tag_385
        /* "src/contracts/0.4.24/StETH.sol":13838:13860  _getShareRateNumerator */
      tag_386
        /* "src/contracts/0.4.24/StETH.sol":13838:13862  _getShareRateNumerator() */
      jump	// in
    tag_385:
        /* "src/contracts/0.4.24/StETH.sol":13811:13862  uint256 numeratorInEther = _getShareRateNumerator() */
      swap2
      pop
        /* "src/contracts/0.4.24/StETH.sol":13902:13928  _getShareRateDenominator() */
      tag_387
        /* "src/contracts/0.4.24/StETH.sol":13902:13926  _getShareRateDenominator */
      tag_388
        /* "src/contracts/0.4.24/StETH.sol":13902:13928  _getShareRateDenominator() */
      jump	// in
    tag_387:
        /* "src/contracts/0.4.24/StETH.sol":13872:13928  uint256 denominatorInShares = _getShareRateDenominator() */
      swap1
      pop
        /* "src/contracts/0.4.24/StETH.sol":13946:14016  Math256.ceilDiv(_sharesAmount * numeratorInEther, denominatorInShares) */
      tag_389
        /* "src/contracts/0.4.24/StETH.sol":13978:13994  numeratorInEther */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":13962:13975  _sharesAmount */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":13962:13994  _sharesAmount * numeratorInEther */
      mul
        /* "src/contracts/0.4.24/StETH.sol":13996:14015  denominatorInShares */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":13946:13961  Math256.ceilDiv */
      tag_390
        /* "src/contracts/0.4.24/StETH.sol":13946:14016  Math256.ceilDiv(_sharesAmount * numeratorInEther, denominatorInShares) */
      jump	// in
    tag_389:
        /* "src/contracts/0.4.24/StETH.sol":13939:14016  return Math256.ceilDiv(_sharesAmount * numeratorInEther, denominatorInShares) */
      swap5
        /* "src/contracts/0.4.24/StETH.sol":13645:14023  function getPooledEthBySharesRoundUp(uint256 _sharesAmount) public view returns (uint256) {... */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":24277:24385  function resume() external {... */
    tag_100:
        /* "src/contracts/0.4.24/Lido.sol":24314:24332  _auth(RESUME_ROLE) */
      tag_392
        /* "src/contracts/0.4.24/Lido.sol":4028:4094  0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
      0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7
        /* "src/contracts/0.4.24/Lido.sol":24314:24319  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":24314:24332  _auth(RESUME_ROLE) */
      jump	// in
    tag_392:
        /* "src/contracts/0.4.24/Lido.sol":24343:24352  _resume() */
      tag_394
        /* "src/contracts/0.4.24/Lido.sol":24343:24350  _resume */
      tag_395
        /* "src/contracts/0.4.24/Lido.sol":24343:24352  _resume() */
      jump	// in
    tag_394:
        /* "src/contracts/0.4.24/Lido.sol":24362:24378  _resumeStaking() */
      tag_396
        /* "src/contracts/0.4.24/Lido.sol":24362:24376  _resumeStaking */
      tag_397
        /* "src/contracts/0.4.24/Lido.sol":24362:24378  _resumeStaking() */
      jump	// in
    tag_396:
        /* "src/contracts/0.4.24/Lido.sol":24277:24385  function resume() external {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":42662:43306  function mintExternalShares(address _recipient, uint256 _amountOfShares) external {... */
    tag_103:
        /* "src/contracts/0.4.24/Lido.sol":42762:42782  _amountOfShares != 0 */
      dup1
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":42754:42813  require(_amountOfShares != 0, "MINT_ZERO_AMOUNT_OF_SHARES") */
      tag_399
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1a
      0x24
      dup3
      add
      mstore
      0x4d494e545f5a45524f5f414d4f554e545f4f465f534841524553000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_399:
        /* "src/contracts/0.4.24/Lido.sol":42823:42841  _auth(_vaultHub()) */
      tag_400
        /* "src/contracts/0.4.24/Lido.sol":42829:42840  _vaultHub() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":42829:42838  _vaultHub */
      tag_402
        /* "src/contracts/0.4.24/Lido.sol":42829:42840  _vaultHub() */
      jump	// in
    tag_401:
        /* "src/contracts/0.4.24/Lido.sol":42823:42828  _auth */
      tag_403
        /* "src/contracts/0.4.24/Lido.sol":42823:42841  _auth(_vaultHub()) */
      jump	// in
    tag_400:
        /* "src/contracts/0.4.24/Lido.sol":42851:42868  _whenNotStopped() */
      tag_404
        /* "src/contracts/0.4.24/Lido.sol":42851:42866  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":42851:42868  _whenNotStopped() */
      jump	// in
    tag_404:
        /* "src/contracts/0.4.24/Lido.sol":42906:42937  _getMaxMintableExternalShares() */
      tag_406
        /* "src/contracts/0.4.24/Lido.sol":42906:42935  _getMaxMintableExternalShares */
      tag_407
        /* "src/contracts/0.4.24/Lido.sol":42906:42937  _getMaxMintableExternalShares() */
      jump	// in
    tag_406:
        /* "src/contracts/0.4.24/Lido.sol":42887:42937  _amountOfShares <= _getMaxMintableExternalShares() */
      dup2
      gt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":42879:42973  require(_amountOfShares <= _getMaxMintableExternalShares(), "EXTERNAL_BALANCE_LIMIT_EXCEEDED") */
      tag_408
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1f
      0x24
      dup3
      add
      mstore
      0x45585445524e414c5f42414c414e43455f4c494d49545f455843454544454400
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_408:
        /* "src/contracts/0.4.24/Lido.sol":42984:43044  _decreaseStakingLimit(getPooledEthByShares(_amountOfShares)) */
      tag_409
        /* "src/contracts/0.4.24/Lido.sol":43006:43043  getPooledEthByShares(_amountOfShares) */
      tag_410
        /* "src/contracts/0.4.24/Lido.sol":43027:43042  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43006:43026  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/Lido.sol":43006:43043  getPooledEthByShares(_amountOfShares) */
      jump	// in
    tag_410:
        /* "src/contracts/0.4.24/Lido.sol":42984:43005  _decreaseStakingLimit */
      tag_373
        /* "src/contracts/0.4.24/Lido.sol":42984:43044  _decreaseStakingLimit(getPooledEthByShares(_amountOfShares)) */
      jump	// in
    tag_409:
        /* "src/contracts/0.4.24/Lido.sol":43055:43113  _setExternalShares(_getExternalShares() + _amountOfShares) */
      tag_411
        /* "src/contracts/0.4.24/Lido.sol":43097:43112  _amountOfShares */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":43074:43094  _getExternalShares() */
      tag_412
        /* "src/contracts/0.4.24/Lido.sol":43074:43092  _getExternalShares */
      tag_413
        /* "src/contracts/0.4.24/Lido.sol":43074:43094  _getExternalShares() */
      jump	// in
    tag_412:
        /* "src/contracts/0.4.24/Lido.sol":43074:43112  _getExternalShares() + _amountOfShares */
      add
        /* "src/contracts/0.4.24/Lido.sol":43055:43073  _setExternalShares */
      tag_414
        /* "src/contracts/0.4.24/Lido.sol":43055:43113  _setExternalShares(_getExternalShares() + _amountOfShares) */
      jump	// in
    tag_411:
        /* "src/contracts/0.4.24/Lido.sol":43123:43163  _mintShares(_recipient, _amountOfShares) */
      tag_415
        /* "src/contracts/0.4.24/Lido.sol":43135:43145  _recipient */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43147:43162  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43123:43134  _mintShares */
      tag_376
        /* "src/contracts/0.4.24/Lido.sol":43123:43163  _mintShares(_recipient, _amountOfShares) */
      jump	// in
    tag_415:
      pop
        /* "src/contracts/0.4.24/Lido.sol":43174:43234  _emitTransferAfterMintingShares(_recipient, _amountOfShares) */
      tag_416
        /* "src/contracts/0.4.24/Lido.sol":43206:43216  _recipient */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43218:43233  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43174:43205  _emitTransferAfterMintingShares */
      tag_382
        /* "src/contracts/0.4.24/Lido.sol":43174:43234  _emitTransferAfterMintingShares(_recipient, _amountOfShares) */
      jump	// in
    tag_416:
        /* "src/contracts/0.4.24/Lido.sol":43250:43299  ExternalSharesMinted(_recipient, _amountOfShares) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
      sub(exp(0x2, 0xa0), 0x1)
      dup5
      and
      swap2
      0xee473f96486a2f4b93ccb6729f121223e96975db6e0d6a5ef01f56477e3eab3b
      swap2
      swap1
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":42662:43306  function mintExternalShares(address _recipient, uint256 _amountOfShares) external {... */
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":5504:5600  function name() external pure returns (string) {... */
    tag_106:
        /* "src/contracts/0.4.24/StETH.sol":5561:5593  return "Liquid staked Ether 2.0" */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x17
      dup2
      mstore
      0x4c6971756964207374616b656420457468657220322e30000000000000000000
      0x20
      dup3
      add
      mstore
        /* "src/contracts/0.4.24/StETH.sol":5504:5600  function name() external pure returns (string) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":24019:24121  function stop() external {... */
    tag_113:
        /* "src/contracts/0.4.24/Lido.sol":24054:24071  _auth(PAUSE_ROLE) */
      tag_419
        /* "src/contracts/0.4.24/Lido.sol":3890:3956  0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
      0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
        /* "src/contracts/0.4.24/Lido.sol":24054:24059  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":24054:24071  _auth(PAUSE_ROLE) */
      jump	// in
    tag_419:
        /* "src/contracts/0.4.24/Lido.sol":24082:24089  _stop() */
      tag_420
        /* "src/contracts/0.4.24/Lido.sol":24082:24087  _stop */
      tag_421
        /* "src/contracts/0.4.24/Lido.sol":24082:24089  _stop() */
      jump	// in
    tag_420:
        /* "src/contracts/0.4.24/Lido.sol":24099:24114  _pauseStaking() */
      tag_396
        /* "src/contracts/0.4.24/Lido.sol":24099:24112  _pauseStaking */
      tag_423
        /* "src/contracts/0.4.24/Lido.sol":24099:24114  _pauseStaking() */
      jump	// in
        /* "src/@aragon/os/contracts/common/Initializable.sol":1127:1335  function hasInitialized() public view returns (bool) {... */
    tag_116:
        /* "src/@aragon/os/contracts/common/Initializable.sol":1174:1178  bool */
      0x0
        /* "src/@aragon/os/contracts/common/Initializable.sol":1190:1217  uint256 initializationBlock */
      dup1
        /* "src/@aragon/os/contracts/common/Initializable.sol":1220:1244  getInitializationBlock() */
      tag_425
        /* "src/@aragon/os/contracts/common/Initializable.sol":1220:1242  getInitializationBlock */
      tag_273
        /* "src/@aragon/os/contracts/common/Initializable.sol":1220:1244  getInitializationBlock() */
      jump	// in
    tag_425:
        /* "src/@aragon/os/contracts/common/Initializable.sol":1190:1244  uint256 initializationBlock = getInitializationBlock() */
      swap1
      pop
        /* "src/@aragon/os/contracts/common/Initializable.sol":1261:1285  initializationBlock != 0 */
      dup1
      iszero
      dup1
      iszero
      swap1
        /* "src/@aragon/os/contracts/common/Initializable.sol":1261:1328  initializationBlock != 0 && getBlockNumber() >= initializationBlock */
      tag_426
      jumpi
      pop
        /* "src/@aragon/os/contracts/common/Initializable.sol":1309:1328  initializationBlock */
      dup1
        /* "src/@aragon/os/contracts/common/Initializable.sol":1289:1305  getBlockNumber() */
      tag_427
        /* "src/@aragon/os/contracts/common/Initializable.sol":1289:1303  getBlockNumber */
      tag_428
        /* "src/@aragon/os/contracts/common/Initializable.sol":1289:1305  getBlockNumber() */
      jump	// in
    tag_427:
        /* "src/@aragon/os/contracts/common/Initializable.sol":1289:1328  getBlockNumber() >= initializationBlock */
      lt
      iszero
        /* "src/@aragon/os/contracts/common/Initializable.sol":1261:1328  initializationBlock != 0 && getBlockNumber() >= initializationBlock */
    tag_426:
        /* "src/@aragon/os/contracts/common/Initializable.sol":1254:1328  return initializationBlock != 0 && getBlockNumber() >= initializationBlock */
      swap2
      pop
        /* "src/@aragon/os/contracts/common/Initializable.sol":1127:1335  function hasInitialized() public view returns (bool) {... */
      pop
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":4437:4565  bytes32 public constant BUFFER_RESERVE_MANAGER_ROLE =... */
    tag_119:
        /* "src/contracts/0.4.24/Lido.sol":4499:4565  0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921 */
      0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921
        /* "src/contracts/0.4.24/Lido.sol":4437:4565  bytes32 public constant BUFFER_RESERVE_MANAGER_ROLE =... */
      dup2
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":8652:8805  function approve(address _spender, uint256 _amount) external returns (bool) {... */
    tag_122:
        /* "src/contracts/0.4.24/StETH.sol":8722:8726  bool */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":8738:8777  _approve(msg.sender, _spender, _amount) */
      tag_430
        /* "src/contracts/0.4.24/StETH.sol":8747:8757  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":8759:8767  _spender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":8769:8776  _amount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":8738:8746  _approve */
      tag_431
        /* "src/contracts/0.4.24/StETH.sol":8738:8777  _approve(msg.sender, _spender, _amount) */
      jump	// in
    tag_430:
      pop
        /* "src/contracts/0.4.24/StETH.sol":8794:8798  true */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":8652:8805  function approve(address _spender, uint256 _amount) external returns (bool) {... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":4281:4394  bytes32 public constant STAKING_CONTROL_ROLE = 0xa42eee1333c0758ba72be38e728b6dadb32ea767de5b4ddbaea1dae85b1b051f */
    tag_125:
      0x0
      dup1
      mload
      0x20
      data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      dup2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":29350:29542  function setDepositsReserveTarget(uint256 _newDepositsReserveTarget) external {... */
    tag_128:
        /* "src/contracts/0.4.24/Lido.sol":29438:29472  _auth(BUFFER_RESERVE_MANAGER_ROLE) */
      tag_433
        /* "src/contracts/0.4.24/Lido.sol":4499:4565  0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921 */
      0x33969636f1fbf3d7d062d4de4a08e7bd3c46606ec28b3a4398d2665be559b921
        /* "src/contracts/0.4.24/Lido.sol":29438:29443  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":29438:29472  _auth(BUFFER_RESERVE_MANAGER_ROLE) */
      jump	// in
    tag_433:
        /* "src/contracts/0.4.24/Lido.sol":29483:29535  _setDepositsReserveTarget(_newDepositsReserveTarget) */
      tag_434
        /* "src/contracts/0.4.24/Lido.sol":29509:29534  _newDepositsReserveTarget */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":29483:29508  _setDepositsReserveTarget */
      tag_435
        /* "src/contracts/0.4.24/Lido.sol":29483:29535  _setDepositsReserveTarget(_newDepositsReserveTarget) */
      jump	// in
    tag_434:
        /* "src/contracts/0.4.24/Lido.sol":29350:29542  function setDepositsReserveTarget(uint256 _newDepositsReserveTarget) external {... */
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":29078:29220  function getDepositsReserveTarget() public view returns (uint256) {... */
    tag_131:
        /* "src/contracts/0.4.24/Lido.sol":29135:29142  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":29161:29213  DEPOSITS_RESERVE_TARGET_POSITION.getStorageUint256() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":8965:9031  0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81 */
      0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81
        /* "src/contracts/0.4.24/Lido.sol":29161:29211  DEPOSITS_RESERVE_TARGET_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":29161:29213  DEPOSITS_RESERVE_TARGET_POSITION.getStorageUint256() */
      jump	// in
    tag_437:
        /* "src/contracts/0.4.24/Lido.sol":29154:29213  return DEPOSITS_RESERVE_TARGET_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":29078:29220  function getDepositsReserveTarget() public view returns (uint256) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":13059:13634  function initialize(address _lidoLocator, address _eip712StETH, uint256 _depositsReserveTarget) public payable onlyInit {... */
    tag_133:
        /* "src/contracts/0.4.24/Lido.sol":13412:13432  ILidoLocator locator */
      0x0
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
      tag_440
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:636  getInitializationBlock */
      tag_273
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
      jump	// in
    tag_440:
        /* "src/@aragon/os/contracts/common/Initializable.sol":645:670  ERROR_ALREADY_INITIALIZED */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x18
      dup2
      mstore
      0x494e49545f414c52454144595f494e495449414c495a45440000000000000000
      0x20
      dup3
      add
      mstore
      swap1
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:643  getInitializationBlock() == 0 */
      iszero
        /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
      tag_441
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x4
      add
      dup1
      dup1
      0x20
      add
      dup3
      dup2
      sub
      dup3
      mstore
      dup4
      dup2
      dup2
      mload
      dup2
      mstore
      0x20
      add
      swap2
      pop
      dup1
      mload
      swap1
      0x20
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":8:108   */
    tag_442:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_443
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_442)
    tag_443:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_445
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_445:
      pop
      swap3
      pop
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_441:
      pop
        /* "src/contracts/0.4.24/Lido.sol":13189:13214  _bootstrapInitialHolder() */
      tag_447
        /* "src/contracts/0.4.24/Lido.sol":13189:13212  _bootstrapInitialHolder */
      tag_448
        /* "src/contracts/0.4.24/Lido.sol":13189:13214  _bootstrapInitialHolder() */
      jump	// in
    tag_447:
        /* "src/contracts/0.4.24/Lido.sol":13250:13279  _setLidoLocator(_lidoLocator) */
      tag_449
        /* "src/contracts/0.4.24/Lido.sol":13266:13278  _lidoLocator */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":13250:13265  _setLidoLocator */
      tag_450
        /* "src/contracts/0.4.24/Lido.sol":13250:13279  _setLidoLocator(_lidoLocator) */
      jump	// in
    tag_449:
        /* "src/contracts/0.4.24/Lido.sol":13294:13322  LidoLocatorSet(_lidoLocator) */
      0x40
      dup1
      mload
      sub(exp(0x2, 0xa0), 0x1)
      dup7
      and
      dup2
      mstore
      swap1
      mload
      0x61f9416d3c29deb4e424342445a2b132738430becd9fa275e11297c90668b22e
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":13332:13368  _initializeEIP712StETH(_eip712StETH) */
      tag_451
        /* "src/contracts/0.4.24/Lido.sol":13355:13367  _eip712StETH */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":13332:13354  _initializeEIP712StETH */
      tag_452
        /* "src/contracts/0.4.24/Lido.sol":13332:13368  _initializeEIP712StETH(_eip712StETH) */
      jump	// in
    tag_451:
        /* "src/contracts/0.4.24/Lido.sol":13379:13401  _setContractVersion(4) */
      tag_453
        /* "src/contracts/0.4.24/Lido.sol":13399:13400  4 */
      0x4
        /* "src/contracts/0.4.24/Lido.sol":13379:13398  _setContractVersion */
      tag_454
        /* "src/contracts/0.4.24/Lido.sol":13379:13401  _setContractVersion(4) */
      jump	// in
    tag_453:
      pop
        /* "src/contracts/0.4.24/Lido.sol":13448:13460  _lidoLocator */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":13472:13545  _approve(_withdrawalQueue(locator), _burner(locator), INFINITE_ALLOWANCE) */
      tag_455
        /* "src/contracts/0.4.24/Lido.sol":13481:13506  _withdrawalQueue(locator) */
      tag_456
        /* "src/contracts/0.4.24/Lido.sol":13448:13460  _lidoLocator */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":13481:13497  _withdrawalQueue */
      tag_457
        /* "src/contracts/0.4.24/Lido.sol":13481:13506  _withdrawalQueue(locator) */
      jump	// in
    tag_456:
        /* "src/contracts/0.4.24/Lido.sol":13508:13524  _burner(locator) */
      tag_458
        /* "src/contracts/0.4.24/Lido.sol":13516:13523  locator */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":13508:13515  _burner */
      tag_459
        /* "src/contracts/0.4.24/Lido.sol":13508:13524  _burner(locator) */
      jump	// in
    tag_458:
      not(0x0)
        /* "src/contracts/0.4.24/Lido.sol":13472:13480  _approve */
      tag_431
        /* "src/contracts/0.4.24/Lido.sol":13472:13545  _approve(_withdrawalQueue(locator), _burner(locator), INFINITE_ALLOWANCE) */
      jump	// in
    tag_455:
        /* "src/contracts/0.4.24/Lido.sol":13555:13604  _setDepositsReserveTarget(_depositsReserveTarget) */
      tag_460
        /* "src/contracts/0.4.24/Lido.sol":13581:13603  _depositsReserveTarget */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":13555:13580  _setDepositsReserveTarget */
      tag_435
        /* "src/contracts/0.4.24/Lido.sol":13555:13604  _setDepositsReserveTarget(_depositsReserveTarget) */
      jump	// in
    tag_460:
        /* "src/contracts/0.4.24/Lido.sol":13614:13627  initialized() */
      tag_461
        /* "src/contracts/0.4.24/Lido.sol":13614:13625  initialized */
      tag_462
        /* "src/contracts/0.4.24/Lido.sol":13614:13627  initialized() */
      jump	// in
    tag_461:
        /* "src/contracts/0.4.24/Lido.sol":13059:13634  function initialize(address _lidoLocator, address _eip712StETH, uint256 _depositsReserveTarget) public payable onlyInit {... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":6201:6302  function totalSupply() external view returns (uint256) {... */
    tag_136:
        /* "src/contracts/0.4.24/StETH.sol":6247:6254  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":6273:6295  _getTotalPooledEther() */
      tag_437
        /* "src/contracts/0.4.24/StETH.sol":6273:6293  _getTotalPooledEther */
      tag_465
        /* "src/contracts/0.4.24/StETH.sol":6273:6295  _getTotalPooledEther() */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":12431:12734  function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {... */
    tag_139:
        /* "src/contracts/0.4.24/StETH.sol":12502:12509  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":12542:12553  UINT128_MAX */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/StETH.sol":12529:12553  _ethAmount < UINT128_MAX */
      dup3
      lt
        /* "src/contracts/0.4.24/StETH.sol":12521:12571  require(_ethAmount < UINT128_MAX, "ETH_TOO_LARGE") */
      tag_467
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xd
      0x24
      dup3
      add
      mstore
      0x4554485f544f4f5f4c4152474500000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_467:
        /* "src/contracts/0.4.24/StETH.sol":12681:12705  _getShareRateNumerator() */
      tag_468
        /* "src/contracts/0.4.24/StETH.sol":12681:12703  _getShareRateNumerator */
      tag_386
        /* "src/contracts/0.4.24/StETH.sol":12681:12705  _getShareRateNumerator() */
      jump	// in
    tag_468:
        /* "src/contracts/0.4.24/StETH.sol":12614:12640  _getShareRateDenominator() */
      tag_469
        /* "src/contracts/0.4.24/StETH.sol":12614:12638  _getShareRateDenominator */
      tag_388
        /* "src/contracts/0.4.24/StETH.sol":12614:12640  _getShareRateDenominator() */
      jump	// in
    tag_469:
        /* "src/contracts/0.4.24/StETH.sol":12589:12599  _ethAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":12589:12640  _ethAmount... */
      mul
        /* "src/contracts/0.4.24/StETH.sol":12588:12705  (_ethAmount... */
      dup2
      iszero
      iszero
      tag_470
      jumpi
      invalid
    tag_470:
      div
        /* "src/contracts/0.4.24/StETH.sol":12581:12705  return (_ethAmount... */
      swap1
      pop
        /* "src/contracts/0.4.24/StETH.sol":12431:12734  function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {... */
    tag_466:
      swap2
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":52980:53726  function emitTokenRebase(... */
    tag_142:
        /* "src/contracts/0.4.24/Lido.sol":53336:53356  _auth(_accounting()) */
      tag_472
        /* "src/contracts/0.4.24/Lido.sol":53342:53355  _accounting() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":53342:53353  _accounting */
      tag_474
        /* "src/contracts/0.4.24/Lido.sol":53342:53355  _accounting() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":53336:53356  _auth(_accounting()) */
    tag_472:
        /* "src/contracts/0.4.24/Lido.sol":53372:53599  TokenRebased(... */
      0x40
      dup1
      mload
      dup10
      dup2
      mstore
      0x20
      dup2
      add
      dup10
      swap1
      mstore
      dup1
      dup3
      add
      dup9
      swap1
      mstore
      0x60
      dup2
      add
      dup8
      swap1
      mstore
      0x80
      dup2
      add
      dup7
      swap1
      mstore
      0xa0
      dup2
      add
      dup4
      swap1
      mstore
      swap1
      mload
        /* "src/contracts/0.4.24/Lido.sol":53398:53414  _reportTimestamp */
      dup11
      swap2
        /* "src/contracts/0.4.24/Lido.sol":53372:53599  TokenRebased(... */
      0xff08c3ef606d198e316ef5b822193c489965899eb4e3c248cea1a4626c3eda50
      swap2
      swap1
      dup2
      swap1
      sub
      0xc0
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":53615:53719  InternalShareRateUpdated(_reportTimestamp, _postInternalShares, _postInternalEther, _sharesMintedAsFees) */
      0x40
      dup1
      mload
      dup5
      dup2
      mstore
      0x20
      dup2
      add
      dup5
      swap1
      mstore
      dup1
      dup3
      add
      dup4
      swap1
      mstore
      swap1
      mload
        /* "src/contracts/0.4.24/Lido.sol":53640:53656  _reportTimestamp */
      dup11
      swap2
        /* "src/contracts/0.4.24/Lido.sol":53615:53719  InternalShareRateUpdated(_reportTimestamp, _postInternalShares, _postInternalEther, _sharesMintedAsFees) */
      0xaf00d86be4cd299db16aa59803992e174fa88b67d81a0c7dd0148f9a75606a8d
      swap2
      swap1
      dup2
      swap1
      sub
      0x60
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":52980:53726  function emitTokenRebase(... */
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":19222:19369  function isStakingPaused() public view returns (bool) {... */
    tag_145:
        /* "src/contracts/0.4.24/Lido.sol":19270:19274  bool */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":19293:19362  STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":19293:19344  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_477
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":19293:19342  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":19293:19344  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_477:
        /* "src/contracts/0.4.24/Lido.sol":19293:19360  STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused */
      tag_479
        /* "src/contracts/0.4.24/Lido.sol":19293:19362  STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":40309:41111  function withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount) external {... */
    tag_148:
        /* "src/contracts/0.4.24/Lido.sol":40457:40485  IStakingRouter stakingRouter */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":40684:40712  uint256 newSeedDepositsCount */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":40415:40427  canDeposit() */
      tag_481
        /* "src/contracts/0.4.24/Lido.sol":40415:40425  canDeposit */
      tag_345
        /* "src/contracts/0.4.24/Lido.sol":40415:40427  canDeposit() */
      jump	// in
    tag_481:
        /* "src/contracts/0.4.24/Lido.sol":40407:40447  require(canDeposit(), "CAN_NOT_DEPOSIT") */
      iszero
      iszero
      tag_482
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x43414e5f4e4f545f4445504f5349540000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_482:
        /* "src/contracts/0.4.24/Lido.sol":40488:40504  _stakingRouter() */
      tag_483
        /* "src/contracts/0.4.24/Lido.sol":40488:40502  _stakingRouter */
      tag_484
        /* "src/contracts/0.4.24/Lido.sol":40488:40504  _stakingRouter() */
      jump	// in
    tag_483:
        /* "src/contracts/0.4.24/Lido.sol":40457:40504  IStakingRouter stakingRouter = _stakingRouter() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":40514:40543  _auth(address(stakingRouter)) */
      tag_485
        /* "src/contracts/0.4.24/Lido.sol":40528:40541  stakingRouter */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":40514:40519  _auth */
      tag_403
        /* "src/contracts/0.4.24/Lido.sol":40514:40543  _auth(address(stakingRouter)) */
      jump	// in
    tag_485:
        /* "src/contracts/0.4.24/Lido.sol":40561:40573  _amount != 0 */
      dup4
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":40553:40589  require(_amount != 0, "ZERO_AMOUNT") */
      tag_486
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xb
      0x24
      dup3
      add
      mstore
      0x5a45524f5f414d4f554e54000000000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_486:
        /* "src/contracts/0.4.24/Lido.sol":40600:40631  _spendDepositableEther(_amount) */
      tag_487
        /* "src/contracts/0.4.24/Lido.sol":40623:40630  _amount */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":40600:40622  _spendDepositableEther */
      tag_488
        /* "src/contracts/0.4.24/Lido.sol":40600:40631  _spendDepositableEther(_amount) */
      jump	// in
    tag_487:
        /* "src/contracts/0.4.24/Lido.sol":40667:40668  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":40646:40664  _seedDepositsCount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":40646:40668  _seedDepositsCount > 0 */
      gt
        /* "src/contracts/0.4.24/Lido.sol":40642:40964  if (_seedDepositsCount > 0) {... */
      iszero
      tag_489
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":40715:40762  _getSeedDepositsCount().add(_seedDepositsCount) */
      tag_490
        /* "src/contracts/0.4.24/Lido.sol":40743:40761  _seedDepositsCount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":40715:40738  _getSeedDepositsCount() */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":40715:40736  _getSeedDepositsCount */
      tag_492
        /* "src/contracts/0.4.24/Lido.sol":40715:40738  _getSeedDepositsCount() */
      jump	// in
    tag_491:
        /* "src/contracts/0.4.24/Lido.sol":40715:40742  _getSeedDepositsCount().add */
      swap1
        /* "src/contracts/0.4.24/Lido.sol":40715:40762  _getSeedDepositsCount().add(_seedDepositsCount) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":40715:40742  _getSeedDepositsCount().add */
      tag_493
        /* "src/contracts/0.4.24/Lido.sol":40715:40762  _getSeedDepositsCount().add(_seedDepositsCount) */
      and
      jump	// in
    tag_490:
        /* "src/contracts/0.4.24/Lido.sol":40684:40762  uint256 newSeedDepositsCount = _getSeedDepositsCount().add(_seedDepositsCount) */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":40776:40819  _setSeedDepositsCount(newSeedDepositsCount) */
      tag_494
        /* "src/contracts/0.4.24/Lido.sol":40798:40818  newSeedDepositsCount */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":40776:40797  _setSeedDepositsCount */
      tag_495
        /* "src/contracts/0.4.24/Lido.sol":40776:40819  _setSeedDepositsCount(newSeedDepositsCount) */
      jump	// in
    tag_494:
        /* "src/contracts/0.4.24/Lido.sol":40905:40953  DepositedValidatorsChanged(newSeedDepositsCount) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
      0xe0aacfc334457703148118055ec794ac17654c6f918d29638ba3b18003cee5ff
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":40642:40964  if (_seedDepositsCount > 0) {... */
    tag_489:
        /* "src/contracts/0.4.24/Lido.sol":41050:41063  stakingRouter */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":41050:41087  stakingRouter.receiveDepositableEther */
      and
      0x13ae8460
        /* "src/contracts/0.4.24/Lido.sol":41094:41101  _amount */
      dup6
        /* "src/contracts/0.4.24/Lido.sol":41050:41104  stakingRouter.receiveDepositableEther.value(_amount)() */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x0
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup6
      dup9
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_496
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_496:
        /* "src/contracts/0.4.24/Lido.sol":41050:41104  stakingRouter.receiveDepositableEther.value(_amount)() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_497
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_497:
        /* "src/contracts/0.4.24/Lido.sol":41050:41104  stakingRouter.receiveDepositableEther.value(_amount)() */
      pop
      pop
      pop
      pop
      pop
        /* "src/contracts/0.4.24/Lido.sol":40309:41111  function withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount) external {... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":9671:9903  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {... */
    tag_151:
        /* "src/contracts/0.4.24/StETH.sol":9765:9769  bool */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":9781:9826  _spendAllowance(_sender, msg.sender, _amount) */
      tag_499
        /* "src/contracts/0.4.24/StETH.sol":9797:9804  _sender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":9806:9816  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":9818:9825  _amount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":9781:9796  _spendAllowance */
      tag_500
        /* "src/contracts/0.4.24/StETH.sol":9781:9826  _spendAllowance(_sender, msg.sender, _amount) */
      jump	// in
    tag_499:
        /* "src/contracts/0.4.24/StETH.sol":9836:9875  _transfer(_sender, _recipient, _amount) */
      tag_501
        /* "src/contracts/0.4.24/StETH.sol":9846:9853  _sender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":9855:9865  _recipient */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":9867:9874  _amount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":9836:9845  _transfer */
      tag_502
        /* "src/contracts/0.4.24/StETH.sol":9836:9875  _transfer(_sender, _recipient, _amount) */
      jump	// in
    tag_501:
      pop
        /* "src/contracts/0.4.24/StETH.sol":9892:9896  true */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":9671:9903  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {... */
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":794:973  function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {... */
    tag_154:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":860:878  IEVMScriptExecutor */
      0x0
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:938  getEVMScriptRegistry() */
      tag_504
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:936  getEVMScriptRegistry */
      tag_309
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:938  getEVMScriptRegistry() */
      jump	// in
    tag_504:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:956  getEVMScriptRegistry().getScriptExecutor */
      and
      0x4bf2a7f
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":957:964  _script */
      dup4
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:965  getEVMScriptRegistry().getScriptExecutor(_script) */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup1
      0x20
      add
      dup3
      dup2
      sub
      dup3
      mstore
      dup4
      dup2
      dup2
      mload
      dup2
      mstore
      0x20
      add
      swap2
      pop
      dup1
      mload
      swap1
      0x20
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":8:108   */
    tag_505:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_506
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_505)
    tag_506:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:965  getEVMScriptRegistry().getScriptExecutor(_script) */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_508
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_508:
      pop
      swap3
      pop
      pop
      pop
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_509:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:965  getEVMScriptRegistry().getScriptExecutor(_script) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_510
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_510:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:965  getEVMScriptRegistry().getScriptExecutor(_script) */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_511
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_511:
      pop
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":916:965  getEVMScriptRegistry().getScriptExecutor(_script) */
      mload
      swap3
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":794:973  function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":18285:18794  function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external {... */
    tag_157:
        /* "src/contracts/0.4.24/Lido.sol":18390:18417  _auth(STAKING_CONTROL_ROLE) */
      tag_513
      0x0
      dup1
      mload
      0x20
      data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":18390:18395  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":18390:18417  _auth(STAKING_CONTROL_ROLE) */
      jump	// in
    tag_513:
        /* "src/contracts/0.4.24/Lido.sol":18454:18468  uint96(-1) / 2 */
      0x7fffffffffffffffffffffff
        /* "src/contracts/0.4.24/Lido.sol":18436:18468  _maxStakeLimit <= uint96(-1) / 2 */
      dup3
      gt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":18428:18498  require(_maxStakeLimit <= uint96(-1) / 2, "TOO_LARGE_MAX_STAKE_LIMIT") */
      tag_515
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x19
      0x24
      dup3
      add
      mstore
      0x544f4f5f4c415247455f4d41585f5354414b455f4c494d495400000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_515:
        /* "src/contracts/0.4.24/Lido.sol":18509:18711  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      tag_516
        /* "src/contracts/0.4.24/Lido.sol":18572:18701  STAKING_STATE_POSITION.getStorageStakeLimitStruct()... */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":18657:18671  _maxStakeLimit */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":18673:18700  _stakeLimitIncreasePerBlock */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":18572:18623  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_518
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":18572:18621  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":18572:18623  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_518:
        /* "src/contracts/0.4.24/Lido.sol":18572:18656  STAKING_STATE_POSITION.getStorageStakeLimitStruct()... */
      swap2
        /* "src/contracts/0.4.24/Lido.sol":18572:18701  STAKING_STATE_POSITION.getStorageStakeLimitStruct()... */
      swap1
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":18572:18656  STAKING_STATE_POSITION.getStorageStakeLimitStruct()... */
      tag_519
        /* "src/contracts/0.4.24/Lido.sol":18572:18701  STAKING_STATE_POSITION.getStorageStakeLimitStruct()... */
      and
      jump	// in
    tag_517:
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":7617:7683  0xa3678de4a579be090bed1177e0a24f77cc29d181ac22fd7688aca344d8938015 */
      swap1
        /* "src/contracts/0.4.24/Lido.sol":18509:18711  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":18509:18558  STAKING_STATE_POSITION.setStorageStakeLimitStruct */
      tag_520
        /* "src/contracts/0.4.24/Lido.sol":18509:18711  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      and
      jump	// in
    tag_516:
        /* "src/contracts/0.4.24/Lido.sol":18727:18787  StakingLimitSet(_maxStakeLimit, _stakeLimitIncreasePerBlock) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      0x20
      dup2
      add
      dup4
      swap1
      mstore
      dup2
      mload
      0xce9fddf6179affa1ea7bf36d80a6bf0284e0f3b91f4b2fa6eea2af923e7fac2d
      swap3
      swap2
      dup2
      swap1
      sub
      swap1
      swap2
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":18285:18794  function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external {... */
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":3990:4094  bytes32 public constant RESUME_ROLE = 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
    tag_160:
        /* "src/contracts/0.4.24/Lido.sol":4028:4094  0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
      0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7
        /* "src/contracts/0.4.24/Lido.sol":3990:4094  bytes32 public constant RESUME_ROLE = 0x2fc10cc8ae19568712f7a176fb4978616a610650813c9d05326c34abb62749c7 */
      dup2
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":5899:5975  function decimals() external pure returns (uint8) {... */
    tag_163:
        /* "src/contracts/0.4.24/StETH.sol":5966:5968  18 */
      0x12
        /* "src/contracts/0.4.24/StETH.sol":5899:5975  function decimals() external pure returns (uint8) {... */
      swap1
      jump	// out
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2252:2481  function getRecoveryVault() public view returns (address) {... */
    tag_166:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2301:2308  address */
      0x0
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2415  kernel() */
      tag_523
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2413  kernel */
      tag_324
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2415  kernel() */
      jump	// in
    tag_523:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2432  kernel().getRecoveryVault */
      and
      0x32f0a3b5
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2434  kernel().getRecoveryVault() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_524:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2434  kernel().getRecoveryVault() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_525
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_525:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2434  kernel().getRecoveryVault() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_526
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_526:
      pop
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2407:2434  kernel().getRecoveryVault() */
      mload
      swap1
      pop
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2252:2481  function getRecoveryVault() public view returns (address) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/StETHPermit.sol":4825:4972  function DOMAIN_SEPARATOR() external view returns (bytes32) {... */
    tag_169:
        /* "src/contracts/0.4.24/StETHPermit.sol":4876:4883  bytes32 */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":4915:4931  getEIP712StETH() */
      tag_528
        /* "src/contracts/0.4.24/StETHPermit.sol":4915:4929  getEIP712StETH */
      tag_292
        /* "src/contracts/0.4.24/StETHPermit.sol":4915:4931  getEIP712StETH() */
      jump	// in
    tag_528:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":4902:4950  IEIP712StETH(getEIP712StETH()).domainSeparatorV4 */
      and
      0xb8f120b3
        /* "src/contracts/0.4.24/StETHPermit.sol":4959:4963  this */
      address
        /* "src/contracts/0.4.24/StETHPermit.sol":4902:4965  IEIP712StETH(getEIP712StETH()).domainSeparatorV4(address(this)) */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup3
      sub(exp(0x2, 0xa0), 0x1)
      and
      sub(exp(0x2, 0xa0), 0x1)
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":3853:3956  bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
    tag_175:
        /* "src/contracts/0.4.24/Lido.sol":3890:3956  0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
      0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d
        /* "src/contracts/0.4.24/Lido.sol":3853:3956  bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d */
      dup2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":33764:34518  function getBalanceStats()... */
    tag_178:
        /* "src/contracts/0.4.24/Lido.sol":33851:33890  uint256 clValidatorsBalanceAtLastReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":33904:33940  uint256 clPendingBalanceAtLastReport */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":33954:33986  uint256 depositedSinceLastReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":34000:34033  uint256 depositedForCurrentReport */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":34124:34168  _getClValidatorsBalanceAndClPendingBalance() */
      tag_535
        /* "src/contracts/0.4.24/Lido.sol":34124:34166  _getClValidatorsBalanceAndClPendingBalance */
      tag_536
        /* "src/contracts/0.4.24/Lido.sol":34124:34168  _getClValidatorsBalanceAndClPendingBalance() */
      jump	// in
    tag_535:
        /* "src/contracts/0.4.24/Lido.sol":34058:34168  (clValidatorsBalanceAtLastReport, clPendingBalanceAtLastReport) = _getClValidatorsBalanceAndClPendingBalance() */
      swap1
      swap5
      pop
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":34206:34231  _getDepositedPostReport() */
      tag_537
        /* "src/contracts/0.4.24/Lido.sol":34206:34229  _getDepositedPostReport */
      tag_538
        /* "src/contracts/0.4.24/Lido.sol":34206:34231  _getDepositedPostReport() */
      jump	// in
    tag_537:
        /* "src/contracts/0.4.24/Lido.sol":34179:34231  depositedSinceLastReport = _getDepositedPostReport() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":34272:34305  _getDepositedNextReportAdjusted() */
      tag_539
        /* "src/contracts/0.4.24/Lido.sol":34272:34303  _getDepositedNextReportAdjusted */
      tag_540
        /* "src/contracts/0.4.24/Lido.sol":34272:34305  _getDepositedNextReportAdjusted() */
      jump	// in
    tag_539:
      pop
        /* "src/contracts/0.4.24/Lido.sol":33764:34518  function getBalanceStats()... */
      swap4
      swap5
      swap3
      swap4
        /* "src/contracts/0.4.24/Lido.sol":34459:34483  depositedSinceLastReport */
      swap2
      swap3
        /* "src/contracts/0.4.24/Lido.sol":34459:34511  depositedSinceLastReport - depositedForCurrentReport */
      swap2
      dup4
      sub
      swap2
        /* "src/contracts/0.4.24/Lido.sol":33764:34518  function getBalanceStats()... */
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":10441:10650  function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {... */
    tag_181:
        /* "src/contracts/0.4.24/StETH.sol":10550:10560  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":10525:10529  bool */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":10572:10594  allowances[msg.sender] */
      dup2
      dup2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":10572:10582  allowances */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":10572:10594  allowances[msg.sender] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":10572:10604  allowances[msg.sender][_spender] */
      dup8
      and
      dup5
      mstore
      swap1
      swap2
      mstore
      dup2
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":10525:10529  bool */
      swap1
      swap2
        /* "src/contracts/0.4.24/StETH.sol":10541:10622  _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue)) */
      tag_430
      swap2
        /* "src/contracts/0.4.24/StETH.sol":10562:10570  _spender */
      dup6
      swap1
        /* "src/contracts/0.4.24/StETH.sol":10572:10621  allowances[msg.sender][_spender].add(_addedValue) */
      tag_543
      swap1
        /* "src/contracts/0.4.24/StETH.sol":10609:10620  _addedValue */
      dup7
        /* "src/contracts/0.4.24/StETH.sol":10572:10621  allowances[msg.sender][_spender].add(_addedValue) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":10572:10608  allowances[msg.sender][_spender].add */
      tag_493
        /* "src/contracts/0.4.24/StETH.sol":10572:10621  allowances[msg.sender][_spender].add(_addedValue) */
      and
      jump	// in
    tag_543:
        /* "src/contracts/0.4.24/StETH.sol":10541:10549  _approve */
      tag_431
        /* "src/contracts/0.4.24/StETH.sol":10541:10622  _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue)) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":54646:54753  function getTreasury() external view returns (address) {... */
    tag_184:
        /* "src/contracts/0.4.24/Lido.sol":54692:54699  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":54718:54735  _getLidoLocator() */
      tag_545
        /* "src/contracts/0.4.24/Lido.sol":54718:54733  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":54718:54735  _getLidoLocator() */
      jump	// in
    tag_545:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":54718:54744  _getLidoLocator().treasury */
      and
      0x61d027b3
        /* "src/contracts/0.4.24/Lido.sol":54718:54746  _getLidoLocator().treasury() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/utils/Pausable.sol":753:863  function isStopped() public view returns (bool) {... */
    tag_187:
        /* "src/contracts/0.4.24/utils/Pausable.sol":795:799  bool */
      0x0
        /* "src/contracts/0.4.24/utils/Pausable.sol":819:856  ACTIVE_FLAG_POSITION.getStorageBool() */
      tag_551
      0x0
      dup1
      mload
      0x20
      data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/utils/Pausable.sol":819:854  ACTIVE_FLAG_POSITION.getStorageBool */
      tag_438
        /* "src/contracts/0.4.24/utils/Pausable.sol":819:856  ACTIVE_FLAG_POSITION.getStorageBool() */
      jump	// in
    tag_551:
        /* "src/contracts/0.4.24/utils/Pausable.sol":818:856  !ACTIVE_FLAG_POSITION.getStorageBool() */
      iszero
        /* "src/contracts/0.4.24/utils/Pausable.sol":811:856  return !ACTIVE_FLAG_POSITION.getStorageBool() */
      swap1
      pop
        /* "src/contracts/0.4.24/utils/Pausable.sol":753:863  function isStopped() public view returns (bool) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":24709:24812  function getBufferedEther() external view returns (uint256) {... */
    tag_190:
        /* "src/contracts/0.4.24/Lido.sol":24760:24767  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":24786:24805  _getBufferedEther() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":24786:24803  _getBufferedEther */
      tag_379
        /* "src/contracts/0.4.24/Lido.sol":24786:24805  _getBufferedEther() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":23321:23560  function receiveELRewards() external payable {... */
    tag_192:
        /* "src/contracts/0.4.24/Lido.sol":23376:23400  _auth(_elRewardsVault()) */
      tag_556
        /* "src/contracts/0.4.24/Lido.sol":23382:23399  _elRewardsVault() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":23382:23397  _elRewardsVault */
      tag_558
        /* "src/contracts/0.4.24/Lido.sol":23382:23399  _elRewardsVault() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":23376:23400  _auth(_elRewardsVault()) */
    tag_556:
        /* "src/contracts/0.4.24/Lido.sol":23411:23509  TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256(getTotalELRewardsCollected().add(msg.value)) */
      tag_559
        /* "src/contracts/0.4.24/Lido.sol":23465:23508  getTotalELRewardsCollected().add(msg.value) */
      tag_560
        /* "src/contracts/0.4.24/Lido.sol":23498:23507  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":23465:23493  getTotalELRewardsCollected() */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":23465:23491  getTotalELRewardsCollected */
      tag_369
        /* "src/contracts/0.4.24/Lido.sol":23465:23493  getTotalELRewardsCollected() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":23465:23508  getTotalELRewardsCollected().add(msg.value) */
    tag_560:
        /* "src/contracts/0.4.24/Lido.sol":7928:7994  0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb */
      0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb
      swap1
        /* "src/contracts/0.4.24/Lido.sol":23411:23509  TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256(getTotalELRewardsCollected().add(msg.value)) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":23411:23464  TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/Lido.sol":23411:23509  TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256(getTotalELRewardsCollected().add(msg.value)) */
      and
      jump	// in
    tag_559:
        /* "src/contracts/0.4.24/Lido.sol":23525:23553  ELRewardsReceived(msg.value) */
      0x40
      dup1
      mload
        /* "src/contracts/0.4.24/Lido.sol":23543:23552  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":23525:23553  ELRewardsReceived(msg.value) */
      dup2
      mstore
      swap1
      mload
      0xd27f9b0c98bdee27044afa149eadcd2047d6399cb6613a45c5b87e6aca76e6b5
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":23321:23560  function receiveELRewards() external payable {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":41315:41574  function mintShares(address _recipient, uint256 _amountOfShares) external {... */
    tag_195:
        /* "src/contracts/0.4.24/Lido.sol":41399:41419  _auth(_accounting()) */
      tag_564
        /* "src/contracts/0.4.24/Lido.sol":41405:41418  _accounting() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":41405:41416  _accounting */
      tag_474
        /* "src/contracts/0.4.24/Lido.sol":41405:41418  _accounting() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":41399:41419  _auth(_accounting()) */
    tag_564:
        /* "src/contracts/0.4.24/Lido.sol":41429:41446  _whenNotStopped() */
      tag_566
        /* "src/contracts/0.4.24/Lido.sol":41429:41444  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":41429:41446  _whenNotStopped() */
      jump	// in
    tag_566:
        /* "src/contracts/0.4.24/Lido.sol":41457:41497  _mintShares(_recipient, _amountOfShares) */
      tag_567
        /* "src/contracts/0.4.24/Lido.sol":41469:41479  _recipient */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":41481:41496  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":41457:41468  _mintShares */
      tag_376
        /* "src/contracts/0.4.24/Lido.sol":41457:41497  _mintShares(_recipient, _amountOfShares) */
      jump	// in
    tag_567:
      pop
        /* "src/contracts/0.4.24/Lido.sol":41507:41567  _emitTransferAfterMintingShares(_recipient, _amountOfShares) */
      tag_568
        /* "src/contracts/0.4.24/Lido.sol":41539:41549  _recipient */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":41551:41566  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":41507:41538  _emitTransferAfterMintingShares */
      tag_382
        /* "src/contracts/0.4.24/Lido.sol":41507:41567  _emitTransferAfterMintingShares(_recipient, _amountOfShares) */
      jump	// in
    tag_568:
        /* "src/contracts/0.4.24/Lido.sol":41315:41574  function mintShares(address _recipient, uint256 _amountOfShares) external {... */
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":54382:54517  function getWithdrawalCredentials() external view returns (bytes32) {... */
    tag_198:
        /* "src/contracts/0.4.24/Lido.sol":54441:54448  bytes32 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":54467:54483  _stakingRouter() */
      tag_570
        /* "src/contracts/0.4.24/Lido.sol":54467:54481  _stakingRouter */
      tag_484
        /* "src/contracts/0.4.24/Lido.sol":54467:54483  _stakingRouter() */
      jump	// in
    tag_570:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":54467:54508  _stakingRouter().getWithdrawalCredentials */
      and
      0x56396715
        /* "src/contracts/0.4.24/Lido.sol":54467:54510  _stakingRouter().getWithdrawalCredentials() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":46284:47390  function processClStateUpdate(uint256 _reportTimestamp, uint256 _clValidatorsBalance, uint256 _clPendingBalance)... */
    tag_201:
        /* "src/contracts/0.4.24/Lido.sol":46487:46514  uint256 depositedNextReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":46516:46532  uint256 curNonce */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":46428:46445  _whenNotStopped() */
      tag_575
        /* "src/contracts/0.4.24/Lido.sol":46428:46443  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":46428:46445  _whenNotStopped() */
      jump	// in
    tag_575:
        /* "src/contracts/0.4.24/Lido.sol":46455:46475  _auth(_accounting()) */
      tag_576
        /* "src/contracts/0.4.24/Lido.sol":46461:46474  _accounting() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":46461:46472  _accounting */
      tag_474
        /* "src/contracts/0.4.24/Lido.sol":46461:46474  _accounting() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":46455:46475  _auth(_accounting()) */
    tag_576:
        /* "src/contracts/0.4.24/Lido.sol":46536:46569  _getDepositedNextReportAdjusted() */
      tag_578
        /* "src/contracts/0.4.24/Lido.sol":46536:46567  _getDepositedNextReportAdjusted */
      tag_540
        /* "src/contracts/0.4.24/Lido.sol":46536:46569  _getDepositedNextReportAdjusted() */
      jump	// in
    tag_578:
        /* "src/contracts/0.4.24/Lido.sol":46486:46569  (uint256 depositedNextReport, uint256 curNonce) = _getDepositedNextReportAdjusted() */
      swap2
      pop
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":46635:46708  _setDepositedNextReportAndLastDepositNonce(depositedNextReport, curNonce) */
      tag_579
        /* "src/contracts/0.4.24/Lido.sol":46678:46697  depositedNextReport */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":46699:46707  curNonce */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":46635:46677  _setDepositedNextReportAndLastDepositNonce */
      tag_580
        /* "src/contracts/0.4.24/Lido.sol":46635:46708  _setDepositedNextReportAndLastDepositNonce(depositedNextReport, curNonce) */
      jump	// in
    tag_579:
        /* "src/contracts/0.4.24/Lido.sol":46951:46995  _setDepositedPostReport(depositedNextReport) */
      tag_581
        /* "src/contracts/0.4.24/Lido.sol":46975:46994  depositedNextReport */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":46951:46974  _setDepositedPostReport */
      tag_582
        /* "src/contracts/0.4.24/Lido.sol":46951:46995  _setDepositedPostReport(depositedNextReport) */
      jump	// in
    tag_581:
        /* "src/contracts/0.4.24/Lido.sol":47010:47057  DepositedPostReportUpdated(depositedNextReport) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      swap1
      mload
      0xd87d7ff193e5d1560bdbe21e4e14d13dde0de4e49a03812517640af0a2d5c42c
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":47209:47292  _setClValidatorsBalanceAndClPendingBalance(_clValidatorsBalance, _clPendingBalance) */
      tag_583
        /* "src/contracts/0.4.24/Lido.sol":47252:47272  _clValidatorsBalance */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":47274:47291  _clPendingBalance */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":47209:47251  _setClValidatorsBalanceAndClPendingBalance */
      tag_584
        /* "src/contracts/0.4.24/Lido.sol":47209:47292  _setClValidatorsBalanceAndClPendingBalance(_clValidatorsBalance, _clPendingBalance) */
      jump	// in
    tag_583:
        /* "src/contracts/0.4.24/Lido.sol":47307:47383  CLBalancesUpdated(_reportTimestamp, _clValidatorsBalance, _clPendingBalance) */
      0x40
      dup1
      mload
      dup6
      dup2
      mstore
      0x20
      dup2
      add
      dup6
      swap1
      mstore
      dup2
      mload
        /* "src/contracts/0.4.24/Lido.sol":47325:47341  _reportTimestamp */
      dup8
      swap3
        /* "src/contracts/0.4.24/Lido.sol":47307:47383  CLBalancesUpdated(_reportTimestamp, _clValidatorsBalance, _clPendingBalance) */
      0xc091cf4d34e62bb075bf8dadd00496528c94b8f3fdec3affd7414840847017d2
      swap3
      dup3
      swap1
      sub
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":46284:47390  function processClStateUpdate(uint256 _reportTimestamp, uint256 _clValidatorsBalance, uint256 _clPendingBalance)... */
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":19611:19773  function getCurrentStakeLimit() external view returns (uint256) {... */
    tag_204:
        /* "src/contracts/0.4.24/Lido.sol":19666:19673  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":19692:19766  _getCurrentStakeLimit(STAKING_STATE_POSITION.getStorageStakeLimitStruct()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":19714:19765  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_587
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":19714:19763  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":19714:19765  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_587:
        /* "src/contracts/0.4.24/Lido.sol":19692:19713  _getCurrentStakeLimit */
      tag_588
        /* "src/contracts/0.4.24/Lido.sol":19692:19766  _getCurrentStakeLimit(STAKING_STATE_POSITION.getStorageStakeLimitStruct()) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":30990:31095  function getExternalShares() external view returns (uint256) {... */
    tag_207:
        /* "src/contracts/0.4.24/Lido.sol":31042:31049  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":31068:31088  _getExternalShares() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":31068:31086  _getExternalShares */
      tag_413
        /* "src/contracts/0.4.24/Lido.sol":31068:31088  _getExternalShares() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":47519:48375  function internalizeExternalBadDebt(uint256 _amountOfShares) external {... */
    tag_210:
        /* "src/contracts/0.4.24/Lido.sol":47720:47742  uint256 externalShares */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":47607:47627  _amountOfShares != 0 */
      dup2
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":47599:47652  require(_amountOfShares != 0, "BAD_DEBT_ZERO_SHARES") */
      tag_592
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x4241445f444542545f5a45524f5f534841524553000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_592:
        /* "src/contracts/0.4.24/Lido.sol":47662:47679  _whenNotStopped() */
      tag_593
        /* "src/contracts/0.4.24/Lido.sol":47662:47677  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":47662:47679  _whenNotStopped() */
      jump	// in
    tag_593:
        /* "src/contracts/0.4.24/Lido.sol":47689:47709  _auth(_accounting()) */
      tag_594
        /* "src/contracts/0.4.24/Lido.sol":47695:47708  _accounting() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":47695:47706  _accounting */
      tag_474
        /* "src/contracts/0.4.24/Lido.sol":47695:47708  _accounting() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":47689:47709  _auth(_accounting()) */
    tag_594:
        /* "src/contracts/0.4.24/Lido.sol":47745:47765  _getExternalShares() */
      tag_596
        /* "src/contracts/0.4.24/Lido.sol":47745:47763  _getExternalShares */
      tag_413
        /* "src/contracts/0.4.24/Lido.sol":47745:47765  _getExternalShares() */
      jump	// in
    tag_596:
        /* "src/contracts/0.4.24/Lido.sol":47720:47765  uint256 externalShares = _getExternalShares() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":47784:47817  externalShares >= _amountOfShares */
      dup2
      dup2
      lt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":47776:47842  require(externalShares >= _amountOfShares, "EXT_SHARES_TOO_SMALL") */
      tag_597
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x4558545f5348415245535f544f4f5f534d414c4c000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_597:
        /* "src/contracts/0.4.24/Lido.sol":48205:48257  _setExternalShares(externalShares - _amountOfShares) */
      tag_598
        /* "src/contracts/0.4.24/Lido.sol":48241:48256  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":48224:48238  externalShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":48224:48256  externalShares - _amountOfShares */
      sub
        /* "src/contracts/0.4.24/Lido.sol":48205:48223  _setExternalShares */
      tag_414
        /* "src/contracts/0.4.24/Lido.sol":48205:48257  _setExternalShares(externalShares - _amountOfShares) */
      jump	// in
    tag_598:
        /* "src/contracts/0.4.24/Lido.sol":48273:48317  ExternalBadDebtInternalized(_amountOfShares) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      swap1
      mload
      0x4e80196ef1285462b2c4ee20f88e18e58c59e405eec6fd51f5fd1d614bc98a7f
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":48332:48368  ExternalSharesBurnt(_amountOfShares) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      swap1
      mload
      0xad21467656c56eb8c99f7916faa12f7a657a04d8802100acec62e92451ac5606
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":47519:48375  function internalizeExternalBadDebt(uint256 _amountOfShares) external {... */
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":20482:21410  function getStakeLimitFullInfo()... */
    tag_213:
        /* "src/contracts/0.4.24/Lido.sol":20575:20596  bool isStakingPaused_ */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":20610:20632  bool isStakingLimitSet */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":20646:20671  uint256 currentStakeLimit */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":20685:20706  uint256 maxStakeLimit */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":20720:20753  uint256 maxStakeLimitGrowthBlocks */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":20767:20789  uint256 prevStakeLimit */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":20803:20831  uint256 prevStakeBlockNumber */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":20856:20898  StakeLimitState.Data memory stakeLimitData */
      tag_599
      jump	// in(tag_600)
    tag_599:
        /* "src/contracts/0.4.24/Lido.sol":20901:20952  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_602
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":20901:20950  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":20901:20952  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_602:
        /* "src/contracts/0.4.24/Lido.sol":20856:20952  StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":20982:21014  stakeLimitData.isStakingPaused() */
      tag_603
        /* "src/contracts/0.4.24/Lido.sol":20982:20996  stakeLimitData */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":20982:21012  stakeLimitData.isStakingPaused */
      tag_479
        /* "src/contracts/0.4.24/Lido.sol":20982:21014  stakeLimitData.isStakingPaused() */
      jump	// in
    tag_603:
        /* "src/contracts/0.4.24/Lido.sol":20963:21014  isStakingPaused_ = stakeLimitData.isStakingPaused() */
      swap8
      pop
        /* "src/contracts/0.4.24/Lido.sol":21044:21078  stakeLimitData.isStakingLimitSet() */
      tag_604
        /* "src/contracts/0.4.24/Lido.sol":21044:21058  stakeLimitData */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":21044:21076  stakeLimitData.isStakingLimitSet */
      tag_605
        /* "src/contracts/0.4.24/Lido.sol":21044:21078  stakeLimitData.isStakingLimitSet() */
      jump	// in
    tag_604:
        /* "src/contracts/0.4.24/Lido.sol":21024:21078  isStakingLimitSet = stakeLimitData.isStakingLimitSet() */
      swap7
      pop
        /* "src/contracts/0.4.24/Lido.sol":21109:21146  _getCurrentStakeLimit(stakeLimitData) */
      tag_606
        /* "src/contracts/0.4.24/Lido.sol":21131:21145  stakeLimitData */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":21109:21130  _getCurrentStakeLimit */
      tag_588
        /* "src/contracts/0.4.24/Lido.sol":21109:21146  _getCurrentStakeLimit(stakeLimitData) */
      jump	// in
    tag_606:
        /* "src/contracts/0.4.24/Lido.sol":21089:21146  currentStakeLimit = _getCurrentStakeLimit(stakeLimitData) */
      swap6
      pop
        /* "src/contracts/0.4.24/Lido.sol":21173:21187  stakeLimitData */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":21173:21201  stakeLimitData.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":21157:21201  maxStakeLimit = stakeLimitData.maxStakeLimit */
      and
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":21239:21253  stakeLimitData */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":21239:21279  stakeLimitData.maxStakeLimitGrowthBlocks */
      0x40
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":21211:21279  maxStakeLimitGrowthBlocks = stakeLimitData.maxStakeLimitGrowthBlocks */
      0xffffffff
      and
      swap4
      pop
        /* "src/contracts/0.4.24/Lido.sol":21306:21320  stakeLimitData */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":21306:21335  stakeLimitData.prevStakeLimit */
      0x20
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":21289:21335  prevStakeLimit = stakeLimitData.prevStakeLimit */
      and
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":21368:21382  stakeLimitData */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":21368:21403  stakeLimitData.prevStakeBlockNumber */
      0x0
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":21345:21403  prevStakeBlockNumber = stakeLimitData.prevStakeBlockNumber */
      0xffffffff
      and
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":20482:21410  function getStakeLimitFullInfo()... */
      pop
      swap1
      swap2
      swap3
      swap4
      swap5
      swap6
      swap7
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":15578:16011  function transferSharesFrom(... */
    tag_216:
        /* "src/contracts/0.4.24/StETH.sol":15698:15705  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":15717:15737  uint256 tokensAmount */
      dup1
        /* "src/contracts/0.4.24/StETH.sol":15740:15775  getPooledEthByShares(_sharesAmount) */
      tag_608
        /* "src/contracts/0.4.24/StETH.sol":15761:15774  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":15740:15760  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/StETH.sol":15740:15775  getPooledEthByShares(_sharesAmount) */
      jump	// in
    tag_608:
        /* "src/contracts/0.4.24/StETH.sol":15717:15775  uint256 tokensAmount = getPooledEthByShares(_sharesAmount) */
      swap1
      pop
        /* "src/contracts/0.4.24/StETH.sol":15785:15835  _spendAllowance(_sender, msg.sender, tokensAmount) */
      tag_609
        /* "src/contracts/0.4.24/StETH.sol":15801:15808  _sender */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15810:15820  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":15822:15834  tokensAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":15785:15800  _spendAllowance */
      tag_500
        /* "src/contracts/0.4.24/StETH.sol":15785:15835  _spendAllowance(_sender, msg.sender, tokensAmount) */
      jump	// in
    tag_609:
        /* "src/contracts/0.4.24/StETH.sol":15845:15896  _transferShares(_sender, _recipient, _sharesAmount) */
      tag_610
        /* "src/contracts/0.4.24/StETH.sol":15861:15868  _sender */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15870:15880  _recipient */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15882:15895  _sharesAmount */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15845:15860  _transferShares */
      tag_611
        /* "src/contracts/0.4.24/StETH.sol":15845:15896  _transferShares(_sender, _recipient, _sharesAmount) */
      jump	// in
    tag_610:
        /* "src/contracts/0.4.24/StETH.sol":15906:15975  _emitTransferEvents(_sender, _recipient, tokensAmount, _sharesAmount) */
      tag_612
        /* "src/contracts/0.4.24/StETH.sol":15926:15933  _sender */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15935:15945  _recipient */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":15947:15959  tokensAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":15961:15974  _sharesAmount */
      dup7
        /* "src/contracts/0.4.24/StETH.sol":15906:15925  _emitTransferEvents */
      tag_613
        /* "src/contracts/0.4.24/StETH.sol":15906:15975  _emitTransferEvents(_sender, _recipient, tokensAmount, _sharesAmount) */
      jump	// in
    tag_612:
        /* "src/contracts/0.4.24/StETH.sol":15992:16004  tokensAmount */
      dup1
        /* "src/contracts/0.4.24/StETH.sol":15985:16004  return tokensAmount */
      swap2
      pop
        /* "src/contracts/0.4.24/StETH.sol":15578:16011  function transferSharesFrom(... */
    tag_607:
      pop
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":6844:6978  function balanceOf(address _account) external view returns (uint256) {... */
    tag_219:
        /* "src/contracts/0.4.24/StETH.sol":6904:6911  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":6930:6971  getPooledEthByShares(_sharesOf(_account)) */
      tag_381
        /* "src/contracts/0.4.24/StETH.sol":6951:6970  _sharesOf(_account) */
      tag_616
        /* "src/contracts/0.4.24/StETH.sol":6961:6969  _account */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":6951:6960  _sharesOf */
      tag_617
        /* "src/contracts/0.4.24/StETH.sol":6951:6970  _sharesOf(_account) */
      jump	// in
    tag_616:
        /* "src/contracts/0.4.24/StETH.sol":6930:6950  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/StETH.sol":6930:6971  getPooledEthByShares(_sharesOf(_account)) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":43492:44451  function burnExternalShares(uint256 _amountOfShares) external {... */
    tag_222:
        /* "src/contracts/0.4.24/Lido.sol":43689:43711  uint256 externalShares */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":43572:43592  _amountOfShares != 0 */
      dup3
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":43564:43623  require(_amountOfShares != 0, "BURN_ZERO_AMOUNT_OF_SHARES") */
      tag_619
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1a
      0x24
      dup3
      add
      mstore
      0x4255524e5f5a45524f5f414d4f554e545f4f465f534841524553000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_619:
        /* "src/contracts/0.4.24/Lido.sol":43633:43651  _auth(_vaultHub()) */
      tag_620
        /* "src/contracts/0.4.24/Lido.sol":43639:43650  _vaultHub() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":43639:43648  _vaultHub */
      tag_402
        /* "src/contracts/0.4.24/Lido.sol":43639:43650  _vaultHub() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":43633:43651  _auth(_vaultHub()) */
    tag_620:
        /* "src/contracts/0.4.24/Lido.sol":43661:43678  _whenNotStopped() */
      tag_622
        /* "src/contracts/0.4.24/Lido.sol":43661:43676  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":43661:43678  _whenNotStopped() */
      jump	// in
    tag_622:
        /* "src/contracts/0.4.24/Lido.sol":43714:43734  _getExternalShares() */
      tag_623
        /* "src/contracts/0.4.24/Lido.sol":43714:43732  _getExternalShares */
      tag_413
        /* "src/contracts/0.4.24/Lido.sol":43714:43734  _getExternalShares() */
      jump	// in
    tag_623:
        /* "src/contracts/0.4.24/Lido.sol":43689:43734  uint256 externalShares = _getExternalShares() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":43766:43781  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43749:43763  externalShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":43749:43781  externalShares < _amountOfShares */
      lt
        /* "src/contracts/0.4.24/Lido.sol":43745:43813  if (externalShares < _amountOfShares) revert("EXT_SHARES_TOO_SMALL") */
      iszero
      tag_624
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":43783:43813  revert("EXT_SHARES_TOO_SMALL") */
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x4558545f5348415245535f544f4f5f534d414c4c000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":43745:43813  if (externalShares < _amountOfShares) revert("EXT_SHARES_TOO_SMALL") */
    tag_624:
        /* "src/contracts/0.4.24/Lido.sol":43823:43875  _setExternalShares(externalShares - _amountOfShares) */
      tag_625
        /* "src/contracts/0.4.24/Lido.sol":43859:43874  _amountOfShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":43842:43856  externalShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":43842:43874  externalShares - _amountOfShares */
      sub
        /* "src/contracts/0.4.24/Lido.sol":43823:43841  _setExternalShares */
      tag_414
        /* "src/contracts/0.4.24/Lido.sol":43823:43875  _setExternalShares(externalShares - _amountOfShares) */
      jump	// in
    tag_625:
        /* "src/contracts/0.4.24/Lido.sol":43885:43925  _burnShares(msg.sender, _amountOfShares) */
      tag_626
        /* "src/contracts/0.4.24/Lido.sol":43897:43907  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":43909:43924  _amountOfShares */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":43885:43896  _burnShares */
      tag_627
        /* "src/contracts/0.4.24/Lido.sol":43885:43925  _burnShares(msg.sender, _amountOfShares) */
      jump	// in
    tag_626:
      pop
        /* "src/contracts/0.4.24/Lido.sol":43958:43995  getPooledEthByShares(_amountOfShares) */
      tag_628
        /* "src/contracts/0.4.24/Lido.sol":43979:43994  _amountOfShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":43958:43978  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/Lido.sol":43958:43995  getPooledEthByShares(_amountOfShares) */
      jump	// in
    tag_628:
        /* "src/contracts/0.4.24/Lido.sol":43936:43995  uint256 stethAmount = getPooledEthByShares(_amountOfShares) */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":44005:44039  _increaseStakingLimit(stethAmount) */
      tag_629
        /* "src/contracts/0.4.24/Lido.sol":44027:44038  stethAmount */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":44005:44026  _increaseStakingLimit */
      tag_630
        /* "src/contracts/0.4.24/Lido.sol":44005:44039  _increaseStakingLimit(stethAmount) */
      jump	// in
    tag_629:
        /* "src/contracts/0.4.24/Lido.sol":44322:44393  _emitSharesBurnt(msg.sender, stethAmount, stethAmount, _amountOfShares) */
      tag_631
        /* "src/contracts/0.4.24/Lido.sol":44339:44349  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":44351:44362  stethAmount */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":44364:44375  stethAmount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":44377:44392  _amountOfShares */
      dup7
        /* "src/contracts/0.4.24/Lido.sol":44322:44338  _emitSharesBurnt */
      tag_632
        /* "src/contracts/0.4.24/Lido.sol":44322:44393  _emitSharesBurnt(msg.sender, stethAmount, stethAmount, _amountOfShares) */
      jump	// in
    tag_631:
        /* "src/contracts/0.4.24/Lido.sol":44408:44444  ExternalSharesBurnt(_amountOfShares) */
      0x40
      dup1
      mload
      dup5
      dup2
      mstore
      swap1
      mload
      0xad21467656c56eb8c99f7916faa12f7a657a04d8802100acec62e92451ac5606
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":43492:44451  function burnExternalShares(uint256 _amountOfShares) external {... */
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":17044:17285  function resumeStaking() external {... */
    tag_225:
        /* "src/contracts/0.4.24/Lido.sol":17088:17115  _auth(STAKING_CONTROL_ROLE) */
      tag_634
      0x0
      dup1
      mload
      0x20
      data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":17088:17093  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":17088:17115  _auth(STAKING_CONTROL_ROLE) */
      jump	// in
    tag_634:
        /* "src/contracts/0.4.24/Lido.sol":17133:17149  hasInitialized() */
      tag_635
        /* "src/contracts/0.4.24/Lido.sol":17133:17147  hasInitialized */
      tag_116
        /* "src/contracts/0.4.24/Lido.sol":17133:17149  hasInitialized() */
      jump	// in
    tag_635:
        /* "src/contracts/0.4.24/Lido.sol":17125:17169  require(hasInitialized(), "NOT_INITIALIZED") */
      iszero
      iszero
      tag_636
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x4e4f545f494e495449414c495a45440000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_636:
        /* "src/contracts/0.4.24/Lido.sol":17179:17196  _whenNotStopped() */
      tag_637
        /* "src/contracts/0.4.24/Lido.sol":17179:17194  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":17179:17196  _whenNotStopped() */
      jump	// in
    tag_637:
        /* "src/contracts/0.4.24/Lido.sol":17214:17231  isStakingPaused() */
      tag_638
        /* "src/contracts/0.4.24/Lido.sol":17214:17229  isStakingPaused */
      tag_145
        /* "src/contracts/0.4.24/Lido.sol":17214:17231  isStakingPaused() */
      jump	// in
    tag_638:
        /* "src/contracts/0.4.24/Lido.sol":17206:17251  require(isStakingPaused(), "ALREADY_RESUMED") */
      iszero
      iszero
      tag_394
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x414c52454144595f524553554d45440000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":56232:57033  function getFeeDistribution()... */
    tag_228:
        /* "src/contracts/0.4.24/Lido.sol":56309:56338  uint16 treasuryFeeBasisPoints */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56340:56370  uint16 insuranceFeeBasisPoints */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":56372:56402  uint16 operatorsFeeBasisPoints */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56418:56446  IStakingRouter stakingRouter */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":56475:56499  uint256 totalBasisPoints */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56546:56562  uint256 totalFee */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":56614:56647  uint256 treasuryFeeBasisPointsAbs */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56649:56683  uint256 operatorsFeeBasisPointsAbs */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":56449:56465  _stakingRouter() */
      tag_642
        /* "src/contracts/0.4.24/Lido.sol":56449:56463  _stakingRouter */
      tag_484
        /* "src/contracts/0.4.24/Lido.sol":56449:56465  _stakingRouter() */
      jump	// in
    tag_642:
        /* "src/contracts/0.4.24/Lido.sol":56418:56465  IStakingRouter stakingRouter = _stakingRouter() */
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":56502:56515  stakingRouter */
      dup5
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":56502:56534  stakingRouter.TOTAL_BASIS_POINTS */
      and
      0x271662ec
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_643
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_643:
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_644
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_644:
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_645
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_645:
      pop
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      mload
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      0x40
      dup1
      mload
      0x9fbb7bae00000000000000000000000000000000000000000000000000000000
      dup2
      mstore
      swap1
      mload
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      swap2
      swap6
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":56565:56601  stakingRouter.getTotalFeeE4Precision */
      dup8
      and
      swap2
      0x9fbb7bae
      swap2
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      0x4
      dup1
      dup3
      add
      swap3
        /* "src/contracts/0.4.24/Lido.sol":56502:56536  stakingRouter.TOTAL_BASIS_POINTS() */
      0x20
      swap3
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      swap1
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56565:56601  stakingRouter.getTotalFeeE4Precision */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":5:7   */
      dup1
      iszero
      tag_646
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_646:
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_647
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_647:
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_648
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_648:
      pop
        /* "src/contracts/0.4.24/Lido.sol":56565:56603  stakingRouter.getTotalFeeE4Precision() */
      mload
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      0x40
      dup1
      mload
      0xefcdcc0e00000000000000000000000000000000000000000000000000000000
      dup2
      mstore
      dup2
      mload
        /* "src/contracts/0.4.24/Lido.sol":56546:56603  uint256 totalFee = stakingRouter.getTotalFeeE4Precision() */
      0xffff
      swap1
      swap4
      and
      swap6
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":56699:56758  stakingRouter.getStakingFeeAggregateDistributionE4Precision */
      dup9
      and
      swap3
      0xefcdcc0e
      swap3
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      0x4
      dup1
      dup5
      add
      swap4
      swap2
      swap3
      swap2
      dup3
      swap1
      sub
      add
      dup2
      0x0
        /* "src/contracts/0.4.24/Lido.sol":56699:56758  stakingRouter.getStakingFeeAggregateDistributionE4Precision */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":5:7   */
      dup1
      iszero
      tag_649
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_649:
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_650
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_650:
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x40
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_651
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_651:
      pop
        /* "src/contracts/0.4.24/Lido.sol":56699:56760  stakingRouter.getStakingFeeAggregateDistributionE4Precision() */
      dup1
      mload
      0x20
      swap1
      swap2
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":56797:56798  0 */
      0x0
      swap9
      pop
        /* "src/contracts/0.4.24/Lido.sol":56613:56760  (uint256 treasuryFeeBasisPointsAbs, uint256 operatorsFeeBasisPointsAbs) =... */
      0xffff
      swap2
      dup3
      and
      swap4
      pop
      and
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":56915:56923  totalFee */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":56867:56911  treasuryFeeBasisPointsAbs * totalBasisPoints */
      dup5
      dup4
      mul
        /* "src/contracts/0.4.24/Lido.sol":56866:56923  (treasuryFeeBasisPointsAbs * totalBasisPoints) / totalFee */
      dup2
      iszero
      iszero
      tag_652
      jumpi
      invalid
    tag_652:
      div
        /* "src/contracts/0.4.24/Lido.sol":56834:56924  treasuryFeeBasisPoints = uint16((treasuryFeeBasisPointsAbs * totalBasisPoints) / totalFee) */
      swap8
      pop
        /* "src/contracts/0.4.24/Lido.sol":57017:57025  totalFee */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":56997:57013  totalBasisPoints */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":56968:56994  operatorsFeeBasisPointsAbs */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":56968:57013  operatorsFeeBasisPointsAbs * totalBasisPoints */
      mul
        /* "src/contracts/0.4.24/Lido.sol":56967:57025  (operatorsFeeBasisPointsAbs * totalBasisPoints) / totalFee */
      dup2
      iszero
      iszero
      tag_653
      jumpi
      invalid
    tag_653:
      div
        /* "src/contracts/0.4.24/Lido.sol":56934:57026  operatorsFeeBasisPoints = uint16((operatorsFeeBasisPointsAbs * totalBasisPoints) / totalFee) */
      swap6
      pop
        /* "src/contracts/0.4.24/Lido.sol":56232:57033  function getFeeDistribution()... */
      pop
      pop
      pop
      pop
      pop
      swap1
      swap2
      swap3
      jump	// out
        /* "src/ConversionHarness.sol":376:430  function configure(address c) external {controller=c;} */
    tag_231:
        /* "src/ConversionHarness.sol":416:426  controller */
      0x3
        /* "src/ConversionHarness.sol":416:428  controller=c */
      dup1
      sload
      not(0xffffffffffffffffffffffffffffffffffffffff)
      and
      sub(exp(0x2, 0xa0), 0x1)
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
        /* "src/ConversionHarness.sol":376:430  function configure(address c) external {controller=c;} */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":23818:23953  function receiveWithdrawals() external payable {... */
    tag_233:
        /* "src/contracts/0.4.24/Lido.sol":23875:23900  _auth(_withdrawalVault()) */
      tag_656
        /* "src/contracts/0.4.24/Lido.sol":23881:23899  _withdrawalVault() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":23881:23897  _withdrawalVault */
      tag_658
        /* "src/contracts/0.4.24/Lido.sol":23881:23899  _withdrawalVault() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":23875:23900  _auth(_withdrawalVault()) */
    tag_656:
        /* "src/contracts/0.4.24/Lido.sol":23916:23946  WithdrawalsReceived(msg.value) */
      0x40
      dup1
      mload
        /* "src/contracts/0.4.24/Lido.sol":23936:23945  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":23916:23946  WithdrawalsReceived(msg.value) */
      dup2
      mstore
      swap1
      mload
      0x6e5086f7e1ab04bd826e77faae35b1bcfe31bd144623361a40ea4af51670b1c3
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":23818:23953  function receiveWithdrawals() external payable {... */
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":12982:13297  function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {... */
    tag_236:
        /* "src/contracts/0.4.24/StETH.sol":13056:13063  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":13099:13110  UINT128_MAX */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/StETH.sol":13083:13110  _sharesAmount < UINT128_MAX */
      dup3
      lt
        /* "src/contracts/0.4.24/StETH.sol":13075:13131  require(_sharesAmount < UINT128_MAX, "SHARES_TOO_LARGE") */
      tag_660
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x5348415245535f544f4f5f4c4152474500000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_660:
        /* "src/contracts/0.4.24/StETH.sol":13239:13265  _getShareRateDenominator() */
      tag_661
        /* "src/contracts/0.4.24/StETH.sol":13239:13263  _getShareRateDenominator */
      tag_388
        /* "src/contracts/0.4.24/StETH.sol":13239:13265  _getShareRateDenominator() */
      jump	// in
    tag_661:
        /* "src/contracts/0.4.24/StETH.sol":13177:13201  _getShareRateNumerator() */
      tag_469
        /* "src/contracts/0.4.24/StETH.sol":13177:13199  _getShareRateNumerator */
      tag_386
        /* "src/contracts/0.4.24/StETH.sol":13177:13201  _getShareRateNumerator() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":44813:45786  function rebalanceExternalEtherToInternal(uint256 _amountOfShares) external payable {... */
    tag_238:
        /* "src/contracts/0.4.24/Lido.sol":45139:45161  uint256 externalShares */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":44915:44924  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":44915:44929  msg.value != 0 */
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":44907:44944  require(msg.value != 0, "ZERO_VALUE") */
      tag_665
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xa
      0x24
      dup3
      add
      mstore
      0x5a45524f5f56414c554500000000000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_665:
        /* "src/contracts/0.4.24/Lido.sol":44954:44972  _auth(_vaultHub()) */
      tag_666
        /* "src/contracts/0.4.24/Lido.sol":44960:44971  _vaultHub() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":44960:44969  _vaultHub */
      tag_402
        /* "src/contracts/0.4.24/Lido.sol":44960:44971  _vaultHub() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":44954:44972  _auth(_vaultHub()) */
    tag_666:
        /* "src/contracts/0.4.24/Lido.sol":44982:44999  _whenNotStopped() */
      tag_668
        /* "src/contracts/0.4.24/Lido.sol":44982:44997  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":44982:44999  _whenNotStopped() */
      jump	// in
    tag_668:
        /* "src/contracts/0.4.24/Lido.sol":45027:45071  getPooledEthBySharesRoundUp(_amountOfShares) */
      tag_669
        /* "src/contracts/0.4.24/Lido.sol":45055:45070  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":45027:45054  getPooledEthBySharesRoundUp */
      tag_97
        /* "src/contracts/0.4.24/Lido.sol":45027:45071  getPooledEthBySharesRoundUp(_amountOfShares) */
      jump	// in
    tag_669:
        /* "src/contracts/0.4.24/Lido.sol":45014:45023  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":45014:45071  msg.value != getPooledEthBySharesRoundUp(_amountOfShares) */
      eq
        /* "src/contracts/0.4.24/Lido.sol":45010:45129  if (msg.value != getPooledEthBySharesRoundUp(_amountOfShares)) {... */
      tag_670
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":45087:45118  revert("VALUE_SHARES_MISMATCH") */
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x15
      0x24
      dup3
      add
      mstore
      0x56414c55455f5348415245535f4d49534d415443480000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":45010:45129  if (msg.value != getPooledEthBySharesRoundUp(_amountOfShares)) {... */
    tag_670:
        /* "src/contracts/0.4.24/Lido.sol":45164:45184  _getExternalShares() */
      tag_671
        /* "src/contracts/0.4.24/Lido.sol":45164:45182  _getExternalShares */
      tag_413
        /* "src/contracts/0.4.24/Lido.sol":45164:45184  _getExternalShares() */
      jump	// in
    tag_671:
        /* "src/contracts/0.4.24/Lido.sol":45139:45184  uint256 externalShares = _getExternalShares() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":45216:45231  _amountOfShares */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":45199:45213  externalShares */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":45199:45231  externalShares < _amountOfShares */
      lt
        /* "src/contracts/0.4.24/Lido.sol":45195:45263  if (externalShares < _amountOfShares) revert("EXT_SHARES_TOO_SMALL") */
      iszero
      tag_672
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":45233:45263  revert("EXT_SHARES_TOO_SMALL") */
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x4558545f5348415245535f544f4f5f534d414c4c000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":45195:45263  if (externalShares < _amountOfShares) revert("EXT_SHARES_TOO_SMALL") */
    tag_672:
        /* "src/contracts/0.4.24/Lido.sol":45355:45407  _setExternalShares(externalShares - _amountOfShares) */
      tag_673
        /* "src/contracts/0.4.24/Lido.sol":45391:45406  _amountOfShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":45374:45388  externalShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":45374:45406  externalShares - _amountOfShares */
      sub
        /* "src/contracts/0.4.24/Lido.sol":45355:45373  _setExternalShares */
      tag_414
        /* "src/contracts/0.4.24/Lido.sol":45355:45407  _setExternalShares(externalShares - _amountOfShares) */
      jump	// in
    tag_673:
        /* "src/contracts/0.4.24/Lido.sol":45458:45508  _setBufferedEther(_getBufferedEther() + msg.value) */
      tag_674
        /* "src/contracts/0.4.24/Lido.sol":45498:45507  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":45476:45495  _getBufferedEther() */
      tag_378
        /* "src/contracts/0.4.24/Lido.sol":45476:45493  _getBufferedEther */
      tag_379
        /* "src/contracts/0.4.24/Lido.sol":45476:45495  _getBufferedEther() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":45458:45508  _setBufferedEther(_getBufferedEther() + msg.value) */
    tag_674:
        /* "src/contracts/0.4.24/Lido.sol":45685:45728  ExternalEtherTransferredToBuffer(msg.value) */
      0x40
      dup1
      mload
        /* "src/contracts/0.4.24/Lido.sol":45718:45727  msg.value */
      callvalue
        /* "src/contracts/0.4.24/Lido.sol":45685:45728  ExternalEtherTransferredToBuffer(msg.value) */
      dup2
      mstore
      swap1
      mload
      0x4ee34277c93491eeca655ad5c42ae1c193a5719e1c8837df9058af7696817cce
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":45743:45779  ExternalSharesBurnt(_amountOfShares) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      swap1
      mload
      0xad21467656c56eb8c99f7916faa12f7a657a04d8802100acec62e92451ac5606
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":44813:45786  function rebalanceExternalEtherToInternal(uint256 _amountOfShares) external payable {... */
      pop
      pop
      jump	// out
        /* "src/@aragon/os/contracts/common/VaultRecoverable.sol":1658:1757  function allowRecoverability(address token) public view returns (bool) {... */
    tag_241:
      pop
        /* "src/@aragon/os/contracts/common/VaultRecoverable.sol":1746:1750  true */
      0x1
      swap1
        /* "src/@aragon/os/contracts/common/VaultRecoverable.sol":1658:1757  function allowRecoverability(address token) public view returns (bool) {... */
      jump	// out
        /* "src/contracts/0.4.24/StETHPermit.sol":4524:4633  function nonces(address owner) external view returns (uint256) {... */
    tag_244:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":4604:4626  noncesByAddress[owner] */
      and
        /* "src/contracts/0.4.24/StETHPermit.sol":4578:4585  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":4604:4626  noncesByAddress[owner] */
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":4604:4619  noncesByAddress */
      0x2
        /* "src/contracts/0.4.24/StETHPermit.sol":4604:4626  noncesByAddress[owner] */
      0x20
      mstore
      0x40
      swap1
      keccak256
      sload
      swap1
        /* "src/contracts/0.4.24/StETHPermit.sol":4524:4633  function nonces(address owner) external view returns (uint256) {... */
      jump	// out
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":795:901  function appId() public view returns (bytes32) {... */
    tag_247:
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":833:840  bytes32 */
      0x0
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":859:894  APP_ID_POSITION.getStorageBytes32() */
      tag_437
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":600:666  0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b */
      0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":859:892  APP_ID_POSITION.getStorageBytes32 */
      tag_438
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":859:894  APP_ID_POSITION.getStorageBytes32() */
      jump	// in
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
    tag_250:
        /* "src/contracts/0.4.24/StETHPermit.sol":5396:5414  string memory name */
      0x60
        /* "src/contracts/0.4.24/StETHPermit.sol":5424:5445  string memory version */
      dup1
        /* "src/contracts/0.4.24/StETHPermit.sol":5455:5470  uint256 chainId */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":5480:5505  address verifyingContract */
      dup1
        /* "src/contracts/0.4.24/StETHPermit.sol":5542:5558  getEIP712StETH() */
      tag_682
        /* "src/contracts/0.4.24/StETHPermit.sol":5542:5556  getEIP712StETH */
      tag_292
        /* "src/contracts/0.4.24/StETHPermit.sol":5542:5558  getEIP712StETH() */
      jump	// in
    tag_682:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5572  IEIP712StETH(getEIP712StETH()).eip712Domain */
      and
      0xf4409319
        /* "src/contracts/0.4.24/StETHPermit.sol":5581:5585  this */
      address
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup3
      sub(exp(0x2, 0xa0), 0x1)
      and
      sub(exp(0x2, 0xa0), 0x1)
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      0x0
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_683
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_683:
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_684
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_684:
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      pop
      pop
      pop
      pop
      mload(0x40)
        /* "--CODEGEN--":39:55   */
      returndatasize
        /* "--CODEGEN--":36:37   */
      0x0
        /* "--CODEGEN--":17:34   */
      dup3
        /* "--CODEGEN--":2:56   */
      returndatacopy
        /* "--CODEGEN--":101:105   */
      0x1f
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      returndatasize
        /* "--CODEGEN--":80:95   */
      swap1
      dup2
      add
      not(0x1f)
        /* "--CODEGEN--":76:107   */
      and
        /* "--CODEGEN--":65:108   */
      dup3
      add
        /* "--CODEGEN--":120:124   */
      0x40
        /* "--CODEGEN--":113:133   */
      mstore
        /* "--CODEGEN--":13:16   */
      0x80
        /* "--CODEGEN--":5:17   */
      dup2
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_685
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_685:
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      dup2
      add
      swap1
      dup1
      dup1
      mload
        /* "--CODEGEN--":20:31   */
      0x100000000
        /* "--CODEGEN--":15:18   */
      dup2
        /* "--CODEGEN--":12:32   */
      gt
        /* "--CODEGEN--":9:11   */
      iszero
      tag_686
      jumpi
        /* "--CODEGEN--":45:46   */
      0x0
        /* "--CODEGEN--":42:43   */
      dup1
        /* "--CODEGEN--":35:47   */
      revert
        /* "--CODEGEN--":9:11   */
    tag_686:
        /* "--CODEGEN--":64:85   */
      dup3
      add
        /* "--CODEGEN--":126:130   */
      0x20
        /* "--CODEGEN--":117:131   */
      dup2
      add
        /* "--CODEGEN--":142:173   */
      dup5
      dup2
      gt
        /* "--CODEGEN--":139:141   */
      iszero
      tag_687
      jumpi
        /* "--CODEGEN--":186:187   */
      0x0
        /* "--CODEGEN--":183:184   */
      dup1
        /* "--CODEGEN--":176:188   */
      revert
        /* "--CODEGEN--":139:141   */
    tag_687:
        /* "--CODEGEN--":218:228   */
      dup2
      mload
        /* "--CODEGEN--":268:279   */
      0x100000000
        /* "--CODEGEN--":251:280   */
      dup2
      gt
        /* "--CODEGEN--":293:336   */
      dup3
      dup3
      add
        /* "--CODEGEN--":290:348   */
      dup8
      lt
        /* "--CODEGEN--":239:357   */
      or
        /* "--CODEGEN--":236:238   */
      iszero
      tag_688
      jumpi
        /* "--CODEGEN--":370:371   */
      0x0
        /* "--CODEGEN--":367:368   */
      dup1
        /* "--CODEGEN--":360:372   */
      revert
        /* "--CODEGEN--":236:238   */
    tag_688:
        /* "--CODEGEN--":0:382   */
      pop
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      swap3
      swap2
      swap1
      0x20
      add
      dup1
      mload
        /* "--CODEGEN--":20:31   */
      0x100000000
        /* "--CODEGEN--":15:18   */
      dup2
        /* "--CODEGEN--":12:32   */
      gt
        /* "--CODEGEN--":9:11   */
      iszero
      tag_689
      jumpi
        /* "--CODEGEN--":45:46   */
      0x0
        /* "--CODEGEN--":42:43   */
      dup1
        /* "--CODEGEN--":35:47   */
      revert
        /* "--CODEGEN--":9:11   */
    tag_689:
        /* "--CODEGEN--":64:85   */
      dup3
      add
        /* "--CODEGEN--":126:130   */
      0x20
        /* "--CODEGEN--":117:131   */
      dup2
      add
        /* "--CODEGEN--":142:173   */
      dup5
      dup2
      gt
        /* "--CODEGEN--":139:141   */
      iszero
      tag_690
      jumpi
        /* "--CODEGEN--":186:187   */
      0x0
        /* "--CODEGEN--":183:184   */
      dup1
        /* "--CODEGEN--":176:188   */
      revert
        /* "--CODEGEN--":139:141   */
    tag_690:
        /* "--CODEGEN--":218:228   */
      dup2
      mload
        /* "--CODEGEN--":268:279   */
      0x100000000
        /* "--CODEGEN--":251:280   */
      dup2
      gt
        /* "--CODEGEN--":293:336   */
      dup3
      dup3
      add
        /* "--CODEGEN--":290:348   */
      dup8
      lt
        /* "--CODEGEN--":239:357   */
      or
        /* "--CODEGEN--":236:238   */
      iszero
      tag_691
      jumpi
        /* "--CODEGEN--":370:371   */
      0x0
        /* "--CODEGEN--":367:368   */
      dup1
        /* "--CODEGEN--":360:372   */
      revert
        /* "--CODEGEN--":236:238   */
    tag_691:
      pop
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      0x20
      dup3
      add
      mload
      0x40
      swap1
      swap3
      add
      mload
        /* "src/contracts/0.4.24/StETHPermit.sol":5522:5587  return IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      swap5
      swap9
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5529:5587  IEIP712StETH(getEIP712StETH()).eip712Domain(address(this)) */
      swap7
      pop
      swap5
      pop
      swap2
      swap3
      pop
      pop
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":5340:5594  function eip712Domain() external view returns (... */
      swap1
      swap2
      swap3
      swap4
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":41755:42353  function burnShares(uint256 _amountOfShares) external {... */
    tag_261:
        /* "src/contracts/0.4.24/Lido.sol":41873:41901  uint256 preRebaseTokenAmount */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":42001:42030  uint256 postRebaseTokenAmount */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":41819:41835  _auth(_burner()) */
      tag_693
        /* "src/contracts/0.4.24/Lido.sol":41825:41834  _burner() */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":41825:41832  _burner */
      tag_695
        /* "src/contracts/0.4.24/Lido.sol":41825:41834  _burner() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":41819:41835  _auth(_burner()) */
    tag_693:
        /* "src/contracts/0.4.24/Lido.sol":41845:41862  _whenNotStopped() */
      tag_696
        /* "src/contracts/0.4.24/Lido.sol":41845:41860  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":41845:41862  _whenNotStopped() */
      jump	// in
    tag_696:
        /* "src/contracts/0.4.24/Lido.sol":41904:41941  getPooledEthByShares(_amountOfShares) */
      tag_697
        /* "src/contracts/0.4.24/Lido.sol":41925:41940  _amountOfShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":41904:41924  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/Lido.sol":41904:41941  getPooledEthByShares(_amountOfShares) */
      jump	// in
    tag_697:
        /* "src/contracts/0.4.24/Lido.sol":41873:41941  uint256 preRebaseTokenAmount = getPooledEthByShares(_amountOfShares) */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":41951:41991  _burnShares(msg.sender, _amountOfShares) */
      tag_698
        /* "src/contracts/0.4.24/Lido.sol":41963:41973  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":41975:41990  _amountOfShares */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":41951:41962  _burnShares */
      tag_627
        /* "src/contracts/0.4.24/Lido.sol":41951:41991  _burnShares(msg.sender, _amountOfShares) */
      jump	// in
    tag_698:
      pop
        /* "src/contracts/0.4.24/Lido.sol":42033:42070  getPooledEthByShares(_amountOfShares) */
      tag_699
        /* "src/contracts/0.4.24/Lido.sol":42054:42069  _amountOfShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":42033:42053  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/Lido.sol":42033:42070  getPooledEthByShares(_amountOfShares) */
      jump	// in
    tag_699:
        /* "src/contracts/0.4.24/Lido.sol":42001:42070  uint256 postRebaseTokenAmount = getPooledEthByShares(_amountOfShares) */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":42256:42346  _emitSharesBurnt(msg.sender, preRebaseTokenAmount, postRebaseTokenAmount, _amountOfShares) */
      tag_700
        /* "src/contracts/0.4.24/Lido.sol":42273:42283  msg.sender */
      caller
        /* "src/contracts/0.4.24/Lido.sol":42285:42305  preRebaseTokenAmount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":42307:42328  postRebaseTokenAmount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":42330:42345  _amountOfShares */
      dup7
        /* "src/contracts/0.4.24/Lido.sol":42256:42272  _emitSharesBurnt */
      tag_632
        /* "src/contracts/0.4.24/Lido.sol":42256:42346  _emitSharesBurnt(msg.sender, preRebaseTokenAmount, postRebaseTokenAmount, _amountOfShares) */
      jump	// in
    tag_700:
        /* "src/contracts/0.4.24/Lido.sol":41755:42353  function burnShares(uint256 _amountOfShares) external {... */
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":31228:31355  function getMaxMintableExternalShares() external view returns (uint256) {... */
    tag_264:
        /* "src/contracts/0.4.24/Lido.sol":31291:31298  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":31317:31348  _getMaxMintableExternalShares() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":31317:31346  _getMaxMintableExternalShares */
      tag_407
        /* "src/contracts/0.4.24/Lido.sol":31317:31348  _getMaxMintableExternalShares() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":28787:28924  function getWithdrawalsReserve() external view returns (uint256) {... */
    tag_267:
        /* "src/contracts/0.4.24/Lido.sol":28843:28850  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":28869:28898  _getBufferedEtherAllocation() */
      tag_704
        /* "src/contracts/0.4.24/Lido.sol":28869:28896  _getBufferedEtherAllocation */
      tag_705
        /* "src/contracts/0.4.24/Lido.sol":28869:28898  _getBufferedEtherAllocation() */
      jump	// in
    tag_704:
        /* "src/contracts/0.4.24/Lido.sol":28869:28917  _getBufferedEtherAllocation().withdrawalsReserve */
      0x60
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":28862:28917  return _getBufferedEtherAllocation().withdrawalsReserve */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":28787:28924  function getWithdrawalsReserve() external view returns (uint256) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/utils/Versioned.sol":1385:1514  function getContractVersion() public view returns (uint256) {... */
    tag_270:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1436:1443  uint256 */
      0x0
        /* "src/contracts/0.4.24/utils/Versioned.sol":1462:1507  CONTRACT_VERSION_POSITION.getStorageUint256() */
      tag_437
        /* "src/contracts/0.4.24/utils/Versioned.sol":948:1014  0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6 */
      0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
        /* "src/contracts/0.4.24/utils/Versioned.sol":1462:1505  CONTRACT_VERSION_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/Versioned.sol":1462:1507  CONTRACT_VERSION_POSITION.getStorageUint256() */
      jump	// in
        /* "src/@aragon/os/contracts/common/Initializable.sol":880:1017  function getInitializationBlock() public view returns (uint256) {... */
    tag_273:
        /* "src/@aragon/os/contracts/common/Initializable.sol":935:942  uint256 */
      0x0
        /* "src/@aragon/os/contracts/common/Initializable.sol":961:1010  INITIALIZATION_BLOCK_POSITION.getStorageUint256() */
      tag_437
        /* "src/@aragon/os/contracts/common/Initializable.sol":344:410  0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e */
      0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e
        /* "src/@aragon/os/contracts/common/Initializable.sol":961:1008  INITIALIZATION_BLOCK_POSITION.getStorageUint256 */
      tag_438
        /* "src/@aragon/os/contracts/common/Initializable.sol":961:1010  INITIALIZATION_BLOCK_POSITION.getStorageUint256() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":13831:14489  function finalizeUpgrade_v4(uint256 _depositsReserveTarget) external {... */
    tag_276:
        /* "src/contracts/0.4.24/Lido.sol":14152:14176  IAccountingOracle oracle */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":14213:14235  bool mainDataSubmitted */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":13918:13934  hasInitialized() */
      tag_711
        /* "src/contracts/0.4.24/Lido.sol":13918:13932  hasInitialized */
      tag_116
        /* "src/contracts/0.4.24/Lido.sol":13918:13934  hasInitialized() */
      jump	// in
    tag_711:
        /* "src/contracts/0.4.24/Lido.sol":13910:13954  require(hasInitialized(), "NOT_INITIALIZED") */
      iszero
      iszero
      tag_712
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x4e4f545f494e495449414c495a45440000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_712:
        /* "src/contracts/0.4.24/Lido.sol":14179:14198  _accountingOracle() */
      tag_713
        /* "src/contracts/0.4.24/Lido.sol":14179:14196  _accountingOracle */
      tag_714
        /* "src/contracts/0.4.24/Lido.sol":14179:14198  _accountingOracle() */
      jump	// in
    tag_713:
        /* "src/contracts/0.4.24/Lido.sol":14152:14198  IAccountingOracle oracle = _accountingOracle() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":14244:14250  oracle */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":14244:14269  oracle.getProcessingState */
      and
      0x8f7797c2
        /* "src/contracts/0.4.24/Lido.sol":14244:14271  oracle.getProcessingState() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x120
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_715
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_715:
        /* "src/contracts/0.4.24/Lido.sol":14244:14271  oracle.getProcessingState() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_716
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_716:
        /* "src/contracts/0.4.24/Lido.sol":14244:14271  oracle.getProcessingState() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:16   */
      0x120
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:17   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_717
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_717:
      pop
        /* "src/contracts/0.4.24/Lido.sol":14244:14271  oracle.getProcessingState() */
      0x60
      add
      mload
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":14281:14320  require(mainDataSubmitted, "NO_REPORT") */
      dup1
      iszero
      iszero
      tag_718
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x9
      0x24
      dup3
      add
      mstore
      0x4e4f5f5245504f52540000000000000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_718:
        /* "src/contracts/0.4.24/Lido.sol":14331:14355  _checkContractVersion(3) */
      tag_719
        /* "src/contracts/0.4.24/Lido.sol":14353:14354  3 */
      0x3
        /* "src/contracts/0.4.24/Lido.sol":14331:14352  _checkContractVersion */
      tag_720
        /* "src/contracts/0.4.24/Lido.sol":14331:14355  _checkContractVersion(3) */
      jump	// in
    tag_719:
        /* "src/contracts/0.4.24/Lido.sol":14365:14387  _setContractVersion(4) */
      tag_721
        /* "src/contracts/0.4.24/Lido.sol":14385:14386  4 */
      0x4
        /* "src/contracts/0.4.24/Lido.sol":14365:14384  _setContractVersion */
      tag_454
        /* "src/contracts/0.4.24/Lido.sol":14365:14387  _setContractVersion(4) */
      jump	// in
    tag_721:
        /* "src/contracts/0.4.24/Lido.sol":14397:14423  _migrateStorage_v3_to_v4() */
      tag_722
        /* "src/contracts/0.4.24/Lido.sol":14397:14421  _migrateStorage_v3_to_v4 */
      tag_723
        /* "src/contracts/0.4.24/Lido.sol":14397:14423  _migrateStorage_v3_to_v4() */
      jump	// in
    tag_722:
        /* "src/contracts/0.4.24/Lido.sol":14433:14482  _setDepositsReserveTarget(_depositsReserveTarget) */
      tag_700
        /* "src/contracts/0.4.24/Lido.sol":14459:14481  _depositsReserveTarget */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":14433:14458  _setDepositsReserveTarget */
      tag_435
        /* "src/contracts/0.4.24/Lido.sol":14433:14482  _setDepositsReserveTarget(_depositsReserveTarget) */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":14578:14922  function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {... */
    tag_279:
        /* "src/contracts/0.4.24/StETH.sol":14663:14670  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":14746:14766  uint256 tokensAmount */
      dup1
        /* "src/contracts/0.4.24/StETH.sol":14682:14736  _transferShares(msg.sender, _recipient, _sharesAmount) */
      tag_726
        /* "src/contracts/0.4.24/StETH.sol":14698:14708  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":14710:14720  _recipient */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":14722:14735  _sharesAmount */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":14682:14697  _transferShares */
      tag_611
        /* "src/contracts/0.4.24/StETH.sol":14682:14736  _transferShares(msg.sender, _recipient, _sharesAmount) */
      jump	// in
    tag_726:
        /* "src/contracts/0.4.24/StETH.sol":14769:14804  getPooledEthByShares(_sharesAmount) */
      tag_727
        /* "src/contracts/0.4.24/StETH.sol":14790:14803  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":14769:14789  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/StETH.sol":14769:14804  getPooledEthByShares(_sharesAmount) */
      jump	// in
    tag_727:
        /* "src/contracts/0.4.24/StETH.sol":14746:14804  uint256 tokensAmount = getPooledEthByShares(_sharesAmount) */
      swap1
      pop
        /* "src/contracts/0.4.24/StETH.sol":14814:14886  _emitTransferEvents(msg.sender, _recipient, tokensAmount, _sharesAmount) */
      tag_728
        /* "src/contracts/0.4.24/StETH.sol":14834:14844  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":14846:14856  _recipient */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":14858:14870  tokensAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":14872:14885  _sharesAmount */
      dup7
        /* "src/contracts/0.4.24/StETH.sol":14814:14833  _emitTransferEvents */
      tag_613
        /* "src/contracts/0.4.24/StETH.sol":14814:14886  _emitTransferEvents(msg.sender, _recipient, tokensAmount, _sharesAmount) */
      jump	// in
    tag_728:
        /* "src/contracts/0.4.24/StETH.sol":14903:14915  tokensAmount */
      swap4
        /* "src/contracts/0.4.24/StETH.sol":14578:14922  function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":49291:51081  function collectRewardsAndProcessWithdrawals(... */
    tag_282:
        /* "src/contracts/0.4.24/Lido.sol":49708:49728  ILidoLocator locator */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":50489:50514  uint256 postBufferedEther */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":49680:49697  _whenNotStopped() */
      tag_730
        /* "src/contracts/0.4.24/Lido.sol":49680:49695  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/Lido.sol":49680:49697  _whenNotStopped() */
      jump	// in
    tag_730:
        /* "src/contracts/0.4.24/Lido.sol":49731:49748  _getLidoLocator() */
      tag_731
        /* "src/contracts/0.4.24/Lido.sol":49731:49746  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":49731:49748  _getLidoLocator() */
      jump	// in
    tag_731:
        /* "src/contracts/0.4.24/Lido.sol":49708:49748  ILidoLocator locator = _getLidoLocator() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":49758:49785  _auth(_accounting(locator)) */
      tag_732
        /* "src/contracts/0.4.24/Lido.sol":49764:49784  _accounting(locator) */
      tag_401
        /* "src/contracts/0.4.24/Lido.sol":49776:49783  locator */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":49764:49775  _accounting */
      tag_734
        /* "src/contracts/0.4.24/Lido.sol":49764:49784  _accounting(locator) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":49758:49785  _auth(_accounting(locator)) */
    tag_732:
        /* "src/contracts/0.4.24/Lido.sol":49894:49895  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":49871:49891  _elRewardsToWithdraw */
      dup7
        /* "src/contracts/0.4.24/Lido.sol":49871:49895  _elRewardsToWithdraw > 0 */
      gt
        /* "src/contracts/0.4.24/Lido.sol":49867:49984  if (_elRewardsToWithdraw > 0) {... */
      iszero
      tag_735
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":49911:49935  _elRewardsVault(locator) */
      tag_736
        /* "src/contracts/0.4.24/Lido.sol":49927:49934  locator */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":49911:49926  _elRewardsVault */
      tag_737
        /* "src/contracts/0.4.24/Lido.sol":49911:49935  _elRewardsVault(locator) */
      jump	// in
    tag_736:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":49911:49951  _elRewardsVault(locator).withdrawRewards */
      and
      0x9342c8f4
        /* "src/contracts/0.4.24/Lido.sol":49952:49972  _elRewardsToWithdraw */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":49911:49973  _elRewardsVault(locator).withdrawRewards(_elRewardsToWithdraw) */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup3
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_738
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_738:
        /* "src/contracts/0.4.24/Lido.sol":49911:49973  _elRewardsVault(locator).withdrawRewards(_elRewardsToWithdraw) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_739
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_739:
        /* "src/contracts/0.4.24/Lido.sol":49911:49973  _elRewardsVault(locator).withdrawRewards(_elRewardsToWithdraw) */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_740
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_740:
      pop
      pop
        /* "src/contracts/0.4.24/Lido.sol":49867:49984  if (_elRewardsToWithdraw > 0) {... */
    tag_735:
        /* "src/contracts/0.4.24/Lido.sol":50082:50083  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":50057:50079  _withdrawalsToWithdraw */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":50057:50083  _withdrawalsToWithdraw > 0 */
      gt
        /* "src/contracts/0.4.24/Lido.sol":50053:50179  if (_withdrawalsToWithdraw > 0) {... */
      iszero
      tag_741
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":50099:50124  _withdrawalVault(locator) */
      tag_742
        /* "src/contracts/0.4.24/Lido.sol":50116:50123  locator */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":50099:50115  _withdrawalVault */
      tag_743
        /* "src/contracts/0.4.24/Lido.sol":50099:50124  _withdrawalVault(locator) */
      jump	// in
    tag_742:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":50099:50144  _withdrawalVault(locator).withdrawWithdrawals */
      and
      0x3194528a
        /* "src/contracts/0.4.24/Lido.sol":50145:50167  _withdrawalsToWithdraw */
      dup9
        /* "src/contracts/0.4.24/Lido.sol":50099:50168  _withdrawalVault(locator).withdrawWithdrawals(_withdrawalsToWithdraw) */
      mload(0x40)
      dup3
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup3
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      0x0
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_744
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_744:
        /* "src/contracts/0.4.24/Lido.sol":50099:50168  _withdrawalVault(locator).withdrawWithdrawals(_withdrawalsToWithdraw) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_745
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_745:
        /* "src/contracts/0.4.24/Lido.sol":50099:50168  _withdrawalVault(locator).withdrawWithdrawals(_withdrawalsToWithdraw) */
      pop
      pop
      pop
      pop
        /* "src/contracts/0.4.24/Lido.sol":50053:50179  if (_withdrawalsToWithdraw > 0) {... */
    tag_741:
        /* "src/contracts/0.4.24/Lido.sol":50297:50298  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":50265:50294  _etherToLockOnWithdrawalQueue */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":50265:50298  _etherToLockOnWithdrawalQueue > 0 */
      gt
        /* "src/contracts/0.4.24/Lido.sol":50261:50479  if (_etherToLockOnWithdrawalQueue > 0) {... */
      iszero
      tag_746
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":50314:50339  _withdrawalQueue(locator) */
      tag_747
        /* "src/contracts/0.4.24/Lido.sol":50331:50338  locator */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":50314:50330  _withdrawalQueue */
      tag_457
        /* "src/contracts/0.4.24/Lido.sol":50314:50339  _withdrawalQueue(locator) */
      jump	// in
    tag_747:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":50314:50361  _withdrawalQueue(locator)... */
      and
      0xb6013cef
        /* "src/contracts/0.4.24/Lido.sol":50381:50410  _etherToLockOnWithdrawalQueue */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":50412:50444  _lastWithdrawalRequestToFinalize */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":50446:50467  _withdrawalsShareRate */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":50314:50468  _withdrawalQueue(locator)... */
      mload(0x40)
      dup5
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      dup1
      dup4
      dup2
      mstore
      0x20
      add
      dup3
      dup2
      mstore
      0x20
      add
      swap3
      pop
      pop
      pop
      0x0
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      dup6
      dup9
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_748
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_748:
        /* "src/contracts/0.4.24/Lido.sol":50314:50468  _withdrawalQueue(locator)... */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_749
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_749:
        /* "src/contracts/0.4.24/Lido.sol":50314:50468  _withdrawalQueue(locator)... */
      pop
      pop
      pop
      pop
      pop
        /* "src/contracts/0.4.24/Lido.sol":50261:50479  if (_etherToLockOnWithdrawalQueue > 0) {... */
    tag_746:
        /* "src/contracts/0.4.24/Lido.sol":50517:50724  _getBufferedEther()... */
      tag_750
        /* "src/contracts/0.4.24/Lido.sol":50694:50723  _etherToLockOnWithdrawalQueue */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":50517:50642  _getBufferedEther()... */
      tag_751
        /* "src/contracts/0.4.24/Lido.sol":50619:50641  _withdrawalsToWithdraw */
      dup10
        /* "src/contracts/0.4.24/Lido.sol":50517:50575  _getBufferedEther()... */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":50554:50574  _elRewardsToWithdraw */
      dup11
        /* "src/contracts/0.4.24/Lido.sol":50517:50536  _getBufferedEther() */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":50517:50534  _getBufferedEther */
      tag_379
        /* "src/contracts/0.4.24/Lido.sol":50517:50536  _getBufferedEther() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":50517:50642  _getBufferedEther()... */
    tag_751:
        /* "src/contracts/0.4.24/Lido.sol":50517:50693  _getBufferedEther()... */
      swap1
        /* "src/contracts/0.4.24/Lido.sol":50517:50724  _getBufferedEther()... */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":50517:50693  _getBufferedEther()... */
      tag_754
        /* "src/contracts/0.4.24/Lido.sol":50517:50724  _getBufferedEther()... */
      and
      jump	// in
    tag_750:
        /* "src/contracts/0.4.24/Lido.sol":50489:50724  uint256 postBufferedEther = _getBufferedEther()... */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":50762:50798  _setBufferedEther(postBufferedEther) */
      tag_755
        /* "src/contracts/0.4.24/Lido.sol":50780:50797  postBufferedEther */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":50762:50779  _setBufferedEther */
      tag_380
        /* "src/contracts/0.4.24/Lido.sol":50762:50798  _setBufferedEther(postBufferedEther) */
      jump	// in
    tag_755:
        /* "src/contracts/0.4.24/Lido.sol":50808:50840  _updateBufferedEtherAllocation() */
      tag_756
        /* "src/contracts/0.4.24/Lido.sol":50808:50838  _updateBufferedEtherAllocation */
      tag_757
        /* "src/contracts/0.4.24/Lido.sol":50808:50840  _updateBufferedEtherAllocation() */
      jump	// in
    tag_756:
        /* "src/contracts/0.4.24/Lido.sol":50856:51074  ETHDistributed(... */
      0x40
      dup1
      mload
      dup10
      dup2
      mstore
      0x20
      dup2
      add
      dup12
      swap1
      mstore
      dup1
      dup3
      add
      dup10
      swap1
      mstore
      0x60
      dup2
      add
      dup9
      swap1
      mstore
      0x80
      dup2
      add
      dup4
      swap1
      mstore
      swap1
      mload
        /* "src/contracts/0.4.24/Lido.sol":50884:50900  _reportTimestamp */
      dup12
      swap2
        /* "src/contracts/0.4.24/Lido.sol":50856:51074  ETHDistributed(... */
      0x92dd3cb149a1eebd51fd8c2a3653fd96f30c4ac01d4f850fc16d46abd6c3e92f
      swap2
      swap1
      dup2
      swap1
      sub
      0xa0
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":49291:51081  function collectRewardsAndProcessWithdrawals(... */
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":5708:5788  function symbol() external pure returns (string) {... */
    tag_285:
        /* "src/contracts/0.4.24/StETH.sol":5767:5781  return "stETH" */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x5
      dup2
      mstore
      0x7374455448000000000000000000000000000000000000000000000000000000
      0x20
      dup3
      add
      mstore
        /* "src/contracts/0.4.24/StETH.sol":5708:5788  function symbol() external pure returns (string) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/StETHPermit.sol":6337:6458  function getEIP712StETH() public view returns (address) {... */
    tag_292:
        /* "src/contracts/0.4.24/StETHPermit.sol":6384:6391  address */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":6410:6451  EIP712_STETH_POSITION.getStorageAddress() */
      tag_437
        /* "src/contracts/0.4.24/StETHPermit.sol":2725:2791  0x42b2d95e1ce15ce63bf9a8d9f6312cf44b23415c977ffa3b884333422af8941c */
      0x42b2d95e1ce15ce63bf9a8d9f6312cf44b23415c977ffa3b884333422af8941c
        /* "src/contracts/0.4.24/StETHPermit.sol":6410:6449  EIP712_STETH_POSITION.getStorageAddress */
      tag_438
        /* "src/contracts/0.4.24/StETHPermit.sol":6410:6451  EIP712_STETH_POSITION.getStorageAddress() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":21531:21644  function getMaxExternalRatioBP() external view returns (uint256) {... */
    tag_295:
        /* "src/contracts/0.4.24/Lido.sol":21587:21594  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":21613:21637  _getMaxExternalRatioBP() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":21613:21635  _getMaxExternalRatioBP */
      tag_764
        /* "src/contracts/0.4.24/Lido.sol":21613:21637  _getMaxExternalRatioBP() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":53822:53944  function transferToVault(... */
    tag_298:
        /* "src/contracts/0.4.24/Lido.sol":53914:53937  revert("NOT_SUPPORTED") */
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xd
      0x24
      dup3
      add
      mstore
      0x4e4f545f535550504f5254454400000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1640:2136  function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {... */
    tag_301:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1732:1736  bool */
      0x0
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1818:1838  IKernel linkedKernel */
      dup1
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1753:1769  hasInitialized() */
      tag_767
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1753:1767  hasInitialized */
      tag_116
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1753:1769  hasInitialized() */
      jump	// in
    tag_767:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1752:1769  !hasInitialized() */
      iszero
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1748:1808  if (!hasInitialized()) {... */
      iszero
      tag_768
      jumpi
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1792:1797  false */
      0x0
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1785:1797  return false */
      swap2
      pop
      jump(tag_607)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1748:1808  if (!hasInitialized()) {... */
    tag_768:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1841:1849  kernel() */
      tag_769
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1841:1847  kernel */
      tag_324
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1841:1849  kernel() */
      jump	// in
    tag_769:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1818:1849  IKernel linkedKernel = kernel() */
      swap1
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1863:1898  address(linkedKernel) == address(0) */
      dup2
      and
      iszero
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1859:1937  if (address(linkedKernel) == address(0)) {... */
      iszero
      tag_770
      jumpi
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1921:1926  false */
      0x0
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1914:1926  return false */
      swap2
      pop
      jump(tag_607)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1859:1937  if (address(linkedKernel) == address(0)) {... */
    tag_770:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:1966  linkedKernel */
      dup1
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:1980  linkedKernel.hasPermission */
      and
      0xfdef9106
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1994:2001  _sender */
      dup7
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2023:2027  this */
      address
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2042:2047  _role */
      dup8
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2061:2119  ConversionHelpers.dangerouslyCastUintArrayToBytes(_params) */
      tag_771
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2111:2118  _params */
      dup9
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2061:2110  ConversionHelpers.dangerouslyCastUintArrayToBytes */
      tag_772
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":2061:2119  ConversionHelpers.dangerouslyCastUintArrayToBytes(_params) */
      jump	// in
    tag_771:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:2129  linkedKernel.hasPermission(... */
      mload(0x40)
      exp(0x2, 0xe0)
      0xffffffff
      dup8
      and
      mul
      dup2
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      dup1
      dup7
      and
      0x4
      dup4
      add
      swap1
      dup2
      mstore
      swap1
      dup6
      and
      0x24
      dup4
      add
      mstore
      0x44
      dup3
      add
      dup5
      swap1
      mstore
      0x80
      0x64
      dup4
      add
      swap1
      dup2
      mstore
      dup4
      mload
      0x84
      dup5
      add
      mstore
      dup4
      mload
      swap2
      swap3
      swap1
      swap2
      0xa4
      swap1
      swap2
      add
      swap1
      0x20
      dup6
      add
      swap1
      dup1
      dup4
      dup4
      0x0
        /* "--CODEGEN--":8:108   */
    tag_773:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_774
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_773)
    tag_774:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:2129  linkedKernel.hasPermission(... */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_776
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_776:
      pop
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_777
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_777:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:2129  linkedKernel.hasPermission(... */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_778
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_778:
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:2129  linkedKernel.hasPermission(... */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_779
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_779:
      pop
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1954:2129  linkedKernel.hasPermission(... */
      mload
      swap6
        /* "src/@aragon/os/contracts/apps/AragonApp.sol":1640:2136  function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":22940:23052  function submit(address _referral) external payable returns (uint256) {... */
    tag_303:
        /* "src/contracts/0.4.24/Lido.sol":23001:23008  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":23027:23045  _submit(_referral) */
      tag_381
        /* "src/contracts/0.4.24/Lido.sol":23035:23044  _referral */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":23027:23034  _submit */
      tag_94
        /* "src/contracts/0.4.24/Lido.sol":23027:23045  _submit(_referral) */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":11280:11631  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {... */
    tag_306:
        /* "src/contracts/0.4.24/StETH.sol":11423:11433  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":11369:11373  bool */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":11412:11434  allowances[msg.sender] */
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":11412:11422  allowances */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":11412:11434  allowances[msg.sender] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":11412:11444  allowances[msg.sender][_spender] */
      dup7
      and
      dup5
      mstore
      swap1
      swap2
      mstore
      dup2
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":11462:11498  currentAllowance >= _subtractedValue */
      dup3
      dup2
      lt
      iszero
        /* "src/contracts/0.4.24/StETH.sol":11454:11523  require(currentAllowance >= _subtractedValue, "ALLOWANCE_BELOW_ZERO") */
      tag_783
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x414c4c4f57414e43455f42454c4f575f5a45524f000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_783:
        /* "src/contracts/0.4.24/StETH.sol":11533:11603  _approve(msg.sender, _spender, currentAllowance.sub(_subtractedValue)) */
      tag_501
        /* "src/contracts/0.4.24/StETH.sol":11542:11552  msg.sender */
      caller
        /* "src/contracts/0.4.24/StETH.sol":11554:11562  _spender */
      dup6
        /* "src/contracts/0.4.24/StETH.sol":11564:11602  currentAllowance.sub(_subtractedValue) */
      tag_543
        /* "src/contracts/0.4.24/StETH.sol":11564:11580  currentAllowance */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":11585:11601  _subtractedValue */
      dup8
        /* "src/contracts/0.4.24/StETH.sol":11564:11602  currentAllowance.sub(_subtractedValue) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":11564:11584  currentAllowance.sub */
      tag_754
        /* "src/contracts/0.4.24/StETH.sol":11564:11602  currentAllowance.sub(_subtractedValue) */
      and
      jump	// in
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":979:1210  function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {... */
    tag_309:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1032:1050  IEVMScriptRegistry */
      0x0
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1062:1082  address registryAddr */
      dup1
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1093  kernel() */
      tag_787
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1091  kernel */
      tag_324
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1093  kernel() */
      jump	// in
    tag_787:
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1154  kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID) */
      0x40
      dup1
      mload
      0xbe00bbd800000000000000000000000000000000000000000000000000000000
      dup2
      mstore
        /* "src/@aragon/os/contracts/kernel/KernelConstants.sol":1367:1433  0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb */
      0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1154  kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID) */
      0x4
      dup3
      add
      mstore
        /* "src/@aragon/os/contracts/evmscript/IEVMScriptRegistry.sol":329:395  0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61 */
      0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1154  kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID) */
      0x24
      dup3
      add
      mstore
      swap1
      mload
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1100  kernel().getApp */
      swap3
      swap1
      swap3
      and
      swap2
      0xbe00bbd8
      swap2
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1154  kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID) */
      0x44
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
      0x0
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1100  kernel().getApp */
      dup8
        /* "src/@aragon/os/contracts/evmscript/EVMScriptRunner.sol":1085:1154  kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID) */
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":5:7   */
      dup1
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/ConversionHarness.sol":432:568  function transfer(address to,uint256 amount) external returns(bool) {... */
    tag_312:
        /* "src/ConversionHarness.sol":513:523  controller */
      sload(0x3)
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      0x40
      dup1
      mload
      0x5c997e4d00000000000000000000000000000000000000000000000000000000
      dup2
      mstore
        /* "src/ConversionHarness.sol":531:541  msg.sender */
      caller
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      0x4
      dup3
      add
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      dup6
      dup2
      and
      0x24
      dup4
      add
      mstore
      0x44
      dup3
      add
      dup6
      swap1
      mstore
      swap2
      mload
        /* "src/ConversionHarness.sol":494:498  bool */
      0x0
      swap4
        /* "src/ConversionHarness.sol":513:523  controller */
      swap3
      swap1
      swap3
      and
      swap2
        /* "src/ConversionHarness.sol":504:530  Callback(controller).moved */
      0x5c997e4d
      swap2
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      0x64
      dup1
      dup3
      add
      swap3
        /* "src/ConversionHarness.sol":494:498  bool */
      dup7
      swap3
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      swap1
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/ConversionHarness.sol":494:498  bool */
      dup4
        /* "src/ConversionHarness.sol":513:523  controller */
      dup8
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":5:7   */
      dup1
      iszero
      tag_792
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_792:
        /* "src/ConversionHarness.sol":504:552  Callback(controller).moved(msg.sender,to,amount) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_793
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_793:
      pop
        /* "src/ConversionHarness.sol":560:564  true */
      0x1
      swap7
        /* "src/ConversionHarness.sol":432:568  function transfer(address to,uint256 amount) external returns(bool) {... */
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":32473:33248  function getBeaconStat()... */
    tag_315:
        /* "src/contracts/0.4.24/Lido.sol":32545:32572  uint256 depositedValidators */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":32574:32598  uint256 beaconValidators */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":32600:32621  uint256 beaconBalance */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":32693:32720  uint256 clValidatorsBalance */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":32722:32746  uint256 clPendingBalance */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":32659:32682  _getSeedDepositsCount() */
      tag_795
        /* "src/contracts/0.4.24/Lido.sol":32659:32680  _getSeedDepositsCount */
      tag_492
        /* "src/contracts/0.4.24/Lido.sol":32659:32682  _getSeedDepositsCount() */
      jump	// in
    tag_795:
        /* "src/contracts/0.4.24/Lido.sol":32637:32682  depositedValidators = _getSeedDepositsCount() */
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":32750:32794  _getClValidatorsBalanceAndClPendingBalance() */
      tag_796
        /* "src/contracts/0.4.24/Lido.sol":32750:32792  _getClValidatorsBalanceAndClPendingBalance */
      tag_536
        /* "src/contracts/0.4.24/Lido.sol":32750:32794  _getClValidatorsBalanceAndClPendingBalance() */
      jump	// in
    tag_796:
        /* "src/contracts/0.4.24/Lido.sol":32692:32794  (uint256 clValidatorsBalance, uint256 clPendingBalance) = _getClValidatorsBalanceAndClPendingBalance() */
      swap1
      swap3
      pop
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":33157:33176  depositedValidators */
      dup5
      dup1
        /* "src/contracts/0.4.24/Lido.sol":33199:33240  clValidatorsBalance.add(clPendingBalance) */
      tag_797
        /* "src/contracts/0.4.24/Lido.sol":32692:32794  (uint256 clValidatorsBalance, uint256 clPendingBalance) = _getClValidatorsBalanceAndClPendingBalance() */
      dup5
      dup5
        /* "src/contracts/0.4.24/Lido.sol":33199:33240  clValidatorsBalance.add(clPendingBalance) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":33199:33222  clValidatorsBalance.add */
      tag_493
        /* "src/contracts/0.4.24/Lido.sol":33199:33240  clValidatorsBalance.add(clPendingBalance) */
      and
      jump	// in
    tag_797:
        /* "src/contracts/0.4.24/Lido.sol":33149:33241  return (depositedValidators, depositedValidators, clValidatorsBalance.add(clPendingBalance)) */
      swap5
      pop
      swap5
      pop
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":32473:33248  function getBeaconStat()... */
      pop
      pop
      swap1
      swap2
      swap3
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":18861:19137  function removeStakingLimit() external {... */
    tag_318:
        /* "src/contracts/0.4.24/Lido.sol":18910:18937  _auth(STAKING_CONTROL_ROLE) */
      tag_799
      0x0
      dup1
      mload
      0x20
      data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":18910:18915  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":18910:18937  _auth(STAKING_CONTROL_ROLE) */
      jump	// in
    tag_799:
        /* "src/contracts/0.4.24/Lido.sol":18948:19093  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      tag_800
        /* "src/contracts/0.4.24/Lido.sol":19011:19083  STAKING_STATE_POSITION.getStorageStakeLimitStruct().removeStakingLimit() */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":19011:19062  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_802
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":19011:19060  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":19011:19062  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_802:
        /* "src/contracts/0.4.24/Lido.sol":19011:19081  STAKING_STATE_POSITION.getStorageStakeLimitStruct().removeStakingLimit */
      tag_803
        /* "src/contracts/0.4.24/Lido.sol":19011:19083  STAKING_STATE_POSITION.getStorageStakeLimitStruct().removeStakingLimit() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":18948:19093  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
    tag_800:
        /* "src/contracts/0.4.24/Lido.sol":19109:19130  StakingLimitRemoved() */
      mload(0x40)
      0x9b2a687c198898fcc32a33bbc610d478f177a73ab7352023e6cc1de5bf12a3df
      swap1
      0x0
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":18861:19137  function removeStakingLimit() external {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":55187:55314  function getFee() external view returns (uint16 totalFee) {... */
    tag_321:
        /* "src/contracts/0.4.24/Lido.sol":55228:55243  uint16 totalFee */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":55266:55282  _stakingRouter() */
      tag_805
        /* "src/contracts/0.4.24/Lido.sol":55266:55280  _stakingRouter */
      tag_484
        /* "src/contracts/0.4.24/Lido.sol":55266:55282  _stakingRouter() */
      jump	// in
    tag_805:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":55266:55305  _stakingRouter().getTotalFeeE4Precision */
      and
      0x9fbb7bae
        /* "src/contracts/0.4.24/Lido.sol":55266:55307  _stakingRouter().getTotalFeeE4Precision() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":673:789  function kernel() public view returns (IKernel) {... */
    tag_324:
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":712:719  IKernel */
      0x0
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":746:781  KERNEL_POSITION.getStorageAddress() */
      tag_437
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":484:550  0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b */
      0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":746:779  KERNEL_POSITION.getStorageAddress */
      tag_438
        /* "src/@aragon/os/contracts/apps/AppStorage.sol":746:781  KERNEL_POSITION.getStorageAddress() */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":11886:11985  function getTotalShares() external view returns (uint256) {... */
    tag_327:
        /* "src/contracts/0.4.24/StETH.sol":11935:11942  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":11961:11978  _getTotalShares() */
      tag_437
        /* "src/contracts/0.4.24/StETH.sol":11961:11976  _getTotalShares */
      tag_813
        /* "src/contracts/0.4.24/StETH.sol":11961:11978  _getTotalShares() */
      jump	// in
        /* "src/contracts/0.4.24/StETHPermit.sol":3614:4219  function permit(... */
    tag_330:
        /* "src/contracts/0.4.24/StETHPermit.sol":3834:3852  bytes32 structHash */
      0x0
      dup1
        /* "src/contracts/0.4.24/StETHPermit.sol":3774:3789  block.timestamp */
      timestamp
        /* "src/contracts/0.4.24/StETHPermit.sol":3774:3802  block.timestamp <= _deadline */
      dup7
      lt
      iszero
        /* "src/contracts/0.4.24/StETHPermit.sol":3766:3823  require(block.timestamp <= _deadline, "DEADLINE_EXPIRED") */
      tag_815
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x444541444c494e455f4558504952454400000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_815:
        /* "src/contracts/0.4.24/StETHPermit.sol":3028:3094  0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9 */
      0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
        /* "src/contracts/0.4.24/StETHPermit.sol":3906:3912  _owner */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":3914:3922  _spender */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":3924:3930  _value */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":3932:3949  _useNonce(_owner) */
      tag_816
        /* "src/contracts/0.4.24/StETHPermit.sol":3906:3912  _owner */
      dup4
        /* "src/contracts/0.4.24/StETHPermit.sol":3932:3941  _useNonce */
      tag_817
        /* "src/contracts/0.4.24/StETHPermit.sol":3932:3949  _useNonce(_owner) */
      jump	// in
    tag_816:
        /* "src/contracts/0.4.24/StETHPermit.sol":3878:3961  abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, _useNonce(_owner), _deadline) */
      0x40
      dup1
      mload
      0x20
      dup1
      dup3
      add
      swap8
      swap1
      swap8
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      swap6
      dup7
      and
      dup2
      dup4
      add
      mstore
      swap4
      swap1
      swap5
      and
      0x60
      dup5
      add
      mstore
      0x80
      dup4
      add
      swap2
      swap1
      swap2
      mstore
      0xa0
      dup3
      add
      mstore
      0xc0
      dup1
      dup3
      add
      dup11
      swap1
      mstore
      dup3
      mload
        /* "--CODEGEN--":26:47   */
      dup1
      dup4
      sub
        /* "--CODEGEN--":22:54   */
      swap1
      swap2
      add
        /* "--CODEGEN--":6:55   */
      dup2
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":3878:3961  abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, _useNonce(_owner), _deadline) */
      0xe0
      swap1
      swap2
      add
      swap2
      dup3
      swap1
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":3855:3971  keccak256(... */
      dup1
      mload
        /* "src/contracts/0.4.24/StETHPermit.sol":3878:3961  abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, _useNonce(_owner), _deadline) */
      swap1
      swap3
      dup3
      swap2
        /* "src/contracts/0.4.24/StETHPermit.sol":3855:3971  keccak256(... */
      swap1
      dup5
      add
      swap1
      dup1
        /* "src/contracts/0.4.24/StETHPermit.sol":3878:3961  abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, _useNonce(_owner), _deadline) */
      dup4
        /* "src/contracts/0.4.24/StETHPermit.sol":3855:3971  keccak256(... */
      dup4
        /* "--CODEGEN--":36:189   */
    tag_818:
        /* "--CODEGEN--":66:68   */
      0x20
        /* "--CODEGEN--":58:69   */
      dup4
      lt
        /* "--CODEGEN--":36:189   */
      tag_819
      jumpi
        /* "--CODEGEN--":176:186   */
      dup1
      mload
        /* "--CODEGEN--":164:187   */
      dup3
      mstore
      not(0x1f)
        /* "--CODEGEN--":139:151   */
      swap1
      swap3
      add
      swap2
        /* "--CODEGEN--":98:100   */
      0x20
        /* "--CODEGEN--":89:101   */
      swap2
      dup3
      add
      swap2
        /* "--CODEGEN--":114:126   */
      add
        /* "--CODEGEN--":36:189   */
      jump(tag_818)
    tag_819:
        /* "--CODEGEN--":274:275   */
      0x1
        /* "--CODEGEN--":267:270   */
      dup4
        /* "--CODEGEN--":263:265   */
      0x20
        /* "--CODEGEN--":259:271   */
      sub
        /* "--CODEGEN--":254:257   */
      0x100
        /* "--CODEGEN--":250:272   */
      exp
        /* "--CODEGEN--":246:276   */
      sub
        /* "--CODEGEN--":315:319   */
      dup1
        /* "--CODEGEN--":311:320   */
      not
        /* "--CODEGEN--":305:308   */
      dup3
        /* "--CODEGEN--":299:309   */
      mload
        /* "--CODEGEN--":295:321   */
      and
        /* "--CODEGEN--":356:360   */
      dup2
        /* "--CODEGEN--":350:353   */
      dup5
        /* "--CODEGEN--":344:354   */
      mload
        /* "--CODEGEN--":340:361   */
      and
        /* "--CODEGEN--":389:396   */
      dup1
        /* "--CODEGEN--":380:387   */
      dup3
        /* "--CODEGEN--":377:397   */
      or
        /* "--CODEGEN--":372:375   */
      dup6
        /* "--CODEGEN--":365:398   */
      mstore
        /* "--CODEGEN--":3:402   */
      pop
      pop
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":3855:3971  keccak256(... */
      pop
      pop
      pop
      swap1
      pop
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETHPermit.sol":3834:3971  bytes32 structHash = keccak256(... */
      swap2
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":4010:4026  getEIP712StETH() */
      tag_821
        /* "src/contracts/0.4.24/StETHPermit.sol":4010:4024  getEIP712StETH */
      tag_292
        /* "src/contracts/0.4.24/StETHPermit.sol":4010:4026  getEIP712StETH() */
      jump	// in
    tag_821:
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      0x40
      dup1
      mload
      0x804e5eb300000000000000000000000000000000000000000000000000000000
      dup2
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":4052:4056  this */
      address
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      0x4
      dup3
      add
      mstore
      0x24
      dup2
      add
      dup6
      swap1
      mstore
      swap1
      mload
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4043  IEIP712StETH(getEIP712StETH()).hashTypedDataV4 */
      swap3
      swap1
      swap3
      and
      swap2
      0x804e5eb3
      swap2
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      0x44
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
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4043  IEIP712StETH(getEIP712StETH()).hashTypedDataV4 */
      dup8
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":5:7   */
      dup1
      iszero
      tag_822
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_822:
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_823
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_823:
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_824
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_824:
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      mload
      swap1
      pop
        /* "src/contracts/0.4.24/StETHPermit.sol":4089:4146  SignatureUtils.isValidSignature(_owner, hash, _v, _r, _s) */
      tag_825
        /* "src/contracts/0.4.24/StETHPermit.sol":4121:4127  _owner */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":3997:4070  IEIP712StETH(getEIP712StETH()).hashTypedDataV4(address(this), structHash) */
      dup3
        /* "src/contracts/0.4.24/StETHPermit.sol":4135:4137  _v */
      dup8
        /* "src/contracts/0.4.24/StETHPermit.sol":4139:4141  _r */
      dup8
        /* "src/contracts/0.4.24/StETHPermit.sol":4143:4145  _s */
      dup8
        /* "src/contracts/0.4.24/StETHPermit.sol":4089:4120  SignatureUtils.isValidSignature */
      tag_826
        /* "src/contracts/0.4.24/StETHPermit.sol":4089:4146  SignatureUtils.isValidSignature(_owner, hash, _v, _r, _s) */
      jump	// in
    tag_825:
        /* "src/contracts/0.4.24/StETHPermit.sol":4081:4168  require(SignatureUtils.isValidSignature(_owner, hash, _v, _r, _s), "INVALID_SIGNATURE") */
      iszero
      iszero
      tag_827
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x11
      0x24
      dup3
      add
      mstore
      0x494e56414c49445f5349474e4154555245000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_827:
        /* "src/contracts/0.4.24/StETHPermit.sol":4178:4212  _approve(_owner, _spender, _value) */
      tag_497
        /* "src/contracts/0.4.24/StETHPermit.sol":4187:4193  _owner */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":4195:4203  _spender */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":4205:4211  _value */
      dup10
        /* "src/contracts/0.4.24/StETHPermit.sol":4178:4186  _approve */
      tag_431
        /* "src/contracts/0.4.24/StETHPermit.sol":4178:4212  _approve(_owner, _spender, _value) */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":7968:8103  function allowance(address _owner, address _spender) public view returns (uint256) {... */
    tag_333:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":8068:8086  allowances[_owner] */
      swap2
      dup3
      and
        /* "src/contracts/0.4.24/StETH.sol":8042:8049  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":8068:8086  allowances[_owner] */
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":8068:8078  allowances */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":8068:8086  allowances[_owner] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":8068:8096  allowances[_owner][_spender] */
      swap4
      swap1
      swap5
      and
      dup3
      mstore
      swap2
      swap1
      swap2
      mstore
      keccak256
      sload
      swap1
        /* "src/contracts/0.4.24/StETH.sol":7968:8103  function allowance(address _owner, address _spender) public view returns (uint256) {... */
      jump	// out
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":286:403  function isPetrified() public view returns (bool) {... */
    tag_336:
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":330:334  bool */
      0x0
      not(0x0)
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":353:377  getInitializationBlock() */
      tag_831
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":353:375  getInitializationBlock */
      tag_273
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":353:377  getInitializationBlock() */
      jump	// in
    tag_831:
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":353:396  getInitializationBlock() == PETRIFIED_BLOCK */
      eq
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":346:396  return getInitializationBlock() == PETRIFIED_BLOCK */
      swap1
      pop
        /* "src/@aragon/os/contracts/common/Petrifiable.sol":286:403  function isPetrified() public view returns (bool) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":30771:30893  function getExternalEther() external view returns (uint256) {... */
    tag_339:
        /* "src/contracts/0.4.24/Lido.sol":30822:30829  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":30848:30886  _getExternalEther(_getInternalEther()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":30866:30885  _getInternalEther() */
      tag_834
        /* "src/contracts/0.4.24/Lido.sol":30866:30883  _getInternalEther */
      tag_835
        /* "src/contracts/0.4.24/Lido.sol":30866:30885  _getInternalEther() */
      jump	// in
    tag_834:
        /* "src/contracts/0.4.24/Lido.sol":30848:30865  _getExternalEther */
      tag_836
        /* "src/contracts/0.4.24/Lido.sol":30848:30886  _getExternalEther(_getInternalEther()) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":31868:31972  function getLidoLocator() external view returns (ILidoLocator) {... */
    tag_342:
        /* "src/contracts/0.4.24/Lido.sol":31917:31929  ILidoLocator */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":31948:31965  _getLidoLocator() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":31948:31963  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":31948:31965  _getLidoLocator() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":37595:37724  function canDeposit() public view returns (bool) {... */
    tag_345:
        /* "src/contracts/0.4.24/Lido.sol":37638:37642  bool */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":37662:37680  _withdrawalQueue() */
      tag_840
        /* "src/contracts/0.4.24/Lido.sol":37662:37678  _withdrawalQueue */
      tag_841
        /* "src/contracts/0.4.24/Lido.sol":37662:37680  _withdrawalQueue() */
      jump	// in
    tag_840:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":37662:37699  _withdrawalQueue().isBunkerModeActive */
      and
      0x2b95b781
        /* "src/contracts/0.4.24/Lido.sol":37662:37701  _withdrawalQueue().isBunkerModeActive() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_842
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_842:
        /* "src/contracts/0.4.24/Lido.sol":37662:37701  _withdrawalQueue().isBunkerModeActive() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_843
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_843:
        /* "src/contracts/0.4.24/Lido.sol":37662:37701  _withdrawalQueue().isBunkerModeActive() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_844
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_844:
      pop
        /* "src/contracts/0.4.24/Lido.sol":37662:37701  _withdrawalQueue().isBunkerModeActive() */
      mload
        /* "src/contracts/0.4.24/Lido.sol":37661:37701  !_withdrawalQueue().isBunkerModeActive() */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":37661:37717  !_withdrawalQueue().isBunkerModeActive() && !isStopped() */
      dup1
      iszero
      tag_437
      jumpi
      pop
        /* "src/contracts/0.4.24/Lido.sol":37706:37717  isStopped() */
      tag_551
        /* "src/contracts/0.4.24/Lido.sol":37706:37715  isStopped */
      tag_187
        /* "src/contracts/0.4.24/Lido.sol":37706:37717  isStopped() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":4129:4240  bytes32 public constant STAKING_PAUSE_ROLE = 0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
    tag_348:
        /* "src/contracts/0.4.24/Lido.sol":4174:4240  0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
      0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8
        /* "src/contracts/0.4.24/Lido.sol":4129:4240  bytes32 public constant STAKING_PAUSE_ROLE = 0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
      dup2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":28109:28256  function getDepositsReserve() external view returns (uint256 depositsReserve) {... */
    tag_351:
        /* "src/contracts/0.4.24/Lido.sol":28162:28185  uint256 depositsReserve */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":28204:28233  _getBufferedEtherAllocation() */
      tag_848
        /* "src/contracts/0.4.24/Lido.sol":28204:28231  _getBufferedEtherAllocation */
      tag_705
        /* "src/contracts/0.4.24/Lido.sol":28204:28233  _getBufferedEtherAllocation() */
      jump	// in
    tag_848:
        /* "src/contracts/0.4.24/Lido.sol":28204:28249  _getBufferedEtherAllocation().depositsReserve */
      0x40
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":28197:28249  return _getBufferedEtherAllocation().depositsReserve */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":28109:28256  function getDepositsReserve() external view returns (uint256 depositsReserve) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":37937:38075  function getDepositableEther() external view returns (uint256) {... */
    tag_354:
        /* "src/contracts/0.4.24/Lido.sol":37991:37998  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":38017:38068  _getDepositableEther(_getBufferedEtherAllocation()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":38038:38067  _getBufferedEtherAllocation() */
      tag_851
        /* "src/contracts/0.4.24/Lido.sol":38038:38065  _getBufferedEtherAllocation */
      tag_705
        /* "src/contracts/0.4.24/Lido.sol":38038:38067  _getBufferedEtherAllocation() */
      jump	// in
    tag_851:
        /* "src/contracts/0.4.24/Lido.sol":38017:38037  _getDepositableEther */
      tag_852
        /* "src/contracts/0.4.24/Lido.sol":38017:38068  _getDepositableEther(_getBufferedEtherAllocation()) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":21837:22004  function setMaxExternalRatioBP(uint256 _maxExternalRatioBP) external {... */
    tag_357:
        /* "src/contracts/0.4.24/Lido.sol":21916:21943  _auth(STAKING_CONTROL_ROLE) */
      tag_854
      0x0
      dup1
      mload
      0x20
      data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":21916:21921  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":21916:21943  _auth(STAKING_CONTROL_ROLE) */
      jump	// in
    tag_854:
        /* "src/contracts/0.4.24/Lido.sol":21954:21997  _setMaxExternalRatioBP(_maxExternalRatioBP) */
      tag_434
        /* "src/contracts/0.4.24/Lido.sol":21977:21996  _maxExternalRatioBP */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":21954:21976  _setMaxExternalRatioBP */
      tag_856
        /* "src/contracts/0.4.24/Lido.sol":21954:21997  _setMaxExternalRatioBP(_maxExternalRatioBP) */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":12064:12175  function sharesOf(address _account) external view returns (uint256) {... */
    tag_360:
        /* "src/contracts/0.4.24/StETH.sol":12123:12130  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":12149:12168  _sharesOf(_account) */
      tag_381
        /* "src/contracts/0.4.24/StETH.sol":12159:12167  _account */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":12149:12158  _sharesOf */
      tag_617
        /* "src/contracts/0.4.24/StETH.sol":12149:12168  _sharesOf(_account) */
      jump	// in
        /* "src/ConversionHarness.sol":348:373  address public controller */
    tag_363:
      and(sub(exp(0x2, 0xa0), 0x1), sload(0x3))
      dup2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":16535:16691  function pauseStaking() external {... */
    tag_366:
        /* "src/contracts/0.4.24/Lido.sol":16578:16603  _auth(STAKING_PAUSE_ROLE) */
      tag_860
        /* "src/contracts/0.4.24/Lido.sol":4174:4240  0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8 */
      0x84ea57490227bc2be925c684e2a367071d69890b629590198f4125a018eb1de8
        /* "src/contracts/0.4.24/Lido.sol":16578:16583  _auth */
      tag_393
        /* "src/contracts/0.4.24/Lido.sol":16578:16603  _auth(STAKING_PAUSE_ROLE) */
      jump	// in
    tag_860:
        /* "src/contracts/0.4.24/Lido.sol":16622:16639  isStakingPaused() */
      tag_861
        /* "src/contracts/0.4.24/Lido.sol":16622:16637  isStakingPaused */
      tag_145
        /* "src/contracts/0.4.24/Lido.sol":16622:16639  isStakingPaused() */
      jump	// in
    tag_861:
        /* "src/contracts/0.4.24/Lido.sol":16621:16639  !isStakingPaused() */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":16613:16658  require(!isStakingPaused(), "ALREADY_PAUSED") */
      tag_420
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xe
      0x24
      dup3
      add
      mstore
      0x414c52454144595f504155534544000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":31659:31806  function getTotalELRewardsCollected() public view returns (uint256) {... */
    tag_369:
        /* "src/contracts/0.4.24/Lido.sol":31718:31725  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":31744:31799  TOTAL_EL_REWARDS_COLLECTED_POSITION.getStorageUint256() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":7928:7994  0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb */
      0xafe016039542d12eec0183bb0b1ffc2ca45b027126a494672fba4154ee77facb
        /* "src/contracts/0.4.24/Lido.sol":31744:31797  TOTAL_EL_REWARDS_COLLECTED_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":31744:31799  TOTAL_EL_REWARDS_COLLECTED_POSITION.getStorageUint256() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":62433:63187  function _decreaseStakingLimit(uint256 _amount) internal {... */
    tag_373:
        /* "src/contracts/0.4.24/Lido.sol":62500:62542  StakeLimitState.Data memory stakeLimitData */
      tag_866
      jump	// in(tag_600)
    tag_866:
        /* "src/contracts/0.4.24/Lido.sol":62873:62898  uint256 currentStakeLimit */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":62545:62596  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_868
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":62545:62594  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":62545:62596  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_868:
        /* "src/contracts/0.4.24/Lido.sol":62500:62596  StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":62757:62789  stakeLimitData.isStakingPaused() */
      tag_869
        /* "src/contracts/0.4.24/Lido.sol":62757:62771  stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62757:62787  stakeLimitData.isStakingPaused */
      tag_479
        /* "src/contracts/0.4.24/Lido.sol":62757:62789  stakeLimitData.isStakingPaused() */
      jump	// in
    tag_869:
        /* "src/contracts/0.4.24/Lido.sol":62756:62789  !stakeLimitData.isStakingPaused() */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":62748:62808  require(!stakeLimitData.isStakingPaused(), "STAKING_PAUSED") */
      tag_870
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xe
      0x24
      dup3
      add
      mstore
      0x5354414b494e475f504155534544000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_870:
        /* "src/contracts/0.4.24/Lido.sol":62823:62857  stakeLimitData.isStakingLimitSet() */
      tag_871
        /* "src/contracts/0.4.24/Lido.sol":62823:62837  stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62823:62855  stakeLimitData.isStakingLimitSet */
      tag_605
        /* "src/contracts/0.4.24/Lido.sol":62823:62857  stakeLimitData.isStakingLimitSet() */
      jump	// in
    tag_871:
        /* "src/contracts/0.4.24/Lido.sol":62819:63181  if (stakeLimitData.isStakingLimitSet()) {... */
      iszero
      tag_700
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":62901:62944  stakeLimitData.calculateCurrentStakeLimit() */
      tag_873
        /* "src/contracts/0.4.24/Lido.sol":62901:62915  stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62901:62942  stakeLimitData.calculateCurrentStakeLimit */
      tag_874
        /* "src/contracts/0.4.24/Lido.sol":62901:62944  stakeLimitData.calculateCurrentStakeLimit() */
      jump	// in
    tag_873:
        /* "src/contracts/0.4.24/Lido.sol":62873:62944  uint256 currentStakeLimit = stakeLimitData.calculateCurrentStakeLimit() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":62966:62994  _amount <= currentStakeLimit */
      dup1
      dup4
      gt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":62958:63010  require(_amount <= currentStakeLimit, "STAKE_LIMIT") */
      tag_875
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xb
      0x24
      dup3
      add
      mstore
      0x5354414b455f4c494d4954000000000000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_875:
        /* "src/contracts/0.4.24/Lido.sol":63025:63170  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      tag_700
        /* "src/contracts/0.4.24/Lido.sol":63092:63156  stakeLimitData.updatePrevStakeLimit(currentStakeLimit - _amount) */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":63092:63106  stakeLimitData */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":63128:63155  currentStakeLimit - _amount */
      dup6
      dup5
      sub
        /* "src/contracts/0.4.24/Lido.sol":63092:63156  stakeLimitData.updatePrevStakeLimit(currentStakeLimit - _amount) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":63092:63127  stakeLimitData.updatePrevStakeLimit */
      tag_878
        /* "src/contracts/0.4.24/Lido.sol":63092:63156  stakeLimitData.updatePrevStakeLimit(currentStakeLimit - _amount) */
      and
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":20558:21614  function _mintShares(address _recipient, uint256 _sharesAmount) internal returns (uint256 newTotalShares) {... */
    tag_376:
        /* "src/contracts/0.4.24/StETH.sol":20640:20662  uint256 newTotalShares */
      0x0
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":20682:20706  _recipient != address(0) */
      dup4
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":20674:20728  require(_recipient != address(0), "MINT_TO_ZERO_ADDR") */
      tag_880
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x11
      0x24
      dup3
      add
      mstore
      0x4d494e545f544f5f5a45524f5f41444452000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_880:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":20746:20773  _recipient != address(this) */
      dup4
      and
        /* "src/contracts/0.4.24/StETH.sol":20768:20772  this */
      address
        /* "src/contracts/0.4.24/StETH.sol":20746:20773  _recipient != address(this) */
      eq
      iszero
        /* "src/contracts/0.4.24/StETH.sol":20738:20800  require(_recipient != address(this), "MINT_TO_STETH_CONTRACT") */
      tag_881
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x16
      0x24
      dup3
      add
      mstore
      0x4d494e545f544f5f53544554485f434f4e545241435400000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_881:
        /* "src/contracts/0.4.24/StETH.sol":20828:20864  _getTotalShares().add(_sharesAmount) */
      tag_882
        /* "src/contracts/0.4.24/StETH.sol":20850:20863  _sharesAmount */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":20828:20845  _getTotalShares() */
      tag_491
        /* "src/contracts/0.4.24/StETH.sol":20828:20843  _getTotalShares */
      tag_813
        /* "src/contracts/0.4.24/StETH.sol":20828:20845  _getTotalShares() */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":20828:20864  _getTotalShares().add(_sharesAmount) */
    tag_882:
        /* "src/contracts/0.4.24/StETH.sol":20811:20864  newTotalShares = _getTotalShares().add(_sharesAmount) */
      swap1
      pop
      not(0xffffffffffffffffffffffffffffffff)
        /* "src/contracts/0.4.24/StETH.sol":20882:20916  newTotalShares & UINT128_HIGH_MASK */
      dup2
      and
        /* "src/contracts/0.4.24/StETH.sol":20882:20921  newTotalShares & UINT128_HIGH_MASK == 0 */
      iszero
        /* "src/contracts/0.4.24/StETH.sol":20874:20941  require(newTotalShares & UINT128_HIGH_MASK == 0, "SHARES_OVERFLOW") */
      tag_884
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x5348415245535f4f564552464c4f570000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_884:
        /* "src/contracts/0.4.24/StETH.sol":20952:21010  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      tag_885
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":20995:21009  newTotalShares */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":20952:21010  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":20952:20994  TOTAL_SHARES_POSITION_LOW128.setLowUint128 */
      tag_886
        /* "src/contracts/0.4.24/StETH.sol":20952:21010  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      and
      jump	// in
    tag_885:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":21042:21060  shares[_recipient] */
      dup4
      and
        /* "src/contracts/0.4.24/StETH.sol":21042:21048  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":21042:21060  shares[_recipient] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":21042:21079  shares[_recipient].add(_sharesAmount) */
      tag_887
      swap1
        /* "src/contracts/0.4.24/StETH.sol":21065:21078  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":21042:21079  shares[_recipient].add(_sharesAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":21042:21064  shares[_recipient].add */
      tag_493
        /* "src/contracts/0.4.24/StETH.sol":21042:21079  shares[_recipient].add(_sharesAmount) */
      and
      jump	// in
    tag_887:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":21021:21039  shares[_recipient] */
      swap1
      swap4
      and
        /* "src/contracts/0.4.24/StETH.sol":21021:21027  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":21021:21039  shares[_recipient] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":21021:21079  shares[_recipient] = shares[_recipient].add(_sharesAmount) */
      swap3
      swap1
      swap3
      sstore
      pop
        /* "src/contracts/0.4.24/StETH.sol":20558:21614  function _mintShares(address _recipient, uint256 _sharesAmount) internal returns (uint256 newTotalShares) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":67468:67618  function _getBufferedEther() internal view returns (uint256) {... */
    tag_379:
        /* "src/contracts/0.4.24/Lido.sol":67520:67527  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":67546:67611  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowUint128() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67546:67609  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowUint128 */
      tag_890
        /* "src/contracts/0.4.24/Lido.sol":67546:67611  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowUint128() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":67981:68143  function _setBufferedEther(uint256 _newBufferedEther) internal {... */
    tag_380:
        /* "src/contracts/0.4.24/Lido.sol":68054:68136  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowUint128(_newBufferedEther) */
      tag_434
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":68118:68135  _newBufferedEther */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":68054:68136  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowUint128(_newBufferedEther) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":68054:68117  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowUint128 */
      tag_886
        /* "src/contracts/0.4.24/Lido.sol":68054:68136  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowUint128(_newBufferedEther) */
      and
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":22916:23107  function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount) internal {... */
    tag_382:
        /* "src/contracts/0.4.24/StETH.sol":23012:23100  _emitTransferEvents(address(0), _to, getPooledEthByShares(_sharesAmount), _sharesAmount) */
      tag_568
        /* "src/contracts/0.4.24/StETH.sol":23040:23041  0 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":23044:23047  _to */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":23049:23084  getPooledEthByShares(_sharesAmount) */
      tag_895
        /* "src/contracts/0.4.24/StETH.sol":23070:23083  _sharesAmount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":23049:23069  getPooledEthByShares */
      tag_236
        /* "src/contracts/0.4.24/StETH.sol":23049:23084  getPooledEthByShares(_sharesAmount) */
      jump	// in
    tag_895:
        /* "src/contracts/0.4.24/StETH.sol":23086:23099  _sharesAmount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":23012:23031  _emitTransferEvents */
      tag_613
        /* "src/contracts/0.4.24/StETH.sol":23012:23100  _emitTransferEvents(address(0), _to, getPooledEthByShares(_sharesAmount), _sharesAmount) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":59538:59647  function _getShareRateNumerator() internal view returns (uint256) {... */
    tag_386:
        /* "src/contracts/0.4.24/Lido.sol":59595:59602  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":59621:59640  _getInternalEther() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":59621:59638  _getInternalEther */
      tag_835
        /* "src/contracts/0.4.24/Lido.sol":59621:59640  _getInternalEther() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":59774:60077  function _getShareRateDenominator() internal view returns (uint256) {... */
    tag_388:
        /* "src/contracts/0.4.24/Lido.sol":59833:59840  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":59853:59872  uint256 totalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":59874:59896  uint256 externalShares */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":59938:59960  uint256 internalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":59900:59928  _getTotalAndExternalShares() */
      tag_899
        /* "src/contracts/0.4.24/Lido.sol":59900:59926  _getTotalAndExternalShares */
      tag_900
        /* "src/contracts/0.4.24/Lido.sol":59900:59928  _getTotalAndExternalShares() */
      jump	// in
    tag_899:
        /* "src/contracts/0.4.24/Lido.sol":59852:59928  (uint256 totalShares, uint256 externalShares) = _getTotalAndExternalShares() */
      swap3
      pop
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":59977:59991  externalShares */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":59963:59974  totalShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":59963:59991  totalShares - externalShares */
      sub
        /* "src/contracts/0.4.24/Lido.sol":59938:59991  uint256 internalShares = totalShares - externalShares */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":60056:60070  internalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":60049:60070  return internalShares */
      swap4
      pop
        /* "src/contracts/0.4.24/Lido.sol":59774:60077  function _getShareRateDenominator() internal view returns (uint256) {... */
    tag_898:
      pop
      pop
      pop
      swap1
      jump	// out
        /* "src/contracts/common/lib/Math256.sol":1161:1355  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {... */
    tag_390:
        /* "src/contracts/common/lib/Math256.sol":1223:1230  uint256 */
      0x0
        /* "src/contracts/common/lib/Math256.sol":1320:1326  a == 0 */
      dup3
      iszero
        /* "src/contracts/common/lib/Math256.sol":1320:1348  a == 0 ? 0 : (a - 1) / b + 1 */
      tag_902
      jumpi
        /* "src/contracts/common/lib/Math256.sol":1343:1344  b */
      dup2
        /* "src/contracts/common/lib/Math256.sol":1338:1339  1 */
      0x1
        /* "src/contracts/common/lib/Math256.sol":1334:1335  a */
      dup5
        /* "src/contracts/common/lib/Math256.sol":1334:1339  a - 1 */
      sub
        /* "src/contracts/common/lib/Math256.sol":1333:1344  (a - 1) / b */
      dup2
      iszero
      iszero
      tag_903
      jumpi
      invalid
    tag_903:
      div
        /* "src/contracts/common/lib/Math256.sol":1347:1348  1 */
      0x1
        /* "src/contracts/common/lib/Math256.sol":1333:1348  (a - 1) / b + 1 */
      add
        /* "src/contracts/common/lib/Math256.sol":1320:1348  a == 0 ? 0 : (a - 1) / b + 1 */
      jump(tag_728)
    tag_902:
        /* "src/contracts/common/lib/Math256.sol":1329:1330  0 */
      0x0
        /* "src/contracts/common/lib/Math256.sol":1313:1348  return a == 0 ? 0 : (a - 1) / b + 1 */
      swap4
        /* "src/contracts/common/lib/Math256.sol":1161:1355  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":63904:64040  function _auth(bytes32 _role) internal view {... */
    tag_393:
        /* "src/contracts/0.4.24/Lido.sol":63996:64012  new uint256[](0) */
      0x40
      dup1
      mload
        /* "src/contracts/0.4.24/Lido.sol":64010:64011  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":63996:64012  new uint256[](0) */
      dup2
      mstore
      0x20
      dup2
      add
      swap1
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":63966:64013  canPerform(msg.sender, _role, new uint256[](0)) */
      tag_906
      swap1
        /* "src/contracts/0.4.24/Lido.sol":63977:63987  msg.sender */
      caller
      swap1
        /* "src/contracts/0.4.24/Lido.sol":63989:63994  _role */
      dup4
      swap1
        /* "src/contracts/0.4.24/Lido.sol":63966:63976  canPerform */
      tag_301
        /* "src/contracts/0.4.24/Lido.sol":63966:64013  canPerform(msg.sender, _role, new uint256[](0)) */
      jump	// in
    tag_906:
        /* "src/contracts/0.4.24/Lido.sol":63958:64033  require(canPerform(msg.sender, _role, new uint256[](0)), "APP_AUTH_FAILED") */
      iszero
      iszero
      tag_434
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x4150505f415554485f4641494c45440000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/utils/Pausable.sol":1012:1147  function _resume() internal {... */
    tag_395:
        /* "src/contracts/0.4.24/utils/Pausable.sol":1050:1064  _whenStopped() */
      tag_910
        /* "src/contracts/0.4.24/utils/Pausable.sol":1050:1062  _whenStopped */
      tag_911
        /* "src/contracts/0.4.24/utils/Pausable.sol":1050:1064  _whenStopped() */
      jump	// in
    tag_910:
        /* "src/contracts/0.4.24/utils/Pausable.sol":1075:1116  ACTIVE_FLAG_POSITION.setStorageBool(true) */
      tag_912
      0x0
      dup1
      mload
      0x20
      data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/utils/Pausable.sol":1111:1115  true */
      0x1
        /* "src/contracts/0.4.24/utils/Pausable.sol":1075:1116  ACTIVE_FLAG_POSITION.setStorageBool(true) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/Pausable.sol":1075:1110  ACTIVE_FLAG_POSITION.setStorageBool */
      tag_562
        /* "src/contracts/0.4.24/utils/Pausable.sol":1075:1116  ACTIVE_FLAG_POSITION.setStorageBool(true) */
      and
      jump	// in
    tag_912:
        /* "src/contracts/0.4.24/utils/Pausable.sol":1131:1140  Resumed() */
      mload(0x40)
      0x62451d457bc659158be6e6247f56ec1df424a5c7597f71c20c2bc44e0965c8f9
      swap1
      0x0
      swap1
      log1
        /* "src/contracts/0.4.24/utils/Pausable.sol":1012:1147  function _resume() internal {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":61745:61984  function _resumeStaking() internal {... */
    tag_397:
        /* "src/contracts/0.4.24/Lido.sol":61790:61945  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      tag_915
        /* "src/contracts/0.4.24/Lido.sol":61853:61935  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(false) */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":61929:61934  false */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":61853:61904  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_917
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":61853:61902  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":61853:61904  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_917:
        /* "src/contracts/0.4.24/Lido.sol":61853:61928  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState */
      swap1
        /* "src/contracts/0.4.24/Lido.sol":61853:61935  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(false) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":61853:61928  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState */
      tag_918
        /* "src/contracts/0.4.24/Lido.sol":61853:61935  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(false) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":61790:61945  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
    tag_915:
        /* "src/contracts/0.4.24/Lido.sol":61961:61977  StakingResumed() */
      mload(0x40)
      0xedaeeae9aed70c4545d3ab0065713261c9cee8d6cf5c8b07f52f0a65fd91efda
      swap1
      0x0
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":61745:61984  function _resumeStaking() internal {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":64647:64752  function _vaultHub() internal view returns (address) {... */
    tag_402:
        /* "src/contracts/0.4.24/Lido.sol":64691:64698  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64717:64734  _getLidoLocator() */
      tag_920
        /* "src/contracts/0.4.24/Lido.sol":64717:64732  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":64717:64734  _getLidoLocator() */
      jump	// in
    tag_920:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64717:64743  _getLidoLocator().vaultHub */
      and
      0x6dd6e80b
        /* "src/contracts/0.4.24/Lido.sol":64717:64745  _getLidoLocator().vaultHub() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":64085:64199  function _auth(address _address) internal view {... */
    tag_403:
        /* "src/contracts/0.4.24/Lido.sol":64150:64160  msg.sender */
      caller
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64150:64172  msg.sender == _address */
      dup3
      and
      eq
        /* "src/contracts/0.4.24/Lido.sol":64142:64192  require(msg.sender == _address, "APP_AUTH_FAILED") */
      tag_434
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0xf
      0x24
      dup3
      add
      mstore
      0x4150505f415554485f4641494c45440000000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/utils/Pausable.sol":490:617  function _whenNotStopped() internal view {... */
    tag_405:
        /* "src/contracts/0.4.24/utils/Pausable.sol":549:586  ACTIVE_FLAG_POSITION.getStorageBool() */
      tag_927
      0x0
      dup1
      mload
      0x20
      data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/utils/Pausable.sol":549:584  ACTIVE_FLAG_POSITION.getStorageBool */
      tag_438
        /* "src/contracts/0.4.24/utils/Pausable.sol":549:586  ACTIVE_FLAG_POSITION.getStorageBool() */
      jump	// in
    tag_927:
        /* "src/contracts/0.4.24/utils/Pausable.sol":541:610  require(ACTIVE_FLAG_POSITION.getStorageBool(), "CONTRACT_IS_STOPPED") */
      iszero
      iszero
      tag_396
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x13
      0x24
      dup3
      add
      mstore
      0x434f4e54524143545f49535f53544f5050454400000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":60964:61497  function _getMaxMintableExternalShares() internal view returns (uint256) {... */
    tag_407:
        /* "src/contracts/0.4.24/Lido.sol":61028:61035  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":61047:61065  uint256 maxRatioBP */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":61209:61228  uint256 totalShares */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":61230:61252  uint256 externalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":61068:61092  _getMaxExternalRatioBP() */
      tag_930
        /* "src/contracts/0.4.24/Lido.sol":61068:61090  _getMaxExternalRatioBP */
      tag_764
        /* "src/contracts/0.4.24/Lido.sol":61068:61092  _getMaxExternalRatioBP() */
      jump	// in
    tag_930:
        /* "src/contracts/0.4.24/Lido.sol":61047:61092  uint256 maxRatioBP = _getMaxExternalRatioBP() */
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":61106:61121  maxRatioBP == 0 */
      dup3
      iszero
        /* "src/contracts/0.4.24/Lido.sol":61102:61131  if (maxRatioBP == 0) return 0 */
      iszero
      tag_931
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":61130:61131  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":61123:61131  return 0 */
      swap4
      pop
      jump(tag_898)
        /* "src/contracts/0.4.24/Lido.sol":61102:61131  if (maxRatioBP == 0) return 0 */
    tag_931:
        /* "src/contracts/0.4.24/Lido.sol":4718:4723  10000 */
      0x2710
        /* "src/contracts/0.4.24/Lido.sol":61145:61155  maxRatioBP */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":61145:61177  maxRatioBP == TOTAL_BASIS_POINTS */
      eq
        /* "src/contracts/0.4.24/Lido.sol":61141:61197  if (maxRatioBP == TOTAL_BASIS_POINTS) return uint256(-1) */
      iszero
      tag_932
      jumpi
      not(0x0)
        /* "src/contracts/0.4.24/Lido.sol":61179:61197  return uint256(-1) */
      swap4
      pop
      jump(tag_898)
        /* "src/contracts/0.4.24/Lido.sol":61141:61197  if (maxRatioBP == TOTAL_BASIS_POINTS) return uint256(-1) */
    tag_932:
        /* "src/contracts/0.4.24/Lido.sol":61256:61284  _getTotalAndExternalShares() */
      tag_933
        /* "src/contracts/0.4.24/Lido.sol":61256:61282  _getTotalAndExternalShares */
      tag_900
        /* "src/contracts/0.4.24/Lido.sol":61256:61284  _getTotalAndExternalShares() */
      jump	// in
    tag_933:
        /* "src/contracts/0.4.24/Lido.sol":61208:61284  (uint256 totalShares, uint256 externalShares) = _getTotalAndExternalShares() */
      swap1
      swap3
      pop
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":4718:4723  10000 */
      0x2710
        /* "src/contracts/0.4.24/Lido.sol":61327:61362  externalShares * TOTAL_BASIS_POINTS */
      dup2
      mul
        /* "src/contracts/0.4.24/Lido.sol":61299:61323  totalShares * maxRatioBP */
      dup4
      dup4
      mul
        /* "src/contracts/0.4.24/Lido.sol":61299:61362  totalShares * maxRatioBP <= externalShares * TOTAL_BASIS_POINTS */
      gt
        /* "src/contracts/0.4.24/Lido.sol":61295:61372  if (totalShares * maxRatioBP <= externalShares * TOTAL_BASIS_POINTS) return 0 */
      tag_934
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":61371:61372  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":61364:61372  return 0 */
      swap4
      pop
      jump(tag_898)
        /* "src/contracts/0.4.24/Lido.sol":61295:61372  if (totalShares * maxRatioBP <= externalShares * TOTAL_BASIS_POINTS) return 0 */
    tag_934:
        /* "src/contracts/0.4.24/Lido.sol":61479:61489  maxRatioBP */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":4718:4723  10000 */
      0x2710
        /* "src/contracts/0.4.24/Lido.sol":61458:61489  TOTAL_BASIS_POINTS - maxRatioBP */
      sub
        /* "src/contracts/0.4.24/Lido.sol":4718:4723  10000 */
      0x2710
        /* "src/contracts/0.4.24/Lido.sol":61418:61432  externalShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":61418:61453  externalShares * TOTAL_BASIS_POINTS */
      mul
        /* "src/contracts/0.4.24/Lido.sol":61405:61415  maxRatioBP */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":61391:61402  totalShares */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":61391:61415  totalShares * maxRatioBP */
      mul
        /* "src/contracts/0.4.24/Lido.sol":61391:61453  totalShares * maxRatioBP - externalShares * TOTAL_BASIS_POINTS */
      sub
        /* "src/contracts/0.4.24/Lido.sol":61390:61490  (totalShares * maxRatioBP - externalShares * TOTAL_BASIS_POINTS) / (TOTAL_BASIS_POINTS - maxRatioBP) */
      dup2
      iszero
      iszero
      tag_935
      jumpi
      invalid
    tag_935:
      div
        /* "src/contracts/0.4.24/Lido.sol":61383:61490  return (totalShares * maxRatioBP - externalShares * TOTAL_BASIS_POINTS) / (TOTAL_BASIS_POINTS - maxRatioBP) */
      swap4
      pop
        /* "src/contracts/0.4.24/Lido.sol":60964:61497  function _getMaxMintableExternalShares() internal view returns (uint256) {... */
      pop
      pop
      pop
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":66938:67075  function _getExternalShares() internal view returns (uint256) {... */
    tag_413:
        /* "src/contracts/0.4.24/Lido.sol":66991:66998  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":67017:67068  TOTAL_AND_EXTERNAL_SHARES_POSITION.getHighUint128() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67017:67066  TOTAL_AND_EXTERNAL_SHARES_POSITION.getHighUint128 */
      tag_938
        /* "src/contracts/0.4.24/Lido.sol":67017:67068  TOTAL_AND_EXTERNAL_SHARES_POSITION.getHighUint128() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":67081:67226  function _setExternalShares(uint256 _externalShares) internal {... */
    tag_414:
        /* "src/contracts/0.4.24/Lido.sol":67153:67219  TOTAL_AND_EXTERNAL_SHARES_POSITION.setHighUint128(_externalShares) */
      tag_434
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67203:67218  _externalShares */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":67153:67219  TOTAL_AND_EXTERNAL_SHARES_POSITION.setHighUint128(_externalShares) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":67153:67202  TOTAL_AND_EXTERNAL_SHARES_POSITION.setHighUint128 */
      tag_941
        /* "src/contracts/0.4.24/Lido.sol":67153:67219  TOTAL_AND_EXTERNAL_SHARES_POSITION.setHighUint128(_externalShares) */
      and
      jump	// in
        /* "src/contracts/0.4.24/utils/Pausable.sol":869:1006  function _stop() internal {... */
    tag_421:
        /* "src/contracts/0.4.24/utils/Pausable.sol":905:922  _whenNotStopped() */
      tag_943
        /* "src/contracts/0.4.24/utils/Pausable.sol":905:920  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/utils/Pausable.sol":905:922  _whenNotStopped() */
      jump	// in
    tag_943:
        /* "src/contracts/0.4.24/utils/Pausable.sol":933:975  ACTIVE_FLAG_POSITION.setStorageBool(false) */
      tag_944
      0x0
      dup1
      mload
      0x20
      data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/utils/Pausable.sol":969:974  false */
      0x0
        /* "src/contracts/0.4.24/utils/Pausable.sol":933:975  ACTIVE_FLAG_POSITION.setStorageBool(false) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/Pausable.sol":933:968  ACTIVE_FLAG_POSITION.setStorageBool */
      tag_562
        /* "src/contracts/0.4.24/utils/Pausable.sol":933:975  ACTIVE_FLAG_POSITION.setStorageBool(false) */
      and
      jump	// in
    tag_944:
        /* "src/contracts/0.4.24/utils/Pausable.sol":990:999  Stopped() */
      mload(0x40)
      0x7acc84e34091ae817647a4c49116f5cc07f319078ba80f8f5fde37ea7e25cbd6
      swap1
      0x0
      swap1
      log1
        /* "src/contracts/0.4.24/utils/Pausable.sol":869:1006  function _stop() internal {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":61503:61739  function _pauseStaking() internal {... */
    tag_423:
        /* "src/contracts/0.4.24/Lido.sol":61547:61701  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
      tag_946
        /* "src/contracts/0.4.24/Lido.sol":61610:61691  STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(true) */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":61686:61690  true */
      0x1
        /* "src/contracts/0.4.24/Lido.sol":61610:61661  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_917
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":61610:61659  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":61610:61661  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":61547:61701  STAKING_STATE_POSITION.setStorageStakeLimitStruct(... */
    tag_946:
        /* "src/contracts/0.4.24/Lido.sol":61717:61732  StakingPaused() */
      mload(0x40)
      0x26d1807b479eaba249c1214b82e4b65bbb0cc73ee8a17901324b1ef1b5904e49
      swap1
      0x0
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":61503:61739  function _pauseStaking() internal {... */
      jump	// out
        /* "src/@aragon/os/contracts/common/TimeHelpers.sol":346:440  function getBlockNumber() internal view returns (uint256) {... */
    tag_428:
        /* "src/@aragon/os/contracts/common/TimeHelpers.sol":421:433  block.number */
      number
        /* "src/@aragon/os/contracts/common/TimeHelpers.sol":346:440  function getBlockNumber() internal view returns (uint256) {... */
      swap1
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":17783:18097  function _approve(address _owner, address _spender, uint256 _amount) internal {... */
    tag_431:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":17879:17899  _owner != address(0) */
      dup4
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":17871:17926  require(_owner != address(0), "APPROVE_FROM_ZERO_ADDR") */
      tag_951
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x16
      0x24
      dup3
      add
      mstore
      0x415050524f56455f46524f4d5f5a45524f5f4144445200000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_951:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":17944:17966  _spender != address(0) */
      dup3
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":17936:17991  require(_spender != address(0), "APPROVE_TO_ZERO_ADDR") */
      tag_952
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x415050524f56455f544f5f5a45524f5f41444452000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_952:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":18002:18020  allowances[_owner] */
      dup1
      dup5
      and
      0x0
      dup2
      dup2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":18002:18012  allowances */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":18002:18020  allowances[_owner] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":18002:18030  allowances[_owner][_spender] */
      swap5
      dup8
      and
      dup1
      dup5
      mstore
      swap5
      dup3
      mstore
      swap2
      dup3
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":18002:18040  allowances[_owner][_spender] = _amount */
      dup6
      swap1
      sstore
        /* "src/contracts/0.4.24/StETH.sol":18055:18090  Approval(_owner, _spender, _amount) */
      dup2
      mload
      dup6
      dup2
      mstore
      swap2
      mload
      0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
      swap3
      dup2
      swap1
      sub
      swap1
      swap2
      add
      swap1
      log3
        /* "src/contracts/0.4.24/StETH.sol":17783:18097  function _approve(address _owner, address _spender, uint256 _amount) internal {... */
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":29981:30665  function _setDepositsReserveTarget(uint256 _newDepositsReserveTarget) internal {... */
    tag_435:
        /* "src/contracts/0.4.24/Lido.sol":30224:30254  uint256 currentDepositsReserve */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":30070:30147  DEPOSITS_RESERVE_TARGET_POSITION.setStorageUint256(_newDepositsReserveTarget) */
      tag_954
        /* "src/contracts/0.4.24/Lido.sol":8965:9031  0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81 */
      0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81
        /* "src/contracts/0.4.24/Lido.sol":30121:30146  _newDepositsReserveTarget */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":30070:30147  DEPOSITS_RESERVE_TARGET_POSITION.setStorageUint256(_newDepositsReserveTarget) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":30070:30120  DEPOSITS_RESERVE_TARGET_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/Lido.sol":30070:30147  DEPOSITS_RESERVE_TARGET_POSITION.setStorageUint256(_newDepositsReserveTarget) */
      and
      jump	// in
    tag_954:
        /* "src/contracts/0.4.24/Lido.sol":30162:30213  DepositsReserveTargetSet(_newDepositsReserveTarget) */
      0x40
      dup1
      mload
      dup4
      dup2
      mstore
      swap1
      mload
      0x72cc060f0ebe226352283dbe16fdcdb0d674f306ad980fbfa3d4b6932fee0b1e
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":30257:30302  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      tag_955
      0x0
      dup1
      mload
      0x20
      data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":30257:30300  DEPOSITS_RESERVE_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":30257:30302  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      jump	// in
    tag_955:
        /* "src/contracts/0.4.24/Lido.sol":30224:30302  uint256 currentDepositsReserve = DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":30564:30586  currentDepositsReserve */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":30536:30561  _newDepositsReserveTarget */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":30536:30586  _newDepositsReserveTarget < currentDepositsReserve */
      lt
        /* "src/contracts/0.4.24/Lido.sol":30532:30659  if (_newDepositsReserveTarget < currentDepositsReserve) {... */
      iszero
      tag_568
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":30602:30648  _setDepositsReserve(_newDepositsReserveTarget) */
      tag_568
        /* "src/contracts/0.4.24/Lido.sol":30622:30647  _newDepositsReserveTarget */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":30602:30621  _setDepositsReserve */
      tag_958
        /* "src/contracts/0.4.24/Lido.sol":30602:30648  _setDepositsReserve(_newDepositsReserveTarget) */
      jump	// in
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":518:652  function getStorageUint256(bytes32 position) internal view returns (uint256 data) {... */
    tag_438:
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":629:644  sload(position) */
      sload
      swap1
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":619:646  { data := sload(position) } */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":66380:66932  function _bootstrapInitialHolder() internal {... */
    tag_448:
        /* "src/contracts/0.4.24/Lido.sol":66460:66464  this */
      address
        /* "src/contracts/0.4.24/Lido.sol":66452:66473  address(this).balance */
      balance
        /* "src/contracts/0.4.24/Lido.sol":66490:66502  balance != 0 */
      dup1
      iszero
      iszero
        /* "src/contracts/0.4.24/Lido.sol":66483:66503  assert(balance != 0) */
      tag_961
      jumpi
      invalid
    tag_961:
        /* "src/contracts/0.4.24/Lido.sol":66518:66535  _getTotalShares() */
      tag_962
        /* "src/contracts/0.4.24/Lido.sol":66518:66533  _getTotalShares */
      tag_813
        /* "src/contracts/0.4.24/Lido.sol":66518:66535  _getTotalShares() */
      jump	// in
    tag_962:
        /* "src/contracts/0.4.24/Lido.sol":66518:66540  _getTotalShares() == 0 */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":66514:66926  if (_getTotalShares() == 0) {... */
      iszero
      tag_434
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":66696:66722  _setBufferedEther(balance) */
      tag_964
        /* "src/contracts/0.4.24/Lido.sol":66714:66721  balance */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":66696:66713  _setBufferedEther */
      tag_380
        /* "src/contracts/0.4.24/Lido.sol":66696:66722  _setBufferedEther(balance) */
      jump	// in
    tag_964:
        /* "src/contracts/0.4.24/Lido.sol":66831:66874  Submitted(INITIAL_TOKEN_HOLDER, balance, 0) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":66872:66873  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":66831:66874  Submitted(INITIAL_TOKEN_HOLDER, balance, 0) */
      0x20
      dup3
      add
      mstore
      dup2
      mload
        /* "src/contracts/0.4.24/StETH.sol":2534:2540  0xdead */
      0xdead
      swap3
        /* "src/contracts/0.4.24/Lido.sol":66831:66874  Submitted(INITIAL_TOKEN_HOLDER, balance, 0) */
      0x96a25c8ce0baabc1fdefd93e9ed25d8e092a3332f3aa9a41722b5697231d1d1a
      swap3
      dup3
      swap1
      sub
      add
      swap1
      log2
        /* "src/contracts/0.4.24/Lido.sol":66888:66915  _mintInitialShares(balance) */
      tag_434
        /* "src/contracts/0.4.24/Lido.sol":66907:66914  balance */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":66888:66906  _mintInitialShares */
      tag_966
        /* "src/contracts/0.4.24/Lido.sol":66888:66915  _mintInitialShares(balance) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":70038:70193  function _setLidoLocator(address _newLidoLocator) internal {... */
    tag_450:
        /* "src/contracts/0.4.24/Lido.sol":70107:70186  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setLowUint160(uint160(_newLidoLocator)) */
      tag_434
      0x0
      dup1
      mload
      0x20
      data_3eb18c3a715d47bfedca2cc24f79d054a8631bb4d9c2412403ec4f54b08ff05d
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
      sub(exp(0x2, 0xa0), 0x1)
      dup4
      and
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":70107:70160  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setLowUint160 */
      tag_969
        /* "src/contracts/0.4.24/Lido.sol":70107:70186  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setLowUint160(uint160(_newLidoLocator)) */
      and
      jump	// in
        /* "src/contracts/0.4.24/StETHPermit.sol":5942:6269  function _initializeEIP712StETH(address _eip712StETH) internal {... */
    tag_452:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":6023:6049  _eip712StETH != address(0) */
      dup2
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETHPermit.sol":6015:6070  require(_eip712StETH != address(0), "ZERO_EIP712STETH") */
      tag_971
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x5a45524f5f454950373132535445544800000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_971:
        /* "src/contracts/0.4.24/StETHPermit.sol":6116:6117  0 */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":6088:6104  getEIP712StETH() */
      tag_972
        /* "src/contracts/0.4.24/StETHPermit.sol":6088:6102  getEIP712StETH */
      tag_292
        /* "src/contracts/0.4.24/StETHPermit.sol":6088:6104  getEIP712StETH() */
      jump	// in
    tag_972:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":6088:6118  getEIP712StETH() == address(0) */
      and
      eq
        /* "src/contracts/0.4.24/StETHPermit.sol":6080:6146  require(getEIP712StETH() == address(0), "EIP712STETH_ALREADY_SET") */
      tag_973
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x17
      0x24
      dup3
      add
      mstore
      0x45495037313253544554485f414c52454144595f534554000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_973:
        /* "src/contracts/0.4.24/StETHPermit.sol":6157:6210  EIP712_STETH_POSITION.setStorageAddress(_eip712StETH) */
      tag_974
        /* "src/contracts/0.4.24/StETHPermit.sol":2725:2791  0x42b2d95e1ce15ce63bf9a8d9f6312cf44b23415c977ffa3b884333422af8941c */
      0x42b2d95e1ce15ce63bf9a8d9f6312cf44b23415c977ffa3b884333422af8941c
        /* "src/contracts/0.4.24/StETHPermit.sol":6197:6209  _eip712StETH */
      dup3
        /* "src/contracts/0.4.24/StETHPermit.sol":6157:6210  EIP712_STETH_POSITION.setStorageAddress(_eip712StETH) */
      0xffffffff
        /* "src/contracts/0.4.24/StETHPermit.sol":6157:6196  EIP712_STETH_POSITION.setStorageAddress */
      tag_562
        /* "src/contracts/0.4.24/StETHPermit.sol":6157:6210  EIP712_STETH_POSITION.setStorageAddress(_eip712StETH) */
      and
      jump	// in
    tag_974:
        /* "src/contracts/0.4.24/StETHPermit.sol":6226:6262  EIP712StETHInitialized(_eip712StETH) */
      0x40
      dup1
      mload
      sub(exp(0x2, 0xa0), 0x1)
      dup4
      and
      dup2
      mstore
      swap1
      mload
      0xb80a5409082a3729c9fc139f8b41192c40e85252752df2c07caebd613086ca83
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/StETHPermit.sol":5942:6269  function _initializeEIP712StETH(address _eip712StETH) internal {... */
      pop
      jump	// out
        /* "src/contracts/0.4.24/utils/Versioned.sol":1676:1842  function _setContractVersion(uint256 version) internal {... */
    tag_454:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1741:1793  CONTRACT_VERSION_POSITION.setStorageUint256(version) */
      tag_977
        /* "src/contracts/0.4.24/utils/Versioned.sol":948:1014  0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6 */
      0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6
        /* "src/contracts/0.4.24/utils/Versioned.sol":1785:1792  version */
      dup3
        /* "src/contracts/0.4.24/utils/Versioned.sol":1741:1793  CONTRACT_VERSION_POSITION.setStorageUint256(version) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/Versioned.sol":1741:1784  CONTRACT_VERSION_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/Versioned.sol":1741:1793  CONTRACT_VERSION_POSITION.setStorageUint256(version) */
      and
      jump	// in
    tag_977:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1808:1835  ContractVersionSet(version) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
      0xfddcded6b4f4730c226821172046b48372d3cd963c159701ae1b7c3bcac541bb
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/utils/Versioned.sol":1676:1842  function _setContractVersion(uint256 version) internal {... */
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":64349:64507  function _withdrawalQueue(ILidoLocator _locator) internal view returns (IWithdrawalQueue) {... */
    tag_457:
        /* "src/contracts/0.4.24/Lido.sol":64421:64437  IWithdrawalQueue */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64473:64481  _locator */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64473:64497  _locator.withdrawalQueue */
      and
      0x37d5fe99
        /* "src/contracts/0.4.24/Lido.sol":64473:64499  _locator.withdrawalQueue() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":64758:64871  function _burner(ILidoLocator _locator) internal view returns (address) {... */
    tag_459:
        /* "src/contracts/0.4.24/Lido.sol":64821:64828  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64847:64855  _locator */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64847:64862  _locator.burner */
      and
      0x27810b6e
        /* "src/contracts/0.4.24/Lido.sol":64847:64864  _locator.burner() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/@aragon/os/contracts/common/Initializable.sol":1446:1569  function initialized() internal onlyInit {... */
    tag_462:
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
      tag_987
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:636  getInitializationBlock */
      tag_273
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:638  getInitializationBlock() */
      jump	// in
    tag_987:
        /* "src/@aragon/os/contracts/common/Initializable.sol":645:670  ERROR_ALREADY_INITIALIZED */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x18
      dup2
      mstore
      0x494e49545f414c52454144595f494e495449414c495a45440000000000000000
      0x20
      dup3
      add
      mstore
      swap1
        /* "src/@aragon/os/contracts/common/Initializable.sol":614:643  getInitializationBlock() == 0 */
      iszero
        /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
      tag_988
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x4
      add
      dup1
      dup1
      0x20
      add
      dup3
      dup2
      sub
      dup3
      mstore
      dup4
      dup2
      dup2
      mload
      dup2
      mstore
      0x20
      add
      swap2
      pop
      dup1
      mload
      swap1
      0x20
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_443
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_442)
        /* "src/@aragon/os/contracts/common/Initializable.sol":606:671  require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED) */
    tag_988:
      pop
        /* "src/@aragon/os/contracts/common/Initializable.sol":1497:1562  INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber()) */
      tag_396
        /* "src/@aragon/os/contracts/common/Initializable.sol":1545:1561  getBlockNumber() */
      tag_995
        /* "src/@aragon/os/contracts/common/Initializable.sol":1545:1559  getBlockNumber */
      tag_428
        /* "src/@aragon/os/contracts/common/Initializable.sol":1545:1561  getBlockNumber() */
      jump	// in
    tag_995:
        /* "src/@aragon/os/contracts/common/Initializable.sol":344:410  0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e */
      0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e
      swap1
        /* "src/@aragon/os/contracts/common/Initializable.sol":1497:1562  INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber()) */
      0xffffffff
        /* "src/@aragon/os/contracts/common/Initializable.sol":1497:1544  INITIALIZATION_BLOCK_POSITION.setStorageUint256 */
      tag_562
        /* "src/@aragon/os/contracts/common/Initializable.sol":1497:1562  INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber()) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":58959:59151  function _getTotalPooledEther() internal view returns (uint256) {... */
    tag_465:
        /* "src/contracts/0.4.24/Lido.sol":59014:59021  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":59033:59054  uint256 internalEther */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":59057:59076  _getInternalEther() */
      tag_997
        /* "src/contracts/0.4.24/Lido.sol":59057:59074  _getInternalEther */
      tag_835
        /* "src/contracts/0.4.24/Lido.sol":59057:59076  _getInternalEther() */
      jump	// in
    tag_997:
        /* "src/contracts/0.4.24/Lido.sol":59033:59076  uint256 internalEther = _getInternalEther() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":59093:59144  internalEther.add(_getExternalEther(internalEther)) */
      tag_426
        /* "src/contracts/0.4.24/Lido.sol":59111:59143  _getExternalEther(internalEther) */
      tag_999
        /* "src/contracts/0.4.24/Lido.sol":59129:59142  internalEther */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":59111:59128  _getExternalEther */
      tag_836
        /* "src/contracts/0.4.24/Lido.sol":59111:59143  _getExternalEther(internalEther) */
      jump	// in
    tag_999:
        /* "src/contracts/0.4.24/Lido.sol":59093:59106  internalEther */
      dup3
      swap1
        /* "src/contracts/0.4.24/Lido.sol":59093:59144  internalEther.add(_getExternalEther(internalEther)) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":59093:59110  internalEther.add */
      tag_493
        /* "src/contracts/0.4.24/Lido.sol":59093:59144  internalEther.add(_getExternalEther(internalEther)) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":65111:65220  function _accounting() internal view returns (address) {... */
    tag_474:
        /* "src/contracts/0.4.24/Lido.sol":65157:65164  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65183:65213  _accounting(_getLidoLocator()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":65195:65212  _getLidoLocator() */
      tag_1002
        /* "src/contracts/0.4.24/Lido.sol":65195:65210  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":65195:65212  _getLidoLocator() */
      jump	// in
    tag_1002:
        /* "src/contracts/0.4.24/Lido.sol":65183:65194  _accounting */
      tag_734
        /* "src/contracts/0.4.24/Lido.sol":65183:65213  _accounting(_getLidoLocator()) */
      jump	// in
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2714:3262  function getStorageStakeLimitStruct(bytes32 _position) internal view returns (StakeLimitState.Data memory stakeLimit) {... */
    tag_478:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2792:2830  StakeLimitState.Data memory stakeLimit */
      tag_1003
      jump	// in(tag_600)
    tag_1003:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2842:2859  uint256 slotValue */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2862:2891  _position.getStorageUint256() */
      tag_1005
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2862:2871  _position */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2862:2889  _position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2862:2891  _position.getStorageUint256() */
      jump	// in
    tag_1005:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2902:2987  stakeLimit.prevStakeBlockNumber = uint32(slotValue >> PREV_STAKE_BLOCK_NUMBER_OFFSET) */
      0xffffffff
      dup1
      dup3
      and
      dup5
      mstore
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3032:3068  slotValue >> PREV_STAKE_LIMIT_OFFSET */
      0x100000000
      dup4
      div
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2997:3069  stakeLimit.prevStakeLimit = uint96(slotValue >> PREV_STAKE_LIMIT_OFFSET) */
      dup2
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2451:2453  32 */
      0x20
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2997:3022  stakeLimit.prevStakeLimit */
      dup7
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2997:3069  stakeLimit.prevStakeLimit = uint96(slotValue >> PREV_STAKE_LIMIT_OFFSET) */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3125:3174  slotValue >> MAX_STAKE_LIMIT_GROWTH_BLOCKS_OFFSET */
      0x100000000000000000000000000000000
      dup4
      div
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3079:3175  stakeLimit.maxStakeLimitGrowthBlocks = uint32(slotValue >> MAX_STAKE_LIMIT_GROWTH_BLOCKS_OFFSET) */
      swap1
      swap2
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3079:3115  stakeLimit.maxStakeLimitGrowthBlocks */
      0x40
      dup6
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3079:3175  stakeLimit.maxStakeLimitGrowthBlocks = uint32(slotValue >> MAX_STAKE_LIMIT_GROWTH_BLOCKS_OFFSET) */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3219:3254  slotValue >> MAX_STAKE_LIMIT_OFFSET */
      0x10000000000000000000000000000000000000000
      swap1
      swap2
      div
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3185:3255  stakeLimit.maxStakeLimit = uint96(slotValue >> MAX_STAKE_LIMIT_OFFSET) */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3185:3209  stakeLimit.maxStakeLimit */
      0x60
      dup4
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3185:3255  stakeLimit.maxStakeLimit = uint96(slotValue >> MAX_STAKE_LIMIT_OFFSET) */
      mstore
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2902:2912  stakeLimit */
      swap2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2714:3262  function getStorageStakeLimitStruct(bytes32 _position) internal view returns (StakeLimitState.Data memory stakeLimit) {... */
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5060:5203  function isStakingPaused(StakeLimitState.Data memory _data) internal pure returns(bool) {... */
    tag_479:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5165:5191  _data.prevStakeBlockNumber */
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5165:5196  _data.prevStakeBlockNumber == 0 */
      0xffffffff
      and
      iszero
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5060:5203  function isStakingPaused(StakeLimitState.Data memory _data) internal pure returns(bool) {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":64205:64343  function _stakingRouter() internal view returns (IStakingRouter) {... */
    tag_484:
        /* "src/contracts/0.4.24/Lido.sol":64254:64268  IStakingRouter */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64302:64319  _getLidoLocator() */
      tag_1008
        /* "src/contracts/0.4.24/Lido.sol":64302:64317  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":64302:64319  _getLidoLocator() */
      jump	// in
    tag_1008:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64302:64333  _getLidoLocator().stakingRouter */
      and
      0xef6c064c
        /* "src/contracts/0.4.24/Lido.sol":64302:64335  _getLidoLocator().stakingRouter() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":38640:39911  function _spendDepositableEther(uint256 _depositAmount) internal {... */
    tag_488:
        /* "src/contracts/0.4.24/Lido.sol":38715:38756  BufferedEtherAllocation memory allocation */
      tag_1012
      jump	// in(tag_1013)
    tag_1012:
        /* "src/contracts/0.4.24/Lido.sol":38798:38822  uint256 depositableEther */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":39113:39140  uint256 depositedPostReport */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":39411:39438  uint256 depositedNextReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":39440:39456  uint256 curNonce */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":39658:39687  uint256 storedDepositsReserve */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":38759:38788  _getBufferedEtherAllocation() */
      tag_1015
        /* "src/contracts/0.4.24/Lido.sol":38759:38786  _getBufferedEtherAllocation */
      tag_705
        /* "src/contracts/0.4.24/Lido.sol":38759:38788  _getBufferedEtherAllocation() */
      jump	// in
    tag_1015:
        /* "src/contracts/0.4.24/Lido.sol":38715:38788  BufferedEtherAllocation memory allocation = _getBufferedEtherAllocation() */
      swap6
      pop
        /* "src/contracts/0.4.24/Lido.sol":38825:38857  _getDepositableEther(allocation) */
      tag_1016
        /* "src/contracts/0.4.24/Lido.sol":38846:38856  allocation */
      dup7
        /* "src/contracts/0.4.24/Lido.sol":38825:38845  _getDepositableEther */
      tag_852
        /* "src/contracts/0.4.24/Lido.sol":38825:38857  _getDepositableEther(allocation) */
      jump	// in
    tag_1016:
        /* "src/contracts/0.4.24/Lido.sol":38798:38857  uint256 depositableEther = _getDepositableEther(allocation) */
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":38875:38909  _depositAmount <= depositableEther */
      dup5
      dup8
      gt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":38867:38930  require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER") */
      tag_1017
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x4e4f545f454e4f5547485f455448455200000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1017:
        /* "src/contracts/0.4.24/Lido.sol":39143:39188  _getDepositedPostReport().add(_depositAmount) */
      tag_1018
        /* "src/contracts/0.4.24/Lido.sol":39173:39187  _depositAmount */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":39143:39168  _getDepositedPostReport() */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":39143:39166  _getDepositedPostReport */
      tag_538
        /* "src/contracts/0.4.24/Lido.sol":39143:39168  _getDepositedPostReport() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":39143:39188  _getDepositedPostReport().add(_depositAmount) */
    tag_1018:
        /* "src/contracts/0.4.24/Lido.sol":39238:39254  allocation.total */
      dup7
      mload
        /* "src/contracts/0.4.24/Lido.sol":39113:39188  uint256 depositedPostReport = _getDepositedPostReport().add(_depositAmount) */
      swap1
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":39198:39296  _setBufferedEtherAndDepositedPostReport(allocation.total.sub(_depositAmount), depositedPostReport) */
      tag_1020
      swap1
        /* "src/contracts/0.4.24/Lido.sol":39238:39274  allocation.total.sub(_depositAmount) */
      tag_1021
      swap1
        /* "src/contracts/0.4.24/Lido.sol":39259:39273  _depositAmount */
      dup10
        /* "src/contracts/0.4.24/Lido.sol":39238:39274  allocation.total.sub(_depositAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":39238:39258  allocation.total.sub */
      tag_754
        /* "src/contracts/0.4.24/Lido.sol":39238:39274  allocation.total.sub(_depositAmount) */
      and
      jump	// in
    tag_1021:
        /* "src/contracts/0.4.24/Lido.sol":39276:39295  depositedPostReport */
      dup6
        /* "src/contracts/0.4.24/Lido.sol":39198:39237  _setBufferedEtherAndDepositedPostReport */
      tag_1022
        /* "src/contracts/0.4.24/Lido.sol":39198:39296  _setBufferedEtherAndDepositedPostReport(allocation.total.sub(_depositAmount), depositedPostReport) */
      jump	// in
    tag_1020:
        /* "src/contracts/0.4.24/Lido.sol":39311:39358  DepositedPostReportUpdated(depositedPostReport) */
      0x40
      dup1
      mload
      dup6
      dup2
      mstore
      swap1
      mload
      0xd87d7ff193e5d1560bdbe21e4e14d13dde0de4e49a03812517640af0a2d5c42c
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":39373:39399  Unbuffered(_depositAmount) */
      0x40
      dup1
      mload
      dup9
      dup2
      mstore
      swap1
      mload
      0x76a397bea5768d4fca97ef47792796e35f98dc81b16c1de84e28a818e1f97108
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":39460:39493  _getDepositedNextReportAdjusted() */
      tag_1023
        /* "src/contracts/0.4.24/Lido.sol":39460:39491  _getDepositedNextReportAdjusted */
      tag_540
        /* "src/contracts/0.4.24/Lido.sol":39460:39493  _getDepositedNextReportAdjusted() */
      jump	// in
    tag_1023:
        /* "src/contracts/0.4.24/Lido.sol":39410:39493  (uint256 depositedNextReport, uint256 curNonce) = _getDepositedNextReportAdjusted() */
      swap1
      swap4
      pop
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":39525:39564  depositedNextReport.add(_depositAmount) */
      tag_1024
        /* "src/contracts/0.4.24/Lido.sol":39410:39493  (uint256 depositedNextReport, uint256 curNonce) = _getDepositedNextReportAdjusted() */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":39549:39563  _depositAmount */
      dup9
        /* "src/contracts/0.4.24/Lido.sol":39525:39564  depositedNextReport.add(_depositAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":39525:39548  depositedNextReport.add */
      tag_493
        /* "src/contracts/0.4.24/Lido.sol":39525:39564  depositedNextReport.add(_depositAmount) */
      and
      jump	// in
    tag_1024:
        /* "src/contracts/0.4.24/Lido.sol":39503:39564  depositedNextReport = depositedNextReport.add(_depositAmount) */
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":39574:39647  _setDepositedNextReportAndLastDepositNonce(depositedNextReport, curNonce) */
      tag_1025
        /* "src/contracts/0.4.24/Lido.sol":39617:39636  depositedNextReport */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":39638:39646  curNonce */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":39574:39616  _setDepositedNextReportAndLastDepositNonce */
      tag_580
        /* "src/contracts/0.4.24/Lido.sol":39574:39647  _setDepositedNextReportAndLastDepositNonce(depositedNextReport, curNonce) */
      jump	// in
    tag_1025:
        /* "src/contracts/0.4.24/Lido.sol":39690:39735  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      tag_1026
      0x0
      dup1
      mload
      0x20
      data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":39690:39733  DEPOSITS_RESERVE_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":39690:39735  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      jump	// in
    tag_1026:
        /* "src/contracts/0.4.24/Lido.sol":39658:39735  uint256 storedDepositsReserve = DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":39773:39774  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":39749:39770  storedDepositsReserve */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":39749:39774  storedDepositsReserve > 0 */
      gt
        /* "src/contracts/0.4.24/Lido.sol":39745:39905  if (storedDepositsReserve > 0) {... */
      iszero
      tag_1028
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":39790:39894  _setDepositsReserve(storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0) */
      tag_1028
        /* "src/contracts/0.4.24/Lido.sol":39834:39848  _depositAmount */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":39810:39831  storedDepositsReserve */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":39810:39848  storedDepositsReserve > _depositAmount */
      gt
        /* "src/contracts/0.4.24/Lido.sol":39810:39893  storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0 */
      tag_1029
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":39892:39893  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":39810:39893  storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0 */
      jump(tag_1030)
    tag_1029:
        /* "src/contracts/0.4.24/Lido.sol":39875:39889  _depositAmount */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":39851:39872  storedDepositsReserve */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":39851:39889  storedDepositsReserve - _depositAmount */
      sub
        /* "src/contracts/0.4.24/Lido.sol":39810:39893  storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0 */
    tag_1030:
        /* "src/contracts/0.4.24/Lido.sol":39790:39809  _setDepositsReserve */
      tag_958
        /* "src/contracts/0.4.24/Lido.sol":39790:39894  _setDepositsReserve(storedDepositsReserve > _depositAmount ? storedDepositsReserve - _depositAmount : 0) */
      jump	// in
    tag_1028:
        /* "src/contracts/0.4.24/Lido.sol":38640:39911  function _spendDepositableEther(uint256 _depositAmount) internal {... */
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":69173:69306  function _getSeedDepositsCount() internal view returns (uint256) {... */
    tag_492:
        /* "src/contracts/0.4.24/Lido.sol":69229:69236  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":69255:69299  SEED_DEPOSITS_COUNT_POSITION.getLowUint128() */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":7371:7437  0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238 */
      0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238
        /* "src/contracts/0.4.24/Lido.sol":69255:69297  SEED_DEPOSITS_COUNT_POSITION.getLowUint128 */
      tag_890
        /* "src/contracts/0.4.24/Lido.sol":69255:69299  SEED_DEPOSITS_COUNT_POSITION.getLowUint128() */
      jump	// in
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1928:2098  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {... */
    tag_493:
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":2053:2071  ERROR_ADD_OVERFLOW */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x11
      dup2
      mstore
      0x4d4154485f4144445f4f564552464c4f57000000000000000000000000000000
      0x20
      dup3
      add
      mstore
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1988:1995  uint256 */
      0x0
      swap1
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":2019:2026  _a + _b */
      dup4
      dup4
      add
      swap1
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":2044:2051  c >= _a */
      dup5
      dup3
      lt
      iszero
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":2036:2072  require(c >= _a, ERROR_ADD_OVERFLOW) */
      tag_607
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x4
      add
      dup1
      dup1
      0x20
      add
      dup3
      dup2
      sub
      dup3
      mstore
      dup4
      dup2
      dup2
      mload
      dup2
      mstore
      0x20
      add
      swap2
      pop
      dup1
      mload
      swap1
      0x20
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_443
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_442)
        /* "src/contracts/0.4.24/Lido.sol":69312:69465  function _setSeedDepositsCount(uint256 _newSeedDepositsCount) internal {... */
    tag_495:
        /* "src/contracts/0.4.24/Lido.sol":69393:69458  SEED_DEPOSITS_COUNT_POSITION.setLowUint128(_newSeedDepositsCount) */
      tag_434
        /* "src/contracts/0.4.24/Lido.sol":7371:7437  0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238 */
      0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238
        /* "src/contracts/0.4.24/Lido.sol":69436:69457  _newSeedDepositsCount */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":69393:69458  SEED_DEPOSITS_COUNT_POSITION.setLowUint128(_newSeedDepositsCount) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":69393:69435  SEED_DEPOSITS_COUNT_POSITION.setLowUint128 */
      tag_886
        /* "src/contracts/0.4.24/Lido.sol":69393:69458  SEED_DEPOSITS_COUNT_POSITION.setLowUint128(_newSeedDepositsCount) */
      and
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":18378:18739  function _spendAllowance(address _owner, address _spender, uint256 _amount) internal {... */
    tag_500:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":18500:18518  allowances[_owner] */
      dup1
      dup5
      and
        /* "src/contracts/0.4.24/StETH.sol":18473:18497  uint256 currentAllowance */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":18500:18518  allowances[_owner] */
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":18500:18510  allowances */
      0x1
        /* "src/contracts/0.4.24/StETH.sol":18500:18518  allowances[_owner] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":18500:18528  allowances[_owner][_spender] */
      swap4
      dup7
      and
      dup4
      mstore
      swap3
      swap1
      mstore
      keccak256
      sload
      not(0x0)
        /* "src/contracts/0.4.24/StETH.sol":18542:18580  currentAllowance != INFINITE_ALLOWANCE */
      dup2
      eq
        /* "src/contracts/0.4.24/StETH.sol":18538:18733  if (currentAllowance != INFINITE_ALLOWANCE) {... */
      tag_461
      jumpi
        /* "src/contracts/0.4.24/StETH.sol":18604:18631  currentAllowance >= _amount */
      dup2
      dup2
      lt
      iszero
        /* "src/contracts/0.4.24/StETH.sol":18596:18654  require(currentAllowance >= _amount, "ALLOWANCE_EXCEEDED") */
      tag_1043
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x12
      0x24
      dup3
      add
      mstore
      0x414c4c4f57414e43455f45584345454445440000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1043:
        /* "src/contracts/0.4.24/StETH.sol":18668:18722  _approve(_owner, _spender, currentAllowance - _amount) */
      tag_461
        /* "src/contracts/0.4.24/StETH.sol":18677:18683  _owner */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":18685:18693  _spender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":18714:18721  _amount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":18695:18711  currentAllowance */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":18695:18721  currentAllowance - _amount */
      sub
        /* "src/contracts/0.4.24/StETH.sol":18668:18676  _approve */
      tag_431
        /* "src/contracts/0.4.24/StETH.sol":18668:18722  _approve(_owner, _spender, currentAllowance - _amount) */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":17130:17429  function _transfer(address _sender, address _recipient, uint256 _amount) internal {... */
    tag_502:
        /* "src/contracts/0.4.24/StETH.sol":17222:17247  uint256 _sharesToTransfer */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":17250:17279  getSharesByPooledEth(_amount) */
      tag_1046
        /* "src/contracts/0.4.24/StETH.sol":17271:17278  _amount */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":17250:17270  getSharesByPooledEth */
      tag_139
        /* "src/contracts/0.4.24/StETH.sol":17250:17279  getSharesByPooledEth(_amount) */
      jump	// in
    tag_1046:
        /* "src/contracts/0.4.24/StETH.sol":17222:17279  uint256 _sharesToTransfer = getSharesByPooledEth(_amount) */
      swap1
      pop
        /* "src/contracts/0.4.24/StETH.sol":17289:17344  _transferShares(_sender, _recipient, _sharesToTransfer) */
      tag_1047
        /* "src/contracts/0.4.24/StETH.sol":17305:17312  _sender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17314:17324  _recipient */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17326:17343  _sharesToTransfer */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":17289:17304  _transferShares */
      tag_611
        /* "src/contracts/0.4.24/StETH.sol":17289:17344  _transferShares(_sender, _recipient, _sharesToTransfer) */
      jump	// in
    tag_1047:
        /* "src/contracts/0.4.24/StETH.sol":17354:17422  _emitTransferEvents(_sender, _recipient, _amount, _sharesToTransfer) */
      tag_461
        /* "src/contracts/0.4.24/StETH.sol":17374:17381  _sender */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17383:17393  _recipient */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17395:17402  _amount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17404:17421  _sharesToTransfer */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":17354:17373  _emitTransferEvents */
      tag_613
        /* "src/contracts/0.4.24/StETH.sol":17354:17422  _emitTransferEvents(_sender, _recipient, _amount, _sharesToTransfer) */
      jump	// in
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5794:7245  function setStakingLimit(... */
    tag_519:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5968:5988  StakeLimitState.Data */
      tag_1049
      jump	// in(tag_600)
    tag_1049:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6015:6034  _maxStakeLimit != 0 */
      dup3
      iszero
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6007:6059  require(_maxStakeLimit != 0, "ZERO_MAX_STAKE_LIMIT") */
      tag_1051
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x14
      0x24
      dup3
      add
      mstore
      0x5a45524f5f4d41585f5354414b455f4c494d4954000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1051:
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6077:6105  _maxStakeLimit <= uint96(-1) */
      dup4
      gt
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6069:6135  require(_maxStakeLimit <= uint96(-1), "TOO_LARGE_MAX_STAKE_LIMIT") */
      tag_1052
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x19
      0x24
      dup3
      add
      mstore
      0x544f4f5f4c415247455f4d41585f5354414b455f4c494d495400000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1052:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6153:6198  _maxStakeLimit >= _stakeLimitIncreasePerBlock */
      dup2
      dup4
      lt
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6145:6227  require(_maxStakeLimit >= _stakeLimitIncreasePerBlock, "TOO_LARGE_LIMIT_INCREASE") */
      tag_1053
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x18
      0x24
      dup3
      add
      mstore
      0x544f4f5f4c415247455f4c494d49545f494e4352454153450000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1053:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6259:6291  _stakeLimitIncreasePerBlock == 0 */
      dup2
      iszero
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6258:6368  (_stakeLimitIncreasePerBlock == 0)... */
      tag_1054
      jumpi
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6309:6367  _maxStakeLimit / _stakeLimitIncreasePerBlock <= uint32(-1) */
      0xffffffff
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6326:6353  _stakeLimitIncreasePerBlock */
      dup3
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6309:6323  _maxStakeLimit */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6309:6353  _maxStakeLimit / _stakeLimitIncreasePerBlock */
      dup2
      iszero
      iszero
      tag_1055
      jumpi
      invalid
    tag_1055:
      div
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6309:6367  _maxStakeLimit / _stakeLimitIncreasePerBlock <= uint32(-1) */
      gt
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6258:6368  (_stakeLimitIncreasePerBlock == 0)... */
    tag_1054:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6237:6418  require(... */
      iszero
      iszero
      tag_1056
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x18
      0x24
      dup3
      add
      mstore
      0x544f4f5f534d414c4c5f4c494d49545f494e4352454153450000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1056:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6573  _data.prevStakeBlockNumber */
      dup4
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6578  _data.prevStakeBlockNumber == 0 */
      0xffffffff
      and
      iszero
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6658  _data.prevStakeBlockNumber == 0 ||... */
      tag_1057
      jumpi
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6634:6653  _data.maxStakeLimit */
      0x60
      dup5
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6634:6658  _data.maxStakeLimit == 0 */
      and
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6658  _data.prevStakeBlockNumber == 0 ||... */
    tag_1057:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6812  _data.prevStakeBlockNumber == 0 ||... */
      dup1
      tag_1058
      jumpi
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6792:6797  _data */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6792:6812  _data.prevStakeLimit */
      0x20
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6775:6812  _maxStakeLimit < _data.prevStakeLimit */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6775:6789  _maxStakeLimit */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6775:6812  _maxStakeLimit < _data.prevStakeLimit */
      lt
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6547:6812  _data.prevStakeBlockNumber == 0 ||... */
    tag_1058:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6493:6893  if (... */
      iszero
      tag_1059
      jumpi
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6837:6882  _data.prevStakeLimit = uint96(_maxStakeLimit) */
      dup4
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6837:6857  _data.prevStakeLimit */
      0x20
      dup6
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6837:6882  _data.prevStakeLimit = uint96(_maxStakeLimit) */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6493:6893  if (... */
    tag_1059:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6948:6980  _stakeLimitIncreasePerBlock != 0 */
      dup2
      iszero
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6948:7039  _stakeLimitIncreasePerBlock != 0 ? uint32(_maxStakeLimit / _stakeLimitIncreasePerBlock) : 0 */
      tag_1060
      jumpi
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7038:7039  0 */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6948:7039  _stakeLimitIncreasePerBlock != 0 ? uint32(_maxStakeLimit / _stakeLimitIncreasePerBlock) : 0 */
      jump(tag_1061)
    tag_1060:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7007:7034  _stakeLimitIncreasePerBlock */
      dup2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6990:7004  _maxStakeLimit */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6990:7034  _maxStakeLimit / _stakeLimitIncreasePerBlock */
      dup2
      iszero
      iszero
      tag_1062
      jumpi
      invalid
    tag_1062:
      div
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6948:7039  _stakeLimitIncreasePerBlock != 0 ? uint32(_maxStakeLimit / _stakeLimitIncreasePerBlock) : 0 */
    tag_1061:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6902:7039  _data.maxStakeLimitGrowthBlocks =... */
      0xffffffff
      swap1
      dup2
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6902:6933  _data.maxStakeLimitGrowthBlocks */
      0x40
      dup7
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":6902:7039  _data.maxStakeLimitGrowthBlocks =... */
      mstore
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7050:7094  _data.maxStakeLimit = uint96(_maxStakeLimit) */
      dup5
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7050:7069  _data.maxStakeLimit */
      0x60
      dup7
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7050:7094  _data.maxStakeLimit = uint96(_maxStakeLimit) */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7109:7135  _data.prevStakeBlockNumber */
      dup5
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7109:7140  _data.prevStakeBlockNumber != 0 */
      and
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7105:7216  if (_data.prevStakeBlockNumber != 0) {... */
      tag_1063
      jumpi
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7156:7205  _data.prevStakeBlockNumber = uint32(block.number) */
      0xffffffff
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7192:7204  block.number */
      number
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7156:7205  _data.prevStakeBlockNumber = uint32(block.number) */
      and
      dup5
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7105:7216  if (_data.prevStakeBlockNumber != 0) {... */
    tag_1063:
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7233:7238  _data */
      swap2
      swap3
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5794:7245  function setStakingLimit(... */
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3450:3933  function setStorageStakeLimitStruct(bytes32 _position, StakeLimitState.Data memory _data) internal {... */
    tag_520:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3870:3889  _data.maxStakeLimit */
      0x60
      dup2
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3771:3802  _data.maxStakeLimitGrowthBlocks */
      0x40
      dup3
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":2451:2453  32 */
      0x20
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3696:3716  _data.prevStakeLimit */
      dup4
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3608:3634  _data.prevStakeBlockNumber */
      dup4
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3559:3926  _position.setStorageUint256(... */
      tag_568
      swap4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3559:3568  _position */
      dup7
      swap4
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3862:3890  uint256(_data.maxStakeLimit) */
      swap2
      dup3
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3862:3916  uint256(_data.maxStakeLimit) << MAX_STAKE_LIMIT_OFFSET */
      0x10000000000000000000000000000000000000000
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3763:3803  uint256(_data.maxStakeLimitGrowthBlocks) */
      0xffffffff
      swap2
      dup3
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3763:3843  uint256(_data.maxStakeLimitGrowthBlocks) << MAX_STAKE_LIMIT_GROWTH_BLOCKS_OFFSET */
      0x100000000000000000000000000000000
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3688:3717  uint256(_data.prevStakeLimit) */
      swap3
      swap1
      swap5
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3688:3744  uint256(_data.prevStakeLimit) << PREV_STAKE_LIMIT_OFFSET */
      0x100000000
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3600:3635  uint256(_data.prevStakeBlockNumber) */
      swap3
      dup2
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3600:3744  uint256(_data.prevStakeBlockNumber) << PREV_STAKE_BLOCK_NUMBER_OFFSET... */
      swap3
      swap1
      swap3
      or
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3600:3843  uint256(_data.prevStakeBlockNumber) << PREV_STAKE_BLOCK_NUMBER_OFFSET... */
      or
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3600:3916  uint256(_data.prevStakeBlockNumber) << PREV_STAKE_BLOCK_NUMBER_OFFSET... */
      swap2
      swap1
      swap2
      or
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3559:3586  _position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":3559:3926  _position.setStorageUint256(... */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":69523:69718  function _getClValidatorsBalanceAndClPendingBalance() internal view returns (uint256, uint256) {... */
    tag_536:
        /* "src/contracts/0.4.24/Lido.sol":69600:69607  uint256 */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":69635:69711  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.getLowAndHighUint128() */
      tag_1067
        /* "src/contracts/0.4.24/Lido.sol":7089:7155  0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112 */
      0x96e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112
        /* "src/contracts/0.4.24/Lido.sol":69635:69709  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":69635:69711  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.getLowAndHighUint128() */
      jump	// in
    tag_1067:
        /* "src/contracts/0.4.24/Lido.sol":69628:69711  return CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.getLowAndHighUint128() */
      swap2
      pop
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":69523:69718  function _getClValidatorsBalanceAndClPendingBalance() internal view returns (uint256, uint256) {... */
      swap1
      swap2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":67624:67781  function _getDepositedPostReport() internal view returns (uint256) {... */
    tag_538:
        /* "src/contracts/0.4.24/Lido.sol":67682:67689  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":67708:67774  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getHighUint128() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67708:67772  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getHighUint128 */
      tag_938
        /* "src/contracts/0.4.24/Lido.sol":67708:67774  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getHighUint128() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":36623:37172  function _getDepositedNextReportAdjusted() internal view returns (uint256 depositedNextReport, uint256 curNonce) {... */
    tag_540:
        /* "src/contracts/0.4.24/Lido.sol":36689:36716  uint256 depositedNextReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":36718:36734  uint256 curNonce */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":36746:36763  uint256 lastNonce */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":36808:36852  _getDepositedNextReportAndLastDepositNonce() */
      tag_1072
        /* "src/contracts/0.4.24/Lido.sol":36808:36850  _getDepositedNextReportAndLastDepositNonce */
      tag_1073
        /* "src/contracts/0.4.24/Lido.sol":36808:36852  _getDepositedNextReportAndLastDepositNonce() */
      jump	// in
    tag_1072:
        /* "src/contracts/0.4.24/Lido.sol":36773:36852  (depositedNextReport, lastNonce) = _getDepositedNextReportAndLastDepositNonce() */
      swap1
      swap4
      pop
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":36876:36894  _getCurrentFrame() */
      tag_1074
        /* "src/contracts/0.4.24/Lido.sol":36876:36892  _getCurrentFrame */
      tag_1075
        /* "src/contracts/0.4.24/Lido.sol":36876:36894  _getCurrentFrame() */
      jump	// in
    tag_1074:
      pop
        /* "src/contracts/0.4.24/Lido.sol":36862:36894  (curNonce,) = _getCurrentFrame() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":36931:36952  curNonce != lastNonce */
      dup1
      dup3
      eq
        /* "src/contracts/0.4.24/Lido.sol":36927:37166  if (curNonce != lastNonce) {... */
      tag_1076
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":37154:37155  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":37132:37155  depositedNextReport = 0 */
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":36927:37166  if (curNonce != lastNonce) {... */
    tag_1076:
        /* "src/contracts/0.4.24/Lido.sol":36623:37172  function _getDepositedNextReportAdjusted() internal view returns (uint256 depositedNextReport, uint256 curNonce) {... */
      pop
      swap1
      swap2
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":70199:70356  function _getLidoLocator() internal view returns (ILidoLocator) {... */
    tag_546:
        /* "src/contracts/0.4.24/Lido.sol":70249:70261  ILidoLocator */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":70293:70348  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getLowUint160() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_3eb18c3a715d47bfedca2cc24f79d054a8631bb4d9c2412403ec4f54b08ff05d
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":70293:70346  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getLowUint160 */
      tag_1079
        /* "src/contracts/0.4.24/Lido.sol":70293:70348  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getLowUint160() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":65574:65700  function _elRewardsVault() internal view returns (address) {... */
    tag_558:
        /* "src/contracts/0.4.24/Lido.sol":65624:65631  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65658:65692  _elRewardsVault(_getLidoLocator()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":65674:65691  _getLidoLocator() */
      tag_1083
        /* "src/contracts/0.4.24/Lido.sol":65674:65689  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":65674:65691  _getLidoLocator() */
      jump	// in
    tag_1083:
        /* "src/contracts/0.4.24/Lido.sol":65658:65673  _elRewardsVault */
      tag_737
        /* "src/contracts/0.4.24/Lido.sol":65658:65692  _elRewardsVault(_getLidoLocator()) */
      jump	// in
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1027:1146  function setStorageUint256(bytes32 position, uint256 data) internal {... */
    tag_562:
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1116:1138  sstore(position, data) */
      swap1
      sstore
        /* "src/@aragon/os/contracts/common/UnstructuredStorage.sol":1114:1140  { sstore(position, data) } */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":68826:69110  function _setDepositedNextReportAndLastDepositNonce(uint256 _depositedNextReport, uint256 _lastDepositNonce)... */
    tag_580:
        /* "src/contracts/0.4.24/Lido.sol":68966:69103  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.setLowAndHighUint128(... */
      tag_568
        /* "src/contracts/0.4.24/Lido.sol":6676:6742  0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957 */
      0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957
        /* "src/contracts/0.4.24/Lido.sol":69054:69074  _depositedNextReport */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":69076:69093  _lastDepositNonce */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":68966:69103  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.setLowAndHighUint128(... */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":68966:69040  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.setLowAndHighUint128 */
      tag_1087
        /* "src/contracts/0.4.24/Lido.sol":68966:69103  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.setLowAndHighUint128(... */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":68149:68330  function _setDepositedPostReport(uint256 _newDepositedPostReport) internal {... */
    tag_582:
        /* "src/contracts/0.4.24/Lido.sol":68234:68323  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setHighUint128(_newDepositedPostReport) */
      tag_434
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":68299:68322  _newDepositedPostReport */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":68234:68323  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setHighUint128(_newDepositedPostReport) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":68234:68298  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setHighUint128 */
      tag_941
        /* "src/contracts/0.4.24/Lido.sol":68234:68323  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setHighUint128(_newDepositedPostReport) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":69724:70020  function _setClValidatorsBalanceAndClPendingBalance(uint256 _newClValidatorsBalance, uint256 _newClPendingBalance)... */
    tag_584:
        /* "src/contracts/0.4.24/Lido.sol":69870:70013  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.setLowAndHighUint128(... */
      tag_568
        /* "src/contracts/0.4.24/Lido.sol":7089:7155  0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112 */
      0x96e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112
        /* "src/contracts/0.4.24/Lido.sol":69958:69981  _newClValidatorsBalance */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":69983:70003  _newClPendingBalance */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":69870:70013  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.setLowAndHighUint128(... */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":69870:69944  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.setLowAndHighUint128 */
      tag_1087
        /* "src/contracts/0.4.24/Lido.sol":69870:70013  CL_VALIDATORS_BALANCE_AND_CL_PENDING_BALANCE_POSITION.setLowAndHighUint128(... */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":61990:62342  function _getCurrentStakeLimit(StakeLimitState.Data memory _stakeLimitData) internal view returns (uint256) {... */
    tag_588:
        /* "src/contracts/0.4.24/Lido.sol":62089:62096  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":62112:62145  _stakeLimitData.isStakingPaused() */
      tag_1093
        /* "src/contracts/0.4.24/Lido.sol":62112:62127  _stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62112:62143  _stakeLimitData.isStakingPaused */
      tag_479
        /* "src/contracts/0.4.24/Lido.sol":62112:62145  _stakeLimitData.isStakingPaused() */
      jump	// in
    tag_1093:
        /* "src/contracts/0.4.24/Lido.sol":62108:62180  if (_stakeLimitData.isStakingPaused()) {... */
      iszero
      tag_1094
      jumpi
      pop
        /* "src/contracts/0.4.24/Lido.sol":62168:62169  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":62161:62169  return 0 */
      jump(tag_466)
        /* "src/contracts/0.4.24/Lido.sol":62108:62180  if (_stakeLimitData.isStakingPaused()) {... */
    tag_1094:
        /* "src/contracts/0.4.24/Lido.sol":62194:62229  _stakeLimitData.isStakingLimitSet() */
      tag_1095
        /* "src/contracts/0.4.24/Lido.sol":62194:62209  _stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62194:62227  _stakeLimitData.isStakingLimitSet */
      tag_605
        /* "src/contracts/0.4.24/Lido.sol":62194:62229  _stakeLimitData.isStakingLimitSet() */
      jump	// in
    tag_1095:
        /* "src/contracts/0.4.24/Lido.sol":62193:62229  !_stakeLimitData.isStakingLimitSet() */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":62189:62274  if (!_stakeLimitData.isStakingLimitSet()) {... */
      iszero
      tag_1096
      jumpi
      pop
      not(0x0)
        /* "src/contracts/0.4.24/Lido.sol":62245:62263  return uint256(-1) */
      jump(tag_466)
        /* "src/contracts/0.4.24/Lido.sol":62189:62274  if (!_stakeLimitData.isStakingLimitSet()) {... */
    tag_1096:
        /* "src/contracts/0.4.24/Lido.sol":62291:62335  _stakeLimitData.calculateCurrentStakeLimit() */
      tag_381
        /* "src/contracts/0.4.24/Lido.sol":62291:62306  _stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":62291:62333  _stakeLimitData.calculateCurrentStakeLimit */
      tag_874
        /* "src/contracts/0.4.24/Lido.sol":62291:62335  _stakeLimitData.calculateCurrentStakeLimit() */
      jump	// in
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5301:5439  function isStakingLimitSet(StakeLimitState.Data memory _data) internal pure returns(bool) {... */
    tag_605:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5408:5427  _data.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5408:5432  _data.maxStakeLimit != 0 */
      and
      iszero
      iszero
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":5301:5439  function isStakingLimitSet(StakeLimitState.Data memory _data) internal pure returns(bool) {... */
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":19502:20107  function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal {... */
    tag_611:
        /* "src/contracts/0.4.24/StETH.sol":19845:19872  uint256 currentSenderShares */
      0x0
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19614:19635  _sender != address(0) */
      dup5
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":19606:19663  require(_sender != address(0), "TRANSFER_FROM_ZERO_ADDR") */
      tag_1100
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x17
      0x24
      dup3
      add
      mstore
      0x5452414e534645525f46524f4d5f5a45524f5f41444452000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1100:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19681:19705  _recipient != address(0) */
      dup4
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":19673:19731  require(_recipient != address(0), "TRANSFER_TO_ZERO_ADDR") */
      tag_1101
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x15
      0x24
      dup3
      add
      mstore
      0x5452414e534645525f544f5f5a45524f5f414444520000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1101:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19749:19776  _recipient != address(this) */
      dup4
      and
        /* "src/contracts/0.4.24/StETH.sol":19771:19775  this */
      address
        /* "src/contracts/0.4.24/StETH.sol":19749:19776  _recipient != address(this) */
      eq
      iszero
        /* "src/contracts/0.4.24/StETH.sol":19741:19807  require(_recipient != address(this), "TRANSFER_TO_STETH_CONTRACT") */
      tag_1102
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1a
      0x24
      dup3
      add
      mstore
      0x5452414e534645525f544f5f53544554485f434f4e5452414354000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1102:
        /* "src/contracts/0.4.24/StETH.sol":19817:19834  _whenNotStopped() */
      tag_1103
        /* "src/contracts/0.4.24/StETH.sol":19817:19832  _whenNotStopped */
      tag_405
        /* "src/contracts/0.4.24/StETH.sol":19817:19834  _whenNotStopped() */
      jump	// in
    tag_1103:
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19875:19890  shares[_sender] */
      dup4
      and
        /* "src/contracts/0.4.24/StETH.sol":19875:19881  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":19875:19890  shares[_sender] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":19908:19944  _sharesAmount <= currentSenderShares */
      dup1
      dup3
      gt
      iszero
        /* "src/contracts/0.4.24/StETH.sol":19900:19965  require(_sharesAmount <= currentSenderShares, "BALANCE_EXCEEDED") */
      tag_1104
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x42414c414e43455f455843454544454400000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1104:
        /* "src/contracts/0.4.24/StETH.sol":19994:20032  currentSenderShares.sub(_sharesAmount) */
      tag_1105
        /* "src/contracts/0.4.24/StETH.sol":19994:20013  currentSenderShares */
      dup2
        /* "src/contracts/0.4.24/StETH.sol":20018:20031  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":19994:20032  currentSenderShares.sub(_sharesAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":19994:20017  currentSenderShares.sub */
      tag_754
        /* "src/contracts/0.4.24/StETH.sol":19994:20032  currentSenderShares.sub(_sharesAmount) */
      and
      jump	// in
    tag_1105:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19976:19991  shares[_sender] */
      dup1
      dup7
      and
        /* "src/contracts/0.4.24/StETH.sol":19976:19982  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":19976:19991  shares[_sender] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      dup1
      dup3
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":19976:20032  shares[_sender] = currentSenderShares.sub(_sharesAmount) */
      swap4
      swap1
      swap4
      sstore
        /* "src/contracts/0.4.24/StETH.sol":20063:20081  shares[_recipient] */
      swap1
      dup6
      and
      dup2
      mstore
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":20063:20100  shares[_recipient].add(_sharesAmount) */
      tag_1106
      swap1
        /* "src/contracts/0.4.24/StETH.sol":20086:20099  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":20063:20100  shares[_recipient].add(_sharesAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":20063:20085  shares[_recipient].add */
      tag_493
        /* "src/contracts/0.4.24/StETH.sol":20063:20100  shares[_recipient].add(_sharesAmount) */
      and
      jump	// in
    tag_1106:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":20042:20060  shares[_recipient] */
      swap1
      swap4
      and
        /* "src/contracts/0.4.24/StETH.sol":20042:20048  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":20042:20060  shares[_recipient] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":20042:20100  shares[_recipient] = shares[_recipient].add(_sharesAmount) */
      swap3
      swap1
      swap3
      sstore
      pop
      pop
      pop
        /* "src/contracts/0.4.24/StETH.sol":19502:20107  function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal {... */
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":22564:22787  function _emitTransferEvents(address _from, address _to, uint256 _tokenAmount, uint256 _sharesAmount) internal {... */
    tag_613:
        /* "src/contracts/0.4.24/StETH.sol":22706:22709  _to */
      dup3
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22690:22724  Transfer(_from, _to, _tokenAmount) */
      and
        /* "src/contracts/0.4.24/StETH.sol":22699:22704  _from */
      dup5
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22690:22724  Transfer(_from, _to, _tokenAmount) */
      and
      0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
        /* "src/contracts/0.4.24/StETH.sol":22711:22723  _tokenAmount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":22690:22724  Transfer(_from, _to, _tokenAmount) */
      mload(0x40)
      dup1
      dup3
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log3
        /* "src/contracts/0.4.24/StETH.sol":22761:22764  _to */
      dup3
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22739:22780  TransferShares(_from, _to, _sharesAmount) */
      and
        /* "src/contracts/0.4.24/StETH.sol":22754:22759  _from */
      dup5
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22739:22780  TransferShares(_from, _to, _sharesAmount) */
      and
      0x9d9c909296d9c674451c0c24f02cb64981eb3b727f99865939192f880a755dcb
        /* "src/contracts/0.4.24/StETH.sol":22766:22779  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":22739:22780  TransferShares(_from, _to, _sharesAmount) */
      mload(0x40)
      dup1
      dup3
      dup2
      mstore
      0x20
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      log3
        /* "src/contracts/0.4.24/StETH.sol":22564:22787  function _emitTransferEvents(address _from, address _to, uint256 _tokenAmount, uint256 _sharesAmount) internal {... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":19023:19132  function _sharesOf(address _account) internal view returns (uint256) {... */
    tag_617:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":19109:19125  shares[_account] */
      and
        /* "src/contracts/0.4.24/StETH.sol":19083:19090  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":19109:19125  shares[_account] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
      sload
      swap1
        /* "src/contracts/0.4.24/StETH.sol":19023:19132  function _sharesOf(address _account) internal view returns (uint256) {... */
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":21996:22485  function _burnShares(address _account, uint256 _sharesAmount) internal returns (uint256 newTotalShares) {... */
    tag_627:
        /* "src/contracts/0.4.24/StETH.sol":22076:22098  uint256 newTotalShares */
      0x0
      dup1
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22118:22140  _account != address(0) */
      dup5
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/StETH.sol":22110:22164  require(_account != address(0), "BURN_FROM_ZERO_ADDR") */
      tag_1110
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x13
      0x24
      dup3
      add
      mstore
      0x4255524e5f46524f4d5f5a45524f5f4144445200000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1110:
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22199:22215  shares[_account] */
      dup4
      and
        /* "src/contracts/0.4.24/StETH.sol":22199:22205  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":22199:22215  shares[_account] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
      sload
        /* "src/contracts/0.4.24/StETH.sol":22233:22263  _sharesAmount <= accountShares */
      dup1
      dup4
      gt
      iszero
        /* "src/contracts/0.4.24/StETH.sol":22225:22284  require(_sharesAmount <= accountShares, "BALANCE_EXCEEDED") */
      tag_1111
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x10
      0x24
      dup3
      add
      mstore
      0x42414c414e43455f455843454544454400000000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1111:
        /* "src/contracts/0.4.24/StETH.sol":22312:22348  _getTotalShares().sub(_sharesAmount) */
      tag_1112
        /* "src/contracts/0.4.24/StETH.sol":22334:22347  _sharesAmount */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":22312:22329  _getTotalShares() */
      tag_751
        /* "src/contracts/0.4.24/StETH.sol":22312:22327  _getTotalShares */
      tag_813
        /* "src/contracts/0.4.24/StETH.sol":22312:22329  _getTotalShares() */
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":22312:22348  _getTotalShares().sub(_sharesAmount) */
    tag_1112:
        /* "src/contracts/0.4.24/StETH.sol":22295:22348  newTotalShares = _getTotalShares().sub(_sharesAmount) */
      swap2
      pop
        /* "src/contracts/0.4.24/StETH.sol":22358:22416  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      tag_1114
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":22295:22348  newTotalShares = _getTotalShares().sub(_sharesAmount) */
      dup4
        /* "src/contracts/0.4.24/StETH.sol":22358:22416  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":22358:22400  TOTAL_SHARES_POSITION_LOW128.setLowUint128 */
      tag_886
        /* "src/contracts/0.4.24/StETH.sol":22358:22416  TOTAL_SHARES_POSITION_LOW128.setLowUint128(newTotalShares) */
      and
      jump	// in
    tag_1114:
        /* "src/contracts/0.4.24/StETH.sol":22446:22478  accountShares.sub(_sharesAmount) */
      tag_1115
        /* "src/contracts/0.4.24/StETH.sol":22446:22459  accountShares */
      dup2
        /* "src/contracts/0.4.24/StETH.sol":22464:22477  _sharesAmount */
      dup5
        /* "src/contracts/0.4.24/StETH.sol":22446:22478  accountShares.sub(_sharesAmount) */
      0xffffffff
        /* "src/contracts/0.4.24/StETH.sol":22446:22463  accountShares.sub */
      tag_754
        /* "src/contracts/0.4.24/StETH.sol":22446:22478  accountShares.sub(_sharesAmount) */
      and
      jump	// in
    tag_1115:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETH.sol":22427:22443  shares[_account] */
      swap1
      swap5
      and
        /* "src/contracts/0.4.24/StETH.sol":22427:22433  shares */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":22427:22443  shares[_account] */
      swap1
      dup2
      mstore
      0x20
      dup2
      swap1
      mstore
      0x40
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETH.sol":22427:22478  shares[_account] = accountShares.sub(_sharesAmount) */
      swap4
      swap1
      swap4
      sstore
        /* "src/contracts/0.4.24/StETH.sol":21996:22485  function _burnShares(address _account, uint256 _sharesAmount) internal returns (uint256 newTotalShares) {... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":63193:63787  function _increaseStakingLimit(uint256 _amount) internal {... */
    tag_630:
        /* "src/contracts/0.4.24/Lido.sol":63260:63302  StakeLimitState.Data memory stakeLimitData */
      tag_1116
      jump	// in(tag_600)
    tag_1116:
        /* "src/contracts/0.4.24/Lido.sol":63577:63598  uint256 newStakeLimit */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":63305:63356  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      tag_1118
      0x0
      dup1
      mload
      0x20
      data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":63305:63354  STAKING_STATE_POSITION.getStorageStakeLimitStruct */
      tag_478
        /* "src/contracts/0.4.24/Lido.sol":63305:63356  STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      jump	// in
    tag_1118:
        /* "src/contracts/0.4.24/Lido.sol":63260:63356  StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION.getStorageStakeLimitStruct() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":63490:63524  stakeLimitData.isStakingLimitSet() */
      tag_1119
        /* "src/contracts/0.4.24/Lido.sol":63490:63504  stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":63490:63522  stakeLimitData.isStakingLimitSet */
      tag_605
        /* "src/contracts/0.4.24/Lido.sol":63490:63524  stakeLimitData.isStakingLimitSet() */
      jump	// in
    tag_1119:
        /* "src/contracts/0.4.24/Lido.sol":63490:63561  stakeLimitData.isStakingLimitSet() && !stakeLimitData.isStakingPaused() */
      dup1
      iszero
      tag_1120
      jumpi
      pop
        /* "src/contracts/0.4.24/Lido.sol":63529:63561  stakeLimitData.isStakingPaused() */
      tag_1121
        /* "src/contracts/0.4.24/Lido.sol":63529:63543  stakeLimitData */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":63529:63559  stakeLimitData.isStakingPaused */
      tag_479
        /* "src/contracts/0.4.24/Lido.sol":63529:63561  stakeLimitData.isStakingPaused() */
      jump	// in
    tag_1121:
        /* "src/contracts/0.4.24/Lido.sol":63528:63561  !stakeLimitData.isStakingPaused() */
      iszero
        /* "src/contracts/0.4.24/Lido.sol":63490:63561  stakeLimitData.isStakingLimitSet() && !stakeLimitData.isStakingPaused() */
    tag_1120:
        /* "src/contracts/0.4.24/Lido.sol":63486:63781  if (stakeLimitData.isStakingLimitSet() && !stakeLimitData.isStakingPaused()) {... */
      iszero
      tag_700
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":63647:63654  _amount */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":63601:63644  stakeLimitData.calculateCurrentStakeLimit() */
      tag_1123
        /* "src/contracts/0.4.24/Lido.sol":63601:63615  stakeLimitData */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":63601:63642  stakeLimitData.calculateCurrentStakeLimit */
      tag_874
        /* "src/contracts/0.4.24/Lido.sol":63601:63644  stakeLimitData.calculateCurrentStakeLimit() */
      jump	// in
    tag_1123:
        /* "src/contracts/0.4.24/Lido.sol":63601:63654  stakeLimitData.calculateCurrentStakeLimit() + _amount */
      add
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":63669:63770  STAKING_STATE_POSITION.setStorageStakeLimitStruct(stakeLimitData.updatePrevStakeLimit(newStakeLimit)) */
      tag_700
        /* "src/contracts/0.4.24/Lido.sol":63719:63769  stakeLimitData.updatePrevStakeLimit(newStakeLimit) */
      tag_517
        /* "src/contracts/0.4.24/Lido.sol":63719:63733  stakeLimitData */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":63601:63654  stakeLimitData.calculateCurrentStakeLimit() + _amount */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":63719:63769  stakeLimitData.updatePrevStakeLimit(newStakeLimit) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":63719:63754  stakeLimitData.updatePrevStakeLimit */
      tag_878
        /* "src/contracts/0.4.24/Lido.sol":63719:63769  stakeLimitData.updatePrevStakeLimit(newStakeLimit) */
      and
      jump	// in
        /* "src/contracts/0.4.24/StETH.sol":23167:23425  function _emitSharesBurnt(... */
    tag_632:
        /* "src/contracts/0.4.24/StETH.sol":23335:23418  SharesBurnt(_account, _preRebaseTokenAmount, _postRebaseTokenAmount, _sharesAmount) */
      0x40
      dup1
      mload
      dup5
      dup2
      mstore
      0x20
      dup2
      add
      dup5
      swap1
      mstore
      dup1
      dup3
      add
      dup4
      swap1
      mstore
      swap1
      mload
      sub(exp(0x2, 0xa0), 0x1)
      dup7
      and
      swap2
      0x8b2a1e1ad5e0578c3dd82494156e985dade827a87c573b5c1c7716a32162ad64
      swap2
      swap1
      dup2
      swap1
      sub
      0x60
      add
      swap1
      log2
        /* "src/contracts/0.4.24/StETH.sol":23167:23425  function _emitSharesBurnt(... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":65870:65998  function _withdrawalVault() internal view returns (address) {... */
    tag_658:
        /* "src/contracts/0.4.24/Lido.sol":65921:65928  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65955:65990  _withdrawalVault(_getLidoLocator()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":65972:65989  _getLidoLocator() */
      tag_1129
        /* "src/contracts/0.4.24/Lido.sol":65972:65987  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":65972:65989  _getLidoLocator() */
      jump	// in
    tag_1129:
        /* "src/contracts/0.4.24/Lido.sol":65955:65971  _withdrawalVault */
      tag_743
        /* "src/contracts/0.4.24/Lido.sol":65955:65990  _withdrawalVault(_getLidoLocator()) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":64877:64978  function _burner() internal view returns (address) {... */
    tag_695:
        /* "src/contracts/0.4.24/Lido.sol":64919:64926  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64945:64962  _getLidoLocator() */
      tag_1132
        /* "src/contracts/0.4.24/Lido.sol":64945:64960  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":64945:64962  _getLidoLocator() */
      jump	// in
    tag_1132:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":64945:64969  _getLidoLocator().burner */
      and
      0x27810b6e
        /* "src/contracts/0.4.24/Lido.sol":64945:64971  _getLidoLocator().burner() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":27296:27846  function _getBufferedEtherAllocation() internal view returns (BufferedEtherAllocation allocation) {... */
    tag_705:
        /* "src/contracts/0.4.24/Lido.sol":27358:27392  BufferedEtherAllocation allocation */
      tag_1136
      jump	// in(tag_1013)
    tag_1136:
        /* "src/contracts/0.4.24/Lido.sol":27404:27421  uint256 remaining */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":27424:27443  _getBufferedEther() */
      tag_1138
        /* "src/contracts/0.4.24/Lido.sol":27424:27441  _getBufferedEther */
      tag_379
        /* "src/contracts/0.4.24/Lido.sol":27424:27443  _getBufferedEther() */
      jump	// in
    tag_1138:
        /* "src/contracts/0.4.24/Lido.sol":27453:27481  allocation.total = remaining */
      dup1
      dup4
      mstore
        /* "src/contracts/0.4.24/Lido.sol":27404:27443  uint256 remaining = _getBufferedEther() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":27521:27590  Math256.min(remaining, DEPOSITS_RESERVE_POSITION.getStorageUint256()) */
      tag_1139
        /* "src/contracts/0.4.24/Lido.sol":27404:27443  uint256 remaining = _getBufferedEther() */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":27544:27589  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      tag_1140
      0x0
      dup1
      mload
      0x20
      data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":27544:27587  DEPOSITS_RESERVE_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":27544:27589  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      jump	// in
    tag_1140:
        /* "src/contracts/0.4.24/Lido.sol":27521:27532  Math256.min */
      tag_1141
        /* "src/contracts/0.4.24/Lido.sol":27521:27590  Math256.min(remaining, DEPOSITS_RESERVE_POSITION.getStorageUint256()) */
      jump	// in
    tag_1139:
        /* "src/contracts/0.4.24/Lido.sol":27492:27518  allocation.depositsReserve */
      0x40
      dup4
      add
        /* "src/contracts/0.4.24/Lido.sol":27492:27590  allocation.depositsReserve = Math256.min(remaining, DEPOSITS_RESERVE_POSITION.getStorageUint256()) */
      dup2
      swap1
      mstore
        /* "src/contracts/0.4.24/Lido.sol":27600:27639  remaining -= allocation.depositsReserve */
      swap1
      sub
        /* "src/contracts/0.4.24/Lido.sol":27682:27743  Math256.min(remaining, _withdrawalQueue().unfinalizedStETH()) */
      tag_1142
        /* "src/contracts/0.4.24/Lido.sol":27600:27639  remaining -= allocation.depositsReserve */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":27705:27723  _withdrawalQueue() */
      tag_1143
        /* "src/contracts/0.4.24/Lido.sol":27705:27721  _withdrawalQueue */
      tag_841
        /* "src/contracts/0.4.24/Lido.sol":27705:27723  _withdrawalQueue() */
      jump	// in
    tag_1143:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":27705:27740  _withdrawalQueue().unfinalizedStETH */
      and
      0xd0fb84e8
        /* "src/contracts/0.4.24/Lido.sol":27705:27742  _withdrawalQueue().unfinalizedStETH() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_1144
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_1144:
        /* "src/contracts/0.4.24/Lido.sol":27705:27742  _withdrawalQueue().unfinalizedStETH() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_1145
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_1145:
        /* "src/contracts/0.4.24/Lido.sol":27705:27742  _withdrawalQueue().unfinalizedStETH() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x20
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_1146
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_1146:
      pop
        /* "src/contracts/0.4.24/Lido.sol":27705:27742  _withdrawalQueue().unfinalizedStETH() */
      mload
        /* "src/contracts/0.4.24/Lido.sol":27682:27693  Math256.min */
      tag_1141
        /* "src/contracts/0.4.24/Lido.sol":27682:27743  Math256.min(remaining, _withdrawalQueue().unfinalizedStETH()) */
      jump	// in
    tag_1142:
        /* "src/contracts/0.4.24/Lido.sol":27650:27679  allocation.withdrawalsReserve */
      0x60
      dup4
      add
        /* "src/contracts/0.4.24/Lido.sol":27650:27743  allocation.withdrawalsReserve = Math256.min(remaining, _withdrawalQueue().unfinalizedStETH()) */
      dup2
      swap1
      mstore
        /* "src/contracts/0.4.24/Lido.sol":27753:27795  remaining -= allocation.withdrawalsReserve */
      swap1
      sub
        /* "src/contracts/0.4.24/Lido.sol":27806:27827  allocation.unreserved */
      0x20
      dup3
      add
        /* "src/contracts/0.4.24/Lido.sol":27806:27839  allocation.unreserved = remaining */
      mstore
        /* "src/contracts/0.4.24/Lido.sol":27650:27660  allocation */
      swap1
        /* "src/contracts/0.4.24/Lido.sol":27296:27846  function _getBufferedEtherAllocation() internal view returns (BufferedEtherAllocation allocation) {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":65226:65376  function _accountingOracle() internal view returns (IAccountingOracle) {... */
    tag_714:
        /* "src/contracts/0.4.24/Lido.sol":65278:65295  IAccountingOracle */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65332:65349  _getLidoLocator() */
      tag_1148
        /* "src/contracts/0.4.24/Lido.sol":65332:65347  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":65332:65349  _getLidoLocator() */
      jump	// in
    tag_1148:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":65332:65366  _getLidoLocator().accountingOracle */
      and
      0x5a2031f9
        /* "src/contracts/0.4.24/Lido.sol":65332:65368  _getLidoLocator().accountingOracle() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_524
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/utils/Versioned.sol":1520:1670  function _checkContractVersion(uint256 version) internal view {... */
    tag_720:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1611:1631  getContractVersion() */
      tag_1153
        /* "src/contracts/0.4.24/utils/Versioned.sol":1611:1629  getContractVersion */
      tag_270
        /* "src/contracts/0.4.24/utils/Versioned.sol":1611:1631  getContractVersion() */
      jump	// in
    tag_1153:
        /* "src/contracts/0.4.24/utils/Versioned.sol":1600:1631  version == getContractVersion() */
      dup2
      eq
        /* "src/contracts/0.4.24/utils/Versioned.sol":1592:1663  require(version == getContractVersion(), "UNEXPECTED_CONTRACT_VERSION") */
      tag_434
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1b
      0x24
      dup3
      add
      mstore
      0x554e45585045435445445f434f4e54524143545f56455253494f4e0000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":14495:16304  function _migrateStorage_v3_to_v4() internal {... */
    tag_723:
        /* "src/contracts/0.4.24/Lido.sol":14711:14777  0xc36804a03ec742b57b141e4e5d8d3bd1ddb08451fd0f9983af8aaab357a78e2f */
      0xc36804a03ec742b57b141e4e5d8d3bd1ddb08451fd0f9983af8aaab357a78e2f
        /* "src/contracts/0.4.24/Lido.sol":14929:14995  0xa84c096ee27e195f25d7b6c7c2a03229e49f1a2a5087e57ce7d7127707942fe3 */
      0xa84c096ee27e195f25d7b6c7c2a03229e49f1a2a5087e57ce7d7127707942fe3
        /* "src/contracts/0.4.24/Lido.sol":14651:14696  bytes32 CL_BALANCE_AND_CL_VALIDATORS_POSITION */
      0x0
      dup1
      dup1
      dup1
      dup1
      dup1
        /* "src/contracts/0.4.24/Lido.sol":15072:15132  CL_BALANCE_AND_CL_VALIDATORS_POSITION.getLowAndHighUint128() */
      tag_1156
        /* "src/contracts/0.4.24/Lido.sol":14711:14777  0xc36804a03ec742b57b141e4e5d8d3bd1ddb08451fd0f9983af8aaab357a78e2f */
      dup9
        /* "src/contracts/0.4.24/Lido.sol":15072:15130  CL_BALANCE_AND_CL_VALIDATORS_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":15072:15132  CL_BALANCE_AND_CL_VALIDATORS_POSITION.getLowAndHighUint128() */
      jump	// in
    tag_1156:
        /* "src/contracts/0.4.24/Lido.sol":15006:15132  (uint256 clValidatorsBalance, uint256 clValidators) =... */
      swap1
      swap7
      pop
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":15209:15280  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.getLowAndHighUint128() */
      tag_1157
        /* "src/contracts/0.4.24/Lido.sol":15209:15257  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":15209:15278  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":15209:15280  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.getLowAndHighUint128() */
      jump	// in
    tag_1157:
        /* "src/contracts/0.4.24/Lido.sol":15142:15280  (uint256 bufferedEther, uint256 depositedValidators) =... */
      swap4
      pop
      swap4
      pop
        /* "src/contracts/0.4.24/Lido.sol":4656:4664  32 ether */
      0x1bc16d674ec800000
        /* "src/contracts/0.4.24/Lido.sol":15490:15502  clValidators */
      dup6
        /* "src/contracts/0.4.24/Lido.sol":15468:15487  depositedValidators */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":15468:15502  depositedValidators - clValidators */
      sub
        /* "src/contracts/0.4.24/Lido.sol":15467:15518  (depositedValidators - clValidators) * DEPOSIT_SIZE */
      mul
        /* "src/contracts/0.4.24/Lido.sol":15437:15518  uint256 depositedPostReport = (depositedValidators - clValidators) * DEPOSIT_SIZE */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":15528:15603  _setBufferedEtherAndDepositedPostReport(bufferedEther, depositedPostReport) */
      tag_1158
        /* "src/contracts/0.4.24/Lido.sol":15568:15581  bufferedEther */
      dup5
        /* "src/contracts/0.4.24/Lido.sol":15583:15602  depositedPostReport */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":15528:15567  _setBufferedEtherAndDepositedPostReport */
      tag_1022
        /* "src/contracts/0.4.24/Lido.sol":15528:15603  _setBufferedEtherAndDepositedPostReport(bufferedEther, depositedPostReport) */
      jump	// in
    tag_1158:
        /* "src/contracts/0.4.24/Lido.sol":15805:15823  _getCurrentFrame() */
      tag_1159
        /* "src/contracts/0.4.24/Lido.sol":15805:15821  _getCurrentFrame */
      tag_1075
        /* "src/contracts/0.4.24/Lido.sol":15805:15823  _getCurrentFrame() */
      jump	// in
    tag_1159:
        /* "src/contracts/0.4.24/Lido.sol":15783:15823  (uint256 curNonce,) = _getCurrentFrame() */
      pop
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":15856:15929  _setDepositedNextReportAndLastDepositNonce(depositedPostReport, curNonce) */
      tag_1160
        /* "src/contracts/0.4.24/Lido.sol":15899:15918  depositedPostReport */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":15920:15928  curNonce */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":15856:15898  _setDepositedNextReportAndLastDepositNonce */
      tag_580
        /* "src/contracts/0.4.24/Lido.sol":15856:15929  _setDepositedNextReportAndLastDepositNonce(depositedPostReport, curNonce) */
      jump	// in
    tag_1160:
        /* "src/contracts/0.4.24/Lido.sol":16001:16067  _setClValidatorsBalanceAndClPendingBalance(clValidatorsBalance, 0) */
      tag_1161
        /* "src/contracts/0.4.24/Lido.sol":16044:16063  clValidatorsBalance */
      dup7
        /* "src/contracts/0.4.24/Lido.sol":16065:16066  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":16001:16043  _setClValidatorsBalanceAndClPendingBalance */
      tag_584
        /* "src/contracts/0.4.24/Lido.sol":16001:16067  _setClValidatorsBalanceAndClPendingBalance(clValidatorsBalance, 0) */
      jump	// in
    tag_1161:
        /* "src/contracts/0.4.24/Lido.sol":16077:16119  _setSeedDepositsCount(depositedValidators) */
      tag_1162
        /* "src/contracts/0.4.24/Lido.sol":16099:16118  depositedValidators */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":16077:16098  _setSeedDepositsCount */
      tag_495
        /* "src/contracts/0.4.24/Lido.sol":16077:16119  _setSeedDepositsCount(depositedValidators) */
      jump	// in
    tag_1162:
        /* "src/contracts/0.4.24/Lido.sol":16160:16218  CL_BALANCE_AND_CL_VALIDATORS_POSITION.setStorageUint256(0) */
      tag_1163
        /* "src/contracts/0.4.24/Lido.sol":16160:16197  CL_BALANCE_AND_CL_VALIDATORS_POSITION */
      dup9
        /* "src/contracts/0.4.24/Lido.sol":16216:16217  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":16160:16218  CL_BALANCE_AND_CL_VALIDATORS_POSITION.setStorageUint256(0) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":16160:16215  CL_BALANCE_AND_CL_VALIDATORS_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/Lido.sol":16160:16218  CL_BALANCE_AND_CL_VALIDATORS_POSITION.setStorageUint256(0) */
      and
      jump	// in
    tag_1163:
        /* "src/contracts/0.4.24/Lido.sol":16228:16297  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.setStorageUint256(0) */
      tag_1164
        /* "src/contracts/0.4.24/Lido.sol":16228:16276  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":16295:16296  0 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":16228:16297  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.setStorageUint256(0) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":16228:16294  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/Lido.sol":16228:16297  BUFFERED_ETHER_AND_DEPOSITED_VALIDATORS_POSITION.setStorageUint256(0) */
      and
      jump	// in
    tag_1164:
        /* "src/contracts/0.4.24/Lido.sol":14495:16304  function _migrateStorage_v3_to_v4() internal {... */
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":64984:65105  function _accounting(ILidoLocator _locator) internal view returns (address) {... */
    tag_734:
        /* "src/contracts/0.4.24/Lido.sol":65051:65058  address */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65077:65085  _locator */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":65077:65096  _locator.accounting */
      and
      0x9624e83e
        /* "src/contracts/0.4.24/Lido.sol":65077:65098  _locator.accounting() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":65382:65568  function _elRewardsVault(ILidoLocator _locator) internal view returns (ILidoExecutionLayerRewardsVault) {... */
    tag_737:
        /* "src/contracts/0.4.24/Lido.sol":65453:65484  ILidoExecutionLayerRewardsVault */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65535:65543  _locator */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":65535:65558  _locator.elRewardsVault */
      and
      0xe441d25f
        /* "src/contracts/0.4.24/Lido.sol":65535:65560  _locator.elRewardsVault() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/contracts/0.4.24/Lido.sol":65706:65864  function _withdrawalVault(ILidoLocator _locator) internal view returns (IWithdrawalVault) {... */
    tag_743:
        /* "src/contracts/0.4.24/Lido.sol":65778:65794  IWithdrawalVault */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":65830:65838  _locator */
      dup2
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":65830:65854  _locator.withdrawalVault */
      and
      0x69d42148
        /* "src/contracts/0.4.24/Lido.sol":65830:65856  _locator.withdrawalVault() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x20
      mload(0x40)
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_509
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1685:1857  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {... */
    tag_754:
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1782:1801  ERROR_SUB_UNDERFLOW */
      0x40
      dup1
      mload
      dup1
      dup3
      add
      swap1
      swap2
      mstore
      0x12
      dup2
      mstore
      0x4d4154485f5355425f554e444552464c4f570000000000000000000000000000
      0x20
      dup3
      add
      mstore
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1745:1752  uint256 */
      0x0
      swap1
      dup2
      swap1
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1772:1780  _b <= _a */
      dup5
      dup5
      gt
      iszero
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1764:1802  require(_b <= _a, ERROR_SUB_UNDERFLOW) */
      tag_1178
      jumpi
      mload(0x40)
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x4
      add
      dup1
      dup1
      0x20
      add
      dup3
      dup2
      sub
      dup3
      mstore
      dup4
      dup2
      dup2
      mload
      dup2
      mstore
      0x20
      add
      swap2
      pop
      dup1
      mload
      swap1
      0x20
      add
      swap1
      dup1
      dup4
      dup4
        /* "--CODEGEN--":23:24   */
      0x0
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_443
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_442)
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1764:1802  require(_b <= _a, ERROR_SUB_UNDERFLOW) */
    tag_1178:
      pop
      pop
      pop
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1824:1831  _a - _b */
      swap1
      sub
      swap1
        /* "src/@aragon/os/contracts/lib/math/SafeMath.sol":1685:1857  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":51197:51526  function _updateBufferedEtherAllocation() internal {... */
    tag_757:
        /* "src/contracts/0.4.24/Lido.sol":51258:51287  uint256 depositsReserveTarget */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":51326:51349  uint256 depositsReserve */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":51290:51316  getDepositsReserveTarget() */
      tag_1184
        /* "src/contracts/0.4.24/Lido.sol":51290:51314  getDepositsReserveTarget */
      tag_131
        /* "src/contracts/0.4.24/Lido.sol":51290:51316  getDepositsReserveTarget() */
      jump	// in
    tag_1184:
        /* "src/contracts/0.4.24/Lido.sol":51258:51316  uint256 depositsReserveTarget = getDepositsReserveTarget() */
      swap2
      pop
        /* "src/contracts/0.4.24/Lido.sol":51352:51397  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      tag_1185
      0x0
      dup1
      mload
      0x20
      data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":51352:51395  DEPOSITS_RESERVE_POSITION.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/Lido.sol":51352:51397  DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      jump	// in
    tag_1185:
        /* "src/contracts/0.4.24/Lido.sol":51326:51397  uint256 depositsReserve = DEPOSITS_RESERVE_POSITION.getStorageUint256() */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":51430:51451  depositsReserveTarget */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":51412:51427  depositsReserve */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":51412:51451  depositsReserve < depositsReserveTarget */
      lt
        /* "src/contracts/0.4.24/Lido.sol":51408:51520  if (depositsReserve < depositsReserveTarget) {... */
      iszero
      tag_568
      jumpi
        /* "src/contracts/0.4.24/Lido.sol":51467:51509  _setDepositsReserve(depositsReserveTarget) */
      tag_568
        /* "src/contracts/0.4.24/Lido.sol":51487:51508  depositsReserveTarget */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":51467:51486  _setDepositsReserve */
      tag_958
        /* "src/contracts/0.4.24/Lido.sol":51467:51509  _setDepositsReserve(depositsReserveTarget) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":70690:70835  function _getMaxExternalRatioBP() internal view returns (uint256) {... */
    tag_764:
        /* "src/contracts/0.4.24/Lido.sol":70747:70754  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":70773:70828  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getHighUint96() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_3eb18c3a715d47bfedca2cc24f79d054a8631bb4d9c2412403ec4f54b08ff05d
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":70773:70826  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getHighUint96 */
      tag_1191
        /* "src/contracts/0.4.24/Lido.sol":70773:70828  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.getHighUint96() */
      jump	// in
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":142:681  function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {... */
    tag_772:
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":559:572  _input.length */
      dup1
      mload
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":575:577  32 */
      0x20
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":559:577  _input.length * 32 */
      mul
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":639:665  mstore(output, byteLength) */
      dup2
      mstore
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":559:565  _input */
      swap1
        /* "src/@aragon/os/contracts/common/ConversionHelpers.sol":596:675  {... */
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7460:7652  function removeStakingLimit(... */
    tag_803:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7560:7580  StakeLimitState.Data */
      tag_1193
      jump	// in(tag_600)
    tag_1193:
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7621:7622  0 */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7599:7618  _data.maxStakeLimit */
      0x60
      dup3
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7599:7622  _data.maxStakeLimit = 0 */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7599:7618  _data.maxStakeLimit */
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7460:7652  function removeStakingLimit(... */
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":18817:18944  function _getTotalShares() internal view returns (uint256) {... */
    tag_813:
        /* "src/contracts/0.4.24/StETH.sol":18867:18874  uint256 */
      0x0
        /* "src/contracts/0.4.24/StETH.sol":18893:18937  TOTAL_SHARES_POSITION_LOW128.getLowUint128() */
      tag_437
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/StETH.sol":18893:18935  TOTAL_SHARES_POSITION_LOW128.getLowUint128 */
      tag_890
        /* "src/contracts/0.4.24/StETH.sol":18893:18937  TOTAL_SHARES_POSITION_LOW128.getLowUint128() */
      jump	// in
        /* "src/contracts/0.4.24/StETHPermit.sol":5687:5857  function _useNonce(address _owner) internal returns (uint256 current) {... */
    tag_817:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":5777:5800  noncesByAddress[_owner] */
      dup2
      and
        /* "src/contracts/0.4.24/StETHPermit.sol":5740:5755  uint256 current */
      0x0
        /* "src/contracts/0.4.24/StETHPermit.sol":5777:5800  noncesByAddress[_owner] */
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":5777:5792  noncesByAddress */
      0x2
        /* "src/contracts/0.4.24/StETHPermit.sol":5777:5800  noncesByAddress[_owner] */
      0x20
      mstore
      0x40
      swap1
      keccak256
      sload
        /* "src/contracts/0.4.24/StETHPermit.sol":5836:5850  current.add(1) */
      tag_1198
        /* "src/contracts/0.4.24/StETHPermit.sol":5777:5800  noncesByAddress[_owner] */
      dup2
        /* "src/contracts/0.4.24/StETHPermit.sol":5848:5849  1 */
      0x1
        /* "src/contracts/0.4.24/StETHPermit.sol":5836:5850  current.add(1) */
      0xffffffff
        /* "src/contracts/0.4.24/StETHPermit.sol":5836:5847  current.add */
      tag_493
        /* "src/contracts/0.4.24/StETHPermit.sol":5836:5850  current.add(1) */
      and
      jump	// in
    tag_1198:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/StETHPermit.sol":5810:5833  noncesByAddress[_owner] */
      swap1
      swap3
      and
      0x0
      swap1
      dup2
      mstore
        /* "src/contracts/0.4.24/StETHPermit.sol":5810:5825  noncesByAddress */
      0x2
        /* "src/contracts/0.4.24/StETHPermit.sol":5810:5833  noncesByAddress[_owner] */
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/contracts/0.4.24/StETHPermit.sol":5810:5850  noncesByAddress[_owner] = current.add(1) */
      swap2
      swap1
      swap2
      sstore
        /* "src/contracts/0.4.24/StETHPermit.sol":5687:5857  function _useNonce(address _owner) internal returns (uint256 current) {... */
      swap1
      jump	// out
        /* "src/contracts/common/lib/SignatureUtils.sol":1058:2386  function isValidSignature(... */
    tag_826:
        /* "src/contracts/common/lib/SignatureUtils.sol":1217:1221  bool */
      0x0
        /* "src/contracts/common/lib/SignatureUtils.sol":1269:1285  bytes memory sig */
      0x60
        /* "src/contracts/common/lib/SignatureUtils.sol":1523:1540  bytes memory data */
      dup1
        /* "src/contracts/common/lib/SignatureUtils.sol":1630:1644  bytes32 retval */
      0x0
        /* "src/contracts/common/lib/SignatureUtils.sol":1237:1253  _hasCode(signer) */
      tag_1200
        /* "src/contracts/common/lib/SignatureUtils.sol":1246:1252  signer */
      dup10
        /* "src/contracts/common/lib/SignatureUtils.sol":1237:1245  _hasCode */
      tag_1201
        /* "src/contracts/common/lib/SignatureUtils.sol":1237:1253  _hasCode(signer) */
      jump	// in
    tag_1200:
        /* "src/contracts/common/lib/SignatureUtils.sol":1233:2380  if (_hasCode(signer)) {... */
      iszero
      tag_1202
      jumpi
        /* "src/contracts/common/lib/SignatureUtils.sol":1288:1313  abi.encodePacked(r, s, v) */
      0x40
      dup1
      mload
      0x20
      dup1
      dup3
      add
      dup10
      swap1
      mstore
      dup2
      dup4
      add
      dup9
      swap1
      mstore
      0x100000000000000000000000000000000000000000000000000000000000000
      0xff
      dup12
      and
      mul
      0x60
      dup4
      add
      mstore
      dup3
      mload
        /* "--CODEGEN--":22:54   */
      0x41
        /* "--CODEGEN--":26:47   */
      dup2
      dup5
      sub
        /* "--CODEGEN--":22:54   */
      add
        /* "--CODEGEN--":6:55   */
      dup2
      mstore
        /* "src/contracts/common/lib/SignatureUtils.sol":1288:1313  abi.encodePacked(r, s, v) */
      0x61
      dup4
      add
      dup5
      mstore
        /* "src/contracts/common/lib/SignatureUtils.sol":1543:1616  abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      0x85
      dup4
      add
      dup13
      dup2
      mstore
      0xa5
      dup5
      add
      swap5
      dup6
      mstore
      dup2
      mload
      0xc5
      dup6
      add
      mstore
      dup2
      mload
        /* "src/contracts/common/lib/SignatureUtils.sol":1288:1313  abi.encodePacked(r, s, v) */
      swap2
      swap8
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1566:1601  ERC1271_IS_VALID_SIGNATURE_SELECTOR */
      0x1626ba7e00000000000000000000000000000000000000000000000000000000
      swap5
        /* "src/contracts/common/lib/SignatureUtils.sol":1603:1610  msgHash */
      dup14
      swap5
        /* "src/contracts/common/lib/SignatureUtils.sol":1288:1313  abi.encodePacked(r, s, v) */
      dup10
      swap5
        /* "src/contracts/common/lib/SignatureUtils.sol":1543:1616  abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      swap3
      swap4
      swap2
      swap3
      0xe5
      swap1
      swap2
      add
      swap2
      swap1
      dup6
      add
      swap1
      dup1
      dup4
      dup4
        /* "src/contracts/common/lib/SignatureUtils.sol":1288:1313  abi.encodePacked(r, s, v) */
      0x0
        /* "--CODEGEN--":8:108   */
    tag_1203:
        /* "--CODEGEN--":33:36   */
      dup4
        /* "--CODEGEN--":30:31   */
      dup2
        /* "--CODEGEN--":27:37   */
      lt
        /* "--CODEGEN--":8:108   */
      iszero
      tag_1204
      jumpi
        /* "--CODEGEN--":90:101   */
      dup2
      dup2
      add
        /* "--CODEGEN--":84:102   */
      mload
        /* "--CODEGEN--":71:82   */
      dup4
      dup3
      add
        /* "--CODEGEN--":64:103   */
      mstore
        /* "--CODEGEN--":52:54   */
      0x20
        /* "--CODEGEN--":45:55   */
      add
        /* "--CODEGEN--":8:108   */
      jump(tag_1203)
    tag_1204:
        /* "--CODEGEN--":12:26   */
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1543:1616  abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      pop
      pop
      pop
      swap1
      pop
      swap1
      dup2
      add
      swap1
      0x1f
      and
      dup1
      iszero
      tag_1206
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x1
      dup4
      0x20
      sub
      0x100
      exp
      sub
      not
      and
      dup2
      mstore
      0x20
      add
      swap2
      pop
    tag_1206:
      pop
      swap4
      pop
      pop
      pop
      pop
      mload(0x40)
        /* "--CODEGEN--":49:53   */
      0x20
        /* "--CODEGEN--":39:46   */
      dup2
        /* "--CODEGEN--":30:37   */
      dup4
        /* "--CODEGEN--":26:47   */
      sub
        /* "--CODEGEN--":22:54   */
      sub
        /* "--CODEGEN--":13:20   */
      dup2
        /* "--CODEGEN--":6:55   */
      mstore
        /* "src/contracts/common/lib/SignatureUtils.sol":1543:1616  abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      swap1
      0x40
      mstore
      swap1
      not(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
      and
        /* "--CODEGEN--":38:42   */
      0x20
        /* "--CODEGEN--":29:36   */
      dup3
        /* "--CODEGEN--":25:43   */
      add
        /* "--CODEGEN--":67:77   */
      dup1
        /* "--CODEGEN--":61:78   */
      mload
        /* "--CODEGEN--":96:154   */
      0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        /* "--CODEGEN--":199:207   */
      dup4
        /* "--CODEGEN--":192:196   */
      dup2
        /* "--CODEGEN--":186:190   */
      dup4
        /* "--CODEGEN--":182:197   */
      and
        /* "--CODEGEN--":179:208   */
      or
        /* "--CODEGEN--":167:177   */
      dup4
        /* "--CODEGEN--":160:209   */
      mstore
        /* "--CODEGEN--":0:215   */
      pop
      pop
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1543:1616  abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1523:1616  bytes memory data = abi.encodeWithSelector(ERC1271_IS_VALID_SIGNATURE_SELECTOR, msgHash, sig) */
      swap2
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1823:1827  0x40 */
      0x40
        /* "src/contracts/common/lib/SignatureUtils.sol":1817:1828  mload(0x40) */
      mload
        /* "src/contracts/common/lib/SignatureUtils.sol":1877:1879  32 */
      0x20
        /* "src/contracts/common/lib/SignatureUtils.sol":1862:1875  outDataOffset */
      dup2
        /* "src/contracts/common/lib/SignatureUtils.sol":1858:1880  add(outDataOffset, 32) */
      add
        /* "src/contracts/common/lib/SignatureUtils.sol":1852:1856  0x40 */
      0x40
        /* "src/contracts/common/lib/SignatureUtils.sol":1845:1881  mstore(0x40, add(outDataOffset, 32)) */
      mstore
        /* "src/contracts/common/lib/SignatureUtils.sol":2063:2065  32 */
      0x20
        /* "src/contracts/common/lib/SignatureUtils.sol":2048:2061  outDataOffset */
      dup2
        /* "src/contracts/common/lib/SignatureUtils.sol":2041:2045  data */
      dup5
        /* "src/contracts/common/lib/SignatureUtils.sol":2035:2046  mload(data) */
      mload
        /* "src/contracts/common/lib/SignatureUtils.sol":2030:2032  32 */
      0x20
        /* "src/contracts/common/lib/SignatureUtils.sol":2024:2028  data */
      dup7
        /* "src/contracts/common/lib/SignatureUtils.sol":2020:2033  add(data, 32) */
      add
        /* "src/contracts/common/lib/SignatureUtils.sol":2012:2018  signer */
      dup14
        /* "src/contracts/common/lib/SignatureUtils.sol":2005:2010  gas() */
      gas
        /* "src/contracts/common/lib/SignatureUtils.sol":1994:2066  staticcall(gas(), signer, add(data, 32), mload(data), outDataOffset, 32) */
      staticcall
        /* "src/contracts/common/lib/SignatureUtils.sol":2127:2129  32 */
      0x20
        /* "src/contracts/common/lib/SignatureUtils.sol":2109:2125  returndatasize() */
      returndatasize
        /* "src/contracts/common/lib/SignatureUtils.sol":2106:2130  eq(returndatasize(), 32) */
      eq
        /* "src/contracts/common/lib/SignatureUtils.sol":2102:2103  1 */
      0x1
        /* "src/contracts/common/lib/SignatureUtils.sol":2093:2100  success */
      dup3
        /* "src/contracts/common/lib/SignatureUtils.sol":2090:2104  eq(success, 1) */
      eq
        /* "src/contracts/common/lib/SignatureUtils.sol":2086:2131  and(eq(success, 1), eq(returndatasize(), 32)) */
      and
        /* "src/contracts/common/lib/SignatureUtils.sol":2083:2085  if */
      iszero
      tag_1207
      jumpi
        /* "src/contracts/common/lib/SignatureUtils.sol":2170:2183  outDataOffset */
      dup2
        /* "src/contracts/common/lib/SignatureUtils.sol":2164:2184  mload(outDataOffset) */
      mload
        /* "src/contracts/common/lib/SignatureUtils.sol":2154:2184  retval := mload(outDataOffset) */
      swap3
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":2083:2085  if */
    tag_1207:
      pop
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":2254:2289  ERC1271_IS_VALID_SIGNATURE_SELECTOR */
      0x1626ba7e00000000000000000000000000000000000000000000000000000000
        /* "src/contracts/common/lib/SignatureUtils.sol":2236:2290  retval == bytes32(ERC1271_IS_VALID_SIGNATURE_SELECTOR) */
      dup2
      eq
      swap4
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":2229:2290  return retval == bytes32(ERC1271_IS_VALID_SIGNATURE_SELECTOR) */
      jump(tag_1208)
        /* "src/contracts/common/lib/SignatureUtils.sol":1233:2380  if (_hasCode(signer)) {... */
    tag_1202:
        /* "src/contracts/common/lib/SignatureUtils.sol":2363:2369  signer */
      dup9
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/common/lib/SignatureUtils.sol":2328:2369  ECDSA.recover(msgHash, v, r, s) == signer */
      and
        /* "src/contracts/common/lib/SignatureUtils.sol":2328:2359  ECDSA.recover(msgHash, v, r, s) */
      tag_1209
        /* "src/contracts/common/lib/SignatureUtils.sol":2342:2349  msgHash */
      dup10
        /* "src/contracts/common/lib/SignatureUtils.sol":2351:2352  v */
      dup10
        /* "src/contracts/common/lib/SignatureUtils.sol":2354:2355  r */
      dup10
        /* "src/contracts/common/lib/SignatureUtils.sol":2357:2358  s */
      dup10
        /* "src/contracts/common/lib/SignatureUtils.sol":2328:2341  ECDSA.recover */
      tag_1210
        /* "src/contracts/common/lib/SignatureUtils.sol":2328:2359  ECDSA.recover(msgHash, v, r, s) */
      jump	// in
    tag_1209:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/common/lib/SignatureUtils.sol":2328:2369  ECDSA.recover(msgHash, v, r, s) == signer */
      and
      eq
        /* "src/contracts/common/lib/SignatureUtils.sol":2321:2369  return ECDSA.recover(msgHash, v, r, s) == signer */
      swap4
      pop
        /* "src/contracts/common/lib/SignatureUtils.sol":1233:2380  if (_hasCode(signer)) {... */
    tag_1208:
        /* "src/contracts/common/lib/SignatureUtils.sol":1058:2386  function isValidSignature(... */
      pop
      pop
      pop
      swap6
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":57892:58437  function _getInternalEther() internal view returns (uint256) {... */
    tag_835:
        /* "src/contracts/0.4.24/Lido.sol":57944:57951  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":57964:57985  uint256 bufferedEther */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":57987:58014  uint256 depositedPostReport */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":58070:58097  uint256 clValidatorsBalance */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":58099:58123  uint256 clPendingBalance */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":58018:58059  _getBufferedEtherAndDepositedPostReport() */
      tag_1212
        /* "src/contracts/0.4.24/Lido.sol":58018:58057  _getBufferedEtherAndDepositedPostReport */
      tag_1213
        /* "src/contracts/0.4.24/Lido.sol":58018:58059  _getBufferedEtherAndDepositedPostReport() */
      jump	// in
    tag_1212:
        /* "src/contracts/0.4.24/Lido.sol":57963:58059  (uint256 bufferedEther, uint256 depositedPostReport) = _getBufferedEtherAndDepositedPostReport() */
      swap4
      pop
      swap4
      pop
        /* "src/contracts/0.4.24/Lido.sol":58127:58171  _getClValidatorsBalanceAndClPendingBalance() */
      tag_1214
        /* "src/contracts/0.4.24/Lido.sol":58127:58169  _getClValidatorsBalanceAndClPendingBalance */
      tag_536
        /* "src/contracts/0.4.24/Lido.sol":58127:58171  _getClValidatorsBalanceAndClPendingBalance() */
      jump	// in
    tag_1214:
        /* "src/contracts/0.4.24/Lido.sol":58069:58171  (uint256 clValidatorsBalance, uint256 clPendingBalance) = _getClValidatorsBalanceAndClPendingBalance() */
      swap1
      swap3
      pop
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":58345:58430  bufferedEther.add(clValidatorsBalance).add(clPendingBalance).add(depositedPostReport) */
      tag_1215
        /* "src/contracts/0.4.24/Lido.sol":58410:58429  depositedPostReport */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":58345:58405  bufferedEther.add(clValidatorsBalance).add(clPendingBalance) */
      tag_491
        /* "src/contracts/0.4.24/Lido.sol":58069:58171  (uint256 clValidatorsBalance, uint256 clPendingBalance) = _getClValidatorsBalanceAndClPendingBalance() */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":58345:58405  bufferedEther.add(clValidatorsBalance).add(clPendingBalance) */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":58345:58358  bufferedEther */
      dup9
        /* "src/contracts/0.4.24/Lido.sol":58069:58171  (uint256 clValidatorsBalance, uint256 clPendingBalance) = _getClValidatorsBalanceAndClPendingBalance() */
      dup8
        /* "src/contracts/0.4.24/Lido.sol":58345:58383  bufferedEther.add(clValidatorsBalance) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":58345:58362  bufferedEther.add */
      tag_493
        /* "src/contracts/0.4.24/Lido.sol":58345:58383  bufferedEther.add(clValidatorsBalance) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":58345:58430  bufferedEther.add(clValidatorsBalance).add(clPendingBalance).add(depositedPostReport) */
    tag_1215:
        /* "src/contracts/0.4.24/Lido.sol":58338:58430  return bufferedEther.add(clValidatorsBalance).add(clPendingBalance).add(depositedPostReport) */
      swap5
      pop
        /* "src/contracts/0.4.24/Lido.sol":57892:58437  function _getInternalEther() internal view returns (uint256) {... */
      pop
      pop
      pop
      pop
      swap1
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":58518:58824  function _getExternalEther(uint256 _internalEther) internal view returns (uint256) {... */
    tag_836:
        /* "src/contracts/0.4.24/Lido.sol":58592:58599  uint256 */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":58612:58631  uint256 totalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":58633:58655  uint256 externalShares */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":58697:58719  uint256 internalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":58659:58687  _getTotalAndExternalShares() */
      tag_1219
        /* "src/contracts/0.4.24/Lido.sol":58659:58685  _getTotalAndExternalShares */
      tag_900
        /* "src/contracts/0.4.24/Lido.sol":58659:58687  _getTotalAndExternalShares() */
      jump	// in
    tag_1219:
        /* "src/contracts/0.4.24/Lido.sol":58611:58687  (uint256 totalShares, uint256 externalShares) = _getTotalAndExternalShares() */
      swap3
      pop
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":58736:58750  externalShares */
      dup2
        /* "src/contracts/0.4.24/Lido.sol":58722:58733  totalShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":58722:58750  totalShares - externalShares */
      sub
        /* "src/contracts/0.4.24/Lido.sol":58697:58750  uint256 internalShares = totalShares - externalShares */
      swap1
      pop
        /* "src/contracts/0.4.24/Lido.sol":58803:58817  internalShares */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":58785:58799  _internalEther */
      dup6
        /* "src/contracts/0.4.24/Lido.sol":58768:58782  externalShares */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":58768:58799  externalShares * _internalEther */
      mul
        /* "src/contracts/0.4.24/Lido.sol":58767:58817  (externalShares * _internalEther) / internalShares */
      dup2
      iszero
      iszero
      tag_1220
      jumpi
      invalid
    tag_1220:
      div
      swap6
        /* "src/contracts/0.4.24/Lido.sol":58518:58824  function _getExternalEther(uint256 _internalEther) internal view returns (uint256) {... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":64513:64641  function _withdrawalQueue() internal view returns (IWithdrawalQueue) {... */
    tag_841:
        /* "src/contracts/0.4.24/Lido.sol":64564:64580  IWithdrawalQueue */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":64599:64634  _withdrawalQueue(_getLidoLocator()) */
      tag_437
        /* "src/contracts/0.4.24/Lido.sol":64616:64633  _getLidoLocator() */
      tag_1223
        /* "src/contracts/0.4.24/Lido.sol":64616:64631  _getLidoLocator */
      tag_546
        /* "src/contracts/0.4.24/Lido.sol":64616:64633  _getLidoLocator() */
      jump	// in
    tag_1223:
        /* "src/contracts/0.4.24/Lido.sol":64599:64615  _withdrawalQueue */
      tag_457
        /* "src/contracts/0.4.24/Lido.sol":64599:64634  _withdrawalQueue(_getLidoLocator()) */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":38274:38446  function _getDepositableEther(BufferedEtherAllocation allocation) internal pure returns (uint256) {... */
    tag_852:
        /* "src/contracts/0.4.24/Lido.sol":38418:38439  allocation.unreserved */
      0x20
      dup2
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":38389:38415  allocation.depositsReserve */
      0x40
      swap1
      swap2
      add
      mload
        /* "src/contracts/0.4.24/Lido.sol":38389:38439  allocation.depositsReserve + allocation.unreserved */
      add
      swap1
        /* "src/contracts/0.4.24/Lido.sol":38274:38446  function _getDepositableEther(BufferedEtherAllocation allocation) internal pure returns (uint256) {... */
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":70362:70684  function _setMaxExternalRatioBP(uint256 _newMaxExternalRatioBP) internal {... */
    tag_856:
        /* "src/contracts/0.4.24/Lido.sol":4718:4723  10000 */
      0x2710
        /* "src/contracts/0.4.24/Lido.sol":70453:70497  _newMaxExternalRatioBP <= TOTAL_BASIS_POINTS */
      dup2
      gt
      iszero
        /* "src/contracts/0.4.24/Lido.sol":70445:70528  require(_newMaxExternalRatioBP <= TOTAL_BASIS_POINTS, "INVALID_MAX_EXTERNAL_RATIO") */
      tag_1226
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x1a
      0x24
      dup3
      add
      mstore
      0x494e56414c49445f4d41585f45585445524e414c5f524154494f000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
    tag_1226:
        /* "src/contracts/0.4.24/Lido.sol":70539:70616  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setHighUint96(_newMaxExternalRatioBP) */
      tag_1227
      0x0
      dup1
      mload
      0x20
      data_3eb18c3a715d47bfedca2cc24f79d054a8631bb4d9c2412403ec4f54b08ff05d
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":70593:70615  _newMaxExternalRatioBP */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":70539:70616  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setHighUint96(_newMaxExternalRatioBP) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":70539:70592  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setHighUint96 */
      tag_1228
        /* "src/contracts/0.4.24/Lido.sol":70539:70616  LOCATOR_AND_MAX_EXTERNAL_RATIO_POSITION.setHighUint96(_newMaxExternalRatioBP) */
      and
      jump	// in
    tag_1227:
        /* "src/contracts/0.4.24/Lido.sol":70632:70677  MaxExternalRatioBPSet(_newMaxExternalRatioBP) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
      0x13c514ee70ee403f89bdf5ab83908edba92a77e3a61e19b774670c0a2cb2d7e6
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":70362:70684  function _setMaxExternalRatioBP(uint256 _newMaxExternalRatioBP) internal {... */
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4317:4996  function calculateCurrentStakeLimit(StakeLimitState.Data memory _data) internal view returns(uint256 limit) {... */
    tag_874:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4410:4423  uint256 limit */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4435:4464  uint256 stakeLimitIncPerBlock */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4628:4648  uint256 blocksPassed */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4702:4716  uint256 change */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4478:4483  _data */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4478:4509  _data.maxStakeLimitGrowthBlocks */
      0x40
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4478:4514  _data.maxStakeLimitGrowthBlocks != 0 */
      0xffffffff
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4513:4514  0 */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4478:4514  _data.maxStakeLimitGrowthBlocks != 0 */
      eq
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4474:4618  if (_data.maxStakeLimitGrowthBlocks != 0) {... */
      iszero
      tag_1230
      jumpi
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4576:4581  _data */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4576:4607  _data.maxStakeLimitGrowthBlocks */
      0x40
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4554:4607  _data.maxStakeLimit / _data.maxStakeLimitGrowthBlocks */
      0xffffffff
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4554:4559  _data */
      dup6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4554:4573  _data.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4554:4607  _data.maxStakeLimit / _data.maxStakeLimitGrowthBlocks */
      and
      dup2
      iszero
      iszero
      tag_1231
      jumpi
      invalid
    tag_1231:
      div
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4530:4607  stakeLimitIncPerBlock = _data.maxStakeLimit / _data.maxStakeLimitGrowthBlocks */
      and
      swap3
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4474:4618  if (_data.maxStakeLimitGrowthBlocks != 0) {... */
    tag_1230:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4666:4671  _data */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4666:4692  _data.prevStakeBlockNumber */
      0x0
      add
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4651:4692  block.number - _data.prevStakeBlockNumber */
      0xffffffff
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4651:4663  block.number */
      number
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4651:4692  block.number - _data.prevStakeBlockNumber */
      sub
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4628:4692  uint256 blocksPassed = block.number - _data.prevStakeBlockNumber */
      swap2
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4734:4755  stakeLimitIncPerBlock */
      dup3
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4719:4731  blocksPassed */
      dup3
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4719:4755  blocksPassed * stakeLimitIncPerBlock */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4702:4755  uint256 change = blocksPassed * stakeLimitIncPerBlock */
      swap1
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4797:4802  _data */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4797:4816  _data.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4816  _data.prevStakeLimit < _data.maxStakeLimit */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4779  _data */
      dup6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4794  _data.prevStakeLimit */
      0x20
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4816  _data.prevStakeLimit < _data.maxStakeLimit */
      and
      lt
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4989  _data.prevStakeLimit < _data.maxStakeLimit ?... */
      tag_1232
      jumpi
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4910:4989  _constGasMax(_saturatingSub(_data.prevStakeLimit, change), _data.maxStakeLimit) */
      tag_1233
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4923:4967  _saturatingSub(_data.prevStakeLimit, change) */
      tag_1234
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4938:4943  _data */
      dup7
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4938:4958  _data.prevStakeLimit */
      0x20
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4923:4967  _saturatingSub(_data.prevStakeLimit, change) */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4960:4966  change */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4923:4937  _saturatingSub */
      tag_1235
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4923:4967  _saturatingSub(_data.prevStakeLimit, change) */
      jump	// in
    tag_1234:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4969:4974  _data */
      dup7
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4969:4988  _data.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4910:4989  _constGasMax(_saturatingSub(_data.prevStakeLimit, change), _data.maxStakeLimit) */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4910:4922  _constGasMax */
      tag_1236
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4910:4989  _constGasMax(_saturatingSub(_data.prevStakeLimit, change), _data.maxStakeLimit) */
      jump	// in
    tag_1233:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4774:4989  _data.prevStakeLimit < _data.maxStakeLimit ?... */
      jump(tag_1238)
    tag_1232:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4831:4895  _constGasMin(_data.prevStakeLimit + change, _data.maxStakeLimit) */
      tag_1238
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4867:4873  change */
      dup2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4844:4849  _data */
      dup7
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4844:4864  _data.prevStakeLimit */
      0x20
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4844:4873  _data.prevStakeLimit + change */
      and
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4875:4880  _data */
      dup7
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4875:4894  _data.maxStakeLimit */
      0x60
      add
      mload
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4831:4895  _constGasMin(_data.prevStakeLimit + change, _data.maxStakeLimit) */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4831:4843  _constGasMin */
      tag_1239
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4831:4895  _constGasMin(_data.prevStakeLimit + change, _data.maxStakeLimit) */
      jump	// in
    tag_1238:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4766:4989  limit = _data.prevStakeLimit < _data.maxStakeLimit ?... */
      swap6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":4317:4996  function calculateCurrentStakeLimit(StakeLimitState.Data memory _data) internal view returns(uint256 limit) {... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7948:8363  function updatePrevStakeLimit(... */
    tag_878:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8086:8106  StakeLimitState.Data */
      tag_1240
      jump	// in(tag_600)
    tag_1240:
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8132:8164  _newPrevStakeLimit <= uint96(-1) */
      dup3
      gt
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8125:8165  assert(_newPrevStakeLimit <= uint96(-1)) */
      tag_1242
      jumpi
      invalid
    tag_1242:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8182:8208  _data.prevStakeBlockNumber */
      dup3
      mload
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8182:8213  _data.prevStakeBlockNumber != 0 */
      0xffffffff
      and
      iszero
      iszero
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8175:8214  assert(_data.prevStakeBlockNumber != 0) */
      tag_1243
      jumpi
      invalid
    tag_1243:
      pop
      sub(exp(0x2, 0x60), 0x1)
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8225:8274  _data.prevStakeLimit = uint96(_newPrevStakeLimit) */
      and
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8225:8245  _data.prevStakeLimit */
      0x20
      dup3
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8225:8274  _data.prevStakeLimit = uint96(_newPrevStakeLimit) */
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8320:8332  block.number */
      number
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8284:8333  _data.prevStakeBlockNumber = uint32(block.number) */
      0xffffffff
      and
      dup2
      mstore
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8225:8245  _data.prevStakeLimit */
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":7948:8363  function updatePrevStakeLimit(... */
      jump	// out
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":748:968  function setLowUint128(bytes32 position, uint256 data) internal {... */
    tag_886:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":822:837  uint256 high128 */
      0x0
      not(0xffffffffffffffffffffffffffffffff)
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":840:868  position.getStorageUint256() */
      tag_1245
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":840:848  position */
      dup5
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":840:866  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":840:868  position.getStorageUint256() */
      jump	// in
    tag_1245:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":840:888  position.getStorageUint256() & UINT128_HIGH_MASK */
      and
      swap1
      pop
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":898:961  position.setStorageUint256(high128 | (data & UINT128_LOW_MASK)) */
      tag_700
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":898:906  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":943:959  UINT128_LOW_MASK */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":936:959  data & UINT128_LOW_MASK */
      dup5
      and
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":925:960  high128 | (data & UINT128_LOW_MASK) */
      dup4
      or
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":898:961  position.setStorageUint256(high128 | (data & UINT128_LOW_MASK)) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":898:924  position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":898:961  position.setStorageUint256(high128 | (data & UINT128_LOW_MASK)) */
      and
      jump	// in
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":598:742  function getLowUint128(bytes32 position) internal view returns (uint256) {... */
    tag_890:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":662:669  uint256 */
      0x0
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":719:735  UINT128_LOW_MASK */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":688:716  position.getStorageUint256() */
      tag_1248
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":688:696  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":688:714  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":688:716  position.getStorageUint256() */
      jump	// in
    tag_1248:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":688:735  position.getStorageUint256() & UINT128_LOW_MASK */
      and
      swap3
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":598:742  function getLowUint128(bytes32 position) internal view returns (uint256) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":67232:67392  function _getTotalAndExternalShares() internal view returns (uint256, uint256) {... */
    tag_900:
        /* "src/contracts/0.4.24/Lido.sol":67293:67300  uint256 */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":67328:67385  TOTAL_AND_EXTERNAL_SHARES_POSITION.getLowAndHighUint128() */
      tag_1067
      0x0
      dup1
      mload
      0x20
      data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67328:67383  TOTAL_AND_EXTERNAL_SHARES_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":67328:67385  TOTAL_AND_EXTERNAL_SHARES_POSITION.getLowAndHighUint128() */
      jump	// in
        /* "src/contracts/0.4.24/utils/Pausable.sol":623:747  function _whenStopped() internal view {... */
    tag_911:
        /* "src/contracts/0.4.24/utils/Pausable.sol":680:717  ACTIVE_FLAG_POSITION.getStorageBool() */
      tag_1252
      0x0
      dup1
      mload
      0x20
      data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/utils/Pausable.sol":680:715  ACTIVE_FLAG_POSITION.getStorageBool */
      tag_438
        /* "src/contracts/0.4.24/utils/Pausable.sol":680:717  ACTIVE_FLAG_POSITION.getStorageBool() */
      jump	// in
    tag_1252:
        /* "src/contracts/0.4.24/utils/Pausable.sol":679:717  !ACTIVE_FLAG_POSITION.getStorageBool() */
      iszero
        /* "src/contracts/0.4.24/utils/Pausable.sol":671:740  require(!ACTIVE_FLAG_POSITION.getStorageBool(), "CONTRACT_IS_ACTIVE") */
      tag_396
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x12
      0x24
      dup3
      add
      mstore
      0x434f4e54524143545f49535f4143544956450000000000000000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8614:8877  function setStakeLimitPauseState(... */
    tag_918:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8743:8763  StakeLimitState.Data */
      tag_1255
      jump	// in(tag_600)
    tag_1255:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8818:8827  _isPaused */
      dup2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8818:8846  _isPaused ? 0 : block.number */
      tag_1257
      jumpi
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8834:8846  block.number */
      number
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8818:8846  _isPaused ? 0 : block.number */
      jump(tag_1258)
    tag_1257:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8830:8831  0 */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8818:8846  _isPaused ? 0 : block.number */
    tag_1258:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8782:8847  _data.prevStakeBlockNumber = uint32(_isPaused ? 0 : block.number) */
      0xffffffff
      and
      dup4
      mstore
      pop
      swap1
      swap2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":8614:8877  function setStakeLimitPauseState(... */
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":974:1107  function getHighUint128(bytes32 position) internal view returns (uint256) {... */
    tag_938:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1039:1046  uint256 */
      0x0
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1097:1100  128 */
      0x80
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1065:1093  position.getStorageUint256() */
      tag_1260
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1065:1073  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1065:1091  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1065:1093  position.getStorageUint256() */
      jump	// in
    tag_1260:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1065:1100  position.getStorageUint256() >> 128 */
      swap1
      0x2
      exp
      swap1
      div
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1058:1100  return position.getStorageUint256() >> 128 */
      swap1
      pop
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":974:1107  function getHighUint128(bytes32 position) internal view returns (uint256) {... */
      swap2
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1113:1319  function setHighUint128(bytes32 position, uint256 data) internal {... */
    tag_941:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1188:1202  uint256 low128 */
      0x0
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1236:1252  UINT128_LOW_MASK */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1205:1233  position.getStorageUint256() */
      tag_1262
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1205:1213  position */
      dup5
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1205:1231  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1205:1233  position.getStorageUint256() */
      jump	// in
    tag_1262:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1205:1252  position.getStorageUint256() & UINT128_LOW_MASK */
      and
      swap1
      pop
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1262:1312  position.setStorageUint256((data << 128) | low128) */
      tag_700
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1262:1270  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1290:1301  data << 128 */
      0x100000000000000000000000000000000
      dup5
      mul
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1289:1311  (data << 128) | low128 */
      dup4
      or
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1262:1312  position.setStorageUint256((data << 128) | low128) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1262:1288  position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1262:1312  position.setStorageUint256((data << 128) | low128) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":28359:28561  function _setDepositsReserve(uint256 _newDepositsReserve) internal {... */
    tag_958:
        /* "src/contracts/0.4.24/Lido.sol":28436:28500  DEPOSITS_RESERVE_POSITION.setStorageUint256(_newDepositsReserve) */
      tag_1265
      0x0
      dup1
      mload
      0x20
      data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":28480:28499  _newDepositsReserve */
      dup3
        /* "src/contracts/0.4.24/Lido.sol":28436:28500  DEPOSITS_RESERVE_POSITION.setStorageUint256(_newDepositsReserve) */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":28436:28479  DEPOSITS_RESERVE_POSITION.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/Lido.sol":28436:28500  DEPOSITS_RESERVE_POSITION.setStorageUint256(_newDepositsReserve) */
      and
      jump	// in
    tag_1265:
        /* "src/contracts/0.4.24/Lido.sol":28515:28554  DepositsReserveSet(_newDepositsReserve) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
      0x257937ce49d8cbbe1d68a2be7297a18a6e2830528d9154a0f131e5094e894613
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log1
        /* "src/contracts/0.4.24/Lido.sol":28359:28561  function _setDepositsReserve(uint256 _newDepositsReserve) internal {... */
      pop
      jump	// out
        /* "src/contracts/0.4.24/StETH.sol":23496:23699  function _mintInitialShares(uint256 _sharesAmount) internal {... */
    tag_966:
        /* "src/contracts/0.4.24/StETH.sol":23566:23614  _mintShares(INITIAL_TOKEN_HOLDER, _sharesAmount) */
      tag_1267
        /* "src/contracts/0.4.24/StETH.sol":2534:2540  0xdead */
      0xdead
        /* "src/contracts/0.4.24/StETH.sol":23600:23613  _sharesAmount */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":23566:23577  _mintShares */
      tag_376
        /* "src/contracts/0.4.24/StETH.sol":23566:23614  _mintShares(INITIAL_TOKEN_HOLDER, _sharesAmount) */
      jump	// in
    tag_1267:
      pop
        /* "src/contracts/0.4.24/StETH.sol":23624:23692  _emitTransferAfterMintingShares(INITIAL_TOKEN_HOLDER, _sharesAmount) */
      tag_434
        /* "src/contracts/0.4.24/StETH.sol":2534:2540  0xdead */
      0xdead
        /* "src/contracts/0.4.24/StETH.sol":23678:23691  _sharesAmount */
      dup3
        /* "src/contracts/0.4.24/StETH.sol":23624:23655  _emitTransferAfterMintingShares */
      tag_382
        /* "src/contracts/0.4.24/StETH.sol":23624:23692  _emitTransferAfterMintingShares(INITIAL_TOKEN_HOLDER, _sharesAmount) */
      jump	// in
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1884:2070  function setLowUint160(bytes32 position, uint256 data) internal {... */
    tag_969:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1958:2063  position.setStorageUint256((position.getStorageUint256() & UINT96_HIGH_MASK) | (data & UINT160_LOW_MASK)) */
      tag_568
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2038:2061  data & UINT160_LOW_MASK */
      dup3
      and
      not(0xffffffffffffffffffffffffffffffffffffffff)
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1986:2014  position.getStorageUint256() */
      tag_1271
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1986:1994  position */
      dup6
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1986:2012  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1986:2014  position.getStorageUint256() */
      jump	// in
    tag_1271:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1958:1966  position */
      dup6
      swap3
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1986:2033  position.getStorageUint256() & UINT96_HIGH_MASK */
      swap2
      and
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1985:2062  (position.getStorageUint256() & UINT96_HIGH_MASK) | (data & UINT160_LOW_MASK) */
      or
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1958:2063  position.setStorageUint256((position.getStorageUint256() & UINT96_HIGH_MASK) | (data & UINT160_LOW_MASK)) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1958:1984  position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1958:2063  position.setStorageUint256((position.getStorageUint256() & UINT96_HIGH_MASK) | (data & UINT160_LOW_MASK)) */
      and
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":68336:68619  function _setBufferedEtherAndDepositedPostReport(uint256 _newBufferedEther, uint256 _newDepositedPostReport)... */
    tag_1022:
        /* "src/contracts/0.4.24/Lido.sol":68476:68612  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowAndHighUint128(... */
      tag_568
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":68560:68577  _newBufferedEther */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":68579:68602  _newDepositedPostReport */
      dup4
        /* "src/contracts/0.4.24/Lido.sol":68476:68612  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowAndHighUint128(... */
      0xffffffff
        /* "src/contracts/0.4.24/Lido.sol":68476:68546  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowAndHighUint128 */
      tag_1087
        /* "src/contracts/0.4.24/Lido.sol":68476:68612  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.setLowAndHighUint128(... */
      and
      jump	// in
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1325:1553  function getLowAndHighUint128(bytes32 position) internal view returns (uint256 low, uint256 high) {... */
    tag_1068:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1396:1407  uint256 low */
      0x0
      dup1
      dup1
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1449:1477  position.getStorageUint256() */
      tag_1276
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1449:1457  position */
      dup5
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1449:1475  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1449:1477  position.getStorageUint256() */
      jump	// in
    tag_1276:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1501:1517  UINT128_LOW_MASK */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1493:1517  value & UINT128_LOW_MASK */
      dup2
      and
      swap6
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1534:1546  value >> 128 */
      0x100000000000000000000000000000000
      swap1
      swap2
      div
      swap5
      pop
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1325:1553  function getLowAndHighUint128(bytes32 position) internal view returns (uint256 low, uint256 high) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/Lido.sol":68625:68820  function _getDepositedNextReportAndLastDepositNonce() internal view returns (uint256, uint256) {... */
    tag_1073:
        /* "src/contracts/0.4.24/Lido.sol":68702:68709  uint256 */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":68737:68813  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.getLowAndHighUint128() */
      tag_1067
        /* "src/contracts/0.4.24/Lido.sol":6676:6742  0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957 */
      0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957
        /* "src/contracts/0.4.24/Lido.sol":68737:68811  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":68737:68813  DEPOSITED_NEXT_REPORT_AND_LAST_DEPOSIT_NONCE_POSITION.getLowAndHighUint128() */
      jump	// in
        /* "src/contracts/0.4.24/Lido.sol":37244:37422  function _getCurrentFrame() internal view returns (uint256 refSlot, uint256 refSlotTimestamp) {... */
    tag_1075:
        /* "src/contracts/0.4.24/Lido.sol":37295:37310  uint256 refSlot */
      0x0
        /* "src/contracts/0.4.24/Lido.sol":37312:37336  uint256 refSlotTimestamp */
      dup1
        /* "src/contracts/0.4.24/Lido.sol":37378:37397  _accountingOracle() */
      tag_1280
        /* "src/contracts/0.4.24/Lido.sol":37378:37395  _accountingOracle */
      tag_714
        /* "src/contracts/0.4.24/Lido.sol":37378:37397  _accountingOracle() */
      jump	// in
    tag_1280:
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/Lido.sol":37378:37413  _accountingOracle().getCurrentFrame */
      and
      0x72f79b13
        /* "src/contracts/0.4.24/Lido.sol":37378:37415  _accountingOracle().getCurrentFrame() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x2, 0xe0)
      mul
      dup2
      mstore
      0x4
      add
      0x40
      dup1
      mload
      dup1
      dup4
      sub
      dup2
      0x0
      dup8
      dup1
      extcodesize
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_1281
      jumpi
        /* "--CODEGEN--":30:31   */
      0x0
        /* "--CODEGEN--":27:28   */
      dup1
        /* "--CODEGEN--":20:32   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_1281:
        /* "src/contracts/0.4.24/Lido.sol":37378:37415  _accountingOracle().getCurrentFrame() */
      pop
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_1282
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_1282:
        /* "src/contracts/0.4.24/Lido.sol":37378:37415  _accountingOracle().getCurrentFrame() */
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
        /* "--CODEGEN--":13:15   */
      0x40
        /* "--CODEGEN--":8:11   */
      dup2
        /* "--CODEGEN--":5:16   */
      lt
        /* "--CODEGEN--":2:4   */
      iszero
      tag_1283
      jumpi
        /* "--CODEGEN--":29:30   */
      0x0
        /* "--CODEGEN--":26:27   */
      dup1
        /* "--CODEGEN--":19:31   */
      revert
        /* "--CODEGEN--":2:4   */
    tag_1283:
      pop
        /* "src/contracts/0.4.24/Lido.sol":37378:37415  _accountingOracle().getCurrentFrame() */
      dup1
      mload
      0x20
      swap1
      swap2
      add
      mload
      swap1
      swap4
      swap1
      swap3
      pop
        /* "src/contracts/0.4.24/Lido.sol":37244:37422  function _getCurrentFrame() internal view returns (uint256 refSlot, uint256 refSlotTimestamp) {... */
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1734:1878  function getLowUint160(bytes32 position) internal view returns (uint256) {... */
    tag_1079:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1798:1805  uint256 */
      0x0
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1824:1852  position.getStorageUint256() */
      tag_1248
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1824:1832  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1824:1850  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1824:1852  position.getStorageUint256() */
      jump	// in
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1559:1728  function setLowAndHighUint128(bytes32 position, uint256 low, uint256 high) internal {... */
    tag_1087:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1653:1721  position.setStorageUint256((high << 128) | (low & UINT128_LOW_MASK)) */
      tag_700
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1653:1661  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1681:1692  high << 128 */
      0x100000000000000000000000000000000
      dup4
      mul
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1703:1719  UINT128_LOW_MASK */
      0xffffffffffffffffffffffffffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1697:1719  low & UINT128_LOW_MASK */
      dup6
      and
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1680:1720  (high << 128) | (low & UINT128_LOW_MASK) */
      or
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1653:1721  position.setStorageUint256((high << 128) | (low & UINT128_LOW_MASK)) */
      0xffffffff
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1653:1679  position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":1653:1721  position.setStorageUint256((high << 128) | (low & UINT128_LOW_MASK)) */
      and
      jump	// in
        /* "src/contracts/common/lib/Math256.sol":557:661  function min(uint256 a, uint256 b) internal pure returns (uint256) {... */
    tag_1141:
        /* "src/contracts/common/lib/Math256.sol":615:622  uint256 */
      0x0
        /* "src/contracts/common/lib/Math256.sol":645:646  b */
      dup2
        /* "src/contracts/common/lib/Math256.sol":641:642  a */
      dup4
        /* "src/contracts/common/lib/Math256.sol":641:646  a < b */
      lt
        /* "src/contracts/common/lib/Math256.sol":641:654  a < b ? a : b */
      tag_1289
      jumpi
        /* "src/contracts/common/lib/Math256.sol":653:654  b */
      dup2
        /* "src/contracts/common/lib/Math256.sol":641:654  a < b ? a : b */
      jump(tag_728)
    tag_1289:
      pop
        /* "src/contracts/common/lib/Math256.sol":649:650  a */
      swap1
      swap2
        /* "src/contracts/common/lib/Math256.sol":557:661  function min(uint256 a, uint256 b) internal pure returns (uint256) {... */
      swap1
      pop
      jump	// out
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2076:2208  function getHighUint96(bytes32 position) internal view returns (uint256) {... */
    tag_1191:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2140:2147  uint256 */
      0x0
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2198:2201  160 */
      0xa0
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2166:2194  position.getStorageUint256() */
      tag_1260
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2166:2174  position */
      dup4
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2166:2192  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2166:2194  position.getStorageUint256() */
      jump	// in
        /* "src/contracts/common/lib/SignatureUtils.sol":2392:2597  function _hasCode(address addr) internal view returns (bool) {... */
    tag_1201:
        /* "src/contracts/common/lib/SignatureUtils.sol":2447:2451  bool */
      0x0
        /* "src/contracts/common/lib/SignatureUtils.sol":2547:2564  extcodesize(addr) */
      swap1
      extcodesize
        /* "src/contracts/common/lib/SignatureUtils.sol":2582:2590  size > 0 */
      gt
      swap1
        /* "src/contracts/common/lib/SignatureUtils.sol":2392:2597  function _hasCode(address addr) internal view returns (bool) {... */
      jump	// out
        /* "src/contracts/common/lib/ECDSA.sol":1050:2393  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address)... */
    tag_1210:
        /* "src/contracts/common/lib/ECDSA.sol":1135:1142  address */
      0x0
      dup1
        /* "src/contracts/common/lib/ECDSA.sol":2054:2120  0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 */
      0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0
        /* "src/contracts/common/lib/ECDSA.sol":2040:2120  uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 */
      dup4
      gt
      iszero
        /* "src/contracts/common/lib/ECDSA.sol":2032:2159  require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value") */
      tag_1295
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x22
      0x24
      dup3
      add
      mstore
      0x45434453413a20696e76616c6964207369676e6174757265202773272076616c
      0x44
      dup3
      add
      mstore
      0x7565000000000000000000000000000000000000000000000000000000000000
      0x64
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x84
      add
      swap1
      revert
    tag_1295:
        /* "src/contracts/common/lib/ECDSA.sol":2271:2295  ecrecover(hash, v, r, s) */
      0x40
      dup1
      mload
      0x0
      dup1
      dup3
      mstore
      0x20
      dup1
      dup4
      add
      dup1
      dup6
      mstore
      dup11
      swap1
      mstore
      0xff
      dup10
      and
      dup4
      dup6
      add
      mstore
      0x60
      dup4
      add
      dup9
      swap1
      mstore
      0x80
      dup4
      add
      dup8
      swap1
      mstore
      swap3
      mload
      0x1
      swap4
      0xa0
      dup1
      dup6
      add
      swap5
      swap2
      swap4
      not(0x1f)
      dup5
      add
      swap4
      swap3
      dup4
      swap1
      sub
      swap1
      swap2
      add
      swap2
      swap1
      dup7
      gas
      call
      iszero
        /* "--CODEGEN--":8:17   */
      dup1
        /* "--CODEGEN--":5:7   */
      iszero
      tag_1296
      jumpi
        /* "--CODEGEN--":45:61   */
      returndatasize
        /* "--CODEGEN--":42:43   */
      0x0
        /* "--CODEGEN--":39:40   */
      dup1
        /* "--CODEGEN--":24:62   */
      returndatacopy
        /* "--CODEGEN--":77:93   */
      returndatasize
        /* "--CODEGEN--":74:75   */
      0x0
        /* "--CODEGEN--":67:94   */
      revert
        /* "--CODEGEN--":5:7   */
    tag_1296:
      pop
      pop
        /* "src/contracts/common/lib/ECDSA.sol":2271:2295  ecrecover(hash, v, r, s) */
      mload(add(not(0x1f), mload(0x40)))
      swap2
      pop
      pop
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/common/lib/ECDSA.sol":2313:2333  signer != address(0) */
      dup2
      and
      iszero
      iszero
        /* "src/contracts/common/lib/ECDSA.sol":2305:2362  require(signer != address(0), "ECDSA: invalid signature") */
      tag_1238
      jumpi
      0x40
      dup1
      mload
      mul(0x461bcd, exp(0x2, 0xe5))
      dup2
      mstore
      0x20
      0x4
      dup3
      add
      mstore
      0x18
      0x24
      dup3
      add
      mstore
      0x45434453413a20696e76616c6964207369676e61747572650000000000000000
      0x44
      dup3
      add
      mstore
      swap1
      mload
      swap1
      dup2
      swap1
      sub
      0x64
      add
      swap1
      revert
        /* "src/contracts/0.4.24/Lido.sol":67787:67975  function _getBufferedEtherAndDepositedPostReport() internal view returns (uint256, uint256) {... */
    tag_1213:
        /* "src/contracts/0.4.24/Lido.sol":67861:67868  uint256 */
      0x0
      dup1
        /* "src/contracts/0.4.24/Lido.sol":67896:67968  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowAndHighUint128() */
      tag_1067
      0x0
      dup1
      mload
      0x20
      data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e
      dup4
      codecopy
      dup2
      mload
      swap2
      mstore
        /* "src/contracts/0.4.24/Lido.sol":67896:67966  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowAndHighUint128 */
      tag_1068
        /* "src/contracts/0.4.24/Lido.sol":67896:67968  BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION.getLowAndHighUint128() */
      jump	// in
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2214:2388  function setHighUint96(bytes32 position, uint256 data) internal {... */
    tag_1228:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2288:2381  position.setStorageUint256((data << 160) | (position.getStorageUint256() & UINT160_LOW_MASK)) */
      tag_568
      sub(exp(0x2, 0xa0), 0x1)
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2332:2360  position.getStorageUint256() */
      tag_1302
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2332:2340  position */
      dup5
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2332:2358  position.getStorageUint256 */
      tag_438
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2332:2360  position.getStorageUint256() */
      jump	// in
    tag_1302:
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2288:2296  position */
      dup5
      swap2
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2332:2379  position.getStorageUint256() & UINT160_LOW_MASK */
      and
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2316:2327  data << 160 */
      0x10000000000000000000000000000000000000000
      dup5
      mul
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2315:2380  (data << 160) | (position.getStorageUint256() & UINT160_LOW_MASK) */
      or
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2288:2314  position.setStorageUint256 */
      tag_562
        /* "src/contracts/0.4.24/utils/UnstructuredStorageExt.sol":2288:2381  position.setStorageUint256((data << 160) | (position.getStorageUint256() & UINT160_LOW_MASK)) */
      jump	// in
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10231:10418  function _saturatingSub(uint256 a, uint256 b) internal pure returns (uint256 result) {... */
    tag_1235:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10300:10314  uint256 result */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10326:10345  uint256 isUnderflow */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10348:10365  _constGasLt(a, b) */
      tag_1304
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10360:10361  a */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10363:10364  b */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10348:10359  _constGasLt */
      tag_1305
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10348:10365  _constGasLt(a, b) */
      jump	// in
    tag_1304:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10326:10365  uint256 isUnderflow = _constGasLt(a, b) */
      swap1
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10399:10410  isUnderflow */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10395:10396  1 */
      0x1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10395:10410  1 - isUnderflow */
      sub
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10389:10390  b */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10385:10386  a */
      dup6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10385:10390  a - b */
      sub
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10384:10411  (a - b) * (1 - isUnderflow) */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10375:10411  result = (a - b) * (1 - isUnderflow) */
      swap2
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10231:10418  function _saturatingSub(uint256 a, uint256 b) internal pure returns (uint256 result) {... */
      pop
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9859:10066  function _constGasMax(uint256 _lhs, uint256 _rhs) internal pure returns (uint256 max) {... */
    tag_1236:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9932:9943  uint256 max */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9955:9972  uint256 lhsIsLess */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9975:9998  _constGasLt(_lhs, _rhs) */
      tag_1307
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9987:9991  _lhs */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9993:9997  _rhs */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9975:9986  _constGasLt */
      tag_1305
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9975:9998  _constGasLt(_lhs, _rhs) */
      jump	// in
    tag_1307:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9955:9998  uint256 lhsIsLess = _constGasLt(_lhs, _rhs) */
      swap1
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10049:10058  lhsIsLess */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10042:10046  _rhs */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10042:10058  _rhs * lhsIsLess */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10027:10036  lhsIsLess */
      dup2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10023:10024  1 */
      0x1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10023:10036  1 - lhsIsLess */
      sub
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10015:10019  _lhs */
      dup6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10015:10037  _lhs * (1 - lhsIsLess) */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10014:10059  (_lhs * (1 - lhsIsLess)) + (_rhs * lhsIsLess) */
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":10008:10059  max = (_lhs * (1 - lhsIsLess)) + (_rhs * lhsIsLess) */
      swap2
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9859:10066  function _constGasMax(uint256 _lhs, uint256 _rhs) internal pure returns (uint256 max) {... */
      pop
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9425:9632  function _constGasMin(uint256 _lhs, uint256 _rhs) internal pure returns (uint256 min) {... */
    tag_1239:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9498:9509  uint256 min */
      0x0
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9521:9538  uint256 lhsIsLess */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9541:9564  _constGasLt(_lhs, _rhs) */
      tag_1309
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9553:9557  _lhs */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9559:9563  _rhs */
      dup5
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9541:9552  _constGasLt */
      tag_1305
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9541:9564  _constGasLt(_lhs, _rhs) */
      jump	// in
    tag_1309:
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9521:9564  uint256 lhsIsLess = _constGasLt(_lhs, _rhs) */
      swap1
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9614:9623  lhsIsLess */
      dup1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9610:9611  1 */
      0x1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9610:9623  1 - lhsIsLess */
      sub
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9602:9606  _rhs */
      dup4
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9602:9624  _rhs * (1 - lhsIsLess) */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9588:9597  lhsIsLess */
      dup2
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9581:9585  _lhs */
      dup6
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9581:9597  _lhs * lhsIsLess */
      mul
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9580:9625  (_lhs * lhsIsLess) + (_rhs * (1 - lhsIsLess)) */
      add
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9574:9625  min = (_lhs * lhsIsLess) + (_rhs * (1 - lhsIsLess)) */
      swap2
      pop
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9425:9632  function _constGasMin(uint256 _lhs, uint256 _rhs) internal pure returns (uint256 min) {... */
      pop
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9049:9198  function _constGasLt(uint256 a, uint256 b) internal pure returns (uint256 result) {... */
    tag_1305:
      gt
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9174:9182  lt(a, b) */
      swap1
        /* "src/contracts/0.4.24/lib/StakeLimitUtils.sol":9150:9192  {... */
      jump	// out
        /* "src/ConversionHarness.sol":310:570  contract ConversionHarness is Lido {... */
    tag_600:
      0x40
      dup1
      mload
      0x80
      dup2
      add
      dup3
      mstore
      0x0
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
      swap2
      swap1
      swap2
      mstore
      swap1
      jump	// out
    tag_1013:
      0x80
      mload(0x40)
      swap1
      dup2
      add
      0x40
      mstore
      dup1
      0x0
      dup2
      mstore
      0x20
      add
      0x0
      dup2
      mstore
      0x20
      add
      0x0
      dup2
      mstore
      0x20
      add
      0x0
      dup2
      mstore
      pop
      swap1
      jump	// out
    stop
    data_1114a0703a7054ca46938fb9a536dc6f4acd78982a1c38ff67a2abc0cba036c2 644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece
    data_1bb23cf3ca13de924c5a6628ed9f345bcdd53218d177ccf94cd314bc91069c26 a42eee1333c0758ba72be38e728b6dadb32ea767de5b4ddbaea1dae85b1b051f
    data_2b387666d10344475f935386344c3380efb9e86c368001c39fd80f0a5201191f 6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6
    data_3eb18c3a715d47bfedca2cc24f79d054a8631bb4d9c2412403ec4f54b08ff05d d92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223
    data_5b552783cdc28c74f04089c6f684289875df2e6fa8686768ece7f438c4673b3e 81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f
    data_dcc3be0dc0c18b2ca85c153b2219cb382e65522ef4b4ca4dddc889590a25e4a9 a3678de4a579be090bed1177e0a24f77cc29d181ac22fd7688aca344d8938015
    data_ff3f110fb4c0fbb387442b78586be75e5ceeb593a61e4b9b76ea3c2dffdc4301 da4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13

    auxdata: 0xa165627a7a72305820c5345cbb2c4eb2aa8d490277d3b176584d612b86538188758f08e2cf26cc5ef10029
}

