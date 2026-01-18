// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // Import the DeployFundMe script to use its deploy function
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //0.1 ETH
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        // Give USER some ETH to start with
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        // Deploy the interaction contracts
        FundFundMe fundFundMe = new FundFundMe();
        // Fund the FundFundMe contract so it can send ETH
        vm.deal(address(fundFundMe), 1 ether); // give the contract some ether to work with
        // 1️⃣ Fund the FundMe contract
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        // 2️⃣ Withdraw funds from FundMe
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
