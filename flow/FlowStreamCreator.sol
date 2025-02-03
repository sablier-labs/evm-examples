// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";

import { FlowUtilities } from "./FlowUtilities.sol";

contract FlowStreamCreator {
    // Mainnet addresses
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ISablierFlow public constant FLOW = ISablierFlow(0x3DF2AAEdE81D2F6b261F79047517713B8E844E04);

    // Create a stream that sends 1000 USDC per month.
    function createStream_1K_PerMonth() external returns (uint256 streamId) {
        UD21x18 ratePerSecond =
            FlowUtilities.ratePerSecondWithDuration({ token: address(USDC), amount: 1000e6, duration: 30 days });

        streamId = FLOW.create({
            sender: msg.sender, // The sender will be able to manage the stream
            recipient: address(0xCAFE), // The recipient of the streamed tokens
            ratePerSecond: ratePerSecond, // The rate per second equivalent to 1000 USDC per month
            token: USDC, // The token to be streamed
            transferable: true // Whether the stream will be transferable or not
         });
    }

    // Create a stream that sends 1,000,000 USDC per year.
    function createStream_1M_PerYear() external returns (uint256 streamId) {
        UD21x18 ratePerSecond =
            FlowUtilities.ratePerSecondWithDuration({ token: address(USDC), amount: 1_000_000e6, duration: 365 days });

        streamId = FLOW.create({
            sender: msg.sender, // The sender will be able to manage the stream
            recipient: address(0xCAFE), // The recipient of the streamed tokens
            ratePerSecond: ratePerSecond, // The rate per second equivalent to 1,000,00 USDC per year
            token: USDC, // The token to be streamed
            transferable: true // Whether the stream will be transferable or not
         });
    }
}
