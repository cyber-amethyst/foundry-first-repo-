//SPDX License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //since this is before the vm,startBroadcast,
        //it will not be sent as a real txn to the network, it will only just be simulated on a local call.
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        //Anything after startBroadcast is a real txn
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed); //(has been updated to take the price feed address as an argument)
        //We still have our sepolia address here which will require us to always make a call to anvil or particlar chainlink node to get the price feed addresss.
        // Else we are met with error if we just pass or test the contract without making the Abi call to the network and inputing the url of the chainlink node.
        //what we can do is to create mock contracts that will simulate the chainlink node and then we can use that to test our contract without having to make a call to the network.
        vm.stopBroadcast();
        //console.log("FundMe deployed to: ", address(fundMe));
        //console.log("FundMe deployed to: ", address(this));
        //console.log("FundMe deployed to: ", msg.sender);
        //console.log("FundMe deployed to: ", tx.origin);
        return fundMe;
    }
}
