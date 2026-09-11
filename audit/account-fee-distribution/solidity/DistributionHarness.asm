    /* "src/DistributionHarness.sol":320:1841  contract DistributionHarness {... */
  mstore(0x40, 0xc0)
    /* "src/DistributionHarness.sol":566:655  constructor(ILidoShares lido, ILocatorTreasury locator) {LIDO=lido;LIDO_LOCATOR=locator;} */
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
  sub(exp(0x02, 0xa0), 0x01)
    /* "src/DistributionHarness.sol":623:632  LIDO=lido */
  swap2
  dup3
  and
  0x80
  mstore
    /* "src/DistributionHarness.sol":633:653  LIDO_LOCATOR=locator */
  and
  0xa0
  mstore
    /* "src/DistributionHarness.sol":320:1841  contract DistributionHarness {... */
  jump(tag_8)
    /* "#utility.yul":14:158   */
tag_7:
  sub(exp(0x02, 0xa0), 0x01)
    /* "#utility.yul":102:133   */
  dup2
  and
    /* "#utility.yul":92:134   */
  dup2
  eq
    /* "#utility.yul":82:152   */
  tag_10
  jumpi
    /* "#utility.yul":148:149   */
  0x00
    /* "#utility.yul":145:146   */
  dup1
    /* "#utility.yul":138:150   */
  revert
    /* "#utility.yul":82:152   */
tag_10:
    /* "#utility.yul":14:158   */
  pop
  jump	// out
    /* "#utility.yul":163:615   */
tag_3:
    /* "#utility.yul":283:289   */
  0x00
    /* "#utility.yul":291:297   */
  dup1
    /* "#utility.yul":344:346   */
  0x40
    /* "#utility.yul":332:341   */
  dup4
    /* "#utility.yul":323:330   */
  dup6
    /* "#utility.yul":319:342   */
  sub
    /* "#utility.yul":315:347   */
  slt
    /* "#utility.yul":312:364   */
  iszero
  tag_12
  jumpi
    /* "#utility.yul":360:361   */
  0x00
    /* "#utility.yul":357:358   */
  dup1
    /* "#utility.yul":350:362   */
  revert
    /* "#utility.yul":312:364   */
tag_12:
    /* "#utility.yul":392:401   */
  dup3
    /* "#utility.yul":386:402   */
  mload
    /* "#utility.yul":411:455   */
  tag_13
    /* "#utility.yul":449:454   */
  dup2
    /* "#utility.yul":411:455   */
  tag_7
  jump	// in
tag_13:
    /* "#utility.yul":524:526   */
  0x20
    /* "#utility.yul":509:527   */
  dup5
  add
    /* "#utility.yul":503:528   */
  mload
    /* "#utility.yul":474:479   */
  swap1
  swap3
  pop
    /* "#utility.yul":537:583   */
  tag_14
    /* "#utility.yul":503:528   */
  dup2
    /* "#utility.yul":537:583   */
  tag_7
  jump	// in
tag_14:
    /* "#utility.yul":602:609   */
  dup1
    /* "#utility.yul":592:609   */
  swap2
  pop
  pop
    /* "#utility.yul":163:615   */
  swap3
  pop
  swap3
  swap1
  pop
  jump	// out
tag_8:
    /* "src/DistributionHarness.sol":320:1841  contract DistributionHarness {... */
  mload(0x80)
  mload(0xa0)
  codecopy(0x00, dataOffset(sub_0), dataSize(sub_0))
  0x00
  assignImmutable("0x5bc0457d8881b800fd1bc0d6df907345b3bf287e43a5790ded3d08dbacf9c03a")
  0x00
  assignImmutable("0x77c32b454bb61eb9df9e3848d0ded3e59753acda90ae58befe564733aec82e4c")
  return(0x00, dataSize(sub_0))
stop

