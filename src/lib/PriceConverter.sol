// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        address priceFeedAddress
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        require(answer > 0, "Invalid price data");
        // nhận về 8 digits, thêm vào 10 số 0 để lấy thành 18 digits
        return uint256(answer) * 1e10;
    }

    function getConversionRate(
        uint256 ethAmount,
        address priceFeedAddress
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeedAddress);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
