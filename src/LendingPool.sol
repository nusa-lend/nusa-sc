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

/**
 * @title LendingPool
 * @author Nusa Protocol Team
 * @notice Core lending pool contract that manages cross-chain borrowing and lending operations
 * @dev This contract is upgradeable and uses OpenZeppelin's upgradeable contracts.
 *      It implements a lending pool with collateral-based borrowing, cross-chain functionality via LayerZero,
 *      and dynamic interest rate calculations based on utilization rates.
 * 
 * Key Features:
 * - Cross-chain borrowing and lending via LayerZero
 * - Collateral-based lending with configurable LTV ratios
 * - Dynamic interest rates based on utilization
 * - Share-based accounting for deposits and borrows
 * - Role-based access control for administrative functions
 * - Pausable operations for emergency situations
 */
contract LendingPool is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when attempting to add a chain ID that already exists
    /// @param _chainId The chain ID that already exists
    error ChainIdExist(uint256 _chainId);

    /// @notice Thrown when attempting to add a token that already exists
    /// @param _token The token address that already exists
    error TokenExist(address _token);

    /// @notice Thrown when a token's data stream (price feed) is not set
    /// @param _token The token address that doesn't have a data stream set
    error TokenDataStreamNotSet(address _token);

    /// @notice Thrown when user has insufficient collateral for withdrawal
    /// @param _token The collateral token address
    /// @param _amount The amount being withdrawn
    /// @param _userCollateralBalance The user's actual collateral balance
    error InsufficientCollateral(address _token, uint256 _amount, uint256 _userCollateralBalance);

    /// @notice Thrown when pool has insufficient liquidity for withdrawal or borrow
    /// @param _token The token address
    /// @param _amount The amount being requested
    /// @param _totalSupplyAssets The total supply assets available
    error InsufficientLiquidity(address _token, uint256 _amount, uint256 _totalSupplyAssets);

    /// @notice Thrown when user attempts to withdraw more shares than they own
    /// @param _token The token address
    /// @param _shares The shares being withdrawn
    /// @param _userSupplyShares The user's actual share balance
    error InvalidShares(address _token, uint256 _shares, uint256 _userSupplyShares);

    /// @notice Thrown when a zero amount is provided for operations that require non-zero amounts
    error ZeroAmount();

    /// @notice Thrown when attempting to use a token that is not active
    /// @param _token The inactive token address
    error TokenNotActive(address _token);

    /// @notice Thrown when user access control validation fails
    /// @param _sender The sender address
    /// @param _user The user address being accessed
    error UserAccessControl(address _sender, address _user);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Role identifier for accounts that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for accounts that can upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Role identifier for accounts that have owner privileges
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Array of supported chain IDs for cross-chain operations
    uint256[] public chainIds;

    /// @notice Array of supported token addresses
    address[] public tokens;

    /// @notice Address of the Router contract that manages cross-chain configurations
    address public router;

    /// @notice Mapping of addresses authorized to perform operations on behalf of users
    /// @dev operator address => authorization status
    mapping(address => bool) public operator;

    /// @notice Mapping to track which tokens are currently active for operations
    /// @dev token address => active status
    mapping(address => bool) public tokenActive;

    /// @notice Total collateral deposited for each token across all users
    /// @dev token address => total collateral amount
    mapping(address => uint256) public totalCollateral;

    /// @notice User collateral balances by user, chain ID, and token
    /// @dev user address => chain ID => token address => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public userCollateral;

    /// @notice Total assets supplied to the pool for each token (for lending)
    /// @dev token address => total supply assets amount
    mapping(address => uint256) public totalSupplyAssets;

    /// @notice Total shares issued for supplied assets for each token
    /// @dev token address => total supply shares
    mapping(address => uint256) public totalSupplyShares;

    /// @notice User shares for supplied assets by user and token
    /// @dev user address => token address => shares amount
    mapping(address => mapping(address => uint256)) public userSupplyShares;

    /// @notice Total assets borrowed from the pool for each token
    /// @dev token address => total borrow assets amount
    mapping(address => uint256) public totalBorrowAssets;

    /// @notice Total shares issued for borrowed assets for each token
    /// @dev token address => total borrow shares
    mapping(address => uint256) public totalBorrowShares;

    /// @notice User shares for borrowed assets by user, chain ID, and token
    /// @dev user address => chain ID => token address => shares amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public userBorrowShares;

    /// @notice Loan-to-value ratio for each token (with 18 decimals precision)
    /// @dev token address => LTV ratio
    mapping(address => uint256) public borrowLtv;

    /// @notice Timestamp of last interest accrual for each token
    /// @dev token address => timestamp
    mapping(address => uint256) public lastAccrued;

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when an operator's authorization status is updated
    /// @param operator The operator address
    /// @param status The new authorization status
    event OperatorSet(address indexed operator, bool status);

    /// @notice Emitted when a user supplies collateral to the pool
    /// @param user The user supplying collateral
    /// @param token The token address being supplied as collateral
    /// @param amount The amount of collateral supplied
    event SupplyCollateral(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws collateral from the pool
    /// @param user The user withdrawing collateral
    /// @param token The token address being withdrawn
    /// @param amount The amount of collateral withdrawn
    event WithdrawCollateral(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user supplies liquidity to the pool for lending
    /// @param user The user supplying liquidity
    /// @param token The token address being supplied
    /// @param amount The amount of liquidity supplied
    event SupplyLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws liquidity from the pool
    /// @param user The user withdrawing liquidity
    /// @param token The token address being withdrawn
    /// @param amount The amount of liquidity withdrawn
    event WithdrawLiquidity(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a user borrows tokens from the pool (potentially cross-chain)
    /// @param user The user borrowing tokens
    /// @param token The token address being borrowed
    /// @param amount The amount being borrowed
    /// @param chainDst The destination chain ID where tokens will be sent
    event Borrow(address indexed user, address indexed token, uint256 amount, uint256 chainDst);

    /// @notice Emitted when a user repays borrowed tokens
    /// @param user The user repaying tokens
    /// @param token The token address being repaid
    /// @param amount The amount being repaid
    event Repay(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a new chain ID is added to supported chains
    /// @param chainId The chain ID that was added
    event ChainIdSet(uint256 chainId);

    /// @notice Emitted when a token's active status is updated
    /// @param token The token address
    /// @param active The new active status
    event TokenSet(address token, bool active);

    /// @notice Emitted when the router address is updated
    /// @param router The new router address
    event RouterSet(address router);

    /// @notice Emitted when a token's borrow LTV ratio is updated
    /// @param token The token address
    /// @param ltv The new LTV ratio (with 18 decimals precision)
    event BorrowLtvSet(address indexed token, uint256 ltv);

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    /// @notice Ensures the token has a valid data stream (price feed) configured
    /// @param _token The token address to check
    modifier checkTokenDataStream(address _token) {
        _checkTokenDataStream(_token);
        _;
    }

    /// @notice Ensures the token is currently active for operations
    /// @param _token The token address to check
    modifier isTokenActive(address _token) {
        _isTokenActive(_token);
        _;
    }

    /// @notice Validates user access control permissions
    /// @param _user The user address to validate access for
    modifier userAccessControl(address _user) {
        _userAccessControl(_user);
        _;
    }

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Contract constructor that disables initializers for the implementation contract
    /// @dev This prevents the implementation contract from being initialized directly
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the upgradeable contract with default settings and roles
    /// @dev This function replaces the constructor for upgradeable contracts.
    ///      It sets up all the inherited contracts and grants initial roles to the deployer.
    ///      The current chain ID is automatically added to the supported chains list.
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

    // =============================================================
    //                       CORE FUNCTIONS
    // =============================================================

    /// @notice Supplies collateral tokens to the pool on behalf of a user
    /// @dev Collateral can be used to secure borrowing positions.
    ///      Interest is accrued before updating balances to ensure accurate accounting.
    /// @param _user The user account that will own the collateral
    /// @param _token The ERC20 token address to supply as collateral
    /// @param _amount The amount of tokens to supply as collateral
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

    /// @notice Withdraws collateral tokens from the pool for a user
    /// @dev Validates that the user has sufficient collateral before withdrawal.
    ///      Interest is accrued before updating balances. Health check is currently commented out.
    /// @param _user The user account to withdraw collateral for
    /// @param _token The ERC20 token address to withdraw as collateral
    /// @param _amount The amount of tokens to withdraw
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

    /// @notice Supplies liquidity tokens to the pool for lending on behalf of a user
    /// @dev Uses a share-based system where shares represent proportional ownership of the pool.
    ///      If this is the first deposit, shares equal the amount. Otherwise, shares are calculated
    ///      proportionally based on existing pool size. Interest is accrued before calculations.
    /// @param _user The user account that will own the liquidity shares
    /// @param _token The ERC20 token address to supply as liquidity
    /// @param _amount The amount of tokens to supply as liquidity (must be > 0)
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

    /// @notice Withdraws liquidity from the pool by burning shares and receiving underlying tokens
    /// @dev Converts shares back to tokens based on current pool ratio. Ensures sufficient liquidity
    ///      remains to cover outstanding borrows. Interest is accrued before calculations.
    /// @param _user The user account to withdraw liquidity for
    /// @param _token The ERC20 token address to withdraw
    /// @param _shares The number of shares to burn for withdrawal (must be > 0)
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

    /// @notice Borrows tokens from the pool, potentially cross-chain via LayerZero
    /// @dev Supports both same-chain and cross-chain borrowing. For cross-chain borrows,
    ///      uses LayerZero's OApp to send tokens to the destination chain.
    ///      Interest is accrued before borrowing. Health checks are currently commented out.
    /// @param _user The user account that will receive the borrowed tokens
    /// @param _token The ERC20 token address to borrow
    /// @param _amount The amount of tokens to borrow (must be > 0)
    /// @param _chainDst The destination chain ID where tokens should be sent
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

    /// @notice Repays borrowed tokens by burning borrow shares
    /// @dev Converts shares to token amount based on current borrow pool ratio.
    ///      Interest is accrued before calculations to ensure accurate repayment amounts.
    /// @param _user The user account repaying the borrowed tokens
    /// @param _token The ERC20 token address being repaid
    /// @param _shares The number of borrow shares to burn for repayment (must be > 0)
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

    // =============================================================
    //                    ADMINISTRATIVE FUNCTIONS
    // =============================================================

    /// @notice Sets or revokes operator privileges for an address
    /// @dev Operators can perform actions on behalf of users. Only OWNER_ROLE can call this.
    /// @param _operator The address to grant or revoke operator privileges
    /// @param _status True to grant operator privileges, false to revoke
    function setOperator(address _operator, bool _status) public onlyRole(OWNER_ROLE) {
        operator[_operator] = _status;
        emit OperatorSet(_operator, _status);
    }

    /// @notice Adds a new chain ID to the list of supported chains for cross-chain operations
    /// @dev Prevents adding duplicate chain IDs. Only OWNER_ROLE can call this.
    /// @param _chainId The chain ID to add to the supported chains list
    function setChainId(uint256 _chainId) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == _chainId) {
                revert ChainIdExist(_chainId);
            }
        }

        chainIds.push(_chainId);
        emit ChainIdSet(_chainId);
    }

    /// @notice Adds or removes a token from the supported tokens list
    /// @dev When adding a token (_active = true), initializes its lastAccrued timestamp.
    ///      When removing a token (_active = false), removes it from the tokens array.
    ///      Only OWNER_ROLE can call this.
    /// @param _token The token address to add or remove
    /// @param _active True to add the token, false to remove it
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

    /// @notice Sets the active status of a token for pool operations
    /// @dev This controls whether a token can be used for borrowing, lending, etc.
    ///      Only OWNER_ROLE can call this.
    /// @param _token The token address to update
    /// @param _active True to activate the token, false to deactivate
    function setTokenActive(address _token, bool _active) public onlyRole(OWNER_ROLE) {
        tokenActive[_token] = _active;
        emit TokenSet(_token, _active);
    }

    // =============================================================
    //                    INTEREST CALCULATION
    // =============================================================

    /// @notice Accrues interest for a token based on elapsed time and current borrow rate
    /// @dev Calculates interest based on total borrowed assets and time elapsed since last accrual.
    ///      Interest is added to both supply and borrow totals. Updates lastAccrued timestamp.
    /// @param _token The token address to accrue interest for
    function accrueInterest(address _token) public checkTokenDataStream(_token) isTokenActive(_token) {
        uint256 borrowRate = calculateBorrowRate(_token);

        uint256 interestPerYear = (totalBorrowAssets[_token] * borrowRate) / 10000; // borrowRate is scaled by 100
        uint256 elapsedTime = block.timestamp - lastAccrued[_token];
        uint256 interest = (interestPerYear * elapsedTime) / 365 days;

        totalSupplyAssets[_token] += interest;
        totalBorrowAssets[_token] += interest;
        lastAccrued[_token] = block.timestamp;
    }

    /// @notice Calculates the current borrow rate based on utilization
    /// @dev Uses a two-slope interest rate model:
    ///      - Base rate to optimal utilization: linear increase from 5% to 10%
    ///      - Above optimal utilization: sharp increase from 10% to 100%
    ///      - Optimal utilization is set at 75%
    ///      - Returns 5% base rate when no supply exists
    /// @param _token The token address to calculate borrow rate for
    /// @return borrowRate The annual borrow rate scaled by 100 (e.g., 500 = 5%)
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

    /// @notice Sets the router contract address
    /// @dev The router manages cross-chain configurations and token mappings.
    ///      Only OWNER_ROLE can call this.
    /// @param _router The new router contract address
    function setRouter(address _router) public onlyRole(OWNER_ROLE) {
        router = _router;
        emit RouterSet(_router);
    }

    /// @notice Sets the loan-to-value ratio for a token
    /// @dev The LTV ratio determines how much can be borrowed against collateral.
    ///      Uses 18 decimal precision. Only OWNER_ROLE can call this.
    /// @param _token The token address to set LTV for
    /// @param _ltv The LTV ratio with 18 decimal precision (e.g., 0.75e18 = 75%)
    function setBorrowLtv(address _token, uint256 _ltv)
        public
        checkTokenDataStream(_token)
        isTokenActive(_token)
        onlyRole(OWNER_ROLE)
    {
        borrowLtv[_token] = _ltv; // 18 decimals
        emit BorrowLtvSet(_token, _ltv);
    }

    // =============================================================
    //                    INTERNAL HELPER FUNCTIONS
    // =============================================================

    /// @notice Internal function to validate that a token has a configured price feed
    /// @dev Checks if the token has a price feed set in the TokenDataStream contract
    /// @param _token The token address to validate
    function _checkTokenDataStream(address _token) internal view {
        if (ITokenDataStream(IRouter(router).tokenDataStream()).tokenPriceFeed(_token) == address(0)) {
            revert TokenDataStreamNotSet(_token);
        }
    }

    /// @notice Internal function to validate that a token is active for operations
    /// @dev Reverts if the token is not marked as active
    /// @param _token The token address to validate
    function _isTokenActive(address _token) internal view {
        if (!tokenActive[_token]) revert TokenNotActive(_token);
    }

    /// @notice Internal function for user access control validation
    /// @dev Currently commented out - would validate that msg.sender has permission
    ///      to act on behalf of the specified user
    /// @param _user The user address to validate access for
    function _userAccessControl(address _user) internal view {
        // if (msg.sender == _oapp(block.chainid)) return;
        // if (msg.sender != _user) revert UserAccessControl(msg.sender, _user);
    }

    /// @notice Internal function to handle borrow logic and share calculation
    /// @dev Calculates borrow shares based on current pool ratio, updates user and total balances.
    ///      Validates sufficient liquidity exists. Health check is currently commented out.
    /// @param _user The user address borrowing tokens
    /// @param _token The token address being borrowed
    /// @param _amount The amount of tokens to borrow
    /// @param _chainDst The destination chain ID for the borrow position
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

    /// @notice Internal function to get the OApp address for a specific chain ID
    /// @dev Retrieves the LayerZero OApp contract address from the router
    /// @param _chainId The chain ID to get the OApp address for
    /// @return The OApp contract address for the specified chain
    function _oapp(uint256 _chainId) internal view returns (address) {
        return IRouter(router).chainIdToOApp(_chainId);
    }

    /// @notice Internal function to get the LayerZero endpoint ID for a chain ID
    /// @dev Retrieves the LayerZero endpoint ID from the router
    /// @param _chainId The chain ID to get the endpoint ID for
    /// @return The LayerZero endpoint ID for the specified chain
    function _endPointId(uint256 _chainId) internal view returns (uint256) {
        return IRouter(router).chainIdToLzEid(_chainId);
    }

    /// @notice Internal function to get the corresponding token address on another chain
    /// @dev Retrieves the cross-chain token mapping from the router
    /// @param _token The token address on the current chain
    /// @param _chainDst The destination chain ID
    /// @return The corresponding token address on the destination chain
    function _getCrosschainToken(address _token, uint256 _chainDst) internal view returns (address) {
        return IRouter(router).crosschainTokenByChainId(_token, _chainDst);
    }

    // =============================================================
    //                    EMERGENCY & UPGRADE FUNCTIONS
    // =============================================================

    /// @notice Pauses all contract operations
    /// @dev Only accounts with PAUSER_ROLE can call this function.
    ///      When paused, most contract functions will revert.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all contract operations
    /// @dev Only accounts with PAUSER_ROLE can call this function.
    ///      Resumes normal contract functionality.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Authorizes contract upgrades
    /// @dev Only accounts with UPGRADER_ROLE can authorize upgrades.
    ///      This is required by the UUPSUpgradeable pattern.
    /// @param newImplementation The address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /// @notice Receives Ether sent to the contract
    /// @dev Required for cross-chain operations that may involve native token transfers
    receive() external payable {}

    /// @notice Fallback function for any calls with invalid function signatures
    /// @dev Required for cross-chain operations that may involve native token transfers
    fallback() external payable {}
}
