// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "../../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;

    // Fake address user
    address public constant USER = address(1);

    function setUp() external {
        crowdfunding = new Crowdfunding();
        vm.deal(USER, 100 ether); // Give USER some ether
    }

    function test_can_fund() public {
        uint256 user_balance_before = USER.balance;
        console.log("User balance before funding:", user_balance_before);

        uint256 amount = 1 ether;
        crowdfunding.fund{value: amount}();
    }
}
