// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenDataStream} from "./interfaces/ITokenDataStream.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IIsHealthy} from "./interfaces/IIsHealthy.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IOAppBorrow} from "./interfaces/IOAppBorrow.sol";

contract LendingPool is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    error ChainIdExist(uint256 _chainId);
    error TokenExist(address _token);
    error TokenDataStreamNotSet(address _token);
    error InsufficientCollateral(address _token, uint256 _amount, uint256 _userCollateralBalance);
    error InsufficientLiquidity(address _token, uint256 _amount, uint256 _totalSupplyAssets);
    error InvalidShares(address _token, uint256 _shares, uint256 _userSupplyShares);
    error ZeroAmount();
    error TokenNotActive(address _token);
    error UserAccessControl(address _sender, address _user);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256[] public chainIds;
    address[] public tokens;

    address public router;

    mapping(address => bool) public operator;
    mapping(address => bool) public tokenActive;
    mapping(address => uint256) public totalCollateral;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public userCollateral; // user => chainid => token => amount

    mapping(address => uint256) public totalSupplyAssets;
    mapping(address => uint256) public totalSupplyShares;
    mapping(address => mapping(address => uint256)) public userSupplyShares; // user => token => shares

    mapping(address => uint256) public totalBorrowAssets;
    mapping(address => uint256) public totalBorrowShares;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public userBorrowShares; // user => chainid => token => shares

    mapping(address => uint256) public borrowLtv;
    mapping(address => uint256) public lastAccrued;

    event OperatorSet(address indexed operator, bool status);
    event SupplyCollateral(address indexed user, address indexed token, uint256 amount);
    event WithdrawCollateral(address indexed user, address indexed token, uint256 amount);
    event SupplyLiquidity(address indexed user, address indexed token, uint256 amount);
    event WithdrawLiquidity(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, address indexed token, uint256 amount, uint256 chainDst);
    event Repay(address indexed user, address indexed token, uint256 amount);
    event ChainIdSet(uint256 chainId);
    event TokenSet(address token, bool active);
    event RouterSet(address router);
    event BorrowLtvSet(address indexed token, uint256 ltv);

    modifier checkTokenDataStream(address _token) {
        _checkTokenDataStream(_token);
        _;
    }

    modifier isTokenActive(address _token) {
        _isTokenActive(_token);
        _;
    }

    modifier userAccessControl(address _user) {
        _userAccessControl(_user);
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);

        chainIds.push(block.chainid);
    }

    function supplyCollateral(address _user, address _token, uint256 _amount)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        nonReentrant
    {
        accrueInterest(_token);
        totalCollateral[_token] += _amount;
        userCollateral[_user][block.chainid][_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit SupplyCollateral(_user, _token, _amount);
    }

    function withdrawCollateral(address _user, address _token, uint256 _amount)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        nonReentrant
    {
        if (_amount > userCollateral[_user][block.chainid][_token]) {
            revert InsufficientCollateral(_token, _amount, userCollateral[_user][block.chainid][_token]);
        }

        accrueInterest(_token);

        totalCollateral[_token] -= _amount;
        userCollateral[_user][block.chainid][_token] -= _amount;

        // IIsHealthy(IRouter(router).isHealthy()).isHealthy(borrowLtv[_token],_user,tokens,_token,totalBorrowAssets[_token],totalBorrowShares[_token],userBorrowShares[_user][_token]);

        IERC20(_token).safeTransfer(_user, _amount);

        emit WithdrawCollateral(_user, _token, _amount);
    }

    function supplyLiquidity(address _user, address _token, uint256 _amount)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        nonReentrant
    {
        if (_amount == 0) revert ZeroAmount();
        accrueInterest(_token);
        uint256 shares = 0;
        if (totalSupplyAssets[_token] == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupplyShares[_token]) / totalSupplyAssets[_token];
        }
        userSupplyShares[_user][_token] += shares;
        totalSupplyShares[_token] += shares;
        totalSupplyAssets[_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit SupplyLiquidity(_user, _token, _amount);
    }

    function withdrawLiquidity(address _user, address _token, uint256 _shares)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        nonReentrant
    {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userSupplyShares[_user][_token]) {
            revert InvalidShares(_token, _shares, userSupplyShares[_user][_token]);
        }

        accrueInterest(_token);

        uint256 amount = ((_shares * totalSupplyAssets[_token]) / totalSupplyShares[_token]);
        if (totalSupplyAssets[_token] - amount < totalBorrowAssets[_token]) {
            revert InsufficientLiquidity(_token, amount, totalSupplyAssets[_token]);
        }

        userSupplyShares[_user][_token] -= _shares;
        totalSupplyShares[_token] -= _shares;
        totalSupplyAssets[_token] -= amount;

        IERC20(_token).safeTransfer(_user, amount);
        emit WithdrawLiquidity(_user, _token, amount);
    }

    function borrow(address _user, address _token, uint256 _amount, uint256 _chainDst)
        public
        payable
        checkTokenDataStream(_token)
        isTokenActive(_token)
        userAccessControl(_user)
        nonReentrant
    {
        if (_amount == 0) revert ZeroAmount();
        accrueInterest(_token);
        _borrow(_user, _token, _amount, _chainDst);
        if (msg.sender == _oapp(block.chainid)) {
            IERC20(_token).safeTransfer(_user, _amount);
        } else if (_chainDst == block.chainid) {
            IERC20(_token).safeTransfer(_user, _amount);
        } else {
            bytes memory options = "";
            IOAppBorrow(_oapp(block.chainid)).sendString{value: msg.value}(
                uint32(_endPointId(_chainDst)), _amount, _token, _user, options
            );
        }
        emit Borrow(_user, _token, _amount, _chainDst);
    }

    function repay(address _user, address _token, uint256 _shares)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        nonReentrant
    {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > userBorrowShares[_user][block.chainid][_token]) {
            revert InvalidShares(_token, _shares, userBorrowShares[_user][block.chainid][_token]);
        }
        accrueInterest(_token);
        uint256 amount = ((_shares * totalBorrowAssets[_token]) / totalBorrowShares[_token]);

        userBorrowShares[_user][block.chainid][_token] -= _shares;
        totalBorrowShares[_token] -= _shares;
        totalBorrowAssets[_token] -= amount;

        IERC20(_token).safeTransferFrom(_user, address(this), amount);
        emit Repay(_user, _token, amount);
    }

    function setOperator(address _operator, bool _status) public onlyRole(OWNER_ROLE) {
        operator[_operator] = _status;
        emit OperatorSet(_operator, _status);
    }

    function setChainId(uint256 _chainId) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == _chainId) {
                revert ChainIdExist(_chainId);
            }
        }

        chainIds.push(_chainId);
        emit ChainIdSet(_chainId);
    }

    function setToken(address _token, bool _active) public onlyRole(OWNER_ROLE) {
        if (_active) {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (tokens[i] == _token) {
                    revert TokenExist(_token);
                }
            }

            tokens.push(_token);
            lastAccrued[_token] = block.timestamp;
        } else {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (tokens[i] == _token) {
                    tokens[i] = tokens[tokens.length - 1];
                    tokens.pop();
                    break;
                }
            }
        }
        emit TokenSet(_token, _active);
    }

    function setTokenActive(address _token, bool _active) public onlyRole(OWNER_ROLE) {
        tokenActive[_token] = _active;
        emit TokenSet(_token, _active);
    }

    function accrueInterest(address _token) public checkTokenDataStream(_token) isTokenActive(_token) {
        uint256 borrowRate = calculateBorrowRate(_token);

        uint256 interestPerYear = (totalBorrowAssets[_token] * borrowRate) / 10000; // borrowRate is scaled by 100
        uint256 elapsedTime = block.timestamp - lastAccrued[_token];
        uint256 interest = (interestPerYear * elapsedTime) / 365 days;

        totalSupplyAssets[_token] += interest;
        totalBorrowAssets[_token] += interest;
        lastAccrued[_token] = block.timestamp;
    }

    function calculateBorrowRate(address _token) public view returns (uint256 borrowRate) {
        if (totalSupplyAssets[_token] == 0) {
            return 500; // 5% base rate when no supply (scaled by 100)
        }

        // Calculate utilization rate (scaled by 10000 for precision)
        uint256 utilizationRate = (totalBorrowAssets[_token] * 10000) / totalSupplyAssets[_token];

        // Interest rate model parameters
        uint256 baseRate = 500; // 5% base rate (scaled by 100)
        uint256 optimalUtilization = 7500; // 75% optimal utilization (scaled by 10000)
        uint256 rateAtOptimal = 1000; // 10% rate at optimal utilization (scaled by 100)
        uint256 maxRate = 10000; // 100% maximum rate (scaled by 100)

        if (utilizationRate <= optimalUtilization) {
            // Linear increase from base rate to optimal rate
            borrowRate = baseRate + ((utilizationRate * (rateAtOptimal - baseRate)) / optimalUtilization);
        } else {
            // Sharp increase after optimal utilization to discourage over-borrowing
            uint256 excessUtilization = utilizationRate - optimalUtilization;
            uint256 maxExcessUtilization = 10000 - optimalUtilization; // 25% (scaled by 10000)

            // Rate = rateAtOptimal + (excessUtilization * (maxRate - rateAtOptimal)) / maxExcessUtilization
            borrowRate = rateAtOptimal + ((excessUtilization * (maxRate - rateAtOptimal)) / maxExcessUtilization);
        }

        return borrowRate;
    }

    function setRouter(address _router) public onlyRole(OWNER_ROLE) {
        router = _router;
        emit RouterSet(_router);
    }

    function setBorrowLtv(address _token, uint256 _ltv)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        onlyRole(OWNER_ROLE)
    {
        borrowLtv[_token] = _ltv; // 18 decimals
        emit BorrowLtvSet(_token, _ltv);
    }

    function _checkTokenDataStream(address _token) internal view {
        if (ITokenDataStream(IRouter(router).tokenDataStream()).tokenPriceFeed(_token) == address(0)) {
            revert TokenDataStreamNotSet(_token);
        }
    }

    function _isTokenActive(address _token) internal view {
        if (!tokenActive[_token]) revert TokenNotActive(_token);
    }

    function _userAccessControl(address _user) internal view {
        // if (msg.sender == _oapp(block.chainid)) return;
        // if (msg.sender != _user) revert UserAccessControl(msg.sender, _user);
    }

    function _borrow(address _user, address _token, uint256 _amount, uint256 _chainDst) internal {
        uint256 shares = 0;
        if (totalBorrowShares[_token] == 0) {
            shares = _amount;
        } else {
            shares = ((_amount * totalBorrowShares[_token]) / totalBorrowAssets[_token]);
        }
        userBorrowShares[_user][_chainDst][_token] += shares;
        totalBorrowShares[_token] += shares;
        totalBorrowAssets[_token] += _amount;
        if (totalBorrowAssets[_token] > totalSupplyAssets[_token]) {
            revert InsufficientLiquidity(_token, _amount, totalSupplyAssets[_token]);
        }
        // IIsHealthy(IRouter(router).isHealthy()).isHealthy(borrowLtv[_token],_user,tokens,_token,totalBorrowAssets[_token],totalBorrowShares[_token],userBorrowShares[_user][_chainDst][_token]);
    }

    function _oapp(uint256 _chainId) internal view returns (address) {
        return IRouter(router).chainIdToOApp(_chainId);
    }

    function _endPointId(uint256 _chainId) internal view returns (uint256) {
        return IRouter(router).chainIdToLzEid(_chainId);
    }

    function _getCrosschainToken(address _token, uint256 _chainDst) internal view returns (address) {
        return IRouter(router).crosschainTokenByChainId(_token, _chainDst);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    receive() external payable {}
    fallback() external payable {}
}
