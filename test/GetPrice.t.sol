// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import {CurveSpotPrice} from "src/GetSpotPriceAndPool.sol";
import "src/interfaces/IMetaPoolRegistry.sol";

contract GetPrice is Test {
    CurveSpotPrice public spotPriceContract;

    address immutable metaPoolRegistryContractAddress = 0xF98B45FA17DE75FB1aD0e7aFD971b0ca00e379fC;
    address immutable DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address immutable USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public sender = address(1337);

    function setUp() public {
      
        spotPriceContract = new CurveSpotPrice(metaPoolRegistryContractAddress);
    }

    function testGetSpotPrice() public {

        vm.startPrank(sender);

        uint256 amount = 1 ether;

        address[] memory tokens = new address[](2);
        tokens[0] = DAI_ADDRESS;
        tokens[1] = USDC_ADDRESS;

        uint256 amountsOut = spotPriceContract.getSpotPrice(tokens, amount);
        console.log("Pool Found %s", spotPriceContract.poolAddress());
        console.log(amountsOut);

        assertGt(amountsOut, 0, "Spot price should be greater than 0");
    }
}