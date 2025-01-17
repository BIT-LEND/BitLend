// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "./ComptrollerStorage.sol";

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) prices;
    mapping(address => bool) public whitelisted; 
    address public admin; 
    event WhitelistUpdated(address asset, bool isWhitelisted); 
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    constructor() {
        admin = msg.sender;
    }
    function _getUnderlyingAddress(CToken cToken) private view returns (address) {
        address asset;
        if (compareStrings(cToken.symbol(), "bBB")) {
            asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            asset = address(CErc20(address(cToken)).underlying());
        }
        return asset;
    }

    function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
        return prices[_getUnderlyingAddress(cToken)];
    }

    function setUnderlyingPrice(CToken[] memory cTokens, uint[] memory underlyingPriceMantissas) public {
        require(whitelisted[msg.sender], "Asset not whitelisted");
        uint numTokens = cTokens.length;
        require(numTokens == underlyingPriceMantissas.length, "Comptroller:: invalid input");
        for (uint i = 0; i < numTokens; ++i) {
           
            address asset = _getUnderlyingAddress(cTokens[i]);
            emit PricePosted(asset, prices[asset], underlyingPriceMantissas[i], underlyingPriceMantissas[i]);
            prices[asset] = underlyingPriceMantissas[i];
        }
      
    }

    function setDirectPrice(address asset, uint price) public {
        require(whitelisted[msg.sender], "Asset not whitelisted");
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function addToWhitelist(address asset) public {
        require(msg.sender == admin, "only admin can set");
        whitelisted[asset] = true;
        emit WhitelistUpdated(asset, true); 
    }

    function removeFromWhitelist(address asset) public {
        require(msg.sender == admin, "only admin can set");
        whitelisted[asset] = false; 
        emit WhitelistUpdated(asset, false); 
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
