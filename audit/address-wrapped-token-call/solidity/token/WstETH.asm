    /* "src/core/WstETH.sol":1052:4250  contract WstETH is ERC20Permit {... */
  mstore(0x40, 0x0140)
    /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1006:1101  keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)") */
  0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
    /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":961:1101  bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)") */
  0x0120
  mstore
    /* "src/core/WstETH.sol":1187:1378  constructor(IStETH _stETH)... */
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
  dup2
  add
  0x40
  mstore
  0x20
  dup2
  lt
  iszero
  tag_2
  jumpi
  0x00
  dup1
  revert
tag_2:
  pop
  mload
    /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1333:1399  constructor(string memory name) internal EIP712(name, "1") {... */
  0x40
  dup1
  mload
  dup1
  dup3
  add
  dup3
  mstore
  0x1f
  dup1
  dup3
  mstore
  0x57726170706564206c6971756964207374616b656420457468657220322e3000
    /* "src/core/WstETH.sol":1187:1378  constructor(IStETH _stETH)... */
  0x20
    /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1333:1399  constructor(string memory name) internal EIP712(name, "1") {... */
  dup4
  dup2
  add
  dup3
  swap1
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2324:2875  constructor(string memory name, string memory version) internal {... */
  dup5
  mload
  dup1
  dup7
  add
  dup7
  mstore
  0x01
  dup2
  mstore
  shl(0xf8, 0x31)
  dup2
  dup4
  add
  mstore
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":1958:2103  constructor (string memory name_, string memory symbol_) public {... */
  dup6
  mload
  dup1
  dup8
  add
  dup8
  mstore
  swap4
  dup5
  mstore
  dup4
  dup3
  add
  swap3
  dup4
  mstore
  dup6
  mload
  dup1
  dup8
  add
  swap1
  swap7
  mstore
  0x06
  dup7
  mstore
  shl(0xd3, 0x0eee6e88aa89)
  swap2
  dup7
  add
  swap2
  swap1
  swap2
  mstore
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2032:2045  _name = name_ */
  dup3
  mload
    /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1333:1399  constructor(string memory name) internal EIP712(name, "1") {... */
  swap4
  swap5
  dup6
  swap5
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2324:2875  constructor(string memory name, string memory version) internal {... */
  swap2
  swap4
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":1958:2103  constructor (string memory name_, string memory symbol_) public {... */
  swap3
  swap1
  swap2
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2032:2045  _name = name_ */
  tag_8
  swap2
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2032:2037  _name */
  0x03
  swap2
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2032:2045  _name = name_ */
  tag_9
  jump	// in
tag_8:
  pop
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2055:2072  _symbol = symbol_ */
  dup1
  mload
  tag_10
  swap1
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2055:2062  _symbol */
  0x04
  swap1
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2055:2072  _symbol = symbol_ */
  0x20
  dup5
  add
  swap1
  tag_9
  jump	// in
tag_10:
  pop
  pop
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2082:2091  _decimals */
  0x05
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2082:2096  _decimals = 18 */
  dup1
  sload
  not(0xff)
  and
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2094:2096  18 */
  0x12
    /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2082:2096  _decimals = 18 */
  or
  swap1
  sstore
  pop
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2419:2441  keccak256(bytes(name)) */
  dup2
  mload
  0x20
  dup1
  dup5
  add
  swap2
  swap1
  swap2
  keccak256
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2475:2500  keccak256(bytes(version)) */
  dup3
  mload
  swap2
  dup4
  add
  swap2
  swap1
  swap2
  keccak256
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2634:2659  _HASHED_NAME = hashedName */
  0xc0
  dup3
  swap1
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2669:2700  _HASHED_VERSION = hashedVersion */
  0xe0
  dup2
  swap1
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2529:2624  keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)") */
  0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2729:2742  _getChainId() */
  tag_12
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2729:2740  _getChainId */
  tag_13
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2729:2742  _getChainId() */
  jump	// in
tag_12:
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2710:2742  _CACHED_CHAIN_ID = _getChainId() */
  0xa0
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2779:2837  _buildDomainSeparator(typeHash, hashedName, hashedVersion) */
  tag_14
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2801:2809  typeHash */
  dup2
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2811:2821  hashedName */
  dup5
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2823:2836  hashedVersion */
  dup5
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2779:2800  _buildDomainSeparator */
  tag_15
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2779:2837  _buildDomainSeparator(typeHash, hashedName, hashedVersion) */
  jump	// in
tag_14:
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2752:2837  _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion) */
  0x80
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2847:2868  _TYPE_HASH = typeHash */
  0x0100
  mstore
  pop
  pop
    /* "src/core/WstETH.sol":1357:1362  stETH */
  0x07
    /* "src/core/WstETH.sol":1357:1371  stETH = _stETH */
  dup1
  sload
  not(sub(shl(0xa0, 0x01), 0x01))
  and
  sub(shl(0xa0, 0x01), 0x01)
  swap6
  swap1
  swap6
  and
  swap5
  swap1
  swap5
  or
  swap1
  swap4
  sstore
  pop
    /* "src/core/WstETH.sol":1052:4250  contract WstETH is ERC20Permit {... */
  tag_18
  swap2
  pop
  pop
  jump
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4391:4711  function _getChainId() private view returns (uint256 chainId) {... */
tag_13:
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4686:4695  chainid() */
  chainid
  swap1
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4661:4705  {... */
  jump	// out
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3250:3577  function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {... */
tag_15:
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3352:3359  bytes32 */
  0x00
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3429:3437  typeHash */
  dup4
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3455:3459  name */
  dup4
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3477:3484  version */
  dup4
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3515  _getChainId() */
  tag_21
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3513  _getChainId */
  tag_13
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3515  _getChainId() */
  jump	// in
tag_21:
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3541:3545  this */
  address
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3401:3560  abi.encode(... */
  add(0x20, mload(0x40))
  dup1
  dup7
  dup2
  mstore
  0x20
  add
  dup6
  dup2
  mstore
  0x20
  add
  dup5
  dup2
  mstore
  0x20
  add
  dup4
  dup2
  mstore
  0x20
  add
  dup3
  sub(shl(0xa0, 0x01), 0x01)
  and
  dup2
  mstore
  0x20
  add
  swap6
  pop
  pop
  pop
  pop
  pop
  pop
  mload(0x40)
  0x20
  dup2
  dup4
  sub
  sub
  dup2
  mstore
  swap1
  0x40
  mstore
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3378:3570  keccak256(... */
  dup1
  mload
  swap1
  0x20
  add
  keccak256
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3371:3570  return keccak256(... */
  swap1
  pop
    /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3250:3577  function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {... */
  swap4
  swap3
  pop
  pop
  pop
  jump	// out
    /* "src/core/WstETH.sol":1052:4250  contract WstETH is ERC20Permit {... */
tag_9:
  dup3
  dup1
  sload
  0x01
  dup2
  0x01
  and
  iszero
  0x0100
  mul
  sub
  and
  0x02
  swap1
  div
  swap1
  0x00
  mstore
  keccak256(0x00, 0x20)
  swap1
  0x1f
  add
  0x20
  swap1
  div
  dup2
  add
  swap3
  dup3
  0x1f
  lt
  tag_23
  jumpi
  dup1
  mload
  not(0xff)
  and
  dup4
  dup1
  add
  or
  dup6
  sstore
  jump(tag_25)
tag_23:
  dup3
  dup1
  add
  0x01
  add
  dup6
  sstore
  dup3
  iszero
  tag_25
  jumpi
  swap2
  dup3
  add
tag_24:
  dup3
  dup2
  gt
  iszero
  tag_25
  jumpi
  dup3
  mload
  dup3
  sstore
  swap2
  0x20
  add
  swap2
  swap1
  0x01
  add
  swap1
  jump(tag_24)
tag_25:
  pop
  tag_26
  swap3
  swap2
  pop
  tag_27
  jump	// in
tag_26:
  pop
  swap1
  jump	// out
tag_27:
tag_28:
  dup1
  dup3
  gt
  iszero
  tag_26
  jumpi
  0x00
  dup2
  sstore
  0x01
  add
  jump(tag_28)
tag_18:
  mload(0x80)
  mload(0xa0)
  mload(0xc0)
  mload(0xe0)
  mload(0x0100)
  mload(0x0120)
  codecopy(0x00, dataOffset(sub_0), dataSize(sub_0))
  assignImmutable("0x3ac7ca38fd21a491cc5fb19169926fdbe6b54822181a3fae6f9aebec8e42713d")
  assignImmutable("0x24036ccf201a67256250eabe66d3f9fd72f9c4d022f225a8ee964be060dcb993")
  assignImmutable("0x7dbef654fd5c6145f82b72cd5dbbfc6d48fd276b8a7a4371a61d55985b9d6d8b")
  assignImmutable("0xac09810740600c31fa69f9db79ed6fc3e3281f758a950fe1fb254a3a3ae571b6")
  assignImmutable("0x9af6e0c6f9b8f572459f1957d56f01ba73ab5558fbad6cdb8b94d4ee7705c26c")
  assignImmutable("0x583f4f71b32721321fd0f20e674c3938142ce9f243e802c16cfc4def7d2dc523")
  return(0x00, dataSize(sub_0))
stop

sub_0: assembly {
        /* "src/core/WstETH.sol":1052:4250  contract WstETH is ERC20Permit {... */
      mstore(0x40, 0x80)
      jumpi(tag_1, lt(calldatasize, 0x04))
      shr(0xe0, calldataload(0x00))
      dup1
      0x9576a0c8
      gt
      tag_24
      jumpi
      dup1
      0xbb2952fc
      gt
      tag_25
      jumpi
      dup1
      0xbb2952fc
      eq
      tag_18
      jumpi
      dup1
      0xc1fe3e48
      eq
      tag_19
      jumpi
      dup1
      0xd505accf
      eq
      tag_20
      jumpi
      dup1
      0xdd62ed3e
      eq
      tag_21
      jumpi
      dup1
      0xde0e9a3e
      eq
      tag_22
      jumpi
      dup1
      0xea598cb0
      eq
      tag_23
      jumpi
      jump(tag_2)
    tag_25:
      dup1
      0x9576a0c8
      eq
      tag_13
      jumpi
      dup1
      0x95d89b41
      eq
      tag_14
      jumpi
      dup1
      0xa457c2d7
      eq
      tag_15
      jumpi
      dup1
      0xa9059cbb
      eq
      tag_16
      jumpi
      dup1
      0xb0e38900
      eq
      tag_17
      jumpi
      jump(tag_2)
    tag_24:
      dup1
      0x313ce567
      gt
      tag_26
      jumpi
      dup1
      0x313ce567
      eq
      tag_8
      jumpi
      dup1
      0x3644e515
      eq
      tag_9
      jumpi
      dup1
      0x39509351
      eq
      tag_10
      jumpi
      dup1
      0x70a08231
      eq
      tag_11
      jumpi
      dup1
      0x7ecebe00
      eq
      tag_12
      jumpi
      jump(tag_2)
    tag_26:
      dup1
      0x035faf82
      eq
      tag_3
      jumpi
      dup1
      0x06fdde03
      eq
      tag_4
      jumpi
      dup1
      0x095ea7b3
      eq
      tag_5
      jumpi
      dup1
      0x18160ddd
      eq
      tag_6
      jumpi
      dup1
      0x23b872dd
      eq
      tag_7
      jumpi
      jump(tag_2)
    tag_1:
      jumpi(tag_2, calldatasize)
        /* "src/core/WstETH.sol":3029:3034  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":3029:3071  stETH.submit{value: msg.value}(address(0)) */
      0x40
      dup1
      mload
      shl(0xe0, 0xa1903eab)
      dup2
      mstore
        /* "src/core/WstETH.sol":3012:3026  uint256 shares */
      0x00
        /* "src/core/WstETH.sol":3029:3071  stETH.submit{value: msg.value}(address(0)) */
      0x04
      dup3
      add
      dup2
      swap1
      mstore
      swap2
      mload
        /* "src/core/WstETH.sol":3012:3026  uint256 shares */
      swap2
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":3029:3034  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":3029:3041  stETH.submit */
      0xa1903eab
      swap2
        /* "src/core/WstETH.sol":3049:3058  msg.value */
      callvalue
      swap2
        /* "src/core/WstETH.sol":3029:3071  stETH.submit{value: msg.value}(address(0)) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":3049:3058  msg.value */
      dup6
        /* "src/core/WstETH.sol":3029:3034  stETH */
      dup9
        /* "src/core/WstETH.sol":3029:3071  stETH.submit{value: msg.value}(address(0)) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_29
      jumpi
      0x00
      dup1
      revert
    tag_29:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_31
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_31:
      pop
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_32
      jumpi
      0x00
      dup1
      revert
    tag_32:
      pop
      mload
      swap1
      pop
        /* "src/core/WstETH.sol":3081:3106  _mint(msg.sender, shares) */
      tag_33
        /* "src/core/WstETH.sol":3087:3097  msg.sender */
      caller
        /* "src/core/WstETH.sol":3029:3071  stETH.submit{value: msg.value}(address(0)) */
      dup3
        /* "src/core/WstETH.sol":3081:3086  _mint */
      tag_34
        /* "src/core/WstETH.sol":3081:3106  _mint(msg.sender, shares) */
      jump	// in
    tag_33:
        /* "src/core/WstETH.sol":2975:3113  receive() external payable {... */
      pop
        /* "src/core/WstETH.sol":1052:4250  contract WstETH is ERC20Permit {... */
      stop
    tag_2:
      0x00
      dup1
      revert
        /* "src/core/WstETH.sol":3895:4011  function stEthPerToken() external view returns (uint256) {... */
    tag_3:
      callvalue
      dup1
      iszero
      tag_35
      jumpi
      0x00
      dup1
      revert
    tag_35:
      pop
      tag_36
      tag_37
      jump	// in
    tag_36:
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2168:2257  function name() public view virtual returns (string memory) {... */
    tag_4:
      callvalue
      dup1
      iszero
      tag_38
      jumpi
      0x00
      dup1
      revert
    tag_38:
      pop
      tag_39
      tag_40
      jump	// in
    tag_39:
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
      0x00
    tag_41:
      dup4
      dup2
      lt
      iszero
      tag_43
      jumpi
      dup2
      dup2
      add
      mload
      dup4
      dup3
      add
      mstore
      0x20
      add
      jump(tag_41)
    tag_43:
      pop
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
      tag_44
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x01
      dup4
      0x20
      sub
      0x0100
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
    tag_44:
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4244:4410  function approve(address spender, uint256 amount) public virtual override returns (bool) {... */
    tag_5:
      callvalue
      dup1
      iszero
      tag_45
      jumpi
      0x00
      dup1
      revert
    tag_45:
      pop
      tag_46
      0x04
      dup1
      calldatasize
      sub
      0x40
      dup2
      lt
      iszero
      tag_47
      jumpi
      0x00
      dup1
      revert
    tag_47:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      and
      swap1
      0x20
      add
      calldataload
      tag_48
      jump	// in
    tag_46:
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3235:3341  function totalSupply() public view virtual override returns (uint256) {... */
    tag_6:
      callvalue
      dup1
      iszero
      tag_49
      jumpi
      0x00
      dup1
      revert
    tag_49:
      pop
      tag_36
      tag_51
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4877:5194  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {... */
    tag_7:
      callvalue
      dup1
      iszero
      tag_52
      jumpi
      0x00
      dup1
      revert
    tag_52:
      pop
      tag_46
      0x04
      dup1
      calldatasize
      sub
      0x60
      dup2
      lt
      iszero
      tag_54
      jumpi
      0x00
      dup1
      revert
    tag_54:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      dup2
      and
      swap2
      0x20
      dup2
      add
      calldataload
      swap1
      swap2
      and
      swap1
      0x40
      add
      calldataload
      tag_55
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3086:3175  function decimals() public view virtual returns (uint8) {... */
    tag_8:
      callvalue
      dup1
      iszero
      tag_56
      jumpi
      0x00
      dup1
      revert
    tag_56:
      pop
      tag_57
      tag_58
      jump	// in
    tag_57:
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
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2557:2670  function DOMAIN_SEPARATOR() external view override returns (bytes32) {... */
    tag_9:
      callvalue
      dup1
      iszero
      tag_59
      jumpi
      0x00
      dup1
      revert
    tag_59:
      pop
      tag_36
      tag_61
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5589:5804  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {... */
    tag_10:
      callvalue
      dup1
      iszero
      tag_62
      jumpi
      0x00
      dup1
      revert
    tag_62:
      pop
      tag_46
      0x04
      dup1
      calldatasize
      sub
      0x40
      dup2
      lt
      iszero
      tag_64
      jumpi
      0x00
      dup1
      revert
    tag_64:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      and
      swap1
      0x20
      add
      calldataload
      tag_65
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3399:3524  function balanceOf(address account) public view virtual override returns (uint256) {... */
    tag_11:
      callvalue
      dup1
      iszero
      tag_66
      jumpi
      0x00
      dup1
      revert
    tag_66:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_68
      jumpi
      0x00
      dup1
      revert
    tag_68:
      pop
      calldataload
      sub(shl(0xa0, 0x01), 0x01)
      and
      tag_69
      jump	// in
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2315:2433  function nonces(address owner) public view override returns (uint256) {... */
    tag_12:
      callvalue
      dup1
      iszero
      tag_70
      jumpi
      0x00
      dup1
      revert
    tag_70:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_72
      jumpi
      0x00
      dup1
      revert
    tag_72:
      pop
      calldataload
      sub(shl(0xa0, 0x01), 0x01)
      and
      tag_73
      jump	// in
        /* "src/core/WstETH.sol":4131:4248  function tokensPerStEth() external view returns (uint256) {... */
    tag_13:
      callvalue
      dup1
      iszero
      tag_74
      jumpi
      0x00
      dup1
      revert
    tag_74:
      pop
      tag_36
      tag_76
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2370:2463  function symbol() public view virtual returns (string memory) {... */
    tag_14:
      callvalue
      dup1
      iszero
      tag_77
      jumpi
      0x00
      dup1
      revert
    tag_77:
      pop
      tag_39
      tag_79
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6291:6557  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {... */
    tag_15:
      callvalue
      dup1
      iszero
      tag_84
      jumpi
      0x00
      dup1
      revert
    tag_84:
      pop
      tag_46
      0x04
      dup1
      calldatasize
      sub
      0x40
      dup2
      lt
      iszero
      tag_86
      jumpi
      0x00
      dup1
      revert
    tag_86:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      and
      swap1
      0x20
      add
      calldataload
      tag_87
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3727:3899  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {... */
    tag_16:
      callvalue
      dup1
      iszero
      tag_88
      jumpi
      0x00
      dup1
      revert
    tag_88:
      pop
      tag_46
      0x04
      dup1
      calldatasize
      sub
      0x40
      dup2
      lt
      iszero
      tag_90
      jumpi
      0x00
      dup1
      revert
    tag_90:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      and
      swap1
      0x20
      add
      calldataload
      tag_91
      jump	// in
        /* "src/core/WstETH.sol":3299:3443  function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {... */
    tag_17:
      callvalue
      dup1
      iszero
      tag_92
      jumpi
      0x00
      dup1
      revert
    tag_92:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_94
      jumpi
      0x00
      dup1
      revert
    tag_94:
      pop
      calldataload
      tag_95
      jump	// in
        /* "src/core/WstETH.sol":3631:3777  function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256) {... */
    tag_18:
      callvalue
      dup1
      iszero
      tag_96
      jumpi
      0x00
      dup1
      revert
    tag_96:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_98
      jumpi
      0x00
      dup1
      revert
    tag_98:
      pop
      calldataload
      tag_99
      jump	// in
        /* "src/core/WstETH.sol":1089:1108  IStETH public stETH */
    tag_19:
      callvalue
      dup1
      iszero
      tag_100
      jumpi
      0x00
      dup1
      revert
    tag_100:
      pop
      tag_101
      tag_102
      jump	// in
    tag_101:
      0x40
      dup1
      mload
      sub(shl(0xa0, 0x01), 0x01)
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
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1460:2254  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {... */
    tag_20:
      callvalue
      dup1
      iszero
      tag_103
      jumpi
      0x00
      dup1
      revert
    tag_103:
      pop
      tag_104
      0x04
      dup1
      calldatasize
      sub
      0xe0
      dup2
      lt
      iszero
      tag_105
      jumpi
      0x00
      dup1
      revert
    tag_105:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      dup2
      and
      swap2
      0x20
      dup2
      add
      calldataload
      swap1
      swap2
      and
      swap1
      0x40
      dup2
      add
      calldataload
      swap1
      0x60
      dup2
      add
      calldataload
      swap1
      0xff
      0x80
      dup3
      add
      calldataload
      and
      swap1
      0xa0
      dup2
      add
      calldataload
      swap1
      0xc0
      add
      calldataload
      tag_106
      jump	// in
    tag_104:
      stop
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3957:4106  function allowance(address owner, address spender) public view virtual override returns (uint256) {... */
    tag_21:
      callvalue
      dup1
      iszero
      tag_107
      jumpi
      0x00
      dup1
      revert
    tag_107:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x40
      dup2
      lt
      iszero
      tag_109
      jumpi
      0x00
      dup1
      revert
    tag_109:
      pop
      sub(shl(0xa0, 0x01), 0x01)
      dup2
      calldataload
      dup2
      and
      swap2
      0x20
      add
      calldataload
      and
      tag_110
      jump	// in
        /* "src/core/WstETH.sol":2546:2889  function unwrap(uint256 _wstETHAmount) external returns (uint256) {... */
    tag_22:
      callvalue
      dup1
      iszero
      tag_111
      jumpi
      0x00
      dup1
      revert
    tag_111:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_113
      jumpi
      0x00
      dup1
      revert
    tag_113:
      pop
      calldataload
      tag_114
      jump	// in
        /* "src/core/WstETH.sol":1866:2216  function wrap(uint256 _stETHAmount) external returns (uint256) {... */
    tag_23:
      callvalue
      dup1
      iszero
      tag_115
      jumpi
      0x00
      dup1
      revert
    tag_115:
      pop
      tag_36
      0x04
      dup1
      calldatasize
      sub
      0x20
      dup2
      lt
      iszero
      tag_117
      jumpi
      0x00
      dup1
      revert
    tag_117:
      pop
      calldataload
      tag_118
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7832:8202  function _mint(address account, uint256 amount) internal virtual {... */
    tag_34:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7915:7936  account != address(0) */
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7907:7972  require(account != address(0), "ERC20: mint to the zero address") */
      tag_120
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1f
      0x24
      dup3
      add
      mstore
      0x45524332303a206d696e7420746f20746865207a65726f206164647265737300
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
    tag_120:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7983:8032  _beforeTokenTransfer(address(0), account, amount) */
      tag_121
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8012:8013  0 */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8016:8023  account */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8025:8031  amount */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7983:8003  _beforeTokenTransfer */
      tag_122
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7983:8032  _beforeTokenTransfer(address(0), account, amount) */
      jump	// in
    tag_121:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8058:8070  _totalSupply */
      sload(0x02)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8058:8082  _totalSupply.add(amount) */
      tag_123
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8075:8081  amount */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8058:8074  _totalSupply.add */
      tag_124
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8058:8082  _totalSupply.add(amount) */
      jump	// in
    tag_123:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8043:8055  _totalSupply */
      0x02
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8043:8082  _totalSupply = _totalSupply.add(amount) */
      sstore
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8131  _balances[account] */
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8122  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8131  _balances[account] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8143  _balances[account].add(amount) */
      tag_125
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8136:8142  amount */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8135  _balances[account].add */
      tag_124
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8113:8143  _balances[account].add(amount) */
      jump	// in
    tag_125:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8110  _balances[account] */
      dup4
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8101  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8110  _balances[account] */
      dup2
      dup2
      mstore
      0x20
      dup2
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8143  _balances[account] = _balances[account].add(amount) */
      swap5
      swap1
      swap5
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8158:8195  Transfer(address(0), account, amount) */
      dup4
      mload
      dup6
      dup2
      mstore
      swap4
      mload
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8110  _balances[account] */
      swap3
      swap4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8092:8101  _balances */
      swap2
      swap3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8158:8195  Transfer(address(0), account, amount) */
      0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
      swap3
      dup2
      swap1
      sub
      swap1
      swap2
      add
      swap1
      log3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7832:8202  function _mint(address account, uint256 amount) internal virtual {... */
      pop
      pop
      jump	// out
        /* "src/core/WstETH.sol":3895:4011  function stEthPerToken() external view returns (uint256) {... */
    tag_37:
        /* "src/core/WstETH.sol":3969:3974  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":3969:4004  stETH.getPooledEthByShares(1 ether) */
      0x40
      dup1
      mload
      shl(0xe3, 0x0f451f71)
      dup2
      mstore
        /* "src/core/WstETH.sol":3996:4003  1 ether */
      0x0de0b6b3a7640000
        /* "src/core/WstETH.sol":3969:4004  stETH.getPooledEthByShares(1 ether) */
      0x04
      dup3
      add
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":3943:3950  uint256 */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":3969:3974  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":3969:3995  stETH.getPooledEthByShares */
      0x7a28fb88
      swap2
        /* "src/core/WstETH.sol":3969:4004  stETH.getPooledEthByShares(1 ether) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":3969:3974  stETH */
      dup7
        /* "src/core/WstETH.sol":3969:4004  stETH.getPooledEthByShares(1 ether) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_127
      jumpi
      0x00
      dup1
      revert
    tag_127:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_129
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_129:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_130
      jumpi
      0x00
      dup1
      revert
    tag_130:
      pop
      mload
      swap1
      pop
        /* "src/core/WstETH.sol":3895:4011  function stEthPerToken() external view returns (uint256) {... */
    tag_126:
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2168:2257  function name() public view virtual returns (string memory) {... */
    tag_40:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2245:2250  _name */
      0x03
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2238:2250  return _name */
      dup1
      sload
      0x40
      dup1
      mload
      0x20
      0x1f
      0x02
      not(0x00)
      0x0100
      0x01
      dup9
      and
      iszero
      mul
      add
      swap1
      swap6
      and
      swap5
      swap1
      swap5
      div
      swap4
      dup5
      add
      dup2
      swap1
      div
      dup2
      mul
      dup3
      add
      dup2
      add
      swap1
      swap3
      mstore
      dup3
      dup2
      mstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2213:2226  string memory */
      0x60
      swap4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2238:2250  return _name */
      swap1
      swap3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2245:2250  _name */
      swap1
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2238:2250  return _name */
      dup4
      add
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2245:2250  _name */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2238:2250  return _name */
      dup3
      dup1
      iszero
      tag_132
      jumpi
      dup1
      0x1f
      lt
      tag_133
      jumpi
      0x0100
      dup1
      dup4
      sload
      div
      mul
      dup4
      mstore
      swap2
      0x20
      add
      swap2
      jump(tag_132)
    tag_133:
      dup3
      add
      swap2
      swap1
      0x00
      mstore
      keccak256(0x00, 0x20)
      swap1
    tag_134:
      dup2
      sload
      dup2
      mstore
      swap1
      0x01
      add
      swap1
      0x20
      add
      dup1
      dup4
      gt
      tag_134
      jumpi
      dup3
      swap1
      sub
      0x1f
      and
      dup3
      add
      swap2
    tag_132:
      pop
      pop
      pop
      pop
      pop
      swap1
      pop
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2168:2257  function name() public view virtual returns (string memory) {... */
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4244:4410  function approve(address spender, uint256 amount) public virtual override returns (bool) {... */
    tag_48:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4327:4331  bool */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4343:4382  _approve(_msgSender(), spender, amount) */
      tag_136
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4352:4364  _msgSender() */
      tag_137
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4352:4362  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4352:4364  _msgSender() */
      jump	// in
    tag_137:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4366:4373  spender */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4375:4381  amount */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4343:4351  _approve */
      tag_139
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4343:4382  _approve(_msgSender(), spender, amount) */
      jump	// in
    tag_136:
      pop
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4399:4403  true */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4244:4410  function approve(address spender, uint256 amount) public virtual override returns (bool) {... */
      swap3
      swap2
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3235:3341  function totalSupply() public view virtual override returns (uint256) {... */
    tag_51:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3322:3334  _totalSupply */
      sload(0x02)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3235:3341  function totalSupply() public view virtual override returns (uint256) {... */
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4877:5194  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {... */
    tag_55:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4983:4987  bool */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4999:5035  _transfer(sender, recipient, amount) */
      tag_142
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5009:5015  sender */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5017:5026  recipient */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5028:5034  amount */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4999:5008  _transfer */
      tag_143
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4999:5035  _transfer(sender, recipient, amount) */
      jump	// in
    tag_142:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5045:5166  _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")) */
      tag_144
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5054:5060  sender */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5062:5074  _msgSender() */
      tag_145
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5062:5072  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5062:5074  _msgSender() */
      jump	// in
    tag_145:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5165  _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance") */
      tag_146
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5114:5120  amount */
      dup6
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5165  _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance") */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
      0x28
      dup2
      mstore
      0x20
      add
      data_974d1b4421da69cc60b481194f0dad36a5bb4e23da810da7a7fb30cdba178330
      0x28
      swap2
      codecopy
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5095  _allowances[sender] */
      dup11
      and
      0x00
      swap1
      dup2
      mstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5087  _allowances */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5095  _allowances[sender] */
      0x20
      mstore
      0x40
      dup2
      keccak256
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5096:5108  _msgSender() */
      tag_147
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5096:5106  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5096:5108  _msgSender() */
      jump	// in
    tag_147:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5109  _allowances[sender][_msgSender()] */
      and
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
      sload
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5165  _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance") */
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5113  _allowances[sender][_msgSender()].sub */
      tag_148
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5076:5165  _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance") */
      jump	// in
    tag_146:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5045:5053  _approve */
      tag_139
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5045:5166  _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")) */
      jump	// in
    tag_144:
      pop
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5183:5187  true */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4877:5194  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {... */
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3086:3175  function decimals() public view virtual returns (uint8) {... */
    tag_58:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3159:3168  _decimals */
      and(0xff, sload(0x05))
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3086:3175  function decimals() public view virtual returns (uint8) {... */
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2557:2670  function DOMAIN_SEPARATOR() external view override returns (bytes32) {... */
    tag_61:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2617:2624  bytes32 */
      0x00
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2643:2663  _domainSeparatorV4() */
      tag_151
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2643:2661  _domainSeparatorV4 */
      tag_152
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2643:2663  _domainSeparatorV4() */
      jump	// in
    tag_151:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2636:2663  return _domainSeparatorV4() */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2557:2670  function DOMAIN_SEPARATOR() external view override returns (bytes32) {... */
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5589:5804  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {... */
    tag_65:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5677:5681  bool */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5693:5776  _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue)) */
      tag_136
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5702:5714  _msgSender() */
      tag_155
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5702:5712  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5702:5714  _msgSender() */
      jump	// in
    tag_155:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5716:5723  spender */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5775  _allowances[_msgSender()][spender].add(addedValue) */
      tag_146
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5764:5774  addedValue */
      dup6
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5736  _allowances */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5750  _allowances[_msgSender()] */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5737:5749  _msgSender() */
      tag_157
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5737:5747  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5737:5749  _msgSender() */
      jump	// in
    tag_157:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5750  _allowances[_msgSender()] */
      swap1
      dup2
      and
      dup3
      mstore
      0x20
      dup1
      dup4
      add
      swap4
      swap1
      swap4
      mstore
      0x40
      swap2
      dup3
      add
      0x00
      swap1
      dup2
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5759  _allowances[_msgSender()][spender] */
      swap2
      dup13
      and
      dup2
      mstore
      swap3
      mstore
      swap1
      keccak256
      sload
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5763  _allowances[_msgSender()][spender].add */
      tag_124
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":5725:5775  _allowances[_msgSender()][spender].add(addedValue) */
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3399:3524  function balanceOf(address account) public view virtual override returns (uint256) {... */
    tag_69:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3499:3517  _balances[account] */
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3473:3480  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3499:3517  _balances[account] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3399:3524  function balanceOf(address account) public view virtual override returns (uint256) {... */
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2315:2433  function nonces(address owner) public view override returns (uint256) {... */
    tag_73:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2416  _nonces[owner] */
      dup2
      and
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2376:2383  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2416  _nonces[owner] */
      swap1
      dup2
      mstore
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2409  _nonces */
      0x06
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2416  _nonces[owner] */
      0x20
      mstore
      0x40
      dup2
      keccak256
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2426  _nonces[owner].current() */
      tag_160
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2424  _nonces[owner].current */
      tag_161
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2402:2426  _nonces[owner].current() */
      jump	// in
    tag_160:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2395:2426  return _nonces[owner].current() */
      swap3
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2315:2433  function nonces(address owner) public view override returns (uint256) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/core/WstETH.sol":4131:4248  function tokensPerStEth() external view returns (uint256) {... */
    tag_76:
        /* "src/core/WstETH.sol":4206:4211  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":4206:4241  stETH.getSharesByPooledEth(1 ether) */
      0x40
      dup1
      mload
      shl(0xe0, 0x19208451)
      dup2
      mstore
        /* "src/core/WstETH.sol":4233:4240  1 ether */
      0x0de0b6b3a7640000
        /* "src/core/WstETH.sol":4206:4241  stETH.getSharesByPooledEth(1 ether) */
      0x04
      dup3
      add
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":4180:4187  uint256 */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":4206:4211  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":4206:4232  stETH.getSharesByPooledEth */
      0x19208451
      swap2
        /* "src/core/WstETH.sol":4206:4241  stETH.getSharesByPooledEth(1 ether) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":4206:4211  stETH */
      dup7
        /* "src/core/WstETH.sol":4206:4241  stETH.getSharesByPooledEth(1 ether) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_127
      jumpi
      0x00
      dup1
      revert
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2370:2463  function symbol() public view virtual returns (string memory) {... */
    tag_79:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2449:2456  _symbol */
      0x04
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2442:2456  return _symbol */
      dup1
      sload
      0x40
      dup1
      mload
      0x20
      0x1f
      0x02
      not(0x00)
      0x0100
      0x01
      dup9
      and
      iszero
      mul
      add
      swap1
      swap6
      and
      swap5
      swap1
      swap5
      div
      swap4
      dup5
      add
      dup2
      swap1
      div
      dup2
      mul
      dup3
      add
      dup2
      add
      swap1
      swap3
      mstore
      dup3
      dup2
      mstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2417:2430  string memory */
      0x60
      swap4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2442:2456  return _symbol */
      swap1
      swap3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2449:2456  _symbol */
      swap1
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2442:2456  return _symbol */
      dup4
      add
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2449:2456  _symbol */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":2442:2456  return _symbol */
      dup3
      dup1
      iszero
      tag_132
      jumpi
      dup1
      0x1f
      lt
      tag_133
      jumpi
      0x0100
      dup1
      dup4
      sload
      div
      mul
      dup4
      mstore
      swap2
      0x20
      add
      swap2
      jump(tag_132)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6291:6557  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {... */
    tag_87:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6384:6388  bool */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6400:6529  _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")) */
      tag_136
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6409:6421  _msgSender() */
      tag_173
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6409:6419  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6409:6421  _msgSender() */
      jump	// in
    tag_173:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6423:6430  spender */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6528  _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero") */
      tag_146
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6471:6486  subtractedValue */
      dup6
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6528  _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero") */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
      0x25
      dup2
      mstore
      0x20
      add
      data_f8b476f7d28209d77d4a4ac1fe36b9f8259aa1bb6bddfa6e89de7e51615cf8a8
      0x25
      swap2
      codecopy
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6443  _allowances */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6457  _allowances[_msgSender()] */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6444:6456  _msgSender() */
      tag_175
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6444:6454  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6444:6456  _msgSender() */
      jump	// in
    tag_175:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6457  _allowances[_msgSender()] */
      swap1
      dup2
      and
      dup3
      mstore
      0x20
      dup1
      dup4
      add
      swap4
      swap1
      swap4
      mstore
      0x40
      swap2
      dup3
      add
      0x00
      swap1
      dup2
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6466  _allowances[_msgSender()][spender] */
      swap2
      dup14
      and
      dup2
      mstore
      swap3
      mstore
      swap1
      keccak256
      sload
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6528  _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero") */
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6470  _allowances[_msgSender()][spender].sub */
      tag_148
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":6432:6528  _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero") */
      jump	// in
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3727:3899  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {... */
    tag_91:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3813:3817  bool */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3829:3871  _transfer(_msgSender(), recipient, amount) */
      tag_136
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3839:3851  _msgSender() */
      tag_178
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3839:3849  _msgSender */
      tag_138
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3839:3851  _msgSender() */
      jump	// in
    tag_178:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3853:3862  recipient */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3864:3870  amount */
      dup5
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3829:3838  _transfer */
      tag_143
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3829:3871  _transfer(_msgSender(), recipient, amount) */
      jump	// in
        /* "src/core/WstETH.sol":3299:3443  function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {... */
    tag_95:
        /* "src/core/WstETH.sol":3396:3401  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":3396:3436  stETH.getSharesByPooledEth(_stETHAmount) */
      0x40
      dup1
      mload
      shl(0xe0, 0x19208451)
      dup2
      mstore
      0x04
      dup2
      add
      dup5
      swap1
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":3370:3377  uint256 */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":3396:3401  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":3396:3422  stETH.getSharesByPooledEth */
      0x19208451
      swap2
        /* "src/core/WstETH.sol":3396:3436  stETH.getSharesByPooledEth(_stETHAmount) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":3396:3401  stETH */
      dup7
        /* "src/core/WstETH.sol":3396:3436  stETH.getSharesByPooledEth(_stETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_180
      jumpi
      0x00
      dup1
      revert
    tag_180:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_182
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_182:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_183
      jumpi
      0x00
      dup1
      revert
    tag_183:
      pop
      mload
      swap3
        /* "src/core/WstETH.sol":3299:3443  function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256) {... */
      swap2
      pop
      pop
      jump	// out
        /* "src/core/WstETH.sol":3631:3777  function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256) {... */
    tag_99:
        /* "src/core/WstETH.sol":3729:3734  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":3729:3770  stETH.getPooledEthByShares(_wstETHAmount) */
      0x40
      dup1
      mload
      shl(0xe3, 0x0f451f71)
      dup2
      mstore
      0x04
      dup2
      add
      dup5
      swap1
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":3703:3710  uint256 */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":3729:3734  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":3729:3755  stETH.getPooledEthByShares */
      0x7a28fb88
      swap2
        /* "src/core/WstETH.sol":3729:3770  stETH.getPooledEthByShares(_wstETHAmount) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":3729:3734  stETH */
      dup7
        /* "src/core/WstETH.sol":3729:3770  stETH.getPooledEthByShares(_wstETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_180
      jumpi
      0x00
      dup1
      revert
        /* "src/core/WstETH.sol":1089:1108  IStETH public stETH */
    tag_102:
      and(sub(shl(0xa0, 0x01), 0x01), sload(0x07))
      dup2
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1460:2254  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {... */
    tag_106:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1687:1695  deadline */
      dup4
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1668:1683  block.timestamp */
      timestamp
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1668:1695  block.timestamp <= deadline */
      gt
      iszero
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1660:1729  require(block.timestamp <= deadline, "ERC20Permit: expired deadline") */
      tag_190
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1d
      0x24
      dup3
      add
      mstore
      0x45524332305065726d69743a206578706972656420646561646c696e65000000
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
    tag_190:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1931  _nonces[owner] */
      dup8
      and
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1740:1758  bytes32 structHash */
      0x00
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1931  _nonces[owner] */
      swap1
      dup2
      mstore
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1924  _nonces */
      0x06
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1931  _nonces[owner] */
      0x20
      mstore
      0x40
      dup2
      keccak256
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1812:1828  _PERMIT_TYPEHASH */
      immutable("0x3ac7ca38fd21a491cc5fb19169926fdbe6b54822181a3fae6f9aebec8e42713d")
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1846:1851  owner */
      dup10
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1869:1876  spender */
      dup10
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1894:1899  value */
      dup10
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1941  _nonces[owner].current() */
      tag_191
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1939  _nonces[owner].current */
      tag_161
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1917:1941  _nonces[owner].current() */
      jump	// in
    tag_191:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1959:1967  deadline */
      dup10
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1784:1981  abi.encode(... */
      add(0x20, mload(0x40))
      dup1
      dup8
      dup2
      mstore
      0x20
      add
      dup7
      sub(shl(0xa0, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      dup6
      sub(shl(0xa0, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      dup5
      dup2
      mstore
      0x20
      add
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
      swap7
      pop
      pop
      pop
      pop
      pop
      pop
      pop
      mload(0x40)
      0x20
      dup2
      dup4
      sub
      sub
      dup2
      mstore
      swap1
      0x40
      mstore
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1761:1991  keccak256(... */
      dup1
      mload
      swap1
      0x20
      add
      keccak256
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1740:1991  bytes32 structHash = keccak256(... */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2002:2014  bytes32 hash */
      0x00
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2017:2045  _hashTypedDataV4(structHash) */
      tag_192
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2034:2044  structHash */
      dup3
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2017:2033  _hashTypedDataV4 */
      tag_193
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2017:2045  _hashTypedDataV4(structHash) */
      jump	// in
    tag_192:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2002:2045  bytes32 hash = _hashTypedDataV4(structHash) */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2056:2070  address signer */
      0x00
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2073:2101  ECDSA.recover(hash, v, r, s) */
      tag_194
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2087:2091  hash */
      dup3
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2093:2094  v */
      dup8
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2096:2097  r */
      dup8
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2099:2100  s */
      dup8
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2073:2086  ECDSA.recover */
      tag_195
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2073:2101  ECDSA.recover(hash, v, r, s) */
      jump	// in
    tag_194:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2056:2101  address signer = ECDSA.recover(hash, v, r, s) */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2129:2134  owner */
      dup10
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2119:2134  signer == owner */
      and
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2119:2125  signer */
      dup2
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2119:2134  signer == owner */
      and
      eq
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2111:2169  require(signer == owner, "ERC20Permit: invalid signature") */
      tag_196
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1e
      0x24
      dup3
      add
      mstore
      0x45524332305065726d69743a20696e76616c6964207369676e61747572650000
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
    tag_196:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2194  _nonces[owner] */
      dup11
      and
      0x00
      swap1
      dup2
      mstore
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2187  _nonces */
      0x06
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2194  _nonces[owner] */
      0x20
      mstore
      0x40
      swap1
      keccak256
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2206  _nonces[owner].increment() */
      tag_197
      swap1
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2204  _nonces[owner].increment */
      tag_198
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2180:2206  _nonces[owner].increment() */
      jump	// in
    tag_197:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2216:2247  _approve(owner, spender, value) */
      tag_199
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2225:2230  owner */
      dup11
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2232:2239  spender */
      dup11
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2241:2246  value */
      dup11
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2216:2224  _approve */
      tag_139
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":2216:2247  _approve(owner, spender, value) */
      jump	// in
    tag_199:
        /* "src/@openzeppelin/contracts/drafts/ERC20Permit.sol":1460:2254  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {... */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3957:4106  function allowance(address owner, address spender) public view virtual override returns (uint256) {... */
    tag_110:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4072:4090  _allowances[owner] */
      swap2
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4046:4053  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4072:4090  _allowances[owner] */
      swap1
      dup2
      mstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4072:4083  _allowances */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4072:4090  _allowances[owner] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":4072:4099  _allowances[owner][spender] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":3957:4106  function allowance(address owner, address spender) public view virtual override returns (uint256) {... */
      jump	// out
        /* "src/core/WstETH.sol":2546:2889  function unwrap(uint256 _wstETHAmount) external returns (uint256) {... */
    tag_114:
        /* "src/core/WstETH.sol":2603:2610  uint256 */
      0x00
        /* "src/core/WstETH.sol":2646:2647  0 */
      dup1
        /* "src/core/WstETH.sol":2630:2643  _wstETHAmount */
      dup3
        /* "src/core/WstETH.sol":2630:2647  _wstETHAmount > 0 */
      gt
        /* "src/core/WstETH.sol":2622:2690  require(_wstETHAmount > 0, "wstETH: zero amount unwrap not allowed") */
      tag_202
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x26
      dup2
      mstore
      0x20
      add
      dup1
      data_1a42f1a0f2c477904f63a1e61c82541c03292bdb2857feec1c64d8bdae388b93
      0x26
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_202:
        /* "src/core/WstETH.sol":2722:2727  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":2722:2763  stETH.getPooledEthByShares(_wstETHAmount) */
      0x40
      dup1
      mload
      shl(0xe3, 0x0f451f71)
      dup2
      mstore
      0x04
      dup2
      add
      dup6
      swap1
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":2700:2719  uint256 stETHAmount */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":2722:2727  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":2722:2748  stETH.getPooledEthByShares */
      0x7a28fb88
      swap2
        /* "src/core/WstETH.sol":2722:2763  stETH.getPooledEthByShares(_wstETHAmount) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":2722:2727  stETH */
      dup7
        /* "src/core/WstETH.sol":2722:2763  stETH.getPooledEthByShares(_wstETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_203
      jumpi
      0x00
      dup1
      revert
    tag_203:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_205
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_205:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_206
      jumpi
      0x00
      dup1
      revert
    tag_206:
      pop
      mload
      swap1
      pop
        /* "src/core/WstETH.sol":2773:2805  _burn(msg.sender, _wstETHAmount) */
      tag_207
        /* "src/core/WstETH.sol":2779:2789  msg.sender */
      caller
        /* "src/core/WstETH.sol":2791:2804  _wstETHAmount */
      dup5
        /* "src/core/WstETH.sol":2773:2778  _burn */
      tag_208
        /* "src/core/WstETH.sol":2773:2805  _burn(msg.sender, _wstETHAmount) */
      jump	// in
    tag_207:
        /* "src/core/WstETH.sol":2815:2820  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":2815:2854  stETH.transfer(msg.sender, stETHAmount) */
      0x40
      dup1
      mload
      shl(0xe0, 0xa9059cbb)
      dup2
      mstore
        /* "src/core/WstETH.sol":2830:2840  msg.sender */
      caller
        /* "src/core/WstETH.sol":2815:2854  stETH.transfer(msg.sender, stETHAmount) */
      0x04
      dup3
      add
      mstore
      0x24
      dup2
      add
      dup5
      swap1
      mstore
      swap1
      mload
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":2815:2820  stETH */
      swap1
      swap3
      and
      swap2
        /* "src/core/WstETH.sol":2815:2829  stETH.transfer */
      0xa9059cbb
      swap2
        /* "src/core/WstETH.sol":2815:2854  stETH.transfer(msg.sender, stETHAmount) */
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
        /* "src/core/WstETH.sol":2815:2820  stETH */
      0x00
      dup8
        /* "src/core/WstETH.sol":2815:2854  stETH.transfer(msg.sender, stETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_209
      jumpi
      0x00
      dup1
      revert
    tag_209:
      pop
      gas
      call
      iszero
      dup1
      iszero
      tag_211
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_211:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_212
      jumpi
      0x00
      dup1
      revert
    tag_212:
      pop
        /* "src/core/WstETH.sol":2871:2882  stETHAmount */
      swap1
      swap4
        /* "src/core/WstETH.sol":2546:2889  function unwrap(uint256 _wstETHAmount) external returns (uint256) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/core/WstETH.sol":1866:2216  function wrap(uint256 _stETHAmount) external returns (uint256) {... */
    tag_118:
        /* "src/core/WstETH.sol":1920:1927  uint256 */
      0x00
        /* "src/core/WstETH.sol":1962:1963  0 */
      dup1
        /* "src/core/WstETH.sol":1947:1959  _stETHAmount */
      dup3
        /* "src/core/WstETH.sol":1947:1963  _stETHAmount > 0 */
      gt
        /* "src/core/WstETH.sol":1939:1997  require(_stETHAmount > 0, "wstETH: can't wrap zero stETH") */
      tag_214
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1d
      0x24
      dup3
      add
      mstore
      0x7773744554483a2063616e27742077726170207a65726f207374455448000000
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
    tag_214:
        /* "src/core/WstETH.sol":2030:2035  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":2030:2070  stETH.getSharesByPooledEth(_stETHAmount) */
      0x40
      dup1
      mload
      shl(0xe0, 0x19208451)
      dup2
      mstore
      0x04
      dup2
      add
      dup6
      swap1
      mstore
      swap1
      mload
        /* "src/core/WstETH.sol":2007:2027  uint256 wstETHAmount */
      0x00
      swap3
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":2030:2035  stETH */
      and
      swap2
        /* "src/core/WstETH.sol":2030:2056  stETH.getSharesByPooledEth */
      0x19208451
      swap2
        /* "src/core/WstETH.sol":2030:2070  stETH.getSharesByPooledEth(_stETHAmount) */
      0x24
      dup1
      dup4
      add
      swap3
      0x20
      swap3
      swap2
      swap1
      dup3
      swap1
      sub
      add
      dup2
        /* "src/core/WstETH.sol":2030:2035  stETH */
      dup7
        /* "src/core/WstETH.sol":2030:2070  stETH.getSharesByPooledEth(_stETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_215
      jumpi
      0x00
      dup1
      revert
    tag_215:
      pop
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_217
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_217:
      pop
      pop
      pop
      pop
      mload(0x40)
      returndatasize
      0x20
      dup2
      lt
      iszero
      tag_218
      jumpi
      0x00
      dup1
      revert
    tag_218:
      pop
      mload
      swap1
      pop
        /* "src/core/WstETH.sol":2080:2111  _mint(msg.sender, wstETHAmount) */
      tag_219
        /* "src/core/WstETH.sol":2086:2096  msg.sender */
      caller
        /* "src/core/WstETH.sol":2030:2070  stETH.getSharesByPooledEth(_stETHAmount) */
      dup3
        /* "src/core/WstETH.sol":2080:2085  _mint */
      tag_34
        /* "src/core/WstETH.sol":2080:2111  _mint(msg.sender, wstETHAmount) */
      jump	// in
    tag_219:
        /* "src/core/WstETH.sol":2121:2126  stETH */
      sload(0x07)
        /* "src/core/WstETH.sol":2121:2180  stETH.transferFrom(msg.sender, address(this), _stETHAmount) */
      0x40
      dup1
      mload
      shl(0xe0, 0x23b872dd)
      dup2
      mstore
        /* "src/core/WstETH.sol":2140:2150  msg.sender */
      caller
        /* "src/core/WstETH.sol":2121:2180  stETH.transferFrom(msg.sender, address(this), _stETHAmount) */
      0x04
      dup3
      add
      mstore
        /* "src/core/WstETH.sol":2160:2164  this */
      address
        /* "src/core/WstETH.sol":2121:2180  stETH.transferFrom(msg.sender, address(this), _stETHAmount) */
      0x24
      dup3
      add
      mstore
      0x44
      dup2
      add
      dup7
      swap1
      mstore
      swap1
      mload
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/core/WstETH.sol":2121:2126  stETH */
      swap1
      swap3
      and
      swap2
        /* "src/core/WstETH.sol":2121:2139  stETH.transferFrom */
      0x23b872dd
      swap2
        /* "src/core/WstETH.sol":2121:2180  stETH.transferFrom(msg.sender, address(this), _stETHAmount) */
      0x64
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
        /* "src/core/WstETH.sol":2121:2126  stETH */
      0x00
      dup8
        /* "src/core/WstETH.sol":2121:2180  stETH.transferFrom(msg.sender, address(this), _stETHAmount) */
      dup1
      extcodesize
      iszero
      dup1
      iszero
      tag_209
      jumpi
      0x00
      dup1
      revert
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":10701:10793  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { } */
    tag_122:
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2690:2865  function add(uint256 a, uint256 b) internal pure returns (uint256) {... */
    tag_124:
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2748:2755  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2779:2784  a + b */
      dup3
      dup3
      add
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2802:2808  c >= a */
      dup4
      dup2
      lt
      iszero
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2794:2840  require(c >= a, "SafeMath: addition overflow") */
      tag_226
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1b
      0x24
      dup3
      add
      mstore
      0x536166654d6174683a206164646974696f6e206f766572666c6f770000000000
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
    tag_226:
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2857:2858  c */
      swap4
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":2690:2865  function add(uint256 a, uint256 b) internal pure returns (uint256) {... */
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/utils/Context.sol":598:702  function _msgSender() internal view virtual returns (address payable) {... */
    tag_138:
        /* "src/@openzeppelin/contracts/utils/Context.sol":685:695  msg.sender */
      caller
        /* "src/@openzeppelin/contracts/utils/Context.sol":598:702  function _msgSender() internal view virtual returns (address payable) {... */
      swap1
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9355:9695  function _approve(address owner, address spender, uint256 amount) internal virtual {... */
    tag_139:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9456:9475  owner != address(0) */
      dup4
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9448:9516  require(owner != address(0), "ERC20: approve from the zero address") */
      tag_229
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x24
      dup2
      mstore
      0x20
      add
      dup1
      data_c953f4879035ed60e766b34720f656aab5c697b141d924c283124ecedb91c208
      0x24
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_229:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9534:9555  spender != address(0) */
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9526:9594  require(spender != address(0), "ERC20: approve to the zero address") */
      tag_230
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x22
      dup2
      mstore
      0x20
      add
      dup1
      data_24883cc5fe64ace9d0df1893501ecb93c77180f0ff69cca79affb3c316dc8029
      0x22
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_230:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9605:9623  _allowances[owner] */
      dup1
      dup5
      and
      0x00
      dup2
      dup2
      mstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9605:9616  _allowances */
      0x01
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9605:9623  _allowances[owner] */
      0x20
      swap1
      dup2
      mstore
      0x40
      dup1
      dup4
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9605:9632  _allowances[owner][spender] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9605:9641  _allowances[owner][spender] = amount */
      dup6
      swap1
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9656:9688  Approval(owner, spender, amount) */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":9355:9695  function _approve(address owner, address spender, uint256 amount) internal virtual {... */
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7031:7561  function _transfer(address sender, address recipient, uint256 amount) internal virtual {... */
    tag_143:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7136:7156  sender != address(0) */
      dup4
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7128:7198  require(sender != address(0), "ERC20: transfer from the zero address") */
      tag_232
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x25
      dup2
      mstore
      0x20
      add
      dup1
      data_baecc556b46f4ed0f2b4cb599d60785ac8563dd2dc0a5bf12edea1c39e5e1fea
      0x25
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_232:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7216:7239  recipient != address(0) */
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7208:7279  require(recipient != address(0), "ERC20: transfer to the zero address") */
      tag_233
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x23
      dup2
      mstore
      0x20
      add
      dup1
      data_0557e210f7a69a685100a7e4e3d0a7024c546085cee28910fd17d0b081d9516f
      0x23
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_233:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7290:7337  _beforeTokenTransfer(sender, recipient, amount) */
      tag_234
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7311:7317  sender */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7319:7328  recipient */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7330:7336  amount */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7290:7310  _beforeTokenTransfer */
      tag_122
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7290:7337  _beforeTokenTransfer(sender, recipient, amount) */
      jump	// in
    tag_234:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7439  _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance") */
      tag_235
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7390:7396  amount */
      dup2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7439  _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance") */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
      0x26
      dup2
      mstore
      0x20
      add
      data_4107e8a8b9e94bf8ff83080ddec1c0bffe897ebc2241b89d44f66b3d274088b6
      0x26
      swap2
      codecopy
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7385  _balances[sender] */
      dup7
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7377  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7385  _balances[sender] */
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
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7439  _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance") */
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7389  _balances[sender].sub */
      tag_148
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7368:7439  _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance") */
      jump	// in
    tag_235:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7348:7365  _balances[sender] */
      dup1
      dup6
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7348:7357  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7348:7365  _balances[sender] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7348:7439  _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance") */
      swap4
      swap1
      swap4
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7472:7492  _balances[recipient] */
      swap1
      dup5
      and
      dup2
      mstore
      keccak256
      sload
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7472:7504  _balances[recipient].add(amount) */
      tag_236
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7497:7503  amount */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7472:7496  _balances[recipient].add */
      tag_124
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7472:7504  _balances[recipient].add(amount) */
      jump	// in
    tag_236:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7449:7469  _balances[recipient] */
      dup1
      dup5
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7449:7458  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7449:7469  _balances[recipient] */
      dup2
      dup2
      mstore
      0x20
      dup2
      dup2
      mstore
      0x40
      swap2
      dup3
      swap1
      keccak256
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7449:7504  _balances[recipient] = _balances[recipient].add(amount) */
      swap5
      swap1
      swap5
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7519:7554  Transfer(sender, recipient, amount) */
      dup1
      mload
      dup6
      dup2
      mstore
      swap1
      mload
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7449:7469  _balances[recipient] */
      swap2
      swap4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7519:7554  Transfer(sender, recipient, amount) */
      swap3
      dup8
      and
      swap3
      0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
      swap3
      swap2
      dup3
      swap1
      sub
      add
      swap1
      log3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":7031:7561  function _transfer(address sender, address recipient, uint256 amount) internal virtual {... */
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5432:5595  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {... */
    tag_148:
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5518:5525  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5553:5565  errorMessage */
      dup2
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5545:5551  b <= a */
      dup5
      dup5
      gt
      iszero
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5537:5566  require(b <= a, errorMessage) */
      tag_238
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x00
    tag_239:
      dup4
      dup2
      lt
      iszero
      tag_241
      jumpi
      dup2
      dup2
      add
      mload
      dup4
      dup3
      add
      mstore
      0x20
      add
      jump(tag_239)
    tag_241:
      pop
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
      tag_242
      jumpi
      dup1
      dup3
      sub
      dup1
      mload
      0x01
      dup4
      0x20
      sub
      0x0100
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
    tag_242:
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
    tag_238:
      pop
      pop
      pop
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5583:5588  a - b */
      swap1
      sub
      swap1
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":5432:5595  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {... */
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":2961:3244  function _domainSeparatorV4() internal view virtual returns (bytes32) {... */
    tag_152:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3022:3029  bytes32 */
      0x00
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3062:3078  _CACHED_CHAIN_ID */
      immutable("0x9af6e0c6f9b8f572459f1957d56f01ba73ab5558fbad6cdb8b94d4ee7705c26c")
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3045:3058  _getChainId() */
      tag_244
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3045:3056  _getChainId */
      tag_245
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3045:3058  _getChainId() */
      jump	// in
    tag_244:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3045:3078  _getChainId() == _CACHED_CHAIN_ID */
      eq
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3041:3238  if (_getChainId() == _CACHED_CHAIN_ID) {... */
      iszero
      tag_246
      jumpi
      pop
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3101:3125  _CACHED_DOMAIN_SEPARATOR */
      immutable("0x583f4f71b32721321fd0f20e674c3938142ce9f243e802c16cfc4def7d2dc523")
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3094:3125  return _CACHED_DOMAIN_SEPARATOR */
      jump(tag_126)
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3041:3238  if (_getChainId() == _CACHED_CHAIN_ID) {... */
    tag_246:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3163:3227  _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION) */
      tag_248
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3185:3195  _TYPE_HASH */
      immutable("0x24036ccf201a67256250eabe66d3f9fd72f9c4d022f225a8ee964be060dcb993")
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3197:3209  _HASHED_NAME */
      immutable("0xac09810740600c31fa69f9db79ed6fc3e3281f758a950fe1fb254a3a3ae571b6")
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3211:3226  _HASHED_VERSION */
      immutable("0x7dbef654fd5c6145f82b72cd5dbbfc6d48fd276b8a7a4371a61d55985b9d6d8b")
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3163:3184  _buildDomainSeparator */
      tag_249
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3163:3227  _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION) */
      jump	// in
    tag_248:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3156:3227  return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION) */
      swap1
      pop
      jump(tag_126)
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1106:1218  function current(Counter storage counter) internal view returns (uint256) {... */
    tag_161:
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1197:1211  counter._value */
      sload
      swap1
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1106:1218  function current(Counter storage counter) internal view returns (uint256) {... */
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4202:4385  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {... */
    tag_193:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4279:4286  bytes32 */
      0x00
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4344:4364  _domainSeparatorV4() */
      tag_252
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4344:4362  _domainSeparatorV4 */
      tag_152
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4344:4364  _domainSeparatorV4() */
      jump	// in
    tag_252:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4366:4376  structHash */
      dup3
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4315:4377  abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash) */
      add(0x20, mload(0x40))
      dup1
      dup1
      shl(0xf0, 0x1901)
      dup2
      mstore
      pop
      0x02
      add
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
      mload(0x40)
      0x20
      dup2
      dup4
      sub
      sub
      dup2
      mstore
      swap1
      0x40
      mstore
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4305:4378  keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash)) */
      dup1
      mload
      swap1
      0x20
      add
      keccak256
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4298:4378  return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash)) */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4202:4385  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {... */
      swap2
      swap1
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":1960:3374  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {... */
    tag_195:
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":2045:2052  address */
      0x00
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":2960:3026  0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 */
      0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":2946:3026  uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 */
      dup3
      gt
      iszero
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":2938:3065  require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value") */
      tag_254
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x22
      dup2
      mstore
      0x20
      add
      dup1
      data_520d1f787dbcafbbfc007fd2c4ecf3d2711ec587f3ee9a1215c0b646c3e530bd
      0x22
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_254:
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3083:3084  v */
      dup4
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3083:3090  v == 27 */
      0xff
      and
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3088:3090  27 */
      0x1b
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3083:3090  v == 27 */
      eq
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3083:3101  v == 27 || v == 28 */
      dup1
      tag_255
      jumpi
      pop
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3094:3095  v */
      dup4
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3094:3101  v == 28 */
      0xff
      and
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3099:3101  28 */
      0x1c
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3094:3101  v == 28 */
      eq
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3083:3101  v == 27 || v == 28 */
    tag_255:
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3075:3140  require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value") */
      tag_256
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x22
      dup2
      mstore
      0x20
      add
      dup1
      data_8522ee1b53216f595394db8e80a64d9e7d9bd512c0811c18debe9f40858597e4
      0x22
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_256:
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3235:3249  address signer */
      0x00
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3252:3276  ecrecover(hash, v, r, s) */
      0x01
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3262:3266  hash */
      dup7
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3268:3269  v */
      dup7
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3271:3272  r */
      dup7
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3274:3275  s */
      dup7
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3252:3276  ecrecover(hash, v, r, s) */
      mload(0x40)
      0x00
      dup2
      mstore
      0x20
      add
      0x40
      mstore
      mload(0x40)
      dup1
      dup6
      dup2
      mstore
      0x20
      add
      dup5
      0xff
      and
      dup2
      mstore
      0x20
      add
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
      swap5
      pop
      pop
      pop
      pop
      pop
      0x20
      mload(0x40)
      0x20
      dup2
      sub
      swap1
      dup1
      dup5
      sub
      swap1
      dup6
      gas
      staticcall
      iszero
      dup1
      iszero
      tag_258
      jumpi
      returndatasize
      0x00
      dup1
      returndatacopy
      revert(0x00, returndatasize)
    tag_258:
      pop
      pop
      mload(add(not(0x1f), mload(0x40)))
      swap2
      pop
      pop
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3294:3314  signer != address(0) */
      dup2
      and
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3286:3343  require(signer != address(0), "ECDSA: invalid signature") */
      tag_259
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
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
    tag_259:
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":3361:3367  signer */
      swap6
        /* "src/@openzeppelin/contracts/cryptography/ECDSA.sol":1960:3374  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {... */
      swap5
      pop
      pop
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1224:1402  function increment(Counter storage counter) internal {... */
    tag_198:
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1376:1395  counter._value += 1 */
      dup1
      sload
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1394:1395  1 */
      0x01
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1376:1395  counter._value += 1 */
      add
      swap1
      sstore
        /* "src/@openzeppelin/contracts/utils/Counters.sol":1224:1402  function increment(Counter storage counter) internal {... */
      jump	// out
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8522:8932  function _burn(address account, uint256 amount) internal virtual {... */
    tag_208:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8605:8626  account != address(0) */
      dup3
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8597:8664  require(account != address(0), "ERC20: burn from the zero address") */
      tag_262
      jumpi
      mload(0x40)
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x04
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
      0x21
      dup2
      mstore
      0x20
      add
      dup1
      data_b16788493b576042bb52c50ed56189e0b250db113c7bfb1c3897d25cf9632d7f
      0x21
      swap2
      codecopy
      0x40
      add
      swap2
      pop
      pop
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
    tag_262:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8675:8724  _beforeTokenTransfer(account, address(0), amount) */
      tag_263
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8696:8703  account */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8713:8714  0 */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8717:8723  amount */
      dup4
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8675:8695  _beforeTokenTransfer */
      tag_122
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8675:8724  _beforeTokenTransfer(account, address(0), amount) */
      jump	// in
    tag_263:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8824  _balances[account].sub(amount, "ERC20: burn amount exceeds balance") */
      tag_264
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8779:8785  amount */
      dup2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8824  _balances[account].sub(amount, "ERC20: burn amount exceeds balance") */
      mload(0x40)
      dup1
      0x60
      add
      0x40
      mstore
      dup1
      0x22
      dup2
      mstore
      0x20
      add
      data_149b126e7125232b4200af45303d04fba8b74653b1a295a6a561a528c33fefdd
      0x22
      swap2
      codecopy
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8774  _balances[account] */
      dup6
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8765  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8774  _balances[account] */
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
      swap2
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8824  _balances[account].sub(amount, "ERC20: burn amount exceeds balance") */
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8778  _balances[account].sub */
      tag_148
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8756:8824  _balances[account].sub(amount, "ERC20: burn amount exceeds balance") */
      jump	// in
    tag_264:
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8735:8753  _balances[account] */
      dup4
      and
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8735:8744  _balances */
      0x00
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8735:8753  _balances[account] */
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
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8735:8824  _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance") */
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8849:8861  _totalSupply */
      sload(0x02)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8849:8873  _totalSupply.sub(amount) */
      tag_265
      swap1
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8866:8872  amount */
      dup3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8849:8865  _totalSupply.sub */
      tag_266
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8849:8873  _totalSupply.sub(amount) */
      jump	// in
    tag_265:
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8834:8846  _totalSupply */
      0x02
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8834:8873  _totalSupply = _totalSupply.sub(amount) */
      sstore
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8888:8925  Transfer(account, address(0), amount) */
      0x40
      dup1
      mload
      dup3
      dup2
      mstore
      swap1
      mload
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8914:8915  0 */
      0x00
      swap2
      sub(shl(0xa0, 0x01), 0x01)
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8888:8925  Transfer(account, address(0), amount) */
      dup6
      and
      swap2
      0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
      swap2
      dup2
      swap1
      sub
      0x20
      add
      swap1
      log3
        /* "src/@openzeppelin/contracts/token/ERC20/ERC20.sol":8522:8932  function _burn(address account, uint256 amount) internal virtual {... */
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4391:4711  function _getChainId() private view returns (uint256 chainId) {... */
    tag_245:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4686:4695  chainid() */
      chainid
      swap1
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":4661:4705  {... */
      jump	// out
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3250:3577  function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {... */
    tag_249:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3352:3359  bytes32 */
      0x00
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3429:3437  typeHash */
      dup4
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3455:3459  name */
      dup4
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3477:3484  version */
      dup4
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3515  _getChainId() */
      tag_269
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3513  _getChainId */
      tag_245
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3502:3515  _getChainId() */
      jump	// in
    tag_269:
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3541:3545  this */
      address
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3401:3560  abi.encode(... */
      add(0x20, mload(0x40))
      dup1
      dup7
      dup2
      mstore
      0x20
      add
      dup6
      dup2
      mstore
      0x20
      add
      dup5
      dup2
      mstore
      0x20
      add
      dup4
      dup2
      mstore
      0x20
      add
      dup3
      sub(shl(0xa0, 0x01), 0x01)
      and
      dup2
      mstore
      0x20
      add
      swap6
      pop
      pop
      pop
      pop
      pop
      pop
      mload(0x40)
      0x20
      dup2
      dup4
      sub
      sub
      dup2
      mstore
      swap1
      0x40
      mstore
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3378:3570  keccak256(... */
      dup1
      mload
      swap1
      0x20
      add
      keccak256
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3371:3570  return keccak256(... */
      swap1
      pop
        /* "src/@openzeppelin/contracts/drafts/EIP712.sol":3250:3577  function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {... */
      swap4
      swap3
      pop
      pop
      pop
      jump	// out
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3136:3291  function sub(uint256 a, uint256 b) internal pure returns (uint256) {... */
    tag_266:
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3194:3201  uint256 */
      0x00
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3226:3227  a */
      dup3
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3221:3222  b */
      dup3
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3221:3227  b <= a */
      gt
      iszero
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3213:3262  require(b <= a, "SafeMath: subtraction overflow") */
      tag_271
      jumpi
      0x40
      dup1
      mload
      shl(0xe5, 0x461bcd)
      dup2
      mstore
      0x20
      0x04
      dup3
      add
      mstore
      0x1e
      0x24
      dup3
      add
      mstore
      0x536166654d6174683a207375627472616374696f6e206f766572666c6f770000
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
    tag_271:
      pop
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3279:3284  a - b */
      swap1
      sub
      swap1
        /* "src/@openzeppelin/contracts/math/SafeMath.sol":3136:3291  function sub(uint256 a, uint256 b) internal pure returns (uint256) {... */
      jump	// out
    stop
    data_0557e210f7a69a685100a7e4e3d0a7024c546085cee28910fd17d0b081d9516f 45524332303a207472616e7366657220746f20746865207a65726f2061646472657373
    data_149b126e7125232b4200af45303d04fba8b74653b1a295a6a561a528c33fefdd 45524332303a206275726e20616d6f756e7420657863656564732062616c616e6365
    data_1a42f1a0f2c477904f63a1e61c82541c03292bdb2857feec1c64d8bdae388b93 7773744554483a207a65726f20616d6f756e7420756e77726170206e6f7420616c6c6f776564
    data_24883cc5fe64ace9d0df1893501ecb93c77180f0ff69cca79affb3c316dc8029 45524332303a20617070726f766520746f20746865207a65726f2061646472657373
    data_4107e8a8b9e94bf8ff83080ddec1c0bffe897ebc2241b89d44f66b3d274088b6 45524332303a207472616e7366657220616d6f756e7420657863656564732062616c616e6365
    data_520d1f787dbcafbbfc007fd2c4ecf3d2711ec587f3ee9a1215c0b646c3e530bd 45434453413a20696e76616c6964207369676e6174757265202773272076616c7565
    data_8522ee1b53216f595394db8e80a64d9e7d9bd512c0811c18debe9f40858597e4 45434453413a20696e76616c6964207369676e6174757265202776272076616c7565
    data_974d1b4421da69cc60b481194f0dad36a5bb4e23da810da7a7fb30cdba178330 45524332303a207472616e7366657220616d6f756e74206578636565647320616c6c6f77616e6365
    data_b16788493b576042bb52c50ed56189e0b250db113c7bfb1c3897d25cf9632d7f 45524332303a206275726e2066726f6d20746865207a65726f2061646472657373
    data_baecc556b46f4ed0f2b4cb599d60785ac8563dd2dc0a5bf12edea1c39e5e1fea 45524332303a207472616e736665722066726f6d20746865207a65726f2061646472657373
    data_c953f4879035ed60e766b34720f656aab5c697b141d924c283124ecedb91c208 45524332303a20617070726f76652066726f6d20746865207a65726f2061646472657373
    data_f8b476f7d28209d77d4a4ac1fe36b9f8259aa1bb6bddfa6e89de7e51615cf8a8 45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77207a65726f

    auxdata: 0xa264697066735822122092f6104e50d5073acd9ce803c3ae7524c9e704dc1eaf3c012ecf0f885e359e1564736f6c634300060c0033
}

