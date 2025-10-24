// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Helper} from "../src/devtools/Helper.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OAppBorrow} from "../src/L0/OAppBorrow.sol";
import {IOAppBorrow} from "../src/interfaces/IOAppBorrow.sol";
import {HelperDeployment} from "../src/HelperDeployment.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {Pricefeed} from "../src/Pricefeed.sol";

// RUN
// forge test --match-contract NusaTest -vvvv
contract NusaTest is Test, Helper, HelperDeployment {
    using OptionsBuilder for bytes;

    USDC public usdc;
    WETH public weth;
    WBTC public wbtc;
    // address public usdc;
    // address public weth;
    // address public wbtc;
    Router public router;
    IsHealthy public isHealthy;
    TokenDataStream public tokenDataStream;
    LendingPool public lendingPool;
    ERC1967Proxy public proxy;
    OAppBorrow public oappBorrow;
    Pricefeed public pricefeed;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    uint32 dstEid0;
    uint32 dstEid1;

    address endpoint;
    address oapp;
    address sendLib;
    address receiveLib;
    address dvn1;
    address dvn2;
    address executor;
    uint32 srcEid;
    uint32 gracePeriod;

    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;
    uint32 constant RECEIVE_CONFIG_TYPE = 2;
    uint16 constant SEND = 1; // Message type for send function

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("hyperliquid_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startPrank(owner);
        _deployMockToken();
        _deployNusaCore();
        _activateToken();
        // _getUtils(); // Initialize endpoint and LayerZero config variables
        // _deployOAppBorrow();
        // _setLibraries();
        // _setSendConfig();
        // _setReceiveConfig();
        // _setPeers();
        // _setEnforcedOptions();
        // _setChainId();
        // router.setChainIdToLzEid(block.chainid == 8453 ? 42161 : 8453, dstEid1);
        // router.setChainIdToOApp(8453, address(oappBorrow));
        vm.stopPrank();
        deal(address(usdc), alice, 100_000e6);
        deal(address(weth), alice, 100_000e18);
        vm.deal(alice, 100_000e18);
    }

    function _deployMockToken() internal {
        usdc = new USDC();
        weth = new WETH();
        wbtc = new WBTC();
        // usdc = block.chainid == 8453 ? BASE_USDC : ARB_USDC;
        // weth = block.chainid == 8453 ? BASE_WETH : ARB_WETH;
        // wbtc = block.chainid == 8453 ? BASE_WBTC : ARB_WBTC;
        tokenDataStream = new TokenDataStream();

        if (block.chainid == 8453) {
            tokenDataStream.setTokenPriceFeed(address(usdc), address(BASE_USDC_USD));
            tokenDataStream.setTokenPriceFeed(address(weth), address(BASE_ETH_USD));
        } else if (block.chainid == 42161) {
            pricefeed = new Pricefeed(address(usdc));
            pricefeed.setPrice(0, 1e8, 0, 0, 0);
            tokenDataStream.setTokenPriceFeed(address(usdc), address(pricefeed));

            pricefeed = new Pricefeed(address(weth));
            pricefeed.setPrice(0, 4_000e8, 0, 0, 0);
            tokenDataStream.setTokenPriceFeed(address(weth), address(pricefeed));
        }
    }

    function _deployNusaCore() internal {
        router = new Router();

        isHealthy = new IsHealthy(address(router));

        lendingPool = new LendingPool();
        bytes memory data = abi.encodeWithSelector(lendingPool.initialize.selector);
        proxy = new ERC1967Proxy(address(lendingPool), data);
        lendingPool = LendingPool(payable(proxy));
        lendingPool.setRouter(address(router));

        router.setTokenDataStream(address(tokenDataStream));
        router.setIsHealthy(address(isHealthy));
        router.setLendingPool(address(lendingPool));
    }

    function _activateToken() internal {
        lendingPool.setTokenActive(address(weth), true);
        lendingPool.setTokenActive(address(usdc), true);
        lendingPool.setToken(address(weth), true);
        lendingPool.setToken(address(usdc), true);

        lendingPool.setBorrowLtv(address(weth), 0.8e18); // Set borrow LTV (80% = 0.8e18)
        lendingPool.setBorrowLtv(address(usdc), 0.8e18); // Set borrow LTV (80% = 0.8e18)
    }

    function _getUtils() internal {
        if (block.chainid == 8453) {
            endpoint = BASE_LZ_ENDPOINT;
            sendLib = BASE_SEND_LIB;
            receiveLib = BASE_RECEIVE_LIB;
            dvn1 = BASE_DVN1;
            dvn2 = BASE_DVN2;
            executor = BASE_EXECUTOR;
            srcEid = BASE_EID;
            dstEid0 = BASE_EID;
            dstEid1 = ARB_EID;
            gracePeriod = uint32(0);
        } else if (block.chainid == 42161) {
            endpoint = ARB_LZ_ENDPOINT;
            sendLib = ARB_SEND_LIB;
            receiveLib = ARB_RECEIVE_LIB;
            dvn1 = ARB_DVN1;
            dvn2 = ARB_DVN2;
            executor = ARB_EXECUTOR;
            srcEid = ARB_EID;
            dstEid0 = ARB_EID;
            dstEid1 = BASE_EID;
            gracePeriod = uint32(0);
        }
    }

    /// @notice Helper function to convert fixed-size array to dynamic array
    function _toDynamicArray(address[2] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](2);
        dynamicArray[0] = fixedArray[0];
        dynamicArray[1] = fixedArray[1];
        return dynamicArray;
    }

    function _toDynamicArray1(address[1] memory fixedArray) internal pure returns (address[] memory) {
        address[] memory dynamicArray = new address[](1);
        dynamicArray[0] = fixedArray[0];
        return dynamicArray;
    }

    function _deployOAppBorrow() internal {
        oappBorrow = new OAppBorrow(endpoint, owner);
        oappBorrow.setLendingPool(address(lendingPool));
        router.setChainIdToOApp(block.chainid, address(oappBorrow));
        router.setChainIdToLzEid(block.chainid == 8453 ? 8453 : 42161, dstEid0);
        router.setChainIdToLzEid(block.chainid == 8453 ? 42161 : 8453, dstEid1);
    }

    /// @notice Set send and receive libraries for LayerZero endpoint
    function _setLibraries() internal {
        ILayerZeroEndpointV2(endpoint).setSendLibrary(address(oappBorrow), dstEid1, sendLib);
        ILayerZeroEndpointV2(endpoint).setReceiveLibrary(address(oappBorrow), srcEid, receiveLib, gracePeriod);
    }

    /// @notice Set send configuration (ULN + Executor)
    function _setSendConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });

        ExecutorConfig memory exec = ExecutorConfig({maxMessageSize: 10000, executor: executor});
        bytes memory encodedUln = abi.encode(uln);
        bytes memory encodedExec = abi.encode(exec);

        SetConfigParam[] memory params = new SetConfigParam[](4);
        params[0] = SetConfigParam(dstEid0, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[1] = SetConfigParam(dstEid0, ULN_CONFIG_TYPE, encodedUln);
        params[2] = SetConfigParam(dstEid1, EXECUTOR_CONFIG_TYPE, encodedExec);
        params[3] = SetConfigParam(dstEid1, ULN_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(endpoint).setConfig(address(oappBorrow), sendLib, params);
    }

    /// @notice Set receive configuration (ULN)
    function _setReceiveConfig() internal {
        UlnConfig memory uln = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _toDynamicArray([dvn1, dvn2]),
            optionalDVNs: new address[](0)
        });

        bytes memory encodedUln = abi.encode(uln);
        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(dstEid0, RECEIVE_CONFIG_TYPE, encodedUln);
        params[1] = SetConfigParam(dstEid1, RECEIVE_CONFIG_TYPE, encodedUln);

        ILayerZeroEndpointV2(endpoint).setConfig(address(oappBorrow), receiveLib, params);
    }

    /// @notice Set peer connections between OApps on different chains
    function _setPeers() internal {
        // Set peer to itself for same chain
        oappBorrow.setPeer(dstEid0, bytes32(uint256(uint160(address(oappBorrow)))));

        // Set peer to remote oappBorrow for cross-chain (use same address for testing)
        oappBorrow.setPeer(dstEid1, bytes32(uint256(uint160(address(oappBorrow)))));
    }

    /// @notice Set enforced execution options for specific message types
    function _setEnforcedOptions() internal {
        bytes memory options1 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0);
        bytes memory options2 = OptionsBuilder.newOptions().addExecutorLzReceiveOption(100000, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({eid: dstEid0, msgType: SEND, options: options1});
        enforcedOptions[1] = EnforcedOptionParam({eid: dstEid1, msgType: SEND, options: options2});

        oappBorrow.setEnforcedOptions(enforcedOptions);
    }

    function _setChainId() internal {
        lendingPool.setChainId(block.chainid == 8453 ? 42161 : 8453);
    }

    // RUN
    // forge test -vvv --match-test test_setChainId
    // function test_setChainId() public {
    //     vm.startPrank(owner);
    //     lendingPool.setChainId(8453);
    //     vm.stopPrank();
    // }

    // RUN
    // forge test -vvv --match-test test_supply_collateral
    function test_supply_collateral() public {
        vm.startPrank(alice);
        uint256 amount = 1_000e18;
        IERC20(address(weth)).approve(address(lendingPool), amount);
        lendingPool.supplyCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, block.chainid, address(weth)), amount);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdraw_collateral
    function test_withdraw_collateral() public {
        vm.startPrank(alice);
        uint256 amount = 1_000e18;

        // First supply collateral
        IERC20(address(weth)).approve(address(lendingPool), amount);
        lendingPool.supplyCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, block.chainid, address(weth)), amount);

        // Then withdraw it
        lendingPool.withdrawCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, block.chainid, address(weth)), 0);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_supply_liquidity
    function test_supply_liquidity() public {
        vm.startPrank(alice);
        uint256 amount = 1_000e6;
        IERC20(address(usdc)).approve(address(lendingPool), amount);
        lendingPool.supplyLiquidity(alice, address(usdc), amount);
        assertEq(lendingPool.userSupplyShares(alice, address(usdc)), amount);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdraw_liquidity
    function test_withdraw_liquidity() public {
        test_supply_liquidity();
        vm.startPrank(alice);
        uint256 shares = 1_000e6;
        lendingPool.withdrawLiquidity(alice, address(usdc), shares);
        assertEq(lendingPool.userSupplyShares(alice, address(usdc)), 0);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_borrow
    function test_borrow() public {
        test_supply_collateral();
        test_supply_liquidity();

        vm.startPrank(alice);
        uint256 amount = 500e6;
        lendingPool.borrow(alice, address(usdc), amount, block.chainid);
        assertEq(lendingPool.userBorrowShares(alice, block.chainid, address(usdc)), amount);
        vm.stopPrank();

        console.log("totalBorrowAssets(USDC)", lendingPool.totalBorrowAssets(address(usdc)));
        console.log("totalSupplyAssets(USDC)", lendingPool.totalSupplyAssets(address(usdc)));

        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest(address(usdc));

        console.log("totalBorrowAssets(USDC)", lendingPool.totalBorrowAssets(address(usdc)));
        console.log("totalSupplyAssets(USDC)", lendingPool.totalSupplyAssets(address(usdc)));
    }

    // RUN
    // forge test -vvv --match-test test_repay
    function test_repay() public {
        test_borrow();
        vm.startPrank(alice);
        uint256 shares = 500e6;
        uint256 amount =
            ((shares * lendingPool.totalBorrowAssets(address(usdc))) / lendingPool.totalBorrowShares(address(usdc)));

        IERC20(address(usdc)).approve(address(lendingPool), amount);

        lendingPool.repay(alice, address(usdc), shares);
        assertEq(lendingPool.userBorrowShares(alice, block.chainid, address(usdc)), 0);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_borrow_crosschain
    function test_borrow_crosschain() public {
        test_supply_collateral();
        test_supply_liquidity();
        vm.startPrank(alice);
        uint256 amount = 500e6;

        // TODO: HELPER GET FEE
        MessagingFee memory fee = IOAppBorrow(router.chainIdToOApp(block.chainid)).quoteSendString(
            uint32(router.chainIdToLzEid(42161)), amount, address(usdc), alice, "", false
        );
        console.log("fee", fee.nativeFee);

        lendingPool.borrow{value: fee.nativeFee}(alice, address(usdc), amount, 42161);
        assertEq(lendingPool.userBorrowShares(alice, 42161, address(usdc)), amount);
        vm.stopPrank();

        console.log("totalBorrowAssets(USDC)", lendingPool.totalBorrowAssets(address(usdc)));
        console.log("totalSupplyAssets(USDC)", lendingPool.totalSupplyAssets(address(usdc)));
    }
}
