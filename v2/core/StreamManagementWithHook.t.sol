// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "@sablier/v2-core/src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupLinear } from "@sablier/v2-core/src/SablierV2LockupLinear.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/src/Test.sol";
import { StreamManagementWithHook } from "./StreamManagementWithHook.sol";

contract MockERC20 is ERC20 {
    constructor(address to) ERC20("MockERC20", "MockERC20") {
        _mint(to, 1_000_000e18);
    }
}

contract StreamManagementWithHookTest is Test {
    StreamManagementWithHook internal streamManager;
    ISablierV2LockupLinear internal sablierLockup;

    ERC20 internal token;
    uint128 internal amount = 10e18;
    uint256 internal DEFAULT_STREAM_ID;

    address internal alice;
    address internal bob;
    address internal sablierAdmin;

    function setUp() public {
        // Create a test users
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
        sablierAdmin = payable(makeAddr("SablierAdmin"));

        // Create a mock ERC20 token and send 1M tokens to Bob
        token = new MockERC20(bob);

        // Deploy Sablier Lockup Linear contract
        sablierLockup = new SablierV2LockupLinear(
            sablierAdmin,
            ISablierV2NFTDescriptor(address(0)) // Irrelevant for test purposes
        );

        // Deploy StreamManagementWithHook contract
        streamManager = new StreamManagementWithHook(sablierLockup, token);

        // Whitelist the contract to be able to hook into Sablier Lockup contract
        vm.startPrank(sablierAdmin);
        sablierLockup.allowToHook(address(streamManager));
        vm.stopPrank();

        // Approve streamManager to spend MockERC20 on behalf of Bob
        vm.startPrank(bob);
        token.approve(address(streamManager), type(uint128).max);
    }

    // Test creating a stream from Bob (Stream Manager Owner) to Alice (Beneficiary)
    function test_Create() public {
        // Create a stream with Alice as the beneficiary
        uint256 streamId = streamManager.create({ beneficiary: alice, totalAmount: amount });

        // Check streamId
        assertEq(streamId, 1);

        // Check balances
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 1_000_000e18 - amount);
        assertEq(token.balanceOf(address(sablierLockup)), amount);

        // Check stream details are correct
        assertEq(address(sablierLockup.getAsset(streamId)), address(token));
        assertEq(sablierLockup.getRecipient(streamId), address(streamManager));
        assertEq(sablierLockup.getDepositedAmount(streamId), amount);
        assertEq(sablierLockup.isCancelable(streamId), true);
        assertEq(sablierLockup.isTransferable(streamId), false);

        // Check streamManager details are correct
        assertEq(streamManager.streamBeneficiaries(streamId), alice);
    }

    modifier givenStreamsCreated() {
        // Create a stream with Alice as the beneficiary
        DEFAULT_STREAM_ID = streamManager.create({ beneficiary: alice, totalAmount: amount });
        require(DEFAULT_STREAM_ID == 1, "Stream creation failed");
        _;
    }

    // Test that withdraw from Sablier stream reverts if it is directly called on the Sablier Lockup contract
    function test_Withdraw_RevertWhen_CallerNotStreamManager() public givenStreamsCreated {
        // Warp time to exceed total duration
        vm.warp({ newTimestamp: block.timestamp + 60 weeks });

        // Prank Alice to be the `msg.sender`.
        vm.startPrank(alice);

        // Since Alice is the `msg.sender`, `withdraw` to Sablier stream should revert due to hook restriction
        vm.expectRevert(abi.encodeWithSelector(StreamManagementWithHook.CallerNotThisContract.selector));
        sablierLockup.withdraw(DEFAULT_STREAM_ID, address(streamManager), 1e18);
    }

    // Test that withdraw from Sablier stream succeeds if it is called through the `streamManager` contract
    function test_Withdraw() public givenStreamsCreated {
        // Advance time enough to make cliff period over and the total duration to be over
        vm.warp({ newTimestamp: block.timestamp + 60 weeks });

        // Prank Alice to be the `msg.sender`
        vm.startPrank(alice);

        // Alice can withdraw from the streamManager contract
        streamManager.withdraw(DEFAULT_STREAM_ID, 1e18);

        assertEq(token.balanceOf(alice), 1e18);

        // Withdraw max tokens from the stream
        streamManager.withdrawMax(DEFAULT_STREAM_ID);

        assertEq(token.balanceOf(alice), 10e18);
    }
}
