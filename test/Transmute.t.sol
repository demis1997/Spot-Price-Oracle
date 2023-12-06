// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "lib/forge-std/src/Test.sol";
import {Transmuter} from "../src/Transmuter.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import "lib/forge-std/src/console.sol";

contract TransmuterTests is Test {
    FakeSwapper internal swapper;
    ERC20Mock internal destinationToken;
    Transmuter internal transmuter;

    function setUp() public virtual {
        swapper = new FakeSwapper();
        destinationToken = new ERC20Mock();
        transmuter = new Transmuter(
            address(destinationToken),
            address(swapper)
        );
    }

    function test_Setup() public {
        assertTrue(address(swapper) != address(0));
        assertTrue(address(destinationToken) != address(0));
        assertTrue(address(transmuter) != address(0));
    }
}

contract DepositFundsTests is TransmuterTests {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_CanDepositEth() public {
        address user1 = address(1);
        uint256 amount1 = 10e18;

        address[] memory tokens = new address[](1);
        tokens[0] = transmuter.ETH();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount1;

        vm.deal(user1, 10e18);

        vm.startPrank(user1);
        transmuter.depositFunds{value: 10e18}(tokens, amounts);
        vm.stopPrank();

        assertEq(transmuter.userBalances(user1, transmuter.ETH()), amount1);
    }

    function test_OvercreditEthBalance() public {
        address user1 = address(1);
        uint256 depositAmount = 10 ether; // Each deposit amount
        uint256 totalMsgValue = 10 ether; // Total ETH sent for only one deposit

        // Simulate user1 has enough ETH
        vm.deal(user1, totalMsgValue);

        // User attempts to deposit 10 ETH three times, but sends only 10 ETH in total
        address[] memory tokens = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        tokens[0] = transmuter.ETH(); // Real ETH address
        tokens[1] = transmuter.ETH(); // Assuming ETH is represented multiple times
        tokens[2] = transmuter.ETH(); // Assuming ETH is represented multiple times
        amounts[0] = depositAmount;
        amounts[1] = depositAmount;
        amounts[2] = depositAmount;

        // Execute deposit with only 10 ETH sent (not 30 ETH)
        vm.startPrank(user1);
        transmuter.depositFunds{value: totalMsgValue}(tokens, amounts);
        vm.stopPrank();

        // Check user's balance for ETH in the contract
        uint256 userBalanceEth = transmuter.userBalances(
            user1,
            transmuter.ETH()
        );

        // Assertion: User balance should match the actual ETH sent, not the sum of amounts
        assertEq(
            userBalanceEth,
            totalMsgValue,
            "User's ETH balance should match the actual ETH sent"
        );
    }

    function test_CanDepositSingleToken() public {
        address user1 = address(1);
        uint256 amount1 = 10e18;
        ERC20Mock token = new ERC20Mock();

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount1;

        token.mint(user1, amount1);

        vm.startPrank(user1);
        token.approve(address(transmuter), amount1);
        transmuter.depositFunds(tokens, amounts);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(transmuter.userBalances(user1, address(token)), amount1);
    }

    function test_CanDepositMultipleTokens() public {
        address user1 = address(1);
        uint256 amount1 = 10e18;
        uint256 amount2 = 9e18;
        ERC20Mock token1 = new ERC20Mock();
        ERC20Mock token2 = new ERC20Mock();

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        token1.mint(user1, amount1);
        token2.mint(user1, amount2);

        vm.startPrank(user1);
        token1.approve(address(transmuter), amount1);
        token2.approve(address(transmuter), amount2);
        transmuter.depositFunds(tokens, amounts);
        vm.stopPrank();

        assertEq(token1.balanceOf(user1), 0);
        assertEq(token2.balanceOf(user1), 0);
        assertEq(transmuter.userBalances(user1, address(token1)), amount1);
        assertEq(transmuter.userBalances(user1, address(token2)), amount2);
    }
}

