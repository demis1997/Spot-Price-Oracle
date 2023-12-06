// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import {AssesmentOracle} from "src/GetSpotPrice.sol"; // Adjust the path as needed
import {ICurvePool} from "src/interfaces/ICurvePool.sol"; // Adjust the path as needed

contract GetOraclePrice is Test {
    AssesmentOracle public oracle;

    address immutable DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address immutable USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address immutable POOL_ADDRESS = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    function setUp() public {
        oracle = new AssesmentOracle();
    }

    function testGetSpotPrice() public {
        uint256 spotPrice = oracle.getSpotPrice(
            DAI_ADDRESS,
            POOL_ADDRESS,
            USDT_ADDRESS
        );
        console.log("Spot Price: ", spotPrice);

        assertGt(spotPrice, 0, "Spot price should be greater than 0");
    }

    function testGetSpotPriceInRange() public {
        uint256 spotPrice = oracle.getSpotPrice(
            DAI_ADDRESS,
            POOL_ADDRESS,
            USDT_ADDRESS
        );
        console.log("Spot Price: ", spotPrice);
        //I checked the price on my fork directly from the pool to compare with what i am getting here through the console logs and expected bounds as adittional check.
        uint256 expectedLowerBound = 999000;
        uint256 expectedUpperBound = 999900;

        assertTrue(
            spotPrice >= expectedLowerBound && spotPrice <= expectedUpperBound,
            "Spot price should be within the expected range"
        );
    }
}
