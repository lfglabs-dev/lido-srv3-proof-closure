    constructor(
        address _depositContract,
        address _lido,
        address _lidoLocator,
        uint256 _maxEBType1,
        uint256 _maxEBType2
    ) {
        SRUtils._requireNotZero(_depositContract);
        SRUtils._requireNotZero(_lido);
        SRUtils._requireNotZero(_lidoLocator);

        DEPOSIT_CONTRACT = IDepositContract(_depositContract);
        LIDO = ILido(_lido);
        LIDO_LOCATOR = ILidoLocator(_lidoLocator);

        SRUtils._requireNotZero(_maxEBType1);
        SRUtils._requireNotZero(_maxEBType2);
        MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = _maxEBType1;
        MAX_EFFECTIVE_BALANCE_WC_TYPE_02 = _maxEBType2;
