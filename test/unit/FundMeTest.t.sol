// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // Import the DeployFundMe script to use its deploy function

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("Vickie"); // this is a cheatcode that will create a random address for us to use in our tests
    uint256 constant SEND_VALUE = 10e18; // OR 0.1 ether == 100000000000000000
    uint256 constant STARTING_BALANCE = 10e18; // 10 ether
    uint256 constant GAS_PRICE = 1; // 1 gwei

    //we can use this constant gas price to simulate a real world scenario where gas price is not zero
    //e.g; vm.txGasPrice(GAS_PRICE);

    //uint256 number = 1;
    function setUp() external {
        // this function is run before each test case
        // us-> FundMeTest -> FundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //number = 2;
        DeployFundMe deployFundMe = new DeployFundMe(); // Create an instance of the DeployFundMe script
        fundMe = deployFundMe.run(); // Call the run function to deploy the FundMe contract
        vm.deal(USER, STARTING_BALANCE); // this is a cheatcode that will give the USER address some starting balance to work with
    }

    function testMinimumDollarIsFive() public view {
        //console.log(number) used for writing test cases and in debugging
        //console.log("Hello World"); include this in the test case and when running it, recall to use -vv to specify the visibility of logging
        //For my version of foundry, i have to use the -vvv before i specify the test flag that i want to run. For eg; forge test -vvv --match-test testPriceFeedVersionIsAccurate(Note to write the natch test in full to avoid errors)

        //assertEq(number, 2);
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        //console.log(fundMe.i_owner()) ; // this will print the address of the owner
        //console.log(msg.sender); // this will print the address of the sender
        assertEq(fundMe.getOwner(), msg.sender); // now cause we are using deployscript to run this test, the owner is back to being msg.sender
        //otherwise,we use * address(this));* // this will check if the owner is the same as the sender, rather than using msg.sender which is a different address and would fail.
        // Note that it is good to have a couple of tests written before you start refactoring, to avoid breaking anything

        //what can we do to work with addresses outside our system?
        // 1. Unit test
        //      - Testing a specific part of our code
        // 2. Integration test
        //      - Testing how our code works with other parts of our code
        // 3. Forked test
        //      - Testing how our code works with other parts of the blockchain i.e Testing our code on a simulated real environment.
        // 4. Staging test
        //      - Testing our code in a real environment that is not production enviroment alone, to make sure everything is working correctly. This happens when we deploy our code to a testnet or mainnet.
    }

    //function testPriceFeedVersionIsAccurate() public view{
    //uint256 version = fundMe.getVersion();
    //assertEq(version, 4); // this will check if the version is 4
    //the downside of using the forked  test is that it will run a lot of abi codes which will take a lot of time to run and also run a lot of gas
    //we can also use the block.chainid to check which network we are on and then check the version of the price feed}
    //Here is a better way to put it
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();

        if (block.chainid == 1) {
            // Ethereum Mainnet
            assertEq(version, 6);
        } else if (block.chainid == 11155111) {
            // Sepolia
            assertEq(version, 4);
        } else {
            // Default or local mock returns
            assertEq(version, 4); // or whatever your mock is set to
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        //fundMe.fund{value: 1e17}(); // this will send 0.1 eth to the fund function
        //we expect this to fail because the minimum is 5 usd which is about 0.002 eth
        vm.expectRevert(); //By using this expectRevert, this will expect the next line to revert; and this is euivalent to saying "assert(this txn fails/reverts)".
        fundMe.fund(); // this will send 0 eth to the fund function and therefore revert
        //uint256 cat = 1; this on the other hand will not make the function fail/revert because enough ETH was sent
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // this will make the next call be from USER address rather than the default address which is address(this)
        fundMe.fund{value: SEND_VALUE}();
        //we could also say assert(fundMe.addressToAmountFunded(address(this)) == 10e18);
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); // we want to be very explicit in our tests of who is sending what at all times
        //we can use the 'prank' cheatcode to always know who is sending what call. This only works in our test files and is only applicable to foundry
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0); // we want to be very explicit in our tests of who is sending what at all times
        assertEq(funder, USER);
    }

    //NOTE: You can run a specific test function by using the command: forge test --match-test <function name>
    //e.g; forge test --match-test testWithdrawWithASingleFunder

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // this modifier will make sure that your test functions are not too long and also avoid code repetition, so that you don't have to keep writing the same code in multiple test functions
    //it is a good practice to use modifiers to keep your test functions clean and readable
    //remember to add the 'funded' modifier to any test function that requires the contract to be funded before running the test

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        //Now we want to try to withdraw as USER rather than the owner and this should fail
        vm.prank(USER);
        vm.expectRevert(); // we expect this to revert because USER is not the owner
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft(); //for instance,  if this is 1000
        //we can use the txGasPrice cheatcode to set the gas price for the next transaction
        vm.txGasPrice(GAS_PRICE); // this will set the gas price for the next transaction to 1 gwei
        vm.prank(fundMe.getOwner()); // and this txn spent/ cost 200 gas
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); // the final gas left after the txn is 800. Such that;
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // this will give us the gas used in gwei i.e (1000-800) * 1 gwei = 200 gwei
        console.log(gasUsed);
        //we can also convert this to ether by dividing by 1e9 i.e 200 gwei / 1e9 = 0.0000002 ether
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because 0 is already taken by USER in the funded modifier and it reverts
        for (
            uint160 i = startingFunderIndex;
            i < startingFunderIndex + numberOfFunders;
            i++
        ) {
            //we could use the prank cheatcode and the vm.deal cheatcode to create multiple funders addresses that will fund the fundMe contract i.e
            //vm.prank (address(i)); // this will make the next call be from address(i) rather than the default address which is address(this)
            //vm.deal(address(i), SEND_VALUE); // this will give address(i) some starting balance to work with
            //fundMe.fund{value: SEND_VALUE}();
            // BUT/// a better way to do this is to use the hoax cheatcode which is a forge standard keycode which combines both prank and deal into one line of code
            hoax(address(i), SEND_VALUE); // this address can be generated with numbers but the 'uint' becomes uint160 and not uint256
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner()); //doing vm.startprank is better practice than just using vm.prank if you have multiple calls to make as the same address
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because 0 is already taken by USER in the funded modifier and it reverts
        for (
            uint160 i = startingFunderIndex;
            i < startingFunderIndex + numberOfFunders;
            i++
        ) {
            //we could use the prank cheatcode and the vm.deal cheatcode to create multiple funders addresses that will fund the fundMe contract i.e
            //vm.prank (address(i)); // this will make the next call be from address(i) rather than the default address which is address(this)
            //vm.deal(address(i), SEND_VALUE); // this will give address(i) some starting balance to work with
            //fundMe.fund{value: SEND_VALUE}();
            // BUT/// a better way to do this is to use the hoax cheatcode which is a forge standard keycode which combines both prank and deal into one line of code
            hoax(address(i), SEND_VALUE); // this address can be generated with numbers but the 'uint' becomes uint160 and not uint256
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner()); //doing vm.startprank is better practice than just using vm.prank if you have multiple calls to make as the same address
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
    // us is calling -> fundMeTest which then -> deploys the FundMe contract
    // refactoring s when you change thr achitechtural i.e structure of your code, without actually changing their functionality.
    // if you update how you deploy your contract in script, you also have to update how you deploy in your test as well. But this can be too much work and therefore we have to find a way to make it easier for us to deploy our contract in both script and test.
    // We can do this by creating a constructor in our test contract that will deploy the contract for us, so we don't have to write the same code in both script and test. so we use the import statement to import the 'deploy' function from the script to the test contract. This way we can use the same code to deploy our contract in both script and test.
}
