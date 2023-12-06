// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IMetaPoolRegistry.sol";
import "./interfaces/ICurvePool.sol";


contract CurveSpotPrice {
    address public poolAddress;

    IMetaPoolRegistry private metaPoolRegistryContract;
    ICurvePool private poolContract;

    constructor(address _addr) payable {
        metaPoolRegistryContract = IMetaPoolRegistry(_addr);
    }

    function _curveMetaPool(address pool, address tokenIn, address tokenOut, uint256 amount)
        internal
        returns (uint256)
    {
        int128 i = 0;
        int128 j = 0;
        uint128 coinIdx = 0;
        poolContract = ICurvePool(pool);

        while (i == i) {
            address coin = poolContract.coins(coinIdx);

            if (coin == tokenIn) {
                i = int128(coinIdx);
            } else if (coin == tokenOut) {
                j = int128(coinIdx);
            }

            if (i != j) {
                break;
            }
            coinIdx++;
        }
        uint256 amountsOut = poolContract.get_dy(i, j, amount);

        return amountsOut;
    }

    function getSpotPrice(address[] calldata tokens, uint256 realAmountIn) external returns (uint256) {
        poolAddress = metaPoolRegistryContract.find_pool_for_coins(tokens[0], tokens[1]);

        require(poolAddress != address(0), "No pools found");

        uint256 amountsOut = _curveMetaPool(poolAddress, tokens[0], tokens[1], realAmountIn);

        return amountsOut;
    }
}
