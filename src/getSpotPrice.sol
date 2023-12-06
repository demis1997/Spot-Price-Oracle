// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;


// This contract assumes that the pool passed to getSpotPrice is a valid Curve pool and that both token and quoteToken are part of this pool. 
// It also assumes a fixed amount (1 ether, which should be adjusted for different token decimals) for the price calculation. 

import "./interfaces/ICurvePool.sol";
import "./interfaces/ISpotPriceOracle.sol";

contract AssesmentOracle is ISpotPriceOracle {
    function getSpotPrice(
        address token,
        address pool,
        address quoteToken
    ) external view override returns (uint256 price) {
        ICurvePool curvePool = ICurvePool(pool);
        int128 i = findTokenIndex(curvePool, token);
        int128 j = findTokenIndex(curvePool, quoteToken);

        require(i != j, "Same token provided for both inputs");

        // Assuming the amount for price calculation is 1 unit of the input token
        uint256 amount = 1 ether; 
        return curvePool.get_dy(i, j, amount);
    }

    function findTokenIndex(ICurvePool pool, address token) internal view returns (int128) {
        uint128 coinIdx = 0;
        while (coinIdx < 8) { 
            try pool.coins(coinIdx) returns (address coin) {
                if (coin == token) {
                    return int128(coinIdx);
                }
            } catch {
                break;
            }
            coinIdx++;
        }
        revert("Token not found in pool");
    }
}
