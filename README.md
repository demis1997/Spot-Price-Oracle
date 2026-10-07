# Spot-Price-Oracle

Foundry spot-price and transmuter contract experiments with fork-oriented tests.

## Source and reproduction

Inspected Solidity: `src/Transmuter.sol`, `test/GetPrice.t.sol`, `src/getSpotPrice.sol`, `test/Transmute.t.sol`. Contracts include `Transmuter`, `GetPrice`, `assumes`, `AssesmentOracle`, `TransmuterTests`. Source compiler pragmas: `^0.8.23`.

```sh
forge build
forge test
```

These commands are derived from the Foundry layout and were not run in this pass. Dependency versions and any fork RPC requirements need verification before execution.

This is a prototype/security-study example. Do not interpret the source as audited production code or execute it against third-party deployments. No on-chain transaction was performed.

License: the existing checked-in license remains unchanged.

## Existing notes and attribution

To run this use anvil to fork with the following command:

 anvil --fork-url https://mainnet.infura.io/v3/YOUR-API-KEY-HERE

and then use the following to test and view the logs:
forge test -vv --rpc-url http://127.0.0.1:8545   


GetSpotPrice.sol meets assesment requirements and uses the interface
GetSpotPriceAndPool.sol is an extra implementation i did that does not use your interface.
