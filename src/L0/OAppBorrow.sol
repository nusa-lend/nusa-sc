// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IRouter} from "../interfaces/IRouter.sol";

/**
 * @title OAppBorrow
 * @author Nusa Protocol Team
 * @notice LayerZero OApp contract that handles cross-chain borrowing operations
 * @dev This contract extends LayerZero's OApp to enable cross-chain token borrowing.
 *      It receives borrow requests from source chains and executes borrows on the destination chain
 *      by interacting with the local LendingPool contract.
 * 
 * Key Features:
 * - Cross-chain message sending and receiving via LayerZero
 * - Integration with LendingPool for executing borrows
 * - Cross-chain token mapping through Router
 * - Fee estimation for cross-chain operations
 * - Message options support for gas and execution control
 */
contract OAppBorrow is OApp, OAppOptionsType3 {
    // =============================================================
    //                       STATE VARIABLES
    // =============================================================

    /// @notice Stores the last received cross-chain message data
    /// @dev Used for debugging and verification of received messages
    bytes public lastMessage;

    /// @notice Message type identifier for send operations
    uint16 public constant SEND = 1;

    /// @notice Address of the LendingPool contract on this chain
    address public lendingPool;

    /// @notice Address of the Router contract for cross-chain configurations
    address public router;

    // =============================================================
    //                           ERRORS
    // =============================================================

    /// @notice Thrown when attempting to send to a chain where the token mapping is not configured
    /// @param token The token address that doesn't have a mapping
    /// @param dstEid The destination endpoint ID where the mapping is missing
    error TokenNotSet(address token, uint32 dstEid);

    // =============================================================
    //                           EVENTS
    // =============================================================

    /// @notice Emitted when a cross-chain borrow message is received and processed
    /// @param srcEid The source LayerZero endpoint ID
    /// @param sender The user address receiving the borrowed tokens
    /// @param nonce The LayerZero message nonce
    /// @param token The token address being borrowed
    event MessageReceived(uint32 indexed srcEid, address indexed sender, uint64 nonce, address token);

    /// @notice Emitted when the lending pool address is updated
    /// @param lendingPool The new lending pool contract address
    event SetLendingPool(address lendingPool);

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    /// @notice Initializes the OAppBorrow contract with LayerZero endpoint and owner
    /// @dev Sets up the LayerZero OApp with the specified endpoint and owner addresses
    /// @param _endpoint The LayerZero endpoint address for this chain
    /// @param _owner The owner address that will have administrative privileges
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    // =============================================================
    //                        CORE FUNCTIONS
    // =============================================================

    /// @notice Quotes the fee for sending a cross-chain borrow message
    /// @dev Calculates the LayerZero messaging fee for the cross-chain borrow operation
    /// @param _dstEid The destination LayerZero endpoint ID
    /// @param _amount The amount of tokens to borrow
    /// @param _token The token address to borrow
    /// @param _user The user address that will receive the borrowed tokens
    /// @param _options LayerZero message options for gas and execution parameters
    /// @param _payInLzToken Whether to pay fees in LayerZero token instead of native token
    /// @return fee The messaging fee structure containing native and LZ token costs
    function quoteSendString(
        uint32 _dstEid,
        uint256 _amount,
        address _token,
        address _user,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(_amount, _token, _user);
        fee = _quote(_dstEid, _message, combineOptions(_dstEid, SEND, _options), _payInLzToken);
    }

    /// @notice Sends a cross-chain borrow message to the destination chain
    /// @dev Maps the local token to the destination chain token address and sends via LayerZero.
    ///      The message contains the borrow amount, destination token address, and user address.
    /// @param _dstEid The destination LayerZero endpoint ID
    /// @param _amount The amount of tokens to borrow
    /// @param _token The local token address to borrow (will be mapped to destination token)
    /// @param _user The user address that will receive the borrowed tokens
    /// @param _options LayerZero message options for gas and execution parameters
    function sendString(uint32 _dstEid, uint256 _amount, address _token, address _user, bytes calldata _options) external payable {
        _token = IRouter(router).crosschainTokenByLzEid(address(_token), _dstEid);
        if (_token == address(0)) {
            revert TokenNotSet(address(_token), _dstEid);
        }
        bytes memory _message = abi.encode(_amount, _token, _user);

        _lzSend(
            _dstEid, _message, combineOptions(_dstEid, SEND, _options), MessagingFee(msg.value, 0), payable(msg.sender)
        );
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // 2. Receive business logic
    //
    // Override _lzReceive to decode the incoming bytes and apply your logic.
    // The base OAppReceiver.lzReceive ensures:
    //   • Only the LayerZero Endpoint can call this method
    //   • The sender is a registered peer (peers[srcEid] == origin.sender)
    // ──────────────────────────────────────────────────────────────────────────────

    // =============================================================
    //                    LAYERZERO MESSAGE HANDLING
    // =============================================================

    /// @notice Internal function called by LayerZero when a message is received
    /// @dev Decodes the received message and executes a borrow on the local LendingPool.
    ///      The message contains amount, token address, and user address.
    /// @param _origin Metadata containing source chain info, sender address, and nonce
    /// @param _message ABI-encoded bytes containing (amount, token, user)
    function _lzReceive(
        Origin calldata _origin,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) internal override {
        (uint256 amount, address token, address user) = abi.decode(_message, (uint256, address, address));

        lastMessage = _message;

        // Execute the borrow on the local LendingPool
        ILendingPool(payable(lendingPool)).borrow(user, token, amount, block.chainid);

        emit MessageReceived(_origin.srcEid, user, _origin.nonce, token);
    }

    // =============================================================
    //                   CONFIGURATION FUNCTIONS
    // =============================================================

    /// @notice Sets the lending pool contract address
    /// @dev Only the contract owner can call this function
    /// @param _lendingPool The new lending pool contract address
    function setLendingPool(address _lendingPool) public onlyOwner {
        lendingPool = _lendingPool;
        emit SetLendingPool(_lendingPool);
    }

    /// @notice Sets the router contract address
    /// @dev Only the contract owner can call this function.
    ///      The router provides cross-chain token mappings.
    /// @param _router The new router contract address
    function setRouter(address _router) public onlyOwner {
        router = _router;
    }
}