sub_0: assembly {
        /* "src/DistributionHarness.sol":320:1841  contract DistributionHarness {... */
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
      div(calldataload(0x00), exp(0x02, 0xe0))
      0x3286f3b3
      dup2
      eq
      tag_3
      jumpi
      dup1
      0x8b21f170
      eq
      tag_4
      jumpi
      dup1
      0xdbba4b48
      eq
      tag_5
      jumpi
      dup1
      0xf72df651
      eq
      tag_6
      jumpi
    tag_2:
      0x00
      dup1
      revert
        /* "src/DistributionHarness.sol":842:1088  function mintAndDistribute(uint256 mint,address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
    tag_3:
      tag_7
      tag_8
      calldatasize
      0x04
      tag_9
      jump	// in
    tag_8:
      tag_10
      jump	// in
    tag_7:
      stop
        /* "src/DistributionHarness.sol":355:388  ILidoShares public immutable LIDO */
    tag_4:
      tag_11
      immutable("0x77c32b454bb61eb9df9e3848d0ded3e59753acda90ae58befe564733aec82e4c")
      dup2
      jump
    tag_11:
      mload(0x40)
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":3163:3218   */
      swap1
      swap2
      and
        /* "#utility.yul":3145:3219   */
      dup2
      mstore
        /* "#utility.yul":3133:3135   */
      0x20
        /* "#utility.yul":3118:3136   */
      add
        /* "src/DistributionHarness.sol":355:388  ILidoShares public immutable LIDO */
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
        /* "src/DistributionHarness.sol":394:440  ILocatorTreasury public immutable LIDO_LOCATOR */
    tag_5:
      tag_11
      immutable("0x5bc0457d8881b800fd1bc0d6df907345b3bf287e43a5790ded3d08dbacf9c03a")
      dup2
      jump
        /* "src/DistributionHarness.sol":660:837  function distribute(address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
    tag_6:
      tag_7
      tag_20
      calldatasize
      0x04
      tag_21
      jump	// in
    tag_20:
      tag_22
      jump	// in
        /* "src/DistributionHarness.sol":842:1088  function mintAndDistribute(uint256 mint,address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
    tag_10:
        /* "src/DistributionHarness.sol":975:981  mint>0 */
      dup4
      iszero
        /* "src/DistributionHarness.sol":972:1082  if(mint>0) {LIDO.mintSetup(address(this),mint); _distributeFee(FeeDistribution(recipients,amounts,treasury));} */
      tag_30
      jumpi
        /* "src/DistributionHarness.sol":984:1018  LIDO.mintSetup(address(this),mint) */
      mload(0x40)
      0x33435c3200000000000000000000000000000000000000000000000000000000
      dup2
      mstore
        /* "src/DistributionHarness.sol":1007:1011  this */
      address
        /* "src/DistributionHarness.sol":984:1018  LIDO.mintSetup(address(this),mint) */
      0x04
      dup3
      add
        /* "#utility.yul":4326:4400   */
      mstore
        /* "#utility.yul":4416:4434   */
      0x24
      dup2
      add
        /* "#utility.yul":4409:4443   */
      dup6
      swap1
      mstore
        /* "src/DistributionHarness.sol":984:988  LIDO */
      immutable("0x77c32b454bb61eb9df9e3848d0ded3e59753acda90ae58befe564733aec82e4c")
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/DistributionHarness.sol":984:998  LIDO.mintSetup */
      and
      swap1
      0x33435c32
      swap1
        /* "#utility.yul":4299:4317   */
      0x44
      add
        /* "src/DistributionHarness.sol":984:1018  LIDO.mintSetup(address(this),mint) */
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
      tag_27
      jumpi
      0x00
      dup1
      revert
    tag_27:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_29
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_29:
      pop
      pop
      pop
      pop
        /* "src/DistributionHarness.sol":1020:1080  _distributeFee(FeeDistribution(recipients,amounts,treasury)) */
      tag_30
        /* "src/DistributionHarness.sol":1035:1079  FeeDistribution(recipients,amounts,treasury) */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
        /* "src/DistributionHarness.sol":1051:1061  recipients */
      dup6
        /* "src/DistributionHarness.sol":1035:1079  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      0x20
      add
        /* "src/DistributionHarness.sol":1062:1069  amounts */
      dup5
        /* "src/DistributionHarness.sol":1035:1079  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      0x20
      add
        /* "src/DistributionHarness.sol":1070:1078  treasury */
      dup4
        /* "src/DistributionHarness.sol":1035:1079  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      pop
        /* "src/DistributionHarness.sol":1020:1034  _distributeFee */
      tag_31
        /* "src/DistributionHarness.sol":1020:1080  _distributeFee(FeeDistribution(recipients,amounts,treasury)) */
      jump	// in
    tag_30:
        /* "src/DistributionHarness.sol":842:1088  function mintAndDistribute(uint256 mint,address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/DistributionHarness.sol":660:837  function distribute(address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
    tag_22:
        /* "src/DistributionHarness.sol":770:830  _distributeFee(FeeDistribution(recipients,amounts,treasury)) */
      tag_33
        /* "src/DistributionHarness.sol":785:829  FeeDistribution(recipients,amounts,treasury) */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
        /* "src/DistributionHarness.sol":801:811  recipients */
      dup6
        /* "src/DistributionHarness.sol":785:829  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      0x20
      add
        /* "src/DistributionHarness.sol":812:819  amounts */
      dup5
        /* "src/DistributionHarness.sol":785:829  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      0x20
      add
        /* "src/DistributionHarness.sol":820:828  treasury */
      dup4
        /* "src/DistributionHarness.sol":785:829  FeeDistribution(recipients,amounts,treasury) */
      dup2
      mstore
      pop
        /* "src/DistributionHarness.sol":770:784  _distributeFee */
      tag_31
        /* "src/DistributionHarness.sol":770:830  _distributeFee(FeeDistribution(recipients,amounts,treasury)) */
      jump	// in
    tag_33:
        /* "src/DistributionHarness.sol":660:837  function distribute(address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {... */
      pop
      pop
      pop
      jump	// out
        /* "src/DistributionHarness.sol":1093:1838  function _distributeFee(FeeDistribution memory _feeDistribution) internal {... */
    tag_31:
        /* "src/DistributionHarness.sol":1207:1243  _feeDistribution.moduleFeeRecipients */
      dup1
      mload
        /* "src/DistributionHarness.sol":1285:1320  _feeDistribution.moduleSharesToMint */
      0x20
      dup3
      add
      mload
        /* "src/DistributionHarness.sol":1347:1364  recipients.length */
      dup2
      mload
        /* "src/DistributionHarness.sol":1177:1204  address[] memory recipients */
      0x00
        /* "src/DistributionHarness.sol":1375:1587  for (uint256 i; i < length; ++i) {... */
    tag_35:
        /* "src/DistributionHarness.sol":1395:1401  length */
      dup2
        /* "src/DistributionHarness.sol":1391:1392  i */
      dup2
        /* "src/DistributionHarness.sol":1391:1401  i < length */
      lt
        /* "src/DistributionHarness.sol":1375:1587  for (uint256 i; i < length; ++i) {... */
      iszero
      tag_36
      jumpi
        /* "src/DistributionHarness.sol":1422:1442  uint256 moduleShares */
      0x00
        /* "src/DistributionHarness.sol":1445:1457  sharesToMint */
      dup4
        /* "src/DistributionHarness.sol":1458:1459  i */
      dup3
        /* "src/DistributionHarness.sol":1445:1460  sharesToMint[i] */
      dup2
      mload
      dup2
      lt
      tag_39
      jumpi
      tag_39
      tag_40
      jump	// in
    tag_39:
      0x20
      mul
      0x20
      add
      add
      mload
        /* "src/DistributionHarness.sol":1422:1460  uint256 moduleShares = sharesToMint[i] */
      swap1
      pop
        /* "src/DistributionHarness.sol":1493:1494  0 */
      0x00
        /* "src/DistributionHarness.sol":1478:1490  moduleShares */
      dup2
        /* "src/DistributionHarness.sol":1478:1494  moduleShares > 0 */
      gt
        /* "src/DistributionHarness.sol":1474:1577  if (moduleShares > 0) {... */
      iszero
      tag_41
      jumpi
        /* "src/DistributionHarness.sol":1514:1518  LIDO */
      immutable("0x77c32b454bb61eb9df9e3848d0ded3e59753acda90ae58befe564733aec82e4c")
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/DistributionHarness.sol":1514:1533  LIDO.transferShares */
      and
      0x8fcb4e5b
        /* "src/DistributionHarness.sol":1534:1544  recipients */
      dup7
        /* "src/DistributionHarness.sol":1545:1546  i */
      dup5
        /* "src/DistributionHarness.sol":1534:1547  recipients[i] */
      dup2
      mload
      dup2
      lt
      tag_43
      jumpi
      tag_43
      tag_40
      jump	// in
    tag_43:
      0x20
      mul
      0x20
      add
      add
      mload
        /* "src/DistributionHarness.sol":1549:1561  moduleShares */
      dup4
        /* "src/DistributionHarness.sol":1514:1562  LIDO.transferShares(recipients[i], moduleShares) */
      mload(0x40)
      dup4
      0xffffffff
      and
      exp(0x02, 0xe0)
      mul
      dup2
      mstore
      0x04
      add
      tag_44
      swap3
      swap2
      swap1
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":4344:4399   */
      swap3
      swap1
      swap3
      and
        /* "#utility.yul":4326:4400   */
      dup3
      mstore
        /* "#utility.yul":4431:4433   */
      0x20
        /* "#utility.yul":4416:4434   */
      dup3
      add
        /* "#utility.yul":4409:4443   */
      mstore
        /* "#utility.yul":4314:4316   */
      0x40
        /* "#utility.yul":4299:4317   */
      add
      swap1
        /* "#utility.yul":4152:4449   */
      jump
        /* "src/DistributionHarness.sol":1514:1562  LIDO.transferShares(recipients[i], moduleShares) */
    tag_44:
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
      tag_45
      jumpi
      0x00
      dup1
      revert
    tag_45:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_47
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_47:
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
      tag_48
      swap2
      swap1
      tag_49
      jump	// in
    tag_48:
      pop
        /* "src/DistributionHarness.sol":1474:1577  if (moduleShares > 0) {... */
    tag_41:
      pop
        /* "src/DistributionHarness.sol":1403:1406  ++i */
      tag_50
      dup2
      tag_51
      jump	// in
    tag_50:
      swap1
      pop
        /* "src/DistributionHarness.sol":1375:1587  for (uint256 i; i < length; ++i) {... */
      jump(tag_35)
    tag_36:
      pop
        /* "src/DistributionHarness.sol":1622:1659  _feeDistribution.treasurySharesToMint */
      0x40
      dup5
      add
      mload
        /* "src/DistributionHarness.sol":1673:1691  treasuryShares > 0 */
      dup1
      iszero
        /* "src/DistributionHarness.sol":1669:1832  if (treasuryShares > 0) { // zero is an edge case when all fees goes to modules... */
      tag_52
      jumpi
        /* "src/DistributionHarness.sol":1761:1765  LIDO */
      immutable("0x77c32b454bb61eb9df9e3848d0ded3e59753acda90ae58befe564733aec82e4c")
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/DistributionHarness.sol":1761:1780  LIDO.transferShares */
      and
      0x8fcb4e5b
        /* "src/DistributionHarness.sol":1781:1793  LIDO_LOCATOR */
      immutable("0x5bc0457d8881b800fd1bc0d6df907345b3bf287e43a5790ded3d08dbacf9c03a")
      sub(exp(0x02, 0xa0), 0x01)
        /* "src/DistributionHarness.sol":1781:1802  LIDO_LOCATOR.treasury */
      and
      0x61d027b3
        /* "src/DistributionHarness.sol":1781:1804  LIDO_LOCATOR.treasury() */
      mload(0x40)
      dup2
      0xffffffff
      and
      exp(0x02, 0xe0)
      mul
      dup2
      mstore
      0x04
      add
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
      tag_53
      jumpi
      0x00
      dup1
      revert
    tag_53:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_55
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_55:
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
      tag_56
      swap2
      swap1
      tag_57
      jump	// in
    tag_56:
        /* "src/DistributionHarness.sol":1761:1821  LIDO.transferShares(LIDO_LOCATOR.treasury(), treasuryShares) */
      mload(0x40)
      exp(0x02, 0xe0)
      0xffffffff
      dup5
      and
      mul
      dup2
      mstore
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":4344:4399   */
      swap1
      swap2
      and
        /* "src/DistributionHarness.sol":1761:1821  LIDO.transferShares(LIDO_LOCATOR.treasury(), treasuryShares) */
      0x04
      dup3
      add
        /* "#utility.yul":4326:4400   */
      mstore
        /* "#utility.yul":4416:4434   */
      0x24
      dup2
      add
        /* "#utility.yul":4409:4443   */
      dup5
      swap1
      mstore
        /* "#utility.yul":4299:4317   */
      0x44
      add
        /* "src/DistributionHarness.sol":1761:1821  LIDO.transferShares(LIDO_LOCATOR.treasury(), treasuryShares) */
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
      tag_59
      jumpi
      0x00
      dup1
      revert
    tag_59:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_61
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_61:
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
      tag_62
      swap2
      swap1
      tag_49
      jump	// in
    tag_62:
      pop
        /* "src/DistributionHarness.sol":1669:1832  if (treasuryShares > 0) { // zero is an edge case when all fees goes to modules... */
    tag_52:
        /* "src/DistributionHarness.sol":1167:1838  {... */
      pop
      pop
      pop
      pop
        /* "src/DistributionHarness.sol":1093:1838  function _distributeFee(FeeDistribution memory _feeDistribution) internal {... */
      pop
      jump	// out
        /* "#utility.yul":14:198   */
    tag_63:
        /* "#utility.yul":66:143   */
      0x4e487b7100000000000000000000000000000000000000000000000000000000
        /* "#utility.yul":63:64   */
      0x00
        /* "#utility.yul":56:144   */
      mstore
        /* "#utility.yul":163:167   */
      0x41
        /* "#utility.yul":160:161   */
      0x04
        /* "#utility.yul":153:168   */
      mstore
        /* "#utility.yul":187:191   */
      0x24
        /* "#utility.yul":184:185   */
      0x00
        /* "#utility.yul":177:192   */
      revert
        /* "#utility.yul":203:478   */
    tag_64:
        /* "#utility.yul":274:276   */
      0x40
        /* "#utility.yul":268:277   */
      mload
        /* "#utility.yul":339:341   */
      0x1f
        /* "#utility.yul":320:333   */
      dup3
      add
      not(0x1f)
        /* "#utility.yul":316:343   */
      and
        /* "#utility.yul":304:344   */
      dup2
      add
        /* "#utility.yul":374:392   */
      0xffffffffffffffff
        /* "#utility.yul":359:393   */
      dup2
      gt
        /* "#utility.yul":395:417   */
      dup3
      dup3
      lt
        /* "#utility.yul":356:418   */
      or
        /* "#utility.yul":353:441   */
      iszero
      tag_73
      jumpi
        /* "#utility.yul":421:439   */
      tag_73
      tag_63
      jump	// in
    tag_73:
        /* "#utility.yul":457:459   */
      0x40
        /* "#utility.yul":450:472   */
      mstore
        /* "#utility.yul":203:478   */
      swap2
      swap1
      pop
      jump	// out
        /* "#utility.yul":483:669   */
    tag_65:
        /* "#utility.yul":543:547   */
      0x00
        /* "#utility.yul":576:594   */
      0xffffffffffffffff
        /* "#utility.yul":568:574   */
      dup3
        /* "#utility.yul":565:595   */
      gt
        /* "#utility.yul":562:618   */
      iszero
      tag_76
      jumpi
        /* "#utility.yul":598:616   */
      tag_76
      tag_63
      jump	// in
    tag_76:
      pop
        /* "#utility.yul":658:662   */
      0x20
        /* "#utility.yul":639:656   */
      swap1
      dup2
      mul
        /* "#utility.yul":635:663   */
      add
      swap1
        /* "#utility.yul":483:669   */
      jump	// out
        /* "#utility.yul":674:828   */
    tag_66:
      sub(exp(0x02, 0xa0), 0x01)
        /* "#utility.yul":753:758   */
      dup2
        /* "#utility.yul":749:803   */
      and
        /* "#utility.yul":742:747   */
      dup2
        /* "#utility.yul":739:804   */
      eq
        /* "#utility.yul":729:822   */
      tag_78
      jumpi
        /* "#utility.yul":818:819   */
      0x00
        /* "#utility.yul":815:816   */
      dup1
        /* "#utility.yul":808:820   */
      revert
        /* "#utility.yul":729:822   */
    tag_78:
        /* "#utility.yul":674:828   */
      pop
      jump	// out
        /* "#utility.yul":833:1571   */
    tag_67:
        /* "#utility.yul":887:892   */
      0x00
        /* "#utility.yul":940:943   */
      dup3
        /* "#utility.yul":933:937   */
      0x1f
        /* "#utility.yul":925:931   */
      dup4
        /* "#utility.yul":921:938   */
      add
        /* "#utility.yul":917:944   */
      slt
        /* "#utility.yul":907:962   */
      tag_80
      jumpi
        /* "#utility.yul":958:959   */
      0x00
        /* "#utility.yul":955:956   */
      dup1
        /* "#utility.yul":948:960   */
      revert
        /* "#utility.yul":907:962   */
    tag_80:
        /* "#utility.yul":994:1000   */
      dup2
        /* "#utility.yul":981:1001   */
      calldataload
        /* "#utility.yul":1020:1024   */
      0x20
        /* "#utility.yul":1044:1104   */
      tag_81
        /* "#utility.yul":1060:1103   */
      tag_82
        /* "#utility.yul":1100:1102   */
      dup4
        /* "#utility.yul":1060:1103   */
      tag_65
      jump	// in
    tag_82:
        /* "#utility.yul":1044:1104   */
      tag_64
      jump	// in
    tag_81:
        /* "#utility.yul":1138:1153   */
      dup3
      dup2
      mstore
        /* "#utility.yul":1220:1231   */
      swap2
      dup2
      mul
        /* "#utility.yul":1208:1232   */
      dup5
      add
        /* "#utility.yul":1204:1237   */
      dup2
      add
      swap2
        /* "#utility.yul":1169:1181   */
      dup2
      dup2
      add
      swap1
        /* "#utility.yul":1249:1264   */
      dup7
      dup5
      gt
        /* "#utility.yul":1246:1281   */
      iszero
      tag_83
      jumpi
        /* "#utility.yul":1277:1278   */
      0x00
        /* "#utility.yul":1274:1275   */
      dup1
        /* "#utility.yul":1267:1279   */
      revert
        /* "#utility.yul":1246:1281   */
    tag_83:
        /* "#utility.yul":1313:1315   */
      dup3
        /* "#utility.yul":1305:1311   */
      dup7
        /* "#utility.yul":1301:1316   */
      add
        /* "#utility.yul":1325:1542   */
    tag_84:
        /* "#utility.yul":1341:1347   */
      dup5
        /* "#utility.yul":1336:1339   */
      dup2
        /* "#utility.yul":1333:1348   */
      lt
        /* "#utility.yul":1325:1542   */
      iszero
      tag_86
      jumpi
        /* "#utility.yul":1421:1424   */
      dup1
        /* "#utility.yul":1408:1425   */
      calldataload
        /* "#utility.yul":1438:1469   */
      tag_87
        /* "#utility.yul":1463:1468   */
      dup2
        /* "#utility.yul":1438:1469   */
      tag_66
      jump	// in
    tag_87:
        /* "#utility.yul":1482:1500   */
      dup4
      mstore
        /* "#utility.yul":1520:1532   */
      swap2
      dup4
      add
      swap2
        /* "#utility.yul":1358:1370   */
      dup4
      add
        /* "#utility.yul":1325:1542   */
      jump(tag_84)
    tag_86:
      pop
        /* "#utility.yul":1560:1565   */
      swap7
        /* "#utility.yul":833:1571   */
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":1576:2239   */
    tag_68:
        /* "#utility.yul":1630:1635   */
      0x00
        /* "#utility.yul":1683:1686   */
      dup3
        /* "#utility.yul":1676:1680   */
      0x1f
        /* "#utility.yul":1668:1674   */
      dup4
        /* "#utility.yul":1664:1681   */
      add
        /* "#utility.yul":1660:1687   */
      slt
        /* "#utility.yul":1650:1705   */
      tag_89
      jumpi
        /* "#utility.yul":1701:1702   */
      0x00
        /* "#utility.yul":1698:1699   */
      dup1
        /* "#utility.yul":1691:1703   */
      revert
        /* "#utility.yul":1650:1705   */
    tag_89:
        /* "#utility.yul":1737:1743   */
      dup2
        /* "#utility.yul":1724:1744   */
      calldataload
        /* "#utility.yul":1763:1767   */
      0x20
        /* "#utility.yul":1787:1847   */
      tag_90
        /* "#utility.yul":1803:1846   */
      tag_82
        /* "#utility.yul":1843:1845   */
      dup4
        /* "#utility.yul":1803:1846   */
      tag_65
      jump	// in
        /* "#utility.yul":1787:1847   */
    tag_90:
        /* "#utility.yul":1881:1896   */
      dup3
      dup2
      mstore
        /* "#utility.yul":1963:1974   */
      swap2
      dup2
      mul
        /* "#utility.yul":1951:1975   */
      dup5
      add
        /* "#utility.yul":1947:1980   */
      dup2
      add
      swap2
        /* "#utility.yul":1912:1924   */
      dup2
      dup2
      add
      swap1
        /* "#utility.yul":1992:2007   */
      dup7
      dup5
      gt
        /* "#utility.yul":1989:2024   */
      iszero
      tag_92
      jumpi
        /* "#utility.yul":2020:2021   */
      0x00
        /* "#utility.yul":2017:2018   */
      dup1
        /* "#utility.yul":2010:2022   */
      revert
        /* "#utility.yul":1989:2024   */
    tag_92:
        /* "#utility.yul":2056:2058   */
      dup3
        /* "#utility.yul":2048:2054   */
      dup7
        /* "#utility.yul":2044:2059   */
      add
        /* "#utility.yul":2068:2210   */
    tag_93:
        /* "#utility.yul":2084:2090   */
      dup5
        /* "#utility.yul":2079:2082   */
      dup2
        /* "#utility.yul":2076:2091   */
      lt
        /* "#utility.yul":2068:2210   */
      iszero
      tag_86
      jumpi
        /* "#utility.yul":2150:2167   */
      dup1
      calldataload
        /* "#utility.yul":2138:2168   */
      dup4
      mstore
        /* "#utility.yul":2188:2200   */
      swap2
      dup4
      add
      swap2
        /* "#utility.yul":2101:2113   */
      dup4
      add
        /* "#utility.yul":2068:2210   */
      jump(tag_93)
        /* "#utility.yul":2244:2976   */
    tag_9:
        /* "#utility.yul":2380:2386   */
      0x00
        /* "#utility.yul":2388:2394   */
      dup1
        /* "#utility.yul":2396:2402   */
      0x00
        /* "#utility.yul":2404:2410   */
      dup1
        /* "#utility.yul":2457:2460   */
      0x80
        /* "#utility.yul":2445:2454   */
      dup6
        /* "#utility.yul":2436:2443   */
      dup8
        /* "#utility.yul":2432:2455   */
      sub
        /* "#utility.yul":2428:2461   */
      slt
        /* "#utility.yul":2425:2478   */
      iszero
      tag_97
      jumpi
        /* "#utility.yul":2474:2475   */
      0x00
        /* "#utility.yul":2471:2472   */
      dup1
        /* "#utility.yul":2464:2476   */
      revert
        /* "#utility.yul":2425:2478   */
    tag_97:
        /* "#utility.yul":2510:2519   */
      dup5
        /* "#utility.yul":2497:2520   */
      calldataload
        /* "#utility.yul":2487:2520   */
      swap4
      pop
        /* "#utility.yul":2571:2573   */
      0x20
        /* "#utility.yul":2560:2569   */
      dup6
        /* "#utility.yul":2556:2574   */
      add
        /* "#utility.yul":2543:2575   */
      calldataload
        /* "#utility.yul":2594:2612   */
      0xffffffffffffffff
        /* "#utility.yul":2635:2637   */
      dup1
        /* "#utility.yul":2627:2633   */
      dup3
        /* "#utility.yul":2624:2638   */
      gt
        /* "#utility.yul":2621:2655   */
      iszero
      tag_98
      jumpi
        /* "#utility.yul":2651:2652   */
      0x00
        /* "#utility.yul":2648:2649   */
      dup1
        /* "#utility.yul":2641:2653   */
      revert
        /* "#utility.yul":2621:2655   */
    tag_98:
        /* "#utility.yul":2674:2735   */
      tag_99
        /* "#utility.yul":2727:2734   */
      dup9
        /* "#utility.yul":2718:2724   */
      dup4
        /* "#utility.yul":2707:2716   */
      dup10
        /* "#utility.yul":2703:2725   */
      add
        /* "#utility.yul":2674:2735   */
      tag_67
      jump	// in
    tag_99:
        /* "#utility.yul":2664:2735   */
      swap5
      pop
        /* "#utility.yul":2788:2790   */
      0x40
        /* "#utility.yul":2777:2786   */
      dup8
        /* "#utility.yul":2773:2791   */
      add
        /* "#utility.yul":2760:2792   */
      calldataload
        /* "#utility.yul":2744:2792   */
      swap2
      pop
        /* "#utility.yul":2817:2819   */
      dup1
        /* "#utility.yul":2807:2815   */
      dup3
        /* "#utility.yul":2804:2820   */
      gt
        /* "#utility.yul":2801:2837   */
      iszero
      tag_100
      jumpi
        /* "#utility.yul":2833:2834   */
      0x00
        /* "#utility.yul":2830:2831   */
      dup1
        /* "#utility.yul":2823:2835   */
      revert
        /* "#utility.yul":2801:2837   */
    tag_100:
      pop
        /* "#utility.yul":2856:2919   */
      tag_101
        /* "#utility.yul":2911:2918   */
      dup8
        /* "#utility.yul":2900:2908   */
      dup3
        /* "#utility.yul":2889:2898   */
      dup9
        /* "#utility.yul":2885:2909   */
      add
        /* "#utility.yul":2856:2919   */
      tag_68
      jump	// in
    tag_101:
        /* "#utility.yul":2244:2976   */
      swap5
      swap8
      swap4
      swap7
      pop
        /* "#utility.yul":2846:2919   */
      swap4
      swap5
        /* "#utility.yul":2966:2968   */
      0x60
        /* "#utility.yul":2951:2969   */
      add
        /* "#utility.yul":2938:2970   */
      calldataload
      swap4
      pop
      pop
      pop
        /* "#utility.yul":2244:2976   */
      jump	// out
        /* "#utility.yul":3484:4147   */
    tag_21:
        /* "#utility.yul":3611:3617   */
      0x00
        /* "#utility.yul":3619:3625   */
      dup1
        /* "#utility.yul":3627:3633   */
      0x00
        /* "#utility.yul":3680:3682   */
      0x60
        /* "#utility.yul":3668:3677   */
      dup5
        /* "#utility.yul":3659:3666   */
      dup7
        /* "#utility.yul":3655:3678   */
      sub
        /* "#utility.yul":3651:3683   */
      slt
        /* "#utility.yul":3648:3700   */
      iszero
      tag_105
      jumpi
        /* "#utility.yul":3696:3697   */
      0x00
        /* "#utility.yul":3693:3694   */
      dup1
        /* "#utility.yul":3686:3698   */
      revert
        /* "#utility.yul":3648:3700   */
    tag_105:
        /* "#utility.yul":3736:3745   */
      dup4
        /* "#utility.yul":3723:3746   */
      calldataload
        /* "#utility.yul":3765:3783   */
      0xffffffffffffffff
        /* "#utility.yul":3806:3808   */
      dup1
        /* "#utility.yul":3798:3804   */
      dup3
        /* "#utility.yul":3795:3809   */
      gt
        /* "#utility.yul":3792:3826   */
      iszero
      tag_106
      jumpi
        /* "#utility.yul":3822:3823   */
      0x00
        /* "#utility.yul":3819:3820   */
      dup1
        /* "#utility.yul":3812:3824   */
      revert
        /* "#utility.yul":3792:3826   */
    tag_106:
        /* "#utility.yul":3845:3906   */
      tag_107
        /* "#utility.yul":3898:3905   */
      dup8
        /* "#utility.yul":3889:3895   */
      dup4
        /* "#utility.yul":3878:3887   */
      dup9
        /* "#utility.yul":3874:3896   */
      add
        /* "#utility.yul":3845:3906   */
      tag_67
      jump	// in
    tag_107:
        /* "#utility.yul":3835:3906   */
      swap5
      pop
        /* "#utility.yul":3959:3961   */
      0x20
        /* "#utility.yul":3948:3957   */
      dup7
        /* "#utility.yul":3944:3962   */
      add
        /* "#utility.yul":3931:3963   */
      calldataload
        /* "#utility.yul":3915:3963   */
      swap2
      pop
        /* "#utility.yul":3988:3990   */
      dup1
        /* "#utility.yul":3978:3986   */
      dup3
        /* "#utility.yul":3975:3991   */
      gt
        /* "#utility.yul":3972:4008   */
      iszero
      tag_108
      jumpi
        /* "#utility.yul":4004:4005   */
      0x00
        /* "#utility.yul":4001:4002   */
      dup1
        /* "#utility.yul":3994:4006   */
      revert
        /* "#utility.yul":3972:4008   */
    tag_108:
      pop
        /* "#utility.yul":4027:4090   */
      tag_109
        /* "#utility.yul":4082:4089   */
      dup7
        /* "#utility.yul":4071:4079   */
      dup3
        /* "#utility.yul":4060:4069   */
      dup8
        /* "#utility.yul":4056:4080   */
      add
        /* "#utility.yul":4027:4090   */
      tag_68
      jump	// in
    tag_109:
        /* "#utility.yul":4017:4090   */
      swap3
      pop
      pop
        /* "#utility.yul":4137:4139   */
      0x40
        /* "#utility.yul":4126:4135   */
      dup5
        /* "#utility.yul":4122:4140   */
      add
        /* "#utility.yul":4109:4141   */
      calldataload
        /* "#utility.yul":4099:4141   */
      swap1
      pop
        /* "#utility.yul":3484:4147   */
      swap3
      pop
      swap3
      pop
      swap3
      jump	// out
        /* "#utility.yul":4454:4638   */
    tag_40:
        /* "#utility.yul":4506:4583   */
      0x4e487b7100000000000000000000000000000000000000000000000000000000
        /* "#utility.yul":4503:4504   */
      0x00
        /* "#utility.yul":4496:4584   */
      mstore
        /* "#utility.yul":4603:4607   */
      0x32
        /* "#utility.yul":4600:4601   */
      0x04
        /* "#utility.yul":4593:4608   */
      mstore
        /* "#utility.yul":4627:4631   */
      0x24
        /* "#utility.yul":4624:4625   */
      0x00
        /* "#utility.yul":4617:4632   */
      revert
        /* "#utility.yul":4643:4827   */
    tag_49:
        /* "#utility.yul":4713:4719   */
      0x00
        /* "#utility.yul":4766:4768   */
      0x20
        /* "#utility.yul":4754:4763   */
      dup3
        /* "#utility.yul":4745:4752   */
      dup5
        /* "#utility.yul":4741:4764   */
      sub
        /* "#utility.yul":4737:4769   */
      slt
        /* "#utility.yul":4734:4786   */
      iszero
      tag_113
      jumpi
        /* "#utility.yul":4782:4783   */
      0x00
        /* "#utility.yul":4779:4780   */
      dup1
        /* "#utility.yul":4772:4784   */
      revert
        /* "#utility.yul":4734:4786   */
    tag_113:
      pop
        /* "#utility.yul":4805:4821   */
      mload
      swap2
        /* "#utility.yul":4643:4827   */
      swap1
      pop
      jump	// out
        /* "#utility.yul":4832:5121   */
    tag_51:
        /* "#utility.yul":4871:4874   */
      0x00
      not(0x00)
        /* "#utility.yul":4892:4909   */
      dup3
      eq
        /* "#utility.yul":4889:5086   */
      iszero
      tag_115
      jumpi
        /* "#utility.yul":4942:5019   */
      0x4e487b7100000000000000000000000000000000000000000000000000000000
        /* "#utility.yul":4939:4940   */
      0x00
        /* "#utility.yul":4932:5020   */
      mstore
        /* "#utility.yul":5043:5047   */
      0x11
        /* "#utility.yul":5040:5041   */
      0x04
        /* "#utility.yul":5033:5048   */
      mstore
        /* "#utility.yul":5071:5075   */
      0x24
        /* "#utility.yul":5068:5069   */
      0x00
        /* "#utility.yul":5061:5076   */
      revert
        /* "#utility.yul":4889:5086   */
    tag_115:
      pop
        /* "#utility.yul":5113:5114   */
      0x01
        /* "#utility.yul":5102:5115   */
      add
      swap1
        /* "#utility.yul":4832:5121   */
      jump	// out
        /* "#utility.yul":5126:5377   */
    tag_57:
        /* "#utility.yul":5196:5202   */
      0x00
        /* "#utility.yul":5249:5251   */
      0x20
        /* "#utility.yul":5237:5246   */
      dup3
        /* "#utility.yul":5228:5235   */
      dup5
        /* "#utility.yul":5224:5247   */
      sub
        /* "#utility.yul":5220:5252   */
      slt
        /* "#utility.yul":5217:5269   */
      iszero
      tag_117
      jumpi
        /* "#utility.yul":5265:5266   */
      0x00
        /* "#utility.yul":5262:5263   */
      dup1
        /* "#utility.yul":5255:5267   */
      revert
        /* "#utility.yul":5217:5269   */
    tag_117:
        /* "#utility.yul":5297:5306   */
      dup2
        /* "#utility.yul":5291:5307   */
      mload
        /* "#utility.yul":5316:5347   */
      tag_118
        /* "#utility.yul":5341:5346   */
      dup2
        /* "#utility.yul":5316:5347   */
      tag_66
      jump	// in
    tag_118:
        /* "#utility.yul":5366:5371   */
      swap4
        /* "#utility.yul":5126:5377   */
      swap3
      pop
      pop
      pop
      jump	// out

    auxdata: 0xa26469706673582212205bd18a3de273e40aca6a73f67739dda3396febba0d64bf625fd3b37f269609bd64736f6c63430008090033
}