contract TransmuteTests is TransmuterTests {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_CanTransmuteEth() external {
        address user1 = address(1);
        uint256 amount1 = 10e18;

        address[] memory tokens = new address[](1);
        tokens[0] = transmuter.ETH();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount1;

        vm.deal(user1, 10e18);

        vm.startPrank(user1);
        transmuter.depositFunds{value: amount1}(tokens, amounts);
        vm.stopPrank();

        bytes memory swapData = abi.encodeWithSelector(
            FakeSwapper.swap.selector,
            transmuter.ETH(),
            10e18,
            address(destinationToken),
            8e18
        );
        address[] memory users = new address[](1);
        users[0] = user1;

        assertEq(destinationToken.balanceOf(user1), 0);

        transmuter.transmute{value: amount1}(
            users,
            transmuter.ETH(),
            10e18,
            swapData
        );

        assertEq(destinationToken.balanceOf(user1), 8e18);
        assertEq(transmuter.userBalances(user1, transmuter.ETH()), 0);
    }

    function test_TransmuteWithExcessiveAmount() external {
        address user1 = address(1);
        address user2 = address(2);
        uint256 user1Deposit = 5e18;
        uint256 user2Deposit = 5e18;
        uint256 excessiveSwapAmount = 15e18;
        ERC20Mock token = new ERC20Mock();

        token.mint(user1, user1Deposit);
        token.mint(user2, user2Deposit);
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = user1Deposit;

        vm.startPrank(user1);
        token.approve(address(transmuter), user1Deposit);
        transmuter.depositFunds(tokens, amounts);
        console.log(
            "User 1 Balance After Deposit:",
            transmuter.userBalances(user1, address(token))
        );
        vm.stopPrank();

        amounts[0] = user2Deposit;
        vm.startPrank(user2);
        token.approve(address(transmuter), user2Deposit);
        transmuter.depositFunds(tokens, amounts);
        console.log(
            "User 2 Balance After Deposit:",
            transmuter.userBalances(user2, address(token))
        );
        vm.stopPrank();

        console.log(
            "Total Balance Before Transmute:",
            transmuter.userBalances(user1, address(token)) +
                transmuter.userBalances(user2, address(token))
        );

        bytes memory swapData = abi.encodeWithSelector(
            FakeSwapper.swap.selector,
            address(token),
            excessiveSwapAmount,
            address(destinationToken),
            20e18
        ); // Assuming swap yields 20 tokens
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        try
            transmuter.transmute(
                users,
                address(token),
                excessiveSwapAmount,
                swapData
            )
        {
            console.log("Transmute did not revert as expected");
        } catch Error(string memory reason) {
            console.log("Transmute reverted with reason:", reason);
        } catch {
            console.log("Transmute reverted with unknown reason");
        }
    }

    function test_CanTransmuteSingleUser() external {
        address user1 = address(1);
        uint256 amount1 = 10e18;
        ERC20Mock token = new ERC20Mock();

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount1;

        token.mint(user1, amount1);

        vm.startPrank(user1);
        token.approve(address(transmuter), amount1);
        transmuter.depositFunds(tokens, amounts);
        vm.stopPrank();

        bytes memory swapData = abi.encodeWithSelector(
            FakeSwapper.swap.selector,
            address(token),
            10e18,
            address(destinationToken),
            8e18
        );
        address[] memory users = new address[](1);
        users[0] = user1;

        assertEq(destinationToken.balanceOf(user1), 0);

        transmuter.transmute(users, address(token), 10e18, swapData);

        assertEq(token.balanceOf(address(transmuter)), 0);
        assertEq(destinationToken.balanceOf(user1), 8e18);
        assertEq(transmuter.userBalances(user1, address(token)), 0);
    }

    function test_CanTransmuteMultipleUsers() external {
        address user1 = address(1);
        address user2 = address(2);
        uint256 amount1 = 10e18;
        uint256 amount2 = 5e18;
        ERC20Mock token = new ERC20Mock();

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount1;

        token.mint(user1, amount1);
        token.mint(user2, amount2);

        vm.startPrank(user1);
        token.approve(address(transmuter), amount1);
        transmuter.depositFunds(tokens, amounts);
        vm.stopPrank();

        amounts[0] = amount2;
        vm.startPrank(user2);
        token.approve(address(transmuter), amount2);
        transmuter.depositFunds(tokens, amounts);
        vm.stopPrank();

        bytes memory swapData = abi.encodeWithSelector(
            FakeSwapper.swap.selector,
            address(token),
            15e18,
            address(destinationToken),
            30e18
        );
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        assertEq(destinationToken.balanceOf(user1), 0);
        assertEq(destinationToken.balanceOf(user2), 0);

        transmuter.transmute(users, address(token), 15e18, swapData);

        assertEq(token.balanceOf(address(transmuter)), 0);
        assertEq(destinationToken.balanceOf(user1), 20e18);
        assertEq(destinationToken.balanceOf(user2), 10e18);
        assertEq(transmuter.userBalances(user1, address(token)), 0);
        assertEq(transmuter.userBalances(user2, address(token)), 0);
    }
}

contract FakeSwapper {
    address public constant ETH = 0x000000000000000000000000000000000000000E;

    function swap(
        address tokenToTake,
        uint256 amountToTake,
        address tokenToMint,
        uint256 amountToMint
    ) external payable {
        if (tokenToTake != ETH) {
            IERC20(tokenToTake).transferFrom(
                msg.sender,
                address(this),
                amountToTake
            );
        }
        ERC20Mock(tokenToMint).mint(msg.sender, amountToMint);
    }
}
