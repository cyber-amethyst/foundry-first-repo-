//SPDX-License-Identifier: MIT

//In this contract, we intend to
//1. Deploy mocks when on a local Anvil chain
//2. Keep track of contract addresses across different chain networks
//For example sepolia ETH/USD price feed address is 0x694AA1769357215DE4FAC081bf1f309aDC325306
//which is different from the mainnet ETH/USD price feed address which is 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //we want this contract to be able to:
    // deploy mocks when on a local Anvil chain
    // otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    //make a new line and create a constant to pass for the numbers you want to pass in your mock test
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    //these helps us maintain readable codes rather than just using random numbers in our codeS

    //We use the struct keyword to hold the configuration for the different networks in anycase we want to add more networks in the future.
    //recall that a struct is a collection of variables of different types that are grouped together under a single name.
    struct NetworkConfig {
        address priceFeed; //which is just the ETH/USD price feed address
    }

    constructor() {
        //Note that in the recent versions of foundry, you cannot assign a memory struct to a storage struct variable
        if (block.chainid == 11155111) {
            // Sepolia chain id
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            // Mainnet chain id
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            // Anvil chain id
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        //memory keyword is used caused its a special type, its note stored in storage.
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        //NetworkConfig memory anvilConfig = NetworkConfig({
        //priceFeed: address(0) // placeholder just to show that we can deploy mocks here
        // In a real scenario, when using Anvil (local), we'll deploy a MockV3Aggregator and assign its address here.
        // See deployFundMe.s.sol for actual deployment logic
        // For example, if you had a mock contract deployed, you could set it like this
        // priceFeed: address(new MockV3Aggregator(8, 2000e8)) // 8 decimals, 2000 USD price
        //});note that a mock contract is just a fake contract that mimics the behaviour of a real contract
        // in that it is real, but it is controlled and predictable by us alone.
        // Remember to import the new mock contract you plan on using
        //return anvilConfig;
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 8 decimals, 2000 USD price (magic numbers have been replaced with constants)
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed) // we return the address of the mock contract
        });
        return anvilConfig;
    }

    //Remember we only made a placeholder for our getAnvilEthConfig, so now we do something different
    // 1. deploy the mocks
    // 2. Return the mock address
}
