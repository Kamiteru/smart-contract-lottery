// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract InteractionTest is Test, CodeConstants {
    Raffle raffle;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;
    uint256 public constant FUND_AMOUNT = 3 ether;

    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.run();
        config = helperConfig.getConfig();
    }

    function testCreateSubscriptionUsingConfig() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        // Act
        (uint256 subId, address vrfCoordinator) = createSubscription.createSubscriptionUsingConfig();
        // Assert
        assertTrue(subId != 0, "subId should not be zero");
        (,,, address owner,) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subId);
        assertEq(owner, config.account, "owner mismatch");
    }

    function testCreateSubscription() public {
        // Arrange
        config = helperConfig.getConfig();
        // Act
        vm.startPrank(config.account);
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).createSubscription();
        vm.stopPrank();
        // Assert
        assertTrue(subId != 0);
    }

    function testFundSubscriptionUsingConfig() public {
        // Arrange
        config = helperConfig.getConfig();
        vm.startPrank(config.account);
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).createSubscription();
        vm.stopPrank();
        FundSubscription fundSubscription = new FundSubscription();
        // Act
        fundSubscription.fundSubscription(config.vrfCoordinatorV2_5, subId, config.link, config.account);
        // Assert
        (uint96 balance,,,,) = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).getSubscription(subId);
        assertGt(balance, 0, "Balance should be greater than 0");
    }

    function testFundSubscription() public {
        // Arrange
        config = helperConfig.getConfig();
        vm.startPrank(config.account);
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).createSubscription();
        vm.stopPrank();
        (uint96 initialBalance,,,,) = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).getSubscription(subId);
        assertEq(initialBalance, 0, "Initial balance should be 0");
        // Act
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startPrank(config.account);
            VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopPrank();
        } else {
            vm.startPrank(config.account);
            LinkToken(config.link).transferAndCall(config.vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopPrank();
        }
        // Assert
        (uint96 balance,,, address owner,) = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).getSubscription(subId);
        assertEq(owner, config.account, "Owner should be config.account");

        if (block.chainid == LOCAL_CHAIN_ID) {
            assertEq(balance, initialBalance + FUND_AMOUNT * 100, "Balance should increase by FUND_AMOUNT * 100");
        } else {
            assertGe(balance, initialBalance + FUND_AMOUNT, "Balance should increase by at least FUND_AMOUNT");
        }
    }

    function testAddConsumerUsingConfig() public {
        // Arrange
        config = helperConfig.getConfig();
        AddConsumer addConsumer = new AddConsumer();
        vm.startPrank(config.account);
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).createSubscription();
        vm.stopPrank();
        // Act
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, subId, config.account);
        // Assert
        assertTrue(
            VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).consumerIsAdded(subId, address(raffle)),
            "Raffle should be added as consumer"
        );
    }

    function testAddConsumer() public {
        // Arrange
        config = helperConfig.getConfig();
        vm.startPrank(config.account);
        uint256 subId = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).createSubscription();
        vm.stopPrank();
        // Act
        vm.startPrank(config.account);
        VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).addConsumer(subId, address(raffle));
        vm.stopPrank();
        // Assert
        (,,,, address[] memory consumers) = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).getSubscription(subId);
        assertEq(consumers.length, 1, "Should have exactly one consumer");
        assertEq(consumers[0], address(raffle), "Raffle should be the consumer");
    }
}
