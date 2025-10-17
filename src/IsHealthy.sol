// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {ITokenDataStream} from "./interfaces/ITokenDataStream.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract IsHealthy is Ownable {
    error InsufficientCollateral(uint256 borrowValue, uint256 collateralValue, uint256 maxBorrow);
    error InvalidLtv(uint256 ltv);

    address public router;

    constructor(address _router) Ownable(msg.sender) {
        router = _router;
    }

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }

    function isHealthy(
        uint256 ltv,
        address user,
        address borrowToken,
        address[] memory tokens,
        uint256[] memory chainIds,
        uint256 totalBorrowAssets,
        uint256 totalBorrowShares,
        uint256 userBorrowShares,
        address lendingPool
    ) public view {
        if (ltv == 0) revert InvalidLtv(ltv);
        
        // If user has no borrows, they're always healthy
        if (userBorrowShares == 0 || totalBorrowShares == 0) {
            return;
        }
        
        (, uint256 borrowPrice,,,) = ITokenDataStream(IRouter(router).tokenDataStream()).latestRoundData(borrowToken);
        uint256 collateralValue = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token != address(0) && ILendingPool(lendingPool).tokenActive(token)) {
                uint256 userCollateralAmount = _userCollateralAmount(user, tokens[i]);
                uint256 collateralAdjustedPrice =
                    _userCollateralPrice(tokens[i]) * 1e18 / 10 ** _oracleDecimal(tokens[i]);
                uint256 userCollateralValue =
                    userCollateralAmount * collateralAdjustedPrice / (10 ** _tokenDecimals(tokens[i]));
                collateralValue += userCollateralValue;
            }
        }
        uint256 borrowed = (userBorrowShares * totalBorrowAssets) / totalBorrowShares;
        uint256 borrowAdjustedPrice = uint256(borrowPrice) * 1e18 / 10 ** _oracleDecimal(borrowToken);
        uint256 borrowValue = (borrowed * borrowAdjustedPrice) / (10 ** _tokenDecimals(borrowToken));

        uint256 maxBorrow = (collateralValue * ltv) / 1e18;

        bool isLiquidatable = (borrowValue > collateralValue) || (borrowValue > maxBorrow);

        if (isLiquidatable) {
            revert InsufficientCollateral(borrowValue, collateralValue, maxBorrow);
        }
    }

    function _userCollateralAmount(address _user, address _token) internal view returns (uint256) {
        return ILendingPool(IRouter(router).lendingPool()).userCollateral(_user, _token);
    }

    function _userCollateralPrice(address _token) internal view returns (uint256) {
        (, uint256 price,,,) = ITokenDataStream(IRouter(router).tokenDataStream()).latestRoundData(_token);
        return price;
    }

    function _oracleDecimal(address _token) internal view returns (uint256) {
        return ITokenDataStream(IRouter(router).tokenDataStream()).decimals(_token);
    }

    function _tokenDecimals(address _token) internal view returns (uint256) {
        return IERC20Metadata(_token).decimals();
    }
}
