# Contracts Technical Assessment

Thank you for your interest in Tokemak and for taking the time to perform the technical assessment. Please privately fork the repo and grant access to the designated contact upon your completion. The assessment comes in two parts:

1.  Find the Bugs
2.  Implement a Spot Price Oracle

## Find the Bugs - Transmuter

Review the `src/Transmuter.sol` contract in the `transmuter` branch. Open a PR to `main` and perform your review. Your review should focus on bugs and security/attack issues.

## Spot Price Oracle Implementation

Provide an implementation of the `src/interfaces/ISpotPriceOracle.sol` interface for a Curve StableSwap pool (V1):

- Must work on 2+ coin pools
- Is not required to work on meta, lending, or -ng pools
- You can assume the requested token, and quote token, are constituents of the pool provided.
- Please list any assumptions you've made in the contract


To run this use anvil to fork with the following command:

 anvil --fork-url https://mainnet.infura.io/v3/YOUR-API-KEY-HERE

and then use the following to test and view the logs:
forge test -vv --rpc-url http://127.0.0.1:8545   


GetSpotPrice.sol meets assesment requirements and uses the interface
GetSpotPriceAndPool.sol is an extra implementation i did that does not use your interface.

The bugs I found in the two functions can be seen in the comments for each functions and the foundry tests.
I have also included the fixes


