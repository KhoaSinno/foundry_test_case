// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "../../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    event Funded(address indexed funder, uint256 value);
    address public ethPriceFeed;
    // Fake address user
    address public constant USER = address(1);

    uint256 public constant AMOUNT_OF_USER = 100 ether;
    uint256 public constant AMOUNT_TO_FUND = 5 ether;
    uint8 public constant PRICE_FEED_DECIMALS = 8;
    int256 public constant PRICE_FEED_INITIAL_ANSWER = 2000e8;

    function setUp() external {
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            PRICE_FEED_DECIMALS,
            PRICE_FEED_INITIAL_ANSWER
        );
        ethPriceFeed = address(mockV3Aggregator);
        crowdfunding = new Crowdfunding(ethPriceFeed);
        vm.deal(USER, AMOUNT_OF_USER); // Give USER some ether
    }

    function test_can_fund() public {
        uint256 user_balance_before = USER.balance;
        uint256 crowdfunding_balance_before = address(crowdfunding).balance;

        vm.expectEmit();
        emit Funded(USER, AMOUNT_TO_FUND);

        vm.prank(USER);
        crowdfunding.fund{value: AMOUNT_TO_FUND}();

        uint256 user_balance_after = USER.balance;
        uint256 crowdfunding_balance_after = address(crowdfunding).balance;

        assertEq(user_balance_after + AMOUNT_TO_FUND, user_balance_before);
        assertEq(
            crowdfunding_balance_after,
            crowdfunding_balance_before + AMOUNT_TO_FUND
        );

        // More assertions
        assertTrue(crowdfunding.s_funderToAmount(USER) == AMOUNT_TO_FUND);
        assertTrue(crowdfunding.s_funders(0) == USER);
        assertTrue(crowdfunding.s_is_funders(USER));
        assertTrue(crowdfunding.gets_fundersLength() == 1);
    }
}
