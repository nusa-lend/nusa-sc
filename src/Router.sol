// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Router
 * @author Nusa Protocol Team
 * @notice Central routing contract that manages cross-chain configurations and token mappings
 * @dev This contract serves as a configuration hub for cross-chain operations, maintaining
 *      mappings between chain IDs, LayerZero endpoint IDs, OApp contracts, and token addresses.
 *      It provides a centralized way to manage cross-chain infrastructure without hardcoding
 *      addresses in the main lending contracts.
 * 
 * Key Features:
 * - Chain ID to LayerZero endpoint ID mappings
 * - Chain ID to OApp contract address mappings  
 * - Cross-chain token address mappings
 * - References to core protocol contracts (TokenDataStream, IsHealthy, LendingPool)
 */
contract Router is Ownable {
    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Address of the TokenDataStream contract that manages price feeds
    address public tokenDataStream;

    /// @notice Address of the IsHealthy contract that validates borrowing positions
    address public isHealthy;

    /// @notice Address of the main LendingPool contract
    address public lendingPool;

    /// @notice Maps chain IDs to their corresponding LayerZero endpoint IDs
    /// @dev chain ID => LayerZero endpoint ID
    mapping(uint256 => uint256) public chainIdToLzEid;

    /// @notice Maps chain IDs to their corresponding OApp contract addresses
    /// @dev chain ID => OApp contract address
    mapping(uint256 => address) public chainIdToOApp;

    /// @notice Maps tokens to their corresponding addresses on other chains by chain ID
    /// @dev local token address => destination chain ID => remote token address
    mapping(address => mapping(uint256 => address)) public crosschainTokenByChainId;

    /// @notice Maps tokens to their corresponding addresses on other chains by LayerZero endpoint ID
    /// @dev local token address => LayerZero endpoint ID => remote token address
    mapping(address => mapping(uint256 => address)) public crosschainTokenByLzEid;
    
    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when attempting to set cross-chain token mapping for a chain without LayerZero endpoint ID
    /// @param chainId The chain ID that doesn't have an endpoint ID set
    /// @param lzEid The LayerZero endpoint ID (should be 0 when this error is thrown)
    error LzEidNotSet(uint256 chainId, uint256 lzEid);

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when the TokenDataStream contract address is updated
    /// @param tokenDataStream The new TokenDataStream contract address
    event TokenDataStreamSet(address tokenDataStream);

    /// @notice Emitted when the IsHealthy contract address is updated
    /// @param isHealthy The new IsHealthy contract address
    event IsHealthySet(address isHealthy);

    /// @notice Emitted when the LendingPool contract address is updated
    /// @param lendingPool The new LendingPool contract address
    event LendingPoolSet(address lendingPool);

    /// @notice Emitted when a chain ID to LayerZero endpoint ID mapping is set
    /// @param chainId The chain ID
    /// @param lzEid The LayerZero endpoint ID
    event ChainIdToLzEidSet(uint256 chainId, uint256 lzEid);

    /// @notice Emitted when a chain ID to OApp contract mapping is set
    /// @param chainId The chain ID
    /// @param oApp The OApp contract address
    event ChainIdToOAppSet(uint256 chainId, address oApp);

    /// @notice Emitted when a cross-chain token mapping is set
    /// @param token The local token address
    /// @param chainDst The destination chain ID
    /// @param lzEid The LayerZero endpoint ID
    /// @param crosschainToken The corresponding token address on the destination chain
    event CrosschainTokenSet(address token, uint256 chainDst, uint256 lzEid, address crosschainToken);

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the Router contract and sets the deployer as owner
    /// @dev Sets up Ownable with the message sender as the initial owner
    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                    CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets the TokenDataStream contract address
    /// @dev Only the contract owner can call this function
    /// @param _tokenDataStream The address of the TokenDataStream contract
    function setTokenDataStream(address _tokenDataStream) public onlyOwner {
        tokenDataStream = _tokenDataStream;
        emit TokenDataStreamSet(_tokenDataStream);
    }

    /// @notice Sets the IsHealthy contract address
    /// @dev Only the contract owner can call this function
    /// @param _isHealthy The address of the IsHealthy contract
    function setIsHealthy(address _isHealthy) public onlyOwner {
        isHealthy = _isHealthy;
        emit IsHealthySet(_isHealthy);
    }

    /// @notice Sets the LendingPool contract address
    /// @dev Only the contract owner can call this function
    /// @param _lendingPool The address of the LendingPool contract
    function setLendingPool(address _lendingPool) public onlyOwner {
        lendingPool = _lendingPool;
        emit LendingPoolSet(_lendingPool);
    }

    /// @notice Maps a chain ID to its corresponding LayerZero endpoint ID
    /// @dev Required for cross-chain operations via LayerZero. Only owner can call this.
    /// @param _chainId The chain ID (e.g., 1 for Ethereum mainnet)
    /// @param _lzEid The LayerZero endpoint ID for the chain
    function setChainIdToLzEid(uint256 _chainId, uint256 _lzEid) public onlyOwner {
        chainIdToLzEid[_chainId] = _lzEid;
        emit ChainIdToLzEidSet(_chainId, _lzEid);
    }

    /// @notice Maps a chain ID to its corresponding OApp contract address
    /// @dev OApps handle cross-chain message receiving. Only owner can call this.
    /// @param _chainId The chain ID
    /// @param _oApp The OApp contract address deployed on that chain
    function setChainIdToOApp(uint256 _chainId, address _oApp) public onlyOwner {
        chainIdToOApp[_chainId] = _oApp;
        emit ChainIdToOAppSet(_chainId, _oApp);
    }

    /// @notice Maps a local token to its corresponding token address on another chain
    /// @dev Sets both chain ID and LayerZero endpoint ID mappings. Requires the destination
    ///      chain to have a LayerZero endpoint ID configured first. Only owner can call this.
    /// @param _token The local token address
    /// @param _chainDst The destination chain ID
    /// @param _crosschainToken The corresponding token address on the destination chain
    function setCrosschainToken(address _token, uint256 _chainDst, address _crosschainToken) public onlyOwner {
        uint256 _lzEid = chainIdToLzEid[_chainDst];
        if (_lzEid == 0) revert LzEidNotSet(_chainDst, _lzEid);
        crosschainTokenByLzEid[_token][_lzEid] = _crosschainToken;
        crosschainTokenByChainId[_token][_chainDst] = _crosschainToken;
        emit CrosschainTokenSet(_token, _chainDst, _lzEid, _crosschainToken);
    }
}
