// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @notice Thrown when a non-owner tries to call owner-only functions
 * @dev Custom error is more gas efficient than using strings
 */
error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author @Cyber-amethyst (Vickie)
 * @notice This contract allows users to fund and the owner to withdraw funds
 * @dev Implements Chainlink Price Feeds to convert ETH amounts to USD
 */
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders; // Note that all these s_... are storage functions
    //It is also best practice to make state variables be set to private rather than public. It is more gas efficient
    //e.g, mapping(address => uint256) public s_addressToAmountFunded; ---->this is not gas efficient

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18; //5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed; // s_ is used to represent that it is a storage variable

    /**
     * @notice Constructor that sets the contract owner and price feed
     * @param priceFeed Address of the Chainlink price feed contract
     * @dev The owner is set to the deployer (msg.sender)
     */
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /**
     * @notice Allows users to fund the contract with ETH
     * @dev Requires at least MINIMUM_USD worth of ETH based on current price feed
     * @dev Adds the funder to the s_funders array and updates their total funded amount
     */
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    /**
     * @notice Gets the version of the Chainlink price feed being used
     * @return The version number of the price feed aggregator
     */
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * @dev Modifier to restrict function access to only the contract owner
     */
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    /**
     * @notice Allows the owner to withdraw all funds (gas optimized version)
     * @dev More gas efficient than withdraw() by caching the funders array length in memory
     * @dev Resets all funder balances and the funders array, then transfers all ETH to owner
     */
    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
                //This will save gas by avoiding reading s_funders.length on every loop and instead read it once. funderLenght is now a memory variable
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; // s_addressToAmountFunded is a storage variable and will be called from storage regardless
        }
        s_funders = new address[](0); // reset the array
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed"); //there is not much to do here, its already gas efficient
    }

    /**
     * @notice Allows the owner to withdraw all funds
     * @dev Resets all funder balances and the funders array, then transfers all ETH to owner
     * @dev Uses the call method which is the recommended way to transfer ETH
     */
    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // transfer issue is it uses too much gas and can fail if the recipient is a contract that does not accept ether
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    /**
     * @notice Fallback function that redirects to fund()
     * @dev Called when contract receives ETH with data that doesn't match any function
     */
    fallback() external payable {
        fund();
    }

    /**
     * @notice Receive function that redirects to fund()
     * @dev Called when contract receives plain ETH with no data
     */
    receive() external payable {
        fund();
    }

    /**
     * Creating getter functions
     * View / Pure function will be our 'Getters'
     */
    /**
     * @notice Gets the total amount funded by a specific address
     * @param fundingAddress The address to query
     * @return The amount in wei that the address has funded
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    /**
     * @notice Gets the funder address at a specific index in the funders array
     * @param index The index position in the funders array
     * @return The address of the funder at that index
     */
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    /**
     * @notice Gets the contract owner's address
     * @return The address of the contract owner
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
