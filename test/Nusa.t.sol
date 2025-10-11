// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Helper} from "../src/devtools/Helper.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Nusa is Test, Helper {
    USDC public usdc;
    WETH public weth;
    Router public router;
    IsHealthy public isHealthy;
    TokenDataStream public tokenDataStream;
    LendingPool public lendingPool;
    ERC1967Proxy public proxy;
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        vm.startPrank(owner);
        _deployMockToken();
        _deployNusaCore();
        _activateToken();
        deal(address(usdc), alice, 100_000e6);
        deal(address(weth), alice, 100_000e18);
        vm.stopPrank();
    }

    function _deployMockToken() internal {
        usdc = new USDC();
        weth = new WETH();
        tokenDataStream = new TokenDataStream();

        tokenDataStream.setTokenPriceFeed(address(usdc), address(BASE_USDC_USD));
        tokenDataStream.setTokenPriceFeed(address(weth), address(BASE_ETH_USD));
    }

    function _deployNusaCore() internal {
        router = new Router();

        isHealthy = new IsHealthy(address(router));

        lendingPool = new LendingPool();
        bytes memory data = abi.encodeWithSelector(lendingPool.initialize.selector);
        proxy = new ERC1967Proxy(address(lendingPool), data);
        lendingPool = LendingPool(address(proxy));
        lendingPool.setRouter(address(router));

        router.setTokenDataStream(address(tokenDataStream));
        router.setIsHealthy(address(isHealthy));
        router.setLendingPool(address(lendingPool));
    }

    function _activateToken() internal {
        lendingPool.setToken(address(weth), true);
        lendingPool.setToken(address(usdc), true);
        
        lendingPool.setBorrowLtv(address(weth), 0.8e18); // Set borrow LTV (80% = 0.8e18)
        lendingPool.setBorrowLtv(address(usdc), 0.8e18); // Set borrow LTV (80% = 0.8e18)
    }

    // RUN
    // forge test -vvv --match-test test_setChainId
    // function test_setChainId() public {
    //     vm.startPrank(owner);
    //     lendingPool.setChainId(8453);
    //     vm.stopPrank();
    // }

    // RUN
    // forge test -vvv --match-test test_supplyCollateral
    function test_supplyCollateral() public {
        vm.startPrank(alice);
        uint256 amount = 1_000e18;
        IERC20(address(weth)).approve(address(lendingPool), amount);
        lendingPool.supplyCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, address(weth)), amount);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdrawCollateral
    function test_withdrawCollateral() public {
        vm.startPrank(alice);
        uint256 amount = 1_000e18;
        
        // First supply collateral
        IERC20(address(weth)).approve(address(lendingPool), amount);
        lendingPool.supplyCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, address(weth)), amount);
        
        // Then withdraw it
        lendingPool.withdrawCollateral(alice, address(weth), amount);
        assertEq(lendingPool.userCollateral(alice, address(weth)), 0);
        vm.stopPrank();
    }
}
