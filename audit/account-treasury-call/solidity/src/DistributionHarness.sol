pragma solidity 0.8.9;
interface ILidoShares {
    function transferShares(address,uint256) external returns (uint256);
    function mintSetup(address,uint256) external;
    function sharesOf(address) external view returns (uint256);
}
interface ILocatorTreasury { function treasury() external view returns (address); }
contract DistributionHarness {
    ILidoShares public immutable LIDO;
    ILocatorTreasury public immutable LIDO_LOCATOR;
    struct FeeDistribution {address[] moduleFeeRecipients; uint256[] moduleSharesToMint; uint256 treasurySharesToMint;}
    constructor(ILidoShares lido, ILocatorTreasury locator) {LIDO=lido;LIDO_LOCATOR=locator;}
    function distribute(address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {
        _distributeFee(FeeDistribution(recipients,amounts,treasury));
    }
    function mintAndDistribute(uint256 mint,address[] memory recipients,uint256[] memory amounts,uint256 treasury) external {
        if(mint>0) {LIDO.mintSetup(address(this),mint); _distributeFee(FeeDistribution(recipients,amounts,treasury));}
    }
    function _distributeFee(FeeDistribution memory _feeDistribution) internal {
        address[] memory recipients = _feeDistribution.moduleFeeRecipients;
        uint256[] memory sharesToMint = _feeDistribution.moduleSharesToMint;
        uint256 length = recipients.length;

        for (uint256 i; i < length; ++i) {
            uint256 moduleShares = sharesToMint[i];
            if (moduleShares > 0) {
                LIDO.transferShares(recipients[i], moduleShares);
            }
        }

        uint256 treasuryShares = _feeDistribution.treasurySharesToMint;
        if (treasuryShares > 0) { // zero is an edge case when all fees goes to modules
            LIDO.transferShares(LIDO_LOCATOR.treasury(), treasuryShares);
        }
    }

}
