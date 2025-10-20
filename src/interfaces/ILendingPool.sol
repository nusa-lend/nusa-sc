// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPool {
    // View functions
    function totalBorrowAssets(address _token) external view returns (uint256);
    function totalBorrowShares(address _token) external view returns (uint256);
    function userCollateral(address _user, uint256 _chainId, address _token) external view returns (uint256);
    function tokenActive(address _token) external view returns (bool);
    function totalCollateral(address _token) external view returns (uint256);
    function totalSupplyAssets(address _token) external view returns (uint256);
    function totalSupplyShares(address _token) external view returns (uint256);
    function userSupplyShares(address _user, address _token) external view returns (uint256);
    function userBorrowShares(address _user, uint256 _chainId, address _token) external view returns (uint256);
    function borrowLtv(address _token) external view returns (uint256);
    function lastAccrued(address _token) external view returns (uint256);
    function operator(address _operator) external view returns (bool);
    function router() external view returns (address);
    function chainIds(uint256 _index) external view returns (uint256);
    function tokens(uint256 _index) external view returns (address);
    
    // Core lending functions
    function borrow(address _user, address _token, uint256 _amount, uint256 _chainDst) external payable;
    function repay(address _user, address _token, uint256 _shares) external;
    function supplyCollateral(address _user, address _token, uint256 _amount) external;
    function supplyLiquidity(address _user, address _token, uint256 _amount) external;
    function withdrawCollateral(address _user, address _token, uint256 _amount) external;
    function withdrawLiquidity(address _user, address _token, uint256 _shares) external;
    
    // Interest calculation functions
    function accrueInterest(address _token) external;
    function calculateBorrowRate(address _token) external view returns (uint256);
    
    // Admin functions
    function setOperator(address _operator, bool _status) external;
    function setChainId(uint256 _chainId) external;
    function setToken(address _token, bool _active) external;
    function setTokenActive(address _token, bool _active) external;
    function setRouter(address _router) external;
    function setBorrowLtv(address _token, uint256 _ltv) external;
    function pause() external;
    function unpause() external;
    
    // Access control functions
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    
    // Upgrade functions
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    
    // Events
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
}