// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Allows users to deposit tokens which can later be swapped into the `destinationToken` in bulk and redistributed
contract Transmuter {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Notional address we use to identify raw eth transfers
    address public constant ETH = 0x000000000000000000000000000000000000000E;

    /// @notice Swap router such as 0x or 1inch
    address public immutable swapRouter;

    /// @notice Token that deposits will be swapped into
    address public immutable destinationToken;

    /// @notice Mapping of user -> token -> deposited balance
    mapping(address => mapping(address => uint256)) public userBalances;

    // =================================================================
    // Errors
    // =================================================================

    error InvalidAddress();
    error MismatchLength();
    error InsufficientEth();
    //added error
    error SwapDidNotYieldTokens();
    error InsufficientTotalBalanceForSwap();

    // =================================================================
    // Events
    // =================================================================

    event FundsDeposited(address user, address[] tokens, uint256[] amounts);
    event UserAmountTransmuted(
        address user,
        address originalToken,
        uint256 originalAmount,
        uint256 destAmount
    );

    // =================================================================
    // Constructor
    // =================================================================

    constructor(address destinationToken_, address swapRouter_) {
        if (destinationToken_ == address(0)) {
            revert InvalidAddress();
        }
        if (swapRouter_ == address(0)) {
            revert InvalidAddress();
        }
        destinationToken = destinationToken_;
        swapRouter = swapRouter_;
    }

    // =================================================================
    // Public - State Changing
    // =================================================================

    /// @notice Deposit tokens and/or ETH for later swapping
    /// @param tokens Tokens to deposit. Approvals should be made prior to this call
    /// @param amounts Amounts to deposit

    //We can send different ETH with the same amount and keep increasing the balance.
    // for example if we add 50 as the value and we provide tokens of ETH, WETH, ETHE, the amounts would be 50,50,50 and userbalances will be equal to 150 instead of 50.
    //We should use msg.value instead

    function depositFunds(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external payable {
        uint256 len = tokens.length;
        if (len != amounts.length) {
            revert MismatchLength();
        }

        uint256 totalEthAmount = 0;

        // Credit ETH deposit
        if (msg.value > 0) {
            userBalances[msg.sender][ETH] += msg.value;
        }

        // Handle ERC20 token deposits
        for (uint256 i; i < len; ++i) {
            if (tokens[i] != ETH) {
                // Assuming ETH is a placeholder for the native ETH address
                IERC20(tokens[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amounts[i]
                );
                userBalances[msg.sender][tokens[i]] += amounts[i];
            }
        }
        // Check if the total ETH amount is correct
        if (totalEthAmount > msg.value) {
            revert InsufficientEth();
        }

        // Update the user balance for ETH if there was an ETH deposit
        if (totalEthAmount > 0) {
            userBalances[msg.sender][ETH] += totalEthAmount;
        }
        //added the event here instead
        emit FundsDeposited(msg.sender, tokens, amounts);
    }

    /// @notice Swap the given token for the given users to the `destinationToken`
    /// @param users Users to swap for
    /// @param token Token to swap out of
    /// @param amount The amount of token to swap out of
    /// @param swapData Call to the swap router to perform to execute the swap

    //because there is no check here, anyone can swap any token for anyone but I wont change this as to not change functionality of contract.
    //made the function payable
    function transmute(
        address[] calldata users,
        address token,
        uint256 amount,
        bytes calldata swapData
    ) external payable {
        uint256 userCnt = users.length;
        uint256 total = 0;
        uint256[] memory balances = new uint256[](userCnt);

        // Tally the balances so we know how to distribute later
        for (uint256 i = 0; i < userCnt; ++i) {
            uint256 amt = userBalances[users[i]][token];
            balances[i] = amt; // Storing original amount for distribution calculation
            total += amt;
        }

        if (total == 0) {
            //usage of custom error
            revert InsufficientTotalBalanceForSwap();
        }

        if (amount > total) {
            revert InsufficientTotalBalanceForSwap();
        }

        uint256 beforeBalance = IERC20(destinationToken).balanceOf(
            address(this)
        );

        // Perform the swap
        if (token == ETH) {
            if (msg.value != amount) {
                revert InsufficientEth();
            }
            swapRouter.functionCallWithValue(swapData, amount);
        } else {
            // ERC20 token swap logic
            IERC20(token).safeIncreaseAllowance(swapRouter, amount);
            swapRouter.functionCall(swapData);
        }

        // Figure out the total amount we received from the swap so we know how much to distribute

        uint256 amountReceived = IERC20(destinationToken).balanceOf(
            address(this)
        ) - beforeBalance;
        //checks after the swap essentially if it failed or not and reverts if it does.
        if (amountReceived == 0) {
            revert SwapDidNotYieldTokens();
        }

        // Distribute the tokens proportionally
        for (uint256 i = 0; i < userCnt; ++i) {
            userBalances[users[i]][token] = 0; // Resetting user balances to zero
            uint256 usersAmount = (amountReceived * balances[i]) / total; // Division rounding here.

            IERC20(destinationToken).safeTransfer(users[i], usersAmount);

            // Event emission after transfer to reflect final state
            emit UserAmountTransmuted(
                users[i],
                token,
                balances[i],
                usersAmount
            );
        }
    }
}
