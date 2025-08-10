// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PriceConverter} from "./lib/PriceConverter.sol";

contract Crowdfunding {
    using PriceConverter for uint256;

    error NoAvailableAmount();

    uint256 public constant MINIMUM_USD = 5e18; // 5 USD in Wei
    address public immutable i_owner;

    mapping(address => bool) public s_is_funders;
    mapping(address => uint256) public s_funderToAmount;
    address[] public s_funders;

    event Funded(address indexed funder, uint256 value);
    event Withdrawn(uint256 value);

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert NoAvailableAmount();
        }
        _;
    }

    function fund() public payable {
        // require(
        //     msg.value.getConversionRate() >= MINIMUM_USD,
        //     "no available amount"
        // );

        s_funderToAmount[msg.sender] += msg.value;
        bool isFunded = s_is_funders[msg.sender];

        if (!isFunded) {
            s_funders.push(msg.sender);
            s_is_funders[msg.sender] = true;
        }

        emit Funded(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(i_owner).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        emit Withdrawn(address(this).balance);
    }

    // Tìm ra có bao nhiêu người đã đóng góp
    function gets_fundersLength() public view returns (uint256) {
        return s_funders.length;
    }
}
