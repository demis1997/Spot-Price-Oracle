// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMetaPoolRegistry {
    function find_pool_for_coins(address _from, address _to) external view returns (address);
}