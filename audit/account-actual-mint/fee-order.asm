
======= audit/account-actual-mint/FeeOrder.sol:FeeOrder =======
EVM assembly:
    /* "audit/account-actual-mint/FeeOrder.sol":23:201  contract FeeOrder { function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } } */
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
  dataSize(sub_0)
  dup1
  dataOffset(sub_0)
  0x00
  codecopy
  0x00
  return
stop

sub_0: assembly {
        /* "audit/account-actual-mint/FeeOrder.sol":23:201  contract FeeOrder { function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } } */
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
      0x40b31196
      eq
      tag_3
      jumpi
    tag_2:
      0x00
      dup1
      revert
        /* "audit/account-actual-mint/FeeOrder.sol":43:199  function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } */
    tag_3:
      tag_4
      tag_5
      calldatasize
      0x04
      tag_6
      jump	// in
    tag_5:
      tag_7
      jump	// in
    tag_4:
      mload(0x40)
        /* "#utility.yul":481:506   */
      swap1
      dup2
      mstore
        /* "#utility.yul":469:471   */
      0x20
        /* "#utility.yul":454:472   */
      add
        /* "audit/account-actual-mint/FeeOrder.sol":43:199  function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } */
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      return
    tag_7:
        /* "audit/account-actual-mint/FeeOrder.sol":134:141  uint256 */
      0x00
        /* "audit/account-actual-mint/FeeOrder.sol":175:195  postEther - feeEther */
      tag_11
        /* "audit/account-actual-mint/FeeOrder.sol":187:195  feeEther */
      dup5
        /* "audit/account-actual-mint/FeeOrder.sol":175:184  postEther */
      dup4
        /* "audit/account-actual-mint/FeeOrder.sol":175:195  postEther - feeEther */
      tag_12
      jump	// in
    tag_11:
        /* "audit/account-actual-mint/FeeOrder.sol":153:170  feeEther * shares */
      tag_13
        /* "audit/account-actual-mint/FeeOrder.sol":164:170  shares */
      dup5
        /* "audit/account-actual-mint/FeeOrder.sol":153:161  feeEther */
      dup7
        /* "audit/account-actual-mint/FeeOrder.sol":153:170  feeEther * shares */
      tag_14
      jump	// in
    tag_13:
        /* "audit/account-actual-mint/FeeOrder.sol":152:196  (feeEther * shares) / (postEther - feeEther) */
      tag_15
      swap2
      swap1
      tag_16
      jump	// in
    tag_15:
        /* "audit/account-actual-mint/FeeOrder.sol":145:196  return (feeEther * shares) / (postEther - feeEther) */
      swap5
        /* "audit/account-actual-mint/FeeOrder.sol":43:199  function quantity(uint256 feeEther,uint256 shares,uint256 postEther) external pure returns(uint256) { return (feeEther * shares) / (postEther - feeEther); } */
      swap4
      pop
      pop
      pop
      pop
      jump	// out
        /* "#utility.yul":14:330   */
    tag_6:
        /* "#utility.yul":91:97   */
      0x00
        /* "#utility.yul":99:105   */
      dup1
        /* "#utility.yul":107:113   */
      0x00
        /* "#utility.yul":160:162   */
      0x60
        /* "#utility.yul":148:157   */
      dup5
        /* "#utility.yul":139:146   */
      dup7
        /* "#utility.yul":135:158   */
      sub
        /* "#utility.yul":131:163   */
      slt
        /* "#utility.yul":128:180   */
      iszero
      tag_20
      jumpi
        /* "#utility.yul":176:177   */
      0x00
        /* "#utility.yul":173:174   */
      dup1
        /* "#utility.yul":166:178   */
      revert
        /* "#utility.yul":128:180   */
    tag_20:
      pop
      pop
        /* "#utility.yul":199:222   */
      dup2
      calldataload
      swap4
        /* "#utility.yul":269:271   */
      0x20
        /* "#utility.yul":254:272   */
      dup4
      add
        /* "#utility.yul":241:273   */
      calldataload
      swap4
      pop
        /* "#utility.yul":320:322   */
      0x40
        /* "#utility.yul":305:323   */
      swap1
      swap3
      add
        /* "#utility.yul":292:324   */
      calldataload
      swap2
        /* "#utility.yul":14:330   */
      swap1
      pop
      jump	// out
        /* "#utility.yul":517:644   */
    tag_17:
        /* "#utility.yul":578:588   */
      0x4e487b71
        /* "#utility.yul":573:576   */
      0xe0
        /* "#utility.yul":569:589   */
      shl
        /* "#utility.yul":566:567   */
      0x00
        /* "#utility.yul":559:590   */
      mstore
        /* "#utility.yul":609:613   */
      0x11
        /* "#utility.yul":606:607   */
      0x04
        /* "#utility.yul":599:614   */
      mstore
        /* "#utility.yul":633:637   */
      0x24
        /* "#utility.yul":630:631   */
      0x00
        /* "#utility.yul":623:638   */
      revert
        /* "#utility.yul":649:774   */
    tag_12:
        /* "#utility.yul":689:693   */
      0x00
        /* "#utility.yul":717:718   */
      dup3
        /* "#utility.yul":714:715   */
      dup3
        /* "#utility.yul":711:719   */
      lt
        /* "#utility.yul":708:742   */
      iszero
      tag_25
      jumpi
        /* "#utility.yul":722:740   */
      tag_25
      tag_17
      jump	// in
    tag_25:
      pop
        /* "#utility.yul":759:768   */
      sub
      swap1
        /* "#utility.yul":649:774   */
      jump	// out
        /* "#utility.yul":779:947   */
    tag_14:
        /* "#utility.yul":819:826   */
      0x00
        /* "#utility.yul":885:886   */
      dup2
        /* "#utility.yul":881:882   */
      0x00
        /* "#utility.yul":877:883   */
      not
        /* "#utility.yul":873:887   */
      div
        /* "#utility.yul":870:871   */
      dup4
        /* "#utility.yul":867:888   */
      gt
        /* "#utility.yul":862:863   */
      dup3
        /* "#utility.yul":855:864   */
      iszero
        /* "#utility.yul":848:865   */
      iszero
        /* "#utility.yul":844:889   */
      and
        /* "#utility.yul":841:912   */
      iszero
      tag_28
      jumpi
        /* "#utility.yul":892:910   */
      tag_28
      tag_17
      jump	// in
    tag_28:
      pop
        /* "#utility.yul":932:941   */
      mul
      swap1
        /* "#utility.yul":779:947   */
      jump	// out
        /* "#utility.yul":952:1169   */
    tag_16:
        /* "#utility.yul":992:993   */
      0x00
        /* "#utility.yul":1018:1019   */
      dup3
        /* "#utility.yul":1008:1140   */
      tag_30
      jumpi
        /* "#utility.yul":1062:1072   */
      0x4e487b71
        /* "#utility.yul":1057:1060   */
      0xe0
        /* "#utility.yul":1053:1073   */
      shl
        /* "#utility.yul":1050:1051   */
      0x00
        /* "#utility.yul":1043:1074   */
      mstore
        /* "#utility.yul":1097:1101   */
      0x12
        /* "#utility.yul":1094:1095   */
      0x04
        /* "#utility.yul":1087:1102   */
      mstore
        /* "#utility.yul":1125:1129   */
      0x24
        /* "#utility.yul":1122:1123   */
      0x00
        /* "#utility.yul":1115:1130   */
      revert
        /* "#utility.yul":1008:1140   */
    tag_30:
      pop
        /* "#utility.yul":1154:1163   */
      div
      swap1
        /* "#utility.yul":952:1169   */
      jump	// out

    auxdata: 0xa2646970667358221220a85b093c11f32ffaa28229f91edada4b73bfe1d0088d8c97608ad9d6527d1de764736f6c63430008090033
}

