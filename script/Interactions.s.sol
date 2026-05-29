//this is an interactions script file that allows us to interact with our contract in a reproducable way.
//it is a child contract of the DeployFundMe script.
//it is used to test the contract in a real world scenario
//it is used to fund the contract and withdraw the funds.
//fund script 
//withdraw script



// SPDX-License Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

// so this interactions file can have multiple contracts in it. e.g FundFundMe and WithdrawFundMe

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
//take note to make sure that your intercations is with yor most recently deployed contract.
//this is because the most recently deployed contract is the one that is being tested.
//so if you are not using the most recently deployed contract, you will be testing the wrong contract.
//this is why we use the DevOpsTools.get_most_recent_deployment function to get the most recently deployed contract.
//this is a cheatcode that will get the most recently deployed contract on the current chain you are connected to.j
    
    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external { // this is the function that will call the FundFundMe function to fund the FundMe contract

        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid); 
        // this will get the most recently deployed FundMe contract on the current chain you are connected to
        vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid); // this will get the most recently deployed FundMe contract on the current chain you are connected to

        withdrawFundMe(mostRecentlyDeployed);
    }
}
//In essence, the interactions file is a child contract of the DeployFundMe script. It is just a list of all the ways we can interact with our contract in a reproducable way.
//Hence the fund script and the withdraw script are child contracts of the DeployFundMe script
